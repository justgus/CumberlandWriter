//
//  ImageStore.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/1/25.
//

import Foundation
import UniformTypeIdentifiers

enum ImageStoreError: Error {
    case couldNotResolveAppSupportDirectory
    case invalidFileExtension
}

final class ImageStore {
    static let shared = ImageStore()
    private init() {}

    private let imagesSubdirectory = "OriginalImages"

    // Resolve and create (if needed) the base directory where we store images.
    private func baseDirectoryURL() throws -> URL {
        let fm = FileManager.default

        // Application Support/<bundle id>/
        guard var appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw ImageStoreError.couldNotResolveAppSupportDirectory
        }

        // Put files under a bundle-unique container
        let bundleID = Bundle.main.bundleIdentifier ?? "App"
        appSupport.appendPathComponent(bundleID, isDirectory: true)

        // Ensure base path exists
        try fm.createDirectory(at: appSupport, withIntermediateDirectories: true, attributes: nil)

        // Exclude from backups
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? appSupport.setResourceValues(resourceValues)

        // Append images subdirectory
        let imagesDir = appSupport.appendingPathComponent(imagesSubdirectory, isDirectory: true)
        try fm.createDirectory(at: imagesDir, withIntermediateDirectories: true, attributes: nil)

        // Apply platform-appropriate protection to directory if available
        applyFileProtectionIfAvailable(at: imagesDir)

        return imagesDir
    }

    // Check if a URL is inside our managed store directory
    func isURLInsideStore(_ url: URL) -> Bool {
        guard let base = try? baseDirectoryURL() else { return false }
        return url.standardizedFileURL.path.hasPrefix(base.standardizedFileURL.path)
    }

    // Construct a file URL for a given id and extension (without writing).
    func fileURL(for id: UUID, fileExtension ext: String) throws -> URL {
        let sanitizedExt = sanitizeExtension(ext)
        let dir = try baseDirectoryURL()
        let filename = "\(id.uuidString).\(sanitizedExt)"
        return dir.appendingPathComponent(filename, isDirectory: false)
    }

    // Write original image data and return its file URL.
    // The file name is <UUID>.<ext>, where ext is lowercased and sanitized.
    func writeOriginalImageData(_ data: Data, for id: UUID, fileExtension ext: String) throws -> URL {
        let sanitizedExt = sanitizeExtension(ext)

        let fileURL = try fileURL(for: id, fileExtension: sanitizedExt)

        // Write atomically to avoid partial files
        try data.write(to: fileURL, options: [.atomic])

        // Apply protection to the file if supported
        applyFileProtectionIfAvailable(at: fileURL)

        return fileURL
    }

    // Delete a previously stored image at a given URL (ignores if it doesn't exist).
    func deleteOriginalImage(at url: URL) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
    }

    // Return all URLs of originals currently on disk.
    func listAllOriginalImageURLs() -> [URL] {
        guard let dir = try? baseDirectoryURL() else { return [] }
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        return contents.filter { url in
            (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
        }
    }

    // Attempt to derive a UUID from a managed original image URL (expects "<uuid>.<ext>").
    func originalID(from url: URL) -> UUID? {
        let basename = url.deletingPathExtension().lastPathComponent
        return UUID(uuidString: basename)
    }

    // Remove files whose UUIDs are not present in the provided set; returns deleted URLs.
    func pruneOrphanOriginals(existingIDs: Set<UUID>) -> [URL] {
        let fm = FileManager.default
        var deleted: [URL] = []
        for url in listAllOriginalImageURLs() {
            guard let id = originalID(from: url) else { continue }
            if !existingIDs.contains(id) {
                do {
                    try fm.removeItem(at: url)
                    deleted.append(url)
                } catch {
                    // Best-effort; keep going
                }
            }
        }
        return deleted
    }

    // MARK: - Helpers

    private func sanitizeExtension(_ ext: String) -> String {
        let sanitizedExt = ext.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard sanitizedExt.range(of: #"^[a-z0-9]+$"#, options: .regularExpression) != nil else {
            // Fall back to jpg if invalid
            return "jpg"
        }
        return sanitizedExt
    }

    // Apply an appropriate file protection attribute on iPadOS/iOS; no-op on macOS.
    private func applyFileProtectionIfAvailable(at url: URL) {
#if os(iOS)
        // Choose a conservative default; adjust if your UX requires access while locked.
        let attributes: [FileAttributeKey: Any] = [.protectionKey: FileProtectionType.completeUnlessOpen]
        try? FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
#endif
    }
}
