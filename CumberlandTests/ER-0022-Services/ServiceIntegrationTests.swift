//
//  ServiceIntegrationTests.swift
//  CumberlandTests
//
//  Created for ER-0022 Phase 5: Testing and Validation
//  Integration tests for CardOperationManager, RelationshipManager, and Repositories.
//
//  Note: These tests use an in-memory ModelContext to avoid import issues.
//
//  Swift Testing suite that wires together CardOperationManager,
//  RelationshipManager, CardRepository, EdgeRepository, and StructureRepository
//  with an in-memory SwiftData container. Verifies CRUD operations, relationship
//  creation/deletion, and repository query correctness end-to-end.
//

import Foundation
import Testing
import SwiftData

/// Integration tests for ER-0022 Phase 1 & 2 services and repositories
///
/// Tests the following components:
/// - CardOperationManager (Phase 1)
/// - RelationshipManager (Phase 1)
/// - CardRepository (Phase 2)
/// - EdgeRepository (Phase 2)
/// - StructureRepository (Phase 2)
/// - QueryService (Phase 2)
/// - ServiceContainer (Phase 4)
///
/// These tests verify that services correctly interact with SwiftData
/// and that the dependency injection infrastructure works as expected.
@Suite("Service Integration Tests")
@MainActor
struct ServiceIntegrationTests {

    // MARK: - Test Setup Helpers

    /// Create an in-memory ModelContext for testing
    func createTestContext() throws -> ModelContext {
        let schema = Schema(AppSchemaV5.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    /// Create a test card with specified properties
    func createTestCard(context: ModelContext, kind: Kinds, name: String) -> Card {
        let card = Card(kind: kind, name: name, subtitle: "", detailedText: "Test card")
        context.insert(card)
        return card
    }

    // MARK: - ServiceContainer Tests

    @Test("ServiceContainer initializes all services correctly")
    func testServiceContainerInitialization() throws {
        let context = try createTestContext()
        let container = ServiceContainer(modelContext: context)

        // Verify all repositories are initialized
        #expect(container.cardRepository !== nil, "CardRepository should be initialized")
        #expect(container.edgeRepository !== nil, "EdgeRepository should be initialized")
        #expect(container.structureRepository !== nil, "StructureRepository should be initialized")
        #expect(container.queryService !== nil, "QueryService should be initialized")

        // Verify all services are initialized
        #expect(container.cardOperations !== nil, "CardOperationManager should be initialized")
        #expect(container.relationshipManager !== nil, "RelationshipManager should be initialized")
        #expect(container.imageProcessing !== nil, "ImageProcessingService should be accessible")

        // Verify context is accessible
        #expect(container.modelContext === context, "ModelContext should match initialization context")
    }

    @Test("ServiceContainer.preview() creates valid test instance")
    func testServiceContainerPreview() {
        let container = ServiceContainer.preview()

        #expect(container.cardRepository !== nil, "Preview container should have CardRepository")
        #expect(container.cardOperations !== nil, "Preview container should have CardOperationManager")

        // Should be using in-memory store for previews
        // We can verify this works by creating a card and ensuring it doesn't persist
        let card = Card(kind: .characters, name: "Preview Test Card")
        container.modelContext.insert(card)
        try? container.modelContext.save()

        // Card should exist in context
        let allCards = container.cardRepository.fetchAll()
        #expect(allCards.count == 1, "Preview container should store cards in memory")
    }

    // MARK: - CardOperationManager Tests

    @Test("CardOperationManager creates card successfully")
    func testCreateCard() throws {
        let context = try createTestContext()
        let manager = CardOperationManager(modelContext: context)

        let card = try manager.createCard(
            kind: .characters,
            name: "Test Character",
            subtitle: "Hero",
            detailedText: "A brave warrior"
        )

        #expect(card.name == "Test Character", "Card should have correct name")
        #expect(card.subtitle == "Hero", "Card should have correct subtitle")
        #expect(card.kind == .characters, "Card should have correct kind")
        #expect(card.detailedText == "A brave warrior", "Card should have correct detailed text")

        // Verify card was persisted
        let fetch = FetchDescriptor<Card>()
        let savedCards = try context.fetch(fetch)
        #expect(savedCards.count == 1, "Card should be saved to context")
    }

    @Test("CardOperationManager deletes card successfully")
    func testDeleteCard() throws {
        let context = try createTestContext()
        let manager = CardOperationManager(modelContext: context)

        // Create a card
        let card = try manager.createCard(kind: .locations, name: "Test Location")

        // Verify it exists
        var fetch = FetchDescriptor<Card>()
        var cards = try context.fetch(fetch)
        #expect(cards.count == 1, "Card should exist before deletion")

        // Delete the card
        try manager.deleteCard(card)

        // Verify it's gone
        fetch = FetchDescriptor<Card>()
        cards = try context.fetch(fetch)
        #expect(cards.count == 0, "Card should be deleted from context")
    }

    @Test("CardOperationManager deletes multiple cards")
    func testDeleteMultipleCards() throws {
        let context = try createTestContext()
        let manager = CardOperationManager(modelContext: context)

        // Create multiple cards
        let card1 = try manager.createCard(kind: .characters, name: "Character 1")
        let card2 = try manager.createCard(kind: .characters, name: "Character 2")
        let card3 = try manager.createCard(kind: .locations, name: "Location 1")

        // Delete two of them
        try manager.deleteCards([card1, card3])

        // Verify only card2 remains
        let fetch = FetchDescriptor<Card>()
        let remainingCards = try context.fetch(fetch)
        #expect(remainingCards.count == 1, "Only one card should remain")
        #expect(remainingCards.first?.name == "Character 2", "Correct card should remain")
    }

    @Test("CardOperationManager duplicates card with properties")
    func testDuplicateCard() throws {
        let context = try createTestContext()
        let manager = CardOperationManager(modelContext: context)

        // Create original card
        let original = try manager.createCard(
            kind: .artifacts,
            name: "Original Sword",
            subtitle: "Legendary Weapon",
            detailedText: "A powerful ancient blade"
        )

        // Duplicate it
        let duplicate = try manager.duplicateCard(original)

        #expect(duplicate.name == "Original Sword (Copy)", "Duplicate should have '(Copy)' suffix")
        #expect(duplicate.subtitle == "Legendary Weapon", "Duplicate should copy subtitle")
        #expect(duplicate.detailedText == "A powerful ancient blade", "Duplicate should copy detailed text")
        #expect(duplicate.kind == .artifacts, "Duplicate should copy kind")

        // Verify both exist
        let fetch = FetchDescriptor<Card>()
        let allCards = try context.fetch(fetch)
        #expect(allCards.count == 2, "Should have original and duplicate")
    }

    // MARK: - RelationshipManager Tests

    @Test("RelationshipManager creates relationship successfully")
    func testCreateRelationship() throws {
        let context = try createTestContext()
        let manager = RelationshipManager(modelContext: context)

        // Create two cards
        let character = createTestCard(context: context, kind: .characters, name: "Hero")
        let sword = createTestCard(context: context, kind: .artifacts, name: "Legendary Sword")

        // Find or create a relationship type
        let relationType = try getOrCreateRelationType(context: context, code: "owns", forward: "owns", backward: "owned-by")

        // Create relationship
        let edge = try manager.createRelationship(
            from: character,
            to: sword,
            type: relationType,
            note: "Inherited from father"
        )

        #expect(edge.from === character, "Edge should have correct source")
        #expect(edge.to === sword, "Edge should have correct target")
        #expect(edge.type === relationType, "Edge should have correct type")
        #expect(edge.note == "Inherited from father", "Edge should have correct note")

        // Verify edge was persisted
        let fetch = FetchDescriptor<CardEdge>()
        let savedEdges = try context.fetch(fetch)
        #expect(savedEdges.count >= 1, "At least forward edge should be saved")
    }

    @Test("RelationshipManager prevents duplicate relationships")
    func testPreventDuplicateRelationship() throws {
        let context = try createTestContext()
        let manager = RelationshipManager(modelContext: context)

        let cardA = createTestCard(context: context, kind: .characters, name: "Character A")
        let cardB = createTestCard(context: context, kind: .characters, name: "Character B")
        let relationType = try getOrCreateRelationType(context: context, code: "knows", forward: "knows", backward: "known-by")

        // Create first relationship
        try manager.createRelationship(from: cardA, to: cardB, type: relationType, createReverse: false)

        // Attempt to create duplicate - should throw
        do {
            try manager.createRelationship(from: cardA, to: cardB, type: relationType, createReverse: false)
            Issue.record("Should have thrown RelationshipError.alreadyExists")
        } catch {
            // Expected to throw
            #expect(true, "Correctly prevented duplicate relationship")
        }
    }

    @Test("RelationshipManager removes relationship")
    func testRemoveRelationship() throws {
        let context = try createTestContext()
        let manager = RelationshipManager(modelContext: context)

        let cardA = createTestCard(context: context, kind: .locations, name: "Location A")
        let cardB = createTestCard(context: context, kind: .buildings, name: "Building B")
        let relationType = try getOrCreateRelationType(context: context, code: "contains", forward: "contains", backward: "part-of")

        // Create relationship
        try manager.createRelationship(from: cardA, to: cardB, type: relationType)

        // Verify it exists
        var fetch = FetchDescriptor<CardEdge>()
        var edges = try context.fetch(fetch)
        let initialCount = edges.count
        #expect(initialCount >= 1, "Relationship should exist")

        // Remove it
        try manager.removeRelationship(between: cardA, and: cardB)

        // Verify it's gone
        fetch = FetchDescriptor<CardEdge>()
        edges = try context.fetch(fetch)
        #expect(edges.count == 0, "All edges between cards should be removed")
    }

    @Test("RelationshipManager queries outgoing edges")
    func testGetOutgoingEdges() throws {
        let context = try createTestContext()
        let manager = RelationshipManager(modelContext: context)

        let hero = createTestCard(context: context, kind: .characters, name: "Hero")
        let sword = createTestCard(context: context, kind: .artifacts, name: "Sword")
        let shield = createTestCard(context: context, kind: .artifacts, name: "Shield")
        let relationType = try getOrCreateRelationType(context: context, code: "owns", forward: "owns", backward: "owned-by")

        // Create two outgoing relationships from hero
        try manager.createRelationship(from: hero, to: sword, type: relationType, createReverse: false)
        try manager.createRelationship(from: hero, to: shield, type: relationType, createReverse: false)

        // Query outgoing edges
        let outgoing = manager.getOutgoingEdges(for: hero)

        #expect(outgoing.count == 2, "Hero should have 2 outgoing edges")
    }

    // MARK: - CardRepository Tests

    @Test("CardRepository fetches all cards")
    func testCardRepositoryFetchAll() throws {
        let context = try createTestContext()
        let repo = CardRepository(modelContext: context)

        // Create test cards
        _ = createTestCard(context: context, kind: .characters, name: "Character 1")
        _ = createTestCard(context: context, kind: .locations, name: "Location 1")
        _ = createTestCard(context: context, kind: .artifacts, name: "Artifact 1")
        try context.save()

        let allCards = repo.fetchAll()
        #expect(allCards.count == 3, "Should fetch all 3 cards")
    }

    @Test("CardRepository fetches cards by kind")
    func testCardRepositoryFetchByKind() throws {
        let context = try createTestContext()
        let repo = CardRepository(modelContext: context)

        _ = createTestCard(context: context, kind: .characters, name: "Character 1")
        _ = createTestCard(context: context, kind: .characters, name: "Character 2")
        _ = createTestCard(context: context, kind: .locations, name: "Location 1")
        try context.save()

        let characters = repo.fetch(byKind: .characters)
        #expect(characters.count == 2, "Should fetch only character cards")

        let locations = repo.fetch(byKind: .locations)
        #expect(locations.count == 1, "Should fetch only location cards")
    }

    @Test("CardRepository searches cards by text")
    func testCardRepositorySearch() throws {
        let context = try createTestContext()
        let repo = CardRepository(modelContext: context)

        _ = createTestCard(context: context, kind: .characters, name: "Dark Lord Voldemort")
        _ = createTestCard(context: context, kind: .characters, name: "Harry Potter")
        _ = createTestCard(context: context, kind: .locations, name: "Dark Forest")
        try context.save()

        let darkResults = repo.search(query: "dark")
        #expect(darkResults.count == 2, "Should find 2 cards containing 'dark'")

        let harryResults = repo.search(query: "harry")
        #expect(harryResults.count == 1, "Should find 1 card containing 'harry'")
    }

    @Test("CardRepository fetches card by UUID")
    func testCardRepositoryFetchByUUID() throws {
        let context = try createTestContext()
        let repo = CardRepository(modelContext: context)

        let card = createTestCard(context: context, kind: .vehicles, name: "Starship")
        try context.save()

        let uuid = card.id
        let fetched = repo.fetch(byUUID: uuid)

        #expect(fetched !== nil, "Should fetch card by UUID")
        #expect(fetched?.name == "Starship", "Should fetch correct card")
    }

    // MARK: - EdgeRepository Tests

    @Test("EdgeRepository fetches edges for card")
    func testEdgeRepositoryFetchForCard() throws {
        let context = try createTestContext()
        let edgeRepo = EdgeRepository(modelContext: context)
        let manager = RelationshipManager(modelContext: context)

        let hero = createTestCard(context: context, kind: .characters, name: "Hero")
        let sword = createTestCard(context: context, kind: .artifacts, name: "Sword")
        let relationType = try getOrCreateRelationType(context: context, code: "owns", forward: "owns", backward: "owned-by")

        try manager.createRelationship(from: hero, to: sword, type: relationType)
        try context.save()

        let edges = edgeRepo.fetchEdges(for: hero)
        #expect(edges.count >= 1, "Should fetch edges for card")
    }

    // MARK: - QueryService Tests

    @Test("QueryService provides access to common queries")
    func testQueryServiceGetAllCards() throws {
        let context = try createTestContext()
        let queryService = QueryService(modelContext: context)

        _ = createTestCard(context: context, kind: .characters, name: "Character 1")
        _ = createTestCard(context: context, kind: .locations, name: "Location 1")
        try context.save()

        let allCards = queryService.getAllCards()
        #expect(allCards.count == 2, "QueryService should return all cards")
    }

    // MARK: - Helper Functions

    /// Get or create a RelationType for testing
    func getOrCreateRelationType(context: ModelContext, code: String, forward: String, backward: String) throws -> RelationType {
        // Try to fetch existing
        let fetch = FetchDescriptor<RelationType>(
            predicate: #Predicate { $0.code == code }
        )
        if let existing = try context.fetch(fetch).first {
            return existing
        }

        // Create new
        let relationType = RelationType(code: code, forwardVerbiage: forward, backwardVerbiage: backward)
        context.insert(relationType)
        try context.save()
        return relationType
    }
}
