//
//  CardRepositoryTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 1.2: Comprehensive tests for CardRepository
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

@Suite("Card Repository", .serialized)
struct CardRepositoryTests {

    // MARK: - Fetch All Tests

    @Test("Fetch all cards returns sorted by name")
    @MainActor
    func fetchAllCardsSorted() async throws {
        let context = try TestFixtures.makeIsolatedContext()
        let repo = CardRepository(modelContext: context)

        // Create test cards in random order
        let _ = TestFixtures.createSampleCharacter(name: "Zebra", context: context)
        let _ = TestFixtures.createSampleCharacter(name: "Alpha", context: context)
        let _ = TestFixtures.createSampleCharacter(name: "Mike", context: context)
        try context.save()

        let cards = repo.fetchAll()

        #expect(cards.count >= 3)
        // Should be sorted alphabetically
        let names = cards.map { $0.name }
        let sortedNames = names.sorted()
        #expect(names == sortedNames)
    }

    // MARK: - Fetch by Kind Tests

    @Test("Fetch cards by kind filters correctly")
    @MainActor
    func fetchCardsByKind() async throws {
        let context = try TestFixtures.makeIsolatedContext()
        let repo = CardRepository(modelContext: context)

        // Create cards of different kinds
        let character = TestFixtures.createSampleCharacter(name: "Hero", context: context)
        let location = TestFixtures.createSampleLocation(name: "Castle", context: context)
        try context.save()

        let characters = repo.fetch(byKind: .characters)
        let locations = repo.fetch(byKind: .locations)

        // Verify filtering
        #expect(characters.contains { $0.id == character.id })
        #expect(!characters.contains { $0.id == location.id })
        #expect(locations.contains { $0.id == location.id })
        #expect(!locations.contains { $0.id == character.id })
    }

    @Test("Fetch cards by multiple kinds")
    @MainActor
    func fetchCardsByMultipleKinds() async throws {
        let context = try TestFixtures.makeIsolatedContext()
        let repo = CardRepository(modelContext: context)

        let character = TestFixtures.createSampleCharacter(name: "Hero", context: context)
        let location = TestFixtures.createSampleLocation(name: "Castle", context: context)
        try context.save()

        let cards = repo.fetch(byKinds: [.characters, .locations])

        #expect(cards.count >= 2)
        #expect(cards.contains { $0.id == character.id })
        #expect(cards.contains { $0.id == location.id })
    }

    // MARK: - Fetch by ID Tests

    @Test("Fetch card by UUID finds correct card")
    @MainActor
    func fetchCardByUUID() async throws {
        let context = try TestFixtures.makeIsolatedContext()
        let repo = CardRepository(modelContext: context)

        let card = TestFixtures.createSampleCharacter(name: "Target", context: context)
        try context.save()

        let fetched = repo.fetch(byUUID: card.id)

        #expect(fetched != nil)
        #expect(fetched?.id == card.id)
        #expect(fetched?.name == "Target")
    }

    @Test("Fetch card by UUID returns nil for non-existent UUID")
    @MainActor
    func fetchCardByNonExistentUUID() async throws {
        let context = try TestFixtures.makeIsolatedContext()
        let repo = CardRepository(modelContext: context)

        let randomUUID = UUID()
        let fetched = repo.fetch(byUUID: randomUUID)

        #expect(fetched == nil)
    }

    // MARK: - Search Tests

    @Test("Search finds cards by name")
    @MainActor
    func searchCardsByName() async throws {
        let context = try TestFixtures.makeIsolatedContext()
        let repo = CardRepository(modelContext: context)

        let _ = TestFixtures.createSampleCharacter(name: "Aragorn", context: context)
        let _ = TestFixtures.createSampleCharacter(name: "Gandalf", context: context)
        try context.save()

        let results = repo.search(query: "aragorn")

        #expect(results.count >= 1)
        #expect(results.contains { $0.name.lowercased().contains("aragorn") })
    }

    @Test("Search returns all cards for empty query")
    @MainActor
    func searchWithEmptyQuery() async throws {
        let context = try TestFixtures.makeIsolatedContext()
        let repo = CardRepository(modelContext: context)

        let _ = TestFixtures.createSampleCharacter(name: "Test1", context: context)
        let _ = TestFixtures.createSampleCharacter(name: "Test2", context: context)
        try context.save()

        let results = repo.search(query: "")

        #expect(results.count >= 2)
    }

    // MARK: - Insert and Delete Tests

    @Test("Insert card adds to context")
    @MainActor
    func insertCard() async throws {
        let context = try TestFixtures.makeIsolatedContext()
        let repo = CardRepository(modelContext: context)

        let card = try repo.createCard(kind: .characters, name: "New Character", subtitle: "", detailedText: "")

        let fetched = repo.fetch(byUUID: card.id)
        #expect(fetched != nil)
        #expect(fetched?.name == "New Character")
    }

    @Test("Delete card removes from context")
    @MainActor
    func deleteCard() async throws {
        let context = try TestFixtures.makeIsolatedContext()
        let repo = CardRepository(modelContext: context)

        let card = TestFixtures.createSampleCharacter(name: "ToDelete", context: context)
        try context.save()

        let cardID = card.id

        try repo.deleteCard(card)

        let fetched = repo.fetch(byUUID: cardID)
        #expect(fetched == nil)
    }

    // MARK: - Count Tests

    @Test("Count operations return correct values")
    @MainActor
    func countOperations() async throws {
        let context = try TestFixtures.makeIsolatedContext()
        let repo = CardRepository(modelContext: context)

        // Create known quantities
        let _ = TestFixtures.createSampleCharacter(name: "Char1", context: context)
        let _ = TestFixtures.createSampleCharacter(name: "Char2", context: context)
        let _ = TestFixtures.createSampleLocation(name: "Loc1", context: context)
        try context.save()

        let totalCount = repo.countAll()
        let characterCount = repo.count(ofKind: .characters)

        #expect(totalCount >= 3)
        #expect(characterCount >= 2)
    }
}
