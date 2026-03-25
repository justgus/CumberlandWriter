// RelationshipManagerTests.swift
// CumberlandTests

import Testing
import SwiftData
import Foundation
@testable import Cumberland

@Suite("RelationshipManager Tests", .serialized)
struct RelationshipManagerTests {

    @MainActor
    private func makeManager() throws -> (RelationshipManager, ModelContext) {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()
        let mgr = RelationshipManager(modelContext: ctx)
        return (mgr, ctx)
    }

    // MARK: - Creation

    @Test("createRelationship creates forward edge")
    @MainActor
    func createForwardEdge() async throws {
        let (mgr, ctx) = try makeManager()
        let cardA = TestFixtures.createSampleCharacter(name: "Aria", context: ctx)
        let cardB = TestFixtures.createSampleArtifact(name: "Sword", context: ctx)
        let rt = TestFixtures.createRelationType(context: ctx)
        try ctx.save()

        let edge = try mgr.createRelationship(from: cardA, to: cardB, type: rt, createReverse: false)
        #expect(edge.from?.id == cardA.id)
        #expect(edge.to?.id == cardB.id)
        #expect(edge.type?.code == rt.code)
    }

    @Test("createRelationship with createReverse creates both edges")
    @MainActor
    func createBidirectionalEdges() async throws {
        let (mgr, ctx) = try makeManager()
        let cardA = TestFixtures.createSampleCharacter(name: "Aria", context: ctx)
        let cardB = TestFixtures.createSampleArtifact(name: "Sword", context: ctx)
        let rt = TestFixtures.createRelationType(context: ctx)
        try ctx.save()

        _ = try mgr.createRelationship(from: cardA, to: cardB, type: rt, createReverse: true)

        let allEdges = try ctx.fetch(FetchDescriptor<CardEdge>())
        #expect(allEdges.count == 2) // forward + reverse
    }

    @Test("createRelationship throws alreadyExists on duplicate")
    @MainActor
    func createDuplicateThrows() async throws {
        let (mgr, ctx) = try makeManager()
        let cardA = TestFixtures.createSampleCharacter(name: "Aria", context: ctx)
        let cardB = TestFixtures.createSampleArtifact(name: "Sword", context: ctx)
        let rt = TestFixtures.createRelationType(context: ctx)
        try ctx.save()

        _ = try mgr.createRelationship(from: cardA, to: cardB, type: rt, createReverse: false)

        do {
            _ = try mgr.createRelationship(from: cardA, to: cardB, type: rt, createReverse: false)
            Issue.record("Expected alreadyExists error")
        } catch let error as RelationshipError {
            #expect(error == .alreadyExists)
        }
    }

    @Test("createRelationship increments cached edge counts")
    @MainActor
    func createIncrementsCounters() async throws {
        let (mgr, ctx) = try makeManager()
        let cardA = TestFixtures.createSampleCharacter(name: "Aria", context: ctx)
        let cardB = TestFixtures.createSampleArtifact(name: "Sword", context: ctx)
        let rt = TestFixtures.createRelationType(context: ctx)
        try ctx.save()

        #expect(cardA.cachedOutgoingEdgeCount == 0)
        #expect(cardB.cachedIncomingEdgeCount == 0)

        _ = try mgr.createRelationship(from: cardA, to: cardB, type: rt, createReverse: false)

        #expect(cardA.cachedOutgoingEdgeCount == 1)
        #expect(cardB.cachedIncomingEdgeCount == 1)
    }

    // MARK: - Deletion

    @Test("removeRelationship deletes all edges between two cards")
    @MainActor
    func removeAllEdgesBetweenCards() async throws {
        let (mgr, ctx) = try makeManager()
        let cardA = TestFixtures.createSampleCharacter(name: "A", context: ctx)
        let cardB = TestFixtures.createSampleCharacter(name: "B", context: ctx)
        let rt = TestFixtures.createRelationType(context: ctx)
        try ctx.save()

        _ = try mgr.createRelationship(from: cardA, to: cardB, type: rt, createReverse: true)
        try mgr.removeRelationship(between: cardA, and: cardB)

        let remaining = try ctx.fetch(FetchDescriptor<CardEdge>())
        #expect(remaining.isEmpty)
    }

    @Test("removeEdge deletes single edge and decrements counts")
    @MainActor
    func removeEdgeDecrementsCount() async throws {
        let (mgr, ctx) = try makeManager()
        let cardA = TestFixtures.createSampleCharacter(name: "A", context: ctx)
        let cardB = TestFixtures.createSampleCharacter(name: "B", context: ctx)
        let rt = TestFixtures.createRelationType(context: ctx)
        try ctx.save()

        let edge = try mgr.createRelationship(from: cardA, to: cardB, type: rt, createReverse: false)
        #expect(cardA.cachedOutgoingEdgeCount == 1)

        try mgr.removeEdge(edge)
        #expect(cardA.cachedOutgoingEdgeCount == 0)
        #expect(cardB.cachedIncomingEdgeCount == 0)
    }

    @Test("removeAllEdges removes all and returns count")
    @MainActor
    func removeAllEdgesReturnsCount() async throws {
        let (mgr, ctx) = try makeManager()
        let cardA = TestFixtures.createSampleCharacter(name: "A", context: ctx)
        let cardB = TestFixtures.createSampleCharacter(name: "B", context: ctx)
        let cardC = TestFixtures.createSampleCharacter(name: "C", context: ctx)
        let rt = TestFixtures.createRelationType(context: ctx)
        try ctx.save()

        _ = try mgr.createRelationship(from: cardA, to: cardB, type: rt, createReverse: false)
        _ = try mgr.createRelationship(from: cardA, to: cardC, type: rt, createReverse: false)

        let count = try mgr.removeAllEdges(for: cardA)
        #expect(count == 2)
        #expect(cardA.cachedOutgoingEdgeCount == 0)
        #expect(cardA.cachedIncomingEdgeCount == 0)
    }

    // MARK: - Queries

    @Test("relationshipExists returns correct values")
    @MainActor
    func relationshipExistsWorks() async throws {
        let (mgr, ctx) = try makeManager()
        let cardA = TestFixtures.createSampleCharacter(name: "A", context: ctx)
        let cardB = TestFixtures.createSampleCharacter(name: "B", context: ctx)
        let rt = TestFixtures.createRelationType(context: ctx)
        try ctx.save()

        #expect(!mgr.relationshipExists(from: cardA, to: cardB, type: rt))

        _ = try mgr.createRelationship(from: cardA, to: cardB, type: rt, createReverse: false)
        #expect(mgr.relationshipExists(from: cardA, to: cardB, type: rt))
    }

    // MARK: - Validation

    @Test("validateRelationship rejects self-referencing")
    @MainActor
    func validateRejectsSelfRef() async throws {
        let (mgr, ctx) = try makeManager()
        let card = TestFixtures.createSampleCharacter(name: "Solo", context: ctx)
        let rt = TestFixtures.createRelationType(context: ctx)
        try ctx.save()

        #expect(!mgr.validateRelationship(from: card, to: card, type: rt))
    }

    @Test("validateRelationship rejects existing relationship")
    @MainActor
    func validateRejectsExisting() async throws {
        let (mgr, ctx) = try makeManager()
        let cardA = TestFixtures.createSampleCharacter(name: "A", context: ctx)
        let cardB = TestFixtures.createSampleCharacter(name: "B", context: ctx)
        let rt = TestFixtures.createRelationType(context: ctx)
        try ctx.save()

        _ = try mgr.createRelationship(from: cardA, to: cardB, type: rt, createReverse: false)
        #expect(!mgr.validateRelationship(from: cardA, to: cardB, type: rt))
    }
}
