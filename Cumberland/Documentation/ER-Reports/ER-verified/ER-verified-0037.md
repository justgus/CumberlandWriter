# ER-0037: Theming System — Multi-Color Themes, Background Images & User-Defined Themes

**Status:** ✅ Implemented - Verified
**Component:** UI / Theming Infrastructure
**Priority:** High
**Date Requested:** 2026-02-22
**Date Implemented:** 2026-02-23 (Phase 1), 2026-03-03 (Phases 2 & 3)
**Date Verified:** 2026-03-03

**Rationale:**
Cumberland's theming system needs to go beyond single-color skins. Each theme should leverage its full color palette — Whimsical should feel warm and layered with many earthy tones, a Purple theme should showcase rich violets and lavenders, a Halloween theme should use bold contrasts of black, bone-white, and pumpkin orange. Users should also be able to create their own themes via an importable JSON specification. Additionally, themed background images (PNG textures) applied to key surfaces — sidebar, card list, Murderboard canvas, etc. — add visual depth that solid colors alone cannot achieve.

**Current Behavior (before implementation):**
No theming system existed. All colors were hardcoded throughout the app using system defaults.

**Desired Behavior:**
A rich theming system where:
- Each built-in theme uses its full multi-color palette across an expanded set of semantic tokens
- Background images (PNG textures) can be applied to major app surfaces
- Users can create, import, and export custom themes via `.cumberlandtheme` JSON files
- Multiple distinctive built-in themes ship with v1.0 (Default, Whimsical, Purple, Halloween)

---

## Phase 1: Theme Infrastructure (Verified 2026-03-03)

- `Theme` protocol, `ThemeTokens` (semantic design tokens: colors, fonts, shapes, shadows, spacing)
- `SurfaceFill` enum (`.material`, `.solid`, `.textured`)
- `ThemeManager` (@Observable with @AppStorage persistence)
- `ThemeEnvironment` (EnvironmentKey injection)
- Glass system integration — all 6 Glass files theme-aware
- `WhimsicalTheme` definition — parchment/leather/ink palette; serif fonts; warm shadows
- Theme picker in Settings > Display
- CardView themed — fonts, colors, corner radii, shadows
- visionOS safety via `SurfaceFill.platformResolved`
- Zero regression: `DefaultTheme` matches pre-existing hardcoded values exactly

**Phase 1 Files Created:**
- `Theming/ThemeTokens.swift` — SurfaceFill enum + ThemeColors/Fonts/Shapes/Shadows/Spacing structs
- `Theming/Theme.swift` — Theme protocol
- `Theming/DefaultTheme.swift` — System-matching defaults
- `Theming/ThemeManager.swift` — @Observable theme management with @AppStorage
- `Theming/ThemeEnvironment.swift` — EnvironmentKey injection + `.themeEnvironment()` modifier
- `Theming/WhimsicalTheme.swift` — Warm parchment aesthetic

**Phase 1 Files Modified:**
- `CumberlandApp.swift` — ThemeManager @State property, `.themeEnvironment()` on all user-facing WindowGroups
- `GlassKit.swift` — GlassButtonModifier, GlassSurfaceModifier, GlassEffectContainer, GlassFormSection all theme-aware
- `GlassEffects.swift` — GlassButtonStyle theme-aware
- `GlassSurfaceStyle.swift` — Theme-aware surface fills with visionOS material preservation
- `GlassToolbarStyle.swift` — Theme-aware toolbar backgrounds
- `GlassDropZone.swift` — Theme-aware highlight colors, fonts
- `Components/GlassCard.swift` — Theme-aware surface, borders, shadows, spacing
- `SettingsView.swift` — Theme picker section in DisplaySettingsPane
- `CardView.swift` — Theme-aware fonts, colors, corner radii, shadows

---

## Phase 2: Multi-Color Palettes & Background Images (Verified 2026-03-03)

**Implemented:**
1. Expanded ThemeColors token set: `accentTertiary`, `surfaceTertiary`, `tagBackground`, `tagText`, `destructive`, `success`
2. `ThemeBackgroundImages` struct with 7 surface slots
3. `SurfaceFill.textured` fully implemented
4. `ThemeBackgroundView` modifier for tiled/stretched image overlays
5. Background images wired into 7 target surfaces
6. PurpleTheme ("Purple Reign") — amethyst, lavender, royal gold, dusty rose
7. HalloweenTheme — charcoal, bone-white, pumpkin orange, blood red, witch purple
8. WhimsicalTheme overhauled to pastel multi-color (rose cream, lavender mist, pastel teal/coral/gold, Cochin serif font)
9. Procedural texture assets: whimsical-parchment, whimsical-cork, purple-damask, halloween-cobweb
10. Sidebar text/icon theming with explicit foregroundStyle on Label subviews

**Phase 2 Files Created:**
- `Theming/PurpleTheme.swift`
- `Theming/HalloweenTheme.swift`
- `Theming/ThemeBackgroundView.swift`
- `Assets.xcassets/ThemeAssets/` — 4 procedural texture imagesets

**Phase 2 Files Modified:**
- `Theming/ThemeTokens.swift` — 6 new color tokens + ThemeBackgroundImages struct + SurfaceFill.textured
- `Theming/Theme.swift` — Added `backgroundImages` to protocol
- `Theming/DefaultTheme.swift` — Defaults for all new tokens
- `Theming/WhimsicalTheme.swift` — Complete palette rewrite + Cochin fonts + parchment/cork textures
- `Theming/ThemeManager.swift` — Registers 4 built-in themes
- `MainAppView.swift` — Background images on sidebar/content/empty state, explicit sidebar label theming
- `ContentPlaceholderView.swift` — backgroundImageKeyPath parameter
- `Murderboard/MurderBoardView.swift` — Background image on canvas
- `StructureBoardView.swift` — Background image on board + @EnvironmentObject for ThemeManager
- `MapWizardView.swift` — Background image on wizard landing

---

## Phase 3: User-Defined Themes (Verified 2026-03-03)

**Implemented:**
1. `.cumberlandtheme` JSON schema with `UTType.cumberlandTheme` registered on all 3 platforms
2. `UserTheme` Codable struct conforming to `Theme` protocol with DefaultTheme fallback for all fields
3. `ThemeFileManager` for import/export/persistence in Application Support
4. Import/Export/Duplicate/Delete UI in Settings > Display > Theme
5. Share Sheet integration (iOS) via UIActivityViewController
6. Base64-encoded background image bundling in user theme JSON
7. Image validation: 2 MB max size, 4096x4096 max dimensions
8. Export correctly resolves distinct light/dark hex values via appearance contexts
9. Cached image cleanup on theme deletion
10. `ThemeBackgroundModifier` resolves images from both asset catalog and cached disk

**Phase 3 Files Created:**
- `Theming/UserTheme.swift` — UTType, UserTheme struct, ThemeJSON schema types, Color hex helpers, decode/export
- `Theming/ThemeFileManager.swift` — Singleton for import/export/delete/persistence/image caching

**Phase 3 Files Modified:**
- `Theming/ThemeManager.swift` — User theme support: load from disk, add/remove/duplicate, builtInIDs
- `SettingsView.swift` — Import/Export/Duplicate/Share/Delete buttons, fileImporter/fileExporter, ThemeDocument, error alerts
- `Cumberland/Info.plist` — UTType com.cumberland.theme (UTExportedTypeDeclarations)
- `Cumberland IOS/Info.plist` — Same UTType registration
- `Cumberland_visionOS/Info.plist` — Same UTType registration

---

**Notes:**
- WhimsicalTheme uses Cochin (system-bundled archaic serif font) — no licensing issues
- Current procedural textures are 256x256 1x — suitable for tiling but could benefit from higher-quality hand-crafted replacements
- visionOS ignores background images (materials required for spatial depth perception)
- User theme JSON format is forward-compatible — unknown keys ignored, missing keys use DefaultTheme defaults
- Per-Kind accent colors (`Kinds.accentColor(for:)`) remain unchanged — these are content-semantic, not theme-semantic
