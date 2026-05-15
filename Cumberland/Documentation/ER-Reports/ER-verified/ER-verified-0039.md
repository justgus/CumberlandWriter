# ER-0039: Cross-Platform Feasibility — Windows

**Status:** ✅ Implemented - Verified
**Component:** Platform / Architecture
**Priority:** Low
**Date Requested:** 2026-02-22
**Date Implemented:** 2026-02-24
**Date Verified:** 2026-02-24

**Rationale:**
Expanding Cumberland's reach to Windows would serve writers who use Windows as their primary platform. This ER is a research and feasibility assessment — not an implementation commitment — given the significant technical barriers.

**Current Behavior:**
Cumberland is an Apple-exclusive app built on SwiftUI, SwiftData, CloudKit, PencilKit, MapKit, and RealityKit. None of these frameworks exist on Windows.

**Desired Behavior:**
A clear, documented assessment of the most viable path to running Cumberland (or a functionally equivalent app) on Windows, with a realistic cost/benefit analysis and recommended approach.

**Implementation Summary — Feasibility Report:**

### Approach 1: Swift on Windows + WinUI 3

| Criterion | Assessment |
|-----------|------------|
| Code reuse | ~15-20% (model logic, algorithms only) |
| UI rewrite | Complete — SwiftUI → WinUI 3 via C++/C# interop or SwiftWinRT |
| Data layer | SwiftData → GRDB.swift or SQLite.swift (Swift on Windows supports SPM) |
| Sync | CloudKit → Supabase/Firebase |
| Drawing | PencilKit → Win2D or Direct2D canvas (full rewrite) |
| Maps | MapKit → Bing Maps SDK or MapLibre |
| Scope | **Large/Rewrite** — 12-18 months |
| Distribution | MSIX package via Microsoft Store or sideload |
| Runtime | Swift runtime DLLs bundled (~30 MB overhead) |

**Verdict:** Technically possible but extremely high friction. Swift on Windows has no GUI framework — you'd use C++/C# interop for WinUI 3, making this essentially two codebases. The Swift Windows toolchain (swift.org) compiles SPM packages, but FFI to WinRT is manual and brittle. Not recommended unless a dedicated Windows team exists.

### Approach 2: Web Application (Swift Backend + Web Frontend)

| Criterion | Assessment |
|-----------|------------|
| Code reuse | ~25-30% (server-side model logic via Vapor/Hummingbird) |
| UI rewrite | Complete — SwiftUI → React/Vue/Svelte |
| Data layer | SwiftData → PostgreSQL + server-side ORM (Fluent) |
| Sync | Native via server — replaces CloudKit entirely |
| Drawing | PencilKit → HTML5 Canvas + Fabric.js / Excalidraw |
| Maps | MapKit → Leaflet / MapLibre GL JS |
| Scope | **Rewrite** — 9-15 months for full parity |
| Distribution | URL (no install), optional PWA for offline |
| Runtime | Modern browser only |

**Verdict:** Best cross-platform reach — a single web app covers Windows, Linux, Android, and any device with a browser. Offline PWA support makes it viable for writers without constant connectivity. The drawing canvas is the biggest challenge (HTML5 Canvas is capable but stylus pressure sensitivity support varies by browser). Server-side Swift (Vapor) could reuse some model logic. **Recommended if the goal is maximum platform reach with a single codebase.**

### Approach 3: Electron / Tauri

| Criterion | Assessment |
|-----------|------------|
| Code reuse | ~10-15% (Electron: none; Tauri: Rust backend, no Swift) |
| UI rewrite | Complete — SwiftUI → HTML/CSS/JS |
| Data layer | SwiftData → SQLite (via better-sqlite3 or sql.js) or IndexedDB |
| Sync | CloudKit → Supabase/Firebase client SDK |
| Drawing | PencilKit → HTML5 Canvas + Fabric.js |
| Maps | MapKit → Leaflet / MapLibre GL JS |
| Scope | **Rewrite** — 9-12 months |
| Distribution | Electron: ~120 MB installer; Tauri: ~3-10 MB installer |
| Runtime | Electron bundles Chromium; Tauri uses OS WebView (Edge WebView2 on Windows) |

**Verdict:** Tauri is the lighter-weight option (3-10 MB vs Electron's 120 MB). Same web frontend as Approach 2 but packaged as a native desktop app with file system access and system tray. **Tauri recommended over Electron** for bundle size and performance. However, this is essentially the same frontend effort as a pure web app — consider whether the desktop wrapper adds enough value over a PWA.

### Approach 4: Kotlin Multiplatform (KMP) + Compose

| Criterion | Assessment |
|-----------|------------|
| Code reuse | 0% from Swift (but ~60-70% shared Kotlin across Android/Windows/Desktop) |
| UI rewrite | Complete — SwiftUI → Compose Multiplatform |
| Data layer | SwiftData → SQLDelight (Kotlin, cross-platform SQLite) |
| Sync | CloudKit → Supabase / Ktor-based custom sync |
| Drawing | PencilKit → Compose Canvas API (Skia-backed, hardware-accelerated) |
| Maps | MapKit → Google Maps Compose or MapLibre |
| Scope | **Full rewrite** — 12-18 months, but covers Android simultaneously |
| Distribution | JVM-based Windows installer (MSI/EXE, ~50-80 MB) |
| Runtime | JVM bundled via jpackage or GraalVM native-image |

**Verdict:** The strongest option if Android (ER-0041) is also a priority. A single Kotlin codebase can target Windows (Compose Desktop), Android (Compose for Android), and Linux (Compose Desktop). The investment is significant (full rewrite) but yields three platforms. Drawing via Compose Canvas (Skia) is production-grade. **Recommended if pursuing Android + Windows + Linux together.**

### Approach 5: Flutter

| Criterion | Assessment |
|-----------|------------|
| Code reuse | 0% from Swift (but ~70-80% shared Dart across all platforms) |
| UI rewrite | Complete — SwiftUI → Flutter widgets (Dart) |
| Data layer | SwiftData → drift (Dart SQLite ORM) or Isar |
| Sync | CloudKit → Firebase (first-class Flutter support) or Supabase |
| Drawing | PencilKit → Flutter CustomPainter + flutter_drawing_board |
| Maps | MapKit → google_maps_flutter or flutter_map (Leaflet-based) |
| Scope | **Full rewrite** — 12-18 months |
| Distribution | Native Windows executable (~15-25 MB) |
| Runtime | Flutter engine bundled (Skia rendering) |

**Verdict:** Flutter targets Windows, Android, iOS, Linux, macOS, and web — the broadest platform coverage of any single framework. Production-ready Windows support. The Dart language is a full departure from Swift. Drawing via CustomPainter is capable but less mature than Compose Canvas for complex pen input. Firebase integration is excellent. **Recommended if Flutter's broader platform coverage justifies the full Dart migration.**

### Overall Recommendation

No approach offers >50% code reuse from the existing Swift codebase. The choice depends on strategic priorities:

| Priority | Recommended Approach |
|----------|---------------------|
| Maximum platform reach, minimal native feel | **Web App (PWA)** — covers all platforms via browser |
| Android + Windows + Linux, native feel | **KMP + Compose** — single Kotlin codebase for 3 platforms |
| Desktop-focused (Windows + Linux) | **Tauri** — lightweight desktop wrapper around web frontend |
| All platforms including iOS replacement | **Flutter** — broadest framework, but replaces Apple-native app |

**Minimal proof-of-concept:** Build a Tauri app with a basic card list view, SQLite-backed persistence, and an HTML5 Canvas drawing surface. This validates the core interactions (CRUD, drawing) with the lowest setup cost.

**Notes:**
- Swift on Windows is functional but the ecosystem is minimal compared to Apple platforms
- CloudKit replacement candidates: Firebase, Supabase, custom sync, CRDTs
- SwiftData replacement candidates: SQLite (direct), GRDB, SQLDelight (Kotlin), drift (Dart)
- The drawing system (PencilKit on iOS, custom NSView on macOS) would need a complete replacement on any approach
- A web app or Tauri approach would naturally overlap with ER-0040 (Linux) and partially with ER-0041 (Android)
- No approach preserves the Apple-native experience — any Windows port is a separate product
- Related: ER-0040 (Linux), ER-0041 (Android)
