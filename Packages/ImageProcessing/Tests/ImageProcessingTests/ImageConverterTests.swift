//
//  ImageConverterTests.swift
//  ImageProcessingTests
//
//  Tests for image format conversion functionality.
//

import Foundation
import Testing
@testable import ImageProcessing

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@Suite("ImageConverter Tests")
struct ImageConverterTests {

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

    // MARK: - PNG Conversion Tests

    @Test("Convert image data to PNG")
    func convertToPNG() {
        guard let imageData = generateTestImageData(width: 300, height: 300, red: 0.0, green: 1.0, blue: 0.0) else {
            Issue.record("Failed to create test image data")
            return
        }

        let pngData = ImageProcessingService.shared.convertToPNG(imageData)
        #expect(pngData != nil)

        if let png = pngData {
            // Verify PNG signature: 89 50 4E 47
            let bytes = [UInt8](png.prefix(4))
            #expect(bytes.count >= 4)
            if bytes.count >= 4 {
                #expect(bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47,
                       "Should have correct PNG signature")
            }
        }
    }

    @Test("Convert invalid data to PNG returns nil")
    func convertToPNGInvalidData() {
        let invalidData = Data("Not an image".utf8)
        let pngData = ImageProcessingService.shared.convertToPNG(invalidData)
        #expect(pngData == nil)
    }

    // MARK: - JPEG Conversion Tests

    @Test("Convert image data to JPEG")
    func convertToJPEG() {
        guard let imageData = generateTestImageData(width: 300, height: 300, red: 0.0, green: 0.0, blue: 1.0) else {
            Issue.record("Failed to create test image data")
            return
        }

        let jpegData = ImageProcessingService.shared.convertToJPEG(imageData, compressionQuality: 0.9)
        #expect(jpegData != nil)

        if let jpeg = jpegData {
            // Verify JPEG signature: FF D8 FF
            let bytes = [UInt8](jpeg.prefix(3))
            #expect(bytes.count >= 3)
            if bytes.count >= 3 {
                #expect(bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF,
                       "Should have correct JPEG signature")
            }
        }
    }

    @Test("Lower JPEG compression produces smaller file")
    func jpegCompressionQuality() {
        guard let imageData = generateTestImageData(width: 500, height: 500) else {
            Issue.record("Failed to create test image data")
            return
        }

        let highQuality = ImageProcessingService.shared.convertToJPEG(imageData, compressionQuality: 1.0)
        let lowQuality = ImageProcessingService.shared.convertToJPEG(imageData, compressionQuality: 0.1)

        #expect(highQuality != nil)
        #expect(lowQuality != nil)

        if let high = highQuality, let low = lowQuality {
            #expect(low.count < high.count, "Lower quality should produce smaller file")
        }
    }

    @Test("Convert to JPEG with default compression quality")
    func jpegDefaultQuality() {
        guard let imageData = generateTestImageData(width: 400, height: 400) else {
            Issue.record("Failed to create test image data")
            return
        }

        let jpegData = ImageProcessingService.shared.convertToJPEG(imageData)
        #expect(jpegData != nil)
    }

    @Test("Convert invalid data to JPEG returns nil")
    func convertToJPEGInvalidData() {
        let invalidData = Data("Not an image".utf8)
        let jpegData = ImageProcessingService.shared.convertToJPEG(invalidData)
        #expect(jpegData == nil)
    }

    // MARK: - Round-Trip Tests

    @Test("Round-trip: thumbnail then JPEG conversion")
    func thumbnailToJPEGRoundTrip() {
        guard let imageData = generateTestImageData(width: 1000, height: 800) else {
            Issue.record("Failed to create test image data")
            return
        }

        guard let thumbnailData = ImageProcessingService.shared.generateThumbnail(from: imageData, size: CGSize(width: 150, height: 150)) else {
            Issue.record("Failed to generate thumbnail")
            return
        }

        let jpegData = ImageProcessingService.shared.convertToJPEG(thumbnailData, compressionQuality: 0.8)
        #expect(jpegData != nil)

        if let jpeg = jpegData {
            #if os(macOS)
            #expect(NSImage(data: jpeg) != nil)
            #else
            #expect(UIImage(data: jpeg) != nil)
            #endif
        }
    }

    @Test("Round-trip: PNG conversion preserves validity")
    func pngRoundTrip() {
        guard let imageData = generateTestImageData(width: 100, height: 100, red: 1.0, green: 0.5, blue: 0.25) else {
            Issue.record("Failed to create test image data")
            return
        }

        guard let png1 = ImageProcessingService.shared.convertToPNG(imageData) else {
            Issue.record("First PNG conversion failed")
            return
        }

        guard let png2 = ImageProcessingService.shared.convertToPNG(png1) else {
            Issue.record("Second PNG conversion failed")
            return
        }

        #if os(macOS)
        #expect(NSImage(data: png1) != nil)
        #expect(NSImage(data: png2) != nil)
        #else
        #expect(UIImage(data: png1) != nil)
        #expect(UIImage(data: png2) != nil)
        #endif
    }
}
