//
//  LayerManagerTests.swift
//  BrushEngineTests
//
//  ER-0052 Phase 1.1: Comprehensive tests for LayerManager operations
//

import Testing
import Foundation
import CoreGraphics
import SwiftUI
@testable import BrushEngine

@Suite("Layer Manager Operations")
struct LayerManagerTests {

    // MARK: - Initialization Tests

    @Test("Initialize LayerManager with default layer")
    func initializeLayerManager() {
        let manager = LayerManager()

        #expect(manager.layers.count == 1)
        #expect(manager.activeLayerID != nil)
        #expect(manager.isEmpty == false)
        #expect(manager.layerCount == 1)
    }

    @Test("Initialize LayerManager with custom layers")
    func initializeWithCustomLayers() {
        let layer1 = DrawingLayer(name: "Test Layer 1", order: 0, layerType: .terrain)
        let layer2 = DrawingLayer(name: "Test Layer 2", order: 1, layerType: .water)

        let manager = LayerManager(layers: [layer1, layer2])

        #expect(manager.layers.count == 2)
        #expect(manager.activeLayerID == layer1.id)
    }

    // MARK: - Layer Creation Tests

    @Test("Create new layer with default settings")
    func createLayer() {
        let manager = LayerManager()
        let initialCount = manager.layers.count

        let newLayer = manager.createLayer(name: "New Layer", type: .generic)

        #expect(manager.layers.count == initialCount + 1)
        #expect(newLayer.name == "New Layer")
        #expect(newLayer.layerType == .generic)
        #expect(manager.activeLayerID == newLayer.id)
    }

    @Test("Create layer above active layer")
    func createLayerAboveActive() {
        let manager = LayerManager()
        let firstLayer = manager.layers.first!

        let newLayer = manager.createLayerAboveActive(name: "Above Layer", type: .water)

        #expect(newLayer.order == firstLayer.order + 1)
        #expect(manager.activeLayerID == newLayer.id)
    }

    // MARK: - Layer Deletion Tests

    @Test("Delete layer by ID")
    func deleteLayer() {
        let manager = LayerManager()
        let layer1 = manager.createLayer(name: "Layer 1", type: .terrain)
        let layer2 = manager.createLayer(name: "Layer 2", type: .water)

        let initialCount = manager.layers.count

        manager.deleteLayer(id: layer1.id)

        #expect(manager.layers.count == initialCount - 1)
        #expect(manager.getLayer(id: layer1.id) == nil)
        #expect(manager.getLayer(id: layer2.id) != nil)
    }

    @Test("Delete active layer selects another")
    func deleteActiveLayerSelectsAnother() {
        let manager = LayerManager()
        let layer1 = manager.layers.first!
        manager.createLayer(name: "Layer 2", type: .water)

        manager.selectLayer(id: layer1.id)
        #expect(manager.activeLayerID == layer1.id)

        manager.deleteLayer(id: layer1.id)

        // Should auto-select another layer
        #expect(manager.activeLayerID != nil)
        #expect(manager.activeLayerID != layer1.id)
    }

    @Test("Delete last layer creates new one")
    func deleteLastLayerCreatesNew() {
        let manager = LayerManager()
        let onlyLayer = manager.layers.first!

        manager.deleteLayer(id: onlyLayer.id)

        // Should auto-create a new layer
        #expect(manager.layers.count == 1)
        #expect(manager.activeLayerID != nil)
    }

    // MARK: - Layer Duplication Tests

    @Test("Duplicate layer copies content and properties")
    func duplicateLayer() {
        let manager = LayerManager()
        let originalLayer = manager.layers.first!
        originalLayer.name = "Original"
        originalLayer.opacity = 0.75
        originalLayer.isVisible = true

        let duplicate = manager.duplicateLayer(id: originalLayer.id)

        #expect(duplicate != nil)
        #expect(duplicate?.name == "Original Copy")
        #expect(duplicate?.opacity == 0.75)
        #expect(duplicate?.isVisible == true)
        #expect(duplicate?.isLocked == false) // Duplicates are unlocked by default
        #expect(manager.activeLayerID == duplicate?.id)
    }

    // MARK: - Layer Visibility & Lock Tests

    @Test("Toggle layer visibility")
    func toggleVisibility() {
        let manager = LayerManager()
        let layer = manager.layers.first!
        let initialVisibility = layer.isVisible

        manager.toggleVisibility(id: layer.id)

        #expect(layer.isVisible == !initialVisibility)
    }

    @Test("Set layer lock status")
    func setLockStatus() {
        let manager = LayerManager()
        let layer = manager.layers.first!

        manager.setLock(id: layer.id, isLocked: true)
        #expect(layer.isLocked == true)

        manager.setLock(id: layer.id, isLocked: false)
        #expect(layer.isLocked == false)
    }

    @Test("Set layer opacity clamped to valid range")
    func setOpacityClamped() {
        let manager = LayerManager()
        let layer = manager.layers.first!

        // Test upper bound clamping
        manager.setOpacity(id: layer.id, opacity: 1.5)
        #expect(layer.opacity <= 1.0)

        // Test lower bound clamping
        manager.setOpacity(id: layer.id, opacity: -0.5)
        #expect(layer.opacity >= 0.0)

        // Test valid value
        manager.setOpacity(id: layer.id, opacity: 0.75)
        #expect(layer.opacity == 0.75)
    }

    // MARK: - Layer Ordering Tests

    @Test("Move layer changes order correctly")
    func moveLayerChangesOrder() {
        let manager = LayerManager()
        let layer1 = manager.createLayer(name: "Layer 1", type: .terrain)
        let layer2 = manager.createLayer(name: "Layer 2", type: .water)
        let layer3 = manager.createLayer(name: "Layer 3", type: .roads)

        // Initial order: layer1 (0), layer2 (1), layer3 (2)
        #expect(layer1.order < layer2.order)
        #expect(layer2.order < layer3.order)

        // Move layer1 to the top
        manager.bringToFront(id: layer1.id)

        #expect(layer1.order > layer2.order)
        #expect(layer1.order > layer3.order)
    }

    @Test("Send layer to back")
    func sendLayerToBack() {
        let manager = LayerManager()
        let layer1 = manager.createLayer(name: "Layer 1", type: .terrain)
        let layer2 = manager.createLayer(name: "Layer 2", type: .water)

        let initialOrder1 = layer1.order
        let initialOrder2 = layer2.order

        #expect(initialOrder2 > initialOrder1)

        manager.sendToBack(id: layer2.id)

        #expect(layer2.order < layer1.order)
    }

    // MARK: - Computed Properties Tests

    @Test("Base layer returns order 0 layer")
    func baseLayerReturnsOrderZero() {
        let manager = LayerManager()
        let firstLayer = manager.layers.first!
        firstLayer.order = 0

        let baseLayer = manager.baseLayer

        #expect(baseLayer != nil)
        #expect(baseLayer?.order == 0)
    }

    @Test("Sorted layers returns correct order")
    func sortedLayersCorrectOrder() {
        // Create manager with no default layer
        let layer1 = DrawingLayer(name: "Layer 1", order: 5, layerType: .terrain)
        let layer2 = DrawingLayer(name: "Layer 2", order: 1, layerType: .water)
        let layer3 = DrawingLayer(name: "Layer 3", order: 3, layerType: .roads)

        let manager = LayerManager(layers: [layer1, layer2, layer3])

        let sorted = manager.sortedLayers

        #expect(sorted.count == 3)
        #expect(sorted[0].order == 1)  // layer2
        #expect(sorted[1].order == 3)  // layer3
        #expect(sorted[2].order == 5)  // layer1
        #expect(sorted[0].name == "Layer 2")
        #expect(sorted[1].name == "Layer 3")
        #expect(sorted[2].name == "Layer 1")
    }
}
