//
//  PurpleTheme.swift
//  Cumberland
//
//  ER-0037 Phase 2: Multi-Color Themes
//
//  A regal, deep theme inspired by amethyst, twilight, and velvet.
//  Light mode: soft lavender fields with plum accents and silver chrome.
//  Dark mode: deep midnight violet with warm amethyst highlights.
//
//  On visionOS, solid fills are promoted to materials for spatial depth.
//

import SwiftUI

/// A regal theme with deep plums, soft lavenders, violet accents, and silver text.
struct PurpleTheme: Theme {
    let id = "purple"
    let displayName = String(localized: "Purple Reign")

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

    /// Lavender mist: soft purple-white (light) / deep midnight (dark)
    private static let lavenderMist = adaptive(
        light: (0.93, 0.90, 0.97),   // #EDE6F8 — lavender field
        dark:  (0.10, 0.08, 0.16)    // #1A1429 — midnight violet
    )
    /// Wisteria: slightly deeper lavender (light) / warmer midnight (dark)
    private static let wisteria = adaptive(
        light: (0.88, 0.84, 0.94),   // #E0D7F0 — wisteria petals
        dark:  (0.13, 0.11, 0.20)    // #211C33 — twilight
    )
    /// Soft iris: tertiary surface
    private static let softIris = adaptive(
        light: (0.90, 0.87, 0.95),   // #E6DEF2 — iris bloom
        dark:  (0.12, 0.10, 0.18)    // #1E192E — deep dusk
    )
    /// Card background
    private static let cardBg = adaptive(
        light: (0.95, 0.93, 0.98),   // #F2EDFA — lightest lavender
        dark:  (0.12, 0.10, 0.18)    // #1E192E
    )

    // MARK: - Text Palette

    /// Deep purple ink (light) / silver-lavender (dark)
    private static let purpleInk = adaptive(
        light: (0.18, 0.12, 0.28),   // #2E1F47 — deep purple
        dark:  (0.85, 0.82, 0.92)    // #D9D1EB — silver lavender
    )
    /// Secondary text
    private static let secondaryText = adaptive(
        light: (0.40, 0.34, 0.52),   // #665785
        dark:  (0.68, 0.63, 0.78)    // #ADA1C7
    )
    /// Tertiary text
    private static let tertiaryText = adaptive(
        light: (0.55, 0.50, 0.65),   // #8C80A6
        dark:  (0.50, 0.46, 0.60)    // #807599
    )

    // MARK: - Accent Palette

    /// Amethyst: primary accent
    private static let amethyst = adaptive(
        light: (0.55, 0.28, 0.70),   // #8C47B3 — rich amethyst
        dark:  (0.70, 0.45, 0.85)    // #B373D9 — bright amethyst
    )
    /// Royal gold: secondary accent
    private static let royalGold = adaptive(
        light: (0.72, 0.62, 0.20),   // #B89E33 — muted royal gold
        dark:  (0.85, 0.75, 0.35)    // #D9BF59 — brighter gold
    )
    /// Dusty rose: tertiary accent
    private static let dustyRose = adaptive(
        light: (0.68, 0.40, 0.52),   // #AD6685
        dark:  (0.80, 0.55, 0.65)    // #CC8CA6
    )

    // MARK: - Tag Palette

    /// Soft violet tag background
    private static let tagVioletBg = adaptive(
        light: (0.82, 0.75, 0.92),   // #D1C0EB — pale violet
        dark:  (0.20, 0.16, 0.30)    // #33294D — deep violet
    )
    /// Tag text: vivid purple
    private static let tagVioletText = adaptive(
        light: (0.42, 0.22, 0.58),   // #6B3894
        dark:  (0.78, 0.62, 0.92)    // #C79EEB — bright lilac
    )

    // MARK: - Semantic State Colors

    /// Crimson for destructive actions
    private static let crimson = adaptive(
        light: (0.70, 0.12, 0.18),   // #B31F2E
        dark:  (0.88, 0.32, 0.38)    // #E05261
    )
    /// Emerald for success states
    private static let emerald = adaptive(
        light: (0.15, 0.52, 0.35),   // #268559
        dark:  (0.30, 0.72, 0.52)    // #4DB885
    )

    // MARK: - Chrome Palette

    /// Silver border
    private static let silverBorder = adaptive(
        light: (0.72, 0.68, 0.80),   // #B8ADCC
        dark:  (0.28, 0.25, 0.38)    // #474061
    )
    /// Silver divider
    private static let silverDivider = adaptive(
        light: (0.76, 0.72, 0.84),   // #C2B8D6
        dark:  (0.22, 0.20, 0.32)    // #383352
    )
    /// Deep shadow
    private static let deepShadow = adaptive(
        light: (0.15, 0.10, 0.25),   // #261A40
        dark:  (0.0, 0.0, 0.0)
    )
    /// Highlight hairline
    private static let silverHighlight = adaptive(
        light: (0.96, 0.94, 1.0),    // #F5F0FF — near-white lilac
        dark:  (0.30, 0.26, 0.42)    // #4D426B — muted purple highlight
    )

    // MARK: - Tokens

    let colors = ThemeColors(
        surfacePrimary: .solid(lavenderMist),
        surfaceSecondary: .solid(wisteria),
        surfaceTertiary: .solid(softIris),
        surfaceGlass: .solid(lavenderMist),
        surfaceGlassProminent: .solid(wisteria),
        accentPrimary: amethyst,
        accentSecondary: royalGold,
        accentTertiary: dustyRose,
        textPrimary: purpleInk,
        textSecondary: secondaryText,
        textTertiary: tertiaryText,
        tagBackground: tagVioletBg,
        tagText: tagVioletText,
        destructive: crimson,
        success: emerald,
        border: silverBorder,
        shadow: deepShadow,
        divider: silverDivider,
        cardBackground: cardBg,
        highlightHairline: silverHighlight,
        highlightHairlineDarkOpacity: 0.22,
        highlightHairlineLightOpacity: 0.35
    )

    let fonts = ThemeFonts(
        largeTitle: .system(.largeTitle, design: .rounded),
        headline: .system(.headline, design: .rounded),
        subheadline: .system(.subheadline, design: .rounded),
        body: .system(.body, design: .default),
        caption: .system(.caption, design: .default),
        footnote: .system(.footnote, design: .default)
    )

    let shapes = ThemeShapes(
        cardCornerRadius: 14,
        buttonCornerRadius: 10,
        panelCornerRadius: 14,
        toolbarCornerRadius: 14,
        thumbnailCornerRadius: 8
    )

    let shadows = ThemeShadows(
        cardColor: deepShadow,
        cardDarkOpacity: 0.40,
        cardLightOpacity: 0.12,
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
        buttonPaddingVertical: 7,
        buttonPaddingHorizontal: 10
    )

    let backgroundImages = ThemeBackgroundImages.none
}
