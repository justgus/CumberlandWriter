//
//  BoardNodeSizeKeys.swift
//  BoardEngine
//
//  Preference keys for bubbling up node size measurements from
//  individual node views to the canvas layer for hit-testing and
//  gesture target registration.
//

import SwiftUI

// MARK: - Node Layout Size Key

/// Preference key collecting the full layout size of each node view,
/// keyed by node ID. Used as a fallback measurement for hit-testing.
public struct BoardNodeSizesKey: PreferenceKey {
    nonisolated(unsafe) public static var defaultValue: [UUID: CGSize] = [:]
    public static func reduce(value: inout [UUID: CGSize], nextValue: () -> [UUID: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Node Visual Size Key

/// Preference key collecting the visual "card shape" size of each node,
/// keyed by node ID. This is the size reported by the consumer's node
/// view and used for precise gesture hit-testing.
public struct BoardNodeVisualSizesKey: PreferenceKey {
    nonisolated(unsafe) public static var defaultValue: [UUID: CGSize] = [:]
    public static func reduce(value: inout [UUID: CGSize], nextValue: () -> [UUID: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
