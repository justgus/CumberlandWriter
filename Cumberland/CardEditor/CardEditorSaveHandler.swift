//
//  CardEditorSaveHandler.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//  Extracted from CardEditorView.swift
//

import Foundation
import SwiftData

/// Handles complex save logic for CardEditor including structure creation,
/// relationship management, and auto-generation
@MainActor
final class CardEditorSaveHandler {

    private let modelContext: ModelContext
    private let viewModel: CardEditorViewModel

    init(modelContext: ModelContext, viewModel: CardEditorViewModel) {
        self.modelContext = modelContext
        self.viewModel = viewModel
    }

    // MARK: - Save Operations

    /// Save a new card (create mode)
    func saveNewCard(kind: Kinds, onComplete: @escaping (Card) -> Void) throws {
        let card = try viewModel.createCard(kind: kind) { [weak self] card in
            // Structure creation callback for projects
            if kind == .projects {
                self?.persistStructureForNewProject(projectCard: card)
            }
        }

        // Auto-generate image if conditions met
        tryAutoGenerateImage(for: card)

        onComplete(card)
    }

    /// Save an existing card (edit mode)
    func saveExistingCard(_ card: Card, onComplete: @escaping () -> Void) throws {
        try viewModel.updateCard(card) { [weak self] card in
            // Structure update callback for projects
            if card.kind == .projects {
                self?.updateStructureForExistingProject(projectCard: card)
            }
        }

        // Auto-generate image if conditions met
        tryAutoGenerateImage(for: card)

        onComplete()
    }

    // MARK: - Structure Management

    private func persistStructureForNewProject(projectCard: Card) {
        guard !viewModel.structureName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard !viewModel.editableElements.isEmpty else { return }

        // Create structure
        let structure = StoryStructure(name: viewModel.structureName)
        modelContext.insert(structure)

        // Create elements
        for (index, editableEl) in viewModel.editableElements.enumerated() {
            let element = StructureElement(
                name: editableEl.name,
                elementDescription: editableEl.description,
                orderIndex: index
            )
            element.colorHue = editableEl.colorHue
            element.storyStructure = structure
            modelContext.insert(element)

            // No card assignments for new project
        }

        try? modelContext.save()
    }

    private func updateStructureForExistingProject(projectCard: Card) {
        // Find existing structure for this project
        let projectName = projectCard.name
        let fetchDesc = FetchDescriptor<StoryStructure>(
            predicate: #Predicate { structure in
                structure.name == projectName
            }
        )

        guard let existing = try? modelContext.fetch(fetchDesc).first else {
            // No existing structure - create if user configured one
            if viewModel.attachStructure {
                persistStructureForNewProject(projectCard: projectCard)
            }
            return
        }

        if !viewModel.attachStructure {
            // User toggled off - remove structure
            modelContext.delete(existing)
            try? modelContext.save()
            return
        }

        // Update existing structure
        existing.name = viewModel.structureName

        // Sync elements
        let oldElements = existing.elements ?? []

        // Remove elements not in editableElements
        for oldEl in oldElements {
            if !viewModel.editableElements.contains(where: { $0.name == oldEl.name }) {
                modelContext.delete(oldEl)
            }
        }

        // Add/update elements from editableElements
        for (index, editableEl) in viewModel.editableElements.enumerated() {
            if let existingEl = oldElements.first(where: { $0.name == editableEl.name }) {
                // Update existing
                existingEl.orderIndex = index
                existingEl.elementDescription = editableEl.description
                existingEl.colorHue = editableEl.colorHue
            } else {
                // Create new
                let newElement = StructureElement(
                    name: editableEl.name,
                    elementDescription: editableEl.description,
                    orderIndex: index
                )
                newElement.colorHue = editableEl.colorHue
                newElement.storyStructure = existing
                modelContext.insert(newElement)
            }
        }

        try? modelContext.save()
    }

    // MARK: - Auto-Generation

    private func tryAutoGenerateImage(for card: Card) {
        let settings = AISettings.shared

        // Check if auto-generation is enabled
        guard settings.autoGenerateImages else { return }

        // Check if AI is available
        guard settings.isImageGenerationAvailable else { return }

        // Check if card doesn't already have an image
        guard card.originalImageData == nil else { return }

        // Check if description meets minimum word count
        let words = card.detailedText.split(separator: " ").count
        guard words >= settings.autoGenerateMinWords else { return }

        // All conditions met - trigger async image generation
        Task { @MainActor in
            await generateImageForCard(card)
        }
    }

    private func generateImageForCard(_ card: Card) async {
        // Extract prompt from card description
        let prompts = PromptExtractor.extractPromptVariations(
            from: card.detailedText,
            cardName: card.name,
            cardKind: card.kind
        )

        guard let primaryPrompt = prompts.first else { return }

        // Get AI provider
        guard let provider = AISettings.shared.currentImageGenerationProvider else { return }

        do {
            let imageData = try await provider.generateImage(prompt: primaryPrompt)

            // Save image to card
            try? card.setOriginalImageData(imageData)
            try? modelContext.save()

            #if DEBUG
            print("✅ [CardEditorSaveHandler] Auto-generated image for card: \(card.name)")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ [CardEditorSaveHandler] Auto-generation failed: \(error)")
            #endif
        }
    }
}
