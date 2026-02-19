//
//  MurderBoardRootView.swift
//  MurderboardApp
//
//  Root navigation view hosting a boards list and board detail.
//  Uses NavigationSplitView on iPad/macOS/visionOS and NavigationStack
//  on iPhone. Persists the last-selected board and ensures at least
//  one board exists on first launch (with sample investigation data).
//

import SwiftUI
import SwiftData

struct MurderBoardRootView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage("MurderBoard.lastSelectedBoardID")
    private var lastSelectedBoardIDString: String = ""

    @State private var selectedBoardID: UUID?
    @State private var hasRestoredSelection = false

    @Query(sort: \InvestigationBoard.name, order: .forward)
    private var boards: [InvestigationBoard]

    // MARK: - Body

    var body: some View {
        #if os(macOS) || os(visionOS)
        splitNavigation
        #else
        if UIDevice.current.userInterfaceIdiom == .pad {
            splitNavigation
        } else {
            stackNavigation
        }
        #endif
    }

    // MARK: - NavigationSplitView (iPad / macOS / visionOS)

    private var splitNavigation: some View {
        NavigationSplitView {
            BoardsListView(selectedBoardID: $selectedBoardID)
                .navigationTitle("Boards")
        } detail: {
            detailView
        }
        .onAppear { restoreSelection() }
        .onChange(of: selectedBoardID) { _, newValue in
            persistSelection(newValue)
        }
        .task { ensureAtLeastOneBoard() }
    }

    // MARK: - NavigationStack (iPhone)

    private var stackNavigation: some View {
        NavigationStack {
            BoardsListView(selectedBoardID: $selectedBoardID)
                .navigationTitle("Boards")
                .navigationDestination(item: $selectedBoardID) { boardID in
                    if let board = boards.first(where: { $0.id == boardID }) {
                        InvestigationBoardView(board: board)
                            .navigationTitle(board.name)
                    }
                }
        }
        .onAppear { restoreSelection() }
        .onChange(of: selectedBoardID) { _, newValue in
            persistSelection(newValue)
        }
        .task { ensureAtLeastOneBoard() }
    }

    // MARK: - Detail Pane

    @ViewBuilder
    private var detailView: some View {
        if let board = selectedBoard {
            InvestigationBoardView(board: board)
                .id(board.id)
                .navigationTitle(board.name)
        } else {
            boardPlaceholder
        }
    }

    private var selectedBoard: InvestigationBoard? {
        guard let id = selectedBoardID else { return nil }
        return boards.first(where: { $0.id == id })
    }

    private var boardPlaceholder: some View {
        ContentUnavailableView(
            "Select a Board",
            systemImage: "rectangle.and.text.magnifyingglass",
            description: Text("Choose a board from the list to begin your investigation.")
        )
    }

    // MARK: - Selection Persistence

    private func restoreSelection() {
        guard !hasRestoredSelection else { return }
        hasRestoredSelection = true

        if let uuid = UUID(uuidString: lastSelectedBoardIDString),
           boards.contains(where: { $0.id == uuid }) {
            selectedBoardID = uuid
        } else if let first = boards.first {
            selectedBoardID = first.id
        }
    }

    private func persistSelection(_ id: UUID?) {
        lastSelectedBoardIDString = id?.uuidString ?? ""
    }

    // MARK: - First-Launch Seeding

    private func ensureAtLeastOneBoard() {
        guard boards.isEmpty else { return }
        let ds = InvestigationDataSource(modelContext: modelContext)
        ds.loadOrCreateBoard(name: "My Investigation")
        if let board = ds.board {
            selectedBoardID = board.id
        }
    }
}
