//
//  BrushSet.swift
//  BrushEngine
//
//  Brush collection and metadata for themed brush sets
//

import SwiftUI
import Foundation

// MARK: - Brush Set

/// A collection of brushes organized for a specific map type or style
public struct BrushSet: Identifiable, Codable {
    // MARK: - Identity

    public let id: UUID
    public var name: String
    public var description: String
    public var mapType: MapType

    // MARK: - Content

    public var brushes: [MapBrush]
    public var defaultLayers: [LayerType]

    // MARK: - Metadata

    public var thumbnail: Data?
    public var author: String?
    public var version: String
    public var isBuiltIn: Bool
    public var isInstalled: Bool

    public var createdAt: Date
    public var modifiedAt: Date

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        mapType: MapType,
        brushes: [MapBrush] = [],
        defaultLayers: [LayerType] = [],
        thumbnail: Data? = nil,
        author: String? = nil,
        version: String = "1.0",
        isBuiltIn: Bool = false,
        isInstalled: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.mapType = mapType
        self.brushes = brushes
        self.defaultLayers = defaultLayers
        self.thumbnail = thumbnail
        self.author = author
        self.version = version
        self.isBuiltIn = isBuiltIn
        self.isInstalled = isInstalled

        let now = Date()
        self.createdAt = now
        self.modifiedAt = now
    }

    // MARK: - Computed Properties

    /// Number of brushes in this set
    public var brushCount: Int {
        brushes.count
    }

    /// All categories represented in this brush set
    public var categories: [BrushCategory] {
        Array(Set(brushes.map { $0.category })).sorted { $0.rawValue < $1.rawValue }
    }

    /// Brushes organized by category
    public var brushesByCategory: [BrushCategory: [MapBrush]] {
        Dictionary(grouping: brushes, by: { $0.category })
    }

    /// Whether this brush set has any brushes
    public var isEmpty: Bool {
        brushes.isEmpty
    }

    // MARK: - Brush Management

    /// Add a brush to this set
    public mutating func addBrush(_ brush: MapBrush) {
        brushes.append(brush)
        modifiedAt = Date()
    }

    /// Remove a brush by ID
    public mutating func removeBrush(id: UUID) {
        brushes.removeAll { $0.id == id }
        modifiedAt = Date()
    }

    /// Update a brush in this set
    public mutating func updateBrush(_ brush: MapBrush) {
        if let index = brushes.firstIndex(where: { $0.id == brush.id }) {
            brushes[index] = brush
            modifiedAt = Date()
        }
    }

    /// Get a brush by ID
    public func getBrush(id: UUID) -> MapBrush? {
        brushes.first { $0.id == id }
    }

    /// Get brushes in a specific category
    public func brushes(in category: BrushCategory) -> [MapBrush] {
        brushes.filter { $0.category == category }
    }

    // MARK: - Layer Management

    /// Add a default layer type
    public mutating func addDefaultLayer(_ layerType: LayerType) {
        if !defaultLayers.contains(layerType) {
            defaultLayers.append(layerType)
            modifiedAt = Date()
        }
    }

    /// Remove a default layer type
    public mutating func removeDefaultLayer(_ layerType: LayerType) {
        defaultLayers.removeAll { $0 == layerType }
        modifiedAt = Date()
    }

    /// Create a layer manager with default layers for this brush set
    public func createDefaultLayerManager() -> LayerManager {
        let manager = LayerManager()

        // Remove the default generic layer
        if let defaultLayer = manager.layers.first {
            manager.deleteLayer(id: defaultLayer.id)
        }

        // Add configured default layers
        for (index, layerType) in defaultLayers.enumerated() {
            let layer = DrawingLayer(
                name: layerType.rawValue,
                order: index,
                layerType: layerType
            )
            manager.layers.append(layer)
        }

        // Select the first layer
        if let firstLayer = manager.layers.first {
            manager.activeLayerID = firstLayer.id
        }

        return manager
    }
}

// MARK: - Map Type

/// Classification of map types that brushes are optimized for
public enum MapType: String, CaseIterable, Codable, Identifiable {
    case exterior = "Exterior/World Maps"
    case interior = "Interior/Architectural"
    case hybrid = "Hybrid"
    case custom = "Custom"

    public var id: String { rawValue }

    public var description: String {
        switch self {
        case .exterior:
            return "Outdoor maps with terrain, rivers, forests, and settlements"
        case .interior:
            return "Indoor maps with walls, doors, rooms, and furniture"
        case .hybrid:
            return "Flexible maps supporting both interior and exterior elements"
        case .custom:
            return "User-created custom brush sets"
        }
    }

    public var icon: String {
        switch self {
        case .exterior: return "map.fill"
        case .interior: return "house.fill"
        case .hybrid: return "square.split.2x2.fill"
        case .custom: return "paintpalette.fill"
        }
    }

    /// Recommended default layers for this map type
    public var recommendedLayers: [LayerType] {
        switch self {
        case .exterior:
            return [.terrain, .water, .vegetation, .roads, .structures, .annotations]
        case .interior:
            return [.generic, .walls, .features, .furniture, .annotations]
        case .hybrid:
            return [.terrain, .structures, .walls, .features, .annotations]
        case .custom:
            return [.generic]
        }
    }
}

// MARK: - Brush Set Extensions

extension BrushSet {
    /// Create a sample brush set for previews
    public static func sample() -> BrushSet {
        BrushSet(
            name: "Sample Brush Set",
            description: "A sample collection of brushes for testing",
            mapType: .exterior,
            brushes: [
                .basicPen,
                .marker,
                .pencil
            ],
            defaultLayers: [.terrain, .water, .structures],
            isBuiltIn: true,
            isInstalled: true
        )
    }

    /// Create an empty custom brush set
    public static func emptyCustom(name: String) -> BrushSet {
        BrushSet(
            name: name,
            description: "Custom brush set",
            mapType: .custom,
            brushes: [],
            defaultLayers: [.generic],
            isBuiltIn: false,
            isInstalled: true
        )
    }
}

// MARK: - Brush Set Package (for import/export)

/// Complete package of a brush set including all assets
public struct BrushSetPackage: Codable {
    public let metadata: BrushSetMetadata
    public let brushes: [MapBrush]
    public let previewImages: [String: Data] // brush id -> preview image
    public let textures: [String: Data] // texture id -> image data
    public let thumbnailImage: Data?

    /// Create a package from a brush set
    public init(brushSet: BrushSet) {
        self.metadata = BrushSetMetadata(
            id: brushSet.id,
            name: brushSet.name,
            description: brushSet.description,
            mapType: brushSet.mapType,
            author: brushSet.author,
            version: brushSet.version,
            defaultLayers: brushSet.defaultLayers,
            createdAt: brushSet.createdAt,
            modifiedAt: brushSet.modifiedAt
        )
        self.brushes = brushSet.brushes
        self.previewImages = [:] // TODO: Generate preview images
        self.textures = BrushSetPackage.extractTextures(from: brushSet.brushes)
        self.thumbnailImage = brushSet.thumbnail
    }

    /// Convert back to a brush set
    public func toBrushSet() -> BrushSet {
        BrushSet(
            id: metadata.id,
            name: metadata.name,
            description: metadata.description,
            mapType: metadata.mapType,
            brushes: brushes,
            defaultLayers: metadata.defaultLayers,
            thumbnail: thumbnailImage,
            author: metadata.author,
            version: metadata.version,
            isBuiltIn: false,
            isInstalled: false
        )
    }

    private static func extractTextures(from brushes: [MapBrush]) -> [String: Data] {
        var textures: [String: Data] = [:]

        for brush in brushes {
            if let textureData = brush.textureImage {
                textures[brush.id.uuidString] = textureData
            }
        }

        return textures
    }
}

// MARK: - Brush Set Metadata

/// Metadata for a brush set (used in packages and catalogs)
public struct BrushSetMetadata: Codable {
    public let id: UUID
    public var name: String
    public var description: String
    public var mapType: MapType
    public var author: String?
    public var version: String
    public var defaultLayers: [LayerType]
    public var createdAt: Date
    public var modifiedAt: Date

    /// File format version for compatibility
    public static let formatVersion = "1.0"
}

// MARK: - Brush Set Collection

/// A collection of brush sets (used in the brush registry)
public struct BrushSetCollection: Codable {
    public var brushSets: [BrushSet]

    public var count: Int {
        brushSets.count
    }

    public var isEmpty: Bool {
        brushSets.isEmpty
    }

    public mutating func add(_ brushSet: BrushSet) {
        brushSets.append(brushSet)
    }

    public mutating func remove(id: UUID) {
        brushSets.removeAll { $0.id == id }
    }

    public func get(id: UUID) -> BrushSet? {
        brushSets.first { $0.id == id }
    }

    /// Get all brush sets of a specific type
    public func brushSets(ofType mapType: MapType) -> [BrushSet] {
        brushSets.filter { $0.mapType == mapType }
    }

    /// Get all installed brush sets
    public var installedBrushSets: [BrushSet] {
        brushSets.filter { $0.isInstalled }
    }

    /// Get all built-in brush sets
    public var builtInBrushSets: [BrushSet] {
        brushSets.filter { $0.isBuiltIn }
    }
}
