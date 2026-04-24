// CardOperationManagerTests.swift
// CumberlandTests

import Testing
import SwiftData
import Foundation
@testable import Cumberland

@Suite("CardOperationManager Tests", .serialized)
struct CardOperationManagerTests {

    @MainActor
    private func makeManager() throws -> (CardOperationManager, ModelContext) {
        let ctx = try TestFixtures.makeIsolatedContext()
        let mgr = CardOperationManager(modelContext: ctx)
        mgr.relationshipManager = RelationshipManager(modelContext: ctx)
        return (mgr, ctx)
    }

    // MARK: - Creation

    @Test("createCard persists with correct properties")
    @MainActor
    func createCardPersists() async throws {
        let (mgr, ctx) = try makeManager()
        let card = try mgr.createCard(kind: .characters, name: "Hero", subtitle: "Bold", detailedText: "A brave warrior")

        #expect(card.kind == .characters)
        #expect(card.name == "Hero")
        #expect(card.subtitle == "Bold")

        let fetched = try ctx.fetch(FetchDescriptor<Card>())
        #expect(fetched.count == 1)
    }

    // MARK: - Deletion

    @Test("deleteCard calls cleanupBeforeDeletion")
    @MainActor
    func deleteCardCleansUp() async throws {
        let (mgr, ctx) = try makeManager()
        let cardA = try mgr.createCard(kind: .characters, name: "A")
        let cardB = try mgr.createCard(kind: .artifacts, name: "B")
        let rt = TestFixtures.createRelationType(context: ctx)
        try ctx.save()

        _ = try mgr.relationshipManager?.createRelationship(from: cardA, to: cardB, type: rt, createReverse: false)
        cardA.cachedOutgoingEdgeCount = 1
        cardB.cachedIncomingEdgeCount = 1

        try mgr.deleteCard(cardA)

        // Card A is deleted, B's count should be decremented
        #expect(cardB.cachedIncomingEdgeCount == 0)
        let cards = try ctx.fetch(FetchDescriptor<Card>())
        #expect(cards.count == 1) // only cardB remains
    }

    @Test("deleteCards batch-deletes multiple cards")
    @MainActor
    func deleteCardsBatch() async throws {
        let (mgr, ctx) = try makeManager()
        let a = try mgr.createCard(kind: .characters, name: "A")
        let b = try mgr.createCard(kind: .characters, name: "B")
        _ = try mgr.createCard(kind: .characters, name: "C")

        try mgr.deleteCards([a, b])

        let remaining = try ctx.fetch(FetchDescriptor<Card>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.name == "C")
    }

    // MARK: - Duplication

    @Test("duplicateCard copies name with (Copy) suffix")
    @MainActor
    func duplicateCardCopiesName() async throws {
        let (mgr, _) = try makeManager()
        let original = try mgr.createCard(kind: .characters, name: "Hero", subtitle: "Bold", detailedText: "Details")
        let dup = try mgr.duplicateCard(original)

        #expect(dup.name == "Hero (Copy)")
        #expect(dup.subtitle == "Bold")
        #expect(dup.detailedText == "Details")
        #expect(dup.kind == .characters)
    }

    @Test("duplicateCard does not copy relationships")
    @MainActor
    func duplicateCardNoEdges() async throws {
        let (mgr, ctx) = try makeManager()
        let cardA = try mgr.createCard(kind: .characters, name: "A")
        let cardB = try mgr.createCard(kind: .artifacts, name: "B")
        let rt = TestFixtures.createRelationType(context: ctx)
        try ctx.save()
        _ = try mgr.relationshipManager?.createRelationship(from: cardA, to: cardB, type: rt, createReverse: false)

        let dup = try mgr.duplicateCard(cardA)
        let dupEdges = mgr.relationshipManager?.getAllEdges(for: dup) ?? []
        #expect(dupEdges.isEmpty)
    }

    @Test("duplicateCard copies epoch properties")
    @MainActor
    func duplicateCardCopiesEpoch() async throws {
        let (mgr, _) = try makeManager()
        let original = try mgr.createCard(kind: .timelines, name: "Timeline")
        original.epochDate = Date(timeIntervalSince1970: 0)
        original.epochDescription = "The Beginning"

        let dup = try mgr.duplicateCard(original)
        #expect(dup.epochDate == original.epochDate)
        #expect(dup.epochDescription == "The Beginning")
    }

    // MARK: - Type Change

    @Test("changeCardType removes edges and returns count")
    @MainActor
    func changeTypeRemovesEdges() async throws {
        let (mgr, ctx) = try makeManager()
        let card = try mgr.createCard(kind: .characters, name: "Hero")
        let target = try mgr.createCard(kind: .artifacts, name: "Sword")
        let rt = TestFixtures.createRelationType(context: ctx)
        try ctx.save()
        _ = try mgr.relationshipManager?.createRelationship(from: card, to: target, type: rt, createReverse: false)

        let deleted = try mgr.changeCardType(card, to: .locations)
        #expect(deleted >= 1)
        #expect(card.kind == .locations)
    }

    @Test("changeCardType is no-op when kind unchanged")
    @MainActor
    func changeTypeSameKindNoop() async throws {
        let (mgr, _) = try makeManager()
        let card = try mgr.createCard(kind: .characters, name: "Hero")
        let deleted = try mgr.changeCardType(card, to: .characters)
        #expect(deleted == 0)
    }

    // MARK: - Validation & Search

    @Test("validateCardCreation rejects empty name")
    @MainActor
    func validateRejectsEmptyName() async throws {
        let (mgr, _) = try makeManager()
        #expect(!mgr.validateCardCreation(name: "", kind: .characters))
    }

    @Test("searchCards matches case-insensitively")
    @MainActor
    func searchCaseInsensitive() async throws {
        let (mgr, _) = try makeManager()
        _ = try mgr.createCard(kind: .characters, name: "Sir Aldric")
        _ = try mgr.createCard(kind: .locations, name: "Westport")

        let results = mgr.searchCards(query: "sir")
        #expect(results.count == 1)
        #expect(results.first?.name == "Sir Aldric")
    }
}
