//
//  SearchEngineTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 1.4: Comprehensive tests for SwiftDataSearchEngine
//  Tests full-text search, ranking, snippet generation, and performance
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

@Suite("Search Engine", .serialized)
struct SearchEngineTests {

    // MARK: - Helper Methods

    /// Helper to create a card with normalized search text populated
    @MainActor
    private func createCard(kind: Kinds, name: String, subtitle: String = "", detailedText: String = "", author: String? = nil, context: ModelContext) throws -> Card {
        let mgr = CardOperationManager(modelContext: context)
        let card = try mgr.createCard(kind: kind, name: name, subtitle: subtitle, detailedText: detailedText)
        if let author = author {
            card.author = author
            card.recomputeNormalizedSearchText()
        }
        return card
    }

    // MARK: - Basic Search Tests

    @Test("Search by name returns exact match")
    @MainActor
    func searchByName() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let alice = TestFixtures.createSampleCharacter(name: "Alice Wonderland", context: context)
        context.save()

        let results = await engine.search("Alice", maxResults: 10)

        #expect(results.count == 1)
        #expect(results.first?.card.id == alice.id)
        #expect(results.first?.matchType == .name)
    }

    @Test("Search by subtitle returns match")
    @MainActor
    func searchBySubtitle() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let _ = try createCard(kind: .characters, name: "Hero", subtitle: "Brave warrior", detailedText: "", context: context)

        let results = await engine.search("warrior", maxResults: 10)

        #expect(results.count == 1)
        #expect(results.first?.matchType == .subtitle)
        #expect(results.first?.preview == "Brave warrior")
    }

    @Test("Search by detailed text returns match with snippet")
    @MainActor
    func searchByDetailedText() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let _ = try createCard(kind: .locations, name: "Castle", subtitle: "", detailedText: "A magnificent fortress with tall towers", context: context)

        let results = await engine.search("fortress", maxResults: 10)

        #expect(results.count == 1)
        #expect(results.first?.matchType == .details)
        #expect(results.first?.preview.contains("fortress") == true)
    }

    @Test("Search returns empty for no matches")
    @MainActor
    func searchNoMatches() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let _ = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        try context.save()

        let results = await engine.search("Zephyr", maxResults: 10)

        #expect(results.isEmpty)
    }

    @Test("Search with empty query returns empty")
    @MainActor
    func searchEmptyQuery() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let _ = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        try context.save()

        let results = await engine.search("", maxResults: 10)

        #expect(results.isEmpty)
    }

    @Test("Search with whitespace-only query returns empty")
    @MainActor
    func searchWhitespaceQuery() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let _ = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        try context.save()

        let results = await engine.search("   ", maxResults: 10)

        #expect(results.isEmpty)
    }

    // MARK: - Case Sensitivity Tests

    @Test("Search is case insensitive")
    @MainActor
    func searchCaseInsensitive() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let card = TestFixtures.createSampleCharacter(name: "Dragon Slayer", context: context)
        try context.save()

        let results1 = await engine.search("dragon", maxResults: 10)
        let results2 = await engine.search("DRAGON", maxResults: 10)
        let results3 = await engine.search("DrAgOn", maxResults: 10)

        #expect(results1.count == 1)
        #expect(results2.count == 1)
        #expect(results3.count == 1)
    }

    @Test("Search normalizes diacritics")
    @MainActor
    func searchNormalizesDiacritics() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let card = try createCard(kind: .locations, name: "Café Français", subtitle: "", detailedText: "", context: context)
        context.insert(card)
        try context.save()

        let results = await engine.search("cafe", maxResults: 10)

        #expect(results.count == 1)
        #expect(results.first?.card.id == card.id)
    }

    // MARK: - Ranking Tests

    @Test("Name matches rank higher than subtitle")
    @MainActor
    func nameRankingPriority() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let card1 = try createCard(kind: .characters, name: "Dragon Master", subtitle: "", detailedText: "", context: context)
        let card2 = try createCard(kind: .characters, name: "Knight", subtitle: "Dragon slayer", detailedText: "", context: context)
        context.insert(card1)
        context.insert(card2)
        try context.save()

        let results = await engine.search("dragon", maxResults: 10)

        #expect(results.count >= 1)
        // First result should be the name match
        #expect(results.first?.matchType == .name)
    }

    @Test("Results sorted alphabetically by name")
    @MainActor
    func resultsSortedByName() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let _ = try createCard(kind: .characters, name: "Zara the Brave", subtitle: "", detailedText: "", context: context)
        let _ = try createCard(kind: .characters, name: "Alice the Brave", subtitle: "", detailedText: "", context: context)
        let _ = try createCard(kind: .characters, name: "Marcus the Brave", subtitle: "", detailedText: "", context: context)

        let results = await engine.search("brave", maxResults: 10)

        #expect(results.count >= 3)
        // Should be sorted: Alice, Marcus, Zara
        let names = results.map { $0.card.name }
        let sortedNames = names.sorted()
        #expect(names == sortedNames)
    }

    // MARK: - Max Results Tests

    @Test("Respects max results limit")
    @MainActor
    func respectsMaxResults() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        // Create 10 cards with "hero" in the name
        for i in 0..<10 {
            let card = try createCard(kind: .characters, name: "Hero \(i)", subtitle: "", detailedText: "", context: context)
            context.insert(card)
        }
        try context.save()

        let results = await engine.search("hero", maxResults: 5)

        #expect(results.count == 5)
    }

    // MARK: - Snippet Generation Tests

    @Test("Snippet includes query context")
    @MainActor
    func snippetIncludesContext() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let longText = "The ancient kingdom was known for its magnificent library. " +
                       "Scholars from distant lands would travel for months to study the rare manuscripts."

        let _ = try createCard(kind: .locations, name: "Library", subtitle: "", detailedText: longText, context: context)

        let results = await engine.search("library", maxResults: 10)

        #expect(results.count == 1)
        #expect(results.first?.preview.lowercased().contains("library") == true)
        // Snippet should be shorter than full text
        #expect(results.first?.preview.count ?? 0 < longText.count)
    }

    @Test("Snippet handles match at start of text")
    @MainActor
    func snippetStartOfText() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let text = "Castle stands at the peak of the mountain, overlooking the valley below."
        let card = try createCard(kind: .locations, name: "Place", subtitle: "", detailedText: text, context: context)
        context.insert(card)
        try context.save()

        let results = await engine.search("castle", maxResults: 10)

        #expect(results.count == 1)
        #expect(results.first?.preview.hasPrefix("Castle") == true)
    }

    @Test("Snippet handles match at end of text")
    @MainActor
    func snippetEndOfText() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let text = "The ancient ruins contain many treasures and artifacts from the old kingdom"
        let card = try createCard(kind: .locations, name: "Place", subtitle: "", detailedText: text, context: context)
        context.insert(card)
        try context.save()

        let results = await engine.search("kingdom", maxResults: 10)

        #expect(results.count == 1)
        #expect(results.first?.preview.hasSuffix("kingdom") == true)
    }

    // MARK: - Multi-Word Query Tests

    @Test("Search handles multi-word queries")
    @MainActor
    func multiWordQuery() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let card = try createCard(kind: .characters, name: "Sir Galahad the Pure", subtitle: "", detailedText: "", context: context)
        context.insert(card)
        try context.save()

        let results = await engine.search("Sir Galahad", maxResults: 10)

        #expect(results.count == 1)
    }

    // MARK: - Partial Match Tests

    @Test("Search finds partial word matches")
    @MainActor
    func partialWordMatch() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let card = try createCard(kind: .characters, name: "Alexander", subtitle: "", detailedText: "", context: context)
        context.insert(card)
        try context.save()

        let results = await engine.search("alex", maxResults: 10)

        #expect(results.count == 1)
    }

    // MARK: - Multiple Cards Tests

    @Test("Search returns multiple matching cards")
    @MainActor
    func multipleMatches() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let card1 = try createCard(kind: .characters, name: "Fire Mage", subtitle: "", detailedText: "", context: context)
        let card2 = try createCard(kind: .artifacts, name: "Fire Sword", subtitle: "", detailedText: "", context: context)
        let card3 = try createCard(kind: .locations, name: "Tower", subtitle: "The fire tower", detailedText: "", context: context)

        context.insert(card1)
        context.insert(card2)
        context.insert(card3)
        try context.save()

        let results = await engine.search("fire", maxResults: 10)

        #expect(results.count >= 3)
    }

    // MARK: - Author Search Tests

    @Test("Search by author returns match")
    @MainActor
    func searchByAuthor() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let _ = try createCard(kind: .scenes, name: "Battle Scene", subtitle: "", detailedText: "", author: "John Smith", context: context)

        let results = await engine.search("John", maxResults: 10)

        #expect(results.count == 1)
        #expect(results.first?.matchType == .author)
    }

    // MARK: - Special Characters Tests

    @Test("Search handles special characters")
    @MainActor
    func specialCharacters() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let card = try createCard(kind: .characters, name: "O'Brien", subtitle: "", detailedText: "", context: context)
        context.insert(card)
        try context.save()

        let results = await engine.search("O'Brien", maxResults: 10)

        #expect(results.count == 1)
    }

    // MARK: - Performance Tests

    @Test("Search is performant with many cards")
    @MainActor
    func searchPerformance() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        // Create 100 cards
        for i in 0..<100 {
            let _ = try createCard(kind: .characters, name: "Character \(i)", subtitle: "Subtitle \(i)", detailedText: "Details about character \(i)", context: context)
        }
        try context.save()

        let start = Date()
        let results = await engine.search("character", maxResults: 10)
        let duration = Date().timeIntervalSince(start)

        #expect(results.count == 10)
        // Should search 100 cards in < 200ms
        #expect(duration < 0.2)
    }

    // MARK: - SearchResult Tests

    @Test("SearchResult has correct structure")
    @MainActor
    func searchResultStructure() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let engine = SwiftDataSearchEngine(context: context)

        let card = TestFixtures.createSampleCharacter(name: "Test Character", context: context)
        try context.save()

        let results = await engine.search("test", maxResults: 10)

        #expect(results.count == 1)
        let result = results.first!

        #expect(result.id == card.id)
        #expect(result.card.id == card.id)
        #expect(result.matchType == .name)
        #expect(!result.preview.isEmpty)
    }

    @Test("MatchType has system images")
    func matchTypeSystemImages() {
        #expect(SearchResult.MatchType.name.systemImage == "textformat")
        #expect(SearchResult.MatchType.subtitle.systemImage == "text.alignleft")
        #expect(SearchResult.MatchType.details.systemImage == "doc.text")
        #expect(SearchResult.MatchType.author.systemImage == "person.text.rectangle")
    }
}
