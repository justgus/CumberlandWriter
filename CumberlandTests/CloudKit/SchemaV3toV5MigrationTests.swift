//
//  SchemaV3toV5MigrationTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 1.3: Tests for Schema V3 to V5 migration
//  V3→V5 skips V4 (which was identical to V3) and adds ImageVersion model
//  Plus optional AI metadata properties on Card
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

@Suite("Schema V3 to V5 Migration", .serialized)
struct SchemaV3toV5MigrationTests {

    // MARK: - Schema Version Tests

    @Test("Schema V5 has correct version identifier")
    func schemaV5VersionIdentifier() {
        let version = AppSchemaV5.versionIdentifier

        #expect(version.major == 5)
        #expect(version.minor == 0)
        #expect(version.patch == 0)
    }

    @Test("Schema V5 includes ImageVersion model")
    func schemaV5Models() {
        let models = AppSchemaV5.models

        // V5 should have 11 models (10 from V3 + ImageVersion)
        #expect(models.count == 11)
    }

    @Test("Migration plan skips V4")
    func migrationPlanSkipsV4() {
        let schemas = AppMigrations.schemas

        // Should include V1, V2, V3, V5 (not V4)
        #expect(schemas.count == 4)

        // Verify V5 is in the list
        let hasV5 = schemas.contains { schema in
            schema.versionIdentifier.major == 5
        }
        #expect(hasV5)
    }

    // MARK: - ImageVersion Model Tests

    @Test("ImageVersion can be created and persisted")
    @MainActor
    func imageVersionCreation() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = TestFixtures.createSampleCharacter(name: "Test", context: context)

        let version = ImageVersion(
            card: card,
            imageData: Data([0x01, 0x02, 0x03]),
            prompt: "Test prompt",
            provider: "Test Provider",
            versionNumber: 1
        )

        if card.imageVersions == nil { card.imageVersions = [] }
        card.imageVersions?.append(version)

        context.insert(version)
        try context.save()

        let versionID = version.id
        let cardID = card.id

        let fetched = try context.fetch(FetchDescriptor<ImageVersion>(
            predicate: #Predicate { $0.id == versionID }
        )).first

        #expect(fetched != nil)
        #expect(fetched?.versionNumber == 1)
        #expect(fetched?.card?.id == cardID)
    }

    @Test("Card can have multiple image versions")
    @MainActor
    func cardMultipleImageVersions() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = TestFixtures.createSampleCharacter(name: "Test", context: context)

        let v1 = ImageVersion(
            card: card,
            imageData: Data([0x01]),
            prompt: "Version 1",
            provider: "Test Provider",
            versionNumber: 1
        )

        let v2 = ImageVersion(
            card: card,
            imageData: Data([0x02]),
            prompt: "Version 2",
            provider: "Test Provider",
            versionNumber: 2
        )

        if card.imageVersions == nil { card.imageVersions = [] }
        card.imageVersions?.append(v1)
        card.imageVersions?.append(v2)

        context.insert(v1)
        context.insert(v2)
        try context.save()

        // Verify both versions are associated with card
        #expect(card.imageVersions?.count == 2)
    }

    @Test("ImageVersion stores creation timestamp")
    @MainActor
    func imageVersionTimestamp() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = TestFixtures.createSampleCharacter(name: "Test", context: context)

        let before = Date()
        let version = ImageVersion(
            card: card,
            imageData: Data([0x01]),
            prompt: "Test",
            provider: "Test Provider"
        )
        let after = Date()

        context.insert(version)
        try context.save()

        // generatedAt should be set during initialization (between before and after)
        #expect(version.generatedAt >= before)
        #expect(version.generatedAt <= after)
    }

    // MARK: - AI Metadata Tests (ER-0009/ER-0017)
    // Note: AI metadata is stored on ImageVersion, not directly on Card

    @Test("ImageVersion stores AI generation metadata")
    @MainActor
    func imageVersionAIMetadata() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = TestFixtures.createSampleCharacter(name: "Hero", context: context)
        let version = ImageVersion(
            card: card,
            imageData: Data([0x01, 0x02]),
            prompt: "A brave warrior in medieval armor",
            provider: "OpenAI",
            modelVersion: "dall-e-3"
        )

        context.insert(version)
        try context.save()

        let versionID = version.id

        let fetched = try context.fetch(FetchDescriptor<ImageVersion>(
            predicate: #Predicate { $0.id == versionID }
        )).first

        #expect(fetched?.prompt == "A brave warrior in medieval armor")
        #expect(fetched?.provider == "OpenAI")
        #expect(fetched?.modelVersion == "dall-e-3")
    }

    // MARK: - Optional Property Migration Tests

    @Test("Optional properties default to nil")
    @MainActor
    func optionalPropertiesDefaultNil() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .locations, name: "Castle", subtitle: "", detailedText: "")
        context.insert(card)
        try context.save()

        // All optional properties should be nil or empty
        #expect(card.originalImageData == nil)
        #expect(card.thumbnailData == nil)
        #expect(card.draftMapWorkData == nil)
        #expect(card.imageVersions?.isEmpty ?? true)
    }

    @Test("Optional properties can be set independently")
    @MainActor
    func optionalPropertiesIndependent() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .artifacts, name: "Sword", subtitle: "", detailedText: "")

        // Set only some optional properties
        card.originalImageData = Data([0x01, 0x02])
        card.thumbnailData = Data([0x03, 0x04])
        // Leave draftMapWorkData nil

        context.insert(card)
        try context.save()

        let cardID = card.id

        let fetched = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )).first

        #expect(fetched?.originalImageData != nil)
        #expect(fetched?.thumbnailData != nil)
        #expect(fetched?.draftMapWorkData == nil)
    }
}
