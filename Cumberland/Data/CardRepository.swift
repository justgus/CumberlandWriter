//
//  CardRepository.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 2
//

import Foundation
import SwiftData
import RealityKit

/// Repository for Card data access operations.
/// Encapsulates all SwiftData queries and operations for the Card model.
///
/// **ER-0022 Phase 2**: Abstracts SwiftData access to enable testability and dependency injection
@Observable
@MainActor
final class CardRepository {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch Operations

    /// Fetch all cards, sorted by name
    /// - Returns: Array of all cards
    func fetchAll() -> [Card] {
        let fetch = FetchDescriptor<Card>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch cards filtered by kind
    /// - Parameter kind: The card kind to filter by
    /// - Returns: Array of cards matching the kind
    func fetch(byKind kind: Kinds) -> [Card] {
        let kindRaw = kind.rawValue
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { $0.kindRaw == kindRaw },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch a single card by its persistent identifier
    /// - Parameter id: The persistent identifier
    /// - Returns: The card, or nil if not found
    func fetch(byID id: PersistentIdentifier) -> Card? {
        return modelContext.model(for: id) as? Card
    }

    /// Fetch a card by UUID
    /// - Parameter uuid: The card's UUID
    /// - Returns: The card, or nil if not found
    func fetch(byUUID uuid: UUID) -> Card? {
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == uuid }
        )
        return try? modelContext.fetch(fetch).first
    }

    /// Search cards by text query (searches name, subtitle, and detailed text)
    /// - Parameter query: The search query
    /// - Returns: Array of matching cards
    func search(query: String) -> [Card] {
        guard !query.isEmpty else { return fetchAll() }

        let lowercaseQuery = query.lowercased()

        // Use normalized search text for efficient searching
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { card in
                card.normalizedSearchText.contains(lowercaseQuery)
            },
            sortBy: [SortDescriptor(\.name)]
        )

        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch cards with images (originalImageData is not nil)
    /// - Returns: Array of cards with images
    func fetchCardsWithImages() -> [Card] {
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { $0.originalImageData != nil },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch cards by multiple kinds
    /// - Parameter kinds: Array of kinds to filter by
    /// - Returns: Array of cards matching any of the kinds
    func fetch(byKinds kinds: [Kinds]) -> [Card] {
        let kindRawValues = kinds.map { $0.rawValue }
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { card in
                kindRawValues.contains(card.kindRaw)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch cards assigned to a specific structure element
    /// - Parameter element: The structure element
    /// - Returns: Array of cards assigned to this element
    func fetch(assignedTo element: StructureElement) -> [Card] {
        // Return cards from the element's relationship directly
        return element.assignedCards ?? []
    }

    /// Fetch cards not assigned to any structure (backlog cards)
    /// - Returns: Array of unassigned cards
    func fetchUnassignedCards() -> [Card] {
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { card in
                card.structureElements?.isEmpty ?? true
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    // MARK: - Insert/Update/Delete Operations

    /// Insert a new card into the context
    /// - Parameter card: The card to insert
    /// - Throws: SwiftData errors
    func insert(_ card: Card) throws {
        modelContext.insert(card)
        try modelContext.save()
    }

    /// Delete a card from the context
    /// - Parameter card: The card to delete
    /// - Throws: SwiftData errors
    func delete(_ card: Card) throws {
        modelContext.delete(card)
        try modelContext.save()
    }

    /// Save changes to the context
    /// - Throws: SwiftData errors
    func save() throws {
        try modelContext.save()
    }

    // MARK: - Batch Operations

    /// Delete multiple cards
    /// - Parameter cards: Array of cards to delete
    /// - Throws: SwiftData errors
    func delete(_ cards: [Card]) throws {
        for card in cards {
            modelContext.delete(card)
        }
        try modelContext.save()
    }

    /// Fetch count of cards by kind
    /// - Parameter kind: The card kind
    /// - Returns: Count of cards of this kind
    func count(ofKind kind: Kinds) -> Int {
        return fetch(byKind: kind).count
    }

    /// Fetch total count of all cards
    /// - Returns: Total count
    func countAll() -> Int {
        return fetchAll().count
    }

    // MARK: - Specialized Queries

    /// Fetch timeline cards (kind = .timelines)
    /// - Returns: Array of timeline cards
    func fetchTimelineCards() -> [Card] {
        return fetch(byKind: .timelines)
    }

    /// Fetch calendar cards (kind = .calendars)
    /// - Returns: Array of calendar cards
    func fetchCalendarCards() -> [Card] {
        return fetch(byKind: .calendars)
    }

    /// Fetch chronicle cards (kind = .chronicles)
    /// - Returns: Array of chronicle cards
    func fetchChronicleCards() -> [Card] {
        return fetch(byKind: .chronicles)
    }

    /// Fetch scene cards (kind = .scenes)
    /// - Returns: Array of scene cards
    func fetchSceneCards() -> [Card] {
        return fetch(byKind: .scenes)
    }

    /// Fetch character cards (kind = .characters)
    /// - Returns: Array of character cards
    func fetchCharacterCards() -> [Card] {
        return fetch(byKind: .characters)
    }

    /// Fetch location cards (kind = .locations)
    /// - Returns: Array of location cards
    func fetchLocationCards() -> [Card] {
        return fetch(byKind: .locations)
    }

    /// Fetch cards with AI-generated images
    /// - Returns: Array of cards with AI-generated images
    func fetchCardsWithAIImages() -> [Card] {
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { $0.imageGeneratedByAI == true },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch recently modified cards
    /// - Parameter limit: Maximum number of cards to return
    /// - Returns: Array of recently modified cards
    func fetchRecentlyModified(limit: Int = 10) -> [Card] {
        // Note: Card model doesn't have a modifiedDate property
        // This would need to be added to the model first
        // For now, return all cards sorted by name
        return Array(fetchAll().prefix(limit))
    }
}
