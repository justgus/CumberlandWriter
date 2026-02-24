//
//  WhimsicalTheme.swift
//  Cumberland
//
//  ER-0037: Theming System — Whimsical Skin
//
//  A warm, handcrafted aesthetic theme inspired by parchment, leather,
//  and vintage stationery. Uses earthy tones, serif fonts (system Georgia),
//  softer corner radii, and warm brown shadows.
//
//  Colors adapt to light/dark mode: light mode uses warm cream parchment,
//  dark mode uses deep warm browns (like aged leather by candlelight).
//
//  On visionOS, solid parchment fills are promoted to materials to
//  preserve spatial depth perception.
//

import SwiftUI

/// A warm, whimsical theme with parchment colors and a handcrafted feel.
struct WhimsicalTheme: Theme {
    let id = "whimsical"
    let displayName = String(localized: "Whimsical")

    // MARK: - Adaptive Palette (light / dark)

    // Helper to create colors that adapt to light/dark mode
    #if os(macOS)
    private static func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let (r, g, b) = isDark ? dark : light
            return NSColor(red: r, green: g, blue: b, alpha: 1.0)
        }))
    }
    #else
    private static func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        Color(uiColor: UIColor { traits in
            let (r, g, b) = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: r, green: g, blue: b, alpha: 1.0)
        })
    }
    #endif

    // --- Surfaces ---
    /// Parchment base: warm cream (light) / deep warm charcoal (dark)
    private static let parchment = adaptive(
        light: (0.96, 0.90, 0.78),   // #F5E6C8
        dark:  (0.12, 0.10, 0.08)    // #1E1914 — aged leather in shadow
    )
    /// Aged paper: slightly darker cream (light) / slightly lighter charcoal (dark)
    private static let agedPaper = adaptive(
        light: (0.93, 0.88, 0.78),   // #EDE0C8
        dark:  (0.16, 0.13, 0.10)    // #29211A — parchment by candlelight
    )
    /// Card background
    private static let cardBg = adaptive(
        light: (0.96, 0.90, 0.78),   // same as parchment light
        dark:  (0.14, 0.12, 0.09)    // #241E17 — slightly warmer than surface
    )

    // --- Text ---
    /// Ink: deep brown (light) / warm off-white (dark)
    private static let ink = adaptive(
        light: (0.17, 0.09, 0.06),   // #2C1810
        dark:  (0.91, 0.84, 0.72)    // #E8D6B8 — warm parchment text
    )
    /// Secondary text
    private static let secondaryText = adaptive(
        light: (0.40, 0.30, 0.22),
        dark:  (0.68, 0.58, 0.48)    // #AD9479
    )
    /// Tertiary text
    private static let tertiaryText = adaptive(
        light: (0.55, 0.45, 0.38),
        dark:  (0.50, 0.42, 0.34)    // #806B57
    )

    // --- Accents ---
    /// Leather: rich brown (light) / warm copper (dark)
    private static let leather = adaptive(
        light: (0.545, 0.271, 0.075), // #8B4513
        dark:  (0.72, 0.45, 0.20)    // #B87333 — burnished copper
    )
    /// Muted gold
    private static let mutedGold = adaptive(
        light: (0.72, 0.53, 0.04),   // #B8860B
        dark:  (0.82, 0.65, 0.20)    // #D1A633 — brighter gold for dark bg
    )

    // --- Chrome ---
    /// Border
    private static let warmBorder = adaptive(
        light: (0.78, 0.70, 0.60),
        dark:  (0.30, 0.25, 0.20)    // #4D4033
    )
    /// Divider
    private static let warmDivider = adaptive(
        light: (0.82, 0.74, 0.64),
        dark:  (0.25, 0.21, 0.17)    // #40352B
    )
    /// Warm shadow
    private static let warmShadow = adaptive(
        light: (0.30, 0.18, 0.10),
        dark:  (0.0, 0.0, 0.0)       // pure black shadow in dark mode
    )
    /// Highlight hairline
    private static let warmHighlight = adaptive(
        light: (1.0, 0.97, 0.90),
        dark:  (0.35, 0.28, 0.20)    // warm brown highlight in dark
    )

    // MARK: - Tokens

    let colors = ThemeColors(
        surfacePrimary: .solid(parchment),
        surfaceSecondary: .solid(agedPaper),
        surfaceGlass: .solid(parchment),
        surfaceGlassProminent: .solid(agedPaper),
        accentPrimary: leather,
        accentSecondary: mutedGold,
        textPrimary: ink,
        textSecondary: secondaryText,
        textTertiary: tertiaryText,
        border: warmBorder,
        shadow: warmShadow,
        divider: warmDivider,
        cardBackground: cardBg,
        highlightHairline: warmHighlight,
        highlightHairlineDarkOpacity: 0.25,
        highlightHairlineLightOpacity: 0.40
    )

    let fonts = ThemeFonts(
        largeTitle: .system(.largeTitle, design: .serif),
        headline: .system(.headline, design: .serif),
        subheadline: .system(.subheadline, design: .serif),
        body: .system(.body, design: .serif),
        caption: .system(.caption, design: .serif),
        footnote: .system(.footnote, design: .serif)
    )

    let shapes = ThemeShapes(
        cardCornerRadius: 16,
        buttonCornerRadius: 12,
        panelCornerRadius: 16,
        toolbarCornerRadius: 16,
        thumbnailCornerRadius: 10
    )

    let shadows = ThemeShadows(
        cardColor: warmShadow,
        cardDarkOpacity: 0.45,
        cardLightOpacity: 0.15,
        cardRadius: 10,
        cardX: 0,
        cardY: 5,
        hoverRadiusBoost: 3,
        hoverYBoost: 2
    )

    let spacing = ThemeSpacing(
        cardPadding: 14,
        sectionSpacing: 10,
        listRowSpacing: 10,
        buttonPaddingVertical: 8,
        buttonPaddingHorizontal: 12
    )
}
