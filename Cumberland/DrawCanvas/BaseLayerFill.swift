//
//  BaseLayerFill.swift
//  Cumberland
//
//  Base layer fill system for quick map background establishment
//

import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

// MARK: - Base Layer Category

/// Category for grouping fill types by use case
enum BaseLayerCategory: String, Codable {
    case exterior = "Exterior"
    case interior = "Interior"

    var displayName: String { rawValue }
}

// MARK: - Base Layer Fill Type

/// Predefined fill types for map base layers
enum BaseLayerFillType: String, CaseIterable, Codable, Identifiable {
    // Exterior terrain types
    case land = "Land"
    case water = "Water"
    case sandy = "Sandy"
    case rocky = "Rocky"
    case snow = "Snow"
    case ice = "Ice"
    case forested = "Forested"
    case mountain = "Mountain"

    // Interior floor types
    case tile = "Tile"
    case stone = "Stone"
    case wood = "Wood"
    case slate = "Slate"
    case cobbles = "Cobbles"
    case concrete = "Concrete"
    case metal = "Metal"

    var id: String { rawValue }

    /// Category this fill type belongs to
    var category: BaseLayerCategory {
        switch self {
        case .land, .water, .sandy, .rocky, .snow, .ice, .forested, .mountain:
            return .exterior
        case .tile, .stone, .wood, .slate, .cobbles, .concrete, .metal:
            return .interior
        }
    }

    /// Target water percentage for this terrain type
    /// Determines how much of the elevation map will be below sea level (negative values)
    var waterPercentage: Double {
        switch self {
        case .sandy: return 0.02      // 2% water - desert/beach
        case .rocky: return 0.05      // 5% water - rocky badlands
        case .mountain: return 0.07   // 7% water - mountain ranges
        case .snow: return 0.15       // 15% water - tundra/glacial
        case .land: return 0.40       // 40% water - grasslands/plains
        case .forested: return 0.60   // 60% water - forest/jungle
        case .ice: return 0.66        // 66% water - arctic/ice sheets
        case .water: return 0.90      // 90% water - ocean/archipelago
        // Interior types don't use water percentage
        default: return 0.0
        }
    }

    /// Default color for this fill type
    var defaultColor: Color {
        switch self {
        // Exterior colors
        case .land:
            return Color(red: 0.4, green: 0.7, blue: 0.3) // Grass green
        case .water:
            return Color(red: 0.2, green: 0.5, blue: 0.8) // Ocean blue
        case .sandy:
            return Color(red: 0.76, green: 0.7, blue: 0.5) // Khaki/sand
        case .rocky:
            return Color(red: 0.4, green: 0.26, blue: 0.13) // Dark brown
        case .snow:
            return Color(red: 0.95, green: 0.95, blue: 0.98) // Off-white
        case .ice:
            return Color(red: 0.53, green: 0.81, blue: 0.92) // Electric blue
        case .forested:
            return Color(red: 0.2, green: 0.5, blue: 0.2) // Dark forest green
        case .mountain:
            return Color(red: 0.45, green: 0.35, blue: 0.3) // Rocky brown-gray

        // Interior colors
        case .tile:
            return Color(red: 0.9, green: 0.9, blue: 0.85) // Cream tile
        case .stone:
            return Color(red: 0.5, green: 0.5, blue: 0.52) // Gray stone
        case .wood:
            return Color(red: 0.55, green: 0.4, blue: 0.25) // Brown wood
        case .slate:
            return Color(red: 0.3, green: 0.35, blue: 0.4) // Dark gray-blue
        case .cobbles:
            return Color(red: 0.45, green: 0.42, blue: 0.4) // Gray-brown
        case .concrete:
            return Color(red: 0.65, green: 0.65, blue: 0.65) // Light gray
        case .metal:
            return Color(red: 0.7, green: 0.72, blue: 0.75) // Silvery gray
        }
    }

    /// Display name for UI
    var displayName: String { rawValue }

    /// SF Symbol icon representing this fill type
    var icon: String {
        switch self {
        // Exterior icons
        case .land:
            return "leaf.fill"
        case .water:
            return "drop.fill"
        case .sandy:
            return "circle.dotted"
        case .rocky:
            return "mountain.2.fill"
        case .snow:
            return "snowflake"
        case .ice:
            return "snowflake.circle.fill"
        case .forested:
            return "tree.fill"
        case .mountain:
            return "mountain.2.fill"

        // Interior icons
        case .tile:
            return "square.grid.3x3.fill"
        case .stone:
            return "square.fill"
        case .wood:
            return "rectangle.fill"
        case .slate:
            return "square.slash.fill"
        case .cobbles:
            return "circle.grid.3x3.fill"
        case .concrete:
            return "square.on.square"
        case .metal:
            return "rectangle.3.group.fill"
        }
    }

    /// Get all fill types for a specific category
    static func types(for category: BaseLayerCategory) -> [BaseLayerFillType] {
        allCases.filter { $0.category == category }
    }

    /// Get exterior fill types
    static var exteriorTypes: [BaseLayerFillType] {
        types(for: .exterior)
    }

    /// Get interior fill types
    static var interiorTypes: [BaseLayerFillType] {
        types(for: .interior)
    }
}

// MARK: - Layer Fill

/// Represents a fill applied to a layer (typically the base layer)
struct LayerFill: Codable, Equatable {
    /// The type of fill
    var fillType: BaseLayerFillType

    /// Custom color override (if nil, uses fillType.defaultColor)
    var customColor: LayerFillColor?

    /// Fill opacity (0.0 to 1.0)
    var opacity: CGFloat = 1.0

    /// Seed for procedural pattern generation (ensures consistent patterns)
    var patternSeed: Int = 12345

    /// Optional terrain metadata for procedural exterior generation
    var terrainMetadata: TerrainMapMetadata?

    /// The effective color to use for rendering
    var effectiveColor: Color {
        customColor?.toColor() ?? fillType.defaultColor
    }

    /// Whether this fill type uses procedural patterns (interior types only)
    var usesProceduralPattern: Bool {
        fillType.category == .interior
    }

    /// Whether this fill type uses procedural terrain generation (exterior types with metadata)
    var usesProceduralTerrain: Bool {
        fillType.category == .exterior && terrainMetadata != nil
    }

    /// Initialize with a fill type
    init(fillType: BaseLayerFillType, customColor: LayerFillColor? = nil, opacity: CGFloat = 1.0, patternSeed: Int? = nil, terrainMetadata: TerrainMapMetadata? = nil) {
        self.fillType = fillType
        self.customColor = customColor
        self.opacity = opacity
        self.patternSeed = patternSeed ?? Int.random(in: 1...999999)
        self.terrainMetadata = terrainMetadata
    }

    /// Initialize with a fill type and SwiftUI Color
    init(fillType: BaseLayerFillType, color: Color? = nil, opacity: CGFloat = 1.0, patternSeed: Int? = nil, terrainMetadata: TerrainMapMetadata? = nil) {
        self.fillType = fillType
        self.customColor = color.map { LayerFillColor(from: $0) }
        self.opacity = opacity
        self.patternSeed = patternSeed ?? Int.random(in: 1...999999)
        self.terrainMetadata = terrainMetadata
    }

    // Custom Codable to encode CGFloat opacity as Double for robustness
    private enum CodingKeys: String, CodingKey {
        case fillType
        case customColor
        case opacity
        case patternSeed
        case terrainMetadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fillType = try container.decode(BaseLayerFillType.self, forKey: .fillType)
        self.customColor = try container.decodeIfPresent(LayerFillColor.self, forKey: .customColor)
        // Decode opacity as Double, then cast to CGFloat
        let opacityDouble = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
        self.opacity = CGFloat(opacityDouble)
        self.patternSeed = try container.decodeIfPresent(Int.self, forKey: .patternSeed) ?? 12345
        self.terrainMetadata = try container.decodeIfPresent(TerrainMapMetadata.self, forKey: .terrainMetadata)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fillType, forKey: .fillType)
        try container.encodeIfPresent(customColor, forKey: .customColor)
        // Encode opacity as Double to avoid CGFloat Codable issues across platforms
        try container.encode(Double(opacity), forKey: .opacity)
        try container.encode(patternSeed, forKey: .patternSeed)
        try container.encodeIfPresent(terrainMetadata, forKey: .terrainMetadata)
    }
}

// MARK: - Layer Fill Color

/// Platform-agnostic color representation for layer fills
struct LayerFillColor: Codable, Equatable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

    /// Initialize with RGBA components
    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Initialize from SwiftUI Color
    init(from color: Color) {
        // Convert to platform color to extract components
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        // Try to get RGBA components
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            self.red = r
            self.green = g
            self.blue = b
            self.alpha = a
        } else {
            // Fallback to black if conversion fails
            self.red = 0
            self.green = 0
            self.blue = 0
            self.alpha = 1
        }

        #elseif os(macOS)
        // Convert to sRGB color space for reliable component extraction
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.black
        self.red = nsColor.redComponent
        self.green = nsColor.greenComponent
        self.blue = nsColor.blueComponent
        self.alpha = nsColor.alphaComponent

        #else
        // Fallback for other platforms
        self.red = 0
        self.green = 0
        self.blue = 0
        self.alpha = 1
        #endif
    }

    /// Convert to SwiftUI Color
    func toColor() -> Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    #if canImport(UIKit)
    /// Convert to UIColor
    func toUIColor() -> UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    #endif

    #if os(macOS)
    /// Convert to NSColor
    func toNSColor() -> NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    #endif
}

// MARK: - Preview Helpers

#if DEBUG
extension LayerFill {
    /// Sample water fill for previews
    static var sampleWater: LayerFill {
        LayerFill(fillType: .water, customColor: nil, opacity: 1.0)
    }

    /// Sample land fill for previews
    static var sampleLand: LayerFill {
        LayerFill(fillType: .land, customColor: nil, opacity: 1.0)
    }

    /// Sample stone floor for previews
    static var sampleStone: LayerFill {
        LayerFill(fillType: .stone, customColor: nil, opacity: 1.0)
    }
}
#endif
