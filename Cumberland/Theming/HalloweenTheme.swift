//
//  HalloweenTheme.swift
//  Cumberland
//
//  ER-0037 Phase 2: Multi-Color Themes
//
//  A spooky theme inspired by Halloween night — charcoal black backgrounds,
//  bone-white text, pumpkin orange accents, blood red destructive actions,
//  and sickly green for success. Evokes carved jack-o'-lanterns, cobwebs,
//  and moonlit graveyards.
//
//  Light mode: charcoal grays with orange/bone pop.
//  Dark mode: near-black with vivid pumpkin glow.
//
//  On visionOS, solid fills are promoted to materials for spatial depth.
//

import SwiftUI

/// A spooky Halloween theme with black, bone-white, pumpkin orange, and blood red.
struct HalloweenTheme: Theme {
    let id = "halloween"
    let displayName = String(localized: "Halloween")

    // MARK: - Adaptive Palette (light / dark)

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

    // MARK: - Surface Palette

    /// Charcoal: dark slate (light) / near-black (dark)
    private static let charcoal = adaptive(
        light: (0.15, 0.14, 0.16),   // #262329 — dark slate
        dark:  (0.06, 0.05, 0.07)    // #0F0D12 — midnight black
    )
    /// Tombstone gray: slightly lighter (light) / very dark gray (dark)
    private static let tombstone = adaptive(
        light: (0.20, 0.19, 0.22),   // #333038 — tombstone
        dark:  (0.09, 0.08, 0.10)    // #17141A — crypt
    )
    /// Cobweb gray: tertiary surface
    private static let cobweb = adaptive(
        light: (0.18, 0.17, 0.20),   // #2E2B33 — cobweb shadow
        dark:  (0.08, 0.07, 0.09)    // #141217 — deep void
    )
    /// Card background
    private static let cardBg = adaptive(
        light: (0.22, 0.20, 0.24),   // #38333D — slightly warmer slate
        dark:  (0.10, 0.08, 0.11)    // #1A141C — coffin interior
    )

    // MARK: - Text Palette

    /// Bone white: warm off-white
    private static let boneWhite = adaptive(
        light: (0.92, 0.88, 0.82),   // #EBE0D1 — aged bone
        dark:  (0.90, 0.86, 0.80)    // #E6DBCC — moonlit bone
    )
    /// Ghost gray: secondary text
    private static let ghostGray = adaptive(
        light: (0.65, 0.60, 0.55),   // #A6998C
        dark:  (0.60, 0.55, 0.50)    // #998C80 — faded ghost
    )
    /// Fog: tertiary text
    private static let fog = adaptive(
        light: (0.50, 0.46, 0.42),   // #80766B
        dark:  (0.42, 0.38, 0.34),   // #6B6157
    )

    // MARK: - Accent Palette

    /// Pumpkin orange: primary accent
    private static let pumpkinOrange = adaptive(
        light: (0.90, 0.52, 0.08),   // #E68514 — carved jack-o'-lantern
        dark:  (0.95, 0.58, 0.12)    // #F2941F — glowing pumpkin
    )
    /// Candle flame: secondary accent
    private static let candleFlame = adaptive(
        light: (0.85, 0.68, 0.15),   // #D9AD26 — flickering candle
        dark:  (0.92, 0.75, 0.22)    // #EBBF38 — bright flame
    )
    /// Witch purple: tertiary accent
    private static let witchPurple = adaptive(
        light: (0.55, 0.25, 0.65),   // #8C40A6 — witch's cloak
        dark:  (0.68, 0.38, 0.78)    // #AD61C7 — glowing spell
    )

    // MARK: - Tag Palette

    /// Dark pumpkin tag background
    private static let tagPumpkinBg = adaptive(
        light: (0.35, 0.22, 0.08),   // #593814 — dark pumpkin rind
        dark:  (0.28, 0.18, 0.06)    // #472E0F — carved shadow
    )
    /// Bright orange tag text
    private static let tagPumpkinText = adaptive(
        light: (0.95, 0.60, 0.15),   // #F29926 — vivid pumpkin
        dark:  (0.98, 0.65, 0.20)    // #FAA633 — lantern glow
    )

    // MARK: - Semantic State Colors

    /// Blood red for destructive actions
    private static let bloodRed = adaptive(
        light: (0.72, 0.08, 0.08),   // #B81414 — fresh blood
        dark:  (0.85, 0.15, 0.15)    // #D92626 — bright arterial
    )
    /// Sickly green for success states (eerie twist on "positive")
    private static let sicklyGreen = adaptive(
        light: (0.25, 0.55, 0.18),   // #408C2E — swamp moss
        dark:  (0.35, 0.72, 0.28)    // #59B847 — toxic glow
    )

    // MARK: - Chrome Palette

    /// Iron border
    private static let ironBorder = adaptive(
        light: (0.35, 0.32, 0.38),   // #595261 — wrought iron
        dark:  (0.22, 0.20, 0.25)    // #383340 — dark iron
    )
    /// Iron divider
    private static let ironDivider = adaptive(
        light: (0.30, 0.28, 0.33),   // #4D4754 — fence rail
        dark:  (0.18, 0.16, 0.20)    // #2E2933 — crypt bar
    )
    /// Void shadow
    private static let voidShadow = adaptive(
        light: (0.0, 0.0, 0.0),      // pure black
        dark:  (0.0, 0.0, 0.0)
    )
    /// Faint moonlight highlight
    private static let moonlight = adaptive(
        light: (0.40, 0.38, 0.45),   // #666173 — pale moonlight
        dark:  (0.18, 0.16, 0.22)    // #2E2938 — dim moonlight
    )

    // MARK: - Tokens

    let colors = ThemeColors(
        surfacePrimary: .solid(charcoal),
        surfaceSecondary: .solid(tombstone),
        surfaceTertiary: .solid(cobweb),
        surfaceGlass: .solid(charcoal),
        surfaceGlassProminent: .solid(tombstone),
        accentPrimary: pumpkinOrange,
        accentSecondary: candleFlame,
        accentTertiary: witchPurple,
        textPrimary: boneWhite,
        textSecondary: ghostGray,
        textTertiary: fog,
        tagBackground: tagPumpkinBg,
        tagText: tagPumpkinText,
        destructive: bloodRed,
        success: sicklyGreen,
        border: ironBorder,
        shadow: voidShadow,
        divider: ironDivider,
        cardBackground: cardBg,
        highlightHairline: moonlight,
        highlightHairlineDarkOpacity: 0.15,
        highlightHairlineLightOpacity: 0.20
    )

    let fonts = ThemeFonts(
        largeTitle: .system(.largeTitle, design: .serif, weight: .bold),
        headline: .system(.headline, design: .serif),
        subheadline: .system(.subheadline, design: .default),
        body: .system(.body, design: .default),
        caption: .system(.caption, design: .default),
        footnote: .system(.footnote, design: .default)
    )

    let shapes = ThemeShapes(
        cardCornerRadius: 10,
        buttonCornerRadius: 6,
        panelCornerRadius: 10,
        toolbarCornerRadius: 10,
        thumbnailCornerRadius: 6
    )

    let shadows = ThemeShadows(
        cardColor: voidShadow,
        cardDarkOpacity: 0.60,
        cardLightOpacity: 0.50,
        cardRadius: 12,
        cardX: 0,
        cardY: 6,
        hoverRadiusBoost: 4,
        hoverYBoost: 3
    )

    let spacing = ThemeSpacing(
        cardPadding: 12,
        sectionSpacing: 8,
        listRowSpacing: 8,
        buttonPaddingVertical: 6,
        buttonPaddingHorizontal: 10
    )

    let backgroundImages = ThemeBackgroundImages.none
}
