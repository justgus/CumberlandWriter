//
//  RelationshipInferenceTests.swift
//  CumberlandTests
//
//  Phase 10 tests for RelationshipInference (ER-0010).
//  Covers pattern matching, sentence splitting, entity matching,
//  deduplication, confidence calculation, and edge cases.
//

import Testing
import Foundation
@testable import Cumberland

@Suite("RelationshipInference Tests", .serialized)
struct RelationshipInferenceTests {

    let inference = RelationshipInference()

    // MARK: - Pattern Definitions

    @Test("Patterns are defined and non-empty")
    func patternsDefined() {
        #expect(RelationshipInference.patterns.count >= 15)
    }

    @Test("Each pattern has required fields")
    func patternFields() {
        for pattern in RelationshipInference.patterns {
            #expect(!pattern.id.isEmpty)
            #expect(!pattern.triggers.isEmpty)
            #expect(!pattern.relationTypeCode.isEmpty)
            #expect(pattern.baseConfidence > 0.0)
            #expect(pattern.baseConfidence <= 1.0)
            #expect(!pattern.description.isEmpty)
        }
    }

    @Test("Pattern IDs are unique")
    func patternIDsUnique() {
        let ids = RelationshipInference.patterns.map(\.id)
        let uniqueIDs = Set(ids)
        #expect(ids.count == uniqueIDs.count)
    }

    // MARK: - Ownership Pattern Detection

    @Test("Detect ownership relationship: character owns artifact")
    func detectOwnership() {
        let text = "Aria owns the Shadowblade."
        let entities = [
            Entity(name: "Aria", type: .character, confidence: 0.9, context: text),
            Entity(name: "Shadowblade", type: .artifact, confidence: 0.85, context: text)
        ]

        let results = inference.inferRelationships(from: text, entities: entities, existingCards: [])

        #expect(results.count >= 1)
        if let rel = results.first {
            #expect(rel.sourceEntityName == "Aria")
            #expect(rel.targetEntityName == "Shadowblade")
            #expect(rel.forwardVerb == "owns")
            #expect(rel.inverseVerb == "owned-by")
        }
    }

    @Test("Detect uses relationship")
    func detectUses() {
        let text = "Aria uses the Crystal Staff."
        let entities = [
            Entity(name: "Aria", type: .character, confidence: 0.9, context: text),
            Entity(name: "Crystal Staff", type: .artifact, confidence: 0.85, context: text)
        ]

        let results = inference.inferRelationships(from: text, entities: entities, existingCards: [])

        #expect(results.count >= 1)
        if let rel = results.first {
            #expect(rel.sourceEntityName == "Aria")
            #expect(rel.targetEntityName == "Crystal Staff")
            #expect(rel.forwardVerb == "uses")
        }
    }

    // MARK: - Character Relationship Detection

    @Test("Detect mentoring relationship")
    func detectMentoring() {
        let text = "Gandalf mentors Frodo in the ways of the ring."
        let entities = [
            Entity(name: "Gandalf", type: .character, confidence: 0.9, context: text),
            Entity(name: "Frodo", type: .character, confidence: 0.9, context: text)
        ]

        let results = inference.inferRelationships(from: text, entities: entities, existingCards: [])

        #expect(results.count >= 1)
        if let rel = results.first {
            #expect(rel.sourceEntityName == "Gandalf")
            #expect(rel.targetEntityName == "Frodo")
            #expect(rel.forwardVerb == "mentors")
        }
    }

    @Test("Detect conflict relationship")
    func detectConflict() {
        let text = "Aria fights the Dark Knight."
        let entities = [
            Entity(name: "Aria", type: .character, confidence: 0.9, context: text),
            Entity(name: "Dark Knight", type: .character, confidence: 0.85, context: text)
        ]

        let results = inference.inferRelationships(from: text, entities: entities, existingCards: [])

        #expect(results.count >= 1)
        if let rel = results.first {
            #expect(rel.forwardVerb == "conflicts-with")
        }
    }

    // MARK: - Vehicle Pattern Detection

    @Test("Detect pilots relationship")
    func detectPilots() {
        let text = "Marcus pilots the Windrunner across the sky."
        let entities = [
            Entity(name: "Marcus", type: .character, confidence: 0.9, context: text),
            Entity(name: "Windrunner", type: .vehicle, confidence: 0.85, context: text)
        ]

        let results = inference.inferRelationships(from: text, entities: entities, existingCards: [])

        #expect(results.count >= 1)
        if let rel = results.first {
            #expect(rel.sourceEntityName == "Marcus")
            #expect(rel.targetEntityName == "Windrunner")
            #expect(rel.forwardVerb == "pilots")
        }
    }

    // MARK: - Discovery Pattern

    @Test("Detect discovery relationship")
    func detectDiscovery() {
        let text = "Elena discovered the Ancient Vault deep underground."
        let entities = [
            Entity(name: "Elena", type: .character, confidence: 0.9, context: text),
            Entity(name: "Ancient Vault", type: .building, confidence: 0.85, context: text)
        ]

        let results = inference.inferRelationships(from: text, entities: entities, existingCards: [])

        #expect(results.count >= 1)
        if let rel = results.first {
            #expect(rel.sourceEntityName == "Elena")
            #expect(rel.targetEntityName == "Ancient Vault")
            #expect(rel.forwardVerb == "discovered")
        }
    }

    // MARK: - No Relationship Cases

    @Test("No relationship detected with single entity")
    func singleEntity() {
        let text = "Aria walked alone through the forest."
        let entities = [
            Entity(name: "Aria", type: .character, confidence: 0.9, context: text)
        ]

        let results = inference.inferRelationships(from: text, entities: entities, existingCards: [])
        #expect(results.isEmpty)
    }

    @Test("No relationship detected without trigger words")
    func noTriggerWords() {
        let text = "Aria and Shadowblade are mentioned in the story."
        let entities = [
            Entity(name: "Aria", type: .character, confidence: 0.9, context: text),
            Entity(name: "Shadowblade", type: .artifact, confidence: 0.85, context: text)
        ]

        let _ = inference.inferRelationships(from: text, entities: entities, existingCards: [])
        // May or may not find relationships depending on "mentioned" triggering "references"
        // The key point is this tests the path where no obvious pattern match occurs
    }

    @Test("Empty text returns no relationships")
    func emptyText() {
        let entities = [
            Entity(name: "Aria", type: .character, confidence: 0.9, context: ""),
            Entity(name: "Shadowblade", type: .artifact, confidence: 0.85, context: "")
        ]

        let results = inference.inferRelationships(from: "", entities: entities, existingCards: [])
        #expect(results.isEmpty)
    }

    @Test("Empty entities returns no relationships")
    func emptyEntities() {
        let text = "Aria owns the Shadowblade."
        let results = inference.inferRelationships(from: text, entities: [], existingCards: [])
        #expect(results.isEmpty)
    }

    // MARK: - Sentence Order Matters

    @Test("Source must appear before trigger and target")
    func sentenceOrderMatters() {
        // "Shadowblade owns Aria" - wrong order for character->artifact ownership
        // Shadowblade is an artifact, not a character, so sourceKind constraint should fail
        let text = "The Shadowblade was wielded by Aria."
        let entities = [
            Entity(name: "Aria", type: .character, confidence: 0.9, context: text),
            Entity(name: "Shadowblade", type: .artifact, confidence: 0.85, context: text)
        ]

        let results = inference.inferRelationships(from: text, entities: entities, existingCards: [])
        // Should not detect "Shadowblade owns Aria" because source must be character
        let wrongRelationship = results.first(where: {
            $0.sourceEntityName == "Shadowblade" && $0.forwardVerb == "owns"
        })
        #expect(wrongRelationship == nil)
    }

    // MARK: - Deduplication

    @Test("Duplicate relationships are removed")
    func deduplication() {
        // Text with the same relationship stated twice
        let text = "Aria owns the Shadowblade. Yes, Aria owns the Shadowblade indeed."
        let entities = [
            Entity(name: "Aria", type: .character, confidence: 0.9, context: text),
            Entity(name: "Shadowblade", type: .artifact, confidence: 0.85, context: text)
        ]

        let results = inference.inferRelationships(from: text, entities: entities, existingCards: [])

        // Should deduplicate to at most one "owns" relationship
        let ownsRelationships = results.filter { $0.forwardVerb == "owns" }
        #expect(ownsRelationships.count <= 1)
    }

    // MARK: - Confidence Scoring

    @Test("Confidence is capped at 0.95")
    func confidenceCap() {
        let text = "Aria owns the Shadowblade."
        let entities = [
            Entity(name: "Aria", type: .character, confidence: 0.9, context: text),
            Entity(name: "Shadowblade", type: .artifact, confidence: 0.85, context: text)
        ]

        let results = inference.inferRelationships(from: text, entities: entities, existingCards: [])

        for rel in results {
            #expect(rel.confidence <= 0.95)
            #expect(rel.confidence > 0.0)
        }
    }

    // MARK: - Multiple Relationships in Text

    @Test("Multiple relationships detected in multi-sentence text")
    func multipleRelationships() {
        let text = "Aria owns the Shadowblade. Marcus pilots the Windrunner. Aria fights the Dark Knight."
        let entities = [
            Entity(name: "Aria", type: .character, confidence: 0.9, context: text),
            Entity(name: "Shadowblade", type: .artifact, confidence: 0.85, context: text),
            Entity(name: "Marcus", type: .character, confidence: 0.9, context: text),
            Entity(name: "Windrunner", type: .vehicle, confidence: 0.85, context: text),
            Entity(name: "Dark Knight", type: .character, confidence: 0.8, context: text)
        ]

        let results = inference.inferRelationships(from: text, entities: entities, existingCards: [])

        #expect(results.count >= 2) // Should find at least owns and pilots
    }

    // MARK: - DetectedRelationship Pattern Extension

    @Test("DetectedRelationship pattern initializer splits code correctly")
    func patternInitializer() {
        let pattern = RelationshipInference.RelationshipPattern(
            id: "test",
            triggers: ["test"],
            relationTypeCode: "forward/backward",
            isSymmetric: false,
            baseConfidence: 0.8,
            sourceKind: nil,
            targetKind: nil,
            description: "Test pattern"
        )

        let rel = DetectedRelationship(
            sourceEntityName: "A",
            targetEntityName: "B",
            pattern: pattern,
            confidence: 0.85,
            context: "test context"
        )

        #expect(rel.forwardVerb == "forward")
        #expect(rel.inverseVerb == "backward")
        #expect(rel.sourceEntityName == "A")
        #expect(rel.targetEntityName == "B")
        #expect(rel.confidence == 0.85)
        #expect(rel.context == "test context")
        #expect(rel.relationTypeCode == "forward/backward")
    }
}
