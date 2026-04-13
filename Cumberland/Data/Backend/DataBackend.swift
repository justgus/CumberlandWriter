//
//  DataBackend.swift
//  Cumberland
//
//  Created by Claude on 2026-04-13.
//  ER-0058 Phase 1: Main storage backend orchestrator
//

import SwiftData
import OSLog
import Foundation

/// Centralized data backend orchestrator
/// Provides clean separation between in-memory, local, and CloudKit storage modes
/// Handles mode selection, fallback chain, and cross-platform test overrides
struct DataBackend {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "DataBackend")

    // MARK: - Performance Profiling (ER-0058 Phase 5)

    /// Performance profiling mode (enabled via environment variable or programmatically)
    static var isProfilingEnabled: Bool {
        ProcessInfo.processInfo.environment["PROFILE_SWIFTDATA"] != nil ||
        UserDefaults.standard.bool(forKey: "ProfileMode_Enabled")
    }

    /// Performance metrics collected during profiling
    struct PerformanceMetrics {
        let operation: String
        let duration: TimeInterval
        let timestamp: Date
        let storageMode: StorageMode?

        var description: String {
            let modeStr = storageMode?.displayName ?? "Unknown"
            return String(format: "[\(operation)] \(modeStr): %.3fs at %@", duration, timestamp.formatted())
        }
    }

    /// Collected performance metrics (thread-safe)
    private static let metricsLock = NSLock()
    private static var collectedMetrics: [PerformanceMetrics] = []

    /// Record a performance metric
    static func recordMetric(_ metric: PerformanceMetrics) {
        guard isProfilingEnabled else { return }

        metricsLock.lock()
        defer { metricsLock.unlock() }

        collectedMetrics.append(metric)
        logger.debug("📊 \(metric.description)")
    }

    /// Get all collected metrics
    static func getMetrics() -> [PerformanceMetrics] {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        return collectedMetrics
    }

    /// Clear collected metrics
    static func clearMetrics() {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        collectedMetrics.removeAll()
        logger.info("📊 Cleared performance metrics")
    }

    /// Measure execution time of an operation
    /// - Parameters:
    ///   - operation: Name of the operation
    ///   - mode: Storage mode being used
    ///   - block: The operation to measure
    /// - Returns: Result of the operation
    static func measure<T>(
        _ operation: String,
        mode: StorageMode? = nil,
        _ block: () throws -> T
    ) rethrows -> T {
        let start = Date()
        let result = try block()
        let duration = Date().timeIntervalSince(start)

        recordMetric(PerformanceMetrics(
            operation: operation,
            duration: duration,
            timestamp: Date(),
            storageMode: mode
        ))

        return result
    }

    /// Async version of measure
    static func measureAsync<T>(
        _ operation: String,
        mode: StorageMode? = nil,
        _ block: () async throws -> T
    ) async rethrows -> T {
        let start = Date()
        let result = try await block()
        let duration = Date().timeIntervalSince(start)

        recordMetric(PerformanceMetrics(
            operation: operation,
            duration: duration,
            timestamp: Date(),
            storageMode: mode
        ))

        return result
    }

    // MARK: - Container Creation

    /// Create a ModelContainer with the specified storage mode
    ///
    /// - Parameters:
    ///   - mode: The storage mode to use
    ///   - schema: The SwiftData schema
    /// - Returns: A configured ModelContainer
    /// - Throws: SwiftData initialization errors
    static func makeContainer(mode: StorageMode, schema: Schema) throws -> ModelContainer {
        logger.info("Creating ModelContainer with mode: \(mode.displayName)")

        return try measure("Container Creation", mode: mode) {
            switch mode {
            case .inMemory:
                return try InMemoryBackend.makeContainer(schema: schema)

            case .local:
                return try LocalBackend.makeContainer(schema: schema)

            case .cloudKit(let identifier):
                return try CloudKitBackend.makeContainer(identifier: identifier, schema: schema)
            }
        }
    }

    /// Create a container with automatic mode selection and fallback chain
    ///
    /// **CRITICAL: This should ONLY be used on FIRST LAUNCH when no storage preference exists.**
    ///
    /// Once a user has chosen a storage mode, that mode should be used exclusively.
    /// Falling back to a different mode would switch to a DIFFERENT DATABASE, causing
    /// apparent data loss (the user's existing data would become invisible).
    ///
    /// **Network Offline Scenario:**
    /// - If user has chosen CloudKit and network is offline, CloudKit container
    ///   initialization will SUCCEED but operate in offline mode with local cache.
    /// - CloudKit does NOT fail initialization due to network issues - it gracefully
    ///   degrades to local cache and will sync when network returns.
    /// - Only critical failures (no iCloud account, corrupted database) should trigger fallback.
    ///
    /// Attempts to create a container using the following priority:
    /// 1. CloudKit (if iCloud is available at first launch)
    /// 2. Local disk (if CloudKit fails during first launch)
    /// 3. In-memory (last resort fallback for development/testing)
    ///
    /// - Parameter schema: The SwiftData schema
    /// - Returns: A ModelContainer (guaranteed to succeed via fallback)
    static func makeContainerWithFallback(schema: Schema) -> ModelContainer {
        logger.debug("⚠️ Using fallback chain (should only happen on first launch)")

        // Try CloudKit first
        do {
            logger.info("Attempting CloudKit backend...")
            let container = try makeContainer(mode: .cloudKit("iCloud.CumberlandCloud"), schema: schema)
            logger.info("✅ CloudKit backend initialized successfully")
            return container
        } catch {
            logger.error("❌ CloudKit backend failed: \(error.localizedDescription)")
            logger.warning("   This is expected on first launch if iCloud is not available")
        }

        // Fallback to local disk
        do {
            logger.warning("Falling back to local disk backend...")
            let container = try makeContainer(mode: .local, schema: schema)
            logger.info("✅ Local disk backend initialized successfully")
            return container
        } catch {
            logger.error("❌ Local disk backend failed: \(error.localizedDescription)")
        }

        // Last resort: in-memory
        do {
            logger.warning("Falling back to in-memory backend (last resort)...")
            let container = try makeContainer(mode: .inMemory, schema: schema)
            logger.info("✅ In-memory backend initialized successfully")
            return container
        } catch {
            // This should never happen - in-memory should always succeed
            fatalError("All storage backends failed. In-memory backend error: \(error)")
        }
    }

    /// Create a container using the user's chosen storage mode (NO FALLBACK)
    ///
    /// **Use this for all launches AFTER the user has chosen a storage mode.**
    ///
    /// This method will throw an error if container creation fails, rather than
    /// silently switching to a different storage mode (which would cause data loss).
    ///
    /// - Parameters:
    ///   - mode: The user's chosen storage mode (from UserDefaults/AppSettings)
    ///   - schema: The SwiftData schema
    /// - Returns: A ModelContainer using the specified mode
    /// - Throws: SwiftData initialization errors (which should be shown to the user)
    ///
    /// **Error Handling:**
    /// - If CloudKit fails due to network issues, it will still succeed with local cache
    /// - If CloudKit fails due to no iCloud account, throw error and inform user
    /// - If Local fails due to disk corruption, throw error and offer recovery options
    static func makeContainerWithUserPreference(mode: StorageMode, schema: Schema) throws -> ModelContainer {
        logger.info("Creating container with user preference: \(mode.displayName)")

        do {
            let container = try makeContainer(mode: mode, schema: schema)
            logger.info("✅ Container created successfully with user preference")
            return container
        } catch {
            logger.error("❌ CRITICAL: Failed to create container with user preference: \(error)")
            logger.error("   Mode: \(mode.displayName)")
            logger.error("   This is a critical error - do NOT fall back to different storage mode")
            throw error
        }
    }

    // MARK: - Test & Development Override Detection

    /// Detect storage mode override from environment variables or launch arguments
    ///
    /// Checks multiple sources for test/development overrides (cross-platform):
    /// 1. Environment variables (macOS, simulators)
    /// 2. Launch arguments (all platforms, including devices)
    /// 3. UserDefaults test key (fallback)
    ///
    /// - Returns: Storage mode override, or `nil` if no override is set
    ///
    /// **Usage Examples:**
    /// - Environment variable: `STORAGE_MODE=inMemory`
    /// - Launch argument: `-STORAGE_MODE inMemory`
    /// - UserDefaults: `TestMode_StorageMode = "local"`
    static func detectStorageModeOverride() -> StorageMode? {
        // Method 1: Environment variable (macOS, simulators)
        if let envMode = ProcessInfo.processInfo.environment["STORAGE_MODE"] {
            logger.debug("Storage mode override from environment: \(envMode)")
            return parseStorageMode(envMode)
        }

        // Method 2: Launch argument (all platforms, UI tests)
        // Format: "-STORAGE_MODE inMemory"
        let args = CommandLine.arguments
        if let index = args.firstIndex(of: "-STORAGE_MODE"),
           index + 1 < args.count {
            let argMode = args[index + 1]
            logger.debug("Storage mode override from launch argument: \(argMode)")
            return parseStorageMode(argMode)
        }

        // Method 3: UserDefaults test override (fallback for all platforms)
        if let defaultsMode = UserDefaults.standard.string(forKey: "TestMode_StorageMode") {
            logger.debug("Storage mode override from UserDefaults: \(defaultsMode)")
            return parseStorageMode(defaultsMode)
        }

        return nil
    }

    /// Check if onboarding should be skipped (for tests)
    ///
    /// - Returns: `true` if onboarding should be bypassed
    static func shouldSkipOnboarding() -> Bool {
        // Environment variable
        if ProcessInfo.processInfo.environment["SKIP_ONBOARDING"] != nil {
            return true
        }

        // Launch argument
        if CommandLine.arguments.contains("-SKIP_ONBOARDING") {
            return true
        }

        // UserDefaults
        if UserDefaults.standard.bool(forKey: "TestMode_SkipOnboarding") {
            return true
        }

        return false
    }

    // MARK: - Private Helpers

    /// Parse a string into a StorageMode
    ///
    /// - Parameter string: String representation of storage mode
    /// - Returns: StorageMode, or `nil` if string is invalid
    private static func parseStorageMode(_ string: String) -> StorageMode? {
        switch string.lowercased() {
        case "inmemory", "memory":
            return .inMemory

        case "local":
            return .local

        case "cloudkit", "cloud":
            return .cloudKit("iCloud.CumberlandCloud")

        default:
            logger.warning("Unknown storage mode string: \(string)")
            return nil
        }
    }
}
