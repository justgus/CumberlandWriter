//
//  BrushEngine.swift
//  Cumberland
//
//  Brush rendering engine - converts brush properties into rendered strokes
//

import SwiftUI
import Foundation
import CoreGraphics

#if canImport(PencilKit)
import PencilKit
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Seeded Random Generator

/// Simple seeded random number generator for consistent pseudo-random variation
struct SeededRandomGenerator {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(abs(seed))
        // Mix the seed to improve distribution
        self.state = self.state &* 6364136223846793005 &+ 1442695040888963407
    }

    mutating func next() -> UInt64 {
        // Linear congruential generator
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    mutating func nextDouble(in range: ClosedRange<CGFloat>) -> CGFloat {
        let normalized = CGFloat(next() % 10000) / 10000.0
        return range.lowerBound + normalized * (range.upperBound - range.lowerBound)
    }
}

// MARK: - Brush Engine

/// Handles rendering of brush strokes with various patterns and effects
class BrushEngine {
    
    // MARK: - PencilKit Tool Creation
    
    #if canImport(PencilKit)
    /// Convert a MapBrush to a PencilKit tool
    static func createPKTool(from brush: MapBrush, color: Color, width: CGFloat? = nil) -> PKTool {
        let finalWidth = width ?? brush.defaultWidth
        
        // Use base color if available, otherwise use provided color
        let brushColor = brush.color ?? color
        
        // Determine ink type based on pattern
        let inkType: PKInkingTool.InkType
        switch brush.patternType {
        case .solid:
            inkType = .pen
        case .stippled:
            inkType = .pencil
        case .dashed, .dotted:
            inkType = .pen // Will need custom rendering for true dashed/dotted
        default:
            inkType = .marker
        }
        
        #if canImport(UIKit)
        // Use toPencilKitColor() to prevent black color inversion (DR-0001)
        let pkColor = brushColor.toPencilKitColor()
        #elseif canImport(AppKit)
        let pkColor = NSColor(brushColor)
        #endif
        
        // Apply opacity
        let finalColor: PKTool
        if brush.opacity < 1.0 {
            #if canImport(UIKit)
            let adjustedColor = pkColor.withAlphaComponent(brush.opacity)
            finalColor = PKInkingTool(inkType, color: adjustedColor, width: finalWidth)
            #elseif canImport(AppKit)
            let adjustedColor = pkColor.withAlphaComponent(brush.opacity)
            finalColor = PKInkingTool(inkType, color: adjustedColor, width: finalWidth)
            #endif
        } else {
            finalColor = PKInkingTool(inkType, color: pkColor, width: finalWidth)
        }
        
        return finalColor
    }
    #endif
    
    // MARK: - Core Graphics Rendering
    
    /// Render a brush stroke in a Core Graphics context
    static func renderStroke(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat? = nil,
        context: CGContext
    ) {
        guard points.count > 1 else { return }
        
        let finalWidth = width ?? brush.defaultWidth
        
        // Apply brush settings to context
        context.saveGState()
        context.setAlpha(brush.opacity)
        context.setBlendMode(brush.blendMode.cgBlendMode)
        
        // Apply smoothing if needed
        let smoothedPoints = brush.smoothing > 0 ? smoothPath(points, amount: brush.smoothing) : points
        
        // Render based on pattern type
        switch brush.patternType {
        case .solid:
            renderSolidStroke(points: smoothedPoints, color: color, width: finalWidth, brush: brush, context: context)
            
        case .dashed:
            renderDashedStroke(points: smoothedPoints, color: color, width: finalWidth, context: context)
            
        case .dotted:
            renderDottedStroke(points: smoothedPoints, color: color, width: finalWidth, context: context)
            
        case .stippled:
            renderStippledStroke(points: smoothedPoints, color: color, width: finalWidth, context: context)
            
        case .stamp:
            renderStampStroke(points: smoothedPoints, brush: brush, color: color, width: finalWidth, context: context)
            
        case .hatched:
            renderHatchedStroke(points: smoothedPoints, color: color, width: finalWidth, context: context)
            
        case .crossHatched:
            renderCrossHatchedStroke(points: smoothedPoints, color: color, width: finalWidth, context: context)
            
        case .textured:
            // Textured rendering will be implemented in Phase 3
            renderSolidStroke(points: smoothedPoints, color: color, width: finalWidth, brush: brush, context: context)
        }
        
        context.restoreGState()
    }
    
    // MARK: - Public wrappers for pattern renderers
    
    /// Public wrapper for dotted stroke rendering
    /// For use by demos or external callers without exposing internal implementation details.
    static func dottedStroke(
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        context: CGContext
    ) {
        renderDottedStroke(points: points, color: color, width: width, context: context)
    }
    
    // MARK: - Pattern Renderers
    
    static func renderSolidStroke(
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        brush: MapBrush,
        context: CGContext
    ) {
        #if canImport(UIKit)
        let cgColor = UIColor(color).cgColor
        #elseif canImport(AppKit)
        let cgColor = NSColor(color).cgColor
        #else
        let cgColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        #endif
        
        // Apply pressure sensitivity and tapering if enabled
        if brush.pressureSensitivity || brush.taperStart || brush.taperEnd {
            renderVariableWidthStroke(
                points: points,
                color: color,
                width: width,
                brush: brush,
                context: context
            )
        } else {
            // Standard fixed-width stroke
            context.setStrokeColor(cgColor)
            context.setLineWidth(width)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            
            context.beginPath()
            context.move(to: points[0])
            
            for point in points.dropFirst() {
                context.addLine(to: point)
            }
            
            context.strokePath()
        }
    }
    
    /// Render stroke with variable width (for pressure sensitivity and tapering)
    static func renderVariableWidthStroke(
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        brush: MapBrush,
        context: CGContext
    ) {
        guard points.count > 1 else { return }
        
        #if canImport(UIKit)
        let cgColor = UIColor(color).cgColor
        #elseif canImport(AppKit)
        let cgColor = NSColor(color).cgColor
        #else
        let cgColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        #endif
        
        context.setFillColor(cgColor)
        
        // Calculate width for each point based on position in stroke
        let pointCount = points.count
        
        for i in 0..<(pointCount - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            
            // Calculate progress through stroke (0.0 to 1.0)
            let progress = CGFloat(i) / CGFloat(pointCount - 1)
            
            // Calculate width multiplier based on tapering
            var widthMultiplier: CGFloat = 1.0
            
            if brush.taperStart && progress < 0.2 {
                // Taper in at start (0% to 20%)
                widthMultiplier = progress / 0.2
            } else if brush.taperEnd && progress > 0.8 {
                // Taper out at end (80% to 100%)
                widthMultiplier = (1.0 - progress) / 0.2
            }
            
            let segmentWidth = width * widthMultiplier
            
            // Draw segment as filled polygon
            let dx = p2.x - p1.x
            let dy = p2.y - p1.y
            let distance = hypot(dx, dy)
            
            guard distance > 0 else { continue }
            
            let perpX = -dy / distance
            let perpY = dx / distance
            
            let halfWidth = segmentWidth / 2
            
            context.beginPath()
            context.move(to: CGPoint(x: p1.x + perpX * halfWidth, y: p1.y + perpY * halfWidth))
            context.addLine(to: CGPoint(x: p1.x - perpX * halfWidth, y: p1.y - perpY * halfWidth))
            context.addLine(to: CGPoint(x: p2.x - perpX * halfWidth, y: p2.y - perpY * halfWidth))
            context.addLine(to: CGPoint(x: p2.x + perpX * halfWidth, y: p2.y + perpY * halfWidth))
            context.closePath()
            context.fillPath()
        }
    }
    
    static func renderDashedStroke(
        points: [CGPoint],
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
        context.setLineWidth(width)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // Set dash pattern: [dash length, gap length]
        let dashPattern: [CGFloat] = [width * 3, width * 2]
        context.setLineDash(phase: 0, lengths: dashPattern)
        
        context.beginPath()
        context.move(to: points[0])
        
        for point in points.dropFirst() {
            context.addLine(to: point)
        }
        
        context.strokePath()
        
        // Reset dash pattern
        context.setLineDash(phase: 0, lengths: [])
    }
    
    static func renderDottedStroke(
        points: [CGPoint],
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
        context.setLineWidth(width)
        context.setLineCap(.round)
        
        // Set dot pattern: very short dash with gap
        let dotPattern: [CGFloat] = [0.5, width * 1.5]
        context.setLineDash(phase: 0, lengths: dotPattern)
        
        context.beginPath()
        context.move(to: points[0])
        
        for point in points.dropFirst() {
            context.addLine(to: point)
        }
        
        context.strokePath()
        
        // Reset dash pattern
        context.setLineDash(phase: 0, lengths: [])
    }
    
    static func renderStippledStroke(
        points: [CGPoint],
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
        
        context.setFillColor(cgColor)
        
        // Draw small circles along the path
        let spacing = width * 0.5
        var _: CGFloat = 0
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            
            var t: CGFloat = 0
            while t < segmentLength {
                let progress = t / segmentLength
                let x = p1.x + (p2.x - p1.x) * progress
                let y = p1.y + (p2.y - p1.y) * progress
                
                // Add small random offset for stipple effect
                let offsetX = CGFloat.random(in: -width*0.3...width*0.3)
                let offsetY = CGFloat.random(in: -width*0.3...width*0.3)
                
                let dotSize = width * CGFloat.random(in: 0.3...0.7)
                let dotRect = CGRect(
                    x: x + offsetX - dotSize/2,
                    y: y + offsetY - dotSize/2,
                    width: dotSize,
                    height: dotSize
                )
                
                context.fillEllipse(in: dotRect)
                
                t += spacing
            }
        }
    }
    
    static func renderStampStroke(
        points: [CGPoint],
        brush: MapBrush,
        color: Color,
        width: CGFloat,
        context: CGContext
    ) {
        // Stamp pattern - place symbols at intervals
        // This will be expanded in Phase 3 with actual stamp patterns
        #if canImport(UIKit)
        let cgColor = UIColor(color).cgColor
        #elseif canImport(AppKit)
        let cgColor = NSColor(color).cgColor
        #else
        let cgColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        #endif
        
        context.setFillColor(cgColor)
        
        let spacing = brush.spacing * width
        var _: CGFloat = 0
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            
            var t: CGFloat = 0
            while t < segmentLength {
                let progress = t / segmentLength
                let x = p1.x + (p2.x - p1.x) * progress
                let y = p1.y + (p2.y - p1.y) * progress
                
                // Draw a simple circle stamp (will be replaced with actual patterns)
                let stampSize = width * (1.0 + CGFloat.random(in: -brush.sizeVariation...brush.sizeVariation))
                let stampRect = CGRect(
                    x: x - stampSize/2,
                    y: y - stampSize/2,
                    width: stampSize,
                    height: stampSize
                )
                
                context.fillEllipse(in: stampRect)
                
                t += spacing
            }
        }
    }
    
    static func renderHatchedStroke(
        points: [CGPoint],
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
        context.setLineWidth(width * 0.5)
        context.setLineCap(.butt)
        
        // Draw parallel lines perpendicular to the stroke
        let spacing = width * 2
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            
            // Calculate perpendicular direction
            let dx = (p2.x - p1.x) / segmentLength
            let dy = (p2.y - p1.y) / segmentLength
            let perpX = -dy
            let perpY = dx
            
            var t: CGFloat = 0
            while t < segmentLength {
                let _ = t / segmentLength
                let x = p1.x + dx * t
                let y = p1.y + dy * t
                
                // Draw hatch line
                context.move(to: CGPoint(x: x, y: y))
                context.addLine(to: CGPoint(
                    x: x + perpX * width * 2,
                    y: y + perpY * width * 2
                ))
                
                t += spacing
            }
        }
        
        context.strokePath()
    }
    
    static func renderCrossHatchedStroke(
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        context: CGContext
    ) {
        // Render hatching in both directions
        renderHatchedStroke(points: points, color: color, width: width, context: context)
        
        // Render second set of hatches in opposite direction
        #if canImport(UIKit)
        let cgColor = UIColor(color).cgColor
        #elseif canImport(AppKit)
        let cgColor = NSColor(color).cgColor
        #else
        let cgColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        #endif
        
        context.setStrokeColor(cgColor)
        context.setLineWidth(width * 0.5)
        
        let spacing = width * 2
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            
            let dx = (p2.x - p1.x) / segmentLength
            let dy = (p2.y - p1.y) / segmentLength
            let perpX = dy  // Opposite direction from hatching
            let perpY = -dx
            
            var t: CGFloat = 0
            while t < segmentLength {
                let _ = t / segmentLength
                let x = p1.x + dx * t
                let y = p1.y + dy * t
                
                context.move(to: CGPoint(x: x, y: y))
                context.addLine(to: CGPoint(
                    x: x + perpX * width * 2,
                    y: y + perpY * width * 2
                ))
                
                t += spacing
            }
        }
        
        context.strokePath()
    }
    
    // MARK: - Path Smoothing
    
    /// Apply Catmull-Rom spline smoothing to a path
    static func smoothPath(_ points: [CGPoint], amount: CGFloat) -> [CGPoint] {
        guard points.count > 2, amount > 0 else { return points }
        
        var smoothedPoints: [CGPoint] = []
        smoothedPoints.append(points[0]) // Keep first point
        
        // Simple moving average smoothing
        let windowSize = max(2, Int(amount * 5))
        
        for i in 1..<(points.count - 1) {
            let startIndex = max(0, i - windowSize/2)
            let endIndex = min(points.count - 1, i + windowSize/2)
            
            var sumX: CGFloat = 0
            var sumY: CGFloat = 0
            var count: CGFloat = 0
            
            for j in startIndex...endIndex {
                sumX += points[j].x
                sumY += points[j].y
                count += 1
            }
            
            let avgX = sumX / count
            let avgY = sumY / count
            
            // Interpolate between original and smoothed point
            let smoothedX = points[i].x + (avgX - points[i].x) * amount
            let smoothedY = points[i].y + (avgY - points[i].y) * amount
            
            smoothedPoints.append(CGPoint(x: smoothedX, y: smoothedY))
        }
        
        smoothedPoints.append(points[points.count - 1]) // Keep last point
        
        return smoothedPoints
    }
    
    // MARK: - Grid Snapping
    
    /// Snap points to a grid
    static func snapToGrid(_ points: [CGPoint], gridSpacing: CGFloat) -> [CGPoint] {
        points.map { point in
            CGPoint(
                x: round(point.x / gridSpacing) * gridSpacing,
                y: round(point.y / gridSpacing) * gridSpacing
            )
        }
    }
    
    // MARK: - Advanced Pattern Rendering Integration
    
    /// Render brush stroke using category-specific pattern generation
    static func renderAdvancedStroke(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat? = nil,
        context: CGContext,
        terrainMetadata: TerrainMapMetadata? = nil
    ) {
        guard points.count > 1 else { return }

        let finalWidth = width ?? brush.defaultWidth

        // Apply brush settings to context
        context.saveGState()
        context.setAlpha(brush.opacity)
        context.setBlendMode(brush.blendMode.cgBlendMode)

        // Apply smoothing if needed
        let smoothedPoints = brush.smoothing > 0 ? smoothPath(points, amount: brush.smoothing) : points

        // Use advanced pattern generators based on category
        switch brush.category {
        case .terrain:
            renderTerrainBrush(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)

        case .water:
            renderWaterBrush(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context, terrainMetadata: terrainMetadata)

        case .vegetation:
            renderVegetationBrush(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)

        case .roads:
            renderRoadBrush(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)

        case .structures:
            renderStructureBrush(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)

        case .architectural, .symbols:
            // ER-0004: Render interior/architectural brushes based on pattern type
            renderPatternBasedBrush(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)

        default:
            // Check if pattern type requires advanced rendering
            if brush.patternType == .stamp || brush.patternType == .hatched || brush.patternType == .stippled || brush.patternType == .textured {
                renderPatternBasedBrush(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)
            } else {
                // Fall back to standard rendering
                renderStroke(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)
            }
        }

        context.restoreGState()
    }
    
    // MARK: - Category-Specific Renderers
    
    static func renderTerrainBrush(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        context: CGContext
    ) {
        // Terrain brushes use procedural patterns
        if brush.name.lowercased().contains("mountain") {
            let style: MountainStyle = brush.name.lowercased().contains("rounded") ? .rounded : .jagged
            let pattern = generateMountainPattern(points: points, width: width, style: style)
            renderPatternStroke(pattern: pattern, color: color, width: width * 0.5, context: context)
            
        } else if brush.name.lowercased().contains("cliff") {
            let pattern = ProceduralPatternGenerator.generateDetailedCliff(
                points: points,
                width: width,
                height: width * 2,
                weathering: 0.6
            )
            renderPatternStroke(pattern: pattern, color: color, width: width * 0.5, context: context)
            
        } else if brush.name.lowercased().contains("ridge") {
            let pattern = ProceduralPatternGenerator.generateNaturalRidge(
                points: points,
                width: width,
                prominence: 1.0
            )
            renderPatternStroke(pattern: pattern, color: color, width: width * 0.5, context: context)
            
        } else if brush.name.lowercased().contains("hill") {
            let pattern = generateHillPattern(points: points, width: width)
            renderPatternStroke(pattern: pattern, color: color, width: width * 0.5, context: context)
            
        } else {
            // Default terrain rendering
            renderSolidStroke(points: points, color: color, width: width, brush: brush, context: context)
        }
    }
    
    /// DR-0032: Calculate scale-aware beach width based on map's physical size
    /// Base layer uses ~10% of elevation range for beaches, we match that proportion
    private static func calculateScaleAwareBeachWidth(
        brushWidth: CGFloat,
        terrainMetadata: TerrainMapMetadata?,
        waterType: WaterType
    ) -> CGFloat {
        // If no terrain metadata, fall back to percentage of brush width
        guard let metadata = terrainMetadata else {
            switch waterType {
            case .lake: return brushWidth * 0.5
            case .sea: return brushWidth * 0.55
            case .ocean: return brushWidth * 0.6
            case .river: return brushWidth * 0.3
            case .stream: return brushWidth * 0.15
            }
        }

        // Calculate beach width based on map scale
        // Base layer: beaches are ~10% of terrain features
        // For a 100-mile map, terrain features span ~10 miles, so beaches ~1 mile
        // We need to convert this to brush coordinate space
        let mapSizeMiles = metadata.physicalSizeMiles

        // Adjust beach multiplier based on map scale (larger maps = relatively smaller beaches)
        let scaleMultiplier: CGFloat
        if mapSizeMiles < 10 {
            // Small scale (village/battlefield): Proportionally larger beaches
            scaleMultiplier = 0.7
        } else if mapSizeMiles < 100 {
            // Medium scale (city/region): Moderate beaches
            scaleMultiplier = 0.5
        } else {
            // Large scale (continent/world): Proportionally smaller beaches
            scaleMultiplier = 0.35
        }

        // Apply water type hierarchy: Ocean > Sea > Lake > River > Stream
        let typeMultiplier: CGFloat
        switch waterType {
        case .ocean: typeMultiplier = 1.2
        case .sea: typeMultiplier = 1.0
        case .lake: typeMultiplier = 0.85
        case .river: typeMultiplier = 0.5
        case .stream: typeMultiplier = 0.25
        }

        return brushWidth * scaleMultiplier * typeMultiplier
    }

    enum WaterType {
        case lake, sea, ocean, river, stream
    }

    static func renderWaterBrush(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        context: CGContext,
        terrainMetadata: TerrainMapMetadata? = nil
    ) {
        if brush.name.lowercased().contains("coast") {
            let pattern = ProceduralPatternGenerator.generateDetailedCoastline(
                points: points,
                width: width,
                detail: .high,
                erosion: 0.7
            )
            renderPatternStroke(pattern: pattern, color: color, width: width * 0.5, context: context)

        } else if brush.name.lowercased().contains("river") || brush.name.lowercased().contains("stream") {
            // ER-0003: Procedural rivers with realistic meandering
            // DR-0031: Increased intensity for more visible meandering
            let isStream = brush.name.lowercased().contains("stream")
            let meanderIntensity: CGFloat = isStream ? 1.0 : 1.5
            let waterType: WaterType = isStream ? .stream : .river

            let meanderedPath = generateProceduralRiverPath(
                points: points,
                width: width,
                meanderIntensity: meanderIntensity
            )

            // DR-0031: Generate synthetic pressure values for width variation and tapered ends
            let pressureValues = generateRiverPressureProfile(pointCount: meanderedPath.count)

            // DR-0032: Calculate scale-aware beach width for sandy banks
            let beachWidth = calculateScaleAwareBeachWidth(
                brushWidth: width,
                terrainMetadata: terrainMetadata,
                waterType: waterType
            )

            // Generate outer banks (sandy beach)
            let (leftBeachBank, rightBeachBank) = generateRiverStrokeWithPressure(
                centerPath: meanderedPath,
                baseWidth: width + beachWidth * 2, // Add beach on both sides
                pressureValues: pressureValues
            )

            // Generate inner banks (water edge)
            let (leftBank, rightBank) = generateRiverStrokeWithPressure(
                centerPath: meanderedPath,
                baseWidth: width,
                pressureValues: pressureValues
            )

            // DR-0032: First, render sandy beach banks
            #if canImport(UIKit)
            let sandColor = UIColor(red: 0.90, green: 0.75, blue: 0.50, alpha: 1.0).cgColor
            #elseif canImport(AppKit)
            let sandColor = NSColor(red: 0.90, green: 0.75, blue: 0.50, alpha: 1.0).cgColor
            #else
            let sandColor = CGColor(red: 0.90, green: 0.75, blue: 0.50, alpha: 1.0)
            #endif

            context.setFillColor(sandColor)
            context.setAlpha(brush.opacity)

            context.beginPath()
            if !leftBeachBank.isEmpty {
                context.move(to: leftBeachBank[0])
                for i in 1..<leftBeachBank.count {
                    let current = leftBeachBank[i]
                    if i < leftBeachBank.count - 1 {
                        let next = leftBeachBank[i + 1]
                        let midPoint = CGPoint(
                            x: (current.x + next.x) / 2,
                            y: (current.y + next.y) / 2
                        )
                        context.addQuadCurve(to: midPoint, control: current)
                    } else {
                        context.addLine(to: current)
                    }
                }
            }
            // Connect to right beach bank (in reverse)
            if !rightBeachBank.isEmpty {
                let reversedBank = rightBeachBank.reversed()
                for (i, point) in reversedBank.enumerated() {
                    if i == 0 {
                        context.addLine(to: point)
                    } else if i < rightBeachBank.count - 1 {
                        let nextIndex = rightBeachBank.count - i - 2
                        if nextIndex >= 0 {
                            let next = rightBeachBank[nextIndex]
                            let midPoint = CGPoint(
                                x: (point.x + next.x) / 2,
                                y: (point.y + next.y) / 2
                            )
                            context.addQuadCurve(to: midPoint, control: point)
                        }
                    } else {
                        context.addLine(to: point)
                    }
                }
            }
            context.closePath()
            context.fillPath()

            // Render river water as filled polygon between inner banks
            #if canImport(UIKit)
            let cgColor = UIColor(color).cgColor
            #elseif canImport(AppKit)
            let cgColor = NSColor(color).cgColor
            #else
            let cgColor = CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1)
            #endif

            context.setFillColor(cgColor)
            context.setAlpha(brush.opacity * 0.9) // Slightly transparent for water effect

            // DR-0031: Draw filled river shape with smooth curves instead of jagged lines
            context.beginPath()
            if !leftBank.isEmpty {
                context.move(to: leftBank[0])
                // Use quadratic curves for smooth banks
                for i in 1..<leftBank.count {
                    let current = leftBank[i]
                    if i < leftBank.count - 1 {
                        let next = leftBank[i + 1]
                        let midPoint = CGPoint(
                            x: (current.x + next.x) / 2,
                            y: (current.y + next.y) / 2
                        )
                        context.addQuadCurve(to: midPoint, control: current)
                    } else {
                        context.addLine(to: current)
                    }
                }
            }
            // Connect to right bank (in reverse) with smooth curves
            if !rightBank.isEmpty {
                let reversedBank = rightBank.reversed()
                for (i, point) in reversedBank.enumerated() {
                    if i == 0 {
                        context.addLine(to: point)
                    } else if i < rightBank.count - 1 {
                        let nextIndex = rightBank.count - i - 2
                        if nextIndex >= 0 {
                            let next = rightBank[nextIndex]
                            let midPoint = CGPoint(
                                x: (point.x + next.x) / 2,
                                y: (point.y + next.y) / 2
                            )
                            context.addQuadCurve(to: midPoint, control: point)
                        }
                    } else {
                        context.addLine(to: point)
                    }
                }
            }
            context.closePath()
            context.fillPath()

            // DR-0031: Add center line for detail with smooth curves
            context.setStrokeColor(cgColor)
            context.setAlpha(brush.opacity * 0.3)
            context.setLineWidth(1.0)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.beginPath()
            if !meanderedPath.isEmpty {
                context.move(to: meanderedPath[0])
                // Smooth center line with quadratic curves
                for i in 1..<meanderedPath.count {
                    let current = meanderedPath[i]
                    if i < meanderedPath.count - 1 {
                        let next = meanderedPath[i + 1]
                        let midPoint = CGPoint(
                            x: (current.x + next.x) / 2,
                            y: (current.y + next.y) / 2
                        )
                        context.addQuadCurve(to: midPoint, control: current)
                    } else {
                        context.addLine(to: current)
                    }
                }
            }
            context.strokePath()

        } else if brush.name.lowercased().contains("wave") {
            let pattern = generateWaterPattern(points: points, width: width, waveSize: 1.0)
            renderPatternStroke(pattern: pattern, color: color, width: width * 0.5, context: context)

        // ER-0005: Ocean and Sea brushes removed (redundant with base layer)
        } else if brush.name.lowercased().contains("lake") {
            // DR-0031: Lake rendering - filled area with irregular organic shoreline
            renderLakeBrush(brush: brush, points: points, color: color, width: width, context: context, terrainMetadata: terrainMetadata)

        } else if brush.name.lowercased().contains("marsh") {
            // DR-0031: Marsh rendering - scattered vegetation with water patches
            renderMarshBrush(brush: brush, points: points, color: color, width: width, context: context)

        } else {
            // Default water rendering with slight transparency
            renderSolidStroke(points: points, color: color, width: width, brush: brush, context: context)
        }
    }

    /// DR-0031: Render lake with sandy shoreline and base-layer-matched water color
    static func renderLakeBrush(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        context: CGContext,
        terrainMetadata: TerrainMapMetadata? = nil
    ) {
        guard points.count > 1 else { return }

        let seed = Int.random(in: 0...10000)
        srand48(seed)

        // Create irregular shoreline by adding randomized offset to path
        var shorelinePoints: [CGPoint] = []
        for i in 0..<points.count {
            let point = points[i]
            let randomOffset = CGFloat(drand48() - 0.5) * width * 0.3
            let offsetPoint = CGPoint(
                x: point.x + randomOffset,
                y: point.y + randomOffset
            )
            shorelinePoints.append(offsetPoint)
        }

        // DR-0031: Use base layer colors - sand and water
        let sandColor = Color(red: 0.90, green: 0.75, blue: 0.50)  // Beach sand
        let waterColor = Color(hue: 0.55, saturation: 0.70, brightness: 0.5)  // Base layer water

        #if canImport(UIKit)
        let sandCGColor = UIColor(sandColor).cgColor
        let waterCGColor = UIColor(waterColor).cgColor
        #elseif canImport(AppKit)
        let sandCGColor = NSColor(sandColor).cgColor
        let waterCGColor = NSColor(waterColor).cgColor
        #else
        let sandCGColor = CGColor(red: 0.90, green: 0.75, blue: 0.50, alpha: 1)
        let waterCGColor = CGColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1)
        #endif

        // First, draw sandy shoreline (outer ring)
        context.setFillColor(sandCGColor)
        context.setAlpha(1.0)  // Opaque sand

        context.beginPath()
        if !shorelinePoints.isEmpty {
            context.move(to: shorelinePoints[0])
            for i in 1..<shorelinePoints.count {
                let current = shorelinePoints[i]
                if i < shorelinePoints.count - 1 {
                    let next = shorelinePoints[i + 1]
                    let midPoint = CGPoint(
                        x: (current.x + next.x) / 2,
                        y: (current.y + next.y) / 2
                    )
                    context.addQuadCurve(to: midPoint, control: current)
                } else {
                    context.addLine(to: current)
                }
            }
        }
        context.fillPath()

        // Second, draw water (slightly inset from sandy shore)
        var waterPoints: [CGPoint] = []
        // DR-0032: Use scale-aware beach width calculation
        let insetAmount = calculateScaleAwareBeachWidth(
            brushWidth: width,
            terrainMetadata: terrainMetadata,
            waterType: .lake
        )

        for i in 0..<shorelinePoints.count {
            let point = shorelinePoints[i]
            // Simple inward offset (toward center)
            let centerX = shorelinePoints.reduce(0.0) { $0 + $1.x } / CGFloat(shorelinePoints.count)
            let centerY = shorelinePoints.reduce(0.0) { $0 + $1.y } / CGFloat(shorelinePoints.count)
            let dx = centerX - point.x
            let dy = centerY - point.y
            let dist = hypot(dx, dy)
            if dist > 0 {
                let offsetX = point.x + (dx / dist) * insetAmount
                let offsetY = point.y + (dy / dist) * insetAmount
                waterPoints.append(CGPoint(x: offsetX, y: offsetY))
            } else {
                waterPoints.append(point)
            }
        }

        context.setFillColor(waterCGColor)
        context.setAlpha(1.0)  // DR-0031: Opaque water

        context.beginPath()
        if !waterPoints.isEmpty {
            context.move(to: waterPoints[0])
            for i in 1..<waterPoints.count {
                let current = waterPoints[i]
                if i < waterPoints.count - 1 {
                    let next = waterPoints[i + 1]
                    let midPoint = CGPoint(
                        x: (current.x + next.x) / 2,
                        y: (current.y + next.y) / 2
                    )
                    context.addQuadCurve(to: midPoint, control: current)
                } else {
                    context.addLine(to: current)
                }
            }
        }
        context.fillPath()

        // DR-0031: Add subtle stippling for water texture (keep this effect)
        context.setAlpha(0.2)
        for point in waterPoints where drand48() < 0.3 {
            let stippleOffset = CGPoint(
                x: point.x + CGFloat(drand48() - 0.5) * width * 0.3,
                y: point.y + CGFloat(drand48() - 0.5) * width * 0.3
            )
            context.fillEllipse(in: CGRect(x: stippleOffset.x - 1, y: stippleOffset.y - 1, width: 2, height: 2))
        }
    }

    /// DR-0031: Render marsh as filled area with scattered vegetation and water patches
    static func renderMarshBrush(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        context: CGContext
    ) {
        guard points.count > 1 else { return }

        let seed = Int.random(in: 0...10000)
        srand48(seed)

        // Create marsh boundary with slight irregularity
        var marshPoints: [CGPoint] = []
        for i in 0..<points.count {
            let point = points[i]
            let randomOffset = CGFloat(drand48() - 0.5) * width * 0.2
            let offsetPoint = CGPoint(
                x: point.x + randomOffset,
                y: point.y + randomOffset
            )
            marshPoints.append(offsetPoint)
        }

        // DR-0031: Use base layer water color for marsh water
        let waterColor = Color(hue: 0.55, saturation: 0.70, brightness: 0.45)  // Slightly darker water
        let mudColor = Color(red: 0.45, green: 0.40, blue: 0.30)  // Muddy brown

        #if canImport(UIKit)
        let mudCGColor = UIColor(mudColor).cgColor
        let waterCGColor = UIColor(waterColor).cgColor
        let vegetationColor = UIColor.green.withAlphaComponent(0.7).cgColor
        #elseif canImport(AppKit)
        let mudCGColor = NSColor(mudColor).cgColor
        let waterCGColor = NSColor(waterColor).cgColor
        let vegetationColor = NSColor.green.withAlphaComponent(0.7).cgColor
        #else
        let mudCGColor = CGColor(red: 0.45, green: 0.40, blue: 0.30, alpha: 1)
        let waterCGColor = CGColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1)
        let vegetationColor = CGColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 0.7)
        #endif

        // First, fill with muddy base
        context.setFillColor(mudCGColor)
        context.setAlpha(1.0)

        context.beginPath()
        if !marshPoints.isEmpty {
            context.move(to: marshPoints[0])
            for i in 1..<marshPoints.count {
                let current = marshPoints[i]
                if i < marshPoints.count - 1 {
                    let next = marshPoints[i + 1]
                    let midPoint = CGPoint(
                        x: (current.x + next.x) / 2,
                        y: (current.y + next.y) / 2
                    )
                    context.addQuadCurve(to: midPoint, control: current)
                } else {
                    context.addLine(to: current)
                }
            }
        }
        context.fillPath()

        // Calculate bounding box for scattering elements
        let minX = marshPoints.map { $0.x }.min() ?? 0
        let maxX = marshPoints.map { $0.x }.max() ?? 0
        let minY = marshPoints.map { $0.y }.min() ?? 0
        let maxY = marshPoints.map { $0.y }.max() ?? 0

        // Scatter water patches and vegetation throughout the area
        let density = Int(width * 3)  // More elements for wider brush
        for _ in 0..<density {
            let scatterX = minX + CGFloat(drand48()) * (maxX - minX)
            let scatterY = minY + CGFloat(drand48()) * (maxY - minY)

            if drand48() < 0.4 {
                // Draw water patch (small circle)
                context.setFillColor(waterCGColor)
                context.setAlpha(0.8)
                let patchSize = CGFloat(drand48() * 4 + 2)
                context.fillEllipse(in: CGRect(
                    x: scatterX - patchSize,
                    y: scatterY - patchSize,
                    width: patchSize * 2,
                    height: patchSize * 2
                ))
            } else {
                // Draw reed/vegetation (short vertical line)
                context.setStrokeColor(vegetationColor)
                context.setAlpha(0.8)
                context.setLineWidth(1.5)
                context.setLineCap(.round)

                let reedHeight = CGFloat(drand48() * 8 + 5)
                context.beginPath()
                context.move(to: CGPoint(x: scatterX, y: scatterY))
                context.addLine(to: CGPoint(x: scatterX + CGFloat(drand48() - 0.5) * 2, y: scatterY - reedHeight))
                context.strokePath()
            }
        }
    }

    static func renderVegetationBrush(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        context: CGContext
    ) {
        if brush.name.lowercased().contains("forest") || brush.name.lowercased().contains("tree") {
            let density: CGFloat = brush.name.lowercased().contains("dense") ? 2.0 : 1.0
            let trees = generateForestPattern(points: points, width: width, density: density)
            renderStampPattern(stamps: trees, color: color, context: context)
            
        } else {
            // Other vegetation uses stippled pattern
            renderStippledStroke(points: points, color: color, width: width, context: context)
        }
    }
    
    static func renderRoadBrush(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        context: CGContext
    ) {
        let roadType: RoadType
        if brush.name.lowercased().contains("highway") {
            roadType = .highway
        } else if brush.name.lowercased().contains("path") || brush.name.lowercased().contains("trail") {
            roadType = .path
        } else {
            roadType = .standard
        }

        // ER-0003: Apply curve smoothing for more natural roads
        var processedPoints = points

        // Smooth curves for highways and roads (not paths/trails)
        if roadType == .highway || roadType == .standard {
            processedPoints = smoothPath(points, amount: 0.5)
        }

        // ER-0003: Optional grid snapping for urban roads
        if brush.snapToGrid && roadType != .path {
            // Grid snap for urban planning (align to 45° angles and regular spacing)
            processedPoints = applyGridSnapping(processedPoints, gridSize: width * 2)
        }

        let pattern = generateRoadPattern(points: processedPoints, width: width, roadType: roadType)
        renderPatternStroke(pattern: pattern, color: color, width: width * 0.5, context: context)
    }

    /// ER-0003: Apply grid snapping to road points for urban layouts
    private static func applyGridSnapping(_ points: [CGPoint], gridSize: CGFloat) -> [CGPoint] {
        guard points.count > 1 else { return points }

        var snappedPoints: [CGPoint] = []
        snappedPoints.append(points[0]) // Keep first point

        for i in 1..<points.count {
            let prevPoint = snappedPoints.last!
            let currentPoint = points[i]

            let dx = currentPoint.x - prevPoint.x
            let dy = currentPoint.y - prevPoint.y

            // Snap to dominant axis or 45° diagonal
            let absDx = abs(dx)
            let absDy = abs(dy)

            var snappedX = currentPoint.x
            var snappedY = currentPoint.y

            // Snap to nearest 45° increment or axis-aligned direction
            if absDx > absDy * 2 {
                // Mostly horizontal - snap to horizontal
                snappedY = prevPoint.y
            } else if absDy > absDx * 2 {
                // Mostly vertical - snap to vertical
                snappedX = prevPoint.x
            } else {
                // Diagonal - snap to 45°
                let avgDistance = (absDx + absDy) / 2
                snappedX = prevPoint.x + (dx > 0 ? avgDistance : -avgDistance)
                snappedY = prevPoint.y + (dy > 0 ? avgDistance : -avgDistance)
            }

            // Snap to grid
            snappedX = round(snappedX / gridSize) * gridSize
            snappedY = round(snappedY / gridSize) * gridSize

            snappedPoints.append(CGPoint(x: snappedX, y: snappedY))
        }

        return snappedPoints
    }
    
    static func renderStructureBrush(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        context: CGContext
    ) {
        let buildings = generateBuildingPattern(points: points, width: width)
        
        #if canImport(UIKit)
        let cgColor = UIColor(color).cgColor
        #elseif canImport(AppKit)
        let cgColor = NSColor(color).cgColor
        #else
        let cgColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        #endif
        
        for (rect, style) in buildings {
            style.render(in: rect, context: context, color: cgColor)
        }
    }

    // MARK: - Pattern-Based Renderer (ER-0004)

    /// Render brushes based on their pattern type (for architectural, symbols, and other pattern-driven brushes)
    static func renderPatternBasedBrush(
        brush: MapBrush,
        points: [CGPoint],
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
        context.setFillColor(cgColor)
        context.setLineWidth(width)

        // Check if this is a wall brush - use smart wall rendering
        let brushName = brush.name.lowercased()
        if brushName.contains("wall") && brush.patternType == .solid {
            renderSmartWall(points: points, width: width, context: context, brushName: brush.name)
            return
        }

        switch brush.patternType {
        case .stamp:
            // Render stamps (symbols, furniture, etc.) along the path
            renderStampPattern(points: points, width: width, spacing: width * 2.0, context: context, brush: brush)

        case .hatched:
            // Render cross-hatch pattern for floors, areas
            renderHatchedPattern(points: points, width: width, context: context)

        case .stippled:
            // Render stippled/dotted pattern
            renderStippledPattern(points: points, width: width, context: context)

        case .textured:
            // Render textured stroke
            renderTexturedPattern(points: points, width: width, context: context)

        case .solid:
            // Check if this is an area fill brush (not a wall)
            if brushName.contains("lava") || brushName.contains("chasm") ||
               brushName.contains("carpet") || brushName.contains("water feature") {
                // Area fill - fill the entire area with solid color
                renderSolidAreaFill(points: points, width: width, context: context)
            } else {
                // Solid line - use standard rendering
                renderStroke(brush: brush, points: points, color: color, width: width, context: context)
            }

        default:
            // Fall back to standard rendering
            renderStroke(brush: brush, points: points, color: color, width: width, context: context)
        }
    }

    /// Render smart walls with straight lines, thickness, and dungeon features
    static func renderSmartWall(
        points: [CGPoint],
        width: CGFloat,
        context: CGContext,
        brushName: String
    ) {
        guard points.count > 1 else { return }

        let name = brushName.lowercased()
        let isDungeon = name.contains("dungeon") || name.contains("cavern") || name.contains("cave")
        let isThick = name.contains("thick")
        let isThin = name.contains("thin")

        // The 'width' parameter should represent 6 inches in canvas points
        // (based on grid scale: if grid = 1 foot, then width should be half a grid square)
        //
        // Standard wall = 6 inches = width
        // Thick wall = 12 inches = width * 2
        // Thin wall = 2 inches = width / 3

        let actualWidth: CGFloat
        if isThick {
            actualWidth = width * 2.0  // 12 inches = 2x standard
        } else if isThin {
            actualWidth = width / 3.0  // 2 inches = 1/3 standard
        } else {
            actualWidth = width        // 6 inches = standard
        }

        context.setLineWidth(actualWidth)
        context.setLineCap(.square)
        context.setLineJoin(.miter)

        if isDungeon {
            // Jagged, rough walls for dungeons/caverns
            renderJaggedWall(points: points, width: actualWidth, context: context)
        } else if isThin {
            // Thin wall: just two solid lines, no fill
            renderThinWall(points: points, width: actualWidth, context: context)
        } else if isThick {
            // Thick wall: two standard walls side-by-side
            renderThickWall(points: points, width: actualWidth, context: context)
        } else {
            // Standard wall: line-fill-line architectural style
            renderStraightWall(points: points, width: actualWidth, context: context)
        }
    }

    /// Render straight architectural walls - double-line architectural style
    static func renderStraightWall(
        points: [CGPoint],
        width: CGFloat,
        context: CGContext
    ) {
        guard points.count > 1 else { return }

        // Draw a perfectly straight line from start to end, ignoring all intermediate points
        let start = points.first!
        let end = points.last!

        // Calculate perpendicular direction for offset
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 0.01 else { return }

        // Unit perpendicular vector
        let perpX = -dy / length
        let perpY = dx / length

        // Wall consists of:
        // - 1" solid line on one side
        // - 4" reduced opacity rectangle in middle
        // - 1" solid line on other side
        // Total = 6" standard wall

        let solidLineThickness = width / 6.0  // 1" in canvas units
        let halfTotalThickness = width / 2.0   // 3" offset from centerline

        // Outer line 1 (offset by +3")
        let outerOffset1 = halfTotalThickness
        let outer1Start = CGPoint(
            x: start.x + perpX * outerOffset1,
            y: start.y + perpY * outerOffset1
        )
        let outer1End = CGPoint(
            x: end.x + perpX * outerOffset1,
            y: end.y + perpY * outerOffset1
        )

        // Outer line 2 (offset by -3")
        let outerOffset2 = -halfTotalThickness
        let outer2Start = CGPoint(
            x: start.x + perpX * outerOffset2,
            y: start.y + perpY * outerOffset2
        )
        let outer2End = CGPoint(
            x: end.x + perpX * outerOffset2,
            y: end.y + perpY * outerOffset2
        )

        // Draw middle fill rectangle (4" wide, reduced opacity)
        context.saveGState()
        context.setAlpha(0.3)  // Reduced opacity for interior

        let fillOffset1 = (width / 2.0) - solidLineThickness
        let fillOffset2 = -(width / 2.0) + solidLineThickness

        let fillP1 = CGPoint(x: start.x + perpX * fillOffset1, y: start.y + perpY * fillOffset1)
        let fillP2 = CGPoint(x: end.x + perpX * fillOffset1, y: end.y + perpY * fillOffset1)
        let fillP3 = CGPoint(x: end.x + perpX * fillOffset2, y: end.y + perpY * fillOffset2)
        let fillP4 = CGPoint(x: start.x + perpX * fillOffset2, y: start.y + perpY * fillOffset2)

        context.beginPath()
        context.move(to: fillP1)
        context.addLine(to: fillP2)
        context.addLine(to: fillP3)
        context.addLine(to: fillP4)
        context.closePath()
        context.fillPath()
        context.restoreGState()

        // Draw outer solid lines (1" thick each)
        context.setLineWidth(solidLineThickness)
        context.setLineCap(.square)

        // First outer line
        context.beginPath()
        context.move(to: outer1Start)
        context.addLine(to: outer1End)
        context.strokePath()

        // Second outer line
        context.beginPath()
        context.move(to: outer2Start)
        context.addLine(to: outer2End)
        context.strokePath()
    }

    /// Render thin walls - just two solid lines (no fill rectangle)
    static func renderThinWall(
        points: [CGPoint],
        width: CGFloat,
        context: CGContext
    ) {
        guard points.count > 1 else { return }

        let start = points.first!
        let end = points.last!

        // Calculate perpendicular direction
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 0.01 else { return }

        let perpX = -dy / length
        let perpY = dx / length

        // Thin wall = two 1" lines separated by nothing
        // Total width = 2", so each line offset by ±1"
        let halfWidth = width / 2.0
        let lineThickness = width / 2.0  // Each line is 1" thick

        // Line 1 (offset +1")
        let line1Start = CGPoint(x: start.x + perpX * halfWidth, y: start.y + perpY * halfWidth)
        let line1End = CGPoint(x: end.x + perpX * halfWidth, y: end.y + perpY * halfWidth)

        // Line 2 (offset -1")
        let line2Start = CGPoint(x: start.x - perpX * halfWidth, y: start.y - perpY * halfWidth)
        let line2End = CGPoint(x: end.x - perpX * halfWidth, y: end.y - perpY * halfWidth)

        context.setLineWidth(lineThickness)
        context.setLineCap(.square)

        // Draw both lines
        context.beginPath()
        context.move(to: line1Start)
        context.addLine(to: line1End)
        context.strokePath()

        context.beginPath()
        context.move(to: line2Start)
        context.addLine(to: line2End)
        context.strokePath()
    }

    /// Render thick walls - two standard walls side-by-side
    static func renderThickWall(
        points: [CGPoint],
        width: CGFloat,
        context: CGContext
    ) {
        guard points.count > 1 else { return }

        let start = points.first!
        let end = points.last!

        // Calculate perpendicular direction
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 0.01 else { return }

        let perpX = -dy / length
        let perpY = dx / length

        // Thick wall = two standard 6" walls side-by-side = 12" total
        // Each standard wall is 6" (half the total width)
        let standardWallWidth = width / 2.0

        // Offset each wall by ±3" from center
        let offsetDistance = standardWallWidth / 2.0

        // Render first wall (offset +3")
        let wall1Start = CGPoint(x: start.x + perpX * offsetDistance, y: start.y + perpY * offsetDistance)
        let wall1End = CGPoint(x: end.x + perpX * offsetDistance, y: end.y + perpY * offsetDistance)
        renderStandardWallSegment(from: wall1Start, to: wall1End, width: standardWallWidth, context: context)

        // Render second wall (offset -3")
        let wall2Start = CGPoint(x: start.x - perpX * offsetDistance, y: start.y - perpY * offsetDistance)
        let wall2End = CGPoint(x: end.x - perpX * offsetDistance, y: end.y - perpY * offsetDistance)
        renderStandardWallSegment(from: wall2Start, to: wall2End, width: standardWallWidth, context: context)
    }

    /// Helper: Render a single standard wall segment (line-fill-line)
    static func renderStandardWallSegment(
        from start: CGPoint,
        to end: CGPoint,
        width: CGFloat,
        context: CGContext
    ) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 0.01 else { return }

        let perpX = -dy / length
        let perpY = dx / length

        let solidLineThickness = width / 6.0
        let halfTotalThickness = width / 2.0

        // Outer lines
        let outer1Start = CGPoint(x: start.x + perpX * halfTotalThickness, y: start.y + perpY * halfTotalThickness)
        let outer1End = CGPoint(x: end.x + perpX * halfTotalThickness, y: end.y + perpY * halfTotalThickness)
        let outer2Start = CGPoint(x: start.x - perpX * halfTotalThickness, y: start.y - perpY * halfTotalThickness)
        let outer2End = CGPoint(x: end.x - perpX * halfTotalThickness, y: end.y - perpY * halfTotalThickness)

        // Middle fill
        context.saveGState()
        context.setAlpha(0.3)

        let fillOffset1 = halfTotalThickness - solidLineThickness
        let fillOffset2 = -halfTotalThickness + solidLineThickness

        let fillP1 = CGPoint(x: start.x + perpX * fillOffset1, y: start.y + perpY * fillOffset1)
        let fillP2 = CGPoint(x: end.x + perpX * fillOffset1, y: end.y + perpY * fillOffset1)
        let fillP3 = CGPoint(x: end.x + perpX * fillOffset2, y: end.y + perpY * fillOffset2)
        let fillP4 = CGPoint(x: start.x + perpX * fillOffset2, y: start.y + perpY * fillOffset2)

        context.beginPath()
        context.move(to: fillP1)
        context.addLine(to: fillP2)
        context.addLine(to: fillP3)
        context.addLine(to: fillP4)
        context.closePath()
        context.fillPath()
        context.restoreGState()

        // Draw outer lines
        context.setLineWidth(solidLineThickness)
        context.setLineCap(.square)

        context.beginPath()
        context.move(to: outer1Start)
        context.addLine(to: outer1End)
        context.strokePath()

        context.beginPath()
        context.move(to: outer2Start)
        context.addLine(to: outer2End)
        context.strokePath()
    }

    /// Render jagged dungeon/cavern walls - straight line with jaggedness
    static func renderJaggedWall(
        points: [CGPoint],
        width: CGFloat,
        context: CGContext
    ) {
        guard points.count > 1 else { return }

        // Use ONLY start and end points - ignore mouse path
        let start = points.first!
        let end = points.last!

        // Calculate straight line direction
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lineLength = hypot(dx, dy)

        guard lineLength > 0.01 else { return }

        // Unit vectors along and perpendicular to line
        let dirX = dx / lineLength
        let dirY = dy / lineLength
        let perpX = -dirY
        let perpY = dirX

        // Cave walls: organic varied amplitude
        let baseAmplitude = width * 0.5 // Maximum deviation from centerline

        // Lower frequency - longer wavelengths for more organic feel
        let primaryWavelength: CGFloat = 30.0 // Main undulation
        let secondaryWavelength: CGFloat = 12.0 // Finer detail

        // Generate jagged points along the straight line
        context.beginPath()
        context.move(to: start)

        // Fewer segments for lower frequency (one every ~8 canvas units)
        let numSegments = max(3, Int(lineLength / 8.0))

        // Use random seed based on start point for consistent variation
        let seed = Int(start.x * 1000 + start.y * 1000)
        var rng = SeededRandomGenerator(seed: seed)

        for i in 1..<numSegments {
            let t = CGFloat(i) / CGFloat(numSegments)
            let distanceAlongLine = t * lineLength

            // Base point on the straight line
            let baseX = start.x + dirX * distanceAlongLine
            let baseY = start.y + dirY * distanceAlongLine

            // Layered sine waves for organic variation
            // Primary wave: large, slow undulation
            let primaryPhase = (distanceAlongLine / primaryWavelength) * 2.0 * CGFloat.pi
            let primaryOffset = sin(primaryPhase)

            // Secondary wave: finer detail at lower amplitude
            let secondaryPhase = (distanceAlongLine / secondaryWavelength) * 2.0 * CGFloat.pi
            let secondaryOffset = sin(secondaryPhase) * 0.3

            // Vary amplitude along the wall for organic feel (use slower noise)
            let amplitudePhase = (distanceAlongLine / (primaryWavelength * 2.0)) * 2.0 * CGFloat.pi
            let amplitudeVariation = 0.7 + sin(amplitudePhase) * 0.3 // Range: 0.4 to 1.0

            // Combine waves with varied amplitude
            let combinedOffset = (primaryOffset + secondaryOffset) * baseAmplitude * amplitudeVariation

            // Add subtle random variation (seeded for consistency)
            let randomVariation = rng.nextDouble(in: -0.15...0.15) * baseAmplitude
            let offset = combinedOffset + randomVariation

            let jaggedX = baseX + perpX * offset
            let jaggedY = baseY + perpY * offset

            context.addLine(to: CGPoint(x: jaggedX, y: jaggedY))
        }

        // End at the actual end point (not jagged)
        context.addLine(to: end)
        context.strokePath()
    }

    /// Render stamp pattern - ALWAYS place single item, sized and oriented by drag
    static func renderStampPattern(
        points: [CGPoint],
        width: CGFloat,
        spacing: CGFloat,
        context: CGContext,
        brush: MapBrush
    ) {
        guard points.count > 1 else { return }

        // ER-0004: Click-and-drag interaction for stamp brushes
        // ALWAYS render a single item - user feedback: "I'd like the switch to never occur"
        // Drag defines bounding box: start = upper-left corner, end = lower-right corner

        let start = points.first!
        let end = points.last!

        // Calculate bounding box dimensions
        let dx = end.x - start.x
        let dy = end.y - start.y
        let boxWidth = abs(dx)
        let boxHeight = abs(dy)

        // Size is the diagonal of the bounding box (max dimension for square objects)
        // Or we could use the larger of width/height
        let itemSize = max(boxWidth, boxHeight)

        // Position is the CENTER of the bounding box
        let centerX = start.x + dx / 2.0
        let centerY = start.y + dy / 2.0
        let center = CGPoint(x: centerX, y: centerY)

        // NO ROTATION - keep items axis-aligned (not rotated by drag direction)
        // User feedback: stamps were rotating 45° when dragging corner-to-corner
        let angle: CGFloat = 0

        // Minimum size threshold (don't let items get too tiny)
        let minSize: CGFloat = 20.0
        let finalSize = max(itemSize, minSize)

        // Place ONE item at the CENTER of bounding box, sized by drag dimensions, axis-aligned
        renderStampShape(
            at: center,
            size: finalSize,
            angle: angle,
            context: context,
            brushName: brush.name
        )
    }

    /// Render specific stamp shapes based on brush name
    static func renderStampShape(
        at position: CGPoint,
        size: CGFloat,
        angle: CGFloat,
        context: CGContext,
        brushName: String
    ) {
        context.saveGState()
        context.translateBy(x: position.x, y: position.y)
        context.rotate(by: angle)

        let name = brushName.lowercased()

        if name.contains("door") {
            // Draw door arc
            let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
            context.setLineWidth(2.0)

            // Door frame
            context.stroke(rect)

            // Door swing arc
            context.beginPath()
            context.addArc(center: CGPoint(x: -size/2, y: size/2),
                          radius: size,
                          startAngle: -CGFloat.pi/2,
                          endAngle: 0,
                          clockwise: false)
            context.strokePath()

        } else if name.contains("archway") || name.contains("arch") {
            // Draw archway - gap in wall with arched top
            let wallThickness = size * 0.15
            context.setLineWidth(wallThickness)

            // Left wall segment
            context.beginPath()
            context.move(to: CGPoint(x: -size/2, y: size/2))
            context.addLine(to: CGPoint(x: -size/2, y: -size/4))
            context.strokePath()

            // Right wall segment
            context.beginPath()
            context.move(to: CGPoint(x: size/2, y: size/2))
            context.addLine(to: CGPoint(x: size/2, y: -size/4))
            context.strokePath()

            // Arch top (semicircle connecting the walls)
            context.beginPath()
            context.addArc(center: CGPoint(x: 0, y: -size/4),
                          radius: size/2,
                          startAngle: CGFloat.pi,
                          endAngle: 0,
                          clockwise: false)
            context.strokePath()

        } else if name.contains("portcullis") || name.contains("gate") {
            // Draw portcullis - gap in wall filled with small circles (bars)
            let wallThickness = size * 0.15
            context.setLineWidth(wallThickness)

            // Left wall segment
            context.beginPath()
            context.move(to: CGPoint(x: -size/2, y: size/2))
            context.addLine(to: CGPoint(x: -size/2, y: -size/2))
            context.strokePath()

            // Right wall segment
            context.beginPath()
            context.move(to: CGPoint(x: size/2, y: size/2))
            context.addLine(to: CGPoint(x: size/2, y: -size/2))
            context.strokePath()

            // Top wall segment
            context.beginPath()
            context.move(to: CGPoint(x: -size/2, y: -size/2))
            context.addLine(to: CGPoint(x: size/2, y: -size/2))
            context.strokePath()

            // Fill gap with small circles representing bars
            let barSize = size * 0.08
            let barSpacing = size * 0.15
            let gapWidth = size - wallThickness * 2
            let gapHeight = size * 0.8

            // Draw vertical bars (small circles in rows and columns)
            var x = -gapWidth/2 + barSpacing
            while x <= gapWidth/2 {
                var y = -gapHeight/2 + barSpacing
                while y <= gapHeight/2 {
                    let barRect = CGRect(x: x - barSize/2, y: y - barSize/2, width: barSize, height: barSize)
                    context.fillEllipse(in: barRect)
                    y += barSpacing
                }
                x += barSpacing
            }

        } else if name.contains("window") {
            // Draw window (cross pattern)
            let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
            context.setLineWidth(2.0)
            context.stroke(rect)

            // Cross panes
            context.beginPath()
            context.move(to: CGPoint(x: -size/2, y: 0))
            context.addLine(to: CGPoint(x: size/2, y: 0))
            context.move(to: CGPoint(x: 0, y: -size/2))
            context.addLine(to: CGPoint(x: 0, y: size/2))
            context.strokePath()

        } else if name.contains("round") && name.contains("table") {
            // Draw round table (circle)
            let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
            context.fillEllipse(in: rect)
            context.setLineWidth(1.5)
            context.strokeEllipse(in: rect)

        } else if name.contains("table") {
            // Draw table (rectangle)
            let rect = CGRect(x: -size/2, y: -size/3, width: size, height: size * 0.66)
            context.fill(rect)
            context.setLineWidth(1.5)
            context.stroke(rect)

        } else if name.contains("chair") {
            // Draw chair (small square with back)
            let seatSize = size * 0.6
            let seatRect = CGRect(x: -seatSize/2, y: -seatSize/4, width: seatSize, height: seatSize/2)
            context.fill(seatRect)

            // Chair back
            let backRect = CGRect(x: -seatSize/2, y: -seatSize/2, width: seatSize, height: seatSize/4)
            context.fill(backRect)

        } else if name.contains("bed") {
            // Draw bed (rectangle with headboard)
            let bedRect = CGRect(x: -size/2, y: -size/3, width: size, height: size * 0.66)
            context.fill(bedRect)

            // Headboard
            context.setLineWidth(3.0)
            context.beginPath()
            context.move(to: CGPoint(x: -size/2, y: -size/3))
            context.addLine(to: CGPoint(x: size/2, y: -size/3))
            context.strokePath()

        } else if name.contains("chest") || name.contains("crate") {
            // Draw chest/crate (square with X)
            let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
            context.fill(rect)
            context.setLineWidth(1.5)
            context.stroke(rect)

            // X pattern
            context.beginPath()
            context.move(to: CGPoint(x: -size/2, y: -size/2))
            context.addLine(to: CGPoint(x: size/2, y: size/2))
            context.move(to: CGPoint(x: size/2, y: -size/2))
            context.addLine(to: CGPoint(x: -size/2, y: size/2))
            context.strokePath()

        } else if name.contains("throne") {
            // Draw throne (chair with high back)
            let seatSize = size * 0.7
            let seatRect = CGRect(x: -seatSize/2, y: -seatSize/4, width: seatSize, height: seatSize/2)
            context.fill(seatRect)

            // High back
            let backRect = CGRect(x: -seatSize/3, y: -size/2, width: seatSize * 0.66, height: size * 0.4)
            context.fill(backRect)

            // Armrests
            context.setLineWidth(2.0)
            context.beginPath()
            context.move(to: CGPoint(x: -seatSize/2, y: -seatSize/4))
            context.addLine(to: CGPoint(x: -seatSize/1.5, y: -seatSize/4))
            context.move(to: CGPoint(x: seatSize/2, y: -seatSize/4))
            context.addLine(to: CGPoint(x: seatSize/1.5, y: -seatSize/4))
            context.strokePath()

        } else if name.contains("altar") {
            // Draw altar (elevated platform)
            let altarRect = CGRect(x: -size/2, y: -size/4, width: size, height: size/2)
            context.fill(altarRect)

            // Base
            let baseRect = CGRect(x: -size/3, y: size/4, width: size * 0.66, height: size/8)
            context.fill(baseRect)

        } else if name.contains("statue") {
            // Draw statue (pedestal with figure)
            let pedestalRect = CGRect(x: -size/3, y: size/6, width: size * 0.66, height: size/3)
            context.fill(pedestalRect)

            // Figure (circle on top)
            let figureRect = CGRect(x: -size/4, y: -size/2, width: size/2, height: size * 0.66)
            context.fillEllipse(in: figureRect)

        } else if name.contains("column") || name.contains("pillar") {
            // Draw column (circle)
            let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
            context.fillEllipse(in: rect)
            context.setLineWidth(2.0)
            context.strokeEllipse(in: rect)

        } else if name.contains("barrel") || name.contains("keg") {
            // Draw barrel (oval)
            let rect = CGRect(x: -size/2, y: -size/3, width: size, height: size * 0.66)
            context.fillEllipse(in: rect)

            // Bands
            context.setLineWidth(1.5)
            context.beginPath()
            context.move(to: CGPoint(x: -size/2, y: -size/6))
            context.addLine(to: CGPoint(x: size/2, y: -size/6))
            context.move(to: CGPoint(x: -size/2, y: size/6))
            context.addLine(to: CGPoint(x: size/2, y: size/6))
            context.strokePath()

        } else {
            // Default: circle
            let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
            context.fillEllipse(in: rect)
        }

        context.restoreGState()
    }

    /// Render hatched pattern - area fill with hatch lines (for stairs, floors, grids)
    static func renderHatchedPattern(
        points: [CGPoint],
        width: CGFloat,
        context: CGContext
    ) {
        guard points.count > 1 else { return }

        // Create closed path
        let clipPath = CGMutablePath()
        clipPath.move(to: points[0])
        for point in points.dropFirst() {
            clipPath.addLine(to: point)
        }
        clipPath.closeSubpath()

        // Fill with light base color
        context.saveGState()
        context.setAlpha(0.2)
        context.addPath(clipPath)
        context.fillPath()
        context.restoreGState()

        // Draw hatch lines across the area
        // Calculate bounding box
        let boundingBox = clipPath.boundingBox
        guard !boundingBox.isEmpty else {
            return
        }

        let hatchSpacing = width * 0.4
        let hatchAngle = CGFloat.pi / 4 // 45 degrees

        // Draw diagonal hatch lines
        context.setLineWidth(1.0)

        // First direction (/)
        let diagonal = hypot(boundingBox.width, boundingBox.height)
        var offset: CGFloat = -diagonal

        while offset < diagonal * 2 {
            let startX = boundingBox.minX + offset
            let startY = boundingBox.minY
            let endX = boundingBox.minX + offset + boundingBox.height * tan(hatchAngle)
            let endY = boundingBox.maxY

            context.saveGState()
            context.addPath(clipPath)
            context.clip()

            context.beginPath()
            context.move(to: CGPoint(x: startX, y: startY))
            context.addLine(to: CGPoint(x: endX, y: endY))
            context.strokePath()

            context.restoreGState()

            offset += hatchSpacing
        }

        // Second direction (\) for cross-hatch
        offset = -diagonal
        while offset < diagonal * 2 {
            let startX = boundingBox.maxX - offset
            let startY = boundingBox.minY
            let endX = boundingBox.maxX - offset - boundingBox.height * tan(hatchAngle)
            let endY = boundingBox.maxY

            context.saveGState()
            context.addPath(clipPath)
            context.clip()

            context.beginPath()
            context.move(to: CGPoint(x: startX, y: startY))
            context.addLine(to: CGPoint(x: endX, y: endY))
            context.strokePath()

            context.restoreGState()

            offset += hatchSpacing
        }
    }

    /// Render stippled pattern - area fill with dots (for rubble, rough surfaces)
    static func renderStippledPattern(
        points: [CGPoint],
        width: CGFloat,
        context: CGContext
    ) {
        guard points.count > 1 else { return }

        // Create closed path
        let clipPath = CGMutablePath()
        clipPath.move(to: points[0])
        for point in points.dropFirst() {
            clipPath.addLine(to: point)
        }
        clipPath.closeSubpath()

        // Fill with light base color
        context.saveGState()
        context.setAlpha(0.15)
        context.addPath(clipPath)
        context.fillPath()
        context.restoreGState()

        // Draw dots densely across the area
        let boundingBox = clipPath.boundingBox
        guard !boundingBox.isEmpty else {
            return
        }

        let dotSpacing = width * 0.2
        let minDotSize = width * 0.05
        let maxDotSize = width * 0.15

        // Clip to the closed path area
        context.saveGState()
        context.addPath(clipPath)
        context.clip()

        // Generate random dots within the bounding box
        let numDotsX = Int(boundingBox.width / dotSpacing) + 1
        let numDotsY = Int(boundingBox.height / dotSpacing) + 1

        for i in 0..<numDotsX {
            for j in 0..<numDotsY {
                let baseX = boundingBox.minX + CGFloat(i) * dotSpacing
                let baseY = boundingBox.minY + CGFloat(j) * dotSpacing

                // Add randomness
                let offsetX = CGFloat.random(in: -dotSpacing/3...dotSpacing/3)
                let offsetY = CGFloat.random(in: -dotSpacing/3...dotSpacing/3)
                let dotSize = CGFloat.random(in: minDotSize...maxDotSize)

                let x = baseX + offsetX
                let y = baseY + offsetY

                // Vary opacity for more natural look
                let opacity = CGFloat.random(in: 0.4...0.9)
                context.setAlpha(opacity)

                let dotRect = CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize)
                context.fillEllipse(in: dotRect)
            }
        }

        context.restoreGState() // Restore the clip/dot drawing state
    }

    /// Render solid area fill - for area tiles like lava, carpet, water feature, chasm
    static func renderSolidAreaFill(
        points: [CGPoint],
        width: CGFloat,
        context: CGContext
    ) {
        guard points.count > 1 else { return }

        // Create path from points
        context.beginPath()
        context.move(to: points[0])

        for point in points.dropFirst() {
            context.addLine(to: point)
        }

        // Close the path to create an enclosed area
        context.closePath()

        // Fill the interior of the closed area
        context.fillPath()
    }

    /// Render textured pattern - rough/sketchy texture
    static func renderTexturedPattern(
        points: [CGPoint],
        width: CGFloat,
        context: CGContext
    ) {
        guard points.count > 1 else { return }

        // Draw multiple offset strokes for texture effect
        context.setLineWidth(width * 0.7)

        for offset in stride(from: -width/3, to: width/3, by: width/6) {
            context.beginPath()
            context.move(to: points[0])

            for point in points.dropFirst() {
                let offsetX = CGFloat.random(in: -1...1) * offset
                let offsetY = CGFloat.random(in: -1...1) * offset
                context.addLine(to: CGPoint(x: point.x + offsetX, y: point.y + offsetY))
            }

            context.strokePath()
        }
    }

    // MARK: - Brush Presets with Advanced Patterns

    /// Get recommended rendering method for a brush
    static func recommendedRenderingMethod(for brush: MapBrush) -> BrushRenderingMethod {
        // Determine if brush should use standard or advanced rendering

        // Category-based advanced rendering
        if brush.category == .terrain || brush.category == .water || brush.category == .vegetation {
            return .advanced
        }

        // ER-0004: Interior brush categories need advanced rendering
        if brush.category == .architectural || brush.category == .symbols {
            return .advanced
        }

        // Pattern-based advanced rendering
        if brush.patternType == .stamp || brush.patternType == .textured || brush.patternType == .hatched || brush.patternType == .stippled {
            return .advanced
        }

        return .standard
    }
}

// MARK: - Brush Rendering Method

enum BrushRenderingMethod {
    case standard       // Basic Core Graphics rendering
    case advanced       // Procedural pattern generation
    case hybrid         // Combination of both
}
