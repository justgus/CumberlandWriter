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
        // Note: This modifier is used directly by GlassSurfaceStyle.swift on non-visionOS
        // platforms via the native .glassEffect API. On those paths the theme is applied
        // at the GlassSurfaceStyle level. This fallback uses ultraThinMaterial as default.
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
    @Environment(\.themeManager) private var themeManager

    func makeBody(configuration: Configuration) -> some View {
        let theme = themeManager.currentTheme
        configuration.label
            .padding(.horizontal, theme.spacing.buttonPaddingHorizontal + 4)
            .padding(.vertical, theme.spacing.buttonPaddingVertical + 2)
            .background {
                theme.colors.surfaceGlass.platformResolved.asBackground(
                    cornerRadius: theme.shapes.buttonCornerRadius, style: .continuous)
            }
            .overlay {
                RoundedRectangle(cornerRadius: theme.shapes.buttonCornerRadius, style: .continuous)
                    .stroke(theme.colors.border.opacity(0.6), lineWidth: 0.5)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

