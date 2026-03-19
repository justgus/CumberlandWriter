//
//  WhimsicalTheme.swift
//  Cumberland
//
//  ER-0037: Theming System — Whimsical Skin
//
//  A playful, storybook-inspired theme with a pastel multi-color
//  palette. Surfaces use soft fairy-tale tones (rose cream, lavender mist),
//  accents are pastel teal, coral, and gold, and semantic colors use
//  storybook crimson and enchanted green. Cochin serif fonts and generous
//  shapes evoke illustrated manuscripts and handbound journals.
//
//  Colors adapt to light/dark mode: light mode is bright and airy like
//  an open picture book; dark mode is rich and cozy like reading by
//  candlelight in a wizard's study.
//
//  On visionOS, solid fills are promoted to materials for spatial depth.
//

import SwiftUI

/// A playful, storybook theme with a multi-color palette of teal, coral, gold, and blush.
struct WhimsicalTheme: Theme {
    let id = "whimsical"
    let displayName = String(localized: "Whimsical")

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

    /// Rose cream: main surface — pinkish pastel storybook page
    private static let roseCream = adaptive(
        light: (0.98, 0.93, 0.94),   // #FAEDF0 — rose-tinted page
        dark:  (0.16, 0.12, 0.14)    // #291F24 — dusky rose binding
    )
    /// Lavender mist: secondary surface — chapter dividers, cards
    private static let lavenderMist = adaptive(
        light: (0.95, 0.92, 0.97),   // #F2EBF8 — lavender petal
        dark:  (0.15, 0.12, 0.18)    // #261F2E — dried lavender
    )
    /// Soft sky: tertiary surface — alternating rows, subtle variation
    private static let softSky = adaptive(
        light: (0.92, 0.95, 0.98),   // #EBF2FA — morning sky
        dark:  (0.12, 0.14, 0.18)    // #1F242E — twilight sky
    )
    /// Card background: warm pastel pink
    private static let cardBg = adaptive(
        light: (0.97, 0.93, 0.93),   // #F8EDED — rose parchment
        dark:  (0.17, 0.13, 0.14)    // #2B2124 — candlelit rose desk
    )

    // MARK: - Text Palette

    /// Deep charcoal with warmth (light) / soft cream (dark)
    private static let storyInk = adaptive(
        light: (0.18, 0.15, 0.12),   // #2E261F — fountain pen ink
        dark:  (0.92, 0.88, 0.82)    // #EBE0D1 — candlelit page
    )
    /// Secondary text: muted story tone
    private static let marginNote = adaptive(
        light: (0.42, 0.38, 0.34),   // #6B6157 — pencil margin note
        dark:  (0.65, 0.60, 0.55)    // #A6998C — faded annotation
    )
    /// Tertiary text
    private static let whisper = adaptive(
        light: (0.58, 0.54, 0.50),   // #948A80 — whispered aside
        dark:  (0.48, 0.44, 0.40)    // #7A7066 — distant echo
    )

    // MARK: - Accent Palette

    /// Pastel teal: primary accent — soft enchanted pool
    private static let pastelTeal = adaptive(
        light: (0.40, 0.68, 0.68),   // #66ADAD — soft teal
        dark:  (0.45, 0.75, 0.75)    // #73BFBF — glowing lagoon
    )
    /// Pastel coral: secondary accent — gentle warmth
    private static let pastelCoral = adaptive(
        light: (0.90, 0.58, 0.55),   // #E6948C — soft coral
        dark:  (0.92, 0.62, 0.58)    // #EB9E94 — rosy fireside
    )
    /// Pastel gold: tertiary accent — gentle fairy shimmer
    private static let pastelGold = adaptive(
        light: (0.85, 0.75, 0.42),   // #D9BF6B — soft fairy dust
        dark:  (0.90, 0.80, 0.48)    // #E6CC7A — warm lantern
    )

    // MARK: - Tag Palette

    /// Pastel teal tag background
    private static let tagTealBg = adaptive(
        light: (0.86, 0.94, 0.94),   // #DBF0F0 — misty lagoon
        dark:  (0.12, 0.22, 0.22)    // #1F3838 — deep pool
    )
    /// Teal tag text
    private static let tagTealText = adaptive(
        light: (0.25, 0.52, 0.52),   // #408585 — soft teal
        dark:  (0.50, 0.78, 0.78)    // #80C7C7 — bright lagoon
    )

    // MARK: - Semantic State Colors

    /// Storybook crimson for destructive/warning
    private static let crimsonRose = adaptive(
        light: (0.72, 0.15, 0.22),   // #B82638 — red riding hood
        dark:  (0.88, 0.30, 0.35),   // #E04D59 — enchanted apple
    )
    /// Enchanted green for success
    private static let enchantedGreen = adaptive(
        light: (0.15, 0.50, 0.28),   // #268047 — forest clearing
        dark:  (0.30, 0.70, 0.45)    // #4DB373 — fairy glade
    )

    // MARK: - Chrome Palette

    /// Warm border
    private static let warmBorder = adaptive(
        light: (0.80, 0.75, 0.68),   // #CCBFAD — gilt edge
        dark:  (0.28, 0.24, 0.20)    // #473D33 — dark binding
    )
    /// Warm divider
    private static let warmDivider = adaptive(
        light: (0.84, 0.79, 0.72),   // #D6C9B8 — page crease
        dark:  (0.22, 0.19, 0.16)    // #383029 — shadow crease
    )
    /// Warm shadow
    private static let warmShadow = adaptive(
        light: (0.25, 0.18, 0.12),   // #402E1F — cast shadow
        dark:  (0.0, 0.0, 0.0)       // pure black in dark
    )
    /// Warm highlight
    private static let warmHighlight = adaptive(
        light: (1.0, 0.98, 0.94),    // #FFFAF0 — page gleam
        dark:  (0.30, 0.25, 0.20)    // #4D4033 — candlelight edge
    )

    // MARK: - Tokens

    let colors = ThemeColors(
        surfacePrimary: .solid(roseCream),
        surfaceSecondary: .solid(lavenderMist),
        surfaceTertiary: .solid(softSky),
        surfaceGlass: .solid(roseCream),
        surfaceGlassProminent: .solid(lavenderMist),
        accentPrimary: pastelTeal,
        accentSecondary: pastelCoral,
        accentTertiary: pastelGold,
        textPrimary: storyInk,
        textSecondary: marginNote,
        textTertiary: whisper,
        tagBackground: tagTealBg,
        tagText: tagTealText,
        destructive: crimsonRose,
        success: enchantedGreen,
        border: warmBorder,
        shadow: warmShadow,
        divider: warmDivider,
        cardBackground: cardBg,
        highlightHairline: warmHighlight,
        highlightHairlineDarkOpacity: 0.25,
        highlightHairlineLightOpacity: 0.40
    )

    let fonts = ThemeFonts(
        largeTitle: .custom("Cochin", size: 28, relativeTo: .largeTitle),
        headline: .custom("Cochin-Bold", size: 14, relativeTo: .headline),
        subheadline: .custom("Cochin", size: 12, relativeTo: .subheadline),
        body: .custom("Cochin", size: 14, relativeTo: .body),
        caption: .custom("Cochin", size: 10, relativeTo: .caption),
        footnote: .custom("Cochin", size: 11, relativeTo: .footnote)
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

    let backgroundImages = ThemeBackgroundImages(
        sidebarBackground: "whimsical-parchment",
        contentBackground: "whimsical-parchment",
        murderboardCanvas: "whimsical-cork",
        structureBoardCanvas: nil,
        wizardHero: nil,
        emptyState: nil,
        detailPlaceholder: nil
    )
}
