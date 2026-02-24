# Non-visionOS Features — Implementation Plan

**Covers:** ER-0037 (Theming), ER-0039 (Windows), ER-0040 (Linux), ER-0041 (Android)
**Date:** 2026-02-23

---

## Overview

These four ERs cover two distinct categories:
- **ER-0037 (Theming)** — An implementable feature that changes the app's visual presentation across all platforms
- **ER-0039/0040/0041 (Cross-Platform Feasibility)** — Research-only ERs that produce feasibility reports, not code

The theming system is fully independent of the visionOS workspace ERs and the cross-platform research. It can be implemented at any time.

The three cross-platform ERs share significant overlap and should be conducted together as a single research effort.

---

## ER-0037: Theming System — Whimsical Skin

### Dependency
None. Fully independent of all other ERs. Can be implemented before, during, or after the visionOS work.

### Implementation Steps

#### Step 1: Theme Protocol & Infrastructure

1. **`Theme.swift`** — Define the `Theme` protocol with semantic token categories:
   ```
   protocol Theme {
       var colors: ThemeColors { get }
       var fonts: ThemeFonts { get }
       var shapes: ThemeShapes { get }
       var spacing: ThemeSpacing { get }
       var decorations: ThemeDecorations { get }
   }
   ```
   - `ThemeColors`: `cardBackground`, `sidebarBackground`, `accentPrimary`, `textPrimary`, `textSecondary`, `borderColor`, `shadowColor`, etc.
   - `ThemeFonts`: `sectionHeader`, `cardTitle`, `bodyText`, `caption`, `decorativeHeader`, etc.
   - `ThemeShapes`: `cardCornerRadius`, `buttonCornerRadius`, `tabCornerRadius`, etc.
   - `ThemeSpacing`: `cardPadding`, `sectionSpacing`, `listRowSpacing`, etc.
   - `ThemeDecorations`: `dividerStyle`, `emptyStateImage`, `backgroundTexture`, etc.

2. **`ThemeManager.swift`** — `@Observable` class managing active theme:
   - `currentTheme: Theme` (computed from stored preference)
   - `themeName: String` persisted via `@AppStorage("selectedTheme")`
   - `availableThemes: [String: Theme]` registry
   - Method: `setTheme(_:)` — updates preference, triggers UI refresh

3. **`DefaultTheme.swift`** — Conformance that returns system defaults for all tokens
   - Matches current app appearance exactly — no visual regression
   - All token values derived from SwiftUI system colors/fonts

4. **Inject into Environment** — In `CumberlandApp.swift`:
   - Create `ThemeManager` instance
   - Pass via `.environment(\.theme, themeManager.currentTheme)` custom `EnvironmentKey`

#### Step 2: Themed ViewModifiers

1. **`ThemedModifiers.swift`** — Collection of `ViewModifier` structs:
   - `.themedCard()` — applies card background, corner radius, shadow, border from theme
   - `.themedSidebar()` — sidebar background, text styling
   - `.themedButton()` — button style using theme tokens
   - `.themedSectionHeader()` — header font, color, spacing
   - `.themedDivider()` — divider style/color
   - `.themedEmptyState()` — empty state illustration and text styling

2. **Extension on View** — Convenience methods:
   ```swift
   extension View {
       func themedCard() -> some View { modifier(ThemedCardModifier()) }
       func themedSidebar() -> some View { modifier(ThemedSidebarModifier()) }
       // etc.
   }
   ```

#### Step 3: Incremental Adoption

Apply themed modifiers to existing views incrementally. Priority order:

1. **CardView.swift** — `.themedCard()` for card background, border, shadow
2. **MainAppView.swift** — `.themedSidebar()` for sidebar background
3. **SettingsView.swift** — Theme picker UI + themed sections
4. **CardEditorView.swift** — Themed form sections
5. **MurderBoardView.swift** — Themed canvas background, node styling
6. **MapWizardView.swift** — Themed wizard steps
7. **StructureBoardView.swift** — Themed lanes and cards
8. **All remaining views** — Systematic sweep

Each view adoption is a small, testable change. No big-bang rewrite.

#### Step 4: Whimsical Theme

1. **`WhimsicalTheme.swift`** — Conformance with warm, handcrafted aesthetic:
   - Colors: parchment (#F5E6C8), ink (#2C1810), aged paper (#EDE0C8), leather (#8B4513), muted gold (#B8860B)
   - Fonts: script/handwritten for headers (bundled custom font), warm serif for body (bundled or system Georgia)
   - Shapes: softer corner radii (16pt), organic rounded rectangles
   - Spacing: slightly more generous padding for a "breathing room" feel
   - Decorations: subtle parchment texture backgrounds, ornamental dividers, quill-pen empty state illustrations

2. **Asset catalog** — Create `Whimsical.xcassets` or folder within main assets:
   - Parchment texture (tileable)
   - Paper grain overlay
   - Ornamental divider images
   - Empty state illustrations (hand-drawn style)
   - Custom font files (.ttf/.otf) with appropriate licensing

3. **Platform adaptations:**
   - macOS: Textures render at full quality
   - iOS: Slightly simplified textures for performance
   - visionOS: Glass materials may need theme-aware tinting rather than opaque textures

#### Step 5: Settings Integration

1. Add "Appearance" section to `SettingsView.swift` (or expand existing)
2. Theme picker: segmented control or list showing available themes with previews
3. Preview thumbnails for each theme
4. Theme change applies immediately (no restart)

#### Step 6: Verification

1. Build on all 3 platforms
2. Verify DefaultTheme matches current appearance exactly (no regression)
3. Switch to Whimsical — verify all views adopt the new skin
4. Switch back — clean revert
5. Quit/relaunch — theme choice persists
6. Run with VoiceOver — verify accessibility unaffected by theme change

### Risk Areas

- **Font licensing** — Any bundled typeface must be verified for app distribution licensing. Fallback: system Georgia for serif, system Noteworthy for handwritten.
- **visionOS materials** — Glass/material effects may conflict with opaque theme backgrounds. May need conditional logic per platform.
- **Dark mode interaction** — Themes should work in both light and dark system appearance. The Whimsical theme may define its own light/dark variants, or override system appearance entirely.

---

## ER-0039, ER-0040, ER-0041: Cross-Platform Feasibility Research

### Approach

These three ERs are research-only — no code changes to Cumberland. They produce a feasibility report document. Because the cross-platform landscape heavily overlaps (most solutions target 2+ platforms), these should be conducted as a **single research effort** producing one unified report with platform-specific sections.

### Deliverable

A single document: `Documentation/Cross-Platform-Feasibility-Report.md` with sections for each target platform and each evaluated approach.

### Research Steps

#### Step 1: Inventory Cumberland's Framework Dependencies

Before evaluating approaches, catalog what needs replacement:

| Framework | Usage in Cumberland | Replacement Difficulty |
|-----------|-------------------|----------------------|
| SwiftUI | All UI (170 Swift files) | Full UI rewrite on any non-Apple platform |
| SwiftData | All persistence (Card, Board, Source, etc.) | Need equivalent ORM + migration system |
| CloudKit | Sync across devices | Need alternative sync service |
| PencilKit | iOS drawing canvas | Need pressure-sensitive canvas replacement |
| Custom NSView | macOS drawing canvas | Need equivalent canvas |
| MapKit | Map capture, location search | Need mapping library (Google Maps, Mapbox) |
| RealityKit | visionOS spatial features | No equivalent on non-Apple platforms |
| Photos framework | Image picker integration | Platform-specific image access |

#### Step 2: Evaluate Cross-Platform Approaches

For each approach, assess against all three target platforms:

**A. Web Application (Swift backend + web frontend)**
- Research: Vapor/Hummingbird for backend, React/Vue/Svelte for frontend
- Assess: offline capability (Service Workers/PWA), drawing canvas (HTML5 Canvas, Fabric.js), sync (WebSockets, CRDTs)
- Coverage: Windows + Linux + Android (via browser)
- Code reuse: ~0% of UI code, ~30-40% of business logic (if backend is Swift)

**B. Electron/Tauri (desktop cross-platform)**
- Research: Tauri (Rust backend + web frontend) vs Electron (Node.js + Chromium)
- Assess: performance, bundle size, native feel, drawing canvas
- Coverage: Windows + Linux (not mobile)
- Code reuse: ~0% of UI code

**C. Kotlin Multiplatform (KMP) + Compose Multiplatform**
- Research: current state of Compose for Desktop (Windows, Linux) and Compose for Android
- Assess: rewrite scope, persistence (SQLDelight), sync (Firebase/Supabase), drawing (Compose Canvas)
- Coverage: Windows + Linux + Android
- Code reuse: ~0% (full Kotlin rewrite)

**D. Flutter**
- Research: Flutter Desktop (Windows, Linux) + Flutter Mobile (Android)
- Assess: Dart rewrite scope, plugin ecosystem (drawing, maps, sync)
- Coverage: Windows + Linux + Android + iOS (if desired)
- Code reuse: ~0% (full Dart rewrite)

**E. Skip (Swift → Kotlin transpiler) — Android only**
- Research: current Skip capabilities at skip.tools
- Assess: which SwiftUI patterns transpile, SwiftData replacement (GRDB), PencilKit replacement
- Coverage: Android only
- Code reuse: ~60-80% of SwiftUI code (if Skip supports the patterns used)

**F. Swift on Windows/Linux + native UI**
- Research: Swift Windows toolchain, Swift Linux toolchain, GTK bindings (Adwaita-swift)
- Assess: UI framework maturity, FFI overhead, build system integration
- Coverage: Windows (Swift + WinUI/WPF), Linux (Swift + GTK)
- Code reuse: ~50% of business logic (Swift compiles), ~0% of UI

#### Step 3: Build Evaluation Matrix

For each approach × platform combination:

| Criteria | Weight | How to Assess |
|----------|--------|--------------|
| Code reuse from existing Swift | High | % of files that can be used as-is or with minor changes |
| Drawing canvas feasibility | Critical | Can we get pressure-sensitive, multi-layer drawing? |
| Data persistence | High | Can we migrate SwiftData models? What replaces it? |
| Sync/collaboration | Medium | What replaces CloudKit? What's the cost? |
| Distribution model | Medium | App store, direct download, web? |
| Maintenance burden | High | How many codebases to maintain? |
| Native platform feel | Medium | Does it feel like a native app or a web wrapper? |
| Engineering scope | High | Estimate relative to original Cumberland effort |

#### Step 4: Platform-Specific Considerations

**Windows (ER-0039):**
- Distribution: Microsoft Store, direct download, or web
- Drawing: Windows Ink API, Wacom tablet support
- Sync: No CloudKit — Firebase, Supabase, or custom

**Linux (ER-0040):**
- Distribution: Flatpak, Snap, AppImage, or web
- Desktop integration: GTK vs Qt theming, system tray, notifications
- Drawing: X11/Wayland input, Wacom drivers

**Android (ER-0041):**
- Distribution: Google Play Store
- Drawing: Android Canvas API, stylus/S Pen support, pressure sensitivity
- Sync: Firebase (natural fit), or same as Windows/Linux choice
- Skip: dedicated deep-dive — build a minimal prototype if possible

#### Step 5: Write Recommendation

For each platform, recommend a primary approach with justification. Consider:
- Can one approach cover multiple platforms? (Web covers all three; KMP covers all three; Flutter covers all three)
- What's the maintenance multiplier? (N separate codebases = N× maintenance)
- What's the minimum viable prototype to validate the recommendation?

### Output

The report should include:
1. Executive summary with recommendation per platform
2. Detailed evaluation matrix (approach × criteria × platform)
3. Framework replacement table (SwiftData → X, CloudKit → Y, etc.)
4. Recommended proof-of-concept for validation
5. Decision: unified approach (one cross-platform solution for all) vs. per-platform solutions

### Timeline Consideration

This is pure research — no code changes, no dependencies on other ERs. It can be conducted at any time, by any team member, and produces a document that informs future planning decisions. The research effort is bounded and does not block any other work.

---

## Execution Priority

| Priority | ER | Type | Independence |
|----------|------|------|-------------|
| **Any time** | ER-0037 | Implementation | Fully independent — can start whenever desired |
| **Any time** | ER-0039/0040/0041 | Research | Fully independent — no code changes, no dependencies |

Neither of these blocks or is blocked by the visionOS work (ER-0042–0051). The theming system (ER-0037) is probably the most immediately rewarding — it produces a visible, user-facing change that enhances the app's identity. The cross-platform research is strategic planning for future direction.

---

*Last Updated: 2026-02-23*
