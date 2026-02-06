//
//  ImageVersionManager.swift
//  Cumberland
//
//  Created by Claude Code on 2/2/26.
//  ER-0017 Phase 2: Image Version History Management
//

import Foundation
import SwiftData
import OSLog

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Manages image version history for cards
/// Handles saving previous versions, cleanup, and restoration
final class ImageVersionManager {

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "ImageVersionManager")

    // MARK: - Singleton

    static let shared = ImageVersionManager()

    private init() {}

    // MARK: - Version History Management

    /// Save the current image as a version before regenerating
    /// - Parameters:
    ///   - card: The card to save version for
    ///   - context: The model context
    /// - Returns: The created ImageVersion, or nil if no current image
    @discardableResult
    func saveCurrentAsVersion(for card: Card, in context: ModelContext) -> ImageVersion? {
        guard let currentImageData = card.originalImageData else {
            logger.debug("No current image to save as version for card '\(card.name)'")
            return nil
        }

        // Get current version number
        let existingVersions = (card.imageVersions ?? []).sorted()
        let nextVersionNumber = (existingVersions.last?.versionNumber ?? 0) + 1

        // Create new version
        let version = ImageVersion(
            card: card,
            imageData: currentImageData,
            generatedAt: card.imageAIGeneratedAt ?? Date(),
            prompt: card.imageAIPrompt ?? "",
            provider: card.imageAIProvider ?? "Unknown",
            versionNumber: nextVersionNumber
        )

        // Add to card's versions
        if card.imageVersions == nil {
            card.imageVersions = []
        }
        card.imageVersions?.append(version)

        // Insert into context
        context.insert(version)

        logger.info("Saved current image as version \(nextVersionNumber) for card '\(card.name)'")

        // Enforce history limit
        enforceHistoryLimit(for: card, in: context)

        return version
    }

    /// Enforce the history limit by removing oldest versions
    /// - Parameters:
    ///   - card: The card to enforce limit for
    ///   - context: The model context
    func enforceHistoryLimit(for card: Card, in context: ModelContext) {
        let limit = AISettings.shared.imageHistoryLimit
        guard limit > 0 else { return } // No limit

        guard let versions = card.imageVersions, versions.count > limit else {
            return // Under limit
        }

        // Sort by version number and remove oldest
        let sorted = versions.sorted()
        let toRemove = sorted.prefix(versions.count - limit)

        for version in toRemove {
            card.imageVersions?.removeAll { $0.id == version.id }
            context.delete(version)
            logger.debug("Deleted version \(version.versionNumber) for card '\(card.name)' (enforcing limit of \(limit))")
        }

        logger.info("Enforced history limit for card '\(card.name)': removed \(toRemove.count) old versions")
    }

    /// Restore a specific version as the current image
    /// - Parameters:
    ///   - version: The version to restore
    ///   - card: The card to restore to
    ///   - context: The model context
    func restoreVersion(_ version: ImageVersion, for card: Card, in context: ModelContext) {
        guard let imageData = version.imageData else {
            logger.error("Cannot restore version: no image data")
            return
        }

        // Save current image as a version first (to preserve it)
        saveCurrentAsVersion(for: card, in: context)

        // Restore the version using setOriginalImageData to properly update imageFileURL
        // This ensures views watching imageFileURL will refresh
        do {
            try card.setOriginalImageData(imageData)
        } catch {
            logger.error("Failed to set image data: \(error.localizedDescription)")
            return
        }

        // Update AI metadata
        card.imageAIProvider = version.provider
        card.imageAIPrompt = version.prompt
        card.imageAIGeneratedAt = version.generatedAt
        card.imageGeneratedByAI = true

        logger.info("Restored version \(version.versionNumber) for card '\(card.name)'")
    }

    /// Delete a specific version
    /// - Parameters:
    ///   - version: The version to delete
    ///   - card: The card the version belongs to
    ///   - context: The model context
    func deleteVersion(_ version: ImageVersion, for card: Card, in context: ModelContext) {
        card.imageVersions?.removeAll { $0.id == version.id }
        context.delete(version)
        logger.info("Deleted version \(version.versionNumber) for card '\(card.name)'")
    }

    /// Clear all version history for a card
    /// - Parameters:
    ///   - card: The card to clear history for
    ///   - context: The model context
    func clearAllVersions(for card: Card, in context: ModelContext) {
        guard let versions = card.imageVersions, !versions.isEmpty else { return }

        let count = versions.count
        for version in versions {
            context.delete(version)
        }
        card.imageVersions = []

        logger.info("Cleared \(count) versions for card '\(card.name)'")
    }

    // MARK: - Statistics

    /// Get version history statistics for a card
    /// - Parameter card: The card to get statistics for
    /// - Returns: Statistics about the card's version history
    func getStatistics(for card: Card) -> VersionStatistics {
        let versions = card.imageVersions ?? []
        let totalSize = versions.compactMap { $0.imageData?.count }.reduce(0, +)

        return VersionStatistics(
            versionCount: versions.count,
            oldestVersion: versions.sorted().first,
            newestVersion: versions.sorted().last,
            totalSize: totalSize
        )
    }

    struct VersionStatistics {
        let versionCount: Int
        let oldestVersion: ImageVersion?
        let newestVersion: ImageVersion?
        let totalSize: Int

        var totalSizeFormatted: String {
            let bytes = Double(totalSize)
            if bytes < 1024 {
                return "\(Int(bytes)) B"
            } else if bytes < 1024 * 1024 {
                return String(format: "%.1f KB", bytes / 1024)
            } else {
                return String(format: "%.1f MB", bytes / (1024 * 1024))
            }
        }
    }

    // MARK: - Thumbnail Generation

    /// Generate thumbnail using ImageProcessingService (ER-0022 Phase 1)
    private func generateThumbnail(from imageData: Data) -> Data? {
        return ImageProcessingService.shared.generateThumbnail(from: imageData)
    }
}

// MARK: - Convenience Extensions

extension Card {
    /// Save current image as a version (convenience method)
    @discardableResult
    func saveCurrentImageAsVersion(in context: ModelContext) -> ImageVersion? {
        return ImageVersionManager.shared.saveCurrentAsVersion(for: self, in: context)
    }

    /// Get version history statistics
    var versionStatistics: ImageVersionManager.VersionStatistics {
        return ImageVersionManager.shared.getStatistics(for: self)
    }

    /// Check if card has version history
    var hasVersionHistory: Bool {
        return !(imageVersions ?? []).isEmpty
    }

    /// Get sorted versions (newest first)
    var sortedVersions: [ImageVersion] {
        return (imageVersions ?? []).sorted().reversed()
    }
}
