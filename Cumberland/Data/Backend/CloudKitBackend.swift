//
//  CloudKitBackend.swift
//  Cumberland
//
//  Created by Claude on 2026-04-13.
//  ER-0058 Phase 1: CloudKit storage backend with automatic sync
//

import SwiftData
import OSLog

/// CloudKit storage backend
/// Provides persistent storage with automatic iCloud synchronization across devices
/// Requires an active iCloud account
struct CloudKitBackend {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "CloudKitBackend")

    /// Create a CloudKit-backed ModelContainer
    ///
    /// - Parameters:
    ///   - identifier: CloudKit container identifier (e.g., "iCloud.CumberlandCloud")
    ///   - schema: The SwiftData schema to use
    /// - Returns: A ModelContainer configured for CloudKit sync
    /// - Throws: SwiftData initialization errors, CloudKit availability errors
    ///
    /// This backend stores data persistently and synchronizes automatically across
    /// all devices signed into the same iCloud account. CloudKit handles conflict
    /// resolution, schema migrations, and network synchronization automatically.
    static func makeContainer(identifier: String, schema: Schema) throws -> ModelContainer {
        logger.debug("Creating CloudKit ModelContainer with identifier: \(identifier)")

        // Configure CloudKit-backed storage
        let config = ModelConfiguration(identifier)

        let container = try ModelContainer(for: schema, configurations: [config])
        logger.info("CloudKit ModelContainer created successfully: \(identifier)")

        return container
    }
}
