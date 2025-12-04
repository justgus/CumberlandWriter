//
//  MapBrush.swift
//  Cumberland
//
//  Brush model and properties for map drawing
//

import SwiftUI
import Foundation

// MARK: - Map Brush

/// Defines a single brush with rendering properties for map creation
struct MapBrush: Identifiable, Codable, Hashable {
    // MARK: - Identity
    
    let id: UUID
    var name: String
    var icon: String // SF Symbol name
    var category: BrushCategory
    
    // MARK: - Visual Properties
    
    /// Optional base color (nil = use user-selected color)
    var baseColor: CodableColor?
    
    /// Default stroke width
    var defaultWidth: CGFloat
    
    /// Minimum allowed width
    var minWidth: CGFloat
    
    /// Maximum allowed width
    var maxWidth: CGFloat
    
    // MARK: - Behavior Properties
    
    /// Brush opacity (0.0 to 1.0)
    var opacity: CGFloat
    
    /// Blend mode for rendering
    var blendMode: LayerBlendMode
    
    /// Whether brush responds to pressure (Apple Pencil, pressure-sensitive tablets)
    var pressureSensitivity: Bool
    
    /// Taper stroke at the beginning
    var taperStart: Bool
    
    /// Taper stroke at the end
    var taperEnd: Bool
    
    // MARK: - Pattern/Texture Properties
    
    /// Pattern rendering type
    var patternType: BrushPattern
    
    /// Optional texture image data
    var textureImage: Data?
    
    /// Spacing between stamps/pattern repetitions (for non-continuous brushes)
    var spacing: CGFloat
    
    /// Random scatter amount (0.0 = no scatter)
    var scatterAmount: CGFloat
    
    /// Rotation randomization (in degrees)
    var rotationVariation: CGFloat
    
    /// Size randomization (0.0 to 1.0, multiplied by width)
    var sizeVariation: CGFloat
    
    // MARK: - Constraints & Behavior
    
    /// Layer type this brush is optimized for (nil = any layer)
    var requiresLayer: LayerType?
    
    /// Whether brush snaps to grid
    var snapToGrid: Bool
    
    /// Path smoothing amount (0.0 = no smoothing, 1.0 = maximum)
    var smoothing: CGFloat
    
    /// Whether this is a built-in brush (cannot be deleted)
    var isBuiltIn: Bool
    
    // MARK: - Metadata
    
    var createdAt: Date
    var modifiedAt: Date
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "paintbrush.fill",
        category: BrushCategory,
        baseColor: Color? = nil,
        defaultWidth: CGFloat = 5.0,
        minWidth: CGFloat = 1.0,
        maxWidth: CGFloat = 50.0,
        opacity: CGFloat = 1.0,
        blendMode: LayerBlendMode = .normal,
        pressureSensitivity: Bool = true,
        taperStart: Bool = false,
        taperEnd: Bool = false,
        patternType: BrushPattern = .solid,
        textureImage: Data? = nil,
        spacing: CGFloat = 5.0,
        scatterAmount: CGFloat = 0.0,
        rotationVariation: CGFloat = 0.0,
        sizeVariation: CGFloat = 0.0,
        requiresLayer: LayerType? = nil,
        snapToGrid: Bool = false,
        smoothing: CGFloat = 0.5,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.category = category
        self.baseColor = baseColor.map { CodableColor(color: $0) }
        self.defaultWidth = defaultWidth
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.opacity = opacity
        self.blendMode = blendMode
        self.pressureSensitivity = pressureSensitivity
        self.taperStart = taperStart
        self.taperEnd = taperEnd
        self.patternType = patternType
        self.textureImage = textureImage
        self.spacing = spacing
        self.scatterAmount = scatterAmount
        self.rotationVariation = rotationVariation
        self.sizeVariation = sizeVariation
        self.requiresLayer = requiresLayer
        self.snapToGrid = snapToGrid
        self.smoothing = smoothing
        self.isBuiltIn = isBuiltIn
        
        let now = Date()
        self.createdAt = now
        self.modifiedAt = now
    }
    
    // MARK: - Convenience Properties
    
    /// Get the base color as a SwiftUI Color
    var color: Color? {
        baseColor?.toColor()
    }
    
    /// Whether this brush has custom texture
    var hasTexture: Bool {
        textureImage != nil
    }
    
    /// Whether this brush uses pattern rendering
    var usesPattern: Bool {
        patternType != .solid
    }
    
    // MARK: - Modification
    
    /// Create a copy with updated properties
    func modified(
        name: String? = nil,
        defaultWidth: CGFloat? = nil,
        opacity: CGFloat? = nil,
        baseColor: Color? = nil
    ) -> MapBrush {
        var copy = self
        if let name = name { copy.name = name }
        if let width = defaultWidth { copy.defaultWidth = width }
        if let opacity = opacity { copy.opacity = opacity }
        if let color = baseColor { copy.baseColor = CodableColor(color: color) }
        copy.modifiedAt = Date()
        return copy
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MapBrush, rhs: MapBrush) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Brush Category

/// Categorizes brushes by their intended use
enum BrushCategory: String, CaseIterable, Codable, Identifiable {
    case basic = "Basic"
    case terrain = "Terrain"
    case water = "Water Features"
    case roads = "Roads & Paths"
    case vegetation = "Vegetation"
    case structures = "Structures"
    case architectural = "Architectural"
    case symbols = "Symbols"
    case text = "Text & Labels"
    case effects = "Effects"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .basic: return "paintbrush.fill"
        case .terrain: return "mountain.2.fill"
        case .water: return "drop.fill"
        case .roads: return "road.lanes"
        case .vegetation: return "leaf.fill"
        case .structures: return "building.2.fill"
        case .architectural: return "square.grid.3x3.fill"
        case .symbols: return "star.fill"
        case .text: return "textformat"
        case .effects: return "sparkles"
        }
    }
    
    var description: String {
        switch self {
        case .basic: return "General purpose drawing tools"
        case .terrain: return "Mountains, hills, valleys"
        case .water: return "Rivers, lakes, oceans"
        case .roads: return "Roads, paths, trails"
        case .vegetation: return "Trees, forests, plants"
        case .structures: return "Buildings, cities, castles"
        case .architectural: return "Walls, doors, windows"
        case .symbols: return "Icons and markers"
        case .text: return "Text and labels"
        case .effects: return "Special effects and overlays"
        }
    }
}

// MARK: - Brush Pattern

/// Defines how a brush renders its stroke
enum BrushPattern: String, CaseIterable, Codable, Hashable {
    case solid = "Solid"
    case dashed = "Dashed"
    case dotted = "Dotted"
    case stippled = "Stippled"
    case textured = "Textured"
    case stamp = "Stamp"
    case hatched = "Hatched"
    case crossHatched = "Cross-Hatched"
    
    var description: String {
        switch self {
        case .solid: return "Continuous solid line"
        case .dashed: return "Dashed line pattern"
        case .dotted: return "Dotted line pattern"
        case .stippled: return "Random stipple texture"
        case .textured: return "Custom texture pattern"
        case .stamp: return "Repeated stamp (for symbols)"
        case .hatched: return "Single-direction hatching"
        case .crossHatched: return "Cross-direction hatching"
        }
    }
}

// MARK: - Codable Color

/// A Codable wrapper for SwiftUI Color
struct CodableColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    
    init(color: Color) {
        // Convert Color to components
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
        #elseif canImport(AppKit)
        let nsColor = NSColor(color)
        if let rgbColor = nsColor.usingColorSpace(.deviceRGB) {
            self.red = Double(rgbColor.redComponent)
            self.green = Double(rgbColor.greenComponent)
            self.blue = Double(rgbColor.blueComponent)
            self.opacity = Double(rgbColor.alphaComponent)
        } else {
            // Fallback
            self.red = 0
            self.green = 0
            self.blue = 0
            self.opacity = 1
        }
        #else
        self.red = 0
        self.green = 0
        self.blue = 0
        self.opacity = 1
        #endif
    }
    
    func toColor() -> Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
    
    #if canImport(UIKit)
    func toUIColor() -> UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: opacity)
    }
    #endif
    
    #if canImport(AppKit)
    func toNSColor() -> NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: opacity)
    }
    #endif
}

// MARK: - Brush Extensions

extension MapBrush {
    /// Create a sample brush for previews/testing
    static func sample(
        name: String = "Sample Brush",
        category: BrushCategory = .basic,
        pattern: BrushPattern = .solid
    ) -> MapBrush {
        MapBrush(
            name: name,
            category: category,
            patternType: pattern
        )
    }
    
    /// Default basic pen brush
    static var basicPen: MapBrush {
        MapBrush(
            name: "Pen",
            icon: "pencil",
            category: .basic,
            defaultWidth: 3.0,
            isBuiltIn: true
        )
    }
    
    /// Default marker brush
    static var marker: MapBrush {
        MapBrush(
            name: "Marker",
            icon: "highlighter",
            category: .basic,
            defaultWidth: 10.0,
            opacity: 0.5,
            isBuiltIn: true
        )
    }
    
    /// Default pencil brush
    static var pencil: MapBrush {
        MapBrush(
            name: "Pencil",
            icon: "pencil.tip",
            category: .basic,
            defaultWidth: 2.0,
            opacity: 0.8,
            patternType: .stippled,
            isBuiltIn: true
        )
    }
}
