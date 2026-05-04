//
//  BoardManager.swift
//  Cumberland
//
//  Created as part of DR-0104: Service Layer Completion.
//  Refactored for DR-0203: Separated data access (moved to BoardRepository)
//  from business logic (remains here).
//
//  Service layer for Board and BoardNode business logic. Handles board lifecycle,
//  validation, coordinate transformations, and delegates all database operations
//  to BoardRepository.
//

import Foundation
import SwiftData
import BoardEngine

/// Centralized service for Board and BoardNode business logic.
///
/// **DR-0104**: Absorbs board creation, fetchOrCreate, node management logic
/// **DR-0203**: Now uses BoardRepository for all data access (platform independence)
@Observable
@MainActor
final class BoardManager {

    private let modelContext: ModelContext
    private let boardRepository: BoardRepository

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.boardRepository = BoardRepository(modelContext: modelContext)
    }

    // MARK: - Board Operations

    /// Create a new Board and persist it.
    @discardableResult
    func createBoard(name: String, primaryCard: Card? = nil) throws -> Board {
        return try boardRepository.createBoard(name: name, primaryCard: primaryCard)
    }

    /// Delete a Board (cascade deletes all its BoardNodes).
    func deleteBoard(_ board: Board) throws {
        try boardRepository.deleteBoard(board)
    }

    /// Fetch or create a board whose primaryCard matches the given card.
    /// If found, ensures the primary card has a node on the board.
    /// If not found, creates a new board with an auto-generated name.
    ///
    /// **Business Logic**: Auto-naming, primary node presence, state validation
    func fetchOrCreatePrimaryBoard(for primary: Card) -> Board {
        // Try to fetch existing board
        if let existing = boardRepository.fetchBoard(byPrimaryCard: primary) {
            // Business logic: ensure primary card is on the board
            existing.ensurePrimaryPresence(in: modelContext)
            // Business logic: validate and clamp transform state
            existing.clampState()
            try? boardRepository.save()
            return existing
        }

        // Business logic: generate board name based on card
        let name = "\(primary.name.isEmpty ? primary.kind.singularTitle : primary.name) Board"

        // Create new board via repository
        guard let board = try? boardRepository.createBoard(
            name: name,
            primaryCard: primary,
            zoomScale: 1.0,
            panX: 0,
            panY: 0
        ) else {
            // Fallback: create without throwing
            let board = Board(name: name, primaryCard: primary, zoomScale: 1.0, panX: 0, panY: 0)
            modelContext.insert(board)
            board.ensurePrimaryPresence(in: modelContext)
            try? modelContext.save()
            return board
        }

        // Business logic: ensure primary presence after creation
        board.ensurePrimaryPresence(in: modelContext)
        try? boardRepository.save()
        return board
    }

    // MARK: - Node Operations

    /// Add a card to a board at a given position. Returns existing node if already present.
    ///
    /// **Business Logic**: Duplicate detection, fallback node creation
    @discardableResult
    func addNode(to board: Board, card: Card, position: (x: Double, y: Double) = (0, 0)) -> BoardNode {
        // Business logic: check for existing node using Board helper
        if let node = board.node(for: card, in: modelContext, createIfMissing: true, defaultPosition: position) {
            try? boardRepository.save()
            return node
        }

        // Fallback: create directly via repository
        guard let node = try? boardRepository.createNode(
            board: board,
            card: card,
            posX: position.x,
            posY: position.y
        ) else {
            // Final fallback if repository throws
            let node = BoardNode(board: board, card: card, posX: position.x, posY: position.y)
            modelContext.insert(node)
            try? modelContext.save()
            return node
        }

        return node
    }

    /// Remove a single BoardNode from its board.
    func removeNode(_ node: BoardNode) throws {
        try boardRepository.deleteNode(node)
    }

    /// Toggle the pinned state of a BoardNode.
    ///
    /// **Business Logic**: Toggle operation
    func togglePin(for node: BoardNode) throws {
        let newPinned = !node.pinned
        try boardRepository.updateNode(node, pinned: newPinned)
    }

    /// Set the pinned state of a BoardNode explicitly.
    func setPin(for node: BoardNode, pinned: Bool) throws {
        try boardRepository.updateNode(node, pinned: pinned)
    }

    /// Update a BoardNode's position.
    func updateNodePosition(_ node: BoardNode, x: Double, y: Double) {
        node.posX = x
        node.posY = y
    }

    /// Update a Board's transform (zoom and pan).
    ///
    /// **Business Logic**: Validation, clamping to min/max bounds
    func updateBoardTransform(_ board: Board, zoomScale: Double, panX: Double, panY: Double) {
        // Business logic: clamp values to valid ranges
        board.zoomScale = zoomScale.clamped(to: BoardConfiguration.cumberland.minZoom...BoardConfiguration.cumberland.maxZoom)
        board.panX = panX.clamped(to: BoardConfiguration.cumberland.minPan...BoardConfiguration.cumberland.maxPan)
        board.panY = panY.clamped(to: BoardConfiguration.cumberland.minPan...BoardConfiguration.cumberland.maxPan)
        // Business logic: additional validation
        board.clampState()
    }

    /// Update a Board's backlog filter.
    func updateBacklogFilter(_ board: Board, filter: String?) {
        board.backlogKindRaw = filter
    }

    /// Save the current context state.
    func save() throws {
        try boardRepository.save()
    }

    // MARK: - Queries

    /// Fetch a board by its primary card.
    func fetchBoard(primaryCard: Card) -> Board? {
        return boardRepository.fetchBoard(byPrimaryCard: primaryCard)
    }

    /// Fetch all boards sorted by name.
    func fetchAllBoards() -> [Board] {
        return boardRepository.fetchAllBoards()
    }
}
