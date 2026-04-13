//
//  LocalBackend.swift
//  Cumberland
//
//  Created by Claude on 2026-04-13.
//  ER-0058 Phase 1: Local disk storage backend without CloudKit sync
//

import SwiftData
import OSLog

/// Local disk storage backend
/// Provides persistent storage on the local device without CloudKit synchronization
/// Data remains on this device only and works fully offline
struct LocalBackend {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "LocalBackend")

    /// Create a local disk ModelContainer (no CloudKit sync)
    ///
    /// - Parameter schema: The SwiftData schema to use
    /// - Returns: A ModelContainer configured for local disk storage
    /// - Throws: SwiftData initialization errors
    ///
    /// This backend stores data persistently on the local device's disk.
    /// No CloudKit synchronization occurs - data stays on this device only.
    /// Ideal for users who prefer offline-only workflows or don't have iCloud accounts.
    static func makeContainer(schema: Schema) throws -> ModelContainer {
        logger.debug("Creating local disk ModelContainer (no CloudKit)")

        // Configure local disk storage (default location)
        // CloudKit is implicitly disabled by not specifying a CloudKit container
        let config = ModelConfiguration()

        let container = try ModelContainer(for: schema, configurations: [config])
        logger.info("Local disk ModelContainer created successfully")

        return container
    }
}
