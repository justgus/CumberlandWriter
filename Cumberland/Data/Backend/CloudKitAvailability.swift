//
//  CloudKitAvailability.swift
//  Cumberland
//
//  Created by Claude on 2026-04-13.
//  ER-0058 Phase 1: iCloud account detection utility
//  ER-0058 Phase 4: Enhanced with ObservableObject for SwiftUI integration
//

import Foundation
import CloudKit
import OSLog
import Combine

/// Utility for detecting iCloud account availability
/// Used to determine whether CloudKit storage mode is available
///
/// **Phase 4 Addition**: Now an ObservableObject for real-time UI updates
@MainActor
final class CloudKitAvailability: ObservableObject {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "CloudKit")

    /// Current account status (for UI binding)
    @Published private(set) var accountStatus: CKAccountStatus = .couldNotDetermine

    /// Whether iCloud is currently available
    @Published private(set) var isCurrentlyAvailable: Bool = false

    /// Singleton instance for shared access
    static let shared = CloudKitAvailability()

    private init() {
        // Initialize by checking availability
        Task {
            await refresh()
        }
    }

    /// Refresh the availability status
    func refresh() async {
        let (status, available) = await Self.checkStatus()
        accountStatus = status
        isCurrentlyAvailable = available
    }

    // MARK: - Static Methods (Legacy API)

    /// Check account status and return both status and availability
    private static func checkStatus() async -> (CKAccountStatus, Bool) {
        do {
            let status = try await CKContainer.default().accountStatus()

            switch status {
            case .available:
                logger.info("iCloud account available")
                return (status, true)

            case .noAccount:
                logger.warning("No iCloud account signed in")
                return (status, false)

            case .restricted:
                logger.warning("iCloud account restricted (parental controls or enterprise policy)")
                return (status, false)

            case .couldNotDetermine:
                logger.error("Could not determine iCloud account status")
                return (status, false)

            case .temporarilyUnavailable:
                logger.warning("iCloud temporarily unavailable (network issue or service outage)")
                return (status, false)

            @unknown default:
                logger.error("Unknown iCloud account status: \(status.rawValue)")
                return (status, false)
            }
        } catch {
            logger.error("Failed to check iCloud status: \(error.localizedDescription)")
            return (.couldNotDetermine, false)
        }
    }

    /// Check if iCloud account is available and signed in
    ///
    /// - Returns: `true` if iCloud is available, `false` otherwise
    ///
    /// This checks the user's iCloud account status to determine if CloudKit sync
    /// can be enabled. If the user is not signed into iCloud, CloudKit mode will fail.
    static func isAvailable() async -> Bool {
        let (_, available) = await checkStatus()
        return available
    }

    /// Get detailed status message for UI display
    ///
    /// - Returns: A user-friendly status message
    static func statusMessage() async -> String {
        let available = await isAvailable()
        return available ? "iCloud Available" : "iCloud Not Available"
    }

    /// Get detailed status with reason for unavailability
    ///
    /// - Returns: A tuple with availability status and detailed reason
    static func detailedStatus() async -> (available: Bool, reason: String) {
        do {
            let status = try await CKContainer.default().accountStatus()

            switch status {
            case .available:
                return (true, "iCloud account is signed in and available")

            case .noAccount:
                return (false, "Not signed into iCloud. Sign in via System Settings to enable sync.")

            case .restricted:
                return (false, "iCloud access is restricted by parental controls or enterprise policy")

            case .couldNotDetermine:
                return (false, "Unable to determine iCloud status. Please try again later.")

            case .temporarilyUnavailable:
                return (false, "iCloud is temporarily unavailable. Check your network connection.")

            @unknown default:
                return (false, "Unknown iCloud status")
            }
        } catch {
            return (false, "Error checking iCloud: \(error.localizedDescription)")
        }
    }
}
