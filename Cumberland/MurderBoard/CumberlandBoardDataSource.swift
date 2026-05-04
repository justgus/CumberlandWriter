//
//  CumberlandBoardDataSource.swift
//  Cumberland
//
//  Observable data source that bridges Cumberland's Board + ModelContext
//  to BoardEngine's BoardDataSource protocol. Used by MurderBoardView
//  to drive BoardEngine's generic canvas, gesture, and layout systems.
//

import SwiftUI
import SwiftData
import BoardEngine

// MARK: - Cumberland Board Data Source

@Observable
@MainActor
final class CumberlandBoardDataSource: @MainActor BoardDataSource {
    typealias Node = CumberlandNode
    typealias Edge = CumberlandEdge

    // Underlying SwiftData models
    private(set) var board: Board?

    // Service managers for repository operations (ER-0022 Phase 2)
    private let boardManager: BoardManager
    private let edgeRepository: EdgeRepository

    // All cards query result (injected by the view)
    var allCards: [Card] = []

    // MARK: - BoardDataSource Protocol

    var boardID: UUID {
        board?.id ?? UUID()
    }

    var zoomScale: Double {
        get { board?.zoomScale ?? 1.0 }
        set {
            board?.zoomScale = newValue.clamped(to: BoardConfiguration.cumberland.minZoom...BoardConfiguration.cumberland.maxZoom)
        }
    }

    var panX: Double {
        get { board?.panX ?? 0.0 }
        set {
            board?.panX = newValue.clamped(to: BoardConfiguration.cumberland.minPan...BoardConfiguration.cumberland.maxPan)
        }
    }

    var panY: Double {
        get { board?.panY ?? 0.0 }
        set {
            board?.panY = newValue.clamped(to: BoardConfiguration.cumberland.minPan...BoardConfiguration.cumberland.maxPan)
        }
    }

    var nodes: [CumberlandNode] {
        guard let board = board else { return [] }
        let primaryCardID = board.primaryCard?.id
        return (board.nodes ?? []).compactMap { boardNode -> CumberlandNode? in
            guard boardNode.card != nil else { return nil }
            return CumberlandNode(from: boardNode, primaryCardID: primaryCardID)
        }
    }

    var primaryNodeID: UUID? {
        board?.primaryCard?.id
    }

    var onEdgeCreationRequested: ((_ sourceNodeID: UUID, _ targetNodeID: UUID) -> Void)?

    var backlogItems: [CumberlandNode] {
        // Not used — Cumberland's sidebar uses its own card-based approach
        []
    }

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.boardManager = BoardManager(modelContext: modelContext)
        self.edgeRepository = EdgeRepository(modelContext: modelContext)
    }

    // MARK: - Board Loading

    /// DR-0104: Use BoardManager for board loading
    func loadBoard(for primary: Card) {
        let b = boardManager.fetchOrCreatePrimaryBoard(for: primary)
        b.clampState()
        self.board = b
    }

    // MARK: - BoardDataSource Methods

    func edges(for nodeIDs: Set<UUID>) -> [CumberlandEdge] {
        // Gather all edges between cards that are on the board
        var result: [CumberlandEdge] = []
        let cards = (board?.nodes ?? []).compactMap { $0.card }
        let cardIDSet = Set(cards.map { $0.id })

        for card in cards where nodeIDs.contains(card.id) {
            // ER-0036: Desync-aware edge query via EdgeRepository
            // If cached count says edges exist but array is empty, fetch via EdgeRepository
            let arrayEdges = card.outgoingEdges ?? []
            let edges: [CardEdge]
            if arrayEdges.isEmpty && card.cachedOutgoingEdgeCount > 0 {
                edges = edgeRepository.fetchOutgoing(from: card)
            } else {
                edges = arrayEdges
            }

            for edge in edges {
                guard let targetID = edge.to?.id, cardIDSet.contains(targetID) else { continue }
                result.append(CumberlandEdge(from: edge))
            }
        }

        return result
    }

    func moveNode(_ nodeID: UUID, to position: CGPoint) {
        guard let boardNode = findBoardNode(for: nodeID) else { return }
        boardManager.updateNodePosition(boardNode, x: position.x, y: position.y)
    }

    func commitNodeMove(_ nodeID: UUID) {
        try? boardManager.save()
    }

    func removeNode(_ nodeID: UUID) {
        guard let boardNode = findBoardNode(for: nodeID) else { return }
        try? boardManager.removeNode(boardNode)
    }

    // MARK: - Pin Management (ER-0031)

    /// Toggle the pinned state of a BoardNode for the given card ID.
    /// Returns the new pinned state, or nil if the card is not on the board.
    @discardableResult
    func togglePin(for cardID: UUID) -> Bool? {
        guard let boardNode = findBoardNode(for: cardID) else { return nil }
        try? boardManager.togglePin(for: boardNode)
        return boardNode.pinned
    }

    /// Set the pinned state explicitly for a given card ID.
    func setPin(for cardID: UUID, pinned: Bool) {
        guard let boardNode = findBoardNode(for: cardID) else { return }
        try? boardManager.setPin(for: boardNode, pinned: pinned)
    }

    func addNodes(_ nodeIDs: [UUID], at position: CGPoint) {
        guard let board = board else { return }

        for (index, cardID) in nodeIDs.enumerated() {
            guard let card = allCards.first(where: { $0.id == cardID }) else { continue }

            // Check if already on board
            let existing = (board.nodes ?? []).first { $0.card?.id == card.id }
            if existing != nil { continue }

            let angle = (Double(index) / Double(nodeIDs.count)) * 2.0 * .pi
            let radius = 100.0 + Double(index) * 20.0
            let x = position.x + cos(angle) * radius
            let y = position.y + sin(angle) * radius

            _ = boardManager.addNode(to: board, card: card, position: (x, y))
        }
    }

    func persistTransform() {
        guard let b = board else { return }
        boardManager.updateBoardTransform(b, zoomScale: b.zoomScale, panX: b.panX, panY: b.panY)
        try? boardManager.save()
    }

    func setBacklogFilter(_ filter: String?) {
        guard let b = board else { return }
        boardManager.updateBacklogFilter(b, filter: filter)
    }

    // MARK: - Helpers

    /// Find the underlying SwiftData BoardNode for a given card ID.
    private func findBoardNode(for cardID: UUID) -> BoardNode? {
        (board?.nodes ?? []).first(where: { $0.card?.id == cardID })
    }
}
