//
//  BoardEdgeCreationState.swift
//  BoardEngine
//
//  Observable state machine for interactive edge creation on the board canvas.
//  Tracks a pending edge (source node + live cursor position) and the hovered
//  target node during a drag operation.
//

import SwiftUI
import Observation

// MARK: - Pending Edge Creation

/// Identifiable struct for sheet(item:) presentation.
/// Ensures data is available when the edge creation sheet renders.
public struct BoardPendingEdge: Identifiable, Sendable {
    public let id = UUID()
    public let sourceNodeID: UUID
    public let targetNodeID: UUID

    public init(sourceNodeID: UUID, targetNodeID: UUID) {
        self.sourceNodeID = sourceNodeID
        self.targetNodeID = targetNodeID
    }
}

// MARK: - Edge Creation State

/// Observable state for an edge creation drag operation on the board canvas.
@Observable
public final class BoardEdgeCreationState {
    /// The node ID that is the source of the edge being created.
    public var sourceCardID: UUID?

    /// Current drag position in view coordinates.
    public var currentDragPosition: CGPoint?

    /// The node ID currently being hovered over as a potential target.
    public var hoveredTargetID: UUID?

    /// Whether an edge creation drag is currently active.
    public var isDragging: Bool {
        sourceCardID != nil && currentDragPosition != nil
    }

    public init() {}

    /// Start a new edge creation drag.
    public func startDrag(from nodeID: UUID, at position: CGPoint) {
        sourceCardID = nodeID
        currentDragPosition = position
        hoveredTargetID = nil
    }

    /// Update the current drag position.
    public func updateDrag(to position: CGPoint) {
        currentDragPosition = position
    }

    /// Set the hovered target.
    public func setHoveredTarget(_ nodeID: UUID?) {
        hoveredTargetID = nodeID
    }

    /// End the drag and return the target if valid.
    @discardableResult
    public func endDrag() -> UUID? {
        let target = hoveredTargetID
        sourceCardID = nil
        currentDragPosition = nil
        hoveredTargetID = nil
        return target
    }

    /// Cancel the drag without creating an edge.
    public func cancelDrag() {
        sourceCardID = nil
        currentDragPosition = nil
        hoveredTargetID = nil
    }
}
