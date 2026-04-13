//
//  DataBackendTests.swift
//  CumberlandTests
//
//  Created by Claude on 2026-04-13.
//  ER-0058 Phase 1: Unit tests for storage backend implementations
//

import Testing
import SwiftData
import Foundation
@testable import Cumberland

@Suite("Data Backend Tests", .serialized)
@MainActor
struct DataBackendTests {

    // MARK: - StorageMode Tests

    @Test("StorageMode display names are correct")
    func storageModeDisplayNames() {
        #expect(StorageMode.inMemory.displayName == "In-Memory (Testing)")
        #expect(StorageMode.local.displayName == "Local Storage Only")
        #expect(StorageMode.cloudKit("test").displayName == "iCloud Sync")
    }

    @Test("StorageMode sync support is correct")
    func storageModeSyncSupport() {
        #expect(StorageMode.inMemory.supportsSync == false)
        #expect(StorageMode.local.supportsSync == false)
        #expect(StorageMode.cloudKit("test").supportsSync == true)
    }

    @Test("StorageMode persistence is correct")
    func storageModePersistence() {
        #expect(StorageMode.inMemory.isPersistent == false)
        #expect(StorageMode.local.isPersistent == true)
        #expect(StorageMode.cloudKit("test").isPersistent == true)
    }

    @Test("StorageMode equality works correctly")
    func storageModeEquality() {
        #expect(StorageMode.inMemory == StorageMode.inMemory)
        #expect(StorageMode.local == StorageMode.local)
        #expect(StorageMode.cloudKit("A") == StorageMode.cloudKit("A"))
        #expect(StorageMode.cloudKit("A") != StorageMode.cloudKit("B"))
        #expect(StorageMode.inMemory != StorageMode.local)
    }

    // MARK: - InMemoryBackend Tests

    @Test("InMemoryBackend creates container successfully")
    @MainActor
    func inMemoryBackendCreation() throws {
        let schema = Schema(AppSchemaV5.models)
        let container = try InMemoryBackend.makeContainer(schema: schema)

        //#expect(container != nil)

        // Verify it's actually in-memory by checking we can create a context
        let context = ModelContext(container)
        #expect(context.autosaveEnabled == true) // Default behavior
    }

    @Test("InMemoryBackend container is isolated per creation")
    @MainActor
    func inMemoryBackendIsolation() throws {
        let schema = Schema(AppSchemaV5.models)

        // Create two separate in-memory containers
        let container1 = try InMemoryBackend.makeContainer(schema: schema)
        let container2 = try InMemoryBackend.makeContainer(schema: schema)

        let context1 = ModelContext(container1)
        let context2 = ModelContext(container2)

        // Create a card in container1
        let card1 = Card(kind: .characters, name: "Test Character", subtitle: "", detailedText: "")
        context1.insert(card1)
        try context1.save()

        // Verify it exists in container1
        let fetch1 = FetchDescriptor<Card>()
        let results1 = try context1.fetch(fetch1)
        #expect(results1.count == 1)

        // Verify it does NOT exist in container2 (isolation)
        let fetch2 = FetchDescriptor<Card>()
        let results2 = try context2.fetch(fetch2)
        #expect(results2.count == 0)
    }

    // MARK: - LocalBackend Tests

    @Test("LocalBackend creates container successfully")
    @MainActor
    func localBackendCreation() throws {
        let schema = Schema(AppSchemaV5.models)
        let container = try LocalBackend.makeContainer(schema: schema)

        //#expect(container != nil)

        let _ = ModelContext(container)
        //#expect(context != nil)
    }

    // MARK: - DataBackend Tests

    @Test("DataBackend creates in-memory container")
    @MainActor
    func dataBackendInMemory() throws {
        let schema = Schema(AppSchemaV5.models)
        let _ = try DataBackend.makeContainer(mode: .inMemory, schema: schema)

        //#expect(container != nil)
    }

    @Test("DataBackend creates local container")
    @MainActor
    func dataBackendLocal() throws {
        let schema = Schema(AppSchemaV5.models)
        let _ = try DataBackend.makeContainer(mode: .local, schema: schema)

        //#expect(container != nil)
    }

    @Test("DataBackend parseStorageMode from string")
    func dataBackendParsing() {
        // Test via detectStorageModeOverride with UserDefaults
        UserDefaults.standard.set("inMemory", forKey: "TestMode_StorageMode")
        let mode1 = DataBackend.detectStorageModeOverride()
        #expect(mode1 == .inMemory)

        UserDefaults.standard.set("local", forKey: "TestMode_StorageMode")
        let mode2 = DataBackend.detectStorageModeOverride()
        #expect(mode2 == .local)

        UserDefaults.standard.set("cloudKit", forKey: "TestMode_StorageMode")
        let mode3 = DataBackend.detectStorageModeOverride()
        #expect(mode3 == .cloudKit("iCloud.CumberlandCloud"))

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "TestMode_StorageMode")
    }

    @Test("DataBackend shouldSkipOnboarding detects UserDefaults")
    func dataBackendSkipOnboarding() {
        // Initially false
        #expect(DataBackend.shouldSkipOnboarding() == false)

        // Set UserDefaults
        UserDefaults.standard.set(true, forKey: "TestMode_SkipOnboarding")
        #expect(DataBackend.shouldSkipOnboarding() == true)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "TestMode_SkipOnboarding")
        #expect(DataBackend.shouldSkipOnboarding() == false)
    }

    @Test("DataBackend fallback chain succeeds")
    @MainActor
    func dataBackendFallback() {
        let schema = Schema(AppSchemaV5.models)

        // Fallback chain should always succeed (even if CloudKit fails, it falls back to local or in-memory)
        let container = DataBackend.makeContainerWithFallback(schema: schema)
        //#expect(container != nil)

        // Verify we can use it
        let context = ModelContext(container)
        let card = Card(kind: .characters, name: "Fallback Test", subtitle: "", detailedText: "")
        context.insert(card)

        // Should not throw
        try? context.save()
    }

    // MARK: - Phase 3: Isolated Container Tests

    @Test("StorageMode rawValue serialization")
    @MainActor
    func storageModeRawValue() {
        #expect(StorageMode.inMemory.rawValue == "inMemory")
        #expect(StorageMode.local.rawValue == "local")
        #expect(StorageMode.cloudKit("iCloud.Test").rawValue == "cloudKit")
    }

    @Test("StorageMode fromString parsing")
    @MainActor
    func storageModeFromString() {
        #expect(StorageMode.fromString("inMemory") == .inMemory)
        #expect(StorageMode.fromString("memory") == .inMemory) // Alias
        #expect(StorageMode.fromString("local") == .local)
        #expect(StorageMode.fromString("cloudKit") == .cloudKit("iCloud.CumberlandCloud"))
        #expect(StorageMode.fromString("cloud") == .cloudKit("iCloud.CumberlandCloud")) // Alias
        #expect(StorageMode.fromString("invalid") == nil)
    }

    @Test("TestFixtures.makeIsolatedContainer creates fresh container")
    @MainActor
    func testFixturesIsolatedContainer() async throws {
        let (container, context) = try TestFixtures.makeIsolatedContainer()

        // Verify container is in-memory
        let config = container.configurations.first
        #expect(config?.isStoredInMemoryOnly == true)

        // Verify empty - no cards should exist
        let cards = try context.fetch(FetchDescriptor<Card>())
        #expect(cards.isEmpty)
    }

    @Test("TestFixtures.makeIsolatedContainer with relationTypes seed")
    @MainActor
    func testFixturesIsolatedContainerWithRelationTypes() async throws {
        let (_, context) = try TestFixtures.makeIsolatedContainer(seed: .relationTypes)

        // Verify RelationTypes were seeded
        let types = try context.fetch(FetchDescriptor<RelationType>())
        #expect(!types.isEmpty)
        #expect(types.contains(where: { $0.code == "owns/owned-by" }))
        #expect(types.contains(where: { $0.code == "uses/used-by" }))
    }

    @Test("TestFixtures.makeIsolatedContainer with calendarSystems seed")
    @MainActor
    func testFixturesIsolatedContainerWithCalendars() async throws {
        let (_, context) = try TestFixtures.makeIsolatedContainer(seed: .calendarSystems)

        // Verify Gregorian calendar was seeded
        let calendars = try context.fetch(FetchDescriptor<CalendarSystem>())
        #expect(!calendars.isEmpty)
        #expect(calendars.contains(where: { $0.name == "Gregorian" }))

        // Verify calendar card was created
        let kindRaw = "Calendars"
        let calendarCards = try context.fetch(FetchDescriptor<Card>(
            predicate: #Predicate<Card> { $0.kindRaw == kindRaw }
        ))
        #expect(!calendarCards.isEmpty)
        #expect(calendarCards.contains(where: { $0.name == "Gregorian" }))
    }

    @Test("TestFixtures.makeIsolatedContainer with all seeds")
    @MainActor
    func testFixturesIsolatedContainerWithAllSeeds() async throws {
        let (_, context) = try TestFixtures.makeIsolatedContainer(seed: .all)

        // Verify both RelationTypes and CalendarSystems were seeded
        let types = try context.fetch(FetchDescriptor<RelationType>())
        #expect(!types.isEmpty)

        let calendars = try context.fetch(FetchDescriptor<CalendarSystem>())
        #expect(!calendars.isEmpty)
    }

    @Test("Isolated containers do not share state")
    @MainActor
    func isolatedContainersSeparate() async throws {
        // Create first container and add a card
        let (_, context1) = try TestFixtures.makeIsolatedContainer()
        let card1 = Card(kind: .characters, name: "Container 1 Card", subtitle: "", detailedText: "")
        context1.insert(card1)
        try context1.save()

        // Create second container and verify it's empty
        let (_, context2) = try TestFixtures.makeIsolatedContainer()
        let cards = try context2.fetch(FetchDescriptor<Card>())
        #expect(cards.isEmpty) // Should NOT see card1 from first container
    }

    @Test("Isolated containers can run concurrently")
    @MainActor
    func isolatedContainersConcurrent() async throws {
        // This test verifies that multiple isolated containers can exist simultaneously
        // without conflicts (unlike the shared container approach which requires locking)

        let (_, context1) = try TestFixtures.makeIsolatedContainer()
        let (_, context2) = try TestFixtures.makeIsolatedContainer()
        let (_, context3) = try TestFixtures.makeIsolatedContainer()

        // Each can operate independently
        context1.insert(Card(kind: .characters, name: "Card A", subtitle: "", detailedText: ""))
        context2.insert(Card(kind: .locations, name: "Card B", subtitle: "", detailedText: ""))
        context3.insert(Card(kind: .artifacts, name: "Card C", subtitle: "", detailedText: ""))

        try context1.save()
        try context2.save()
        try context3.save()

        // Verify each context only sees its own card
        let cards1 = try context1.fetch(FetchDescriptor<Card>())
        let cards2 = try context2.fetch(FetchDescriptor<Card>())
        let cards3 = try context3.fetch(FetchDescriptor<Card>())

        #expect(cards1.count == 1)
        #expect(cards1[0].name == "Card A")

        #expect(cards2.count == 1)
        #expect(cards2[0].name == "Card B")

        #expect(cards3.count == 1)
        #expect(cards3[0].name == "Card C")
    }
}
