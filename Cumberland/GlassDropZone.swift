//
//  GlassDropZone.swift
//  Cumberland
//
//  Reusable drop-zone component with a glass-morphism aesthetic. Renders a
//  translucent inset rectangle with a dashed border that highlights in accent
//  color when a drag enters the target area. Used in card editors and map
//  wizard import steps.
//

import SwiftUI

struct GlassDropZone: View {
    let height: CGFloat
    let cornerRadius: CGFloat
    let isTargeted: Bool
    let contentPadding: CGFloat
    let label: String

    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        let theme = themeManager.currentTheme
        ZStack {
            // Transparent spacer to reserve inset
            Color.clear
                .frame(height: height)

            // Glassy pill target
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(theme.colors.highlightHairline.opacity(
                            scheme == .dark ? theme.colors.highlightHairlineDarkOpacity
                                           : theme.colors.highlightHairlineLightOpacity + 0.02
                        ), lineWidth: 0.75)
                        .blendMode(.overlay)
                )
                .overlay(
                    // Glow when targeted
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(theme.colors.accentPrimary.opacity(isTargeted ? 0.8 : 0.0), lineWidth: 2.0)
                        .blur(radius: isTargeted ? 3 : 0)
                        .animation(.easeInOut(duration: 0.15), value: isTargeted)
                )
                .padding(.horizontal, max(0, contentPadding - 4))
                .frame(height: height)
                .overlay(
                    HStack(spacing: 8) {
                        Image(systemName: "tray.and.arrow.down")
                            .foregroundStyle(theme.colors.accentPrimary)
                        Text(label)
                            .font(theme.fonts.footnote)
                            .foregroundStyle(theme.colors.textSecondary)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, contentPadding)
                )
        }
        .accessibilityLabel(Text(label))
    }
}
