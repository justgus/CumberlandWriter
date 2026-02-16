//
//  ProceduralPatternGenerator.swift
//  BrushEngine
//
//  Advanced procedural pattern generation for natural map features
//

import SwiftUI
import Foundation
import CoreGraphics

// MARK: - Procedural Pattern Generator

/// Generates complex, natural-looking patterns for map terrain features
public class ProceduralPatternGenerator {

    // MARK: - Noise Generation

    /// Simple Perlin-like noise for natural variation
    public static func noise(_ x: CGFloat, _ y: CGFloat, seed: Int = 0) -> CGFloat {
        let ix = Int(floor(x))
        let iy = Int(floor(y))

        let fx = x - CGFloat(ix)
        let fy = y - CGFloat(iy)

        // Smooth interpolation
        let u = fx * fx * (3.0 - 2.0 * fx)
        let v = fy * fy * (3.0 - 2.0 * fy)

        // Hash function for pseudo-random values
        let a = hash(ix, iy, seed)
        let b = hash(ix + 1, iy, seed)
        let c = hash(ix, iy + 1, seed)
        let d = hash(ix + 1, iy + 1, seed)

        let k0 = CGFloat(a) / CGFloat(Int.max)
        let k1 = CGFloat(b) / CGFloat(Int.max)
        let k2 = CGFloat(c) / CGFloat(Int.max)
        let k3 = CGFloat(d) / CGFloat(Int.max)

        return lerp(
            lerp(k0, k1, u),
            lerp(k2, k3, u),
            v
        )
    }

    /// Simple hash function for noise
    private static func hash(_ x: Int, _ y: Int, _ seed: Int) -> Int {
        var h = seed &+ x &* 374761393
        h = (h ^ (h >> 24)) &* 1664525
        h = h &+ y &* 1013904223
        h = h ^ (h >> 24)
        return abs(h)
    }

    /// Linear interpolation
    private static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        return a + (b - a) * t
    }

    /// Fractional Brownian Motion (layered noise for natural patterns)
    public static func fbm(_ x: CGFloat, _ y: CGFloat, octaves: Int = 4) -> CGFloat {
        var value: CGFloat = 0
        var amplitude: CGFloat = 0.5
        var frequency: CGFloat = 1.0

        for _ in 0..<octaves {
            value += amplitude * noise(x * frequency, y * frequency)
            amplitude *= 0.5
            frequency *= 2.0
        }

        return value
    }

    // MARK: - Coastline Generation

    /// Generate highly detailed, natural-looking coastline
    public static func generateDetailedCoastline(
        points: [CGPoint],
        width: CGFloat,
        detail: CoastlineDetail = .medium,
        erosion: CGFloat = 0.5
    ) -> CGPath {
        let path = CGMutablePath()
        guard points.count > 1 else { return path }

        let subdivisionLevel = detail.subdivisionLevel
        let roughnessScale = detail.roughnessScale * erosion

        // ER-0003: Enhanced multi-scale subdivision for more realistic coastlines
        var detailedPoints: [CGPoint] = []

        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]

            detailedPoints.append(p1)

            // Add intermediate points
            for j in 1..<subdivisionLevel {
                let t = CGFloat(j) / CGFloat(subdivisionLevel)
                let midX = p1.x + (p2.x - p1.x) * t
                let midY = p1.y + (p2.y - p1.y) * t

                detailedPoints.append(CGPoint(x: midX, y: midY))
            }
        }
        detailedPoints.append(points[points.count - 1])

        // ER-0003: Apply multi-scale noise-based displacement for realistic bays and peninsulas
        path.move(to: detailedPoints[0])

        for i in 1..<detailedPoints.count {
            let point = detailedPoints[i]

            // Get perpendicular direction for displacement
            let prevPoint = detailedPoints[i - 1]
            let dx = point.x - prevPoint.x
            let dy = point.y - prevPoint.y
            let distance = hypot(dx, dy)

            guard distance > 0 else { continue }

            let perpX = -dy / distance
            let perpY = dx / distance

            // ER-0003: Multi-scale displacement for realistic coastline features
            // Large-scale features (bays, peninsulas) - low frequency, high amplitude
            let largeFBM = fbm(point.x / (width * 40), point.y / (width * 40), octaves: 3)
            let largeDisplacement = (largeFBM - 0.5) * width * roughnessScale * 3.0

            // Medium-scale features (inlets, headlands) - medium frequency
            let mediumFBM = fbm(point.x / (width * 15), point.y / (width * 15), octaves: 5)
            let mediumDisplacement = (mediumFBM - 0.5) * width * roughnessScale * 1.5

            // Fine-scale features (rocks, small irregularities) - high frequency, low amplitude
            let fineFBM = fbm(point.x / (width * 5), point.y / (width * 5), octaves: 6)
            let fineDisplacement = (fineFBM - 0.5) * width * roughnessScale * 0.5

            // Combine scales for realistic coastline
            let totalDisplacement = largeDisplacement + mediumDisplacement + fineDisplacement

            let newX = point.x + perpX * totalDisplacement
            let newY = point.y + perpY * totalDisplacement

            // ER-0003: Add occasional dramatic features (rocky outcrops)
            let dramaticFeature = sin(CGFloat(i) * 0.3) > 0.85 // ~15% chance
            let dramaticScale: CGFloat = dramaticFeature ? 1.8 : 1.0

            // Use curves for smoother coastline
            if i % 2 == 0 {
                let controlX = (prevPoint.x + newX) / 2 + CGFloat.random(in: -width*0.2...width*0.2) * dramaticScale
                let controlY = (prevPoint.y + newY) / 2 + CGFloat.random(in: -width*0.2...width*0.2) * dramaticScale
                path.addQuadCurve(
                    to: CGPoint(x: newX, y: newY),
                    control: CGPoint(x: controlX, y: controlY)
                )
            } else {
                path.addLine(to: CGPoint(x: newX, y: newY))
            }
        }

        return path
    }

    /// Generate coastline with beaches (gradual transition)
    public static func generateBeachCoastline(
        points: [CGPoint],
        width: CGFloat,
        beachWidth: CGFloat
    ) -> (coastline: CGPath, beach: CGPath) {
        let coastlinePath = generateDetailedCoastline(points: points, width: width, detail: .high, erosion: 0.7)

        let beachPath = CGMutablePath()

        // Create parallel path offset by beach width
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]

            let dx = p2.x - p1.x
            let dy = p2.y - p1.y
            let distance = hypot(dx, dy)

            guard distance > 0 else { continue }

            let perpX = -dy / distance
            let perpY = dx / distance

            let beachOffset = beachWidth + width

            let bp1 = CGPoint(x: p1.x + perpX * beachOffset, y: p1.y + perpY * beachOffset)
            let bp2 = CGPoint(x: p2.x + perpX * beachOffset, y: p2.y + perpY * beachOffset)

            if i == 0 {
                beachPath.move(to: bp1)
            }
            beachPath.addLine(to: bp2)
        }

        return (coastlinePath, beachPath)
    }

    // MARK: - Cliff & Ridge Generation

    /// Generate detailed cliff face with natural erosion patterns
    public static func generateDetailedCliff(
        points: [CGPoint],
        width: CGFloat,
        height: CGFloat,
        dropDirection: CliffDirection = .down,
        weathering: CGFloat = 0.5
    ) -> CGPath {
        let path = CGMutablePath()
        guard points.count > 1 else { return path }

        // Draw main cliff edge
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        // Generate complex hatching pattern
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]

            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let dx = (p2.x - p1.x) / segmentLength
            let dy = (p2.y - p1.y) / segmentLength

            let perpX = -dy * (dropDirection == .down ? 1 : -1)
            let perpY = dx * (dropDirection == .down ? 1 : -1)

            let hatchSpacing = width * 0.4
            let numHatches = max(3, Int(segmentLength / hatchSpacing))

            for j in 0..<numHatches {
                let t = CGFloat(j) / CGFloat(numHatches)
                let baseX = p1.x + dx * t * segmentLength
                let baseY = p1.y + dy * t * segmentLength

                // Use noise to vary hatch length and angle
                let noiseValue = fbm(baseX / (width * 5), baseY / (width * 5))
                let lengthVariation = (noiseValue - 0.5) * weathering
                let hatchLength = height * (1.0 + lengthVariation)

                let angleVariation = (noise(baseX / width, baseY / width) - 0.5) * weathering * 0.3
                let adjustedPerpX = perpX * cos(angleVariation) - perpY * sin(angleVariation)
                let adjustedPerpY = perpX * sin(angleVariation) + perpY * cos(angleVariation)

                // Draw weathered hatch line
                let endX = baseX + adjustedPerpX * hatchLength
                let endY = baseY + adjustedPerpY * hatchLength

                path.move(to: CGPoint(x: baseX, y: baseY))

                // Add irregularity to hatch line
                let midX = (baseX + endX) / 2 + CGFloat.random(in: -width*0.1...width*0.1) * weathering
                let midY = (baseY + endY) / 2 + CGFloat.random(in: -width*0.1...width*0.1) * weathering

                path.addLine(to: CGPoint(x: midX, y: midY))
                path.addLine(to: CGPoint(x: endX, y: endY))
            }
        }

        return path
    }

    /// Generate mountain ridge with natural irregularities
    public static func generateNaturalRidge(
        points: [CGPoint],
        width: CGFloat,
        prominence: CGFloat = 1.0
    ) -> CGPath {
        let path = CGMutablePath()
        guard points.count > 1 else { return path }

        // ER-0003: Create mountain ridge with passes and interconnected peaks
        var ridgePoints: [CGPoint] = []
        var passLocations: [Int] = [] // Track pass indices for visual markers

        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]

            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let dx = (p2.x - p1.x) / segmentLength
            let dy = (p2.y - p1.y) / segmentLength
            let perpX = -dy
            let perpY = dx

            // Subdivide segment
            let subdivisions = max(5, Int(segmentLength / width))

            for j in 0...subdivisions {
                let t = CGFloat(j) / CGFloat(subdivisions)
                let baseX = p1.x + (p2.x - p1.x) * t
                let baseY = p1.y + (p2.y - p1.y) * t

                // ER-0003: Generate peaks and passes using multiple frequencies
                let noiseValue = fbm(baseX / (width * 5), baseY / (width * 5), octaves: 5)

                // Create pass pattern: periodic dips in elevation (mountain passes)
                // Passes occur roughly every 30-50 points
                let passFrequency = 0.15 // 15% of points are passes
                let passPattern = sin(CGFloat(ridgePoints.count) * 0.15)
                let isPass = passPattern < -0.7 && CGFloat.random(in: 0...1) < passFrequency

                var elevation: CGFloat
                if isPass {
                    // Mountain pass: reduced elevation (saddle point)
                    elevation = (noiseValue - 0.5) * width * prominence * 0.3
                    passLocations.append(ridgePoints.count)
                } else {
                    // Regular peak: full elevation with variation
                    let peakVariation = CGFloat.random(in: 0.7...1.3) // Vary peak heights
                    elevation = (noiseValue - 0.5) * width * prominence * peakVariation
                }

                let ridgeX = baseX + perpX * elevation
                let ridgeY = baseY + perpY * elevation

                ridgePoints.append(CGPoint(x: ridgeX, y: ridgeY))
            }
        }

        // Draw smooth ridge line
        if !ridgePoints.isEmpty {
            path.move(to: ridgePoints[0])
            for i in 1..<ridgePoints.count {
                path.addLine(to: ridgePoints[i])
            }
        }

        // ER-0003: Add hatching on both sides with pass markers
        for i in 0..<(ridgePoints.count - 1) {
            let p1 = ridgePoints[i]
            let p2 = ridgePoints[i + 1]

            let dx = p2.x - p1.x
            let dy = p2.y - p1.y
            let distance = hypot(dx, dy)

            guard distance > 0 else { continue }

            let perpX = -dy / distance
            let perpY = dx / distance

            // Check if this is a pass location
            let isPassPoint = passLocations.contains(i)

            if i % 2 == 0 {
                let hatchLength = width * CGFloat.random(in: 0.8...1.5)

                // ER-0003: Visual marker for passes (saddle points)
                if isPassPoint {
                    // Pass marker: shorter hatches and gap in the middle
                    let passHatchLength = hatchLength * 0.5

                    // Left hatch (shorter for pass)
                    path.move(to: p1)
                    path.addLine(to: CGPoint(
                        x: p1.x - perpX * passHatchLength,
                        y: p1.y - perpY * passHatchLength
                    ))

                    // Right hatch (shorter for pass)
                    path.move(to: p1)
                    path.addLine(to: CGPoint(
                        x: p1.x + perpX * passHatchLength,
                        y: p1.y + perpY * passHatchLength
                    ))

                    // Add pass indicator (small gap/notch symbol)
                    path.move(to: CGPoint(x: p1.x - width * 0.15, y: p1.y))
                    path.addLine(to: CGPoint(x: p1.x + width * 0.15, y: p1.y))
                } else {
                    // Regular peak: full-length hatches
                    // Left hatch
                    path.move(to: p1)
                    path.addLine(to: CGPoint(
                        x: p1.x - perpX * hatchLength,
                        y: p1.y - perpY * hatchLength
                    ))

                    // Right hatch
                    path.move(to: p1)
                    path.addLine(to: CGPoint(
                        x: p1.x + perpX * hatchLength,
                        y: p1.y + perpY * hatchLength
                    ))
                }
            }
        }

        return path
    }

    // MARK: - Mountain Range Generation

    /// Generate complete mountain range with multiple peaks
    public static func generateMountainRange(
        points: [CGPoint],
        width: CGFloat,
        peakDensity: CGFloat = 1.0,
        style: MountainRangeStyle = .alpine
    ) -> CGPath {
        let path = CGMutablePath()
        guard points.count > 1 else { return path }

        // Draw base line
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        // Generate peaks using noise
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]

            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let dx = (p2.x - p1.x) / segmentLength
            let dy = (p2.y - p1.y) / segmentLength
            let perpX = -dy
            let perpY = dx

            let peakSpacing = width * (2.0 / peakDensity)
            let numPeaks = max(1, Int(segmentLength / peakSpacing))

            for j in 0..<numPeaks {
                let t = CGFloat(j) / CGFloat(numPeaks)
                let baseX = p1.x + (p2.x - p1.x) * t
                let baseY = p1.y + (p2.y - p1.y) * t

                // Use noise to determine peak height
                let noiseValue = fbm(baseX / (width * 10), baseY / (width * 10))
                let peakHeight = width * (1.5 + noiseValue * 2.0)

                let peakX = baseX + perpX * peakHeight
                let peakY = baseY + perpY * peakHeight

                switch style {
                case .alpine:
                    // Sharp, jagged peaks
                    path.move(to: CGPoint(x: baseX, y: baseY))
                    path.addLine(to: CGPoint(x: peakX, y: peakY))

                    // Add sub-peaks
                    let subPeakOffset = width * 0.5
                    path.addLine(to: CGPoint(
                        x: peakX + perpX * subPeakOffset * 0.3,
                        y: peakY + perpY * subPeakOffset * 0.3
                    ))

                case .rolling:
                    // Smooth, rounded peaks
                    let cp1X = baseX + perpX * peakHeight * 0.3
                    let cp1Y = baseY + perpY * peakHeight * 0.3
                    let cp2X = peakX - dx * width * 0.2
                    let cp2Y = peakY - dy * width * 0.2

                    path.move(to: CGPoint(x: baseX, y: baseY))
                    path.addCurve(
                        to: CGPoint(x: peakX, y: peakY),
                        control1: CGPoint(x: cp1X, y: cp1Y),
                        control2: CGPoint(x: cp2X, y: cp2Y)
                    )

                case .volcanic:
                    // Wide base, steep top
                    let baseWidth = width * 1.5
                    let leftBase = CGPoint(x: baseX - dx * baseWidth, y: baseY - dy * baseWidth)
                    let rightBase = CGPoint(x: baseX + dx * baseWidth, y: baseY + dy * baseWidth)

                    path.move(to: leftBase)
                    path.addLine(to: CGPoint(x: peakX, y: peakY))
                    path.addLine(to: rightBase)
                }
            }
        }

        return path
    }

    // MARK: - Water Feature Generation

    /// Generate river with natural meandering
    public static func generateMeanderingRiver(
        startPoint: CGPoint,
        endPoint: CGPoint,
        width: CGFloat,
        meanderAmount: CGFloat = 0.5
    ) -> CGPath {
        let path = CGMutablePath()

        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let distance = hypot(dx, dy)

        let segments = max(10, Int(distance / (width * 5)))
        var riverPoints: [CGPoint] = []

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let straightX = startPoint.x + dx * t
            let straightY = startPoint.y + dy * t

            // Apply perpendicular meandering
            let perpX = -dy / distance
            let perpY = dx / distance

            let noiseValue = fbm(t * 3, 0, octaves: 3)
            let meander = (noiseValue - 0.5) * distance * meanderAmount * 0.3

            let riverX = straightX + perpX * meander
            let riverY = straightY + perpY * meander

            riverPoints.append(CGPoint(x: riverX, y: riverY))
        }

        // Create smooth river path
        path.move(to: riverPoints[0])
        for i in 1..<riverPoints.count {
            let point = riverPoints[i]

            if i % 2 == 1 && i < riverPoints.count - 1 {
                // Use curves for smooth flow
                let nextPoint = riverPoints[i + 1]
                let controlX = (point.x + nextPoint.x) / 2
                let controlY = (point.y + nextPoint.y) / 2
                path.addQuadCurve(to: nextPoint, control: CGPoint(x: controlX, y: controlY))
            } else if i % 2 == 0 {
                path.addLine(to: point)
            }
        }

        return path
    }

    /// Generate lake with irregular shore
    public static func generateIrregularLake(
        center: CGPoint,
        radius: CGFloat,
        irregularity: CGFloat = 0.3
    ) -> CGPath {
        let path = CGMutablePath()

        let numPoints = 36 // One point every 10 degrees
        var lakePoints: [CGPoint] = []

        for i in 0..<numPoints {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(numPoints)

            // Use noise to vary radius
            let noiseValue = fbm(cos(angle) * 2, sin(angle) * 2, octaves: 3)
            let radiusVariation = (noiseValue - 0.5) * irregularity
            let adjustedRadius = radius * (1.0 + radiusVariation)

            let x = center.x + cos(angle) * adjustedRadius
            let y = center.y + sin(angle) * adjustedRadius

            lakePoints.append(CGPoint(x: x, y: y))
        }

        // Create smooth closed path
        path.move(to: lakePoints[0])
        for i in 1..<lakePoints.count {
            let point = lakePoints[i]
            let prevPoint = lakePoints[i - 1]

            let controlX = (prevPoint.x + point.x) / 2
            let controlY = (prevPoint.y + point.y) / 2

            path.addQuadCurve(to: point, control: CGPoint(x: controlX, y: controlY))
        }

        // Close back to start
        let lastPoint = lakePoints[lakePoints.count - 1]
        let firstPoint = lakePoints[0]
        let controlX = (lastPoint.x + firstPoint.x) / 2
        let controlY = (lastPoint.y + firstPoint.y) / 2
        path.addQuadCurve(to: firstPoint, control: CGPoint(x: controlX, y: controlY))

        path.closeSubpath()

        return path
    }
}

// MARK: - Pattern Style Enums

public enum CoastlineDetail {
    case low
    case medium
    case high
    case veryHigh

    public var subdivisionLevel: Int {
        switch self {
        case .low: return 2
        case .medium: return 4
        case .high: return 8
        case .veryHigh: return 16
        }
    }

    public var roughnessScale: CGFloat {
        switch self {
        case .low: return 0.5
        case .medium: return 1.0
        case .high: return 1.5
        case .veryHigh: return 2.0
        }
    }
}

public enum MountainRangeStyle {
    case alpine      // Sharp, jagged peaks
    case rolling     // Smooth, rounded hills
    case volcanic    // Wide base, steep peaks
}
