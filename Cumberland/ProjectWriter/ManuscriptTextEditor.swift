//
//  ManuscriptTextEditor.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-26.
//  ManuscriptTextEditor Container - Widget-based manuscript editor.
//
//  Phase 4 Implementation (ER-0056)
//  - ScrollView container with VStack of Chapter Widgets
//  - Query chapters for project
//  - Keyboard event routing (placeholder for cross-widget navigation)
//  - Fills all available space
//
//  Architecture:
//  ManuscriptTextEditor (ScrollView)
//  └── VStack
//      ├── ChapterWidget (Chapter 1)
//      │   ├── VStack (Scene Stack)
//      │   │   ├── SceneWidget (Scene 1-1)
//      │   │   │   ├── SceneSelectionGrip (leading, 4pt)
//      │   │   │   └── SceneTextEditor
//      │   │   └── ...
//      │   └── ChapterSelectionGrip (trailing, 8pt)
//      └── ...
//

import SwiftUI
import SwiftData

/// ManuscriptTextEditor - Container for widget-based manuscript editing
struct ManuscriptTextEditor: View {
    let project: Card
    @Binding var activeChapterID: UUID?
    @Binding var activeSceneID: UUID?
    @Environment(\.modelContext) private var modelContext

    // Use @Query to automatically observe SwiftData changes
    @Query private var allCards: [Card]

    // Computed property to filter chapters for this project
    private var chapters: [Card] {
        project.chaptersInProject(modelContext: modelContext)
    }

    var body: some View {
        VStack(spacing: 0) {
            if chapters.isEmpty {
                // Empty manuscript - no chapters yet
                emptyState
            } else {
                ForEach(chapters) { chapter in
                    ChapterWidget(chapter: chapter, project: project)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No Chapters Yet")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Create your first chapter to begin writing.")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

}

// MARK: - Preview

struct ManuscriptTextEditor_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var activeChapterID: UUID? = nil
        @State private var activeSceneID: UUID? = nil
        let project: Card

        var body: some View {
            ManuscriptTextEditor(
                project: project,
                activeChapterID: $activeChapterID,
                activeSceneID: $activeSceneID
            )
        }
    }

    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Card.self, CardEdge.self, configurations: config)
        let context = container.mainContext

        let project = Card(kind: .projects, name: "My Novel", subtitle: "", detailedText: "")
        context.insert(project)

        return PreviewWrapper(project: project)
            .modelContainer(container)
            .frame(width: 800, height: 600)
            .previewDisplayName("Empty Manuscript")
    }
}
