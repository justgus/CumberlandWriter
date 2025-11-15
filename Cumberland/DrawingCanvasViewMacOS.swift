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
        
        // Connect the view to the model
        canvasState.macosCanvasView = view
        
        return view
    }
    
    func updateNSView(_ nsView: MacOSDrawingView, context: Context) {
        nsView.canvasModel = canvasState
        nsView.needsDisplay = true
    }
}

// MARK: - macOS Drawing View (NSView)

class MacOSDrawingView: NSView {
    var canvasModel: DrawingCanvasModel?
    
    // Current stroke being drawn
    private var currentStroke: DrawingStroke?
    
    // All completed strokes
    private var strokes: [DrawingStroke] = []
    
    // Undo stack
    private var undoStack: [[DrawingStroke]] = []
    private var redoStack: [[DrawingStroke]] = []
    
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
        
        let location = convert(event.locationInWindow, from: nil)
        
        // Save state for undo
        pushUndoState()
        
        // Start new stroke
        let color = NSColor(model.selectedColor)
        let lineWidth = model.selectedLineWidth
        
        currentStroke = DrawingStroke(
            points: [location],
            color: color,
            lineWidth: lineWidth,
            toolType: model.selectedToolType
        )
        
        needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        
        // Add point to current stroke
        currentStroke?.points.append(location)
        
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        // Finalize stroke
        if let stroke = currentStroke {
            strokes.append(stroke)
            currentStroke = nil
        }
        
        needsDisplay = true
        
        // Update model's isEmpty state
        canvasModel?.hasStrokes = !strokes.isEmpty
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Draw background
        if let bgColor = canvasModel?.backgroundColor {
            NSColor(bgColor).setFill()
        } else {
            NSColor.white.setFill()
        }
        context.fill(bounds)
        
        // Draw grid if enabled
        if let model = canvasModel, model.showGrid {
            drawGrid(in: context, spacing: model.gridSpacing, color: NSColor(model.gridColor))
        }
        
        // Draw all completed strokes
        for stroke in strokes {
            drawStroke(stroke, in: context)
        }
        
        // Draw current stroke being created
        if let stroke = currentStroke {
            drawStroke(stroke, in: context)
        }
    }
    
    private func drawStroke(_ stroke: DrawingStroke, in context: CGContext) {
        guard stroke.points.count > 1 else { return }
        
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
        context.setLineWidth(1.0)
        context.setAlpha(0.5)
        
        let width = bounds.width
        let height = bounds.height
        
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
        undoStack.append(strokes)
        redoStack.removeAll() // Clear redo stack when new action is performed
        
        // Limit undo stack size
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
    }
    
    func undo() {
        guard !undoStack.isEmpty else { return }
        
        redoStack.append(strokes)
        strokes = undoStack.removeLast()
        
        needsDisplay = true
        canvasModel?.hasStrokes = !strokes.isEmpty
    }
    
    func redo() {
        guard !redoStack.isEmpty else { return }
        
        undoStack.append(strokes)
        strokes = redoStack.removeLast()
        
        needsDisplay = true
        canvasModel?.hasStrokes = !strokes.isEmpty
    }
    
    func canUndo() -> Bool {
        !undoStack.isEmpty
    }
    
    func canRedo() -> Bool {
        !redoStack.isEmpty
    }
    
    func clear() {
        pushUndoState()
        strokes.removeAll()
        currentStroke = nil
        needsDisplay = true
        canvasModel?.hasStrokes = false
    }
    
    func isEmpty() -> Bool {
        strokes.isEmpty
    }
    
    // MARK: - Export
    
    func exportAsImageData() -> Data? {
        guard let bitmapRep = bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        cacheDisplay(in: bounds, to: bitmapRep)
        return bitmapRep.representation(using: .png, properties: [:])
    }
    
    func exportStrokes() -> Data {
        let encoder = JSONEncoder()
        let encodableStrokes = strokes.map { EncodableStroke(from: $0) }
        return (try? encoder.encode(encodableStrokes)) ?? Data()
    }
    
    func importStrokes(from data: Data) {
        let decoder = JSONDecoder()
        guard let encodableStrokes = try? decoder.decode([EncodableStroke].self, from: data) else { return }
        
        pushUndoState()
        strokes = encodableStrokes.map { $0.toDrawingStroke() }
        needsDisplay = true
        canvasModel?.hasStrokes = !strokes.isEmpty
    }
}

// MARK: - Drawing Stroke Model

struct DrawingStroke {
    var points: [CGPoint]
    var color: NSColor
    var lineWidth: CGFloat
    var toolType: DrawingToolType
}

// MARK: - Encodable Stroke (for saving/loading)

struct EncodableStroke: Codable {
    let points: [CGPointCodable]
    let colorRed: CGFloat
    let colorGreen: CGFloat
    let colorBlue: CGFloat
    let colorAlpha: CGFloat
    let lineWidth: CGFloat
    let toolType: String
    
    init(from stroke: DrawingStroke) {
        self.points = stroke.points.map { CGPointCodable(x: $0.x, y: $0.y) }
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        stroke.color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.colorRed = r
        self.colorGreen = g
        self.colorBlue = b
        self.colorAlpha = a
        self.lineWidth = stroke.lineWidth
        self.toolType = stroke.toolType.rawValue
    }
    
    func toDrawingStroke() -> DrawingStroke {
        DrawingStroke(
            points: points.map { CGPoint(x: $0.x, y: $0.y) },
            color: NSColor(red: colorRed, green: colorGreen, blue: colorBlue, alpha: colorAlpha),
            lineWidth: lineWidth,
            toolType: DrawingToolType(rawValue: toolType) ?? .pen
        )
    }
}

struct CGPointCodable: Codable {
    let x: CGFloat
    let y: CGFloat
}

#endif
