//
//  ElevationMap.swift
//  BrushEngine
//
//  Pre-computed elevation data for procedural terrain generation
//  Uses fractal noise to create realistic elevation patterns
//

import Foundation
import CoreGraphics

// MARK: - Elevation Map

/// Pre-computed elevation data for terrain generation
/// Generates a heightmap using fractal noise that determines biome placement
/// Elevation range: -1.0 (deepest/underwater) to 1.0 (highest peak), 0.0 = sea level
public class ElevationMap {
    public let width: Int
    public let height: Int
    private var elevations: [Double] // Flattened 2D array (-1.0 to 1.0 range)

    /// Initialize and generate elevation map
    /// - Parameters:
    ///   - width: Width of the elevation map in pixels
    ///   - height: Height of the elevation map in pixels
    ///   - seed: Random seed for reproducible generation
    ///   - waterPercentage: Target percentage of terrain that should be water (0.0 to 1.0)
    ///   - scale: Feature scale multiplier (higher = larger terrain features)
    ///   - octaves: Number of noise layers (more = more detail)
    public init(width: Int, height: Int, seed: Int, waterPercentage: Double = 0.5, scale: Double = 1.0, octaves: Int = 6) {
        self.width = width
        self.height = height
        self.elevations = []

        let noise = NoiseGenerator(seed: seed)

        // Pre-compute elevation for every point
        elevations.reserveCapacity(width * height)

        // Track min/max for remapping
        var minElev = Double.infinity
        var maxElev = -Double.infinity

        for y in 0..<height {
            for x in 0..<width {
                // Normalize coordinates to 0-1 range
                let nx = Double(x) / Double(width) * scale
                let ny = Double(y) / Double(height) * scale

                // Use fractal noise for realistic terrain
                // Scale factor of 4.0 creates appropriately sized terrain features
                // Returns values in [-1, 1] range
                let elevation = noise.fractalNoise2D(
                    x: nx * 4.0,
                    y: ny * 4.0,
                    octaves: octaves,
                    persistence: 0.5
                )

                elevations.append(elevation)
                minElev = min(minElev, elevation)
                maxElev = max(maxElev, elevation)
            }
        }

        print("[ElevationMap] Generated \(width)×\(height) elevations (raw fractal noise):")
        print("  - Min: \(String(format: "%.3f", minElev))")
        print("  - Max: \(String(format: "%.3f", maxElev))")

        // Step 1: Remap to full -1.0 to 1.0 range
        // Fractal noise may not use the full range, so stretch it
        if maxElev > minElev {
            let range = maxElev - minElev
            for i in 0..<elevations.count {
                // Remap from [minElev, maxElev] to [-1.0, 1.0]
                elevations[i] = 2.0 * (elevations[i] - minElev) / range - 1.0
            }
            print("[ElevationMap] Remapped to full -1.0 to 1.0 range")
        }

        // Step 2: Apply water percentage skewing
        // Shift elevation distribution so that waterPercentage of values are < 0 (underwater)
        if waterPercentage > 0.0 && waterPercentage < 1.0 {
            // Sort elevations to find the percentile value
            let sorted = elevations.sorted()
            let percentileIndex = Int(waterPercentage * Double(sorted.count))
            let percentileValue = sorted[min(percentileIndex, sorted.count - 1)]

            // Shift all elevations so that the percentile value = 0.0 (sea level)
            let shift = -percentileValue
            for i in 0..<elevations.count {
                elevations[i] = (elevations[i] + shift).clamped(to: -1.0...1.0)
            }

            print("[ElevationMap] Applied water skewing: target=\(Int(waterPercentage * 100))%, shift=\(String(format: "%.3f", shift))")
        }

        // Print final statistics
        var finalMin = Double.infinity
        var finalMax = -Double.infinity
        var finalSum = 0.0
        var waterCount = 0

        for elev in elevations {
            finalMin = min(finalMin, elev)
            finalMax = max(finalMax, elev)
            finalSum += elev
            if elev < 0 { waterCount += 1 }
        }

        let finalAvg = finalSum / Double(elevations.count)
        let actualWaterPct = Double(waterCount) / Double(elevations.count) * 100.0

        print("[ElevationMap] Final elevations:")
        print("  - Min: \(String(format: "%.3f", finalMin))")
        print("  - Max: \(String(format: "%.3f", finalMax))")
        print("  - Avg: \(String(format: "%.3f", finalAvg))")
        print("  - Water: \(String(format: "%.1f", actualWaterPct))% (target: \(Int(waterPercentage * 100))%)")
    }

    /// Get elevation at specific point
    /// - Parameters:
    ///   - x: X coordinate (0 to width-1)
    ///   - y: Y coordinate (0 to height-1)
    /// - Returns: Elevation value (-1.0 = deepest/underwater, 0.0 = sea level, 1.0 = highest peak)
    public func elevation(at x: Int, y: Int) -> Double {
        guard x >= 0, x < width, y >= 0, y < height else { return 0.0 }
        return elevations[y * width + x]
    }

    /// Get elevation with bilinear interpolation for smooth sampling
    /// This allows querying elevation at non-integer coordinates
    /// - Parameter point: Point to sample elevation at
    /// - Returns: Interpolated elevation value (-1.0 to 1.0)
    public func elevationInterpolated(at point: CGPoint) -> Double {
        let x = Double(point.x).clamped(to: 0.0...Double(width - 1))
        let y = Double(point.y).clamped(to: 0.0...Double(height - 1))

        // Get the four surrounding integer coordinates
        let x0 = Int(floor(x))
        let y0 = Int(floor(y))
        let x1 = min(x0 + 1, width - 1)
        let y1 = min(y0 + 1, height - 1)

        // Fractional parts for interpolation
        let fx = x - Double(x0)
        let fy = y - Double(y0)

        // Get elevations at the four corners
        let e00 = elevation(at: x0, y: y0)
        let e10 = elevation(at: x1, y: y0)
        let e01 = elevation(at: x0, y: y1)
        let e11 = elevation(at: x1, y: y1)

        // Bilinear interpolation
        let e0 = e00 * (1 - fx) + e10 * fx
        let e1 = e01 * (1 - fx) + e11 * fx
        return e0 * (1 - fy) + e1 * fy
    }

    /// Get statistics about the elevation map
    /// Useful for debugging and visualization
    public var statistics: ElevationStatistics {
        var min = Double.infinity
        var max = -Double.infinity
        var sum = 0.0

        for elevation in elevations {
            min = Swift.min(min, elevation)
            max = Swift.max(max, elevation)
            sum += elevation
        }

        let average = sum / Double(elevations.count)

        return ElevationStatistics(
            min: min,
            max: max,
            average: average,
            width: width,
            height: height
        )
    }
}

// MARK: - Elevation Statistics

/// Statistical information about an elevation map
public struct ElevationStatistics {
    public let min: Double
    public let max: Double
    public let average: Double
    public let width: Int
    public let height: Int

    public var description: String {
        """
        Elevation Map Statistics:
        - Size: \(width)×\(height)
        - Min: \(String(format: "%.3f", min))
        - Max: \(String(format: "%.3f", max))
        - Avg: \(String(format: "%.3f", average))
        """
    }
}

// clamped(to:) extension on Double is defined in TerrainPattern.swift
