//
//  TerrainMapMetadata.swift
//  BrushEngine
//
//  Map scale and generation parameters for procedural terrain-based maps
//

import Foundation
import SwiftUI

// MARK: - Map Scale Category

/// Map scale categories that determine terrain distribution percentages
public enum MapScaleCategory: String, Codable {
    case small = "Small"      // < 10 miles (village/battlefield)
    case medium = "Medium"    // 10-100 miles (city/region)
    case large = "Large"      // > 100 miles (continent/world)

    /// Percentage of dominant terrain type for this scale
    /// Small scale: 80-90% selected type (85% average)
    /// Medium scale: 70-80% selected type (75% average)
    /// Large scale: 55-70% selected type (62.5% average)
    public var dominantPercentage: Double {
        switch self {
        case .small: return 0.85  // 85% dominant, 15% variety
        case .medium: return 0.75 // 75% dominant, 25% variety
        case .large: return 0.625 // 62.5% dominant, 37.5% variety
        }
    }

    /// Categorize a physical distance into a scale category
    public static func categorize(miles: Double) -> MapScaleCategory {
        if miles < 10 { return .small }
        if miles < 100 { return .medium }
        return .large
    }

    /// Short label for UI display
    public var displayName: String { rawValue }
}

// MARK: - Terrain Map Metadata

/// Stores physical scale and generation parameters for terrain-based maps
/// This metadata determines how procedural terrain is generated and distributed
public struct TerrainMapMetadata: Codable, Equatable {
    /// Physical size of the map in miles
    public var physicalSizeMiles: Double

    /// Map scale category (affects terrain distribution)
    public var scaleCategory: MapScaleCategory

    /// Percentage of canvas that should be the dominant terrain type
    /// Derived from scaleCategory but stored for quick access
    public var dominantTerrainPercentage: Double

    /// Seed for terrain generation (ensures consistency across sessions)
    /// Same seed + same parameters = identical terrain pattern
    public var terrainSeed: Int

    /// Optional water percentage override (0.01 to 0.90)
    /// If set, overrides the default water percentage for the terrain type
    /// For water terrain type, this represents land percentage instead (inverted)
    public var waterPercentageOverride: Double?

    /// Initialize with physical size in miles
    /// - Parameters:
    ///   - physicalSizeMiles: The width/extent of the map in miles
    ///   - terrainSeed: Optional seed for reproducible generation (random if nil)
    public init(physicalSizeMiles: Double, terrainSeed: Int? = nil) {
        self.physicalSizeMiles = physicalSizeMiles
        self.scaleCategory = MapScaleCategory.categorize(miles: physicalSizeMiles)
        self.dominantTerrainPercentage = scaleCategory.dominantPercentage
        self.terrainSeed = terrainSeed ?? Int.random(in: 1...999999)
    }

    /// Convenience initializer for unit tests and debugging
    public init(scaleCategory: MapScaleCategory, terrainSeed: Int) {
        switch scaleCategory {
        case .small:
            self.physicalSizeMiles = 5.0  // Representative small scale
        case .medium:
            self.physicalSizeMiles = 50.0 // Representative medium scale
        case .large:
            self.physicalSizeMiles = 500.0 // Representative large scale
        }
        self.scaleCategory = scaleCategory
        self.dominantTerrainPercentage = scaleCategory.dominantPercentage
        self.terrainSeed = terrainSeed
    }
}

// MARK: - Helper Extensions

extension TerrainMapMetadata: CustomStringConvertible {
    public var description: String {
        return "TerrainMapMetadata(size: \(physicalSizeMiles)mi, scale: \(scaleCategory.displayName), dominant: \(Int(dominantTerrainPercentage * 100))%, seed: \(terrainSeed))"
    }
}
