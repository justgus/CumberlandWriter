//
//  MainAppView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/10/25.
//

import SwiftUI
import SwiftData

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

    // Sidebar and navigation state
    @State private var sidebarSelection: SidebarItem? = .structure
    @State private var searchText = ""

    // Sheets
    @State private var showingCardEditor = false
    @State private var showingSettings = false

    // Three-pane split visibility (keep all visible on macOS by default)
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    // Filtered cards for the current selection + search
    private var filteredCards: [Card] {
        var filtered = cards

        switch sidebarSelection {
        case .kind(let k):
            filtered = filtered.filter { $0.kind == k }
        case .all, .none:
            break
        case .structure:
            // No card grid when in Structure; content is handled separately.
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

        return filtered.sorted { $0.name < $1.name }
    }

    var body: some View {
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
        .sheet(isPresented: $showingCardEditor) {
            NavigationView {
                CardEditorView(mode: .create(kind: currentCreationKind) { _ in
                    showingCardEditor = false
                })
            }
            .frame(minWidth: 560, minHeight: 520)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView()
            }
            .frame(minWidth: 560, minHeight: 420)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCardEditor = true
                } label: {
                    Label("New Card", systemImage: "plus")
                }
                .disabled(isStructureSelected) // New Card doesn’t apply to Structure directly
            }
        }
        .onAppear {
            // Keep all columns visible when the window allows
            columnVisibility = .all
        }
        // Keep the force flag in sync with search mode:
        // When entering search mode, force CardSheetView; when leaving, clear it.
        .onChange(of: searchText) { _, newText in
            if newText.isEmpty {
                navigationCoordinator.clearForce()
            } else {
                navigationCoordinator.forceCardSheetView = true
            }
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
                // Placeholder for your structure UI. Replace with your real Structure view.
                ContentPlaceholderView(
                    title: "Structure",
                    subtitle: "Define and manage story structure for your projects."
                )
                .padding()
            } else {
                if filteredCards.isEmpty {
                    emptyState
                        .padding()
                } else {
                    cardGrid
                }
            }
        }
        // Provide the navigation destination for Card to populate the detail pane
        .navigationDestination(for: Card.self) { card in
            // Routing rules:
            // 1) If we're viewing search results (All + non-empty search) OR the coordinator forces it,
            //    show CardSheetView.
            // 2) Else if Projects is the current kind, show CardRelationshipView.
            // 3) Otherwise, default to CardSheetView.
            if isSearchResultsContext || navigationCoordinator.forceCardSheetView {
                CardSheetView(card: card)
                    .navigationTitle(card.name)
            } else if isProjectsContext {
                CardRelationshipView(primary: card)
                    .navigationTitle("Relationships: \(card.name)")
            } else {
                CardSheetView(card: card)
                    .navigationTitle(card.name)
            }
        }
        .navigationTitle(contentNavigationTitle)
    }

    // MARK: - Detail Column

    private var detailColumn: some View {
        // Default placeholder when no card is selected in the content column.
        // The "default detail" behavior you want is that the standard detail for a card
        // is CardSheetView unless overridden per-kind in navigationDestination above.
        ContentPlaceholderView(
            title: "Select a Card",
            subtitle: "Choose a card from the middle column to see its details.",
            systemImage: "rectangle.and.text.magnifyingglass"
        )
        .padding()
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentPlaceholderView(
            title: searchText.isEmpty ? "No Cards" : "No Results",
            subtitle: searchText.isEmpty
                ? "Create your first card to get started with your creative writing journey."
                : "No cards match your search."
        )
        .overlay(alignment: .bottom) {
            if searchText.isEmpty {
                Button {
                    showingCardEditor = true
                } label: {
                    Label("Create Card", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 12)
            }
        }
    }

    private var cardGrid: some View {
        ScrollView {
            LazyVGrid(columns: adaptiveColumns, spacing: 16) {
                ForEach(filteredCards) { card in
                    NavigationLink(value: card) {
                        CardView(card: card)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 300), spacing: 16)]
    }

    // MARK: - Helpers

    private var isStructureSelected: Bool {
        if case .structure = sidebarSelection { return true }
        return false
    }

    private var isProjectsContext: Bool {
        if case .kind(let k) = sidebarSelection, k == .projects {
            return true
        }
        return false
    }

    private var isSearchResultsContext: Bool {
        if case .all = sidebarSelection, !searchText.isEmpty {
            return true
        }
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
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, configurations: config)

    // Add some sample data
    let context = container.mainContext
    let sample1 = Card(kind: .projects, name: "Sample Project", subtitle: "A test project", detailedText: "This is a sample project for preview purposes.")
    let sample2 = Card(kind: .characters, name: "Ada", subtitle: "The Analyst", detailedText: "Curious and meticulous.")
    context.insert(sample1)
    context.insert(sample2)

    return MainAppView()
        .modelContainer(container)
}

