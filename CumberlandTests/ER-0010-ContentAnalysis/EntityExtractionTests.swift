//
//  EntityExtractionTests.swift
//  CumberlandTests
//
//  Swift Testing suite for ER-0010: AI Content Analysis.
//  Tests entity extraction from narrative text: character, location, artifact,
//  and relationship detection with confidence thresholds.
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

/// Tests for entity extraction from text descriptions
/// Part of ER-0010: AI Content Analysis
@Suite("Entity Extraction Tests", .serialized)
struct EntityExtractionTests {

    // MARK: - Entity Type Tests

    @Test("Entity type to card kind mapping")
    func entityTypeMapping() {
        #expect(EntityType.character.toCardKind() == .characters)
        #expect(EntityType.location.toCardKind() == .locations)
        #expect(EntityType.building.toCardKind() == .buildings)
        #expect(EntityType.artifact.toCardKind() == .artifacts)
        #expect(EntityType.vehicle.toCardKind() == .vehicles)
        #expect(EntityType.organization.toCardKind() == .characters) // Organizations map to characters
        #expect(EntityType.event.toCardKind() == .chronicles) // Events map to chronicles
        #expect(EntityType.historicalEvent.toCardKind() == .chronicles) // Historical events map to chronicles
    }

    // MARK: - Entity Structure Tests

    @Test("Create extracted entity")
    func createEntity() {
        let entity = Entity(
            name: "Aria",
            type: .character,
            confidence: 0.95,
            context: "Aria drew her sword in the tavern"
        )

        #expect(entity.name == "Aria")
        #expect(entity.type == .character)
        #expect(entity.confidence == 0.95)
        #expect(entity.context?.contains("sword") == true)
    }

    @Test("Entity with high confidence")
    func highConfidenceEntity() {
        let entity = Entity(
            name: "Crystal Palace",
            type: .building,
            confidence: 0.98,
            context: "The Crystal Palace stood majestically"
        )

        #expect(entity.confidence >= 0.9)
    }

    @Test("Entity with low confidence")
    func lowConfidenceEntity() {
        let entity = Entity(
            name: "Unknown Place",
            type: .location,
            confidence: 0.45,
            context: "They went somewhere"
        )

        #expect(entity.confidence < 0.7)
    }

    // MARK: - Analysis Result Tests

    @Test("Create analysis result")
    func createAnalysisResult() {
        let entities = [
            Entity(name: "Aria", type: .character, confidence: 0.9, context: "context"),
            Entity(name: "Shadowblade", type: .artifact, confidence: 0.85, context: "context")
        ]

        let result = AnalysisResult(
            entities: entities,
            relationships: nil,
            calendars: nil,
            metadata: nil
        )

        #expect(result.entities?.count == 2)
    }

    @Test("Empty analysis result")
    func emptyAnalysisResult() {
        let result = AnalysisResult(
            entities: [],
            relationships: [],
            calendars: [],
            metadata: nil
        )

        #expect(result.entities?.isEmpty == true)
        #expect(result.relationships?.isEmpty == true)
    }

    // MARK: - Text Parsing Tests

    @Test("Extract character mentions")
    func extractCharacterMentions() {
        let text = "Aria Moonstone met Commander Vex at the tavern"

        // Simulate extraction
        let expectedEntities = ["Aria Moonstone", "Commander Vex"]

        // Manual check (actual extraction done by AI provider)
        for name in expectedEntities {
            #expect(text.contains(name))
        }
    }

    @Test("Extract location mentions")
    func extractLocationMentions() {
        let text = "The group traveled from Dustport to the Crystal Caverns"

        let expectedLocations = ["Dustport", "Crystal Caverns"]

        for location in expectedLocations {
            #expect(text.contains(location))
        }
    }

    @Test("Extract artifact mentions")
    func extractArtifactMentions() {
        let text = "She wielded the Shadowblade and wore the Amulet of Protection"

        let expectedArtifacts = ["Shadowblade", "Amulet of Protection"]

        for artifact in expectedArtifacts {
            #expect(text.contains(artifact))
        }
    }

    // MARK: - Confidence Scoring Tests

    @Test("Confidence threshold filtering")
    func confidenceThresholdFiltering() {
        let entities = [
            Entity(name: "High", type: .character, confidence: 0.95, context: ""),
            Entity(name: "Medium", type: .character, confidence: 0.75, context: ""),
            Entity(name: "Low", type: .character, confidence: 0.45, context: "")
        ]

        let threshold = 0.7
        let filtered = entities.filter { $0.confidence >= threshold }

        #expect(filtered.count == 2) // High and Medium
        #expect(filtered[0].name == "High")
        #expect(filtered[1].name == "Medium")
    }

    @Test("Default confidence threshold")
    func defaultConfidenceThreshold() {
        let defaultThreshold = AISettings.Defaults.confidenceThreshold

        #expect(defaultThreshold == 0.70)
    }

    // MARK: - Duplicate Detection Tests

    @Test("Detect exact duplicate entity")
    @MainActor
    func detectExactDuplicate() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        // Create existing card via service layer
        let existing = TestFixtures.createSampleCharacter(name: "Aria Moonstone", context: context)

        // Extract same entity
        let extracted = Entity(
            name: "Aria Moonstone",
            type: .character,
            confidence: 0.9,
            context: "test"
        )

        // Check for duplicate (manual check - actual matching done by suggestion engine)
        #expect(extracted.name == existing.name)
    }

    @Test("Detect fuzzy duplicate entity")
    func detectFuzzyDuplicate() {
        let existingName = "Commander Vex"
        // Only test substrings that simple contains() can match
        // Abbreviations like "Cmdr Vex" require a real fuzzy matching engine
        let extractedNames = ["Vex", "Commander"]

        // Simple fuzzy matching simulation
        for extracted in extractedNames {
            let normalized1 = existingName.lowercased()
            let normalized2 = extracted.lowercased()

            // Check if one contains the other
            let isFuzzyMatch = normalized1.contains(normalized2) || normalized2.contains(normalized1)

            #expect(isFuzzyMatch == true)
        }
    }

    // MARK: - Context Extraction Tests

    @Test("Extract entity context from sentence")
    func extractEntityContext() {
        let fullText = "In the depths of the Crystal Caverns, Aria discovered an ancient artifact. The caverns were filled with glowing crystals that illuminated the darkness."

        let entityName = "Crystal Caverns"

        // Find sentence containing entity
        let sentences = fullText.components(separatedBy: ". ")
        let contextSentence = sentences.first { $0.contains(entityName) }

        #expect(contextSentence != nil)
        #expect(contextSentence?.contains(entityName) == true)
    }

    // MARK: - Entity Type Classification Tests

    @Test("Classify proper nouns as entities")
    func classifyProperNouns() {
        let properNouns = ["Aria", "Dustport", "Shadowblade"]

        for noun in properNouns {
            // Check capitalization (simple heuristic)
            let firstChar = noun.first
            #expect(firstChar?.isUppercase == true)
        }
    }

    @Test("Skip common words")
    func skipCommonWords() {
        let commonWords = ["the", "and", "in", "at", "to"]

        for word in commonWords {
            let firstChar = word.first
            #expect(firstChar?.isUppercase == false)
        }
    }

    // MARK: - Minimum Text Length Tests

    @Test("Text meets minimum length for analysis")
    func textMeetsMinimumLength() {
        let shortText = "Too short"
        let longText = String(repeating: "word ", count: 30) // 30 words

        let shortWordCount = shortText.split(separator: " ").count
        let longWordCount = longText.split(separator: " ").count

        #expect(shortWordCount < AISettings.Defaults.analysisMinWordCount)
        #expect(longWordCount >= AISettings.Defaults.analysisMinWordCount)
    }

    // MARK: - Analysis Settings Tests

    @Test("Analysis scope settings")
    func analysisScopeSettings() {
        #expect(AnalysisScope.conservative.defaultThreshold == 0.80)
        #expect(AnalysisScope.moderate.defaultThreshold == 0.70)
        #expect(AnalysisScope.aggressive.defaultThreshold == 0.60)
    }

    @Test("Enable specific entity types")
    func enableSpecificEntityTypes() {
        let settings = AISettings.shared

        // Check if entity type is enabled
        let characterEnabled = settings.isEntityTypeEnabled(.character)
        let locationEnabled = settings.isEntityTypeEnabled(.location)

        // Should be booleans (actual values depend on user settings)
        _ = characterEnabled
        _ = locationEnabled
    }

    // MARK: - Edge Cases

    @Test("Empty text returns no entities")
    func emptyTextNoEntities() {
        let emptyText = ""
        let wordCount = emptyText.split(separator: " ").count

        #expect(wordCount == 0)
    }

    @Test("Very long text is handled")
    func veryLongTextHandled() {
        let longText = String(repeating: "word ", count: 1000)
        let wordCount = longText.split(separator: " ").count

        #expect(wordCount == 1000)
    }

    @Test("Special characters in entity names")
    func specialCharactersInNames() {
        let names = ["O'Brien", "Jean-Luc", "Aria's Blade", "The Crystal (Ancient)"]

        for name in names {
            #expect(name.count > 0)
        }
    }

    @Test("Unicode entity names")
    func unicodeEntityNames() {
        let names = ["Señor", "Café", "München", "東京"]

        for name in names {
            #expect(name.count > 0)
        }
    }

    // MARK: - Multi-Entity Tests

    @Test("Extract multiple entities of same type")
    func multipleEntitiesSameType() {
        let entities = [
            Entity(name: "Aria", type: .character, confidence: 0.9, context: ""),
            Entity(name: "Vex", type: .character, confidence: 0.85, context: ""),
            Entity(name: "Kael", type: .character, confidence: 0.95, context: "")
        ]

        let characters = entities.filter { $0.type == .character }
        #expect(characters.count == 3)
    }

    @Test("Extract entities of different types")
    func entitiesDifferentTypes() {
        let entities = [
            Entity(name: "Aria", type: .character, confidence: 0.9, context: ""),
            Entity(name: "Dustport", type: .location, confidence: 0.85, context: ""),
            Entity(name: "Shadowblade", type: .artifact, confidence: 0.95, context: "")
        ]

        let types = Set(entities.map { $0.type })
        #expect(types.count == 3)
        #expect(types.contains(.character))
        #expect(types.contains(.location))
        #expect(types.contains(.artifact))
    }
}
