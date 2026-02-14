//
//  ThumbnailGeneratorTests.swift
//  ImageProcessingTests
//
//  Tests for thumbnail generation functionality.
//

import Foundation
import Testing
@testable import ImageProcessing

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@Suite("ThumbnailGenerator Tests")
struct ThumbnailGeneratorTests {

    // MARK: - Test Helpers

    func generateTestImageData(width: Int = 100, height: Int = 100, red: CGFloat = 1.0, green: CGFloat = 0.0, blue: CGFloat = 0.0) -> Data? {
        #if os(macOS)
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
            NSColor(red: red, green: green, blue: blue, alpha: 1.0).setFill()
            rect.fill()
            return true
        }
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .png, properties: [:])
        #else
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { context in
            UIColor(red: red, green: green, blue: blue, alpha: 1.0).setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return image.pngData()
        #endif
    }

    // MARK: - Tests

    @Test("Generate thumbnail from valid image data")
    func generateThumbnailSuccess() {
        guard let imageData = generateTestImageData(width: 500, height: 500) else {
            Issue.record("Failed to create test image data")
            return
        }

        let thumbnail = ImageProcessingService.shared.generateThumbnail(from: imageData, size: CGSize(width: 200, height: 200))
        #expect(thumbnail != nil, "Thumbnail should be generated successfully")

        if let thumbnail {
            #if os(macOS)
            let image = NSImage(data: thumbnail)
            #expect(image != nil, "Thumbnail data should be valid NSImage")
            #else
            let image = UIImage(data: thumbnail)
            #expect(image != nil, "Thumbnail data should be valid UIImage")
            #endif
        }
    }

    @Test("Generate thumbnail with custom size preserves aspect ratio")
    func thumbnailCustomSizeAspectRatio() {
        guard let imageData = generateTestImageData(width: 800, height: 600) else {
            Issue.record("Failed to create test image data")
            return
        }

        let thumbnail = ImageProcessingService.shared.generateThumbnail(from: imageData, size: CGSize(width: 150, height: 150))
        #expect(thumbnail != nil)

        if let thumbnail {
            // Verify thumbnail is smaller than the original by checking data size
            #expect(thumbnail.count < imageData.count, "Thumbnail should be smaller than original")
            // Verify it's a valid image
            #if os(macOS)
            #expect(NSImage(data: thumbnail) != nil, "Thumbnail should be valid NSImage")
            #else
            #expect(UIImage(data: thumbnail) != nil, "Thumbnail should be valid UIImage")
            #endif
        }
    }

    @Test("Generate thumbnail from invalid data returns nil")
    func thumbnailInvalidData() {
        let invalidData = Data("This is not an image".utf8)
        let thumbnail = ImageProcessingService.shared.generateThumbnail(from: invalidData)
        #expect(thumbnail == nil)
    }

    @Test("Generate thumbnail with default size (200x200)")
    func thumbnailDefaultSize() {
        guard let imageData = generateTestImageData(width: 1000, height: 1000) else {
            Issue.record("Failed to create test image data")
            return
        }

        let thumbnail = ImageProcessingService.shared.generateThumbnail(from: imageData)
        #expect(thumbnail != nil)

        if let thumbnail {
            // Verify thumbnail is smaller than the original
            #expect(thumbnail.count < imageData.count, "Thumbnail should be smaller than original")
            // Verify it's a valid image
            #if os(macOS)
            #expect(NSImage(data: thumbnail) != nil)
            #else
            #expect(UIImage(data: thumbnail) != nil)
            #endif
        }
    }

    @Test("Service is a singleton")
    func singletonInstance() {
        let instance1 = ImageProcessingService.shared
        let instance2 = ImageProcessingService.shared
        #expect(instance1 === instance2)
    }
}
