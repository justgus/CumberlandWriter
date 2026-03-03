//
//  UserTheme.swift
//  Cumberland
//
//  ER-0037 Phase 2, Step 5: User-Defined Theme Support
//
//  A Codable theme loaded from a `.cumberlandtheme` JSON file.
//  All color fields use light/dark hex pairs. Missing or invalid
//  fields fall back to DefaultTheme values so partial themes are safe.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - UTType Registration

extension UTType {
    /// Cumberland theme file type (`.cumberlandtheme`).
    static let cumberlandTheme = UTType(
        exportedAs: "com.cumberland.theme",
        conformingTo: .json
    )
}

// MARK: - UserTheme

/// A user-defined theme decoded from a `.cumberlandtheme` JSON file.
///
/// JSON structure:
/// ```json
/// {
///   "id": "my-custom-theme",
///   "displayName": "My Theme",
///   "colors": {
///     "surfacePrimary": { "light": "#F5E6C8", "dark": "#1E1914" },
///     "accentPrimary": { "light": "#8B4513", "dark": "#B87333" },
///     ...
///   },
///   "fonts": { "design": "serif" },
///   "shapes": { "cardCornerRadius": 16 },
///   "shadows": { "cardRadius": 10 },
///   "spacing": { "cardPadding": 14 }
/// }
/// ```
struct UserTheme: Theme {
    let id: String
    let displayName: String
    let colors: ThemeColors
    let fonts: ThemeFonts
    let shapes: ThemeShapes
    let shadows: ThemeShadows
    let spacing: ThemeSpacing
    let backgroundImages: ThemeBackgroundImages

    /// Whether this theme was loaded from a user file (vs built-in).
    let isUserDefined: Bool = true
}

// MARK: - JSON Schema Types

/// A pair of hex colors for light and dark mode.
struct ColorPairJSON: Codable {
    let light: String
    let dark: String
}

/// Surface fill specification in JSON.
struct SurfaceFillJSON: Codable {
    /// Fill type: "material", "solid", or "textured"
    let type: String?
    /// Hex color pair for solid/textured fills.
    let color: ColorPairJSON?
    /// Material name for material fills: "ultraThin", "thin", "regular", "thick", "ultraThick"
    let material: String?
    /// Asset name for textured fills.
    let texture: String?
}

/// Complete JSON schema for a `.cumberlandtheme` file.
struct ThemeJSON: Codable {
    let id: String
    let displayName: String
    let colors: ColorsJSON?
    let fonts: FontsJSON?
    let shapes: ShapesJSON?
    let shadows: ShadowsJSON?
    let spacing: SpacingJSON?
    let backgroundImages: BackgroundImagesJSON?
}

struct ColorsJSON: Codable {
    var surfacePrimary: SurfaceFillJSON?
    var surfaceSecondary: SurfaceFillJSON?
    var surfaceTertiary: SurfaceFillJSON?
    var surfaceGlass: SurfaceFillJSON?
    var surfaceGlassProminent: SurfaceFillJSON?
    var accentPrimary: ColorPairJSON?
    var accentSecondary: ColorPairJSON?
    var accentTertiary: ColorPairJSON?
    var textPrimary: ColorPairJSON?
    var textSecondary: ColorPairJSON?
    var textTertiary: ColorPairJSON?
    var tagBackground: ColorPairJSON?
    var tagText: ColorPairJSON?
    var destructive: ColorPairJSON?
    var success: ColorPairJSON?
    var border: ColorPairJSON?
    var shadow: ColorPairJSON?
    var divider: ColorPairJSON?
    var cardBackground: ColorPairJSON?
    var highlightHairline: ColorPairJSON?
    var highlightHairlineDarkOpacity: CGFloat?
    var highlightHairlineLightOpacity: CGFloat?
}

struct FontsJSON: Codable {
    /// Font design: "default", "serif", "rounded", "monospaced"
    var design: String?
}

struct ShapesJSON: Codable {
    var cardCornerRadius: CGFloat?
    var buttonCornerRadius: CGFloat?
    var panelCornerRadius: CGFloat?
    var toolbarCornerRadius: CGFloat?
    var thumbnailCornerRadius: CGFloat?
}

struct ShadowsJSON: Codable {
    var cardDarkOpacity: CGFloat?
    var cardLightOpacity: CGFloat?
    var cardRadius: CGFloat?
    var cardX: CGFloat?
    var cardY: CGFloat?
    var hoverRadiusBoost: CGFloat?
    var hoverYBoost: CGFloat?
}

struct SpacingJSON: Codable {
    var cardPadding: CGFloat?
    var sectionSpacing: CGFloat?
    var listRowSpacing: CGFloat?
    var buttonPaddingVertical: CGFloat?
    var buttonPaddingHorizontal: CGFloat?
}

struct BackgroundImagesJSON: Codable {
    var sidebarBackground: String?
    var contentBackground: String?
    var murderboardCanvas: String?
    var structureBoardCanvas: String?
    var wizardHero: String?
    var emptyState: String?
    var detailPlaceholder: String?
}

// MARK: - Decoding

extension UserTheme {
    /// Decode a `UserTheme` from JSON data, falling back to `DefaultTheme` for any missing fields.
    static func decode(from data: Data) throws -> UserTheme {
        let decoder = JSONDecoder()
        let json = try decoder.decode(ThemeJSON.self, from: data)
        let fallback = DefaultTheme()

        let colors = ThemeColors(
            surfacePrimary: json.colors?.surfacePrimary?.toSurfaceFill() ?? fallback.colors.surfacePrimary,
            surfaceSecondary: json.colors?.surfaceSecondary?.toSurfaceFill() ?? fallback.colors.surfaceSecondary,
            surfaceTertiary: json.colors?.surfaceTertiary?.toSurfaceFill() ?? fallback.colors.surfaceTertiary,
            surfaceGlass: json.colors?.surfaceGlass?.toSurfaceFill() ?? fallback.colors.surfaceGlass,
            surfaceGlassProminent: json.colors?.surfaceGlassProminent?.toSurfaceFill() ?? fallback.colors.surfaceGlassProminent,
            accentPrimary: json.colors?.accentPrimary?.toColor() ?? fallback.colors.accentPrimary,
            accentSecondary: json.colors?.accentSecondary?.toColor() ?? fallback.colors.accentSecondary,
            accentTertiary: json.colors?.accentTertiary?.toColor() ?? fallback.colors.accentTertiary,
            textPrimary: json.colors?.textPrimary?.toColor() ?? fallback.colors.textPrimary,
            textSecondary: json.colors?.textSecondary?.toColor() ?? fallback.colors.textSecondary,
            textTertiary: json.colors?.textTertiary?.toColor() ?? fallback.colors.textTertiary,
            tagBackground: json.colors?.tagBackground?.toColor() ?? fallback.colors.tagBackground,
            tagText: json.colors?.tagText?.toColor() ?? fallback.colors.tagText,
            destructive: json.colors?.destructive?.toColor() ?? fallback.colors.destructive,
            success: json.colors?.success?.toColor() ?? fallback.colors.success,
            border: json.colors?.border?.toColor() ?? fallback.colors.border,
            shadow: json.colors?.shadow?.toColor() ?? fallback.colors.shadow,
            divider: json.colors?.divider?.toColor() ?? fallback.colors.divider,
            cardBackground: json.colors?.cardBackground?.toColor() ?? fallback.colors.cardBackground,
            highlightHairline: json.colors?.highlightHairline?.toColor() ?? fallback.colors.highlightHairline,
            highlightHairlineDarkOpacity: json.colors?.highlightHairlineDarkOpacity ?? fallback.colors.highlightHairlineDarkOpacity,
            highlightHairlineLightOpacity: json.colors?.highlightHairlineLightOpacity ?? fallback.colors.highlightHairlineLightOpacity
        )

        let fontDesign = json.fonts?.design?.toFontDesign() ?? Font.Design.default
        let fonts = ThemeFonts(
            largeTitle: .system(.largeTitle, design: fontDesign),
            headline: .system(.headline, design: fontDesign),
            subheadline: .system(.subheadline, design: fontDesign),
            body: .system(.body, design: fontDesign),
            caption: .system(.caption, design: fontDesign),
            footnote: .system(.footnote, design: fontDesign)
        )

        let shapes = ThemeShapes(
            cardCornerRadius: json.shapes?.cardCornerRadius ?? fallback.shapes.cardCornerRadius,
            buttonCornerRadius: json.shapes?.buttonCornerRadius ?? fallback.shapes.buttonCornerRadius,
            panelCornerRadius: json.shapes?.panelCornerRadius ?? fallback.shapes.panelCornerRadius,
            toolbarCornerRadius: json.shapes?.toolbarCornerRadius ?? fallback.shapes.toolbarCornerRadius,
            thumbnailCornerRadius: json.shapes?.thumbnailCornerRadius ?? fallback.shapes.thumbnailCornerRadius
        )

        let shadows = ThemeShadows(
            cardColor: json.colors?.shadow?.toColor() ?? fallback.shadows.cardColor,
            cardDarkOpacity: json.shadows?.cardDarkOpacity ?? fallback.shadows.cardDarkOpacity,
            cardLightOpacity: json.shadows?.cardLightOpacity ?? fallback.shadows.cardLightOpacity,
            cardRadius: json.shadows?.cardRadius ?? fallback.shadows.cardRadius,
            cardX: json.shadows?.cardX ?? fallback.shadows.cardX,
            cardY: json.shadows?.cardY ?? fallback.shadows.cardY,
            hoverRadiusBoost: json.shadows?.hoverRadiusBoost ?? fallback.shadows.hoverRadiusBoost,
            hoverYBoost: json.shadows?.hoverYBoost ?? fallback.shadows.hoverYBoost
        )

        let spacing = ThemeSpacing(
            cardPadding: json.spacing?.cardPadding ?? fallback.spacing.cardPadding,
            sectionSpacing: json.spacing?.sectionSpacing ?? fallback.spacing.sectionSpacing,
            listRowSpacing: json.spacing?.listRowSpacing ?? fallback.spacing.listRowSpacing,
            buttonPaddingVertical: json.spacing?.buttonPaddingVertical ?? fallback.spacing.buttonPaddingVertical,
            buttonPaddingHorizontal: json.spacing?.buttonPaddingHorizontal ?? fallback.spacing.buttonPaddingHorizontal
        )

        let bgImages = ThemeBackgroundImages(
            sidebarBackground: json.backgroundImages?.sidebarBackground,
            contentBackground: json.backgroundImages?.contentBackground,
            murderboardCanvas: json.backgroundImages?.murderboardCanvas,
            structureBoardCanvas: json.backgroundImages?.structureBoardCanvas,
            wizardHero: json.backgroundImages?.wizardHero,
            emptyState: json.backgroundImages?.emptyState,
            detailPlaceholder: json.backgroundImages?.detailPlaceholder
        )

        return UserTheme(
            id: json.id,
            displayName: json.displayName,
            colors: colors,
            fonts: fonts,
            shapes: shapes,
            shadows: shadows,
            spacing: spacing,
            backgroundImages: bgImages
        )
    }
}

// MARK: - Export

extension UserTheme {
    /// Export a built-in theme as a `.cumberlandtheme` JSON for sharing/editing.
    static func exportJSON(from theme: any Theme) throws -> Data {
        // We can only export color values from themes that use solid fills.
        // Material-based themes (DefaultTheme) export as gray placeholders.
        let json = ThemeJSON(
            id: theme.id + "-custom",
            displayName: theme.displayName + " (Custom)",
            colors: ColorsJSON(
                surfacePrimary: theme.colors.surfacePrimary.toJSON(),
                surfaceSecondary: theme.colors.surfaceSecondary.toJSON(),
                surfaceTertiary: theme.colors.surfaceTertiary.toJSON(),
                surfaceGlass: theme.colors.surfaceGlass.toJSON(),
                surfaceGlassProminent: theme.colors.surfaceGlassProminent.toJSON(),
                accentPrimary: theme.colors.accentPrimary.toHexPair(),
                accentSecondary: theme.colors.accentSecondary.toHexPair(),
                accentTertiary: theme.colors.accentTertiary.toHexPair(),
                textPrimary: theme.colors.textPrimary.toHexPair(),
                textSecondary: theme.colors.textSecondary.toHexPair(),
                textTertiary: theme.colors.textTertiary.toHexPair(),
                tagBackground: theme.colors.tagBackground.toHexPair(),
                tagText: theme.colors.tagText.toHexPair(),
                destructive: theme.colors.destructive.toHexPair(),
                success: theme.colors.success.toHexPair(),
                border: theme.colors.border.toHexPair(),
                shadow: theme.colors.shadow.toHexPair(),
                divider: theme.colors.divider.toHexPair(),
                cardBackground: theme.colors.cardBackground.toHexPair(),
                highlightHairline: theme.colors.highlightHairline.toHexPair(),
                highlightHairlineDarkOpacity: theme.colors.highlightHairlineDarkOpacity,
                highlightHairlineLightOpacity: theme.colors.highlightHairlineLightOpacity
            ),
            fonts: FontsJSON(design: "default"),
            shapes: ShapesJSON(
                cardCornerRadius: theme.shapes.cardCornerRadius,
                buttonCornerRadius: theme.shapes.buttonCornerRadius,
                panelCornerRadius: theme.shapes.panelCornerRadius,
                toolbarCornerRadius: theme.shapes.toolbarCornerRadius,
                thumbnailCornerRadius: theme.shapes.thumbnailCornerRadius
            ),
            shadows: ShadowsJSON(
                cardDarkOpacity: theme.shadows.cardDarkOpacity,
                cardLightOpacity: theme.shadows.cardLightOpacity,
                cardRadius: theme.shadows.cardRadius,
                cardX: theme.shadows.cardX,
                cardY: theme.shadows.cardY,
                hoverRadiusBoost: theme.shadows.hoverRadiusBoost,
                hoverYBoost: theme.shadows.hoverYBoost
            ),
            spacing: SpacingJSON(
                cardPadding: theme.spacing.cardPadding,
                sectionSpacing: theme.spacing.sectionSpacing,
                listRowSpacing: theme.spacing.listRowSpacing,
                buttonPaddingVertical: theme.spacing.buttonPaddingVertical,
                buttonPaddingHorizontal: theme.spacing.buttonPaddingHorizontal
            ),
            backgroundImages: nil
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(json)
    }
}

// MARK: - Hex Conversion Helpers

private extension ColorPairJSON {
    /// Convert a light/dark hex pair to a platform-adaptive SwiftUI Color.
    func toColor() -> Color {
        let lightColor = Color(hex: light)
        let darkColor = Color(hex: dark)

        #if os(macOS)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? NSColor(darkColor) : NSColor(lightColor)
        }))
        #else
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(darkColor) : UIColor(lightColor)
        })
        #endif
    }
}

private extension SurfaceFillJSON {
    func toSurfaceFill() -> SurfaceFill {
        switch type {
        case "material":
            let m: Material
            switch material {
            case "thin": m = .thinMaterial
            case "regular": m = .regularMaterial
            case "thick": m = .thickMaterial
            case "ultraThick": m = .ultraThickMaterial
            default: m = .ultraThinMaterial
            }
            return .material(m)
        case "textured":
            if let pair = color {
                return .textured(pair.toColor(), texture)
            }
            return .solid(.gray)
        default: // "solid" or unknown
            if let pair = color {
                return .solid(pair.toColor())
            }
            return .solid(.gray)
        }
    }
}

private extension SurfaceFill {
    func toJSON() -> SurfaceFillJSON {
        switch self {
        case .material(let m):
            let name: String
            // We can't directly introspect Material, use a generic name
            _ = m
            name = "ultraThin"
            return SurfaceFillJSON(type: "material", color: nil, material: name, texture: nil)
        case .solid(let c):
            return SurfaceFillJSON(type: "solid", color: c.toHexPair(), material: nil, texture: nil)
        case .textured(let c, let tex):
            return SurfaceFillJSON(type: "textured", color: c.toHexPair(), material: nil, texture: tex)
        }
    }
}

private extension String {
    func toFontDesign() -> Font.Design {
        switch self {
        case "serif": return .serif
        case "rounded": return .rounded
        case "monospaced": return .monospaced
        default: return .default
        }
    }
}

// MARK: - Color ↔ Hex

extension Color {
    /// Convert to a hex pair for export. Returns the resolved color in both
    /// a generic light and dark context. Falls back to gray if resolution fails.
    func toHexPair() -> ColorPairJSON {
        // Resolve the dynamic color in both light and dark appearance
        // contexts so the exported JSON contains distinct values.
        #if os(macOS)
        let nsColor = NSColor(self)

        let lightAppearance = NSAppearance(named: .aqua)!
        let darkAppearance = NSAppearance(named: .darkAqua)!

        let light = Self.resolveHex(nsColor, appearance: lightAppearance)
        let dark = Self.resolveHex(nsColor, appearance: darkAppearance)
        #else
        let uiColor = UIColor(self)

        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let darkTraits = UITraitCollection(userInterfaceStyle: .dark)

        let light = Self.resolveHex(uiColor, traits: lightTraits)
        let dark = Self.resolveHex(uiColor, traits: darkTraits)
        #endif
        return ColorPairJSON(light: light, dark: dark)
    }

    #if os(macOS)
    private static func resolveHex(_ nsColor: NSColor, appearance: NSAppearance) -> String {
        var resolved: NSColor?
        appearance.performAsCurrentDrawingAppearance {
            resolved = nsColor.usingColorSpace(.sRGB)
        }
        guard let c = resolved else { return "#808080" }
        return String(format: "#%02X%02X%02X",
            Int(c.redComponent * 255), Int(c.greenComponent * 255), Int(c.blueComponent * 255))
    }
    #else
    private static func resolveHex(_ uiColor: UIColor, traits: UITraitCollection) -> String {
        let resolved = uiColor.resolvedColor(with: traits)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    #endif
}
