//
//  BoardDataSource.swift
//  BoardEngine
//
//  Protocol for the data source that feeds the board canvas.
//  Abstracts away the storage mechanism (SwiftData, CoreData, in-memory)
//  so BoardEngine views can work with any backing store.
//

import SwiftUI
import Observation

// MARK: - Board Data Source

/// Data source protocol for the board canvas. Provides nodes, edges,
/// transform state, and mutation methods. Consumers implement this
/// protocol to bridge their own data models to BoardEngine.
@MainActor
public protocol BoardDataSource: AnyObject, Observable {
    associatedtype Node: BoardNodeRepresentable
    associatedtype Edge: BoardEdgeRepresentable

    // MARK: - Board Identity

    /// Unique identifier for the current board.
    var boardID: UUID { get }

    // MARK: - Transform State

    /// Current zoom scale.
    var zoomScale: Double { get set }

    /// Current horizontal pan offset (view coordinates).
    var panX: Double { get set }

    /// Current vertical pan offset (view coordinates).
    var panY: Double { get set }

    // MARK: - Nodes

    /// All nodes currently on the board.
    var nodes: [Node] { get }

    /// The ID of the primary / anchor node, if any.
    var primaryNodeID: UUID? { get }

    // MARK: - Edges

    /// Return all edges relevant to the given set of node IDs.
    /// The implementation should return edges where both source and target
    /// are in the provided set.
    func edges(for nodeIDs: Set<UUID>) -> [Edge]

    // MARK: - Node Mutations

    /// Move a node to a new world-space position (live, during drag).
    func moveNode(_ nodeID: UUID, to position: CGPoint)

    /// Commit a node move (persist to storage after drag ends).
    func commitNodeMove(_ nodeID: UUID)

    /// Remove a node from the board.
    func removeNode(_ nodeID: UUID)

    /// Add nodes at a given world-space position (e.g. from backlog drop).
    func addNodes(_ nodeIDs: [UUID], at position: CGPoint)

    // MARK: - Transform Persistence

    /// Persist the current zoom/pan transform to storage.
    func persistTransform()

    // MARK: - Edge Creation

    /// Callback invoked when the user completes an edge creation drag.
    /// The consumer is responsible for showing any type-picker UI and
    /// creating the actual edge in storage.
    var onEdgeCreationRequested: ((_ sourceNodeID: UUID, _ targetNodeID: UUID) -> Void)? { get set }

    // MARK: - Backlog

    /// Items available in the backlog (not yet on the board).
    var backlogItems: [Node] { get }

    /// Set a filter on the backlog items (e.g. by category).
    /// Pass `nil` to clear the filter.
    func setBacklogFilter(_ filter: String?)
}
