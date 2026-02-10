//
//  ImageVersion.swift
//  Cumberland
//
//  Created by Claude Code on 2/2/26.
//  ER-0017 Phase 2: Image History Management
//
//  SwiftData model representing a historical version of a card's AI-generated
//  image. Stores image data (external storage), generation prompt, provider
//  name, timestamp, and whether it is the current active version. Managed
//  by ImageVersionManager.
//

import Foundation
import SwiftData
import SwiftUI

/// Represents a previous version of a card's generated image
/// Stores historical versions for comparison, restoration, and undo functionality
@Model
final class ImageVersion: Identifiable {

    // MARK: - Properties

    /// Unique identifier
    var id: UUID = UUID()

    /// The card this version belongs to
    var card: Card?

    /// The image data (stored externally for efficient syncing)
    @Attribute(.externalStorage)
    var imageData: Data?

    /// When this version was generated
    var generatedAt: Date = Date()

    /// The prompt used to generate this image
    var prompt: String = ""

    /// The AI provider used (e.g., "Apple Intelligence", "OpenAI")
    var provider: String = ""

    /// AI model version or identifier
    var modelVersion: String?

    /// Sequential version number (1 = oldest, higher = newer)
    /// Used for FIFO cleanup when history limit is exceeded
    var versionNumber: Int = 0

    /// User-provided notes about this version (optional)
    var notes: String?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        card: Card,
        imageData: Data,
        generatedAt: Date = Date(),
        prompt: String,
        provider: String,
        modelVersion: String? = nil,
        versionNumber: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.card = card
        self.imageData = imageData
        self.generatedAt = generatedAt
        self.prompt = prompt
        self.provider = provider
        self.modelVersion = modelVersion
        self.versionNumber = versionNumber
        self.notes = notes
    }

    // MARK: - Computed Properties

    /// File size of the image data (formatted string)
    var fileSizeString: String {
        guard let data = imageData else { return "0 KB" }
        let bytes = Double(data.count)

        if bytes < 1024 {
            return "\(Int(bytes)) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", bytes / 1024)
        } else {
            return String(format: "%.1f MB", bytes / (1024 * 1024))
        }
    }

    /// Formatted generation date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: generatedAt)
    }

    /// Short prompt preview (first 50 characters)
    var promptPreview: String {
        if prompt.count <= 50 {
            return prompt
        }
        return String(prompt.prefix(50)) + "…"
    }
}

// MARK: - SwiftUI Image Helper

extension ImageVersion {
    /// Convert image data to SwiftUI Image
    func makeImage() -> Image? {
        guard let data = imageData else { return nil }

        #if os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #else
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #endif
    }

    /// Async version that doesn't block main thread
    @MainActor
    func makeImageAsync() async -> Image? {
        return await Task.detached {
            self.makeImage()
        }.value
    }
}

// MARK: - Comparable for Sorting

extension ImageVersion: Comparable {
    static func < (lhs: ImageVersion, rhs: ImageVersion) -> Bool {
        // Sort by version number (newer versions have higher numbers)
        return lhs.versionNumber < rhs.versionNumber
    }

    static func == (lhs: ImageVersion, rhs: ImageVersion) -> Bool {
        return lhs.id == rhs.id
    }
}
