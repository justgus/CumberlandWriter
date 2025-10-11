// AdaptiveGlassToolbar.swift
import SwiftUI

// A lightweight, native Material toolbar container that hosts any content you provide.
// Uses system Materials for a consistent macOS glass look without custom compositing.
public struct AdaptiveGlassToolbar<Content: View>: View {
    private let tint: Color?
    private let interactive: Bool
    private let content: Content

    public init(tint: Color? = nil, interactive: Bool = true, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.interactive = interactive
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: 8) {
            content
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            // Subtle keyline for definition; native separator adapts to appearances
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.separator.opacity(0.6), lineWidth: 0.5)
        )
        .overlay(
            // Optional faint tint wash to echo surrounding accent hues
            Group {
                if let tint {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.10))
                        .allowsHitTesting(false)
                }
            }
        )
        .compositingGroup()
        .shadow(color: .black.opacity(0.08), radius: interactive ? 6 : 4, x: 0, y: interactive ? 3 : 2)
    }
}

