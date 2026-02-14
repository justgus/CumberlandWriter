//
//  ImageConverter.swift
//  ImageProcessing
//
//  Format conversion between PNG, JPEG, and other image formats.
//  Supports macOS (AppKit) and iOS/visionOS (UIKit).
//

import Foundation
import CoreGraphics

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct ImageConverter: Sendable {

    public init() {}

    /// Convert image data to PNG format.
    /// - Parameter imageData: Source image data (any supported format)
    /// - Returns: PNG data, or nil if conversion fails
    public func convertToPNG(_ imageData: Data) -> Data? {
        #if os(macOS)
        guard let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .png, properties: [:])

        #else
        guard let uiImage = UIImage(data: imageData) else { return nil }
        return uiImage.pngData()
        #endif
    }

    /// Convert image data to JPEG format.
    /// - Parameters:
    ///   - imageData: Source image data (any supported format)
    ///   - quality: JPEG compression quality (0.0 - 1.0, default: 0.9)
    /// - Returns: JPEG data, or nil if conversion fails
    public func convertToJPEG(_ imageData: Data, quality: CGFloat = 0.9) -> Data? {
        #if os(macOS)
        guard let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality])

        #else
        guard let uiImage = UIImage(data: imageData) else { return nil }
        return uiImage.jpegData(compressionQuality: quality)
        #endif
    }
}
