//
//  ImageLoader.swift
//  ImageProcessing
//
//  Async image loading from Data and URLs, returning CGImage.
//  Supports macOS (AppKit) and iOS/visionOS (UIKit).
//

import Foundation
import CoreGraphics

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct ImageLoader: Sendable {

    public init() {}

    /// Load a CGImage from image data.
    /// - Parameter data: Source image data
    /// - Returns: CGImage, or nil if loading fails
    public func loadCGImage(from data: Data) async -> CGImage? {
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

    /// Load a CGImage from a file URL.
    /// - Parameter url: Source image URL (local file)
    /// - Returns: CGImage, or nil if loading fails
    public func loadCGImage(from url: URL) async -> CGImage? {
        do {
            let data = try Data(contentsOf: url)
            return await loadCGImage(from: data)
        } catch {
            return nil
        }
    }
}
