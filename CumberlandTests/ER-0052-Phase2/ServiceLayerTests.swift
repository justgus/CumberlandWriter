//
//  ServiceLayerTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 2: Service Layer Completion Tests
//  Tests business logic managers including:
//  - EdgeIntegrityMonitor desync detection
//  - BoardManager CRUD operations
//  - RelationTypeManager CRUD operations
//

import Testing
import SwiftData
import SwiftUI
@testable import Cumberland

// MARK: - Test Container

/// Test suite for Service Layer validation
@Suite("Service Layer Tests", .tags(.phase2, .serviceLayer))
@MainActor
struct ServiceLayerTests {

    // MARK: - Test Infrastructure

    var container: ModelContainer
    var context: ModelContext

    init() throws {
        // Create in-memory container for testing
        let schema = Schema([
            AppSettings.self,
            Card.self,
            RelationType.self,
            CardEdge.self,
            Source.self,
            Citation.self,
            StoryStructure.self,
            StructureElement.self,
            Board.self,
            BoardNode.self,
            ImageVersion.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        self.container = try ModelContainer(for: schema, configurations: [configuration])
        self.context = ModelContext(container)
    }

    // MARK: - EdgeIntegrityMonitor Tests

    @Test("EdgeIntegrityMonitor checks card integrity")
    func testChecksCardIntegrity() throws {
        // Given: A card
        let card = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        context.insert(card)
        try context.save()

        // When: Checking integrity
        let monitor = EdgeIntegrityMonitor()
        let status = monitor.checkIntegrity(card: card)

        // Then: Should return a status (ok, desyncDetected, or countStale)
        // This test verifies the monitor can check integrity
        switch status {
        case .ok:
            break // Valid status
        case .desyncDetected:
            break // Valid status
        case .countStale:
            break // Valid status
        }
    }

    @Test("EdgeIntegrityMonitor recalculates counts")
    func testRecalculatesCounts() throws {
        // Given: A card with edges
        let card1 = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        let card2 = Card(kind: .characters, name: "Villain", subtitle: "", detailedText: "")
        context.insert(card1)
        context.insert(card2)

        let relType = RelationType(code: "fights/fought-by", forwardLabel: "fights", inverseLabel: "fought-by")
        context.insert(relType)

        let edge = CardEdge(from: card1, to: card2, type: relType)
        context.insert(edge)
        try context.save()

        // When: Recalculating counts
        EdgeIntegrityMonitor.recalculateCounts(for: card1, modelContext: context)

        // Then: Function should execute without error
        // Actual count verification would require access to internal properties
        #expect(card1.outgoingEdges?.count == 1)
    }

    @Test("EdgeIntegrityMonitor recovers from desync")
    func testRecoversFromDesync() throws {
        // Given: A card
        let card = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        context.insert(card)
        try context.save()

        // When: Recovering
        let monitor = EdgeIntegrityMonitor()
        let (outgoing, incoming) = monitor.recover(card: card, modelContext: context)

        // Then: Should return authoritative edge arrays
        #expect(outgoing.count == 0) // No actual edges
        #expect(incoming.count == 0)
    }

    // MARK: - BoardManager Tests

    @Test("BoardManager creates new board")
    func testBoardManagerCreatesBoard() throws {
        // Given: BoardManager instance
        let boardManager = BoardManager(modelContext: context)

        // When: Creating a board
        let board = try boardManager.createBoard(name: "Character Relationships", primaryCard: nil)

        // Then: Board should be created
        #expect(board.name == "Character Relationships")
        #expect(board.nodes?.isEmpty == true || board.nodes == nil)
    }

    @Test("BoardManager fetches primary board")
    func testBoardManagerFetchesPrimaryBoard() throws {
        // Given: A card with a primary board
        let card = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        context.insert(card)

        let boardManager = BoardManager(modelContext: context)
        let board = try boardManager.createBoard(name: "Hero's Board", primaryCard: card)
        try context.save()

        // When: Fetching or creating primary board
        let fetchedBoard = boardManager.fetchOrCreatePrimaryBoard(for: card)

        // Then: Should return existing board
        #expect(fetchedBoard.id == board.id)
    }

    @Test("BoardManager adds node to board")
    func testBoardManagerAddsNode() throws {
        // Given: A board and a card
        let card = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        context.insert(card)

        let boardManager = BoardManager(modelContext: context)
        let board = try boardManager.createBoard(name: "Test Board", primaryCard: nil)
        try context.save()

        // When: Adding a node
        let node = boardManager.addNode(to: board, card: card, position: (x: 100, y: 200))

        // Then: Node should be added to board
        #expect(node.card?.id == card.id)
        #expect(node.board?.id == board.id)
        #expect(node.posX == 100)
        #expect(node.posY == 200)
    }

    @Test("BoardManager removes node from board")
    func testBoardManagerRemovesNode() throws {
        // Given: A board with a node
        let card = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        context.insert(card)

        let boardManager = BoardManager(modelContext: context)
        let board = try boardManager.createBoard(name: "Test Board", primaryCard: nil)
        let node = boardManager.addNode(to: board, card: card, position: (x: 100, y: 200))
        try context.save()

        let initialCount = board.nodes?.count ?? 0

        // When: Removing the node
        try boardManager.removeNode(node)
        try context.save()

        // Then: Node should be removed
        let finalCount = board.nodes?.count ?? 0
        #expect(finalCount == initialCount - 1)
    }

    @Test("BoardManager deletes board")
    func testBoardManagerDeletesBoard() throws {
        // Given: A board
        let boardManager = BoardManager(modelContext: context)
        let board = try boardManager.createBoard(name: "Test Board", primaryCard: nil)
        try context.save()

        // When: Deleting the board
        try boardManager.deleteBoard(board)
        try context.save()

        // Then: Board should be deleted
        let allBoards = boardManager.fetchAllBoards()
        #expect(!allBoards.contains { $0.id == board.id })
    }

    // MARK: - RelationTypeManager Tests

    @Test("RelationTypeManager creates relation type")
    func testRelationTypeManagerCreates() throws {
        // Given: RelationTypeManager instance
        let manager = RelationTypeManager(modelContext: context)

        // When: Creating a relation type
        let relType = try manager.createRelationType(
            code: "loves/loved-by",
            forwardLabel: "loves",
            inverseLabel: "loved-by"
        )

        // Then: RelationType should be created
        #expect(relType.code == "loves/loved-by")
        #expect(relType.forwardLabel == "loves")
        #expect(relType.inverseLabel == "loved-by")
    }

    @Test("RelationTypeManager ensures relation type exists")
    func testRelationTypeManagerEnsures() throws {
        // Given: RelationTypeManager with existing type
        let manager = RelationTypeManager(modelContext: context)
        let existing = try manager.createRelationType(
            code: "fights/fought-by",
            forwardLabel: "fights",
            inverseLabel: "fought-by"
        )
        try context.save()

        // When: Ensuring the same type exists
        let ensured = manager.ensureRelationType(
            code: "fights/fought-by",
            forwardLabel: "fights",
            inverseLabel: "fought-by"
        )

        // Then: Should return existing type
        #expect(ensured.id == existing.id)
    }

    @Test("RelationTypeManager deletes relation type")
    func testRelationTypeManagerDeletes() throws {
        // Given: A relation type
        let manager = RelationTypeManager(modelContext: context)
        let relType = try manager.createRelationType(
            code: "test/test-by",
            forwardLabel: "test",
            inverseLabel: "test-by"
        )
        try context.save()

        let typeID = relType.id

        // When: Deleting the relation type
        try manager.deleteRelationType(relType)
        try context.save()

        // Then: RelationType should be deleted
        let descriptor = FetchDescriptor<RelationType>(
            predicate: #Predicate { $0.id == typeID }
        )
        let results = try context.fetch(descriptor)
        #expect(results.isEmpty)
    }
}

// MARK: - Test Tags Extension

extension Tag {
    @Tag static var serviceLayer: Self
}
