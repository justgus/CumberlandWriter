//
//  CardOperationManager.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 1
//

import Foundation
import SwiftData

/// Centralized manager for Card CRUD operations in Cumberland.
/// Consolidates card creation, deletion, and modification logic from MainAppView and other views.
///
/// **ER-0022 Phase 1**: Provides common card operations to reduce code duplication
@Observable
@MainActor
final class CardOperationManager {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Card Creation

    /// Create a new card
    /// - Parameters:
    ///   - kind: The card kind (Characters, Locations, etc.)
    ///   - name: The card name
    ///   - subtitle: Optional subtitle
    ///   - detailedText: Optional detailed description
    /// - Returns: The newly created card
    /// - Throws: SwiftData errors
    @discardableResult
    func createCard(
        kind: Kinds,
        name: String,
        subtitle: String = "",
        detailedText: String = ""
    ) throws -> Card {
        let card = Card(kind: kind, name: name, subtitle: subtitle, detailedText: detailedText)
        modelContext.insert(card)
        try modelContext.save()
        return card
    }

    // MARK: - Card Deletion

    /// Delete a single card with cleanup
    /// - Parameter card: The card to delete
    /// - Throws: SwiftData errors
    func deleteCard(_ card: Card) throws {
        // Clean up associated image files/caches and context-local related rows first
        card.cleanupBeforeDeletion(in: modelContext)

        // Delete the card; cascades remove edges/citations as modeled
        modelContext.delete(card)
        try modelContext.save()
    }

    /// Delete multiple cards with cleanup
    /// - Parameter cards: Array of cards to delete
    /// - Throws: SwiftData errors
    func deleteCards(_ cards: [Card]) throws {
        for card in cards {
            // Clean up associated image files/caches and context-local related rows first
            card.cleanupBeforeDeletion(in: modelContext)

            // Delete the card; cascades remove edges/citations as modeled
            modelContext.delete(card)
        }
        try modelContext.save()
    }

    // MARK: - Card Duplication

    /// Duplicate a card with all its properties (but not relationships)
    /// - Parameter card: The card to duplicate
    /// - Returns: The duplicated card
    /// - Throws: SwiftData errors
    @discardableResult
    func duplicateCard(_ card: Card) throws -> Card {
        let duplicate = Card(
            kind: card.kind,
            name: "\(card.name) (Copy)",
            subtitle: card.subtitle,
            detailedText: card.detailedText
        )

        // Copy image data if present
        if let originalImageData = card.originalImageData {
            try? duplicate.setOriginalImageData(originalImageData)
        }

        // Copy timeline properties if present
        duplicate.epochDate = card.epochDate
        duplicate.epochDescription = card.epochDescription

        modelContext.insert(duplicate)
        try modelContext.save()

        return duplicate
    }

    // MARK: - Card Type Change

    /// Change the card type (kind) - WARNING: This removes all relationships
    /// - Parameters:
    ///   - card: The card to modify
    ///   - newKind: The new card kind
    /// - Throws: SwiftData errors
    func changeCardType(_ card: Card, to newKind: Kinds) throws {
        guard newKind != card.kind else { return }

        // Fetch all edges where this card is either source or target
        let cardID: UUID? = card.id
        let fetchFrom = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == cardID })
        let fetchTo = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.to?.id == cardID })

        let edgesFrom = (try? modelContext.fetch(fetchFrom)) ?? []
        let edgesTo = (try? modelContext.fetch(fetchTo)) ?? []

        // Delete all relationships
        for edge in edgesFrom {
            modelContext.delete(edge)
        }
        for edge in edgesTo {
            modelContext.delete(edge)
        }

        // Change the card type by updating the raw value
        card.kindRaw = newKind.rawValue

        try modelContext.save()
    }

    // MARK: - Card Queries

    /// Fetch all cards
    /// - Returns: Array of all cards
    func fetchAllCards() -> [Card] {
        let fetch = FetchDescriptor<Card>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch cards by kind
    /// - Parameter kind: The card kind to filter by
    /// - Returns: Array of cards of the specified kind
    func fetchCards(ofKind kind: Kinds) -> [Card] {
        let kindRaw = kind.rawValue
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { $0.kindRaw == kindRaw },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Search cards by name
    /// - Parameter query: The search query
    /// - Returns: Array of matching cards
    func searchCards(query: String) -> [Card] {
        guard !query.isEmpty else { return fetchAllCards() }

        let lowercaseQuery = query.lowercased()
        return fetchAllCards().filter { card in
            card.name.lowercased().contains(lowercaseQuery) ||
            card.subtitle.lowercased().contains(lowercaseQuery)
        }
    }

    /// Fetch card by ID
    /// - Parameter id: The card's persistent identifier
    /// - Returns: The card, or nil if not found
    func fetchCard(byID id: PersistentIdentifier) -> Card? {
        return modelContext.model(for: id) as? Card
    }

    // MARK: - Validation

    /// Validate if a card can be created with the given name
    /// - Parameters:
    ///   - name: The proposed card name
    ///   - kind: The card kind
    /// - Returns: True if the card can be created
    func validateCardCreation(name: String, kind: Kinds) -> Bool {
        // Name cannot be empty
        guard !name.isEmpty else { return false }

        // Check if card with same name and kind already exists
        let existingCards = fetchCards(ofKind: kind)
        return !existingCards.contains(where: { $0.name.lowercased() == name.lowercased() })
    }
}

// MARK: - Errors

enum CardOperationError: Error, LocalizedError {
    case invalidName
    case duplicateName
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "The card name is invalid or empty."
        case .duplicateName:
            return "A card with this name already exists."
        case .notFound:
            return "The card could not be found."
        }
    }
}
