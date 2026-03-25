// CumberlandBoardDataSourceTests.swift
// CumberlandTests

import Testing
import SwiftUI
import SwiftData
import Foundation
@testable import Cumberland

@Suite("CumberlandBoardDataSource Tests", .serialized)
struct CumberlandBoardDataSourceTests {

    @MainActor
    private func makeDataSource() throws -> (CumberlandBoardDataSource, ModelContext) {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()
        let ds = CumberlandBoardDataSource(modelContext: ctx)
        return (ds, ctx)
    }

    @Test("loadBoard creates board for primary card")
    @MainActor
    func loadBoardCreates() async throws {
        let (ds, ctx) = try makeDataSource()
        let card = TestFixtures.createSampleCharacter(name: "Primary", context: ctx)
        try ctx.save()

        ds.loadBoard(for: card)

        #expect(ds.board != nil)
        #expect(ds.board?.primaryCard?.id == card.id)
    }

    @Test("moveNode updates position")
    @MainActor
    func moveNodeUpdatesPosition() async throws {
        let (ds, ctx) = try makeDataSource()
        let card = TestFixtures.createSampleCharacter(name: "Hero", context: ctx)
        try ctx.save()

        ds.loadBoard(for: card)
        // Card should now be on the board as a node
        let nodeID = card.id

        ds.moveNode(nodeID, to: CGPoint(x: 300, y: 400))

        // Find the board node and check position
        let boardNode = (ds.board?.nodes ?? []).first(where: { $0.card?.id == card.id })
        #expect(boardNode?.posX == 300)
        #expect(boardNode?.posY == 400)
    }

    @Test("removeNode deletes BoardNode")
    @MainActor
    func removeNodeDeletes() async throws {
        let (ds, ctx) = try makeDataSource()
        let primary = TestFixtures.createSampleCharacter(name: "Primary", context: ctx)
        let other = TestFixtures.createSampleArtifact(name: "Artifact", context: ctx)
        try ctx.save()

        ds.loadBoard(for: primary)
        // Manually add another node to the board
        _ = ds.board?.node(for: other, in: ctx, createIfMissing: true, defaultPosition: (100, 100))

        let initialCount = (ds.board?.nodes ?? []).count
        ds.removeNode(other.id)

        let afterCount = (ds.board?.nodes ?? []).count
        #expect(afterCount == initialCount - 1)
    }

    @Test("addNodes skips duplicates")
    @MainActor
    func addNodesSkipsDuplicates() async throws {
        let (ds, ctx) = try makeDataSource()
        let primary = TestFixtures.createSampleCharacter(name: "Primary", context: ctx)
        let other = TestFixtures.createSampleArtifact(name: "Artifact", context: ctx)
        try ctx.save()

        ds.loadBoard(for: primary)
        ds.allCards = [primary, other]

        // Add other to the board
        ds.addNodes([other.id], at: CGPoint(x: 50, y: 50))
        let countAfterFirst = (ds.board?.nodes ?? []).count

        // Try adding the same card again — should be a no-op
        ds.addNodes([other.id], at: CGPoint(x: 200, y: 200))
        let countAfterSecond = (ds.board?.nodes ?? []).count

        #expect(countAfterFirst == countAfterSecond)
    }

    @Test("addNodes positions multiple in spiral")
    @MainActor
    func addNodesPositionsMultiple() async throws {
        let (ds, ctx) = try makeDataSource()
        let primary = TestFixtures.createSampleCharacter(name: "Primary", context: ctx)
        let cardA = TestFixtures.createSampleArtifact(name: "A", context: ctx)
        let cardB = TestFixtures.createSampleLocation(name: "B", context: ctx)
        try ctx.save()

        ds.loadBoard(for: primary)
        ds.allCards = [primary, cardA, cardB]

        ds.addNodes([cardA.id, cardB.id], at: CGPoint(x: 0, y: 0))

        let nodes = ds.board?.nodes ?? []
        let nodeA = nodes.first(where: { $0.card?.id == cardA.id })
        let nodeB = nodes.first(where: { $0.card?.id == cardB.id })

        #expect(nodeA != nil)
        #expect(nodeB != nil)
        // They should be at different positions (spiral layout)
        if let a = nodeA, let b = nodeB {
            #expect(a.posX != b.posX || a.posY != b.posY)
        }
    }

    @Test("togglePin flips pinned state")
    @MainActor
    func togglePinFlips() async throws {
        let (ds, ctx) = try makeDataSource()
        let card = TestFixtures.createSampleCharacter(name: "Hero", context: ctx)
        try ctx.save()

        ds.loadBoard(for: card)

        // Initially not pinned
        let boardNode = (ds.board?.nodes ?? []).first(where: { $0.card?.id == card.id })
        #expect(boardNode?.pinned == false)

        let newState = ds.togglePin(for: card.id)
        #expect(newState == true)
        #expect(boardNode?.pinned == true)

        let revertedState = ds.togglePin(for: card.id)
        #expect(revertedState == false)
        #expect(boardNode?.pinned == false)
    }

    @Test("setPin sets explicit pinned state")
    @MainActor
    func setPinExplicit() async throws {
        let (ds, ctx) = try makeDataSource()
        let card = TestFixtures.createSampleCharacter(name: "Hero", context: ctx)
        try ctx.save()

        ds.loadBoard(for: card)

        ds.setPin(for: card.id, pinned: true)
        let boardNode = (ds.board?.nodes ?? []).first(where: { $0.card?.id == card.id })
        #expect(boardNode?.pinned == true)

        ds.setPin(for: card.id, pinned: false)
        #expect(boardNode?.pinned == false)
    }
}
