//
//  ThemeFileManager.swift
//  Cumberland
//
//  ER-0037 Phase 2, Step 5: User-Defined Theme Support
//
//  Manages persistence of user-defined themes in the app's Application
//  Support directory. Handles import from `.cumberlandtheme` files,
//  export of current themes, and deletion of user themes.
//

import Foundation
import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Manages user-defined theme files on disk.
///
/// User themes are stored as `.cumberlandtheme` (JSON) files in:
/// `~/Library/Application Support/Cumberland/Themes/`
///
/// Background images bundled as base64 in the JSON are decoded at import
/// time and cached to `~/Library/Application Support/Cumberland/ThemeImages/`.
@MainActor
final class ThemeFileManager {

    /// Shared singleton instance.
    static let shared = ThemeFileManager()

    /// Directory where user themes are persisted.
    private let themesDirectory: URL

    /// Directory where decoded background images are cached.
    private let imagesDirectory: URL

    /// Maximum allowed size for a single base64-decoded image (2 MB).
    static let maxImageBytes = 2 * 1024 * 1024

    /// Maximum allowed dimension for a decoded image (4096 px).
    static let maxImageDimension = 4096

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        themesDirectory = appSupport.appendingPathComponent("Cumberland/Themes", isDirectory: true)
        imagesDirectory = appSupport.appendingPathComponent("Cumberland/ThemeImages", isDirectory: true)

        // Ensure directories exist
        try? FileManager.default.createDirectory(at: themesDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Load All

    /// Load all user themes from disk.
    func loadUserThemes() -> [UserTheme] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: themesDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        return files
            .filter { $0.pathExtension == "cumberlandtheme" }
            .compactMap { url -> UserTheme? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? UserTheme.decode(from: data)
            }
    }

    // MARK: - Import

    /// Import a `.cumberlandtheme` file from the given URL.
    /// Decodes base64 background images (if any), validates them, caches
    /// them to disk, and stores the theme JSON in the themes directory.
    func importTheme(from sourceURL: URL) throws -> UserTheme {
        let rawData: Data
        if sourceURL.startAccessingSecurityScopedResource() {
            defer { sourceURL.stopAccessingSecurityScopedResource() }
            rawData = try Data(contentsOf: sourceURL)
        } else {
            rawData = try Data(contentsOf: sourceURL)
        }

        // First pass: decode the raw JSON to extract base64 image data
        let decoder = JSONDecoder()
        var json = try decoder.decode(ThemeJSON.self, from: rawData)

        // Process base64 background images if present
        if var bgImages = json.backgroundImages {
            let slots: [(dataKey: WritableKeyPath<BackgroundImagesJSON, String?>,
                          nameKey: WritableKeyPath<BackgroundImagesJSON, String?>,
                          suffix: String)] = [
                (\.sidebarBackgroundData, \.sidebarBackground, "sidebar"),
                (\.contentBackgroundData, \.contentBackground, "content"),
                (\.murderboardCanvasData, \.murderboardCanvas, "murderboard"),
                (\.structureBoardCanvasData, \.structureBoardCanvas, "structureboard"),
                (\.wizardHeroData, \.wizardHero, "wizard"),
                (\.emptyStateData, \.emptyState, "empty"),
                (\.detailPlaceholderData, \.detailPlaceholder, "detail"),
            ]

            for slot in slots {
                if let base64String = bgImages[keyPath: slot.dataKey],
                   !base64String.isEmpty {
                    let imageData = try decodeAndValidateImage(base64String)
                    let imageName = "\(json.id)-\(slot.suffix)"
                    try cacheImage(imageData, named: imageName)
                    bgImages[keyPath: slot.nameKey] = imageName
                    bgImages[keyPath: slot.dataKey] = nil // Strip data from stored JSON
                }
            }
            json = ThemeJSON(
                id: json.id,
                displayName: json.displayName,
                colors: json.colors,
                fonts: json.fonts,
                shapes: json.shapes,
                shadows: json.shadows,
                spacing: json.spacing,
                backgroundImages: bgImages
            )
        }

        // Re-encode the cleaned JSON (no base64 data) for storage
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let cleanData = try encoder.encode(json)

        // Decode into UserTheme
        let theme = try UserTheme.decode(from: cleanData)

        // Write cleaned JSON to themes directory
        let destURL = themesDirectory.appendingPathComponent("\(theme.id).cumberlandtheme")
        try cleanData.write(to: destURL, options: .atomic)

        return theme
    }

    // MARK: - Export

    /// Export a theme as JSON data suitable for writing to a `.cumberlandtheme` file.
    func exportThemeData(from theme: any Theme) throws -> Data {
        try UserTheme.exportJSON(from: theme)
    }

    // MARK: - Delete

    /// Delete a user theme from disk by ID.
    func deleteTheme(id: String) throws {
        let fileURL = themesDirectory.appendingPathComponent("\(id).cumberlandtheme")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    /// Check if a theme ID corresponds to a user theme on disk.
    func isUserTheme(id: String) -> Bool {
        let fileURL = themesDirectory.appendingPathComponent("\(id).cumberlandtheme")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    // MARK: - Duplicate

    /// Duplicate a theme by exporting it to JSON and re-importing with a new ID.
    func duplicateTheme(_ theme: any Theme, newID: String, newDisplayName: String) throws -> UserTheme {
        let exportData = try UserTheme.exportJSON(from: theme)

        // Patch the JSON with the new id and displayName
        var json = try JSONDecoder().decode(ThemeJSON.self, from: exportData)
        json = ThemeJSON(
            id: newID,
            displayName: newDisplayName,
            colors: json.colors,
            fonts: json.fonts,
            shapes: json.shapes,
            shadows: json.shadows,
            spacing: json.spacing,
            backgroundImages: json.backgroundImages
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(json)

        let theme = try UserTheme.decode(from: data)
        let destURL = themesDirectory.appendingPathComponent("\(newID).cumberlandtheme")
        try data.write(to: destURL, options: .atomic)

        return theme
    }

    // MARK: - Image Cache

    /// Decode a base64 string to PNG data and validate size constraints.
    private func decodeAndValidateImage(_ base64String: String) throws -> Data {
        guard let imageData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
            throw ThemeImportError.invalidBase64
        }

        // Size check
        if imageData.count > Self.maxImageBytes {
            throw ThemeImportError.imageTooLarge(imageData.count)
        }

        // Dimension check
        #if canImport(AppKit)
        guard let image = NSImage(data: imageData),
              let rep = image.representations.first else {
            throw ThemeImportError.invalidImageData
        }
        if rep.pixelsWide > Self.maxImageDimension || rep.pixelsHigh > Self.maxImageDimension {
            throw ThemeImportError.imageDimensionsTooLarge(rep.pixelsWide, rep.pixelsHigh)
        }
        #elseif canImport(UIKit)
        guard let image = UIImage(data: imageData) else {
            throw ThemeImportError.invalidImageData
        }
        let w = Int(image.size.width * image.scale)
        let h = Int(image.size.height * image.scale)
        if w > Self.maxImageDimension || h > Self.maxImageDimension {
            throw ThemeImportError.imageDimensionsTooLarge(w, h)
        }
        #endif

        return imageData
    }

    /// Cache a decoded image to the ThemeImages directory.
    private func cacheImage(_ data: Data, named name: String) throws {
        let fileURL = imagesDirectory.appendingPathComponent("\(name).png")
        try data.write(to: fileURL, options: .atomic)
    }

    /// Remove cached images for a theme by ID prefix.
    func removeCachedImages(forThemeID id: String) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil) else { return }
        for file in files where file.lastPathComponent.hasPrefix(id) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    /// Get the file URL for a cached theme image by name.
    func cachedImageURL(named name: String) -> URL? {
        let fileURL = imagesDirectory.appendingPathComponent("\(name).png")
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
}

// MARK: - Theme Import Errors

enum ThemeImportError: LocalizedError {
    case invalidBase64
    case invalidImageData
    case imageTooLarge(Int)
    case imageDimensionsTooLarge(Int, Int)

    var errorDescription: String? {
        switch self {
        case .invalidBase64:
            return "A background image contains invalid Base64 data."
        case .invalidImageData:
            return "A background image could not be decoded as a valid image."
        case .imageTooLarge(let bytes):
            let mb = Double(bytes) / (1024 * 1024)
            return String(format: "A background image is too large (%.1f MB). Maximum allowed is 2 MB.", mb)
        case .imageDimensionsTooLarge(let w, let h):
            return "A background image is too large (\(w)x\(h) px). Maximum allowed is 4096x4096 px."
        }
    }
}
