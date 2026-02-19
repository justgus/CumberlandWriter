//
//  InvestigationDataSource.swift
//  MurderboardApp
//
//  Bridges InvestigationBoard + ModelContext to BoardEngine's BoardDataSource.
//

import SwiftUI
import SwiftData
import BoardEngine

// MARK: - Investigation Node Wrapper

/// Wraps InvestigationNode for BoardNodeRepresentable conformance.
struct InvestigationNodeWrapper: BoardNodeRepresentable {
    let nodeID: UUID
    var posX: Double
    var posY: Double
    var zIndex: Double
    let isPinned: Bool
    let displayName: String
    let subtitle: String
    let categorySystemImage: String
    let isPrimary: Bool
    let category: NodeCategory

    var id: UUID { nodeID }

    func accentColor(for scheme: ColorScheme) -> Color {
        category.defaultColor
    }

    init(from node: InvestigationNode, primaryNodeID: UUID?) {
        self.nodeID = node.id
        self.posX = node.posX
        self.posY = node.posY
        self.zIndex = node.zIndex
        self.isPinned = node.pinned
        self.displayName = node.name
        self.subtitle = node.subtitle
        self.categorySystemImage = node.category.systemImage
        self.isPrimary = (node.id == primaryNodeID)
        self.category = node.category
    }
}

// MARK: - Investigation Edge Wrapper

struct InvestigationEdgeWrapper: BoardEdgeRepresentable {
    let edgeID: UUID
    let sourceNodeID: UUID
    let targetNodeID: UUID
    let typeCode: String
    let createdAt: Date

    var id: UUID { edgeID }

    init(from edge: InvestigationEdge) {
        self.edgeID = edge.id
        self.sourceNodeID = edge.sourceNodeID
        self.targetNodeID = edge.targetNodeID
        self.typeCode = edge.label
        self.createdAt = edge.createdAt
    }
}

// MARK: - Investigation Data Source

@Observable
@MainActor
final class InvestigationDataSource: @MainActor BoardDataSource {
    typealias Node = InvestigationNodeWrapper
    typealias Edge = InvestigationEdgeWrapper

    private(set) var board: InvestigationBoard?
    private let modelContext: ModelContext

    var boardID: UUID {
        board?.id ?? UUID()
    }

    var zoomScale: Double {
        get { board?.zoomScale ?? 1.0 }
        set { board?.zoomScale = newValue }
    }

    var panX: Double {
        get { board?.panX ?? 0.0 }
        set { board?.panX = newValue }
    }

    var panY: Double {
        get { board?.panY ?? 0.0 }
        set { board?.panY = newValue }
    }

    var nodes: [InvestigationNodeWrapper] {
        guard let board = board else { return [] }
        return (board.nodes ?? []).map {
            InvestigationNodeWrapper(from: $0, primaryNodeID: board.primaryNodeID)
        }
    }

    var primaryNodeID: UUID? {
        board?.primaryNodeID
    }

    var onEdgeCreationRequested: ((_ sourceNodeID: UUID, _ targetNodeID: UUID) -> Void)?

    var backlogItems: [InvestigationNodeWrapper] {
        guard let board = board else { return [] }
        let currentBoardID = board.id
        // SQL NULL != X yields NULL (not TRUE), so we must explicitly include orphans
        let fetch = FetchDescriptor<InvestigationNode>(
            predicate: #Predicate<InvestigationNode> { $0.board == nil || $0.board?.id != currentBoardID },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        guard let nodes = try? modelContext.fetch(fetch) else { return [] }
        return nodes.map { InvestigationNodeWrapper(from: $0, primaryNodeID: nil) }
    }

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Board Loading

    func loadOrCreateBoard(name: String) {
        let fetch = FetchDescriptor<InvestigationBoard>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        if let existing = try? modelContext.fetch(fetch).first {
            self.board = existing
            return
        }
        let newBoard = InvestigationBoard(name: name)
        modelContext.insert(newBoard)
        try? modelContext.save()
        self.board = newBoard

        // Seed sample data on first launch
        seedSampleData()
    }

    /// Load a specific board directly (used when board selection is externally managed).
    func loadBoard(_ board: InvestigationBoard) {
        self.board = board
    }

    // MARK: - Sample Data

    /// Populates the board with a realistic investigation scenario on first launch.
    /// Creates 12 nodes (persons, places, clues, events, documents, organizations)
    /// and 14 edges connecting them into a web of relationships.
    func seedSampleData() {
        guard let board = board else { return }
        guard (board.nodes ?? []).isEmpty else { return }

        // --- Persons ---
        let detective = makeNode(
            name: "Det. Sarah Chen", subtitle: "Lead investigator, 15yr veteran",
            category: .person, x: 0, y: 0, board: board)

        let victim = makeNode(
            name: "Marcus Webb", subtitle: "Victim, found at docks 02:14 AM",
            category: .person, x: -320, y: -180, board: board)

        let suspect1 = makeNode(
            name: "Julian Reeves", subtitle: "Business partner, alibi unverified",
            category: .person, x: 320, y: -180, board: board)

        let suspect2 = makeNode(
            name: "Nadia Okafor", subtitle: "Ex-wife, restraining order filed",
            category: .person, x: 320, y: 180, board: board)

        let witness = makeNode(
            name: "Tommy Huang", subtitle: "Dock worker, saw dark sedan at 01:50",
            category: .person, x: -320, y: 180, board: board)

        // --- Places ---
        let crimeScene = makeNode(
            name: "Pier 7 Warehouse", subtitle: "Crime scene, industrial district",
            category: .place, x: -160, y: -360, board: board)

        let office = makeNode(
            name: "Webb & Reeves LLC", subtitle: "Victim's office, files missing",
            category: .place, x: 160, y: -360, board: board)

        // --- Clues ---
        let weapon = makeNode(
            name: "9mm Shell Casing", subtitle: "Found near body, partial print",
            category: .weapon, x: -480, y: -360, board: board)

        let evidence = makeNode(
            name: "Burner Phone", subtitle: "Last call to Reeves, 23:47",
            category: .clue, x: 480, y: 0, board: board)

        // --- Events ---
        let timeline = makeNode(
            name: "Insurance Policy Change", subtitle: "2 weeks before death, $2M policy",
            category: .event, x: 0, y: -360, board: board)

        // --- Documents ---
        let document = makeNode(
            name: "Financial Records", subtitle: "Embezzlement evidence, $800K gap",
            category: .document, x: 0, y: 360, board: board)

        // --- Organizations ---
        let org = makeNode(
            name: "Harbor Freight Co.", subtitle: "Shell company, linked to both suspects",
            category: .organization, x: -480, y: 0, board: board)

        // Set detective as primary
        board.primaryNodeID = detective.id

        // --- Edges (relationships) ---
        makeEdge(from: detective, to: victim, label: "investigating", board: board)
        makeEdge(from: detective, to: suspect1, label: "interrogated", board: board)
        makeEdge(from: detective, to: suspect2, label: "interrogated", board: board)
        makeEdge(from: victim, to: suspect1, label: "business partner", board: board)
        makeEdge(from: victim, to: suspect2, label: "ex-spouse", board: board)
        makeEdge(from: victim, to: crimeScene, label: "found dead at", board: board)
        makeEdge(from: suspect1, to: office, label: "works at", board: board)
        makeEdge(from: suspect1, to: evidence, label: "received call from", board: board)
        makeEdge(from: suspect2, to: org, label: "director of", board: board)
        makeEdge(from: witness, to: crimeScene, label: "witnessed activity at", board: board)
        makeEdge(from: weapon, to: crimeScene, label: "found at", board: board)
        makeEdge(from: timeline, to: victim, label: "policy on", board: board)
        makeEdge(from: timeline, to: suspect1, label: "beneficiary", board: board)
        makeEdge(from: document, to: org, label: "linked to", board: board)

        try? modelContext.save()
    }

    @discardableResult
    private func makeNode(name: String, subtitle: String, category: NodeCategory, x: Double, y: Double, board: InvestigationBoard) -> InvestigationNode {
        let node = InvestigationNode(name: name, subtitle: subtitle, category: category, posX: x, posY: y)
        node.board = board
        node.zIndex = Double((board.nodes?.count ?? 0) + 1)
        modelContext.insert(node)
        return node
    }

    @discardableResult
    private func makeEdge(from source: InvestigationNode, to target: InvestigationNode, label: String, board: InvestigationBoard) -> InvestigationEdge {
        // Edges are global relationships, not board-scoped
        let edge = InvestigationEdge(sourceNodeID: source.id, targetNodeID: target.id, label: label)
        modelContext.insert(edge)
        return edge
    }

    // MARK: - BoardDataSource

    func edges(for nodeIDs: Set<UUID>) -> [InvestigationEdgeWrapper] {
        // Edges are global relationships — show any edge where both endpoints
        // are in the provided set (i.e. both nodes are on the current board).
        let fetch = FetchDescriptor<InvestigationEdge>()
        guard let allEdges = try? modelContext.fetch(fetch) else { return [] }
        return allEdges.filter { nodeIDs.contains($0.sourceNodeID) && nodeIDs.contains($0.targetNodeID) }
            .map { InvestigationEdgeWrapper(from: $0) }
    }

    func moveNode(_ nodeID: UUID, to position: CGPoint) {
        guard let node = findNode(nodeID) else { return }
        node.posX = position.x
        node.posY = position.y
    }

    func commitNodeMove(_ nodeID: UUID) {
        try? modelContext.save()
    }

    func removeNode(_ nodeID: UUID) {
        guard let node = findNode(nodeID) else { return }
        node.board = nil
        try? modelContext.save()
    }

    func addNodes(_ nodeIDs: [UUID], at position: CGPoint) {
        guard let board = board else { return }

        for (index, nodeID) in nodeIDs.enumerated() {
            // Skip nodes already on this board
            if (board.nodes ?? []).contains(where: { $0.id == nodeID }) { continue }

            // Find the node (may be orphaned or on another board)
            let fetch = FetchDescriptor<InvestigationNode>(
                predicate: #Predicate<InvestigationNode> { $0.id == nodeID }
            )
            guard let node = try? modelContext.fetch(fetch).first else { continue }

            // Re-attach to board with angular spread for multiple drops
            node.board = board
            let angle = (Double(index) / Double(max(nodeIDs.count, 1))) * 2.0 * .pi
            let radius = nodeIDs.count > 1 ? 80.0 + Double(index) * 20.0 : 0.0
            node.posX = position.x + cos(angle) * radius
            node.posY = position.y + sin(angle) * radius
            node.zIndex = Double((board.nodes?.count ?? 0) + 1)
        }

        try? modelContext.save()
    }

    func persistTransform() {
        try? modelContext.save()
    }

    func setBacklogFilter(_ filter: String?) {
        // Not applicable in standalone mode
    }

    // MARK: - Node CRUD

    /// Create a new node in the backlog (no board assignment).
    /// The node must be explicitly added to a board via drag or the "Add to Board" action.
    func createNode(name: String, subtitle: String = "", category: NodeCategory) -> InvestigationNode? {
        let node = InvestigationNode(
            name: name,
            subtitle: subtitle,
            category: category,
            colorHex: ""
        )
        // Node starts in backlog — no board assignment
        modelContext.insert(node)
        try? modelContext.save()
        return node
    }

    func createEdge(from sourceID: UUID, to targetID: UUID, label: String) {
        // Edges are global relationships between nodes, not board-scoped
        let edge = InvestigationEdge(
            sourceNodeID: sourceID,
            targetNodeID: targetID,
            label: label
        )
        modelContext.insert(edge)
        try? modelContext.save()
    }

    /// Permanently delete a node and its associated edges from the store.
    func deleteNodePermanently(_ nodeID: UUID) {
        let edgeFetch = FetchDescriptor<InvestigationEdge>(
            predicate: #Predicate<InvestigationEdge> {
                $0.sourceNodeID == nodeID || $0.targetNodeID == nodeID
            }
        )
        if let edges = try? modelContext.fetch(edgeFetch) {
            for edge in edges { modelContext.delete(edge) }
        }
        if let node = findNode(nodeID) ?? fetchOrphanedNode(nodeID) {
            modelContext.delete(node)
        }
        try? modelContext.save()
    }

    /// Set a node as the primary node on the current board.
    func setPrimaryNode(_ nodeID: UUID) {
        board?.primaryNodeID = nodeID
        try? modelContext.save()
    }

    // MARK: - Backlog Support

    /// Fetch backlog nodes as actual model objects (for sidebar drag/detail).
    /// Returns all nodes NOT on the current board (includes orphans and nodes on other boards).
    func fetchBacklogNodes() -> [InvestigationNode] {
        guard let board = board else { return [] }
        let currentBoardID = board.id
        // SQL NULL != X yields NULL (not TRUE), so we must explicitly include orphans
        let fetch = FetchDescriptor<InvestigationNode>(
            predicate: #Predicate<InvestigationNode> { $0.board == nil || $0.board?.id != currentBoardID },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Count edges referencing a given node ID (as source or target).
    func edgeCount(for nodeID: UUID) -> Int {
        let fetch = FetchDescriptor<InvestigationEdge>(
            predicate: #Predicate<InvestigationEdge> {
                $0.sourceNodeID == nodeID || $0.targetNodeID == nodeID
            }
        )
        return (try? modelContext.fetchCount(fetch)) ?? 0
    }

    // MARK: - Helpers

    private func findNode(_ nodeID: UUID) -> InvestigationNode? {
        (board?.nodes ?? []).first(where: { $0.id == nodeID })
    }

    /// Find a node not on any board (orphaned/backlog).
    private func fetchOrphanedNode(_ nodeID: UUID) -> InvestigationNode? {
        let fetch = FetchDescriptor<InvestigationNode>(
            predicate: #Predicate<InvestigationNode> { $0.id == nodeID }
        )
        return try? modelContext.fetch(fetch).first
    }
}
