//
//  AIImageInfoView.swift
//  Cumberland
//
//  Created by Claude Code on 1/22/26.
//  ER-0009: AI Image Generation - Attribution Info Panel
//

import SwiftUI

/// Sheet view for displaying detailed AI image generation information
/// Part of ER-0009: AI Image Generation MVP
struct AIImageInfoView: View {

    // MARK: - Properties

    /// The card containing AI image metadata
    let card: Card

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.title)
                            .foregroundStyle(.purple)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Generated Image")
                                .font(.title2.bold())
                            Text("Image details and attribution")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.bottom, 8)

                    // Provider
                    if let provider = card.imageAIProvider {
                        InfoSection(
                            title: "AI Provider",
                            icon: "server.rack",
                            content: provider
                        )
                    }

                    // Generation Date
                    if let date = card.imageAIGeneratedAt {
                        InfoSection(
                            title: "Generated",
                            icon: "clock",
                            content: formatDate(date)
                        )
                    }

                    // Prompt
                    if let prompt = card.imageAIPrompt, !prompt.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "text.quote")
                                    .foregroundStyle(.purple)
                                Text("Prompt")
                                    .font(.headline)
                            }

                            Text(prompt)
                                .font(.body)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }

                    // Legal Notice
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text("Attribution & Rights")
                                .font(.headline)
                        }

                        Text(attributionNotice)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Image Information")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 480, minHeight: 400)
    }

    // MARK: - Helpers

    /// Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    /// Attribution notice based on provider
    private var attributionNotice: String {
        let provider = card.imageAIProvider ?? "AI"

        switch provider.lowercased() {
        case let p where p.contains("apple"):
            return """
            This image was generated using Apple Intelligence. According to Apple's terms, you own \
            the generated images and can use them in your creative work, including commercial use. \
            Attribution is recommended but not required.
            """
        case let p where p.contains("openai") || p.contains("dall"):
            return """
            This image was generated using OpenAI's DALL-E. According to OpenAI's terms, you own \
            the generated images and can use them in your creative work, including commercial use. \
            Attribution is recommended. Check OpenAI's current terms of service for details.
            """
        default:
            return """
            This image was generated using \(provider). Check your AI provider's terms of service \
            for licensing information and attribution requirements.
            """
        }
    }
}

// MARK: - Info Section Component

private struct InfoSection: View {
    let title: String
    let icon: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.purple)
                Text(title)
                    .font(.headline)
            }

            Text(content)
                .font(.body)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    let card = Card(
        kind: .characters,
        name: "Test Character",
        subtitle: "Test",
        detailedText: "Test description"
    )
    card.imageGeneratedByAI = true
    card.imageAIProvider = "OpenAI DALL-E 3"
    card.imageAIPrompt = "A detailed fantasy portrait of a warrior in ornate armor, standing in a mystical forest with glowing magical runes"
    card.imageAIGeneratedAt = Date()

    return AIImageInfoView(card: card)
}
#endif
