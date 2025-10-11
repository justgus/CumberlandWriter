// MainAppView.swift
import SwiftUI
import SwiftData

struct MainAppView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchRouter = SearchRouter()
    @State private var navigationCoordinator = NavigationCoordinator()
    @State private var searchEngine: SearchEngine?
    
    // Navigation state
    @State private var selectedKind: Kinds? = .projects
    @State private var selectedCard: Card?
    
    #if os(macOS)
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    #else
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    #endif
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            SidebarView(
                selectedKind: $selectedKind,
                selectedCard: $selectedCard
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } content: {
            // Content (list of cards for selected kind)
            if let kind = selectedKind {
                KindDetailView(
                    kind: kind,
                    selectedCard: $selectedCard
                )
                .navigationSplitViewColumnWidth(min: 300, ideal: 400)
            } else {
                EmptyKindView()
                    .navigationSplitViewColumnWidth(min: 300, ideal: 400)
            }
        } detail: {
            // Detail view (card details or relationship view)
            DetailView(
                selectedKind: selectedKind,
                selectedCard: selectedCard,
                forceCardSheetView: navigationCoordinator.forceCardSheetView
            )
            .navigationSplitViewColumnWidth(min: 400, ideal: 600)
        }
        .environment(searchRouter)
        .environment(navigationCoordinator)
        .onAppear {
            setupSearchIntegration()
            // Load sample data if needed
            Task {
                await SampleDataProvider.createSampleData(in: modelContext)
            }
        }
        .onChange(of: navigationCoordinator.selectedKind) { _, newKind in
            if let kind = newKind {
                selectedKind = kind
            }
        }
        .onChange(of: navigationCoordinator.selectedCard) { _, newCard in
            selectedCard = newCard
        }
        .onChange(of: selectedKind) { _, newKind in
            navigationCoordinator.selectedKind = newKind
        }
        .onChange(of: selectedCard) { _, newCard in
            navigationCoordinator.selectedCard = newCard
        }
        .overlay {
            if searchRouter.isPresented {
                SearchOverlay(maxResults: 50)
                    .zIndex(1000)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    searchRouter.toggle()
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .help("Search all cards (⌘F)")
                .keyboardShortcut("f", modifiers: .command)
            }
        }
        .searchable(text: .constant(""), isPresented: $searchRouter.isPresented) {
            // Empty search suggestions - we handle search in overlay
        }
    }
    
    private func setupSearchIntegration() {
        let engine = SearchEngine(modelContext: modelContext)
        searchEngine = engine
        searchRouter.setSearchEngine(engine)
        navigationCoordinator.setSearchRouter(searchRouter)
    }
}

// MARK: - Sidebar View

private struct SidebarView: View {
    @Binding var selectedKind: Kinds?
    @Binding var selectedCard: Card?
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        List(selection: $selectedKind) {
            Section {
                ForEach(Kinds.orderedCases) { kind in
                    NavigationLink(value: kind) {
                        Label(kind.title, systemImage: kind.systemImage)
                            .foregroundStyle(kind.accentColor(for: scheme))
                    }
                }
            } header: {
                Text("Card Types")
                    .font(.headline)
            }
        }
        .navigationTitle("Cumberland")
        .onChange(of: selectedKind) { _, _ in
            // Clear card selection when kind changes
            selectedCard = nil
        }
    }
}

// MARK: - Kind Detail View

private struct KindDetailView: View {
    let kind: Kinds
    @Binding var selectedCard: Card?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    
    @Query private var cards: [Card]
    
    init(kind: Kinds, selectedCard: Binding<Card?>) {
        self.kind = kind
        self._selectedCard = selectedCard
        
        // Create predicate for the specific kind
        let kindRaw = kind.rawValue
        self._cards = Query(
            filter: #Predicate<Card> { $0.kindRaw == kindRaw },
            sort: [SortDescriptor(\Card.name, order: .forward)]
        )
    }
    
    var body: some View {
        List(selection: $selectedCard) {
            ForEach(cards) { card in
                NavigationLink(value: card) {
                    CardRowView(card: card)
                }
            }
        }
        .navigationTitle(kind.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    createNewCard()
                } label: {
                    Label("Add \(kind.title.dropLastIfPluralized())", systemImage: "plus")
                }
                .help("Create a new \(kind.title.dropLastIfPluralized())")
            }
        }
    }
    
    private func createNewCard() {
        let newCard = Card(
            kind: kind,
            name: "New \(kind.title.dropLastIfPluralized())",
            subtitle: "",
            detailedText: ""
        )
        modelContext.insert(newCard)
        try? modelContext.save()
        selectedCard = newCard
    }
}

// MARK: - Empty Kind View

private struct EmptyKindView: View {
    var body: some View {
        ContentUnavailableView(
            "Select a Card Type",
            systemImage: "sidebar.left",
            description: Text("Choose a card type from the sidebar to get started")
        )
    }
}

// MARK: - Detail View

private struct DetailView: View {
    let selectedKind: Kinds?
    let selectedCard: Card?
    let forceCardSheetView: Bool
    
    var body: some View {
        Group {
            if let card = selectedCard {
                if forceCardSheetView {
                    // Force CardSheetView (from search results)
                    CardSheetView(card: card)
                } else {
                    // Use default view for the kind
                    defaultDetailView(for: card)
                }
            } else if let kind = selectedKind {
                // Show kind overview when no specific card is selected
                KindOverviewView(kind: kind)
            } else {
                // No selection
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Select a card type and then a specific card to view details")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func defaultDetailView(for card: Card) -> some View {
        switch card.kind {
        case .projects:
            // Projects default to relationship view
            CardRelationshipView(primary: card)
        case .sources:
            // Sources could default to citation view if available
            CardSheetView(card: card)
        case .structure:
            // Structure might have a special story structure view
            CardSheetView(card: card)
        default:
            // Most other kinds default to the sheet view
            CardSheetView(card: card)
        }
    }
}

// MARK: - Card Row View

private struct CardRowView: View {
    let card: Card
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(card.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if !card.subtitle.isEmpty {
                    Text(card.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            if !card.detailedText.isEmpty {
                Text(card.detailedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Kind Overview View

private struct KindOverviewView: View {
    let kind: Kinds
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    
    @Query private var cards: [Card]
    
    init(kind: Kinds) {
        self.kind = kind
        
        let kindRaw = kind.rawValue
        self._cards = Query(
            filter: #Predicate<Card> { $0.kindRaw == kindRaw },
            sort: [SortDescriptor(\Card.name, order: .forward)]
        )
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                VStack(spacing: 12) {
                    Image(systemName: kind.systemImage)
                        .font(.system(size: 48))
                        .foregroundStyle(kind.accentColor(for: scheme))
                    
                    Text(kind.title)
                        .font(.largeTitle).bold()
                    
                    Text("\(cards.count) \(cards.count == 1 ? kind.title.dropLastIfPluralized().lowercased() : kind.title.lowercased())")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                Divider()
                    .padding(.horizontal)
                
                if cards.isEmpty {
                    ContentUnavailableView(
                        "No \(kind.title)",
                        systemImage: kind.systemImage,
                        description: Text("Create your first \(kind.title.dropLastIfPluralized().lowercased()) to get started")
                    )
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent \(kind.title)")
                            .font(.title2).bold()
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(cards.prefix(6)) { card in
                                CardOverviewTile(card: card)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle(kind.title)
        .background(kind.backgroundColor(for: scheme).opacity(0.05))
    }
}

// MARK: - Card Overview Tile

private struct CardOverviewTile: View {
    let card: Card
    
    @Environment(\.colorScheme) private var scheme
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    
    var body: some View {
        Button {
            navigationCoordinator?.navigateToCard(card)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: card.kind.systemImage)
                        .font(.title3)
                        .foregroundStyle(card.kind.accentColor(for: scheme))
                    
                    Spacer()
                }
                
                Text(card.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if !card.subtitle.isEmpty {
                    Text(card.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding()
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(card.kind.accentColor(for: scheme).opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

extension String {
    func dropLastIfPluralized() -> String {
        if self.count > 1 && self.hasSuffix("s") {
            return String(self.dropLast())
        }
        return self
    }
}