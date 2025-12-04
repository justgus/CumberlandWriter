//
//  BrushSet.swift
//  Cumberland
//
//  Brush collection and metadata for themed brush sets
//

import SwiftUI
import Foundation

// MARK: - Brush Set

/// A collection of brushes organized for a specific map type or style
struct BrushSet: Identifiable, Codable {
    // MARK: - Identity
    
    let id: UUID
    var name: String
    var description: String
    var mapType: MapType
    
    // MARK: - Content
    
    var brushes: [MapBrush]
    var defaultLayers: [LayerType]
    
    // MARK: - Metadata
    
    var thumbnail: Data?
    var author: String?
    var version: String
    var isBuiltIn: Bool
    var isInstalled: Bool
    
    var createdAt: Date
    var modifiedAt: Date
    
    // MARK: - Initialization
    
    init(
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
    var brushCount: Int {
        brushes.count
    }
    
    /// All categories represented in this brush set
    var categories: [BrushCategory] {
        Array(Set(brushes.map { $0.category })).sorted { $0.rawValue < $1.rawValue }
    }
    
    /// Brushes organized by category
    var brushesByCategory: [BrushCategory: [MapBrush]] {
        Dictionary(grouping: brushes, by: { $0.category })
    }
    
    /// Whether this brush set has any brushes
    var isEmpty: Bool {
        brushes.isEmpty
    }
    
    // MARK: - Brush Management
    
    /// Add a brush to this set
    mutating func addBrush(_ brush: MapBrush) {
        brushes.append(brush)
        modifiedAt = Date()
    }
    
    /// Remove a brush by ID
    mutating func removeBrush(id: UUID) {
        brushes.removeAll { $0.id == id }
        modifiedAt = Date()
    }
    
    /// Update a brush in this set
    mutating func updateBrush(_ brush: MapBrush) {
        if let index = brushes.firstIndex(where: { $0.id == brush.id }) {
            brushes[index] = brush
            modifiedAt = Date()
        }
    }
    
    /// Get a brush by ID
    func getBrush(id: UUID) -> MapBrush? {
        brushes.first { $0.id == id }
    }
    
    /// Get brushes in a specific category
    func brushes(in category: BrushCategory) -> [MapBrush] {
        brushes.filter { $0.category == category }
    }
    
    // MARK: - Layer Management
    
    /// Add a default layer type
    mutating func addDefaultLayer(_ layerType: LayerType) {
        if !defaultLayers.contains(layerType) {
            defaultLayers.append(layerType)
            modifiedAt = Date()
        }
    }
    
    /// Remove a default layer type
    mutating func removeDefaultLayer(_ layerType: LayerType) {
        defaultLayers.removeAll { $0 == layerType }
        modifiedAt = Date()
    }
    
    /// Create a layer manager with default layers for this brush set
    func createDefaultLayerManager() -> LayerManager {
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
enum MapType: String, CaseIterable, Codable, Identifiable {
    case exterior = "Exterior/World Maps"
    case interior = "Interior/Architectural"
    case hybrid = "Hybrid"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var description: String {
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
    
    var icon: String {
        switch self {
        case .exterior: return "map.fill"
        case .interior: return "house.fill"
        case .hybrid: return "square.split.2x2.fill"
        case .custom: return "paintpalette.fill"
        }
    }
    
    /// Recommended default layers for this map type
    var recommendedLayers: [LayerType] {
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
    static func sample() -> BrushSet {
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
    static func emptyCustom(name: String) -> BrushSet {
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
struct BrushSetPackage: Codable {
    let metadata: BrushSetMetadata
    let brushes: [MapBrush]
    let previewImages: [String: Data] // brush id -> preview image
    let textures: [String: Data] // texture id -> image data
    let thumbnailImage: Data?
    
    /// Create a package from a brush set
    init(brushSet: BrushSet) {
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
    func toBrushSet() -> BrushSet {
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
struct BrushSetMetadata: Codable {
    let id: UUID
    var name: String
    var description: String
    var mapType: MapType
    var author: String?
    var version: String
    var defaultLayers: [LayerType]
    var createdAt: Date
    var modifiedAt: Date
    
    /// File format version for compatibility
    static let formatVersion = "1.0"
}

// MARK: - Brush Set Collection

/// A collection of brush sets (used in the brush registry)
struct BrushSetCollection: Codable {
    var brushSets: [BrushSet]
    
    var count: Int {
        brushSets.count
    }
    
    var isEmpty: Bool {
        brushSets.isEmpty
    }
    
    mutating func add(_ brushSet: BrushSet) {
        brushSets.append(brushSet)
    }
    
    mutating func remove(id: UUID) {
        brushSets.removeAll { $0.id == id }
    }
    
    func get(id: UUID) -> BrushSet? {
        brushSets.first { $0.id == id }
    }
    
    /// Get all brush sets of a specific type
    func brushSets(ofType mapType: MapType) -> [BrushSet] {
        brushSets.filter { $0.mapType == mapType }
    }
    
    /// Get all installed brush sets
    var installedBrushSets: [BrushSet] {
        brushSets.filter { $0.isInstalled }
    }
    
    /// Get all built-in brush sets
    var builtInBrushSets: [BrushSet] {
        brushSets.filter { $0.isBuiltIn }
    }
}
