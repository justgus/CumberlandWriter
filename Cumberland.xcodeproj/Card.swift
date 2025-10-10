//
//  Card.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/1/25.
//

import Foundation
import SwiftData
import SwiftUI
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

@Model
final class Card: Identifiable {
    // Stable identifier for selection and hashing
    @Attribute(.unique)
    var id: UUID

    // Core fields
    var name: String

    // Subtitle text shown in list/secondary UI.
    var subtitle: String

    // Backward-compatibility shim for existing call sites.
    // Migrate call sites to `subtitle` and remove this when convenient.
    @available(*, deprecated, renamed: "subtitle")
    var shortDescription: String {
        get { subtitle }
        set { subtitle = newValue }
    }

    var detailedText: String

    // Additional metadata used by UI
    var sizeCategory: SizeCategory

    // Persisted binary image data (PNG/JPEG/etc.)
    // Store large blobs out-of-line to keep the main store lean.
    @Attribute(.externalStorage)
    var imageData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String,
        detailedText: String,
        sizeCategory: SizeCategory = .standard,
        imageData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.detailedText = detailedText
        self.sizeCategory = sizeCategory
        self.imageData = imageData
    }
}

extension Card {
    // MARK: - Universal SwiftUI Images derived from imageData

    // Full-resolution image decoded from imageData (avoid ImageIO caching)
    var image: Image? {
        guard let data = imageData,
              let cg = CardImageDecoding.cgImage(from: data) else { return nil }
        return Image(decorative: cg, scale: 1, orientation: .up)
    }

    // Downsampled thumbnail for list usage
    var thumbnailImage: Image? {
        guard let data = imageData,
              let cg = CardImageDecoding.cgThumbnail(from: data, maxPixelSize: 64) else { return nil }
        return Image(decorative: cg, scale: 1, orientation: .up)
    }

    // Produce a downsampled image for a target display size in points.
    // Provide scale to match the display scale (e.g., from UIScreen/NSScreen).
    func imageForDisplay(targetSizeInPoints: CGSize, scale: CGFloat = 1) -> Image? {
        guard let data = imageData else { return nil }
        let maxPixel = CardImageDecoding.maxPixelSizeForDisplay(targetSizeInPoints: targetSizeInPoints, scale: scale)
        guard let cg = CardImageDecoding.cgThumbnail(from: data, maxPixelSize: maxPixel) else { return nil }
        return Image(decorative: cg, scale: 1, orientation: .up)
    }

    // MARK: - Mutators

    // Directly set persisted bytes (e.g., from a file import)
    func setImageData(_ data: Data?) {
        imageData = data
    }
}

// MARK: - Image decoding helpers (internal for testing)

/// Centralized, testable image decoding and downsampling utilities for Card imageData.
struct CardImageDecoding {
    /// Create a CGImage without populating ImageIO's cache.
    static func cgImage(from data: Data) -> CGImage? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        // Avoid caching decoded pixels in ImageIO to reduce peak memory.
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceShouldCacheImmediately: false
        ]
        return CGImageSourceCreateImageAtIndex(src, 0, options as CFDictionary)
    }

    /// Create a downsampled CGImage bounded by maxPixelSize.
    /// This uses ImageIO thumbnailing which is significantly more memory efficient.
    static func cgThumbnail(from data: Data, maxPixelSize: Int) -> CGImage? {
        guard maxPixelSize > 0 else { return nil }
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCache: false,
            kCGImageSourceShouldCacheImmediately: false
        ]
        return CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary)
    }

    /// Compute a reasonable max pixel size for a given display target size in points and scale.
    static func maxPixelSizeForDisplay(targetSizeInPoints: CGSize, scale: CGFloat) -> Int {
        let widthPx = max(1, Int(targetSizeInPoints.width * scale))
        let heightPx = max(1, Int(targetSizeInPoints.height * scale))
        // Bound by the larger dimension to preserve aspect ratio.
        return max(widthPx, heightPx)
    }

    /// Optionally detect the UTType of the image data (useful for decisions/logging).
    static func imageType(of data: Data) -> UTType? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let uti = CGImageSourceGetType(src) as String? else { return nil }
        return UTType(uti)
    }
}

// MARK: - SizeCategory

enum SizeCategory: Int, Codable, CaseIterable, Hashable, Sendable {
    case compact
    case standard
    case large

    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .standard: return "Standard"
        case .large: return "Large"
        }
    }
}
