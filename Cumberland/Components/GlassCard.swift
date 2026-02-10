//
//  GlassCard.swift
//  Cumberland
//
//  Extracted from CardRelationshipView.swift as part of ER-0022 Phase 4.5.
//  Reusable glass-morphism container view with configurable corner radius,
//  optional accent tint, shadow depth, and padding. Used throughout the
//  app for panels, inspector cards, and relationship tiles.
//

import SwiftUI

/// A glass-morphism style container view that provides a translucent,
/// material-based background with subtle shadows and optional tinting.
///
/// Used for headers and panels that need a modern, layered appearance.
///
/// **Example Usage:**
/// ```swift
/// GlassCard(cornerRadius: 16, tint: .blue.opacity(0.2)) {
///     VStack {
///         Text("Header")
///         Text("Content")
///     }
/// }
/// ```
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let tint: Color?
    let interactive: Bool
    let content: Content

    /// Create a glass card container
    /// - Parameters:
    ///   - cornerRadius: Corner radius for the rounded rectangle (default: 12)
    ///   - tint: Optional tint color overlay (default: nil)
    ///   - interactive: Whether to use larger shadow for interactive elements (default: true)
    ///   - content: The content to display inside the card
    init(
        cornerRadius: CGFloat = 12,
        tint: Color? = nil,
        interactive: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.interactive = interactive
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.separator.opacity(0.6), lineWidth: 0.5)
                )
                .overlay(
                    Group {
                        if let tint {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(tint.opacity(0.10))
                                .allowsHitTesting(false)
                        }
                    }
                )
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.08), radius: interactive ? 6 : 4, x: 0, y: interactive ? 3 : 2)
        .overlay(
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(12)
        )
    }
}

// MARK: - String Extension for Pluralization

extension String {
    /// Drop the trailing 's' if the string appears to be pluralized.
    /// Simple heuristic: if the string ends with 's' and has more than 1 character, drop it.
    ///
    /// **Examples:**
    /// - "Characters" → "Character"
    /// - "Locations" → "Location"
    /// - "s" → "s" (unchanged, too short)
    func dropLastIfPluralized() -> String {
        if self.count > 1 && self.hasSuffix("s") {
            return String(self.dropLast())
        }
        return self
    }
}

// MARK: - Preview

#if DEBUG
#Preview("GlassCard") {
    VStack(spacing: 20) {
        GlassCard(cornerRadius: 16, tint: .blue) {
            VStack(alignment: .leading) {
                Text("Interactive Card")
                    .font(.headline)
                Text("This is an interactive glass card with blue tint.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 100)

        GlassCard(cornerRadius: 12, interactive: false) {
            VStack(alignment: .leading) {
                Text("Static Card")
                    .font(.headline)
                Text("This is a non-interactive glass card.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 100)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
#endif
