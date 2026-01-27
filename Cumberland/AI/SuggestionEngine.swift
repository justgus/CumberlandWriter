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
        var cardKind: Kinds  // Mutable to allow user to override the suggested type
        let confidence: Double
        let initialDescription: String

        var displayName: String {
            "\(entity.name) (\(cardKind.rawValue))"
        }
    }

    /// Suggestion for creating a relationship
    /// Phase 6: Now supports both AI-extracted and inferred relationships
    struct RelationshipSuggestion: Identifiable {
        let id = UUID()
        let sourceCardName: String
        let targetCardName: String
        let relationTypeCode: String  // Maps to RelationType.code in database
        let confidence: Double
        let context: String?  // Sentence or context where relationship was found

        var displayDescription: String {
            "\(sourceCardName) → \(relationTypeCode) → \(targetCardName)"
        }
    }

    /// Suggestion for creating a calendar system
    /// Phase 7: Calendar extraction from text
    struct CalendarSuggestion: Identifiable {
        let id = UUID()
        let detectedCalendar: CalendarSystemExtractor.DetectedCalendar
        var isEdited: Bool = false  // User has manually edited this suggestion

        var displayName: String {
            detectedCalendar.name
        }

        var displaySummary: String {
            "\(detectedCalendar.monthsPerYear) months, \(detectedCalendar.daysPerMonth ?? 0) days/month"
        }
    }

    /// Collection of all suggestions
    struct Suggestions {
        var cards: [CardSuggestion]
        var relationships: [RelationshipSuggestion]
        var calendars: [CalendarSuggestion]  // Phase 7

        var totalCount: Int {
            cards.count + relationships.count + calendars.count
        }

        var isEmpty: Bool {
            cards.isEmpty && relationships.isEmpty && calendars.isEmpty
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
    /// Phase 6 Fix: Exclude source card from suggestions to prevent duplicates
    func generateCardSuggestions(from entities: [Entity], sourceCard: Card) -> [CardSuggestion] {
        var suggestions: [CardSuggestion] = []

        for entity in entities {
            // Phase 6 Fix: Skip if entity name matches source card name
            // This prevents suggesting to create a card that's already being created
            if entity.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                sourceCard.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
                #if DEBUG
                print("   ⏭️  Skipping entity '\(entity.name)' - matches source card being created")
                #endif
                continue
            }

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
        print("📋 [SuggestionEngine] Generated \(suggestions.count) card suggestions (excluded source card)")
        #endif

        return suggestions
    }

    /// Generate relationship suggestions from AI-extracted relationships
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

            // Map RelationshipType enum to RelationType.code
            let relationTypeCode = mapRelationshipTypeToCode(relationship.type)

            let suggestion = RelationshipSuggestion(
                sourceCardName: sourceCard.name,
                targetCardName: targetCard.name,
                relationTypeCode: relationTypeCode,
                confidence: relationship.confidence,
                context: relationship.context
            )

            suggestions.append(suggestion)
        }

        // Sort by confidence (highest first)
        suggestions.sort { $0.confidence > $1.confidence }

        #if DEBUG
        print("🔗 [SuggestionEngine] Generated \(suggestions.count) AI relationship suggestions")
        #endif

        return suggestions
    }

    /// Generate relationship suggestions from inference (Phase 6)
    /// This uses pattern matching to infer relationships from text structure
    /// Phase 6 Fix: Generate suggestions even if cards don't exist yet (they'll be created from suggestions)
    func generateInferredRelationshipSuggestions(
        from text: String,
        entities: [Entity],
        existingCards: [Card],
        sourceCard: Card? = nil  // The card being created (may not be saved yet)
    ) -> [RelationshipSuggestion] {
        #if DEBUG
        print("🔍 [SuggestionEngine] Starting relationship inference...")
        print("   Text length: \(text.count) characters")
        print("   Entities for inference: \(entities.count)")
        for entity in entities {
            print("     - \(entity.name) (\(entity.type.rawValue))")
        }
        #endif

        let inference = RelationshipInference()
        let detectedRelationships = inference.inferRelationships(
            from: text,
            entities: entities,
            existingCards: existingCards
        )

        #if DEBUG
        print("   Detected \(detectedRelationships.count) relationships from patterns")
        #endif

        var suggestions: [RelationshipSuggestion] = []

        for detected in detectedRelationships {
            // Phase 6 Fix: Don't require cards to exist yet
            // They might be created from the entity suggestions
            // We'll validate existence when actually creating the relationships

            let suggestion = RelationshipSuggestion(
                sourceCardName: detected.sourceEntityName,
                targetCardName: detected.targetEntityName,
                relationTypeCode: detected.relationTypeCode,
                confidence: detected.confidence,
                context: detected.context
            )

            suggestions.append(suggestion)

            #if DEBUG
            print("     → \(detected.sourceEntityName) → [\(detected.relationTypeCode)] → \(detected.targetEntityName) (\(Int(detected.confidence * 100))%)")
            #endif
        }

        // Sort by confidence (highest first)
        suggestions.sort { $0.confidence > $1.confidence }

        #if DEBUG
        print("✅ [SuggestionEngine] Generated \(suggestions.count) inferred relationship suggestions (including pending entities)")
        #endif

        return suggestions
    }

    /// Map OpenAI RelationshipType enum to RelationType.code
    private func mapRelationshipTypeToCode(_ type: RelationshipType) -> String {
        switch type {
        case .owns:
            return "owns/owned-by"
        case .uses:
            return "uses/used-by"
        case .location:
            return "appears-in/is-appeared-by"  // Character at location
        case .memberOf:
            return "part-of/has-member"
        case .trainedAt:
            return "related-to/related-to"  // Generic; specific "trained-at" may not exist
        case .bornIn:
            return "related-to/related-to"  // Generic; specific "born-in" may not exist
        case .commands:
            return "pilots/piloted-by"  // Closest match for vehicles
        case .companion:
            return "allies-with/allies-with"
        case .enemy:
            return "conflicts-with/conflicts-with"
        case .parent:
            return "parent-of/child-of"
        case .child:
            return "parent-of/child-of"  // Same type, but reversed direction
        case .other:
            return "related-to/related-to"
        }
    }

    /// Generate all suggestions (cards + relationships + calendars)
    /// Phase 6: Added relationship inference
    /// Phase 7: Added calendar extraction
    func generateAllSuggestions(
        entities: [Entity],
        relationships: [Relationship],
        sourceCard: Card,
        existingCards: [Card],
        provider: AIProviderProtocol? = nil  // Phase 7: Optional for calendar extraction
    ) async -> Suggestions {
        #if DEBUG
        print("🎯 [SuggestionEngine] generateAllSuggestions called!")
        print("   Source card: \(sourceCard.name) (\(sourceCard.kind.rawValue))")
        print("   Entities: \(entities.count)")
        print("   AI relationships: \(relationships.count)")
        print("   Existing cards: \(existingCards.count)")
        #endif

        let cardSuggestions = generateCardSuggestions(from: entities, sourceCard: sourceCard)

        // Generate relationships from AI
        let aiRelationshipSuggestions = generateRelationshipSuggestions(from: relationships, existingCards: existingCards)

        // Generate relationships from inference (Phase 6)
        let inferredRelationshipSuggestions = generateInferredRelationshipSuggestions(
            from: sourceCard.detailedText,
            entities: entities,
            existingCards: existingCards,
            sourceCard: sourceCard  // Pass source card being created
        )

        // Combine and deduplicate
        var allRelationshipSuggestions = aiRelationshipSuggestions + inferredRelationshipSuggestions
        allRelationshipSuggestions = deduplicateRelationshipSuggestions(allRelationshipSuggestions)

        // Sort by confidence
        allRelationshipSuggestions.sort { $0.confidence > $1.confidence }

        // Phase 7: Generate calendar suggestions for appropriate card types
        var calendarSuggestions: [CalendarSuggestion] = []

        #if DEBUG
        print("📅 [SuggestionEngine] Checking calendar extraction eligibility...")
        print("   Card kind: \(sourceCard.kind)")
        print("   Should extract calendars: \(shouldExtractCalendars(for: sourceCard.kind))")
        print("   Provider available: \(provider != nil)")
        #endif

        if shouldExtractCalendars(for: sourceCard.kind), let provider = provider {
            #if DEBUG
            print("📅 [SuggestionEngine] Starting calendar extraction...")
            #endif

            do {
                let calendars = try await extractCalendarSuggestions(
                    from: sourceCard.detailedText,
                    provider: provider
                )
                calendarSuggestions = calendars

                #if DEBUG
                print("✅ [SuggestionEngine] Calendar extraction complete: \(calendars.count) calendars found")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ [SuggestionEngine] Calendar extraction failed: \(error)")
                #endif
                // Don't fail the whole operation if calendar extraction fails
            }
        } else {
            #if DEBUG
            if !shouldExtractCalendars(for: sourceCard.kind) {
                print("   ⏭️ Skipping calendar extraction: card kind not eligible")
            } else if provider == nil {
                print("   ⏭️ Skipping calendar extraction: no AI provider available")
            }
            #endif
        }

        // Phase 7.5: Filter out card suggestions that match detected calendar names
        // This prevents calendars from being suggested as artifacts
        let calendarNames = Set(calendarSuggestions.map { $0.detectedCalendar.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
        let filteredCardSuggestions = cardSuggestions.filter { suggestion in
            let entityName = suggestion.entity.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let isCalendar = calendarNames.contains(entityName)

            if isCalendar {
                #if DEBUG
                print("   ⏭️  Filtered out entity '\(suggestion.entity.name)' - detected as calendar")
                #endif
            }

            return !isCalendar
        }

        return Suggestions(
            cards: filteredCardSuggestions,
            relationships: allRelationshipSuggestions,
            calendars: calendarSuggestions
        )
    }

    /// Determine if calendar extraction should be attempted for this card kind
    /// Phase 7 / Phase 7.5: Expanded to more card types
    private func shouldExtractCalendars(for kind: Kinds) -> Bool {
        // Extract calendars from worldbuilding and narrative cards
        // Calendars can appear in worldbuilding descriptions, history, locations, etc.
        switch kind {
        case .timelines, .scenes, .worlds, .rules, .characters, .locations, .chronicles, .projects:
            return true
        default:
            return false
        }
    }

    /// Extract calendar suggestions from text
    /// Phase 7
    private func extractCalendarSuggestions(
        from text: String,
        provider: AIProviderProtocol
    ) async throws -> [CalendarSuggestion] {
        let extractor = CalendarSystemExtractor(provider: provider)
        let detectedCalendars = try await extractor.extractCalendars(from: text)

        return detectedCalendars.map { detected in
            CalendarSuggestion(detectedCalendar: detected)
        }
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
    /// Phase 6 implementation
    /// Creates BOTH forward and reverse edges for each relationship (bidirectional)
    func createRelationships(from suggestions: [RelationshipSuggestion], context: ModelContext, existingCards: [Card]) throws {
        #if DEBUG
        print("🔗 [SuggestionEngine] Creating \(suggestions.count) relationships (bidirectional)")
        print("   Available cards: \(existingCards.count)")
        for card in existingCards.prefix(20) {
            print("     - \(card.name) (\(card.kind.rawValue))")
        }
        #endif

        // Fetch all RelationTypes once
        let relationTypesFetch = FetchDescriptor<RelationType>()
        let relationTypes = try context.fetch(relationTypesFetch)

        var createdCount = 0

        for suggestion in suggestions {
            #if DEBUG
            print("   🔍 Looking for: source='\(suggestion.sourceCardName)' target='\(suggestion.targetCardName)'")
            #endif

            // Find the source and target cards
            let foundSourceCard = findCard(named: suggestion.sourceCardName, in: existingCards)
            let foundTargetCard = findCard(named: suggestion.targetCardName, in: existingCards)

            #if DEBUG
            print("      Source found: \(foundSourceCard != nil ? "✅ \(foundSourceCard!.name)" : "❌")")
            print("      Target found: \(foundTargetCard != nil ? "✅ \(foundTargetCard!.name)" : "❌")")
            #endif

            guard let sourceCard = foundSourceCard, let targetCard = foundTargetCard else {
                #if DEBUG
                print("   ⚠️ Skipping relationship: cards not found (\(suggestion.sourceCardName) → \(suggestion.targetCardName))")
                #endif
                continue
            }

            // Find the RelationType
            guard let relationType = relationTypes.first(where: { $0.code == suggestion.relationTypeCode }) else {
                #if DEBUG
                print("   ⚠️ Skipping relationship: RelationType not found (code: \(suggestion.relationTypeCode))")
                #endif
                continue
            }

            // Check if forward relationship already exists
            if relationshipExists(from: sourceCard, to: targetCard, type: relationType, context: context) {
                #if DEBUG
                print("   ⏭️  Skipping relationship: already exists (\(sourceCard.name) → \(targetCard.name))")
                #endif
                continue
            }

            // Create the forward CardEdge (source → target)
            let forwardEdge = CardEdge(from: sourceCard, to: targetCard, type: relationType)
            context.insert(forwardEdge)
            createdCount += 1

            #if DEBUG
            print("   ✅ Created forward: \(sourceCard.name) → [\(relationType.forwardLabel)] → \(targetCard.name)")
            #endif

            // Create the reverse CardEdge (target → source) using mirror type
            ensureReverseEdge(forwardEdge: forwardEdge, context: context)
        }

        // Save all changes
        if createdCount > 0 {
            try context.save()
        }

        #if DEBUG
        let totalEdges = createdCount * 2
        print("✅ [SuggestionEngine] Successfully created \(createdCount) forward + \(createdCount) reverse = \(totalEdges) total edges")
        #endif
    }

    /// Create the reverse edge for bidirectional relationships
    /// Mirrors the pattern from CardRelationshipView
    private func ensureReverseEdge(forwardEdge: CardEdge, context: ModelContext) {
        guard let src = forwardEdge.from,
              let dst = forwardEdge.to,
              let forwardType = forwardEdge.type else {
            return
        }

        // Check if reverse edge already exists
        let srcID = src.id
        let dstID = dst.id
        let reversePredicate = #Predicate<CardEdge> {
            $0.from?.id == dstID && $0.to?.id == srcID
        }
        let reverseFetch = FetchDescriptor(predicate: reversePredicate)

        if let existing = try? context.fetch(reverseFetch), !existing.isEmpty {
            #if DEBUG
            print("   ⏭️  Reverse edge already exists: \(dst.name) → \(src.name)")
            #endif
            return
        }

        // Get or create the mirror type
        let mirrorType = getMirrorType(for: forwardType, sourceKind: src.kind, targetKind: dst.kind, context: context)

        // Create reverse edge with slightly later timestamp for ordering
        let reverseCreatedAt = forwardEdge.createdAt.addingTimeInterval(0.001)
        let reverseEdge = CardEdge(
            from: dst,
            to: src,
            type: mirrorType,
            note: forwardEdge.note,
            createdAt: reverseCreatedAt
        )
        context.insert(reverseEdge)

        #if DEBUG
        print("   ✅ Created reverse: \(dst.name) → [\(mirrorType.forwardLabel)] → \(src.name)")
        #endif
    }

    /// Get or create the mirror RelationType for reverse edges
    /// Forward type: "pilots/piloted-by" → Mirror type: "piloted-by/pilots"
    private func getMirrorType(for type: RelationType, sourceKind: Kinds, targetKind: Kinds, context: ModelContext) -> RelationType {
        // Mirror type has swapped labels and kinds
        let desiredCode = makeRelationTypeCode(forward: type.inverseLabel, inverse: type.forwardLabel)

        // Try to find existing mirror type
        let mirrorPredicate = #Predicate<RelationType> { rt in
            rt.code == desiredCode
        }
        let mirrorFetch = FetchDescriptor(predicate: mirrorPredicate)

        if let existing = try? context.fetch(mirrorFetch).first {
            return existing
        }

        // Create new mirror type
        let mirror = RelationType(
            code: desiredCode,
            forwardLabel: type.inverseLabel,
            inverseLabel: type.forwardLabel,
            sourceKind: targetKind,  // Swapped
            targetKind: sourceKind   // Swapped
        )
        context.insert(mirror)

        #if DEBUG
        print("   🆕 Created mirror RelationType: \(desiredCode)")
        #endif

        return mirror
    }

    /// Build RelationType code from forward/inverse labels
    private func makeRelationTypeCode(forward: String, inverse: String) -> String {
        return "\(forward)/\(inverse)"
    }

    /// Check if a relationship already exists
    private func relationshipExists(from source: Card, to target: Card, type: RelationType, context: ModelContext) -> Bool {
        // Check if edge exists with same source, target, and type
        let sourceID = source.id
        let targetID = target.id
        let typeCode = type.code

        let predicate = #Predicate<CardEdge> {
            $0.from?.id == sourceID &&
            $0.to?.id == targetID &&
            $0.type?.code == typeCode
        }

        let fetchDescriptor = FetchDescriptor(predicate: predicate)

        do {
            let existing = try context.fetch(fetchDescriptor)
            return !existing.isEmpty
        } catch {
            #if DEBUG
            print("   ⚠️ Error checking for existing relationship: \(error)")
            #endif
            return false
        }
    }

    // MARK: - Suggestion Filtering

    /// Deduplicate relationship suggestions (same source, target, type)
    /// Phase 6: Keep highest confidence when duplicates exist
    private func deduplicateRelationshipSuggestions(_ suggestions: [RelationshipSuggestion]) -> [RelationshipSuggestion] {
        var seen: [String: RelationshipSuggestion] = [:]

        for suggestion in suggestions {
            let key = "\(suggestion.sourceCardName)|\(suggestion.targetCardName)|\(suggestion.relationTypeCode)"

            // Keep the one with higher confidence
            if let existing = seen[key] {
                if suggestion.confidence > existing.confidence {
                    seen[key] = suggestion
                }
            } else {
                seen[key] = suggestion
            }
        }

        return Array(seen.values)
    }

    /// Filter suggestions by confidence threshold
    func filterByConfidence(_ suggestions: Suggestions) -> Suggestions {
        let threshold = settings.confidenceThreshold

        let filteredCards = suggestions.cards.filter { $0.confidence >= threshold }
        let filteredRelationships = suggestions.relationships.filter { $0.confidence >= threshold }
        let filteredCalendars = suggestions.calendars.filter { $0.detectedCalendar.confidence >= threshold }

        return Suggestions(
            cards: filteredCards,
            relationships: filteredRelationships,
            calendars: filteredCalendars
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
        let highConfidenceCalendars = suggestions.calendars.filter { $0.detectedCalendar.confidence >= threshold }  // Phase 7

        return Suggestions(
            cards: highConfidenceCards,
            relationships: highConfidenceRelationships,
            calendars: highConfidenceCalendars
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
