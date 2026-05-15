# Enhancement Requests (ER) - Verified Batch 2

This file contains verified enhancement request ER-0003.

---

## ER-0003: Integrate Exterior Brush System into Map Drawing Canvas

**Status:** ✅ Implemented - Verified
**Component:** DrawCanvas, BrushEngine, BrushRegistry, ToolPalette
**Priority:** High
**Date Requested:** 2026-01-07
**Date Implemented:** 2026-01-07
**Date Verified:** 2026-01-09

**Rationale:**
The brush engine and brush system have been created but are not yet integrated into the basic drawing canvas. Users need to be able to select and use brushes from the tool palette to draw on the canvas. Additionally, the existing brushes need procedural enhancements to create realistic terrain features (rivers with meanders, coastlines with bays, mountain ranges with passes, etc.).

**Current Behavior:**
- Brush system exists but is not wired to the drawing canvas
- Inspector tab exists in tool palette but is unused
- Brush grid placeholder exists but shows no actual brushes
- Generic line drawing brushes work but lack advanced procedural features
- No mechanism to select brushes and have them affect drawing tools

**Desired Behavior:**
- Remove unused Inspector tab from tool palette
- Display functional brush grid that shows all brushes from active brush set
- Filter brushes by active layer type automatically
- Clicking a brush updates the drawing tool (iOS PencilKit and macOS Core Graphics)
- Cross-platform support (iOS and macOS)
- Procedural brushes create realistic terrain features:
  - Rivers with natural meandering and variable width (pressure-sensitive)
  - Coastlines with fractal detail (bays, peninsulas, rocky outcrops)
  - Mountain ridges with passes and interconnected peaks
  - Roads with curve smoothing and optional grid snapping for urban layouts
  - Buildings with bulk random placement and special landmark icons

**Requirements:**
1. Remove Inspector tab from FloatingToolPalette
2. Create BrushGridView component with responsive grid layout
3. Filter brushes by layer type (show only relevant brushes)
4. Wire brush selection to canvas drawing tools (iOS PencilKit + macOS Core Graphics)
5. Enhance River/Stream brushes with procedural meandering
6. Enhance Coastline brush with multi-scale fractal randomization
7. Enhance Ridgeline brush with mountain pass generation
8. Enhance Road brushes with curve smoothing and grid snapping
9. Create procedural Building brush with special icons (churches, museums, stadiums, hospitals, etc.)
10. Support pen pressure for variable width on iOS (Apple Pencil)

**Design Approach:**
- **Architecture Decision:** Procedural brushes render to overlay layers (NOT base layer) to preserve non-destructive workflow
- **UI Integration:** Replace brush grid placeholder with functional BrushGridView
- **Cross-Platform:** iOS uses PencilKit tool creation, macOS stores brush reference for Core Graphics rendering
- **Procedural Generation:** Multi-frequency noise functions for natural terrain features
- **Building System:** Weighted random distribution (70% simple, 30% special buildings)

**Components Affected:**
- ToolPaletteState: Remove Inspector tab enum case
- FloatingToolPalette: Remove Inspector tab view
- ToolsTabView: Replace placeholder with BrushGridView
- DrawingCanvasModel: Add selectedBrush property, updateToolFromBrush()
- DrawingCanvasView: Add cross-platform onChange handler for brush selection
- MacOSDrawingView: Apply brush settings during mouseDown
- BrushEngine: Enhanced renderWaterBrush(), renderRoadBrush() with procedural features
- BrushEngine+Patterns: New procedural generators (generateProceduralRiverPath, generateRiverStrokeWithPressure)
- ProceduralPatternGenerator: Enhanced multi-scale coastline and ridge generation
- BuildingStyle enum: Added 7 new special building types with custom rendering

**Implementation Details:**

### Phase 1: UI Integration

1. **Removed Inspector Tab**
   - ToolPaletteState.swift:67 - Removed `inspector` case from PaletteTab enum
   - FloatingToolPalette.swift:136 - Removed Inspector tab content switch case
   - Cleaned up sample preview helpers

2. **Created BrushGridView Component** (NEW FILE: BrushGridView.swift)
   - Responsive LazyVGrid with 60-80pt adaptive cells
   - Filters brushes by active layer type using MapBrush.requiresLayer
   - Visual selection feedback with accent color borders and fills
   - Displays brush count and active brush set name in header
   - Shows "No brush set active" placeholder when appropriate

3. **Integrated BrushGridView into ToolsTabView**
   - ToolsTabView.swift:422 - Replaced brushGridPlaceholder with BrushGridView(canvasState: $canvasState)
   - Removed placeholder view code (lines 431-451)

4. **Connected Brush Selection to Drawing Canvas**
   - DrawingCanvasModel (DrawingCanvasView.swift:247) - Added `selectedBrush: MapBrush?` property
   - DrawingCanvasView.swift:438-456 - Added `updateToolFromBrush()` method:
     - iOS: Creates PKTool using BrushEngine.createAdvancedPKTool()
     - macOS: Stores brush for Core Graphics rendering
   - DrawingCanvasView.swift:141-147 - Added cross-platform onChange handler watching selectedBrushID
   - MacOSDrawingView.mouseDown() (DrawingCanvasViewMacOS.swift:82-119) - Apply brush color/settings during stroke creation

### Phase 2: Procedural Brush Enhancements

5. **Enhanced River/Stream Brushes** (BrushEngine+Patterns.swift:455-586)
   - `generateProceduralRiverPath()` - Multi-frequency sinusoidal meandering:
     - Freq1 (2π): Primary meander curve (60% amplitude)
     - Freq2 (5π): Secondary variations (30% amplitude)
     - Freq3 (11π): Fine-scale wiggles (10% amplitude)
     - Random variation (30%) for natural irregularity
     - Seeded random for reproducible results
   - `generateRiverStrokeWithPressure()` - Variable-width banks:
     - Calculates perpendicular vectors at each point
     - Supports optional pressure array for pen pressure sensitivity
     - Returns left and right bank point arrays
   - BrushEngine.swift:684-739 - Enhanced renderWaterBrush():
     - Detects "river" or "stream" in brush name
     - Different meander intensity: streams (0.5), rivers (0.7)
     - Renders as filled polygon between banks
     - Adds subtle center line for detail (30% opacity)

6. **Enhanced Coastline Brush** (ProceduralPatternGenerator.swift:81-167)
   - Multi-scale fractal displacement using fbm (fractional brownian motion):
     - **Large scale** (40× width, 3 octaves): Bays and peninsulas (3.0× amplitude)
     - **Medium scale** (15× width, 5 octaves): Inlets and headlands (1.5× amplitude)
     - **Fine scale** (5× width, 6 octaves): Rocky irregularities (0.5× amplitude)
   - Occasional dramatic features (15% probability): Rocky outcrops with 1.8× scale
   - Smooth curves using quadratic Bezier with randomized control points

7. **Enhanced Ridgeline Brush** (ProceduralPatternGenerator.swift:274-401)
   - Mountain pass generation:
     - Sinusoidal pattern (0.15 frequency) identifies potential pass locations
     - 15% of points become passes (saddle points)
     - Passes have reduced elevation (30% of peak height)
     - Variable peak heights (0.7-1.3× base) for dramatic effect
   - Visual pass markers:
     - Shorter hatches (50% length) at pass points
     - Gap symbol (horizontal line) indicating pass
     - Full-length hatches at regular peaks

8. **Enhanced Road Brushes** (BrushEngine.swift:769-846)
   - Automatic curve smoothing (0.5 amount) for highways and standard roads
   - Optional grid snapping for urban layouts (when brush.snapToGrid is true):
     - `applyGridSnapping()` method analyzes stroke direction
     - Snaps to dominant axis (horizontal/vertical) or 45° diagonal
     - Grid size = 2× road width
     - Axes: If dx > 2×dy → horizontal, if dy > 2×dx → vertical
     - Diagonal: Otherwise snap to 45° angle
     - Rounds to nearest grid intersection

9. **Enhanced Building Brush** (BrushEngine+Patterns.swift:215-260, 733-937)
   - Bulk random placement with spatial scatter (±0.5× width)
   - Configurable density parameter (default 1.0)
   - Weighted random distribution via `BuildingStyle.randomWeighted()`:
     - 40% simple rectangles
     - 20% detailed (with roofs)
     - 10% towers (multi-level)
     - 5% churches (steeple + cross)
     - 5% museums (classical columns)
     - 5% government (dome building)
     - 5% stadiums (oval with tiers)
     - 5% hospitals (red cross symbol)
     - 5% schools (window grid)
     - 5% industrial (chimney + smoke)
   - Each building style has custom rendering with architectural details

**Files Modified:**
- ToolPaletteState.swift (line 67) - Removed Inspector tab enum
- FloatingToolPalette.swift (line 136) - Removed Inspector tab view
- **BrushGridView.swift (NEW)** - Complete brush grid component
- ToolsTabView.swift (line 422) - Integrated BrushGridView
- DrawingCanvasView.swift (lines 141-147, 247, 438-456) - Brush selection wiring
- DrawingCanvasViewMacOS.swift (lines 82-119) - macOS brush support
- BrushEngine.swift (lines 684-739, 769-846) - Water and road enhancements
- BrushEngine+Patterns.swift (lines 215-260, 408-586, 733-937) - Procedural generators and building system
- ProceduralPatternGenerator.swift (lines 81-167, 274-401) - Multi-scale coastlines and mountain passes

**Test Steps:**

1. **Brush Grid Display**
   - ✅ Open Cumberland on iOS or macOS
   - ✅ Open tool palette → Tools tab
   - ✅ Verify brush grid displays below base layer controls
   - ✅ Verify brushes are filtered by active layer type
   - ✅ Verify brush count is shown in header

2. **Brush Selection**
   - ✅ Click/tap any brush in the grid
   - ✅ Verify brush highlights with blue border and background
   - ✅ Verify only one brush is selected at a time

3. **Drawing with Selected Brush - iOS**
   - ✅ Select "River" brush from water category
   - ✅ Draw a stroke with Apple Pencil
   - ✅ Verify river appears with natural meandering
   - ✅ Vary pen pressure - verify river width changes
   - ✅ Expected: Realistic river with curves, not straight line

4. **Drawing with Selected Brush - macOS**
   - ✅ Select "Coastline" brush
   - ✅ Draw a stroke with mouse/trackpad
   - ✅ Verify coastline has irregular, fractal-like edges
   - ✅ Expected: Realistic coastline with bays and peninsulas

5. **Procedural River Features**
   - ✅ Select "River" or "Stream" brush
   - ✅ Draw multiple strokes
   - ✅ Verify each river has unique meandering pattern
   - ✅ Verify rivers are filled shapes (not just lines)
   - ✅ Verify subtle center line adds depth

6. **Procedural Coastline Features**
   - ✅ Select "Coastline" brush
   - ✅ Draw a long stroke
   - ✅ Verify large-scale features (bays, peninsulas)
   - ✅ Verify medium-scale features (inlets, headlands)
   - ✅ Verify fine-scale irregularities (rocky edges)
   - ✅ Occasional dramatic rocky outcrops should appear

7. **Mountain Ridge with Passes**
   - ✅ Select "Mountain Ridge" brush
   - ✅ Draw a mountain range stroke
   - ✅ Verify ridge line has peaks and valleys
   - ✅ Verify occasional passes (dips) with shorter hatches
   - ✅ Verify pass markers (horizontal gap lines)
   - ✅ Expected: Mountain range like those surrounding Mordor

8. **Road Curve Smoothing**
   - ✅ Select "Highway" or "Road" brush
   - ✅ Draw a winding road
   - ✅ Verify road has smooth curves (not jagged)
   - ✅ Select "Path" or "Trail" brush
   - ✅ Verify paths remain less smoothed (more natural)

9. **Road Grid Snapping** (if brush has snapToGrid enabled)
   - ✅ Select a road brush with grid snapping
   - ✅ Draw roads at various angles
   - ✅ Verify roads snap to horizontal, vertical, or 45° diagonals
   - ✅ Expected: City-style grid layout

10. **Building Bulk Placement**
    - ✅ Select "Building" or "City" brush
    - ✅ Draw a long stroke across canvas
    - ✅ Verify multiple buildings appear along stroke
    - ✅ Verify buildings have random sizes and positions
    - ✅ Verify mix of building types (simple rectangles, detailed houses, towers)
    - ✅ Verify occasional special buildings:
      - Churches (with steeple and cross)
      - Museums (with columns)
      - Government buildings (with dome)
      - Stadiums (oval with tiers)
      - Hospitals (with red cross)
      - Schools (with windows)
      - Industrial (with chimney and smoke)

11. **Cross-Platform Consistency**
    - ✅ Test same brushes on both iOS and macOS
    - ✅ Verify similar visual results (accounting for platform differences)
    - ✅ Verify brush selection works on both platforms

**Verification Results:**
The brush system integration is complete and functional. Users can now select brushes from the tool palette and draw with them on the canvas. All procedural brush enhancements are working as designed across both iOS and macOS platforms.

**Notes:**
- **Architectural Decision**: Procedural brushes render to overlay layers to preserve non-destructive workflow and protect base layer procedural terrain
- **Performance**: Multi-scale noise functions may be expensive for very long strokes; consider optimization if needed
- **Future Enhancement**: Add brush property inspector to adjust parameters (meander intensity, fractal detail, building density) per-brush
- **Future Enhancement**: Save/load custom brush settings per user preference
- **Building Distribution**: Weighted random ensures realistic mix (most buildings are simple, special buildings are rare)
- **Pen Pressure**: iOS supports Apple Pencil pressure for variable width rivers; macOS uses base width (could support Wacom tablet pressure via NSEvent.pressure)

---

## ER-0005: Remove Redundant Water Brush Types

**Status:** ✅ Verified
**Component:** ExteriorMapBrushSet
**Priority:** Medium
**Date Requested:** 2026-01-08
**Date Updated:** 2026-01-09
**Date Implemented:** 2026-01-09
**Date Verified:** 2026-01-09

**Rationale:**
Several water brush types are redundant with base layer terrain generation or cannot be visually distinguished from each other. Removing them will simplify the water brush palette and align with the unified rendering approach (ER-0007).

**Brushes to Remove:**

1. **Waterfall** - No clear use case; waterfalls should be symbols/icons, not brush strokes
2. **Ocean** - Redundant with base layer ocean/coastal terrain types
3. **Sea** - Redundant with base layer coastal terrain types
4. **Stream** - Visually indistinguishable from River brush; consolidate into single River brush

**Current Behavior:**
- All four brushes exist in ExteriorMapBrushSet.swift
- Listed as water feature brushes alongside River, Lake, Marsh
- Ocean/Sea have custom rendering but duplicate base layer functionality
- Stream and River look identical to users
- Takes up unnecessary space in brush palette

**Desired Behavior:**
- Remove Waterfall, Ocean, Sea, and Stream brushes from ExteriorMapBrushSet
- Water brush palette shows only: **River, Lake, Marsh**
- Ocean/Sea features created via base layer terrain generation instead
- River brush handles all flowing water (consolidates River + Stream functionality)
- Brush grid updates to reflect removals
- No impact on existing saved maps (old brush strokes fall back to simple rendering)

**Requirements:**
1. Remove Waterfall, Ocean, Sea, and Stream brushes from `createWaterBrushes()` in ExteriorMapBrushSet.swift
2. Remove Ocean/Sea rendering functions from BrushEngine.swift:
   - `renderOceanBrush()`
   - `renderSeaBrush()`
3. Verify brush grid no longer shows removed options
4. Ensure no broken references to removed brushes
5. Update brush count if displayed anywhere

**Design Approach:**
- Simple deletion of MapBrush definitions in ExteriorMapBrushSet.swift
- Remove rendering functions from BrushEngine.swift (cleanup)
- No migrations needed (brushID stored in strokes will just not resolve to a brush)
- Falls back to simple rendering if old strokes reference removed brushes

**Components Affected:**
- ExteriorMapBrushSet.swift: Remove brush definitions
- BrushEngine.swift: Remove Ocean/Sea rendering functions (lines ~1166-1400)

**Relationship to ER-0007:**
This removal is part of the larger effort to unify map rendering (ER-0007). By removing Ocean/Sea brushes, we eliminate the need to maintain duplicate rendering logic between base layer and brushes. Lake and River brushes will be redesigned to use elevation-based rendering that matches base layer output exactly.

**Notes:**
- Medium priority - simplifies codebase and aligns with unified rendering vision
- Ocean/Sea features better handled by base layer terrain generation
- Stream functionality preserved within enhanced River brush
- If users request ocean/sea brush features later, point them to base layer terrain types
- Backward compatible: old maps with waterfall strokes will still render (just as simple lines)

**Implementation Details:**

Successfully removed four redundant water brushes from the palette, simplifying the UI and aligning with the unified rendering vision (ER-0007).

### Changes Made:

**1. Removed Brush Definitions** (ExteriorMapBrushSet.swift:198-251)
- Removed `Ocean` brush definition (lines 200-213)
- Removed `Sea` brush definition (lines 214-227)
- Removed `Stream` brush definition (lines 244-259)
- Removed `Waterfall` brush definition (lines 290-303)
- Kept: River, Lake, Marsh (simplified to 3 water brushes)
- Added comment explaining removals and rationale

**2. Removed Rendering Functions** (BrushEngine.swift)
- Removed `renderOceanBrush()` function (~125 lines)
- Removed `renderSeaBrush()` function (~120 lines)
- Removed calls to these functions from `renderWaterBrush()` (lines 915-921)
- Added comment: "ER-0005: Ocean and Sea brushes removed (redundant with base layer)"

**3. Fixed Brush Persistence Issue** (BrushRegistry.swift:134-153)
- **Root Cause**: BrushRegistry was loading persisted brush sets from `Cumberland_BrushSets.json` instead of regenerating built-in sets from code
- **Fix**: Added `refreshBuiltInBrushSets()` function that reloads built-in sets from current code
- **Modified** `init()` to always refresh built-in sets on app launch (not just when no persisted sets exist)
- **Result**: Code changes to built-in brushes are now immediately reflected in the UI
- Preserves custom (non-built-in) brush sets while updating built-in ones

**4. Build Verification**
- ✅ macOS build succeeded with no errors
- ✅ No broken references to removed brushes
- ✅ Water brush palette now shows only: River, Lake, Marsh
- ✅ Removed brushes no longer appear in UI after persistence fix

### Files Modified:
- `Cumberland/DrawCanvas/ExteriorMapBrushSet.swift` (removed 90 lines)
- `Cumberland/DrawCanvas/BrushEngine.swift` (removed ~250 lines)
- `Cumberland/DrawCanvas/BrushRegistry.swift` (added refresh function, ~20 lines)

### Result:
- **Before**: 7 water brushes (Ocean, Sea, River, Stream, Lake, Marsh, Waterfall)
- **After**: 3 water brushes (River, Lake, Marsh)
- 57% reduction in water brush count
- Cleaner, more focused brush palette
- Aligns with ER-0007 unified rendering approach

### Backward Compatibility:
- Existing maps with Ocean/Sea/Stream/Waterfall strokes will render as simple lines
- No data migration required
- BrushID resolution will fail gracefully, falling back to default rendering

**Verification Results:**
User confirmed that the removed brushes (Ocean, Sea, Stream, Waterfall) no longer appear in the Exterior Brushes palette on macOS after the brush persistence fix was implemented.

---
## ER-0006: Display Working Indicator During Base Layer Rendering

**Status:** ✅ Verified
**Component:** MapWizardView, BaseLayerButton, ToolsTabView, DrawingCanvasModel
**Priority:** Medium
**Date Requested:** 2026-01-08
**Date Implemented:** 2026-01-09
**Date Verified:** 2026-01-09

**Rationale:**
When regenerating map drafts in the Map Wizard, the base layer rendering (procedural terrain generation) can take several seconds, leaving the user wondering if the app has frozen. A working indicator or progress bar would provide feedback that the operation is in progress.

**Current Behavior:**
- User clicks "Generate" button in Map Wizard
- Screen appears to freeze with no feedback
- After several seconds, the new map appears
- No indication that processing is happening
- User may click multiple times thinking it's broken

**Desired Behavior:**
- User clicks "Generate" button
- Immediately see a working indicator (spinner/progress bar)
- Progress indicator shows generation is in progress
- Indicator disappears when rendering completes
- Clear visual feedback throughout the process

**Requirements:**
1. Display progress indicator when base layer rendering starts
2. Indicator should be visible and clearly indicate work in progress
3. Dismiss indicator when rendering completes
4. Handle cancellation if user dismisses wizard during rendering
5. Cross-platform support (iOS, macOS, visionOS)

**Design Approach:**
- Use SwiftUI `.overlay()` with `ProgressView()` during rendering
- Track rendering state in `@State` variable (e.g., `isGenerating`)
- Set `isGenerating = true` before calling terrain generation
- Set `isGenerating = false` after completion
- Consider indeterminate progress (spinner) vs determinate (percentage)

**Components Affected:**
- MapWizardView: Add progress overlay during generation
- DrawingCanvasModel: May need to expose rendering state
- LayerManager: Track base layer rendering progress

**Notes:**
- Indeterminate spinner is simplest approach (no progress tracking needed)
- Future: Could add percentage progress if terrain generation reports progress
- Consider adding "Cancel" button for long operations

**Implementation Details:**

The progress indicator has been successfully integrated into the Map Wizard's base layer rendering system using an async/await approach with UI overlays.

### Changes Made:

**1. Added State Management** (DrawingCanvasView.swift:293-296)
- Added `var isGeneratingBaseLayer: Bool = false` to `DrawingCanvasModel` class
- Shared state accessible from all views (MapWizardView, BaseLayerButton, ToolsTabView)
- `@Observable` class ensures automatic UI updates when state changes

**2. MapWizardView - Hamburger Menu** (MapWizardView.swift:2217-2239)
- Created async wrapper `applyBaseLayerFillAsync()`
- Uses `await Task.yield()` to allow UI to update before heavy work
- 0.1s pre-delay ensures progress indicator renders
- 0.3s post-delay ensures indicator stays visible
- Updated menu buttons (lines 840-863) to call async wrapper
- Added progress overlay to both `drawConfigView` and `interiorConfigView` (lines 946-963, 1074-1091)

**3. BaseLayerButton - Tools Palette** (BaseLayerButton.swift:296-388)
- **Primary control used by user** - floating Tools Palette
- Wrapped `applyFill()` to call `applyFillAsync()`
- Wrapped `clearFill()` to call `clearFillAsync()`
- Wrapped `applyCustomColor()` to call `applyCustomColorAsync()`
- All use same async pattern with progress indicator

**4. ToolsTabView - Scale and Water Controls** (ToolsTabView.swift:306-422)
- Added `updateTerrainScaleAsync()` wrapper for scale changes (lines 346-366)
- Added `updateWaterPercentageAsync()` wrapper for water % changes (lines 306-326)
- Scale TextField (line 84) and preset buttons (line 117) now use async wrapper
- Water percentage slider (line 207) uses async wrapper
- Progress indicator shows when zoom or water % adjusted

**5. Progress Overlay** (MapWizardView.swift:946-963, 1074-1091)
- Conditional `.overlay` on DrawingCanvasView
- Checks `drawingCanvasModel.isGeneratingBaseLayer`
- Displays semi-transparent background (`.ultraThinMaterial`)
- Shows animated `ProgressView()` (1.5x size)
- Shows "Generating Base Layer..." text
- Matches canvas rounded rectangle shape

### Technical Approach:

The implementation uses SwiftUI's async/await pattern to provide smooth UI feedback:

1. **Immediate Feedback**: Setting `isGeneratingBaseLayer = true` immediately shows the overlay
2. **UI Update Window**: `await Task.yield()` gives SwiftUI time to render the progress indicator
3. **Synchronous Work**: The actual terrain generation happens synchronously in `applyBaseLayerFill()`
4. **Completion Buffer**: Small delay ensures the canvas finishes rendering before hiding the overlay
5. **Clean Dismissal**: Setting `isGeneratingBaseLayer = false` removes the overlay

### Files Modified:

- `Cumberland/DrawCanvas/DrawingCanvasView.swift` (lines 293-296) - Added `isGeneratingBaseLayer` state to model
- `Cumberland/MapWizardView.swift` (lines 840-863, 946-963, 1074-1091, 2217-2239) - Async wrappers and overlay
- `Cumberland/DrawCanvas/BaseLayerButton.swift` (lines 296-441) - Tools Palette async wrappers
- `Cumberland/DrawCanvas/ToolsTabView.swift` (lines 84, 117, 207, 306-422) - Scale/water async wrappers

### Build Status:
✅ Build succeeded with no errors

### Testing Required:

1. **Base Layer Selection - Exterior**
   - ✅ Open Map Wizard → Draw tab
   - ✅ Select Base Layer menu → Exterior → Any terrain type (Grasslands, Mountains, Desert, etc.)
   - ✅ Verify progress overlay appears immediately
   - ✅ Verify "Generating Base Layer..." message is visible
   - ✅ Verify progress spinner is animated
   - ✅ Verify overlay disappears when generation completes
   - ✅ Expected: 2-5 second generation time with clear visual feedback

2. **Base Layer Selection - Interior**
   - ✅ Open Map Wizard → Interior/Architectural tab
   - ✅ Select Base Layer menu → Interior → Any fill type (Stone Floor, Wood Floor, etc.)
   - ✅ Verify progress overlay appears and dismisses correctly
   - ✅ Expected: Faster generation (< 1 second) but still shows feedback

3. **Map Scale Adjustment**
   - ✅ With Exterior base layer active
   - ✅ Adjust "Width" terrain map size slider or text field
   - ✅ Verify progress overlay appears on each change
   - ✅ Test with different scales: 5 mi, 50 mi, 500 mi
   - ✅ Expected: Larger scales may take longer, progress indicator visible throughout

4. **Removal of Base Layer**
   - ✅ Select Base Layer menu → None
   - ✅ Verify quick feedback (removal is fast)
   - ✅ Verify no visual glitches

5. **Rapid Changes**
   - ✅ Quickly switch between different base layer types
   - ✅ Verify each change shows progress indicator
   - ✅ Verify no overlapping indicators or UI glitches
   - ✅ Expected: Smooth transitions even with rapid clicks

6. **Focus Mode**
   - ✅ Enter focus mode (Cmd+Shift+F)
   - ✅ Select/change base layer while in focus mode
   - ✅ Verify progress overlay works in focus mode
   - ✅ Expected: Same behavior as normal mode

7. **Cross-Platform** (if testing on iOS/iPadOS)
   - ✅ Test same scenarios on iOS/iPadOS
   - ✅ Verify progress overlay scales appropriately for touch interface
   - ✅ Expected: Consistent behavior across platforms

### User Experience Improvements:

- **Before**: Screen appeared frozen during base layer generation, users confused whether app was working
- **After**: Clear visual feedback with animated progress indicator and explanatory text
- **Impact**: Eliminates user anxiety during expensive operations, professional polish

### Verification Results:

**User Tested and Confirmed Working:**
- ✅ Progress indicator appears immediately when selecting base layer from Tools Palette
- ✅ "Generating Base Layer..." message visible with animated spinner
- ✅ Modal/sheet dismisses immediately, indicator shows during 2-5 second generation
- ✅ Works on both macOS and iOS
- ✅ All base layer operations show progress indicator:
  - Base layer selection (Land, Water, etc.)
  - Base layer clearing
  - Custom color application
  - Scale adjustments (zoom)
  - Water percentage adjustments

**Lessons Learned:**
- Initial implementation only covered MapWizardView hamburger menu (rarely used)
- Missed BaseLayerButton in Tools Palette (primary user interface)
- Should have searched entire codebase for all `applyFillToBaseLayer` calls upfront
- Complete implementation required async wrappers in 3 files: MapWizardView, BaseLayerButton, ToolsTabView

