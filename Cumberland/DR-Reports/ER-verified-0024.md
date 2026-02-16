# ER-0024: Extract Brush Engine to Swift Package

**Status:** ✅ Implemented - Verified (2026-02-16)
**Component:** Drawing System, Procedural Generation, Swift Package
**Priority:** High
**Date Requested:** 2026-02-03
**Date Implemented:** 2026-02-16
**Date Verified:** 2026-02-16
**Dependencies:** None

---

## Summary

Extracted the brush rendering engine and procedural terrain generation system into a reusable Swift Package. This enables the same powerful map generation capabilities to be used in Storyscapes, game development tools, and other creative applications.

## Implementation

Extracted **18 source files (~9,400 lines)** from `Cumberland/DrawCanvas/` into a new local Swift Package at `Packages/BrushEngine/`. All three app targets (macOS, iOS, visionOS) depend on the package. Cumberland source files import the package module.

### Package Structure
```
Packages/BrushEngine/
├── Package.swift (swift-tools-version:6.2, platforms: macOS 26, iOS 26, visionOS 26)
├── Sources/BrushEngine/
│   ├── Core/
│   │   ├── BrushEngine.swift (2,401 lines) - Core rendering (~40 public static methods)
│   │   ├── BrushEngine+Patterns.swift (~1,000 lines) - Pattern generation
│   │   ├── BrushEngine+macOS.swift (~430 lines) - macOS-specific rendering
│   │   └── BrushEngine+PencilKit.swift (~493 lines) - PencilKit integration
│   ├── Brushes/
│   │   ├── MapBrush.swift (381 lines) - MapBrush, BrushCategory, BrushPattern, CodableColor
│   │   ├── BrushSet.swift (367 lines) - BrushSet, MapType, BrushSetPackage
│   │   ├── BrushRegistry.swift (529 lines) - Brush management singleton
│   │   ├── ExteriorMapBrushSet.swift (639 lines) - Exterior brush definitions
│   │   └── InteriorMapBrushSet.swift (743 lines) - Interior brush definitions
│   ├── Layers/
│   │   ├── DrawingLayer.swift (409 lines) - DrawingLayer, LayerType, DrawingStroke, CGPointCodable
│   │   ├── LayerManager.swift (800 lines) - Layer CRUD, reorder, merge, export
│   │   ├── BaseLayerFill.swift (358 lines) - Fill types and categories
│   │   └── BaseLayerImageCache.swift (129 lines) - Platform image cache
│   └── Patterns/
│       ├── TerrainPattern.swift (454 lines) - Procedural terrain rendering
│       ├── ProceduralPatternGenerator.swift (627 lines) - Noise and terrain generation
│       ├── BaseLayerPatterns.swift (701 lines) - ProceduralPattern protocol, pattern structs
│       ├── ElevationMap.swift (214 lines) - Elevation data model
│       └── TerrainMapMetadata.swift (99 lines) - Map scale and metadata
└── Tests/BrushEngineTests/
```

### What Stays in Cumberland
- UI components (DrawingCanvasView, DrawingCanvasViewMacOS, tool palettes, layer tabs)
- Integration with Card model and SwiftData
- Draft persistence
- BrushEngineDemo, BrushGridView, BaseLayerButton, InspectorTabView, ToolsTabView, LayersTabView

### Key Modifications During Extraction
1. **All types made `public`** -- Access modifiers added to all structs, classes, enums, properties, methods, and initializers
2. **Explicit `public init` added** to `DrawingStroke` and `CGPointCodable` (Swift doesn't synthesize public memberwise inits)
3. **Duplicate `clamped(to:)` extensions resolved** -- Removed from ElevationMap.swift and BrushEngine.swift; canonical version kept in TerrainPattern.swift
4. **Concurrency safety** -- `@MainActor` on `BrushRegistry.shared`; `BaseLayerImageCache` changed from `actor` to `@MainActor final class` to fix actor isolation warnings in synchronous `NSView.draw()` context
5. **Removed duplicate `NSColor.init(_ color: Color)`** extension from package (platform provides it on macOS 14+)
6. **Renamed local `MacOSDrawingStroke`** to `LocalDrawingStroke` in DrawingCanvasViewMacOS.swift to avoid conflict with package type

### Files with `import BrushEngine` Added (10 files)
- `Cumberland/DrawCanvas/DrawingCanvasView.swift`
- `Cumberland/DrawCanvas/DrawingCanvasViewMacOS.swift`
- `Cumberland/DrawCanvas/DrawingCanvasIntegration.swift`
- `Cumberland/DrawCanvas/BrushEngineDemo.swift`
- `Cumberland/DrawCanvas/BrushGridView.swift`
- `Cumberland/DrawCanvas/BaseLayerButton.swift`
- `Cumberland/DrawCanvas/ToolsTabView.swift`
- `Cumberland/DrawCanvas/LayersTabView.swift`
- `Cumberland/DrawCanvas/InspectorTabView.swift`
- `Cumberland/MapWizardView.swift`

### Xcode Project Changes
- Added BrushEngine local package reference to `Cumberland.xcodeproj/project.pbxproj`
- Added package product dependency to all 3 targets (macOS, iOS, visionOS)
- Added 18 extracted files to macOS target's membershipExceptions (iOS/visionOS already excluded them)

### Build Status
- macOS: ✅ Clean build, zero warnings
- iOS: Not yet tested
- visionOS: Not yet tested

---

**Detailed Build Plan:** See `ER-0024-BuildPlan.md`
