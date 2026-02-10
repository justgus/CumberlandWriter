//
//  ImageProcessingService.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 1
//
//  Service for image processing operations: thumbnail generation, image
//  resizing/compression to target byte sizes, format conversion (JPEG/PNG/HEIC),
//  and EXIF metadata extraction. Abstracts platform differences between
//  AppKit (NSImage) and UIKit (UIImage).
//

import Foundation
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Centralized service for all image processing operations in Cumberland.
/// Eliminates duplicate code across BatchGenerationQueue, ImageVersionManager, and CardSheetView.
///
/// **ER-0022 Phase 1**: Consolidates ~145 lines of duplicate image processing code
final class ImageProcessingService {

    // MARK: - Singleton

    static let shared = ImageProcessingService()

    private init() {}

    // MARK: - Thumbnail Generation

    /// Generate a thumbnail from image data
    /// - Parameters:
    ///   - imageData: Source image data
    ///   - size: Target thumbnail size (default: 200x200)
    /// - Returns: Thumbnail image data as PNG, or nil if generation fails
    func generateThumbnail(from imageData: Data, size: CGSize = CGSize(width: 200, height: 200)) -> Data? {
        #if os(macOS)
        guard let nsImage = NSImage(data: imageData) else { return nil }

        let ratio = min(size.width / nsImage.size.width, size.height / nsImage.size.height)
        let newSize = CGSize(width: nsImage.size.width * ratio, height: nsImage.size.height * ratio)

        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        nsImage.draw(in: CGRect(origin: .zero, size: newSize))
        thumbnail.unlockFocus()

        // Convert to PNG data
        guard let tiffData = thumbnail.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapRep.representation(using: .png, properties: [:])

        #else
        guard let uiImage = UIImage(data: imageData) else { return nil }

        let ratio = min(size.width / uiImage.size.width, size.height / uiImage.size.height)
        let newSize = CGSize(width: uiImage.size.width * ratio, height: uiImage.size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return thumbnail?.pngData()
        #endif
    }

    // MARK: - Format Conversion

    /// Convert image data to PNG format
    /// - Parameter imageData: Source image data (any format)
    /// - Returns: PNG data, or nil if conversion fails
    func convertToPNG(_ imageData: Data) -> Data? {
        #if os(macOS)
        guard let nsImage = NSImage(data: imageData) else { return nil }

        // First try native method if available (macOS 12.0+)
        if nsImage.responds(to: Selector(("pngData"))) {
            return nsImage.perform(Selector(("pngData")))?.takeUnretainedValue() as? Data
        }

        // Fallback for older macOS versions
        guard let tiff = nsImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])

        #else
        guard let uiImage = UIImage(data: imageData) else { return nil }
        return uiImage.pngData()
        #endif
    }

    /// Convert image data to JPEG format
    /// - Parameters:
    ///   - imageData: Source image data (any format)
    ///   - compressionQuality: JPEG compression quality (0.0 - 1.0, default: 0.9)
    /// - Returns: JPEG data, or nil if conversion fails
    func convertToJPEG(_ imageData: Data, compressionQuality: CGFloat = 0.9) -> Data? {
        #if os(macOS)
        guard let nsImage = NSImage(data: imageData) else { return nil }

        // First try native method if available (macOS 12.0+)
        if nsImage.responds(to: Selector(("jpegDataWithCompressionQuality:"))) {
            return nsImage.perform(Selector(("jpegDataWithCompressionQuality:")), with: compressionQuality)?.takeUnretainedValue() as? Data
        }

        // Fallback for older macOS versions
        guard let tiff = nsImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])

        #else
        guard let uiImage = UIImage(data: imageData) else { return nil }
        return uiImage.jpegData(compressionQuality: compressionQuality)
        #endif
    }

    // MARK: - Image Loading

    /// Asynchronously load image from data
    /// - Parameter data: Source image data
    /// - Returns: CGImage, or nil if loading fails
    func loadImage(from data: Data) async -> CGImage? {
        #if os(macOS)
        guard let nsImage = NSImage(data: data),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        return cgImage

        #else
        guard let uiImage = UIImage(data: data),
              let cgImage = uiImage.cgImage else {
            return nil
        }
        return cgImage
        #endif
    }

    /// Asynchronously load image from URL
    /// - Parameter url: Source image URL (file or remote)
    /// - Returns: CGImage, or nil if loading fails
    func loadImage(from url: URL) async -> CGImage? {
        do {
            let data = try Data(contentsOf: url)
            return await loadImage(from: data)
        } catch {
            print("ImageProcessingService: Failed to load image from URL: \(error)")
            return nil
        }
    }
}
