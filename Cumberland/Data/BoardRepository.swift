//
//  BoardRepository.swift
//  Cumberland
//
//  Created as part of DR-0203: Complete ER-0022 Phase 2 Migration
//  Extracted from BoardManager to separate data access from business logic.
//
//  Repository encapsulating SwiftData CRUD operations for Board and BoardNode models.
//  Provides methods to create, fetch, update, and delete boards and nodes.
//  Used by BoardManager service layer for all database operations.
//

import Foundation
import SwiftData

/// Repository for Board and BoardNode data access operations.
/// Encapsulates all SwiftData queries and operations for Board-related models.
///
/// **DR-0203**: Separates data access from business logic for platform independence
@Observable
@MainActor
final class BoardRepository {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Board CRUD Operations

    /// Create a new Board and insert it into the context
    /// - Parameters:
    ///   - name: The board name
    ///   - primaryCard: The primary card for this board
    /// - Returns: The newly created board
    /// - Throws: SwiftData errors
    @discardableResult
    func createBoard(name: String, primaryCard: Card? = nil) throws -> Board {
        let board = Board(name: name, primaryCard: primaryCard)
        modelContext.insert(board)
        try modelContext.save()
        return board
    }

    /// Create a board with full configuration
    /// - Parameters:
    ///   - name: The board name
    ///   - primaryCard: The primary card for this board
    ///   - zoomScale: Initial zoom scale
    ///   - panX: Initial X pan
    ///   - panY: Initial Y pan
    /// - Returns: The newly created board
    /// - Throws: SwiftData errors
    @discardableResult
    func createBoard(name: String, primaryCard: Card?, zoomScale: Double, panX: Double, panY: Double) throws -> Board {
        let board = Board(name: name, primaryCard: primaryCard, zoomScale: zoomScale, panX: panX, panY: panY)
        modelContext.insert(board)
        try modelContext.save()
        return board
    }

    /// Delete a Board (cascade deletes all its BoardNodes via SwiftData deleteRule)
    /// - Parameter board: The board to delete
    /// - Throws: SwiftData errors
    func deleteBoard(_ board: Board) throws {
        modelContext.delete(board)
        try modelContext.save()
    }

    /// Update a board's properties
    /// - Parameters:
    ///   - board: The board to update
    ///   - name: New name (nil = no change)
    ///   - zoomScale: New zoom scale (nil = no change)
    ///   - panX: New X pan (nil = no change)
    ///   - panY: New Y pan (nil = no change)
    ///   - backlogKindRaw: New backlog filter (nil = no change)
    /// - Throws: SwiftData errors
    func updateBoard(
        _ board: Board,
        name: String? = nil,
        zoomScale: Double? = nil,
        panX: Double? = nil,
        panY: Double? = nil,
        backlogKindRaw: String? = nil
    ) throws {
        if let name = name {
            board.name = name
        }
        if let zoomScale = zoomScale {
            board.zoomScale = zoomScale
        }
        if let panX = panX {
            board.panX = panX
        }
        if let panY = panY {
            board.panY = panY
        }
        if let backlogKindRaw = backlogKindRaw {
            board.backlogKindRaw = backlogKindRaw
        }
        try modelContext.save()
    }

    /// Save changes to the context
    /// - Throws: SwiftData errors
    func save() throws {
        try modelContext.save()
    }

    // MARK: - BoardNode CRUD Operations

    /// Create a new BoardNode and insert it into the context
    /// - Parameters:
    ///   - board: The board this node belongs to
    ///   - card: The card this node represents
    ///   - posX: X position
    ///   - posY: Y position
    ///   - pinned: Whether the node is pinned
    /// - Returns: The newly created node
    /// - Throws: SwiftData errors
    @discardableResult
    func createNode(
        board: Board,
        card: Card,
        posX: Double,
        posY: Double,
        pinned: Bool = false
    ) throws -> BoardNode {
        let node = BoardNode(board: board, card: card, posX: posX, posY: posY, pinned: pinned)
        modelContext.insert(node)
        try modelContext.save()
        return node
    }

    /// Delete a BoardNode
    /// - Parameter node: The node to delete
    /// - Throws: SwiftData errors
    func deleteNode(_ node: BoardNode) throws {
        modelContext.delete(node)
        try modelContext.save()
    }

    /// Update a node's properties
    /// - Parameters:
    ///   - node: The node to update
    ///   - posX: New X position (nil = no change)
    ///   - posY: New Y position (nil = no change)
    ///   - pinned: New pinned state (nil = no change)
    /// - Throws: SwiftData errors
    func updateNode(
        _ node: BoardNode,
        posX: Double? = nil,
        posY: Double? = nil,
        pinned: Bool? = nil
    ) throws {
        if let posX = posX {
            node.posX = posX
        }
        if let posY = posY {
            node.posY = posY
        }
        if let pinned = pinned {
            node.pinned = pinned
        }
        try modelContext.save()
    }

    // MARK: - Fetch Operations

    /// Fetch a board by its primary card
    /// - Parameter primaryCard: The primary card to search for
    /// - Returns: The board, or nil if not found
    func fetchBoard(byPrimaryCard primaryCard: Card) -> Board? {
        let primaryID: UUID? = primaryCard.id
        let fetch = FetchDescriptor<Board>(
            predicate: #Predicate { $0.primaryCard?.id == primaryID }
        )
        return try? modelContext.fetch(fetch).first
    }

    /// Fetch all boards sorted by name
    /// - Returns: Array of all boards
    func fetchAllBoards() -> [Board] {
        let fetch = FetchDescriptor<Board>(sortBy: [SortDescriptor(\.name, order: .forward)])
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch a board by its UUID
    /// - Parameter uuid: The board's UUID
    /// - Returns: The board, or nil if not found
    func fetchBoard(byUUID uuid: UUID) -> Board? {
        let fetch = FetchDescriptor<Board>(
            predicate: #Predicate { $0.id == uuid }
        )
        return try? modelContext.fetch(fetch).first
    }
}
