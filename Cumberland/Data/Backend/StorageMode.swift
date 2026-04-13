//
//  StorageMode.swift
//  Cumberland
//
//  Created by Claude on 2026-04-13.
//  ER-0058 Phase 1: Storage mode enumeration for modular backend architecture
//

import Foundation

/// Defines the available storage modes for the SwiftData ModelContainer
enum StorageMode: Equatable, Sendable {
    /// In-memory storage (ephemeral, used for tests and previews)
    /// - Data does not persist between app launches
    /// - Fastest performance
    /// - No CloudKit sync
    case inMemory

    /// Local disk storage without CloudKit sync
    /// - Data persists between app launches
    /// - Works offline
    /// - No cross-device sync
    case local

    /// CloudKit-backed storage with automatic sync
    /// - Data persists and syncs across devices
    /// - Requires iCloud account
    /// - Automatic conflict resolution
    /// - Parameter: CloudKit container identifier (e.g., "iCloud.CumberlandCloud")
    case cloudKit(String)

    /// User-facing display name for this storage mode
    var displayName: String {
        switch self {
        case .inMemory:
            return "In-Memory (Testing)"
        case .local:
            return "Local Storage Only"
        case .cloudKit:
            return "iCloud Sync"
        }
    }

    /// Description of this storage mode for UI
    var description: String {
        switch self {
        case .inMemory:
            return "Temporary storage for testing. Data is not saved."
        case .local:
            return "Data stored on this device only. Works offline."
        case .cloudKit:
            return "Data syncs across all your devices via iCloud."
        }
    }

    /// Whether this mode supports cross-device sync
    var supportsSync: Bool {
        switch self {
        case .inMemory, .local:
            return false
        case .cloudKit:
            return true
        }
    }

    /// Whether this mode persists data between app launches
    var isPersistent: Bool {
        switch self {
        case .inMemory:
            return false
        case .local, .cloudKit:
            return true
        }
    }

    /// Raw string value for persistence in UserDefaults
    var rawValue: String {
        switch self {
        case .inMemory:
            return "inMemory"
        case .local:
            return "local"
        case .cloudKit:
            return "cloudKit"
        }
    }

    /// Parse a storage mode from a string (for UserDefaults retrieval)
    /// - Parameter string: The raw string value
    /// - Returns: StorageMode if valid, nil otherwise
    static func fromString(_ string: String) -> StorageMode? {
        switch string.lowercased() {
        case "inmemory", "memory":
            return .inMemory
        case "local":
            return .local
        case "cloudkit", "cloud":
            return .cloudKit("iCloud.CumberlandCloud")
        default:
            return nil
        }
    }
}
