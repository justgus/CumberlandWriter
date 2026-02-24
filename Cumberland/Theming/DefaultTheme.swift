//
//  DefaultTheme.swift
//  Cumberland
//
//  ER-0037: Theming System — Whimsical Skin
//
//  The default theme that exactly matches the current app appearance.
//  All token values are derived from the existing hardcoded values in
//  GlassKit.swift, GlassEffects.swift, CardView.swift, etc. Applying
//  this theme produces zero visual regression.
//

import SwiftUI

/// The default Cumberland theme — matches the existing visual appearance exactly.
struct DefaultTheme: Theme {

    /// System background color that adapts to light/dark mode.
    #if os(macOS)
    private static let systemCardBackground = Color(nsColor: .windowBackgroundColor)
    #elseif os(visionOS)
    private static let systemCardBackground = Color.white
    #else
    private static let systemCardBackground = Color(uiColor: .systemBackground)
    #endif
    let id = "default"
    let displayName = String(localized: "Default")

    let colors = ThemeColors(
        // Matches GlassSurfaceModifier background in GlassKit.swift:86
        surfacePrimary: .material(.ultraThinMaterial),
        // Matches GlassCard / GlassEffectContainer background (.thinMaterial)
        surfaceSecondary: .material(.thinMaterial),
        // Matches GlassButtonModifier non-prominent (.ultraThinMaterial)
        surfaceGlass: .material(.ultraThinMaterial),
        // Matches GlassButtonModifier prominent (.thinMaterial)
        surfaceGlassProminent: .material(.thinMaterial),
        // System accent
        accentPrimary: .accentColor,
        accentSecondary: .accentColor.opacity(0.7),
        // System text colors
        textPrimary: .primary,
        textSecondary: .secondary,
        textTertiary: .secondary.opacity(0.7),
        // Matches .quaternary.opacity(0.6) used for outer keylines
        border: Color.secondary.opacity(0.3),
        // Matches .black.opacity() shadow used throughout Glass files
        shadow: .black,
        // System separator
        divider: Color.secondary.opacity(0.4),
        // System background (matches CardView .fill(.background))
        cardBackground: DefaultTheme.systemCardBackground,
        // Matches GlassKit inner highlight hairline (.white)
        highlightHairline: .white,
        highlightHairlineDarkOpacity: 0.20,
        highlightHairlineLightOpacity: 0.30
    )

    let fonts = ThemeFonts(
        largeTitle: .largeTitle,
        headline: .headline,
        subheadline: .subheadline,
        body: .body,
        caption: .caption,
        footnote: .footnote
    )

    let shapes = ThemeShapes(
        // Matches CardView cardShape cornerRadius: 12
        cardCornerRadius: 12,
        // Matches GlassButtonModifier default cornerRadius: 8
        buttonCornerRadius: 8,
        // Matches glassSurfaceStyle default cornerRadius: 12
        panelCornerRadius: 12,
        // Matches GlassToolbarStyle default cornerRadius: 14
        toolbarCornerRadius: 14,
        // Matches CardView thumbnail clip cornerRadius: 8
        thumbnailCornerRadius: 8
    )

    let shadows = ThemeShadows(
        // Matches GlassKit shadow: .black.opacity(dark ? 0.28 : 0.10)
        cardColor: .black,
        cardDarkOpacity: 0.28,
        cardLightOpacity: 0.10,
        cardRadius: 8,
        cardX: 0,
        cardY: 4,
        hoverRadiusBoost: 2,
        hoverYBoost: 2
    )

    let spacing = ThemeSpacing(
        // Matches GlassCard content padding(12)
        cardPadding: 12,
        // Matches GlassFormSection VStack spacing: 8
        sectionSpacing: 8,
        // Standard list row spacing
        listRowSpacing: 8,
        // Matches GlassButtonModifier padding: 6
        buttonPaddingVertical: 6,
        // Matches GlassButtonModifier padding: 8
        buttonPaddingHorizontal: 8
    )
}

