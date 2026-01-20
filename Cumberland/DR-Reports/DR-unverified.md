# Discrepancy Reports (DR) - Unverified Issues

This document tracks discrepancy reports that have been resolved but are awaiting user verification.

**Status:** Currently **5 unverified DRs** (All Open)

---

## DR-0042: Apple Pencil Not Working with Gesture-Based Brushes on iOS

**Status:** 🔴 Open
**Platform:** iOS/iPadOS only
**Component:** DrawingCanvasView / UIPanGestureRecognizer
**Severity:** High
**Date Identified:** 2026-01-19

**Description:**

When using gesture-based brushes (Walls, Furniture/Stamps) on iOS, the Apple Pencil does not trigger the drawing gesture. Only finger touch works. This is inconsistent with the rest of the app where the Apple Pencil works perfectly for all other interactions (tapping to create maps, setting display parameters, moving the tool palette, changing brushes, etc.).

**Current Behavior:**
- **With Finger Touch**: Walls and furniture draw correctly with dotted preview and final rendering
- **With Apple Pencil**:
  - All UI interactions work (tap buttons, move palette, select brushes, etc.)
  - Drawing gestures do NOT work - nothing happens when dragging with Pencil
  - User must switch to finger to draw walls/furniture
  - Area fill brushes (Carpet, Water Feature, Rubble) work fine with Pencil (they use PencilKit)

**Expected Behavior:**
- Apple Pencil should work identically to finger for gesture-based brushes
- When dragging with Pencil over canvas with Wall/Furniture brush selected:
  - Dotted preview should appear
  - Final wall/furniture should render on touch end
- Consistent behavior: if Pencil works for UI, it should work for drawing

**Root Cause:**

The `UIPanGestureRecognizer` added for gesture-based brushes (DR-0031/ER-0004 implementation) is not configured to recognize Apple Pencil touches. By default, `UIPanGestureRecognizer` only recognizes finger touches unless explicitly configured to allow stylus input.

**Affected Code:**

`Cumberland/DrawCanvas/DrawingCanvasView.swift:1226-1229`
```swift
// ER-0004: Add gesture recognizer for advanced brush drawing
let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrawingGesture(_:)))
panGesture.delegate = context.coordinator
canvasView.addGestureRecognizer(panGesture)
```

**Solution:**

Configure the gesture recognizer to accept stylus input:

```swift
let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrawingGesture(_:)))
panGesture.delegate = context.coordinator
panGesture.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber, UITouch.TouchType.stylus.rawValue as NSNumber]
canvasView.addGestureRecognizer(panGesture)
```

**Steps to Reproduce:**
1. Launch app on iPad with Apple Pencil
2. Create interior map
3. Select Wall brush from tool palette
4. Try to draw wall with Apple Pencil
5. **Observe**: Nothing happens - no preview, no wall
6. Try drawing same wall with finger
7. **Observe**: Preview appears, wall draws correctly

**Workaround:**
- Use finger instead of Apple Pencil for walls and furniture
- Area fill brushes (which use PencilKit) work fine with Pencil

**Impact:**
- **High** - Breaks expected workflow for iPad + Apple Pencil users
- Users must constantly switch between Pencil (for UI) and finger (for drawing)
- Inconsistent user experience
- Particularly problematic for architectural work (walls, furniture) where precision is important

**Priority:** High - This significantly degrades the iPad drawing experience

---

## DR-0041: Vegetation and Terrain Brushes Should Render as Area Fills

**Status:** 🔴 Open
**Platform:** All platforms (macOS, iOS, iPadOS)
**Component:** BrushEngine / ExteriorMapBrushSet
**Severity:** Medium
**Date Identified:** 2026-01-19

**Description:**

Several exterior vegetation and terrain brushes currently render as line strokes but should render as area fills (similar to how the Marsh brush works). These brushes represent terrain features that naturally cover areas rather than follow linear paths.

**Affected Brushes:**

**Vegetation Category:**
- Forest
- Single Tree
- Grassland
- Plains
- Jungle

**Terrain Category:**
- Desert
- Tundra

**Special Case:**
- **Farmland** - Should render as area fill with rectangular "fields" pattern

**Current Behavior:**
- These brushes follow the drawn path as a line
- Vegetation/terrain texture applied along the stroke
- No area fill - only renders where the path was drawn
- Inconsistent with Marsh brush which fills enclosed areas

**Expected Behavior:**
- User draws a freeform closed or open path
- Brush fills the enclosed area (or area around path) with appropriate pattern:
  - **Forest**: Dense tree pattern scattered throughout area
  - **Single Tree**: Sparse individual trees
  - **Grassland**: Grass texture fill
  - **Plains**: Open grass/prairie texture
  - **Jungle**: Dense vegetation with variety
  - **Desert**: Sandy texture with occasional dunes
  - **Tundra**: Cold, sparse ground cover
  - **Farmland**: Rectangular field pattern (plowed rows in grid layout)

**Reference Implementation:**
- **Marsh brush** already works this way - fills areas with marsh/wetland texture
- Same rendering approach should apply to vegetation/terrain brushes

**Design Notes:**

1. **Area Detection:**
   - For closed paths: Fill interior
   - For open paths: Could fill area with some buffer distance, or require closed paths

2. **Pattern Distribution:**
   - Trees: Scattered with random spacing (avoid grid appearance)
   - Grassland/Plains: Organic texture fill
   - Desert: Sandy base with dune shapes
   - Farmland: Grid of rectangular fields at consistent angles

3. **Density Control:**
   - Could use brush width parameter to control density
   - Forest: Dense (many trees)
   - Single Tree: Sparse (few trees)
   - Grassland: Medium coverage

**Steps to Reproduce Current Issue:**
1. Create exterior map
2. Select Forest brush
3. Draw closed loop to define forest area
4. **Observe**: Only the path line has forest texture, interior is empty
5. Compare to Marsh brush which fills the interior

**Impact:**
- Users cannot create realistic area-based terrain features
- Have to draw many overlapping strokes to simulate area coverage (tedious)
- Maps look less professional with line-based vegetation
- Inconsistent with realistic map-making (forests are areas, not lines)

**Affected Files:**
- `Cumberland/DrawCanvas/BrushEngine.swift` - May need new area fill rendering for vegetation
- `Cumberland/DrawCanvas/ExteriorMapBrushSet.swift` - Brush definitions
- Possibly need new pattern generators in `Cumberland/DrawCanvas/ProceduralPatternGenerator.swift`

**Related:**
- Marsh brush already demonstrates the desired behavior
- Interior area fill brushes (Carpet, Water Feature, Rubble) work correctly
- This is about extending area fill to exterior terrain brushes

**Priority:** Medium - Affects map quality and user workflow, but has workaround (draw many strokes)

---

## DR-0040: Brush Set Picker Text Overflow on iOS

**Status:** 🔴 Open
**Platform:** iOS/iPadOS only
**Component:** BrushGridView / Tool Palette
**Severity:** Medium
**Date Identified:** 2026-01-19

**Description:**

In the "Brushes for Generic" section of the tool palette on iOS, when a brush set is selected, the UI layout breaks with text overflowing into the section below.

**Current Behavior:**
- Before selection: "Brush Set:" label and count visible with picker arrows (correct)
- After selecting a brush set (e.g., "Basic Tools", "Exterior Brushes"):
  - Picker text has insufficient width
  - Selected brush set name wraps/overflows vertically
  - "Brush Set:" label overflows into next section
  - Brush count (e.g., "42") overflows into next section

**Expected Behavior:**
- Picker should have sufficient horizontal width for full brush set name
- No text should overflow into adjacent sections
- Layout should remain clean and readable

**Steps to Reproduce:**
1. Open iOS app
2. Create any map (interior or exterior)
3. Open tool palette
4. Navigate to "Brushes for Generic" section
5. Tap picker and select a brush set
6. Observe text overflow into section below

**Root Cause:**
Likely insufficient frame width or missing layout constraints for the Picker view on iOS.

**Affected Files:**
- `Cumberland/DrawCanvas/BrushGridView.swift` - Brush selection UI
- Wherever "Brushes for Generic" picker is implemented

**Impact:**
- Poor UX on iOS - UI appears broken
- Difficult to read selected brush set name
- Overlapping text reduces usability

---

## DR-0038: Draft Interior Drawing Settings Not Remembered Between View Loads

**Status:** 🔴 Open
**Platform:** All platforms (macOS, iOS, iPadOS)
**Component:** MapWizardView / Draft Persistence
**Severity:** Medium
**Date Identified:** 2026-01-10

**Description:**

When working on interior/architectural maps in the Map Wizard, drawing settings such as snap to grid, grid type, grid size, and background color (parchment) are not remembered between view loads or app restarts. Users must re-configure these settings every time they return to work on their map draft.

**Current Behavior:**
- User configures interior map settings:
  - Snap to Grid: ON
  - Grid Type: Square
  - Grid Size: 5 ft
  - Background: Parchment
- User draws on map, then dismisses Map Wizard
- User reopens the same map draft
- **Settings are reset to defaults:**
  - Snap to Grid: OFF (or default state)
  - Grid Type: Reset
  - Grid Size: Reset
  - Background: White (instead of Parchment)

**Expected Behavior:**
- All interior map drawing settings should persist with the draft
- When user reopens a draft, settings should restore exactly as configured
- Settings should be specific to each map draft (not global app settings)
- Cross-platform persistence via CloudKit (settings sync between devices)

**Affected Settings:**
1. **Snap to Grid** (toggle) - Reverts to default
2. **Grid Type** (Square/Hex) - Not remembered
3. **Grid Size** (1 ft, 5 ft, 10 ft, Custom) - Not remembered
4. **Background Color** (White, Dark, Parchment, Gray) - Reverts to White

**Impact:**
- User frustration - must reconfigure settings on every session
- Workflow interruption - breaks creative flow
- Inconsistent experience - exterior map settings may persist differently
- Particularly annoying for long-term projects with specific grid requirements

**Steps to Reproduce:**
1. Open Map Wizard → Interior/Architectural tab
2. Create new interior map or load existing draft
3. Configure settings:
   - Toggle "Snap to Grid" ON
   - Set Grid Type to "Square"
   - Set Grid Size to "5 ft"
   - Set Background to "Parchment"
4. Draw some strokes on the canvas
5. Close Map Wizard (or save draft and quit app)
6. Reopen the same map draft
7. **Observe**: Settings have reverted to defaults

**Expected Fix:**

1. **Persist settings in draft data**:
   - Add properties to `Card.draftMapWorkData` or create dedicated settings object
   - Store: `snapToGrid`, `gridType`, `gridSize`, `gridSpacing`, `backgroundColor`
   - Encode/decode with other draft data

2. **Restore settings on draft load**:
   - When loading draft in MapWizardView, extract settings from persisted data
   - Set `@State` variables to match saved settings
   - Apply settings to canvas (grid overlay, snapping behavior, background)

3. **Save settings on change**:
   - Update persisted data when user changes any setting
   - Use auto-save mechanism (similar to stroke persistence)
   - Ensure settings saved before view dismissal

4. **Cross-platform compatibility**:
   - Settings should sync via CloudKit with draft data
   - Verify Codable conformance for all setting types
   - Test on iOS and macOS

**Files Likely Affected:**
- `Cumberland/MapWizardView.swift` - Settings state management, persistence hooks
- `Cumberland/Model/Card.swift` - Draft data structure (may need new properties)
- `Cumberland/DrawCanvas/DrawingCanvasView.swift` - May need to expose settings to persistence layer
- `Cumberland/DrawCanvas/DrawingCanvasModel.swift` - Settings storage in canvas model

**Possible Implementation:**

**Option 1: Extend Draft Map Work Data**
```swift
struct DraftMapWorkData: Codable {
    var layerManagerData: Data?
    var canvasSize: CGSize?
    // NEW: Interior settings
    var snapToGrid: Bool?
    var gridType: String? // "square" or "hex"
    var gridSpacing: Double? // 1.0, 5.0, 10.0, etc.
    var backgroundColor: String? // "white", "parchment", etc.
}
```

**Option 2: Dedicated Settings Object**
```swift
struct InteriorMapSettings: Codable {
    var snapToGrid: Bool = false
    var showGrid: Bool = true
    var gridType: GridType = .square
    var gridSpacing: Double = 5.0
    var gridUnits: String = "ft"
    var backgroundColor: String = "white"
}

// In DraftMapWorkData:
var interiorSettings: InteriorMapSettings?
```

**Notes:**
- This affects user experience significantly for users working on detailed floor plans or dungeon maps
- Snap to grid is particularly important for architectural accuracy
- Background color affects mood and readability (parchment is popular for fantasy maps)
- May be related to how exterior map settings are (or aren't) persisted
- Consider whether these should be per-draft or global app preferences with per-draft overrides

**Related Issues:**
- May be same issue for exterior maps (need to verify if exterior settings persist)
- Grid overlay rendering may also need to respect persisted settings


## DR-0039: Saved Strokes/Settings Failed to Restore During Drawing Canvas Restoration

**Status:** 🔴 Open
**Platform:** macOS (likely affects all platforms)
**Component:** DrawCanvas / Draft Persistence / LayerManager
**Severity:** High
**Date Identified:** 2026-01-11

**Description:**

When restoring a draft interior/architectural map, the saved drawing strokes are not being properly decoded and restored. The draft restoration process shows that stroke data exists (LayerManager with 2 layers is decoded) but the strokes themselves are lost during the import process, resulting in a blank canvas.

**Console Log Evidence:**
```
Restoring draft work for method: Interior / Architectural
[IMPORT] Decoding LayerManager from 729 bytes
[IMPORT] Restored LayerManager with 2 layers
[IMPORT] LayerManager has no content for this platform - falling back to legacy import
[DR-0004.3] importDrawingData called with 2 bytes
[DR-0004.3] Successfully decoded 0 strokes into model
[DR-0012] macOS - Created PKInkingTool with width: 5.0
✅ Restored drawing canvas state
📍 Restored to step: Configure
✅ Draft restoration complete - currentStep: Configure, method: Interior / Architectural
[DR-0004.3] makeNSView called, model has 0 strokes
```

**Key Observations from Logs:**
1. LayerManager decodes successfully (729 bytes → 2 layers)
2. Error message: "LayerManager has no content for this platform"
3. Falls back to "legacy import"
4. Legacy import receives only **2 bytes** of drawing data
5. Result: **0 strokes** successfully decoded
6. Canvas displays blank despite having saved work

**Steps to Reproduce:**
1. Create a new interior/architectural map in Map Wizard
2. Configure settings (grid, background, etc.)
3. Draw several strokes with interior brushes (walls, furniture, etc.)
4. Save/close the map draft (or quit app)
5. Reopen the same draft
6. **Observe**: Canvas is blank, all strokes are gone

**Expected Behavior:**
- All saved strokes should restore correctly
- LayerManager content should be compatible across platforms
- Drawing data should decode completely (not just 2 bytes)
- Canvas should display all previously drawn strokes

**Actual Behavior:**
- LayerManager reports "no content for this platform"
- Falls back to legacy import which receives minimal data (2 bytes)
- Decoding results in 0 strokes
- User loses all their work

**Root Cause Hypotheses:**

**1. Platform-Specific LayerManager Data**
- LayerManager may be saving data in a platform-specific format
- macOS restoration can't read data saved on macOS (self-incompatibility)
- The "no content for this platform" message suggests platform detection logic issue

**2. Drawing Data Encoding Issue**
- Strokes are being saved to LayerManager but not to the legacy format
- Legacy import path expects drawing data in different location/format
- Only 2 bytes being passed suggests data is truncated or pointer/size issue

**3. Codable/Data Corruption**
- LayerManager decodes (729 bytes) but stroke data within is corrupted
- DrawingStroke array may not be properly encoded/decoded
- CloudKit sync could be corrupting binary data

**Files Likely Affected:**
- `Cumberland/DrawCanvas/DrawingCanvasView.swift` - Draft save/restore logic
- `Cumberland/DrawCanvas/DrawingCanvasViewMacOS.swift` - macOS-specific import
- `Cumberland/DrawCanvas/LayerManager.swift` - Layer persistence, platform detection
- `Cumberland/DrawCanvas/DrawingLayer.swift` - DrawingStroke Codable implementation
- `Cumberland/MapWizardView.swift` - Draft orchestration

**Investigation Needed:**

**1. Check LayerManager Platform Logic:**
```swift
// Where is "no content for this platform" message generated?
// What determines platform compatibility?
// Is macOS data being marked as iOS-only or vice versa?
```

**2. Check Drawing Data Export:**
```swift
// In LayerManager or DrawingCanvasView, where is drawing data exported?
// Why are only 2 bytes being passed to legacy import?
// Should legacy import even be used when LayerManager decodes successfully?
```

**3. Check DrawingStroke Encoding:**
```swift
// Verify DrawingStroke.encode() is saving all fields including brushID
// Verify array encoding isn't being truncated
// Check if Optional fields are causing decode failures
```

**4. Check Platform Macro Logic:**
```swift
// Search for #if os(macOS) / #if os(iOS) that might affect persistence
// Ensure macOS can read macOS-saved data (not just cross-platform)
```

**Workarounds:**
- None currently - users lose work when closing/reopening drafts

**Impact:**
- **Critical workflow blocker** - users cannot save work
- Affects all interior map drawing (likely affects exterior maps too)
- Data loss issue - user work disappears
- Prevents iterative map creation over multiple sessions

**Priority:** HIGH - This is a data loss bug that prevents basic app functionality

---

## Template for Adding New DRs

When a new issue is identified or resolved but not yet verified, add it here using this template:

```markdown
## DR-XXXX: [Brief Title]

**Status:** 🟡 Resolved - Not Verified
**Platform:** iOS / macOS / visionOS / All platforms
**Component:** [Component Name]
**Severity:** Critical / High / Medium / Low
**Date Identified:** YYYY-MM-DD
**Date Resolved:** YYYY-MM-DD

**Description:**
[Detailed description of the issue]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Fix Applied:**
[Description of the fix]

**Test Steps:**
1. [How to verify the fix]
2. [Expected results]

---
```

## Status Indicators

Per DR-GUIDELINES.md:
- 🔴 **Identified - Not Resolved** - Issue found and root cause analyzed, awaiting fix
- 🟡 **Resolved - Not Verified** - Claude can mark when implementation is complete
- ✅ **Resolved - Verified** - Only USER can mark after testing

---

*When user verifies a DR, move it to the appropriate DR-verified-XXXX-YYYY.md file*
