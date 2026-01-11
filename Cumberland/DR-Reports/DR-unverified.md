# Discrepancy Reports (DR) - Unverified Issues

This document tracks discrepancy reports that have been resolved but are awaiting user verification.

**Status:** Currently **3 unverified DRs** (2 Open, 1 Resolved - Not Verified)

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

---

## DR-0031: Advanced Brush Rendering Not Executed on Any Platform (Critical Architecture Issue)

**Status:** 🟡 Resolved - Not Verified (macOS complete, iOS pending)
**Platform:** All platforms (macOS, iOS, iPadOS)
**Component:** DrawCanvas/BrushEngine Integration
**Severity:** Critical
**Date Identified:** 2026-01-08
**Date Resolved:** 2026-01-08 (macOS implementation)

**Description:**
When drawing with advanced brushes (River, terrain brushes, vegetation brushes, etc.), only simple bezier curves are rendered instead of the expected procedurally-generated patterns with meandering curves, variable width, and special effects. Setting a breakpoint at `BrushEngine.swift:694` (where advanced river rendering begins) confirms the code is never reached on ANY platform.

**Root Cause Analysis:**

### The Core Problem: BrushEngine is Completely Disconnected

The BrushEngine system exists and contains fully-implemented advanced rendering algorithms for water, terrain, and vegetation brushes. However, **the BrushEngine is never called by the actual drawing code on any platform**. The integration was planned but never completed.

### iOS/iPadOS Drawing Path:
1. **Uses Apple's PencilKit directly** (`DrawingCanvasView.swift:1150-1250`)
   - `PencilKitCanvasView` wraps `PKCanvasView`
   - All drawing handled by Apple's framework
   - Only supports basic `PKInkingTool` with color and width
   - No custom rendering hooks available
   - **BrushEngine never called**

2. **Integration Guide Exists But Not Implemented:**
   - `DrawingCanvasIntegration.swift` contains integration checklist
   - Step 5: "Handle PencilKit integration - Process drawings with custom patterns"
   - **This step was never completed**

### macOS Drawing Path:
1. **Custom NSView drawing** (`DrawingCanvasViewMacOS.swift:362-426`)
   - `drawStroke()` and `drawCurrentStroke()` methods
   - Renders strokes as simple `NSBezierPath` curves with basic color and width
   - No brush category checking, no pattern generation, no procedural effects
   - **BrushEngine never called**

2. **Brush Information Lost:**
   - When a stroke is saved (line 146-154), only basic properties stored: points, color, lineWidth, toolType
   - `selectedBrush` referenced at mouseDown (line 100) but only to get color and width
   - Brush ID, category, and pattern information NOT stored with stroke

### Evidence of Incomplete Implementation:

**File: `DrawingCanvasIntegration.swift`**
- This is an integration GUIDE, not active code
- Contains helper methods showing HOW to integrate BrushEngine
- Includes checklist with step 5: "Process drawings with custom patterns" (NOT DONE)
- Methods like `completeStroke()` (line 52-82) show proper integration pattern
- These methods are **never called** by actual drawing views

**BrushEngine Methods That Should Be Called But Aren't:**
- `BrushEngine.renderAdvancedStroke()` (line 582)
- `BrushEngine.renderWaterBrush()` (line 668)
- `BrushEngine.renderTerrainBrush()` (line 628)
- `BrushEngine.renderVegetationBrush()` (line 752)

**Affected Code:**
- `Cumberland/DrawCanvas/DrawingCanvasView.swift:1150-1250` - iOS PencilKit canvas (no BrushEngine calls)
- `Cumberland/DrawCanvas/DrawingCanvasViewMacOS.swift:362-426` - macOS drawing (no BrushEngine calls)
- `Cumberland/DrawCanvas/DrawingCanvasViewMacOS.swift:136-169` - macOS stroke finalization (no BrushEngine calls)
- `Cumberland/DrawCanvas/DrawingCanvasIntegration.swift` - Integration guide NOT connected to views
- `Cumberland/DrawCanvas/BrushEngine.swift:582-800` - Advanced rendering code exists but never called

**Expected Behavior:**
Drawing with the River brush should produce:
- Natural meandering curves using sinusoidal displacement
- Variable width along the path with tapered ends
- Filled polygon between left/right banks
- Semi-transparent water effect with subtle center line detail
(Per BrushEngine.renderWaterBrush implementation at lines 668-749)

**Actual Behavior:**
- **iOS**: Simple blue line with constant width (PencilKit's basic PKInkingTool rendering)
- **macOS**: Simple blue line with constant width (NSBezierPath basic rendering)
- **Both**: BrushEngine advanced rendering never executed

**Impact:**
- All advanced brush features are non-functional
- Water brushes (River, Stream, Lake Shore, Ocean) render as simple lines
- Terrain brushes render as simple lines
- Vegetation brushes render as simple lines
- The entire procedural brush system is effectively disabled
- Users cannot create maps with the intended artistic effects

**Proposed Solution Architecture:**

### Option 1: Post-Processing Approach (Recommended for iOS)
Since PencilKit doesn't support custom rendering during drawing, process strokes after completion:

1. **Detect Advanced Brush Strokes:**
   - Store brush metadata with each stroke (extend DrawingLayer.CustomStroke to include brushID)
   - When PencilKit stroke completes, check if it was made with an advanced brush

2. **Post-Process with BrushEngine:**
   - Extract stroke path from PKDrawing
   - Call `BrushEngine.renderAdvancedStroke()` to generate procedural pattern
   - Store rendered image in layer alongside original PKDrawing

3. **Composite Rendering:**
   - When displaying: render base layers, then advanced brush renders, then simple strokes

### Option 2: Custom Drawing Layer (Recommended for macOS)
Since macOS uses custom NSView drawing, integrate BrushEngine directly:

1. **Store Brush Metadata:**
   - Update `CustomStroke` to store full brush reference (not just color/width)
   - Preserve brushID, category, and pattern settings

2. **Render in drawStroke():**
   - Check stroke's brush category
   - If advanced brush: call `BrushEngine.renderAdvancedStroke()`
   - If basic brush: use current NSBezierPath rendering

3. **Real-Time Preview:**
   - In `drawCurrentStroke()`: call BrushEngine for live preview
   - Cache rendered segments to avoid re-rendering entire stroke on each mouse move

### Implementation Priority:
1. ✅ macOS first (easier - custom drawing already exists) - COMPLETED
2. ⏳ iOS second (requires post-processing architecture) - PENDING
3. ⏳ Cross-platform stroke format (ensure macOS advanced strokes can sync to iOS and vice versa) - PENDING

---

## macOS Implementation Complete (2026-01-08)

### Changes Made:

**1. Extended DrawingStroke model to store brush metadata** (`DrawingLayer.swift:335`)
- Added optional `brushID: UUID?` field for backward compatibility
- Allows strokes to reference their original brush for advanced rendering

**2. Extended temporary MacOSDrawingStroke** (`DrawingCanvasViewMacOS.swift:675`)
- Added `brushID: UUID?` field to capture brush during active drawing

**3. Updated mouseDown handler** (`DrawingCanvasViewMacOS.swift:82-123`)
- Captures `brush.id` when a brush is selected
- Stores brushID in the temporary stroke structure

**4. Updated mouseUp handler** (`DrawingCanvasViewMacOS.swift:140-178`)
- Includes `brushID` when converting temporary stroke to codable DrawingStroke
- Persists brush metadata with the stroke

**5. Added BrushRegistry helper method** (`BrushRegistry.swift:57-65`)
- New `findBrush(id: UUID)` method searches all installed brush sets
- Enables lookup of brush by ID for rendering previously-saved strokes

**6. Updated drawStroke() method** (`DrawingCanvasViewMacOS.swift:368-455`)
- Checks if stroke has `brushID`
- Looks up brush from BrushRegistry
- If advanced brush: calls `BrushEngine.renderAdvancedStroke()`
- Otherwise: uses standard bezier path rendering

**7. Updated drawCurrentStroke() method** (`DrawingCanvasViewMacOS.swift:457-537`)
- Real-time preview uses BrushEngine for advanced brushes
- Provides immediate visual feedback during drawing

### Technical Details:

**Color Conversion:**
- DrawingStroke stores RGBA as separate CGFloat values
- Converted to SwiftUI Color for BrushEngine: `Color(red: Double, green: Double, blue: Double, opacity: Double)`

**Advanced Brush Detection:**
- Uses `BrushEngine.recommendedRenderingMethod(for: brush) == .advanced`
- Returns `.advanced` for: water, terrain, vegetation categories, or stamp/textured pattern types

**Backward Compatibility:**
- `brushID` is optional - existing strokes without brushID render using standard path
- No migration needed for existing saved drawings

### Files Modified:
- `Cumberland/DrawCanvas/DrawingLayer.swift` - Added brushID to DrawingStroke
- `Cumberland/DrawCanvas/DrawingCanvasViewMacOS.swift` - Capture brushID, integrate BrushEngine rendering
- `Cumberland/DrawCanvas/BrushRegistry.swift` - Added findBrush() helper method

### Build Status:
✅ Build succeeded with no errors

### Testing Required:
1. Launch Cumberland on macOS
2. Open Map Wizard → Draw tab
3. Select River brush from Water Features palette
4. Create a Water Feature layer
5. Draw a curved stroke
6. Verify the River brush renders with:
   - Meandering sinusoidal curves
   - Variable width with tapered ends
   - Filled polygon between banks
   - Semi-transparent water effect
7. Set breakpoint at `BrushEngine.swift:694` to confirm code is now reached

### iOS Implementation (Pending):
iOS requires a different approach since PencilKit doesn't support custom rendering hooks:
- Option A: Post-process PKDrawing strokes after completion
- Option B: Overlay custom-rendered layer on top of PencilKit canvas
- Option C: Hybrid approach - use PencilKit for simple brushes, custom rendering for advanced brushes

---

## Enhanced River Rendering (2026-01-08 - Second Iteration)

### Problem Identified During Testing:
Initial implementation successfully called BrushEngine, but visual effects were too subtle:
- Meandering barely visible (displacement only ~1x stroke width)
- No width variation (constant pressure = 1.0)
- No tapered ends
- Only "spikes" visible from random variation

### Root Causes:
1. **No pressure values passed** - `generateRiverStrokeWithPressure()` called without pressure parameter
2. **Subtle meander intensity** - 0.7 multiplier created minimal displacement
3. **Missing tapering** - No pressure variation meant constant width throughout

### Enhancements Made:

**1. Increased meander intensity** (`BrushEngine.swift:687`)
- Rivers: 0.7 → 1.5 (2.14x more visible)
- Streams: 0.5 → 1.0 (2x more visible)
- Displacement now ~1.5x stroke width instead of ~0.7x

**2. Added synthetic pressure generation** (`BrushEngine+Patterns.swift:534-563`)
- New `generateRiverPressureProfile()` function
- Generates tapered ends (ramps up first 20%, down last 20%)
- Natural width variation using 3 sine wave frequencies
- Pressure ranges from 0.3 to 1.0 (70% width variation)
- Variation profile: slow + medium + fast sine waves

**3. Integrated pressure into rendering** (`BrushEngine.swift:695-701`)
- Generates pressure values for meanderedPath point count
- Passes pressure to `generateRiverStrokeWithPressure()`
- Width now varies naturally along the river path

### Expected Visual Improvements:
- **Meandering**: 2.14x more pronounced curved paths
- **Width variation**: Up to 70% variation (0.3-1.0 pressure)
- **Tapered ends**: Smooth taper over first/last 20% of stroke
- **Natural appearance**: Sine wave variation creates organic look

### Files Modified (Second Iteration):
- `Cumberland/DrawCanvas/BrushEngine.swift` - Increased intensity, added pressure call
- `Cumberland/DrawCanvas/BrushEngine+Patterns.swift` - Added generateRiverPressureProfile()

### Build Status:
✅ Build succeeded with no errors

### Re-Testing Required:
1. Launch Cumberland on macOS
2. Draw new River brush stroke
3. Verify enhanced effects:
   - ✅ More obvious curved/meandering path
   - ✅ Visible width variation along the stroke
   - ✅ Tapered narrow ends at start and finish
   - ✅ Natural organic appearance

---

## Real-Time Performance Fix (2026-01-08 - Third Iteration)

### Problem Identified During Testing:
User reported timing issue:
- Drawing directly: thick blue line with no features
- Drawing with breakpoint at line 695: correct rendering with all features
- Indicates expensive procedural generation can't keep up with real-time drawing

### Root Cause:
`mouseDragged` is called many times per second (30-60+ Hz), each triggering `needsDisplay`, which calls `drawCurrentStroke` with full BrushEngine procedural generation:
- Sinusoidal meander calculation across all points
- Synthetic pressure generation
- Variable-width bank calculation
- This is far too slow for real-time preview

### Solution Implemented:

**Deferred Advanced Rendering Strategy** (`DrawingCanvasViewMacOS.swift:457-505`)

1. **During Active Drawing (mouseDragged):**
   - `drawCurrentStroke()` uses simple bezier path rendering
   - Renders at 50% opacity for advanced brushes (visual hint it's temporary)
   - Fast enough for smooth 60 FPS preview
   - No procedural generation

2. **After Stroke Complete (mouseUp):**
   - Stroke saved with `brushID` metadata
   - `currentStroke = nil` clears the preview
   - `needsDisplay = true` triggers full redraw
   - `drawStroke()` applies full BrushEngine advanced rendering
   - All procedural features appear in final render

### Why This Works:
- **Preview**: Simple path is fast, provides immediate visual feedback
- **Final**: Full advanced rendering only happens once after stroke complete
- **Performance**: 60 FPS preview + beautiful final result

### User Experience:
1. While drawing: Smooth simple path (50% opacity if advanced brush)
2. On release: Path instantly transforms to advanced rendering with all features

### Files Modified (Third Iteration):
- `Cumberland/DrawCanvas/DrawingCanvasViewMacOS.swift` - Simplified drawCurrentStroke()

### Build Status:
✅ Build succeeded with no errors

### Testing Now:
1. Draw River brush stroke normally (no breakpoint needed!)
2. While drawing: Should see smooth simple preview line
3. On release: Line should instantly show meandering, width variation, tapered ends

---

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
