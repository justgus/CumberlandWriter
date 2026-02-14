//
//  ImageLoaderTests.swift
//  ImageProcessingTests
//
//  Tests for async image loading functionality.
//

import Foundation
import Testing
@testable import ImageProcessing

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@Suite("ImageLoader Tests")
struct ImageLoaderTests {

    // MARK: - Test Helpers

    func generateTestImageData(width: Int = 100, height: Int = 100) -> Data? {
        #if os(macOS)
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
            NSColor.red.setFill()
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
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return image.pngData()
        #endif
    }

    // MARK: - Tests

    @Test("Load CGImage from valid data")
    func loadImageFromData() async {
        guard let imageData = generateTestImageData(width: 200, height: 200) else {
            Issue.record("Failed to create test image data")
            return
        }

        let cgImage = await ImageProcessingService.shared.loadImage(from: imageData)
        #expect(cgImage != nil)

        if let image = cgImage {
            // CGImage dimensions may be 2x on Retina displays
            #expect(image.width >= 200)
            #expect(image.height >= 200)
        }
    }

    @Test("Load CGImage from invalid data returns nil")
    func loadImageFromInvalidData() async {
        let invalidData = Data("Not an image".utf8)
        let cgImage = await ImageProcessingService.shared.loadImage(from: invalidData)
        #expect(cgImage == nil)
    }

    @Test("Load CGImage from file URL")
    func loadImageFromURL() async throws {
        guard let imageData = generateTestImageData(width: 150, height: 150) else {
            Issue.record("Failed to create test image data")
            return
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_image_\(UUID().uuidString).png")
        try imageData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let cgImage = await ImageProcessingService.shared.loadImage(from: tempURL)
        #expect(cgImage != nil)

        if let image = cgImage {
            // CGImage dimensions may be 2x on Retina displays
            #expect(image.width >= 150)
            #expect(image.height >= 150)
        }
    }

    @Test("Load CGImage from nonexistent URL returns nil")
    func loadImageFromBadURL() async {
        let badURL = URL(fileURLWithPath: "/nonexistent/path/image.png")
        let cgImage = await ImageProcessingService.shared.loadImage(from: badURL)
        #expect(cgImage == nil)
    }
}
