//
//  AIImageGenerationView.swift
//  Cumberland
//
//  Created by Claude Code on 1/21/26.
//  ER-0009: AI Image Generation for Cards
//

import SwiftUI
import OSLog

/// Sheet view for generating AI images with prompts
/// Part of ER-0009: AI Image Generation MVP
struct AIImageGenerationView: View {

    // MARK: - Properties

    /// Card name to help generate better prompts
    let cardName: String

    /// Optional initial prompt (for regenerating existing AI images)
    let initialPrompt: String?

    /// Callback when image is successfully generated and accepted
    let onImageGenerated: (GeneratedImageData) -> Void

    @Environment(\.dismiss) private var dismiss

    /// The AI image generator
    @State private var generator = AIImageGenerator()

    /// User's prompt input
    @State private var prompt: String = ""

    /// Suggested prompts based on card name
    @State private var suggestedPrompts: [String] = []

    /// Selected provider name
    @State private var selectedProvider: String = ""

    /// Available providers
    private var availableProviders: [String] {
        AIProviderRegistry.shared.availableProviders().map { $0.name }
    }

    /// Logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "AIImageGenerationView")

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Generate Image with AI")
                        .font(.title2.bold())

                    Text("Describe the image you want to create for \"\(cardName)\"")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Prompt input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt")
                        .font(.headline)

                    TextEditor(text: $prompt)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(.background)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .disabled(generator.isGenerating)

                    // Suggested prompts
                    if !suggestedPrompts.isEmpty && prompt.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Suggestions:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(suggestedPrompts, id: \.self) { suggestion in
                                Button {
                                    prompt = suggestion
                                } label: {
                                    HStack {
                                        Image(systemName: "lightbulb")
                                            .font(.caption)
                                        Text(suggestion)
                                            .font(.caption)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                    }
                }

                // Provider selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Provider")
                        .font(.headline)

                    Picker("Provider", selection: $selectedProvider) {
                        ForEach(availableProviders, id: \.self) { providerName in
                            HStack {
                                Text(providerName)

                                // Show indicator if API key is required
                                if let provider = AIProviderRegistry.shared.provider(named: providerName),
                                   provider.requiresAPIKey {
                                    let providerKey = providerName.split(separator: " ").first.map(String.init)?.lowercased() ?? providerName.lowercased()
                                    if KeychainHelper.shared.hasAPIKey(for: providerKey) {
                                        Image(systemName: "key.fill")
                                            .foregroundStyle(.green)
                                            .font(.caption)
                                    } else {
                                        Image(systemName: "key")
                                            .foregroundStyle(.orange)
                                            .font(.caption)
                                    }
                                }
                            }
                            .tag(providerName)
                        }
                    }
                    #if os(macOS)
                    .pickerStyle(.menu)
                    #else
                    .pickerStyle(.segmented)
                    #endif
                    .disabled(generator.isGenerating)

                    // API key warning if needed
                    if let provider = AIProviderRegistry.shared.provider(named: selectedProvider),
                       provider.requiresAPIKey {
                        let providerKey = selectedProvider.split(separator: " ").first.map(String.init)?.lowercased() ?? selectedProvider.lowercased()
                        if !KeychainHelper.shared.hasAPIKey(for: providerKey) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("API key required. Configure in Settings.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }

                // Generation state
                if generator.isGenerating {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Generating image...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let progress = generator.progress {
                            ProgressView(value: progress)
                                .frame(maxWidth: 300)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }

                // Preview generated image
                if let image = generator.generatedImage {
                    VStack(spacing: 12) {
                        Text("Preview")
                            .font(.headline)

                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .shadow(radius: 4)

                        HStack(spacing: 16) {
                            Button {
                                Task {
                                    await regenerate()
                                }
                            } label: {
                                Label("Retry", systemImage: "arrow.clockwise")
                            }

                            Button {
                                acceptImage()
                            } label: {
                                Label("Accept", systemImage: "checkmark")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                // Error display
                if let error = generator.error {
                    VStack(spacing: 8) {
                        Label("Generation Failed", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                            .foregroundStyle(.red)

                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            generator.reset()
                        } label: {
                            Label("Try Again", systemImage: "arrow.clockwise")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }

                Spacer()

                // Action buttons
                if !generator.isGenerating && generator.generatedImage == nil {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .keyboardShortcut(.cancelAction)

                        Spacer()

                        Button {
                            Task {
                                await generate()
                            }
                        } label: {
                            Label("Generate", systemImage: "wand.and.stars")
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !canGenerate)
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
            .frame(minWidth: 520, minHeight: 480)
            .navigationTitle("AI Image Generation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Pre-fill prompt if regenerating existing AI image
            if let initial = initialPrompt, !initial.isEmpty {
                prompt = initial
            }

            generateSuggestedPrompts()
            // Set default provider
            if selectedProvider.isEmpty {
                selectedProvider = AIProviderRegistry.shared.getPreferredProviderName()
            }
        }
    }

    // MARK: - Computed Properties

    /// Whether generation can proceed (valid provider with API key if needed)
    private var canGenerate: Bool {
        guard let provider = AIProviderRegistry.shared.provider(named: selectedProvider) else {
            return false
        }

        if provider.requiresAPIKey {
            let providerKey = selectedProvider.split(separator: " ").first.map(String.init)?.lowercased() ?? selectedProvider.lowercased()
            return KeychainHelper.shared.hasAPIKey(for: providerKey)
        }

        return true
    }

    // MARK: - Actions

    /// Generate image from prompt
    @MainActor
    private func generate() async {
        logger.info("Generating image with prompt: '\(prompt)' using provider: '\(selectedProvider)'")

        do {
            _ = try await generator.generateImage(prompt: prompt, provider: selectedProvider)
            logger.info("Image generation completed")
        } catch {
            logger.error("Image generation failed: \(error.localizedDescription)")
        }
    }

    /// Regenerate with same prompt
    @MainActor
    private func regenerate() async {
        generator.reset()
        await generate()
    }

    /// Accept the generated image and close
    private func acceptImage() {
        guard let imageData = generator.generatedImageData else {
            logger.error("No image data to accept")
            return
        }

        let data = GeneratedImageData(
            imageData: imageData,
            prompt: prompt,
            provider: selectedProvider,
            generatedAt: Date()
        )

        logger.info("Image accepted, closing sheet")
        onImageGenerated(data)
        dismiss()
    }

    /// Generate suggested prompts based on card name
    private func generateSuggestedPrompts() {
        // Simple prompt suggestions - in the future, this could use AI
        suggestedPrompts = [
            "A detailed illustration of \(cardName)",
            "Concept art for \(cardName)",
            "A portrait of \(cardName)"
        ]
    }
}

// MARK: - Supporting Types

/// Data structure for generated images
struct GeneratedImageData {
    let imageData: Data
    let prompt: String
    let provider: String
    let generatedAt: Date
}

// MARK: - Previews

#if DEBUG
#Preview {
    AIImageGenerationView(
        cardName: "Aria Blackwood",
        initialPrompt: nil,
        onImageGenerated: { data in
            print("Generated: \(data.prompt)")
        }
    )
}
#endif
