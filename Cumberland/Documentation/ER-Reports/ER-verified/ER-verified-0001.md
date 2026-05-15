# Enhancement Requests (ER) - Verified Batch 1

This file contains verified enhancement requests ER-0001.

---

## ER-0001: Interior vs Exterior Canvas Differentiation

**Status:** ✅ Verified
**Component:** DrawCanvas, ToolsTabView, BaseLayerButton, TerrainPattern
**Priority:** High
**Date Requested:** 2026-01-01
**Date Implemented:** 2026-01-03
**Date Verified:** 2026-01-03

**Rationale:**
Differentiate between Interior and Exterior map types to provide context-appropriate UI, scale units, and procedural pattern rendering that matches user expectations for each mapping workflow.

**Requirements:**

1. **Context-Aware Base Layer Menu** - Filter base layer options by map category
2. **Interior-Specific UI** - Show feet units, hide water %, appropriate presets
3. **Fixed-Scale Floor Patterns** - Material sizes don't change with map scale
4. **Wood Plank Pattern** - Realistic 6-inch floor planks with grain and variation
5. **Map Type Persistence** - Save/load category across sessions

**Implementation Summary:**

### Phase 1: Map Type Detection & Storage ✅

Added `mapCategory: BaseLayerCategory?` property to DrawingCanvasModel:
- Tracks whether map is Interior or Exterior
- Set via MapWizardView based on creation method
- Persisted in CanvasStateData for save/load

**Files:** DrawingCanvasView.swift, MapWizardView.swift

### Phase 2: Base Layer Menu Filtering ✅

Modified BaseLayerButton to filter fill types by category:
- Exterior maps show only: Water, Land, Sandy, Forested, Mountain, Snow, Ice, Rocky
- Interior maps show only: Tile, Stone, Wood, Slate, Cobbles, Concrete, Metal
- Backward compatibility for maps without category (shows all)

**Files:** BaseLayerButton.swift

### Phase 3: Tools Palette Conditional UI ✅

Updated ToolsTabView for map-specific controls:
- Exterior: Scale in "mi" with presets 5, 50, 500; water % slider shown
- Interior: Scale in "ft" with presets 10, 50, 100; water % slider hidden
- Created interiorScaleControls() and updateInteriorScale() functions

**Files:** ToolsTabView.swift

### Phase 4: Fixed-Scale Floor Patterns ✅

Interior patterns use fixed pixel sizes (not map-scale dependent):
- TilePattern: 64px tiles
- SlatePattern: 120x60px slabs
- CobblestonePattern: 40px cobbles
- StonePattern, ConcretePattern, MetalPattern: Fixed textures

Pattern sizes remain constant regardless of map scale changes.

**Files:** BaseLayerPatterns.swift

### Phase 5: Wood Plank Pattern ✅

Replaced generic wood texture with realistic floor planks:
- 6-inch wide planks (36 pixels)
- Varied lengths: 2', 3', 4', 5', 6' (144-432 pixels)
- Staggered pattern (offset rows by half plank)
- Horizontal wood grain using fractal noise
- Per-plank color variation (±10% brightness)
- Dark separation lines between planks (2px)

**Files:** BaseLayerPatterns.swift

**Files Modified:**
- DrawingCanvasView.swift (mapCategory property, serialization)
- MapWizardView.swift (category assignment on creation)
- BaseLayerButton.swift (menu filtering logic)
- ToolsTabView.swift (conditional UI, interior controls)
- BaseLayerPatterns.swift (WoodPattern rewrite, fixed-scale patterns)

**Design Trade-offs:**
- Fixed-scale floor patterns change viewport coverage (not material size) when scale changes - more realistic
- Map category set at creation time - cannot convert between Interior/Exterior after creation
- Ensures data consistency and prevents invalid state

**Related DRs:**
- DR-0016: Procedural terrain generation system (foundation)
- DR-0018: Terrain composition profiles (exterior patterns)
- DR-0018.1, DR-0018.2: Scale and water % persistence

---

## ER-0002: Base Layer should not receive strokes

**Status:** ✅ Verified
**Component:** DrawingCanvasView, DrawingCanvasViewMacOS, LayerManager
**Priority:** Medium
**Date Requested:** 2026-01-03
**Date Implemented:** 2026-01-03
**Date Verified:** 2026-01-06

**Rationale:**
The Base Layer serves a specialized purpose as the background/foundation material for a map (terrain, floor, etc.). Allowing strokes to be drawn directly on the Base Layer mixes user-created content (drawings, annotations) with procedurally-generated background material. This creates organizational and workflow issues:

1. **Layer Separation of Concerns**: Base layer should be purely for background fill (terrain/floor patterns), while drawing strokes should exist on content layers above it
2. **Editing Clarity**: Users may accidentally draw on the base layer when they intend to draw on content layers
3. **Export/Composition**: Clear separation between generated backgrounds and hand-drawn content simplifies compositing
4. **Workflow Expectations**: In professional graphics software (Photoshop, Illustrator, Procreate), background layers are typically locked or have special handling to prevent accidental modification

**Current Behavior:**
- Base Layer (order == 0) can be selected as the active layer
- When Base Layer is selected and unlocked, strokes are added to it
- User can draw directly on the procedurally-generated background
- Base Layer strokes mix with terrain/floor patterns

**Desired Behavior:**
1. **Stroke Rejection**: Even if Base Layer is unlocked and selected, strokes should NOT be added to it
2. **Automatic Redirect**: When Base Layer is active, strokes should be redirected to the topmost non-base layer
3. **Layer Creation Fallback**: If only the Base Layer exists (no content layers), automatically create "Layer 1" and add strokes there
4. **Visual Indicator**: Optionally indicate to user that Base Layer cannot receive strokes (UI feedback in Layers tab)
5. **Lock State Independent**: This behavior should apply even when Base Layer is explicitly unlocked

**Implementation:**

Implemented Option 1 (Redirect at Stroke Save Time) across both platforms.

### 1. LayerManager Helper Methods

**LayerManager.swift:67-72** - Added `topmostContentLayer` computed property
**LayerManager.swift:680-700** - Added `getTargetLayerForStrokes()` method

This method:
1. Returns active layer if it's valid (not base, not locked)
2. Falls back to topmost content layer and switches to it
3. Auto-creates "Layer 1" if no content layers exist

### 2. iOS Stroke Saving

**DrawingCanvasView.swift:1148-1154** - Updated `canvasViewDrawingDidChange`
- Replaced direct active layer check with `getTargetLayerForStrokes()` call
- Strokes automatically redirect from base layer

### 3. macOS Stroke Saving

**DrawingCanvasViewMacOS.swift:148-159** - Updated `mouseUp` handler
- Replaced direct active layer check with `getTargetLayerForStrokes()` call
- Strokes automatically redirect from base layer

**Files Modified:**
- LayerManager.swift (added computed property + helper method)
- DrawingCanvasView.swift (iOS stroke redirect)
- DrawingCanvasViewMacOS.swift (macOS stroke redirect)

**Verification Results:**
✅ Strokes do NOT appear on base layer
✅ "Layer 1" auto-created when needed
✅ Strokes redirect to appropriate content layer
✅ Works on both macOS and iOS/visionOS

---
