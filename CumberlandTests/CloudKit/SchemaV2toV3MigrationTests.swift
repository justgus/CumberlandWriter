//
//  SchemaV2toV3MigrationTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 1.3: Tests for Schema V2 to V3 migration
//  V2→V3 adds Board and BoardNode models (lightweight migration)
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

@Suite("Schema V2 to V3 Migration", .serialized)
struct SchemaV2toV3MigrationTests {

    // MARK: - Schema Version Tests

    @Test("Schema V3 has correct version identifier")
    func schemaV3VersionIdentifier() {
        let version = AppSchemaV3.versionIdentifier

        #expect(version.major == 3)
        #expect(version.minor == 0)
        #expect(version.patch == 0)
    }

    @Test("Schema V3 includes Board and BoardNode models")
    func schemaV3Models() {
        let models = AppSchemaV3.models

        // V3 should have 10 models (8 from V2 + Board + BoardNode)
        #expect(models.count == 10)
    }

    // MARK: - Board Model Tests

    @Test("Board can be created and persisted")
    @MainActor
    func boardCreation() async throws {
        let context = try TestFixtures.makeIsolatedContext()

        let board = Board(name: "Test Board")
        context.insert(board)
        try context.save()

        let boardID = board.id

        let fetched = try context.fetch(FetchDescriptor<Board>(
            predicate: #Predicate { $0.id == boardID }
        )).first

        #expect(fetched != nil)
        #expect(fetched?.name == "Test Board")
    }

    @Test("Board has default viewport")
    @MainActor
    func boardDefaultViewport() async throws {
        let context = try TestFixtures.makeIsolatedContext()

        let board = Board(name: "Test Board")
        context.insert(board)
        try context.save()

        // Default viewport should be set
        #expect(board.panX == 0.0)
        #expect(board.panY == 0.0)
        #expect(board.zoomScale == 1.0)
    }

    @Test("Board can have multiple nodes")
    @MainActor
    func boardMultipleNodes() async throws {
        let context = try TestFixtures.makeIsolatedContext()

        let board = Board(name: "Test Board")
        context.insert(board)

        let card1 = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        let card2 = TestFixtures.createSampleCharacter(name: "Bob", context: context)

        let node1 = BoardNode(board: board, card: card1, posX: 100, posY: 100)
        let node2 = BoardNode(board: board, card: card2, posX: 200, posY: 200)

        if board.nodes == nil { board.nodes = [] }
        board.nodes?.append(node1)
        board.nodes?.append(node2)

        context.insert(node1)
        context.insert(node2)
        try context.save()

        // Verify nodes are associated with board
        #expect(board.nodes?.count == 2)
    }

    // MARK: - BoardNode Model Tests

    @Test("BoardNode can be created with card reference")
    @MainActor
    func boardNodeCreation() async throws {
        let context = try TestFixtures.makeIsolatedContext()

        let board = Board(name: "Test Board")
        let card = TestFixtures.createSampleCharacter(name: "Test", context: context)
        let node = BoardNode(board: board, card: card, posX: 150, posY: 250)

        context.insert(board)
        context.insert(node)
        try context.save()

        let allNodes = try context.fetch(FetchDescriptor<BoardNode>())
        let fetched = allNodes.first { $0.board?.id == board.id && $0.card?.id == card.id }

        #expect(fetched != nil)
        #expect(fetched?.card?.id == card.id)
        #expect(fetched?.posX == 150)
        #expect(fetched?.posY == 250)
    }

    @Test("BoardNode position can be updated")
    @MainActor
    func boardNodePositionUpdate() async throws {
        let context = try TestFixtures.makeIsolatedContext()

        let board = Board(name: "Test Board")
        let card = TestFixtures.createSampleCharacter(name: "Test", context: context)
        let node = BoardNode(board: board, card: card, posX: 100, posY: 100)
        context.insert(board)
        context.insert(node)
        try context.save()

        let nodeBoard = node.board?.id
        let nodeCard = node.card?.id

        // Update position
        node.posX = 300
        node.posY = 400
        try context.save()

        let allNodes = try context.fetch(FetchDescriptor<BoardNode>())
        let fetched = allNodes.first { $0.board?.id == nodeBoard && $0.card?.id == nodeCard }

        #expect(fetched?.posX == 300)
        #expect(fetched?.posY == 400)
    }

    @Test("BoardNode maintains relationship with card")
    @MainActor
    func boardNodeCardRelationship() async throws {
        let context = try TestFixtures.makeIsolatedContext()

        let board = Board(name: "Test Board")
        let card = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        let node = BoardNode(board: board, card: card, posX: 0, posY: 0)
        context.insert(board)
        context.insert(node)
        try context.save()

        // Verify bidirectional relationship
        #expect(node.card?.id == card.id)
        // BoardNode should be in card's boardNodes
        #expect(card.boardNodes?.contains { $0.board?.id == board.id && $0.card?.id == card.id } ?? false)
    }

    // MARK: - Delete Rule Tests

    @Test("Deleting board cascades to nodes")
    @MainActor
    func deleteBoardCascadesToNodes() async throws {
        let context = try TestFixtures.makeIsolatedContext()

        let board = Board(name: "Test Board")
        context.insert(board)

        let card = TestFixtures.createSampleCharacter(name: "Test", context: context)
        let node = BoardNode(board: board, card: card, posX: 0, posY: 0)
        if board.nodes == nil { board.nodes = [] }
        board.nodes?.append(node)
        context.insert(node)
        try context.save()

        let boardID = board.id
        let cardID = card.id

        // Delete the board
        context.delete(board)
        try context.save()

        // Node should be deleted (cascade)
        let allNodes = try context.fetch(FetchDescriptor<BoardNode>())
        let fetchedNode = allNodes.first { $0.board?.id == boardID && $0.card?.id == cardID }

        #expect(fetchedNode == nil)
    }

    @Test("Deleting card cascades to nodes")
    @MainActor
    func deleteCardCascadesToNodes() async throws {
        let context = try TestFixtures.makeIsolatedContext()

        let board = Board(name: "Test Board")
        let card = TestFixtures.createSampleCharacter(name: "Test", context: context)
        let node = BoardNode(board: board, card: card, posX: 0, posY: 0)
        context.insert(board)
        context.insert(node)
        try context.save()

        let boardID = board.id
        let cardID = card.id

        // Delete the card
        context.delete(card)
        try context.save()

        // Node should be deleted (cascade from Card.boardNodes)
        let allNodes = try context.fetch(FetchDescriptor<BoardNode>())
        let fetched = allNodes.first { $0.board?.id == boardID && $0.card?.id == cardID }

        #expect(fetched == nil)
    }
}
