//
//  BrushEngine+PencilKit.swift
//  Cumberland
//
//  PencilKit integration for iOS/iPadOS brush rendering
//

import SwiftUI
import Foundation
import CoreGraphics

#if canImport(PencilKit)
import PencilKit
#endif

#if canImport(UIKit)
import UIKit

// MARK: - PencilKit Extension

extension BrushEngine {
    
    #if canImport(PencilKit)
    
    // MARK: - Advanced PencilKit Tool Creation
    
    /// Create an advanced PencilKit tool with full brush properties
    static func createAdvancedPKTool(
        from brush: MapBrush,
        color: Color,
        width: CGFloat? = nil
    ) -> PKTool {
        let finalWidth = width ?? brush.defaultWidth
        let brushColor = brush.baseColor?.toColor() ?? color
        // Use toPencilKitColor() to prevent black color inversion (DR-0001)
        let pkColor = brushColor.toPencilKitColor()

        // Determine the best ink type for the brush pattern
        let inkType = selectInkType(for: brush)

        // Apply opacity to color
        let finalColor = brush.opacity < 1.0
            ? pkColor.withAlphaComponent(brush.opacity)
            : pkColor

        let tool = PKInkingTool(inkType, color: finalColor, width: finalWidth)

        return tool
    }
    
    /// Select the most appropriate PencilKit ink type for a brush
    private static func selectInkType(for brush: MapBrush) -> PKInkingTool.InkType {
        switch brush.patternType {
        case .solid:
            // Use pen for clean solid lines
            return .pen
            
        case .stippled:
            // Pencil gives a textured appearance
            return .pencil
            
        case .dashed, .dotted:
            // Pen with custom rendering needed for true dashes
            return .pen
            
        case .textured, .stamp:
            // Marker for semi-transparent textured look
            return .marker
            
        case .hatched, .crossHatched:
            // Fine pen for precision hatching
            return .pen
        }
    }
    
    // MARK: - PencilKit Canvas Enhancement
    
    /// Configure PKCanvasView for optimal brush rendering
    static func configurePKCanvasView(_ canvasView: PKCanvasView, for brush: MapBrush) {
        // Set drawing policy based on brush pressure sensitivity
        if brush.pressureSensitivity {
            // Only allow Apple Pencil input for pressure-sensitive brushes
            canvasView.drawingPolicy = .pencilOnly
        } else {
            // Allow both finger and Apple Pencil input
            canvasView.drawingPolicy = .anyInput
        }
        
        // Configure ruler if needed for straight lines
        if brush.snapToGrid {
            canvasView.isRulerActive = false // We'll handle snapping manually
        }
    }
    
    // MARK: - Hybrid Rendering (PencilKit + Custom)
    
    /// Determine if a brush requires custom rendering beyond PencilKit
    static func requiresCustomRendering(_ brush: MapBrush) -> Bool {
        switch brush.patternType {
        case .solid, .stippled:
            // PencilKit can handle these
            return false
            
        case .dashed, .dotted, .textured, .stamp, .hatched, .crossHatched:
            // These need custom rendering
            return true
        }
    }
    
    /// Render custom pattern over PencilKit drawing
    static func renderCustomPattern(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        in imageRenderer: UIGraphicsImageRenderer
    ) -> UIImage {
        return imageRenderer.image { context in
            let cgContext = context.cgContext
            
            switch brush.patternType {
            case .dashed:
                renderDashedStroke(points: points, color: color, width: width, context: cgContext)
                
            case .dotted:
                renderDottedStroke(points: points, color: color, width: width, context: cgContext)
                
            case .stamp:
                renderAdvancedStampPattern(brush: brush, points: points, color: color, width: width, context: cgContext)
                
            case .hatched:
                renderHatchedStroke(points: points, color: color, width: width, context: cgContext)
                
            case .crossHatched:
                renderCrossHatchedStroke(points: points, color: color, width: width, context: cgContext)
                
            case .textured:
                if let textureData = brush.textureImage {
                    renderTexturedStroke(
                        points: points,
                        color: color,
                        width: width,
                        textureData: textureData,
                        context: cgContext
                    )
                } else {
                    renderSolidStroke(points: points, color: color, width: width, brush: brush, context: cgContext)
                }
                
            default:
                renderSolidStroke(points: points, color: color, width: width, brush: brush, context: cgContext)
            }
        }
    }
    
    /// Render advanced stamp pattern with proper brush properties
    private static func renderAdvancedStampPattern(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        context: CGContext
    ) {
        let cgColor = UIColor(color).cgColor
        context.setFillColor(cgColor)
        context.setStrokeColor(cgColor)
        
        // Generate stamps based on brush category
        let stamps: [(CGPoint, CGPath)]
        
        switch brush.category {
        case .vegetation:
            stamps = generateForestPattern(points: points, width: width, density: 1.0 / brush.spacing)
            
        case .structures:
            let buildings = generateBuildingPattern(points: points, width: width)
            stamps = buildings.map { rect, style in
                let path = CGMutablePath()
                path.addRect(rect)
                return (CGPoint(x: rect.midX, y: rect.midY), path)
            }
            
        case .terrain:
            // Mountain stamps
            stamps = generateMountainStamps(points: points, width: width)
            
        default:
            // Generic circular stamps
            stamps = generateGenericStamps(points: points, width: width, brush: brush)
        }
        
        // Render with rotation and size variation
        for (position, stampPath) in stamps {
            context.saveGState()
            context.translateBy(x: position.x, y: position.y)
            
            // Apply rotation variation
            if brush.rotationVariation > 0 {
                let rotation = CGFloat.random(in: -brush.rotationVariation...brush.rotationVariation) * .pi / 180
                context.rotate(by: rotation)
            }
            
            // Apply size variation (already in stamp, but can add scale transform)
            if brush.sizeVariation > 0 {
                let scale = 1.0 + CGFloat.random(in: -brush.sizeVariation...brush.sizeVariation)
                context.scaleBy(x: scale, y: scale)
            }
            
            context.addPath(stampPath)
            
            // Fill with some transparency for depth
            context.setAlpha(brush.opacity * 0.8)
            context.fillPath()
            
            // Stroke outline
            context.setAlpha(brush.opacity)
            context.addPath(stampPath)
            context.setLineWidth(1.0)
            context.strokePath()
            
            context.restoreGState()
        }
    }
    
    /// Generate mountain stamps
    private static func generateMountainStamps(points: [CGPoint], width: CGFloat) -> [(CGPoint, CGPath)] {
        var stamps: [(CGPoint, CGPath)] = []
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            
            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let spacing = width * 3
            let numStamps = max(1, Int(segmentLength / spacing))
            
            for j in 0..<numStamps {
                let t = CGFloat(j) / CGFloat(numStamps)
                let x = p1.x + (p2.x - p1.x) * t
                let y = p1.y + (p2.y - p1.y) * t
                
                let path = CGMutablePath()
                let size = width * CGFloat.random(in: 1.5...2.5)
                
                // Triangle mountain
                path.move(to: CGPoint(x: -size/2, y: size/2))
                path.addLine(to: CGPoint(x: 0, y: -size/2))
                path.addLine(to: CGPoint(x: size/2, y: size/2))
                path.closeSubpath()
                
                stamps.append((CGPoint(x: x, y: y), path))
            }
        }
        
        return stamps
    }
    
    /// Generate generic circular stamps
    private static func generateGenericStamps(
        points: [CGPoint],
        width: CGFloat,
        brush: MapBrush
    ) -> [(CGPoint, CGPath)] {
        var stamps: [(CGPoint, CGPath)] = []
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            
            let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
            let spacing = brush.spacing * width
            let numStamps = max(1, Int(segmentLength / spacing))
            
            for j in 0..<numStamps {
                let t = CGFloat(j) / CGFloat(numStamps)
                var x = p1.x + (p2.x - p1.x) * t
                var y = p1.y + (p2.y - p1.y) * t
                
                // Apply scatter
                if brush.scatterAmount > 0 {
                    let scatterRange = width * brush.scatterAmount
                    x += CGFloat.random(in: -scatterRange...scatterRange)
                    y += CGFloat.random(in: -scatterRange...scatterRange)
                }
                
                let size = width * (1.0 + CGFloat.random(in: -brush.sizeVariation...brush.sizeVariation))
                
                let path = CGMutablePath()
                path.addEllipse(in: CGRect(x: -size/2, y: -size/2, width: size, height: size))
                
                stamps.append((CGPoint(x: x, y: y), path))
            }
        }
        
        return stamps
    }
    
    /// Pattern info holder for safe memory management
    private class PatternInfo {
        let cgImage: CGImage
        let width: CGFloat
        
        init(cgImage: CGImage, width: CGFloat) {
            self.cgImage = cgImage
            self.width = width
        }
    }
    
    /// Render textured stroke using texture image
    private static func renderTexturedStroke(
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        textureData: Data,
        context: CGContext
    ) {
        guard let textureImage = UIImage(data: textureData),
              let cgImage = textureImage.cgImage else {
            // Fallback to solid stroke
            renderSolidStroke(points: points, color: color, width: width, brush: .basicPen, context: context)
            return
        }
        
        // Create pattern info with proper memory management
        let patternInfo = PatternInfo(cgImage: cgImage, width: width)
        let patternInfoPointer = Unmanaged.passRetained(patternInfo).toOpaque()
        
        var patternCallbacks = CGPatternCallbacks(
            version: 0,
            drawPattern: { info, context in
                guard let info = info else { return }
                let patternInfo = Unmanaged<PatternInfo>.fromOpaque(info).takeUnretainedValue()
                
                let rect = CGRect(x: 0, y: 0, width: patternInfo.width, height: patternInfo.width)
                context.draw(patternInfo.cgImage, in: rect)
            },
            releaseInfo: { info in
                guard let info = info else { return }
                Unmanaged<PatternInfo>.fromOpaque(info).release()
            }
        )
        
        guard let pattern = CGPattern(
            info: patternInfoPointer,
            bounds: CGRect(x: 0, y: 0, width: width, height: width),
            matrix: .identity,
            xStep: width,
            yStep: width,
            tiling: .constantSpacing,
            isColored: true,
            callbacks: &patternCallbacks
        ) else {
            // Clean up if pattern creation fails
            Unmanaged<PatternInfo>.fromOpaque(patternInfoPointer).release()
            // Fallback if pattern creation fails
            renderSolidStroke(points: points, color: color, width: width, brush: .basicPen, context: context)
            return
        }
        
        // Apply pattern and stroke
        if let patternSpace = CGColorSpace(patternBaseSpace: nil),
           let patternColor = CGColor(patternSpace: patternSpace, pattern: pattern, components: [1.0]) {
            context.setStrokeColor(patternColor)
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
        // Note: The pattern retains the info, and releaseInfo will be called when the pattern is released
    }
    
    // MARK: - Pressure Sensitivity with Apple Pencil
    
    /// Convert PKStroke to points with pressure data
    static func extractPressureData(from stroke: PKStroke) -> [(CGPoint, CGFloat)] {
        var pointsWithPressure: [(CGPoint, CGFloat)] = []
        
        let path = stroke.path
        for i in 0..<path.count {
            let point = path[i]
            let location = point.location
            let force = point.force // Pressure from Apple Pencil
            
            pointsWithPressure.append((location, force))
        }
        
        return pointsWithPressure
    }
    
    /// Render stroke with pressure-sensitive width
    static func renderPressureSensitiveStroke(
        pointsWithPressure: [(CGPoint, CGFloat)],
        brush: MapBrush,
        color: Color,
        baseWidth: CGFloat,
        context: CGContext
    ) {
        guard pointsWithPressure.count > 1 else { return }
        
        let cgColor = UIColor(color).cgColor
        context.setFillColor(cgColor)
        
        for i in 0..<(pointsWithPressure.count - 1) {
            let (p1, pressure1) = pointsWithPressure[i]
            let (p2, pressure2) = pointsWithPressure[i + 1]
            
            // Calculate widths based on pressure
            let width1 = baseWidth * max(0.3, min(1.0, pressure1))
            let width2 = baseWidth * max(0.3, min(1.0, pressure2))
            
            // Draw trapezoid connecting the two points
            let dx = p2.x - p1.x
            let dy = p2.y - p1.y
            let distance = hypot(dx, dy)
            
            guard distance > 0 else { continue }
            
            let perpX = -dy / distance
            let perpY = dx / distance
            
            context.beginPath()
            context.move(to: CGPoint(x: p1.x + perpX * width1/2, y: p1.y + perpY * width1/2))
            context.addLine(to: CGPoint(x: p2.x + perpX * width2/2, y: p2.y + perpY * width2/2))
            context.addLine(to: CGPoint(x: p2.x - perpX * width2/2, y: p2.y - perpY * width2/2))
            context.addLine(to: CGPoint(x: p1.x - perpX * width1/2, y: p1.y - perpY * width1/2))
            context.closePath()
            context.fillPath()
        }
    }
    
    // MARK: - PencilKit Drawing Conversion
    
    /// Convert PencilKit drawing to image with custom brush rendering
    /// Note: Uses stroke index to map strokes to brushes since PKStroke is not Hashable
    static func renderPKDrawingWithCustomBrushes(
        drawing: PKDrawing,
        strokeBrushMap: [Int: MapBrush],
        strokeColorMap: [Int: Color],
        size: CGSize
    ) -> UIImage {
        // Get scale from trait collection (modern approach)
        let scale = UITraitCollection.current.displayScale
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // First, draw the base PKDrawing
            let image = drawing.image(from: CGRect(origin: .zero, size: size), scale: scale)
            image.draw(at: .zero)
            
            // Then overlay custom brush patterns
            for (index, stroke) in drawing.strokes.enumerated() {
                guard let brush = strokeBrushMap[index] else { continue }
                
                if requiresCustomRendering(brush) {
                    let points = stroke.path.map { $0.location }
                    let color = strokeColorMap[index] ?? Color.black
                    let width = CGFloat(stroke.path.first?.size.width ?? 5.0)
                    
                    renderStroke(brush: brush, points: points, color: color, width: width, context: cgContext)
                }
            }
        }
    }
    
    #endif // canImport(PencilKit)
}

// MARK: - PencilKit Stroke Extension

#if canImport(PencilKit)
extension PKStroke {
    /// Get simplified point array from stroke
    var points: [CGPoint] {
        path.map { $0.location }
    }
    
    /// Get average width of stroke
    var averageWidth: CGFloat {
        let widths = path.map { $0.size.width }
        return widths.reduce(0, +) / CGFloat(widths.count)
    }
}
#endif

#endif // canImport(UIKit)
