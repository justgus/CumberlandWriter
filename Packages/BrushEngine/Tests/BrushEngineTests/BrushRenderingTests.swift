//
//  BrushRenderingTests.swift
//  BrushEngineTests
//
//  ER-0052 Phase 1.1: Basic tests for brush rendering and export
//

import Testing
import Foundation
import CoreGraphics
import SwiftUI
@testable import BrushEngine

@Suite("Brush Rendering")
struct BrushRenderingTests {

    // MARK: - Layer Export Tests

    @Test("Export empty layer returns valid data")
    func exportEmptyLayer() {
        let manager = LayerManager()
        let layer = manager.layers.first!

        let imageData = manager.exportLayer(
            id: layer.id,
            canvasSize: CGSize(width: 100, height: 100),
            includeBackground: true,
            backgroundColor: .white
        )

        // Should return data even for empty layer
        #expect(imageData != nil)
    }

    @Test("Export composite with no visible layers returns nil")
    func exportCompositeNoVisibleLayers() {
        let manager = LayerManager()
        let layer = manager.layers.first!

        // Hide the only layer
        manager.setVisibility(id: layer.id, isVisible: false)

        let imageData = manager.exportComposite(
            canvasSize: CGSize(width: 100, height: 100),
            backgroundColor: .white
        )

        // Should return nil when no layers are visible
        #expect(imageData == nil)
    }

    @Test("Export composite with visible layer returns data")
    func exportCompositeWithVisibleLayer() {
        let manager = LayerManager()
        let layer = manager.layers.first!

        let imageData = manager.exportComposite(
            canvasSize: CGSize(width: 100, height: 100),
            backgroundColor: .white
        )

        #expect(imageData != nil)
    }

    @Test("Export layers preserves layer count")
    func exportLayersPreservesCount() {
        let manager = LayerManager()
        manager.createLayer(name: "Layer 2", type: .water)
        manager.createLayer(name: "Layer 3", type: .terrain)

        let exportedData = manager.exportLayers()
        #expect(exportedData != nil)

        // Import and verify count
        if let data = exportedData {
            let importedManager = try? LayerManager.importLayers(from: data)
            #expect(importedManager?.layers.count == manager.layers.count)
        }
    }

    @Test("Import/export roundtrip preserves active layer")
    func importExportRoundtripPreservesActiveLayer() throws {
        let manager = LayerManager()
        let layer2 = manager.createLayer(name: "Layer 2", type: .water)
        manager.selectLayer(id: layer2.id)

        let activeIDBefore = manager.activeLayerID

        let exportedData = manager.exportLayers()
        #expect(exportedData != nil)

        if let data = exportedData {
            let importedManager = try LayerManager.importLayers(from: data)
            #expect(importedManager.activeLayerID == activeIDBefore)
        }
    }
}
