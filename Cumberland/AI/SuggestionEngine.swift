import Foundation
import SwiftData

/// Generates card creation and relationship suggestions from extracted entities
/// Phase 5 (ER-0010) - Content Analysis MVP
class SuggestionEngine {

    // MARK: - Suggestion Types

    /// Suggestion for creating a new card
    struct CardSuggestion: Identifiable {
        let id = UUID()
        let entity: Entity
        let cardKind: Kinds
        let confidence: Double
        let initialDescription: String

        var displayName: String {
            "\(entity.name) (\(cardKind.rawValue))"
        }
    }

    /// Suggestion for creating a relationship
    struct RelationshipSuggestion: Identifiable {
        let id = UUID()
        let relationship: Relationship
        let sourceCardName: String
        let targetCardName: String
        let confidence: Double

        var displayDescription: String {
            "\(sourceCardName) → \(relationship.type.rawValue) → \(targetCardName)"
        }
    }

    /// Collection of all suggestions
    struct Suggestions {
        var cards: [CardSuggestion]
        var relationships: [RelationshipSuggestion]

        var totalCount: Int {
            cards.count + relationships.count
        }

        var isEmpty: Bool {
            cards.isEmpty && relationships.isEmpty
        }
    }

    // MARK: - Properties

    private let settings: AISettings

    // MARK: - Initialization

    init(settings: AISettings = .shared) {
        self.settings = settings
    }

    // MARK: - Public API

    /// Generate card creation suggestions from entities
    func generateCardSuggestions(from entities: [Entity], sourceCard: Card) -> [CardSuggestion] {
        var suggestions: [CardSuggestion] = []

        for entity in entities {
            // Map entity type to card kind
            let cardKind = entity.type.toCardKind()

            // Generate initial description from context
            let initialDescription = generateInitialDescription(for: entity, sourceCard: sourceCard)

            let suggestion = CardSuggestion(
                entity: entity,
                cardKind: cardKind,
                confidence: entity.confidence,
                initialDescription: initialDescription
            )

            suggestions.append(suggestion)
        }

        // Sort by confidence (highest first)
        suggestions.sort { $0.confidence > $1.confidence }

        #if DEBUG
        print("📋 [SuggestionEngine] Generated \(suggestions.count) card suggestions")
        #endif

        return suggestions
    }

    /// Generate relationship suggestions from relationships
    func generateRelationshipSuggestions(from relationships: [Relationship], existingCards: [Card]) -> [RelationshipSuggestion] {
        var suggestions: [RelationshipSuggestion] = []

        for relationship in relationships {
            // Try to find matching cards for source and target
            guard let sourceCard = findCard(named: relationship.source, in: existingCards),
                  let targetCard = findCard(named: relationship.target, in: existingCards) else {
                #if DEBUG
                print("   Skipping relationship: cards not found (\(relationship.source) → \(relationship.target))")
                #endif
                continue
            }

            let suggestion = RelationshipSuggestion(
                relationship: relationship,
                sourceCardName: sourceCard.name,
                targetCardName: targetCard.name,
                confidence: relationship.confidence
            )

            suggestions.append(suggestion)
        }

        // Sort by confidence (highest first)
        suggestions.sort { $0.confidence > $1.confidence }

        #if DEBUG
        print("🔗 [SuggestionEngine] Generated \(suggestions.count) relationship suggestions")
        #endif

        return suggestions
    }

    /// Generate all suggestions (cards + relationships)
    func generateAllSuggestions(
        entities: [Entity],
        relationships: [Relationship],
        sourceCard: Card,
        existingCards: [Card]
    ) -> Suggestions {
        let cardSuggestions = generateCardSuggestions(from: entities, sourceCard: sourceCard)
        let relationshipSuggestions = generateRelationshipSuggestions(from: relationships, existingCards: existingCards)

        return Suggestions(
            cards: cardSuggestions,
            relationships: relationshipSuggestions
        )
    }

    // MARK: - Private Helpers

    /// Generate initial description for a card from entity context
    private func generateInitialDescription(for entity: Entity, sourceCard: Card) -> String {
        var description = ""

        // Add context if available
        if let context = entity.context, !context.isEmpty {
            description += context.trimmingCharacters(in: .whitespacesAndNewlines)
            description += "\n\n"
        }

        // Add mention attribution
        description += "Mentioned in: \(sourceCard.name)"

        return description
    }

    /// Find a card by name (fuzzy matching)
    private func findCard(named name: String, in cards: [Card]) -> Card? {
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Exact match (case-insensitive)
        if let exactMatch = cards.first(where: { $0.name.lowercased() == normalizedName }) {
            return exactMatch
        }

        // Partial match (contains)
        if let partialMatch = cards.first(where: { $0.name.lowercased().contains(normalizedName) }) {
            return partialMatch
        }

        // Reverse partial match (name contains search term)
        if let reverseMatch = cards.first(where: { normalizedName.contains($0.name.lowercased()) }) {
            return reverseMatch
        }

        return nil
    }

    // MARK: - Batch Operations

    /// Create cards from accepted suggestions
    func createCards(from suggestions: [CardSuggestion], context: ModelContext, sourceCard: Card) throws {
        #if DEBUG
        print("✨ [SuggestionEngine] Creating \(suggestions.count) cards")
        #endif

        for suggestion in suggestions {
            let card = Card(
                kind: suggestion.cardKind,
                name: suggestion.entity.name,
                subtitle: "",
                detailedText: suggestion.initialDescription
            )

            context.insert(card)

            // TODO: Create "mentioned in" relationship to source card
            // This will be implemented when we add relationship creation
        }

        try context.save()

        #if DEBUG
        print("✅ [SuggestionEngine] Successfully created \(suggestions.count) cards")
        #endif
    }

    /// Create relationships from accepted suggestions
    /// NOTE: Phase 6 implementation - requires RelationType model lookup/creation
    func createRelationships(from suggestions: [RelationshipSuggestion], context: ModelContext, existingCards: [Card]) throws {
        #if DEBUG
        print("🔗 [SuggestionEngine] Creating \(suggestions.count) relationships")
        print("   ⚠️ Relationship creation not yet implemented (Phase 6)")
        #endif

        // TODO: Phase 6 - Implement relationship creation
        // This requires:
        // 1. Looking up or creating RelationType objects for each relationship type
        // 2. Creating CardEdge with the proper RelationType reference
        // 3. Handling bidirectional relationships

        // For now, skip relationship creation in Phase 5 MVP
        // Only card creation is supported in this phase

        #if DEBUG
        print("   Skipped \(suggestions.count) relationship suggestions")
        #endif
    }

    // MARK: - Suggestion Filtering

    /// Filter suggestions by confidence threshold
    func filterByConfidence(_ suggestions: Suggestions) -> Suggestions {
        let threshold = settings.confidenceThreshold

        let filteredCards = suggestions.cards.filter { $0.confidence >= threshold }
        let filteredRelationships = suggestions.relationships.filter { $0.confidence >= threshold }

        return Suggestions(
            cards: filteredCards,
            relationships: filteredRelationships
        )
    }

    /// Group card suggestions by type
    func groupByType(_ suggestions: [CardSuggestion]) -> [Kinds: [CardSuggestion]] {
        var grouped: [Kinds: [CardSuggestion]] = [:]

        for suggestion in suggestions {
            grouped[suggestion.cardKind, default: []].append(suggestion)
        }

        return grouped
    }

    /// Get high confidence suggestions only
    func getHighConfidenceSuggestions(_ suggestions: Suggestions, threshold: Double = 0.85) -> Suggestions {
        let highConfidenceCards = suggestions.cards.filter { $0.confidence >= threshold }
        let highConfidenceRelationships = suggestions.relationships.filter { $0.confidence >= threshold }

        return Suggestions(
            cards: highConfidenceCards,
            relationships: highConfidenceRelationships
        )
    }
}

// MARK: - Statistics

extension SuggestionEngine {
    struct SuggestionStats {
        let totalCards: Int
        let totalRelationships: Int
        let highConfidenceCards: Int
        let highConfidenceRelationships: Int
        let averageConfidence: Double

        var highConfidenceRate: Double {
            let total = totalCards + totalRelationships
            guard total > 0 else { return 0.0 }
            let highConfidence = highConfidenceCards + highConfidenceRelationships
            return Double(highConfidence) / Double(total)
        }
    }

    func getStats(for suggestions: Suggestions) -> SuggestionStats {
        let highConfidence = getHighConfidenceSuggestions(suggestions)

        let allConfidences = suggestions.cards.map { $0.confidence } +
                            suggestions.relationships.map { $0.confidence }
        let averageConfidence = allConfidences.isEmpty ? 0.0 : allConfidences.reduce(0.0, +) / Double(allConfidences.count)

        return SuggestionStats(
            totalCards: suggestions.cards.count,
            totalRelationships: suggestions.relationships.count,
            highConfidenceCards: highConfidence.cards.count,
            highConfidenceRelationships: highConfidence.relationships.count,
            averageConfidence: averageConfidence
        )
    }
}
