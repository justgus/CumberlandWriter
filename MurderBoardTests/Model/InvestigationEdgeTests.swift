// InvestigationEdgeTests.swift
// MurderBoardTests

import Testing
import SwiftData
import Foundation
@testable import MurderBoard

@Suite("InvestigationEdge Tests", .serialized)
struct InvestigationEdgeTests {

    @MainActor
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: InvestigationBoard.self, InvestigationNode.self, InvestigationEdge.self,
            configurations: config
        )
        return container.mainContext
    }

    @Test("create edge with source and target IDs")
    @MainActor
    func createEdgeWithIDs() async throws {
        let ctx = try makeContext()
        let sourceID = UUID()
        let targetID = UUID()
        let edge = InvestigationEdge(sourceNodeID: sourceID, targetNodeID: targetID, label: "knows")
        ctx.insert(edge)
        try ctx.save()

        #expect(edge.sourceNodeID == sourceID)
        #expect(edge.targetNodeID == targetID)
        #expect(edge.label == "knows")
    }

    @Test("edge default label is empty string")
    @MainActor
    func edgeDefaultLabelEmpty() async throws {
        let ctx = try makeContext()
        let edge = InvestigationEdge(sourceNodeID: UUID(), targetNodeID: UUID())
        ctx.insert(edge)
        try ctx.save()

        #expect(edge.label == "")
    }

    @Test("edge persists createdAt")
    @MainActor
    func edgePersistsCreatedAt() async throws {
        let ctx = try makeContext()
        let before = Date()
        let edge = InvestigationEdge(sourceNodeID: UUID(), targetNodeID: UUID(), label: "witnessed")
        ctx.insert(edge)
        try ctx.save()
        let after = Date()

        #expect(edge.createdAt >= before)
        #expect(edge.createdAt <= after)
    }
}
