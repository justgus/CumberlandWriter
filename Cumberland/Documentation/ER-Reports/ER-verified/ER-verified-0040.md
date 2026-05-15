# ER-0040: Cross-Platform Feasibility — Linux

**Status:** ✅ Implemented - Verified
**Component:** Platform / Architecture
**Priority:** Low
**Date Requested:** 2026-02-22
**Date Implemented:** 2026-02-24
**Date Verified:** 2026-02-24

**Rationale:**
Linux support would serve writers in the open-source community and those using Linux workstations. This ER is a research and feasibility assessment, closely related to ER-0039 (Windows) since many solutions would overlap.

**Current Behavior:**
Cumberland is Apple-exclusive. No Linux deployment path exists.

**Desired Behavior:**
A documented assessment of the most viable path to running Cumberland on Linux, potentially sharing approach with ER-0039 (Windows).

**Implementation Summary — Feasibility Report:**

### Approach 1: Swift on Linux + GTK (Adwaita-swift)

| Criterion | Assessment |
|-----------|------------|
| Code reuse | ~20-25% (model logic, algorithms; Swift compiles natively on Linux) |
| UI rewrite | Complete — SwiftUI → Adwaita-swift (SwiftUI-like API for GNOME/Libadwaita) |
| Data layer | SwiftData → GRDB.swift (works on Linux via SPM) |
| Sync | CloudKit → Supabase / Firebase REST API |
| Drawing | PencilKit → GTK Cairo drawing API (capable but low-level) |
| Maps | MapKit → libshumate (GNOME map widget) or embedded web map |
| Scope | **Large** — 9-12 months |
| Distribution | Flatpak (preferred), Snap, AppImage, or .deb/.rpm |
| Runtime | Swift runtime (~15 MB), GTK4/Libadwaita system libraries |
| Maturity | **Pre-production** — Adwaita-swift is v0.2.6, pre-1.0; SwiftCrossUI is experimental |

**Verdict:** The most "Swift-native" option for Linux. Adwaita-swift provides a SwiftUI-like declarative API, so the mental model transfers well. However, the library is pre-1.0, community-maintained, and may not support all the complex view compositions Cumberland requires (custom canvas, drag-and-drop, multi-window). GRDB.swift works on Linux, which is a plus. **Only viable for adventurous early adopters willing to contribute upstream fixes.** Not recommended for production use today.

### Approach 2: Swift on Linux + SwiftCrossUI

| Criterion | Assessment |
|-----------|------------|
| Code reuse | ~20-25% (same as Adwaita-swift — Swift model layer) |
| UI rewrite | Complete — SwiftUI → SwiftCrossUI (targets GTK, Qt, and web backends) |
| Data layer | SwiftData → GRDB.swift |
| Sync | CloudKit → Supabase / Firebase REST API |
| Drawing | PencilKit → backend-dependent (GTK Cairo or Qt QPainter) |
| Maps | MapKit → backend-dependent web embed |
| Scope | **Large** — 12+ months |
| Distribution | Same as Approach 1 |
| Maturity | **Experimental** — very early, limited widget set |

**Verdict:** SwiftCrossUI is more ambitious (multiple backends) but less mature than Adwaita-swift. The widget set is limited — no complex list views, no canvas, no drag-and-drop. **Not viable for Cumberland's complexity today.** Monitor for future development.

### Approach 3: Web Application (Shared with ER-0039)

| Criterion | Assessment |
|-----------|------------|
| Code reuse | ~25-30% (server-side model logic via Vapor/Hummingbird) |
| UI rewrite | Complete — SwiftUI → React/Vue/Svelte |
| Data layer | SwiftData → PostgreSQL + server ORM |
| Sync | Native via server |
| Drawing | PencilKit → HTML5 Canvas + Fabric.js / Excalidraw |
| Maps | MapKit → Leaflet / MapLibre GL JS |
| Scope | **Rewrite** — 9-15 months (same as ER-0039 Approach 2) |
| Distribution | URL (zero install), optional PWA |
| Runtime | Modern browser (Firefox, Chrome, Edge) |

**Verdict:** Identical assessment to ER-0039 Approach 2. **Perfect overlap with Windows** — a single web app serves both. Linux users are often comfortable with web apps and PWAs. Distribution is trivial (no packaging required). **Recommended for maximum Windows + Linux overlap.**

### Approach 4: Tauri (Shared with ER-0039)

| Criterion | Assessment |
|-----------|------------|
| Code reuse | ~10-15% (Rust backend, no Swift) |
| UI rewrite | Complete — SwiftUI → HTML/CSS/JS |
| Data layer | SwiftData → SQLite (via sql.js or rusqlite) |
| Sync | CloudKit → Supabase/Firebase client SDK |
| Drawing | PencilKit → HTML5 Canvas + Fabric.js |
| Maps | MapKit → Leaflet / MapLibre GL JS |
| Scope | **Rewrite** — 9-12 months (same as ER-0039 Approach 3) |
| Distribution | AppImage, Flatpak, .deb, .rpm (~3-10 MB) |
| Runtime | System WebKitGTK (Linux), bundled on other platforms |

**Verdict:** Tauri's Linux support uses WebKitGTK (system-provided on most distros). Same frontend as the web app but with native file system access and system integration. Packaging as Flatpak or AppImage provides clean distribution. **Best option for a native-feel desktop app on Windows + Linux simultaneously.**

### Approach 5: KMP + Compose Desktop (Shared with ER-0039)

| Criterion | Assessment |
|-----------|------------|
| Code reuse | 0% from Swift (but ~60-70% shared Kotlin across Android/Windows/Linux) |
| UI rewrite | Complete — SwiftUI → Compose Multiplatform |
| Data layer | SwiftData → SQLDelight |
| Sync | CloudKit → Supabase / Ktor custom sync |
| Drawing | PencilKit → Compose Canvas (Skia, hardware-accelerated) |
| Maps | MapKit → MapLibre via Compose wrapper |
| Scope | **Full rewrite** — 12-18 months, covers Android + Windows + Linux |
| Distribution | JVM-based Linux installer, Flatpak, or native via GraalVM |
| Runtime | JVM bundled (~50-80 MB) or GraalVM native-image (~30-50 MB) |

**Verdict:** Identical assessment to ER-0039 Approach 4. Compose Desktop runs on Linux with full Skia rendering. The JVM runtime is heavier but reliable. **Recommended if pursuing Android + Windows + Linux as a unified Kotlin codebase.**

### Approach 6: Flutter (Shared with ER-0039)

| Criterion | Assessment |
|-----------|------------|
| Code reuse | 0% from Swift (but ~70-80% shared Dart across all platforms) |
| UI rewrite | Complete — SwiftUI → Flutter widgets |
| Data layer | SwiftData → drift / Isar |
| Sync | CloudKit → Firebase / Supabase |
| Drawing | PencilKit → Flutter CustomPainter |
| Maps | MapKit → flutter_map |
| Scope | **Full rewrite** — 12-18 months |
| Distribution | Native Linux binary (~15-25 MB), Snap or Flatpak |
| Runtime | Flutter engine bundled |
| Maturity | Linux support is "stable" but less battle-tested than Windows/Android |

**Verdict:** Flutter's Linux support is officially stable but receives less attention than mobile platforms. Desktop Linux plugins (file pickers, system tray, notifications) are less mature. **Viable but Linux is not Flutter's strongest platform.** Same full-rewrite cost as KMP.

### Approach 7: Qt (C++/Python)

| Criterion | Assessment |
|-----------|------------|
| Code reuse | 0% from Swift |
| UI rewrite | Complete — SwiftUI → QML or Qt Widgets |
| Data layer | SwiftData → SQLite via Qt SQL module |
| Sync | CloudKit → custom sync via Qt Network |
| Drawing | PencilKit → Qt QPainter / QGraphicsScene (very capable) |
| Maps | MapKit → Qt Location module |
| Scope | **Full rewrite** — 12-18 months |
| Distribution | AppImage, Flatpak, .deb, .rpm |
| Maturity | **Very mature** — 30+ year history, excellent Linux support |

**Verdict:** Qt is the most mature cross-platform desktop framework with first-class Linux support. QPainter and QGraphicsScene are excellent for drawing applications. However, Qt requires C++ or Python (PyQt/PySide), which is a significant departure from Swift. The licensing model (LGPL/commercial) may be a consideration. **Best "traditional desktop" option if native feel on Linux is paramount.** Not recommended due to language barrier and no mobile story.

### Overall Recommendation & Windows Overlap

The key finding is that **every viable Linux approach also covers Windows** — there is no Linux-specific solution worth pursuing independently.

| Priority | Recommended Approach | Windows Overlap |
|----------|---------------------|-----------------|
| Lowest effort, broadest reach | **Web App (PWA)** | Perfect overlap with ER-0039 |
| Native desktop feel | **Tauri** | Perfect overlap with ER-0039 |
| Android + Desktop | **KMP + Compose** | Full overlap with ER-0039 + ER-0041 |
| Maximum platform coverage | **Flutter** | Full overlap with ER-0039 + ER-0041 |
| Swift-native on Linux | **Adwaita-swift** | No Windows overlap (Linux-only) |

**Decision: ER-0039 and ER-0040 should be treated as a single "desktop cross-platform" decision.** The recommended proof-of-concept is the same as ER-0039: a Tauri app with card list, SQLite persistence, and HTML5 Canvas drawing.

### Linux-Specific Considerations

- **Packaging:** Flatpak is the most universal Linux packaging format (works across distros). AppImage is simpler but has less system integration. Snap is Ubuntu-centric.
- **Desktop integration:** Linux DEs (GNOME, KDE, etc.) have different conventions — Tauri/web abstracts this away; GTK-native apps look best on GNOME.
- **Stylus support:** Wacom/stylus pressure sensitivity is well-supported on Linux via libinput, but browser/toolkit support varies. GTK Cairo handles it well.
- **Market size:** Linux desktop market share is ~4% globally (growing in developer/creative communities). The effort-to-reach ratio is lower than Windows or Android.

**Notes:**
- Swift on Linux is more mature than Swift on Windows (server-side Swift runs on Linux)
- GTK bindings for Swift exist but are not widely adopted — pre-1.0 maturity
- Linux desktop market share is small but passionate — consider effort vs. reach
- A web app or Tauri approach naturally covers Linux without platform-specific work
- **Key insight:** There is no reason to pursue a Linux-only solution — every viable approach also covers Windows
- Related: ER-0039 (Windows), ER-0041 (Android)
