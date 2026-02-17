//
//  BoardEdgeRepresentable.swift
//  BoardEngine
//
//  Protocol for a relationship/edge between two nodes on the board.
//  Used by the edges layer to determine which edges to render and
//  how to deduplicate bidirectional relationships.
//

import Foundation

// MARK: - Board Edge Representable

/// Represents a directed edge (relationship) between two nodes.
public protocol BoardEdgeRepresentable: Identifiable where ID == UUID {
    /// Unique identifier for this edge.
    var edgeID: UUID { get }

    /// The node ID this edge originates from.
    var sourceNodeID: UUID { get }

    /// The node ID this edge points to.
    var targetNodeID: UUID { get }

    /// A type code used for deterministic deduplication when multiple edges
    /// exist between the same pair of nodes (e.g. "owns/owned-by").
    var typeCode: String { get }

    /// Creation date, used as a tiebreaker for deterministic edge selection.
    var createdAt: Date { get }
}

// MARK: - Default ID conformance

extension BoardEdgeRepresentable {
    public var id: UUID { edgeID }
}
