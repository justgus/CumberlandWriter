//
//  ContentPlaceholderView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/4/25.
//
//  Empty-state placeholder view displaying a title, subtitle, and optional
//  SF Symbol. Used throughout the app when a list, detail column, or canvas
//  has no content to display.
//

import Foundation
import SwiftUI

struct ContentPlaceholderView: View {
    let title: String
    let subtitle: String
    var systemImage: String? = "rectangle.and.text.magnifyingglass"

    /// Which background image slot to use from `ThemeBackgroundImages`.
    /// Defaults to `\.detailPlaceholder` for "no selection" states.
    /// Use `\.emptyState` for "no content" empty states.
    var backgroundImageKeyPath: KeyPath<ThemeBackgroundImages, String?> = \.detailPlaceholder

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        let theme = themeManager.currentTheme
        VStack(spacing: 20) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(theme.colors.textSecondary)
                    .accessibilityHidden(true)
                    .padding(10)
                    .background {
                        theme.colors.surfaceGlass.platformResolved.asBackground()
                            .clipShape(Circle())
                    }
                    .clipShape(Circle())
                    .padding()
            }

            VStack(spacing: 12) {
                Text(title)
                    .font(theme.fonts.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(theme.fonts.body)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background {
                theme.colors.surfaceSecondary.platformResolved.asBackground(
                    cornerRadius: theme.shapes.panelCornerRadius, style: .continuous)
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.shapes.panelCornerRadius, style: .continuous))
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .background {
            // Theme surface background for the entire placeholder area
            theme.colors.surfacePrimary.platformResolved.asBackground()
                .overlay {
                    // Subtle gradient wash using theme accent
                    LinearGradient(
                        colors: [
                            .clear,
                            theme.colors.accentPrimary.opacity(0.03),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .themeBackground(backgroundImageKeyPath, mode: .stretch, opacity: 0.08, theme: theme)
    }
}

#Preview {
    Group {
        ContentPlaceholderView(
            title: "No items yet",
            subtitle: "Create a new item to see it here."
        )
        ContentPlaceholderView(
            title: "Select an item",
            subtitle: "Choose an item from the list to see its details.",
            systemImage: "hand.tap"
        )
        .preferredColorScheme(.dark)
    }
    .padding()
}

