import Testing
import Foundation
import CoreGraphics
@testable import BoardEngine

@Suite("BoardEngine Tests")
struct BoardEngineTests {

    // MARK: - Transform Tests

    @Test("BoardCanvasTransform round-trip")
    func transformRoundTrip() {
        let world = CGPoint(x: 100, y: 200)
        let scale = 1.5
        let panX = 50.0
        let panY = -30.0

        let view = BoardCanvasTransform.worldToView(world, scale: scale, panX: panX, panY: panY)
        let back = BoardCanvasTransform.viewToWorld(view, scale: scale, panX: panX, panY: panY)

        #expect(abs(back.x - world.x) < 0.001)
        #expect(abs(back.y - world.y) < 0.001)
    }

    @Test("BoardCanvasTransform worldToView formula")
    func transformFormula() {
        // v = w*S + T
        let world = CGPoint(x: 10, y: 20)
        let scale = 2.0
        let panX = 100.0
        let panY = 50.0

        let view = BoardCanvasTransform.worldToView(world, scale: scale, panX: panX, panY: panY)
        #expect(view.x == 10 * 2.0 + 100.0) // 120
        #expect(view.y == 20 * 2.0 + 50.0)  // 90
    }

    @Test("BoardCanvasTransform viewToWorld inverse")
    func transformInverse() {
        // w = (v - T) / S
        let view = CGPoint(x: 120, y: 90)
        let scale = 2.0
        let panX = 100.0
        let panY = 50.0

        let world = BoardCanvasTransform.viewToWorld(view, scale: scale, panX: panX, panY: panY)
        #expect(abs(world.x - 10) < 0.001)
        #expect(abs(world.y - 20) < 0.001)
    }

    @Test("BoardCanvasTransform viewCanvasRect")
    func viewCanvasRect() {
        let size = CGSize(width: 800, height: 600)
        let rect = BoardCanvasTransform.viewCanvasRect(
            worldForWindowSize: size,
            scale: 1.0,
            panX: 0.0,
            panY: 0.0
        )
        // At scale 1.0 and no pan, world rect should match view rect
        #expect(abs(rect.width - 800) < 0.001)
        #expect(abs(rect.height - 600) < 0.001)
    }

    @Test("BoardCanvasTransform worldCenter")
    func worldCenter() {
        let size = CGSize(width: 800, height: 600)
        let center = BoardCanvasTransform.worldCenter(
            forWindowSize: size,
            scale: 1.0,
            panX: 0.0,
            panY: 0.0
        )
        #expect(abs(center.x - 400) < 0.001)
        #expect(abs(center.y - 300) < 0.001)
    }

    // MARK: - Edge Creation State Tests

    @Test("BoardEdgeCreationState lifecycle")
    func edgeCreationStateLifecycle() {
        let state = BoardEdgeCreationState()
        #expect(state.isDragging == false)

        state.startDrag(from: UUID(), at: CGPoint(x: 10, y: 20))
        #expect(state.isDragging == true)

        let targetID = UUID()
        state.setHoveredTarget(targetID)
        #expect(state.hoveredTargetID == targetID)

        let result = state.endDrag()
        #expect(result == targetID)
        #expect(state.isDragging == false)
    }

    @Test("BoardEdgeCreationState cancel clears state")
    func edgeCreationStateCancel() {
        let state = BoardEdgeCreationState()
        state.startDrag(from: UUID(), at: CGPoint(x: 10, y: 20))
        state.setHoveredTarget(UUID())
        #expect(state.isDragging == true)

        state.cancelDrag()
        #expect(state.isDragging == false)
        #expect(state.hoveredTargetID == nil)
        #expect(state.sourceCardID == nil)
    }

    @Test("BoardEdgeCreationState endDrag without target returns nil")
    func edgeCreationStateNoTarget() {
        let state = BoardEdgeCreationState()
        state.startDrag(from: UUID(), at: CGPoint(x: 10, y: 20))
        let result = state.endDrag()
        #expect(result == nil)
    }

    @Test("BoardEdgeCreationState endDrag returns target when set")
    func edgeCreationStateEndDragWithTarget() {
        let state = BoardEdgeCreationState()
        let sourceID = UUID()
        let targetID = UUID()

        state.startDrag(from: sourceID, at: CGPoint(x: 0, y: 0))
        state.setHoveredTarget(targetID)

        let result = state.endDrag()
        #expect(result == targetID)

        // After endDrag, state should be cleared
        #expect(state.isDragging == false)
        #expect(state.sourceCardID == nil)
        #expect(state.hoveredTargetID == nil)
    }

    // MARK: - Geometry Extension Tests

    @Test("Comparable.clamped")
    func clampedValues() {
        #expect(5.0.clamped(to: 0.0...10.0) == 5.0)
        #expect((-1.0).clamped(to: 0.0...10.0) == 0.0)
        #expect(15.0.clamped(to: 0.0...10.0) == 10.0)
    }

    @Test("CGFloat.dg and Double.cg round-trip")
    func dgCgRoundTrip() {
        let cgValue: CGFloat = 42.5
        let doubleValue = cgValue.dg
        let backToCG = doubleValue.cg

        #expect(doubleValue == 42.5)
        #expect(backToCG == 42.5)
    }

    @Test("CGSize.clamped")
    func sizeClamp() {
        let size = CGSize(width: 500, height: 300)
        let clamped = size.clamped(maxWidth: 400, maxHeight: 200)
        #expect(clamped.width <= 400)
        #expect(clamped.height <= 200)
    }

    @Test("CGSize.scaled")
    func sizeScale() {
        let size = CGSize(width: 100, height: 200)
        let scaled = size.scaled(by: 2.0)
        #expect(scaled.width == 200)
        #expect(scaled.height == 400)
    }

    // MARK: - Configuration Tests

    @Test("BoardConfiguration defaults")
    func configurationDefaults() {
        let config = BoardConfiguration()
        #expect(config.minZoom == 0.01)
        #expect(config.maxZoom == 2.0)
        #expect(config.windowCornerRadius == 18)
    }

    @Test("BoardConfiguration.cumberland preset matches defaults")
    func configurationCumberlandPreset() {
        let preset = BoardConfiguration.cumberland
        let defaults = BoardConfiguration()
        #expect(preset.minZoom == defaults.minZoom)
        #expect(preset.maxZoom == defaults.maxZoom)
        #expect(preset.minPan == defaults.minPan)
        #expect(preset.maxPan == defaults.maxPan)
    }

    @Test("BoardConfiguration custom values via mutation")
    func configurationCustom() {
        var config = BoardConfiguration()
        config.minZoom = 0.5
        config.maxZoom = 5.0
        config.minPan = -500
        config.maxPan = 500
        config.windowCornerRadius = 24
        config.windowBorderWidth = 8

        #expect(config.minZoom == 0.5)
        #expect(config.maxZoom == 5.0)
        #expect(config.minPan == -500)
        #expect(config.maxPan == 500)
        #expect(config.windowCornerRadius == 24)
        #expect(config.windowBorderWidth == 8)
    }

    @Test("BoardPendingEdge identifiable")
    func pendingEdgeIdentifiable() {
        let edge = BoardPendingEdge(sourceNodeID: UUID(), targetNodeID: UUID())
        #expect(edge.id != UUID()) // Should have a unique ID
        #expect(edge.sourceNodeID != edge.targetNodeID || edge.sourceNodeID == edge.targetNodeID)
    }
}
