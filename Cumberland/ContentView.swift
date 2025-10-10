//
//  ContentView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/1/25.
//

import SwiftUI
import SwiftData
#if os(iOS)
import PhotosUI
#endif
import UniformTypeIdentifiers
import ImageIO

private let projectsKind: Kinds = .projects

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.name, order: .forward) private var cards: [Card]
    @Environment(SearchRouter.self) private var searchRouter
    @Environment(CardSelectionRouter.self) private var selectionRouter
    @Environment(ProjectSelectionRouter.self) private var projectRouter

    @State private var selectedKind: Kinds? = .projects
    @State private var selectedCard: Card?
    @State private var newCardKind: Kinds?

    // Unified editor for editing existing cards
    @State private var editingCard: Card?

    // iOS: Present SettingsView in a sheet
    #if os(iOS)
    @State private var isShowingSettings: Bool = false
    #endif

    // Query the singleton AppSettings so we can apply global preferences (e.g., color scheme)
    @Query(
        FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.singletonKey == "AppSettingsSingleton" }
        )
    ) private var settingsResults: [AppSettings]
    @State private var appSettings: AppSettings?

    var body: some View {
        @Bindable var selectionRouter = selectionRouter

        Group {
            threeColumnLayout
        }
        .overlay(alignment: .center) {
            if searchRouter.isPresented {
                SearchOverlay(maxResults: 50)
                    .transition(.opacity)
            }
        }
        .sheet(item: $selectionRouter.selectedCard) { (card: Card) in
            CardView(card: card)
        }
        .sheet(item: $newCardKind) { kind in
            CardEditorView(mode: .create(kind: kind) { savedCard in
                selectedKind = kind
                selectedCard = savedCard
                newCardKind = nil
            })
        }
        .sheet(item: $editingCard) { card in
            CardEditorView(mode: .edit(card: card) {
                // Nothing else to do; dismiss handled in editor
                editingCard = nil
            })
        }
        #if os(iOS)
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
        #endif
        .onChange(of: selectedKind) {
            selectedCard = nil
        }
        .onAppear {
            // Ensure a settings object exists so preferences apply at launch
            if let first = settingsResults.first {
                appSettings = first
            } else {
                appSettings = AppSettings.fetchOrCreate(in: modelContext)
            }
        }
        // React to changes in the settings row (e.g., color scheme toggle) and update live
        .task(id: settingsResults.first?.colorSchemePreferenceRaw) {
            appSettings = settingsResults.first ?? appSettings
        }
        // Apply the preferred color scheme from settings (nil = follow system)
        .preferredColorScheme(appSettings?.colorSchemePreference.resolvedColorScheme)
    }

    private var threeColumnLayout: some View {
        NavigationSplitView {
            sidebar
        } content: {
            if selectedKind == .sources {
                // Leave content empty; SourcesView will occupy the detail pane fully.
                ContentPlaceholderView(
                    title: "Sources",
                    subtitle: "Manage your bibliographic sources in the detail pane."
                )
                .navigationTitle("Sources")
            } else {
                contentList
                    .navigationTitle(contentTitle)
                    .toolbar {
                        if let kind = selectedKind, kind != .sources {
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    newCardKind = kind
                                } label: {
                                    Label("New \(kind.title.dropLastIfPluralized())", systemImage: "plus")
                                }
                                .disabled(selectedKind == nil)
                            }

                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    if let card = selectedCard {
                                        editingCard = card
                                    }
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .disabled(selectedCard == nil)
                            }

                            ToolbarItem(placement: .destructiveAction) {
                                Button(role: .destructive) {
                                    if let card = selectedCard {
                                        deleteCards([card])
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .disabled(selectedCard == nil)
                            }

                            #if os(iOS)
                            // iOS-standard entry point for in-app settings
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    isShowingSettings = true
                                } label: {
                                    Label("Settings", systemImage: "gearshape")
                                }
                                .accessibilityLabel("Settings")
                            }
                            #endif
                        }
                    }
            }
        } detail: {
            if selectedKind == .sources {
                SourcesView()
                    .navigationTitle("Sources")
            } else if let card = selectedCard {
                // For Projects, show the relationship map; for others, show the sheet editor.
                if selectedKind == .projects && card.kind == .projects {
                    CardRelationshipView(primary: card)
                        // CardRelationshipView sets its own navigation title; we keep the split view title consistent.
                        .navigationTitle(detailTitle)
                } else {
                    CardSheetView(card: card)
                        .navigationTitle(detailTitle)
                }
            } else if selectedKind != nil {
                ContentPlaceholderView(
                    title: "Select an item",
                    subtitle: "Choose an item from the list to see items."
                )
                .navigationTitle(detailTitle)
            } else {
                ContentPlaceholderView(
                    title: "No selection",
                    subtitle: "Choose a section and an item to see details."
                )
                .navigationTitle(detailTitle)
            }
        }
    }

    private var sidebar: some View {
        List(selection: $selectedKind) {
            ForEach(Kinds.orderedCases) { item in
                Label(item.title, systemImage: item.systemImage)
                    .tag(item as Kinds?)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedKind = item
                    }
            }
        }
        .navigationTitle("Browse")
    }

    // MARK: - Refactored Content List

    private var contentList: some View {
        Group {
            if let kind = selectedKind {
                let items = filteredCards(for: kind)
                if items.isEmpty {
                    ContentPlaceholderView(
                        title: "No \(kind.title) yet",
                        subtitle: "Create a new \(kind.title.dropLastIfPluralized()) to see it here."
                    )
                } else {
                    listView(for: items)
                }
            } else {
                ContentPlaceholderView(
                    title: "Select a section",
                    subtitle: "Choose a section from the list to see items."
                )
            }
        }
    }

    private func filteredCards(for kind: Kinds) -> [Card] {
        guard kind != .sources else { return [] }
        return cards.filter { $0.kind == kind }
    }

    @ViewBuilder
    private func listView(for items: [Card]) -> some View {
        List(selection: $selectedCard) {
            ForEach(items) { card in
                ContentRowView(
                    card: card,
                    isSelected: selectedCard?.id == card.id,
                    onSingleClick: { handleSingleClick(on: card) },
                    onDoubleClick: { handleDoubleClick(on: card) },
                    onRightClick: { handleRightClick(on: card) },
                    onControlClick: { handleRightClick(on: card) },
                    onEdit: { editingCard = card },
                    onDelete: { deleteCards([card]) }
                )
                .tag(card)
            }
            .onDelete { indexSet in
                let toDelete = indexSet.compactMap { idx in
                    items.indices.contains(idx) ? items[idx] : nil
                }
                deleteCards(toDelete)
            }
        }
    }

    // MARK: - Row interaction handlers

    private func handleSingleClick(on card: Card) {
        if selectedCard?.id == card.id {
            selectedCard = nil
        } else {
            selectedCard = card
        }
    }

    private func handleDoubleClick(on card: Card) {
        editingCard = card
    }

    private func handleRightClick(on card: Card) {
        selectedCard = card
    }

    // MARK: - Titles

    private var contentTitle: String {
        selectedKind?.title ?? "Browse"
    }

    private var detailTitle: String {
        if let kind = selectedKind, let card = selectedCard {
            return "\(kind.title): \(card.name)"
        }
        return "Details"
    }

    // MARK: - Helpers

    private func deleteCards(_ cardsToDelete: [Card]) {
        guard !cardsToDelete.isEmpty else { return }

        if let selected = selectedCard, cardsToDelete.contains(where: { $0.id == selected.id }) {
            selectedCard = nil
        }

        for card in cardsToDelete {
            let cardID = card.id
            let fetchEdges = FetchDescriptor<CardEdge>(
                predicate: #Predicate<CardEdge> { edge in
                    edge.from.id == cardID || edge.to.id == cardID
                }
            )
            if let edges = try? modelContext.fetch(fetchEdges) {
                for e in edges {
                    modelContext.delete(e)
                }
            }

            // Delete citations that reference this card
            let fetchCitations = FetchDescriptor<Citation>(
                predicate: #Predicate<Citation> { $0.card.id == cardID }
            )
            if let cites = try? modelContext.fetch(fetchCitations) {
                for c in cites { modelContext.delete(c) }
            }

            card.cleanupBeforeDeletion()
            modelContext.delete(card)
        }

        try? modelContext.save()
    }
}

// MARK: - Row View

private struct ContentRowView: View {
    let card: Card
    let isSelected: Bool
    let onSingleClick: () -> Void
    let onDoubleClick: () -> Void
    let onRightClick: () -> Void
    let onControlClick: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(card.name)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(1)

            let subtitle = card.subtitle
            if !subtitle.isEmpty {
                Text("— \(subtitle)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onDoubleClick() }
        .onTapGesture { onSingleClick() }
        #if os(macOS)
        .simultaneousGesture(
            TapGesture().modifiers(.control).onEnded { onControlClick() }
        )
        #endif
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Detail header thumbnail

private struct DetailHeaderThumbnailView: View {
    let card: Card
    @State private var image: Image?

    var body: some View {
        ZStack {
            if let image {
                image
                    .resizable()
                    .scaledToFit() // Preserve aspect ratio; no cropping
                    .accessibilityLabel("Cover Image")
            } else {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task(id: card.thumbnailData) {
            await load()
        }
        .task {
            if image == nil {
                await load()
            }
        }
    }

    @MainActor
    private func load() async {
        let img = await card.makeThumbnailImage()
        withAnimation(.easeInOut(duration: 0.15)) {
            self.image = img
        }
    }
}

extension String {
    func dropLastIfPluralized() -> String {
        guard hasSuffix("s"), count > 1 else { return self }
        return String(dropLast())
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Card.self, RelationType.self, CardEdge.self, AppSettings.self, Source.self, Citation.self], inMemory: true)
        .environment(SearchRouter())
        .environment(CardSelectionRouter())
        .environment(ProjectSelectionRouter())
}
