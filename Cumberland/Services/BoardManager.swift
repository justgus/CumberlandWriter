//
//  BoardManager.swift
//  Cumberland
//
//  Created as part of DR-0104: Service Layer Completion.
//  Centralises Board and BoardNode CRUD operations previously scattered
//  across Board.swift (model helpers), CumberlandBoardDataSource,
//  DeveloperBoardsView, and MurderBoardView.
//

import Foundation
import SwiftData

/// Centralized manager for Board and BoardNode persistence operations.
///
/// **DR-0104**: Absorbs board creation, fetchOrCreate, node management,
/// and deletion logic into a single service.
@Observable
@MainActor
final class BoardManager {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Board CRUD

    /// Create a new Board and persist it.
    @discardableResult
    func createBoard(name: String, primaryCard: Card? = nil) throws -> Board {
        let board = Board(name: name, primaryCard: primaryCard)
        modelContext.insert(board)
        try modelContext.save()
        return board
    }

    /// Delete a Board (cascade deletes all its BoardNodes).
    func deleteBoard(_ board: Board) throws {
        modelContext.delete(board)
        try modelContext.save()
    }

    /// Fetch or create a board whose primaryCard matches the given card.
    /// If found, ensures the primary card has a node on the board.
    /// If not found, creates a new board with an auto-generated name.
    func fetchOrCreatePrimaryBoard(for primary: Card) -> Board {
        let primaryID: UUID? = primary.id
        let fetch = FetchDescriptor<Board>(
            predicate: #Predicate { $0.primaryCard?.id == primaryID },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        if let existing = try? modelContext.fetch(fetch), let board = existing.first {
            board.ensurePrimaryPresence(in: modelContext)
            board.clampState()
            try? modelContext.save()
            return board
        }
        // Create a new board
        let name = "\(primary.name.isEmpty ? primary.kind.singularTitle : primary.name) Board"
        let board = Board(name: name, primaryCard: primary, zoomScale: 1.0, panX: 0, panY: 0)
        modelContext.insert(board)
        board.ensurePrimaryPresence(in: modelContext)
        try? modelContext.save()
        return board
    }

    // MARK: - Node Management

    /// Add a card to a board at a given position. Returns existing node if already present.
    @discardableResult
    func addNode(to board: Board, card: Card, position: (x: Double, y: Double) = (0, 0)) -> BoardNode {
        // Delegate to Board's existing node helper which handles duplicate checks
        if let node = board.node(for: card, in: modelContext, createIfMissing: true, defaultPosition: position) {
            try? modelContext.save()
            return node
        }
        // Fallback — should not reach here since createIfMissing: true
        let node = BoardNode(board: board, card: card, posX: position.x, posY: position.y)
        modelContext.insert(node)
        try? modelContext.save()
        return node
    }

    /// Remove a single BoardNode from its board.
    func removeNode(_ node: BoardNode) throws {
        modelContext.delete(node)
        try modelContext.save()
    }

    /// Toggle the pinned state of a BoardNode.
    func togglePin(for node: BoardNode) throws {
        node.pinned.toggle()
        try modelContext.save()
    }

    // MARK: - Queries

    /// Fetch a board by its primary card.
    func fetchBoard(primaryCard: Card) -> Board? {
        let primaryID: UUID? = primaryCard.id
        let fetch = FetchDescriptor<Board>(
            predicate: #Predicate { $0.primaryCard?.id == primaryID }
        )
        return try? modelContext.fetch(fetch).first
    }

    /// Fetch all boards sorted by name.
    func fetchAllBoards() -> [Board] {
        let fetch = FetchDescriptor<Board>(sortBy: [SortDescriptor(\.name, order: .forward)])
        return (try? modelContext.fetch(fetch)) ?? []
    }
}
