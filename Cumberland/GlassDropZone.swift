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

    var body: some View {
        ZStack {
            // Transparent spacer to reserve inset
            Color.clear
                .frame(height: height)

            // Glassy pill target
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.white.opacity(scheme == .dark ? 0.20 : 0.32), lineWidth: 0.75)
                        .blendMode(.overlay)
                )
                .overlay(
                    // Glow when targeted
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.accentColor.opacity(isTargeted ? 0.8 : 0.0), lineWidth: 2.0)
                        .blur(radius: isTargeted ? 3 : 0)
                        .animation(.easeInOut(duration: 0.15), value: isTargeted)
                )
                .padding(.horizontal, max(0, contentPadding - 4))
                .frame(height: height)
                .overlay(
                    HStack(spacing: 8) {
                        Image(systemName: "tray.and.arrow.down")
                            .foregroundStyle(Color.accentColor)
                        Text(label)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, contentPadding)
                )
        }
        .accessibilityLabel(Text(label))
    }
}
