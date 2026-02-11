//
//  ImageMetadataWriter.swift
//  Cumberland
//
//  Created by Claude Code on 1/22/26.
//  ER-0009: AI Image Generation - EXIF/IPTC Metadata Embedding
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Utility for embedding EXIF/IPTC metadata into AI-generated images
/// Part of ER-0009: AI Image Generation Attribution
struct ImageMetadataWriter {

    // MARK: - Public API

    /// Embed AI generation metadata into image data
    /// - Parameters:
    ///   - imageData: Original image data (PNG or JPEG)
    ///   - prompt: The AI prompt used to generate the image
    ///   - provider: The AI provider name
    ///   - generatedAt: When the image was generated
    ///   - copyright: Optional copyright text (defaults to Cumberland attribution)
    /// - Returns: Image data with embedded metadata, or original data if embedding fails
    static func embedAIMetadata(
        in imageData: Data,
        prompt: String,
        provider: String,
        generatedAt: Date,
        copyright: String? = nil
    ) -> Data {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let uniformTypeIdentifier = CGImageSourceGetType(source),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            print("⚠️ [ImageMetadataWriter] Failed to create image source")
            return imageData
        }

        // Create metadata dictionary
        let metadata = createMetadata(
            prompt: prompt,
            provider: provider,
            generatedAt: generatedAt,
            copyright: copyright
        )

        // Create destination with embedded metadata
        let destinationData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            destinationData,
            uniformTypeIdentifier,
            1,
            nil
        ) else {
            print("⚠️ [ImageMetadataWriter] Failed to create image destination")
            return imageData
        }

        // Add image with metadata
        CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)

        // Finalize
        guard CGImageDestinationFinalize(destination) else {
            print("⚠️ [ImageMetadataWriter] Failed to finalize image destination")
            return imageData
        }

        #if DEBUG
        print("✓ [ImageMetadataWriter] Successfully embedded AI metadata")
        #endif

        return destinationData as Data
    }

    // MARK: - Private Helpers

    /// Create EXIF/IPTC metadata dictionary for AI-generated images
    private static func createMetadata(
        prompt: String,
        provider: String,
        generatedAt: Date,
        copyright: String?
    ) -> [String: Any] {
        var metadata: [String: Any] = [:]

        // TIFF metadata (basic image info)
        var tiff: [String: Any] = [:]
        tiff[kCGImagePropertyTIFFArtist as String] = "Cumberland App + \(provider)"
        tiff[kCGImagePropertyTIFFSoftware as String] = "Cumberland \(appVersion())"
        tiff[kCGImagePropertyTIFFCopyright as String] = copyright ?? defaultCopyright(provider: provider)
        tiff[kCGImagePropertyTIFFDateTime as String] = formatDateForTIFF(generatedAt)
        metadata[kCGImagePropertyTIFFDictionary as String] = tiff

        // EXIF metadata (extended info)
        var exif: [String: Any] = [:]
        exif[kCGImagePropertyExifDateTimeOriginal as String] = formatDateForEXIF(generatedAt)
        exif[kCGImagePropertyExifDateTimeDigitized as String] = formatDateForEXIF(generatedAt)
        exif[kCGImagePropertyExifUserComment as String] = createUserComment(prompt: prompt, provider: provider)
        metadata[kCGImagePropertyExifDictionary as String] = exif

        // IPTC metadata (publishing info)
        var iptc: [String: Any] = [:]
        iptc[kCGImagePropertyIPTCSource as String] = "\(provider) Image Generation"
        iptc[kCGImagePropertyIPTCCaptionAbstract as String] = "AI-generated image. Prompt: \(prompt)"
        iptc[kCGImagePropertyIPTCKeywords as String] = ["AI-generated", provider, "Cumberland"]
        iptc[kCGImagePropertyIPTCCopyrightNotice as String] = copyright ?? defaultCopyright(provider: provider)
        iptc[kCGImagePropertyIPTCDateCreated as String] = formatDateForIPTC(generatedAt)
        iptc[kCGImagePropertyIPTCTimeCreated as String] = formatTimeForIPTC(generatedAt)
        metadata[kCGImagePropertyIPTCDictionary as String] = iptc

        // PNG metadata (if PNG format)
        var png: [String: Any] = [:]
        png[kCGImagePropertyPNGAuthor as String] = "Cumberland App + \(provider)"
        png[kCGImagePropertyPNGDescription as String] = "AI-generated image using \(provider). Prompt: \(prompt)"
        png[kCGImagePropertyPNGCopyright as String] = copyright ?? defaultCopyright(provider: provider)
        png[kCGImagePropertyPNGCreationTime as String] = formatDateForPNG(generatedAt)
        png[kCGImagePropertyPNGSoftware as String] = "Cumberland \(appVersion())"
        metadata[kCGImagePropertyPNGDictionary as String] = png

        return metadata
    }

    /// Get app version string
    private static func appVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0"
    }

    /// Default copyright text (Phase 4A: Use copyright template from settings)
    private static func defaultCopyright(provider: String) -> String {
        let settings = AISettings.shared
        let template = settings.copyrightTemplate

        // Replace placeholders
        var copyright = template
        let currentYear = Calendar.current.component(.year, from: Date())
        copyright = copyright.replacingOccurrences(of: "{YEAR}", with: String(currentYear))
        copyright = copyright.replacingOccurrences(of: "{USER}", with: NSFullUserName())
        copyright = copyright.replacingOccurrences(of: "{PROVIDER}", with: provider)
        // Note: {CARD} placeholder can't be replaced here (would need card name parameter)

        return copyright
    }

    /// Format date for TIFF (YYYY:MM:DD HH:MM:SS)
    private static func formatDateForTIFF(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    /// Format date for EXIF (YYYY:MM:DD HH:MM:SS)
    private static func formatDateForEXIF(_ date: Date) -> String {
        formatDateForTIFF(date) // Same format
    }

    /// Format date for IPTC (YYYYMMDD)
    private static func formatDateForIPTC(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    /// Format time for IPTC (HHMMSS±HHMM)
    private static func formatTimeForIPTC(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmmssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    /// Format date for PNG (ISO 8601)
    private static func formatDateForPNG(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }

    /// Create detailed user comment with generation details
    private static func createUserComment(prompt: String, provider: String) -> String {
        """
        AI-Generated Image
        Provider: \(provider)
        Prompt: \(prompt)
        Software: Cumberland \(appVersion())
        """
    }
}

// MARK: - Extensions

extension ImageMetadataWriter {

    /// Convenience method to embed metadata directly from Card properties
    /// - Parameters:
    ///   - imageData: Original image data
    ///   - prompt: Generation prompt
    ///   - provider: AI provider name
    ///   - generatedAt: Generation timestamp
    ///   - userCopyright: Optional user-provided copyright text
    /// - Returns: Image data with embedded metadata
    static func embedMetadataForCard(
        imageData: Data,
        prompt: String,
        provider: String,
        generatedAt: Date,
        userCopyright: String? = nil
    ) -> Data {
        return embedAIMetadata(
            in: imageData,
            prompt: prompt,
            provider: provider,
            generatedAt: generatedAt,
            copyright: userCopyright
        )
    }
}
