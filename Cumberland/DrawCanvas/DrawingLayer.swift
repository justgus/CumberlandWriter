//
//  DrawingLayer.swift
//  Cumberland
//
//  Layer system for map drawing - supports multiple layers with independent content
//

import SwiftUI
import Foundation

#if canImport(PencilKit)
import PencilKit
#endif

#if os(macOS)
import AppKit
#endif

// MARK: - Drawing Layer

/// Represents a single drawing layer with its own content and properties.
/// Each layer can have different visibility, opacity, blend modes, and content.
@Observable
class DrawingLayer: Identifiable, Codable {
    // MARK: - Identity
    
    let id: UUID
    var name: String
    var order: Int // Z-index for rendering (higher = on top)
    
    // MARK: - Visibility & Interaction
    
    var isVisible: Bool
    var isLocked: Bool
    
    // MARK: - Visual Properties
    
    var opacity: CGFloat // 0.0 to 1.0
    var blendMode: LayerBlendMode
    
    // MARK: - Layer Type
    
    var layerType: LayerType
    
    // MARK: - Drawing Content
    
    #if canImport(PencilKit)
    /// PencilKit drawing for iOS/iPadOS
    var drawing: PKDrawing
    #endif
    
    /// macOS native strokes
    var macosStrokes: [DrawingStroke]

    // MARK: - Base Layer Fill

    /// Optional fill for base layers (typically order == 0)
    var layerFill: LayerFill?

    // MARK: - Metadata
    
    var createdAt: Date
    var modifiedAt: Date
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        order: Int = 0,
        isVisible: Bool = true,
        isLocked: Bool = false,
        opacity: CGFloat = 1.0,
        blendMode: LayerBlendMode = .normal,
        layerType: LayerType
    ) {
        self.id = id
        self.name = name
        self.order = order
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.opacity = opacity
        self.blendMode = blendMode
        self.layerType = layerType
        
        #if canImport(PencilKit)
        self.drawing = PKDrawing()
        #endif
        
        self.macosStrokes = []
        
        let now = Date()
        self.createdAt = now
        self.modifiedAt = now
    }
    
    // MARK: - Content Queries
    
    /// Whether this layer has any content
    var isEmpty: Bool {
        #if canImport(PencilKit)
        return drawing.bounds.isEmpty && macosStrokes.isEmpty
        #else
        return macosStrokes.isEmpty
        #endif
    }
    
    /// Update the modified timestamp
    func markModified() {
        modifiedAt = Date()
    }

    // MARK: - Base Layer Helpers

    /// Whether this layer is the base layer (order == 0)
    var isBaseLayer: Bool {
        order == 0
    }

    /// Apply a fill to this layer
    func applyFill(_ fill: LayerFill?) {
        self.layerFill = fill
        markModified()
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case order
        case isVisible
        case isLocked
        case opacity
        case blendMode
        case layerType
        case drawingData
        case macosStrokesData
        case layerFill
        case createdAt
        case modifiedAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        order = try container.decode(Int.self, forKey: .order)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        isLocked = try container.decode(Bool.self, forKey: .isLocked)
        opacity = try container.decode(CGFloat.self, forKey: .opacity)
        blendMode = try container.decode(LayerBlendMode.self, forKey: .blendMode)
        layerType = try container.decode(LayerType.self, forKey: .layerType)
        layerFill = try? container.decode(LayerFill.self, forKey: .layerFill)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
        
        // Decode drawing data
        #if canImport(PencilKit)
        if let drawingData = try? container.decode(Data.self, forKey: .drawingData) {
            drawing = (try? PKDrawing(data: drawingData)) ?? PKDrawing()
        } else {
            drawing = PKDrawing()
        }
        #endif
        
        // Decode macOS strokes
        if let strokesData = try? container.decode(Data.self, forKey: .macosStrokesData) {
            let decoder = JSONDecoder()
            macosStrokes = (try? decoder.decode([DrawingStroke].self, from: strokesData)) ?? []
        } else {
            macosStrokes = []
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(order, forKey: .order)
        try container.encode(isVisible, forKey: .isVisible)
        try container.encode(isLocked, forKey: .isLocked)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(blendMode, forKey: .blendMode)
        try container.encode(layerType, forKey: .layerType)
        try container.encodeIfPresent(layerFill, forKey: .layerFill)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        
        // Encode drawing data
        #if canImport(PencilKit)
        let drawingData = drawing.dataRepresentation()
        try container.encode(drawingData, forKey: .drawingData)
        #endif
        
        // Encode macOS strokes
        let encoder = JSONEncoder()
        if let strokesData = try? encoder.encode(macosStrokes) {
            try container.encode(strokesData, forKey: .macosStrokesData)
        }
    }
}

// MARK: - Map Context

/// Context for filtering layer types based on map purpose
enum MapContext: String, CaseIterable {
    case world = "World/Region"
    case dungeon = "Dungeon"
    case building = "Building"
    case battle = "Battle Map"
    case all = "All Types"
}

// MARK: - Layer Type

/// Categorizes layers by their intended use, which affects available brushes
enum LayerType: String, CaseIterable, Codable, Identifiable {
    case terrain = "Terrain"
    case water = "Water Features"
    case vegetation = "Vegetation"
    case roads = "Roads & Paths"
    case structures = "Structures"
    case walls = "Walls"
    case features = "Features"
    case furniture = "Furniture"
    case annotations = "Annotations"
    case reference = "Reference"
    case generic = "Generic"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .terrain: return "mountain.2"
        case .water: return "drop.fill"
        case .vegetation: return "leaf.fill"
        case .roads: return "road.lanes"
        case .structures: return "building.2.fill"
        case .walls: return "rectangle.fill"
        case .features: return "circle.grid.3x3.fill"
        case .furniture: return "square.grid.2x2"
        case .annotations: return "text.bubble.fill"
        case .reference: return "photo.on.rectangle"
        case .generic: return "square.on.square"
        }
    }
    
    var description: String {
        switch self {
        case .terrain: return "Base terrain and geography"
        case .water: return "Rivers, lakes, oceans"
        case .vegetation: return "Forests, trees, plants"
        case .roads: return "Roads, paths, railroads"
        case .structures: return "Buildings, cities, castles"
        case .walls: return "Walls and barriers"
        case .features: return "Architectural features"
        case .furniture: return "Interior furniture"
        case .annotations: return "Text and symbols"
        case .reference: return "Non-exported reference images"
        case .generic: return "General purpose drawing"
        }
    }
    
    /// Which map contexts this layer type applies to
    var applicableContexts: Set<MapContext> {
        switch self {
        case .terrain, .water, .vegetation, .roads, .structures:
            return [.world, .all]
        case .walls, .features, .furniture:
            return [.dungeon, .building, .all]
        case .annotations, .reference, .generic:
            return Set(MapContext.allCases)
        }
    }
    
    /// Get layer types appropriate for a given map context
    static func types(for context: MapContext) -> [LayerType] {
        if context == .all {
            return LayerType.allCases
        }
        return LayerType.allCases.filter { $0.applicableContexts.contains(context) }
    }
}

// MARK: - Layer Blend Mode

/// Blend modes for layer compositing
enum LayerBlendMode: String, CaseIterable, Codable {
    case normal = "Normal"
    case multiply = "Multiply"
    case screen = "Screen"
    case overlay = "Overlay"
    case darken = "Darken"
    case lighten = "Lighten"
    case colorBurn = "Color Burn"
    case colorDodge = "Color Dodge"
    case softLight = "Soft Light"
    case hardLight = "Hard Light"
    case difference = "Difference"
    case exclusion = "Exclusion"
    case hue = "Hue"
    case saturation = "Saturation"
    case color = "Color"
    case luminosity = "Luminosity"
    
    /// Convert to Core Graphics blend mode
    var cgBlendMode: CGBlendMode {
        switch self {
        case .normal: return .normal
        case .multiply: return .multiply
        case .screen: return .screen
        case .overlay: return .overlay
        case .darken: return .darken
        case .lighten: return .lighten
        case .colorBurn: return .colorBurn
        case .colorDodge: return .colorDodge
        case .softLight: return .softLight
        case .hardLight: return .hardLight
        case .difference: return .difference
        case .exclusion: return .exclusion
        case .hue: return .hue
        case .saturation: return .saturation
        case .color: return .color
        case .luminosity: return .luminosity
        }
    }
}

// MARK: - Drawing Stroke (macOS)

/// Native stroke data for macOS drawing (shared with DrawingCanvasViewMacOS)
struct DrawingStroke: Codable {
    var points: [CGPointCodable]
    var colorRed: CGFloat
    var colorGreen: CGFloat
    var colorBlue: CGFloat
    var colorAlpha: CGFloat
    var lineWidth: CGFloat
    var toolType: String

    // DR-0031: Store brush metadata for advanced rendering
    var brushID: UUID?  // Optional for backward compatibility

    #if os(macOS)
    /// Convert to NSColor for rendering
    var color: NSColor {
        NSColor(red: colorRed, green: colorGreen, blue: colorBlue, alpha: colorAlpha)
    }

    /// Convert points to CGPoint array
    var cgPoints: [CGPoint] {
        points.map { CGPoint(x: $0.x, y: $0.y) }
    }
    #endif
}

struct CGPointCodable: Codable {
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Layer Extension for Preview

extension DrawingLayer {
    /// Create a sample layer for previews
    static func sample(name: String, type: LayerType) -> DrawingLayer {
        DrawingLayer(name: name, layerType: type)
    }
}
