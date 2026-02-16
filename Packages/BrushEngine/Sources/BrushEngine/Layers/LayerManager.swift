//
//  LayerManager.swift
//  BrushEngine
//
//  Layer stack management and operations for multi-layer drawing
//

import SwiftUI
import Foundation

#if canImport(PencilKit)
import PencilKit
#endif

// MARK: - Layer Manager

/// Manages a stack of drawing layers with operations for creation, deletion, reordering, and compositing
@Observable
public class LayerManager: Codable {
    // MARK: - Layer Stack

    /// All layers in the document, ordered by z-index
    public var layers: [DrawingLayer] = []

    /// ID of the currently active/selected layer
    public var activeLayerID: UUID?

    // MARK: - Persistence Delegate

    /// Assign to receive automatic save notifications when layer state changes.
    /// The delegate is held weakly; it typically points to a SwiftData model object.
    public weak var persistenceDelegate: (any LayerPersistenceDelegate)?

    /// Manually trigger a save to the delegate.
    /// Call this to force a snapshot (e.g., before backgrounding the app).
    public func saveDraftWork() {
        guard let delegate = persistenceDelegate,
              let data = exportLayers() else { return }
        delegate.save(layerData: data)
    }

    /// Load layer state from the delegate, replacing current state.
    /// Does nothing if delegate returns nil or data is malformed.
    public func loadDraftWork() {
        guard let delegate = persistenceDelegate,
              let data = delegate.loadDraftWork() else { return }
        guard let restored = try? LayerManager.importLayers(from: data) else { return }
        self.layers = restored.layers
        self.activeLayerID = restored.activeLayerID
    }

    /// Notify delegate of state change. Called after every mutating operation.
    private func notifyPersistence() {
        guard let delegate = persistenceDelegate,
              let data = exportLayers() else { return }
        delegate.save(layerData: data)
    }

    // MARK: - Computed Properties

    /// The currently active layer for drawing
    public var activeLayer: DrawingLayer? {
        get {
            layers.first { $0.id == activeLayerID }
        }
        set {
            if let newLayer = newValue {
                activeLayerID = newLayer.id
            }
        }
    }

    /// Layers sorted by order (bottom to top)
    public var sortedLayers: [DrawingLayer] {
        layers.sorted { $0.order < $1.order }
    }

    /// Whether the layer stack is empty
    public var isEmpty: Bool {
        layers.isEmpty
    }

    /// Number of layers
    public var layerCount: Int {
        layers.count
    }

    /// Whether all layers are empty
    public var allLayersEmpty: Bool {
        layers.allSatisfy { $0.isEmpty }
    }

    /// The base layer (layer at order 0)
    public var baseLayer: DrawingLayer? {
        layers.first { $0.order == 0 }
    }

    /// ER-0002: The topmost non-base, non-locked content layer
    public var topmostContentLayer: DrawingLayer? {
        sortedLayers
            .filter { $0.order != 0 && !$0.isLocked }
            .last
    }

    /// Inferred map context based on layer types
    public var inferredMapContext: MapContext {
        // Check if we have any interior-specific layers
        let hasInteriorLayers = layers.contains { layer in
            [.walls, .features, .furniture].contains(layer.layerType)
        }
        // Check if we have exterior layers
        let hasExteriorLayers = layers.contains { layer in
            [.terrain, .water, .vegetation, .roads].contains(layer.layerType)
        }

        if hasInteriorLayers { return .dungeon }
        if hasExteriorLayers { return .world }
        return .all
    }

    /// Available fill types based on inferred map context
    public var availableFillTypes: [BaseLayerFillType] {
        let context = inferredMapContext
        switch context {
        case .world:
            return BaseLayerFillType.allCases.filter { $0.category == .exterior }
        case .dungeon, .building:
            return BaseLayerFillType.allCases.filter { $0.category == .interior }
        case .all, .battle:
            return BaseLayerFillType.allCases
        }
    }

    // MARK: - Initialization

    public init() {
        // Start with a default layer
        let defaultLayer = DrawingLayer(name: "Layer 1", order: 0, layerType: .generic)
        layers = [defaultLayer]
        activeLayerID = defaultLayer.id
    }

    /// Initialize with specific layers
    public init(layers: [DrawingLayer]) {
        self.layers = layers
        if let firstLayer = layers.first {
            self.activeLayerID = firstLayer.id
        }
    }

    // MARK: - Layer Creation

    /// Create a new layer with default settings
    @discardableResult
    public func createLayer(name: String? = nil, type: LayerType = .generic) -> DrawingLayer {
        let nextOrder = (layers.map { $0.order }.max() ?? -1) + 1
        let layerNumber = layers.count + 1
        let layerName = name ?? "Layer \(layerNumber)"

        let newLayer = DrawingLayer(
            name: layerName,
            order: nextOrder,
            layerType: type
        )

        layers.append(newLayer)
        activeLayerID = newLayer.id
        notifyPersistence()

        return newLayer
    }

    /// Create a new layer above the current active layer
    @discardableResult
    public func createLayerAboveActive(name: String? = nil, type: LayerType = .generic) -> DrawingLayer {
        guard let activeLayer = activeLayer else {
            return createLayer(name: name, type: type)
        }

        let layerNumber = layers.count + 1
        let layerName = name ?? "Layer \(layerNumber)"

        // Insert with order between active and next layer
        let nextOrder = activeLayer.order + 1

        // Shift up all layers above
        for layer in layers where layer.order >= nextOrder {
            layer.order += 1
        }

        let newLayer = DrawingLayer(
            name: layerName,
            order: nextOrder,
            layerType: type
        )

        layers.append(newLayer)
        activeLayerID = newLayer.id
        notifyPersistence()

        return newLayer
    }

    // MARK: - Layer Deletion

    /// Delete a layer by ID
    public func deleteLayer(id: UUID) {
        guard let index = layers.firstIndex(where: { $0.id == id }) else { return }

        let deletedOrder = layers[index].order
        layers.remove(at: index)

        // Renumber layers after the deleted one
        for layer in layers where layer.order > deletedOrder {
            layer.order -= 1
        }

        // If we deleted the active layer, select another
        if activeLayerID == id {
            if let newActive = layers.first {
                activeLayerID = newActive.id
            } else {
                // Create a new layer if we deleted the last one
                createLayer()
            }
        }
        notifyPersistence()
    }

    /// Delete multiple layers
    public func deleteLayers(ids: [UUID]) {
        for id in ids {
            deleteLayer(id: id)
        }
        notifyPersistence()
    }

    // MARK: - Layer Duplication

    /// Duplicate a layer
    @discardableResult
    public func duplicateLayer(id: UUID) -> DrawingLayer? {
        guard let layer = layers.first(where: { $0.id == id }) else { return nil }

        let nextOrder = (layers.map { $0.order }.max() ?? -1) + 1

        let duplicate = DrawingLayer(
            id: UUID(),
            name: "\(layer.name) Copy",
            order: nextOrder,
            isVisible: layer.isVisible,
            isLocked: false, // Unlock duplicates by default
            opacity: layer.opacity,
            blendMode: layer.blendMode,
            layerType: layer.layerType
        )

        // Copy drawing content
        #if canImport(PencilKit)
        duplicate.drawing = layer.drawing
        #endif
        duplicate.macosStrokes = layer.macosStrokes

        layers.append(duplicate)
        activeLayerID = duplicate.id
        notifyPersistence()

        return duplicate
    }

    // MARK: - Layer Reordering

    /// Move a layer from one position to another
    public func moveLayer(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex >= 0,
              sourceIndex < layers.count,
              destinationIndex >= 0,
              destinationIndex < layers.count else { return }

        let sorted = sortedLayers
        let movedLayer = sorted[sourceIndex]

        // Rebuild order values
        var newOrder = 0
        for (index, layer) in sorted.enumerated() {
            if index == sourceIndex {
                continue // Skip the moved layer
            }

            if index == destinationIndex {
                if sourceIndex < destinationIndex {
                    // Moving down: insert after destination
                    layer.order = newOrder
                    newOrder += 1
                    movedLayer.order = newOrder
                    newOrder += 1
                } else {
                    // Moving up: insert before destination
                    movedLayer.order = newOrder
                    newOrder += 1
                    layer.order = newOrder
                    newOrder += 1
                }
            } else {
                layer.order = newOrder
                newOrder += 1
            }
        }
        notifyPersistence()
    }

    /// Move a layer by ID to a new order position
    public func moveLayer(id: UUID, toOrder newOrder: Int) {
        guard let layer = layers.first(where: { $0.id == id }) else { return }

        let oldOrder = layer.order
        layer.order = newOrder

        // Adjust other layers
        if newOrder > oldOrder {
            // Moving up
            for otherLayer in layers where otherLayer.id != id && otherLayer.order > oldOrder && otherLayer.order <= newOrder {
                otherLayer.order -= 1
            }
        } else if newOrder < oldOrder {
            // Moving down
            for otherLayer in layers where otherLayer.id != id && otherLayer.order >= newOrder && otherLayer.order < oldOrder {
                otherLayer.order += 1
            }
        }
        notifyPersistence()
    }

    /// Bring layer to front (highest order)
    public func bringToFront(id: UUID) {
        guard let layer = layers.first(where: { $0.id == id }) else { return }
        let maxOrder = layers.map { $0.order }.max() ?? 0

        if layer.order != maxOrder {
            moveLayer(id: id, toOrder: maxOrder + 1)
        }
    }

    /// Send layer to back (lowest order)
    public func sendToBack(id: UUID) {
        guard let layer = layers.first(where: { $0.id == id }) else { return }
        let minOrder = layers.map { $0.order }.min() ?? 0

        if layer.order != minOrder {
            moveLayer(id: id, toOrder: minOrder - 1)
        }
    }

    // MARK: - Layer Merging

    /// Merge a layer into another layer (combines their content)
    public func mergeLayer(id: UUID, into targetID: UUID) {
        guard let sourceLayer = layers.first(where: { $0.id == id }),
              let targetLayer = layers.first(where: { $0.id == targetID }),
              id != targetID else { return }

        // Merge content based on platform
        #if canImport(PencilKit)
        // Combine PencilKit drawings
        let sourceStrokes = sourceLayer.drawing.strokes
        targetLayer.drawing.strokes.append(contentsOf: sourceStrokes)
        #endif

        // Combine macOS strokes
        targetLayer.macosStrokes.append(contentsOf: sourceLayer.macosStrokes)

        // Mark target as modified
        targetLayer.markModified()

        // Delete the source layer (deleteLayer calls notifyPersistence)
        deleteLayer(id: id)

        // Make target active
        activeLayerID = targetID
    }

    /// Merge all visible layers into a single layer
    @discardableResult
    public func mergeAllVisible() -> DrawingLayer? {
        let visibleLayers = sortedLayers.filter { $0.isVisible }

        guard visibleLayers.count > 1 else {
            return visibleLayers.first
        }

        // Create a new merged layer
        let mergedLayer = DrawingLayer(
            name: "Merged Layer",
            order: 0,
            layerType: .generic
        )

        // Combine all content
        for layer in visibleLayers {
            #if canImport(PencilKit)
            mergedLayer.drawing.strokes.append(contentsOf: layer.drawing.strokes)
            #endif
            mergedLayer.macosStrokes.append(contentsOf: layer.macosStrokes)
        }

        // Remove old layers
        let idsToRemove = visibleLayers.map { $0.id }
        for id in idsToRemove {
            if let index = layers.firstIndex(where: { $0.id == id }) {
                layers.remove(at: index)
            }
        }

        // Add merged layer
        layers.append(mergedLayer)
        activeLayerID = mergedLayer.id
        notifyPersistence()

        return mergedLayer
    }

    // MARK: - Layer Visibility & Locking

    /// Toggle layer visibility
    public func toggleVisibility(id: UUID) {
        guard let layer = layers.first(where: { $0.id == id }) else { return }
        layer.isVisible.toggle()
        // DR-0025: Trigger observation update by reassigning array
        layers = layers
        notifyPersistence()
    }

    /// Set layer visibility
    public func setVisibility(id: UUID, isVisible: Bool) {
        guard let layer = layers.first(where: { $0.id == id }) else { return }
        layer.isVisible = isVisible
        // DR-0025: Trigger observation update by reassigning array
        layers = layers
        notifyPersistence()
    }

    /// Toggle layer lock status
    public func toggleLock(id: UUID) {
        guard let layer = layers.first(where: { $0.id == id }) else { return }
        layer.isLocked.toggle()
        // DR-0025: Trigger observation update by reassigning array
        layers = layers
        notifyPersistence()
    }

    /// Set layer lock status
    public func setLock(id: UUID, isLocked: Bool) {
        guard let layer = layers.first(where: { $0.id == id }) else { return }
        layer.isLocked = isLocked
        // DR-0025: Trigger observation update by reassigning array
        layers = layers
        notifyPersistence()
    }

    /// Set layer opacity
    public func setOpacity(id: UUID, opacity: CGFloat) {
        guard let layer = layers.first(where: { $0.id == id }) else { return }
        layer.opacity = max(0, min(1, opacity)) // Clamp to 0-1
        layer.markModified()
        // DR-0025: Trigger observation update by reassigning array
        layers = layers
        notifyPersistence()
    }

    /// Set layer blend mode
    public func setBlendMode(id: UUID, blendMode: LayerBlendMode) {
        guard let layer = layers.first(where: { $0.id == id }) else { return }
        layer.blendMode = blendMode
        layer.markModified()
        // DR-0025: Trigger observation update by reassigning array
        layers = layers
        notifyPersistence()
    }

    // MARK: - Layer Naming

    /// Rename a layer
    public func renameLayer(id: UUID, newName: String) {
        guard let layer = layers.first(where: { $0.id == id }) else { return }
        layer.name = newName
        layer.markModified()
        // DR-0025: Trigger observation update by reassigning array
        layers = layers
        notifyPersistence()
    }

    /// Set layer type
    public func setLayerType(id: UUID, type: LayerType) {
        guard let layer = layers.first(where: { $0.id == id }) else { return }
        layer.layerType = type
        layer.markModified()
        // DR-0025: Trigger observation update by reassigning array
        layers = layers
        notifyPersistence()
    }

    // MARK: - Base Layer Fill

    /// Apply a fill to the base layer (creates base layer if needed)
    public func applyFillToBaseLayer(_ fill: LayerFill?) {
        if let base = baseLayer {
            base.applyFill(fill)
        } else {
            // Create base layer if it doesn't exist
            let base = DrawingLayer(name: "Base Layer", order: 0, layerType: .terrain)
            layers.append(base)
            base.applyFill(fill)
            // Make it the active layer
            activeLayerID = base.id
        }
        notifyPersistence()
    }

    /// Get the current fill on the base layer
    public var baseLayerFill: LayerFill? {
        baseLayer?.layerFill
    }

    // MARK: - Layer Selection

    /// Select/activate a layer
    public func selectLayer(id: UUID) {
        guard layers.contains(where: { $0.id == id }) else { return }
        activeLayerID = id
    }

    /// Get layer by ID
    public func getLayer(id: UUID) -> DrawingLayer? {
        layers.first { $0.id == id }
    }

    // MARK: - Bulk Operations

    /// Show all layers
    public func showAllLayers() {
        for layer in layers {
            layer.isVisible = true
        }
        // DR-0025: Trigger observation update by reassigning array
        layers = layers
        notifyPersistence()
    }

    /// Hide all layers except the specified one
    public func hideAllExcept(id: UUID) {
        for layer in layers {
            layer.isVisible = (layer.id == id)
        }
        // DR-0025: Trigger observation update by reassigning array
        layers = layers
        notifyPersistence()
    }

    /// Lock all layers except the specified one
    public func lockAllExcept(id: UUID) {
        for layer in layers {
            layer.isLocked = (layer.id != id)
        }
        // DR-0025: Trigger observation update by reassigning array
        layers = layers
        notifyPersistence()
    }

    /// Unlock all layers
    public func unlockAllLayers() {
        for layer in layers {
            layer.isLocked = false
        }
        // DR-0025: Trigger observation update by reassigning array
        layers = layers
        notifyPersistence()
    }

    // MARK: - Export

    /// Export a composited image of all visible layers
    public func exportComposite(canvasSize: CGSize, backgroundColor: Color = .white) -> Data? {
        let visibleLayers = sortedLayers.filter { $0.isVisible }

        guard !visibleLayers.isEmpty else { return nil }

        #if canImport(UIKit)
        UIGraphicsBeginImageContextWithOptions(canvasSize, true, 2.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Draw background
        context.setFillColor(UIColor(backgroundColor).cgColor)
        context.fill(CGRect(origin: .zero, size: canvasSize))

        // Draw each visible layer
        for layer in visibleLayers {
            context.saveGState()
            context.setAlpha(layer.opacity)
            context.setBlendMode(layer.blendMode.cgBlendMode)

            #if canImport(PencilKit)
            let image = layer.drawing.image(from: CGRect(origin: .zero, size: canvasSize), scale: 2.0)
            image.draw(at: .zero)
            #endif

            // Draw macOS strokes if any
            drawStrokes(layer.macosStrokes, in: context)

            context.restoreGState()
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image?.pngData()

        #elseif os(macOS)
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(canvasSize.width),
            pixelsHigh: Int(canvasSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: Int(canvasSize.width) * 4,
            bitsPerPixel: 32
        )

        guard let rep = rep else { return nil }

        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = context

        guard let cgContext = context?.cgContext else {
            NSGraphicsContext.restoreGraphicsState()
            return nil
        }

        // Draw background
        cgContext.setFillColor(NSColor(backgroundColor).cgColor)
        cgContext.fill(CGRect(origin: .zero, size: canvasSize))

        // Draw each visible layer
        for layer in visibleLayers {
            cgContext.saveGState()
            cgContext.setAlpha(layer.opacity)
            cgContext.setBlendMode(layer.blendMode.cgBlendMode)

            #if canImport(PencilKit)
            let image = layer.drawing.image(from: CGRect(origin: .zero, size: canvasSize), scale: 2.0)
            if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                cgContext.draw(cgImage, in: CGRect(origin: .zero, size: canvasSize))
            }
            #endif

            // Draw macOS strokes
            drawStrokes(layer.macosStrokes, in: cgContext)

            cgContext.restoreGState()
        }

        NSGraphicsContext.restoreGraphicsState()

        return rep.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }

    /// Export a single layer as image data
    public func exportLayer(id: UUID, canvasSize: CGSize, includeBackground: Bool = false, backgroundColor: Color = .white) -> Data? {
        guard let layer = layers.first(where: { $0.id == id }) else { return nil }

        #if canImport(UIKit)
        UIGraphicsBeginImageContextWithOptions(canvasSize, includeBackground, 2.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        if includeBackground {
            context.setFillColor(UIColor(backgroundColor).cgColor)
            context.fill(CGRect(origin: .zero, size: canvasSize))
        }

        context.setAlpha(layer.opacity)
        context.setBlendMode(layer.blendMode.cgBlendMode)

        #if canImport(PencilKit)
        let drawingImage = layer.drawing.image(from: CGRect(origin: .zero, size: canvasSize), scale: 2.0)
        drawingImage.draw(at: .zero)
        #endif

        drawStrokes(layer.macosStrokes, in: context)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image?.pngData()

        #elseif os(macOS)
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(canvasSize.width),
            pixelsHigh: Int(canvasSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: Int(canvasSize.width) * 4,
            bitsPerPixel: 32
        )

        guard let rep = rep else { return nil }

        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = context

        guard let cgContext = context?.cgContext else {
            NSGraphicsContext.restoreGraphicsState()
            return nil
        }

        if includeBackground {
            cgContext.setFillColor(NSColor(backgroundColor).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: canvasSize))
        }

        cgContext.setAlpha(layer.opacity)
        cgContext.setBlendMode(layer.blendMode.cgBlendMode)

        #if canImport(PencilKit)
        let image = layer.drawing.image(from: CGRect(origin: .zero, size: canvasSize), scale: 2.0)
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            cgContext.draw(cgImage, in: CGRect(origin: .zero, size: canvasSize))
        }
        #endif

        drawStrokes(layer.macosStrokes, in: cgContext)

        NSGraphicsContext.restoreGraphicsState()

        return rep.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }

    /// Export layer data (for re-importing layers)
    public func exportLayers() -> Data? {
        try? JSONEncoder().encode(self)
    }

    /// Import layers from exported data
    public static func importLayers(from data: Data) throws -> LayerManager {
        try JSONDecoder().decode(LayerManager.self, from: data)
    }

    // MARK: - Helper Methods

    /// ER-0002: Get target layer for stroke saving (creates content layer if needed)
    /// Base layer (order == 0) should never receive strokes
    public func getTargetLayerForStrokes() -> DrawingLayer {
        // If active layer is not the base layer and not locked, use it
        if let active = activeLayer,
           active.order != 0,
           !active.isLocked {
            return active
        }

        // Otherwise, find topmost content layer
        if let topmost = topmostContentLayer {
            // Switch to this layer as active
            activeLayerID = topmost.id
            return topmost
        }

        // No valid content layers exist - create one
        let newLayer = createLayerAboveActive(name: "Layer 1", type: .generic)
        return newLayer
    }

    #if canImport(CoreGraphics)
    /// Draw strokes in a Core Graphics context
    private func drawStrokes(_ strokes: [DrawingStroke], in context: CGContext) {
        for stroke in strokes {
            #if os(macOS)
            context.setStrokeColor(stroke.color.cgColor)
            #elseif canImport(UIKit)
            let color = UIColor(
                red: stroke.colorRed,
                green: stroke.colorGreen,
                blue: stroke.colorBlue,
                alpha: stroke.colorAlpha
            )
            context.setStrokeColor(color.cgColor)
            #endif

            context.setLineWidth(stroke.lineWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)

            let points = stroke.points.map { CGPoint(x: $0.x, y: $0.y) }

            guard points.count > 1 else { continue }

            context.beginPath()
            context.move(to: points[0])

            for point in points.dropFirst() {
                context.addLine(to: point)
            }

            context.strokePath()
        }
    }
    #endif

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case layers
        case activeLayerID
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        layers = try container.decode([DrawingLayer].self, forKey: .layers)
        activeLayerID = try? container.decode(UUID.self, forKey: .activeLayerID)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(layers, forKey: .layers)
        try container.encode(activeLayerID, forKey: .activeLayerID)
    }
}

// MARK: - Layer Manager Extension for Previews

extension LayerManager {
    /// Create a sample layer manager for previews
    public static func sample() -> LayerManager {
        let manager = LayerManager()
        manager.createLayer(name: "Terrain", type: .terrain)
        manager.createLayer(name: "Water", type: .water)
        manager.createLayer(name: "Roads", type: .roads)
        return manager
    }
}
