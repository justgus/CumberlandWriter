//
//  BrushEngine+macOS.swift
//  Cumberland
//
//  macOS-specific brush rendering with AppKit integration
//

import SwiftUI
import Foundation
import CoreGraphics

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

// MARK: - macOS Brush Rendering Extension

extension BrushEngine {
    
    // MARK: - Drawing Stroke Model for macOS
    
    /// Enhanced drawing stroke for macOS with full brush metadata
    struct MacOSDrawingStroke: Codable, Identifiable {
        let id: UUID
        var points: [CGPoint]
        var pressurePoints: [CGFloat]? // Optional pressure data
        var brushID: UUID
        var color: CodableColor
        var width: CGFloat
        var timestamp: Date
        
        init(
            id: UUID = UUID(),
            points: [CGPoint],
            pressurePoints: [CGFloat]? = nil,
            brushID: UUID,
            color: Color,
            width: CGFloat
        ) {
            self.id = id
            self.points = points
            self.pressurePoints = pressurePoints
            self.brushID = brushID
            self.color = CodableColor(color: color)
            self.width = width
            self.timestamp = Date()
        }
    }
    
    // MARK: - NSBezierPath Extensions
    
    /// Convert points to NSBezierPath with smoothing
    static func createBezierPath(from points: [CGPoint], smoothing: CGFloat = 0.5) -> NSBezierPath {
        let path = NSBezierPath()
        guard points.count > 0 else { return path }
        
        if points.count == 1 {
            // Single point - draw a dot
            let point = points[0]
            path.appendOval(in: NSRect(x: point.x - 1, y: point.y - 1, width: 2, height: 2))
            return path
        }
        
        path.move(to: points[0])
        
        if smoothing > 0 && points.count > 2 {
            // Use Catmull-Rom spline for smooth curves
            for i in 0..<(points.count - 1) {
                let p0 = i > 0 ? points[i - 1] : points[i]
                let p1 = points[i]
                let p2 = points[i + 1]
                let p3 = i < points.count - 2 ? points[i + 2] : points[i + 1]
                
                // Calculate control points for cubic Bezier
                let cp1 = CGPoint(
                    x: p1.x + (p2.x - p0.x) * smoothing / 6,
                    y: p1.y + (p2.y - p0.y) * smoothing / 6
                )
                let cp2 = CGPoint(
                    x: p2.x - (p3.x - p1.x) * smoothing / 6,
                    y: p2.y - (p3.y - p1.y) * smoothing / 6
                )
                
                path.curve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
            }
        } else {
            // Simple straight lines
            for point in points.dropFirst() {
                path.line(to: point)
            }
        }
        
        return path
    }
    
    // MARK: - macOS-Optimized Rendering
    
    /// Render stroke in macOS using NSGraphicsContext
    static func renderStrokeForMacOS(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat? = nil,
        in bounds: CGRect
    ) -> NSImage? {
        let finalWidth = width ?? brush.defaultWidth
        
        let image = NSImage(size: bounds.size)
        image.lockFocus()
        
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }
        
        // Apply brush settings
        context.setAlpha(brush.opacity)
        context.setBlendMode(brush.blendMode.cgBlendMode)
        
        // Smooth path if needed
        let smoothedPoints = brush.smoothing > 0 ? smoothPath(points, amount: brush.smoothing) : points
        
        // Use the standard renderStroke method which handles all pattern types
        // This avoids duplicating the rendering logic
        renderStroke(brush: brush, points: smoothedPoints, color: color, width: finalWidth, context: context)
        
        image.unlockFocus()
        return image
    }
    

    
    /// Helper class to safely hold pattern info for CGPattern
    private class PatternInfo {
        let image: CGImage
        let size: CGFloat
        
        init(image: CGImage, size: CGFloat) {
            self.image = image
            self.size = size
        }
    }
    
    /// Render textured stroke for macOS
    private static func renderMacOSTexturedStroke(
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        textureData: Data,
        context: CGContext
    ) {
        guard let textureImage = NSImage(data: textureData),
              let cgImage = textureImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            // Fallback to solid stroke using the public API
            let fallbackBrush = MapBrush.basicPen
            renderStroke(brush: fallbackBrush, points: points, color: color, width: width, context: context)
            return
        }
        
        // Create pattern info using a class to safely manage the CGImage reference
        let patternInfo = PatternInfo(image: cgImage, size: width)
        let patternInfoPointer = Unmanaged.passRetained(patternInfo).toOpaque()
        
        var patternCallbacks = CGPatternCallbacks(
            version: 0,
            drawPattern: { info, context in
                guard let info = info else { return }
                let patternInfo = Unmanaged<PatternInfo>.fromOpaque(info).takeUnretainedValue()
                
                let rect = CGRect(x: 0, y: 0, width: patternInfo.size, height: patternInfo.size)
                context.draw(patternInfo.image, in: rect)
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
            return
        }
        
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
    }
    
    // MARK: - Layer Composition for macOS
    
    /// Composite multiple layers into a single NSImage
    static func compositeLayersForMacOS(
        layers: [DrawingLayer],
        size: CGSize,
        backgroundColor: NSColor = .clear
    ) -> NSImage {
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Draw background
        backgroundColor.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }
        
        // Sort layers by order
        let sortedLayers = layers.sorted { $0.order < $1.order }
        
        for layer in sortedLayers {
            guard layer.isVisible else { continue }
            
            context.saveGState()
            
            // Apply layer opacity and blend mode
            context.setAlpha(layer.opacity)
            context.setBlendMode(layer.blendMode.cgBlendMode)
            
            // Render layer content
            for stroke in layer.macosStrokes {
                // This would require brush lookup - simplified here
                renderLayerStroke(stroke, context: context)
            }
            
            context.restoreGState()
        }
        
        image.unlockFocus()
        return image
    }
    
    /// Render a single layer stroke (simplified)
    private static func renderLayerStroke(_ stroke: DrawingStroke, context: CGContext) {
        // Basic rendering - in real implementation, would look up brush and use full rendering
        let nsColor = NSColor(red: stroke.colorRed, green: stroke.colorGreen, blue: stroke.colorBlue, alpha: stroke.colorAlpha)
        
        context.setStrokeColor(nsColor.cgColor)
        context.setLineWidth(stroke.lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        let cgPoints = stroke.cgPoints
        guard !cgPoints.isEmpty else { return }
        
        context.beginPath()
        context.move(to: cgPoints[0])
        for point in cgPoints.dropFirst() {
            context.addLine(to: point)
        }
        context.strokePath()
    }
    
    // MARK: - Tablet Pressure Support (macOS)
    
    /// Extract pressure from NSEvent (e.g., Wacom tablet)
    static func extractPressureFromEvent(_ event: NSEvent) -> CGFloat {
        // NSEvent provides pressure data for pressure-sensitive tablets
        return CGFloat(event.pressure)
    }
    
    /// Render stroke with tablet pressure sensitivity
    static func renderPressureSensitiveStrokeForMacOS(
        points: [CGPoint],
        pressures: [CGFloat],
        brush: MapBrush,
        color: Color,
        baseWidth: CGFloat,
        context: CGContext
    ) {
        guard points.count == pressures.count, points.count > 1 else { return }
        
        let cgColor = NSColor(color).cgColor
        context.setFillColor(cgColor)
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            let pressure1 = pressures[i]
            let pressure2 = pressures[i + 1]
            
            // Map pressure to width (typically 0.0-1.0)
            let width1 = baseWidth * max(0.3, min(1.0, pressure1))
            let width2 = baseWidth * max(0.3, min(1.0, pressure2))
            
            // Draw trapezoid segment
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
    
    // MARK: - Export Utilities
    
    /// Export layer to PNG data
    static func exportLayerToPNG(_ layer: DrawingLayer, size: CGSize) -> Data? {
        let image = NSImage(size: size)
        
        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }
        
        // Render layer strokes
        for stroke in layer.macosStrokes {
            renderLayerStroke(stroke, context: context)
        }
        
        image.unlockFocus()
        
        // Convert to PNG data
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        return pngData
    }
    
    /// Export all layers composited to PNG
    static func exportCompositeToPNG(layers: [DrawingLayer], size: CGSize, backgroundColor: NSColor = .white) -> Data? {
        let image = compositeLayersForMacOS(layers: layers, size: size, backgroundColor: backgroundColor)
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        return pngData
    }
    
    // MARK: - Performance Optimization
    
    /// Cache rendered layer as NSImage for performance
    static func cacheLayerRendering(_ layer: DrawingLayer, size: CGSize) -> NSImage {
        let image = NSImage(size: size)
        
        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }
        
        // Render all strokes in layer
        for stroke in layer.macosStrokes {
            renderLayerStroke(stroke, context: context)
        }
        
        image.unlockFocus()
        return image
    }
}

// MARK: - NSColor Extension

extension NSColor {
    /// Create NSColor from SwiftUI Color
    convenience init(_ color: Color) {
        // Use NSColor's resolve method to get color components
        // We create a resolved NSColor from the Color using the environment
        let resolved = color.resolve(in: EnvironmentValues())
        
        self.init(
            red: Double(resolved.red),
            green: Double(resolved.green),
            blue: Double(resolved.blue),
            alpha: Double(resolved.opacity)
        )
    }
}

// MARK: - CGPoint Codable Extension

// CGPoint became Codable in iOS 16.0/macOS 13.0
// Only add conformance for older OS versions
#if os(macOS)
@available(macOS, obsoleted: 13.0)
extension CGPoint: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(CGFloat.self)
        let y = try container.decode(CGFloat.self)
        self.init(x: x, y: y)
    }
}
#elseif os(iOS)
@available(iOS, obsoleted: 16.0)
extension CGPoint: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(CGFloat.self)
        let y = try container.decode(CGFloat.self)
        self.init(x: x, y: y)
    }
}
#endif

#endif // canImport(AppKit)
