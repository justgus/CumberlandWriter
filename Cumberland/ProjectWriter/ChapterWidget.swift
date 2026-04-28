//
//  ChapterWidget.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-26.
//  Chapter Widget - Container for all Scene Widgets in a chapter.
//
//  Phase 3 Implementation (ER-0056)
//  - HStack with VStack of Scene Widgets + Chapter Selection Grip (8pt, trailing)
//  - Query scenes for chapter with chapterID filtering
//  - Sort scenes by sortIndex
//  - Chapter-level active state tracking
//

import SwiftUI
import SwiftData

/// Chapter Widget - Contains all scenes for a single chapter
struct ChapterWidget: View {
    let chapter: Card        // Chapter card (kind = .chapters)
    let project: Card        // Parent project
    @Environment(\.modelContext) private var modelContext

    // Use @Query to automatically observe SwiftData changes
    @Query private var allCards: [Card]

    @State private var isActive: Bool = false

    // Computed property to filter scenes for this chapter
    private var scenes: [Card] {
        let cardRepo = CardRepository(modelContext: modelContext)
        return cardRepo.fetchScenesInChapter(
            chapterID: chapter.id,
            projectID: project.id
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            // Scene widgets stack (leading to trailing)
            VStack(spacing: 2) {  // 2pt spacing between scenes for visual separation
                if scenes.isEmpty {
                    // Empty chapter - no scenes to display
                    // ChapterSelectionGrip will show "Empty Chapter" indicator
                } else {
                    ForEach(scenes) { scene in
                        SceneWidget(scene: scene, chapter: chapter)
                    }
                }
            }

            // Chapter Selection Grip (trailing edge)
            ChapterSelectionGrip(
                chapter: chapter,
                sceneCount: scenes.count,
                isActive: isActive
            )
            .frame(width: 8)
        }
    }
}

// MARK: - Preview

#Preview("Empty Chapter") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, CardEdge.self, configurations: config)
    let context = container.mainContext

    // Create project and chapter (no scenes)
    let project = Card(kind: .projects, name: "Test Project", subtitle: "", detailedText: "")
    context.insert(project)

    let chapter = Card(kind: .chapters, name: "Chapter 1", subtitle: "", detailedText: "")
    context.insert(chapter)

    return ChapterWidget(chapter: chapter, project: project)
        .modelContainer(container)
        .frame(width: 600, height: 100)
}

#Preview("Chapter with Scenes") {
    // Note: Creating proper edges in preview is complex
    // This preview shows the structure; actual scene display requires
    // proper Scene → Chapter and Scene → Project edges in real usage
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, CardEdge.self, configurations: config)
    let context = container.mainContext

    let project = Card(kind: .projects, name: "Test Project", subtitle: "", detailedText: "")
    context.insert(project)

    let chapter = Card(kind: .chapters, name: "Chapter 1", subtitle: "", detailedText: "")
    context.insert(chapter)

    return ChapterWidget(chapter: chapter, project: project)
        .modelContainer(container)
        .frame(width: 600, height: 400)
}
