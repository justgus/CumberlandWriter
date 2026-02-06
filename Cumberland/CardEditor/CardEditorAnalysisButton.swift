//
//  CardEditorAnalysisButton.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//  Extracted from CardEditorView.swift
//

import SwiftUI
import SwiftData

/// Analysis button and logic for AI content analysis
struct CardEditorAnalysisButton: View {

    @Bindable var viewModel: CardEditorViewModel
    let mode: CardEditorView.Mode
    let modelContext: ModelContext

    var body: some View {
        Button {
            analyzeContent()
        } label: {
            HStack(spacing: 4) {
                if viewModel.isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "brain")
                        .font(.caption)
                }
                Text("Analyze")
                    .font(.caption)
            }
        }
        .disabled(viewModel.isAnalyzing || !canAnalyze)
        .help(analyzeButtonTooltip)
    }

    // MARK: - Computed Properties

    private var canAnalyze: Bool {
        guard AISettings.shared.isContentAnalysisAvailable else { return false }
        let wordCount = viewModel.detailedText.split(separator: " ").count
        return wordCount >= AISettings.shared.analysisMinWordCount
    }

    private var analyzeButtonTooltip: String {
        if !AISettings.shared.aiEnabled {
            return "AI features disabled in settings"
        }
        if !AISettings.shared.analysisEnabled {
            return "Content analysis disabled in settings"
        }
        if !AISettings.shared.isProviderAvailable {
            return "No AI provider available"
        }
        let wordCount = viewModel.detailedText.split(separator: " ").count
        let minWords = AISettings.shared.analysisMinWordCount
        if wordCount < minWords {
            return "Add more details (\(wordCount)/\(minWords) words)"
        }

        // Show preprocessing info for long text
        if wordCount > 500 {
            return "Analyze \(wordCount) word description (will extract key sentences for faster analysis)"
        }

        return "Analyze description to find entities and suggest cards (\(wordCount) words)"
    }

    // MARK: - Analysis Logic

    private func analyzeContent() {
        viewModel.isAnalyzing = true
        viewModel.analysisSuggestions = nil
        viewModel.analysisError = nil

        Task {
            do {
                // Get AI provider for analysis
                guard let provider = AISettings.shared.currentAnalysisProvider else {
                    throw AIProviderError.providerUnavailable(reason: "No AI provider available for analysis")
                }

                // Get current card (for edit mode) or create a temporary one (for create mode)
                let currentCard: Card
                switch mode {
                case .edit(let card, _):
                    currentCard = card
                case .create(let kind, _):
                    // Create temporary card for analysis
                    currentCard = Card(
                        kind: kind,
                        name: viewModel.name.isEmpty ? "Untitled" : viewModel.name,
                        subtitle: "",
                        detailedText: viewModel.detailedText
                    )
                }

                // Get all existing cards for deduplication
                let existingCards = try modelContext.fetch(FetchDescriptor<Card>())

                // ER-0020: Extract entities AND relationships from AI
                let extractor = EntityExtractor(provider: provider)
                let extractionResult = try await extractor.extractEntities(
                    from: viewModel.detailedText,
                    existingCards: existingCards
                )

                // Generate suggestions (Phase 6: relationship inference, Phase 7: calendar extraction, ER-0020: AI relationships)
                let suggestionEngine = SuggestionEngine()
                let suggestions = await suggestionEngine.generateAllSuggestions(
                    entities: extractionResult.entities,
                    relationships: extractionResult.relationships,  // ER-0020: AI-extracted relationships with dynamic verbs
                    sourceCard: currentCard,
                    existingCards: existingCards,
                    provider: provider,  // Phase 7: Pass provider for calendar extraction
                    totalEntitiesDetected: extractionResult.totalEntitiesDetected,  // ER-0015: Stats for empty state
                    entitiesFilteredAsExisting: extractionResult.entitiesFilteredAsExisting  // ER-0015
                )

                await MainActor.run {
                    viewModel.analysisSuggestions = suggestions
                    viewModel.isAnalyzing = false

                    if !suggestions.cards.isEmpty || !suggestions.relationships.isEmpty || !suggestions.calendars.isEmpty {
                        viewModel.showAnalysisSuggestions = true
                    } else {
                        // Provide helpful message based on text length
                        let wordCount = viewModel.detailedText.split(separator: " ").count
                        if wordCount > 1000 {
                            viewModel.analysisError = "No entities found in the \(wordCount) word description.\n\nFor long prose, AI analyzes key sentences containing proper nouns. Try ensuring character names, locations, and artifacts are capitalized (e.g., 'Aria' not 'aria', 'Blackrock City' not 'the city')."
                        } else {
                            viewModel.analysisError = "No entities found in the description.\n\nTry adding more specific details:\n• Character names (capitalized)\n• Location names (e.g., 'Blackrock City')\n• Artifacts (e.g., 'the Sword of Light')\n• Organizations or buildings"
                        }
                        viewModel.showAnalysisError = true
                    }
                }

            } catch {
                await MainActor.run {
                    // Provide helpful error messages based on error type
                    let errorMessage: String
                    if let aiError = error as? AIProviderError {
                        switch aiError {
                        case .invalidAPIKey:
                            errorMessage = "OpenAI API key is missing or invalid. Please add your API key in Settings → AI, or switch to Apple Intelligence."
                        case .providerUnavailable(let reason):
                            errorMessage = "AI provider unavailable: \(reason)\n\nTry switching to Apple Intelligence in Settings → AI."
                        case .networkError(let underlying):
                            if (underlying as NSError).code == -1001 {
                                errorMessage = "Request timed out. This can happen with cloud-based AI providers.\n\nTry:\n• Using Apple Intelligence (faster, on-device)\n• Shorter descriptions\n• Checking your network connection"
                            } else {
                                errorMessage = "Network error: \(underlying.localizedDescription)"
                            }
                        case .textTooShort(let minLength, let actual):
                            errorMessage = "Description too short (\(actual) words). Please add at least \(minLength) words."
                        default:
                            errorMessage = error.localizedDescription
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }

                    viewModel.analysisError = errorMessage
                    viewModel.showAnalysisError = true
                    viewModel.isAnalyzing = false
                }
            }
        }
    }
}
