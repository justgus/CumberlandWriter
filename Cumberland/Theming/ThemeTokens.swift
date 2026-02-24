//
//  ThemeTokens.swift
//  Cumberland
//
//  ER-0037: Theming System — Whimsical Skin
//
//  Semantic design token structs that define a theme's visual vocabulary.
//  Each token category (colors, fonts, shapes, shadows, spacing) provides
//  named values that views consume instead of hardcoded literals.
//

import SwiftUI

// MARK: - SurfaceFill

/// Describes how a surface should be filled — material (translucent),
/// solid color, or color with texture overlay.
enum SurfaceFill {
    /// Translucent blur material (e.g., `.ultraThinMaterial`, `.thinMaterial`).
    /// Required on visionOS for spatial depth perception.
    case material(Material)

    /// Opaque solid color fill.
    case solid(Color)

    /// Solid color with optional named texture image overlay (future use).
    case textured(Color, String?)

    /// Returns a material-safe variant. If the fill is not a material,
    /// falls back to `.ultraThinMaterial` — used on visionOS where
    /// solid/textured fills break spatial depth perception.
    func visionOSSafe() -> SurfaceFill {
        switch self {
        case .material:
            return self
        case .solid, .textured:
            return .material(.ultraThinMaterial)
        }
    }
}

// MARK: - SurfaceFill View helpers

extension SurfaceFill {
    /// Applies this fill as a background to a `RoundedRectangle` shape.
    @ViewBuilder
    func asBackground(cornerRadius: CGFloat = 0, style: RoundedCornerStyle = .continuous) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: style)
        switch self {
        case .material(let m):
            shape.fill(m)
        case .solid(let c):
            shape.fill(c)
        case .textured(let c, _):
            // Future: overlay a named texture image
            shape.fill(c)
        }
    }

    /// Returns the fill resolved for the current platform.
    /// On visionOS, non-material fills are promoted to materials.
    var platformResolved: SurfaceFill {
        #if os(visionOS)
        return visionOSSafe()
        #else
        return self
        #endif
    }

    /// Returns an `AnyShapeStyle` suitable for `.toolbarBackground()`.
    var toolbarShapeStyle: AnyShapeStyle {
        switch self {
        case .material(let m):
            return AnyShapeStyle(m)
        case .solid(let c):
            return AnyShapeStyle(c)
        case .textured(let c, _):
            return AnyShapeStyle(c)
        }
    }
}

// MARK: - ThemeColors

/// Semantic color tokens for a theme.
struct ThemeColors {
    /// Primary surface fill (main window backgrounds, sidebars).
    let surfacePrimary: SurfaceFill

    /// Secondary surface fill (cards, panels, inspectors).
    let surfaceSecondary: SurfaceFill

    /// Glass overlay fill (toolbars, floating containers, overlays).
    let surfaceGlass: SurfaceFill

    /// Prominent glass fill (heavier translucency for emphasis).
    let surfaceGlassProminent: SurfaceFill

    /// Primary accent color.
    let accentPrimary: Color

    /// Secondary accent color.
    let accentSecondary: Color

    /// Primary text color.
    let textPrimary: Color

    /// Secondary text color.
    let textSecondary: Color

    /// Tertiary text color.
    let textTertiary: Color

    /// Border/stroke color for card edges, separators.
    let border: Color

    /// Shadow color.
    let shadow: Color

    /// Divider line color.
    let divider: Color

    /// Card body background color (opaque fill behind card content).
    let cardBackground: Color

    /// Highlight hairline color (inner stroke on glass surfaces).
    let highlightHairline: Color

    /// Highlight hairline opacity for dark mode.
    let highlightHairlineDarkOpacity: CGFloat

    /// Highlight hairline opacity for light mode.
    let highlightHairlineLightOpacity: CGFloat
}

// MARK: - ThemeFonts

/// Semantic font tokens for a theme.
struct ThemeFonts {
    let largeTitle: Font
    let headline: Font
    let subheadline: Font
    let body: Font
    let caption: Font
    let footnote: Font
}

// MARK: - ThemeShapes

/// Semantic shape tokens for a theme.
struct ThemeShapes {
    /// Corner radius for card containers.
    let cardCornerRadius: CGFloat

    /// Corner radius for buttons and small interactive elements.
    let buttonCornerRadius: CGFloat

    /// Corner radius for panels, inspectors, popovers.
    let panelCornerRadius: CGFloat

    /// Corner radius for toolbars and floating bars.
    let toolbarCornerRadius: CGFloat

    /// Corner radius for thumbnail images within cards.
    let thumbnailCornerRadius: CGFloat
}

// MARK: - ThemeShadows

/// Semantic shadow tokens for a theme.
struct ThemeShadows {
    /// Card shadow color.
    let cardColor: Color

    /// Card shadow color opacity in dark mode.
    let cardDarkOpacity: CGFloat

    /// Card shadow color opacity in light mode.
    let cardLightOpacity: CGFloat

    /// Card shadow blur radius.
    let cardRadius: CGFloat

    /// Card shadow x offset.
    let cardX: CGFloat

    /// Card shadow y offset.
    let cardY: CGFloat

    /// Interactive/hover shadow radius addition.
    let hoverRadiusBoost: CGFloat

    /// Interactive/hover shadow y offset addition.
    let hoverYBoost: CGFloat
}

// MARK: - ThemeSpacing

/// Semantic spacing tokens for a theme.
struct ThemeSpacing {
    /// Inner padding for card content.
    let cardPadding: CGFloat

    /// Spacing between sections in a form or list.
    let sectionSpacing: CGFloat

    /// Spacing between rows in a list.
    let listRowSpacing: CGFloat

    /// Standard button padding (vertical).
    let buttonPaddingVertical: CGFloat

    /// Standard button padding (horizontal).
    let buttonPaddingHorizontal: CGFloat
}
