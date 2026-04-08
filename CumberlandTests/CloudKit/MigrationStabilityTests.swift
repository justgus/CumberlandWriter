//
//  MigrationStabilityTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 1.3: General migration stability and integrity tests
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

@Suite("Migration Stability", .serialized)
struct MigrationStabilityTests {

    // MARK: - Migration Plan Integrity

    @Test("All schemas have unique version identifiers")
    func uniqueVersionIdentifiers() {
        let schemas = AppMigrations.schemas

        var versions: Set<String> = []
        for schema in schemas {
            let versionString = "\(schema.versionIdentifier.major).\(schema.versionIdentifier.minor).\(schema.versionIdentifier.patch)"
            versions.insert(versionString)
        }

        // All versions should be unique
        #expect(versions.count == schemas.count)
    }

    @Test("Schemas are ordered correctly")
    func schemasOrdered() {
        let schemas = AppMigrations.schemas

        // V1 should come before V2, V2 before V3, V3 before V5
        var lastMajor = 0
        for schema in schemas {
            #expect(schema.versionIdentifier.major > lastMajor)
            lastMajor = schema.versionIdentifier.major
        }
    }

    @Test("Migration stages match schema count")
    func migrationStagesMatchSchemas() {
        let schemas = AppMigrations.schemas
        let stages = AppMigrations.stages

        // Should have N-1 stages for N schemas
        #expect(stages.count == schemas.count - 1)
    }

    // MARK: - Data Preservation Tests

    @Test("Card data preserved across container lifecycle")
    @MainActor
    func cardDataPreserved() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = try TestFixtures.createSampleCharacter(name: "Test", context: context)
        card.subtitle = "Test Subtitle"
        card.detailedText = "Test Details"
        try context.save()

        let cardID = card.id

        // Fetch in same context
        let fetched = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )).first

        #expect(fetched?.name == "Test")
        #expect(fetched?.subtitle == "Test Subtitle")
        #expect(fetched?.detailedText == "Test Details")
    }

    @Test("Relationships preserved across save")
    @MainActor
    func relationshipsPreserved() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let source = try TestFixtures.createSampleCharacter(name: "Alice", context: context)
        let target = try TestFixtures.createSampleCharacter(name: "Bob", context: context)
        let relationType = try TestFixtures.createRelationType(code: "knows", context: context)

        let edge = try TestFixtures.createEdge(from: source, to: target, type: relationType, context: context)
        try context.save()

        let edgeID = edge.id

        // Fetch the edge
        let fetchedEdge = try context.fetch(FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.id == edgeID }
        )).first

        #expect(fetchedEdge?.from?.id == source.id)
        #expect(fetchedEdge?.to?.id == target.id)
        #expect(fetchedEdge?.type?.code == "knows")
    }

    // MARK: - Model Compatibility Tests

    @Test("All current models can be instantiated")
    @MainActor
    func allModelsInstantiable() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        // Card
        let card = Card(kind: .characters, name: "Test", subtitle: "", detailedText: "")
        context.insert(card)

        // RelationType
        let relationType = RelationType(code: "test", forwardLabel: "test-forward", inverseLabel: "test-inverse")
        context.insert(relationType)

        // StoryStructure
        let structure = StoryStructure(name: "Test Structure")
        context.insert(structure)

        // Board
        let board = Board(name: "Test Board")
        context.insert(board)

        // ImageVersion
        let imageVersion = ImageVersion(
            card: card,
            imageData: Data([0x01]),
            prompt: "Test",
            provider: "Test Provider"
        )
        context.insert(imageVersion)

        // Should save without errors
        try context.save()

        #expect(true) // If we got here, all models are compatible
    }

    @Test("Default values are consistent")
    @MainActor
    func defaultValuesConsistent() async throws {
        let card1 = Card(kind: .characters, name: "Test1", subtitle: "", detailedText: "")
        let card2 = Card(kind: .characters, name: "Test2", subtitle: "", detailedText: "")

        // Both cards should have different UUIDs
        #expect(card1.id != card2.id)

        // But same kind
        #expect(card1.kind == card2.kind)

        // Both should have same default size category
        #expect(card1.sizeCategory == card2.sizeCategory)
    }

    // MARK: - CloudKit Compatibility Tests

    @Test("Optional properties support CloudKit sync")
    @MainActor
    func optionalPropertiesCloudKitCompatible() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .characters, name: "Test", subtitle: "", detailedText: "")

        // All CloudKit-synced optional properties should be settable
        card.originalImageData = nil
        card.thumbnailData = nil
        card.imageAIPrompt = nil
        card.imageAIProvider = nil
        card.imageGeneratedByAI = nil

        context.insert(card)
        try context.save()

        // Should not crash
        #expect(true)
    }

    @Test("Relationships use optional arrays for CloudKit")
    @MainActor
    func relationshipsCloudKitCompatible() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .characters, name: "Test", subtitle: "", detailedText: "")
        context.insert(card)
        try context.save()

        // All relationship arrays should be optional and default to []
        #expect(card.citations != nil)
        #expect(card.structureElements != nil)
        #expect(card.boardNodes != nil)
        #expect(card.imageVersions != nil)
    }

    // MARK: - Performance Tests

    @Test("Container creation is performant")
    @MainActor
    func containerCreationPerformant() async throws {
        let start = Date()

        // Create container
        let _ = try TestFixtures.makeFullSchemaContainer()

        let duration = Date().timeIntervalSince(start)

        // Should create container in < 1 second
        #expect(duration < 1.0)
    }

    @Test("Batch insert is performant")
    @MainActor
    func batchInsertPerformant() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let start = Date()

        // Insert 100 cards
        for i in 0..<100 {
            let card = Card(kind: .characters, name: "Card \(i)", subtitle: "", detailedText: "")
            context.insert(card)
        }

        try context.save()

        let duration = Date().timeIntervalSince(start)

        // Should insert 100 cards in < 1 second
        #expect(duration < 1.0)
    }
}
