//
//  EdgeRepositoryTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 1.2: Comprehensive tests for EdgeRepository
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

@Suite("Edge Repository", .serialized)
struct EdgeRepositoryTests {

    // MARK: - Fetch Outgoing/Incoming Tests

    @Test("Fetch outgoing edges from a card")
    @MainActor
    func fetchOutgoingEdges() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let edgeRepo = EdgeRepository(modelContext: context)

        let source = TestFixtures.createSampleCharacter(name: "Source", context: context)
        let target1 = TestFixtures.createSampleCharacter(name: "Target1", context: context)
        let target2 = TestFixtures.createSampleCharacter(name: "Target2", context: context)

        let relationType = TestFixtures.createRelationType(code: "knows", context: context)

        let edge1 = TestFixtures.createEdge(from: source, to: target1, type: relationType, context: context)
        let edge2 = TestFixtures.createEdge(from: source, to: target2, type: relationType, context: context)
        try context.save()

        let outgoing = edgeRepo.fetchOutgoing(from: source)

        #expect(outgoing.count == 2)
        #expect(outgoing.contains { $0.id == edge1.id })
        #expect(outgoing.contains { $0.id == edge2.id })
    }

    @Test("Fetch incoming edges to a card")
    @MainActor
    func fetchIncomingEdges() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let edgeRepo = EdgeRepository(modelContext: context)

        let target = TestFixtures.createSampleCharacter(name: "Target", context: context)
        let source1 = TestFixtures.createSampleCharacter(name: "Source1", context: context)
        let source2 = TestFixtures.createSampleCharacter(name: "Source2", context: context)

        let relationType = TestFixtures.createRelationType(code: "knows", context: context)

        let edge1 = TestFixtures.createEdge(from: source1, to: target, type: relationType, context: context)
        let edge2 = TestFixtures.createEdge(from: source2, to: target, type: relationType, context: context)
        try context.save()

        let incoming = edgeRepo.fetchIncoming(to: target)

        #expect(incoming.count == 2)
        #expect(incoming.contains { $0.id == edge1.id })
        #expect(incoming.contains { $0.id == edge2.id })
    }

    @Test("Fetch all edges for a card combines incoming and outgoing")
    @MainActor
    func fetchAllEdgesForCard() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let edgeRepo = EdgeRepository(modelContext: context)

        let card = TestFixtures.createSampleCharacter(name: "Center", context: context)
        let other1 =  TestFixtures.createSampleCharacter(name: "Other1", context: context)
        let other2 = TestFixtures.createSampleCharacter(name: "Other2", context: context)

        let relationType = TestFixtures.createRelationType(code: "knows", context: context)

        // Create outgoing edge
        let _ = TestFixtures.createEdge(from: card, to: other1, type: relationType, context: context)
        // Create incoming edge
        let _ = TestFixtures.createEdge(from: other2, to: card, type: relationType, context: context)
        try context.save()

        let allEdges = edgeRepo.fetchAll(for: card)

        #expect(allEdges.count == 2)
    }

    // MARK: - Fetch Between Cards Tests

    @Test("Fetch edges between two cards finds bidirectional edges")
    @MainActor
    func fetchEdgesBetweenCards() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let edgeRepo = EdgeRepository(modelContext: context)

        let cardA = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        let cardB = TestFixtures.createSampleCharacter(name: "Bob", context: context)

        let knowsType = TestFixtures.createRelationType(code: "knows", context: context)
        let friendsType = TestFixtures.createRelationType(code: "friends", context: context)

        // Create edges in both directions
        let _ = TestFixtures.createEdge(from: cardA, to: cardB, type: knowsType, context: context)
        let _ = TestFixtures.createEdge(from: cardB, to: cardA, type: friendsType, context: context)
        try context.save()

        let edges = edgeRepo.fetchEdges(between: cardA, and: cardB)

        #expect(edges.count == 2)
    }

    // MARK: - Fetch by Type Tests

    @Test("Fetch edges by relation type filters correctly")
    @MainActor
    func fetchEdgesByType() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let edgeRepo = EdgeRepository(modelContext: context)

        let card1 = TestFixtures.createSampleCharacter(name: "Card1", context: context)
        let card2 = TestFixtures.createSampleCharacter(name: "Card2", context: context)
        let card3 = TestFixtures.createSampleCharacter(name: "Card3", context: context)

        let knowsType = TestFixtures.createRelationType(code: "knows", context: context)
        let lovesType = TestFixtures.createRelationType(code: "loves", context: context)

        let _ = TestFixtures.createEdge(from: card1, to: card2, type: knowsType, context: context)
        let _ = TestFixtures.createEdge(from: card1, to: card3, type: lovesType, context: context)
        try context.save()

        let knowsEdges = edgeRepo.fetch(ofType: knowsType)

        #expect(knowsEdges.count >= 1)
        #expect(knowsEdges.allSatisfy { $0.type?.code == "knows" })
    }

    @Test("Fetch outgoing edges of specific type")
    @MainActor
    func fetchOutgoingEdgesOfType() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let edgeRepo = EdgeRepository(modelContext: context)

        let source = TestFixtures.createSampleCharacter(name: "Source", context: context)
        let target1 = TestFixtures.createSampleCharacter(name: "Target1", context: context)
        let target2 = TestFixtures.createSampleCharacter(name: "Target2", context: context)

        let knowsType = TestFixtures.createRelationType(code: "knows", context: context)
        let lovesType = TestFixtures.createRelationType(code: "loves", context: context)

        let _ = TestFixtures.createEdge(from: source, to: target1, type: knowsType, context: context)
        let _ = TestFixtures.createEdge(from: source, to: target2, type: lovesType, context: context)
        try context.save()

        let knowsEdges = edgeRepo.fetchOutgoing(from: source, ofType: knowsType)

        #expect(knowsEdges.count == 1)
        #expect(knowsEdges.first?.to?.id == target1.id)
    }

    // MARK: - Edge Existence Tests

    @Test("Edge existence check returns true when edge exists")
    @MainActor
    func edgeExistsTrue() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let edgeRepo = EdgeRepository(modelContext: context)

        let source = TestFixtures.createSampleCharacter(name: "Source", context: context)
        let target = TestFixtures.createSampleCharacter(name: "Target", context: context)
        let relationType = TestFixtures.createRelationType(code: "knows", context: context)

        let _ = TestFixtures.createEdge(from: source, to: target, type: relationType, context: context)
        try context.save()

        let exists = edgeRepo.exists(from: source, to: target, ofType: relationType)

        #expect(exists == true)
    }

    @Test("Edge existence check returns false when edge does not exist")
    @MainActor
    func edgeExistsFalse() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let edgeRepo = EdgeRepository(modelContext: context)

        let source = TestFixtures.createSampleCharacter(name: "Source", context: context)
        let target = TestFixtures.createSampleCharacter(name: "Target", context: context)
        let relationType = TestFixtures.createRelationType(code: "knows", context: context)
        try context.save()

        // No edge created
        let exists = edgeRepo.exists(from: source, to: target, ofType: relationType)

        #expect(exists == false)
    }

    // MARK: - Delete Operations Tests

    @Test("Delete edge removes it from context")
    @MainActor
    func deleteEdge() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let edgeRepo = EdgeRepository(modelContext: context)

        let source = TestFixtures.createSampleCharacter(name: "Source", context: context)
        let target = TestFixtures.createSampleCharacter(name: "Target", context: context)
        let relationType = TestFixtures.createRelationType(code: "knows", context: context)

        let edge = TestFixtures.createEdge(from: source, to: target, type: relationType, context: context)
        try context.save()

        try edgeRepo.delete(edge)

        let exists = edgeRepo.exists(from: source, to: target, ofType: relationType)
        #expect(exists == false)
    }

    @Test("Delete all edges for card removes both incoming and outgoing")
    @MainActor
    func deleteAllEdgesForCard() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let edgeRepo = EdgeRepository(modelContext: context)

        let center = TestFixtures.createSampleCharacter(name: "Center", context: context)
        let other1 = TestFixtures.createSampleCharacter(name: "Other1", context: context)
        let other2 = TestFixtures.createSampleCharacter(name: "Other2", context: context)
        let relationType = TestFixtures.createRelationType(code: "knows", context: context)

        let _ = TestFixtures.createEdge(from: center, to: other1, type: relationType, context: context)
        let _ = TestFixtures.createEdge(from: other2, to: center, type: relationType, context: context)
        try context.save()

        try edgeRepo.deleteAll(for: center)

        let remainingEdges = edgeRepo.fetchAll(for: center)
        #expect(remainingEdges.isEmpty)
    }
}
