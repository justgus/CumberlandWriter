//
//  BoardEdgeHandle.swift
//  BoardEngine
//
//  Small circular handle rendered on the trailing edge of each node.
//  Dragging from a handle initiates edge creation.
//

import SwiftUI

// MARK: - Board Edge Handle

/// A small circle rendered at the trailing edge of a node, used as the
/// drag origin for edge creation.
public struct BoardEdgeHandle: View {
    public let nodeID: UUID
    public let accentColor: Color
    public let isSource: Bool
    public let isTarget: Bool

    public init(nodeID: UUID, accentColor: Color, isSource: Bool = false, isTarget: Bool = false) {
        self.nodeID = nodeID
        self.accentColor = accentColor
        self.isSource = isSource
        self.isTarget = isTarget
    }

    public var body: some View {
        Circle()
            .fill(isTarget ? accentColor : accentColor.opacity(0.6))
            .frame(width: handleSize, height: handleSize)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
            )
            .scaleEffect(isTarget ? 1.3 : (isSource ? 1.1 : 1.0))
            .shadow(color: accentColor.opacity(isTarget ? 0.6 : 0.3), radius: isTarget ? 6 : 3)
            .animation(.easeInOut(duration: 0.15), value: isTarget)
            .animation(.easeInOut(duration: 0.15), value: isSource)
            .allowsHitTesting(false)
    }

    private var handleSize: CGFloat {
        isTarget ? 16 : 12
    }
}
