//
//  InMemoryBackend.swift
//  Cumberland
//
//  Created by Claude on 2026-04-13.
//  ER-0058 Phase 1: In-memory storage backend for testing and previews
//

import SwiftData
import OSLog

/// In-memory storage backend
/// Provides ephemeral storage that does not persist between app launches
/// Used primarily for unit tests, UI tests, and Xcode previews
struct InMemoryBackend {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "InMemoryBackend")

    /// Create an in-memory ModelContainer
    ///
    /// - Parameter schema: The SwiftData schema to use
    /// - Returns: A ModelContainer configured for in-memory storage
    /// - Throws: SwiftData initialization errors
    ///
    /// **CRITICAL FIX (DR-0115, ER-0058):**
    /// The `cloudKitDatabase: .none` parameter is REQUIRED to prevent CloudKit conflicts.
    /// Without this, `ModelConfiguration(isStoredInMemoryOnly: true)` defaults to
    /// `.automatic` CloudKit database, which causes initialization failures.
    static func makeContainer(schema: Schema) throws -> ModelContainer {
        logger.debug("Creating in-memory ModelContainer")

        // Configure in-memory storage with CloudKit explicitly disabled
        let config = ModelConfiguration(
            "InMemory",
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none  // ⬅️ CRITICAL: Prevents CloudKit conflicts
        )

        let container = try ModelContainer(for: schema, configurations: [config])
        logger.info("In-memory ModelContainer created successfully")

        return container
    }
}
