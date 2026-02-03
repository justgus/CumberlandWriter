import Foundation

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Manages image clipboard operations for copying and pasting images between cards
/// ER-0011 Phase 1: Copy/Paste Images
class ImageClipboardManager {
    static let shared = ImageClipboardManager()

    private init() {}

    // MARK: - Clipboard State

    /// Check if clipboard contains image data
    var hasImageInClipboard: Bool {
        #if canImport(AppKit)
        let pasteboard = NSPasteboard.general
        return pasteboard.types?.contains(.tiff) == true ||
               pasteboard.types?.contains(.png) == true ||
               pasteboard.types?.contains(NSPasteboard.PasteboardType("public.jpeg")) == true
        #elseif canImport(UIKit)
        return UIPasteboard.general.hasImages
        #else
        return false
        #endif
    }

    // MARK: - Copy Operations

    /// Copy image data to clipboard
    /// - Parameter imageData: The image data to copy (PNG, JPEG, etc.)
    /// - Returns: True if copy succeeded, false otherwise
    @discardableResult
    func copyImageToClipboard(_ imageData: Data) -> Bool {
        #if canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // Convert data to NSImage for clipboard
        guard let nsImage = NSImage(data: imageData) else {
            print("⚠️ [ImageClipboard] Failed to create NSImage from data")
            return false
        }

        // Copy as TIFF (lossless, supports all image types)
        guard let tiffData = nsImage.tiffRepresentation else {
            print("⚠️ [ImageClipboard] Failed to create TIFF representation")
            return false
        }

        pasteboard.setData(tiffData, forType: .tiff)

        #if DEBUG
        print("✓ [ImageClipboard] Copied image to clipboard (\(imageData.count) bytes)")
        #endif

        return true
        #elseif canImport(UIKit)
        // Convert data to UIImage for clipboard
        guard let uiImage = UIImage(data: imageData) else {
            print("⚠️ [ImageClipboard] Failed to create UIImage from data")
            return false
        }

        UIPasteboard.general.image = uiImage

        #if DEBUG
        print("✓ [ImageClipboard] Copied image to clipboard (\(imageData.count) bytes)")
        #endif

        return true
        #else
        print("⚠️ [ImageClipboard] Clipboard not supported on this platform")
        return false
        #endif
    }

    /// Copy image from a card to clipboard
    /// - Parameter card: The card whose image to copy
    /// - Returns: True if copy succeeded, false otherwise
    @discardableResult
    func copyCardImage(_ card: Card) -> Bool {
        // Prefer original image data, fall back to thumbnail
        if let imageData = card.originalImageData {
            return copyImageToClipboard(imageData)
        } else if let thumbnailData = card.thumbnailData {
            return copyImageToClipboard(thumbnailData)
        }

        print("⚠️ [ImageClipboard] Card has no image data to copy")
        return false
    }

    // MARK: - Paste Operations

    /// Paste image data from clipboard
    /// - Returns: Image data if successful, nil otherwise
    func pasteImageFromClipboard() -> Data? {
        #if canImport(AppKit)
        let pasteboard = NSPasteboard.general

        // Try to get image from clipboard
        guard pasteboard.types != nil else {
            print("⚠️ [ImageClipboard] No pasteboard types available")
            return nil
        }

        // Prefer PNG/JPEG, fall back to TIFF
        if let data = pasteboard.data(forType: .png) {
            #if DEBUG
            print("✓ [ImageClipboard] Pasted PNG image from clipboard (\(data.count) bytes)")
            #endif
            return data
        }

        if let data = pasteboard.data(forType: NSPasteboard.PasteboardType("public.jpeg")) {
            #if DEBUG
            print("✓ [ImageClipboard] Pasted JPEG image from clipboard (\(data.count) bytes)")
            #endif
            return data
        }

        if let tiffData = pasteboard.data(forType: .tiff),
           let nsImage = NSImage(data: tiffData),
           let pngData = convertToPNG(nsImage) {
            #if DEBUG
            print("✓ [ImageClipboard] Pasted and converted TIFF image from clipboard (\(pngData.count) bytes)")
            #endif
            return pngData
        }

        print("⚠️ [ImageClipboard] No compatible image data in clipboard")
        return nil
        #elseif canImport(UIKit)
        // Try to get image from clipboard
        guard let uiImage = UIPasteboard.general.image else {
            print("⚠️ [ImageClipboard] No image in clipboard")
            return nil
        }

        // Convert to PNG data
        guard let pngData = uiImage.pngData() else {
            print("⚠️ [ImageClipboard] Failed to convert image to PNG")
            return nil
        }

        #if DEBUG
        print("✓ [ImageClipboard] Pasted image from clipboard (\(pngData.count) bytes)")
        #endif

        return pngData
        #else
        print("⚠️ [ImageClipboard] Clipboard not supported on this platform")
        return nil
        #endif
    }

    // MARK: - Helper Methods

    #if canImport(AppKit)
    /// Convert NSImage to PNG data
    private func convertToPNG(_ image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmapRep.representation(using: .png, properties: [:])
    }
    #endif
}
