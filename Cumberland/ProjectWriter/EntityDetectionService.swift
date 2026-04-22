//
//  EntityDetectionService.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-21.
//  Part of Phase 3: Background text parsing service for entity detection
//
//  Analyzes scene text to detect mentions of characters, artifacts, locations, etc.
//  Returns potential cards sorted by confidence for display in Context Gutter.
//

import Foundation
import SwiftData
import NaturalLanguage

/// Background service that parses scene text and detects entity mentions
@MainActor
class EntityDetectionService {
    private let modelContext: ModelContext
    private let cardRepository: CardRepository

    /// Minimum confidence threshold for suggesting potential cards
    private let minimumConfidence: Float = 0.4

    /// Cache of existing cards for faster matching
    private var cardCache: [Kinds: [Card]] = [:]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.cardRepository = CardRepository(modelContext: modelContext)
        loadCardCache()
    }

    // MARK: - Main Detection Method

    /// Detect entities in scene text and return potential cards
    /// - Parameters:
    ///   - text: The scene text to analyze
    ///   - sceneID: The UUID of the scene being analyzed
    /// - Returns: Array of potential cards sorted by confidence (highest first)
    func detectEntities(in text: String, sceneID: UUID) async -> [PotentialCard] {
        guard !text.isEmpty else { return [] }

        var detectedCards: [PotentialCard] = []

        // 1. Exact match detection (existing card names in text)
        detectedCards.append(contentsOf: detectExactMatches(in: text, sceneID: sceneID))

        // 2. Fuzzy match detection (similar to existing card names)
        detectedCards.append(contentsOf: detectFuzzyMatches(in: text, sceneID: sceneID))

        // 3. Named Entity Recognition (capitalized noun phrases)
        detectedCards.append(contentsOf: detectNamedEntities(in: text, sceneID: sceneID))

        // 4. Context keyword detection (phrases like "took the sword", "arrived at the castle")
        detectedCards.append(contentsOf: detectContextKeywords(in: text, sceneID: sceneID))

        // 5. Deduplicate by name and kind, keeping highest confidence
        let uniqueCards = deduplicatePotentialCards(detectedCards)

        // 6. Filter by minimum confidence and sort
        return uniqueCards
            .filter { $0.confidence >= minimumConfidence }
            .sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Detection Strategies

    /// Detect exact matches with existing card names
    private func detectExactMatches(in text: String, sceneID: UUID) -> [PotentialCard] {
        var results: [PotentialCard] = []
        let lowercasedText = text.lowercased()

        for (kind, cards) in cardCache {
            for card in cards {
                let cardName = card.name
                guard !cardName.isEmpty else { continue }

                // Case-insensitive search
                if lowercasedText.contains(cardName.lowercased()) {
                    let potential = PotentialCard(
                        kind: kind,
                        name: cardName,
                        confidence: 1.0, // Exact match = highest confidence
                        sceneID: sceneID,
                        detectionSource: .exactMatch
                    )
                    results.append(potential)
                }
            }
        }

        return results
    }

    /// Detect fuzzy matches with existing card names (Levenshtein distance)
    private func detectFuzzyMatches(in text: String, sceneID: UUID) -> [PotentialCard] {
        var results: [PotentialCard] = []
        let words = extractWords(from: text)

        for (kind, cards) in cardCache {
            for card in cards {
                let cardName = card.name
                guard !cardName.isEmpty else { continue }

                // Check each word against card name
                for word in words {
                    let similarity = calculateSimilarity(between: word, and: cardName)

                    // Fuzzy match threshold: 0.7 to 0.9 confidence
                    if similarity > 0.7 && similarity < 1.0 {
                        let potential = PotentialCard(
                            kind: kind,
                            name: cardName,
                            confidence: Float(similarity) * 0.9, // Scale to 0.63-0.9
                            sceneID: sceneID,
                            detectionSource: .fuzzyMatch
                        )
                        results.append(potential)
                    }
                }
            }
        }

        return results
    }

    /// Detect named entities using capitalization patterns
    private func detectNamedEntities(in text: String, sceneID: UUID) -> [PotentialCard] {
        var results: [PotentialCard] = []

        // Use NaturalLanguage framework for better NER
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            guard let tag = tag else { return true }

            let name = String(text[tokenRange])

            // Map NLTag to Kinds
            let kind: Kinds
            let confidence: Float

            switch tag {
            case .personalName:
                kind = .characters
                confidence = 0.8
            case .placeName:
                kind = .locations
                confidence = 0.8
            case .organizationName:
                kind = .characters // Treat organizations as characters for now
                confidence = 0.6
            default:
                return true // Skip other tags
            }

            let potential = PotentialCard(
                kind: kind,
                name: name,
                confidence: confidence,
                textRange: tokenRange,
                sceneID: sceneID,
                detectionSource: .capitalizationPattern
            )
            results.append(potential)

            return true
        }

        // Fallback: Simple capitalization pattern for non-recognized entities
        let capitalizedWords = extractCapitalizedPhrases(from: text)
        for phrase in capitalizedWords {
            // Skip common words and short phrases
            guard phrase.count > 2, !isCommonWord(phrase) else { continue }

            // Infer kind based on context (simple heuristic)
            let kind = inferKindFromContext(phrase, in: text)

            let potential = PotentialCard(
                kind: kind,
                name: phrase,
                confidence: 0.5, // Lower confidence for simple capitalization
                sceneID: sceneID,
                detectionSource: .capitalizationPattern
            )
            results.append(potential)
        }

        return results
    }

    /// Detect entities using context keywords (e.g., "took the sword", "arrived at")
    private func detectContextKeywords(in text: String, sceneID: UUID) -> [PotentialCard] {
        var results: [PotentialCard] = []

        // Artifact detection patterns
        let artifactPatterns = [
            "took the ", "grabbed the ", "held the ", "wielded the ",
            "carried the ", "dropped the ", "found the ", "lost the "
        ]

        // Location detection patterns
        let locationPatterns = [
            "arrived at ", "entered the ", "left the ", "walked to ",
            "traveled to ", "reached the ", "at the ", "in the "
        ]

        // Character detection patterns (reserved for future use)
        let _ = [
            "met ", "saw ", "spoke to ", "talked to ",
            "with ", "and ", "joined "
        ]

        // Detect artifacts
        for pattern in artifactPatterns {
            if let range = text.range(of: pattern, options: .caseInsensitive) {
                let afterPattern = text[range.upperBound...]
                if let wordMatch = afterPattern.firstMatch(of: /\w+/) {
                    let artifactName = String(wordMatch.output)
                    let potential = PotentialCard(
                        kind: .artifacts,
                        name: artifactName.capitalized,
                        confidence: 0.6,
                        sceneID: sceneID,
                        detectionSource: .contextKeyword
                    )
                    results.append(potential)
                }
            }
        }

        // Detect locations
        for pattern in locationPatterns {
            if let range = text.range(of: pattern, options: .caseInsensitive) {
                let afterPattern = text[range.upperBound...]
                if let wordMatch = afterPattern.firstMatch(of: /[A-Z]\w+/) {
                    let locationName = String(wordMatch.output)
                    let potential = PotentialCard(
                        kind: .locations,
                        name: locationName,
                        confidence: 0.6,
                        sceneID: sceneID,
                        detectionSource: .contextKeyword
                    )
                    results.append(potential)
                }
            }
        }

        return results
    }

    // MARK: - Helper Methods

    /// Extract individual words from text (tokenization)
    private func extractWords(from text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var words: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let word = String(text[tokenRange])
            words.append(word)
            return true
        }

        return words
    }

    /// Extract capitalized phrases (potential proper nouns)
    private func extractCapitalizedPhrases(from text: String) -> [String] {
        var phrases: [String] = []

        // Match sequences of capitalized words
        let pattern = /[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*/
        let matches = text.matches(of: pattern)

        for match in matches {
            phrases.append(String(match.output))
        }

        return phrases
    }

    /// Calculate similarity between two strings (Levenshtein-based)
    private func calculateSimilarity(between s1: String, and s2: String) -> Double {
        let s1Lower = s1.lowercased()
        let s2Lower = s2.lowercased()

        let distance = levenshteinDistance(s1Lower, s2Lower)
        let maxLength = max(s1Lower.count, s2Lower.count)

        guard maxLength > 0 else { return 0.0 }

        return 1.0 - (Double(distance) / Double(maxLength))
    }

    /// Levenshtein distance algorithm
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2Array.count + 1), count: s1Array.count + 1)

        for i in 0...s1Array.count {
            matrix[i][0] = i
        }

        for j in 0...s2Array.count {
            matrix[0][j] = j
        }

        for i in 1...s1Array.count {
            for j in 1...s2Array.count {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return matrix[s1Array.count][s2Array.count]
    }

    /// Check if a word is a common word (to filter out false positives)
    private func isCommonWord(_ word: String) -> Bool {
        let commonWords = Set([
            "the", "and", "but", "or", "at", "in", "on", "to", "for",
            "of", "a", "an", "is", "was", "were", "be", "been",
            "The", "And", "But", "Or", "At", "In", "On", "To", "For"
        ])
        return commonWords.contains(word)
    }

    /// Infer card kind from context (simple heuristic)
    private func inferKindFromContext(_ phrase: String, in text: String) -> Kinds {
        let lowercasedText = text.lowercased()
        let lowercasedPhrase = phrase.lowercased()

        // Check for character indicators
        if lowercasedText.contains("\(lowercasedPhrase) said") ||
           lowercasedText.contains("\(lowercasedPhrase) asked") ||
           lowercasedText.contains("\(lowercasedPhrase) replied") {
            return .characters
        }

        // Check for location indicators
        if lowercasedText.contains("at \(lowercasedPhrase)") ||
           lowercasedText.contains("in \(lowercasedPhrase)") ||
           lowercasedText.contains("to \(lowercasedPhrase)") {
            return .locations
        }

        // Default to characters for proper nouns
        return .characters
    }

    /// Deduplicate potential cards by name and kind, keeping highest confidence
    private func deduplicatePotentialCards(_ cards: [PotentialCard]) -> [PotentialCard] {
        var uniqueCards: [String: PotentialCard] = [:]

        for card in cards {
            let key = "\(card.kind.rawValue):\(card.name.lowercased())"

            if let existing = uniqueCards[key] {
                // Keep card with higher confidence
                if card.confidence > existing.confidence {
                    uniqueCards[key] = card
                }
            } else {
                uniqueCards[key] = card
            }
        }

        return Array(uniqueCards.values)
    }

    // MARK: - Card Cache Management

    /// Load all cards into cache for faster matching
    private func loadCardCache() {
        let relevantKinds: [Kinds] = [
            .characters, .artifacts, .locations,
            .vehicles, .buildings, .chronicles
        ]

        for kind in relevantKinds {
            cardCache[kind] = cardRepository.fetch(byKind: kind)
        }
    }

    /// Refresh card cache (call when cards are added/modified)
    func refreshCache() {
        loadCardCache()
    }
}
