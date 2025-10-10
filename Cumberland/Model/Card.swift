//
//  Card.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/1/25.
//

import Foundation
import SwiftData
import SwiftUI
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Persistence model notes:
// - id is unique to support stable identity across sync and devices.
// - We index key string fields to speed up searches and sorts.
// - thumbnailData uses external storage to keep row payloads small; it remains synced.
// - imageFileURL is local-only by design and will not be synced.
//
@Model
final class Card: Identifiable {
    // Stable identifier for selection and hashing
    @Attribute(.unique)
    var id: UUID

    // Kind of card used for browsing/queries. Immutable to callers after init.
    // Provide a default so migration can backfill existing rows.
    private(set) var kind: Kinds = Kinds.projects

    // Mirror of 'kind' persisted as a primitive for SwiftData querying
    // Keep this in sync with 'kind' (kind is immutable after init here).
    // Provide a default so migration can backfill existing rows.
    var kindRaw: String = Kinds.projects.rawValue

    // Core fields
    var name: String {
        didSet { recomputeNormalizedSearchText() }
    }

    var subtitle: String {
        didSet { recomputeNormalizedSearchText() }
    }

    var detailedText: String {
        didSet { recomputeNormalizedSearchText() }
    }

    // Optional author field
    // Provide a default so migration can backfill existing rows.
    var author: String? = nil {
        didSet { recomputeNormalizedSearchText() }
    }

    // Additional metadata used by UI
    var sizeCategory: SizeCategory

    // Embedded thumbnail data (PNG), synced. External storage keeps the row small.
    @Attribute(.externalStorage)
    var thumbnailData: Data?

    // File URL to original image stored on disk (not synced)
    // This is intentionally local-only; if you later adopt CloudKit, keep this excluded.
    var imageFileURL: URL?

    // Precomputed aggregate for simple/backup searches
    // Provide a default so migration can backfill existing rows.
    var normalizedSearchText: String = ""

    init(
        id: UUID = UUID(),
        kind: Kinds = .projects,
        name: String,
        subtitle: String,
        detailedText: String,
        author: String? = nil,
        sizeCategory: SizeCategory = .standard,
        thumbnailData: Data? = nil,
        imageFileURL: URL? = nil
    ) {
        self.id = id
        self.kind = kind
        self.kindRaw = kind.rawValue
        self.name = name
        self.subtitle = subtitle
        self.detailedText = detailedText
        self.author = author
        self.sizeCategory = sizeCategory
        self.thumbnailData = thumbnailData
        self.imageFileURL = imageFileURL
        self.normalizedSearchText = ""
        recomputeNormalizedSearchText()
    }
}

// MARK: - SwiftUI Images

extension Card {
    @available(*, deprecated, message: "Use makeImage() async to avoid main-thread decoding")
    var image: Image? {
        guard let cg = cgImageFromFileURL() else { return nil }
        return Image(decorative: cg, scale: 1, orientation: .up)
    }

    @available(*, deprecated, message: "Use makeThumbnailImage() async to avoid main-thread decoding")
    var thumbnailImage: Image? {
        guard let cg = cgImageFromThumbnailData() ?? cgImageFromFileURL() else { return nil }
        return Image(decorative: cg, scale: 1, orientation: .up)
    }

    func makeThumbnailImage() async -> Image? {
        guard let cg = await loadThumbnailCGImage() else { return nil }
        return Image(decorative: cg, scale: 1, orientation: .up)
    }

    func makeImage() async -> Image? {
        guard let cg = await loadFullCGImage() else { return nil }
        return Image(decorative: cg, scale: 1, orientation: .up)
    }

    func prefetchImages() {
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            _ = await loadThumbnailCGImage()
            _ = await loadFullCGImage()
        }
    }
}

// MARK: - Public Mutators

extension Card {
    func setOriginalImageData(_ data: Data, preferredFileExtension: String? = nil) throws {
        let inferredExt = Self.inferFileExtension(from: data) ?? "jpg"
        let ext = (preferredFileExtension?.lowercased()).flatMap { $0.isEmpty ? nil : $0 } ?? inferredExt

        if let oldURL = imageFileURL {
            try? ImageStore.shared.deleteOriginalImage(at: oldURL)
        }

        let fileURL = try ImageStore.shared.writeOriginalImageData(data, for: id, fileExtension: ext)
        self.imageFileURL = fileURL

        if let cg = Self.makeCGImage(from: data) {
            self.thumbnailData = Self.makePNGThumbnailData(from: cg, maxPixel: Self.thumbnailMaxPixel)
            Self.cache(set: cg, for: cacheKeyFull)
            if let thumbCG = Self.makeCGImage(from: self.thumbnailData ?? Data()) {
                Self.cache(set: thumbCG, for: cacheKeyThumb)
            } else {
                if let scaled = Self.makeScaledCGImage(from: cg, maxPixel: Self.thumbnailMaxPixel) {
                    Self.cache(set: scaled, for: cacheKeyThumb)
                }
            }
        } else {
            if let cg = cgImageFromFileURL() {
                self.thumbnailData = Self.makePNGThumbnailData(from: cg, maxPixel: Self.thumbnailMaxPixel)
                Self.cache(set: cg, for: cacheKeyFull)
                if let thumbCG = Self.makeCGImage(from: self.thumbnailData ?? Data()) {
                    Self.cache(set: thumbCG, for: cacheKeyThumb)
                }
            }
        }
    }

    func replaceOriginalImageData(_ data: Data, preferredFileExtension: String? = nil) throws {
        try setOriginalImageData(data, preferredFileExtension: preferredFileExtension)
    }

    func removeOriginalImage() {
        if let url = imageFileURL {
            try? ImageStore.shared.deleteOriginalImage(at: url)
        }
        imageFileURL = nil
        Self.cache(removeFor: cacheKeyFull)
    }

    func regenerateThumbnailFromOriginal() {
        guard let cg = cgImageFromFileURL() else { return }
        self.thumbnailData = Self.makePNGThumbnailData(from: cg, maxPixel: Self.thumbnailMaxPixel)
        if let thumbCG = Self.makeCGImage(from: self.thumbnailData ?? Data()) {
            Self.cache(set: thumbCG, for: cacheKeyThumb)
        } else if let scaled = Self.makeScaledCGImage(from: cg, maxPixel: Self.thumbnailMaxPixel) {
            Self.cache(set: scaled, for: cacheKeyThumb)
        }
    }

    @discardableResult
    func validateOriginalURL() -> Bool {
        guard let url = imageFileURL else { return false }
        guard ImageStore.shared.isURLInsideStore(url) else {
            return FileManager.default.fileExists(atPath: url.path)
        }
        let exists = FileManager.default.fileExists(atPath: url.path)
        if !exists {
            imageFileURL = nil
            Self.cache(removeFor: cacheKeyFull)
        }
        return exists
    }

    func cleanupBeforeDeletion() {
        removeOriginalImage()
        clearImageCaches()
    }

    func clearImageCaches() {
        Self.cache(removeFor: cacheKeyFull)
        Self.cache(removeFor: cacheKeyThumb)
    }

    static func purgeAllImageCaches() {
        cgImageCache.removeAllObjects()
    }
}

// MARK: - Image decoding/encoding helpers

private extension Card {
    static let thumbnailMaxPixel: Int = 256

    private static let cgImageCache: NSCache<NSString, CGImage> = {
        let c = NSCache<NSString, CGImage>()
        c.countLimit = 500
        return c
    }()

    var cacheKeyFull: String {
        "\(id.uuidString)-full"
    }

    var cacheKeyThumb: String {
        let v = thumbnailData?.count ?? 0
        return "\(id.uuidString)-thumb-\(v)"
    }

    static func cache(get key: String) -> CGImage? {
        cgImageCache.object(forKey: key as NSString)
    }

    static func cache(set image: CGImage, for key: String) {
        cgImageCache.setObject(image, forKey: key as NSString)
    }

    static func cache(removeFor key: String) {
        cgImageCache.removeObject(forKey: key as NSString)
    }

    func loadThumbnailCGImage() async -> CGImage? {
        if let cached = Self.cache(get: cacheKeyThumb) {
            return cached
        }

        if let data = thumbnailData {
            if let cg = await Self.decodeCGImageAsync(fromData: data) {
                Self.cache(set: cg, for: cacheKeyThumb)
                return cg
            }
        }

        guard let original = await loadFullCGImage() else { return nil }
        if let scaled = Self.makeScaledCGImage(from: original, maxPixel: Self.thumbnailMaxPixel) {
            Self.cache(set: scaled, for: cacheKeyThumb)
            return scaled
        }
        return nil
    }

    func loadFullCGImage() async -> CGImage? {
        if let cached = Self.cache(get: cacheKeyFull) {
            return cached
        }
        guard let url = imageFileURL else { return nil }
        if let cg = await Self.decodeCGImageAsync(fromURL: url) {
            Self.cache(set: cg, for: cacheKeyFull)
            return cg
        }
        return nil
    }

    static func decodeCGImageAsync(fromData data: Data) async -> CGImage? {
        await withCheckedContinuation { continuation in
            Task.detached(priority: .utility) {
                let cg = makeCGImage(from: data)
                continuation.resume(returning: cg)
            }
        }
    }

    static func decodeCGImageAsync(fromURL url: URL) async -> CGImage? {
        await withCheckedContinuation { continuation in
            Task.detached(priority: .utility) {
                guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                    continuation.resume(returning: nil)
                    return
                }
                let cg = CGImageSourceCreateImageAtIndex(src, 0, nil)
                continuation.resume(returning: cg)
            }
        }
    }

    func cgImageFromFileURL() -> CGImage? {
        guard let url = imageFileURL else { return nil }
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, nil)
    }

    func cgImageFromThumbnailData() -> CGImage? {
        guard let data = thumbnailData as CFData? else { return nil }
        guard let src = CGImageSourceCreateWithData(data, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, nil)
    }

    static func makeCGImage(from data: Data) -> CGImage? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, nil)
    }

    static func makeScaledCGImage(from cg: CGImage, maxPixel: Int) -> CGImage? {
        let w = cg.width
        let h = cg.height
        let maxDim = max(w, h)
        let scale = maxDim > maxPixel ? CGFloat(maxPixel) / CGFloat(maxDim) : 1.0
        let targetW = max(1, Int(CGFloat(w) * scale))
        let targetH = max(1, Int(CGFloat(h) * scale))

        guard let colorSpace = cg.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        guard let ctx = CGContext(
            data: nil,
            width: targetW,
            height: targetH,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .high
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: targetW, height: targetH))
        return ctx.makeImage()
    }

    static func makePNGThumbnailData(from cg: CGImage, maxPixel: Int) -> Data? {
        guard let scaled = makeScaledCGImage(from: cg, maxPixel: maxPixel) else { return nil }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, scaled, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }

    static func inferFileExtension(from data: Data) -> String? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(src) as String?,
              let utType = UTType(type) else {
            return nil
        }
        return utType.preferredFilenameExtension
    }
}

// MARK: - Search normalization

private extension Card {
    func recomputeNormalizedSearchText() {
        let s = [name, subtitle, detailedText, author ?? ""]
            .joined(separator: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
        normalizedSearchText = s
    }
}

// MARK: - SizeCategory

enum SizeCategory: Int, Codable, CaseIterable, Hashable, Sendable {
    case compact
    case standard
    case large

    var displayName: String {
        switch self {
        case .compact:  return "Compact"
        case .standard: return "Standard"
        case .large:    return "Large"
        }
    }
}
