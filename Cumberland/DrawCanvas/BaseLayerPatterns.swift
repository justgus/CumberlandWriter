//
//  ProceduralPatterns.swift
//  Cumberland
//
//  Procedural pattern generation for base layer fills
//  Generates realistic surface textures using noise, fractals, and random elements
//

import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

// MARK: - Procedural Pattern Generator

/// Protocol for procedural pattern generators
protocol ProceduralPattern {
    /// Generate pattern into a Core Graphics context
    /// - Parameters:
    ///   - context: Core Graphics context to draw into
    ///   - rect: Rectangle to fill
    ///   - seed: Random seed for reproducible patterns
    ///   - baseColor: Base color for the pattern
    ///   - mapScale: Optional map scale in miles (exterior) or feet (interior) - used to calculate physical sizes
    func draw(in context: CGContext, rect: CGRect, seed: Int, baseColor: Color, mapScale: Double?)
}

// MARK: - Perlin Noise Generator

/// Simple Perlin-style noise generator for procedural textures
class NoiseGenerator {
    private let permutation: [Int]

    init(seed: Int) {
        // Create permutation table based on seed
        var perm = Array(0..<256)
        var rng = SeededRandom(seed: seed)

        // Fisher-Yates shuffle
        for i in (1..<perm.count).reversed() {
            let j = Int(rng.nextDouble() * Double(i + 1))
            perm.swapAt(i, j)
        }

        // Duplicate for wrapping
        self.permutation = perm + perm
    }

    /// Get 2D noise value at coordinates (0.0 to 1.0)
    func noise2D(x: Double, y: Double) -> Double {
        let X = Int(floor(x)) & 255
        let Y = Int(floor(y)) & 255

        let xf = x - floor(x)
        let yf = y - floor(y)

        let u = fade(xf)
        let v = fade(yf)

        let a = permutation[X] + Y
        let b = permutation[X + 1] + Y

        let aa = permutation[a]
        let ab = permutation[a + 1]
        let ba = permutation[b]
        let bb = permutation[b + 1]

        let x1 = lerp(grad(permutation[aa], xf, yf),
                     grad(permutation[ba], xf - 1, yf), u)
        let x2 = lerp(grad(permutation[ab], xf, yf - 1),
                     grad(permutation[bb], xf - 1, yf - 1), u)

        return lerp(x1, x2, v)
    }

    /// Fractal noise (multiple octaves)
    func fractalNoise2D(x: Double, y: Double, octaves: Int = 4, persistence: Double = 0.5) -> Double {
        var total = 0.0
        var frequency = 1.0
        var amplitude = 1.0
        var maxValue = 0.0

        for _ in 0..<octaves {
            total += noise2D(x: x * frequency, y: y * frequency) * amplitude
            maxValue += amplitude
            amplitude *= persistence
            frequency *= 2.0
        }

        return total / maxValue
    }

    private func fade(_ t: Double) -> Double {
        return t * t * t * (t * (t * 6 - 15) + 10)
    }

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        return a + t * (b - a)
    }

    private func grad(_ hash: Int, _ x: Double, _ y: Double) -> Double {
        let h = hash & 3
        let u = h < 2 ? x : y
        let v = h < 2 ? y : x
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }
}

// MARK: - Seeded Random Number Generator

/// Simple seeded random number generator for reproducible patterns
struct SeededRandom {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(truncatingIfNeeded: seed)
        // Mix the seed
        self.state = self.state &* 6364136223846793005 &+ 1442695040888963407
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    mutating func nextDouble() -> Double {
        return Double(next() >> 11) / Double(1 << 53)
    }

    mutating func nextInt(bound: Int) -> Int {
        return Int(nextDouble() * Double(bound))
    }
}

// MARK: - Tile Pattern

struct TilePattern: ProceduralPattern {
    func draw(in context: CGContext, rect: CGRect, seed: Int, baseColor: Color, mapScale: Double?) {
        // DR-0019: Calculate tile size based on map scale for interior maps
        // 12-inch tiles (1 foot) - scale if map scale is provided
        let baseTileSize: CGFloat = 64  // Default for backward compatibility
        let tileSize: CGFloat
        if let scale = mapScale {
            // For interior maps: scale is in feet, canvas represents that many feet
            // 12-inch (1 foot) tiles
            let tileSizeInFeet: CGFloat = 1.0
            tileSize = (tileSizeInFeet / CGFloat(scale)) * rect.width
        } else {
            tileSize = baseTileSize
        }
        let groutWidth: CGFloat = 3

        let noise = NoiseGenerator(seed: seed)

        // Extract color components
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        platformColor(from: baseColor).getRGBA(&r, &g, &b, &a)

        let cols = Int(ceil(rect.width / tileSize))
        let rows = Int(ceil(rect.height / tileSize))

        for row in 0..<rows {
            for col in 0..<cols {
                let x = CGFloat(col) * tileSize
                let y = CGFloat(row) * tileSize

                // Per-tile color variation using noise
                let noiseVal = noise.noise2D(x: Double(col) * 0.1, y: Double(row) * 0.1)
                let variation = 0.85 + (noiseVal + 1.0) * 0.075 // 0.85 to 1.0

                let tileColor = platformColorFromRGBA(
                    r * variation,
                    g * variation,
                    b * variation,
                    a
                )

                // Draw tile
                context.setFillColor(tileColor.cgColor)
                let tileRect = CGRect(x: x, y: y, width: tileSize - groutWidth, height: tileSize - groutWidth)
                context.fill(tileRect)

                // Add subtle noise to tile surface
                drawNoiseOverlay(context: context, rect: tileRect, noise: noise, intensity: 0.03)
            }
        }

        // Draw grout lines
        let groutColor = platformColorFromRGBA(r * 0.7, g * 0.7, b * 0.7, a)
        context.setFillColor(groutColor.cgColor)

        // Vertical grout lines
        for col in 0...cols {
            let x = CGFloat(col) * tileSize - groutWidth / 2
            context.fill(CGRect(x: x, y: 0, width: groutWidth, height: rect.height))
        }

        // Horizontal grout lines
        for row in 0...rows {
            let y = CGFloat(row) * tileSize - groutWidth / 2
            context.fill(CGRect(x: 0, y: y, width: rect.width, height: groutWidth))
        }
    }
}

// MARK: - Wood Plank Pattern (ER-0001 + DR-0019)

struct WoodPattern: ProceduralPattern {
    func draw(in context: CGContext, rect: CGRect, seed: Int, baseColor: Color, mapScale: Double?) {
        var rng = SeededRandom(seed: seed)
        let noise = NoiseGenerator(seed: seed)

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        platformColor(from: baseColor).getRGBA(&r, &g, &b, &a)

        // ER-0001 + DR-0019: Calculate plank sizes based on map scale
        // 6-inch wide planks (0.5 feet)
        let plankHeightInFeet: CGFloat = 0.5  // 6 inches = 0.5 feet

        let plankHeight: CGFloat
        let plankLengths: [CGFloat]

        if let scale = mapScale {
            // DR-0019: Scale planks based on map scale (for interior maps, scale is in feet)
            // Canvas width represents 'scale' feet total
            plankHeight = (plankHeightInFeet / CGFloat(scale)) * rect.width

            // Plank lengths: 2-6 feet
            let lengthsInFeet: [CGFloat] = [2, 3, 4, 5, 6]
            plankLengths = lengthsInFeet.map { ($0 / CGFloat(scale)) * rect.width }
        } else {
            // Backward compatibility: use fixed pixel sizes
            plankHeight = 36
            plankLengths = [144, 216, 288, 360, 432]
        }

        // Separation line width
        let separationWidth: CGFloat = 2

        let rows = Int(ceil(rect.height / plankHeight))

        var currentY: CGFloat = 0

        for row in 0..<rows {
            var currentX: CGFloat = 0

            // Stagger offset for realistic appearance (50% offset every other row)
            if row % 2 == 1 {
                let firstPlankIndex = rng.nextInt(bound: plankLengths.count)
                let firstPlankLength = plankLengths[firstPlankIndex] / 2

                // Draw half plank at start of odd rows for stagger
                drawPlank(
                    context: context,
                    rect: CGRect(x: currentX, y: currentY, width: firstPlankLength, height: plankHeight),
                    noise: noise,
                    rng: &rng,
                    baseR: r, baseG: g, baseB: b, baseA: a,
                    row: row,
                    col: 0
                )
                currentX += firstPlankLength
            }

            // Draw full planks across the row
            var col = 1
            while currentX < rect.width {
                let plankIndex = rng.nextInt(bound: plankLengths.count)
                let plankWidth = plankLengths[plankIndex]

                let actualWidth = min(plankWidth, rect.width - currentX)

                drawPlank(
                    context: context,
                    rect: CGRect(x: currentX, y: currentY, width: actualWidth - separationWidth, height: plankHeight - separationWidth),
                    noise: noise,
                    rng: &rng,
                    baseR: r, baseG: g, baseB: b, baseA: a,
                    row: row,
                    col: col
                )

                currentX += actualWidth
                col += 1
            }

            currentY += plankHeight
        }

        // Draw plank separation lines
        drawPlankSeparations(
            context: context,
            rect: rect,
            plankHeight: plankHeight,
            separationWidth: separationWidth,
            r: r, g: g, b: b, a: a
        )
    }

    private func drawPlank(
        context: CGContext,
        rect: CGRect,
        noise: NoiseGenerator,
        rng: inout SeededRandom,
        baseR: CGFloat, baseG: CGFloat, baseB: CGFloat, baseA: CGFloat,
        row: Int,
        col: Int
    ) {
        // Per-plank color variation (±10% brightness)
        let colorVariation = 0.9 + CGFloat(rng.nextDouble()) * 0.2

        // Draw plank base color
        let plankColor = platformColorFromRGBA(
            baseR * colorVariation,
            baseG * colorVariation,
            baseB * colorVariation,
            baseA
        )
        context.setFillColor(plankColor.cgColor)
        context.fill(rect)

        // Add wood grain texture
        let width = Int(rect.width)
        let height = Int(rect.height)

        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                let worldX = rect.minX + CGFloat(x)
                let worldY = rect.minY + CGFloat(y)

                // Horizontal grain pattern
                let nx = Double(worldX) / 80.0
                let ny = Double(worldY) / 150.0

                // Wood grain using noise
                let grain = noise.fractalNoise2D(x: nx * 0.3, y: ny * 0.8, octaves: 2, persistence: 0.4)
                let grainBrightness = 0.95 + grain * 0.05

                let grainColor = platformColorFromRGBA(
                    baseR * colorVariation * grainBrightness,
                    baseG * colorVariation * grainBrightness,
                    baseB * colorVariation * grainBrightness,
                    baseA * 0.3
                )

                context.setFillColor(grainColor.cgColor)
                context.fill(CGRect(x: worldX, y: worldY, width: 2, height: 2))
            }
        }
    }

    private func drawPlankSeparations(
        context: CGContext,
        rect: CGRect,
        plankHeight: CGFloat,
        separationWidth: CGFloat,
        r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat
    ) {
        // Dark brown/black for plank gaps
        let separationColor = platformColorFromRGBA(r * 0.3, g * 0.3, b * 0.3, a * 0.8)
        context.setFillColor(separationColor.cgColor)

        // Horizontal separations (between plank rows)
        var y: CGFloat = plankHeight
        while y < rect.height {
            context.fill(CGRect(x: 0, y: y - separationWidth, width: rect.width, height: separationWidth))
            y += plankHeight
        }
    }
}

// MARK: - Slate Pattern

struct SlatePattern: ProceduralPattern {
    func draw(in context: CGContext, rect: CGRect, seed: Int, baseColor: Color, mapScale: Double?) {
        let tileWidth: CGFloat = 120
        let tileHeight: CGFloat = 60
        let groutWidth: CGFloat = 2

        let noise = NoiseGenerator(seed: seed)

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        platformColor(from: baseColor).getRGBA(&r, &g, &b, &a)

        let cols = Int(ceil(rect.width / tileWidth))
        let rows = Int(ceil(rect.height / tileHeight))

        for row in 0..<rows {
            for col in 0..<cols {
                // Offset every other row for brick pattern
                let offset = (row % 2 == 0) ? 0 : tileWidth / 2
                let x = CGFloat(col) * tileWidth + offset
                let y = CGFloat(row) * tileHeight

                // Per-tile variation
                let noiseVal = noise.noise2D(x: Double(col) * 0.15, y: Double(row) * 0.15)
                let variation = 0.8 + (noiseVal + 1.0) * 0.1

                let tileColor = platformColorFromRGBA(
                    r * variation,
                    g * variation,
                    b * variation,
                    a
                )

                context.setFillColor(tileColor.cgColor)
                let tileRect = CGRect(x: x, y: y, width: tileWidth - groutWidth, height: tileHeight - groutWidth)
                context.fill(tileRect)

                // Add slate texture (layered look)
                drawNoiseOverlay(context: context, rect: tileRect, noise: noise, intensity: 0.05)
            }
        }
    }
}

// MARK: - Stone Pattern

struct StonePattern: ProceduralPattern {
    func draw(in context: CGContext, rect: CGRect, seed: Int, baseColor: Color, mapScale: Double?) {
        let noise = NoiseGenerator(seed: seed)

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        platformColor(from: baseColor).getRGBA(&r, &g, &b, &a)

        // Fill base color
        context.setFillColor(platformColor(from: baseColor).cgColor)
        context.fill(rect)

        let width = Int(rect.width)
        let height = Int(rect.height)

        // Add stone texture using fractal noise
        for y in stride(from: 0, to: height, by: 4) {
            for x in stride(from: 0, to: width, by: 4) {
                let nx = Double(x) / 200.0
                let ny = Double(y) / 200.0

                let noiseVal = noise.fractalNoise2D(x: nx, y: ny, octaves: 4, persistence: 0.6)
                let brightness = 0.85 + (noiseVal + 1.0) * 0.075

                let pixelColor = platformColorFromRGBA(
                    r * brightness,
                    g * brightness,
                    b * brightness,
                    a * 0.3
                )

                context.setFillColor(pixelColor.cgColor)
                context.fill(CGRect(x: x, y: y, width: 4, height: 4))
            }
        }
    }
}

// MARK: - Cobblestone Pattern

struct CobblestonePattern: ProceduralPattern {
    func draw(in context: CGContext, rect: CGRect, seed: Int, baseColor: Color, mapScale: Double?) {
        var rng = SeededRandom(seed: seed)
        let noise = NoiseGenerator(seed: seed)

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        platformColor(from: baseColor).getRGBA(&r, &g, &b, &a)

        // Draw grout/mortar background
        let groutColor = platformColorFromRGBA(r * 0.6, g * 0.6, b * 0.6, a)
        context.setFillColor(groutColor.cgColor)
        context.fill(rect)

        // Generate cobblestones
        let cobbleSize: CGFloat = 40
        let spacing: CGFloat = 6

        let cols = Int(rect.width / cobbleSize)
        let rows = Int(rect.height / cobbleSize)

        for row in 0..<rows {
            for col in 0..<cols {
                let centerX = CGFloat(col) * cobbleSize + cobbleSize / 2 + CGFloat(rng.nextDouble() - 0.5) * spacing
                let centerY = CGFloat(row) * cobbleSize + cobbleSize / 2 + CGFloat(rng.nextDouble() - 0.5) * spacing

                let sizeVar = cobbleSize * 0.7 + CGFloat(rng.nextDouble()) * cobbleSize * 0.3

                // Color variation per cobble
                let noiseVal = noise.noise2D(x: Double(col) * 0.2, y: Double(row) * 0.2)
                let variation = 0.8 + (noiseVal + 1.0) * 0.1

                let cobbleColor = platformColorFromRGBA(
                    r * variation,
                    g * variation,
                    b * variation,
                    a
                )

                // Draw rounded cobblestone
                context.setFillColor(cobbleColor.cgColor)
                let cobbleRect = CGRect(x: centerX - sizeVar / 2, y: centerY - sizeVar / 2, width: sizeVar, height: sizeVar)
                context.fillEllipse(in: cobbleRect)

                // Add texture
                drawNoiseOverlay(context: context, rect: cobbleRect, noise: noise, intensity: 0.04)
            }
        }
    }
}

// MARK: - Concrete Pattern

struct ConcretePattern: ProceduralPattern {
    func draw(in context: CGContext, rect: CGRect, seed: Int, baseColor: Color, mapScale: Double?) {
        let noise = NoiseGenerator(seed: seed)
        var rng = SeededRandom(seed: seed)

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        platformColor(from: baseColor).getRGBA(&r, &g, &b, &a)

        // Fill base color
        context.setFillColor(platformColor(from: baseColor).cgColor)
        context.fill(rect)

        let width = Int(rect.width)
        let height = Int(rect.height)

        // Add concrete texture (mottled appearance)
        for y in stride(from: 0, to: height, by: 3) {
            for x in stride(from: 0, to: width, by: 3) {
                let nx = Double(x) / 150.0
                let ny = Double(y) / 150.0

                let noiseVal = noise.fractalNoise2D(x: nx, y: ny, octaves: 3, persistence: 0.5)
                let brightness = 0.9 + (noiseVal + 1.0) * 0.05

                let pixelColor = platformColorFromRGBA(
                    r * brightness,
                    g * brightness,
                    b * brightness,
                    a * 0.2
                )

                context.setFillColor(pixelColor.cgColor)
                context.fill(CGRect(x: x, y: y, width: 3, height: 3))
            }
        }

        // Add occasional cracks
        context.setStrokeColor(platformColorFromRGBA(r * 0.7, g * 0.7, b * 0.7, a * 0.5).cgColor)
        context.setLineWidth(1)

        for _ in 0..<5 {
            let startX = CGFloat(rng.nextDouble()) * rect.width
            let startY = CGFloat(rng.nextDouble()) * rect.height
            let endX = startX + CGFloat(rng.nextDouble() - 0.5) * 100
            let endY = startY + CGFloat(rng.nextDouble() - 0.5) * 100

            context.move(to: CGPoint(x: startX, y: startY))
            context.addLine(to: CGPoint(x: endX, y: endY))
            context.strokePath()
        }
    }
}

// MARK: - Metal Pattern

struct MetalPattern: ProceduralPattern {
    func draw(in context: CGContext, rect: CGRect, seed: Int, baseColor: Color, mapScale: Double?) {
        let noise = NoiseGenerator(seed: seed)
        var rng = SeededRandom(seed: seed)

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        platformColor(from: baseColor).getRGBA(&r, &g, &b, &a)

        let width = Int(rect.width)
        let height = Int(rect.height)

        // Create brushed metal effect
        for y in 0..<height {
            for x in stride(from: 0, to: width, by: 2) {
                let nx = Double(x) / 100.0
                let ny = Double(y) / 100.0

                // Horizontal brush strokes
                let brushNoise = noise.noise2D(x: nx * 0.1, y: ny * 2.0)
                let brightness = 0.85 + (brushNoise + 1.0) * 0.075

                let pixelColor = platformColorFromRGBA(
                    r * brightness,
                    g * brightness,
                    b * brightness,
                    a
                )

                context.setFillColor(pixelColor.cgColor)
                context.fill(CGRect(x: x, y: y, width: 2, height: 1))
            }
        }

        // Add some scratches
        context.setStrokeColor(platformColorFromRGBA(r * 0.9, g * 0.9, b * 0.9, a * 0.3).cgColor)
        context.setLineWidth(1)

        for _ in 0..<8 {
            let y = CGFloat(rng.nextDouble()) * rect.height
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: rect.width, y: y + CGFloat(rng.nextDouble() - 0.5) * 20))
            context.strokePath()
        }
    }
}

// MARK: - Helper Functions

private func drawNoiseOverlay(context: CGContext, rect: CGRect, noise: NoiseGenerator, intensity: Double) {
    let step = 4
    for y in stride(from: Int(rect.minY), to: Int(rect.maxY), by: step) {
        for x in stride(from: Int(rect.minX), to: Int(rect.maxX), by: step) {
            let noiseVal = noise.noise2D(x: Double(x) / 50.0, y: Double(y) / 50.0)
            let alpha = intensity * ((noiseVal + 1.0) / 2.0)

            context.setFillColor(CGColor(gray: 0, alpha: alpha))
            context.fill(CGRect(x: x, y: y, width: step, height: step))
        }
    }
}

// MARK: - Platform Color Helpers

#if canImport(UIKit)
private func platformColor(from color: Color) -> UIColor {
    UIColor(color)
}

private func platformColorFromRGBA(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> UIColor {
    UIColor(red: r, green: g, blue: b, alpha: a)
}

extension UIColor {
    func getRGBA(_ r: inout CGFloat, _ g: inout CGFloat, _ b: inout CGFloat, _ a: inout CGFloat) {
        getRed(&r, green: &g, blue: &b, alpha: &a)
    }
}
#elseif os(macOS)
private func platformColor(from color: Color) -> NSColor {
    NSColor(color)
}

private func platformColorFromRGBA(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> NSColor {
    NSColor(red: r, green: g, blue: b, alpha: a)
}

extension NSColor {
    func getRGBA(_ r: inout CGFloat, _ g: inout CGFloat, _ b: inout CGFloat, _ a: inout CGFloat) {
        guard let rgbColor = usingColorSpace(.deviceRGB) else { return }
        rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    }
}
#endif

// MARK: - Pattern Factory

/// Factory for creating procedural patterns based on fill type
struct ProceduralPatternFactory {
    /// Get a procedural pattern for a fill type
    /// - Parameters:
    ///   - fillType: The type of fill to generate a pattern for
    ///   - metadata: Optional terrain metadata for exterior terrain patterns
    /// - Returns: A ProceduralPattern instance, or nil for solid color fills
    static func pattern(for fillType: BaseLayerFillType, metadata: TerrainMapMetadata? = nil) -> ProceduralPattern? {
        // Check for procedural terrain first (exterior types with metadata)
        if fillType.category == .exterior, let terrainMeta = metadata {
            return TerrainPattern(metadata: terrainMeta, dominantFillType: fillType)
        }

        // Interior patterns
        switch fillType {
        case .tile:
            return TilePattern()
        case .wood:
            return WoodPattern()
        case .slate:
            return SlatePattern()
        case .stone:
            return StonePattern()
        case .cobbles:
            return CobblestonePattern()
        case .concrete:
            return ConcretePattern()
        case .metal:
            return MetalPattern()
        default:
            return nil // Solid color fallback
        }
    }
}
