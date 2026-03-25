// BoardModelTests.swift
// CumberlandTests

import Testing
import SwiftData
import Foundation
@testable import Cumberland

@Suite("Board Model Tests", .serialized)
struct BoardModelTests {

    // MARK: - clampState

    @Test("clampState clamps zoom to max")
    @MainActor
    func clampStateMaxZoom() async throws {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()
        let board = TestFixtures.createBoard(name: "Test", context: ctx)
        board.zoomScale = 5.0
        board.clampState()
        #expect(board.zoomScale == Board.maxZoom)
    }

    @Test("clampState clamps zoom to min")
    @MainActor
    func clampStateMinZoom() async throws {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()
        let board = TestFixtures.createBoard(name: "Test", context: ctx)
        board.zoomScale = 0.001
        board.clampState()
        #expect(board.zoomScale == Board.minZoom)
    }

    @Test("clampState clamps panX and panY")
    @MainActor
    func clampStatePan() async throws {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()
        let board = TestFixtures.createBoard(name: "Test", context: ctx)
        board.panX = 2_000_000
        board.panY = -2_000_000
        board.clampState()
        #expect(board.panX == Board.maxPan)
        #expect(board.panY == Board.minPan)
    }

    // MARK: - node(for:in:createIfMissing:)

    @Test("node creates when missing and createIfMissing is true")
    @MainActor
    func nodeCreatesWhenMissing() async throws {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()
        let card = TestFixtures.createSampleCharacter(name: "Hero", context: ctx)
        let board = TestFixtures.createBoard(name: "Board", context: ctx)
        try ctx.save()

        let node = board.node(for: card, in: ctx, createIfMissing: true, defaultPosition: (100, 200))
        #expect(node != nil)
        #expect(node?.posX == 100)
        #expect(node?.posY == 200)
    }

    @Test("node returns nil when missing and createIfMissing is false")
    @MainActor
    func nodeReturnsNilWhenMissing() async throws {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()
        let card = TestFixtures.createSampleCharacter(name: "Hero", context: ctx)
        let board = TestFixtures.createBoard(name: "Board", context: ctx)
        try ctx.save()

        let node = board.node(for: card, in: ctx, createIfMissing: false)
        #expect(node == nil)
    }

    // MARK: - fetchOrCreatePrimaryBoard

    @Test("fetchOrCreatePrimaryBoard creates new board")
    @MainActor
    func fetchOrCreateCreatesNew() async throws {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()
        let card = TestFixtures.createSampleCharacter(name: "Primary", context: ctx)
        try ctx.save()

        let board = Board.fetchOrCreatePrimaryBoard(for: card, in: ctx)
        #expect(board.primaryCard?.id == card.id)
        #expect(board.name.contains("Primary"))
    }

    @Test("fetchOrCreatePrimaryBoard returns existing on repeat call")
    @MainActor
    func fetchOrCreateReturnsExisting() async throws {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()
        let card = TestFixtures.createSampleCharacter(name: "Primary", context: ctx)
        try ctx.save()

        let board1 = Board.fetchOrCreatePrimaryBoard(for: card, in: ctx)
        let board2 = Board.fetchOrCreatePrimaryBoard(for: card, in: ctx)
        #expect(board1.id == board2.id)
    }

    // MARK: - BoardNode.effectiveSizeCategory

    @Test("effectiveSizeCategory uses override when set, falls back to card")
    @MainActor
    func effectiveSizeCategoryOverrideAndFallback() async throws {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()
        let card = TestFixtures.createSampleCharacter(context: ctx)
        card.sizeCategory = .compact
        let board = TestFixtures.createBoard(context: ctx)
        let node = BoardNode(board: board, card: card)
        ctx.insert(node)

        // No override — should fall back to card
        #expect(node.effectiveSizeCategory == .compact)

        // With override
        node.sizeOverrideRaw = SizeCategory.large.rawValue
        #expect(node.effectiveSizeCategory == .large)
    }
}
