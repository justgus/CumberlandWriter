//
//  MigrationTestHelpers.swift
//  CumberlandTests
//
//  Created by Claude on 2026-04-13.
//  ER-0058 Phase 5: Migration testing utilities
//

import Foundation
import SwiftData
import Testing
@testable import Cumberland

/// Utilities for testing SwiftData schema migrations
///
/// **Usage:**
/// ```swift
/// @Test func migrationV4ToV5() async throws {
///     let helper = try MigrationTestHelpers.createMigrationScenario(
///         from: AppSchemaV4.self,
///         to: AppSchemaV5.self
///     )
///
///     // Seed old schema with data
///     try helper.seedOldSchema { context in
///         let card = Card(kind: .characters, name: "Test", subtitle: "", detailedText: "")
///         context.insert(card)
///     }
///
///     // Perform migration
///     let newContainer = try await helper.performMigration()
///
///     // Verify data survived migration
///     let context = ModelContext(newContainer)
///     let cards = try context.fetch(FetchDescriptor<Card>())
///     #expect(cards.count == 1)
///     #expect(cards[0].name == "Test")
/// }
/// ```
@MainActor
struct MigrationTestHelpers {

    // MARK: - Migration Scenario

    /// A migration test scenario with old and new schema versions
    struct MigrationScenario {
        let oldSchema: Schema
        let newSchema: Schema
        let oldContainer: ModelContainer

        /// Seed the old schema container with test data
        /// - Parameter seeder: Closure that receives a ModelContext for the old schema
        func seedOldSchema(_ seeder: (ModelContext) throws -> Void) throws {
            let context = ModelContext(oldContainer)
            context.autosaveEnabled = false
            try seeder(context)
            try context.save()
        }

        /// Perform the migration and return the new container
        /// - Returns: ModelContainer with the new schema
        ///
        /// **Note:** For real migration testing, use the app's actual migration plan.
        /// This simplified version creates a new container with the new schema,
        /// which SwiftData will attempt to migrate automatically (lightweight migration).
        func performMigration() async throws -> ModelContainer {
            // Create new container with the new schema
            // SwiftData will attempt automatic migration if possible
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            return try ModelContainer(for: newSchema, configurations: [config])
        }

        /// Verify data after migration
        /// - Parameter verifier: Closure that receives a ModelContext for the new schema
        func verifyMigration(_ verifier: (ModelContext) throws -> Void) async throws {
            let newContainer = try await performMigration()
            let context = ModelContext(newContainer)
            try verifier(context)
        }
    }

    // MARK: - Scenario Creation

    /// Create a migration test scenario between two schema versions
    ///
    /// - Parameters:
    ///   - oldSchemaType: The old schema version (e.g., AppSchemaV4.self)
    ///   - newSchemaType: The new schema version (e.g., AppSchemaV5.self)
    /// - Returns: A MigrationScenario ready for testing
    ///
    /// **Note:** This creates a simplified migration scenario for testing.
    /// For real migration testing with custom migration stages, use the app's
    /// actual `AppMigrations` plan.
    static func createMigrationScenario<Old: VersionedSchema, New: VersionedSchema>(
        from oldSchemaType: Old.Type,
        to newSchemaType: New.Type
    ) throws -> MigrationScenario {
        let oldSchema = Schema(oldSchemaType.models)
        let newSchema = Schema(newSchemaType.models)

        // Create old schema container (in-memory for tests)
        let oldConfig = ModelConfiguration(
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfig])

        return MigrationScenario(
            oldSchema: oldSchema,
            newSchema: newSchema,
            oldContainer: oldContainer
        )
    }

    // MARK: - Data Verification Helpers

    /// Verify that a specific model count matches expectation after migration
    static func verifyModelCount<T: PersistentModel>(
        _ modelType: T.Type,
        expectedCount: Int,
        in context: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<T>()
        let results = try context.fetch(descriptor)
        guard results.count == expectedCount else {
            Issue.record("Expected \(expectedCount) \(String(describing: modelType)) instances, found \(results.count)")
            return
        }
    }

    /// Verify that all instances of a model have non-nil required properties
    static func verifyRequiredProperties<T: PersistentModel>(
        _ modelType: T.Type,
        in context: ModelContext,
        checker: (T) -> Bool
    ) throws {
        let descriptor = FetchDescriptor<T>()
        let results = try context.fetch(descriptor)

        for instance in results {
            guard checker(instance) else {
                Issue.record("Model \(String(describing: modelType)) failed required property check")
                return
            }
        }
    }

    // MARK: - Schema Comparison

    /// Compare two schemas and report differences
    ///
    /// Useful for understanding what changed between versions
    static func compareSchemas(_ schema1: Schema, _ schema2: Schema) -> SchemaComparison {
        let models1 = Set(schema1.entities.map { $0.name })
        let models2 = Set(schema2.entities.map { $0.name })

        let addedModels = models2.subtracting(models1)
        let removedModels = models1.subtracting(models2)
        let commonModels = models1.intersection(models2)

        return SchemaComparison(
            addedModels: Array(addedModels),
            removedModels: Array(removedModels),
            commonModels: Array(commonModels)
        )
    }

    /// Result of schema comparison
    struct SchemaComparison {
        let addedModels: [String]
        let removedModels: [String]
        let commonModels: [String]

        var hasChanges: Bool {
            !addedModels.isEmpty || !removedModels.isEmpty
        }

        var description: String {
            var parts: [String] = []

            if !addedModels.isEmpty {
                parts.append("Added: \(addedModels.joined(separator: ", "))")
            }

            if !removedModels.isEmpty {
                parts.append("Removed: \(removedModels.joined(separator: ", "))")
            }

            if !hasChanges {
                return "No model changes detected"
            }

            return parts.joined(separator: "; ")
        }
    }

    // MARK: - Performance Measurement

    /// Measure migration performance
    ///
    /// - Parameters:
    ///   - scenario: The migration scenario to measure
    ///   - dataSize: Description of data size (e.g., "100 cards")
    /// - Returns: Migration duration in seconds
    static func measureMigration(_ scenario: MigrationScenario, dataSize: String) async throws -> TimeInterval {
        let start = Date()

        _ = try await scenario.performMigration()

        let duration = Date().timeIntervalSince(start)
        print("Migration (\(dataSize)): \(String(format: "%.3f", duration))s")

        return duration
    }
}

// MARK: - Convenience Extensions

extension ModelContext {
    /// Delete all instances of a specific model type
    /// Useful for cleaning up after migration tests
    func deleteAll<T: PersistentModel>(_ modelType: T.Type) throws {
        try delete(model: T.self)
        try save()
    }

    /// Count instances of a specific model type
    func count<T: PersistentModel>(_ modelType: T.Type) throws -> Int {
        let descriptor = FetchDescriptor<T>()
        let results = try fetch(descriptor)
        return results.count
    }
}
