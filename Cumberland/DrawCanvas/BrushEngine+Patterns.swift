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
    static func generateBuildingPattern(
        points: [CGPoint],
        width: CGFloat
    ) -> [(CGRect, BuildingStyle)] {
        var buildings: [(CGRect, BuildingStyle)] = []
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            
            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let buildingSpacing = width * 3.0
            let numBuildings = max(1, Int(segmentLength / buildingSpacing))
            
            for j in 0..<numBuildings {
                let t = CGFloat(j) / CGFloat(numBuildings)
                let x = p1.x + (p2.x - p1.x) * t
                let y = p1.y + (p2.y - p1.y) * t
                
                let buildingWidth = width * CGFloat.random(in: 0.8...1.5)
                let buildingHeight = width * CGFloat.random(in: 1.0...2.0)
                
                let rect = CGRect(
                    x: x - buildingWidth / 2,
                    y: y - buildingHeight / 2,
                    width: buildingWidth,
                    height: buildingHeight
                )
                
                let style = BuildingStyle.allCases.randomElement() ?? .simple
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

enum BuildingStyle: CaseIterable {
    case simple      // Rectangle only
    case detailed    // Rectangle with roof
    case tower       // Tall thin rectangle
    
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
        }
    }
}
