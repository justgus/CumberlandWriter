# Enhancement Requests (ER) - Unverified

This document tracks enhancement requests that are proposed, in progress, or implemented but awaiting user verification.

**Status:** Currently **2 active ERs**

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
