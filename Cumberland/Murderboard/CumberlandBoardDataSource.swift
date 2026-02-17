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
    private let modelContext: ModelContext

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
        self.modelContext = modelContext
    }

    // MARK: - Board Loading

    func loadBoard(for primary: Card) {
        let b = Board.fetchOrCreatePrimaryBoard(for: primary, in: modelContext)
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
            for edge in (card.outgoingEdges ?? []) {
                guard let targetID = edge.to?.id, cardIDSet.contains(targetID) else { continue }
                result.append(CumberlandEdge(from: edge))
            }
        }

        return result
    }

    func moveNode(_ nodeID: UUID, to position: CGPoint) {
        guard let boardNode = findBoardNode(for: nodeID) else { return }
        boardNode.posX = position.x
        boardNode.posY = position.y
    }

    func commitNodeMove(_ nodeID: UUID) {
        try? modelContext.save()
    }

    func removeNode(_ nodeID: UUID) {
        guard let boardNode = findBoardNode(for: nodeID) else { return }
        modelContext.delete(boardNode)
        try? modelContext.save()
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

            _ = board.node(
                for: card,
                in: modelContext,
                createIfMissing: true,
                defaultPosition: (x, y)
            )
        }

        try? modelContext.save()
    }

    func persistTransform() {
        guard let b = board else { return }
        b.zoomScale = b.zoomScale.clamped(to: BoardConfiguration.cumberland.minZoom...BoardConfiguration.cumberland.maxZoom)
        b.panX = b.panX.clamped(to: BoardConfiguration.cumberland.minPan...BoardConfiguration.cumberland.maxPan)
        b.panY = b.panY.clamped(to: BoardConfiguration.cumberland.minPan...BoardConfiguration.cumberland.maxPan)
        b.clampState()
        try? modelContext.save()
    }

    func setBacklogFilter(_ filter: String?) {
        board?.backlogKindRaw = filter
    }

    // MARK: - Helpers

    /// Find the underlying SwiftData BoardNode for a given card ID.
    private func findBoardNode(for cardID: UUID) -> BoardNode? {
        (board?.nodes ?? []).first(where: { $0.card?.id == cardID })
    }
}
