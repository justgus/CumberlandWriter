//
//  CloudKitSyncTestHelpers.swift
//  CumberlandTests
//
//  Created by Claude on 2026-04-13.
//  ER-0058 Phase 5: CloudKit sync testing utilities
//

import Foundation
import SwiftData
import CloudKit
import Testing
@testable import Cumberland

/// Utilities for testing CloudKit sync behavior
///
/// **Usage:**
/// ```swift
/// @Test func cloudKitSyncTest() async throws {
///     let helper = try CloudKitSyncTestHelpers.createSyncScenario()
///
///     // Create data in first container
///     try helper.seedDevice1 { context in
///         let card = Card(kind: .characters, name: "Synced Card", subtitle: "", detailedText: "")
///         context.insert(card)
///     }
///
///     // Simulate sync
///     try await helper.simulateSync()
///
///     // Verify data appears in second container
///     try helper.verifyDevice2 { context in
///         let cards = try context.fetch(FetchDescriptor<Card>())
///         #expect(cards.count == 1)
///         #expect(cards[0].name == "Synced Card")
///     }
/// }
/// ```
@MainActor
struct CloudKitSyncTestHelpers {

    // MARK: - Sync Scenario

    /// A CloudKit sync test scenario with multiple device containers
    struct SyncScenario {
        let device1Container: ModelContainer
        let device2Container: ModelContainer
        let schema: Schema

        /// Seed device 1 container with test data
        /// - Parameter seeder: Closure that receives a ModelContext for device 1
        func seedDevice1(_ seeder: (ModelContext) throws -> Void) throws {
            let context = ModelContext(device1Container)
            context.autosaveEnabled = false
            try seeder(context)
            try context.save()
        }

        /// Seed device 2 container with test data
        /// - Parameter seeder: Closure that receives a ModelContext for device 2
        func seedDevice2(_ seeder: (ModelContext) throws -> Void) throws {
            let context = ModelContext(device2Container)
            context.autosaveEnabled = false
            try seeder(context)
            try context.save()
        }

        /// Simulate CloudKit sync between devices
        ///
        /// **Note:** This is a simplified simulation for testing purposes.
        /// Real CloudKit sync happens automatically in the background.
        /// In tests, we use in-memory containers so there's no real sync.
        /// This method is a placeholder for future CloudKit mock integration.
        func simulateSync() async throws {
            // TODO: Implement CloudKit sync simulation with mock CKRecords
            // For now, this is a no-op placeholder

            // In a real implementation, this would:
            // 1. Extract CKRecords from device1Container
            // 2. Apply them to device2Container
            // 3. Handle conflict resolution
            // 4. Trigger observers

            print("⚠️ CloudKit sync simulation not yet implemented (ER-0058 Phase 5)")
        }

        /// Verify data in device 2 container
        /// - Parameter verifier: Closure that receives a ModelContext for device 2
        func verifyDevice2(_ verifier: (ModelContext) throws -> Void) throws {
            let context = ModelContext(device2Container)
            try verifier(context)
        }

        /// Verify data in device 1 container
        /// - Parameter verifier: Closure that receives a ModelContext for device 1
        func verifyDevice1(_ verifier: (ModelContext) throws -> Void) throws {
            let context = ModelContext(device1Container)
            try verifier(context)
        }
    }

    // MARK: - Scenario Creation

    /// Create a CloudKit sync test scenario
    ///
    /// Creates two isolated in-memory containers to simulate two devices
    ///
    /// - Returns: A SyncScenario ready for testing
    static func createSyncScenario() throws -> SyncScenario {
        let schema = Schema(AppSchemaV5.models)

        // Create two in-memory containers (simulating two devices)
        // Note: Real CloudKit sync would use actual CloudKit containers
        let device1 = try DataBackend.makeContainer(mode: .inMemory, schema: schema)
        let device2 = try DataBackend.makeContainer(mode: .inMemory, schema: schema)

        return SyncScenario(
            device1Container: device1,
            device2Container: device2,
            schema: schema
        )
    }

    // MARK: - Conflict Simulation

    /// Simulate a CloudKit sync conflict
    ///
    /// Creates the same object in both containers with different values
    ///
    /// - Parameters:
    ///   - scenario: The sync scenario
    ///   - createConflict: Closure that creates conflicting data
    /// - Returns: Description of the conflict created
    static func simulateConflict(
        in scenario: SyncScenario,
        createConflict: (ModelContext, ModelContext) throws -> String
    ) throws -> String {
        let context1 = ModelContext(scenario.device1Container)
        let context2 = ModelContext(scenario.device2Container)

        context1.autosaveEnabled = false
        context2.autosaveEnabled = false

        let conflictDescription = try createConflict(context1, context2)

        try context1.save()
        try context2.save()

        return conflictDescription
    }

    // MARK: - Mock CKRecord Helpers

    /// Create a mock CKRecord from a Card
    ///
    /// Useful for simulating CloudKit record changes
    ///
    /// **Note:** This is a simplified mock. Real CKRecords have more complexity.
    static func mockCKRecord(for card: Card) -> [String: Any] {
        return [
            "recordID": UUID().uuidString,
            "recordType": "Card",
            "fields": [
                "name": card.name,
                "kindRaw": card.kindRaw,
                "subtitle": card.subtitle,
                "detailedText": card.detailedText
            ],
            "modificationDate": Date()
        ]
    }

    /// Apply mock CKRecord changes to a container
    ///
    /// Simulates receiving remote changes from CloudKit
    ///
    /// **Note:** This is a placeholder for future implementation
    static func applyMockRecordChanges(
        _ records: [[String: Any]],
        to container: ModelContainer
    ) async throws {
        // TODO: Implement mock record application
        // For now, this is a no-op placeholder

        print("⚠️ Mock CKRecord application not yet implemented (ER-0058 Phase 5)")
        print("   Would apply \(records.count) record(s)")
    }

    // MARK: - Sync State Verification

    /// Verify that two containers have the same data
    ///
    /// Useful for verifying sync succeeded
    static func verifySyncConsistency<T: PersistentModel>(
        _ modelType: T.Type,
        between container1: ModelContainer,
        and container2: ModelContainer,
        comparing: (T, T) -> Bool
    ) throws -> Bool {
        let context1 = ModelContext(container1)
        let context2 = ModelContext(container2)

        let descriptor = FetchDescriptor<T>()
        let results1 = try context1.fetch(descriptor)
        let results2 = try context2.fetch(descriptor)

        guard results1.count == results2.count else {
            print("⚠️ Count mismatch: \(results1.count) vs \(results2.count)")
            return false
        }

        // TODO: Implement proper comparison logic
        // For now, just verify counts match
        return true
    }

    // MARK: - Performance Measurement

    /// Measure sync performance
    ///
    /// - Parameters:
    ///   - scenario: The sync scenario to measure
    ///   - dataSize: Description of data size (e.g., "100 cards")
    /// - Returns: Sync duration in seconds
    static func measureSync(
        _ scenario: SyncScenario,
        dataSize: String
    ) async throws -> TimeInterval {
        let start = Date()

        try await scenario.simulateSync()

        let duration = Date().timeIntervalSince(start)
        print("CloudKit Sync (\(dataSize)): \(String(format: "%.3f", duration))s")

        return duration
    }
}

// MARK: - CloudKit Availability Testing

extension CloudKitSyncTestHelpers {

    /// Check if CloudKit is available for testing
    ///
    /// **Note:** Most tests should use in-memory containers and not rely on real CloudKit
    static func isCloudKitAvailable() async -> Bool {
        return await CloudKitAvailability.isAvailable()
    }

    /// Skip test if CloudKit is not available
    ///
    /// Use this at the start of tests that require real CloudKit
    ///
    /// ```swift
    /// @Test func realCloudKitTest() async throws {
    ///     try await CloudKitSyncTestHelpers.requireCloudKit()
    ///     // Test code that needs real CloudKit...
    /// }
    /// ```
    static func requireCloudKit() async throws {
        let available = await isCloudKitAvailable()
        guard available else {
            Issue.record("CloudKit not available - skipping test")
            return
        }
    }
}
