// InvestigationDataSourceTests.swift
// MurderBoardTests

import Testing
import SwiftData
import Foundation
@testable import MurderBoard

@Suite("InvestigationDataSource Tests", .serialized)
struct InvestigationDataSourceTests {

    @MainActor
    private func makeDataSource() throws -> (InvestigationDataSource, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: InvestigationBoard.self, InvestigationNode.self, InvestigationEdge.self,
            configurations: config
        )
        let ctx = container.mainContext
        let ds = InvestigationDataSource(modelContext: ctx)
        return (ds, ctx)
    }

    // MARK: - Board Loading

    @Test("loadOrCreateBoard creates new when none exists")
    @MainActor
    func loadOrCreateBoardCreatesNew() async throws {
        let (ds, _) = try makeDataSource()
        ds.loadOrCreateBoard(name: "My Investigation")

        #expect(ds.board != nil)
        #expect(ds.board?.name == "My Investigation")
    }

    @Test("loadOrCreateBoard returns existing on repeat")
    @MainActor
    func loadOrCreateBoardReturnsExisting() async throws {
        let (ds, _) = try makeDataSource()
        ds.loadOrCreateBoard(name: "Investigation A")
        let firstID = ds.board?.id

        ds.loadOrCreateBoard(name: "Investigation B")
        let secondID = ds.board?.id

        // Should return the existing board, not create a new one
        #expect(firstID == secondID)
    }

    @Test("loadOrCreateBoard seeds sample data on first creation")
    @MainActor
    func loadOrCreateBoardSeeds() async throws {
        let (ds, _) = try makeDataSource()
        ds.loadOrCreateBoard(name: "New Case")

        let nodeCount = (ds.board?.nodes ?? []).count
        #expect(nodeCount > 0)
    }

    // MARK: - Seed Data

    @Test("seedSampleData creates 12 nodes")
    @MainActor
    func seedSampleDataCreates12Nodes() async throws {
        let (ds, _) = try makeDataSource()
        ds.loadOrCreateBoard(name: "Test Case")

        let nodeCount = (ds.board?.nodes ?? []).count
        #expect(nodeCount == 12)
    }

    @Test("seedSampleData creates 14 edges")
    @MainActor
    func seedSampleDataCreates14Edges() async throws {
        let (ds, ctx) = try makeDataSource()
        ds.loadOrCreateBoard(name: "Test Case")

        let allEdges = try ctx.fetch(FetchDescriptor<InvestigationEdge>())
        #expect(allEdges.count == 14)
    }

    @Test("seedSampleData sets detective as primary")
    @MainActor
    func seedSampleDataSetsPrimary() async throws {
        let (ds, _) = try makeDataSource()
        ds.loadOrCreateBoard(name: "Test Case")

        #expect(ds.board?.primaryNodeID != nil)
        // The primary node should be the detective
        let primaryNode = (ds.board?.nodes ?? []).first(where: { $0.id == ds.board?.primaryNodeID })
        #expect(primaryNode?.name == "Det. Sarah Chen")
    }

    // MARK: - Nodes and Edges Properties

    @Test("nodes returns wrapped nodes for current board")
    @MainActor
    func nodesReturnsWrapped() async throws {
        let (ds, _) = try makeDataSource()
        ds.loadOrCreateBoard(name: "Test Case")

        let wrappedNodes = ds.nodes
        #expect(wrappedNodes.count == 12)
        // Each wrapped node should have a non-empty displayName
        for node in wrappedNodes {
            #expect(!node.displayName.isEmpty)
        }
    }

    @Test("edges returns only edges between provided nodeIDs")
    @MainActor
    func edgesFiltersByNodeIDs() async throws {
        let (ds, _) = try makeDataSource()
        ds.loadOrCreateBoard(name: "Test Case")

        // Get all node IDs
        let allNodeIDs = Set(ds.nodes.map { $0.nodeID })
        let allEdges = ds.edges(for: allNodeIDs)
        #expect(allEdges.count == 14)

        // With an empty set, should return no edges
        let noEdges = ds.edges(for: Set<UUID>())
        #expect(noEdges.isEmpty)

        // With just one node, only edges where both endpoints are in the set
        if let firstNode = ds.nodes.first {
            let singleNodeEdges = ds.edges(for: [firstNode.nodeID])
            // An edge needs both source and target in the set, so single node = 0 edges
            // (unless there's a self-referencing edge, which there isn't)
            #expect(singleNodeEdges.isEmpty)
        }
    }

    // MARK: - Node Mutations

    @Test("moveNode updates position")
    @MainActor
    func moveNodeUpdatesPosition() async throws {
        let (ds, _) = try makeDataSource()
        ds.loadOrCreateBoard(name: "Test Case")

        guard let firstNode = (ds.board?.nodes ?? []).first else {
            Issue.record("No nodes on board")
            return
        }
        let nodeID = firstNode.id

        ds.moveNode(nodeID, to: CGPoint(x: 999, y: 888))

        #expect(firstNode.posX == 999)
        #expect(firstNode.posY == 888)
    }

    @Test("removeNode detaches node from board (sets board=nil)")
    @MainActor
    func removeNodeDetaches() async throws {
        let (ds, _) = try makeDataSource()
        ds.loadOrCreateBoard(name: "Test Case")

        let initialCount = (ds.board?.nodes ?? []).count
        guard let firstNode = (ds.board?.nodes ?? []).first else {
            Issue.record("No nodes on board")
            return
        }
        let nodeID = firstNode.id

        ds.removeNode(nodeID)

        let afterCount = (ds.board?.nodes ?? []).count
        #expect(afterCount == initialCount - 1)
        // The node should still exist but have nil board
        #expect(firstNode.board == nil)
    }

    @Test("addNodes attaches nodes at position")
    @MainActor
    func addNodesAttaches() async throws {
        let (ds, ctx) = try makeDataSource()
        ds.loadOrCreateBoard(name: "Test Case")

        // Create an orphan node (not on board)
        let orphan = InvestigationNode(name: "New Suspect", category: .person)
        ctx.insert(orphan)
        try ctx.save()

        let beforeCount = (ds.board?.nodes ?? []).count
        ds.addNodes([orphan.id], at: CGPoint(x: 500, y: 500))

        let afterCount = (ds.board?.nodes ?? []).count
        #expect(afterCount == beforeCount + 1)
        #expect(orphan.board?.id == ds.board?.id)
    }

    @Test("addNodes skips already-on-board nodes")
    @MainActor
    func addNodesSkipsDuplicates() async throws {
        let (ds, _) = try makeDataSource()
        ds.loadOrCreateBoard(name: "Test Case")

        guard let existingNode = (ds.board?.nodes ?? []).first else {
            Issue.record("No nodes on board")
            return
        }

        let beforeCount = (ds.board?.nodes ?? []).count
        ds.addNodes([existingNode.id], at: CGPoint(x: 0, y: 0))
        let afterCount = (ds.board?.nodes ?? []).count

        #expect(beforeCount == afterCount)
    }

    // MARK: - Node CRUD

    @Test("createNode creates backlog node (no board)")
    @MainActor
    func createNodeCreatesBacklog() async throws {
        let (ds, _) = try makeDataSource()
        ds.loadOrCreateBoard(name: "Test Case")

        let node = ds.createNode(name: "New Clue", subtitle: "Found at scene", category: .clue)

        #expect(node != nil)
        #expect(node?.name == "New Clue")
        #expect(node?.subtitle == "Found at scene")
        #expect(node?.category == .clue)
        #expect(node?.board == nil) // Backlog — not on any board
    }

    @Test("createEdge creates edge with label")
    @MainActor
    func createEdgeWithLabel() async throws {
        let (ds, ctx) = try makeDataSource()
        ds.loadOrCreateBoard(name: "Test Case")

        let sourceID = UUID()
        let targetID = UUID()
        ds.createEdge(from: sourceID, to: targetID, label: "witnessed")

        let allEdges = try ctx.fetch(FetchDescriptor<InvestigationEdge>())
        let created = allEdges.first(where: { $0.sourceNodeID == sourceID && $0.targetNodeID == targetID })

        #expect(created != nil)
        #expect(created?.label == "witnessed")
    }

    @Test("deleteNodePermanently removes node and its edges")
    @MainActor
    func deleteNodePermanentlyRemovesAll() async throws {
        let (ds, ctx) = try makeDataSource()
        ds.loadOrCreateBoard(name: "Test Case")

        // Find the detective node (primary)
        guard let detective = (ds.board?.nodes ?? []).first(where: { $0.name == "Det. Sarah Chen" }) else {
            Issue.record("Detective node not found")
            return
        }
        let detectiveID = detective.id

        // Count edges involving detective before deletion
        let edgesBefore = try ctx.fetch(FetchDescriptor<InvestigationEdge>())
        let detectiveEdgesBefore = edgesBefore.filter { $0.sourceNodeID == detectiveID || $0.targetNodeID == detectiveID }
        #expect(detectiveEdgesBefore.count > 0)

        ds.deleteNodePermanently(detectiveID)

        // Node should be completely gone
        let allNodes = try ctx.fetch(FetchDescriptor<InvestigationNode>())
        let found = allNodes.first(where: { $0.id == detectiveID })
        #expect(found == nil)

        // Edges involving detective should be gone
        let edgesAfter = try ctx.fetch(FetchDescriptor<InvestigationEdge>())
        let detectiveEdgesAfter = edgesAfter.filter { $0.sourceNodeID == detectiveID || $0.targetNodeID == detectiveID }
        #expect(detectiveEdgesAfter.isEmpty)
    }
}
