//
//  ExternalStorageTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 1.3: Tests for external storage (@Attribute(.externalStorage))
//  Tests large image data handling and CloudKit CKAsset integration
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

@Suite("External Storage", .serialized)
struct ExternalStorageTests {

    // MARK: - External Storage Attribute Tests

    @Test("Small data stored inline")
    @MainActor
    func smallDataInline() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .characters, name: "Test", subtitle: "", detailedText: "")

        // Small data (1KB)
        let smallData = Data(repeating: 0x41, count: 1024)
        card.originalImageData = smallData

        context.insert(card)
        try context.save()

        let cardID = card.id

        let fetched = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )).first

        #expect(fetched?.originalImageData == smallData)
    }

    @Test("Large data uses external storage")
    @MainActor
    func largeDataExternal() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .locations, name: "Map", subtitle: "", detailedText: "")

        // Large data (5MB)
        let largeData = Data(repeating: 0x42, count: 5 * 1024 * 1024)
        card.originalImageData = largeData

        context.insert(card)
        try context.save()

        let cardID = card.id

        // Verify large data persisted
        let fetched = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )).first

        #expect(fetched?.originalImageData?.count == largeData.count)
    }

    @Test("External data can be updated")
    @MainActor
    func externalDataUpdate() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .locations, name: "Map", subtitle: "", detailedText: "")

        // Initial data
        let data1 = Data(repeating: 0x01, count: 2 * 1024 * 1024)
        card.originalImageData = data1
        context.insert(card)
        try context.save()

        let cardID = card.id

        // Update with new data
        let data2 = Data(repeating: 0x02, count: 3 * 1024 * 1024)
        card.originalImageData = data2
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )).first

        #expect(fetched?.originalImageData?.count == data2.count)
        #expect(fetched?.originalImageData?.first == 0x02)
    }

    @Test("External data can be deleted")
    @MainActor
    func externalDataDeletion() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .locations, name: "Map", subtitle: "", detailedText: "")
        let largeData = Data(repeating: 0x42, count: 2 * 1024 * 1024)
        card.originalImageData = largeData

        context.insert(card)
        try context.save()

        let cardID = card.id

        // Delete the data
        card.originalImageData = nil
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )).first

        #expect(fetched?.originalImageData == nil)
    }

    @Test("Multiple cards with external storage")
    @MainActor
    func multipleCardsExternalStorage() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card1 = Card(kind: .locations, name: "Map1", subtitle: "", detailedText: "")
        let card2 = Card(kind: .locations, name: "Map2", subtitle: "", detailedText: "")
        let card3 = Card(kind: .locations, name: "Map3", subtitle: "", detailedText: "")

        card1.originalImageData = Data(repeating: 0x01, count: 1 * 1024 * 1024)
        card2.originalImageData = Data(repeating: 0x02, count: 2 * 1024 * 1024)
        card3.originalImageData = Data(repeating: 0x03, count: 3 * 1024 * 1024)

        context.insert(card1)
        context.insert(card2)
        context.insert(card3)
        try context.save()

        // All should persist correctly
        let allCards = try context.fetch(FetchDescriptor<Card>())
        let withImages = allCards.filter { $0.originalImageData != nil }

        #expect(withImages.count >= 3)
    }

    // MARK: - Image Version External Storage Tests

    @Test("ImageVersion stores data externally")
    @MainActor
    func imageVersionExternalStorage() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = TestFixtures.createSampleCharacter(name: "Test", context: context)

        let version = ImageVersion(
            card: card,
            imageData: Data(repeating: 0x55, count: 4 * 1024 * 1024), // 4MB
            prompt: "Test image",
            provider: "Test Provider",
            versionNumber: 1
        )

        context.insert(version)
        try context.save()

        let versionID = version.id

        let fetched = try context.fetch(FetchDescriptor<ImageVersion>(
            predicate: #Predicate { $0.id == versionID }
        )).first

        #expect(fetched?.imageData?.count == 4 * 1024 * 1024)
    }

    // MARK: - Draft Map Work External Storage Tests

    @Test("Draft map work data uses external storage")
    @MainActor
    func draftMapWorkExternalStorage() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .locations, name: "Map", subtitle: "", detailedText: "")

        // Simulate draft drawing data (2MB PKDrawing data)
        let draftData = Data(repeating: 0x99, count: 2 * 1024 * 1024)
        card.draftMapWorkData = draftData

        context.insert(card)
        try context.save()

        let cardID = card.id

        let fetched = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )).first

        #expect(fetched?.draftMapWorkData?.count == draftData.count)
    }

    // MARK: - Performance Tests

    @Test("Large data save is performant")
    @MainActor
    func largeDataSavePerformant() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .locations, name: "Map", subtitle: "", detailedText: "")
        let largeData = Data(repeating: 0x42, count: 10 * 1024 * 1024) // 10MB

        card.originalImageData = largeData
        context.insert(card)

        let start = Date()
        try context.save()
        let duration = Date().timeIntervalSince(start)

        // Should save in < 2 seconds
        #expect(duration < 2.0)
    }

    @Test("Large data fetch is performant")
    @MainActor
    func largeDataFetchPerformant() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let card = Card(kind: .locations, name: "Map", subtitle: "", detailedText: "")
        let largeData = Data(repeating: 0x42, count: 10 * 1024 * 1024) // 10MB
        card.originalImageData = largeData

        context.insert(card)
        try context.save()

        let cardID = card.id

        let start = Date()
        let fetched = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )).first
        let duration = Date().timeIntervalSince(start)

        // Should fetch in < 1 second
        #expect(duration < 1.0)
        #expect(fetched?.originalImageData?.count == largeData.count)
    }
}
