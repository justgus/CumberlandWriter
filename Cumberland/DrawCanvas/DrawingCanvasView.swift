//
//  DrawingCanvasView.swift
//  Cumberland
//
//  Created on 11/13/25.
//

import SwiftUI

#if canImport(PencilKit)
import PencilKit
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - DrawingCanvasView

/// A cross-platform drawing canvas powered by PencilKit.
/// Provides a complete drawing interface with tools, colors, undo/redo, and export capabilities.
struct DrawingCanvasView: View {
    @Binding var canvasState: DrawingCanvasModel
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var scrollPosition: CGPoint = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            DrawingToolbar(canvasState: $canvasState, scrollPosition: $scrollPosition)
            
            Divider()
            
            // Canvas with zoom and scroll
            #if canImport(PencilKit) && canImport(UIKit)
            ZoomableScrollView(
                contentSize: canvasState.canvasSize,
                zoomScale: $canvasState.zoomScale,
                scrollPosition: $scrollPosition
            ) {
                ZStack {
                    // Background
                    canvasBackgroundView
                    
                    // PencilKit Canvas
                    PencilKitCanvasView(
                        drawing: $canvasState.drawing,
                        tool: canvasState.selectedTool,
                        isRulerActive: canvasState.isRulerActive,
                        canvasSize: canvasState.canvasSize,
                        zoomScale: canvasState.zoomScale
                    )
                }
                .frame(width: canvasState.canvasSize.width, height: canvasState.canvasSize.height)
            }
            .onAppear {
                // Initialize the scroll view to the model's saved offset
                scrollPosition = canvasState.scrollOffset
            }
            .onChange(of: scrollPosition) { _, newValue in
                // Keep model in sync as user pans
                canvasState.scrollOffset = newValue
            }
            .onChange(of: canvasState.scrollOffset) { _, newValue in
                // If model changes externally (e.g., restored), update local state so ZoomableScrollView applies it
                if distance(scrollPosition, newValue) > 0.5 {
                    scrollPosition = newValue
                }
            }
            #elseif os(macOS)
            // macOS native drawing canvas
            MacOSScrollableCanvas(canvasState: $canvasState)
            #else
            // Placeholder for platforms without drawing support
            PlaceholderCanvasView()
            #endif
        }
    }
    
    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx*dx + dy*dy)
    }
    
    @ViewBuilder
    private var canvasBackgroundView: some View {
        ZStack {
            // Base color
            canvasState.backgroundColor
            
            // Optional grid overlay
            if canvasState.showGrid {
                GridOverlayView(
                    spacing: canvasState.gridSpacing * canvasState.zoomScale,
                    color: canvasState.gridColor
                )
            }
        }
    }
}

// MARK: - Drawing Canvas Model

/// Observable model for managing drawing canvas state
@Observable
class DrawingCanvasModel {
    // MARK: - Drawing Data
    
    #if canImport(PencilKit)
    /// The PencilKit drawing
    var drawing: PKDrawing = PKDrawing()
    #endif
    
    /// Canvas dimensions
    var canvasSize: CGSize = CGSize(width: 2048, height: 2048)
    
    // MARK: - Tool State
    
    #if canImport(PencilKit)
    /// Currently selected drawing tool
    var selectedTool: PKTool = PKInkingTool(.pen, color: .black, width: 5)
    #endif
    
    /// Ruler/shape tool active
    var isRulerActive: Bool = false
    
    /// Current tool type for UI
    var selectedToolType: DrawingToolType = .pen
    
    /// Current color
    var selectedColor: Color = .black
    
    /// Current line width
    var selectedLineWidth: CGFloat = 5
    
    // MARK: - Canvas Options
    
    /// Background color
    var backgroundColor: Color = .white
    
    /// Show grid overlay
    var showGrid: Bool = false
    
    /// Grid spacing in points
    var gridSpacing: CGFloat = 50
    
    /// Grid color
    var gridColor: Color = Color.gray.opacity(0.2)
    
    /// Grid type
    var gridType: GridType = .square
    
    // MARK: - Zoom and Pan State
    
    /// Current zoom scale
    var zoomScale: CGFloat = 1.0
    
    /// Current scroll/pan offset (UIScrollView contentOffset on iOS; UI-only on macOS)
    var scrollOffset: CGPoint = .zero
    
    /// Minimum zoom scale
    let minZoomScale: CGFloat = 0.25
    
    /// Maximum zoom scale
    let maxZoomScale: CGFloat = 4.0
    
    // MARK: - Undo/Redo Management
    
    /// Undo manager for canvas operations
    var undoManager: UndoManager = UndoManager()
    
    // MARK: - Computed Properties
    
    /// Whether the canvas has any content
    var isEmpty: Bool {
        #if canImport(PencilKit)
        return drawing.bounds.isEmpty
        #else
        // For macOS, this will need to be updated by the NSView
        return !hasStrokes
        #endif
    }
    
    /// For macOS native drawing: track if we have strokes
    #if os(macOS)
    var hasStrokes: Bool = false
    #endif
    
    /// Whether undo is available
    var canUndo: Bool {
        undoManager.canUndo
    }
    
    /// Whether redo is available
    var canRedo: Bool {
        undoManager.canRedo
    }
    
    // MARK: - Tool Configuration
    
    /// Update the selected tool with current settings
    func updateTool() {
        #if canImport(PencilKit)
        let pkColor: PKInkingTool.InkType
        
        switch selectedToolType {
        case .pen:
            pkColor = .pen
        case .pencil:
            pkColor = .pencil
        case .marker:
            pkColor = .marker
        case .eraser:
            selectedTool = PKEraserTool(.vector)
            return
        case .lasso:
            selectedTool = PKLassoTool()
            return
        }
        
        #if canImport(UIKit)
        selectedTool = PKInkingTool(pkColor, color: UIColor(selectedColor), width: selectedLineWidth)
        #elseif canImport(AppKit)
        selectedTool = PKInkingTool(pkColor, color: NSColor(selectedColor), width: selectedLineWidth)
        #endif
        #endif
    }
    
    // MARK: - Actions
    
    /// Zoom in on the canvas
    func zoomIn() {
        zoomScale = min(zoomScale * 1.5, maxZoomScale)
    }
    
    /// Zoom out on the canvas
    func zoomOut() {
        zoomScale = max(zoomScale / 1.5, minZoomScale)
    }
    
    /// Reset zoom to 100%
    func resetZoom() {
        zoomScale = 1.0
    }
    
    /// Fit canvas to available space
    func zoomToFit(availableSize: CGSize) {
        let widthScale = availableSize.width / canvasSize.width
        let heightScale = availableSize.height / canvasSize.height
        zoomScale = min(widthScale, heightScale, maxZoomScale)
    }
    
    /// Clear the entire canvas
    func clear() {
        #if canImport(PencilKit)
        let oldDrawing = drawing
        drawing = PKDrawing()
        
        // Register undo
        undoManager.registerUndo(withTarget: self) { target in
            target.drawing = oldDrawing
        }
        #endif
    }
    
    /// Export drawing as image data
    func exportAsImageData() -> Data? {
        #if canImport(PencilKit)
        let bounds = drawing.bounds.isEmpty ? CGRect(origin: .zero, size: canvasSize) : drawing.bounds
        
        #if canImport(UIKit)
        // Use a scale of 2.0 for high-quality export that works across all platforms
        // This provides retina-quality images without relying on deprecated UIScreen APIs
        let scale: CGFloat = 2.0
        let image = drawing.image(from: bounds, scale: scale)
        return image.pngData()
        #elseif canImport(AppKit)
        let image = drawing.image(from: bounds, scale: NSScreen.main?.backingScaleFactor ?? 2.0)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let nsImage = NSImage(cgImage: cgImage, size: bounds.size)
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
        #endif
        #else
        // For macOS native drawing, this will be handled by the NSView
        return macosCanvasView?.exportAsImageData()
        #endif
    }
    
    /// Export the full canvas (including background) as PNG for draft persistence
    func exportCanvasAsPNG() -> Data? {
        #if canImport(PencilKit) && canImport(UIKit)
        print("[CANVAS] exportCanvasAsPNG called")
        print("[CANVAS] Canvas size: \(canvasSize)")
        print("[CANVAS] Drawing bounds: \(drawing.bounds)")
        print("[CANVAS] Drawing isEmpty: \(drawing.bounds.isEmpty)")
        print("[CANVAS] Background color: \(backgroundColor)")
        print("[CANVAS] Show grid: \(showGrid)")
        
        // Create a renderer for the full canvas size
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let image = renderer.image { ctx in
            // Draw background
            backgroundColor.cgColor.map { UIColor(cgColor: $0).setFill() } ?? UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvasSize))
            
            // Draw grid if enabled
            if showGrid {
                let path = UIBezierPath()
                
                // Vertical lines
                var x: CGFloat = 0
                while x <= canvasSize.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: canvasSize.height))
                    x += gridSpacing
                }
                
                // Horizontal lines
                var y: CGFloat = 0
                while y <= canvasSize.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                    y += gridSpacing
                }
                
                UIColor(gridColor).setStroke()
                path.lineWidth = 1.0
                path.stroke(with: .normal, alpha: 0.5)
            }
            
            // Draw the PencilKit drawing
            let drawingImage = drawing.image(from: CGRect(origin: .zero, size: canvasSize), scale: 2.0)
            print("[CANVAS] Drawing image size: \(drawingImage.size)")
            drawingImage.draw(at: .zero)
        }
        
        let pngData = image.pngData()
        print("[CANVAS] PNG data size: \(pngData?.count ?? 0) bytes")
        return pngData
        #elseif os(macOS)
        // For macOS, use the native view's PNG export
        return macosCanvasView?.exportAsPNGData()
        #else
        return exportAsImageData()
        #endif
    }
    
    /// Import a PNG image as the canvas background/starting point
    func importCanvasFromPNG(_ data: Data) {
        #if canImport(PencilKit)
        // For PencilKit, we can't directly import a PNG as drawing data
        // Instead, we'll clear the canvas and the user can draw over the imported image
        // (The MapWizardView will handle displaying the PNG as a background layer)
        drawing = PKDrawing()
        #elseif os(macOS)
        // For macOS native drawing, import as background
        macosCanvasView?.importPNGAsBackground(from: data)
        #endif
    }
    
    /// Export drawing data (can be re-imported for editing)
    func exportDrawingData() -> Data {
        #if canImport(PencilKit)
        return drawing.dataRepresentation()
        #else
        // For macOS native drawing
        return macosCanvasView?.exportStrokes() ?? Data()
        #endif
    }
    
    /// Export complete canvas state including settings (for draft persistence)
    func exportCanvasState() -> Data? {
        let state = CanvasStateData(
            drawingData: exportDrawingData(),
            canvasSize: canvasSize,
            backgroundColor: backgroundColor.toHex(),
            showGrid: showGrid,
            gridSpacing: gridSpacing,
            gridColor: gridColor.toHex(),
            gridType: gridType.rawValue,
            zoomScale: zoomScale,
            scrollOffset: scrollOffset
        )
        return try? JSONEncoder().encode(state)
    }
    
    /// Import drawing data (for re-editing)
    func importDrawingData(_ data: Data) throws {
        #if canImport(PencilKit)
        drawing = try PKDrawing(data: data)
        #else
        // For macOS native drawing
        macosCanvasView?.importStrokes(from: data)
        #endif
    }
    
    /// Import complete canvas state from draft data
    func importCanvasState(_ data: Data) throws {
        let state = try JSONDecoder().decode(CanvasStateData.self, from: data)
        
        // Restore drawing
        try importDrawingData(state.drawingData)
        
        // Restore canvas settings
        canvasSize = state.canvasSize
        backgroundColor = Color(hex: state.backgroundColor)
        showGrid = state.showGrid
        gridSpacing = state.gridSpacing
        gridColor = Color(hex: state.gridColor)
        gridType = GridType(rawValue: state.gridType) ?? .square
        zoomScale = state.zoomScale
        scrollOffset = state.scrollOffset
    }
    
    // MARK: - macOS Native Drawing Support
    
    /// Reference to the macOS canvas view (set by the view when created)
    #if os(macOS)
    weak var macosCanvasView: MacOSDrawingView?
    #endif
    
    /// Called by macOS canvas to notify when strokes change
    func notifyStrokesChanged() {
        #if os(macOS)
        hasStrokes = macosCanvasView?.isEmpty() == false
        #endif
    }
}

// MARK: - Drawing Tool Types

enum DrawingToolType: String, CaseIterable, Identifiable {
    case pen = "Pen"
    case pencil = "Pencil"
    case marker = "Marker"
    case eraser = "Eraser"
    case lasso = "Lasso"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .pen: return "pencil"
        case .pencil: return "pencil.tip"
        case .marker: return "highlighter"
        case .eraser: return "eraser.fill"
        case .lasso: return "lasso"
        }
    }
}

enum GridType: String, CaseIterable, Identifiable {
    case square = "Square"
    case hex = "Hexagonal"
    
    var id: String { rawValue }
}

// MARK: - Drawing Toolbar

private struct DrawingToolbar: View {
    @Binding var canvasState: DrawingCanvasModel
    @Binding var scrollPosition: CGPoint
    
    private var canUndo: Bool {
        #if os(macOS)
        return canvasState.macosCanvasView?.canUndo() ?? false
        #else
        return canvasState.canUndo
        #endif
    }
    
    private var canRedo: Bool {
        #if os(macOS)
        return canvasState.macosCanvasView?.canRedo() ?? false
        #else
        return canvasState.canRedo
        #endif
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Tool selection
            ForEach(DrawingToolType.allCases) { toolType in
                Button(action: {
                    canvasState.selectedToolType = toolType
                    canvasState.updateTool()
                }) {
                    Image(systemName: toolType.icon)
                        .font(.title3)
                        .foregroundStyle(canvasState.selectedToolType == toolType ? .blue : .secondary)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(canvasState.selectedToolType == toolType ? Color.blue.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .help(toolType.rawValue)
            }
            
            Divider()
                .frame(height: 24)
            
            // Color picker (only for inking tools)
            if canvasState.selectedToolType != .eraser && canvasState.selectedToolType != .lasso {
                ColorPicker("", selection: $canvasState.selectedColor)
                    .labelsHidden()
                    .frame(width: 32)
                    .onChange(of: canvasState.selectedColor) { _, _ in
                        canvasState.updateTool()
                    }
                
                // Quick color swatches
                HStack(spacing: 4) {
                    ForEach(quickColors, id: \.self) { color in
                        Button(action: {
                            canvasState.selectedColor = color
                            canvasState.updateTool()
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(canvasState.selectedColor == color ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
                .frame(height: 24)
            
            // Line width slider (only for inking tools)
            if canvasState.selectedToolType != .eraser && canvasState.selectedToolType != .lasso {
                HStack(spacing: 8) {
                    Image(systemName: "lineweight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Slider(value: $canvasState.selectedLineWidth, in: 1...20)
                        .frame(width: 100)
                        .onChange(of: canvasState.selectedLineWidth) { _, _ in
                            canvasState.updateTool()
                        }
                    
                    Text("\(Int(canvasState.selectedLineWidth))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                }
            }
            
            Spacer()
            
            // Zoom controls
            HStack(spacing: 8) {
                Button(action: {
                    canvasState.zoomOut()
                }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.plain)
                .help("Zoom Out")
                
                Text("\(Int(canvasState.zoomScale * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50)
                
                Button(action: {
                    canvasState.zoomIn()
                }) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.plain)
                .help("Zoom In")
                
                Button(action: {
                    canvasState.resetZoom()
                }) {
                    Image(systemName: "1.magnifyingglass")
                }
                .buttonStyle(.plain)
                .help("Reset Zoom (100%)")
            }
            
            Divider()
                .frame(height: 24)
            
            // Ruler toggle
            Button(action: {
                canvasState.isRulerActive.toggle()
            }) {
                Image(systemName: "ruler")
                    .foregroundStyle(canvasState.isRulerActive ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Ruler")
            
            // Grid toggle
            Button(action: {
                canvasState.showGrid.toggle()
            }) {
                Image(systemName: "grid")
                    .foregroundStyle(canvasState.showGrid ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Grid")
            
            Divider()
                .frame(height: 24)
            
            // Undo/Redo
            Button(action: {
                #if os(macOS)
                canvasState.macosCanvasView?.undo()
                #else
                canvasState.undoManager.undo()
                #endif
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundStyle(canUndo ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(!canUndo)
            .help("Undo")
            
            Button(action: {
                #if os(macOS)
                canvasState.macosCanvasView?.redo()
                #else
                canvasState.undoManager.redo()
                #endif
            }) {
                Image(systemName: "arrow.uturn.forward")
                    .foregroundStyle(canRedo ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(!canRedo)
            .help("Redo")
            
            // Clear canvas
            Button(action: {
                #if os(macOS)
                canvasState.macosCanvasView?.clear()
                #else
                canvasState.clear()
                #endif
            }) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .disabled(canvasState.isEmpty)
            .help("Clear Canvas")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    private var quickColors: [Color] {
        [.black, .gray, .red, .orange, .yellow, .green, .blue, .purple]
    }
}

// MARK: - PencilKit Canvas Representable

#if canImport(PencilKit) && canImport(UIKit)

private struct PencilKitCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let tool: PKTool
    let isRulerActive: Bool
    let canvasSize: CGSize
    let zoomScale: CGFloat
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawing = drawing
        canvasView.tool = tool
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        
        // Disable the built-in scroll view since we're using our own
        canvasView.isScrollEnabled = false
        
        // Set content size
        canvasView.contentSize = canvasSize
        
        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        canvasView.tool = tool
        canvasView.isRulerActive = isRulerActive
        
        // Only update drawing if it's different (avoid infinite loop)
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }
        
        // Update content size if it changed
        if canvasView.contentSize != canvasSize {
            canvasView.contentSize = canvasSize
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilKitCanvasView
        
        init(_ parent: PencilKitCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

// MARK: - Zoomable Scroll View

private struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let contentSize: CGSize
    @Binding var zoomScale: CGFloat
    @Binding var scrollPosition: CGPoint
    let content: Content
    
    init(
        contentSize: CGSize,
        zoomScale: Binding<CGFloat>,
        scrollPosition: Binding<CGPoint>,
        @ViewBuilder content: () -> Content
    ) {
        self.contentSize = contentSize
        self._zoomScale = zoomScale
        self._scrollPosition = scrollPosition
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 0.25
        scrollView.maximumZoomScale = 4.0
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        
        // Create hosting controller for SwiftUI content
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        
        scrollView.addSubview(hostingController.view)
        
        // Store hosting controller in coordinator
        context.coordinator.hostingController = hostingController
        
        // Set up constraints
        NSLayoutConstraint.activate([
            hostingController.view.widthAnchor.constraint(equalToConstant: contentSize.width),
            hostingController.view.heightAnchor.constraint(equalToConstant: contentSize.height),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        ])
        
        scrollView.contentSize = contentSize
        scrollView.zoomScale = zoomScale
        scrollView.setContentOffset(scrollPosition, animated: false)
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // Update zoom scale if changed externally
        if abs(scrollView.zoomScale - zoomScale) > 0.01 {
            scrollView.setZoomScale(zoomScale, animated: false)
        }
        
        // Update content size if it changed
        if scrollView.contentSize != contentSize {
            scrollView.contentSize = contentSize
            if let hostingView = context.coordinator.hostingController?.view {
                NSLayoutConstraint.deactivate(hostingView.constraints)
                NSLayoutConstraint.activate([
                    hostingView.widthAnchor.constraint(equalToConstant: contentSize.width),
                    hostingView.heightAnchor.constraint(equalToConstant: contentSize.height)
                ])
            }
        }
        
        // Apply external scroll position changes (e.g., after restore)
        if distance(scrollView.contentOffset, scrollPosition) > 0.5 {
            scrollView.setContentOffset(scrollPosition, animated: false)
        }
        
        // Update SwiftUI content
        context.coordinator.hostingController?.rootView = content
    }
    
    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx*dx + dy*dy)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(zoomScale: $zoomScale, scrollPosition: $scrollPosition)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        @Binding var zoomScale: CGFloat
        @Binding var scrollPosition: CGPoint
        var hostingController: UIHostingController<Content>?
        
        init(zoomScale: Binding<CGFloat>, scrollPosition: Binding<CGPoint>) {
            self._zoomScale = zoomScale
            self._scrollPosition = scrollPosition
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController?.view
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // Defer state mutation to avoid "Modifying state during view update"
            let newScale = scrollView.zoomScale
            DispatchQueue.main.async {
                self.zoomScale = newScale
            }
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // Defer state mutation to avoid "Modifying state during view update"
            let newOffset = scrollView.contentOffset
            DispatchQueue.main.async {
                self.scrollPosition = newOffset
            }
        }
    }
}

#endif

// MARK: - macOS Scrollable Canvas Wrapper

#if os(macOS)
private struct MacOSScrollableCanvas: View {
    @Binding var canvasState: DrawingCanvasModel
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                DrawingCanvasViewMacOS(canvasState: $canvasState)
                    .frame(
                        width: canvasState.canvasSize.width * canvasState.zoomScale,
                        height: canvasState.canvasSize.height * canvasState.zoomScale
                    )
                    .scaleEffect(canvasState.zoomScale)
            }
        }
    }
}
#endif

// MARK: - Placeholder Canvas View (for platforms without drawing support)

#if !canImport(PencilKit) && !os(macOS)
private struct PlaceholderCanvasView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pencil.and.scribble")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Drawing Canvas")
                .font(.title)
                .foregroundStyle(.primary)
            
            Text("Interactive drawing canvas is not available on this platform")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Drawing functionality requires iOS, iPadOS, or macOS")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
#endif

// MARK: - Grid Overlay

private struct GridOverlayView: View {
    let spacing: CGFloat
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Vertical lines
                var x: CGFloat = 0
                while x <= width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                    x += spacing
                }
                
                // Horizontal lines
                var y: CGFloat = 0
                while y <= height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                    y += spacing
                }
            }
            .stroke(color, lineWidth: 1)
        }
    }
}

// MARK: - Preview

#Preview("Drawing Canvas") {
    @Previewable @State var canvasModel = DrawingCanvasModel()
    
    DrawingCanvasView(canvasState: .constant(canvasModel))
        .frame(width: 800, height: 600)
}

// MARK: - Canvas State Serialization

/// Codable structure for persisting complete canvas state
struct CanvasStateData: Codable {
    let drawingData: Data
    let canvasSize: CGSize
    let backgroundColor: String
    let showGrid: Bool
    let gridSpacing: CGFloat
    let gridColor: String
    let gridType: String
    let zoomScale: CGFloat
    let scrollOffset: CGPoint
}

// MARK: - Color Hex Extensions

extension Color {
    /// Convert Color to hex string for serialization
    func toHex() -> String {
        #if canImport(UIKit)
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        #elseif canImport(AppKit)
        guard let components = NSColor(self).cgColor.components else { return "#000000" }
        #endif
        
        let r = components[0]
        let g = components.count > 1 ? components[1] : r
        let b = components.count > 2 ? components[2] : r
        let a = components.count > 3 ? components[3] : 1.0
        
        if a < 1.0 {
            return String(format: "#%02X%02X%02X%02X", 
                         Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
        } else {
            return String(format: "#%02X%02X%02X", 
                         Int(r * 255), Int(g * 255), Int(b * 255))
        }
    }
    
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b, a: UInt64
        switch hex.count {
        case 6: // RGB
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8: // RGBA
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
