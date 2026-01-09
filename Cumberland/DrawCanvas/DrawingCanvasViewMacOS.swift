//
//  DrawingCanvasViewMacOS.swift
//  Cumberland
//
//  Created on 11/13/25.
//

import SwiftUI

#if os(macOS)
import AppKit

// MARK: - macOS Drawing Canvas View

/// A native macOS drawing canvas using NSView for mouse/trackpad input
struct DrawingCanvasViewMacOS: NSViewRepresentable {
    @Binding var canvasState: DrawingCanvasModel

    func makeNSView(context: Context) -> MacOSDrawingView {
        let view = MacOSDrawingView()
        view.canvasModel = canvasState
        view.zoomScale = canvasState.zoomScale  // DR-0004: Pass zoom scale for coordinate transformation

        // Connect the view to the model
        canvasState.macosCanvasView = view

        // DR-0004.3: Strokes are now in the model, view will render them automatically
        print("[DR-0004.3] makeNSView called, model has \(canvasState.macOSStrokes.count) strokes")

        return view
    }

    func updateNSView(_ nsView: MacOSDrawingView, context: Context) {
        nsView.canvasModel = canvasState
        nsView.zoomScale = canvasState.zoomScale  // DR-0004: Update zoom scale
        nsView.needsDisplay = true
    }
}

// MARK: - macOS Drawing View (NSView)

class MacOSDrawingView: NSView {
    var canvasModel: DrawingCanvasModel?

    // DR-0004: Zoom scale for coordinate transformation
    // When the view is scaled with .scaleEffect(), mouse coordinates arrive in scaled space
    // We divide by zoomScale to convert back to unscaled canvas coordinates
    var zoomScale: CGFloat = 1.0

    // Current stroke being drawn (using a temporary structure for active drawing)
    private var currentStroke: MacOSDrawingStroke?

    // DR-0004.3: Strokes are now stored in the model, not here
    // This view reads/writes to canvasModel.macOSStrokes

    // Undo stack
    private var undoStack: [[DrawingStroke]] = []
    private var redoStack: [[DrawingStroke]] = []

    // DR-0029: Terrain and pattern caching now handled by shared BaseLayerImageCache
    // (removed local cache dictionaries - using BaseLayerImageCache.shared instead)

    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
    }
    
    // MARK: - Mouse Event Handling
    
    override func mouseDown(with event: NSEvent) {
        guard let model = canvasModel else { return }

        // DR-0014: Convert to unscaled canvas coordinates
        // The view frame is scaled, but we draw in unscaled space with a transform
        let viewLocation = convert(event.locationInWindow, from: nil)
        let location = CGPoint(
            x: viewLocation.x / zoomScale,
            y: viewLocation.y / zoomScale
        )

        // Save state for undo
        pushUndoState()

        // ER-0003: Use brush settings if a brush is selected
        let color: NSColor
        let lineWidth: CGFloat
        let brushID: UUID?  // DR-0031: Capture brush ID for advanced rendering

        if let brush = model.selectedBrush {
            // Use brush color or fall back to selected color
            color = brush.baseColor != nil ? NSColor(brush.baseColor!.toColor()) : NSColor(model.selectedColor)
            // Use brush default width or fall back to selected width
            lineWidth = model.selectedLineWidth // User can override with slider
            brushID = brush.id  // DR-0031: Store brush ID
        } else {
            // Use model settings
            color = NSColor(model.selectedColor)
            lineWidth = model.selectedLineWidth
            brushID = nil
        }

        currentStroke = MacOSDrawingStroke(
            points: [location],
            color: color,
            lineWidth: lineWidth,
            toolType: model.selectedToolType,
            brushID: brushID  // DR-0031: Pass brush ID to stroke
        )

        needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        // DR-0014: Convert to unscaled canvas coordinates
        // The view frame is scaled, but we draw in unscaled space with a transform
        let viewLocation = convert(event.locationInWindow, from: nil)
        let location = CGPoint(
            x: viewLocation.x / zoomScale,
            y: viewLocation.y / zoomScale
        )

        // Add point to current stroke
        currentStroke?.points.append(location)

        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        // Finalize stroke
        if let stroke = currentStroke, let model = canvasModel {
            // Convert to codable DrawingStroke
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            stroke.color.getRed(&r, green: &g, blue: &b, alpha: &a)

            // DR-0031: Include brushID in stored stroke for advanced rendering
            let codableStroke = DrawingStroke(
                points: stroke.points.map { CGPointCodable(x: $0.x, y: $0.y) },
                colorRed: r,
                colorGreen: g,
                colorBlue: b,
                colorAlpha: a,
                lineWidth: stroke.lineWidth,
                toolType: stroke.toolType.rawValue,
                brushID: stroke.brushID
            )

            // DR-0023 / ER-0002: Store stroke in appropriate layer
            // Base layer (order == 0) should never receive strokes
            if let layerManager = model.layerManager {
                let targetLayer = layerManager.getTargetLayerForStrokes()
                targetLayer.macosStrokes.append(codableStroke)
                targetLayer.markModified()
                model.hasStrokes = true
            } else {
                // Fallback to model if no layer manager (backward compatibility)
                model.macOSStrokes.append(codableStroke)
                model.hasStrokes = !model.macOSStrokes.isEmpty
            }
            currentStroke = nil
        }

        needsDisplay = true
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // DR-0014: Apply zoom scale transform to graphics context
        // This ensures strokes are drawn at the correct position regardless of zoom level
        context.saveGState()
        context.scaleBy(x: zoomScale, y: zoomScale)

        // 1. Draw background
        if let bgColor = canvasModel?.backgroundColor {
            NSColor(bgColor).setFill()
        } else {
            NSColor.white.setFill()
        }
        // Adjust bounds for zoom scale when filling background
        context.fill(CGRect(x: 0, y: 0,
                           width: bounds.width / zoomScale,
                           height: bounds.height / zoomScale))

        // 2. Draw base layer fill (if exists and visible)
        // DR-0021: Check layer visibility before rendering
        if let baseLayer = canvasModel?.layerManager?.baseLayer,
           baseLayer.isVisible,
           let fill = baseLayer.layerFill {
            context.setAlpha(fill.opacity)

            let fillRect = CGRect(x: 0, y: 0,
                                 width: bounds.width / zoomScale,
                                 height: bounds.height / zoomScale)

            print("[DrawingCanvasViewMacOS] Drawing base layer: \(fill.fillType.displayName)")
            print("[DrawingCanvasViewMacOS] usesProceduralTerrain: \(fill.usesProceduralTerrain), metadata: \(fill.terrainMetadata?.description ?? "none")")

            // DR-0016: Use procedural terrain for exterior fill types with metadata
            if fill.usesProceduralTerrain, let metadata = fill.terrainMetadata {
                // DR-0029: Use shared cache that persists across visibility toggles
                let cacheKey = BaseLayerImageCache.cacheKey(
                    fillType: fill.fillType.rawValue,
                    patternSeed: fill.patternSeed,
                    terrainSeed: metadata.terrainSeed,
                    width: Int(fillRect.width),
                    height: Int(fillRect.height)
                )

                if let cachedNSImage = BaseLayerImageCache.shared.get(cacheKey),
                   let cgImage = cachedNSImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    // Use cached terrain image
                    context.draw(cgImage, in: fillRect)
                } else {
                    // Generate and cache terrain
                    print("[DrawingCanvasViewMacOS] Generating terrain (cache miss) - key: \(cacheKey)")

                    // Create a bitmap context to render terrain
                    let width = Int(fillRect.width)
                    let height = Int(fillRect.height)
                    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

                    guard let bitmapContext = CGContext(
                        data: nil,
                        width: width,
                        height: height,
                        bitsPerComponent: 8,
                        bytesPerRow: width * 4,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: bitmapInfo.rawValue
                    ) else {
                        print("[DrawingCanvasViewMacOS] Failed to create bitmap context")
                        return
                    }

                    // Render terrain to bitmap context
                    let pattern = TerrainPattern(metadata: metadata, dominantFillType: fill.fillType)
                    // DR-0019: Pass map scale to pattern
                    pattern.draw(in: bitmapContext, rect: CGRect(origin: .zero, size: fillRect.size), seed: fill.patternSeed, baseColor: fill.effectiveColor, mapScale: metadata.physicalSizeMiles)

                    // Create and cache image
                    if let terrainImage = bitmapContext.makeImage() {
                        let nsImage = NSImage(cgImage: terrainImage, size: fillRect.size)
                        BaseLayerImageCache.shared.set(cacheKey, image: nsImage)
                        context.draw(terrainImage, in: fillRect)
                        print("[DrawingCanvasViewMacOS] Terrain cached - size: \(width)x\(height)")
                    }
                }
            }
            // DR-0015 + DR-0022: Use procedural patterns for interior fill types (with caching)
            else if fill.usesProceduralPattern,
               let pattern = ProceduralPatternFactory.pattern(for: fill.fillType) {
                // DR-0029: Use shared cache that persists across visibility toggles
                let mapScale = fill.terrainMetadata?.physicalSizeMiles ?? 0
                let cacheKey = BaseLayerImageCache.cacheKey(
                    fillType: fill.fillType.rawValue,
                    patternSeed: fill.patternSeed,
                    terrainSeed: nil,  // Patterns don't use terrain seed
                    width: Int(fillRect.width),
                    height: Int(fillRect.height)
                )

                if let cachedNSImage = BaseLayerImageCache.shared.get(cacheKey),
                   let cgImage = cachedNSImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    // Use cached pattern image
                    context.draw(cgImage, in: fillRect)
                } else {
                    // Generate and cache pattern
                    print("[DrawingCanvasViewMacOS] Generating pattern (cache miss) - key: \(cacheKey)")

                    // Create a bitmap context to render pattern
                    let width = Int(fillRect.width)
                    let height = Int(fillRect.height)
                    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

                    guard let bitmapContext = CGContext(
                        data: nil,
                        width: width,
                        height: height,
                        bitsPerComponent: 8,
                        bytesPerRow: width * 4,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: bitmapInfo.rawValue
                    ) else {
                        print("[DrawingCanvasViewMacOS] Failed to create bitmap context for pattern")
                        return
                    }

                    // Render pattern to bitmap context
                    // DR-0019: Pass map scale to pattern for correct physical sizing
                    pattern.draw(in: bitmapContext, rect: CGRect(origin: .zero, size: fillRect.size), seed: fill.patternSeed, baseColor: fill.effectiveColor, mapScale: mapScale)

                    // Create and cache image
                    if let patternImage = bitmapContext.makeImage() {
                        let nsImage = NSImage(cgImage: patternImage, size: fillRect.size)
                        BaseLayerImageCache.shared.set(cacheKey, image: nsImage)
                        context.draw(patternImage, in: fillRect)
                        print("[DrawingCanvasViewMacOS] Pattern cached - size: \(width)x\(height)")
                    }
                }
            } else {
                // Simple solid color fill for exterior types without terrain metadata
                print("[DrawingCanvasViewMacOS] Rendering solid color fill")
                let fillColor = fill.effectiveColor
                let nsColor = NSColor(fillColor)
                nsColor.setFill()
                context.fill(fillRect)
            }

            context.setAlpha(1.0) // Reset alpha
        }

        // 3. Draw grid if enabled
        if let model = canvasModel, model.showGrid {
            drawGrid(in: context, spacing: model.gridSpacing, color: NSColor(model.gridColor))
        }

        // DR-0023: Draw strokes from all visible layers (in order, bottom to top)
        if let model = canvasModel, let layerManager = model.layerManager {
            for layer in layerManager.sortedLayers where layer.isVisible {
                context.saveGState()
                context.setAlpha(layer.opacity)

                for stroke in layer.macosStrokes {
                    drawStroke(stroke, in: context)
                }

                context.restoreGState()
            }
        }

        // Fallback: Draw model strokes if no layer system (backward compatibility)
        if let model = canvasModel,
           (model.layerManager == nil || model.layerManager?.layers.isEmpty == true),
           !model.macOSStrokes.isEmpty {
            for stroke in model.macOSStrokes {
                drawStroke(stroke, in: context)
            }
        }

        // Draw current stroke being created
        if let stroke = currentStroke {
            drawCurrentStroke(stroke, in: context)
        }

        // DR-0014: Restore graphics state after drawing with zoom transform
        context.restoreGState()
    }
    
    private func drawStroke(_ stroke: DrawingStroke, in context: CGContext) {
        let points = stroke.cgPoints
        guard points.count > 1 else { return }

        // DR-0031: Check if this stroke has an advanced brush that needs BrushEngine rendering
        if let brushID = stroke.brushID,
           let brush = BrushRegistry.shared.findBrush(id: brushID),
           BrushEngine.recommendedRenderingMethod(for: brush) == .advanced {
            // Use BrushEngine for advanced rendering
            let swiftUIColor = Color(
                red: Double(stroke.colorRed),
                green: Double(stroke.colorGreen),
                blue: Double(stroke.colorBlue),
                opacity: Double(stroke.colorAlpha)
            )
            // DR-0032: Pass terrain metadata for scale-aware beach rendering
            let terrainMetadata = canvasModel?.layerManager?.baseLayer?.layerFill?.terrainMetadata

            BrushEngine.renderAdvancedStroke(
                brush: brush,
                points: points,
                color: swiftUIColor,
                width: stroke.lineWidth,
                context: context,
                terrainMetadata: terrainMetadata
            )
            return
        }

        // Standard rendering (no brush or simple brush)

        // Handle eraser differently
        if let toolType = DrawingToolType(rawValue: stroke.toolType), toolType == .eraser {
            // For eraser, we need to remove intersecting strokes
            // This is a simplified approach - a more sophisticated implementation
            // would track eraser paths and clip them from existing strokes
            context.setBlendMode(.clear)
            context.setLineWidth(stroke.lineWidth * 2) // Make eraser wider
            context.setLineCap(.round)
            context.setLineJoin(.round)
        } else {
            // Normal drawing
            context.setStrokeColor(stroke.color.cgColor)
            context.setLineWidth(stroke.lineWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.setBlendMode(.normal)

            // Apply different styles based on tool type
            if let toolType = DrawingToolType(rawValue: stroke.toolType) {
                switch toolType {
                case .pencil:
                    // Pencil: slight transparency for texture
                    context.setAlpha(0.8)
                case .marker:
                    // Marker: more transparent and wider
                    context.setAlpha(0.4)
                    context.setLineWidth(stroke.lineWidth * 2)
                default:
                    context.setAlpha(1.0)
                }
            } else {
                context.setAlpha(1.0)
            }
        }

        // Draw the path
        context.beginPath()
        context.move(to: points[0])

        // Use quadratic bezier curves for smooth lines
        for i in 1..<points.count {
            let current = points[i]

            if i < points.count - 1 {
                let next = points[i + 1]
                let midPoint = CGPoint(
                    x: (current.x + next.x) / 2,
                    y: (current.y + next.y) / 2
                )
                context.addQuadCurve(to: midPoint, control: current)
            } else {
                context.addLine(to: current)
            }
        }

        context.strokePath()

        // Reset blend mode and alpha
        context.setBlendMode(.normal)
        context.setAlpha(1.0)
    }
    
    private func drawCurrentStroke(_ stroke: MacOSDrawingStroke, in context: CGContext) {
        guard stroke.points.count > 1 else { return }

        // DR-0031: For real-time preview of advanced brushes, use simple rendering for performance
        // Full advanced rendering will be applied on mouseUp when stroke is finalized
        // This prevents the expensive procedural generation from running dozens of times per second

        // Visual hint: Draw with slight transparency to indicate preview
        let isAdvancedBrush = stroke.brushID != nil &&
            BrushRegistry.shared.findBrush(id: stroke.brushID!) != nil &&
            BrushEngine.recommendedRenderingMethod(for: BrushRegistry.shared.findBrush(id: stroke.brushID!)!) == .advanced

        // Standard rendering for real-time preview (fast)

        // Handle eraser differently
        if stroke.toolType == .eraser {
            // For eraser, we need to remove intersecting strokes
            // This is a simplified approach - a more sophisticated implementation
            // would track eraser paths and clip them from existing strokes
            context.setBlendMode(.clear)
            context.setLineWidth(stroke.lineWidth * 2) // Make eraser wider
            context.setLineCap(.round)
            context.setLineJoin(.round)
        } else {
            // Normal drawing
            context.setStrokeColor(stroke.color.cgColor)
            context.setLineWidth(stroke.lineWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.setBlendMode(.normal)

            // DR-0031: Use reduced opacity for advanced brush preview to indicate it's temporary
            if isAdvancedBrush {
                context.setAlpha(0.5)  // Lighter preview for advanced brushes
            } else {
                // Apply different styles based on tool type
                switch stroke.toolType {
                case .pencil:
                    // Pencil: slight transparency for texture
                    context.setAlpha(0.8)
                case .marker:
                    // Marker: more transparent and wider
                    context.setAlpha(0.4)
                    context.setLineWidth(stroke.lineWidth * 2)
                default:
                    context.setAlpha(1.0)
                }
            }
        }

        // Draw the path
        context.beginPath()
        context.move(to: stroke.points[0])

        // Use quadratic bezier curves for smooth lines
        for i in 1..<stroke.points.count {
            let current = stroke.points[i]

            if i < stroke.points.count - 1 {
                let next = stroke.points[i + 1]
                let midPoint = CGPoint(
                    x: (current.x + next.x) / 2,
                    y: (current.y + next.y) / 2
                )
                context.addQuadCurve(to: midPoint, control: current)
            } else {
                context.addLine(to: current)
            }
        }

        context.strokePath()

        // Reset blend mode and alpha
        context.setBlendMode(.normal)
        context.setAlpha(1.0)
    }
    
    private func drawGrid(in context: CGContext, spacing: CGFloat, color: NSColor) {
        context.setStrokeColor(color.cgColor)
        // DR-0014: Scale line width inversely to maintain consistent visual thickness
        context.setLineWidth(1.0 / zoomScale)
        context.setAlpha(0.5)

        // DR-0014: Use unscaled canvas size since context is already scaled
        guard let canvasSize = canvasModel?.canvasSize else { return }
        let width = canvasSize.width
        let height = canvasSize.height

        // Vertical lines
        var x: CGFloat = 0
        while x <= width {
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: height))
            x += spacing
        }

        // Horizontal lines
        var y: CGFloat = 0
        while y <= height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: width, y: y))
            y += spacing
        }

        context.strokePath()
        context.setAlpha(1.0)
    }
    
    // MARK: - Undo/Redo

    private func pushUndoState() {
        guard let model = canvasModel else { return }
        undoStack.append(model.macOSStrokes)
        redoStack.removeAll() // Clear redo stack when new action is performed

        // Limit undo stack size
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
    }

    func undo() {
        guard !undoStack.isEmpty, let model = canvasModel else { return }

        redoStack.append(model.macOSStrokes)
        model.macOSStrokes = undoStack.removeLast()

        needsDisplay = true
        model.hasStrokes = !model.macOSStrokes.isEmpty
    }

    func redo() {
        guard !redoStack.isEmpty, let model = canvasModel else { return }

        undoStack.append(model.macOSStrokes)
        model.macOSStrokes = redoStack.removeLast()

        needsDisplay = true
        model.hasStrokes = !model.macOSStrokes.isEmpty
    }
    
    func canUndo() -> Bool {
        !undoStack.isEmpty
    }
    
    func canRedo() -> Bool {
        !redoStack.isEmpty
    }
    
    func clear() {
        guard let model = canvasModel else { return }
        pushUndoState()
        model.macOSStrokes.removeAll()
        currentStroke = nil
        needsDisplay = true
        model.hasStrokes = false
    }

    func isEmpty() -> Bool {
        canvasModel?.macOSStrokes.isEmpty ?? true
    }
    
    // MARK: - Export
    
    func exportAsImageData() -> Data? {
        // Create a bitmap representation of the current canvas
        guard let bitmapRep = bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        cacheDisplay(in: bounds, to: bitmapRep)
        return bitmapRep.representation(using: .png, properties: [:])
    }
    
    /// Export canvas as PNG at the actual canvas size (not scaled)
    func exportAsPNGData() -> Data? {
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        
        guard width > 0, height > 0 else { return nil }
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        
        guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else { return nil }
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        
        // Draw into the bitmap context
        draw(bounds)
        
        NSGraphicsContext.restoreGraphicsState()
        
        return bitmapRep.representation(using: .png, properties: [:])
    }
    
    // DR-0004.3: Export is now handled by the model
    // This method is kept for compatibility but delegates to model
    func exportStrokes() -> Data {
        guard let model = canvasModel else { return Data() }
        print("[EXPORT] exportStrokes called - reading from model: \(model.macOSStrokes.count) strokes")
        let encoder = JSONEncoder()
        let data = (try? encoder.encode(model.macOSStrokes)) ?? Data()
        print("[EXPORT] Encoded \(model.macOSStrokes.count) strokes into \(data.count) bytes")
        return data
    }

    // DR-0004.3: Import is now handled by the model
    // This method is kept for compatibility but delegates to model
    func importStrokes(from data: Data) {
        guard let model = canvasModel else { return }
        print("[DR-0004.3] importStrokes called with \(data.count) bytes")
        let decoder = JSONDecoder()
        guard let importedStrokes = try? decoder.decode([DrawingStroke].self, from: data) else {
            print("[DR-0004.3] ❌ Failed to decode strokes from data")
            return
        }

        print("[DR-0004.3] Successfully decoded \(importedStrokes.count) strokes into model")
        pushUndoState()
        model.macOSStrokes = importedStrokes
        model.hasStrokes = !model.macOSStrokes.isEmpty
        needsDisplay = true
        print("[DR-0004.3] ✅ Imported \(importedStrokes.count) strokes, hasStrokes: \(!model.macOSStrokes.isEmpty)")
    }

    /// DR-0004.3: Reload strokes from model (called when model is updated externally)
    func reloadFromModel() {
        print("[DR-0004.3] reloadFromModel called")
        needsDisplay = true
    }
    
    /// Import a PNG image as a background layer for the canvas
    func importPNGAsBackground(from pngData: Data) {
        guard let model = canvasModel else { return }
        
        // For now, we'll treat this as clearing the canvas and allowing the user to draw over it
        // In a more sophisticated implementation, you could create a background image layer
        // that sits behind all strokes
        
        // Clear existing strokes first
        pushUndoState()
        model.macOSStrokes.removeAll()
        
        // The PNG becomes the background - we'd need to store it separately
        // and render it in draw(_:) before drawing strokes
        // For simplicity, we're just clearing to allow fresh drawing
        
        needsDisplay = true
        model.hasStrokes = false
    }
}

// MARK: - Temporary Drawing Stroke (for active drawing)

/// Temporary structure used while actively drawing before converting to the codable DrawingStroke
private struct MacOSDrawingStroke {
    var points: [CGPoint]
    var color: NSColor
    var lineWidth: CGFloat
    var toolType: DrawingToolType
    var brushID: UUID?  // DR-0031: Store brush ID for advanced rendering
}

#endif
