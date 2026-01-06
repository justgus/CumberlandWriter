//
//  BaseLayerImageCache.swift
//  Cumberland
//
//  Created by Claude on 2026-01-06.
//  DR-0029: Shared cache for base layer images to persist across visibility toggles and app restarts
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

/// Shared cache for base layer terrain and pattern images
/// Persists across view recreation to avoid regeneration when toggling visibility
class BaseLayerImageCache {
    /// Shared singleton instance
    static let shared = BaseLayerImageCache()

    /// Cache storage: [cacheKey: image]
    private var cache: [String: PlatformImage] = [:]

    /// Memory limit in bytes (~100MB)
    private let maxCacheSize: Int = 100 * 1024 * 1024

    /// Current cache size estimate
    private var currentCacheSize: Int = 0

    /// Thread-safe access
    private let queue = DispatchQueue(label: "com.cumberland.baseLayerImageCache", attributes: .concurrent)

    private init() {
        // Subscribe to memory warnings to clear cache when needed
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        #endif
    }

    /// Generate cache key from fill parameters
    /// Format: "fillType_patternSeed_terrainSeed_widthxheight"
    static func cacheKey(fillType: String, patternSeed: Int, terrainSeed: Int?, width: Int, height: Int) -> String {
        if let terrainSeed = terrainSeed {
            return "\(fillType)_\(patternSeed)_\(terrainSeed)_\(width)x\(height)"
        } else {
            return "\(fillType)_\(patternSeed)_\(width)x\(height)"
        }
    }

    /// Get cached image
    func get(_ key: String) -> PlatformImage? {
        queue.sync {
            if let image = cache[key] {
                print("[BaseLayerImageCache] Cache HIT - key: \(key)")
                return image
            } else {
                print("[BaseLayerImageCache] Cache MISS - key: \(key)")
                return nil
            }
        }
    }

    /// Store image in cache
    func set(_ key: String, image: PlatformImage) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            // Estimate image size (width * height * 4 bytes per pixel for RGBA)
            #if canImport(UIKit)
            let imageSize = Int(image.size.width * image.size.height * 4 * image.scale * image.scale)
            #elseif canImport(AppKit)
            let imageSize = Int(image.size.width * image.size.height * 4)
            #endif

            // If adding this image would exceed limit, clear oldest entries
            while self.currentCacheSize + imageSize > self.maxCacheSize && !self.cache.isEmpty {
                // Remove first entry (FIFO eviction)
                if let firstKey = self.cache.keys.first {
                    self.cache.removeValue(forKey: firstKey)
                    print("[BaseLayerImageCache] Evicted entry: \(firstKey)")
                }
            }

            // Store the image
            self.cache[key] = image
            self.currentCacheSize += imageSize

            print("[BaseLayerImageCache] Cached image - key: \(key), size: ~\(imageSize / 1024 / 1024)MB, total: ~\(self.currentCacheSize / 1024 / 1024)MB")
        }
    }

    /// Clear all cached images
    func clearAll() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll()
            self?.currentCacheSize = 0
            print("[BaseLayerImageCache] Cache cleared")
        }
    }

    /// Remove specific cached image
    func remove(_ key: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeValue(forKey: key)
            print("[BaseLayerImageCache] Removed key: \(key)")
        }
    }

    @objc private func handleMemoryWarning() {
        print("[BaseLayerImageCache] Memory warning - clearing cache")
        clearAll()
    }

    deinit {
        #if canImport(UIKit)
        NotificationCenter.default.removeObserver(self)
        #endif
    }
}
