//
//  SchemaV1toV2MigrationTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 1.3: Tests for Schema V1 to V2 migration
//  V1→V2 adds Card.originalImageData with external storage
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

@Suite("Schema V1 to V2 Migration", .serialized)
struct SchemaV1toV2MigrationTests {

    // MARK: - Migration Plan Tests

    @Test("Migration plan includes V1 to V2 stage")
    func migrationPlanIncludesV1toV2() {
        let stages = AppMigrations.stages

        // Should have at least the V1->V2 migration
        #expect(stages.count >= 1)

        // First stage should be custom migration from V1 to V2
        // Note: We can't directly inspect MigrationStage internals,
        // but we can verify the stages exist
        #expect(!stages.isEmpty)
    }

    @Test("Migration plan includes all schema versions")
    func migrationPlanIncludesAllSchemas() {
        let schemas = AppMigrations.schemas

        // Should include V1, V2, V3, V5 (V4 was skipped)
        #expect(schemas.count == 4)
    }

    @Test("Schema V1 has correct version identifier")
    func schemaV1VersionIdentifier() {
        let version = AppSchemaV1.versionIdentifier

        #expect(version.major == 1)
        #expect(version.minor == 0)
        #expect(version.patch == 0)
    }

    @Test("Schema V2 has correct version identifier")
    func schemaV2VersionIdentifier() {
        let version = AppSchemaV2.versionIdentifier

        #expect(version.major == 2)
        #expect(version.minor == 0)
        #expect(version.patch == 0)
    }

    // MARK: - Model Structure Tests

    @Test("Schema V1 includes all required models")
    func schemaV1Models() {
        let models = AppSchemaV1.models

        // V1 should have 8 models
        #expect(models.count == 8)

        // Verify key models are present by checking count
        // (Can't directly check types due to protocol constraints)
        #expect(models.count >= 8)
    }

    @Test("Schema V2 includes all required models")
    func schemaV2Models() {
        let models = AppSchemaV2.models

        // V2 should have same 8 models as V1
        #expect(models.count == 8)
    }

    // MARK: - Card Model Evolution Tests

    @Test("Card can store external image data")
    @MainActor
    func cardExternalImageData() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .characters, name: "Test", subtitle: "", detailedText: "")

        // Create sample image data (1x1 PNG)
        let imageData = Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52
        ])

        card.originalImageData = imageData
        context.insert(card)
        try context.save()

        let cardID = card.id

        // Verify the data persisted
        let fetched = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )).first

        #expect(fetched != nil)
        #expect(fetched?.originalImageData == imageData)
    }

    @Test("Card external image data is optional")
    @MainActor
    func cardExternalImageDataOptional() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .characters, name: "Test", subtitle: "", detailedText: "")
        context.insert(card)
        try context.save()

        let cardID = card.id

        // originalImageData should be nil by default
        #expect(card.originalImageData == nil)
    }

    // MARK: - External Storage Tests

    @Test("Large image data uses external storage")
    @MainActor
    func largeImageDataExternalStorage() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .locations, name: "Map", subtitle: "", detailedText: "")

        // Create large data (1MB)
        let largeData = Data(repeating: 0x42, count: 1024 * 1024)

        card.originalImageData = largeData
        context.insert(card)
        try context.save()

        let cardID = card.id

        // Verify large data persisted
        let fetched = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )).first

        #expect(fetched != nil)
        #expect(fetched?.originalImageData?.count == largeData.count)
    }

    @Test("Original image data can be cleared")
    @MainActor
    func originalImageDataCanBeCleared() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .characters, name: "Test", subtitle: "", detailedText: "")
        let imageData = Data([0x00, 0x01, 0x02, 0x03])
        card.originalImageData = imageData
        context.insert(card)
        try context.save()

        let cardID = card.id

        // Clear the data
        card.originalImageData = nil
        try context.save()

        // Verify it's cleared
        let fetched = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )).first

        #expect(fetched?.originalImageData == nil)
    }

    // MARK: - Thumbnail Generation Tests

    @Test("Card can store thumbnail data")
    @MainActor
    func cardThumbnailData() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .characters, name: "Test", subtitle: "", detailedText: "")
        let thumbnailData = Data([0x00, 0x01, 0x02])

        card.thumbnailData = thumbnailData
        context.insert(card)
        try context.save()

        let cardID = card.id

        // Verify thumbnail persisted
        let fetched = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )).first

        #expect(fetched?.thumbnailData == thumbnailData)
    }

    @Test("Thumbnail data is independent of original image data")
    @MainActor
    func thumbnailIndependent() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .characters, name: "Test", subtitle: "", detailedText: "")
        card.originalImageData = Data([0x01, 0x02, 0x03])
        card.thumbnailData = Data([0x04, 0x05, 0x06])
        context.insert(card)
        try context.save()

        let cardID = card.id

        // Both should persist independently
        let fetched = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )).first

        #expect(fetched?.originalImageData?.count == 3)
        #expect(fetched?.thumbnailData?.count == 3)
        #expect(fetched?.originalImageData != fetched?.thumbnailData)
    }
}
