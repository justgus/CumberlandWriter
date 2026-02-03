//
//  AIImageGenerationView.swift
//  Cumberland
//
//  Created by Claude Code on 1/21/26.
//  ER-0009: AI Image Generation for Cards
//

import SwiftUI
import OSLog
#if canImport(ImagePlayground)
import ImagePlayground
#endif

/// Sheet view for generating AI images with prompts
/// Part of ER-0009: AI Image Generation MVP
struct AIImageGenerationView: View {

    // MARK: - Properties

    /// Card name to help generate better prompts
    let cardName: String

    /// Card description for smart prompt extraction (Phase 3A)
    let cardDescription: String

    /// Card kind for contextual prompt generation (Phase 3A)
    let cardKind: Kinds

    /// Optional initial prompt (for regenerating existing AI images)
    let initialPrompt: String?

    /// Callback when image is successfully generated and accepted
    let onImageGenerated: (GeneratedImageData) -> Void

    @Environment(\.dismiss) private var dismiss

    /// Check if ImagePlayground is supported (iOS 18.1+, macOS 15.1+)
    #if canImport(ImagePlayground)
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground
    #endif

    /// The AI image generator (for programmatic APIs like OpenAI)
    @State private var generator = AIImageGenerator()

    /// User's prompt input
    @State private var prompt: String = ""

    /// Suggested prompts based on card name
    @State private var suggestedPrompts: [String] = []

    /// Selected provider name - initialized with preferred provider to avoid Picker warning
    @State private var selectedProvider: String = AIProviderRegistry.shared.getPreferredProviderName()

    /// Show ImagePlayground sheet (for Apple Intelligence)
    @State private var showImagePlaygroundSheet: Bool = false

    /// Generated image URL from ImagePlayground
    @State private var imagePlaygroundURL: URL?

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
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .textBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                .allowsHitTesting(false) // Allow text interactions through the overlay
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
                            if usesSheetBasedUI {
                                // Show ImagePlayground sheet
                                showImagePlaygroundSheet = true
                            } else {
                                // Use programmatic API
                                Task {
                                    await generate()
                                }
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
            // Reload provider from settings (DR-0070: ensure picker shows saved value)
            selectedProvider = AISettings.shared.imageGenerationProvider

            // Generate smart suggestions based on card description
            generateSuggestedPrompts()

            // Pre-fill prompt
            if let initial = initialPrompt, !initial.isEmpty {
                // Use existing prompt if regenerating
                prompt = initial
            } else if !suggestedPrompts.isEmpty {
                // Auto-fill with first (best) suggestion for new generation
                prompt = suggestedPrompts[0]
            }
        }
        #if canImport(ImagePlayground)
        .imagePlaygroundSheet(
            isPresented: $showImagePlaygroundSheet,
            concepts: [
                ImagePlaygroundConcept.text(prompt)
            ]
        ) { url in
            handleImagePlaygroundResult(url)
        }
        #endif
    }

    // MARK: - Computed Properties

    /// Whether the selected provider uses sheet-based UI (like ImagePlayground)
    private var usesSheetBasedUI: Bool {
        guard let provider = AIProviderRegistry.shared.provider(named: selectedProvider) else {
            return false
        }
        return provider.usesSheetBasedUI
    }

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

    /// Handle image URL from ImagePlayground
    @MainActor
    private func handleImagePlaygroundResult(_ url: URL) {
        logger.info("ImagePlayground generated image at URL: \(url.path)")

        do {
            // Load image data from the temporary URL
            let imageData = try Data(contentsOf: url)

            // Create generated image data
            let data = GeneratedImageData(
                imageData: imageData,
                prompt: prompt,
                provider: selectedProvider,
                generatedAt: Date()
            )

            logger.info("ImagePlayground image loaded, closing sheet")
            onImageGenerated(data)
            dismiss()

        } catch {
            logger.error("Failed to load image from ImagePlayground URL: \(error.localizedDescription)")
            // ImagePlayground has already shown its UI, so just log and dismiss
            dismiss()
        }
    }

    /// Generate suggested prompts based on card description and type (Phase 3A)
    private func generateSuggestedPrompts() {
        // Use PromptExtractor to generate smart prompts from description
        let variations = PromptExtractor.extractPromptVariations(
            from: cardDescription,
            cardName: cardName,
            cardKind: cardKind
        )

        if !variations.isEmpty {
            suggestedPrompts = variations
        } else {
            // Fallback to simple prompts if description is insufficient
            // Check for weapon terms to avoid content filters
            let sensitivePrefixes = ["weapon", "gun", "rifle", "pistol", "sword", "blade", "knife", "axe", "bomb", "explosive"]
            let nameWords = cardName.lowercased().split(separator: " ").map(String.init)
            let hasSensitiveTerm = nameWords.contains { word in
                sensitivePrefixes.contains(where: { word.contains($0) })
            }

            if cardKind == .artifacts && hasSensitiveTerm {
                // Generic fallback for artifacts with weapon terms
                suggestedPrompts = [
                    "An intricate artifact with detailed craftsmanship",
                    "A detailed object with unique design elements",
                    "Concept art of an artifact, high quality detailed rendering"
                ]
            } else {
                // Normal fallback prompts
                suggestedPrompts = [
                    "A detailed illustration of \(cardName)",
                    "Concept art for \(cardName)",
                    PromptExtractor.kindToPromptPrefix(cardKind) + " \(cardName)"
                ]
            }
        }
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
        cardDescription: "A tall woman with piercing green eyes and flowing crimson hair. She wears an ornate leather coat adorned with silver buttons. Her face bears a mysterious scar across her left cheek.",
        cardKind: .characters,
        initialPrompt: nil,
        onImageGenerated: { data in
            print("Generated: \(data.prompt)")
        }
    )
}
#endif
