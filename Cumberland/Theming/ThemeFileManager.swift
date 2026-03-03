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

/// Manages user-defined theme files on disk.
///
/// User themes are stored as `.cumberlandtheme` (JSON) files in:
/// `~/Library/Application Support/Cumberland/Themes/`
@MainActor
final class ThemeFileManager {

    /// Shared singleton instance.
    static let shared = ThemeFileManager()

    /// Directory where user themes are persisted.
    private let themesDirectory: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        themesDirectory = appSupport.appendingPathComponent("Cumberland/Themes", isDirectory: true)

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: themesDirectory, withIntermediateDirectories: true)
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
    /// Copies the file into the app's themes directory and returns the decoded theme.
    func importTheme(from sourceURL: URL) throws -> UserTheme {
        let data: Data
        if sourceURL.startAccessingSecurityScopedResource() {
            defer { sourceURL.stopAccessingSecurityScopedResource() }
            data = try Data(contentsOf: sourceURL)
        } else {
            data = try Data(contentsOf: sourceURL)
        }

        // Validate by decoding
        let theme = try UserTheme.decode(from: data)

        // Write to themes directory
        let destURL = themesDirectory.appendingPathComponent("\(theme.id).cumberlandtheme")
        try data.write(to: destURL, options: .atomic)

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
}
