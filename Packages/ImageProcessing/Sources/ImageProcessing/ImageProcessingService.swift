//
//  ImageProcessingService.swift
//  ImageProcessing
//
//  Centralized service for all image processing operations.
//  Provides a unified API for thumbnail generation, format conversion,
//  and image loading across macOS, iOS, and visionOS.
//

import Foundation
import CoreGraphics

/// Centralized service for image processing operations.
///
/// Provides a unified API for:
/// - Thumbnail generation with aspect ratio preservation
/// - Format conversion between PNG and JPEG
/// - Async image loading from Data or URLs
///
/// Usage:
/// ```swift
/// import ImageProcessing
///
/// let thumbnail = ImageProcessingService.shared.generateThumbnail(from: imageData)
/// let pngData = ImageProcessingService.shared.convertToPNG(jpegData)
/// let cgImage = await ImageProcessingService.shared.loadImage(from: imageData)
/// ```
public final class ImageProcessingService: Sendable {

    // MARK: - Singleton

    public static let shared = ImageProcessingService()

    private let thumbnailGenerator = ThumbnailGenerator()
    private let imageConverter = ImageConverter()
    private let imageLoader = ImageLoader()

    private init() {}

    // MARK: - Thumbnail Generation

    /// Generate a thumbnail from image data, preserving aspect ratio.
    /// - Parameters:
    ///   - imageData: Source image data (PNG, JPEG, etc.)
    ///   - size: Maximum bounding size for the thumbnail (default: 200x200)
    /// - Returns: Thumbnail as PNG data, or nil if generation fails
    public func generateThumbnail(from imageData: Data, size: CGSize = CGSize(width: 200, height: 200)) -> Data? {
        thumbnailGenerator.generate(from: imageData, size: size)
    }

    // MARK: - Format Conversion

    /// Convert image data to PNG format.
    /// - Parameter imageData: Source image data (any supported format)
    /// - Returns: PNG data, or nil if conversion fails
    public func convertToPNG(_ imageData: Data) -> Data? {
        imageConverter.convertToPNG(imageData)
    }

    /// Convert image data to JPEG format.
    /// - Parameters:
    ///   - imageData: Source image data (any supported format)
    ///   - compressionQuality: JPEG compression quality (0.0 - 1.0, default: 0.9)
    /// - Returns: JPEG data, or nil if conversion fails
    public func convertToJPEG(_ imageData: Data, compressionQuality: CGFloat = 0.9) -> Data? {
        imageConverter.convertToJPEG(imageData, quality: compressionQuality)
    }

    // MARK: - Image Loading

    /// Asynchronously load a CGImage from data.
    /// - Parameter data: Source image data
    /// - Returns: CGImage, or nil if loading fails
    public func loadImage(from data: Data) async -> CGImage? {
        await imageLoader.loadCGImage(from: data)
    }

    /// Asynchronously load a CGImage from a file URL.
    /// - Parameter url: Source image URL (local file)
    /// - Returns: CGImage, or nil if loading fails
    public func loadImage(from url: URL) async -> CGImage? {
        await imageLoader.loadCGImage(from: url)
    }
}
