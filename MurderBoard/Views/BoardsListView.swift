//
//  BoardsListView.swift
//  MurderboardApp
//
//  Scrollable list of all InvestigationBoards with CRUD operations.
//  Supports create, rename, and delete with confirmation. Selection
//  is owned by the parent view (MurderBoardRootView) via binding.
//

import SwiftUI
import SwiftData

struct BoardsListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \InvestigationBoard.name, order: .forward)
    private var boards: [InvestigationBoard]

    @Binding var selectedBoardID: UUID?

    // MARK: - Rename State

    @State private var showingRenameAlert = false
    @State private var boardToRename: InvestigationBoard?
    @State private var renameText: String = ""

    // MARK: - Delete State

    @State private var showingDeleteConfirmation = false
    @State private var boardToDelete: InvestigationBoard?

    // MARK: - Body

    var body: some View {
        List(selection: $selectedBoardID) {
            ForEach(boards) { board in
                BoardRowView(board: board)
                    .tag(board.id)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            boardToDelete = board
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(boards.count <= 1)
                    }
                    .contextMenu {
                        Button {
                            beginRename(board)
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            boardToDelete = board
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(boards.count <= 1)
                    }
            }
        }
        .listStyle(.inset)
        .overlay {
            if boards.isEmpty {
                ContentUnavailableView(
                    "No Boards",
                    systemImage: "square.stack.3d.up.slash",
                    description: Text("Tap + to create your first investigation board.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Board", systemImage: "plus") {
                    createBoard()
                }
            }
        }
        .confirmationDialog(
            "Delete Board?",
            isPresented: $showingDeleteConfirmation,
            presenting: boardToDelete
        ) { board in
            Button("Delete \"\(board.name)\"", role: .destructive) {
                deleteBoard(board)
            }
            Button("Cancel", role: .cancel) {
                boardToDelete = nil
            }
        } message: { board in
            let count = board.nodes?.count ?? 0
            Text("This will permanently delete \"\(board.name)\" and its \(count) node(s). The action cannot be undone.")
        }
        .alert("Rename Board", isPresented: $showingRenameAlert) {
            TextField("Board name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                commitRename()
            }
        } message: {
            Text("Enter a new name for this board.")
        }
    }

    // MARK: - CRUD

    private func createBoard() {
        let board = InvestigationBoard(name: "Untitled Board")
        modelContext.insert(board)
        try? modelContext.save()
        selectedBoardID = board.id
    }

    private func beginRename(_ board: InvestigationBoard) {
        boardToRename = board
        renameText = board.name
        showingRenameAlert = true
    }

    private func commitRename() {
        guard let board = boardToRename, !renameText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        board.name = renameText.trimmingCharacters(in: .whitespaces)
        try? modelContext.save()
        boardToRename = nil
    }

    private func deleteBoard(_ board: InvestigationBoard) {
        guard boards.count > 1 else { return }

        // If deleting the currently selected board, select the next available
        if selectedBoardID == board.id {
            let remaining = boards.filter { $0.id != board.id }
            selectedBoardID = remaining.first?.id
        }

        modelContext.delete(board)
        try? modelContext.save()
        boardToDelete = nil
    }
}
