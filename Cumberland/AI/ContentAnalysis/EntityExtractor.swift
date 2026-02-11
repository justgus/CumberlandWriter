//
//  EntityExtractor.swift
//  Cumberland
//
//  High-level entity extraction orchestrator (ER-0010 Phase 5). Delegates to
//  the configured AIProviderProtocol to extract entities from card description
//  text, then applies filtering, deduplication, and confidence-threshold
//  logic before returning typed ExtractedEntity results.
//

import Foundation
import SwiftData

/// High-level entity extraction orchestrator
/// Uses AI providers to extract entities and applies filtering, deduplication, and confidence thresholding
/// Phase 5 (ER-0010) - Content Analysis MVP
class EntityExtractor {

    // MARK: - Properties

    private let provider: AIProviderProtocol
    private let settings: AISettings
    private let preprocessor: TextPreprocessor

    // MARK: - Initialization

    init(provider: AIProviderProtocol, settings: AISettings = .shared, preprocessor: TextPreprocessor? = nil) {
        self.provider = provider
        self.settings = settings
        // Use custom config for entity extraction - only preprocess for VERY long texts (5000+ words)
        // Claude can handle large texts natively, and preprocessing loses fantasy names
        let entityExtractionConfig = TextPreprocessor.Config(
            maxWords: 3000,
            contextWordsPerSide: 25,
            preprocessThreshold: 5000, // Only preprocess texts over 5000 words
            maxSentencesPerEntity: 10
        )
        self.preprocessor = preprocessor ?? TextPreprocessor(config: entityExtractionConfig)
    }

    // MARK: - Public API

    /// Result from entity and relationship extraction (ER-0020)
    /// ER-0015: Extended with statistics for better empty state messaging
    struct ExtractionResult {
        let entities: [Entity]
        let relationships: [DetectedRelationship]
        let totalEntitiesDetected: Int  // Before filtering
        let entitiesFilteredAsExisting: Int  // Filtered because they already exist as cards
    }

    /// Extract entities AND relationships from text (ER-0020)
    /// - Parameters:
    ///   - text: The text to analyze
    ///   - existingCards: Existing cards in the database for deduplication
    /// - Returns: Extracted entities and AI-generated relationships
    func extractEntities(from text: String, existingCards: [Card]) async throws -> ExtractionResult {
        // Validate input
        guard !text.isEmpty else {
            throw AIProviderError.invalidInput(reason: "Text cannot be empty")
        }

        let wordCount = text.split(separator: " ").count
        let minWords = settings.analysisMinWordCount
        guard wordCount >= minWords else {
            throw AIProviderError.textTooShort(minLength: minWords, actual: wordCount)
        }

        #if DEBUG
        print("🔍 [EntityExtractor] Extracting entities from text")
        print("   Provider: \(provider.name)")
        print("   Word count: \(wordCount)")
        print("   Confidence threshold: \(settings.confidenceThreshold)")
        #endif

        // Preprocess text if it's too long (chapter-length prose optimization)
        let preprocessResult = preprocessor.preprocess(text)
        let textToAnalyze = preprocessResult.condensedText

        #if DEBUG
        if preprocessResult.wasPreprocessed {
            print("   📝 Preprocessed: \(preprocessResult.originalWordCount) → \(preprocessResult.condensedWordCount) words (\(Int(preprocessResult.compressionRatio * 100))%)")
        }
        #endif

        // Call AI provider with preprocessed text
        let result = try await provider.analyzeText(textToAnalyze, for: .entityExtraction)

        guard var entities = result.entities else {
            #if DEBUG
            print("   No entities found")
            #endif
            return ExtractionResult(
                entities: [],
                relationships: [],
                totalEntitiesDetected: 0,
                entitiesFilteredAsExisting: 0
            )
        }

        #if DEBUG
        print("   Raw entities found: \(entities.count)")
        #endif

        // ER-0015: Track total before filtering
        let totalDetected = entities.count

        // Apply filters
        entities = filterByConfidence(entities)
        entities = filterByEnabledTypes(entities)
        entities = deduplicateEntities(entities)

        // ER-0015: Track count before filtering existing cards
        let countBeforeExistingFilter = entities.count
        entities = filterAgainstExistingCards(entities, existingCards: existingCards)
        let entitiesFiltered = countBeforeExistingFilter - entities.count

        // ER-0020: Extract relationships from AI provider
        let relationships = result.relationships ?? []

        #if DEBUG
        print("✅ [EntityExtractor] Extraction complete")
        print("   Final entities: \(entities.count)")
        for entity in entities {
            print("   - \(entity.name) (\(entity.type.rawValue), \(String(format: "%.0f", entity.confidence * 100))%)")
        }
        print("   AI relationships extracted: \(relationships.count)")
        print("   Entities filtered as existing: \(entitiesFiltered)")
        #endif

        return ExtractionResult(
            entities: entities,
            relationships: relationships,
            totalEntitiesDetected: totalDetected,
            entitiesFilteredAsExisting: entitiesFiltered
        )
    }

    // MARK: - Filtering

    /// Filter entities by confidence threshold
    private func filterByConfidence(_ entities: [Entity]) -> [Entity] {
        let threshold = settings.confidenceThreshold
        let filtered = entities.filter { $0.confidence >= threshold }

        #if DEBUG
        let removed = entities.count - filtered.count
        if removed > 0 {
            print("   Filtered \(removed) entities below confidence threshold (\(String(format: "%.0f", threshold * 100))%)")
        }
        #endif

        return filtered
    }

    /// Filter entities by enabled entity types
    private func filterByEnabledTypes(_ entities: [Entity]) -> [Entity] {
        let filtered = entities.filter { entity in
            settings.isEntityTypeEnabled(entity.type)
        }

        #if DEBUG
        let removed = entities.count - filtered.count
        if removed > 0 {
            print("   Filtered \(removed) entities with disabled types")
        }
        #endif

        return filtered
    }

    /// Remove duplicate entities (case-insensitive name matching)
    private func deduplicateEntities(_ entities: [Entity]) -> [Entity] {
        var seen = Set<String>()
        var unique: [Entity] = []

        for entity in entities {
            let key = entity.name.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(entity)
            }
        }

        #if DEBUG
        let removed = entities.count - unique.count
        if removed > 0 {
            print("   Removed \(removed) duplicate entities")
        }
        #endif

        return unique
    }

    /// Filter out entities that already exist as cards
    private func filterAgainstExistingCards(_ entities: [Entity], existingCards: [Card]) -> [Entity] {
        // Build set of existing card names (case-insensitive)
        let existingNames = Set(existingCards.map { $0.name.lowercased() })

        let filtered = entities.filter { entity in
            !existingNames.contains(entity.name.lowercased())
        }

        #if DEBUG
        let removed = entities.count - filtered.count
        if removed > 0 {
            print("   Filtered \(removed) entities that already exist as cards")
        }
        #endif

        return filtered
    }

    // MARK: - Analysis Scope Adjustment

    /// Adjust confidence threshold based on analysis scope
    /// - Note: This modifies the settings confidence threshold
    func applyAnalysisScope() {
        let scope = settings.analysisScopeEnum

        switch scope {
        case .conservative:
            settings.confidenceThreshold = max(settings.confidenceThreshold, 0.80)
        case .moderate:
            settings.confidenceThreshold = max(settings.confidenceThreshold, 0.70)
        case .aggressive:
            settings.confidenceThreshold = max(settings.confidenceThreshold, 0.60)
        }

        #if DEBUG
        print("   Applied \(scope.displayName) scope: threshold = \(String(format: "%.0f", settings.confidenceThreshold * 100))%")
        #endif
    }
}

// MARK: - Convenience Extensions

extension EntityExtractor {
    /// Extract entities grouped by type
    func extractEntitiesGrouped(from text: String, existingCards: [Card]) async throws -> [EntityType: [Entity]] {
        let result = try await extractEntities(from: text, existingCards: existingCards)

        var grouped: [EntityType: [Entity]] = [:]
        for entity in result.entities {
            grouped[entity.type, default: []].append(entity)
        }

        return grouped
    }

    /// Get entity count without performing extraction
    static func estimateEntityCount(in text: String) -> Int {
        // Simple heuristic: ~1 entity per 50 words (very rough)
        let wordCount = text.split(separator: " ").count
        return max(1, wordCount / 50)
    }
}

// MARK: - Statistics

extension EntityExtractor {
    /// Statistics about extracted entities
    struct ExtractionStats {
        let totalFound: Int
        let filteredByConfidence: Int
        let filteredByType: Int
        let duplicates: Int
        let alreadyExist: Int
        let final: Int

        var filterRate: Double {
            guard totalFound > 0 else { return 0.0 }
            return Double(totalFound - final) / Double(totalFound)
        }
    }

    /// Extract entities with detailed statistics
    func extractEntitiesWithStats(from text: String, existingCards: [Card]) async throws -> (entities: [Entity], stats: ExtractionStats) {
        let result = try await provider.analyzeText(text, for: .entityExtraction)
        guard let rawEntities = result.entities else {
            let stats = ExtractionStats(totalFound: 0, filteredByConfidence: 0, filteredByType: 0, duplicates: 0, alreadyExist: 0, final: 0)
            return ([], stats)
        }

        let totalFound = rawEntities.count

        let afterConfidence = filterByConfidence(rawEntities)
        let filteredByConfidence = totalFound - afterConfidence.count

        let afterType = filterByEnabledTypes(afterConfidence)
        let filteredByType = afterConfidence.count - afterType.count

        let afterDedup = deduplicateEntities(afterType)
        let duplicates = afterType.count - afterDedup.count

        let final = filterAgainstExistingCards(afterDedup, existingCards: existingCards)
        let alreadyExist = afterDedup.count - final.count

        let stats = ExtractionStats(
            totalFound: totalFound,
            filteredByConfidence: filteredByConfidence,
            filteredByType: filteredByType,
            duplicates: duplicates,
            alreadyExist: alreadyExist,
            final: final.count
        )

        return (final, stats)
    }
}
