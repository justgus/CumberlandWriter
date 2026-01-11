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
    // DR-0006: Initialize scroll position from model to ensure restoration works
    @State private var scrollPosition: CGPoint
    // DR-0011: Track container size for proper palette positioning
    @State private var containerSize: CGSize = .zero

    // DR-0006: Initialize with scroll position from model for proper restoration
    init(canvasState: Binding<DrawingCanvasModel>) {
        self._canvasState = canvasState
        self._scrollPosition = State(initialValue: canvasState.wrappedValue.scrollOffset)
    }

    var body: some View {
        GeometryReader { geometry in
            content
                .onAppear {
                    containerSize = geometry.size
                }
                .onChange(of: geometry.size) { _, newSize in
                    containerSize = newSize
                }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            // Toolbar
            DrawingToolbar(canvasState: $canvasState, scrollPosition: $scrollPosition)

            Divider()

            // Canvas with zoom and scroll - with palette overlay
            ZStack {
                // Canvas area
                #if canImport(PencilKit) && canImport(UIKit)
                ZoomableScrollView(
                    contentSize: canvasState.canvasSize,
                    zoomScale: $canvasState.zoomScale,
                    scrollPosition: $scrollPosition
                ) {
                    ZStack {
                        // Background
                        canvasBackgroundView

                        // DR-0024: Render all non-active visible layers underneath the canvas
                        if let layerManager = canvasState.layerManager {
                            LayerCompositeView(
                                layerManager: layerManager,
                                canvasSize: canvasState.canvasSize,
                                excludeActiveLayer: true
                            )
                            .frame(width: canvasState.canvasSize.width, height: canvasState.canvasSize.height)
                            // DR-0025: Force SwiftUI to recreate view when layer visibility or order changes
                            .id(layerManager.layers.map { "\($0.id)_\($0.isVisible)_\($0.order)" }.joined())
                        }

                        // PencilKit Canvas (shows only active layer)
                        PencilKitCanvasView(
                            drawing: $canvasState.drawing,
                            tool: canvasState.selectedTool,
                            isRulerActive: canvasState.isRulerActive,
                            canvasSize: canvasState.canvasSize,
                            zoomScale: canvasState.zoomScale,
                            layerManager: canvasState.layerManager
                        )
                        .id(canvasState.toolChangeCounter)  // Force update when tool changes (DR-0001, DR-0002, DR-0003)
                    }
                    .frame(width: canvasState.canvasSize.width, height: canvasState.canvasSize.height)
                }
                .onChange(of: canvasState.layerManager?.activeLayerID) { _, _ in
                    // DR-0024/DR-0026: Sync canvas drawing with active layer when layer selection changes
                    canvasState.syncDrawingWithActiveLayer()
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

                // DR-0011: Floating tool palette overlay - positioned over canvas area only
                if canvasState.toolPaletteState.isVisible {
                    FloatingToolPalette(
                        canvasState: $canvasState,
                        containerSize: containerSize
                    )
                    .frame(width: canvasState.toolPaletteState.width)
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
        }
        .onAppear {
            // Auto-initialize LayerManager for new and existing drawings
            canvasState.ensureLayerManager()

            // DR-0024/DR-0026: Sync canvas with active layer on load
            #if canImport(PencilKit) && canImport(UIKit)
            canvasState.syncDrawingWithActiveLayer()
            #endif
        }
        .onChange(of: canvasState.toolPaletteState.selectedBrushID) { _, newBrushID in
            // ER-0003: Update canvas tool when brush selection changes (cross-platform)
            if let _ = newBrushID,
               let brush = BrushRegistry.shared.selectedBrush {
                canvasState.updateToolFromBrush(brush)
            }
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
            // 1. Base color
            canvasState.backgroundColor

            // 2. Base layer fill (if exists)
            if let baseLayer = canvasState.layerManager?.baseLayer,
               let fill = baseLayer.layerFill {
                #if canImport(UIKit)
                // DR-0016: Use procedural terrain for exterior fill types with metadata
                if fill.usesProceduralTerrain, let metadata = fill.terrainMetadata {
                    ProceduralTerrainView(
                        fill: fill,
                        metadata: metadata,
                        canvasSize: canvasState.canvasSize
                    )
                    .opacity(fill.opacity)
                }
                // DR-0015: Use procedural patterns for interior fill types
                else if fill.usesProceduralPattern {
                    ProceduralPatternView(fill: fill, canvasSize: canvasState.canvasSize)
                        .opacity(fill.opacity)
                } else {
                    // Simple solid color fill for exterior types without terrain metadata
                    Rectangle()
                        .fill(fill.effectiveColor)
                        .opacity(fill.opacity)
                        .frame(width: canvasState.canvasSize.width,
                               height: canvasState.canvasSize.height)
                }
                #else
                // macOS uses direct Core Graphics rendering in the native view
                Rectangle()
                    .fill(fill.effectiveColor)
                    .opacity(fill.opacity)
                    .frame(width: canvasState.canvasSize.width,
                           height: canvasState.canvasSize.height)
                #endif
            }

            // 3. Optional grid overlay
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

    /// Tool change counter to force SwiftUI updates (DR-0001, DR-0002, DR-0003)
    /// PKTool is not Equatable, so we use this counter with .id() to detect changes
    var toolChangeCounter: Int = 0

    /// ER-0003: Currently selected brush (nil = use basic tool settings)
    var selectedBrush: MapBrush?

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

    // MARK: - Tool Palette

    /// State for the floating tool palette
    var toolPaletteState: ToolPaletteState = ToolPaletteState()

    /// Layer manager for multi-layer drawing (optional for backward compatibility)
    var layerManager: LayerManager?

    // MARK: - Base Layer Generation State (ER-0006)

    /// Indicates whether base layer terrain is currently being generated
    var isGeneratingBaseLayer: Bool = false

    /// ER-0001: Map category (Interior vs Exterior) for context-aware UI
    var mapCategory: BaseLayerCategory?

    // MARK: - Layer Manager Initialization

    /// Ensures a LayerManager exists, creating one if needed
    /// Call this when loading existing drawings or creating new ones
    func ensureLayerManager() {
        guard layerManager == nil else { return }

        // Create new layer manager with default base layer
        let manager = LayerManager()

        // Rename the default layer created by LayerManager to be the base layer
        if let defaultLayer = manager.baseLayer {
            defaultLayer.name = "Base Layer"
            defaultLayer.layerType = .terrain
            // Base layer is for fills only - no drawing content
        }

        /*
        var hasExistingContent = false

        // Check if there's existing drawing content to migrate
        #if canImport(PencilKit)
        if !drawing.bounds.isEmpty {
            hasExistingContent = true
        }
        #endif

        #if os(macOS)
        if !macOSStrokes.isEmpty {
            hasExistingContent = true
        }
        #endif
        */

        // Create content layer (always create this)
        let contentLayer = manager.createLayerAboveActive(name: "Content", type: .generic)

        // If there's existing content, migrate it to the content layer (NOT base layer)
        #if canImport(PencilKit)
        if !drawing.bounds.isEmpty {
            contentLayer.drawing = drawing
            contentLayer.name = "Content (Migrated)"
        }
        #endif

        #if os(macOS)
        if !macOSStrokes.isEmpty {
            contentLayer.macosStrokes = macOSStrokes
            contentLayer.name = "Content (Migrated)"
            // Clear the old strokes since they're now in the layer
            macOSStrokes = []
        }
        #endif

        // Set content layer as active so drawing goes there by default
        manager.activeLayerID = contentLayer.id

        layerManager = manager
    }

    /// DR-0024/DR-0026: Sync canvas drawing with active layer
    /// Call this when switching layers to load the active layer's content into the canvas
    #if canImport(PencilKit) && canImport(UIKit)
    func syncDrawingWithActiveLayer() {
        guard let layerManager = layerManager,
              let activeLayer = layerManager.activeLayer else {
            return
        }

        print("[syncDrawingWithActiveLayer] Syncing canvas with layer: \(activeLayer.name)")
        drawing = activeLayer.drawing
    }
    #endif

    // MARK: - Computed Properties
    
    /// Whether the canvas has any content
    var isEmpty: Bool {
        #if canImport(PencilKit) && canImport(UIKit)
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
            toolChangeCounter += 1
            print("[DR-0012] Updated tool to eraser, counter: \(toolChangeCounter)")
            return
        case .lasso:
            selectedTool = PKLassoTool()
            toolChangeCounter += 1
            print("[DR-0012] Updated tool to lasso, counter: \(toolChangeCounter)")
            return
        }

        #if canImport(UIKit)
        // Use toPencilKitColor() to prevent black color inversion issue (DR-0001)
        // DR-0012: Apply 3.0x multiplier on iOS to match macOS visual thickness
        let effectiveWidth = selectedLineWidth * 3.0
        selectedTool = PKInkingTool(pkColor, color: selectedColor.toPencilKitColor(), width: effectiveWidth)
        print("[DR-0012] iOS - Created PKInkingTool with slider: \(selectedLineWidth) → effective width: \(effectiveWidth)")
        #elseif canImport(AppKit)
        selectedTool = PKInkingTool(pkColor, color: NSColor(selectedColor), width: selectedLineWidth)
        print("[DR-0012] macOS - Created PKInkingTool with width: \(selectedLineWidth)")
        #endif
        toolChangeCounter += 1
        print("[DR-0012] Updated inking tool (\(selectedToolType.rawValue)), counter: \(toolChangeCounter)")
        #endif
    }

    /// ER-0003: Update selected tool based on a MapBrush selection
    func updateToolFromBrush(_ brush: MapBrush) {
        // Store the brush for both platforms
        selectedBrush = brush

        #if canImport(PencilKit) && canImport(UIKit)
        // iOS: Use BrushEngine to create PencilKit tool from brush
        selectedTool = BrushEngine.createAdvancedPKTool(
            from: brush,
            color: selectedColor,
            width: selectedLineWidth
        )
        toolChangeCounter += 1
        print("[ER-0003] iOS - Updated tool from brush: \(brush.name), counter: \(toolChangeCounter)")
        #elseif os(macOS)
        // macOS: Store brush for use during drawing (no tool object needed)
        print("[ER-0003] macOS - Selected brush: \(brush.name)")
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
        #if canImport(PencilKit) && canImport(UIKit)
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
        #if canImport(PencilKit) && canImport(UIKit)
        // iOS/iPadOS: Use PencilKit
        let bounds = drawing.bounds.isEmpty ? CGRect(origin: .zero, size: canvasSize) : drawing.bounds
        let scale: CGFloat = 2.0
        let image = drawing.image(from: bounds, scale: scale)
        return image.pngData()
        #else
        // macOS: Use native drawing view
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
        #if canImport(PencilKit) && canImport(UIKit)
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
        #if canImport(PencilKit) && canImport(UIKit)
        // iOS/iPadOS: Use PencilKit
        let data = drawing.dataRepresentation()
        print("[EXPORT] exportDrawingData (PencilKit) - \(data.count) bytes")
        return data
        #else
        // macOS: Export from model (persists across view recreation)
        print("[EXPORT] exportDrawingData - exporting \(macOSStrokes.count) strokes from model")
        let encoder = JSONEncoder()
        let data = (try? encoder.encode(macOSStrokes)) ?? Data()
        print("[EXPORT] exportDrawingData returning \(data.count) bytes")
        return data
        #endif
    }
    
    /// Export complete canvas state including settings (for draft persistence)
    func exportCanvasState() -> Data? {
        print("[EXPORT] exportCanvasState called")

        // DR-0024: Migration code REMOVED - strokes now save directly to layers in real-time
        // This obsolete migration code was causing data loss when autosave triggered:
        // - It would overwrite activeLayer.drawing with model.drawing
        // - But model.drawing contains view state (what's displayed), not editing state
        // - When viewing a different layer, model.drawing doesn't match activeLayerID
        // - Result: Autosave would overwrite the active layer with the wrong layer's content
        //
        // Since DR-0023, strokes save to layers in real-time via:
        // - iOS: canvasViewDrawingDidChange() saves to activeLayer.drawing
        // - macOS: mouseUp() saves to activeLayer.macosStrokes
        // No migration needed at export time - layers already have the correct data.

        ensureLayerManager()

        let drawingData = exportDrawingData()
        print("[EXPORT] Got \(drawingData.count) bytes of drawing data (legacy/fallback)")

        // DR-0008: Encode LayerManager if it exists
        var layerManagerData: Data? = nil
        if let manager = layerManager {
            print("[EXPORT] Encoding LayerManager with \(manager.layerCount) layers")
            layerManagerData = try? JSONEncoder().encode(manager)
            print("[EXPORT] LayerManager encoded to \(layerManagerData?.count ?? 0) bytes")
        } else {
            print("[EXPORT] No LayerManager to encode")
        }

        let state = CanvasStateData(
            drawingData: drawingData,
            canvasSize: canvasSize,
            backgroundColor: backgroundColor.toHex(),
            showGrid: showGrid,
            gridSpacing: gridSpacing,
            gridColor: gridColor.toHex(),
            gridType: gridType.rawValue,
            zoomScale: zoomScale,
            scrollOffset: scrollOffset,
            // DR-0006: Save tool palette state
            isRulerActive: isRulerActive,
            selectedToolType: selectedToolType.rawValue,
            selectedColor: selectedColor.toHex(),
            selectedLineWidth: selectedLineWidth,
            // DR-0008: Save layer manager
            layerManagerData: layerManagerData,
            // ER-0001: Save map category
            mapCategory: mapCategory?.rawValue
        )
        let encoded = try? JSONEncoder().encode(state)
        print("[EXPORT] exportCanvasState returning \(encoded?.count ?? 0) bytes total")
        return encoded
    }
    
    /// Import drawing data (for re-editing)
    func importDrawingData(_ data: Data) throws {
        #if canImport(PencilKit) && canImport(UIKit)
        // iOS/iPadOS: Use PencilKit
        drawing = try PKDrawing(data: data)
        #else
        // macOS: Import into model (persists across view recreation)
        print("[DR-0004.3] importDrawingData called with \(data.count) bytes")
        let decoder = JSONDecoder()
        guard let importedStrokes = try? decoder.decode([DrawingStroke].self, from: data) else {
            print("[DR-0004.3] ❌ Failed to decode strokes from import data")
            return
        }

        print("[DR-0004.3] Successfully decoded \(importedStrokes.count) strokes into model")
        macOSStrokes = importedStrokes
        hasStrokes = !macOSStrokes.isEmpty

        // If view exists, tell it to reload
        if let view = macosCanvasView {
            print("[DR-0004.3] Notifying view to reload from model")
            view.reloadFromModel()
        }
        #endif
    }
    
    /// Import complete canvas state from draft data
    func importCanvasState(_ data: Data) throws {
        let state = try JSONDecoder().decode(CanvasStateData.self, from: data)

        // DR-0008: Restore LayerManager FIRST if it exists
        if let layerManagerData = state.layerManagerData {
            print("[IMPORT] Decoding LayerManager from \(layerManagerData.count) bytes")
            do {
                let manager = try JSONDecoder().decode(LayerManager.self, from: layerManagerData)
                layerManager = manager
                print("[IMPORT] Restored LayerManager with \(manager.layerCount) layers")

                // DR-0016.1: Migrate old exterior base layers to include terrain metadata
                if let baseLayer = manager.baseLayer,
                   let fill = baseLayer.layerFill,
                   fill.fillType.category == .exterior,
                   fill.terrainMetadata == nil {
                    print("[IMPORT] Migrating exterior base layer '\(fill.fillType.displayName)' to include terrain metadata")

                    // Create default terrain metadata for migrated maps
                    let metadata = TerrainMapMetadata(
                        physicalSizeMiles: 100.0, // Default to medium scale
                        terrainSeed: Int.random(in: 1...999999)
                    )

                    // Create new fill with metadata
                    let migratedFill = LayerFill(
                        fillType: fill.fillType,
                        customColor: fill.customColor,
                        opacity: fill.opacity,
                        patternSeed: fill.patternSeed,
                        terrainMetadata: metadata
                    )

                    baseLayer.layerFill = migratedFill
                    print("[IMPORT] Migration complete - terrain metadata added: \(metadata.description)")
                }

                // DR-0013: Extract content from active layer to main drawing properties for display
                if let activeLayer = manager.activeLayer {
                    #if canImport(PencilKit) && canImport(UIKit)
                    // iOS: Copy PKDrawing from active layer to main drawing
                    if !activeLayer.drawing.bounds.isEmpty {
                        drawing = activeLayer.drawing
                        print("[IMPORT] Extracted \(drawing.strokes.count) strokes from active layer to main drawing (iOS)")
                    }
                    #else
                    // macOS: Copy macOS strokes from active layer to main strokes array
                    if !activeLayer.macosStrokes.isEmpty {
                        macOSStrokes = activeLayer.macosStrokes
                        hasStrokes = true
                        print("[IMPORT] Extracted \(macOSStrokes.count) strokes from active layer to main drawing (macOS)")

                        // Notify view to reload if it exists
                        if let view = macosCanvasView {
                            print("[IMPORT] Notifying macOS view to reload")
                            view.reloadFromModel()
                        }
                    }
                    #endif
                }
            } catch {
                print("[IMPORT] ⚠️ Failed to decode LayerManager: \(error)")
                // Fall back to creating a new one later via ensureLayerManager
                layerManager = nil
            }
        } else {
            print("[IMPORT] No LayerManager data in state (legacy draft)")
            // For backward compatibility: Leave layerManager nil, ensureLayerManager will create it
            layerManager = nil
        }

        // Restore drawing (for backward compatibility or as fallback)
        // Use legacy import if: (1) no LayerManager, OR (2) LayerManager has no content for this platform
        #if os(macOS)
        let shouldUseLegacyImport = layerManager == nil || macOSStrokes.isEmpty
        #else
        let shouldUseLegacyImport = layerManager == nil || drawing.bounds.isEmpty
        #endif

        if shouldUseLegacyImport {
            if layerManager != nil {
                print("[IMPORT] LayerManager has no content for this platform - falling back to legacy import")
            }
            try importDrawingData(state.drawingData)
        } else {
            print("[IMPORT] Using LayerManager content - skipping legacy import")
        }

        // Restore canvas settings
        canvasSize = state.canvasSize
        backgroundColor = Color(hex: state.backgroundColor)
        showGrid = state.showGrid
        gridSpacing = state.gridSpacing
        gridColor = Color(hex: state.gridColor)
        gridType = GridType(rawValue: state.gridType) ?? .square
        zoomScale = state.zoomScale
        scrollOffset = state.scrollOffset

        // DR-0006: Restore tool palette state
        isRulerActive = state.isRulerActive
        selectedToolType = DrawingToolType(rawValue: state.selectedToolType) ?? .pen
        selectedColor = Color(hex: state.selectedColor)
        selectedLineWidth = state.selectedLineWidth

        // ER-0001: Restore map category
        if let categoryString = state.mapCategory {
            mapCategory = BaseLayerCategory(rawValue: categoryString)
        }

        // Update the actual tool with restored settings
        updateTool()
    }
    
    // MARK: - macOS Native Drawing Support
    
    /// Reference to the macOS canvas view (set by the view when created)
    #if os(macOS)
    weak var macosCanvasView: MacOSDrawingView?

    /// DR-0004.3: Store strokes in the model to persist across view recreation
    /// SwiftUI may recreate the NSView, so we store strokes here (not in the view)
    var macOSStrokes: [DrawingStroke] = []

    /// DR-0004.3: Pending stroke data to import when view is created
    /// Stores stroke data that needs to be imported before the macOS view exists
    var pendingStrokeData: Data?
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

    // State for editing zoom percentage
    @State private var isEditingZoom: Bool = false
    @State private var zoomText: String = ""
    @FocusState private var zoomFieldFocused: Bool

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
        // DR-0009: Wrap toolbar in ScrollView on iOS for narrow screens
        #if os(iOS)
        ScrollView(.horizontal, showsIndicators: false) {
            toolbarContent
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        #else
        toolbarContent
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        #endif
    }

    // MARK: - Toolbar Content

    private var toolbarContent: some View {
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
                        .onChange(of: canvasState.selectedLineWidth) { oldValue, newValue in
                            print("[DR-0012] Slider changed from \(oldValue) to \(newValue)")
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

                // Editable zoom percentage
                if isEditingZoom {
                    TextField("", text: $zoomText)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .textFieldStyle(.plain)
                        .focused($zoomFieldFocused)
                        .onSubmit {
                            applyCustomZoom()
                        }
                        #if os(macOS)
                        .onExitCommand {
                            cancelZoomEdit()
                        }
                        #endif
                } else {
                    Text("\(Int(canvasState.zoomScale * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 50)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            startZoomEdit()
                        }
                        .help("Click to enter custom zoom percentage")
                }

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

            // DR-0007: Ruler toggle (iOS/iPadOS only - PencilKit feature)
            #if canImport(PencilKit) && canImport(UIKit)
            Button(action: {
                canvasState.isRulerActive.toggle()
            }) {
                Image(systemName: "ruler")
                    .foregroundStyle(canvasState.isRulerActive ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Ruler")

            Divider()
                .frame(height: 24)
            #endif

            // Grid toggle
            Button(action: {
                canvasState.showGrid.toggle()
            }) {
                Image(systemName: "grid")
                    .foregroundStyle(canvasState.showGrid ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Grid")

            // Tool Palette toggle
            Button(action: {
                canvasState.toolPaletteState.toggleVisibility()
            }) {
                Image(systemName: "sidebar.right")
                    .foregroundStyle(canvasState.toolPaletteState.isVisible ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Tool Palette")

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
    }

    // MARK: - Zoom Editing Helpers

    private func startZoomEdit() {
        zoomText = String(Int(canvasState.zoomScale * 100))
        isEditingZoom = true
        zoomFieldFocused = true
    }

    private func applyCustomZoom() {
        // Parse the input text
        let trimmed = zoomText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "%", with: "")

        if let percentage = Int(trimmed) {
            // Clamp to valid range (25% to 400%)
            let clampedPercentage = max(Int(canvasState.minZoomScale * 100), min(percentage, Int(canvasState.maxZoomScale * 100)))
            canvasState.zoomScale = CGFloat(clampedPercentage) / 100.0
        }

        // Exit edit mode
        isEditingZoom = false
        zoomFieldFocused = false
    }

    private func cancelZoomEdit() {
        isEditingZoom = false
        zoomFieldFocused = false
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
    let layerManager: LayerManager?
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawing = drawing
        canvasView.tool = tool
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear

        // Force light mode to prevent color inversion (DR-0001)
        canvasView.overrideUserInterfaceStyle = .light

        // Disable the built-in scroll view since we're using our own
        canvasView.isScrollEnabled = false

        // Set content size
        canvasView.contentSize = canvasSize

        // DR-0012: Log tool details on canvas creation
        if let inkingTool = tool as? PKInkingTool {
            print("[DR-0012] makeUIView - Created canvas with inking tool width: \(inkingTool.width)")
        } else {
            print("[DR-0012] makeUIView - Created canvas with non-inking tool: \(type(of: tool))")
        }

        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        canvasView.tool = tool
        canvasView.isRulerActive = isRulerActive

        // DR-0012: Log tool details on update
        if let inkingTool = tool as? PKInkingTool {
            print("[DR-0012] updateUIView - Updated canvas tool width: \(inkingTool.width)")
        }

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
        var previousActiveLayerID: UUID?

        init(_ parent: PencilKitCanvasView) {
            self.parent = parent
            self.previousActiveLayerID = parent.layerManager?.activeLayerID
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // DR-0023/DR-0026: Detect layer switches to prevent data loss
            if let layerManager = parent.layerManager {
                let currentActiveLayerID = layerManager.activeLayerID

                // Check if active layer changed since last drawing update
                if previousActiveLayerID != currentActiveLayerID {
                    print("[canvasViewDrawingDidChange] Layer switch detected: \(String(describing: previousActiveLayerID)) -> \(String(describing: currentActiveLayerID))")

                    // Layer switched: LOAD the new active layer's drawing into canvas
                    // Don't save - that would overwrite the new layer with old content
                    if let activeLayer = layerManager.activeLayer {
                        parent.drawing = activeLayer.drawing
//                        canvasView.drawing = activeLayer.drawing
                    }

                    previousActiveLayerID = currentActiveLayerID
                    return  // Skip save on layer switch
                }

                // DR-0023 / ER-0002: Save strokes to appropriate layer
                // Base layer (order == 0) should never receive strokes
                let targetLayer = layerManager.getTargetLayerForStrokes()
                targetLayer.drawing = canvasView.drawing
                targetLayer.markModified()

                // Update parent binding
                parent.drawing = canvasView.drawing
                previousActiveLayerID = currentActiveLayerID
            } else {
                // No layer manager: use simple binding update
                parent.drawing = canvasView.drawing
            }
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

// MARK: - Layer Composite View (iOS)

/// DR-0024: Renders all non-active visible layers underneath the active PencilKit canvas
/// Uses UIKit for direct control over rendering to avoid Canvas masking and color issues
private struct LayerCompositeView: UIViewRepresentable {
    let layerManager: LayerManager
    let canvasSize: CGSize
    let excludeActiveLayer: Bool

    func makeUIView(context: Context) -> LayerCompositeUIView {
        let view = LayerCompositeUIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false  // Let touches pass through
        return view
    }

    func updateUIView(_ uiView: LayerCompositeUIView, context: Context) {
        // Get layers to render (sorted bottom to top)
        let layersToRender = layerManager.sortedLayers.filter { layer in
            guard layer.isVisible else { return false }
            if excludeActiveLayer && layer.id == layerManager.activeLayerID { return false }
            if layer.order == 0 { return false }  // Base layer rendered separately
            return true
        }

        uiView.layersToRender = layersToRender
        uiView.canvasSize = canvasSize
        uiView.setNeedsDisplay()
    }
}

/// UIView that renders layer drawings directly
private class LayerCompositeUIView: UIView {
    var layersToRender: [DrawingLayer] = []
    var canvasSize: CGSize = .zero

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Render each layer
        for layer in layersToRender {
            context.saveGState()
            context.setAlpha(layer.opacity)

            // DR-0027/0028: Generate image at appropriate scale
            // Use 0 for scale to match current screen automatically
            let image = layer.drawing.image(from: CGRect(origin: .zero, size: canvasSize), scale: 0)

            // DR-0027: Draw the full image at full canvas size
            image.draw(in: CGRect(origin: .zero, size: canvasSize))

            context.restoreGState()
        }
    }

    // DR-0028: Override trait collection to force light mode (prevents color inversion)
    override var traitCollection: UITraitCollection {
        return super.traitCollection.modifyingTraits { mutableTraits in
            mutableTraits.userInterfaceStyle = .light
        }
    }
}

#endif

// MARK: - macOS Scrollable Canvas Wrapper

#if os(macOS)
private struct MacOSScrollableCanvas: NSViewRepresentable {
    @Binding var canvasState: DrawingCanvasModel

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder

        // Create the canvas view
        let canvasView = NSHostingView(rootView: DrawingCanvasViewMacOS(canvasState: $canvasState))
        canvasView.frame = NSRect(
            x: 0, y: 0,
            width: canvasState.canvasSize.width * canvasState.zoomScale,
            height: canvasState.canvasSize.height * canvasState.zoomScale
        )

        scrollView.documentView = canvasView
        context.coordinator.canvasView = canvasView

        // Set up notification for scroll changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scrollViewDidScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        // DR-0006: Restore initial scroll position
        if canvasState.scrollOffset != .zero {
            scrollView.contentView.scroll(to: NSPoint(
                x: canvasState.scrollOffset.x,
                y: canvasState.scrollOffset.y
            ))
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        // Update canvas size if changed
        let newSize = NSSize(
            width: canvasState.canvasSize.width * canvasState.zoomScale,
            height: canvasState.canvasSize.height * canvasState.zoomScale
        )

        if let canvasView = context.coordinator.canvasView {
            if canvasView.frame.size != newSize {
                canvasView.frame.size = newSize
            }
            // Update the SwiftUI content
            canvasView.rootView = DrawingCanvasViewMacOS(canvasState: $canvasState)
        }

        // DR-0006: Apply external scroll position changes (e.g., after restore)
        let currentOffset = scrollView.contentView.bounds.origin
        if distance(currentOffset, canvasState.scrollOffset) > 0.5 {
            scrollView.contentView.scroll(to: NSPoint(
                x: canvasState.scrollOffset.x,
                y: canvasState.scrollOffset.y
            ))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(canvasState: $canvasState)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx*dx + dy*dy)
    }

    class Coordinator: NSObject {
        @Binding var canvasState: DrawingCanvasModel
        weak var canvasView: NSHostingView<DrawingCanvasViewMacOS>?

        init(canvasState: Binding<DrawingCanvasModel>) {
            self._canvasState = canvasState
        }

        @objc func scrollViewDidScroll(_ notification: Notification) {
            guard let clipView = notification.object as? NSClipView else { return }
            let newOffset = clipView.bounds.origin

            // Only update if significantly different to avoid feedback loops
            if distance(canvasState.scrollOffset, CGPoint(x: newOffset.x, y: newOffset.y)) > 0.5 {
                DispatchQueue.main.async {
                    self.canvasState.scrollOffset = CGPoint(x: newOffset.x, y: newOffset.y)
                }
            }
        }

        private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            let dx = a.x - b.x
            let dy = a.y - b.y
            return sqrt(dx*dx + dy*dy)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
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

// MARK: - Procedural Terrain View (iOS/iPadOS)

#if canImport(UIKit)
/// SwiftUI wrapper for procedural terrain rendering
private struct ProceduralTerrainView: UIViewRepresentable {
    let fill: LayerFill
    let metadata: TerrainMapMetadata
    let canvasSize: CGSize

    func makeUIView(context: Context) -> ProceduralTerrainUIView {
        let view = ProceduralTerrainUIView()
        view.fill = fill
        view.metadata = metadata
        view.canvasSize = canvasSize
        return view
    }

    func updateUIView(_ uiView: ProceduralTerrainUIView, context: Context) {
        uiView.fill = fill
        uiView.metadata = metadata
        uiView.canvasSize = canvasSize
        uiView.setNeedsDisplay()
    }
}

/// UIView that renders procedural terrain
private class ProceduralTerrainUIView: UIView {
    var fill: LayerFill?
    var metadata: TerrainMapMetadata?
    var canvasSize: CGSize = .zero

    override func draw(_ rect: CGRect) {
        print("[ProceduralTerrainUIView] draw() called - rect: \(rect), canvasSize: \(canvasSize)")

        guard UIGraphicsGetCurrentContext() != nil else {
            print("[ProceduralTerrainUIView] ERROR: No graphics context")
            return
        }

        guard let fill = fill else {
            print("[ProceduralTerrainUIView] ERROR: No fill")
            return
        }

        guard let metadata = metadata else {
            print("[ProceduralTerrainUIView] ERROR: No metadata")
            return
        }

        // DR-0029: Use shared cache that persists across visibility toggles
        let cacheKey = BaseLayerImageCache.cacheKey(
            fillType: fill.fillType.rawValue,
            patternSeed: fill.patternSeed,
            terrainSeed: metadata.terrainSeed,
            width: Int(canvasSize.width),
            height: Int(canvasSize.height)
        )

        if let cachedImage = BaseLayerImageCache.shared.get(cacheKey) {
            // Use cached terrain
            cachedImage.draw(at: .zero)
        } else {
            // Generate and cache terrain
            print("[ProceduralTerrainUIView] Generating terrain (cache miss) - key: \(cacheKey)")

            let renderer = UIGraphicsImageRenderer(size: canvasSize)
            let terrainImage = renderer.image { rendererContext in
                let pattern = TerrainPattern(metadata: metadata, dominantFillType: fill.fillType)
                // DR-0019: Pass map scale (terrain already uses metadata which contains scale)
                pattern.draw(in: rendererContext.cgContext, rect: CGRect(origin: .zero, size: canvasSize), seed: fill.patternSeed, baseColor: fill.effectiveColor, mapScale: metadata.physicalSizeMiles)
            }

            BaseLayerImageCache.shared.set(cacheKey, image: terrainImage)
            terrainImage.draw(at: .zero)
            print("[ProceduralTerrainUIView] Terrain cached - size: \(Int(canvasSize.width))x\(Int(canvasSize.height))")
        }
    }

    override var intrinsicContentSize: CGSize {
        canvasSize
    }
}

// MARK: - Procedural Pattern View (iOS/iPadOS)

/// SwiftUI wrapper for procedural pattern rendering
private struct ProceduralPatternView: UIViewRepresentable {
    let fill: LayerFill
    let canvasSize: CGSize

    func makeUIView(context: Context) -> ProceduralPatternUIView {
        let view = ProceduralPatternUIView()
        view.fill = fill
        view.canvasSize = canvasSize
        return view
    }

    func updateUIView(_ uiView: ProceduralPatternUIView, context: Context) {
        uiView.fill = fill
        uiView.canvasSize = canvasSize
        uiView.setNeedsDisplay()
    }
}

/// UIView that renders procedural patterns
private class ProceduralPatternUIView: UIView {
    var fill: LayerFill?
    var canvasSize: CGSize = .zero

    override func draw(_ rect: CGRect) {
        guard let fill = fill,
              let pattern = ProceduralPatternFactory.pattern(for: fill.fillType) else {
            return
        }

        // DR-0029: Use shared cache that persists across visibility toggles
        let mapScale = fill.terrainMetadata?.physicalSizeMiles ?? 0
        let cacheKey = BaseLayerImageCache.cacheKey(
            fillType: fill.fillType.rawValue,
            patternSeed: fill.patternSeed,
            terrainSeed: nil,  // Patterns don't use terrain seed
            width: Int(canvasSize.width),
            height: Int(canvasSize.height)
        )

        // Check if we can use cached pattern
        if let cachedImage = BaseLayerImageCache.shared.get(cacheKey) {
            // Use cached pattern
            cachedImage.draw(at: .zero)
            return
        }

        // Generate and cache pattern
        print("[ProceduralPatternUIView] Generating pattern (cache miss) - key: \(cacheKey)")

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let patternImage = renderer.image { rendererContext in
            // DR-0019: Pass map scale to pattern for correct physical sizing
            pattern.draw(in: rendererContext.cgContext, rect: CGRect(origin: .zero, size: canvasSize), seed: fill.patternSeed, baseColor: fill.effectiveColor, mapScale: mapScale)
        }

        BaseLayerImageCache.shared.set(cacheKey, image: patternImage)
        patternImage.draw(at: .zero)
        print("[ProceduralPatternUIView] Pattern cached - size: \(Int(canvasSize.width))x\(Int(canvasSize.height))")
    }

    override var intrinsicContentSize: CGSize {
        canvasSize
    }
}
#endif

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

    // DR-0006: Tool palette state
    let isRulerActive: Bool
    let selectedToolType: String // DrawingToolType.rawValue
    let selectedColor: String // Color hex
    let selectedLineWidth: CGFloat

    // DR-0008: Layer manager state
    let layerManagerData: Data? // Encoded LayerManager

    // ER-0001: Map category
    let mapCategory: String? // BaseLayerCategory.rawValue
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

    #if canImport(UIKit)
    /// Convert to UIColor with explicit sRGB color space for PencilKit compatibility
    /// This ensures proper color representation, especially for black color which can invert
    /// to white due to semantic color interpretation on iOS/iPadOS.
    /// See DR-0001 for details on the black color inversion issue.
    func toPencilKitColor() -> UIColor {
        let uiColor = UIColor(self)

        // Get RGBA components
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Create new color explicitly in sRGB color space
        // This prevents semantic color interpretation issues (e.g., .black becoming label color)
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    #endif
}
