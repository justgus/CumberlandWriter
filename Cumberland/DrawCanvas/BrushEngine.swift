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
        
        // Use advanced pattern generators based on category
        switch brush.category {
        case .terrain:
            renderTerrainBrush(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)
            
        case .water:
            renderWaterBrush(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)
            
        case .vegetation:
            renderVegetationBrush(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)
            
        case .roads:
            renderRoadBrush(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)
            
        case .structures:
            renderStructureBrush(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)
            
        default:
            // Fall back to standard rendering
            renderStroke(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)
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
    
    static func renderWaterBrush(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        context: CGContext
    ) {
        if brush.name.lowercased().contains("coast") {
            let pattern = ProceduralPatternGenerator.generateDetailedCoastline(
                points: points,
                width: width,
                detail: .high,
                erosion: 0.7
            )
            renderPatternStroke(pattern: pattern, color: color, width: width * 0.5, context: context)
            
        } else if brush.name.lowercased().contains("river") {
            // Rivers use smooth, flowing lines with subtle waves
            let pattern = generateWaterPattern(points: points, width: width, waveSize: 0.5)
            renderPatternStroke(pattern: pattern, color: color, width: width, context: context)
            
        } else if brush.name.lowercased().contains("wave") {
            let pattern = generateWaterPattern(points: points, width: width, waveSize: 1.0)
            renderPatternStroke(pattern: pattern, color: color, width: width * 0.5, context: context)
            
        } else {
            // Default water rendering with slight transparency
            renderSolidStroke(points: points, color: color, width: width, brush: brush, context: context)
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
        
        let pattern = generateRoadPattern(points: points, width: width, roadType: roadType)
        renderPatternStroke(pattern: pattern, color: color, width: width * 0.5, context: context)
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
    
    // MARK: - Brush Presets with Advanced Patterns
    
    /// Get recommended rendering method for a brush
    static func recommendedRenderingMethod(for brush: MapBrush) -> BrushRenderingMethod {
        // Determine if brush should use standard or advanced rendering
        if brush.category == .terrain || brush.category == .water || brush.category == .vegetation {
            return .advanced
        }
        
        if brush.patternType == .stamp || brush.patternType == .textured {
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
