## DR-0016.2: No map scale UI presented when using floating tool palette

**Status:** ✅ Resolved - Not Verified
**Platform:** All platforms (iOS, macOS, visionOS)
**Component:** ToolsTabView / Floating Tool Palette
**Severity:** Medium
**Date Identified:** 2025-12-29

**Description:**
When selecting an exterior base layer through the BaseLayerButton in the floating tool palette, terrain is generated with default scale (100 miles) but no UI is presented to adjust the map scale. The terrain scale selector only appeared in MapWizardView's base layer menu, which users weren't accessing when using the tool palette.

**Steps to Reproduce:**
1. Open drawing canvas with floating tool palette
2. Click "Tools" tab in palette
3. Click "Base Layer" button
4. Select an exterior type (Land, Water, etc.)
5. Observe that terrain is generated but no scale controls appear

**Expected Behavior:**
Terrain scale controls should appear in the floating tool palette below the BaseLayerButton, allowing users to:
- See current scale category (Small/Medium/Large)
- Input custom miles value
- Use quick preset buttons (5 mi, 50 mi, 500 mi)
- See scale description

**Actual Behavior:**
No terrain scale controls visible when using BaseLayerButton from floating tool palette.

**Root Cause:**
The terrain scale UI was only implemented in MapWizardView's drawConfigView, which is only visible when using MapWizardView's base layer menu. When users selected base layers through BaseLayerButton (in the floating tool palette), that UI was not accessible.

**Fix Applied:**

**ToolsTabView.swift** - Added terrain scale controls that appear below BaseLayerButton:

```swift
// DR-0016.2: Show terrain scale controls for exterior base layers
if let fill = canvasState.layerManager?.baseLayerFill,
   fill.fillType.category == .exterior,
   fill.terrainMetadata != nil {
    terrainScaleControls(for: fill)
}

private func terrainScaleControls(for fill: LayerFill) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        // Map Scale header with category badge
        HStack {
            Text("Map Scale")
                .font(.caption)
                .fontWeight(.semibold)
            Spacer()
            Text(scaleCategory(for: fill).displayText)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(.quaternary))
        }

        // Miles input field
        HStack(spacing: 8) {
            TextField("Miles", value: Binding(...), format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
            Text("mi")
        }

        // Quick preset buttons
        HStack(spacing: 6) {
            scalePresetButton(fill: fill, miles: 5, label: "5")
            scalePresetButton(fill: fill, miles: 50, label: "50")
            scalePresetButton(fill: fill, miles: 500, label: "500")
        }

        // Scale description
        Text(scaleCategory(for: fill).description)
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }
}

private func updateTerrainScale(fill: LayerFill, miles: Double) {
    // Recreate metadata with new scale
    let newMetadata = TerrainMapMetadata(
        physicalSizeMiles: miles,
        terrainSeed: fill.terrainMetadata?.terrainSeed ?? Int.random(in: 1...999999)
    )
    
    // Apply updated fill
    let newFill = LayerFill(
        fillType: fill.fillType,
        customColor: fill.customColor,
        opacity: fill.opacity,
        patternSeed: fill.patternSeed,
        terrainMetadata: newMetadata
    )
    canvasState.layerManager?.applyFillToBaseLayer(newFill)
}
```

**Features:**
- Conditionally appears only for exterior base layers with terrain metadata
- Shows current scale category badge (🏘️ Small / 🏙️ Medium / 🌍 Large)
- Allows direct miles input with live update
- Provides quick preset buttons (5, 50, 500 miles)
- Displays scale description explaining terrain composition
- Updates terrain in real-time when scale changes
- Preserves terrain seed to maintain consistent terrain appearance

**Testing:**
After fix, when selecting exterior base layer from tool palette:
1. BaseLayerButton shows selected base layer
2. Terrain scale controls appear immediately below
3. Changing miles value regenerates terrain with new scale
4. Different scales produce different terrain variety (small = uniform, large = diverse)
5. Console shows: `[ToolsTabView] Updating terrain scale to X miles`
6. Console shows: `[ToolsTabView] Scale updated - new category: Y, dominant: Z%`

**Verification Checklist:**
- ✅ Terrain scale UI appears in floating tool palette
- ⏳ UI shows correct current scale value
- ⏳ Miles input field updates terrain
- ⏳ Preset buttons work (5/50/500 mi)
- ⏳ Scale category badge updates correctly
- ⏳ Description text reflects current scale
- ⏳ Terrain regenerates with new dominant percentages

**Related Issues:**
- Parent: DR-0016 (Procedural exterior terrain generation)
- Related: DR-0016.1 (Missing terrain metadata fix)
- Note: Terrain scale UI now available in BOTH locations:
  1. MapWizardView base layer menu (original implementation)
  2. Floating tool palette (new implementation for DR-0016.2)

---


## DR-0016.3: Changing map scale should reseed terrain for fresh pattern

**Status:** ✅ Resolved - Not Verified
**Platform:** All platforms (iOS, macOS, visionOS)
**Component:** ToolsTabView / Terrain Scale Controls
**Severity:** Low
**Date Identified:** 2025-12-29

**Description:**
When changing the map scale in the floating tool palette, the terrain composition changes (different dominant percentages) but the terrain seed was preserved, causing the same elevation pattern to appear with different biome distributions. This made scale changes less impactful visually.

**Rationale:**
Different map scales have fundamentally different terrain compositions:
- **Small scale (< 10 mi)**: 85% dominant type, very uniform (village/battlefield)
- **Medium scale (10-100 mi)**: 75% dominant type, moderate variety (city/region)
- **Large scale (> 100 mi)**: 62.5% dominant type, high diversity (continent/world)

Since the composition changes so dramatically, a fresh terrain pattern (new seed) better showcases the scale difference than reinterpreting the same elevation pattern.

**Expected Behavior:**
Changing map scale should:
1. Update the terrain composition percentages (dominant vs. variety)
2. Generate a completely new terrain pattern (new seed)
3. Produce visually distinct terrains at different scales

**Actual Behavior (Before Fix):**
Changing map scale:
1. Updated terrain composition percentages ✅
2. Preserved the same elevation seed ❌
3. Same terrain pattern with different biome colors (less impactful)

**Root Cause:**
In ToolsTabView.updateTerrainScale(), the code preserved the existing seed:

```swift
// OLD CODE
let newMetadata = TerrainMapMetadata(
    physicalSizeMiles: miles,
    terrainSeed: fill.terrainMetadata?.terrainSeed ?? Int.random(in: 1...999999)
    // ❌ Preserved old seed
)
```

**Fix Applied:**

**ToolsTabView.swift** - Updated to generate new seed on scale change:

```swift
// DR-0016.3: Generate new seed when scale changes
// Different scales have different compositions, so a fresh terrain pattern makes more sense
let newSeed = Int.random(in: 1...999999)

let newMetadata = TerrainMapMetadata(
    physicalSizeMiles: miles,
    terrainSeed: newSeed  // ✅ Always new seed
)

print("[ToolsTabView] Scale updated - new category: \(newMetadata.scaleCategory.rawValue), dominant: \(Int(newMetadata.dominantTerrainPercentage * 100))%, new seed: \(newSeed)")
```

**Note:** MapWizardView already generated new seeds on scale change (it calls `applyBaseLayerFill()` which creates fresh metadata). This fix brings ToolsTabView into parity.

**Benefits of Reseeding:**
1. **More dramatic scale changes** - Completely different terrain each time
2. **Better showcases composition differences** - Not just recoloring, but new patterns
3. **Exploration-friendly** - Users can try different scales to find interesting terrains
4. **Prevents "locked-in" patterns** - No accidentally committing to a terrain pattern early

**Testing:**
After fix, changing scale should:
1. Generate completely new terrain (different valleys, mountains, water placement)
2. Console shows: `[ToolsTabView] Scale updated - ... new seed: XXXXXX` (different each time)
3. Switching between 5 mi → 50 mi → 500 mi produces three distinct terrains
4. Not just color differences, but different elevation patterns

**Verification Checklist:**
- ✅ New seed generated on scale change
- ⏳ Terrain pattern visually distinct after scale change
- ⏳ Switching scales multiple times produces different terrains
- ⏳ Console confirms new seed each time
- ⏳ Works for both ToolsTabView and MapWizardView

**Alternative Considered:**
Could add a "lock seed" toggle to preserve terrain pattern across scales, but:
- Adds UI complexity
- Most users want fresh terrain when changing scale
- Can always regenerate by toggling to different base layer and back
- Decision: Keep simple, always reseed

**Related Issues:**
- Parent: DR-0016 (Procedural exterior terrain generation)
- Related: DR-0016.2 (Terrain scale UI in floating palette)

---


## DR-0016.4: Water base layer produces no water; all maps lack water features

**Status:** ✅ Resolved - Verified (2025-12-31)
**Platform:** All platforms (iOS, macOS, visionOS)
**Component:** BiomeDistributor / Terrain Generation
**Severity:** High
**Date Identified:** 2025-12-29

**Description:**
When generating terrain with any base layer type, no water features appeared in the generated maps. Specifically:
- **Water base layer**: Should produce mostly blue water areas with occasional green islands/coastlines, but showed no water at all
- **Land/Sandy/Mountain base layers**: Should have occasional small lakes or ponds, but had none
- All generated terrains were completely dry with no blue (water) areas visible

**Expected Behavior:**

**Water-dominant map:**
- Mostly blue water areas representing oceans/seas (60-85% depending on scale)
- Occasional green areas representing islands or coastlines (15-40%)
- Natural elevation-based transitions from deep water (dark blue) to shallow (light blue) to beaches (sandy) to land (green)

**Land-dominant map:**
- Mostly green/brown land areas (60-85%)
- Occasional blue water features: lakes, rivers, ponds (5-15%)
- Water appears in lowest elevation areas (valleys)

**Actual Behavior:**
- All maps were completely devoid of water regardless of base layer selection
- Water base layer showed mostly green/land with no blue areas
- Natural biome distribution was completely overridden by dominant type

**Root Cause:**
The dominant type override threshold in BiomeDistributor was far too aggressive:

```swift
// OLD MULTIPLIERS (BROKEN)
case .small: scaleMultiplier = 1.2   // Extremely aggressive
case .medium: scaleMultiplier = 0.8  // Very aggressive
case .large: scaleMultiplier = 0.5   // Still too aggressive
```

**Example calculation showing the problem:**

For **Large scale** (62.5% dominant) with **Land** base layer:
```
threshold = (1.0 - 0.625) × 0.5 = 0.1875

Land natural range: 0.2 - 0.35
Water at elevation 0.05:
  distance from Land range = 0.2 - 0.05 = 0.15
  0.15 < 0.1875 → OVERRIDE TO LAND ❌

Result: Water areas completely eliminated!
```

The threshold of 0.1875 meant any elevation within ±0.1875 of the Land range (0.2-0.35) would be overridden to Land. This covered elevations from 0.0185 to 0.5385 - essentially the entire map!

**Fix Applied:**

**BiomeDistributor.swift** - Drastically reduced override threshold multipliers:

```swift
// DR-0016.4: Use much gentler multipliers to preserve natural biomes
let scaleMultiplier: Double
switch scaleCategory {
case .small:
    scaleMultiplier = 0.15  // Gentle override near dominant range
case .medium:
    scaleMultiplier = 0.10  // Very gentle override
case .large:
    scaleMultiplier = 0.05  // Minimal override, mostly natural distribution
}
```

**New calculation with fixed multipliers:**

For **Large scale** (62.5% dominant) with **Land** base layer:
```
threshold = (1.0 - 0.625) × 0.05 = 0.01875

Water at elevation 0.05:
  distance from Land range = 0.15
  0.15 > 0.01875 → KEEP AS WATER ✅

Land at elevation 0.22:
  within Land range → USE LAND ✅

Sandy at elevation 0.18:
  distance from Land range = 0.02
  0.02 > 0.01875 → KEEP AS SANDY ✅
```

**Impact of Fix:**

**Reduction in override aggressiveness:**
- Small scale: 1.2 → 0.15 (87.5% reduction)
- Medium scale: 0.8 → 0.10 (87.5% reduction)
- Large scale: 0.5 → 0.05 (90% reduction)

**New behavior:**
- Natural biomes preserved at appropriate elevations
- Water appears in valleys (0.0-0.1 elevation range)
- Sandy appears at beaches/deserts (0.1-0.2)
- Land appears at grasslands (0.2-0.35)
- Mountains, cliffs, snow, ice at higher elevations
- Dominant type still shows preference, but doesn't obliterate variety

**Expected Results After Fix:**

**Water-dominant map (62.5% water at large scale):**
- Blue water in valleys and lowlands
- Green islands at higher elevations
- Natural coastline transitions (water → sandy → land)
- Occasional mountain peaks on larger islands

**Land-dominant map (62.5% land at large scale):**
- Green/brown land covering most of map
- Blue lakes/ponds in valleys
- Mountain ranges at high elevations
- Natural water features preserved

**Testing:**
1. Generate Water base layer → Should see blue ocean with green islands
2. Generate Land base layer → Should see green land with blue lakes
3. Generate Mountain base layer → Should see brown/gray peaks with valley water
4. Different scales should affect variety:
   - Small (85% dominant): Very uniform, but still some water
   - Medium (75% dominant): Moderate variety with visible water features
   - Large (62.5% dominant): Significant variety with substantial water areas

**Verification Checklist:**
- ✅ Override thresholds drastically reduced
- ⏳ Water base layer shows blue water with islands
- ⏳ Land base layer shows land with lakes/ponds
- ⏳ All terrain types show appropriate water features
- ⏳ Natural elevation-based biome distribution preserved
- ⏳ Dominant type still has preference but doesn't eliminate variety

**Related Issues:**
- Parent: DR-0016 (Procedural exterior terrain generation)
- Root cause: Original multipliers were designed for much higher variety percentages
- Impact: Completely broke water generation in all terrains

**Design Notes:**
The original multipliers (0.5-1.2) were probably intended for a different algorithm or different percentage targets. The new multipliers (0.05-0.15) work correctly with the current elevation-based distribution algorithm and achieve the intended dominant percentages while preserving natural biome variety.

---


## DR-0016.5: Terrain regenerates on every pan/zoom causing performance issues

**Status:** ✅ Resolved - Verified (2025-12-31)
**Platform:** All platforms (iOS, macOS, visionOS)
**Component:** DrawingCanvasViewMacOS / ProceduralTerrainUIView
**Severity:** High (Performance)
**Date Identified:** 2025-12-31

**Description:**
Base layer terrain generation was running on every redraw of the canvas, including pans, zooms, and window resizes. For a 2048×2048 canvas, this meant:
- Generating a 512×512 elevation map with fractal noise
- Processing ~1 million pixels through biome distribution
- Rendering all terrain colors and variations
- Taking 1-2 seconds per redraw

This made the app feel sluggish and unresponsive during normal canvas interaction.

**Expected Behavior:**
Terrain should be generated once when the base layer is first applied or when terrain parameters change (scale, type, seed). Subsequent redraws should reuse the cached terrain image for instant rendering.

**Actual Behavior:**
Every pan, zoom, or resize triggered full terrain regeneration via the `draw()` method, causing 1-2 second delays.

**Resolution:**

**Fix Date:** 2025-12-31

**Implementation:**

**macOS (DrawingCanvasViewMacOS.swift:60-61, 191-229):**
```swift
// DR-0016.5: Cache rendered terrain to avoid regeneration on every draw
private var terrainCache: [String: CGImage] = [:]

// In draw() method:
let cacheKey = "\(fill.fillType.rawValue)_\(fill.patternSeed)_\(metadata.terrainSeed)_\(Int(fillRect.width))x\(Int(fillRect.height))"

if let cachedImage = terrainCache[cacheKey] {
    // Use cached terrain image (instant)
    context.draw(cachedImage, in: fillRect)
} else {
    // Generate and cache terrain (1-2 seconds, first time only)
    // ... render to bitmap context ...
    terrainCache[cacheKey] = terrainImage
}
```

**iOS (DrawingCanvasView.swift:1516-1558):**
```swift
// DR-0016.5: Cache rendered terrain to avoid regeneration on every draw
private var cachedTerrainImage: UIImage?
private var cachedCacheKey: String?

// Similar caching logic using UIImage instead of CGImage
```

**Cache Key Format:**
`{fillType}_{patternSeed}_{terrainSeed}_{width}x{height}`

Example: `Water_123456_789012_2048x2048`

**Cache Invalidation:**
Cache is invalidated (new key generated) when:
- Base layer type changes (Land → Water)
- Map scale changes (generates new terrainSeed per DR-0016.3)
- Canvas size changes (width/height in key)

**Performance Impact:**
- **First render:** 1-2 seconds (generates and caches)
- **Subsequent renders:** < 0.01 seconds (draws cached image)
- **Memory:** ~16 MB per cached 2048×2048 terrain (RGBA, 4 bytes/pixel)

**Verification Checklist:**
- ✅ Terrain generates once on first display
- ✅ Pan/zoom operations are instant (no regeneration)
- ✅ Resize updates cache with new dimensions
- ✅ Changing base layer type regenerates terrain
- ✅ Changing map scale regenerates terrain (new seed)
- ✅ Console shows "cache miss" once, then cache hits on redraws
- ✅ Works on both macOS and iOS

**Related Issues:**
- Parent: DR-0016 (Procedural exterior terrain generation)
- Related: DR-0016.3 (Scale changes reseed terrain)
- Performance optimization for DR-0016 system

**Files Modified:**
- `DrawingCanvasViewMacOS.swift` - Added terrainCache dictionary and caching logic
- `DrawingCanvasView.swift` - Added cachedTerrainImage and cacheKey to ProceduralTerrainUIView

---


## DR-0017: Welcome step redundant with method selection

**Status:** ✅ Resolved - Verified (2025-12-31)
**Platform:** All platforms (iOS, macOS, visionOS)
**Component:** MapWizardView / Wizard Flow
**Severity:** Low (UX improvement)
**Date Identified:** 2025-12-29

**Description:**
The Map Wizard had two consecutive steps showing essentially the same information:
1. **Welcome step**: Listed all map creation methods with descriptions
2. **Select Method step**: Showed the same methods as interactive cards

This created unnecessary navigation friction - users had to click "Next" on the Welcome screen just to reach the actual method selection buttons.

**Expected Behavior:**
The welcome message and method selection should be merged into a single screen, allowing users to see the welcome message and immediately select their creation method without clicking through an extra step.

**Actual Behavior (Before Fix):**
Users saw a welcome screen that just listed the options, then had to click Next to reach the screen where they could actually select those options.

**Resolution:**

**Fix Date:** 2025-12-31

**Implementation:**

Merged the welcome message with the method selection screen (MapWizardView.swift:324-382):

```swift
private var methodSelectionView: some View {
    VStack(spacing: 24) {
        // DR-0017: Welcome message merged with method selection
        VStack(spacing: 12) {
            Text("Welcome to Cumberland Map Creator")
                .font(.title)
                .bold()

            Text("Create beautiful, professional maps for your tabletop RPG campaigns, worldbuilding projects, or storytelling adventures.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)

            Divider()
                .padding(.vertical, 8)
        }

        // Method selection below welcome message
        VStack(spacing: 16) {
            Text("How would you like to create your map?")
                .font(.title2)
                .bold()

            LazyVGrid(...) {
                // Method cards
            }
        }
    }
}
```

**Changes:**
- Removed `.welcome` case from `WizardStep` enum
- Wizard starts at `.selectMethod` step
- Added welcome header to method selection view with:
  - Title: "Welcome to Cumberland Map Creator"
  - Description of app purpose
  - Divider for visual separation
  - Method selection question and cards below

**User Experience:**
- Users now see welcome message and method selection on the same screen
- No need to click "Next" to reach method selection
- Cleaner, more streamlined wizard flow

**Fix Applied:**

**MapWizardView.swift** - Removed Welcome step entirely:

1. **Removed Welcome case from WizardStep enum:**
```swift
enum WizardStep: String, CaseIterable {
    // DR-0017: Welcome step removed (merged with Select Method)
    case selectMethod = "Select Method"
    case configure = "Configure"  
    case finalize = "Finalize"
}
```

2. **Changed initial step to selectMethod:**
```swift
@State private var currentStep: WizardStep = .selectMethod
```

3. **Removed welcomeStepView and switch case**

4. **Updated navigation logic:**
   - Back button hidden on selectMethod (first step)
   - Reset wizard returns to selectMethod
   - Draft restoration skips to configure

5. **Removed FeatureRow helper view** (only used by Welcome step)

**Changes Summary:**
- Removed ~50 lines of redundant welcome UI code
- Reduced wizard from 4 steps to 3 steps
- Users now start directly at method selection
- Streamlined user experience

**Before (4 steps):**
```
Welcome → Select Method → Configure → Finalize
  ↓          ↓              ↓           ↓
 Info    Choose method   Setup map    Save
(click Next!)
```

**After (3 steps):**
```
Select Method → Configure → Finalize
      ↓            ↓          ↓
 Choose method  Setup map    Save
```

**Benefits:**
- ✅ One less click to start creating a map
- ✅ Faster workflow - go directly to action
- ✅ Less code to maintain
- ✅ Cleaner navigation flow
- ✅ No information loss (method cards show descriptions)

**Testing:**
1. Open MapWizardView
2. Should start directly at method selection (not welcome screen)
3. Should see method cards: Import, Draw, Interior, Maps, AI
4. No "Back" button on first screen (it's the first step)
5. Clicking a method card should proceed to Configure step
6. All existing functionality should work unchanged

**Verification Checklist:**
- ✅ Wizard starts at Select Method
- ⏳ No welcome screen shown
- ⏳ Back button hidden on first step
- ⏳ Reset wizard returns to Select Method
- ⏳ All navigation flows work correctly
- ⏳ Draft restoration still works

**Related Issues:**
- UX improvement suggested by user
- Simplifies wizard flow
- Follows best practice: minimize steps between user and action

# Discrepancy Reports (DR) - Unverified Issues

This document tracks discrepancy reports that have been resolved but are awaiting user verification.

**Status:** Currently **1 unverified DR** (DR-0018 with sub-issues 0018.1 and 0018.2)

---

## DR-0018: Terrain Generation Enhancement - Composition Profiles and UI Improvements

**Status:** ✅ Resolved - Verified
**Platform:** All platforms (iOS, macOS, visionOS)
**Component:** DrawCanvas / TerrainPattern / Map Wizard
**Severity:** Medium (Feature Enhancement)
**Date Identified:** 2025-12-31
**Date Resolved:** 2026-01-01

**Description:**
Enhanced the procedural terrain generation system with terrain-specific composition profiles, improved water percentage control, and various UI/UX improvements for the map scale and water percentage controls.

**Enhancement Components:**

### 1. Terrain-Specific Composition Profiles
Each terrain type now has a unique composition profile that determines how different biome colors appear at different elevations:

**Water (Ocean/Archipelago):**
- 0.0-0.1: Sandy beaches on islands
- 0.1-1.0: Green island interiors (darker at peaks)

**Land (Grasslands/Plains):**
- 0.0-0.05: Sandy shores around water features
- 0.05-1.0: Green grasslands (darker at higher elevations)

**Sandy (Desert):**
- 0.0-0.7: Tan/sandy desert (dominant 70%)
- 0.7-0.9: Rocky outcrops
- 0.9-1.0: Rare mountain peaks

**Forested (Jungle/Forest):**
- 0.0-0.05: Sandy shores
- 0.05-0.2: Green clearings
- 0.2-1.0: Dense teal forest (darker at peaks)

**Mountain (Alpine):**
- 0.0-0.2: Forest/land in valleys
- 0.2-0.5: Green foothills
- 0.5-0.8: Rocky mountainsides
- 0.8-1.0: Dark brown/gray peaks

**Snow (Tundra):**
- 0.0-0.3: Rocky tundra ground (brown)
- 0.3-0.6: White snowfields
- 0.6-0.9: Light blue glaciers
- 0.9-1.0: Snow peaks

**Rocky (Badlands):**
- 0.0-0.3: Sandy/tan base
- 0.3-0.7: Rocky brown
- 0.7-1.0: Dark rocky peaks

**Ice (Arctic):**
- 0.0-0.4: Light blue ice
- 0.4-0.7: Bright white ice
- 0.7-1.0: Snow/ice peaks

### 2. Water Percentage Slider
Added a new UI control in the Tools tab that allows users to override the default water percentage for any terrain type:
- Range: 1% to 90%
- For water terrain type: Slider label shows "Land %" and value is inverted
- For other types: Slider label shows "Water %"
- Includes "Reset to Default" button
- Regenerates terrain with new seed when slider is released (not while dragging)

### 3. Scale-Based Visual Variance
Terrain complexity now varies based on map scale:
- Small maps (< 10 mi): 3-5 octaves, scale 0.3-1.0 (smooth terrain, minimal variance)
- Medium maps (10-100 mi): 5-7 octaves, scale 1.0-2.0 (moderate detail)
- Large maps (≥ 100 mi): 7 octaves, scale 2.0 (high detail, maximum variance)

### 4. Land Shading Direction
Fixed land elevation shading to be intuitively correct:
- Low elevations (valleys): Lighter colors
- High elevations (peaks): Darker colors

### 5. Forest Color Adjustment
Updated forest base color to be more blue-green/teal: `Color(red: 0.15, green: 0.45, blue: 0.30)`

**Implementation:**

**Files Modified:**

1. **TerrainPattern.swift** - Terrain composition system:
   - Added `colorForTerrainComposition()` function (line 223-266)
   - Implemented 8 terrain-specific composition functions (lines 268-383)
   - Each function maps elevation to appropriate colors for that terrain type
   - Replaced simple `colorForLand()` with composition-based approach

2. **ToolsTabView.swift** - Water percentage slider:
   - Added `WaterPercentageSliderView` component (lines 144-228)
   - Implemented deferred regeneration (only on slider release)
   - Shows live percentage while dragging
   - Preserves override when scale changes (lines 232-242)

3. **TerrainMapMetadata.swift** - Water override storage:
   - Added `waterPercentageOverride: Double?` property (line 64)
   - Stores user's custom water percentage preference

4. **MapWizardView.swift** - Base layer state preservation:
   - Modified `applyBaseLayerFill()` to preserve map scale (DR-0018.1)
   - Modified `applyBaseLayerFill()` to preserve water % override (DR-0018.2)

5. **ElevationMap.swift** - Already supported water percentage parameter

---

### DR-0018.1: Map scale resets when changing base layer type

**Status:** ✅ Resolved - Verified

**Problem:** When selecting a different base layer type from the dropdown, the map scale would reset to the default 100 miles instead of preserving the user's custom scale setting.

**Expected:** Map scale should persist when changing terrain type.

**Fix:** Modified `applyBaseLayerFill()` in MapWizardView.swift (lines 2163-2165):
```swift
// DR-0018.1: Preserve existing map scale if available
let existingScale = layerManager.baseLayer?.layerFill?.terrainMetadata?.physicalSizeMiles
let mapScale = existingScale ?? terrainMapSizeMiles
```

**Test Steps:**
1. Open Map Wizard and select "Draw Map"
2. Choose any exterior terrain type (e.g., "Land")
3. Change map scale to 500 miles using the scale slider
4. Switch to a different terrain type (e.g., "Mountain")
5. **Expected:** Map scale remains at 500 miles
6. **Previous behavior:** Would reset to 100 miles

---

### DR-0018.2: Water percentage resets when changing base layer type

**Status:** ✅ Resolved - Verified

**Problem:** When selecting a different base layer type from the dropdown, the water percentage slider would reset to the new terrain type's default, even if the user had set a custom percentage.

**Expected:** Water percentage override should persist when changing terrain type.

**Fix:** Modified `applyBaseLayerFill()` in MapWizardView.swift (lines 2167-2179):
```swift
// DR-0018.2: Preserve existing water percentage override if available
let existingWaterOverride = layerManager.baseLayer?.layerFill?.terrainMetadata?.waterPercentageOverride

// ...create metadata...

// Restore water percentage override
terrainMetadata?.waterPercentageOverride = existingWaterOverride
```

**Test Steps:**
1. Open Map Wizard and select "Draw Map"
2. Choose "Land" terrain type (default 40% water)
3. Adjust water % slider to 25%
4. Switch to "Forested" terrain type (default 60% water)
5. **Expected:** Water % slider remains at 25%
6. **Previous behavior:** Would reset to 60% (Forested default)

---

## Testing Checklist (User Verification Required)

### Terrain Compositions:
- [ ] Water terrain shows sandy beaches on islands
- [ ] Land terrain shows sandy shores at water edges
- [ ] Desert shows mostly tan with rocky outcrops at high elevations
- [ ] Forest shows sandy shores, clearings, and dense forest
- [ ] Mountains show forest→grassland→rocky→peak progression
- [ ] Snow shows rocky tundra, snowfields, glaciers, peaks
- [ ] Rocky shows sandy base transitioning to dark rocky peaks
- [ ] Ice shows light blue to bright white ice zones

### Water Percentage Slider:
- [ ] Slider appears for all exterior terrain types
- [ ] Label shows "Water %" for most types
- [ ] Label shows "Land %" for water terrain type (inverted)
- [ ] Dragging slider updates percentage display smoothly
- [ ] Releasing slider regenerates terrain with new seed
- [ ] No performance issues while dragging
- [ ] Reset button restores terrain type default

### Scale-Based Variance:
- [ ] 5-mile maps show smooth, minimal variance
- [ ] 500-mile maps show moderate detail
- [ ] 1000-mile maps show high detail and complexity

### Settings Persistence:
- [ ] Map scale preserved when changing terrain type (DR-0018.1)
- [ ] Water percentage preserved when changing terrain type (DR-0018.2)
- [ ] Water percentage preserved when changing map scale

---

**Related Files:**
- TerrainPattern.swift (terrain composition implementation)
- ToolsTabView.swift (water percentage slider UI)
- TerrainMapMetadata.swift (water override storage)
- MapWizardView.swift (base layer selection and state preservation)
- ElevationMap.swift (water percentage support)

**Related Issues:**
- Builds on DR-0016 terrain generation system
- Enhances user control over terrain appearance
- Improves visual realism and variety

---

*When user verifies all testing checklist items, this DR can be moved to DR-verified-0011-0018.md*
