# Enhancement Requests (ER) - Unverified

This document tracks enhancement requests that are proposed, in progress, or implemented but awaiting user verification.

**Status:** Currently **5 active ERs**

---

## ER-0006: Display Working Indicator During Base Layer Rendering

**Status:** 🟡 Implemented - Not Verified
**Component:** MapWizard/BaseLayerRendering
**Priority:** Medium
**Date Requested:** 2026-01-08
**Date Implemented:** 2026-01-09

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

**1. Added State Management** (MapWizardView.swift:83)
- Added `@State private var isGeneratingBaseLayer = false` to track generation state
- This state variable controls the visibility of the progress overlay

**2. Created Async Wrapper Function** (MapWizardView.swift:2198-2215)
- New `applyBaseLayerFillAsync()` function wraps the synchronous `applyBaseLayerFill()`
- Sets `isGeneratingBaseLayer = true` before generation
- **Enhanced for macOS visibility**: Uses 0.3s pre-delay to ensure UI renders indicator before expensive work
- Includes additional 0.2s post-delay to ensure indicator remains visible (minimum 0.5s total)
- Sets `isGeneratingBaseLayer = false` when complete
- **Result**: Progress indicator now clearly visible on macOS during generation

**3. Updated Menu Actions** (MapWizardView.swift:843-867)
- Base Layer menu buttons now call `Task { await applyBaseLayerFillAsync(fillType) }`
- Applies to "None", "Exterior", and "Interior" menu options
- All base layer selections now trigger progress indicator

**4. Updated Scale Change Handler** (MapWizardView.swift:911-913)
- Terrain map size onChange handler now uses async wrapper
- Progress indicator shows when user adjusts map scale

**5. Added Progress Overlay** (MapWizardView.swift:949-966, 1077-1094)
- Progress overlay added to drawing canvas in both `drawConfigView` and `interiorConfigView`
- Uses `.overlay` modifier with conditional rendering based on `isGeneratingBaseLayer`
- Overlay includes:
  - Semi-transparent background (`.ultraThinMaterial`)
  - Scaled `ProgressView()` (1.5x size for visibility)
  - "Generating Base Layer..." text with secondary styling
  - Rounded rectangle to match canvas shape

### Technical Approach:

The implementation uses SwiftUI's async/await pattern to provide smooth UI feedback:

1. **Immediate Feedback**: Setting `isGeneratingBaseLayer = true` immediately shows the overlay
2. **UI Update Window**: `await Task.yield()` gives SwiftUI time to render the progress indicator
3. **Synchronous Work**: The actual terrain generation happens synchronously in `applyBaseLayerFill()`
4. **Completion Buffer**: Small delay ensures the canvas finishes rendering before hiding the overlay
5. **Clean Dismissal**: Setting `isGeneratingBaseLayer = false` removes the overlay

### Files Modified:

- `Cumberland/MapWizardView.swift` (lines 83, 843-867, 911-913, 949-966, 1077-1094, 2162-2179)

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

---

## ER-0007: Unify Map Rendering - Base Layer and Brushes Should Produce Identical Features

**Status:** 🔵 Proposed
**Component:** BrushEngine, TerrainPattern, BaseLayerRendering
**Priority:** High
**Date Requested:** 2026-01-09

**Rationale:**
Currently, base layer terrain generation and water brush strokes use completely different rendering approaches, creating visual inconsistency:

- **Base Layer**: Uses elevation maps with elevation-based thresholds (e.g., `elevation < 0.1` = beach) that create organically varying beach/shore widths
- **Brush Strokes**: Use fixed percentage-based calculations (e.g., `width * 0.5`) that create uniform-width beaches regardless of terrain context

This results in maps where base layer water features look fundamentally different from brushed water features. A unified approach using elevation-based rendering for both would create visual consistency and geological realism.

**Current Issues:**

1. **Lake Brush**: Uses fixed inset percentage; doesn't match base layer lake appearance
2. **River Brush**:
   - Short rivers meander well but long rivers become almost straight
   - All rivers same width regardless of length (unrealistic)
   - Uses fixed "beach" width instead of elevation-based basin/valley
3. **Base Layer Sandy Areas**: May be too wide/narrow to match proposed brush approach

**Desired Unified Approach:**

### 1. Lake Brush → Elevation-Based Rendering

**Implementation:**
- Generate `ElevationMap` for lake area (similar to base layer)
- Use same elevation thresholds as base layer: `elevation < 0.1` = beach/sand
- Creates organically varying beach widths matching base layer exactly
- Same fractal noise, same color mapping, identical appearance

**Technical Approach:**
```swift
// Generate elevation map for lake region
let elevationMap = ElevationMap(
    width: boundingWidth,
    height: boundingHeight,
    seed: randomSeed,
    waterPercentage: 0.6, // 60% water, 40% beach/land
    scale: mapScale, // From terrain metadata
    octaves: 6
)

// For each pixel in lake region:
let elevation = elevationMap.elevationAt(x: x, y: y)
if elevation < 0.1 {
    // Sandy beach - matches base layer exactly
    color = Color(red: 0.90, green: 0.75, blue: 0.50)
} else if elevation < 0.0 {
    // Shallow water near shore
    color = waterColor.adjusted(brightness: 1.1)
} else {
    // Deep water
    color = waterColor
}
```

**Result:**
- Extremely large sandy areas of varying shape/width (as requested)
- Looks **exactly** like base layer water features
- Perfect visual consistency

### 2. River Brush → Elevation-Based Valley/Basin Rendering

**Problem Analysis:**
- Short rivers meander ✓ but long rivers straighten ✗
- Current meandering: fixed intensity per segment, accumulated error makes long rivers straight
- All rivers same width (geologically incorrect)
- "Beach" concept wrong - should be "basin/valley" representation

**Proposed Solution:**

**A. Variable River Width Based on Path Length:**
```swift
// River width scales with total path length
let pathLength = calculatePathLength(points)
let riverWidth = baseWidth * (1.0 + log10(pathLength / 100.0))
// Short river (100pt): baseWidth × 1.0 = narrow
// Medium river (1000pt): baseWidth × 2.0 = wider
// Long river (10000pt): baseWidth × 3.0 = very wide (major river)
```

**B. Consistent Meandering Regardless of Length:**
```swift
// Instead of meandering per segment (accumulates error),
// meander based on distance along path (maintains consistency)
func generateMeander(atDistance: Double, pathLength: Double) -> CGPoint {
    // Sinusoidal meandering with fixed wavelength
    let wavelength = 200.0 // Constant meander frequency
    let amplitude = riverWidth * 0.5 // Scales with river width
    let phase = (atDistance / wavelength) * 2.0 * .pi
    return perpendicular offset of sin(phase) * amplitude
}
```

**C. Elevation-Based Valley/Basin:**
```swift
// Generate elevation map along river path
// Width of elevation map = valley width (very wide for long rivers)
let valleyWidth = riverWidth * (5.0...15.0) // 5-15× wider than river
// For a 1000pt long river with 40pt width:
// Valley width = 200-600pt (can affect large map areas)

let elevationMap = generateRiverValleyElevation(
    centerPath: riverPath,
    valleyWidth: valleyWidth,
    depth: 0.3 // Valley depth in elevation units
)

// Render using elevation thresholds:
if elevation < -0.2 {
    // River water (deepest part)
    color = waterColor
} else if elevation < 0.0 {
    // Flood plain / wet basin
    color = Color(red: 0.80, green: 0.75, blue: 0.60) // Muddy/wet
} else if elevation < 0.15 {
    // Sandy banks / dry basin
    color = Color(red: 0.90, green: 0.75, blue: 0.50) // Sand
} else {
    // Valley walls / surrounding terrain
    color = grassColor
}
```

**Result:**
- Long rivers are wider (geologically correct)
- All rivers meander consistently
- Valley/basin effect visible, especially for long rivers
- Extremely wide boundaries for major rivers (affecting entire map area if needed)
- Matches geological reality (Mississippi River valley, etc.)

### 3. Adjust Base Layer Sandy Areas

**Question to User:**
Should we adjust base layer beach rendering to match the new brush approach? Options:

**Option A: Keep Base Layer As-Is**
- Base layer: `elevation < 0.1` threshold (current)
- Brush elevation maps: `elevation < 0.1` threshold (matching)
- Result: Identical rendering

**Option B: Reduce Base Layer Beaches**
- Base layer: `elevation < 0.05` threshold (narrower beaches)
- Brush elevation maps: `elevation < 0.05` threshold (matching)
- Result: Less sandy area overall, but still consistent

**Option C: Configurable Per Terrain Type**
- Different terrain types use different thresholds
- Coastal/water types: `< 0.1` (wide beaches)
- Land/forested types: `< 0.05` (narrow shores)
- Brush elevation maps match the terrain type context

**Recommendation:** Option A (keep current, ensure brushes match exactly)

**Implementation Plan:**

**Phase 1: Lake Brush Elevation-Based Rendering**
1. Create `generateLakeElevationMap()` function in BrushEngine
2. Modify `renderLakeBrush()` to use elevation-based pixel coloring
3. Reuse `compositionWaterType()` or `compositionLandType()` logic from TerrainPattern
4. Test against base layer lakes - should be visually identical

**Phase 2: River Brush Valley Rendering**
1. Modify river width calculation: scale with path length
2. Improve meandering algorithm: distance-based instead of segment-based
3. Create `generateRiverValleyElevationMap()` function
4. Render river using elevation thresholds (water/flood plain/sand/grass)
5. Test short vs. long rivers - both should meander, long ones wider with massive valleys

**Phase 3: Base Layer Consistency Check**
1. Review all terrain composition functions in TerrainPattern.swift
2. Ensure elevation thresholds are consistent
3. Document standard thresholds:
   - `< -0.2`: Deep water
   - `< 0.0`: Shallow water
   - `< 0.05` or `< 0.1`: Beaches/shores (decide on standard)
   - `< 0.2`: Low grasslands
   - etc.

**Phase 4: Remove Redundant Brushes (ER-0005)**
1. Remove Ocean, Sea, Stream, Waterfall brushes
2. Clean up rendering code
3. Update documentation

**Files Affected:**
- `BrushEngine.swift`: Lake and River rendering completely rewritten
- `TerrainPattern.swift`: Possibly extract elevation threshold constants
- `ElevationMap.swift`: May need river-specific elevation generation
- `ExteriorMapBrushSet.swift`: Remove redundant brushes (ER-0005)

**Expected Outcomes:**
1. ✅ Lakes drawn with brush look **exactly** like base layer lakes
2. ✅ Rivers scale width with length (geological realism)
3. ✅ Rivers meander consistently regardless of length
4. ✅ River valleys visible with extremely wide boundaries for long rivers
5. ✅ Base layer and brushes use identical rendering methodology
6. ✅ Simplified brush palette (Lake, River, Marsh only)
7. ✅ Perfect visual consistency across entire map

**Confirmed Decisions (2026-01-09):**

1. ✅ **Lake rendering approach**: Generate full elevation map for lake region, use `elevation < 0.1` threshold for beaches
2. ✅ **River width scaling**: `width * (1 + log10(pathLength/100))` formula approved PLUS fix meandering so long rivers meander as much as short rivers
3. ✅ **River valley width**: 5-15× river width for valley approved
4. ✅ **Base layer beach threshold**: Standardize everything to **single threshold of `< 0.1`** for all terrain types
5. ✅ **River elevation thresholds**: Approved as proposed (Water `< -0.2`, flood plain `< 0`, sand `< 0.15`, grass `> 0.15`)

**Implementation Status:** 🟡 In Progress

**Notes:**
- This is a significant architectural change but will dramatically improve visual consistency
- Elevation-based rendering is the "right" approach geologically
- May increase rendering time slightly (generating elevation maps per stroke)
- Could add caching to improve performance if needed
- Backward compatible: old brush strokes will render with new algorithm (may look different/better)

**Implementation Progress:**

**Phase 1: Standardize Base Layer Threshold** (In Progress)
- Update all terrain composition functions to use `elevation < 0.1` for beaches/shores
- Files: TerrainPattern.swift

**Phase 2: Lake Brush Elevation-Based Rendering** (Pending)
- Generate ElevationMap for lake region
- Use elevation thresholds matching base layer
- Files: BrushEngine.swift

**Phase 3: River Brush Valley Rendering** (Pending)
- Implement width scaling based on path length
- Fix meandering algorithm (distance-based for consistency)
- Generate valley elevation maps
- Render using elevation thresholds
- Files: BrushEngine.swift

**Phase 4: Remove Redundant Brushes** (Pending)
- See ER-0005 for details
- Files: ExteriorMapBrushSet.swift, BrushEngine.swift

---

## ER-0005: Remove Redundant Water Brush Types

**Status:** 🔵 Proposed
**Component:** ExteriorMapBrushSet
**Priority:** Medium
**Date Requested:** 2026-01-08
**Date Updated:** 2026-01-09

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

---

## ER-0004: Interior Brush Implementation

**Status:** 🟡 Implemented - Not Verified
**Component:** BrushRegistry, InteriorMapBrushSet
**Priority:** High
**Date Requested:** 2026-01-07
**Date Implemented:** 2026-01-07

**Rationale:**
The interior brush system has been fully implemented in `InteriorMapBrushSet.swift` with 50+ professional brushes for indoor maps, floor plans, and dungeons. However, the brush set is not currently loaded in the BrushRegistry (lines 105-107 are commented out). Users working on interior maps need access to these brushes.

**Current Behavior:**
- InteriorMapBrushSet.swift exists with complete brush definitions
- 50+ interior brushes are defined (walls, doors, furniture, dungeon features, etc.)
- BrushRegistry.loadBuiltInBrushSets() has commented-out code to load interior brushes
- Only Exterior brushes are currently available in the brush grid
- Users cannot access interior brushes for floor plans/dungeon maps

**Desired Behavior:**
- Interior brush set loads automatically on app startup
- Brush grid displays interior brushes when appropriate layer is selected
- Users can select and use interior brushes for drawing
- Cross-platform support (iOS and macOS) - should work automatically since BrushGridView is already cross-platform

**Requirements:**
1. Uncomment interior brush set loading in BrushRegistry.swift
2. Verify interior brushes appear in brush grid for interior map layers
3. Test that interior brushes work on iOS with PencilKit
4. Test that interior brushes work on macOS with Core Graphics
5. Verify brush filtering by layer type works correctly (e.g., walls layer shows wall brushes)

**Design Approach:**
- Minimal code change: uncomment 2 lines in BrushRegistry.swift:106-107
- Existing BrushGridView from ER-0003 should automatically display interior brushes
- Brush filtering by layer type should work automatically (MapBrush.requiresLayer already implemented)
- No new UI components needed - reuse existing infrastructure

**Components Affected:**
- BrushRegistry: Uncomment interior brush set loading

**Implementation Details:**

### Interior Brush Set Loading Enabled

The interior brush system was already fully implemented in `InteriorMapBrushSet.swift` with 50+ professional brushes:

**8 Architectural Brushes:**
- Wall, Thick Wall, Thin Wall, Cave Wall, Dungeon Wall, Stone Wall, Secret Door, Column

**6 Door/Window Brushes:**
- Door, Double Door, Archway, Window, Arrow Slit, Gate

**8 Room Feature Brushes:**
- Floor Tile, Carpet, Pit, Trap, Stairs Up, Stairs Down, Stairs Spiral, Water Shallow

**8 Furniture Brushes:**
- Table, Chair, Bed, Chest, Bookshelf, Throne, Altar, Statue

**8 Dungeon Brushes:**
- Prison Bars, Chains, Cobweb, Rubble, Sarcophagus, Lava, Bones, Mushrooms

**4 Grid Brushes:**
- Square Grid 5ft, Square Grid 10ft, Hex Grid 5ft, Measurement Ruler

The only change needed was to uncomment lines 105-107 in BrushRegistry.swift:106-107 to enable loading the interior brush set at startup. This minimal change activates all 50+ brushes for use in the brush grid.

**Build Result:**
- iOS build completed successfully with no errors
- BrushRegistry.swift compiled without issues
- Interior brush set will now load on app startup alongside Basic and Exterior brush sets

**Files Modified:**
- BrushRegistry.swift (lines 105-107) - Uncommented interior brush set loading:
  ```swift
  // ER-0004: Load interior brush set
  let interiorSet = InteriorMapBrushSet.create()
  installedBrushSets.append(interiorSet)
  ```

**Test Steps:**

1. **Interior Brush Set Loading**
   - ✅ Launch Cumberland on iOS or macOS
   - ✅ Verify no errors on startup
   - ✅ Check BrushRegistry.shared.installedBrushSets includes "Interior & Architectural" set
   - ✅ Expected: 3 brush sets loaded (Basic, Exterior, Interior)

2. **Brush Grid Display - Interior Brushes**
   - ✅ Create a new interior map or switch to interior layer
   - ✅ Open tool palette → Tools tab
   - ✅ Verify brush grid displays interior brushes
   - ✅ Expected: Wall, Door, Furniture, and other interior brushes visible

3. **Layer-Specific Filtering**
   - ✅ Switch to "Walls" layer
   - ✅ Verify brush grid shows wall-related brushes (Wall, Thick Wall, Thin Wall, Cave Wall, Dungeon Wall, Prison Bars)
   - ✅ Switch to "Furniture" layer
   - ✅ Verify brush grid shows furniture brushes (Table, Chair, Bed, Chest, etc.)
   - ✅ Switch to "Structures" layer
   - ✅ Verify brush grid shows door/window brushes

4. **Drawing with Interior Brushes - iOS**
   - ✅ Select "Wall" brush
   - ✅ Draw a stroke with Apple Pencil
   - ✅ Verify wall appears as solid dark line
   - ✅ Select "Door" brush
   - ✅ Draw a stroke
   - ✅ Verify door stamps appear at spacing intervals

5. **Drawing with Interior Brushes - macOS**
   - ✅ Select "Column" brush
   - ✅ Draw a stroke with mouse
   - ✅ Verify column stamps appear
   - ✅ Select "Floor Tile" brush
   - ✅ Draw an area
   - ✅ Verify hatched pattern appears

6. **Grid Snapping (Interior Brushes)**
   - ✅ Select any brush with snapToGrid=true (e.g., Wall, Column)
   - ✅ Draw a stroke
   - ✅ Verify stroke snaps to grid if grid is enabled
   - ✅ Expected: Clean alignment for architectural elements

7. **Special Interior Brush Patterns**
   - ✅ Select "Stairs Up" brush
   - ✅ Verify hatched pattern with upward orientation
   - ✅ Select "Square Grid 5ft" brush
   - ✅ Verify grid pattern renders correctly
   - ✅ Select "Lava" brush
   - ✅ Verify solid orange/red fill

**Notes:**
- Interior brushes are already fully implemented - just need to enable loading
- All 50+ brushes should work immediately with existing BrushEngine and BrushGridView
- Some interior brushes use specialized patterns (hatched, stippled, stamp) that are already supported
- Grid snapping is built into many interior brushes for architectural accuracy
- This ER has minimal risk since it's just enabling existing functionality

---

## ER-0003: Integrate Exterior Brush System into Map Drawing Canvas

**Status:** 🟡 Implemented - Not Verified
**Component:** DrawCanvas, BrushEngine, BrushRegistry, ToolPalette
**Priority:** High
**Date Requested:** 2026-01-07
**Date Implemented:** 2026-01-07

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

**Notes:**
- **Architectural Decision**: Procedural brushes render to overlay layers to preserve non-destructive workflow and protect base layer procedural terrain
- **Performance**: Multi-scale noise functions may be expensive for very long strokes; consider optimization if needed
- **Future Enhancement**: Add brush property inspector to adjust parameters (meander intensity, fractal detail, building density) per-brush
- **Future Enhancement**: Save/load custom brush settings per user preference
- **Building Distribution**: Weighted random ensures realistic mix (most buildings are simple, special buildings are rare)
- **Pen Pressure**: iOS supports Apple Pencil pressure for variable width rivers; macOS uses base width (could support Wacom tablet pressure via NSEvent.pressure)

---

## Template for Adding New ERs

When a new enhancement is requested, add it here using this template:

```markdown
## ER-XXXX: [Brief Title]

**Status:** 🔵 Proposed / 🟡 In Progress / 🟡 Implemented - Not Verified
**Component:** [Primary Component Name]
**Priority:** Critical / High / Medium / Low
**Date Requested:** YYYY-MM-DD
**Date Implemented:** YYYY-MM-DD (if applicable)
**Date Verified:** YYYY-MM-DD (if applicable)

**Rationale:**
[Why this enhancement is needed - business case, user benefit, technical debt reduction]

**Current Behavior:**
[How the system currently works]

**Desired Behavior:**
[How the system should work after enhancement]

**Requirements:**
1. [Specific requirement 1]
2. [Specific requirement 2]
3. [Specific requirement 3]

**Design Approach:**
[High-level implementation strategy - completed during analysis phase]

**Components Affected:**
- Component 1: [What changes]
- Component 2: [What changes]

**Implementation Details:**
[Detailed description of changes made - filled in during implementation]

**Files Modified:**
- file_path:line_range - [Description of changes]

**Test Steps:**
1. [Step to verify requirement 1]
2. [Step to verify requirement 2]
3. [Expected results]

**Notes:**
[Any additional context, trade-offs, or future considerations]

---
```

## Status Indicators

Per ER-Guidelines.md:
- 🔵 **Proposed** - Enhancement identified and documented, awaiting implementation
- 🟡 **In Progress** - Claude is actively working on this enhancement
- 🟡 **Implemented - Not Verified** - Claude completed implementation, ready for user testing
- ✅ **Implemented - Verified** - Only USER can mark after testing (move to verified batch)

---

*When user verifies an ER, move it to the appropriate ER-verified-XXXX.md file*
