//
//  BoardEdgeDropTargetHighlight.swift
//  BoardEngine
//
//  View modifier that highlights a node when it is the hovered target
//  during an edge creation drag.
//

import SwiftUI

// MARK: - Board Edge Drop Target Highlight

/// Modifier that adds a pulsing highlight border when a node is being
/// hovered as an edge creation target.
public struct BoardEdgeDropTargetHighlight: ViewModifier {
    public let isTarget: Bool
    public let accentColor: Color

    public init(isTarget: Bool, accentColor: Color) {
        self.isTarget = isTarget
        self.accentColor = accentColor
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(accentColor, lineWidth: isTarget ? 3 : 0)
                    .opacity(isTarget ? 0.8 : 0.0)
                    .animation(.easeInOut(duration: 0.2), value: isTarget)
                    .allowsHitTesting(false)
            )
    }
}
