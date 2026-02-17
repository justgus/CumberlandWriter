//
//  BoardNodeRepresentable.swift
//  BoardEngine
//
//  Protocol for any item that can be placed on the board canvas as a node.
//  Consumers conform their own data models to this protocol to provide
//  display name, position, accent color, and category information.
//

import SwiftUI

// MARK: - Board Node Representable

/// Represents any item that can be placed on the canvas as a node.
/// Mutations (position changes) go through `BoardDataSource` methods,
/// so this protocol is read-only.
public protocol BoardNodeRepresentable: Identifiable where ID == UUID {
    /// Unique identifier for this node.
    var nodeID: UUID { get }

    /// World-space X position.
    var posX: Double { get }

    /// World-space Y position.
    var posY: Double { get }

    /// Z-ordering index (higher = on top).
    var zIndex: Double { get }

    /// Whether this node is pinned (cannot be repositioned by layout algorithms).
    var isPinned: Bool { get }

    /// Display name for the node (used in context menus, accessibility).
    var displayName: String { get }

    /// Optional subtitle text.
    var subtitle: String { get }

    /// SF Symbol name for the node's category.
    var categorySystemImage: String { get }

    /// Whether this node is the primary / anchor node on the board.
    var isPrimary: Bool { get }

    /// Accent color for the node, used in edge gradients, handles, and hover glow.
    /// Takes a `ColorScheme` because color may differ between light and dark mode.
    func accentColor(for scheme: ColorScheme) -> Color
}

// MARK: - Default ID conformance

extension BoardNodeRepresentable {
    public var id: UUID { nodeID }
}
