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
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var themeManager: ThemeManager

    // Query for chapters and scenes related to this project
    @Query private var allCards: [Card]

    // State for active chapter and scene
    @State private var activeChapterID: UUID?
    @State private var activeSceneID: UUID?

    // Scene context with potential and confirmed cards
    @State private var sceneContext = SceneContext()

    // Card detail sheet
    @State private var selectedCardForDetail: Card?

    // Chapter creation prompt
    @State private var pendingChapter: Card?

    // Chapter editing
    @State private var editingChapterID: UUID?
    @State private var editingChapterName: String = ""

    // Potential card menu
    @State private var selectedPotentialCard: PotentialCard?
    @State private var showPotentialCardMenu = false

    // Quick action sheets
    @State private var showScenesPanel = false
    @State private var showStructurePanel = false
    @State private var showContextPanel = false
    @State private var showNotesPanel = false
    @State private var showFocusMode = false

    private var chapters: [Card] {
        project.chaptersInProject(modelContext: modelContext)
    }

    private var scenes: [Card] {
        project.scenesInProject(modelContext: modelContext)
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
            // Initialize view (widget-based architecture handles its own loading)
        }
        .sheet(item: $selectedCardForDetail) { card in
            CardSheetView(card: card)
        }
        .confirmationDialog(
            "Create first scene?",
            isPresented: Binding(
                get: { pendingChapter != nil },
                set: { if !$0 { pendingChapter = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Yes, create scene") {
                handleChapterPromptResponse(createScene: true)
            }
            Button("No, just chapter") {
                handleChapterPromptResponse(createScene: false)
            }
        } message: {
            Text("Would you like to create an opening scene for this chapter?")
        }
        .sheet(isPresented: $showPotentialCardMenu) {
            if let potential = selectedPotentialCard {
                potentialCardMenuSheet(for: potential)
                    .presentationBackground {
                        themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground()
                    }
                    .preferredColorScheme(preferredColorScheme)
            }
        }
        .sheet(isPresented: $showScenesPanel) {
            scenesPanel
                .presentationBackground {
                    themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground()
                }
                .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showStructurePanel) {
            structurePanel
        }
        .sheet(isPresented: $showContextPanel) {
            contextPanel
                .presentationBackground {
                    themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground()
                }
                .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showNotesPanel) {
            notesPanel
                .presentationBackground {
                    themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground()
                }
                .preferredColorScheme(preferredColorScheme)
        }
    }

    // MARK: - Quick Action Panels

    private var scenesPanel: some View {
        VStack(spacing: 0) {
            Text("Scenes")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                .padding()

            if scenes.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 48))
                        .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

                    Text("No Scenes Yet")
                        .font(.title3)
                        .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

                    Text("Create a scene to start writing")
                        .font(.body)
                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)

                    Button {
                        createNewScene()
                        showScenesPanel = false
                    } label: {
                        Label("Create Scene", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List(scenes) { scene in
                    HStack {
                        Text(scene.name)
                            .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                        Spacer()
                        if scene.id == activeSceneID {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(themeManager.currentTheme.colors.accentPrimary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        activeSceneID = scene.id
                        sceneContext.activeSceneID = scene.id
                        showScenesPanel = false
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(width: 400, height: 500)
        .background(themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground())
    }

    private var structurePanel: some View {
        StructureSelectionSheet(project: project)
            .frame(width: 800, height: 600)
    }

    private var contextPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scene Context")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                .padding()

            Text("Confirmed Cards")
                .font(.subheadline)
                .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                .padding(.horizontal)

            if sceneContext.confirmedCards.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .font(.system(size: 40))
                        .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
                    Text("No context cards")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List(sceneContext.confirmedCards) { card in
                    HStack {
                        Circle()
                            .fill(colorForKind(card.kind))
                            .frame(width: 8, height: 8)
                        Text(card.name)
                            .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                        Spacer()
                        Text(card.kind.rawValue)
                            .font(.caption)
                            .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(width: 400, height: 500)
        .background(themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground())
    }

    private var notesPanel: some View {
        VStack {
            Text("Scene Notes")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                .padding()

            Text("Notes functionality coming soon...")
                .foregroundStyle(themeManager.currentTheme.colors.textSecondary)

            Spacer()
        }
        .frame(width: 400, height: 500)
        .background(themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground())
    }

    @MainActor
    private func potentialCardMenuSheet(for potential: PotentialCard) -> some View {
        VStack(spacing: 20) {
            Text("Confirm Card")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

            VStack(alignment: .leading, spacing: 12) {
                Text("Name: \(potential.name)")
                Text("Type: \(potential.kind.rawValue)")
                Text("Confidence: \(Int(potential.confidence * 100))%")
            }
            .font(.subheadline)
            .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground())
            .cornerRadius(8)

            VStack(spacing: 12) {
                Button {
                    Task {
                        await confirmPotentialCard(potential, asNewCard: true)
                        showPotentialCardMenu = false
                    }
                } label: {
                    Label("Create New \(potential.kind.rawValue)", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    dismissPotentialCard(potential)
                    showPotentialCardMenu = false
                } label: {
                    Label("Dismiss", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button("Cancel") {
                    showPotentialCardMenu = false
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .frame(width: 400)
        .background(themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground())
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
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 14))
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 10))
                        .offset(x: 4, y: -4)
                }
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                .frame(width: 32, height: 28)
            }
            .buttonStyle(.bordered)
            .help("Create a new chapter")
            .padding(.trailing, 12)
        }
        .frame(height: 44)
        .background {
            themeManager.currentTheme.colors.surfaceSecondary.platformResolved
                .asBackground()
        }
    }

    private func chapterTab(for chapter: Card) -> some View {
        let isActive = activeChapterID == chapter.id
        let isEditing = editingChapterID == chapter.id

        return Group {
            if isEditing {
                // Editing mode - show text field
                TextField("Chapter Name", text: $editingChapterName, onCommit: {
                    saveChapterName(for: chapter)
                })
                .font(.system(size: 13, weight: .semibold))
                .textFieldStyle(.plain)
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground(cornerRadius: 6)
                )
                .onAppear {
                    editingChapterName = chapter.name
                }
            } else {
                // Normal mode - show button
                Button {
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
                .onLongPressGesture {
                    startEditingChapter(chapter)
                }
                .contextMenu {
                    Button("Rename Chapter") {
                        startEditingChapter(chapter)
                    }
                    Button("Delete Chapter", role: .destructive) {
                        deleteChapter(chapter)
                    }
                }
            }
        }
    }

    private func chapterNumber(_ chapter: Card) -> Int {
        (chapters.firstIndex(where: { $0.id == chapter.id }) ?? 0) + 1
    }

    private func scenesInChapter(_ chapter: Card) -> [Card] {
        let repository = CardRepository(modelContext: modelContext)
        return repository.fetchScenesInChapter(chapterID: chapter.id, projectID: project.id)
    }

    private func startEditingChapter(_ chapter: Card) {
        editingChapterID = chapter.id
        editingChapterName = chapter.name
    }

    private func saveChapterName(for chapter: Card) {
        let cardRepo = CardRepository(modelContext: modelContext)
        chapter.name = editingChapterName
        try? cardRepo.save()
        editingChapterID = nil
        editingChapterName = ""
    }

    private func deleteChapter(_ chapter: Card) {
        let cardRepo = CardRepository(modelContext: modelContext)

        // Delete chapter using CardRepository (handles cleanup properly)
        try? cardRepo.deleteCard(chapter)

        // Clear active chapter if it was deleted
        if activeChapterID == chapter.id {
            activeChapterID = chapters.first?.id
        }
    }

    // MARK: - Manuscript Canvas

    private var manuscriptCanvas: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    // Spacer to clear chapter bar
                    Color.clear.frame(height: 60)

                    // Widget-based manuscript text editor
                    if scenes.isEmpty && chapters.isEmpty {
                        // Empty state - no content yet
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 48))
                                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

                            Text("No Scenes Yet")
                                .font(.title2)
                                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

                            Text("Create a chapter and scene to start writing")
                                .font(.body)
                                .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 12) {
                                Button {
                                    createNewChapter()
                                } label: {
                                    Label("Add Chapter", systemImage: "book.closed")
                                }
                                .buttonStyle(.borderedProminent)

                                Button {
                                    createNewScene()
                                } label: {
                                    Label("Add Scene", systemImage: "rectangle.stack")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .frame(maxWidth: 600)
                        .padding(.top, 100)
                    } else {
                        // New widget-based manuscript editor (ER-0056)
                        GeometryReader { geometry in
                            ManuscriptTextEditor(
                                project: project,
                                activeChapterID: $activeChapterID,
                                activeSceneID: $activeSceneID
                            )
                            .frame(
                                minWidth: geometry.size.width,
                                minHeight: 100  // Minimum height for 1 line of text + padding
                            )
                        }
                        .frame(minHeight: 100)  // Ensure GeometryReader itself has minimum height
                    }

                    // Bottom padding to clear Scene Map Instrument and Quick Actions
                    Color.clear.frame(height: 120)
                }
                .onChange(of: activeSceneID) { oldValue, newValue in
                    if let sceneID = newValue {
                        withAnimation {
                            proxy.scrollTo(sceneID, anchor: .top)
                        }
                    }
                }
            }
            .background(themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground())
            // .border(Color.teal, width: 2) // DEBUG - Parent of No Scenes Yet
        }
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

            // Location card (potential or confirmed) - always shown first
            if let confirmedLocation = sceneContext.confirmedLocation {
                confirmedCardCircle(for: confirmedLocation)
            } else if let locationPotential = sceneContext.locationCard {
                potentialCardCircle(for: locationPotential)
            }

            // Divider if we have a location card
            if sceneContext.confirmedLocation != nil || sceneContext.locationCard != nil {
                Divider()
                    .padding(.vertical, 4)
            }

            // Potential cards (sorted by confidence)
            ForEach(sceneContext.sortedPotentialCards.filter { $0.kind != .locations }) { potential in
                potentialCardCircle(for: potential)
            }

            // Confirmed cards (excluding location which is shown at top)
            ForEach(sceneContext.confirmedCards.filter { $0.kind != .locations }) { card in
                confirmedCardCircle(for: card)
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

    /// Potential card circle (greyed out initials or icon, dashed border)
    private func potentialCardCircle(for potential: PotentialCard) -> some View {
        Button {
            handlePotentialCardTap(potential)
        } label: {
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 48, height: 48)

                // Thick colored ring (greyed out)
                Circle()
                    .strokeBorder(potential.indicatorColor.opacity(0.4), lineWidth: 3)
                    .frame(width: 48, height: 48)

                // Initials or icon (greyed out)
                if potential.name.isEmpty || potential.name.lowercased() == "it" || potential.name.lowercased() == "that" {
                    // No name - show icon for kind
                    Image(systemName: potential.kind.systemImage)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.gray.opacity(0.5))
                } else {
                    // Has name - show initials
                    Text(initials(from: potential.name))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.gray.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
        .help("\(potential.name) (potential \(potential.kind.rawValue))")
    }

    /// Confirmed card circle (thumbnail or initials, thick colored border)
    private func confirmedCardCircle(for card: Card) -> some View {
        Button {
            handleConfirmedCardTap(card)
        } label: {
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 48, height: 48)

                // Thick colored ring (kind-specific color, full opacity)
                Circle()
                    .strokeBorder(colorForKind(card.kind), lineWidth: 3)
                    .frame(width: 48, height: 48)

                // Thumbnail or initials
                if let thumbnailData = card.thumbnailData {
                    #if os(macOS)
                    if let nsImage = NSImage(data: thumbnailData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 42, height: 42)
                            .clipShape(Circle())
                    } else {
                        // No valid thumbnail - show initials
                        Text(initials(from: card.name))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(colorForKind(card.kind))
                    }
                    #else
                    if let uiImage = UIImage(data: thumbnailData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 42, height: 42)
                            .clipShape(Circle())
                    } else {
                        // No valid thumbnail - show initials
                        Text(initials(from: card.name))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(colorForKind(card.kind))
                    }
                    #endif
                } else {
                    // No thumbnail - show initials
                    Text(initials(from: card.name))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(colorForKind(card.kind))
                }
            }
        }
        .buttonStyle(.plain)
        .help(card.name)
    }

    private func colorForKind(_ kind: Kinds) -> Color {
        switch kind {
        case .characters: return .blue
        case .artifacts: return .orange
        case .vehicles: return .green
        case .locations: return .purple
        case .buildings: return .brown
        case .chronicles: return .cyan
        default: return .gray
        }
    }

    /// Extract initials from a name (e.g., "John Smith" -> "JS")
    private func initials(from name: String) -> String {
        let words = name.split(separator: " ").map(String.init)

        if words.isEmpty {
            return "?"
        } else if words.count == 1 {
            // Single word - take first two characters
            let word = words[0]
            if word.count >= 2 {
                return String(word.prefix(2)).uppercased()
            } else {
                return word.uppercased()
            }
        } else {
            // Multiple words - take first letter of first two words
            let first = words[0].prefix(1)
            let second = words[1].prefix(1)
            return (String(first) + String(second)).uppercased()
        }
    }

    // MARK: - Scene Map Instrument

    private var sceneMapInstrument: some View {
        HStack(spacing: 8) {
            // Add Scene control
            Button {
                createNewScene()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "film")
                        .font(.system(size: 14))
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 10))
                        .offset(x: 4, y: -4)
                }
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
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
                sceneContext.activeSceneID = scene.id
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
            quickActionButton(title: "Scenes", icon: "rectangle.stack", action: { showScenesPanel = true })
            quickActionButton(title: "Structure", icon: "list.number", action: { showStructurePanel = true })
            quickActionButton(title: "Context", icon: "person.2", action: { showContextPanel = true })
            quickActionButton(title: "Notes", icon: "note.text", action: { showNotesPanel = true })
            quickActionButton(title: "Timeline", icon: "calendar", action: { jumpToTimeline() })
                .disabled(activeSceneID == nil)
            quickActionButton(title: "Focus", icon: "eye", action: { showFocusMode.toggle() })
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            themeManager.currentTheme.colors.surfaceSecondary.platformResolved
                .asBackground()
        )
    }

    private func quickActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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

    /// Jump to timeline view for the active scene
    /// Phase 6: Timeline Integration - Manuscript → Timeline navigation
    private func jumpToTimeline() {
        guard let sceneID = activeSceneID else { return }

        let navigationService = TimelineNavigationService(modelContext: modelContext)
        guard let timeline = navigationService.findPrimaryTimelineForScene(
            sceneID: sceneID,
            projectID: project.id
        ) else {
            // TODO: Show alert or toast that no timeline was found
            print("No timeline found for scene \(sceneID)")
            return
        }

        #if os(macOS) || os(visionOS)
        // Open timeline window with focus on this scene
        let request = AppModel.TimelineViewRequest(
            timelineID: timeline.id,
            focusSceneID: sceneID
        )
        openWindow(value: request)
        #else
        // iOS: Would use NavigationLink push here (requires NavigationStack setup)
        // For now, just log
        print("iOS timeline navigation not yet implemented")
        #endif
    }

    private func createNewChapter() {
        let cardRepo = CardRepository(modelContext: modelContext)
        let edgeRepo = EdgeRepository(modelContext: modelContext)

        // Calculate next chapter number (1-indexed for user-facing display)
        let nextChapterNumber = chapters.count + 1
        let chapterName = "Chapter \(nextChapterNumber)"

        // Create new chapter with proper default name
        guard let newChapter = try? cardRepo.createCard(kind: .chapters, name: chapterName) else {
            return
        }

        // Link chapter to project
        try? edgeRepo.linkChapterToProject(chapter: newChapter, project: project)

        // Save changes immediately so widgets can query the new chapter
        try? cardRepo.save()

        // Set as active chapter
        activeChapterID = newChapter.id

        // Store chapter and prompt user
        pendingChapter = newChapter
    }

    private func handleChapterPromptResponse(createScene: Bool) {
        guard let chapter = pendingChapter else { return }

        if createScene {
            createFirstSceneForChapter(chapter)
        }

        pendingChapter = nil
    }

    private func createFirstSceneForChapter(_ chapter: Card) {
        let cardRepo = CardRepository(modelContext: modelContext)
        let edgeRepo = EdgeRepository(modelContext: modelContext)

        // Calculate chapter number for scene naming
        let chapterNum = chapterNumber(chapter)
        let sceneName = "Chapter \(chapterNum) Opening"

        // Create first scene with chapter-specific name
        guard let firstScene = try? cardRepo.createCard(kind: .scenes, name: sceneName) else {
            return
        }

        // Link scene to chapter and project
        try? edgeRepo.linkSceneToChapter(scene: firstScene, chapter: chapter)
        try? edgeRepo.linkSceneToProject(scene: firstScene, project: project, chapterID: chapter.id)

        // Save changes immediately so widgets can query the new scene
        try? cardRepo.save()

        // Clear scene context for new scene
        sceneContext.clearForNewScene()

        // Auto-create Location potential card
        let locationPotential = PotentialCard(
            kind: .locations,
            name: "Scene Location",
            confidence: 1.0,
            sceneID: firstScene.id,
            detectionSource: .manual
        )
        sceneContext.addPotentialCard(locationPotential)

        // Set as active scene
        activeSceneID = firstScene.id
        sceneContext.activeSceneID = firstScene.id
    }

    private func createNewScene() {
        let cardRepo = CardRepository(modelContext: modelContext)
        let edgeRepo = EdgeRepository(modelContext: modelContext)

        // Create new scene
        guard let newScene = try? cardRepo.createCard(kind: .scenes, name: "New Scene") else {
            return
        }

        // Link scene to active chapter and project
        if let activeChapterID {
            // Link to active chapter
            if let activeChapter = chapters.first(where: { $0.id == activeChapterID }) {
                try? edgeRepo.linkSceneToChapter(scene: newScene, chapter: activeChapter)
                try? edgeRepo.linkSceneToProject(scene: newScene, project: project, chapterID: activeChapterID)
            }
        } else {
            // No active chapter - create orphaned scene
            try? edgeRepo.linkSceneToProject(scene: newScene, project: project)
        }

        // Save changes immediately so widgets can query the new scene
        try? cardRepo.save()

        // Clear scene context for new scene
        sceneContext.clearForNewScene()

        // Auto-create Location potential card
        let locationPotential = PotentialCard(
            kind: .locations,
            name: "Scene Location",
            confidence: 1.0,
            sceneID: newScene.id,
            detectionSource: .manual
        )
        sceneContext.addPotentialCard(locationPotential)

        // Set as active
        activeSceneID = newScene.id
        sceneContext.activeSceneID = newScene.id
    }

    // MARK: - Card Interaction Handlers

    private func handlePotentialCardTap(_ potential: PotentialCard) {
        selectedPotentialCard = potential
        showPotentialCardMenu = true
    }

    @MainActor
    private func confirmPotentialCard(_ potential: PotentialCard, asNewCard: Bool) async {
        let cardRepo = CardRepository(modelContext: modelContext)
        let edgeRepo = EdgeRepository(modelContext: modelContext)

        if asNewCard {
            // Create new card
            if let newCard = try? cardRepo.createCard(
                kind: potential.kind,
                name: potential.name
            ) {
                // Add to confirmed cards
                sceneContext.confirmPotential(potential, asCard: newCard)

                // Link to active scene if exists
                if let activeSceneID,
                   let activeScene = scenes.first(where: { $0.id == activeSceneID }) {
                    // Create appropriate relationship based on kind
                    let relationTypeCode = relationTypeForKind(potential.kind)
                    if let relationType = try? await fetchRelationType(code: relationTypeCode) {
                        try? edgeRepo.createRelationship(from: activeScene, to: newCard, relationType: relationType)
                    }
                }
            }
        }
    }

    private func dismissPotentialCard(_ potential: PotentialCard) {
        sceneContext.dismissPotential(potential)
    }

    private func relationTypeForKind(_ kind: Kinds) -> String {
        switch kind {
        case .characters: return "features/appears-in"
        case .locations: return "set-in/setting-of"
        case .artifacts: return "features/appears-in"
        default: return "related-to/related-to"
        }
    }

    private func fetchRelationType(code: String) async throws -> RelationType? {
        let fetch = FetchDescriptor<RelationType>(
            predicate: #Predicate { $0.code == code }
        )
        return try modelContext.fetch(fetch).first
    }

    private func handleConfirmedCardTap(_ card: Card) {
        selectedCardForDetail = card
    }

    // MARK: - Theme Support

    private var preferredColorScheme: ColorScheme? {
        @AppStorage("AppSettings.colorSchemePreferenceRaw") var colorSchemeRaw: String = "system"

        switch colorSchemeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil // "system" - follow macOS appearance
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
