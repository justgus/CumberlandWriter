//
//  NodeGestureTarget.swift
//  BoardEngine
//
//  Node-level gesture target for drag, selection, and right-click.
//  Already callback-based and clean — works with any data source.
//

import SwiftUI

// MARK: - Node Gesture Target

/// Node-level gesture target for drag and selection.
@MainActor
public final class NodeGestureTarget: GestureTarget {
    public let gestureID = UUID()
    public let nodeID: UUID
    public let isPrimary: Bool
    private var dragStartWorldPosition: CGPoint = .zero
    private var dragGrabOffset: CGPoint = .zero

    // Callbacks to the view
    public var onSelectionChanged: ((UUID?) -> Void)?
    public var onNodeMoved: ((UUID, CGPoint) -> Void)?
    public var onNodeMoveCommit: ((UUID) -> Void)?
    public var onRightClick: ((UUID, CGPoint) -> Void)?

    // Position and size access
    public var getNodeWorldBounds: ((UUID) -> CGRect)?

    public init(nodeID: UUID, isPrimary: Bool = false) {
        self.nodeID = nodeID
        self.isPrimary = isPrimary
    }

    public var worldBounds: CGRect {
        getNodeWorldBounds?(nodeID) ?? CGRect.zero
    }

    public func canHandleGesture(_ gesture: GestureType) -> Bool {
        switch gesture {
        case .tap, .drag, .rightClick, .doubleTap:
            return true
        case .pinch, .twoFingerPan:
            return false
        }
    }

    public func handleGesture(_ gesture: GestureEvent) {
        switch gesture {
        case .tap(_, _):
            onSelectionChanged?(nodeID)

        case .dragBegan(let startLocation, let coordinateInfo):
            onSelectionChanged?(nodeID)
            let worldStart = coordinateInfo.toWorldSpace(startLocation)
            let nodeCenter = CGPoint(x: worldBounds.midX, y: worldBounds.midY)
            dragStartWorldPosition = nodeCenter
            dragGrabOffset = CGPoint(x: worldStart.x - nodeCenter.x, y: worldStart.y - nodeCenter.y)

        case .dragChanged(let location, _, let coordinateInfo):
            let worldPointer = coordinateInfo.toWorldSpace(location)
            let newNodeCenter = CGPoint(
                x: worldPointer.x - dragGrabOffset.x,
                y: worldPointer.y - dragGrabOffset.y
            )
            onNodeMoved?(nodeID, newNodeCenter)

        case .dragEnded(let location, _, _, let coordinateInfo):
            let worldPointer = coordinateInfo.toWorldSpace(location)
            let newNodeCenter = CGPoint(
                x: worldPointer.x - dragGrabOffset.x,
                y: worldPointer.y - dragGrabOffset.y
            )
            onNodeMoved?(nodeID, newNodeCenter)
            onNodeMoveCommit?(nodeID)

        case .rightClick(let location, _):
            #if DEBUG
            print("NodeGestureTarget: rightClick gestureID=\(gestureID), nodeID=\(nodeID), isPrimary=\(isPrimary)")
            #endif
            onSelectionChanged?(nodeID)
            onRightClick?(nodeID, location)

        default:
            break
        }
    }
}
