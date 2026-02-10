//
//  GlassEffects.swift
//  Cumberland
//
//  Created by Assistant on 10/10/25.
//
//  View extension providing a .glassEffect(_:in:) modifier that applies a
//  translucent material background with tinted blur. Used by StoryStructureView,
//  overlays, and other glass-styled containers throughout the app.
//

import SwiftUI

// Extension to provide glass effect modifiers used in StoryStructureView and overlays.
extension View {
    @ViewBuilder
    func glassEffect(_ effect: GlassEffect, in shape: some InsettableShape) -> some View {
        self
            .background {
                shape
                    .fill(.ultraThinMaterial)
            }
            .clipShape(shape)
    }

    // A "modern" variant used by small tags/badges in your UI. This keeps it native by
    // using Material directly, while matching your existing call sites.
    @ViewBuilder
    func modernGlassEffect(_ effect: GlassEffect, in shape: some InsettableShape) -> some View {
        self
            .background {
                shape
                    .fill(.thinMaterial)
            }
            .overlay {
                // Subtle keyline for definition on busy backgrounds
                shape
                    .stroke(.separator.opacity(0.6), lineWidth: 0.5)
            }
            .clipShape(shape)
    }
}

// Simple glass effect enumeration
enum GlassEffect {
    case regular

    func interactive() -> GlassEffect {
        return .regular
    }

    // Keep API compatibility with calls like `.regular.tint(.blue)`
    func tint(_ color: Color) -> GlassEffect {
        // We rely on native Material which already adapts to content;
        // leaving this as a no-op keeps call sites compiling.
        self
    }
}

// Extension to provide glass button style if it doesn't exist
extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle {
        GlassButtonStyle()
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.separator.opacity(0.6), lineWidth: 0.5)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

