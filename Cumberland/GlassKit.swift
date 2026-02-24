//
//  GlassKit.swift
//  Cumberland
//
//  Collection of glass-morphism ViewModifiers, ButtonStyles, and View extensions
//  for the app's visual language. Includes GlassButtonModifier (hover-sensitive
//  translucent buttons), glass chip/tag variants, and the .glassButton() /
//  .glassTag() View extension shortcuts.
//

import SwiftUI

// MARK: - Glass button style / modifier

private struct GlassButtonModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.themeManager) private var themeManager
    @State private var hovering: Bool = false

    var cornerRadius: CGFloat = 8
    var padding: EdgeInsets = EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
    var prominent: Bool = false

    func body(content: Content) -> some View {
        let theme = themeManager.currentTheme
        let fill = prominent ? theme.colors.surfaceGlassProminent : theme.colors.surfaceGlass
        let shadows = theme.shadows

        content
            .padding(padding)
            .background(
                fill.platformResolved.asBackground(
                    cornerRadius: cornerRadius, style: .continuous)
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.colors.highlightHairline.opacity(
                        scheme == .dark ? theme.colors.highlightHairlineDarkOpacity
                                       : theme.colors.highlightHairlineLightOpacity
                    ), lineWidth: 0.75)
                    .blendMode(.overlay)
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.colors.border.opacity(0.6), lineWidth: 0.5)
                    .allowsHitTesting(false)
            )
            .shadow(
                color: shadows.cardColor.opacity(scheme == .dark ? shadows.cardDarkOpacity : shadows.cardLightOpacity),
                radius: (prominent ? 6 : 4) + (hovering ? shadows.hoverRadiusBoost : 0),
                x: shadows.cardX,
                y: (prominent ? 3 : 2) + (hovering ? shadows.hoverYBoost / 2 : 0)
            )
            .scaleEffect(hovering ? (prominent ? 1.03 : 1.02) : 1.0)
            .animation(.easeInOut(duration: 0.12), value: hovering)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onHoverIfAvailable { hovering = $0 }
    }
}

public extension View {
    // Original API remains source-compatible
    func glassButtonStyle(cornerRadius: CGFloat = 8) -> some View {
        modifier(GlassButtonModifier(cornerRadius: cornerRadius))
    }

    // New API with "prominent" option
    func glassButtonStyle(prominent: Bool, cornerRadius: CGFloat = 8) -> some View {
        let pad = prominent
            ? EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            : EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        return modifier(GlassButtonModifier(cornerRadius: cornerRadius, padding: pad, prominent: prominent))
    }
}

// MARK: - Glass surface style (generic background modifier)

private struct GlassSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.themeManager) private var themeManager
    let cornerRadius: CGFloat
    let tint: Color
    let interactive: Bool

    @State private var hovering: Bool = false

    func body(content: Content) -> some View {
        let theme = themeManager.currentTheme
        let shadows = theme.shadows

        content
            .background(
                theme.colors.surfaceGlass.platformResolved.asBackground(
                    cornerRadius: cornerRadius, style: .continuous)
                    .allowsHitTesting(false)
            )
            .overlay(
                // Subtle tint wash to get that caustic/liquid feel
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(scheme == .dark ? 0.14 : 0.10),
                                tint.opacity(0.0),
                                tint.opacity(scheme == .dark ? 0.10 : 0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.softLight)
                    .allowsHitTesting(false)
            )
            .overlay(
                // Inner highlight hairline
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.colors.highlightHairline.opacity(
                        scheme == .dark ? theme.colors.highlightHairlineDarkOpacity
                                       : theme.colors.highlightHairlineLightOpacity + 0.05
                    ), lineWidth: 0.75)
                    .blendMode(.overlay)
                    .allowsHitTesting(false)
            )
            .overlay(
                // Outer subtle keyline to define edges on busy backgrounds
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.colors.border.opacity(0.6), lineWidth: 0.5)
                    .allowsHitTesting(false)
            )
            .shadow(
                color: shadows.cardColor.opacity(scheme == .dark ? shadows.cardDarkOpacity : shadows.cardLightOpacity),
                radius: interactive ? (hovering ? shadows.cardRadius + shadows.hoverRadiusBoost : shadows.cardRadius) : shadows.cardRadius,
                x: shadows.cardX,
                y: interactive ? (hovering ? shadows.cardY + shadows.hoverYBoost : shadows.cardY) : shadows.cardY
            )
            .scaleEffect(interactive && hovering ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: hovering)
            .onHoverIfAvailable { hovering = interactive ? $0 : false }
    }
}

public extension View {
    func glassSurfaceStyle(cornerRadius: CGFloat = 12, tint: Color = .accentColor.opacity(0.15), interactive: Bool = false) -> some View {
        modifier(GlassSurfaceModifier(cornerRadius: cornerRadius, tint: tint, interactive: interactive))
    }
}

// MARK: - GlassEffectContainer

public struct GlassEffectContainer<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var themeManager: ThemeManager
    private let spacing: CGFloat
    private let cornerRadius: CGFloat
    private let content: Content

    public init(spacing: CGFloat = 8, cornerRadius: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        let theme = themeManager.currentTheme
        let shadows = theme.shadows

        HStack(spacing: spacing) {
            content
        }
        .padding(.vertical, theme.spacing.buttonPaddingVertical)
        .padding(.horizontal, theme.spacing.buttonPaddingHorizontal)
        .background(
            theme.colors.surfaceGlassProminent.platformResolved.asBackground(
                cornerRadius: cornerRadius, style: .continuous)
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(theme.colors.highlightHairline.opacity(
                    scheme == .dark ? theme.colors.highlightHairlineDarkOpacity - 0.02
                                   : theme.colors.highlightHairlineLightOpacity - 0.02
                ), lineWidth: 0.75)
                .blendMode(.overlay)
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(theme.colors.border.opacity(0.6), lineWidth: 0.5)
                .allowsHitTesting(false)
        )
        .shadow(color: shadows.cardColor.opacity(scheme == .dark ? shadows.cardDarkOpacity - 0.06 : shadows.cardLightOpacity - 0.02), radius: 6, x: 0, y: 3)
    }
}

// MARK: - GlassFormSection

public struct GlassFormSection<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var themeManager: ThemeManager

    private let title: String
    private let footer: String?
    private let tint: Color
    private let content: Content

    public init(_ title: String,
                footer: String? = nil,
                tint: Color = .accentColor,
                @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.tint = tint
        self.content = content()
    }

    public var body: some View {
        let theme = themeManager.currentTheme
        VStack(alignment: .leading, spacing: theme.spacing.sectionSpacing) {
            // Header
            HStack(spacing: 8) {
                Circle()
                    .fill(tint.opacity(0.9))
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(theme.fonts.headline)
                    .foregroundStyle(theme.colors.textPrimary)
            }
            .padding(.horizontal, 6)
            .padding(.top, 6)

            // Section content
            VStack(spacing: 0) {
                content
            }
            .glassSurfaceStyle(cornerRadius: theme.shapes.panelCornerRadius, tint: tint.opacity(0.25), interactive: true)

            // Footer
            if let footer, !footer.isEmpty {
                Text(footer)
                    .font(theme.fonts.footnote)
                    .foregroundStyle(theme.colors.textSecondary)
                    .padding(.top, 6)
                    .padding(.horizontal, 6)
            }
        }
    }
}

// MARK: - Small helper

private extension View {
    @ViewBuilder
    func onHoverIfAvailable(_ handler: @escaping (Bool) -> Void) -> some View {
        #if os(macOS)
        self.onHover(perform: handler)
        #else
        self
        #endif
    }
}
