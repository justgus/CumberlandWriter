# ER-0041: Cross-Platform Feasibility — Android

**Status:** ✅ Implemented - Verified
**Component:** Platform / Architecture
**Priority:** Low
**Date Requested:** 2026-02-22
**Date Implemented:** 2026-02-24
**Date Verified:** 2026-02-24

**Rationale:**
Android represents the largest mobile platform globally. Supporting Android would dramatically expand Cumberland's potential user base. This ER evaluates feasibility, with special attention to Skip (skip.tools) which transpiles Swift/SwiftUI to Kotlin/Compose.

**Current Behavior:**
Cumberland is Apple-exclusive. No Android deployment path exists.

**Desired Behavior:**
A documented assessment of the most viable path to running Cumberland on Android, with particular focus on approaches that maximize Swift/SwiftUI code reuse.

**Implementation Summary — Feasibility Report:**

### Approach 1: Skip (skip.tools) — RECOMMENDED

| Criterion | Assessment |
|-----------|------------|
| Code reuse | ~40-50% (Swift/SwiftUI transpiled to Kotlin/Compose) |
| UI rewrite | Partial — SwiftUI views transpile, but complex views need `#if SKIP` annotations |
| Data layer | SwiftData → **Not supported** — must use SkipSQL (GRDB.swift → SQLite bridge) |
| Sync | CloudKit → **Not supported** — must use Firebase or Supabase via SkipFirebase plugin |
| Drawing | PencilKit → **Not supported** — must use Android Jetpack Ink API via custom Skip plugin |
| Maps | MapKit → Google Maps SDK via SkipKit plugin |
| Scope | **Large** — 6-9 months |
| Distribution | Google Play Store, APK sideload |
| Impact on Apple app | **Minimal** — source stays Swift/SwiftUI; Skip-specific code in `#if SKIP` blocks |

**Key findings about Skip:**
- **Free and open-source** since January 2026 (was previously subscription-based)
- Transpiles Swift source to Kotlin and SwiftUI to Jetpack Compose at build time
- The transpilation is source-level, not binary — output is readable Kotlin
- Supports SPM packages, Foundation, Observation framework, Combine basics
- **Does NOT support:** SwiftData, PencilKit, CloudKit, MapKit, RealityKit, CoreData, Core Graphics
- Platform-specific code uses `#if SKIP` / `#if !SKIP` compiler directives
- Custom Skip plugins can bridge to Android-native frameworks

**What transpiles cleanly from Cumberland:**
- SwiftUI view hierarchy (NavigationStack, List, Form, Sheet, TabView)
- @Observable / @State / @Binding / @Environment patterns
- Model structs and enums (Kinds, SizeCategory, etc.)
- String processing, date formatting, array operations
- Basic Combine publishers

**What requires Skip plugins or rewrites:**
- SwiftData persistence → SkipSQL (GRDB-based SQLite)
- CloudKit sync → SkipFirebase or custom Supabase plugin
- PencilKit drawing → Custom Skip plugin wrapping Android Jetpack Ink API (4ms latency, pressure-sensitive)
- MapKit → SkipKit Google Maps bridge
- RealityKit (visionOS) → N/A on Android
- Image processing (Core Image) → Android Bitmap/RenderScript via custom plugin
- Terrain generation → Rewrite procedural generation for Android Canvas

**Estimated breakdown:**
- View layer (~120 SwiftUI files): ~60% transpile as-is, ~40% need `#if SKIP` adaptations
- Model layer (~25 files): ~70% transpile, ~30% need persistence layer swap
- Drawing system (~30 files): ~10% reusable (math/algorithms), ~90% needs Android rewrite
- Infrastructure (sync, image, citation): ~20% reusable, ~80% needs platform replacement

**Verdict:** Skip is the most natural path for a SwiftUI app. The 40-50% code reuse is the highest of any approach. The main risk is the drawing system — PencilKit has no Skip equivalent, so a custom plugin wrapping Android's Jetpack Ink API is required. The data layer swap (SwiftData → SkipSQL) is well-documented in Skip's ecosystem. **Recommended as the primary approach** due to lowest impact on the Apple codebase and highest code reuse.

### Approach 2: Kotlin Multiplatform (KMP) + Compose

| Criterion | Assessment |
|-----------|------------|
| Code reuse | 0% from Swift (but ~60-70% shared Kotlin across Android/Windows/Linux) |
| UI rewrite | Complete — SwiftUI → Compose Multiplatform |
| Data layer | SwiftData → SQLDelight (cross-platform Kotlin SQLite) |
| Sync | CloudKit → Supabase / Ktor custom sync |
| Drawing | PencilKit → Compose Canvas API (Skia, hardware-accelerated, excellent stylus support) |
| Maps | MapKit → Google Maps Compose |
| Scope | **Full rewrite** — 12-18 months |
| Distribution | Google Play Store |
| Impact on Apple app | **None** — completely separate codebase (but doubles maintenance) |

**Verdict:** The strongest option if the goal is Android + Windows + Linux from a single non-Swift codebase (see ER-0039 Approach 4, ER-0040 Approach 5). Compose Canvas (Skia-backed) is excellent for drawing apps. However, this is a full rewrite that doubles the maintenance burden — two complete codebases (Swift for Apple, Kotlin for everything else). **Recommended only if Skip proves insufficient and desktop platforms are also a priority.**

### Approach 3: Flutter

| Criterion | Assessment |
|-----------|------------|
| Code reuse | 0% from Swift (but ~70-80% shared Dart across all platforms) |
| UI rewrite | Complete — SwiftUI → Flutter widgets (Dart) |
| Data layer | SwiftData → drift (Dart SQLite ORM) or Isar (NoSQL) |
| Sync | CloudKit → Firebase (first-class Flutter SDK) |
| Drawing | PencilKit → Flutter CustomPainter + stylus_kit / flutter_drawing_board |
| Maps | MapKit → google_maps_flutter or flutter_map |
| Scope | **Full rewrite** — 12-18 months |
| Distribution | Google Play Store |
| Impact on Apple app | **High** — either maintain two apps (Swift + Dart) or replace the Apple app with Flutter |

**Verdict:** Flutter covers Android, iOS, Windows, Linux, macOS, and web — the broadest reach. But adopting Flutter for Android creates a maintenance dilemma: maintain both the Swift Apple app and a Dart Flutter app, or replace the Apple app entirely (losing SwiftUI/SwiftData/PencilKit native quality). Drawing via CustomPainter is capable but less refined than native PencilKit or Jetpack Ink. Firebase integration is excellent. **Not recommended unless willing to consider replacing the Apple-native app entirely.**

### Approach 4: React Native

| Criterion | Assessment |
|-----------|------------|
| Code reuse | 0% from Swift |
| UI rewrite | Complete — SwiftUI → React Native JSX |
| Data layer | SwiftData → WatermelonDB or expo-sqlite |
| Sync | CloudKit → Firebase JS SDK or Supabase |
| Drawing | PencilKit → react-native-canvas + custom native module |
| Maps | MapKit → react-native-maps |
| Scope | **Full rewrite** — 12-18 months |
| Distribution | Google Play Store |
| Impact on Apple app | Same dilemma as Flutter |

**Verdict:** React Native has a large ecosystem but is not well-suited for drawing-intensive applications. The JavaScript bridge adds latency that impacts stylus responsiveness. Canvas drawing requires custom native modules, negating much of the cross-platform benefit. **Not recommended for Cumberland due to the drawing system being a critical feature.**

### Approach 5: Compose Multiplatform (Android-first)

| Criterion | Assessment |
|-----------|------------|
| Code reuse | 0% from Swift (but shared with desktop Compose) |
| UI rewrite | Complete — SwiftUI → Compose |
| Data layer | SwiftData → Room (Android) / SQLDelight (cross-platform) |
| Sync | CloudKit → Firebase / Supabase |
| Drawing | PencilKit → Jetpack Ink API (4ms latency) + Compose Canvas |
| Maps | MapKit → Google Maps Compose |
| Scope | **Full rewrite** — 9-12 months (Android-only, less than full KMP) |
| Distribution | Google Play Store |
| Impact on Apple app | None — separate codebase |

**Verdict:** If Skip doesn't work out and Android is the only non-Apple priority, a focused Compose-only Android app is more manageable than full KMP. Jetpack Ink API provides excellent stylus support (4ms latency, pressure/tilt). Room is Android's standard persistence. This could later expand to desktop via Compose Multiplatform (linking with ER-0039/ER-0040). **Second-best option after Skip.**

### Overall Recommendation

| Priority | Recommended Approach | Rationale |
|----------|---------------------|-----------|
| **Primary** | **Skip (skip.tools)** | Highest code reuse (40-50%), lowest Apple app impact, free/open-source |
| Fallback if Skip insufficient | **Compose (Android-first)** | Native Android quality, expandable to desktop later |
| Maximum platform coverage | **KMP + Compose** | Android + Windows + Linux from one Kotlin codebase |
| Consider deferring | **Web PWA** | If mobile app quality isn't required, a PWA serves Android via browser |

**Minimal proof-of-concept (Skip):**
1. Create a Skip project with Cumberland's `Card` model (simplified)
2. Build a basic card list view with NavigationStack
3. Implement SQLite persistence via SkipSQL
4. Test transpilation on an Android emulator
5. If successful: add a basic drawing canvas using a custom Skip plugin wrapping Android Canvas API

### Critical Framework Replacements Required (Any Approach)

| Apple Framework | Android Replacement | Difficulty |
|----------------|-------------------|------------|
| SwiftData | SkipSQL / Room / SQLDelight | Medium — different API, same SQLite underneath |
| CloudKit | Firebase Firestore + Cloud Storage | High — different sync model, no automatic merge |
| PencilKit | Jetpack Ink API | High — different API, must rebuild brush system |
| MapKit | Google Maps SDK | Medium — well-documented, good API parity |
| RealityKit | ARCore (limited parity) | N/A — visionOS features don't port to Android |
| Core Image | Android Bitmap + RenderScript/Vulkan | Medium — different API, similar capability |

**Notes:**
- Skip is the most natural fit for a SwiftUI app but has limitations with complex framework dependencies
- Skip became free and open-source in January 2026 — this significantly changes the cost/benefit analysis
- If Skip works well, it is the fastest path to Android with the lowest Apple app impact
- Flutter would cover Android + iOS but means maintaining two codebases or replacing the Apple-native version
- KMP could serve Android + Windows + Linux but requires rewriting everything in Kotlin
- Tablet support (drawing with stylus) is critical — Jetpack Ink API (4ms latency) is the best Android option
- Consider a phased approach: Ship a "reader" version first (view cards, no drawing), then add drawing in a second phase
- Related: ER-0039 (Windows), ER-0040 (Linux)
