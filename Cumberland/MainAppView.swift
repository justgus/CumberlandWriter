//
//  MainAppView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/10/25.
//

import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

struct MainAppView: View {
    @Environment(\.modelContext) private var modelContext

    // Provide a shared navigation coordinator for routing decisions
    @State private var navigationCoordinator = NavigationCoordinator()

    // Sidebar selection supports Structure, All, or a specific Kind.
    private enum SidebarItem: Hashable {
        case structure
        case all
        case kind(Kinds)
    }

    @Query private var cards: [Card]

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

    // Three-pane split visibility (keep all visible on macOS by default)
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

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
            break
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

    var body: some View {
        // Use split view with our own selection state controlling the detail pane.
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } content: {
            contentColumn
        } detail: {
            detailColumn
        }
        .environment(navigationCoordinator) // inject coordinator for all children
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $searchText, prompt: "Search cards…")
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
            NavigationView {
                CardEditorView(mode: .create(kind: currentCreationKind) { _ in
                    showingCardEditor = false
                })
            }
            .frame(minWidth: 760, minHeight: 720)
            .presentationSizing(.fitted)
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
                NavigationView {
                    CardEditorView(mode: .edit(card: card) {
                        showingEditCardEditor = false
                    })
                }
                .frame(minWidth: 760, minHeight: 720)
                .presentationSizing(.fitted)
                #endif
            }
        }
        .sheet(isPresented: $showingSettings) {
            #if os(iOS)
            NavigationStack {
                SettingsView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            #else
            NavigationView {
                SettingsView()
            }
            .frame(minWidth: 560, minHeight: 420)
            .presentationSizing(.fitted)
            #endif
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingCardEditor = true
                } label: {
                    Label("New Card", systemImage: "plus")
                }
                .disabled(isStructureSelected) // New Card doesn’t apply to Structure directly

                Button {
                    showingEditCardEditor = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .disabled(selectedCard == nil)
            }

            // macOS segmented picker can remain at outer level
            #if !os(iOS)
            ToolbarItemGroup(placement: .automatic) {
                if let card = selectedCard, !navigationCoordinator.forceCardSheetView {
                    let tabs = availableTabs(for: card)
                    if !tabs.isEmpty {
                        Picker("Card View", selection: $selectedDetailTab) {
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
        .onAppear {
            // Keep all columns visible when the window allows
            columnVisibility = .all

            // Restore last selection; default to Projects on first launch.
            if sidebarSelection == nil {
                if let restored = deserializeSidebarSelection(from: sidebarSelectionRaw) {
                    sidebarSelection = restored
                } else {
                    sidebarSelection = .kind(.projects)
                    sidebarSelectionRaw = serializeSidebarSelection(sidebarSelection)
                }
            }

            // Initialize the detail tab based on current context
            if let card = selectedCard {
                selectedDetailTab = loadRememberedTab(for: card.kind)
                coerceSelectedTabIfNeeded(for: card)
            } else {
                // No card selected; if we’re scoped to a kind, use that kind’s remembered tab.
                switch sidebarSelection {
                case .kind(let k):
                    selectedDetailTab = loadRememberedTab(for: k)
                default:
                    // Default app-wide startup to Projects’ default (Details)
                    selectedDetailTab = loadRememberedTab(for: .projects)
                }
            }

            // Ensure initial split visibility reflects current selection/focus on iPad
            updateSplitVisibilityForSelection()
        }
        // Persist selection when it changes
        .onChange(of: sidebarSelection) { _, newValue in
            sidebarSelectionRaw = serializeSidebarSelection(newValue)
            // Reset card selection when changing context
            selectedCardID = nil
            // Load remembered tab for the newly selected kind (or default)
            switch newValue {
            case .kind(let k):
                selectedDetailTab = loadRememberedTab(for: k)
            default:
                // For All/Structure use the Projects default as a sensible baseline
                selectedDetailTab = loadRememberedTab(for: .projects)
            }
        }
        // Keep the force flag in sync with search mode:
        // When entering search mode, force CardSheetView; when leaving, clear it.
        .onChange(of: searchText) { _, newText in
            if newText.isEmpty {
                navigationCoordinator.clearForce()
            } else {
                navigationCoordinator.forceCardSheetView = true
            }
            // Clear selection when search text changes to avoid stale detail
            selectedCardID = nil
        }
        // Reset/validate the selected tab when the selected card changes
        .onChange(of: selectedCardID) { _, _ in
            // Update split visibility for iPadOS only
            updateSplitVisibilityForSelection()

            guard let card = selectedCard else {
                // If no card selected, base on current kind context (or projects default)
                switch sidebarSelection {
                case .kind(let k):
                    selectedDetailTab = loadRememberedTab(for: k)
                default:
                    selectedDetailTab = loadRememberedTab(for: .projects)
                }
                return
            }
            // Load remembered tab for this card’s kind and validate
            selectedDetailTab = loadRememberedTab(for: card.kind)
            coerceSelectedTabIfNeeded(for: card)
        }
        // Also revalidate when force mode changes (e.g., leaving search)
        .onChange(of: navigationCoordinator.forceCardSheetView) { _, _ in
            if let card = selectedCard {
                coerceSelectedTabIfNeeded(for: card)
            }
        }
        // Persist any user-initiated tab changes per Kind
        .onChange(of: selectedDetailTab) { _, newValue in
            // Persist the selection for the active Kind context
            if let card = selectedCard {
                rememberTab(newValue, for: card.kind)
            } else {
                // No card selected: remember against the sidebar’s Kind if present; else Projects
                switch sidebarSelection {
                case .kind(let k): rememberTab(newValue, for: k)
                default: rememberTab(newValue, for: .projects)
                }
            }
        }
        // React to Focus Mode toggles (from CardSheetView) to hide/show the content list on iPadOS.
        .onChange(of: isFocusModeEnabled) { _, _ in
            updateSplitVisibilityForSelection()
        }
        .onChange(of: focusModeCardIDRaw) { _, _ in
            updateSplitVisibilityForSelection()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $sidebarSelection) {
            // Structure goes first, as requested (separate from Kinds)
            NavigationLink(value: SidebarItem.structure) {
                Label("Structure", systemImage: Kinds.structure.systemImage)
            }

            NavigationLink(value: SidebarItem.all) {
                Label("All Cards", systemImage: "rectangle.stack")
            }

            Section("Card Types") {
                ForEach(Kinds.orderedCases.filter { $0 != .structure }, id: \.self) { kind in
                    NavigationLink(value: SidebarItem.kind(kind)) {
                        Label(kind.title, systemImage: kind.systemImage)
                    }
                }
            }
        }
        .navigationTitle("Cumberland")
        .listStyle(.sidebar)
    }

    // MARK: - Content Column

    private var contentColumn: some View {
        Group {
            if isStructureSelected {
                // Show the actual structures UI
                StoryStructureView()
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
    }

    // MARK: - Detail Column

    private var detailColumn: some View {
        Group {
            if let card = selectedCard {
                if navigationCoordinator.forceCardSheetView {
                    CardSheetView(card: card)
                        .navigationTitle(card.name)
                } else {
                    switch selectedDetailTab {
                    case .details:
                        CardSheetView(card: card)
                            .navigationTitle(card.name)
                    case .relationships:
                        CardRelationshipView(primary: card)
                            .navigationTitle("Relationships: \(card.name)")
                    case .board:
                        // Board only makes sense for projects; guard just in case.
                        if card.kind == .projects {
                            StructureBoardView(project: card)
                                .navigationTitle("Structure Board: \(card.name)")
                        } else {
                            CardSheetView(card: card)
                                .navigationTitle(card.name)
                        }
                    case .timeline:
                        if card.kind == .timelines {
                            TimelineChartView(timeline: card)
                                .navigationTitle(card.name.isEmpty ? "Timeline" : card.name)
                        } else {
                            CardSheetView(card: card)
                                .navigationTitle(card.name)
                        }
                    }
                }
            } else {
                ContentPlaceholderView(
                    title: "Select a Card",
                    subtitle: "Choose a card from the middle column to see its details.",
                    systemImage: "rectangle.and.text.magnifyingglass"
                )
                .padding()
            }
        }
        // Attach the segmented picker to the DETAIL column’s toolbar on iPadOS so it appears in the right nav bar.
        .toolbar {
            #if os(iOS)
            if let card = selectedCard, !navigationCoordinator.forceCardSheetView {
                let tabs = availableTabs(for: card)
                if !tabs.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Picker("Card View", selection: $selectedDetailTab) {
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
    }

    // MARK: - List of Cards (with thumbnails, deletion)

    private var cardList: some View {
        // Bind selection of the list to our selectedCardID to control the detail pane.
        List(selection: $selectedCardID) {
            ForEach(filteredCards) { card in
                // Selectable row; selection drives detailColumn.
                CardListRow(card: card)
                    .tag(card.id as UUID?)
                // iOS-style swipe-to-delete (all kinds)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteCard(card)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                // macOS and iOS context menu fallback (all kinds)
                .contextMenu {
                    Button {
                        // Start edit for this specific row regardless of selection
                        selectedCardID = card.id
                        showingEditCardEditor = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        deleteCard(card)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            // Enable list’s built-in delete for all kinds shown
            .onDelete(perform: deleteCards(at:))
        }
        .listStyle(.inset)
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

    private struct CardListRow: View {
        let card: Card
        @State private var thumbnailImage: Image?

        private let thumbSize: CGFloat = 40
        // Slightly wider container to preserve aspect ratio while keeping rows aligned
        private let thumbWidth: CGFloat = 60

        // Equatable token for .task(id:) to avoid tuple-Equatable issues on older toolchains
        private struct ThumbnailChangeToken: Equatable {
            let id: UUID
            let count: Int
        }

        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    // Background placeholder/border area
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.quaternary.opacity(0.15))

                    if let thumbnailImage {
                        thumbnailImage
                            .resizable()
                            .scaledToFit() // preserve original aspect ratio
                            .frame(maxWidth: thumbWidth - 4, maxHeight: thumbSize - 4)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    } else {
                        // Subtle placeholder
                        Image(systemName: "photo")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: thumbWidth, height: thumbSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(card.name.isEmpty ? "Untitled" : card.name)
                            .font(.headline)
                            .lineLimit(1)
                        Spacer()
                        Text(card.kind.singularTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !card.subtitle.isEmpty {
                        Text(card.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(.vertical, 4)
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

        // Clean up associated image files/caches first
        card.cleanupBeforeDeletion()
        // Delete the card; cascades remove edges/citations as modeled
        modelContext.delete(card)
        try? modelContext.save()
    }

    // MARK: - Subviews

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
                    showingCardEditor = true
                } label: {
                    Label(createButtonTitle, systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Helpers

    private var isStructureSelected: Bool {
        if case .structure = sidebarSelection { return true }
        return false
    }

    private var currentCreationKind: Kinds {
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
            return searchText.isEmpty
                ? "All Cards (\(cards.count))"
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

#Preview {
    // Empty in-memory container; no sample data seeded.
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, configurations: config)

    return MainAppView()
        .modelContainer(container)
}

