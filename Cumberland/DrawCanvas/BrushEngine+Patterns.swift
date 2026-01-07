//
//  BrushEngine+Patterns.swift
//  Cumberland
//
//  Advanced pattern generators for map-specific brushes
//

import SwiftUI
import Foundation
import CoreGraphics

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Pattern Generator Extension

extension BrushEngine {
    
    // MARK: - Terrain Pattern Generators
    
    /// Generate mountain pattern along a path
    static func generateMountainPattern(
        points: [CGPoint],
        width: CGFloat,
        style: MountainStyle = .jagged
    ) -> CGPath {
        let path = CGMutablePath()
        guard points.count > 1 else { return path }
        
        // Draw base line
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        // Add mountain peaks above the line
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            
            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let peakSpacing = width * 2.5
            let numPeaks = max(1, Int(segmentLength / peakSpacing))
            
            // Calculate perpendicular direction (upward)
            let dx = (p2.x - p1.x) / segmentLength
            let dy = (p2.y - p1.y) / segmentLength
            let perpX = -dy
            let perpY = dx
            
            for j in 0..<numPeaks {
                let t = CGFloat(j) / CGFloat(numPeaks)
                let baseX = p1.x + (p2.x - p1.x) * t
                let baseY = p1.y + (p2.y - p1.y) * t
                
                let peakHeight = width * CGFloat.random(in: 1.5...2.5)
                let peakVariation = CGFloat.random(in: -0.2...0.2) * width
                
                switch style {
                case .jagged:
                    // Sharp triangular peak
                    let peakX = baseX + perpX * peakHeight + peakVariation
                    let peakY = baseY + perpY * peakHeight
                    
                    path.move(to: CGPoint(x: baseX, y: baseY))
                    path.addLine(to: CGPoint(x: peakX, y: peakY))
                    
                case .rounded:
                    // Smooth rounded peak using curve
                    let peakX = baseX + perpX * peakHeight + peakVariation
                    let peakY = baseY + perpY * peakHeight
                    
                    let controlOffset = peakHeight * 0.5
                    let cp1X = baseX + perpX * controlOffset - dx * width * 0.3
                    let cp1Y = baseY + perpY * controlOffset - dy * width * 0.3
                    _ = baseX + perpX * controlOffset + dx * width * 0.3
                    _ = baseY + perpY * controlOffset + dy * width * 0.3
                    
                    path.move(to: CGPoint(x: baseX, y: baseY))
                    path.addCurve(
                        to: CGPoint(x: peakX, y: peakY),
                        control1: CGPoint(x: cp1X, y: cp1Y),
                        control2: CGPoint(x: peakX - dx * width * 0.2, y: peakY)
                    )
                    
                case .layered:
                    // Multiple overlapping peaks
                    for layer in 0..<3 {
                        let layerHeight = peakHeight * (1.0 - CGFloat(layer) * 0.3)
                        let layerOffset = CGFloat(layer) * width * 0.4
                        let peakX = baseX + perpX * layerHeight + peakVariation + layerOffset
                        let peakY = baseY + perpY * layerHeight
                        
                        path.move(to: CGPoint(x: baseX, y: baseY))
                        path.addLine(to: CGPoint(x: peakX, y: peakY))
                    }
                }
            }
        }
        
        return path
    }
    
    /// Generate hill pattern (softer than mountains)
    static func generateHillPattern(
        points: [CGPoint],
        width: CGFloat
    ) -> CGPath {
        let path = CGMutablePath()
        guard points.count > 1 else { return path }
        
        path.move(to: points[0])
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            
            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let dx = (p2.x - p1.x) / segmentLength
            let dy = (p2.y - p1.y) / segmentLength
            let perpX = -dy
            let perpY = dx
            
            // Create gentle wave pattern above line
            let hillHeight = width * 0.8
            let midX = (p1.x + p2.x) / 2 + perpX * hillHeight
            let midY = (p1.y + p2.y) / 2 + perpY * hillHeight
            
            // Use quadratic curve for smooth hill
            path.move(to: p1)
            path.addQuadCurve(to: p2, control: CGPoint(x: midX, y: midY))
        }
        
        return path
    }
    
    /// Generate forest/tree cluster pattern
    static func generateForestPattern(
        points: [CGPoint],
        width: CGFloat,
        density: CGFloat = 1.0
    ) -> [(CGPoint, CGPath)] {
        var trees: [(CGPoint, CGPath)] = []
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            
            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let treeSpacing = width * (2.0 / density)
            let numTrees = max(1, Int(segmentLength / treeSpacing))
            
            for j in 0..<numTrees {
                let t = CGFloat(j) / CGFloat(numTrees)
                var x = p1.x + (p2.x - p1.x) * t
                var y = p1.y + (p2.y - p1.y) * t
                
                // Add scatter
                x += CGFloat.random(in: -width...width)
                y += CGFloat.random(in: -width...width)
                
                let treeSize = width * CGFloat.random(in: 0.7...1.3)
                let treePath = generateSingleTree(size: treeSize)
                trees.append((CGPoint(x: x, y: y), treePath))
            }
        }
        
        return trees
    }
    
    /// Generate a single tree symbol
    static func generateSingleTree(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        
        // Trunk
        let trunkWidth = size * 0.15
        let trunkHeight = size * 0.4
        path.addRect(CGRect(
            x: -trunkWidth / 2,
            y: -trunkHeight / 2,
            width: trunkWidth,
            height: trunkHeight
        ))
        
        // Canopy (triangle or circle)
        let canopySize = size * 0.8
        let canopyTop = -trunkHeight / 2 - canopySize
        
        let canopyStyle = Int.random(in: 0...1)
        if canopyStyle == 0 {
            // Triangular canopy
            path.move(to: CGPoint(x: -canopySize / 2, y: -trunkHeight / 2))
            path.addLine(to: CGPoint(x: 0, y: canopyTop))
            path.addLine(to: CGPoint(x: canopySize / 2, y: -trunkHeight / 2))
            path.closeSubpath()
        } else {
            // Circular canopy
            path.addEllipse(in: CGRect(
                x: -canopySize / 2,
                y: canopyTop,
                width: canopySize,
                height: canopySize
            ))
        }
        
        return path
    }
    
    /// Generate building pattern
    /// ER-0003: Generate building pattern with bulk random placement and special icons
    static func generateBuildingPattern(
        points: [CGPoint],
        width: CGFloat,
        density: CGFloat = 1.0
    ) -> [(CGRect, BuildingStyle)] {
        var buildings: [(CGRect, BuildingStyle)] = []

        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]

            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let buildingSpacing = width * 3.0 / density
            let numBuildings = max(1, Int(segmentLength / buildingSpacing))

            for j in 0..<numBuildings {
                let t = CGFloat(j) / CGFloat(numBuildings)

                // Add some random scatter for more natural placement
                let scatter = width * 0.5
                let scatterX = CGFloat.random(in: -scatter...scatter)
                let scatterY = CGFloat.random(in: -scatter...scatter)

                let x = p1.x + (p2.x - p1.x) * t + scatterX
                let y = p1.y + (p2.y - p1.y) * t + scatterY

                // Random building sizes
                let buildingWidth = width * CGFloat.random(in: 0.8...1.5)
                let buildingHeight = width * CGFloat.random(in: 1.0...2.0)

                let rect = CGRect(
                    x: x - buildingWidth / 2,
                    y: y - buildingHeight / 2,
                    width: buildingWidth,
                    height: buildingHeight
                )

                // ER-0003: Use weighted random for realistic distribution
                let style = BuildingStyle.randomWeighted()
                buildings.append((rect, style))
            }
        }

        return buildings
    }
    
    // MARK: - Coastline & Water Patterns
    
    /// Generate wavy coastline pattern
    static func generateCoastlinePattern(
        points: [CGPoint],
        width: CGFloat,
        roughness: CGFloat = 1.0
    ) -> CGPath {
        let path = CGMutablePath()
        guard points.count > 1 else { return path }
        
        path.move(to: points[0])
        
        // Create irregular, natural-looking coastline
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            
            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let dx = (p2.x - p1.x) / segmentLength
            let dy = (p2.y - p1.y) / segmentLength
            let perpX = -dy
            let perpY = dx
            
            // Add multiple control points for irregular coast
            let numControlPoints = max(2, Int(segmentLength / (width * 2)))
            
            var lastPoint = p1
            for j in 1...numControlPoints {
                let t = CGFloat(j) / CGFloat(numControlPoints)
                var nextX = p1.x + (p2.x - p1.x) * t
                var nextY = p1.y + (p2.y - p1.y) * t
                
                // Add perpendicular displacement for roughness
                let displacement = CGFloat.random(in: -width...width) * roughness
                nextX += perpX * displacement
                nextY += perpY * displacement
                
                // Use curve to connect points smoothly
                let controlX = (lastPoint.x + nextX) / 2 + CGFloat.random(in: -width*0.5...width*0.5) * roughness
                let controlY = (lastPoint.y + nextY) / 2 + CGFloat.random(in: -width*0.5...width*0.5) * roughness
                
                path.addQuadCurve(
                    to: CGPoint(x: nextX, y: nextY),
                    control: CGPoint(x: controlX, y: controlY)
                )
                
                lastPoint = CGPoint(x: nextX, y: nextY)
            }
        }
        
        return path
    }
    
    /// Generate cliff pattern with hatching
    static func generateCliffPattern(
        points: [CGPoint],
        width: CGFloat,
        dropDirection: CliffDirection = .down
    ) -> CGPath {
        let path = CGMutablePath()
        guard points.count > 1 else { return path }
        
        // Draw main cliff line
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        // Add hatching to indicate cliff face
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            
            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let hatchSpacing = width * 0.5
            let numHatches = max(2, Int(segmentLength / hatchSpacing))
            
            let dx = (p2.x - p1.x) / segmentLength
            let dy = (p2.y - p1.y) / segmentLength
            let perpX = -dy * (dropDirection == .down ? 1 : -1)
            let perpY = dx * (dropDirection == .down ? 1 : -1)
            
            for j in 0..<numHatches {
                let t = CGFloat(j) / CGFloat(numHatches)
                let baseX = p1.x + (p2.x - p1.x) * t
                let baseY = p1.y + (p2.y - p1.y) * t
                
                let hatchLength = width * CGFloat.random(in: 1.5...2.5)
                
                path.move(to: CGPoint(x: baseX, y: baseY))
                path.addLine(to: CGPoint(
                    x: baseX + perpX * hatchLength,
                    y: baseY + perpY * hatchLength
                ))
            }
        }
        
        return path
    }
    
    /// Generate ridge pattern (double-sided cliffs)
    static func generateRidgePattern(
        points: [CGPoint],
        width: CGFloat
    ) -> CGPath {
        let path = CGMutablePath()
        guard points.count > 1 else { return path }
        
        // Draw center ridge line (thicker)
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        // Add hatching on both sides
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            
            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let hatchSpacing = width * 0.6
            let numHatches = max(2, Int(segmentLength / hatchSpacing))
            
            let dx = (p2.x - p1.x) / segmentLength
            let dy = (p2.y - p1.y) / segmentLength
            let perpX = -dy
            let perpY = dx
            
            for j in 0..<numHatches {
                let t = CGFloat(j) / CGFloat(numHatches)
                let baseX = p1.x + (p2.x - p1.x) * t
                let baseY = p1.y + (p2.y - p1.y) * t
                
                let hatchLength = width * CGFloat.random(in: 1.0...1.5)
                
                // Left side hatch
                path.move(to: CGPoint(x: baseX, y: baseY))
                path.addLine(to: CGPoint(
                    x: baseX - perpX * hatchLength,
                    y: baseY - perpY * hatchLength
                ))
                
                // Right side hatch
                path.move(to: CGPoint(x: baseX, y: baseY))
                path.addLine(to: CGPoint(
                    x: baseX + perpX * hatchLength,
                    y: baseY + perpY * hatchLength
                ))
            }
        }
        
        return path
    }
    
    /// Generate water wave pattern
    static func generateWaterPattern(
        points: [CGPoint],
        width: CGFloat,
        waveSize: CGFloat = 1.0
    ) -> CGPath {
        let path = CGMutablePath()
        guard points.count > 1 else { return path }

        path.move(to: points[0])

        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]

            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let waveLength = width * waveSize
            let numWaves = max(1, Int(segmentLength / waveLength))

            let dx = (p2.x - p1.x) / segmentLength
            let dy = (p2.y - p1.y) / segmentLength
            let perpX = -dy
            let perpY = dx

            var lastPoint = p1

            for j in 0...numWaves {
                let t = CGFloat(j) / CGFloat(numWaves)
                let nextX = p1.x + (p2.x - p1.x) * t
                let nextY = p1.y + (p2.y - p1.y) * t

                // Alternate wave direction
                let amplitude = width * 0.3 * (j % 2 == 0 ? 1 : -1)
                let controlX = (lastPoint.x + nextX) / 2 + perpX * amplitude
                let controlY = (lastPoint.y + nextY) / 2 + perpY * amplitude

                path.addQuadCurve(
                    to: CGPoint(x: nextX, y: nextY),
                    control: CGPoint(x: controlX, y: controlY)
                )

                lastPoint = CGPoint(x: nextX, y: nextY)
            }
        }

        return path
    }

    /// ER-0003: Generate procedural river path with realistic meandering
    static func generateProceduralRiverPath(
        points: [CGPoint],
        width: CGFloat,
        meanderIntensity: CGFloat = 0.7,
        seed: Int = Int.random(in: 0...10000)
    ) -> [CGPoint] {
        guard points.count > 1 else { return points }

        var meanderedPoints: [CGPoint] = []
        let segmentsPerSection = 8 // Controls smoothness

        // Seeded randomizer for reproducible meanders
        srand48(seed)

        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]

            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let dx = (p2.x - p1.x) / segmentLength
            let dy = (p2.y - p1.y) / segmentLength

            // Perpendicular vector for lateral displacement
            let perpX = -dy
            let perpY = dx

            // Add first point if it's the start
            if i == 0 {
                meanderedPoints.append(p1)
            }

            // Create meandering between p1 and p2
            for j in 1...segmentsPerSection {
                let t = CGFloat(j) / CGFloat(segmentsPerSection)

                // Base position along straight line
                let baseX = p1.x + (p2.x - p1.x) * t
                let baseY = p1.y + (p2.y - p1.y) * t

                // Meandering displacement using sinusoidal combination
                // Multiple frequencies create natural river-like curves
                let freq1 = 2.0 * .pi * t
                let freq2 = 5.0 * .pi * t
                let freq3 = 11.0 * .pi * t

                // Combine frequencies with different amplitudes (natural meander signature)
                let meander = sin(freq1) * 0.6 + sin(freq2) * 0.3 + sin(freq3) * 0.1

                // Add random variation for natural irregularity
                let randomVariation = CGFloat(drand48() - 0.5) * 0.3

                // Scale by width and intensity
                let displacement = (meander + randomVariation) * width * meanderIntensity

                // Apply perpendicular displacement
                let meanderedX = baseX + perpX * displacement
                let meanderedY = baseY + perpY * displacement

                meanderedPoints.append(CGPoint(x: meanderedX, y: meanderedY))
            }
        }

        // Add final point
        meanderedPoints.append(points.last!)

        return meanderedPoints
    }

    /// ER-0003: Generate river stroke with variable width (pressure-sensitive)
    static func generateRiverStrokeWithPressure(
        centerPath: [CGPoint],
        baseWidth: CGFloat,
        pressureValues: [CGFloat]? = nil
    ) -> (leftBank: [CGPoint], rightBank: [CGPoint]) {
        guard centerPath.count > 1 else {
            return ([], [])
        }

        var leftBank: [CGPoint] = []
        var rightBank: [CGPoint] = []

        for i in 0..<centerPath.count {
            let point = centerPath[i]

            // Calculate direction vector for perpendicular
            var dx: CGFloat = 0
            var dy: CGFloat = 0

            if i == 0 && centerPath.count > 1 {
                // First point: use direction to next
                dx = centerPath[i + 1].x - point.x
                dy = centerPath[i + 1].y - point.y
            } else if i == centerPath.count - 1 {
                // Last point: use direction from previous
                dx = point.x - centerPath[i - 1].x
                dy = point.y - centerPath[i - 1].y
            } else {
                // Middle points: average of both directions
                let dx1 = point.x - centerPath[i - 1].x
                let dy1 = point.y - centerPath[i - 1].y
                let dx2 = centerPath[i + 1].x - point.x
                let dy2 = centerPath[i + 1].y - point.y
                dx = (dx1 + dx2) / 2
                dy = (dy1 + dy2) / 2
            }

            let length = hypot(dx, dy)
            guard length > 0 else { continue }

            // Normalize and get perpendicular
            let normDx = dx / length
            let normDy = dy / length
            let perpX = -normDy
            let perpY = normDx

            // Apply pressure if available, otherwise use base width
            let pressure = pressureValues != nil && i < pressureValues!.count ? pressureValues![i] : 1.0
            let halfWidth = (baseWidth * pressure) / 2

            // Calculate bank points
            let leftX = point.x + perpX * halfWidth
            let leftY = point.y + perpY * halfWidth
            let rightX = point.x - perpX * halfWidth
            let rightY = point.y - perpY * halfWidth

            leftBank.append(CGPoint(x: leftX, y: leftY))
            rightBank.append(CGPoint(x: rightX, y: rightY))
        }

        return (leftBank, rightBank)
    }
    
    // MARK: - Road & Path Patterns
    
    /// Generate road with parallel lines
    static func generateRoadPattern(
        points: [CGPoint],
        width: CGFloat,
        roadType: RoadType = .standard
    ) -> CGPath {
        let path = CGMutablePath()
        guard points.count > 1 else { return path }
        
        // Calculate offset lines
        var leftPoints: [CGPoint] = []
        var rightPoints: [CGPoint] = []
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            
            let dx = p2.x - p1.x
            let dy = p2.y - p1.y
            let distance = hypot(dx, dy)
            
            let perpX = -dy / distance
            let perpY = dx / distance
            
            let halfWidth = width / 2
            
            leftPoints.append(CGPoint(x: p1.x - perpX * halfWidth, y: p1.y - perpY * halfWidth))
            rightPoints.append(CGPoint(x: p1.x + perpX * halfWidth, y: p1.y + perpY * halfWidth))
        }
        
        // Add last points
        if let lastPoint = points.last, let secondLast = points.dropLast().last {
            let dx = lastPoint.x - secondLast.x
            let dy = lastPoint.y - secondLast.y
            let distance = hypot(dx, dy)
            let perpX = -dy / distance
            let perpY = dx / distance
            let halfWidth = width / 2
            
            leftPoints.append(CGPoint(x: lastPoint.x - perpX * halfWidth, y: lastPoint.y - perpY * halfWidth))
            rightPoints.append(CGPoint(x: lastPoint.x + perpX * halfWidth, y: lastPoint.y + perpY * halfWidth))
        }
        
        // Draw road edges
        path.move(to: leftPoints[0])
        for point in leftPoints.dropFirst() {
            path.addLine(to: point)
        }
        
        path.move(to: rightPoints[0])
        for point in rightPoints.dropFirst() {
            path.addLine(to: point)
        }
        
        // Add center line for highways
        if roadType == .highway {
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        
        return path
    }
    
    // MARK: - Render Pattern-Based Stroke
    
    /// Render a stroke using a generated pattern
    static func renderPatternStroke(
        pattern: CGPath,
        color: Color,
        width: CGFloat,
        context: CGContext
    ) {
        #if canImport(UIKit)
        let cgColor = UIColor(color).cgColor
        #elseif canImport(AppKit)
        let cgColor = NSColor(color).cgColor
        #else
        let cgColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        #endif
        
        context.setStrokeColor(cgColor)
        context.setLineWidth(width * 0.5) // Patterns often have thinner lines
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        context.addPath(pattern)
        context.strokePath()
    }
    
    /// Render a stamp-based pattern (trees, buildings)
    static func renderStampPattern(
        stamps: [(CGPoint, CGPath)],
        color: Color,
        context: CGContext
    ) {
        #if canImport(UIKit)
        let cgColor = UIColor(color).cgColor
        #elseif canImport(AppKit)
        let cgColor = NSColor(color).cgColor
        #else
        let cgColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        #endif
        
        context.setFillColor(cgColor)
        context.setStrokeColor(cgColor)
        context.setLineWidth(1.0)
        
        for (position, stampPath) in stamps {
            context.saveGState()
            context.translateBy(x: position.x, y: position.y)
            
            context.addPath(stampPath)
            context.fillPath()
            
            context.addPath(stampPath)
            context.strokePath()
            
            context.restoreGState()
        }
    }
}

// MARK: - Pattern Style Enums

enum MountainStyle {
    case jagged      // Sharp triangular peaks
    case rounded     // Smooth rounded peaks
    case layered     // Multiple overlapping peaks
}

enum CliffDirection {
    case up
    case down
}

enum RoadType {
    case path
    case standard
    case highway
}

/// ER-0003: Building styles including special landmark icons
enum BuildingStyle: CaseIterable {
    case simple       // Rectangle only
    case detailed     // Rectangle with roof
    case tower        // Tall thin rectangle
    case church       // Cross symbol + steeple
    case museum       // Large with columns
    case government   // Dome building
    case stadium      // Circular/oval
    case hospital     // Cross symbol
    case school       // Multi-window building
    case industrial   // Factory with chimney

    /// ER-0003: Get weighted random building style (special buildings are rarer)
    static func randomWeighted() -> BuildingStyle {
        let roll = CGFloat.random(in: 0...1)

        // Distribution: 70% simple buildings, 30% special
        if roll < 0.40 {
            return .simple
        } else if roll < 0.60 {
            return .detailed
        } else if roll < 0.70 {
            return .tower
        } else if roll < 0.75 {
            return .church
        } else if roll < 0.80 {
            return .museum
        } else if roll < 0.85 {
            return .government
        } else if roll < 0.90 {
            return .stadium
        } else if roll < 0.95 {
            return .hospital
        } else {
            return .school
        }
    }

    func render(in rect: CGRect, context: CGContext, color: CGColor) {
        context.setStrokeColor(color)
        context.setFillColor(color.copy(alpha: 0.3) ?? color)
        context.setLineWidth(1.5)

        switch self {
        case .simple:
            context.stroke(rect)

        case .detailed:
            // Building base
            context.stroke(rect)

            // Roof (triangle)
            let roofPath = CGMutablePath()
            roofPath.move(to: CGPoint(x: rect.minX, y: rect.minY))
            roofPath.addLine(to: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.3))
            roofPath.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            roofPath.closeSubpath()

            context.addPath(roofPath)
            context.fillPath()

        case .tower:
            // Tall building with multiple levels
            context.stroke(rect)

            let numLevels = 3
            for i in 1..<numLevels {
                let y = rect.minY + (rect.height * CGFloat(i) / CGFloat(numLevels))
                context.move(to: CGPoint(x: rect.minX, y: y))
                context.addLine(to: CGPoint(x: rect.maxX, y: y))
                context.strokePath()
            }

        case .church:
            // Church with steeple and cross
            let steepleWidth = rect.width * 0.4
            let steepleHeight = rect.height * 0.5

            // Main building
            context.stroke(rect)

            // Steeple
            let steepleRect = CGRect(
                x: rect.midX - steepleWidth / 2,
                y: rect.minY - steepleHeight,
                width: steepleWidth,
                height: steepleHeight
            )
            context.stroke(steepleRect)

            // Cross on top
            let crossSize = rect.width * 0.2
            let crossX = rect.midX
            let crossY = steepleRect.minY - crossSize
            context.move(to: CGPoint(x: crossX, y: crossY))
            context.addLine(to: CGPoint(x: crossX, y: crossY - crossSize))
            context.move(to: CGPoint(x: crossX - crossSize/2, y: crossY - crossSize/2))
            context.addLine(to: CGPoint(x: crossX + crossSize/2, y: crossY - crossSize/2))
            context.strokePath()

        case .museum:
            // Museum with columns
            context.stroke(rect)

            // Columns
            let numColumns = 4
            let columnWidth = rect.width / CGFloat(numColumns + 1)
            for i in 1...numColumns {
                let x = rect.minX + columnWidth * CGFloat(i)
                context.move(to: CGPoint(x: x, y: rect.minY))
                context.addLine(to: CGPoint(x: x, y: rect.maxY))
            }
            context.strokePath()

        case .government:
            // Government building with dome
            context.stroke(rect)

            // Dome
            let domeRect = CGRect(
                x: rect.minX + rect.width * 0.25,
                y: rect.minY - rect.height * 0.3,
                width: rect.width * 0.5,
                height: rect.height * 0.3
            )
            context.addEllipse(in: domeRect)
            context.strokePath()

        case .stadium:
            // Stadium (oval shape)
            let ovalRect = rect.insetBy(dx: 0, dy: rect.height * 0.1)
            context.addEllipse(in: ovalRect)
            context.strokePath()

            // Seating tiers
            for i in 1...2 {
                let inset = rect.width * CGFloat(i) * 0.15
                let tierRect = ovalRect.insetBy(dx: inset, dy: inset * 0.5)
                context.addEllipse(in: tierRect)
                context.strokePath()
            }

        case .hospital:
            // Hospital with large cross
            context.stroke(rect)

            // Red cross symbol
            let crossSize = rect.width * 0.4
            let crossX = rect.midX
            let crossY = rect.midY

            // Vertical bar
            context.move(to: CGPoint(x: crossX, y: crossY - crossSize/2))
            context.addLine(to: CGPoint(x: crossX, y: crossY + crossSize/2))

            // Horizontal bar
            context.move(to: CGPoint(x: crossX - crossSize/2, y: crossY))
            context.addLine(to: CGPoint(x: crossX + crossSize/2, y: crossY))
            context.strokePath()

        case .school:
            // School building with windows
            context.stroke(rect)

            // Windows in grid
            let rows = 2
            let cols = 3
            let windowWidth = rect.width / CGFloat(cols + 1)
            let windowHeight = rect.height / CGFloat(rows + 1)

            for row in 1...rows {
                for col in 1...cols {
                    let windowRect = CGRect(
                        x: rect.minX + windowWidth * CGFloat(col) - windowWidth * 0.3,
                        y: rect.minY + windowHeight * CGFloat(row) - windowHeight * 0.3,
                        width: windowWidth * 0.6,
                        height: windowHeight * 0.6
                    )
                    context.stroke(windowRect)
                }
            }

        case .industrial:
            // Factory with chimney
            context.stroke(rect)

            // Chimney
            let chimneyWidth = rect.width * 0.2
            let chimneyHeight = rect.height * 0.6
            let chimneyRect = CGRect(
                x: rect.maxX - chimneyWidth,
                y: rect.minY - chimneyHeight,
                width: chimneyWidth,
                height: chimneyHeight
            )
            context.stroke(chimneyRect)

            // Smoke (wavy line)
            context.move(to: CGPoint(x: chimneyRect.midX, y: chimneyRect.minY))
            context.addLine(to: CGPoint(x: chimneyRect.midX + 5, y: chimneyRect.minY - 10))
            context.addLine(to: CGPoint(x: chimneyRect.midX - 5, y: chimneyRect.minY - 20))
            context.strokePath()
        }
    }
}
