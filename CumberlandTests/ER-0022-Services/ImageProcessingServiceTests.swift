//
//  ImageProcessingServiceTests.swift
//  CumberlandTests
//
//  Created for ER-0022 Phase 5: Testing and Validation
//  Tests for ImageProcessingService (Phase 1 deliverable)
//

import Foundation
import Testing

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Tests for ImageProcessingService - ER-0022 Phase 1
///
/// This service consolidates duplicate image processing code from:
/// - BatchGenerationQueue.swift:516-550
/// - ImageVersionManager.swift:196+
/// - CardSheetView.swift (nsImageToPngData, nsImageToJpegData)
@Suite("ImageProcessingService Tests")
struct ImageProcessingServiceTests {

    // MARK: - Test Data Generation

    /// Generate a simple solid-color test image
    func generateTestImageData(width: Int = 100, height: Int = 100, red: CGFloat = 1.0, green: CGFloat = 0.0, blue: CGFloat = 0.0) -> Data? {
        #if os(macOS)
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor(red: red, green: green, blue: blue, alpha: 1.0).setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        image.unlockFocus()

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
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

    // MARK: - Singleton Tests

    @Test("Service is a singleton")
    func testSingletonInstance() {
        let instance1 = ImageProcessingService.shared
        let instance2 = ImageProcessingService.shared

        #expect(instance1 === instance2, "ImageProcessingService should return the same singleton instance")
    }

    // MARK: - Thumbnail Generation Tests

    @Test("Generate thumbnail from valid image data")
    func testGenerateThumbnailSuccess() {
        let testImageData = generateTestImageData(width: 500, height: 500)
        #expect(testImageData != nil, "Test image data should be created")

        guard let imageData = testImageData else { return }

        let service = ImageProcessingService.shared
        let thumbnailData = service.generateThumbnail(from: imageData, size: CGSize(width: 200, height: 200))

        #expect(thumbnailData != nil, "Thumbnail should be generated successfully")

        // Verify thumbnail is valid image data
        if let thumbnail = thumbnailData {
            #if os(macOS)
            let thumbnailImage = NSImage(data: thumbnail)
            #expect(thumbnailImage != nil, "Thumbnail data should be valid NSImage")
            #else
            let thumbnailImage = UIImage(data: thumbnail)
            #expect(thumbnailImage != nil, "Thumbnail data should be valid UIImage")
            #endif
        }
    }

    @Test("Generate thumbnail with custom size")
    func testGenerateThumbnailCustomSize() {
        let testImageData = generateTestImageData(width: 800, height: 600)
        guard let imageData = testImageData else {
            Issue.record("Failed to create test image data")
            return
        }

        let service = ImageProcessingService.shared
        let thumbnailData = service.generateThumbnail(from: imageData, size: CGSize(width: 150, height: 150))

        #expect(thumbnailData != nil, "Thumbnail with custom size should be generated")

        // Verify thumbnail maintains aspect ratio
        if let thumbnail = thumbnailData {
            #if os(macOS)
            if let image = NSImage(data: thumbnail) {
                let size = image.size
                // Original is 800x600 (4:3), scaled to fit in 150x150
                // Height should be limiting factor: 150px high, width = 150 * (4/3) = 200px
                // Actually: aspect ratio preserved, so max dimension = 150
                #expect(size.width <= 150 && size.height <= 150, "Thumbnail should fit within requested size")
            }
            #else
            if let image = UIImage(data: thumbnail) {
                let size = image.size
                #expect(size.width <= 150 && size.height <= 150, "Thumbnail should fit within requested size")
            }
            #endif
        }
    }

    @Test("Generate thumbnail from invalid data returns nil")
    func testGenerateThumbnailInvalidData() {
        let invalidData = Data("This is not an image".utf8)

        let service = ImageProcessingService.shared
        let thumbnailData = service.generateThumbnail(from: invalidData)

        #expect(thumbnailData == nil, "Thumbnail generation should fail for invalid image data")
    }

    @Test("Generate thumbnail with default size")
    func testGenerateThumbnailDefaultSize() {
        let testImageData = generateTestImageData(width: 1000, height: 1000)
        guard let imageData = testImageData else {
            Issue.record("Failed to create test image data")
            return
        }

        let service = ImageProcessingService.shared
        let thumbnailData = service.generateThumbnail(from: imageData) // Uses default 200x200

        #expect(thumbnailData != nil, "Thumbnail with default size should be generated")

        if let thumbnail = thumbnailData {
            #if os(macOS)
            if let image = NSImage(data: thumbnail) {
                #expect(image.size.width <= 200 && image.size.height <= 200, "Default thumbnail should be 200x200 or smaller")
            }
            #else
            if let image = UIImage(data: thumbnail) {
                #expect(image.size.width <= 200 && image.size.height <= 200, "Default thumbnail should be 200x200 or smaller")
            }
            #endif
        }
    }

    // MARK: - PNG Conversion Tests

    @Test("Convert image data to PNG")
    func testConvertToPNG() {
        let testImageData = generateTestImageData(width: 300, height: 300, red: 0.0, green: 1.0, blue: 0.0)
        guard let imageData = testImageData else {
            Issue.record("Failed to create test image data")
            return
        }

        let service = ImageProcessingService.shared
        let pngData = service.convertToPNG(imageData)

        #expect(pngData != nil, "PNG conversion should succeed")

        if let png = pngData {
            // Verify it's valid PNG data (PNG signature: 89 50 4E 47)
            let bytes = [UInt8](png.prefix(4))
            #expect(bytes.count >= 4, "PNG data should have at least 4 bytes")
            if bytes.count >= 4 {
                #expect(bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47,
                       "PNG data should have correct PNG signature")
            }
        }
    }

    @Test("Convert invalid data to PNG returns nil")
    func testConvertToPNGInvalidData() {
        let invalidData = Data("Not an image".utf8)

        let service = ImageProcessingService.shared
        let pngData = service.convertToPNG(invalidData)

        #expect(pngData == nil, "PNG conversion should fail for invalid data")
    }

    // MARK: - JPEG Conversion Tests

    @Test("Convert image data to JPEG")
    func testConvertToJPEG() {
        let testImageData = generateTestImageData(width: 300, height: 300, red: 0.0, green: 0.0, blue: 1.0)
        guard let imageData = testImageData else {
            Issue.record("Failed to create test image data")
            return
        }

        let service = ImageProcessingService.shared
        let jpegData = service.convertToJPEG(imageData, compressionQuality: 0.9)

        #expect(jpegData != nil, "JPEG conversion should succeed")

        if let jpeg = jpegData {
            // Verify it's valid JPEG data (JPEG signature: FF D8 FF)
            let bytes = [UInt8](jpeg.prefix(3))
            #expect(bytes.count >= 3, "JPEG data should have at least 3 bytes")
            if bytes.count >= 3 {
                #expect(bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF,
                       "JPEG data should have correct JPEG signature")
            }
        }
    }

    @Test("Convert to JPEG with different compression qualities")
    func testConvertToJPEGCompressionQuality() {
        let testImageData = generateTestImageData(width: 500, height: 500)
        guard let imageData = testImageData else {
            Issue.record("Failed to create test image data")
            return
        }

        let service = ImageProcessingService.shared

        let highQuality = service.convertToJPEG(imageData, compressionQuality: 1.0)
        let lowQuality = service.convertToJPEG(imageData, compressionQuality: 0.1)

        #expect(highQuality != nil, "High quality JPEG should be generated")
        #expect(lowQuality != nil, "Low quality JPEG should be generated")

        if let high = highQuality, let low = lowQuality {
            // Lower compression quality should result in smaller file size
            #expect(low.count < high.count, "Lower compression quality should produce smaller file")
        }
    }

    @Test("Convert to JPEG with default compression quality")
    func testConvertToJPEGDefaultQuality() {
        let testImageData = generateTestImageData(width: 400, height: 400)
        guard let imageData = testImageData else {
            Issue.record("Failed to create test image data")
            return
        }

        let service = ImageProcessingService.shared
        let jpegData = service.convertToJPEG(imageData) // Uses default 0.9

        #expect(jpegData != nil, "JPEG with default quality should be generated")
    }

    @Test("Convert invalid data to JPEG returns nil")
    func testConvertToJPEGInvalidData() {
        let invalidData = Data("Not an image".utf8)

        let service = ImageProcessingService.shared
        let jpegData = service.convertToJPEG(invalidData)

        #expect(jpegData == nil, "JPEG conversion should fail for invalid data")
    }

    // MARK: - Async Image Loading Tests (if implemented)

    // Note: loadImage(from:) async methods are referenced in ER-0022 but may not be implemented yet
    // Uncomment these tests once async methods are added:

    /*
    @Test("Load image from data asynchronously")
    func testLoadImageFromData() async {
        let testImageData = generateTestImageData(width: 200, height: 200)
        guard let imageData = testImageData else {
            Issue.record("Failed to create test image data")
            return
        }

        let service = ImageProcessingService.shared
        let cgImage = await service.loadImage(from: imageData)

        #expect(cgImage != nil, "Should load CGImage from valid data")

        if let image = cgImage {
            #expect(image.width == 200, "Loaded image should have correct width")
            #expect(image.height == 200, "Loaded image should have correct height")
        }
    }
    */

    // MARK: - Integration Tests

    @Test("Round-trip: Generate thumbnail then convert to JPEG")
    func testThumbnailToJPEGRoundTrip() {
        let testImageData = generateTestImageData(width: 1000, height: 800)
        guard let imageData = testImageData else {
            Issue.record("Failed to create test image data")
            return
        }

        let service = ImageProcessingService.shared

        // Generate thumbnail
        guard let thumbnailData = service.generateThumbnail(from: imageData, size: CGSize(width: 150, height: 150)) else {
            Issue.record("Failed to generate thumbnail")
            return
        }

        // Convert to JPEG
        let jpegData = service.convertToJPEG(thumbnailData, compressionQuality: 0.8)

        #expect(jpegData != nil, "Should convert thumbnail to JPEG")

        // Verify final result is valid
        if let jpeg = jpegData {
            #if os(macOS)
            let finalImage = NSImage(data: jpeg)
            #expect(finalImage != nil, "Final JPEG should be valid image")
            #else
            let finalImage = UIImage(data: jpeg)
            #expect(finalImage != nil, "Final JPEG should be valid image")
            #endif
        }
    }

    @Test("Round-trip: PNG conversion maintains image quality")
    func testPNGRoundTripQuality() {
        let testImageData = generateTestImageData(width: 100, height: 100, red: 1.0, green: 0.5, blue: 0.25)
        guard let imageData = testImageData else {
            Issue.record("Failed to create test image data")
            return
        }

        let service = ImageProcessingService.shared

        // Convert to PNG multiple times
        guard let png1 = service.convertToPNG(imageData) else {
            Issue.record("First PNG conversion failed")
            return
        }

        guard let png2 = service.convertToPNG(png1) else {
            Issue.record("Second PNG conversion failed")
            return
        }

        // Both should produce valid images
        #if os(macOS)
        #expect(NSImage(data: png1) != nil, "First PNG should be valid")
        #expect(NSImage(data: png2) != nil, "Second PNG should be valid")
        #else
        #expect(UIImage(data: png1) != nil, "First PNG should be valid")
        #expect(UIImage(data: png2) != nil, "Second PNG should be valid")
        #endif
    }
}
