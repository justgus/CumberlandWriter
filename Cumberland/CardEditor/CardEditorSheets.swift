//
//  CardEditorSheets.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//  Extracted from CardEditorView.swift
//
//  ViewModifier/extension that attaches all sheet, fullScreenCover, and
//  alert presentations to CardEditorView: AI image generation, photo picker,
//  quick attribution, visual element review, image history, and batch
//  generation progress.
//

import SwiftUI
import SwiftData

/// Container for all sheet presentations and overlays in CardEditorView
struct CardEditorSheets: ViewModifier {

    @Bindable var viewModel: CardEditorViewModel
    let mode: CardEditorView.Mode
    let modelContext: ModelContext
    let onAIImageGenerated: (GeneratedImageData) -> Void

    func body(content: Content) -> some View {
        content
            // Full-size image viewer
            #if os(macOS)
            .sheet(isPresented: $viewModel.showFullSizeImage) {
                fullSizeImageViewer
            }
            #else
            .fullScreenCover(isPresented: $viewModel.showFullSizeImage) {
                fullSizeImageViewer
            }
            #endif
            // AI Image Generation sheet (ER-0009)
            .sheet(isPresented: $viewModel.showAIImageGeneration) {
                aiImageGenerationSheet
            }
            // AI Image Info panel (ER-0009)
            .sheet(isPresented: $viewModel.showAIImageInfo) {
                aiImageInfoSheet
            }
            // Image History panel (ER-0017)
            // DR-0091: onDismiss reloads card image into ViewModel after restore
            .sheet(isPresented: $viewModel.showImageHistory, onDismiss: {
                if case .edit(let card, _) = mode {
                    viewModel.reloadImageFromCard(card)
                }
            }) {
                imageHistorySheet
            }
            // Suggestion Review panel (ER-0010)
            .sheet(isPresented: $viewModel.showAnalysisSuggestions) {
                suggestionReviewSheet
            }
            // Analysis error alert (ER-0010)
            .alert("Analysis Complete", isPresented: $viewModel.showAnalysisError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = viewModel.analysisError {
                    Text(error)
                }
            }
            // Copy feedback overlay (ER-0011 Phase 1)
            .overlay(alignment: .top) {
                if viewModel.showCopyFeedback {
                    feedbackBanner(
                        message: "Image copied to clipboard",
                        binding: $viewModel.showCopyFeedback
                    )
                }
            }
            // Paste feedback overlay (ER-0011 Phase 1)
            .overlay(alignment: .top) {
                if viewModel.showPasteFeedback {
                    feedbackBanner(
                        message: "Image pasted from clipboard",
                        binding: $viewModel.showPasteFeedback
                    )
                }
            }
    }

    // MARK: - Sheet Views

    @ViewBuilder
    private var fullSizeImageViewer: some View {
        if case .edit(let card, _) = mode {
            FullSizeImageViewer(card: card, pendingImageData: viewModel.imageData)
                .id(viewModel.imageData?.count ?? card.originalImageData?.count ?? 0)
        }
    }

    @ViewBuilder
    private var aiImageGenerationSheet: some View {
        AIImageGenerationView(
            cardName: viewModel.name,
            cardDescription: viewModel.detailedText,
            cardKind: mode.kind,
            initialPrompt: nil, // Don't pre-fill - let it generate fresh suggestions
            onImageGenerated: { generatedData in
                onAIImageGenerated(generatedData)
            }
        )
    }

    @ViewBuilder
    private var aiImageInfoSheet: some View {
        if case .edit(let card, _) = mode {
            AIImageInfoView(card: card)
        }
    }

    @ViewBuilder
    private var imageHistorySheet: some View {
        if case .edit(let card, _) = mode {
            ImageHistoryView(card: card)
        }
    }

    @ViewBuilder
    private var suggestionReviewSheet: some View {
        if let suggestions = viewModel.analysisSuggestions {
            SuggestionReviewView(
                suggestions: suggestions,
                sourceCard: currentCardForAnalysis,
                existingCards: allCards,
                pendingRelationships: $viewModel.pendingRelationships
            )
        }
    }

    // MARK: - Feedback Banner

    @ViewBuilder
    private func feedbackBanner(message: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(message)
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 4)
        .padding(.top, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    binding.wrappedValue = false
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var currentCardForAnalysis: Card {
        switch mode {
        case .edit(let card, _):
            return card
        case .create(let kind, _):
            // Create temporary card for display
            return Card(
                kind: kind,
                name: viewModel.name.isEmpty ? "Untitled" : viewModel.name,
                subtitle: "",
                detailedText: viewModel.detailedText
            )
        }
    }

    private var allCards: [Card] {
        (try? modelContext.fetch(FetchDescriptor<Card>())) ?? []
    }
}

// MARK: - View Extension

extension View {
    func cardEditorSheets(
        viewModel: CardEditorViewModel,
        mode: CardEditorView.Mode,
        modelContext: ModelContext,
        onAIImageGenerated: @escaping (GeneratedImageData) -> Void
    ) -> some View {
        modifier(CardEditorSheets(
            viewModel: viewModel,
            mode: mode,
            modelContext: modelContext,
            onAIImageGenerated: onAIImageGenerated
        ))
    }
}
