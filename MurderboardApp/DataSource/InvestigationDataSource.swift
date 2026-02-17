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
final class InvestigationDataSource: BoardDataSource {
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

    var backlogItems: [InvestigationNodeWrapper] { [] }

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
        let edge = InvestigationEdge(sourceNodeID: source.id, targetNodeID: target.id, label: label, board: board)
        modelContext.insert(edge)
        return edge
    }

    // MARK: - BoardDataSource

    func edges(for nodeIDs: Set<UUID>) -> [InvestigationEdgeWrapper] {
        guard let board = board else { return [] }
        let boardID = board.id
        let fetch = FetchDescriptor<InvestigationEdge>(
            predicate: #Predicate { $0.board?.id == boardID }
        )
        guard let allEdges = try? modelContext.fetch(fetch) else { return [] }
        return allEdges.filter { nodeIDs.contains($0.sourceNodeID) || nodeIDs.contains($0.targetNodeID) }
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
        modelContext.delete(node)
        try? modelContext.save()
    }

    func addNodes(_ nodeIDs: [UUID], at position: CGPoint) {
        // In standalone mode, nodes are created directly — this is a no-op
    }

    func persistTransform() {
        try? modelContext.save()
    }

    func setBacklogFilter(_ filter: String?) {
        // Not applicable in standalone mode
    }

    // MARK: - Node CRUD

    func createNode(name: String, subtitle: String = "", category: NodeCategory, at position: CGPoint) -> InvestigationNode? {
        guard let board = board else { return nil }
        let node = InvestigationNode(
            name: name,
            subtitle: subtitle,
            category: category,
            colorHex: "",
            posX: position.x,
            posY: position.y
        )
        node.board = board
        node.zIndex = Double((board.nodes?.count ?? 0) + 1)
        modelContext.insert(node)
        try? modelContext.save()
        return node
    }

    func createEdge(from sourceID: UUID, to targetID: UUID, label: String) {
        guard let board = board else { return }
        let edge = InvestigationEdge(
            sourceNodeID: sourceID,
            targetNodeID: targetID,
            label: label,
            board: board
        )
        modelContext.insert(edge)
        try? modelContext.save()
    }

    // MARK: - Helpers

    private func findNode(_ nodeID: UUID) -> InvestigationNode? {
        (board?.nodes ?? []).first(where: { $0.id == nodeID })
    }
}
