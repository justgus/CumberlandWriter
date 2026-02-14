//
//  ThumbnailGenerator.swift
//  ImageProcessing
//
//  Generates thumbnails from image data with aspect ratio preservation.
//  Supports macOS (AppKit) and iOS/visionOS (UIKit).
//

import Foundation
import CoreGraphics

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct ThumbnailGenerator: Sendable {

    public init() {}

    /// Generate a thumbnail from image data, preserving aspect ratio.
    /// - Parameters:
    ///   - imageData: Source image data (PNG, JPEG, etc.)
    ///   - size: Maximum bounding size for the thumbnail (default: 200x200)
    /// - Returns: Thumbnail as PNG data, or nil if generation fails
    public func generate(from imageData: Data, size: CGSize = CGSize(width: 200, height: 200)) -> Data? {
        #if os(macOS)
        guard let nsImage = NSImage(data: imageData) else { return nil }

        let ratio = min(size.width / nsImage.size.width, size.height / nsImage.size.height)
        let newSize = CGSize(width: nsImage.size.width * ratio, height: nsImage.size.height * ratio)

        let thumbnail = NSImage(size: newSize, flipped: false) { rect in
            nsImage.draw(in: rect)
            return true
        }

        guard let cgImage = thumbnail.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .png, properties: [:])

        #else
        guard let uiImage = UIImage(data: imageData) else { return nil }

        let ratio = min(size.width / uiImage.size.width, size.height / uiImage.size.height)
        let newSize = CGSize(width: uiImage.size.width * ratio, height: uiImage.size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let thumbnailImage = renderer.image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return thumbnailImage.pngData()
        #endif
    }
}
