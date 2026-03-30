// CardModelTests.swift
// CumberlandTests

import Testing
import SwiftData
import Foundation
@testable import Cumberland

@Suite("Card Model Tests", .serialized)
struct CardModelTests {

    // MARK: - Kind Computed Property

    @Test("kind computed property decodes from kindRaw")
    @MainActor
    func kindDecodesFromRaw() async throws {
        let card = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        #expect(card.kind == .characters)
        #expect(card.kindRaw == Kinds.characters.rawValue)
    }

    @Test("kind defaults to .projects for unknown kindRaw")
    @MainActor
    func kindDefaultsForUnknownRaw() async throws {
        let card = Card(name: "Test", subtitle: "", detailedText: "")
        card.kindRaw = "BogusKind"
        #expect(card.kind == .projects)
    }

    // MARK: - SizeCategory

    @Test("sizeCategory read/write through sizeCategoryRaw")
    @MainActor
    func sizeCategoryRoundTrip() async throws {
        let card = Card(name: "Test", subtitle: "", detailedText: "")
        card.sizeCategory = .large
        #expect(card.sizeCategoryRaw == SizeCategory.large.rawValue)
        #expect(card.sizeCategory == .large)

        card.sizeCategory = .compact
        #expect(card.sizeCategoryRaw == SizeCategory.compact.rawValue)
        #expect(card.sizeCategory == .compact)
    }

    // MARK: - Normalized Search Text

    @Test("recomputeNormalizedSearchText combines fields")
    @MainActor
    func normalizedSearchTextCombinesFields() async throws {
        let card = Card(name: "Héro", subtitle: "Knight", detailedText: "A brave soul", author: "Tolkien")
        // After init, normalizedSearchText should contain folded text
        #expect(card.normalizedSearchText.contains("hero"))
        #expect(card.normalizedSearchText.contains("knight"))
        #expect(card.normalizedSearchText.contains("a brave soul"))
        #expect(card.normalizedSearchText.contains("tolkien"))
    }

    @Test("normalizedSearchText updates on name change")
    @MainActor
    func normalizedSearchTextUpdatesOnNameChange() async throws {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()
        let card = Card(name: "Old Name", subtitle: "", detailedText: "")
        ctx.insert(card)
        try ctx.save()
        #expect(card.normalizedSearchText.contains("old name"))

        card.name = "New Name"
        // SwiftData-managed objects may bypass didSet; explicitly recompute
        card.recomputeNormalizedSearchText()
        #expect(card.normalizedSearchText.contains("new name"))
        #expect(!card.normalizedSearchText.contains("old name"))
    }

    // MARK: - Draft Map Work

    @Test("saveDraftMapWork persists data and timestamp")
    @MainActor
    func saveDraftMapWorkPersists() async throws {
        let card = Card(kind: .maps, name: "World Map", subtitle: "", detailedText: "")
        let data = Data("test drawing".utf8)

        card.saveDraftMapWork(data, method: "draw", wizardStep: "step2")

        #expect(card.draftMapWorkData == data)
        #expect(card.draftMapMethodRaw == "draw")
        #expect(card.draftMapWizardStepRaw == "step2")
        #expect(card.draftMapWorkTimestamp != nil)
        #expect(card.hasDraftMapWork == true)
    }

    @Test("clearDraftMapWork resets all draft fields")
    @MainActor
    func clearDraftMapWorkResets() async throws {
        let card = Card(kind: .maps, name: "Map", subtitle: "", detailedText: "")
        card.saveDraftMapWork(Data("data".utf8), method: "draw")
        card.clearDraftMapWork()

        #expect(card.draftMapWorkData == nil)
        #expect(card.draftMapWorkTimestamp == nil)
        #expect(card.draftMapMethodRaw == nil)
        #expect(card.draftMapWizardStepRaw == nil)
        #expect(card.hasDraftMapWork == false)
    }

    @Test("draftMapWorkAge returns correct interval")
    @MainActor
    func draftMapWorkAgeReturnsInterval() async throws {
        let card = Card(kind: .maps, name: "Map", subtitle: "", detailedText: "")
        card.saveDraftMapWork(Data("data".utf8), method: "draw")

        let age = card.draftMapWorkAge
        #expect(age != nil)
        #expect(age! >= 0)
        #expect(age! < 2.0) // Should be very recent
    }

    @Test("draftMapWorkAge returns nil when no draft")
    @MainActor
    func draftMapWorkAgeNilWithoutDraft() async throws {
        let card = Card(kind: .maps, name: "Map", subtitle: "", detailedText: "")
        #expect(card.draftMapWorkAge == nil)
    }

    @Test("hasDraftMapWork returns false for empty data")
    @MainActor
    func hasDraftMapWorkFalseForEmpty() async throws {
        let card = Card(kind: .maps, name: "Map", subtitle: "", detailedText: "")
        #expect(card.hasDraftMapWork == false)
    }

    // MARK: - cleanupBeforeDeletion

    @Test("cleanupBeforeDeletion removes edges and adjusts cached counts")
    @MainActor
    func cleanupRemovesEdgesAndAdjustsCounts() async throws {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()

        let cardA = TestFixtures.createSampleCharacter(name: "Card A", context: ctx)
        let cardB = TestFixtures.createSampleCharacter(name: "Card B", context: ctx)
        let relType = TestFixtures.createRelationType(context: ctx)
        TestFixtures.createEdge(from: cardA, to: cardB, type: relType, context: ctx)

        cardA.cachedOutgoingEdgeCount = 1
        cardB.cachedIncomingEdgeCount = 1
        try ctx.save()

        cardA.cleanupBeforeDeletion(in: ctx)

        // B's incoming count should be decremented
        #expect(cardB.cachedIncomingEdgeCount == 0)

        // Edges referencing A should be deleted
        let edgeFetch = FetchDescriptor<CardEdge>()
        let remainingEdges = try ctx.fetch(edgeFetch)
        #expect(remainingEdges.isEmpty)
    }

    @Test("cleanupBeforeDeletion nullifies board primaryCard")
    @MainActor
    func cleanupNullifiesBoardPrimaryCard() async throws {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()

        let card = TestFixtures.createSampleCharacter(name: "Primary", context: ctx)
        let board = TestFixtures.createBoard(name: "Board", primaryCard: card, context: ctx)
        try ctx.save()

        card.cleanupBeforeDeletion(in: ctx)

        #expect(board.primaryCard == nil)
    }

    @Test("cleanupBeforeDeletion deletes associated boardNodes")
    @MainActor
    func cleanupDeletesBoardNodes() async throws {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()

        let card = TestFixtures.createSampleCharacter(name: "OnBoard", context: ctx)
        let board = TestFixtures.createBoard(name: "Board", context: ctx)
        let node = BoardNode(board: board, card: card, posX: 10, posY: 20)
        ctx.insert(node)
        try ctx.save()

        card.cleanupBeforeDeletion(in: ctx)

        let nodeFetch = FetchDescriptor<BoardNode>()
        let remainingNodes = try ctx.fetch(nodeFetch)
        #expect(remainingNodes.isEmpty)
    }

    // MARK: - Thumbnail URL

    @Test("thumbnailURL returns nil when no thumbnailData")
    @MainActor
    func thumbnailURLNilWithoutData() async throws {
        let card = Card(name: "NoThumb", subtitle: "", detailedText: "")
        #expect(card.thumbnailURL == nil)
    }

    // MARK: - Transfer Representation

    @Test("createTransferRepresentation returns correct data")
    @MainActor
    func transferRepresentationCorrect() async throws {
        let card = Card(kind: .characters, name: "Hero", subtitle: "Brave", detailedText: "Details")
        let transfer = card.createTransferRepresentation()

        #expect(transfer.id == card.id)
        #expect(transfer.name == "Hero")
        #expect(transfer.kindRaw == Kinds.characters.rawValue)
    }
}
