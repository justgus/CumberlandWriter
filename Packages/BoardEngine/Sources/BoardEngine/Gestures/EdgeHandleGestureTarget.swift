//
//  EdgeHandleGestureTarget.swift
//  BoardEngine
//
//  Gesture target for edge creation handles. Responds to drag gestures
//  to initiate and complete edge creation between nodes.
//

import SwiftUI

// MARK: - Edge Handle Gesture Target

/// Gesture target for edge creation handles.
@MainActor
public final class EdgeHandleGestureTarget: GestureTarget {
    public let gestureID = UUID()
    public let nodeID: UUID

    /// Edge creation state reference.
    public var edgeCreationState: BoardEdgeCreationState?

    /// Called when a valid edge drag completes (source, target).
    public var onEdgeCreated: ((UUID, UUID) -> Void)?

    /// Returns bounds in WORLD coordinates for the handle.
    public var getHandleWorldBounds: ((UUID) -> CGRect)?

    /// Hit test all nodes to find which one we're hovering over (takes VIEW coordinates).
    public var hitTestNodes: ((CGPoint) -> UUID?)?

    public init(nodeID: UUID) {
        self.nodeID = nodeID
    }

    public var worldBounds: CGRect {
        getHandleWorldBounds?(nodeID) ?? CGRect.zero
    }

    public func canHandleGesture(_ gesture: GestureType) -> Bool {
        switch gesture {
        case .drag:
            return true
        case .tap, .doubleTap, .rightClick, .pinch, .twoFingerPan:
            return false
        }
    }

    public func handleGesture(_ gesture: GestureEvent) {
        guard let state = edgeCreationState else { return }

        switch gesture {
        case .dragBegan(let startLocation, _):
            state.startDrag(from: nodeID, at: startLocation)
            #if DEBUG
            print("[EdgeHandle] Drag began from node \(nodeID) at \(startLocation)")
            #endif

        case .dragChanged(let location, _, _):
            state.updateDrag(to: location)
            if let targetID = hitTestNodes?(location), targetID != nodeID {
                state.setHoveredTarget(targetID)
            } else {
                state.setHoveredTarget(nil)
            }

        case .dragEnded(let location, _, _, _):
            if let targetID = hitTestNodes?(location), targetID != nodeID {
                state.setHoveredTarget(targetID)
            }

            if let targetID = state.endDrag() {
                #if DEBUG
                print("[EdgeHandle] Drag ended on target \(targetID)")
                #endif
                onEdgeCreated?(nodeID, targetID)
            } else {
                #if DEBUG
                print("[EdgeHandle] Drag ended with no valid target")
                #endif
            }

        default:
            break
        }
    }
}
