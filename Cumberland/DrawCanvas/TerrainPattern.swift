//
//  TerrainPattern.swift
//  Cumberland
//
//  Procedural pattern generator for elevation-based terrain
//  Renders realistic terrain with biome distribution and color variation
//

import SwiftUI
import Foundation
import CoreGraphics

#if canImport(UIKit)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

// MARK: - Terrain Pattern

/// Procedural pattern generator for elevation-based terrain
/// NEW SYSTEM: Uses continuous elevation (-1 to 1) with water percentage skewing
/// Water (< 0) rendered in blues, land (≥ 0) in terrain-specific colors
struct TerrainPattern: ProceduralPattern {
    let metadata: TerrainMapMetadata
    let dominantFillType: BaseLayerFillType

    func draw(in context: CGContext, rect: CGRect, seed: Int, baseColor: Color, mapScale: Double?) {
        // DR-0019: mapScale parameter added for protocol compliance (terrain uses metadata.physicalSizeMiles)
        let width = Int(rect.width)
        let height = Int(rect.height)

        guard width > 0, height > 0 else { return }

        // Generate elevation map (downsample for performance on large canvases)
        // Use 512x512 elevation map regardless of canvas size for bounded memory usage
        let samplingFactor = max(1, min(width, height) / 512)
        let elevationWidth = width / samplingFactor
        let elevationHeight = height / samplingFactor

        print("[TerrainPattern] Generating \(elevationWidth)×\(elevationHeight) elevation map for \(width)×\(height) canvas")

        // Determine water percentage (use override if present, otherwise use terrain type default)
        // For water terrain type, the override represents land % (inverted)
        let waterPercentage: Double
        if let override = metadata.waterPercentageOverride {
            if dominantFillType == .water {
                // Invert for water type - slider controls land instead of water
                waterPercentage = 1.0 - override
            } else {
                waterPercentage = override
            }
        } else {
            waterPercentage = dominantFillType.waterPercentage
        }

        print("[TerrainPattern] Terrain type: \(dominantFillType.displayName), Water target: \(Int(waterPercentage * 100))%\(metadata.waterPercentageOverride != nil ? " (override)" : "")")

        // Calculate noise detail based on map scale
        // Small maps: Less variance (smoother terrain)
        // Large maps: More variance (more complex features)
        let (noiseScale, octaves) = calculateNoiseParameters(physicalSizeMiles: metadata.physicalSizeMiles)
        print("[TerrainPattern] Noise parameters: scale=\(String(format: "%.2f", noiseScale)), octaves=\(octaves)")

        // Generate elevation map with water percentage skewing
        let elevationMap = ElevationMap(
            width: elevationWidth,
            height: elevationHeight,
            seed: metadata.terrainSeed,
            waterPercentage: waterPercentage,
            scale: noiseScale,
            octaves: octaves
        )

        // Calculate world elevation scale based on map size
        let worldScale = calculateWorldElevationScale(physicalSizeMiles: metadata.physicalSizeMiles)
        print("[TerrainPattern] World elevation scale: ±\(String(format: "%.2f", worldScale)) miles")

        // Noise generator for subtle texture variation
        let textureNoise = NoiseGenerator(seed: seed + 1000)

        // Track statistics
        var waterPixels = 0
        var landPixels = 0
        var sampleCount = 0

        // Render terrain pixel by pixel
        // Use 2x2 pixel blocks for 4x performance improvement
        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                // Sample elevation (with interpolation for smoothness)
                let elevX = Double(x) / Double(width) * Double(elevationWidth)
                let elevY = Double(y) / Double(height) * Double(elevationHeight)
                let elevation = elevationMap.elevationInterpolated(
                    at: CGPoint(x: elevX, y: elevY)
                )

                // Get subtle noise for texture variation
                let noiseVal = textureNoise.noise2D(x: Double(x) / 100.0, y: Double(y) / 100.0)

                // Determine final color based on elevation and terrain type
                let finalColor: Color
                if elevation < 0 {
                    // Water - darker blue for deeper water
                    finalColor = colorForWater(depth: -elevation, noise: noiseVal)
                    waterPixels += 1
                } else {
                    // Land - terrain-specific composition based on elevation
                    finalColor = colorForTerrainComposition(
                        terrainType: dominantFillType,
                        elevation: elevation,
                        noise: noiseVal
                    )
                    landPixels += 1
                }
                sampleCount += 1

                // Draw pixel block (2x2 for performance)
                let platformColor = Self.platformColor(from: finalColor)
                context.setFillColor(platformColor.cgColor)
                context.fill(CGRect(x: x, y: y, width: 2, height: 2))
            }
        }

        // Print statistics
        let waterPct = Double(waterPixels) / Double(sampleCount) * 100.0
        let landPct = Double(landPixels) / Double(sampleCount) * 100.0
        print("[TerrainPattern] Rendering complete:")
        print("  - Water: \(waterPixels) pixels (\(String(format: "%.1f", waterPct))%)")
        print("  - Land: \(landPixels) pixels (\(String(format: "%.1f", landPct))%)")
    }

    /// Calculate world elevation scale constant based on map physical size
    /// Continental (≥1000 mi): ±6 miles
    /// State (100-1000 mi): Parabolic 6→1 miles
    /// Small (1-100 mi): Parabolic 1→0 miles
    private func calculateWorldElevationScale(physicalSizeMiles: Double) -> Double {
        if physicalSizeMiles >= 1000 {
            // Continental scale
            return 6.0
        } else if physicalSizeMiles >= 100 {
            // State scale: parabolic from 6.0 (at 1000 mi) to 1.0 (at 100 mi)
            let t = (physicalSizeMiles - 100) / 900  // Normalize to 0-1
            return 1.0 + 5.0 * t * t  // Quadratic easing
        } else {
            // Small scale: parabolic from 1.0 (at 100 mi) to 0.0 (at 1 mi)
            let t = (physicalSizeMiles - 1) / 99
            return 1.0 * t * t
        }
    }

    /// Calculate noise parameters based on map physical size
    /// Small maps: Less detail, smoother terrain
    /// Large maps: More detail, complex features
    /// Returns: (scale, octaves)
    private func calculateNoiseParameters(physicalSizeMiles: Double) -> (Double, Int) {
        if physicalSizeMiles >= 1000 {
            // Continental: Maximum detail and complexity
            return (2.0, 7)  // High frequency, many octaves
        } else if physicalSizeMiles >= 100 {
            // State/Regional: Moderate detail
            // Scale from 1.0 to 2.0, octaves from 5 to 7
            let t = (physicalSizeMiles - 100) / 900  // Normalize to 0-1
            let scale = 1.0 + t  // Linear 1.0 → 2.0
            let octaves = 5 + Int(t * 2)  // 5 → 7
            return (scale, octaves)
        } else {
            // Small/Local: Minimal detail, smooth terrain
            // Scale from 0.3 to 1.0, octaves from 3 to 5
            let t = (physicalSizeMiles - 1) / 99
            let scale = 0.3 + (t * 0.7)  // 0.3 → 1.0
            let octaves = 3 + Int(t * 2)  // 3 → 5
            return (scale, octaves)
        }
    }

    /// Get mean color for a terrain type
    private func meanColorFor(terrainType: BaseLayerFillType) -> Color {
        switch terrainType {
        case .sandy:
            return Color(red: 0.90, green: 0.75, blue: 0.50)  // Tan
        case .rocky:
            return Color(red: 0.35, green: 0.25, blue: 0.20)  // Dark brown
        case .mountain:
            return Color(red: 0.30, green: 0.25, blue: 0.20)  // Darker brown
        case .snow:
            return Color(red: 0.95, green: 0.95, blue: 0.95)  // White/grey
        case .land:
            return Color(red: 0.45, green: 0.70, blue: 0.30)  // Green
        case .forested:
            return Color(red: 0.15, green: 0.45, blue: 0.30)  // Blue-green/teal forest
        case .ice:
            return Color(red: 0.70, green: 0.85, blue: 0.95)  // Light blue
        case .water:
            return Color(red: 0.20, green: 0.50, blue: 0.80)  // Blue (for islands/land in water maps)
        default:
            return terrainType.defaultColor
        }
    }

    /// Calculate water color based on depth
    /// Deeper water (depth closer to 1.0) = darker blue
    private func colorForWater(depth: Double, noise: Double) -> Color {
        // Base water color (medium blue)
        let baseHue: Double = 0.55      // Blue hue (0-1 scale)
        let baseSaturation: Double = 0.70

        // Depth affects brightness: shallow (0.0) = light, deep (1.0) = dark
        // Map depth 0.0-1.0 to brightness 0.7-0.3
        let depthBrightness = 0.7 - (depth * 0.4)

        // Add subtle noise variation
        let noiseBrightness = 1.0 + (noise * 0.05)  // ±5%
        let finalBrightness = (depthBrightness * noiseBrightness).clamped(to: 0.2...0.8)

        return Color(hue: baseHue, saturation: baseSaturation, brightness: finalBrightness)
    }

    /// Calculate terrain color based on terrain type and elevation
    /// Each terrain type has its own composition profile with elevation-based zones
    private func colorForTerrainComposition(terrainType: BaseLayerFillType, elevation: Double, noise: Double) -> Color {
        // elevation is 0.0 (sea level) to 1.0 (peak)

        switch terrainType {
        case .water:
            // Ocean/Archipelago - mostly handled by water%, but islands appear on land
            return compositionWaterType(elevation: elevation, noise: noise)

        case .land:
            // Grasslands/Plains
            return compositionLandType(elevation: elevation, noise: noise)

        case .sandy:
            // Desert
            return compositionSandyType(elevation: elevation, noise: noise)

        case .forested:
            // Forest/Jungle
            return compositionForestedType(elevation: elevation, noise: noise)

        case .mountain:
            // Alpine/Mountain ranges
            return compositionMountainType(elevation: elevation, noise: noise)

        case .snow:
            // Tundra/Glacial
            return compositionSnowType(elevation: elevation, noise: noise)

        case .rocky:
            // Rocky badlands
            return compositionRockyType(elevation: elevation, noise: noise)

        case .ice:
            // Arctic/Ice sheets
            return compositionIceType(elevation: elevation, noise: noise)

        default:
            // Fallback for interior types or unknown
            let baseColor = meanColorFor(terrainType: terrainType)
            return baseColor.adjusted(brightness: 1.15 - (elevation * 0.30) + (noise * 0.05))
        }
    }

    // MARK: - Terrain Composition Profiles

    /// Water terrain: Islands with sandy beaches
    private func compositionWaterType(elevation: Double, noise: Double) -> Color {
        if elevation < 0.1 {
            // Sandy beach
            return Color(red: 0.90, green: 0.75, blue: 0.50).adjusted(brightness: 1.0 + noise * 0.05)
        } else {
            // Green island interior (darker at higher elevations)
            let green = Color(red: 0.45, green: 0.70, blue: 0.30)
            return green.adjusted(brightness: 1.15 - (elevation * 0.30) + (noise * 0.05))
        }
    }

    /// Land terrain: Lakes/rivers with beaches and grasslands
    private func compositionLandType(elevation: Double, noise: Double) -> Color {
        // ER-0007: Standardized threshold to 0.1 for consistency with all terrain types
        if elevation < 0.1 {
            // Sandy shores/beaches
            return Color(red: 0.90, green: 0.75, blue: 0.50).adjusted(brightness: 1.0 + noise * 0.05)
        } else {
            // Grasslands (darker green at higher elevations)
            let green = Color(red: 0.45, green: 0.70, blue: 0.30)
            return green.adjusted(brightness: 1.15 - (elevation * 0.30) + (noise * 0.05))
        }
    }

    /// Sandy terrain: Desert with rocky outcrops and rare peaks
    private func compositionSandyType(elevation: Double, noise: Double) -> Color {
        if elevation < 0.7 {
            // Sandy desert (dominant)
            return Color(red: 0.90, green: 0.75, blue: 0.50).adjusted(brightness: 1.1 - (elevation * 0.20) + (noise * 0.05))
        } else if elevation < 0.9 {
            // Rocky outcrops
            return Color(red: 0.45, green: 0.35, blue: 0.30).adjusted(brightness: 1.0 + noise * 0.05)
        } else {
            // Mountain peaks
            return Color(red: 0.30, green: 0.25, blue: 0.20).adjusted(brightness: 0.9 + noise * 0.05)
        }
    }

    /// Forested terrain: Rivers/lakes with shores and dense forest
    private func compositionForestedType(elevation: Double, noise: Double) -> Color {
        // ER-0007: Standardized threshold to 0.1 for consistency with all terrain types
        if elevation < 0.1 {
            // Sandy shores
            return Color(red: 0.90, green: 0.75, blue: 0.50).adjusted(brightness: 1.0 + noise * 0.05)
        } else if elevation < 0.2 {
            // Land clearings
            return Color(red: 0.45, green: 0.70, blue: 0.30).adjusted(brightness: 1.1 + noise * 0.05)
        } else {
            // Dense forest (darker at higher elevations)
            let forest = Color(red: 0.15, green: 0.45, blue: 0.30)
            return forest.adjusted(brightness: 1.15 - (elevation * 0.30) + (noise * 0.05))
        }
    }

    /// Mountain terrain: Valleys to rocky peaks
    private func compositionMountainType(elevation: Double, noise: Double) -> Color {
        if elevation < 0.2 {
            // Forest/land in valleys
            return Color(red: 0.15, green: 0.45, blue: 0.30).adjusted(brightness: 1.1 + noise * 0.05)
        } else if elevation < 0.5 {
            // Land foothills
            return Color(red: 0.45, green: 0.70, blue: 0.30).adjusted(brightness: 1.1 - (elevation * 0.15) + (noise * 0.05))
        } else if elevation < 0.8 {
            // Rocky mountainsides
            return Color(red: 0.45, green: 0.35, blue: 0.30).adjusted(brightness: 1.0 - (elevation * 0.15) + (noise * 0.05))
        } else {
            // Mountain peaks (dark brown/gray)
            return Color(red: 0.30, green: 0.25, blue: 0.20).adjusted(brightness: 0.9 + noise * 0.05)
        }
    }

    /// Snow terrain: Tundra with snow and ice
    private func compositionSnowType(elevation: Double, noise: Double) -> Color {
        if elevation < 0.3 {
            // Rocky tundra ground
            return Color(red: 0.45, green: 0.40, blue: 0.35).adjusted(brightness: 1.0 + noise * 0.05)
        } else if elevation < 0.6 {
            // Snowfields
            return Color(red: 0.95, green: 0.95, blue: 0.98).adjusted(brightness: 1.0 + noise * 0.03)
        } else if elevation < 0.9 {
            // Ice/glaciers
            return Color(red: 0.70, green: 0.85, blue: 0.95).adjusted(brightness: 1.0 + noise * 0.03)
        } else {
            // Snow peaks
            return Color(red: 0.95, green: 0.95, blue: 0.98).adjusted(brightness: 1.0 + noise * 0.03)
        }
    }

    /// Rocky terrain: Badlands with rocky outcrops
    private func compositionRockyType(elevation: Double, noise: Double) -> Color {
        if elevation < 0.3 {
            // Sandy/tan base
            return Color(red: 0.70, green: 0.60, blue: 0.45).adjusted(brightness: 1.05 + noise * 0.05)
        } else if elevation < 0.7 {
            // Rocky brown
            return Color(red: 0.45, green: 0.35, blue: 0.30).adjusted(brightness: 1.0 - (elevation * 0.15) + (noise * 0.05))
        } else {
            // Dark rocky peaks
            return Color(red: 0.35, green: 0.25, blue: 0.20).adjusted(brightness: 0.9 + noise * 0.05)
        }
    }

    /// Ice terrain: Arctic ice sheets
    private func compositionIceType(elevation: Double, noise: Double) -> Color {
        if elevation < 0.4 {
            // Light blue ice
            return Color(red: 0.70, green: 0.85, blue: 0.95).adjusted(brightness: 1.05 + noise * 0.03)
        } else if elevation < 0.7 {
            // Bright ice
            return Color(red: 0.85, green: 0.93, blue: 0.98).adjusted(brightness: 1.0 + noise * 0.03)
        } else {
            // Snow/ice peaks
            return Color(red: 0.95, green: 0.95, blue: 0.98).adjusted(brightness: 1.0 + noise * 0.03)
        }
    }

    // Platform-specific color conversion
    #if canImport(UIKit)
    private static func platformColor(from color: Color) -> UIColor {
        UIColor(color)
    }
    #elseif os(macOS)
    private static func platformColor(from color: Color) -> NSColor {
        NSColor(color)
    }
    #endif
}

// MARK: - Color Adjustments

private extension Color {
    /// Adjust color brightness while preserving hue and saturation
    /// - Parameter brightness: Brightness multiplier (0.0 = black, 1.0 = original, > 1.0 = brighter)
    /// - Returns: Adjusted color
    func adjusted(brightness: Double) -> Color {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

        // Convert to HSB color space
        guard uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return self
        }

        // Apply brightness adjustment
        let newBrightness = (b * CGFloat(brightness)).clamped(to: 0.0...1.0)

        return Color(UIColor(hue: h, saturation: s, brightness: newBrightness, alpha: a))

        #elseif os(macOS)
        guard let nsColor = NSColor(self).usingColorSpace(.deviceRGB) else {
            return self
        }

        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

        // Convert to HSB color space
        nsColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        // Apply brightness adjustment
        let newBrightness = (b * CGFloat(brightness)).clamped(to: 0.0...1.0)

        return Color(NSColor(hue: h, saturation: s, brightness: newBrightness, alpha: a))

        #else
        return self
        #endif
    }
}

// MARK: - CGFloat Extensions

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

// MARK: - Double Extensions

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}
