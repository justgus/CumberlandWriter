//
//  MainAppView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/10/25.
//

import SwiftUI
import SwiftData
import Combine

#if os(iOS)
import UIKit
#endif

struct MainAppView: View {
    @Environment(\.modelContext) private var modelContext
    // ER-0022 Phase 4: Service container for dependency injection (optional during migration)
    @Environment(\.services) private var services
    #if os(visionOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(AppModel.self) private var appModel
    #endif

    // Provide a shared navigation coordinator for routing decisions
    @State private var navigationCoordinator = NavigationCoordinator()

    // Sidebar selection supports Structure, All, or a specific Kind.
    private enum SidebarItem: Hashable {
        case structure
        case all
        case kind(Kinds)
    }
    
    // Structure-specific selection state
    @State private var selectedStructureID: UUID? = nil
    
    // Column visibility context for persistence
    private enum ColumnVisibilityContext {
        case kind(Kinds)
        case all
        case structure
    }

    @Query private var cards: [Card]
    @Query(sort: \StoryStructure.name, order: .forward) private var structures: [StoryStructure]

    // Persist/restore last sidebar selection across launches
    @AppStorage("MainSidebarSelection") private var sidebarSelectionRaw: String = ""

    // Sidebar and navigation state
    @State private var sidebarSelection: SidebarItem? = nil
    @State private var searchText = ""

    // Selection-driven split view: the selected card controls the detail pane (by ID to avoid Hashable conformance).
    @State private var selectedCardID: UUID? = nil

    // Sheets
    @State private var showingCardEditor = false
    @State private var showingEditCardEditor = false
    @State private var showingSettings = false
    @State private var showingNewStructureSheet = false
    @State private var showingTemplateSheet = false
    #if DEBUG
    @State private var showingDeveloperBoards = false
    @State private var showingDeveloperTools = false
    #endif

    // ER-0017: Batch image generation
    @State private var isMultiSelectMode = false
    @State private var selectedCardIDs: Set<UUID> = []
    @State private var showingBatchGeneration = false
    @State private var batchGenerationQueue: BatchGenerationQueue?

    // DR-0079/0080/0081: Extended multi-select actions
    @State private var showingDeleteConfirmation = false
    @State private var showingBatchDuplicateConfirmation = false

    // DR-0077: Kind filter for All Cards view
    @State private var allCardsKindFilter: Kinds? = nil

    // DR-0082: Source editor sheet (creates Source + linked Card)
    @State private var showingSourceEditor = false

    // Three-pane split visibility (keep all visible on macOS by default)
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    // Column visibility preferences per card kind
    @AppStorage("ColumnVisibility.projects") private var projectsColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.characters") private var charactersColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.scenes") private var scenesColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.worlds") private var worldsColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.timelines") private var timelinesColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.calendars") private var calendarsColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.chapters") private var chaptersColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.all") private var allColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.structure") private var structureColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.maps") private var mapsColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.locations") private var locationsColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.buildings") private var buildingsColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.vehicles") private var vehiclesColumnVisibility: String = "all"
    @AppStorage("COlumnVisibility.artifacts") private var artifactsColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.chronicles") private var chroniclesColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.rules") private var rulesColumnVisibility: String = "all"
    @AppStorage("ColumnVisibility.sources") private var sourcesColumnVisibility: String = "all"

    // Default to Details (and remember per Kind thereafter)
    @State private var selectedDetailTab: CardDetailTab = .details

    // Observe Focus Mode (toggled inside CardSheetView) so we can collapse content on iOS when active.
    @AppStorage("CardDetailFocusModeEnabled") private var isFocusModeEnabled: Bool = false
    @AppStorage("CardDetailFocusModeCardID") private var focusModeCardIDRaw: String = ""

    // Filtered cards for the current selection + search
    private var filteredCards: [Card] {
        var filtered = cards

        switch sidebarSelection {
        case .kind(let k):
            filtered = filtered.filter { $0.kind == k }
        case .all, .none:
            // DR-0077: Apply kind filter in All Cards view
            if let kindFilter = allCardsKindFilter {
                filtered = filtered.filter { $0.kind == kindFilter }
            }
        case .structure:
            // No card list when in Structure; content is handled separately.
            filtered = []
        }

        if !searchText.isEmpty {
            filtered = filtered.filter { card in
                card.name.localizedCaseInsensitiveContains(searchText) ||
                card.subtitle.localizedCaseInsensitiveContains(searchText) ||
                card.detailedText.localizedCaseInsensitiveContains(searchText) ||
                (card.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Deduplicate by id to avoid showing the same instance twice
        filtered = uniqueByID(filtered)

        return filtered.sorted { $0.name < $1.name }
    }

    // Resolve the selected Card from its ID
    private var selectedCard: Card? {
        guard let id = selectedCardID else { return nil }
        // Prefer filtered list when in a filtered context; fall back to all cards
        return filteredCards.first(where: { $0.id == id }) ?? cards.first(where: { $0.id == id })
    }

    // MARK: - Main Navigation

    private var mainNavigationView: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility
        ) {
            sidebar
        } content: {
            contentColumn
        } detail: {
            detailColumn
        }
    }

    var body: some View {
        navigationWithLifecycle
    }

    private var navigationWithLifecycle: some View {
        navigationWithToolbars
            .onAppear {
                onAppearHandler()
            }
            .onChange(of: sidebarSelection) { _, newValue in
                onSidebarSelectionChange(newValue)
            }
            .onChange(of: searchText) { _, newText in
                onSearchTextChange(newText)
            }
            .onChange(of: selectedCardID) { _, _ in
                onSelectedCardIDChange()
            }
            .onChange(of: navigationCoordinator.forceCardSheetView) { _, _ in
                onForceCardSheetViewChange()
            }
            .onChange(of: selectedDetailTab) { _, newValue in
                onSelectedDetailTabChange(newValue)
            }
            .onChange(of: isFocusModeEnabled) { _, _ in
                updateSplitVisibilityForSelection()
            }
            .onChange(of: focusModeCardIDRaw) { _, _ in
                updateSplitVisibilityForSelection()
            }
            .onChange(of: columnVisibility) { _, newVisibility in
                saveColumnVisibility(newVisibility, for: currentColumnVisibilityContext())
            }
    }

    private var navigationWithToolbars: some View {
        navigationWithSheets
            #if os(visionOS)
            .ornament(attachmentAnchor: .scene(.bottom)) {
                primaryActionsOrnament
            }
            .ornament(attachmentAnchor: .scene(.leading)) {
                settingsOrnament
            }
            #endif
            .modifier(ToolbarViewModifier(mainView: self))
    }

    private var navigationWithEnvironment: some View {
        mainNavigationView
            .environment(navigationCoordinator)
            .navigationSplitViewStyle(.balanced)
        // DR-0077: Removed .searchable() - using custom TextField in list header instead
    }

    private var navigationWithSheets: some View {
        navigationWithEnvironment
            // Create sheet
            .sheet(isPresented: $showingCardEditor) {
            #if os(iOS)
            NavigationStack {
                CardEditorView(mode: .create(kind: currentCreationKind) { _ in
                    showingCardEditor = false
                })
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            #else
            NavigationStack {
                CardEditorView(mode: .create(kind: currentCreationKind) { _ in
                    showingCardEditor = false
                })
            }
            .frame(minWidth: 760, idealWidth: 900, maxWidth: 1200, minHeight: 720)
            #endif
        }
        // Edit sheet
        .sheet(isPresented: $showingEditCardEditor) {
            if let card = selectedCard {
                #if os(iOS)
                NavigationStack {
                    CardEditorView(mode: .edit(card: card) {
                        showingEditCardEditor = false
                    })
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                #else
                NavigationStack {
                    CardEditorView(mode: .edit(card: card) {
                        showingEditCardEditor = false
                    })
                }
                .frame(minWidth: 760, idealWidth: 900, maxWidth: 1200, minHeight: 720)
                #endif
            }
        }
        // DR-0082: Source editor sheet (creates Source + linked Card)
        .sheet(isPresented: $showingSourceEditor) {
            SourceEditorSheet(existingSource: nil) { _ in
                // Source and Card created successfully
            }
            #if os(iOS)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            #else
            .frame(minWidth: 560, idealWidth: 640, maxWidth: 800, minHeight: 600)
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("showSettings"))) { _ in
            showingSettings = true
        }
        .sheet(isPresented: $showingSettings) {
            #if os(iOS)
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showingSettings = false
                            }
                        }
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            #elseif os(visionOS)
            NavigationStack {
                SettingsView()
            }
            .frame(minWidth: 720, minHeight: 640)
            .glassBackgroundEffect()
            #else
            NavigationView {
                SettingsView()
            }
            .frame(minWidth: 560, minHeight: 420)
            .presentationSizing(.fitted)
            #endif
        }
        #if DEBUG
        .sheet(isPresented: $showingDeveloperBoards) {
            #if os(iOS)
            NavigationStack {
                DeveloperBoardsView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            #elseif os(visionOS)
            NavigationStack {
                DeveloperBoardsView()
            }
            .frame(minWidth: 920, minHeight: 560)
            .glassBackgroundEffect()
            #else
            NavigationView {
                DeveloperBoardsView()
            }
            .frame(minWidth: 920, minHeight: 560)
            .presentationSizing(.fitted)
            #endif
        }
        .sheet(isPresented: $showingDeveloperTools) {
            #if os(visionOS)
            NavigationStack {
                DeveloperToolsView()
            }
            .frame(minWidth: 520, minHeight: 480)
            .glassBackgroundEffect()
            #elseif os(iOS)
            NavigationStack {
                DeveloperToolsView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            #else
            NavigationView {
                DeveloperToolsView()
            }
            .frame(minWidth: 520, minHeight: 480)
            .presentationSizing(.fitted)
            #endif
        }
        #endif
        // ER-0017: Batch Image Generation sheet
        .sheet(isPresented: $showingBatchGeneration) {
            if let queue = batchGenerationQueue {
                #if os(iOS)
                NavigationStack {
                    BatchGenerationView(queue: queue)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showingBatchGeneration = false
                                }
                            }
                        }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                #elseif os(visionOS)
                NavigationStack {
                    BatchGenerationView(queue: queue)
                }
                .frame(minWidth: 640, minHeight: 480)
                .glassBackgroundEffect()
                #else
                NavigationView {
                    BatchGenerationView(queue: queue)
                }
                .frame(minWidth: 640, minHeight: 480)
                .presentationSizing(.fitted)
                #endif
            }
        }
        // DR-0080: Delete confirmation dialog
        .confirmationDialog(
            "Delete \(selectedCardIDs.count) Card\(selectedCardIDs.count == 1 ? "" : "s")?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelectedCards()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All selected cards and their relationships will be permanently deleted.")
        }
    }

    // MARK: - Lifecycle Handlers (extracted to fix compiler timeout)

    private func onAppearHandler() {
        // One-time data repair
        DataRepair.repairForeignBoardNodes(in: modelContext)

        // Keep all columns visible when the window allows
        columnVisibility = .all

        // Restore last selection
        if sidebarSelection == nil {
            if let restored = deserializeSidebarSelection(from: sidebarSelectionRaw) {
                sidebarSelection = restored
            } else {
                sidebarSelection = .kind(.projects)
                UserDefaults.standard.set(serializeSidebarSelection(sidebarSelection), forKey: "MainSidebarSelection")
            }
        }

        // Load split position for current context
        loadColumnVisibility(for: currentColumnVisibilityContext())

        // Initialize the detail tab
        if let card = selectedCard {
            selectedDetailTab = loadRememberedTab(for: card.kind)
            coerceSelectedTabIfNeeded(for: card)
        } else {
            switch sidebarSelection {
            case .kind(let k):
                selectedDetailTab = loadRememberedTab(for: k)
            default:
                selectedDetailTab = loadRememberedTab(for: .projects)
            }
        }

        updateSplitVisibilityForSelection()
    }

    private func onSidebarSelectionChange(_ newValue: SidebarItem?) {
        let oldContext = currentColumnVisibilityContext()
        saveColumnVisibility(columnVisibility, for: oldContext)

        UserDefaults.standard.set(serializeSidebarSelection(newValue), forKey: "MainSidebarSelection")
        selectedCardID = nil

        if case .structure = newValue {
            // Entering structure mode
        } else {
            selectedStructureID = nil
        }

        loadColumnVisibility(for: currentColumnVisibilityContext())

        switch newValue {
        case .kind(let k):
            selectedDetailTab = loadRememberedTab(for: k)
        default:
            selectedDetailTab = loadRememberedTab(for: .projects)
        }
    }

    private func onSearchTextChange(_ newText: String) {
        if newText.isEmpty {
            navigationCoordinator.clearForce()
        } else {
            navigationCoordinator.forceCardSheetView = true
        }
        selectedCardID = nil
    }

    private func onSelectedCardIDChange() {
        updateSplitVisibilityForSelection()

        guard let card = selectedCard else {
            switch sidebarSelection {
            case .kind(let k):
                selectedDetailTab = loadRememberedTab(for: k)
            default:
                selectedDetailTab = loadRememberedTab(for: .projects)
            }
            return
        }

        selectedDetailTab = loadRememberedTab(for: card.kind)
        coerceSelectedTabIfNeeded(for: card)
    }

    private func onForceCardSheetViewChange() {
        if let card = selectedCard {
            coerceSelectedTabIfNeeded(for: card)
        }
    }

    private func onSelectedDetailTabChange(_ newValue: CardDetailTab) {
        if let card = selectedCard {
            rememberTab(newValue, for: card.kind)
        } else {
            switch sidebarSelection {
            case .kind(let k): rememberTab(newValue, for: k)
            default: rememberTab(newValue, for: .projects)
            }
        }
    }

    // MARK: - Toolbar ViewModifier

    struct ToolbarViewModifier: ViewModifier {
        let mainView: MainAppView

        func body(content: Content) -> some View {
            content
                #if !os(visionOS)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            // DR-0082: Use specialized editor for Sources
                            if mainView.currentCreationKind == .sources {
                                mainView.showingSourceEditor = true
                            } else {
                                mainView.showingCardEditor = true
                            }
                        } label: {
                            Label("New Card", systemImage: "plus")
                        }
                        .disabled(mainView.isStructureSelected)

                        Button {
                            mainView.showingEditCardEditor = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .disabled(mainView.selectedCard == nil)

                        #if DEBUG
                        Button {
                            mainView.showingDeveloperBoards = true
                        } label: {
                            Label("Developer Boards", systemImage: "wrench.and.screwdriver")
                        }
                        .help("Inspect and repair Boards and BoardNodes")
                        #endif
                    }

                    #if !os(iOS)
                    ToolbarItemGroup(placement: .primaryAction) {
                        if let card = mainView.selectedCard, !mainView.navigationCoordinator.forceCardSheetView {
                            let tabs = mainView.availableTabs(for: card)
                            if !tabs.isEmpty {
                                Picker("Card View", selection: mainView.$selectedDetailTab) {
                                    ForEach(tabs) { tab in
                                        Label(tab.title, systemImage: tab.systemImage)
                                            .tag(tab)
                                            .help(tab.helpText)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 420)
                            }
                        }
                    }
                    #endif
                }
                #endif
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $sidebarSelection) {
            // Structure goes first, as requested (separate from Kinds)
            NavigationLink(value: SidebarItem.structure) {
                Label("Structure", systemImage: Kinds.structure.systemImage)
            }
            #if os(visionOS)
            .accessibilityLabel("Structure view")
            .accessibilityHint("View story structure and organization")
            #endif

            NavigationLink(value: SidebarItem.all) {
                Label("All Cards", systemImage: "rectangle.stack")
            }
            #if os(visionOS)
            .accessibilityLabel("All Cards")
            .accessibilityHint("View all cards across all types")
            #endif

            Section("Card Types") {
                ForEach(Kinds.orderedCases.filter { $0 != .structure }, id: \.self) { kind in
                    NavigationLink(value: SidebarItem.kind(kind)) {
                        Label(kind.title, systemImage: kind.systemImage)
                    }
                    #if os(visionOS)
                    .accessibilityLabel(kind.title)
                    .accessibilityHint("View all \(kind.title.lowercased())")
                    #endif
                }
            }
        }
        .navigationTitle("Cumberland")
        .listStyle(.sidebar)
        #if os(visionOS)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Navigation sidebar")
        #endif
    }

    // MARK: - Content Column

    private var contentColumn: some View {
        Group {
            if isStructureSelected {
                // Show the structure list
                structureList
            } else {
                if filteredCards.isEmpty {
                    emptyState
                        .padding()
                } else {
                    cardList
                }
            }
        }
        .navigationTitle(contentNavigationTitle)
        // DR-0030: Add New Card button to iOS toolbar
        // ER-0017: Add batch image generation toolbar buttons
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isMultiSelectMode {
                    Button {
                        // DR-0082: Use specialized editor for Sources
                        if currentCreationKind == .sources {
                            showingSourceEditor = true
                        } else {
                            showingCardEditor = true
                        }
                    } label: {
                        Label("New Card", systemImage: "plus")
                    }
                    .disabled(isStructureSelected) // New Card doesn't apply to Structure directly
                }
            }
            #endif

            // ER-0017 + DR-0079/0080/0081: Multi-select toolbar buttons (all platforms)
            if !isStructureSelected && !filteredCards.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    if isMultiSelectMode {
                        HStack(spacing: 12) {
                            // DR-0080: Delete selected cards
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .disabled(selectedCardIDs.isEmpty)

                            // DR-0081: Duplicate selected cards
                            Button {
                                duplicateSelectedCards()
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            .disabled(selectedCardIDs.isEmpty)

                            // ER-0017: Generate images for selected cards
                            Button {
                                startBatchGeneration()
                            } label: {
                                Label("Generate Images", systemImage: "wand.and.stars")
                            }
                            .disabled(selectedCardIDs.isEmpty)
                        }
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        toggleMultiSelectMode()
                    } label: {
                        Text(isMultiSelectMode ? "Cancel" : "Select")
                    }
                }
            }
        }
    }

    // MARK: - Detail Column

    private var detailColumn: some View {
        Group {
            if isStructureSelected {
                // Show structure detail when a structure is selected
                structureDetail
            } else if let card = selectedCard {
                if navigationCoordinator.forceCardSheetView {
                    CardSheetView(card: card)
                        .navigationTitle(card.name)
                } else {
                    switch selectedDetailTab {
                    case .details:
                        // Route calendar cards to their specialized detail editor
                        if card.kind == .calendars {
                            CalendarDetailEditor(card: card)
                                .navigationTitle(card.name)
                        } else if card.kind == .sources {
                            // DR-0082: Route source cards to bibliographic editor
                            SourceDetailEditor(card: card)
                                .navigationTitle(card.name)
                        } else {
                            CardSheetView(card: card)
                                .navigationTitle(card.name)
                        }
                    case .relationships:
                        CardRelationshipView(primary: card)
                            .navigationTitle("Relationships: \(card.name)")
                    case .aggregateText:
                        // Visible primarily for Chapters
                        AggregateTextView(card: card)
                            .navigationTitle(card.name.isEmpty ? "Aggregate Text" : "Aggregate: \(card.name)")
                    case .board:
                        // Route by kind:
                        if card.kind == .projects {
                            StructureBoardView(project: card)
                                .navigationTitle("Structure Board: \(card.name)")
                        } else if card.kind == .worlds || card.kind == .characters || card.kind == .scenes {
                            MurderBoardView(primary: card)
                                .id(card.id) // Force recreation when selecting a different card so the board refreshes
                                .navigationTitle("\(card.name.isEmpty ? card.kind.singularTitle : card.name) Board")
                        } else {
                            CardSheetView(card: card)
                                .navigationTitle(card.name)
                        }
                    case .timeline:
                        if card.kind == .timelines {
                            TimelineChartView(timeline: card)
                                .navigationTitle(card.name.isEmpty ? "Timeline" : card.name)
                        } else if card.kind == .calendars {
                            if let calendarSystem = card.calendarSystemRef {
                                MultiTimelineGraphView(calendarSystem: calendarSystem)
                                    .navigationTitle(card.name.isEmpty ? "Multi-Timeline" : card.name)
                            } else {
                                ContentPlaceholderView(
                                    title: "No Calendar System",
                                    subtitle: "This calendar card needs a calendar system to display the multi-timeline graph.",
                                    systemImage: "exclamationmark.triangle"
                                )
                                .padding()
                            }
                        } else {
                            CardSheetView(card: card)
                                .navigationTitle(card.name)
                        }
                    case .mapWizard:
                        if card.kind == .maps {
                            MapWizardView(card: card)
                                .navigationTitle("Map Wizard: \(card.name)")
                        } else {
                            CardSheetView(card: card)
                                .navigationTitle(card.name)
                        }
                    case .citations:
                        // DR-0082: Citation management for all card types
                        CitationViewer(card: card)
                            .navigationTitle("Citations: \(card.name)")
                    }
                }
            } else {
                ContentPlaceholderView(
                    title: isStructureSelected ? "Select a Structure" : "Select a Card",
                    subtitle: isStructureSelected ? "Choose a structure from the middle column to see its details." : "Choose a card from the middle column to see its details.",
                    systemImage: isStructureSelected ? "list.number" : "rectangle.and.text.magnifyingglass"
                )
                .padding()
            }
        }
        #if os(visionOS)
        // visionOS: Detail tab picker ornament
        .ornament(attachmentAnchor: .scene(.top)) {
            detailTabPickerOrnament
        }
        #endif

        #if !os(visionOS)

        // Attach the segmented picker to the DETAIL column's toolbar on iPadOS so it appears in the right nav bar.
        .toolbar {
            #if os(iOS)
            if let card = selectedCard, !navigationCoordinator.forceCardSheetView {
                let tabs = availableTabs(for: card)
                if !tabs.isEmpty {
                    // Use .principal placement so the picker occupies the full center of the
                    // navigation bar rather than being squeezed into the trailing area.
                    // Wrapped in a horizontal ScrollView so all segments remain accessible
                    // even on narrow screens where the full segmented control won't fit.
                    ToolbarItem(placement: .principal) {
                        Picker("Card View", selection: $selectedDetailTab) {
                            ForEach(tabs) { tab in
                                Image(systemName: tab.systemImage)
                                    .tag(tab)
                                    .help(tab.helpText)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            #endif
        }
        #endif
    }

    // MARK: - Card list

    private var cardList: some View {
        // ER-0017: In multi-select mode, don't use List selection - handle taps manually
        // In single-select mode, use standard List selection binding
        List(selection: isMultiSelectMode ? .constant(Set<UUID>()) : Binding(
            get: { selectedCardID.map { Set([$0]) } ?? [] },
            set: { selectedCardID = $0.first }
        )) {
            // DR-0077: Inline search header for all card lists (filter dropdown only for All Cards)
            Section {
                EmptyView()
            } header: {
                cardsListHeader
            }

            ForEach(filteredCards) { card in
                // Selectable row; selection drives detailColumn.
                HStack {
                    // ER-0017: Show selection indicator in multi-select mode
                    if isMultiSelectMode {
                        Image(systemName: selectedCardIDs.contains(card.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedCardIDs.contains(card.id) ? .blue : .secondary)
                            .imageScale(.large)
                    }
                    CardListRow(card: card)
                }
                .tag(card.id)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isMultiSelectMode {
                        // Toggle selection in multi-select mode
                        withAnimation {
                            if selectedCardIDs.contains(card.id) {
                                selectedCardIDs.remove(card.id)
                            } else {
                                selectedCardIDs.insert(card.id)
                            }
                        }
                    } else {
                        // Normal single selection
                        selectedCardID = card.id
                    }
                }
                // iOS-style swipe-to-delete (all kinds)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteCard(card)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    #if os(visionOS)
                    .accessibilityLabel("Delete \(card.name.isEmpty ? "card" : card.name)")
                    #endif
                }
                // macOS and iOS context menu fallback (all kinds)
                .contextMenu {
                    #if os(visionOS)
                    // Phase 4: Enhanced context menu with better hierarchy for spatial interaction
                    Section {
                        Button {
                            selectedCardID = card.id
                            #if os(visionOS)
                            openEditCardWindow()
                            #else
                            showingEditCardEditor = true
                            #endif
                        } label: {
                            Label("Edit Card", systemImage: "pencil")
                        }
                        
                        Button {
                            selectedCardID = card.id
                        } label: {
                            Label("View Details", systemImage: "doc.text.magnifyingglass")
                        }
                    }
                    
                    Section {
                        // DR-0081: Duplicate card action
                        Button {
                            duplicateCard(card)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            deleteCard(card)
                        } label: {
                            Label("Delete Card", systemImage: "trash")
                        }
                    }
                    #else
                    // macOS/iOS: Context menu with Edit, Duplicate, Delete
                    Button {
                        // Start edit for this specific row regardless of selection
                        selectedCardID = card.id
                        showingEditCardEditor = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    // DR-0081: Single-card duplicate
                    Button {
                        duplicateCard(card)
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    Divider()
                    Button(role: .destructive) {
                        deleteCard(card)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    #endif
                }
            }
            // Enable list’s built-in delete for all kinds shown
            .onDelete(perform: deleteCards(at:))
        }
        .listStyle(.inset)
        #if os(visionOS)
        // Phase 4: Better list accessibility
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Card list")
        .accessibilityHint("Select a card to view its details")
        #endif
        #if os(macOS)
        // Support Delete key on macOS to delete the selected item
        .onDeleteCommand {
            guard let id = selectedCardID,
                  let card = cards.first(where: { $0.id == id }) else { return }
            deleteCard(card)
            // Clear selection after deletion
            selectedCardID = nil
        }
        #endif
    }

    // MARK: - Structure list and detail

    private var structureList: some View {
        List(selection: $selectedStructureID) {
            ForEach(structures) { structure in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(structure.name)
                            .font(.callout)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Text("\((structure.elements ?? []).count) elements")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .tag(structure.id as UUID?)
                .contentShape(Rectangle())
            }
            .onDelete(perform: deleteStructures)
        }
        .listStyle(.inset)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu("Add Structure", systemImage: "plus") {
                    Button("Custom Structure") {
                        showingNewStructureSheet = true
                    }
                    Button("From Template") {
                        showingTemplateSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewStructureSheet) {
            NewStructureSheet()
        }
        .sheet(isPresented: $showingTemplateSheet) {
            StructureTemplateSheet()
        }
        .onAppear {
            // Auto-select the first structure if nothing is selected
            if selectedStructureID == nil, let first = structures.first {
                selectedStructureID = first.id
            }
        }
        .onChange(of: selectedStructureID) { _, _ in
            // Clear card selection when a structure is selected
            selectedCardID = nil
        }
    }

    private var structureDetail: some View {
        Group {
            if let structure = structures.first(where: { $0.id == selectedStructureID }) {
                StructureDetailView(structure: structure)
            } else {
                ContentPlaceholderView(
                    title: "Select a Structure",
                    subtitle: "Choose a story structure to view and edit its elements.",
                    systemImage: "list.number"
                )
                .padding()
            }
        }
    }

    // MARK: - Deletion helpers

    private func deleteCards(at offsets: IndexSet) {
        let toDelete = filteredCards
            .enumerated()
            .filter { offsets.contains($0.offset) }
            .map { $0.element }

        // If the currently shown detail is among the deletions, clear the detail by resetting selection.
        if let currentID = selectedCardID, toDelete.contains(where: { $0.id == currentID }) {
            selectedCardID = nil
        }

        for card in toDelete {
            deleteCard(card)
        }
        // Clear selection after batch delete
        selectedCardID = nil
    }

    private func deleteCard(_ card: Card) {
        // If this card is currently shown in detail, clear the detail first
        if let currentID = selectedCardID, currentID == card.id {
            selectedCardID = nil
        }

        // ER-0022 Phase 4: Use CardOperationManager if available
        if let services = services {
            try? services.cardOperations.deleteCard(card)
        } else {
            // Fallback: Direct modelContext operation (legacy path)
            card.cleanupBeforeDeletion(in: modelContext)
            modelContext.delete(card)
            try? modelContext.save()
        }
    }

    private func deleteStructures(offsets: IndexSet) {
        withAnimation {
            let toDelete = offsets.map { structures[$0] }
            // Clear selection if we are deleting the selected structure
            if let sel = selectedStructureID, toDelete.contains(where: { $0.id == sel }) {
                selectedStructureID = nil
            }

            for item in toDelete {
                modelContext.delete(item)
            }
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete structures: \(error)")
            }
        }
    }

    // MARK: - Subviews

    // DR-0077: Inline search and filter header for card lists
    private var cardsListHeader: some View {
        HStack(spacing: 8) {
            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)

                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)

                // Clear button when there's text
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
            )

            // Filter dropdown menu (only for All Cards view)
            if case .all = sidebarSelection {
                Menu {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            allCardsKindFilter = nil
                        }
                    } label: {
                        if allCardsKindFilter == nil {
                            Label("All Types", systemImage: "checkmark")
                        } else {
                            Text("All Types")
                        }
                    }

                    Divider()

                    ForEach(Kinds.orderedCases.filter { $0 != .structure }, id: \.self) { kind in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                allCardsKindFilter = kind
                            }
                        } label: {
                            if allCardsKindFilter == kind {
                                Label(kind.title, systemImage: "checkmark")
                            } else {
                                Label(kind.title, systemImage: kind.systemImage)
                            }
                        }
                    }
                } label: {
                    Image(systemName: allCardsKindFilter != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .imageScale(.large)
                        .foregroundStyle(allCardsKindFilter != nil ? Color.accentColor : .secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
        .padding(.vertical, 4)
        .textCase(nil) // Prevent uppercase transformation
    }

    private var emptyState: some View {
        // Determine if we are scoped to a specific kind
        let selectedKind: Kinds? = {
            if case .kind(let k) = sidebarSelection { return k }
            return nil
        }()

        // Title and subtitle vary based on search and selected kind
        let title: String = {
            if searchText.isEmpty {
                if let k = selectedKind {
                    return "No \(k.title)"
                } else {
                    return "No Cards"
                }
            } else {
                return "No Results"
            }
        }()

        let subtitle: String = {
            if searchText.isEmpty {
                if let k = selectedKind {
                    return "Create your first \(k.singularTitle.lowercased()) to get started."
                } else {
                    return "Create your first card to get started with your creative writing journey."
                }
            } else {
                if let k = selectedKind {
                    return "No \(k.title.lowercased()) match your search."
                } else {
                    return "No cards match your search."
                }
            }
        }()

        // Create button title adapts to selected kind
        let createButtonTitle: String = {
            if let k = selectedKind {
                return "Create \(k.singularTitle)"
            } else {
                return "Create Card"
            }
        }()

        return ContentPlaceholderView(
            title: title,
            subtitle: subtitle
        )
        .overlay(alignment: .bottom) {
            if searchText.isEmpty {
                Button {
                    #if os(visionOS)
                    openNewCardWindow()
                    #else
                    // DR-0082: Use specialized editor for Sources
                    if currentCreationKind == .sources {
                        showingSourceEditor = true
                    } else {
                        showingCardEditor = true
                    }
                    #endif
                } label: {
                    Label(createButtonTitle, systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Helpers

    #if os(visionOS)
    // MARK: - visionOS Ornaments
    
    private var primaryActionsOrnament: some View {
        
#if DEBUG
        PrimaryActionsOrnament(
            onNewCard: { openNewCardWindow() },
            onEditCard: { openEditCardWindow() },
            onRefresh: {
                // Basic refresh: clear search and reselect current sidebar item to trigger view updates
                if !searchText.isEmpty { searchText = "" }
                // Optionally, nudge state to force list refresh
                selectedCardID = selectedCardID
            },
            canEdit: selectedCard != nil,
            isStructureSelected: isStructureSelected,
            onDeveloperBoards: { showingDeveloperBoards = true }
        )
#else
        PrimaryActionsOrnament(
            onNewCard: { openNewCardWindow() },
            onEditCard: { openEditCardWindow() },
            onRefresh: {
                if !searchText.isEmpty { searchText = "" }
                selectedCardID = selectedCardID
            },
            canEdit: selectedCard != nil,
            isStructureSelected: isStructureSelected
        )
#endif
    }
    
    private var settingsOrnament: some View {
        VStack(spacing: 12) {
            SettingsOrnament(
                onSettings: { showingSettings = true }, onDismiss: { showingSettings = false }
            )
            
            #if DEBUG
            DeveloperToolsOrnament(
                onDeveloperTools: { showingDeveloperTools = true }
            )
            #endif
        }
    }
    
    private var detailTabPickerOrnament: some View {
        Group {
            if let card = selectedCard, !navigationCoordinator.forceCardSheetView {
                let tabs = availableTabs(for: card)
                if !tabs.isEmpty {
                    DetailTabPickerOrnament(
                        tabs: tabs,
                        selectedTab: $selectedDetailTab
                    )
                }
            }
        }
    }
    #endif

    private var isStructureSelected: Bool {
        if case .structure = sidebarSelection { return true }
        return false
    }

    var currentCreationKind: Kinds {
        switch sidebarSelection {
        case .kind(let k): return k
        default: return .projects
        }
    }

    private var contentNavigationTitle: String {
        switch sidebarSelection {
        case .structure:
            return "Structure"
        case .kind(let k):
            return k.title
        case .all:
            // DR-0077: Simplified title - filter is now inline in list header
            return searchText.isEmpty
                ? "All Cards (\(filteredCards.count))"
                : "Search Results (\(filteredCards.count))"
        case .none:
            return "Cumberland"
        }
    }

    // Deduplicate helper
    private func uniqueByID(_ input: [Card]) -> [Card] {
        var seen = Set<UUID>()
        var result: [Card] = []
        result.reserveCapacity(input.count)
        for c in input {
            if seen.insert(c.id).inserted {
                result.append(c)
            }
        }
        return result
    }

    // MARK: - Batch Operations (ER-0017 + DR-0079/0080/0081)

    private func toggleMultiSelectMode() {
        withAnimation {
            isMultiSelectMode.toggle()
            if !isMultiSelectMode {
                // Exiting multi-select mode - clear selection
                selectedCardIDs.removeAll()
            }
        }
    }

    // DR-0080: Delete selected cards
    private func deleteSelectedCards() {
        let cardsToDelete = filteredCards.filter { selectedCardIDs.contains($0.id) }

        guard !cardsToDelete.isEmpty else {
            print("⚠️ No cards selected for deletion")
            return
        }

        // If the currently shown detail is among the deletions, clear the detail
        if let currentID = selectedCardID, selectedCardIDs.contains(currentID) {
            selectedCardID = nil
        }

        // Use CardOperationManager if available
        if let services = services {
            do {
                try services.cardOperations.deleteCards(cardsToDelete)
                print("✅ Deleted \(cardsToDelete.count) cards")
            } catch {
                print("❌ Failed to delete cards: \(error)")
            }
        } else {
            // Fallback: Direct modelContext operation (legacy path)
            for card in cardsToDelete {
                card.cleanupBeforeDeletion(in: modelContext)
                modelContext.delete(card)
            }
            try? modelContext.save()
        }

        // Exit multi-select mode and clear selection
        withAnimation {
            isMultiSelectMode = false
            selectedCardIDs.removeAll()
        }
    }

    // DR-0081: Duplicate selected cards
    private func duplicateSelectedCards() {
        let cardsToDuplicate = filteredCards.filter { selectedCardIDs.contains($0.id) }

        guard !cardsToDuplicate.isEmpty else {
            print("⚠️ No cards selected for duplication")
            return
        }

        // Use CardOperationManager if available
        if let services = services {
            for card in cardsToDuplicate {
                do {
                    let duplicate = try services.cardOperations.duplicateCard(card)
                    print("✅ Duplicated '\(card.name)' → '\(duplicate.name)'")
                } catch {
                    print("❌ Failed to duplicate '\(card.name)': \(error)")
                }
            }
        } else {
            // Fallback: Manual duplication (legacy path)
            for card in cardsToDuplicate {
                let duplicate = Card(
                    kind: card.kind,
                    name: "\(card.name) (Copy)",
                    subtitle: card.subtitle,
                    detailedText: card.detailedText
                )
                if let originalImageData = card.originalImageData {
                    try? duplicate.setOriginalImageData(originalImageData)
                }
                duplicate.epochDate = card.epochDate
                duplicate.epochDescription = card.epochDescription
                modelContext.insert(duplicate)
            }
            try? modelContext.save()
        }

        // Exit multi-select mode and clear selection
        withAnimation {
            isMultiSelectMode = false
            selectedCardIDs.removeAll()
        }
    }

    // DR-0081: Duplicate a single card (for context menu)
    private func duplicateCard(_ card: Card) {
        if let services = services {
            do {
                let duplicate = try services.cardOperations.duplicateCard(card)
                print("✅ Duplicated '\(card.name)' → '\(duplicate.name)'")
                // Optionally select the new card
                selectedCardID = duplicate.id
            } catch {
                print("❌ Failed to duplicate '\(card.name)': \(error)")
            }
        } else {
            // Fallback: Manual duplication
            let duplicate = Card(
                kind: card.kind,
                name: "\(card.name) (Copy)",
                subtitle: card.subtitle,
                detailedText: card.detailedText
            )
            if let originalImageData = card.originalImageData {
                try? duplicate.setOriginalImageData(originalImageData)
            }
            duplicate.epochDate = card.epochDate
            duplicate.epochDescription = card.epochDescription
            modelContext.insert(duplicate)
            try? modelContext.save()
            // Select the new card
            selectedCardID = duplicate.id
        }
    }

    private func startBatchGeneration() {
        // Get the selected cards
        let cardsToGenerate = filteredCards.filter { selectedCardIDs.contains($0.id) }

        guard !cardsToGenerate.isEmpty else {
            print("⚠️ No cards selected for batch generation")
            return
        }

        // Initialize queue if needed and set provider
        if batchGenerationQueue == nil {
            batchGenerationQueue = BatchGenerationQueue(modelContext: modelContext)
        }

        // Set the provider to the user's preferred image generation provider
        let selectedProvider = AISettings.shared.imageGenerationProvider
        print("🔧 Starting batch generation with provider: '\(selectedProvider)'")
        print("🔧 Selected \(cardsToGenerate.count) cards: \(cardsToGenerate.map { $0.name }.joined(separator: ", "))")

        batchGenerationQueue?.provider = selectedProvider

        // Reset queue and add cards
        batchGenerationQueue?.reset()
        batchGenerationQueue?.addCards(cardsToGenerate)

        // Start generation automatically
        Task { @MainActor in
            await batchGenerationQueue?.start()
        }

        // Show the batch generation view
        showingBatchGeneration = true

        // Exit multi-select mode
        isMultiSelectMode = false
        selectedCardIDs.removeAll()
    }

    // MARK: - Detail tabs helpers

    private func availableTabs(for card: Card) -> [CardDetailTab] {
        CardDetailTab.allowedTabs(for: card.kind)
    }

    private func coerceSelectedTabIfNeeded(for card: Card) {
        let coerced = CardDetailTab.coerce(selectedDetailTab, for: card.kind)
        if coerced != selectedDetailTab {
            selectedDetailTab = coerced
        }
    }

    // MARK: - Remembered tab persistence (UserDefaults)

    private func tabKey(for kind: Kinds) -> String {
        "DetailTab.\(kind.rawValue)"
    }

    private func rememberTab(_ tab: CardDetailTab, for kind: Kinds) {
        let key = tabKey(for: kind)
        UserDefaults.standard.set(tab.rawValue, forKey: key)
    }

    private func loadRememberedTab(for kind: Kinds) -> CardDetailTab {
        let key = tabKey(for: kind)
        let raw = UserDefaults.standard.string(forKey: key)
        let desired = CardDetailTab.from(raw: raw, default: .details)
        return CardDetailTab.coerce(desired, for: kind)
    }

    // MARK: - Sidebar selection persistence

    private func serializeSidebarSelection(_ item: SidebarItem?) -> String {
        guard let item else { return "" }
        switch item {
        case .structure:
            return "structure"
        case .all:
            return "all"
        case .kind(let k):
            return "kind:\(k.rawValue)"
        }
    }

    private func deserializeSidebarSelection(from raw: String) -> SidebarItem? {
        guard !raw.isEmpty else { return nil }
        if raw == "structure" { return .structure }
        if raw == "all" { return .all }
        if raw.hasPrefix("kind:") {
            let rawKind = String(raw.dropFirst("kind:".count))
            if let k = Kinds(rawValue: rawKind) {
                return .kind(k)
            }
        }
        return nil
    }

    // MARK: - Column visibility management
    
    private func loadColumnVisibility(for context: ColumnVisibilityContext) {
        let visibilityString: String
        switch context {
        case .kind(.projects):
            visibilityString = projectsColumnVisibility
        case .kind(.characters):
            visibilityString = charactersColumnVisibility
        case .kind(.scenes):
            visibilityString = scenesColumnVisibility
        case .kind(.worlds):
            visibilityString = worldsColumnVisibility
        case .kind(.timelines):
            visibilityString = timelinesColumnVisibility
        case .kind(.calendars):
            visibilityString = calendarsColumnVisibility
        case .kind(.chapters):
            visibilityString = chaptersColumnVisibility
        case .all:
            visibilityString = allColumnVisibility
        case .structure:
            visibilityString = structureColumnVisibility
        case .kind(.maps):
            visibilityString = mapsColumnVisibility
        case .kind(.locations):
            visibilityString = locationsColumnVisibility
        case .kind(.buildings):
            visibilityString = buildingsColumnVisibility
        case .kind(.vehicles):
            visibilityString = vehiclesColumnVisibility
        case .kind(.artifacts):
            visibilityString = artifactsColumnVisibility
        case .kind(.chronicles):
            visibilityString = chroniclesColumnVisibility
        case .kind(.rules):
            visibilityString = rulesColumnVisibility
        case .kind(.sources):
            visibilityString = sourcesColumnVisibility
        case .kind(.structure):
            visibilityString = structureColumnVisibility
        }
        columnVisibility = parseColumnVisibility(from: visibilityString)
    }

    private func saveColumnVisibility(_ visibility: NavigationSplitViewVisibility, for context: ColumnVisibilityContext) {
        let visibilityString = serializeColumnVisibility(visibility)
        switch context {
        case .kind(.projects):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.projects")
        case .kind(.characters):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.characters")
        case .kind(.scenes):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.scenes")
        case .kind(.worlds):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.worlds")
        case .kind(.timelines):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.timelines")
        case .kind(.calendars):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.calendars")
        case .kind(.chapters):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.chapters")
        case .all:
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.all")
        case .structure:
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.structure")
        case .kind(.maps):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.maps")
        case .kind(.locations):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.locations")
        case .kind(.buildings):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.buildings")
        case .kind(.vehicles):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.vehicles")
        case .kind(.artifacts):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.artifacts")
        case .kind(.chronicles):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.chronicles")
        case .kind(.rules):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.rules")
        case .kind(.sources):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.sources")
        case .kind(.structure):
            UserDefaults.standard.set(visibilityString, forKey: "ColumnVisibility.structure")
        }
    }
    
    private func currentColumnVisibilityContext() -> ColumnVisibilityContext {
        switch sidebarSelection {
        case .kind(let k):
            return .kind(k)
        case .all:
            return .all
        case .structure:
            return .structure
        case .none:
            return .all // Default fallback
        }
    }
    
    private func serializeColumnVisibility(_ visibility: NavigationSplitViewVisibility) -> String {
        switch visibility {
        case .all:
            return "all"
        case .doubleColumn:
            return "doubleColumn"
        case .detailOnly:
            return "detailOnly"
        default:
            return "all"
        }
    }
    
    private func parseColumnVisibility(from string: String) -> NavigationSplitViewVisibility {
        switch string {
        case "all":
            return .all
        case "doubleColumn":
            return .doubleColumn
        case "detailOnly":
            return .detailOnly
        default:
            return .all
        }
    }

    // MARK: - Card Editor Window Management (visionOS Phase 2)
    
    #if os(visionOS)
    /// Opens a new card editor in a floating window (visionOS only)
    private func openCardEditorWindow(mode: AppModel.CardEditorRequest.Mode) {
        let request = AppModel.CardEditorRequest(mode: mode)
        openWindow(value: request)
    }
    
    /// Opens a card creation window for the current kind
    private func openNewCardWindow() {
        openCardEditorWindow(mode: .create(kind: currentCreationKind))
    }
    
    /// Opens a card edit window for the selected card
    private func openEditCardWindow() {
        guard let card = selectedCard else { return }
        openCardEditorWindow(mode: .edit(cardID: card.id))
    }
    #endif

    // MARK: - iPadOS split visibility behavior

    private func updateSplitVisibilityForSelection() {
        #if os(iOS)
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            // When Focus Mode is enabled for the currently selected card, hide both sidebar and content
            if isFocusModeEnabled,
               let selID = selectedCardID,
               focusModeCardIDRaw == selID.uuidString {
                columnVisibility = .detailOnly
            } else if selectedCardID != nil {
                // Keep content + detail visible; hide only the sidebar
                columnVisibility = .doubleColumn
            } else {
                // No selection: show all three columns
                columnVisibility = .all
            }
        }
        #endif
    }
}

private struct CardListRow: View {
    let card: Card
    @State private var thumbnailImage: Image?

    #if os(visionOS)
    // Phase 4: Larger tap targets for spatial input (gaze/pinch)
    private let thumbSize: CGFloat = 52
    private let thumbWidth: CGFloat = 78
    private let verticalPadding: CGFloat = 10
    private let cornerRadius: CGFloat = 8
    #else
    private let thumbSize: CGFloat = 40
    // Slightly wider container to preserve aspect ratio while keeping rows aligned
    private let thumbWidth: CGFloat = 60
    private let verticalPadding: CGFloat = 4
    private let cornerRadius: CGFloat = 6
    #endif

    // Equatable token for .task(id:) to avoid tuple-Equatable issues on older toolchains
    private struct ThumbnailChangeToken: Equatable {
        let id: UUID
        let count: Int
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                // Background placeholder/border area (use Color-based approximation for cross-toolchain compatibility)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))

                if let thumbnailImage {
                    thumbnailImage
                        .resizable()
                        .scaledToFit() // preserve original aspect ratio
                        .frame(maxWidth: thumbWidth - 4, maxHeight: thumbSize - 4)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius - 1, style: .continuous))
                } else {
                    // Subtle placeholder
                    Image(systemName: "photo")
                        #if os(visionOS)
                        .font(.body)
                        #else
                        .font(.caption2)
                        #endif
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: thumbWidth, height: thumbSize)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(card.name.isEmpty ? "Untitled" : card.name)
                        #if os(visionOS)
                        .font(.title3) // Larger, more comfortable for spatial reading
                        #else
                        .font(.headline)
                        #endif
                        .lineLimit(1)
                    Spacer()
                    Text(card.kind.singularTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        #if os(visionOS)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.secondary.opacity(0.15))
                        )
                        #endif
                }
                if !card.subtitle.isEmpty {
                    Text(card.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, verticalPadding)
        #if os(visionOS)
        // Phase 4: Enhanced hover effect for spatial comfort
        .hoverEffect(.highlight)
        .contentShape(Rectangle()) // Ensure entire row area is tappable
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.name.isEmpty ? "Untitled" : card.name), \(card.kind.singularTitle)")
        .accessibilityHint("Double tap to view details")
        #endif
        // Initial load and subsequent refreshes when the image changes.
        // Use a stable change token so the task re-runs when thumbnailData changes.
        .task(id: ThumbnailChangeToken(id: card.id, count: card.thumbnailData?.count ?? 0)) {
            let img = await card.makeThumbnailImage()
            // Animate small updates for polish; nil when no image
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.15)) {
                    thumbnailImage = img
                }
            }
        }
    }
}

#Preview {
// Empty in-memory container; no sample data seeded.
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try! ModelContainer(for: Card.self, configurations: config)

MainAppView()
    .modelContainer(container)
}
