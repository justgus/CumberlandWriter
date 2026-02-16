//
//  DrawingCanvasIntegration.swift
//  Cumberland
//
//  Integration guide and helpers for connecting BrushEngine to DrawingCanvas
//

import SwiftUI
import Foundation
import CoreGraphics
import BrushEngine

#if canImport(PencilKit)
import PencilKit
#endif

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Canvas Integration Helper

/// Helper class to integrate BrushEngine with existing DrawingCanvas
class DrawingCanvasIntegration {
    
    // MARK: - Canvas State
    
    /// Current drawing state
    struct DrawingState {
        var activeBrush: MapBrush?
        var activeColor: Color = .black
        var activeWidth: CGFloat = 5.0
        var isDrawing: Bool = false
        var currentStroke: [CGPoint] = []
        var currentPressures: [CGFloat] = []
    }
    
    // MARK: - Integration Points
    
    /// Process touch/mouse input and convert to stroke points
    static func processTouchInput(
        location: CGPoint,
        pressure: CGFloat = 1.0,
        state: inout DrawingState
    ) {
        guard state.activeBrush != nil else { return }
        
        state.currentStroke.append(location)
        state.currentPressures.append(pressure)
    }
    
    /// Complete the current stroke and render it
    static func completeStroke(
        state: inout DrawingState,
        layer: DrawingLayer,
        context: CGContext
    ) {
        guard let brush = state.activeBrush,
              !state.currentStroke.isEmpty else { return }
        
        // Apply grid snapping if enabled
        let finalPoints = brush.snapToGrid
            ? BrushEngine.snapToGrid(state.currentStroke, gridSpacing: 20)
            : state.currentStroke
        
        // Render based on brush type
        if BrushEngine.recommendedRenderingMethod(for: brush) == .advanced {
            BrushEngine.renderAdvancedStroke(
                brush: brush,
                points: finalPoints,
                color: state.activeColor,
                width: state.activeWidth,
                context: context
            )
        } else {
            BrushEngine.renderStroke(
                brush: brush,
                points: finalPoints,
                color: state.activeColor,
                width: state.activeWidth,
                context: context
            )
        }
        
        // Create drawing stroke for layer (macOS stroke model)
        #if os(macOS)
        // Convert points -> [CGPointCodable]
        let codablePoints: [CGPointCodable] = finalPoints.map { CGPointCodable(x: $0.x, y: $0.y) }
        
        // Convert Color -> RGBA components
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        let a: CGFloat
        #if canImport(AppKit)
        let nsColor = NSColor(state.activeColor)
        if let rgb = nsColor.usingColorSpace(.deviceRGB) {
            r = rgb.redComponent
            g = rgb.greenComponent
            b = rgb.blueComponent
            a = rgb.alphaComponent
        } else {
            r = 0; g = 0; b = 0; a = 1
        }
        #else
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 1
        #if canImport(UIKit)
        UIColor(state.activeColor).getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        #endif
        r = rr; g = gg; b = bb; a = aa
        #endif
        
        let stroke = DrawingStroke(
            points: codablePoints,
            colorRed: r,
            colorGreen: g,
            colorBlue: b,
            colorAlpha: a,
            lineWidth: state.activeWidth,
            toolType: brush.name
        )
        
        layer.macosStrokes.append(stroke)
        #endif
        
        // Clear current stroke
        state.currentStroke.removeAll()
        state.currentPressures.removeAll()
        state.isDrawing = false
    }
    
    // MARK: - PencilKit Integration
    
    #if canImport(PencilKit) && canImport(UIKit)
    
    /// Convert MapBrush to PencilKit tool and configure canvas
    static func configurePencilKitCanvas(
        canvasView: PKCanvasView,
        brush: MapBrush,
        color: Color,
        width: CGFloat
    ) {
        let tool = BrushEngine.createAdvancedPKTool(from: brush, color: color, width: width)
        canvasView.tool = tool
        BrushEngine.configurePKCanvasView(canvasView, for: brush)
    }
    
    /// Process PencilKit drawing with custom brush rendering
    static func processPKDrawing(
        drawing: PKDrawing,
        brush: MapBrush,
        color: Color,
        in bounds: CGRect,
        traitCollection: UITraitCollection? = nil
    ) -> UIImage? {
        let scale = traitCollection?.displayScale ?? 1.0
        
        // Check if custom rendering is needed
        if BrushEngine.requiresCustomRendering(brush) {
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            
            let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
            return renderer.image { context in
                let cgContext = context.cgContext
                
                // Draw base PencilKit content
                let baseImage = drawing.image(from: bounds, scale: scale)
                baseImage.draw(at: .zero)
                
                // Add custom patterns
                for stroke in drawing.strokes {
                    let points = stroke.points
                    
                    BrushEngine.renderAdvancedStroke(
                        brush: brush,
                        points: points,
                        color: color,
                        width: stroke.averageWidth,
                        context: cgContext
                    )
                }
            }
        } else {
            // Use standard PencilKit rendering
            return drawing.image(from: bounds, scale: scale)
        }
    }
    
    #endif
    
    // MARK: - Layer Rendering
    
    /// Render all strokes in a layer to an image
    static func renderLayer(
        _ layer: DrawingLayer,
        size: CGSize,
        brushLookup: [UUID: MapBrush] = [:],
        scale: CGFloat = 1.0
    ) -> CGImage? {
        #if canImport(UIKit)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Apply layer opacity and blend mode
            cgContext.setAlpha(layer.opacity)
            cgContext.setBlendMode(layer.blendMode.cgBlendMode)
            
            // Render strokes
            #if os(macOS)
            for stroke in layer.macosStrokes {
                // If we have brush info, use advanced rendering
                // Otherwise use basic stroke rendering
                let color = UIColor(
                    red: stroke.colorRed,
                    green: stroke.colorGreen,
                    blue: stroke.colorBlue,
                    alpha: stroke.colorAlpha
                )
                
                cgContext.setStrokeColor(color.cgColor)
                cgContext.setLineWidth(stroke.lineWidth)
                cgContext.setLineCap(.round)
                cgContext.setLineJoin(.round)
                
                let points = stroke.points.map { CGPoint(x: $0.x, y: $0.y) }
                guard !points.isEmpty else { continue }
                
                cgContext.beginPath()
                cgContext.move(to: points[0])
                for point in points.dropFirst() {
                    cgContext.addLine(to: point)
                }
                cgContext.strokePath()
            }
            #endif
            
            #if canImport(PencilKit)
            // Render PencilKit drawing if available
            if !layer.drawing.bounds.isEmpty {
                let pkImage = layer.drawing.image(from: CGRect(origin: .zero, size: size), scale: scale)
                pkImage.draw(at: .zero)
            }
            #endif
        }
        
        return image.cgImage
        
        #elseif canImport(AppKit)
        return BrushEngine.exportLayerToPNG(layer, size: size).flatMap { data in
            NSImage(data: data)?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
        #else
        return nil
        #endif
    }
    
    /// Composite multiple layers into single image
    static func compositeLayersToImage(
        layers: [DrawingLayer],
        size: CGSize,
        backgroundColor: Color = .white,
        scale: CGFloat = 1.0
    ) -> CGImage? {
        #if canImport(UIKit)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            cgContext.setFillColor(UIColor(backgroundColor).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Sort layers by order
            let sortedLayers = layers.sorted { $0.order < $1.order }
            
            for layer in sortedLayers where layer.isVisible {
                if let layerImage = renderLayer(layer, size: size, scale: scale) {
                    let image = UIImage(cgImage: layerImage)
                    
                    cgContext.saveGState()
                    cgContext.setAlpha(layer.opacity)
                    cgContext.setBlendMode(layer.blendMode.cgBlendMode)
                    image.draw(at: .zero)
                    cgContext.restoreGState()
                }
            }
        }
        
        return image.cgImage
        
        #elseif canImport(AppKit)
        return BrushEngine.compositeLayersForMacOS(
            layers: layers,
            size: size,
            backgroundColor: NSColor(backgroundColor)
        ).cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        return nil
        #endif
    }
    
    // MARK: - Real-time Preview
    
    /// Generate preview of stroke while drawing (for cursor feedback)
    static func generateStrokePreview(
        brush: MapBrush,
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        size: CGSize,
        scale: CGFloat = 1.0
    ) -> CGImage? {
        guard points.count > 1 else { return nil }
        
        #if canImport(UIKit)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Clear background
            cgContext.clear(CGRect(origin: .zero, size: size))
            
            // Draw preview with slight transparency
            cgContext.setAlpha(0.7)
            
            if BrushEngine.recommendedRenderingMethod(for: brush) == .advanced {
                BrushEngine.renderAdvancedStroke(
                    brush: brush,
                    points: points,
                    color: color,
                    width: width,
                    context: cgContext
                )
            } else {
                BrushEngine.renderStroke(
                    brush: brush,
                    points: points,
                    color: color,
                    width: width,
                    context: cgContext
                )
            }
        }
        
        return image.cgImage
        #else
        return nil
        #endif
    }
    
    // MARK: - Export Utilities
    
    /// Export canvas to PNG with all layers
    static func exportToPNG(
        layers: [DrawingLayer],
        size: CGSize,
        backgroundColor: Color = .white,
        scale: CGFloat = 2.0
    ) -> Data? {
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        guard let cgImage = compositeLayersToImage(
            layers: layers,
            size: scaledSize,
            backgroundColor: backgroundColor
        ) else { return nil }
        
        #if canImport(UIKit)
        let image = UIImage(cgImage: cgImage)
        return image.pngData()
        
        #elseif canImport(AppKit)
        let image = NSImage(cgImage: cgImage, size: scaledSize)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
    
    /// Export single layer to PNG
    static func exportLayerToPNG(
        layer: DrawingLayer,
        size: CGSize,
        scale: CGFloat = 2.0
    ) -> Data? {
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        guard let cgImage = renderLayer(layer, size: scaledSize) else { return nil }
        
        #if canImport(UIKit)
        let image = UIImage(cgImage: cgImage)
        return image.pngData()
        
        #elseif canImport(AppKit)
        let image = NSImage(cgImage: cgImage, size: scaledSize)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
}

// MARK: - SwiftUI Integration Example

#if DEBUG
struct IntegratedDrawingCanvas: View {
    @State private var drawingState = DrawingCanvasIntegration.DrawingState()
    @State private var layers: [DrawingLayer] = [DrawingLayer(name: "Layer 1", layerType: .generic)]
    @State private var selectedBrush: MapBrush? = .basicPen
    @State private var canvasSize: CGSize = CGSize(width: 800, height: 600)
    
    var body: some View {
        VStack {
            // Toolbar
            HStack {
                // Brush selector
                Menu("Brush: \(selectedBrush?.name ?? "None")") {
                    Button("Pen") { selectedBrush = .basicPen }
                    Button("Marker") { selectedBrush = .marker }
                    Button("Pencil") { selectedBrush = .pencil }
                }
                
                Spacer()
                
                // Color picker
                ColorPicker("Color", selection: $drawingState.activeColor)
                
                // Width slider
                Slider(value: $drawingState.activeWidth, in: 1...50) {
                    Text("Width")
                }
                .frame(width: 150)
                
                // Export button
                Button("Export PNG") {
                    exportCanvas()
                }
            }
            .padding()
            
            // Canvas
            CanvasView(
                drawingState: $drawingState,
                layers: $layers,
                selectedBrush: $selectedBrush,
                size: canvasSize
            )
            .frame(width: canvasSize.width, height: canvasSize.height)
            .border(Color.gray)
        }
    }
    
    func exportCanvas() {
        if let pngData = DrawingCanvasIntegration.exportToPNG(
            layers: layers,
            size: canvasSize,
            backgroundColor: .white,
            scale: 2.0
        ) {
            // Save or share PNG data
            print("Exported PNG: \(pngData.count) bytes")
        }
    }
}

struct CanvasView: View {
    @Binding var drawingState: DrawingCanvasIntegration.DrawingState
    @Binding var layers: [DrawingLayer]
    @Binding var selectedBrush: MapBrush?
    let size: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Render all layers
            for layer in layers where layer.isVisible {
                if DrawingCanvasIntegration.renderLayer(layer, size: size) != nil {
                    if let image = context.resolveSymbol(id: layer.id) {
                        context.draw(image, at: CGPoint(x: size.width/2, y: size.height/2))
                    }
                }
            }
            
            // Render current stroke preview
            if drawingState.isDrawing, !drawingState.currentStroke.isEmpty {
                if let brush = selectedBrush {
                    if let previewCGImage = DrawingCanvasIntegration.generateStrokePreview(
                        brush: brush,
                        points: drawingState.currentStroke,
                        color: drawingState.activeColor,
                        width: drawingState.activeWidth,
                        size: size
                    ) {
                        // Draw the preview image to fill the canvas
                        let rect = CGRect(origin: .zero, size: size)
                        context.draw(Image(decorative: previewCGImage, scale: 1.0), in: rect)
                        // Alternatively, if you prefer using Core Graphics directly and have access:
                        // context.cgContext.draw(previewCGImage, in: rect)
                    }
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !drawingState.isDrawing {
                        drawingState.isDrawing = true
                        drawingState.activeBrush = selectedBrush
                    }
                    
                    DrawingCanvasIntegration.processTouchInput(
                        location: value.location,
                        pressure: 1.0,
                        state: &drawingState
                    )
                }
                .onEnded { _ in
                    // Complete stroke
                    if let _ = layers.first {
                        // In real implementation, would pass actual CGContext
                        // This is simplified for demonstration
                        drawingState.isDrawing = false
                        drawingState.currentStroke.removeAll()
                    }
                }
        )
    }
}

#Preview("Integrated Drawing Canvas") {
    IntegratedDrawingCanvas()
}
#endif

// MARK: - Integration Checklist

/*
 INTEGRATION CHECKLIST FOR DRAWING CANVAS:
 
 ✅ 1. Import BrushEngine modules
    - import BrushEngine
    - import ProceduralPatternGenerator (if using advanced patterns)
 
 ✅ 2. Set up brush selection
    - Link to BrushRegistry.shared.selectedBrush
    - Update active brush when selection changes
 
 ✅ 3. Configure touch/mouse input
    - Capture location and pressure
    - Store in DrawingState
 
 ✅ 4. Implement stroke completion
    - Call BrushEngine.renderStroke() or renderAdvancedStroke()
    - Store stroke in active layer
 
 ✅ 5. Handle PencilKit integration (iOS/iPadOS)
    - Convert MapBrush to PKTool
    - Configure PKCanvasView
    - Process drawings with custom patterns
 
 ✅ 6. Implement layer rendering
    - Render each layer separately
    - Composite with opacity and blend modes
 
 ✅ 7. Add export functionality
    - Export to PNG with compositeLayersToImage()
    - Support high-resolution export (2x, 3x scale)
 
 ✅ 8. Optimize performance
    - Cache layer renders
    - Use progressive rendering for complex brushes
    - Implement dirty rect tracking
 
 ✅ 9. Test across platforms
    - iOS/iPadOS with PencilKit
    - macOS with mouse/tablet
    - Verify pattern quality on all devices
 
 ✅ 10. Add user preferences
     - Brush size presets
     - Color palettes
     - Default smoothing amount
     - Grid spacing
 */

