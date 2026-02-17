//
//  CanvasGestureTarget.swift
//  BoardEngine
//
//  Canvas-level gesture target for pan, pinch, and background tap.
//  Generic over BoardConfiguration for zoom/pan limits.
//

import SwiftUI

// MARK: - Canvas Gesture Target

/// Canvas-level gesture target for pan, pinch, and background tap.
@MainActor
public final class CanvasGestureTarget: GestureTarget {
    public let gestureID = UUID()

    /// Configuration providing zoom/pan limits.
    public var configuration: BoardConfiguration

    // Callbacks to the view
    public var onTransformChanged: ((Double, Double, Double) -> Void)?
    public var onTransformCommit: (() -> Void)?
    public var onSelectionChanged: ((UUID?) -> Void)?

    // Transform state access
    public var getCurrentTransform: (() -> (scale: Double, panX: Double, panY: Double))?
    public var getWindowSize: (() -> CGSize)?
    public var getCanvasRect: (() -> CGRect)?

    public init(configuration: BoardConfiguration = .cumberland) {
        self.configuration = configuration
    }

    public var worldBounds: CGRect {
        getCanvasRect?() ?? CGRect(x: -10000, y: -10000, width: 20000, height: 20000)
    }

    public func canHandleGesture(_ gesture: GestureType) -> Bool {
        switch gesture {
        case .tap, .pinch, .twoFingerPan:
            return true
        case .drag, .doubleTap, .rightClick:
            return false
        }
    }

    public func handleGesture(_ gesture: GestureEvent) {
        switch gesture {
        case .tap(_, _):
            onSelectionChanged?(nil)

        case .pinchBegan(_, _, _, _):
            break

        case .pinchChanged(let scale, _, let center, let coordinateInfo):
            if let transform = getCurrentTransform?() {
                let centerWorld = coordinateInfo.toWorldSpace(center)
                let newScale = (transform.scale * scale).clamped(to: configuration.minZoom...configuration.maxZoom)
                let newPanX = center.x - centerWorld.x * newScale
                let newPanY = center.y - centerWorld.y * newScale
                onTransformChanged?(newScale, newPanX, newPanY)
            }

        case .pinchEnded(_, _, _, _):
            onTransformCommit?()

        case .twoFingerPanBegan(_, _):
            break

        case .twoFingerPanChanged(let translation, _, _):
            if let transform = getCurrentTransform?() {
                let newPanX = (transform.panX + translation.width).clamped(to: configuration.minPan...configuration.maxPan)
                let newPanY = (transform.panY + translation.height).clamped(to: configuration.minPan...configuration.maxPan)
                onTransformChanged?(transform.scale, newPanX, newPanY)
            }

        case .twoFingerPanEnded(_, _, _, _):
            onTransformCommit?()

        default:
            break
        }
    }
}
