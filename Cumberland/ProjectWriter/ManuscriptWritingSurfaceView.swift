//
//  ManuscriptWritingSurfaceView.swift
//  Cumberland
//
//  Manuscript-first working surface for Cumberland Writer.
//  Continuous vertical text editor with scene awareness underneath.
//
//  Design principles:
//  - Manuscript first, scene-aware underneath
//  - Continuous scrolling through all scenes
//  - Scene boundaries are subtle (spacing, tone shifts, separator lines)
//  - Right context gutter shows active scene objects (compressed, circle-based)
//  - Chapter tabs at top, scene map at bottom
//  - Quick scene/chapter creation controls
//

import SwiftUI
import SwiftData

struct ManuscriptWritingSurfaceView: View {
    let project: Card

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    // Query for chapters and scenes related to this project
    @Query private var allCards: [Card]

    // State for active chapter and scene
    @State private var activeChapterID: UUID?
    @State private var activeSceneID: UUID?

    // Manuscript text (placeholder - will be built from scenes)
    @State private var manuscriptText: String = ""

    // Context gutter items for active scene
    @State private var contextGutterItems: [Card] = []

    private var chapters: [Card] {
        allCards.filter { card in
            card.kind == .chapters &&
            // TODO: Filter by cards linked to this project
            true
        }
        .sorted { $0.name < $1.name }
    }

    private var scenes: [Card] {
        allCards.filter { card in
            card.kind == .scenes &&
            // TODO: Filter by cards linked to this project and active chapter
            true
        }
        .sorted { $0.name < $1.name }
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main manuscript canvas
                manuscriptCanvas
                    .frame(maxWidth: .infinity)

                // Right context gutter (compressed, object/circle-based)
                contextGutter
                    .frame(width: 80)
            }
        }
        .overlay(alignment: .top) {
            // Chapter tab strip
            chapterTabStrip
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                // Scene map instrument
                sceneMapInstrument
                    .padding(.bottom, 8)

                // Quick action tray
                quickActionTray
            }
        }
        .onAppear {
            loadManuscriptContent()
        }
    }

    // MARK: - Chapter Tab Strip

    private var chapterTabStrip: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(chapters) { chapter in
                        chapterTab(for: chapter)
                    }
                }
                .padding(.horizontal, 12)
            }

            // Add Chapter control
            Button {
                createNewChapter()
            } label: {
                Label("Add Chapter", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 14))
                    .frame(width: 32, height: 28)
            }
            .buttonStyle(.bordered)
            .help("Create a new chapter")
            .padding(.trailing, 12)
        }
        .frame(height: 44)
        .background(
            themeManager.currentTheme.colors.surfaceSecondary.platformResolved
                .asBackground()
                .opacity(0.95)
        )
    }

    private func chapterTab(for chapter: Card) -> some View {
        let isActive = activeChapterID == chapter.id

        return Button {
            withAnimation {
                activeChapterID = chapter.id
                // Jump to first scene in this chapter
                if let firstScene = scenesInChapter(chapter).first {
                    activeSceneID = firstScene.id
                }
            }
        } label: {
            Text(chapter.name.isEmpty ? "Chapter \(chapterNumber(chapter))" : chapter.name)
                .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? themeManager.currentTheme.colors.textPrimary : themeManager.currentTheme.colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    if isActive {
                        themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground(cornerRadius: 6)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func chapterNumber(_ chapter: Card) -> Int {
        (chapters.firstIndex(where: { $0.id == chapter.id }) ?? 0) + 1
    }

    private func scenesInChapter(_ chapter: Card) -> [Card] {
        // TODO: Filter scenes by chapter relationship
        scenes
    }

    // MARK: - Manuscript Canvas

    private var manuscriptCanvas: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                // Current scene chip (floating indicator)
                if let activeScene = scenes.first(where: { $0.id == activeSceneID }) {
                    HStack {
                        Text("Scene \(sceneNumber(activeScene)) • \(activeScene.name)")
                            .font(.caption)
                            .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .background(themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground())
                            )
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }

                // Continuous manuscript text
                TextEditor(text: $manuscriptText)
                    .font(.system(size: 16, design: .serif))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 20)
                    .frame(maxWidth: 800) // Readable line length
            }
        }
        .background(themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground())
    }

    private func sceneNumber(_ scene: Card) -> Int {
        (scenes.firstIndex(where: { $0.id == scene.id }) ?? 0) + 1
    }

    // MARK: - Context Gutter

    private var contextGutter: some View {
        VStack(spacing: 12) {
            Text("Context")
                .font(.caption2)
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
                .padding(.top, 12)

            ForEach(contextGutterItems) { item in
                contextGutterCircle(for: item)
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .background(
            themeManager.currentTheme.colors.surfaceSecondary.platformResolved
                .asBackground()
                .opacity(0.5)
        )
    }

    private func contextGutterCircle(for item: Card) -> some View {
        ZStack {
            Circle()
                .background(themeManager.currentTheme.colors.surfaceTertiary.platformResolved.asBackground())
                .frame(width: 48, height: 48)

            Circle()
                .strokeBorder(colorForKind(item.kind), lineWidth: 3)
                .frame(width: 48, height: 48)

            // Thumbnail or icon
            if let thumbnailData = item.thumbnailData {
                #if os(macOS)
                if let nsImage = NSImage(data: thumbnailData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Image(systemName: item.kind.systemImage)
                        .font(.system(size: 18))
                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                }
                #else
                if let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Image(systemName: item.kind.systemImage)
                        .font(.system(size: 18))
                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                }
                #endif
            } else {
                Image(systemName: item.kind.systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
            }
        }
        .help(item.name)
    }

    private func colorForKind(_ kind: Kinds) -> Color {
        switch kind {
        case .characters: return .blue
        case .artifacts: return .orange
        case .vehicles: return .green
        case .locations: return .purple
        default: return .gray
        }
    }

    // MARK: - Scene Map Instrument

    private var sceneMapInstrument: some View {
        HStack(spacing: 8) {
            // Add Scene control
            Button {
                createNewScene()
            } label: {
                Label("Add Scene", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 14))
            }
            .buttonStyle(.bordered)
            .help("Create a new scene")

            // Scene marks
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(scenes) { scene in
                        sceneMapMark(for: scene)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            themeManager.currentTheme.colors.surfaceSecondary.platformResolved
                .asBackground()
                .opacity(0.95)
        )
    }

    private func sceneMapMark(for scene: Card) -> some View {
        let isActive = activeSceneID == scene.id

        return Button {
            withAnimation {
                activeSceneID = scene.id
                // TODO: Scroll to this scene in manuscript
            }
        } label: {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(isActive ? themeManager.currentTheme.colors.accentPrimary : themeManager.currentTheme.colors.textTertiary)
                .frame(width: 8, height: isActive ? 24 : 16)
        }
        .buttonStyle(.plain)
        .help(scene.name.isEmpty ? "Scene \(sceneNumber(scene))" : scene.name)
    }

    // MARK: - Quick Action Tray

    private var quickActionTray: some View {
        HStack(spacing: 16) {
            quickActionButton(title: "Scenes", icon: "rectangle.stack")
            quickActionButton(title: "Structure", icon: "list.number")
            quickActionButton(title: "Context", icon: "person.2")
            quickActionButton(title: "Notes", icon: "note.text")
            quickActionButton(title: "Focus", icon: "eye")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            themeManager.currentTheme.colors.surfaceSecondary.platformResolved
                .asBackground()
        )
    }

    private func quickActionButton(title: String, icon: String) -> some View {
        Button {
            // TODO: Implement quick actions
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func createNewChapter() {
        let newChapter = Card(kind: .chapters, name: "New Chapter", subtitle: "", detailedText: "")
        modelContext.insert(newChapter)

        // Create first scene in chapter
        let firstScene = Card(kind: .scenes, name: "Opening", subtitle: "", detailedText: "")
        modelContext.insert(firstScene)

        // TODO: Link chapter to project
        // TODO: Link scene to chapter
        // TODO: Set scene order

        try? modelContext.save()

        // Set as active
        activeChapterID = newChapter.id
        activeSceneID = firstScene.id
    }

    private func createNewScene() {
        let newScene = Card(kind: .scenes, name: "New Scene", subtitle: "", detailedText: "")
        modelContext.insert(newScene)

        // TODO: Link scene to active chapter
        // TODO: Insert into scene order

        try? modelContext.save()

        // Set as active
        activeSceneID = newScene.id
    }

    private func loadManuscriptContent() {
        // TODO: Build continuous manuscript text from scenes
        // For now, placeholder
        if scenes.isEmpty {
            manuscriptText = "Start writing your story here...\n\nCreate chapters and scenes using the controls above."
        } else {
            manuscriptText = scenes.map { scene in
                let title = scene.name.isEmpty ? "Untitled Scene" : scene.name
                return "# \(title)\n\n\(scene.detailedText)\n\n"
            }.joined()
        }

        // Set first chapter and scene as active
        if activeChapterID == nil, let firstChapter = chapters.first {
            activeChapterID = firstChapter.id
        }
        if activeSceneID == nil, let firstScene = scenes.first {
            activeSceneID = firstScene.id
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, configurations: config)
    let context = container.mainContext

    let project = Card(kind: .projects, name: "The Lantern Chronicles", subtitle: "", detailedText: "")
    context.insert(project)

    // Add sample chapters and scenes
    let chapter1 = Card(kind: .chapters, name: "The Awakening", subtitle: "", detailedText: "")
    context.insert(chapter1)

    let scene1 = Card(kind: .scenes, name: "The Lantern Room", subtitle: "", detailedText: "The old lantern flickered in the darkness...")
    let scene2 = Card(kind: .scenes, name: "Discovery", subtitle: "", detailedText: "She found the ancient tome on the dusty shelf...")
    context.insert(scene1)
    context.insert(scene2)

    return NavigationStack {
        ManuscriptWritingSurfaceView(project: project)
            .modelContainer(container)
            .environmentObject(ThemeManager())
    }
}
