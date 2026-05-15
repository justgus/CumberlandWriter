# ER-0025: Complete BrushEngine Package for Independent Consumption

**Status:** ✅ Implemented - Verified (2026-02-16)
**Component:** BrushEngine Package, Public API, Layer Persistence
**Priority:** High
**Date Requested:** 2026-02-03
**Date Implemented:** 2026-02-16
**Date Verified:** 2026-02-16
**Dependencies:** ER-0024 (BrushEngine package — completed)

---

## Revised Scope

The original ER-0025 proposed creating an Xcode workspace linking Cumberland and Storyscapes. Per user directive, the scope was revised to: complete the BrushEngine package's public API so external apps can independently consume it, without creating a workspace or integrating Storyscapes.

## Implementation

### 1. LayerPersistenceDelegate Protocol (new file)
- Created `Packages/BrushEngine/Sources/BrushEngine/Layers/LayerPersistenceDelegate.swift`
- Public protocol enabling external apps to receive automatic save notifications from `LayerManager`
- `save(layerData:)` — called after every mutating operation
- `loadDraftWork() -> Data?` — called to restore prior state

### 2. LayerManager Persistence Integration
- Added `public weak var persistenceDelegate: (any LayerPersistenceDelegate)?` to `LayerManager`
- Added `saveDraftWork()` — manually triggers save to delegate
- Added `loadDraftWork()` — restores layer state from delegate
- Added `notifyPersistence()` — private helper called after all 22+ mutating methods (create, delete, duplicate, move, merge, visibility, lock, opacity, blend mode, rename, type, fill, bulk operations)

### 3. BrushRegistry Configurable Storage
- Added `public nonisolated(unsafe) static var storageKey` to `BrushRegistry`
- Storage filename now uses `"\(storageKey).json"` instead of hardcoded `"Cumberland_BrushSets.json"`
- Default value `"Cumberland_BrushSets"` preserves backward compatibility for existing Cumberland users

### 4. Cleanup — Removed 19 Old Duplicate DrawCanvas Files
- Deleted pre-package copies of BrushEngine source files from `Cumberland/DrawCanvas/`
- These files were already excluded from all build targets via membership exceptions
- Includes: BrushEngine.swift, BrushEngine.swift.bak, BrushEngine+macOS/Patterns/PencilKit.swift, BrushRegistry.swift, BrushSet.swift, MapBrush.swift, ExteriorMapBrushSet.swift, InteriorMapBrushSet.swift, LayerManager.swift, DrawingLayer.swift, BaseLayerFill.swift, BaseLayerImageCache.swift, BaseLayerPatterns.swift, TerrainPattern.swift, ProceduralPatternGenerator.swift, ElevationMap.swift, TerrainMapMetadata.swift

## External Consumption Pattern

```swift
import BrushEngine

// Configure storage key (optional)
BrushRegistry.storageKey = "MyApp_BrushSets"

// Create layer manager with persistence
let layerManager = LayerManager()
layerManager.persistenceDelegate = myDataModel
layerManager.loadDraftWork()

// All layer operations auto-save via delegate
layerManager.createLayer(name: "Terrain", type: .terrain)
```

## Files Created
- `Packages/BrushEngine/Sources/BrushEngine/Layers/LayerPersistenceDelegate.swift`

## Files Modified
- `Packages/BrushEngine/Sources/BrushEngine/Layers/LayerManager.swift` — persistence delegate, saveDraftWork, loadDraftWork, notifyPersistence
- `Packages/BrushEngine/Sources/BrushEngine/Brushes/BrushRegistry.swift` — configurable storageKey

## Files Deleted (19)
- 18 old DrawCanvas source files + 1 .bak file (duplicates of package contents)

## Build Status
- macOS: ✅ Zero errors, zero warnings

---

**Detailed Build Plan:** See `ER-0025-BuildPlan.md` (original scope; revised scope documented here)
