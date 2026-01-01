# Enhancement Requests (ER) - Unverified

This document tracks enhancement requests that are proposed, in progress, or implemented but awaiting user verification.

**Status:** Currently **1 active ER**

---

## ER-0001: Interior vs Exterior Canvas Differentiation

**Status:** 🔵 Proposed
**Component:** DrawCanvas, ToolsTabView, BaseLayerButton, TerrainPattern
**Priority:** High
**Date Requested:** 2026-01-01

**Rationale:**
Currently, the base layer dropdown shows all terrain types (exterior) and floor types (interior) regardless of the map type being created. This creates confusion and presents irrelevant options to users. Additionally, interior maps use the same scale units (miles) and show water percentage controls that don't apply to indoor environments. Floor patterns in interior maps should simulate real-world materials with fixed sizes (wood planks, tiles, cobbles) rather than scaling patterns like terrain.

Proper differentiation will:
- Reduce user confusion by showing only relevant base layer options
- Provide appropriate scale units (feet for interiors, miles for exteriors)
- Remove irrelevant controls (water % for interiors)
- Create more realistic floor pattern rendering
- Better match user expectations for interior vs exterior mapping workflows

**Current Behavior:**
1. Base Layer dropdown shows both Exterior (Land, Water, Sandy, etc.) and Interior (Tile, Stone, Wood, etc.) options for all map types
2. Interior maps display "water percentage" slider (not applicable to interiors)
3. Interior maps show scale in "miles" instead of "feet"
4. Floor patterns scale with map scale changes (unrealistic for materials like wood planks, tiles)
5. Wood base layer shows generic wood texture instead of floor planks

**Desired Behavior:**
1. **Exterior Maps**: Base Layer dropdown shows only Exterior terrain types (Water, Land, Sandy, Forested, Mountain, Snow, Ice, Rocky)
2. **Interior Maps**: Base Layer dropdown shows only Interior floor types (Tile, Stone, Wood, Slate, Cobbles, Concrete, Metal)
3. **Interior Maps**: Water percentage slider removed from Tools palette
4. **Interior Maps**: Map scale displayed in "feet" (ft) instead of "miles" (mi)
5. **Interior Maps**: Floor patterns rendered at fixed material scales (don't change size with map scale)
6. **Wood Floor**: Renders as 6-inch planks for realistic flooring appearance

**Requirements:**

1. **Context-Aware Base Layer Menu**
   - Determine if current canvas is Interior or Exterior type
   - Filter BaseLayerButton dropdown to show only relevant fill types
   - BaseLayerFillType.category already exists and can be used for filtering

2. **Interior-Specific UI Adjustments**
   - Hide water percentage slider when base layer category is .interior
   - Change scale unit labels from "mi" to "ft" for interior maps
   - Update scale presets to appropriate foot values (e.g., 10 ft, 50 ft, 100 ft)
   - Preserve all other tool palette functionality

3. **Fixed-Scale Floor Patterns**
   - Floor patterns should render at consistent real-world material sizes
   - Map scale changes should not affect pattern sizes (unlike terrain)
   - Wood, tiles, cobbles, slate, etc. maintain their physical appearance regardless of zoom/scale
   - This simulates how real materials look the same size regardless of viewing distance

4. **Wood Plank Pattern**
   - Generate 6-inch wide plank pattern for wood base layer
   - Planks should have varied length (2-6 feet typical)
   - Include subtle wood grain and slight color variation
   - Realistic spacing/gaps between planks

5. **Map Type Persistence**
   - Store map type (Interior/Exterior) in DrawingCanvasModel or metadata
   - Preserve map type across save/load cycles
   - Use existing MapCreationMethod (.draw = Exterior, .interior = Interior) as source of truth

**Design Approach:**

### Phase 1: Map Type Detection & Storage
1. Add `mapCategory: BaseLayerCategory?` property to DrawingCanvasModel
2. Set this property when map is created via MapWizardView
   - `.draw` method → `.exterior` category
   - `.interior` method → `.interior` category
3. Persist category with map metadata for save/load

### Phase 2: Base Layer Menu Filtering
1. Modify BaseLayerButton to accept map category context
2. Filter BaseLayerFillType options based on canvas category:
   ```swift
   let availableFills = canvasState.mapCategory == .interior
       ? BaseLayerFillType.interiorTypes
       : BaseLayerFillType.exteriorTypes
   ```
3. Update both macOS context menu and iOS sheet to use filtered list
4. Preserve existing UI structure and behavior

### Phase 3: Tools Palette Conditional UI
1. Modify ToolsTabView.terrainScaleControls() to check map category
2. For Interior maps:
   - Change "mi" label to "ft"
   - Update scale presets from [5, 50, 500] to [10, 50, 100] feet
   - Adjust TextField format and display
3. Wrap waterPercentageSlider() in conditional:
   ```swift
   if canvasState.mapCategory != .interior {
       waterPercentageSlider(for: fill)
   }
   ```

### Phase 4: Floor Pattern Rendering
1. Modify TerrainPattern or create new FloorPattern generator
2. Floor patterns should NOT use map scale for noise frequency
3. Instead, use fixed noise parameters based on material type:
   - Wood planks: 6" width, 2-6' length pattern
   - Tiles: 12" × 12" grid pattern
   - Cobbles: 4-8" irregular stone pattern
   - Slate: Large rectangular slabs 18" × 24"
   - Concrete: Subtle texture with expansion joints
   - Metal: Panel grid with rivets/seams
4. Pattern generation ignores physicalSizeMiles, uses fixed pixel-to-material ratio

### Phase 5: Wood Plank Implementation
1. Create plank generation algorithm:
   - Generate horizontal plank rows at 6" intervals (adjusted for canvas scale)
   - Randomize plank lengths (mix of 2', 3', 4', 6' planks)
   - Offset each row for realistic stagger pattern
   - Add wood grain noise within each plank
   - Slight color variation per plank (hue ±5°, brightness ±10%)
   - Thin dark lines for plank separations (1-2px)

**Components Affected:**

- **DrawingCanvasModel** (DrawingCanvasView.swift)
  - Add mapCategory property
  - Update initialization to accept category

- **MapWizardView.swift**
  - Set mapCategory when creating canvas based on selectedMethod
  - Store category in map metadata

- **BaseLayerButton.swift**
  - Filter fill type options based on canvas category
  - Update fillMenuContent and fillMenuList to use filtered types

- **ToolsTabView.swift**
  - Conditional rendering of water percentage slider
  - Unit label changes (mi ↔ ft) based on category
  - Scale preset adjustments for interior maps

- **TerrainPattern.swift or new FloorPattern.swift**
  - Fixed-scale pattern generation for interior materials
  - Wood plank rendering algorithm
  - Material-specific pattern generators

**Implementation Details:**
*To be filled in during implementation phase*

**Files Modified:**
*To be documented during implementation*

**Test Steps:**

### Exterior Map Testing:
1. Create new map using "Draw Map" method
2. Open Tools palette → Base Layer dropdown
3. **Verify**: Only Exterior types shown (Water, Land, Sandy, Forested, Mountain, Snow, Ice, Rocky)
4. Select "Land" base layer
5. **Verify**: Water percentage slider is visible
6. **Verify**: Map scale shows "mi" units with presets 5, 50, 500
7. Change scale from 100 mi to 5 mi
8. **Verify**: Terrain pattern regenerates at new scale

### Interior Map Testing:
1. Create new map using "Interior / Architectural" method
2. Open Tools palette → Base Layer dropdown
3. **Verify**: Only Interior types shown (Tile, Stone, Wood, Slate, Cobbles, Concrete, Metal)
4. Select "Stone" base layer
5. **Verify**: Water percentage slider is NOT visible
6. **Verify**: Map scale shows "ft" units with presets 10, 50, 100
7. Change scale from 100 ft to 50 ft
8. **Verify**: Floor pattern does NOT change size/appearance (fixed material scale)
9. Select "Wood" base layer
10. **Verify**: 6-inch wooden planks visible with realistic grain and stagger pattern
11. Zoom in/out on canvas
12. **Verify**: Plank sizes remain visually consistent

### Save/Load Testing:
1. Create interior map with Wood base layer
2. Save the map
3. Close and reopen the map
4. **Verify**: Map category preserved, base layer dropdown still shows only Interior types
5. **Verify**: Scale still in feet, no water percentage slider

### Edge Case Testing:
1. Create exterior map, select "Land" base layer
2. Switch to different app and background Cumberland (iOS)
3. Return to Cumberland
4. **Verify**: Map type still exterior, all UI elements correct
5. Attempt to manually change a saved interior map's metadata to exterior
6. **Verify**: System handles gracefully or prevents invalid state

**Notes:**

### Design Trade-offs:
- **Fixed-scale floor patterns** mean changing the map scale changes how much of the pattern is visible in the viewport, not the material size itself. This is more realistic but different behavior than terrain scaling.
- **Map category is set at creation time** - users cannot convert an exterior map to interior or vice versa. This is intentional to maintain data consistency.

### Future Considerations:
- Could add "Convert Map Type" function that clears base layer and brushwork when switching between Interior/Exterior
- Material library could be expanded with more floor types (carpet, grass turf for indoor sports, etc.)
- Scale presets could be user-customizable per map type
- Pattern detail level (LOD) could adjust based on zoom level while maintaining material scale

### Alternative Approaches Considered:
1. **Single unified menu with all types** - Rejected because it presents too many irrelevant options
2. **Automatic type detection based on first base layer selected** - Rejected because it's implicit and could cause confusion
3. **Map scale affects floor patterns** - Rejected because it's unrealistic (tiles don't change size in real world)

### Related DRs:
- DR-0016: Procedural terrain generation system (foundation for this work)
- DR-0018: Terrain composition profiles (exterior patterns)
- DR-0018.1, DR-0018.2: Scale and water % persistence (related UI work)

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

*When user verifies an ER, move it to the appropriate ER-verified-XXXX-YYYY.md file*
