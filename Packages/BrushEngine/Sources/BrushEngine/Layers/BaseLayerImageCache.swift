//
//  BaseLayerImageCache.swift
//  BrushEngine
//
//  Created by Claude on 2026-01-06.
//  DR-0029: Shared cache for base layer images to persist across visibility toggles and app restarts
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

/// Shared cache for base layer terrain and pattern images
/// Persists across view recreation to avoid regeneration when toggling visibility
@MainActor
public final class BaseLayerImageCache {
    /// Shared singleton instance
    public static let shared = BaseLayerImageCache()

    /// Cache storage: [cacheKey: image]
    private var cache: [String: PlatformImage] = [:]

    /// Memory limit in bytes (~100MB)
    private let maxCacheSize: Int = 100 * 1024 * 1024

    /// Current cache size estimate
    private var currentCacheSize: Int = 0

    private init() {
        // Subscribe to memory warnings to clear cache when needed
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in self?.clearAll() }
        }
        #endif
    }

    /// Generate cache key from fill parameters
    /// Format: "fillType_patternSeed_terrainSeed_widthxheight"
    public nonisolated static func cacheKey(fillType: String, patternSeed: Int, terrainSeed: Int?, width: Int, height: Int) -> String {
        if let terrainSeed = terrainSeed {
            return "\(fillType)_\(patternSeed)_\(terrainSeed)_\(width)x\(height)"
        } else {
            return "\(fillType)_\(patternSeed)_\(width)x\(height)"
        }
    }

    /// Get cached image
    public func get(_ key: String) -> PlatformImage? {
        if let image = cache[key] {
            print("[BaseLayerImageCache] Cache HIT - key: \(key)")
            return image
        } else {
            print("[BaseLayerImageCache] Cache MISS - key: \(key)")
            return nil
        }
    }

    /// Store image in cache
    public func set(_ key: String, image: PlatformImage) {
        // Estimate image size (width * height * 4 bytes per pixel for RGBA)
        #if canImport(UIKit)
        let imageSize = Int(image.size.width * image.size.height * 4 * image.scale * image.scale)
        #elseif canImport(AppKit)
        let imageSize = Int(image.size.width * image.size.height * 4)
        #endif

        // If adding this image would exceed limit, clear oldest entries
        while currentCacheSize + imageSize > maxCacheSize && !cache.isEmpty {
            // Remove first entry (FIFO eviction)
            if let firstKey = cache.keys.first {
                cache.removeValue(forKey: firstKey)
                print("[BaseLayerImageCache] Evicted entry: \(firstKey)")
            }
        }

        // Store the image
        cache[key] = image
        currentCacheSize += imageSize

        print("[BaseLayerImageCache] Cached image - key: \(key), size: ~\(imageSize / 1024 / 1024)MB, total: ~\(currentCacheSize / 1024 / 1024)MB")
    }

    /// Clear all cached images
    public func clearAll() {
        cache.removeAll()
        currentCacheSize = 0
        print("[BaseLayerImageCache] Cache cleared")
    }

    /// Remove specific cached image
    public func remove(_ key: String) {
        cache.removeValue(forKey: key)
        print("[BaseLayerImageCache] Removed key: \(key)")
    }
}
