//
//  ModelContainerFactory.swift
//  Cumberland
//
//  Created as part of architectural refactoring to separate container
//  creation from the app layer.
//
//  This factory handles all ModelContainer creation logic, including:
//  - Detection of storage mode (first launch vs user preference)
//  - Fallback chains for storage modes
//  - Test/override support
//  - In-memory container creation
//

import Foundation
import SwiftData
import OSLog

/// Factory for creating and configuring ModelContainer instances
///
/// This class encapsulates all container creation logic, supporting:
/// - First-launch automatic detection
/// - User storage preferences
/// - Test mode overrides
/// - In-memory containers for tests/previews
@MainActor
struct ModelContainerFactory {

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "SwiftData")

    // MARK: - Production Container Creation

    /// Create the main application container with automatic mode detection and fallbacks
    /// - Returns: Configured ModelContainer
    static func makeContainer() -> ModelContainer {
        // Build a concrete Schema from the latest versioned schema's models.
        // Latest is V5 (includes Board/BoardNode and AI image metadata).
        let schema = Schema(AppSchemaV5.models)

        // TEMPORARY: Nuclear option for development - delete ALL SwiftData stores
        #if DEBUG
        deleteStoresIfNeeded()
        #endif

        // TESTING BYPASS: Check for override (works on all platforms)
        // Supports environment variables (macOS/simulators) and launch arguments (all platforms)
        if let overrideMode = DataBackend.detectStorageModeOverride() {
            logger.info("🧪 Test override detected: \(overrideMode.displayName)")
            do {
                let container = try DataBackend.makeContainer(mode: overrideMode, schema: schema)
                logger.info("✅ Test container created with override mode: \(overrideMode.displayName)")
                return container
            } catch {
                // This should never fail for in-memory, but log and fall through to fallback
                logger.error("❌ Test override container failed: \(error)")
                fatalError("Test override container creation failed: \(error)")
            }
        }

        // Check if user has a storage preference (AFTER first launch)
        if let userPreferenceRaw = UserDefaults.standard.string(forKey: "storageMode"),
           let userMode = StorageMode.fromString(userPreferenceRaw) {
            // User has chosen a mode - use it exclusively (NO FALLBACK)
            logger.info("📌 User preference found: \(userMode.displayName)")
            do {
                let container = try DataBackend.makeContainerWithUserPreference(mode: userMode, schema: schema)
                logger.info("✅ Container created with user preference: \(userMode.displayName)")
                return container
            } catch {
                // CRITICAL: Do NOT silently fall back - show error to user
                logger.error("❌ CRITICAL: Failed to create container with user preference \(userMode.displayName): \(error)")
                logger.error("   This indicates a serious issue (no iCloud account, disk corruption, etc.)")

                // TODO (Phase 4): Replace fatalError with proper error UI
                // For now, fatal error to prevent data loss from silent fallback
                fatalError("""
                    Failed to create container with your preferred storage mode (\(userMode.displayName)).

                    Error: \(error)

                    Please check:
                    - If using CloudKit: Are you signed into iCloud?
                    - If using Local: Is disk space available?

                    The app cannot continue to prevent data loss from switching storage modes.
                    """)
            }
        }

        // FIRST LAUNCH: No preference set - use fallback chain with auto-detection
        logger.info("🚀 First launch detected - using automatic storage mode selection")
        let container = DataBackend.makeContainerWithFallback(schema: schema)

        // After successful fallback, save the mode that worked for next launch
        let selectedMode = detectCurrentMode(from: container)
        UserDefaults.standard.set(selectedMode.rawValue, forKey: "storageMode")
        logger.info("💾 Saved storage mode preference: \(selectedMode.displayName)")

        return container
    }

    // MARK: - Mode Detection

    /// Detect which storage mode a container is using
    /// - Parameter container: The ModelContainer to inspect
    /// - Returns: The detected StorageMode
    static func detectCurrentMode(from container: ModelContainer) -> StorageMode {
        // Check container configurations to determine which mode is active
        guard let config = container.configurations.first else {
            // Should never happen, but default to local as safest option
            return .local
        }

        // Check if in-memory
        if config.isStoredInMemoryOnly {
            return .inMemory
        }

        // Check if CloudKit by examining the configuration URL for iCloud identifier
        let url = config.url
        if url.absoluteString.contains("iCloud.CumberlandCloud") {
            return .cloudKit("iCloud.CumberlandCloud")
        }

        // Default to local if not in-memory and not CloudKit
        return .local
    }

    // MARK: - Test/Preview Containers

    /// Create an in-memory container for tests or previews
    /// - Parameter types: The model types to include in the schema
    /// - Returns: In-memory ModelContainer
    static func makeInMemoryContainer(_ types: [any PersistentModel.Type]) -> ModelContainer {
        let schema = Schema(types)
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [cfg])
    }

    // MARK: - DEBUG Utilities

    #if DEBUG
    /// Delete all SwiftData stores (nuclear option for development)
    /// Set the flag to true to force deletion on next launch
    private static func deleteStoresIfNeeded() {
        // Set to true to force deletion of all SwiftData stores on next launch
        if false { // Set to true once if migration issues arise
            let fm = FileManager.default

            guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                logger.error("Could not find Application Support directory")
                fatalError("Could not find Application Support directory")
            }

            logger.warning("🔍 Searching for SwiftData stores in: \(appSupport.path)")

            // Delete ALL .store files and related files in Application Support
            var deletedCount = 0

            if let enumerator = fm.enumerator(at: appSupport, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    let filename = fileURL.lastPathComponent

                    // Delete any .store, .store-wal, .store-shm files, or directories that might contain stores
                    if filename.hasSuffix(".store") ||
                       filename.hasSuffix(".store-wal") ||
                       filename.hasSuffix(".store-shm") ||
                       filename.contains("iCloud.CumberlandCloud") {

                        do {
                            // Check if it's a directory
                            var isDirectory: ObjCBool = false
                            if fm.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) {
                                if isDirectory.boolValue {
                                    // Delete entire directory
                                    try fm.removeItem(at: fileURL)
                                    logger.warning("🗑️ Deleted directory: \(filename)")
                                    deletedCount += 1
                                } else {
                                    // Delete file
                                    try fm.removeItem(at: fileURL)
                                    logger.warning("🗑️ Deleted file: \(filename)")
                                    deletedCount += 1
                                }
                            }
                        } catch {
                            logger.error("Failed to delete \(fileURL.path): \(error)")
                        }
                    }
                }
            }

            // Also try to delete the app-specific bundle ID directory entirely
            if let bundleID = Bundle.main.bundleIdentifier {
                let appDir = appSupport.appendingPathComponent(bundleID)
                if fm.fileExists(atPath: appDir.path) {
                    do {
                        try fm.removeItem(at: appDir)
                        logger.warning("🗑️ Deleted entire app directory: \(bundleID)")
                        deletedCount += 1
                    } catch {
                        logger.error("Failed to delete app directory: \(error)")
                    }
                }
            }

            if deletedCount > 0 {
                logger.warning("⚠️ DELETED \(deletedCount) SwiftData store file(s)/directory(ies). Starting completely fresh.")
            } else {
                logger.debug("No existing store files found to delete.")
            }
        }
    }
    #endif
}
