//
//  SceneWidget.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-26.
//  Scene Widget - Text editor for a single Scene Card's detailedText.
//
//  Phase 2 Implementation (ER-0056)
//  - HStack with SceneSelectionGrip (4pt) + SceneTextEditor
//  - Load/save scene text with debouncing (500ms)
//  - Active scene tracking
//  - Focus coordination
//

import SwiftUI
import SwiftData

/// Scene Widget - Editable text for a single scene
struct SceneWidget: View {
    let scene: Card          // Scene card (kind = .scenes)
    let chapter: Card        // Parent chapter
    @Environment(\.modelContext) private var modelContext

    @State private var isActive: Bool = false
    @State private var sceneText: String = ""
    @FocusState private var isFocused: Bool

    // Debouncing state
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 0) {
            // Selection grip (leading edge)
            SceneSelectionGrip(scene: scene, isActive: isActive)
                .frame(width: 4)

            // Text editor
            SceneTextEditor(
                text: $sceneText,
                scene: scene,
                isActive: $isActive,
                isFocused: $isFocused,  // Use $ for FocusState projected value
                onTextChanged: { newText in
                    saveSceneText(newText)
                },
                onNavigateUp: {
                    activatePreviousScene()
                },
                onNavigateDown: {
                    activateNextScene()
                }
            )
        }
        .onAppear {
            loadSceneText()
        }
    }

    // MARK: - Text Loading

    private func loadSceneText() {
        sceneText = scene.detailedText
        print("DEBUG SceneWidget: Loaded text for scene '\(scene.name)': \(sceneText.prefix(50))... (length: \(sceneText.count))")
    }

    // MARK: - Text Saving (Debounced)

    private func saveSceneText(_ newText: String) {
        // Cancel previous save task
        saveTask?.cancel()

        // Note: Don't update sceneText here - binding already handles it
        // Updating it here causes double-render and focus loss

        // Schedule debounced save (500ms)
        saveTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))

                // Check if task was cancelled
                guard !Task.isCancelled else { return }

                // Save to Card
                await MainActor.run {
                    scene.detailedText = newText

                    // Save via CardRepository
                    let cardRepo = CardRepository(modelContext: modelContext)
                    do {
                        try cardRepo.save()
                    } catch {
                        print("Error saving scene text: \(error)")
                    }
                }
            } catch {
                // Task sleep was cancelled or interrupted
            }
        }
    }

    // MARK: - Navigation (Placeholder)

    private func activatePreviousScene() {
        // TODO: Phase 4 - Navigate to previous scene in chapter
        // This will be handled by parent ChapterWidget or ManuscriptTextEditor
        print("Navigate to previous scene (not yet implemented)")
    }

    private func activateNextScene() {
        // TODO: Phase 4 - Navigate to next scene in chapter
        // This will be handled by parent ChapterWidget or ManuscriptTextEditor
        print("Navigate to next scene (not yet implemented)")
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, configurations: config)
    let context = container.mainContext

    // Create sample scene
    let scene = Card(
        kind: .scenes,
        name: "Opening Scene",
        subtitle: "",
        detailedText: """
        The old wooden door creaked as Sarah pushed it open. Dust motes danced in the shaft of sunlight that cut through the darkness of the abandoned library.

        She stepped inside, her footsteps echoing on the marble floor.
        """
    )
    context.insert(scene)

    // Create sample chapter
    let chapter = Card(kind: .chapters, name: "Chapter 1", subtitle: "", detailedText: "")
    context.insert(chapter)

    return SceneWidget(scene: scene, chapter: chapter)
        .modelContainer(container)
        .frame(width: 600, height: 400)
}
