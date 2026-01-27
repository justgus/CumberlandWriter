//
//  RelationshipInference.swift
//  Cumberland
//
//  Phase 6: ER-0010 Relationship Inference
//  Analyzes sentence structure to infer relationships between entities
//

import Foundation

/// Infers relationships between entities based on sentence structure and context
/// Phase 6 (ER-0010) - Relationship Inference
struct RelationshipInference {

    // MARK: - Data Structures

    /// A pattern for detecting relationships in text
    struct RelationshipPattern {
        /// Pattern identifier
        let id: String

        /// Keywords or phrases that indicate this relationship
        let triggers: [String]

        /// Relationship type code (matches RelationType.code)
        let relationTypeCode: String

        /// Whether source and target can be swapped
        let isSymmetric: Bool

        /// Confidence boost for exact matches
        let baseConfidence: Double

        /// Optional source kind constraint
        let sourceKind: Kinds?

        /// Optional target kind constraint
        let targetKind: Kinds?

        /// Description of the pattern
        let description: String
    }

    /// A detected relationship between two entities
    struct DetectedRelationship {
        let id = UUID()
        let sourceEntityName: String
        let targetEntityName: String
        let relationTypeCode: String
        let confidence: Double
        let context: String  // The sentence where it was found
        let pattern: RelationshipPattern
    }

    // MARK: - Relationship Patterns

    /// Predefined patterns for detecting relationships
    /// IMPORTANT: Uses RelationType forwardLabel conventions:
    /// - forwardLabel describes source → target
    /// - inverseLabel describes target → source
    /// - Store as: source → forwardLabel → target
    static let patterns: [RelationshipPattern] = [

        // MARK: Ownership & Possession

        .init(
            id: "owns-possession",
            triggers: ["owns", "has", "possesses", "holds", "carries", "wields", "brandishes"],
            relationTypeCode: "owns/owned-by",
            isSymmetric: false,
            baseConfidence: 0.85,
            sourceKind: .characters,
            targetKind: .artifacts,
            description: "Character owns or possesses an artifact"
        ),

        .init(
            id: "uses-artifact",
            triggers: ["uses", "employs", "utilizes", "wields", "drew", "draws", "unsheathed", "unsheathes"],
            relationTypeCode: "uses/used-by",
            isSymmetric: false,
            baseConfidence: 0.80,
            sourceKind: .characters,
            targetKind: .artifacts,
            description: "Character uses an artifact"
        ),

        // MARK: Location & Spatial

        .init(
            id: "enters-location",
            triggers: ["entered", "enters", "walked into", "arrived at", "came to", "reached"],
            relationTypeCode: "appears-in/is-appeared-by",
            isSymmetric: false,
            baseConfidence: 0.75,
            sourceKind: .characters,
            targetKind: nil, // Can be scenes, locations, buildings
            description: "Character enters or appears in a location/scene"
        ),

        .init(
            id: "born-in-location",
            triggers: ["born in", "born at", "birthplace", "native of", "hails from"],
            relationTypeCode: "related-to/related-to", // Generic for now; specific "born-in" may need to be added
            isSymmetric: false,
            baseConfidence: 0.90,
            sourceKind: .characters,
            targetKind: .locations,
            description: "Character born in a location"
        ),

        .init(
            id: "set-in-location",
            triggers: ["set in", "takes place in", "occurs in", "happens in", "located in"],
            relationTypeCode: "set-in/contains-scene",
            isSymmetric: false,
            baseConfidence: 0.85,
            sourceKind: .scenes,
            targetKind: .worlds,
            description: "Scene set in a world or location"
        ),

        // MARK: Character Relationships

        .init(
            id: "knows-character",
            triggers: ["knows", "met", "meets", "encountered", "acquainted with", "familiar with"],
            relationTypeCode: "knows/known-by",
            isSymmetric: false, // Can be one-directional
            baseConfidence: 0.75,
            sourceKind: .characters,
            targetKind: .characters,
            description: "Character knows another character"
        ),

        .init(
            id: "mentors-character",
            triggers: ["mentors", "teaches", "trains", "trained", "instructed", "guided"],
            relationTypeCode: "mentors/mentored-by",
            isSymmetric: false,
            baseConfidence: 0.80,
            sourceKind: .characters,
            targetKind: .characters,
            description: "Character mentors another character"
        ),

        .init(
            id: "allies-with",
            triggers: ["allies with", "allied with", "fights alongside", "partners with", "joined forces with"],
            relationTypeCode: "allies-with/allies-with",
            isSymmetric: true,
            baseConfidence: 0.80,
            sourceKind: .characters,
            targetKind: .characters,
            description: "Characters are allies"
        ),

        .init(
            id: "conflicts-with",
            triggers: ["fights", "battles", "opposes", "against", "enemy of", "rival of"],
            relationTypeCode: "conflicts-with/conflicts-with",
            isSymmetric: true,
            baseConfidence: 0.80,
            sourceKind: .characters,
            targetKind: .characters,
            description: "Characters are in conflict"
        ),

        // MARK: Vehicle & Transportation

        .init(
            id: "pilots-vehicle",
            triggers: ["pilots", "flies", "drives", "commands", "captains", "steers"],
            relationTypeCode: "pilots/piloted-by",
            isSymmetric: false,
            baseConfidence: 0.85,
            sourceKind: .characters,
            targetKind: .vehicles,
            description: "Character pilots a vehicle"
        ),

        // MARK: Hierarchy & Composition

        .init(
            id: "part-of",
            triggers: ["part of", "belongs to", "member of", "within", "inside", "contained in"],
            relationTypeCode: "includes/part-of",
            isSymmetric: false,
            baseConfidence: 0.75,
            sourceKind: nil,
            targetKind: nil, // Generic
            description: "Entity is part of another entity"
        ),

        // MARK: References & Citations

        .init(
            id: "references",
            triggers: ["references", "mentions", "cites", "refers to", "alludes to"],
            relationTypeCode: "references",
            isSymmetric: false,
            baseConfidence: 0.70,
            sourceKind: nil,
            targetKind: nil,
            description: "Entity references another entity"
        )
    ]

    // MARK: - Inference Logic

    /// Analyze text to detect relationships between entities
    /// - Parameters:
    ///   - text: The text to analyze
    ///   - entities: List of entities found in the text
    ///   - existingCards: Cards that already exist (for matching entity names to cards)
    /// - Returns: List of detected relationships
    func inferRelationships(
        from text: String,
        entities: [Entity],
        existingCards: [Card]
    ) -> [DetectedRelationship] {

        var relationships: [DetectedRelationship] = []

        // Split text into sentences for analysis
        let sentences = splitIntoSentences(text)

        // For each sentence, check if multiple entities appear and look for patterns
        for sentence in sentences {
            let sentenceLower = sentence.lowercased()

            #if DEBUG
            print("   📝 Analyzing sentence: \"\(sentence)\"")
            #endif

            // Find which entities appear in this sentence (using fuzzy matching)
            let entitiesInSentence = entities.filter { entity in
                findEntityInSentence(entityName: entity.name, sentence: sentenceLower) != nil
            }

            #if DEBUG
            print("      Found \(entitiesInSentence.count) entities in this sentence:")
            for ent in entitiesInSentence {
                print("        - \(ent.name)")
            }
            #endif

            // Need at least 2 entities to have a relationship
            guard entitiesInSentence.count >= 2 else {
                #if DEBUG
                print("      ⏭️  Skipping (need 2+ entities for relationship)")
                #endif
                continue
            }

            // Try each pattern
            for pattern in Self.patterns {
                // Check if any trigger appears in sentence
                guard let trigger = pattern.triggers.first(where: { sentenceLower.contains($0.lowercased()) }) else {
                    continue
                }

                // Try to find source and target entities that match the pattern constraints
                for sourceEntity in entitiesInSentence {
                    for targetEntity in entitiesInSentence where sourceEntity.name != targetEntity.name {

                        // Check kind constraints
                        if let requiredSourceKind = pattern.sourceKind,
                           sourceEntity.type.toCardKind() != requiredSourceKind {
                            continue
                        }

                        if let requiredTargetKind = pattern.targetKind,
                           targetEntity.type.toCardKind() != requiredTargetKind {
                            continue
                        }

                        // Check sentence structure to determine if this is the right direction
                        // Phase 6 Fix: Use fuzzy name matching to handle partial names and pronouns
                        let sourceIndex = findEntityInSentence(entityName: sourceEntity.name, sentence: sentenceLower)
                        let targetIndex = findEntityInSentence(entityName: targetEntity.name, sentence: sentenceLower)
                        let triggerIndex = sentenceLower.range(of: trigger.lowercased())?.lowerBound

                        guard let sIdx = sourceIndex, let tIdx = targetIndex, let trIdx = triggerIndex else {
                            continue
                        }

                        // Check if order makes sense: source < trigger < target
                        guard sIdx < trIdx && trIdx < tIdx else {
                            continue
                        }

                        // Calculate confidence based on pattern and context
                        var confidence = pattern.baseConfidence

                        // Boost confidence if entities are close together
                        let distance = sentence.distance(from: sIdx, to: tIdx)
                        if distance < 50 { // Within 50 characters
                            confidence += 0.05
                        }

                        // Cap at 0.95
                        confidence = min(confidence, 0.95)

                        let relationship = DetectedRelationship(
                            sourceEntityName: sourceEntity.name,
                            targetEntityName: targetEntity.name,
                            relationTypeCode: pattern.relationTypeCode,
                            confidence: confidence,
                            context: sentence,
                            pattern: pattern
                        )

                        relationships.append(relationship)
                    }
                }
            }
        }

        // Deduplicate relationships (same source, target, type)
        relationships = deduplicateRelationships(relationships)

        return relationships
    }

    // MARK: - Helper Methods

    /// Find entity name in sentence with fuzzy matching
    /// Handles partial names (e.g., "Drake" matches "Captain Drake")
    /// Returns the index of the match, or nil if not found
    private func findEntityInSentence(entityName: String, sentence: String) -> String.Index? {
        let entityLower = entityName.lowercased()
        let sentenceLower = sentence

        // Try exact match first
        if let range = sentenceLower.range(of: entityLower) {
            return range.lowerBound
        }

        // Try matching each word in the entity name
        // "Captain Drake" → try "captain" and "drake" separately
        let entityWords = entityLower.split(separator: " ")
        for word in entityWords where word.count > 2 {  // Skip short words like "of", "the"
            if let range = sentenceLower.range(of: String(word)) {
                // Found a word from the entity name
                // Return the position where this word appears
                return range.lowerBound
            }
        }

        // Handle common pronoun substitutions for characters
        // If entity is a character and sentence starts with a pronoun, assume it's referring to them
        // This is a simple heuristic - more sophisticated NLP would track coreference
        if entityName.contains(" ") {  // Multi-word names are likely characters (e.g., "Captain Drake")
            let pronouns = ["he ", "she ", "they ", "it "]
            for pronoun in pronouns {
                if sentenceLower.hasPrefix(pronoun) {
                    // Assume pronoun refers to this entity
                    // Return position 0 (start of sentence)
                    return sentenceLower.startIndex
                }
            }
        }

        return nil
    }

    /// Split text into sentences
    private func splitIntoSentences(_ text: String) -> [String] {
        // Simple sentence splitting on periods, exclamation points, question marks
        // This is a simplified version; production code might use NLP libraries
        let pattern = "[.!?]+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [text]
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        var sentences: [String] = []
        var lastEnd = text.startIndex

        for match in matches {
            if let range = Range(match.range, in: text) {
                let sentence = String(text[lastEnd..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty {
                    sentences.append(sentence)
                }
                lastEnd = range.upperBound
            }
        }

        // Add remaining text
        let remaining = String(text[lastEnd...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !remaining.isEmpty {
            sentences.append(remaining)
        }

        return sentences
    }

    /// Remove duplicate relationships
    private func deduplicateRelationships(_ relationships: [DetectedRelationship]) -> [DetectedRelationship] {
        var seen = Set<String>()
        var unique: [DetectedRelationship] = []

        for rel in relationships {
            let key = "\(rel.sourceEntityName)|\(rel.targetEntityName)|\(rel.relationTypeCode)"
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(rel)
            }
        }

        return unique
    }
}
