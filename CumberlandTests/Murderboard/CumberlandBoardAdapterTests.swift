// CumberlandBoardAdapterTests.swift
// CumberlandTests

import Testing
import SwiftUI
import SwiftData
import Foundation
@testable import Cumberland

@Suite("CumberlandBoardAdapter Tests", .serialized)
struct CumberlandBoardAdapterTests {

    @MainActor
    private func makeContext() throws -> ModelContext {
        let ctx = try TestFixtures.makeIsolatedContext()
        return ctx
    }

    // MARK: - CumberlandNode

    @Test("CumberlandNode.init wraps BoardNode properties")
    @MainActor
    func nodeInitWrapsProperties() async throws {
        let ctx = try makeContext()
        let card = TestFixtures.createSampleCharacter(name: "Hero", context: ctx)
        let board = TestFixtures.createBoard(name: "Board", primaryCard: card, context: ctx)
        let boardNode = BoardNode(board: board, card: card)
        boardNode.posX = 150
        boardNode.posY = 250
        boardNode.zIndex = 3.0
        boardNode.pinned = true
        ctx.insert(boardNode)
        try ctx.save()

        let wrapped = CumberlandNode(from: boardNode, primaryCardID: card.id)

        #expect(wrapped.nodeID == card.id)
        #expect(wrapped.posX == 150)
        #expect(wrapped.posY == 250)
        #expect(wrapped.zIndex == 3.0)
        #expect(wrapped.isPinned == true)
        #expect(wrapped.displayName == "Hero")
        #expect(wrapped.categorySystemImage == Kinds.characters.systemImage)
    }

    @Test("CumberlandNode.isPrimary true when matches primaryCardID")
    @MainActor
    func nodeIsPrimaryTrue() async throws {
        let ctx = try makeContext()
        let card = TestFixtures.createSampleCharacter(name: "Primary", context: ctx)
        let board = TestFixtures.createBoard(name: "Board", context: ctx)
        let boardNode = BoardNode(board: board, card: card)
        ctx.insert(boardNode)
        try ctx.save()

        let wrapped = CumberlandNode(from: boardNode, primaryCardID: card.id)
        #expect(wrapped.isPrimary == true)
    }

    @Test("CumberlandNode.isPrimary false when no match")
    @MainActor
    func nodeIsPrimaryFalse() async throws {
        let ctx = try makeContext()
        let card = TestFixtures.createSampleCharacter(name: "Secondary", context: ctx)
        let board = TestFixtures.createBoard(name: "Board", context: ctx)
        let boardNode = BoardNode(board: board, card: card)
        ctx.insert(boardNode)
        try ctx.save()

        let otherID = UUID()
        let wrapped = CumberlandNode(from: boardNode, primaryCardID: otherID)
        #expect(wrapped.isPrimary == false)
    }

    @Test("CumberlandNode.accentColor returns kind-specific color")
    @MainActor
    func nodeAccentColorUsesKind() async throws {
        let ctx = try makeContext()
        let card = TestFixtures.createSampleCharacter(name: "Hero", context: ctx)
        let board = TestFixtures.createBoard(name: "Board", context: ctx)
        let boardNode = BoardNode(board: board, card: card)
        ctx.insert(boardNode)
        try ctx.save()

        let wrapped = CumberlandNode(from: boardNode, primaryCardID: nil)
        let lightColor = wrapped.accentColor(for: .light)
        let darkColor = wrapped.accentColor(for: .dark)

        // Should return the same colors as the card's kind
        #expect(lightColor == Kinds.characters.accentColor(for: .light))
        #expect(darkColor == Kinds.characters.accentColor(for: .dark))
    }

    // MARK: - CumberlandEdge

    @Test("CumberlandEdge.init wraps CardEdge properties")
    @MainActor
    func edgeInitWrapsProperties() async throws {
        let ctx = try makeContext()
        let cardA = TestFixtures.createSampleCharacter(name: "A", context: ctx)
        let cardB = TestFixtures.createSampleArtifact(name: "B", context: ctx)
        let rt = TestFixtures.createRelationType(context: ctx)
        let edge = TestFixtures.createEdge(from: cardA, to: cardB, type: rt, context: ctx)
        try ctx.save()

        let wrapped = CumberlandEdge(from: edge)

        #expect(wrapped.sourceNodeID == cardA.id)
        #expect(wrapped.targetNodeID == cardB.id)
        #expect(wrapped.typeCode == rt.code)
    }
}
