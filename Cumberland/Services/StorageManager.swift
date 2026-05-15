//
//  StorageManager.swift
//  Cumberland
//
//  Created by Claude Code on 2026-05-14.
//  Utility for inspecting SwiftData storage locations and file information.
//
//  Provides diagnostic tools for examining SwiftData store files,
//  calculating storage sizes, and opening storage locations in Finder.
//

import Foundation
#if os(macOS)
import AppKit
#endif

/// Information about a SwiftData storage file
struct StorageFileInfo {
    let filename: String
    let size: Int64
    let formattedSize: String
}

/// Utility class for storage diagnostics and inspection
enum StorageManager {

    /// Scan the Application Support directory for SwiftData store files
    /// - Returns: Array of storage file information, or empty array if none found
    static func scanStorageLocations() -> [StorageFileInfo] {
        var fileInfos: [StorageFileInfo] = []

        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return []
        }

        let fm = FileManager.default

        // Look for .store files
        if let enumerator = fm.enumerator(at: appSupport, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                let filename = fileURL.lastPathComponent

                if filename.hasSuffix(".store") ||
                   filename.hasSuffix(".store-wal") ||
                   filename.hasSuffix(".store-shm") {

                    // Get file size
                    if let attrs = try? fm.attributesOfItem(atPath: fileURL.path),
                       let size = attrs[.size] as? Int64 {
                        let formatter = ByteCountFormatter()
                        formatter.countStyle = .file
                        let sizeStr = formatter.string(fromByteCount: size)
                        fileInfos.append(StorageFileInfo(
                            filename: filename,
                            size: size,
                            formattedSize: sizeStr
                        ))
                    } else {
                        fileInfos.append(StorageFileInfo(
                            filename: filename,
                            size: 0,
                            formattedSize: "Unknown"
                        ))
                    }
                }
            }
        }

        return fileInfos
    }

    /// Open the Application Support directory in Finder (macOS only)
    static func openStorageLocationInFinder() {
        #if os(macOS)
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: appSupport.path)
        }
        #endif
    }

    /// Get the Application Support directory URL
    /// - Returns: URL to Application Support directory, or nil if not found
    static func getStorageLocationURL() -> URL? {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }
}
