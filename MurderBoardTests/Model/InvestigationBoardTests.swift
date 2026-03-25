// InvestigationBoardTests.swift
// MurderBoardTests

import Testing
import SwiftData
import Foundation
@testable import MurderBoard

@Suite("InvestigationBoard Tests", .serialized)
struct InvestigationBoardTests {

    @MainActor
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: InvestigationBoard.self, InvestigationNode.self, InvestigationEdge.self,
            configurations: config
        )
        return container.mainContext
    }

    @Test("create board with name and verify properties")
    @MainActor
    func createBoardVerifyProperties() async throws {
        let ctx = try makeContext()
        let board = InvestigationBoard(name: "Test Case #1")
        ctx.insert(board)
        try ctx.save()

        #expect(board.name == "Test Case #1")
        #expect(board.zoomScale == 1.0)
        #expect(board.panX == 0.0)
        #expect(board.panY == 0.0)
    }

    @Test("nodes relationship is initially empty")
    @MainActor
    func nodesInitiallyEmpty() async throws {
        let ctx = try makeContext()
        let board = InvestigationBoard(name: "Empty Board")
        ctx.insert(board)
        try ctx.save()

        #expect((board.nodes ?? []).isEmpty)
    }

    @Test("primaryNodeID is initially nil")
    @MainActor
    func primaryNodeIDInitiallyNil() async throws {
        let ctx = try makeContext()
        let board = InvestigationBoard(name: "Board")
        ctx.insert(board)
        try ctx.save()

        #expect(board.primaryNodeID == nil)
    }

    @Test("nodes relationship tracks added nodes")
    @MainActor
    func nodesRelationshipTracksAdded() async throws {
        let ctx = try makeContext()
        let board = InvestigationBoard(name: "Board")
        ctx.insert(board)

        let node1 = InvestigationNode(name: "Detective", category: .person)
        node1.board = board
        ctx.insert(node1)

        let node2 = InvestigationNode(name: "Crime Scene", category: .place)
        node2.board = board
        ctx.insert(node2)

        try ctx.save()

        #expect((board.nodes ?? []).count == 2)
    }
}
