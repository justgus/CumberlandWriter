# Discrepancy Reports (DR)

This document tracks all identified discrepancies in the Cumberland application.

## DR-0001: DrawCanvas paints white for black on iOS

**Status:** ✅ Resolved - Verified
**Platform:** iPadOS
**Component:** MapWizardView / DrawCanvas
**Severity:** Medium

**Description:**
In MapWizardView when the wizard option selected is "Draw", the drawing canvas presents black as a color option. However, on iPadOS when the black color option is selected, the line drawn is white.

**Steps to Reproduce:**
1. Open MapWizardView
2. Select "Draw" option in wizard
3. Select black color from color picker
4. Draw on canvas

**Expected Behavior:**
Black color selection should draw black lines on the canvas.

**Actual Behavior:**
Black color selection draws white lines on the canvas.

**Additional Notes:**
- All other colors (gray, red, orange, yellow, green, blue, purple) work correctly
- Issue is specific to black color only
- Suggests color inversion or special handling of black color in conversion

**Date Identified:** 2025-12-04

**Fix Attempts:**

*Attempt 1 - 2025-12-04:*
- **Solution:** Implemented Option C from development plan - Color Extension Helper
- **Result:** ❌ Unsuccessful - Issue persists
- **Implementation Details:**
  - Added `toPencilKitColor()` extension method to fix color conversion
  - Updated three color conversion sites
  - Color conversion fix did not resolve the issue
- **Conclusion:** Root cause is not in color conversion. See DR-0002 and DR-0003 for related issues suggesting tool update propagation problem.

**Related Issues:**
- See DR-0002: Toolbar brush type selection not responding
- See DR-0003: Brush size control has no effect
- All three issues share the same root cause (see Attempt 2 below)

*Attempt 2 - 2025-12-04:*
- **Solution:** Added tool change counter to force SwiftUI updates
- **Result:** ⚠️ **PARTIAL SUCCESS** - Fixed DR-0002 and DR-0003, but DR-0001 persists
- **Root Cause:** PKTool does not conform to Equatable, so SwiftUI was not detecting tool changes
- **Implementation:**
  1. Added `toolChangeCounter` property to `DrawingCanvasModel` (DrawingCanvasView.swift:144)
  2. Increment counter in `updateTool()` method at 3 locations (lines 225, 229, 239)
  3. Added `.id(canvasState.toolChangeCounter)` to PencilKitCanvasView (line 58)
- **Successfully fixed DR-0002 and DR-0003** (verified on device)
- **DR-0001 still occurs** - black color issue is NOT a tool update problem

**Critical New Observations (2025-12-04):**

*Initial observation:*
- **ONLY pure black (RGB 0,0,0) fails** - even near-black colors work correctly
- Black either appears white OR acts like an eraser (user cannot distinguish)
- Tool updates now work (proven by DR-0002/0003 fixes), so issue is in color value itself

*Further testing - BREAKTHROUGH (2025-12-04):*
- **COLORS ARE BEING INVERTED** - This is a systematic inversion problem, not just black!
- Black (RGB 0,0,0) → White (RGB 255,255,255)
- As colors darken toward black, they lighten toward white (and vice versa)
- Red stays red, but darkening red toward black causes it to lighten toward pink/white
- This explains why "near-black" appeared to work - they were inverted to near-white
- **Root cause:** Color inversion happening at PencilKit rendering level or blend mode issue

*Attempt 3 - 2025-12-04:*
- **Solution:** Force PKCanvasView to light mode with `overrideUserInterfaceStyle = .light`
- **Hypothesis:** PKCanvasView was inverting colors in response to dark mode
- **Implementation:** Added `canvasView.overrideUserInterfaceStyle = .light` in DrawingCanvasView.swift:708
- **Result:** ✅ **SUCCESS** - Verified on device
- **Verified:** Colors now render correctly on iPadOS in dark mode
  - Black draws black (not white)
  - Dark colors remain dark (no inversion)
  - Color gradients work correctly

---

## DR-0002: Toolbar brush type selection not responding on iOS

**Status:** ✅ Resolved - Verified
**Platform:** iOS/iPadOS
**Component:** DrawingCanvasView / DrawingToolbar
**Severity:** High

**Description:**
On iOS, when a brush type (pencil, pen, marker) is selected from the default toolbar, the selection does not respond or take effect. However, the eraser tool selects and functions properly.

**Steps to Reproduce:**
1. Open MapWizardView
2. Select "Draw" option in wizard
3. Tap on pencil, pen, or marker tool in toolbar
4. Attempt to draw on canvas

**Expected Behavior:**
Selected brush type should become active and affect drawing behavior.

**Actual Behavior:**
Brush type selection appears to have no effect. Drawing continues with previous tool or default tool.

**Additional Notes:**
- Eraser tool works correctly
- Suggests the issue is specific to inking tools, not all tools
- Related to DR-0001 and DR-0003 - may indicate tool update not propagating to PKCanvasView

**Date Identified:** 2025-12-04

**Resolution:**
- **Fix Date:** 2025-12-04
- **Verification Date:** 2025-12-04
- **Solution:** Unified fix with DR-0001 and DR-0003 using tool change counter
- **Root Cause:** PKTool not Equatable, SwiftUI wasn't detecting tool type changes
- **See DR-0001 for complete implementation details**
- **Verified:** Pen, pencil, and marker selection now work correctly on iPadOS

---

## DR-0003: Brush size control has no effect on iOS

**Status:** ✅ Resolved - Verified
**Platform:** iOS/iPadOS
**Component:** DrawingCanvasView / DrawingToolbar
**Severity:** Medium

**Description:**
On iOS, the brush size slider control changes its value correctly in the UI, but the selected size has no effect on the actual line width drawn on the canvas.

**Steps to Reproduce:**
1. Open MapWizardView
2. Select "Draw" option in wizard
3. Adjust brush size slider
4. Draw on canvas
5. Change brush size slider to different value
6. Draw again

**Expected Behavior:**
Line width should change according to the brush size slider value.

**Actual Behavior:**
Line width remains constant regardless of brush size slider setting.

**Additional Notes:**
- Slider UI updates correctly
- Value change is registered but not applied to drawing
- Related to DR-0001 and DR-0002 - suggests tool updates not propagating to PKCanvasView
- Likely same root cause as DR-0002

**Date Identified:** 2025-12-04

**Resolution:**
- **Fix Date:** 2025-12-04
- **Verification Date:** 2025-12-04
- **Solution:** Unified fix with DR-0001 and DR-0002 using tool change counter
- **Root Cause:** PKTool not Equatable, SwiftUI wasn't detecting width changes in tool
- **See DR-0001 for complete implementation details**
- **Verified:** Brush size slider now correctly affects line width on iPadOS

---

## DR-0004: Strokes drawn on DrawingCanvas change position when zoomed (macOS only)

**Status:** ✅ Resolved - Verified
**Platform:** macOS
**Component:** DrawingCanvasView / MacOSScrollableCanvas
**Severity:** High

**Description:**
On macOS only, strokes drawn on the DrawingCanvas appear at incorrect positions after the canvas is zoomed. The strokes appear displaced from where the user actually drew them, making the drawing canvas unusable at zoom levels other than 100%.

**Steps to Reproduce:**
1. Open DrawingCanvas on macOS
2. Zoom the canvas to any level other than 100% (e.g., 150% or 200%)
3. Draw strokes on the canvas
4. Observe stroke positions

**Expected Behavior:**
Strokes should appear exactly where the user draws them, regardless of zoom level.

**Actual Behavior:**
Strokes appear displaced from the actual drawing position. The displacement increases with higher zoom levels.

**Root Cause Analysis:**
In `DrawingCanvasView.swift:880-896`, the `MacOSScrollableCanvas` applies both a frame resize and a scale effect:

```swift
DrawingCanvasViewMacOS(canvasState: $canvasState)
    .frame(
        width: canvasState.canvasSize.width * canvasState.zoomScale,
        height: canvasState.canvasSize.height * canvasState.zoomScale
    )
    .scaleEffect(canvasState.zoomScale)  // <-- Transforms coordinate space
```

The `.scaleEffect()` modifier transforms the view's coordinate system, which affects mouse event coordinates. When the user clicks on the scaled view:

1. Mouse events arrive in the transformed (scaled) coordinate space
2. `MacOSDrawingView.mouseDown/mouseDragged/mouseUp` use `convert(event.locationInWindow, from: nil)` to get coordinates in the view's coordinate system
3. However, the coordinate system has been scaled by `.scaleEffect()`, so the coordinates are in scaled space
4. The drawing operations render these scaled coordinates, but the view bounds remain at the original canvas size
5. This mismatch causes strokes to appear displaced

**Technical Details:**
- The NSView's bounds are set to the original `canvasSize` (no zoom applied at NSView level)
- SwiftUI's `.scaleEffect()` creates a visual transform but also affects hit-testing and coordinate conversion
- Mouse event coordinates need to be adjusted by the zoom scale to compensate for the transformation

**Date Identified:** 2025-12-12

**Fix Approach:**
Pass the current `zoomScale` from the `DrawingCanvasModel` to `MacOSDrawingView`, and divide mouse event coordinates by the zoom scale to convert from scaled coordinate space back to the canvas's unscaled coordinate space. This ensures strokes are recorded at their correct unscaled positions.

**Implementation (2025-12-12):**

1. **Added `zoomScale` property to `MacOSDrawingView`** (DrawingCanvasViewMacOS.swift:45)
   - Property stores the current zoom scale
   - Used to adjust mouse coordinates during event handling

2. **Updated `DrawingCanvasViewMacOS` to pass zoom scale** (DrawingCanvasViewMacOS.swift:22, 32)
   - `makeNSView`: Initialize view with current zoom scale
   - `updateNSView`: Update zoom scale when canvas state changes

3. **Adjusted mouse event coordinates** (DrawingCanvasViewMacOS.swift:84, 107)
   - `mouseDown`: Divide coordinates by `zoomScale` before storing
   - `mouseDragged`: Divide coordinates by `zoomScale` before appending to stroke
   - Conversion formula: `CGPoint(x: rawLocation.x / zoomScale, y: rawLocation.y / zoomScale)`

**Result (Initial Fix):**
Strokes are now recorded in unscaled canvas coordinates, compensating for SwiftUI's `.scaleEffect()` transformation. This fixed the relative positioning of strokes.

**Follow-up Issue:**
After initial fix, strokes remained correctly positioned relative to each other, but the entire canvas shifted when zoom changed. Strokes moved down/left when zooming in, up/right when zooming out.

**Root Cause (Offset Issue):**
The `MacOSScrollableCanvas` was applying **both** frame resizing and scale effect:
```swift
.frame(width: canvasSize.width * zoomScale, height: canvasSize.height * zoomScale)
.scaleEffect(canvasState.zoomScale)
```
This created a compound scaling effect and offset, as the frame was being resized AND then scaled again.

**Second Fix (2025-12-12):**
Removed the frame resizing multiplication, keeping only the original canvas size (DrawingCanvasView.swift:942-945):
```swift
.frame(width: canvasState.canvasSize.width, height: canvasState.canvasSize.height)
.scaleEffect(canvasState.zoomScale)
```
Now only `.scaleEffect()` handles the zoom, eliminating the offset issue while the coordinate transformation in mouse events compensates for the scale.

**Testing Status:**
✅ Verified on macOS at various zoom levels (100%, 101%, 98%, 150%, 200%, etc.)
**Verification Date:** 2025-12-14

### DR-0004.1: ScrollView extent shrinks when zoomed in (macOS)

**Status:** ✅ Resolved - Verified (2025-12-14)
**Severity:** Medium

**Description:**
After fixing the initial zoom positioning issues, a new problem emerged: when zoomed in, the ScrollView's scrollable area did not extend to the full zoomed canvas. The scroll extent got smaller as zoom increased, preventing users from scrolling to the corners of the zoomed canvas.

**Root Cause:**
SwiftUI's `.scaleEffect()` is a visual transform that doesn't affect layout. The ScrollView was still calculating content size based on the original (unscaled) canvas dimensions, not accounting for the scaled size.

**Fix (2025-12-12):**
Wrapped the scaled canvas in a ZStack container with scaled dimensions (DrawingCanvasView.swift:942-953):
```swift
ZStack {
    DrawingCanvasViewMacOS(canvasState: $canvasState)
        .frame(width: canvasState.canvasSize.width, height: canvasState.canvasSize.height)
        .scaleEffect(canvasState.zoomScale)
}
.frame(
    width: canvasState.canvasSize.width * canvasState.zoomScale,
    height: canvasState.canvasSize.height * canvasState.zoomScale
)
```

This tells the ScrollView the correct content size (scaled dimensions) while keeping the NSView at its original size (with coordinate transformation for mouse events).

**Result:**
ScrollView now correctly provides scrollable area for the full zoomed canvas extent at all zoom levels.

### DR-0004.2: Pen strokes do not track cursor when zoomed (macOS)

**Status:** ✅ Resolved - Verified (2025-12-14)
**Severity:** High

**Description:**
After fixing the scroll extent issue (DR-0004.1), pen strokes no longer tracked the cursor correctly when zoomed. Strokes appeared below the cursor when zoomed in, above the cursor when zoomed out.

**Root Cause - Initial Analysis:**
When the canvas was wrapped in a ZStack container (DR-0004.1 fix), `.scaleEffect()` was scaling from the **center** by default, causing a centering offset.

**First Attempted Fix:**
Changed `.scaleEffect()` to anchor at `.topLeading` and aligned container frames (DrawingCanvasView.swift:942, 948, 953). This eliminated the centering offset but revealed a second issue.

**Root Cause - Double Correction:**
The original implementation divided mouse coordinates by `zoomScale` to compensate for the transform. However, when `.scaleEffect(anchor: .topLeading)` is used, NSView's `convert(event.locationInWindow, from: nil)` **already accounts for the transform**. Dividing by `zoomScale` again caused double-correction:
- Zoomed in (200%): Divided by 2.0 → strokes appeared below (Y too small)
- Zoomed out (50%): Divided by 0.5 → strokes appeared above (Y too large)

**Final Fix (2025-12-12):**
Removed the `zoomScale` division from mouse event handlers (DrawingCanvasViewMacOS.swift:81, 103):
```swift
// Before: let location = CGPoint(x: rawLocation.x / zoomScale, y: rawLocation.y / zoomScale)
// After:  let location = convert(event.locationInWindow, from: nil)
```

With `.topLeading` anchor, the coordinate conversion handles the transform automatically.

**Result:**
Pen strokes now accurately track the cursor at all zoom levels (100%, 50%, 150%, 200%, etc.).

**Files Affected:**
- `DrawingCanvasViewMacOS.swift` - Mouse event handling and coordinate transformation
- `DrawingCanvasView.swift` - MacOSScrollableCanvas frame sizing, ScrollView content size, and scaleEffect anchoring

### DR-0004.3: Drawing canvas not restored on macOS despite detection

**Status:** ✅ Resolved - Verified (2025-12-14)
**Severity:** Medium

**Description:**
When returning to a draft in MapWizardView on macOS, the system correctly detected that drawing canvas data existed, but the strokes were not being restored/displayed on the canvas.

**Root Cause:**
During draft restoration, `importCanvasState()` is called before the `DrawingCanvasView` is created. On macOS, this method calls `macosCanvasView?.importStrokes(from: data)` (DrawingCanvasView.swift:410), but at this point `macosCanvasView` is still `nil` because `makeNSView()` hasn't been called yet. The import silently fails.

**Fix (2025-12-12):**

1. **Added pending data storage** (DrawingCanvasView.swift:438-440):
   - New property `pendingStrokeData` in `DrawingCanvasModel` to store stroke data before view creation

2. **Updated import logic** (DrawingCanvasView.swift:410-416):
   - Check if `macosCanvasView` exists
   - If yes, import immediately
   - If no, store data in `pendingStrokeData` for deferred import

3. **Applied pending data on view creation** (DrawingCanvasViewMacOS.swift:27-32):
   - In `makeNSView()`, after creating the view and connecting it to the model
   - Check for `pendingStrokeData` and import if present
   - Clear `pendingStrokeData` after successful import

**Result:**
Stroke data is now correctly restored when returning to a draft on macOS, regardless of view creation timing.

**Files Affected:**
- `DrawingCanvasView.swift` - Added pending data storage and deferred import logic
- `DrawingCanvasViewMacOS.swift` - Added pending data application on view creation

---

## DR-0005: Cumberland no longer connected to CloudKit

**Status:** ✅ Resolved - Verified
**Platform:** macOS (All platforms affected)
**Component:** SwiftData / CloudKit Integration
**Severity:** Critical

**Description:**
The application was displaying "no longer connected to CloudKit" message on macOS. Investigation revealed that CloudKit sync was intentionally disabled for DEBUG builds and that the SwiftData migration plan was conflicting with CloudKit's schema management.

**Steps to Reproduce:**
1. Launch Cumberland app in DEBUG configuration on macOS
2. Observe CloudKit connectivity status
3. App reports no CloudKit connection

**Expected Behavior:**
App should connect to CloudKit and sync data across devices.

**Actual Behavior:**
App runs in local-only mode with CloudKit disabled, displaying "no longer connected to CloudKit" warning.

**Root Cause Analysis:**

1. **CloudKit Disabled in DEBUG Builds** (CumberlandApp.swift:109-127)
   - CloudKit initialization was wrapped in `#if DEBUG` / `#else` / `#endif` conditional
   - Only production builds attempted CloudKit connection
   - DEBUG builds skipped directly to local storage fallback

2. **Migration Plan Conflict**
   - SwiftData migration plan (`AppMigrations.self`) was being passed to `ModelContainer` initialization
   - CloudKit handles its own schema evolution and migrations
   - Having both SwiftData migrations AND CloudKit caused conflict: "The current model reference and the next model reference cannot be equal"

3. **Automatic Store Deletion**
   - DEBUG flag `deleteCorruptedStores = true` was deleting local stores on every launch
   - Combined with CloudKit being disabled, this prevented any data persistence

**Date Identified:** 2025-12-14

**Resolution:**

**Fix Date:** 2025-12-14
**Verification Date:** 2025-12-14

**Implementation:**

1. **Re-enabled CloudKit for DEBUG builds** (CumberlandApp.swift:108-122)
   - Removed `#if DEBUG` / `#else` / `#endif` conditional compilation directives
   - CloudKit initialization now runs for all build configurations
   - Updated comment to reflect CloudKit is enabled after Development Environment reset

2. **Removed SwiftData Migration Plan** (CumberlandApp.swift:113-121, 126-134, 139-147)
   - Removed `migrationPlan: AppMigrations.self` parameter from all three ModelContainer configurations:
     - CloudKit configuration
     - Local on-disk fallback configuration
     - In-memory fallback configuration
   - CloudKit now handles schema evolution exclusively
   - Comment updated: "Use the latest schema. CloudKit handles migrations itself."

3. **Disabled Automatic Store Deletion** (CumberlandApp.swift:38)
   - Changed `deleteCorruptedStores = true` to `deleteCorruptedStores = false`
   - Prevents automatic deletion of local stores on launch
   - Note: One-time deletion was performed during troubleshooting before fix

4. **Added Empty Data Guard for Canvas Restoration** (MapWizardView.swift:1539-1548)
   - Added guard to check for empty `draftData` before attempting canvas state import
   - Prevents JSON decoding errors when draft data is corrupted or missing
   - Changed error message from ❌ to ⚠️ to indicate non-fatal warning
   - This addresses the "dataCorrupted" error that appeared after store reset

**Additional Actions:**
- User reset CloudKit Development Environment via CloudKit Dashboard
- Fresh start with clean CloudKit container and local stores

**Result:**
✅ App successfully connects to CloudKit in DEBUG builds
✅ SwiftData ModelContainer initializes without migration conflicts
✅ Data syncs across devices via CloudKit
✅ Canvas draft data properly handled when empty/corrupted

**Console Messages (Success):**
```
SwiftData ModelContainer initialized with CloudKit.
```

**Files Affected:**
- `CumberlandApp.swift` - CloudKit configuration, migration plan removal, store deletion flag
- `MapWizardView.swift` - Canvas state restoration error handling

**Verification:**
- App launches successfully without crashes
- CloudKit connection established (verified in console logs)
- No migration errors
- Draft data restoration handles empty data gracefully

---

## DR-0006: Drawing canvas draft does not restore tool palette state

**Status:** ✅ Resolved - Verified
**Platform:** All platforms (iOS, macOS, visionOS)
**Component:** DrawingCanvasView / MapWizardView
**Severity:** Medium

**Description:**
When restoring a draft drawing canvas in MapWizardView, only the strokes/drawings are restored. The tool palette state (brush type, color, zoom, pan position, rulers, grid, background color) is not saved or restored, requiring users to reconfigure their workspace when returning to a draft.

**Expected Behavior:**
When returning to a draft drawing canvas, the complete workspace state should be restored including:
- Selected brush type (pencil, pen, marker, eraser)
- Selected color
- Zoom percentage
- Pan/scroll position (viewport location)
- Ruler visibility state
- Grid visibility state
- Background color selection

**Actual Behavior:**
Only the drawn strokes are restored. All tool palette settings revert to defaults.

**Impact:**
- Users lose their workspace configuration when switching between drafts
- Requires manual reconfiguration each time a draft is reopened
- Disrupts workflow continuity
- Particularly impactful when working on multiple maps with different settings

**Date Identified:** 2025-12-14

**Investigation Findings (2025-12-14):**

Current `CanvasStateData` structure (DrawingCanvasView.swift:1061-1071) saves:
- ✅ `drawingData: Data` - The actual strokes
- ✅ `canvasSize: CGSize`
- ✅ `backgroundColor: String`
- ✅ `showGrid: Bool`
- ✅ `gridSpacing: CGFloat`
- ✅ `gridColor: String`
- ✅ `gridType: String`
- ✅ `zoomScale: CGFloat`
- ✅ `scrollOffset: CGPoint`

**Missing from saved state:**
- ❌ `isRulerActive: Bool` (line 132) - Ruler visibility
- ❌ `selectedToolType: DrawingToolType` (line 135) - Selected brush (pen, pencil, marker, eraser)
- ❌ `selectedColor: Color` (line 138) - Selected drawing color
- ❌ `selectedLineWidth: CGFloat` (line 141) - Brush width/size

**Root Cause:**
The `CanvasStateData` struct and export/import methods were implemented with partial state persistence. Tool palette settings were not included in the initial implementation.

**Resolution:**

**Fix Date:** 2025-12-14
**Verification Date:** 2025-12-14

**Implementation:**

1. **Updated `CanvasStateData` struct** (DrawingCanvasView.swift:1072-1090)
   - Added `isRulerActive: Bool` - Ruler visibility state
   - Added `selectedToolType: String` - Selected brush type (serialized as rawValue)
   - Added `selectedColor: String` - Selected drawing color (serialized as hex)
   - Added `selectedLineWidth: CGFloat` - Brush width/size

2. **Updated `exportCanvasState()` method** (DrawingCanvasView.swift:400-404)
   - Now exports `isRulerActive` from model
   - Serializes `selectedToolType.rawValue` to string
   - Converts `selectedColor` to hex string via `.toHex()`
   - Exports `selectedLineWidth` directly

3. **Updated `importCanvasState()` method** (DrawingCanvasView.swift:454-461)
   - Restores `isRulerActive` from saved state
   - Deserializes `selectedToolType` from string rawValue (fallback to `.pen`)
   - Converts hex string back to `Color` for `selectedColor`
   - Restores `selectedLineWidth` directly
   - Calls `updateTool()` to apply restored settings to PencilKit tool

**Technical Details:**
- `DrawingToolType` enum already had String raw values, making it automatically Codable
- Color serialization uses existing `toHex()` and `Color(hex:)` extension methods
- iOS/PencilKit: `isRulerActive` is passed to PKCanvasView and properly restored
- macOS: Tool settings are read from model during `mouseDown`, automatically using restored values
- Backward compatibility: If old drafts lack new fields, defaults are used (pen tool, black color, width 5)

**Result:**
✅ Complete workspace state now persists across draft sessions
✅ Brush type, color, and width restored correctly
✅ Zoom level maintained
✅ Ruler state preserved on iOS
✅ Grid and background settings already working, now confirmed
✅ Works on all platforms (iOS, macOS, visionOS)

**Follow-up Fix - Scroll Position Restoration (2025-12-14):**

**Issue:** After initial implementation, scroll/pan position was not being restored on either platform.

**Root Cause:**
- **iOS:** Local `@State` variable initialized to `.zero` instead of from model, causing restored position to be ignored
- **macOS:** SwiftUI `ScrollView` does not properly support programmatic scrolling or scroll position tracking

**Fix Implementation:**

1. **iOS Scroll Position** (DrawingCanvasView.swift:30-39)
   - Changed `@State private var scrollPosition: CGPoint = .zero` to non-initialized declaration
   - Added custom `init(canvasState:)` that initializes scroll position from model's `scrollOffset`
   - Removed redundant `onAppear` scroll position initialization
   - Now properly initializes from restored state before view appears

2. **macOS Scroll Position - Final Fix** (DrawingCanvasView.swift:982-1091)
   - **Replaced SwiftUI `ScrollView` with `NSScrollView` via `NSViewRepresentable`**
   - Direct access to scroll position via `NSClipView.bounds.origin`
   - Implemented `NSView.boundsDidChangeNotification` observer to track scroll changes
   - Coordinator pattern updates `canvasState.scrollOffset` when user scrolls
   - `makeNSView`: Restores scroll position using `scroll(to:)` on initial creation
   - `updateNSView`: Applies external scroll position changes (from restoration)
   - Debouncing with distance check (>0.5 pixels) prevents feedback loops

**Why NSScrollView was necessary:**
- SwiftUI's `ScrollView` on macOS lacks programmatic scroll control
- `ScrollViewReader.scrollTo` doesn't work reliably with dynamic positions
- GeometryReader preference approach failed to capture scroll events
- NSScrollView provides reliable notifications and direct scroll control

**Result (Final):**
✅ Scroll/pan position correctly restored on iOS
✅ Scroll/pan position correctly tracked and restored on macOS
✅ User scroll changes immediately saved to model
✅ External scroll position changes (from restoration) reliably applied
✅ No feedback loops or scroll jitter

**Files Affected:**
- `DrawingCanvasView.swift` - CanvasStateData struct, export/import methods, scroll position restoration (iOS and macOS)
- `DrawingCanvasViewMacOS.swift` - No changes needed (reads from model)

**Verification:**
- Create a draft with custom tool settings (red marker, width 10, zoom 150%, ruler on)
- Pan/scroll to a specific position on the canvas (e.g., bottom-right corner)
- Draw some strokes at that position
- Switch to another card/view
- Return to the draft
- ✅ All tool palette settings are restored exactly as configured
- ✅ Canvas is scrolled to the exact same position
- ✅ Previously drawn strokes are visible at the correct scroll position

---

## DR-0007: Ruler button appears on macOS but does nothing

**Status:** ✅ Resolved - Verified
**Platform:** macOS
**Component:** DrawingCanvasView / DrawingToolbar
**Severity:** Low

**Description:**
The ruler button appeared in the drawing toolbar on macOS, but clicking it did not display a ruler or enable ruler functionality. This was confusing because the button was visible but non-functional.

**Expected Behavior:**
Ruler functionality should only be available on platforms that support it (iOS/iPadOS with PencilKit).

**Actual Behavior:**
The ruler button was visible on macOS, toggled state when clicked, but had no effect because macOS uses a custom native drawing implementation instead of PencilKit.

**Root Cause:**
The ruler is a PencilKit-specific feature that only works on iOS/iPadOS. macOS uses a custom `NSView`-based drawing implementation (`MacOSDrawingView`) that does not support PencilKit features like the ruler tool. The toolbar was shared across all platforms without platform-specific filtering.

**Date Identified:** 2025-12-14

**Resolution:**

**Fix Date:** 2025-12-14
**Verification Date:** 2025-12-14

**Implementation:**

Added platform-specific conditional compilation to hide the ruler button on macOS (DrawingCanvasView.swift:680-693):
```swift
// DR-0007: Ruler toggle (iOS/iPadOS only - PencilKit feature)
#if canImport(PencilKit) && canImport(UIKit)
Button(action: {
    canvasState.isRulerActive.toggle()
}) {
    Image(systemName: "ruler")
        .foregroundStyle(canvasState.isRulerActive ? .blue : .secondary)
}
.buttonStyle(.plain)
.help("Toggle Ruler")

Divider()
    .frame(height: 24)
#endif
```

**Result:**
✅ Ruler button now only appears on iOS/iPadOS where PencilKit is available
✅ macOS toolbar no longer shows non-functional ruler button
✅ Cleaner, platform-appropriate UI on macOS
✅ Ruler functionality preserved on iOS/iPadOS

**Technical Notes:**
- The ruler feature requires PencilKit (`PKCanvasView.isRulerActive`)
- iOS/iPadOS use PencilKit for drawing
- macOS uses custom `NSView` drawing implementation without PencilKit
- The `#if canImport(PencilKit) && canImport(UIKit)` check ensures button only shows on iOS/iPadOS
- The `isRulerActive` state is still saved/restored (for iOS), but has no effect on macOS

**Files Affected:**
- `DrawingCanvasView.swift` - Added platform conditional for ruler button visibility

**Verification:**
- ✅ Ruler button hidden on macOS
- ✅ Ruler button visible and functional on iOS/iPadOS (requires iOS 14.0+)
- ✅ No compiler warnings or errors
- ✅ Toolbar layout correct on both platforms

---

## DR-0008: Content Layer not restored when loading existing map data

**Status:** ✅ Resolved - Verified
**Platform:** All platforms (iOS, macOS, visionOS)
**Component:** DrawingCanvasView / MapWizardView / LayerManager
**Severity:** Critical

**Description:**
When loading existing map data from drafts, the LayerManager and its layers (especially the Content Layer) were not being saved or restored. This caused all layer-based content and configuration to be lost when returning to a draft, even though the raw drawing data was still present.

**Expected Behavior:**
When restoring a draft drawing canvas with LayerManager:
- All layers should be restored with their names, types, and properties
- Content Layer should contain all previously drawn strokes
- Base Layer should retain any applied fills
- Layer visibility, opacity, and order should be preserved
- Active layer selection should be maintained

**Actual Behavior:**
When loading existing map data:
- LayerManager was not saved in draft persistence
- Only raw drawing data was exported via `exportDrawingData()`
- On restoration, `ensureLayerManager()` created a NEW LayerManager
- New LayerManager migrated main drawing data to a fresh Content Layer
- All layer-specific configurations were lost
- Multi-layer setups were reduced to single migrated layer

**Impact:**
- Users lost all layer organization when switching between drafts
- Base layer fills were not preserved
- Layer naming and types were reset
- Critical data loss for complex multi-layer maps
- Rendered the layer system unreliable for persistent work

**Date Identified:** 2025-12-22

**Root Cause Analysis:**

The save/restore flow had a critical gap:

**Save Flow (exportCanvasState):**
1. Called `exportDrawingData()` to get raw drawing bytes
2. Exported canvas settings (size, zoom, colors, etc.)
3. ❌ **Did NOT export LayerManager** - it was never serialized

**Restore Flow (importCanvasState):**
1. Imported raw drawing data to main `drawing` property
2. Restored canvas settings
3. ❌ **Did NOT restore LayerManager** - it was never deserialized
4. Later, `DrawingCanvasView.onAppear` called `ensureLayerManager()`
5. Created fresh LayerManager and migrated main drawing to new Content Layer
6. All previous layer configuration lost

**Technical Details:**
- `LayerManager` is `Codable` (LayerManager.swift:18)
- `DrawingLayer` has custom Codable implementation for PKDrawing/strokes (DrawingLayer.swift:126-203)
- `CanvasStateData` struct did not include LayerManager field
- Backward compatibility needed for old drafts without LayerManager

**Resolution:**

**Fix Date:** 2025-12-22
**Verification Date:** 2025-12-22

**Implementation:**

1. **Updated `CanvasStateData` struct** (DrawingCanvasView.swift:1284-1286)
   - Added `layerManagerData: Data?` - Encoded LayerManager (optional for backward compatibility)
   - Optional to handle legacy drafts without LayerManager

2. **Updated `exportCanvasState()` method** (DrawingCanvasView.swift:485-511)
   - Check if `layerManager` exists
   - Encode LayerManager to JSON Data using `JSONEncoder()`
   - Store encoded data in `CanvasStateData.layerManagerData`
   - Print diagnostic messages for debugging
   - Still exports `drawingData` for backward compatibility

3. **Updated `importCanvasState()` method** (DrawingCanvasView.swift:548-587)
   - Check if `layerManagerData` exists in saved state
   - If present: Decode LayerManager from JSON Data and restore it
   - If missing: Set layerManager to nil (legacy draft handling)
   - `ensureLayerManager()` will handle migration for legacy drafts
   - Still imports `drawingData` for fallback/compatibility
   - Error handling for corrupted LayerManager data

**Code Changes:**

```swift
// CanvasStateData struct
struct CanvasStateData: Codable {
    // ... existing fields ...

    // DR-0008: Layer manager state
    let layerManagerData: Data? // Encoded LayerManager
}

// exportCanvasState() method
var layerManagerData: Data? = nil
if let manager = layerManager {
    print("[EXPORT] Encoding LayerManager with \(manager.layerCount) layers")
    layerManagerData = try? JSONEncoder().encode(manager)
    print("[EXPORT] LayerManager encoded to \(layerManagerData?.count ?? 0) bytes")
}

// importCanvasState() method
if let layerManagerData = state.layerManagerData {
    print("[IMPORT] Decoding LayerManager from \(layerManagerData.count) bytes")
    do {
        let manager = try JSONDecoder().decode(LayerManager.self, from: layerManagerData)
        layerManager = manager
        print("[IMPORT] Restored LayerManager with \(manager.layerCount) layers")
    } catch {
        print("[IMPORT] ⚠️ Failed to decode LayerManager: \(error)")
        layerManager = nil
    }
}
```

**Backward Compatibility:**
- ✅ Legacy drafts without `layerManagerData` still work
- ✅ `layerManagerData` is optional - decoder handles missing field
- ✅ Migration via `ensureLayerManager()` still functions for old drafts
- ✅ New drafts save complete LayerManager state

**Result:**
✅ LayerManager fully persists across draft sessions
✅ All layers preserved with names, types, and properties
✅ Content Layer restored with all strokes
✅ Base Layer fills maintained
✅ Layer order, visibility, and opacity preserved
✅ Active layer selection maintained
✅ Multi-layer maps now reliably persistent
✅ Works on all platforms (iOS, macOS, visionOS)

**Files Affected:**
- `DrawingCanvasView.swift` - CanvasStateData struct, exportCanvasState, importCanvasState

**Verification:**
- Create a draft with multiple layers (Base Layer with fill, Content Layer with strokes)
- Configure layer properties (names, visibility, opacity)
- Switch to another card/view
- Return to the draft
- ✅ LayerManager restored with all layers intact
- ✅ Content Layer contains all previous strokes
- ✅ Base Layer fill preserved
- ✅ Layer properties maintained
- ✅ Active layer selection preserved

**Related Issues:**
- Complements DR-0006 (tool palette state restoration)
- Builds on LayerManager initialization system (see LayerManager-Initialization-Guide.md)

---

## DR-0009: Toolbar too wide for view area on iOS

**Status:** ✅ Resolved - Verified
**Platform:** iOS
**Component:** DrawingCanvasView / DrawingToolbar
**Severity:** High

**Description:**
On iOS, the drawing toolbar is too wide to fit within the available view area. This causes many toolbar buttons to overflow off the right edge of the screen, making them completely unreachable.

**Expected Behavior:**
All toolbar buttons should be visible and accessible within the view area on iOS devices.

**Actual Behavior:**
Toolbar buttons overflow off the right edge:
- Toggle Palette button - unreachable
- Delete button - unreachable
- Pen/Pencil/Marker buttons - unreachable
- Other buttons may also be hidden depending on device width

**Impact:**
- Critical toolbar functionality is inaccessible
- Users cannot select drawing tools (pen, pencil, marker)
- Cannot delete canvas content
- Cannot toggle floating palette visibility
- Effectively breaks the drawing canvas UI on iOS

**Steps to Reproduce:**
1. Open MapWizardView on iOS device
2. Select "Draw" option
3. Observe toolbar at top of canvas
4. Attempt to access rightmost buttons

**Date Identified:** 2025-12-22

**Root Cause Analysis:**
The `DrawingToolbar` (DrawingCanvasView.swift:638-904) was designed for larger screen sizes (macOS/iPad) and contains too many UI elements for iPhone-width screens. The toolbar uses an HStack with fixed-width elements that don't adapt to smaller screen sizes.

**Resolution:**

**Fix Date:** 2025-12-22

**Implementation:**

Added platform-specific ScrollView wrapper for iOS to enable horizontal scrolling of toolbar content (DrawingCanvasView.swift:668-905):

1. **Created separate toolbar content view** (lines 687-904)
   - Extracted HStack content into `toolbarContent` computed property
   - Maintains all existing toolbar functionality
   - Shared between iOS and macOS versions

2. **iOS-specific ScrollView wrapper** (lines 670-676)
   - Wraps `toolbarContent` in horizontal ScrollView
   - `showsIndicators: false` for cleaner appearance
   - Preserves padding and background material
   - Enables swipe gesture to access all toolbar buttons

3. **macOS unchanged** (lines 678-682)
   - Uses original layout without ScrollView
   - Maintains desktop-optimized appearance
   - No functional changes for macOS users

**Code Changes:**

```swift
var body: some View {
    // DR-0009: Wrap toolbar in ScrollView on iOS for narrow screens
    #if os(iOS)
    ScrollView(.horizontal, showsIndicators: false) {
        toolbarContent
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .background(.ultraThinMaterial)
    #else
    toolbarContent
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    #endif
}

private var toolbarContent: some View {
    HStack(spacing: 16) {
        // All toolbar buttons...
    }
}
```

**Technical Details:**
- ScrollView provides native horizontal scrolling on iOS
- Touch gestures work naturally for swiping through tools
- No visual scroll indicators (cleaner look)
- All buttons remain at their original sizes (no compression)
- Maintains muscle memory for button positions

**Result:**
✅ All toolbar buttons now accessible on iOS via horizontal scroll
✅ No layout changes on macOS (desktop optimized)
✅ iOS build compiles successfully
✅ macOS build compiles successfully
✅ visionOS build compiles successfully

**Files Affected:**
- `DrawingCanvasView.swift` - DrawingToolbar struct (lines 668-905)

**Verification:**
- ✅ Tested on actual iPhone - toolbar scrolls horizontally
- ✅ All buttons accessible via swipe gesture
- ✅ No regression on iPad
- ✅ Touch scrolling responsive and smooth
- ✅ Toolbar appears and functions correctly

**Verification Date:** 2025-12-22

**Related Issues:**
- Related to DR-0011 (floating palette positioning on iOS)

---

## DR-0010: Draft Content Layer not restored correctly on iOS (local-only, no cross-device sync)

**Status:** 🔴 Unresolved - CloudKit External Storage Sync Issue
**Platform:** iOS (All platforms affected for cross-device sync)
**Component:** DrawingCanvasView / MapWizardView / CloudKit Sync
**Severity:** Critical

**Description:**
When loading a draft map on iOS, the Content Layer appears to restore, but the restoration is unreliable and local-only. Previous edits may appear, but cross-device restoration via CloudKit does not work. Changes made on one device do not sync to other devices.

**Expected Behavior:**
- Draft Content Layer should fully restore on the same device
- Draft data should sync via CloudKit to all user devices
- Opening a draft on Device B should show edits made on Device A
- LayerManager and all layer content should persist across devices

**Actual Behavior:**
- Previous edits sometimes appear (local restoration works partially)
- Cross-device restoration fails completely
- Edits made on Device A do not appear on Device B
- Suggests CloudKit sync is not working for draft map data
- May indicate LayerManager data is not syncing properly

**Impact:**
- Cannot reliably work on maps across multiple devices
- Risk of data loss when switching devices
- Defeats purpose of CloudKit-based multi-device workflow
- Undermines user trust in draft persistence

**Steps to Reproduce:**
1. Create/edit a draft map on iOS Device A with multiple layers
2. Add strokes to Content Layer
3. Switch to another card (triggers draft save)
4. Open same iCloud account on iOS Device B
5. Navigate to the same draft map
6. Observe that Content Layer is empty or incomplete

**Date Identified:** 2025-12-22

**Root Cause Analysis:**

**Investigation Findings:**

1. **Card Model Configuration** (Card.swift:68-78)
   - `draftMapWorkData` is marked with `@Attribute(.externalStorage)` ✅
   - This should sync via CloudKit as a CKAsset ✅
   - Not marked as `@Transient`, so it IS part of the synced schema ✅
   - `draftMapWorkTimestamp`, `draftMapMethodRaw`, `draftMapWizardStepRaw` are standard fields ✅

2. **CloudKit Configuration** (CumberlandApp.swift:111-115)
   - Using `ModelConfiguration("iCloud.CumberlandCloud")` ✅
   - CloudKit is properly enabled after DR-0005 resolution ✅
   - Configuration should sync all non-@Transient fields ✅

3. **Critical Bug Found** (MapWizardView.swift:1673)
   - **Silent error handling:** `try? modelContext.save()` was suppressing all errors
   - If save failed, no error was logged or reported
   - Code printed "✅ Draft saved successfully" even on failure
   - **This masked the actual problem preventing sync**

**Resolution:**

**Fix Date:** 2025-12-22

**Implementation:**

Fixed silent error handling to expose save failures and CloudKit sync issues (MapWizardView.swift:1674-1683):

```swift
// Before (DR-0010 bug):
try? modelContext.save()
print("[SAVE] ✅ Draft saved successfully")

// After (DR-0010 fix):
do {
    try modelContext.save()
    print("[SAVE] ✅ Draft saved successfully to local store")
    print("[SAVE] 📡 CloudKit will sync in background (if enabled)")
} catch {
    print("[SAVE] ❌ Failed to save draft: \(error)")
    print("[SAVE] ⚠️ Draft data will NOT sync to other devices")
    // Don't throw - allow app to continue but log the failure
}
```

**What This Fix Provides:**

1. **Error Visibility**
   - Save failures are now logged with full error details
   - User can see when CloudKit sync will not occur
   - Diagnostic information for troubleshooting

2. **CloudKit Sync Awareness**
   - Explicitly notes that CloudKit syncs in background
   - Sets expectation that sync is not immediate
   - Helps users understand sync timing

3. **Debugging Support**
   - Console logs reveal actual save errors
   - Can identify CloudKit quota issues, network problems, etc.
   - Enables proper diagnosis of sync failures

**Technical Details:**

- SwiftData with CloudKit syncs automatically after `modelContext.save()` succeeds
- External storage (`@Attribute(.externalStorage)`) uses CKAsset for efficient transfer
- CloudKit sync happens asynchronously in background (not immediate)
- Network connectivity required for cross-device sync
- CloudKit sync may be delayed by iOS power management

**Additional Recommendations:**

1. **Monitor Console Logs** - Check for save errors when testing cross-device sync
2. **Wait for Sync** - Allow 10-30 seconds for CloudKit to sync after save
3. **Check Network** - Ensure both devices have active internet connection
4. **Verify iCloud** - Confirm both devices logged into same iCloud account
5. **CloudKit Dashboard** - Check CloudKit console for sync errors or quota issues

**Result:**
✅ Silent error handling fixed - save failures now logged
✅ CloudKit sync awareness added to logging
✅ Diagnostic information available for troubleshooting
❌ **Cross-device sync still not working** - root cause identified

**Testing Results (2025-12-22):**

**Same-Device Persistence:**
- ✅ iOS → iOS: Works perfectly, all strokes restored
- ✅ macOS → macOS: Works perfectly, all strokes restored
- ✅ Local saves: 330KB+ LayerManager data saved successfully
- ✅ No save errors in console logs

**Cross-Device Sync:**
- ❌ iOS → macOS: Draft data does NOT sync
- ❌ macOS → iOS: Draft data does NOT sync
- ✅ Card metadata syncs: New cards appear on both devices
- ✅ CloudKit Dashboard: 572 requests, no sync errors
- ❌ **`draftMapWorkData` stays local-only**

**Root Cause Identified:**

SwiftData/CloudKit is **not syncing** the `@Attribute(.externalStorage)` field:

```swift
// Card.swift:68-69
@Attribute(.externalStorage)
var draftMapWorkData: Data?
```

**Evidence:**
1. Local saves succeed (330,473 bytes LayerManager on iOS)
2. macOS loads old data (87,236 bytes from before)
3. Card metadata syncs normally (tested with new card creation)
4. CloudKit Dashboard shows no errors
5. **Only `draftMapWorkData` doesn't sync** - external storage CKAsset issue

**Why This Matters:**
- Cross-device draft editing completely broken
- Users can't switch between iPhone/iPad/Mac while working
- Defeats purpose of CloudKit-backed multi-device workflow
- Critical blocker for professional workflows

**Attempted Fixes:**
1. ✅ Added error logging (no errors found)
2. ✅ Verified CloudKit configuration
3. ✅ Confirmed external storage attribute
4. ❌ External storage CKAssets not syncing (SwiftData/CloudKit issue)

**Known Issue:**
SwiftData's `@Attribute(.externalStorage)` with CloudKit may not sync CKAssets reliably in all configurations. This appears to be a framework-level issue requiring deeper investigation into:
- CloudKit schema configuration
- SwiftData sync behavior with external storage
- CKAsset upload/download lifecycle
- Possible SwiftData bugs with external storage sync

**Files Affected:**
- `MapWizardView.swift` - Draft save error handling (lines 1674-1683)
- `Card.swift` - draftMapWorkData external storage attribute

**Workaround:**
- Use same device for draft editing
- Finalize maps before switching devices
- Export/import manually if cross-device needed

**Future Investigation Needed:**
- Review CloudKit schema for CKAsset references
- Test with explicit CloudKit record saves (bypass SwiftData)
- Check SwiftData documentation for external storage sync requirements
- Consider alternative serialization approaches
- Monitor Apple Developer Forums for similar issues

**Related Issues:**
- Builds on DR-0008 (LayerManager persistence implementation)
- Blocks DR-0013 (Cross-platform restoration depends on sync)
- Related to DR-0005 (CloudKit connectivity issues - resolved)

---

## DR-0011: Floating tool palette appears off the right edge on iOS

**Status:** ⚠️ In Progress - Geometry Fix Applied
**Platform:** iOS
**Component:** FloatingToolPalette / DrawingCanvasView
**Severity:** Medium

**Description:**
On iOS, the floating tool palette renders off the right edge of the canvas view, making it partially or completely inaccessible.

**Expected Behavior:**
The floating tool palette should be positioned within the visible canvas area, fully accessible to the user.

**Actual Behavior:**
The palette appears positioned off the right edge of the screen, extending beyond the visible bounds.

**Impact:**
- Floating palette functionality is inaccessible
- Users cannot access tools, layers, or inspector tabs
- Workaround: Toggle palette off/on might not help if position is persisted
- Affects usability of entire layer system on iOS

**Steps to Reproduce:**
1. Open DrawingCanvas on iOS device
2. Observe floating tool palette position
3. Palette appears partially or fully off right edge

**Date Identified:** 2025-12-22

**Root Cause Analysis:**
The `FloatingToolPalette` position is managed by `ToolPaletteState.position`. The default position of `CGPoint(x: 0, y: 100)` was designed for macOS. When combined with `.topTrailing` alignment in DrawingCanvasView.swift:94, the palette on iOS would:
- Be aligned to the top-right corner (`.topTrailing`)
- Then offset by x: 0 from that position
- This placed it at or beyond the right edge on narrow iOS screens

The existing `clampPosition(within:paletteSize:)` method in ToolPaletteState was never being called, so bounds checking was not enforced.

**Resolution:**

**Fix Date:** 2025-12-22

**Implementation:**

1. **Platform-Specific Default Position** (ToolPaletteState.swift:20-24, 50-55, 100-105, 143-148)
   - iOS now defaults to `CGPoint(x: -300, y: 100)` to pull palette onto screen from trailing edge
   - macOS retains original `CGPoint(x: 0, y: 100)` which works well on larger screens
   - Applied to: property initialization, `init()`, `resetPosition()`, and Codable `init(from:)`

2. **GeometryReader for Bounds Detection** (FloatingToolPalette.swift:20-52)
   - Wrapped palette in `GeometryReader` to access canvas size
   - Pass canvas bounds to clamping logic

3. **Position Clamping on Appearance** (FloatingToolPalette.swift:48-51)
   - Added `.onAppear` to call `clampPosition()` when palette first displays
   - Ensures palette is always within visible bounds on initial render

4. **Position Clamping After Drag** (FloatingToolPalette.swift:145-164, 169-177)
   - Updated drag gesture to accept canvas size parameter
   - Call `clampPosition()` after drag ends to prevent users from dragging palette off-screen
   - Added `clampPosition(canvasSize:)` helper method

**Code Changes:**

```swift
// ToolPaletteState.swift:20-24 - Platform-specific default position
#if os(iOS)
var position: CGPoint = CGPoint(x: -300, y: 100)
#else
var position: CGPoint = CGPoint(x: 0, y: 100)
#endif

// FloatingToolPalette.swift:20-52 - GeometryReader with clamping
GeometryReader { geometry in
    VStack(spacing: 0) {
        // ... palette content
    }
    .gesture(dragGesture(in: geometry.size))
    .onAppear {
        clampPosition(canvasSize: geometry.size)
    }
}

// FloatingToolPalette.swift:169-177 - Clamping helper
private func clampPosition(canvasSize: CGSize) {
    let paletteSize = CGSize(width: canvasState.toolPaletteState.width, height: 600)
    let bounds = CGRect(origin: .zero, size: canvasSize)
    canvasState.toolPaletteState.clampPosition(within: bounds, paletteSize: paletteSize)
}
```

**Result:**
✅ Palette now positions properly on iOS (pulled left from trailing edge)
✅ Palette cannot be dragged off-screen (clamped to visible bounds)
✅ Position clamping enforced on first appearance and after every drag
✅ macOS positioning unchanged (still works correctly)
✅ Both iOS and macOS builds succeed

**Files Affected:**
- `ToolPaletteState.swift` - Platform-specific default positions, resetPosition(), and Codable support
- `FloatingToolPalette.swift` - GeometryReader, onAppear clamping, drag gesture with bounds checking

**Verification:**
- ✅ iOS build succeeded
- ✅ macOS build succeeded
- ⏳ Awaiting device testing to confirm palette visibility on iOS

**User Testing Results - First Attempt (2025-12-22):**
On iPad in landscape mode, palette appeared almost in center of drawing canvas instead of top-trailing edge. Issue identified: GeometryReader inside FloatingToolPalette was reading its own geometry, not the container bounds. The palette lives inside a ZoomableScrollView, so coordinate space was incorrect.

**Second Fix Attempt (2025-12-22):**

1. **Pass Container Size from Parent** (DrawingCanvasView.swift:33, 42-50, 92-93)
   - Added `containerSize` state variable to track actual view bounds
   - Wrapped entire DrawingCanvasView body in GeometryReader
   - Pass containerSize to FloatingToolPalette as parameter
   - Updates on appearance and when geometry changes

2. **Remove Internal GeometryReader** (FloatingToolPalette.swift:15, 20-55)
   - Removed GeometryReader from inside FloatingToolPalette
   - Accept containerSize as parameter instead
   - Use passed containerSize for clamping and drag bounds
   - Added onChange handler to re-clamp when container size changes (rotation)

**User Testing Results - Second Attempt (2025-12-22):**
Palette still not positioned correctly horizontally. Now appearing ABOVE the drawing canvas and overlapping the toolbar. Issue identified: Palette was being positioned relative to entire view (including toolbar) instead of just the canvas area. The `.topTrailing` alignment was placing it at the top of the whole view.

**Third Fix (2025-12-22):**

**Restructure View Hierarchy** (DrawingCanvasView.swift:53-114)
- Moved palette overlay from outer ZStack to inner ZStack (canvas area only)
- Changed structure from:
  ```
  ZStack {
    VStack { Toolbar, Canvas }
    Palette  // ← Was here (wrong - overlays entire view)
  }
  ```
- To:
  ```
  VStack {
    Toolbar
    ZStack {
      Canvas
      Palette  // ← Now here (correct - overlays only canvas)
    }
  }
  ```
- This ensures `.topTrailing` positions palette at top-right of CANVAS, not entire view

**Code Changes (Second Fix):**

```swift
// DrawingCanvasView.swift:42-50 - Capture actual container geometry
GeometryReader { geometry in
    content
        .onAppear {
            containerSize = geometry.size
        }
        .onChange(of: geometry.size) { _, newSize in
            containerSize = newSize
        }
}

// FloatingToolPalette.swift:15, 46, 51-54 - Use passed container size
struct FloatingToolPalette: View {
    let containerSize: CGSize  // Passed from parent

    .gesture(dragGesture(in: containerSize))
    .onChange(of: containerSize) { _, newSize in
        clampPosition(canvasSize: newSize)
    }
}
```

**Result (Third Fix):**
✅ Palette now positioned within canvas area only (not overlapping toolbar)
✅ `.topTrailing` alignment now relative to canvas, not entire view
✅ Container bounds properly passed and clamped
✅ Both iOS and macOS builds succeed
⏳ Awaiting device testing to confirm proper positioning in landscape

**Related Issues:**
- Similar to DR-0009 (toolbar width issues on iOS) - both address iOS narrow screen layout

---

## DR-0012: Brush line width scaling differs between iOS and macOS

**Status:** 🟡 Resolved - Not Verified
**Platform:** iOS (cross-platform consistency issue)
**Component:** DrawingCanvasView / PencilKit
**Severity:** High

**Description:**
Originally reported as brush size control having no effect on iOS. User testing revealed the slider DOES work, but iOS line widths are much thinner than macOS at the same slider values. Width 1 is extremely thin on iOS, and width 20 is thicker but nowhere near macOS width 20 thickness. This creates an inconsistent cross-platform drawing experience.

**Expected Behavior:**
Line width should change according to the brush size slider value (1-20 range).

**Actual Behavior:**
Line width remains constant regardless of brush size slider setting.

**Steps to Reproduce:**
1. Open DrawingCanvas on iOS device
2. Select pen, pencil, or marker tool
3. Adjust brush size slider to minimum (1)
4. Draw a stroke on canvas
5. Adjust brush size slider to maximum (20)
6. Draw another stroke on canvas
7. Observe that both strokes have identical width

**Date Identified:** 2025-12-22

**Root Cause Analysis:**
This appears very similar to DR-0003 which was previously resolved with the tool change counter fix on 2025-12-04. Investigation revealed:

**Code Review (2025-12-22):**
- ✅ `toolChangeCounter` still present (DrawingCanvasView.swift:172)
- ✅ Counter incremented in `updateTool()` (lines 321, 326, 339)
- ✅ `.id()` modifier still applied to PencilKitCanvasView (line 66)
- ✅ Slider onChange handler calls `updateTool()` (lines 845-848)
- ✅ PKInkingTool created with `selectedLineWidth` parameter (line 333)

**All DR-0003 fix components are still in place.** This suggests either:
1. The mechanism works but something else is interfering
2. User needs to test on device to confirm actual behavior
3. Issue may be specific to certain conditions not yet identified

**Investigation Steps (2025-12-22):**

Added comprehensive diagnostic logging to trace the tool update flow:

1. **Slider Change Detection** (DrawingCanvasView.swift:845-848)
   ```swift
   .onChange(of: canvasState.selectedLineWidth) { oldValue, newValue in
       print("[DR-0012] Slider changed from \(oldValue) to \(newValue)")
       canvasState.updateTool()
   }
   ```

2. **Tool Update Logging** (DrawingCanvasView.swift:334, 337, 340)
   - Logs tool type and width when PKInkingTool is created
   - Shows toolChangeCounter value
   - Platform-specific (iOS vs macOS)

3. **Canvas View Creation Logging** (DrawingCanvasView.swift:1068-1072)
   - Logs tool width when PKCanvasView is created
   - Confirms tool type being used

4. **Canvas View Update Logging** (DrawingCanvasView.swift:1082-1084)
   - Logs tool width when PKCanvasView tool is updated
   - Shows if updateUIView is being called

**Next Steps:**
User needs to test on actual iOS device and observe console output. Expected log sequence when slider changes:
```
[DR-0012] Slider changed from X to Y
[DR-0012] iOS - Created PKInkingTool with width: Y
[DR-0012] Updated inking tool (pen/pencil/marker), counter: N
[DR-0012] makeUIView - Created canvas with inking tool width: Y
```

**Files Affected:**
- `DrawingCanvasView.swift` - Added diagnostic logging to slider, updateTool(), makeUIView(), and updateUIView()

**Related Issues:**
- Related to DR-0003 (Brush size control - resolved 2025-12-04)
- Possible regression or environmental issue

**User Testing Results (2025-12-22):**
Testing revealed DR-0003 WAS resolved - the tool change counter mechanism works correctly. However, a NEW issue was discovered:
- Line thickness DOES change on iOS when slider adjusted
- BUT: Width values are much smaller on iOS than macOS
- Width 1: Extremely thin on iOS (much thinner than macOS)
- Width 20: Thicker on iOS but not nearly as thick as macOS width 20
- Issue: PencilKit on iOS uses different scaling than macOS custom drawing

**Root Cause (Actual):**
PencilKit's interpretation of PKInkingTool width parameter differs from macOS custom drawing stroke width. iOS appears to use approximately 2.5x smaller scale for the same width value. This is a platform rendering difference, not a tool update issue.

**Resolution:**

**Fix Date:** 2025-12-22

**Implementation:**

Applied platform-specific width multiplier to achieve visual parity between iOS and macOS:

**Width Scaling Fix** (DrawingCanvasView.swift:351-353)
```swift
#if canImport(UIKit)
// DR-0012: Apply 3.0x multiplier on iOS to match macOS visual thickness
let effectiveWidth = selectedLineWidth * 3.0
selectedTool = PKInkingTool(pkColor, color: selectedColor.toPencilKitColor(), width: effectiveWidth)
#elseif canImport(AppKit)
selectedTool = PKInkingTool(pkColor, color: NSColor(selectedColor), width: selectedLineWidth)
#endif
```

**How it works:**
- Slider range remains 1-20 on both platforms
- iOS: Width is multiplied by 3.0 before creating PKInkingTool
  - Slider 1 → effective width 3.0
  - Slider 20 → effective width 60
- macOS: Width used directly (unchanged behavior)
- Result: Similar visual thickness across platforms

**Diagnostic logging remains in place** to help verify the multiplier is working correctly.

**User Testing Results (2025-12-22):**
Initial 2.5x multiplier was better but not quite enough. Adjusted to 3.0x per user feedback.

**Result:**
✅ iOS width values now scaled to match macOS visual appearance
✅ Slider range 1-20 consistent on both platforms
✅ Multiplier adjusted from 2.5x to 3.0x based on testing
✅ Both iOS and macOS builds succeed
⏳ Awaiting device testing to verify 3.0x multiplier provides good parity

**Files Affected:**
- `DrawingCanvasView.swift` - Added 3.0x width multiplier for iOS, kept diagnostic logging

**Verification Needed:**
- ⏳ Test on iOS device - compare width 1, 10, and 20 to macOS
- ⏳ Verify visual thickness is now similar across platforms
- ⏳ Further adjust multiplier if needed
- ⏳ Test with all tool types (pen, pencil, marker)

---

## DR-0013: Cross-platform draft restoration fails (iOS → macOS)

**Status:** 🟡 Partially Resolved - Same-device works, cross-device blocked by DR-0010
**Platform:** All platforms (cross-platform compatibility)
**Component:** DrawingCanvasView / LayerManager / Cross-platform serialization
**Severity:** Critical

**Description:**
When a draft map is created on iOS and then opened on macOS, the drawing strokes do not appear. The LayerManager structure is restored correctly, but the actual drawing content (strokes) is missing on macOS. Same-platform restoration (iOS → iOS, macOS → macOS) works correctly.

**Expected Behavior:**
Drawing strokes created on any platform should be visible when the draft is opened on any other platform. Cross-platform compatibility is essential for CloudKit-synced multi-device workflows.

**Actual Behavior:**
- iOS → iOS restoration: ✅ Works correctly
- macOS → macOS restoration: ✅ Works correctly
- **iOS → macOS restoration: ❌ Strokes disappear**
- macOS → iOS restoration: ⚠️ Likely fails (not yet tested)

**Impact:**
- Users cannot reliably work across iOS and macOS devices
- Drawing work created on iPhone/iPad is lost when switching to Mac
- Critical blocker for multi-device workflow
- Renders CloudKit sync partially useless for drawing content

**Steps to Reproduce:**
1. Create a draft map on iOS device
2. Draw strokes on the canvas (visible on iOS)
3. Save draft (switch to another card)
4. Open same draft on macOS device via CloudKit sync
5. Observe that strokes are missing

**Console Logs (Diagnostic):**
```
Restoring draft work for method: Draw Map
[IMPORT] Decoding LayerManager from 839 bytes
[IMPORT] Restored LayerManager with 2 layers
[DR-0004.3] importDrawingData called with 2 bytes
[DR-0004.3] Successfully decoded 0 strokes into model
✅ Restored drawing canvas state
```

**Analysis:**
- LayerManager restored: ✅ 839 bytes, 2 layers
- Drawing data size: ❌ Only 2 bytes (essentially empty)
- Strokes decoded: ❌ 0 strokes

**Date Identified:** 2025-12-22

**Root Cause Analysis:**

**Platform-Specific Export Formats (DrawingCanvasView.swift:462-477):**

**iOS `exportDrawingData()`** (lines 464-468):
```swift
#if canImport(PencilKit) && canImport(UIKit)
// iOS/iPadOS: Use PencilKit
let data = drawing.dataRepresentation()  // PKDrawing binary format
print("[EXPORT] exportDrawingData (PencilKit) - \(data.count) bytes")
return data
```

**macOS `exportDrawingData()`** (lines 470-475):
```swift
#else
// macOS: Export from model (persists across view recreation)
print("[EXPORT] exportDrawingData - exporting \(macOSStrokes.count) strokes from model")
let encoder = JSONEncoder()
let data = (try? encoder.encode(macOSStrokes)) ?? Data()  // JSON format
return data
```

**macOS `importDrawingData()`** (lines 526-533):
```swift
// macOS: Import into model
let decoder = JSONDecoder()
guard let importedStrokes = try? decoder.decode([DrawingStroke].self, from: data) else {
    print("[DR-0004.3] ❌ Failed to decode strokes from import data")
    return  // Silently fails when receiving iOS PKDrawing data
}
```

**The Fundamental Problem:**
1. iOS exports **PKDrawing binary format** (Apple proprietary)
2. macOS expects **JSON `[DrawingStroke]` format** (custom serialization)
3. macOS tries to JSON-decode PKDrawing binary → **fails** → returns 0 strokes
4. No error thrown, just silent failure with empty drawing

**Why LayerManager Alone Wasn't Enough:**
- DR-0008 added LayerManager serialization ✅
- DrawingLayer has cross-platform Codable support ✅
- **BUT** drawing content was never migrated to LayerManager before export
- Content remained in main `drawing` property with platform-specific format
- LayerManager was saved but layers were empty

**Resolution:**

**Fix Date:** 2025-12-22

**Implementation:**

Added automatic content migration to LayerManager before export to ensure cross-platform compatibility (DrawingCanvasView.swift:483-503):

**Key Changes:**

1. **Ensure LayerManager exists** (line 484)
   - Call `ensureLayerManager()` before export
   - Creates LayerManager if needed
   - Provides target for content migration

2. **Migrate iOS content** (lines 488-494)
   ```swift
   #if canImport(PencilKit) && canImport(UIKit)
   // iOS: Migrate PKDrawing content to active layer
   if !drawing.bounds.isEmpty {
       print("[EXPORT] Migrating \(drawing.strokes.count) PKDrawing strokes to active layer")
       activeLayer.drawing = drawing
       activeLayer.markModified()
   }
   ```

3. **Migrate macOS content** (lines 496-501)
   ```swift
   #else
   // macOS: Migrate macOS strokes to active layer
   if !macOSStrokes.isEmpty {
       print("[EXPORT] Migrating \(macOSStrokes.count) macOS strokes to active layer")
       activeLayer.macosStrokes = macOSStrokes
       activeLayer.markModified()
   }
   ```

**How Cross-Platform Serialization Works:**

DrawingLayer (from DrawingLayer.swift:144-203) has custom Codable implementation:

**Encoding:**
```swift
func encode(to encoder: Encoder) throws {
    // Encode drawing data
    #if canImport(PencilKit)
    let drawingData = drawing.dataRepresentation()  // PKDrawing → Data
    try container.encode(drawingData, forKey: .drawingData)
    #endif

    // Encode macOS strokes
    let encoder = JSONEncoder()
    if let strokesData = try? encoder.encode(macosStrokes) {
        try container.encode(strokesData, forKey: .macosStrokesData)
    }
}
```

**Decoding:**
```swift
required init(from decoder: Decoder) throws {
    // Decode drawing data
    #if canImport(PencilKit)
    if let drawingData = try? container.decode(Data.self, forKey: .drawingData) {
        drawing = (try? PKDrawing(data: drawingData)) ?? PKDrawing()
    }
    #endif

    // Decode macOS strokes
    if let strokesData = try? container.decode(Data.self, forKey: .macosStrokesData) {
        macosStrokes = (try? decoder.decode([DrawingStroke].self, from: strokesData)) ?? []
    }
}
```

**Cross-Platform Compatibility:**
- Each platform encodes its own format
- Each platform decodes its own format
- Both formats stored in LayerManager
- iOS reads `drawingData`, ignores `macosStrokesData`
- macOS reads `macosStrokesData`, ignores `drawingData`
- ✅ Works seamlessly across platforms

**Technical Details:**

- Migration happens automatically before every export
- Content copied to active layer (usually "Content Layer")
- LayerManager encoding handles platform differences
- Legacy `drawingData` field kept for backward compatibility
- Each save updates both formats in LayerManager

**Result:**
✅ Drawing content automatically migrated to LayerManager before export
✅ PKDrawing → DrawingStroke conversion implemented (lines 494-520)
✅ LayerManager handles cross-platform serialization correctly
✅ **Same-device restoration works**: iOS → iOS ✅, macOS → macOS ✅
✅ Debounced auto-save implemented (2 seconds after drawing stops)
✅ iOS build compiles successfully
✅ macOS build compiles successfully
❌ **Cross-device restoration blocked**: iOS → macOS fails due to DR-0010 CloudKit sync issue

**Testing Results (2025-12-22):**

**What Works:**
- ✅ iOS same-device: 15 strokes, 330KB+ LayerManager, perfect restoration
- ✅ macOS same-device: All strokes persist correctly
- ✅ PKDrawing conversion: Logs show "Converted 15 PKDrawing strokes to DrawingStroke format"
- ✅ Backward compatibility: Fallback to legacy import when needed (lines 645-660)

**What Doesn't Work:**
- ❌ iOS → macOS: Old data loads (87KB instead of 330KB from iOS)
- ❌ CloudKit sync: Draft data (`draftMapWorkData`) doesn't sync across devices
- ⚠️ Blocked by DR-0010 external storage sync issue

**Files Affected:**
- `DrawingCanvasView.swift` - exportCanvasState() migration and conversion (lines 483-524)
- `DrawingCanvasView.swift` - importCanvasState() extraction and fallback (lines 571-660)
- `MapWizardView.swift` - debouncedSave() for immediate save on changes (lines 1628-1652)

**Verification Needed:**
- Create draft with strokes on iOS
- Verify strokes appear on same iOS device after restore
- Sync to macOS via CloudKit
- Verify strokes appear on macOS after restore
- Test reverse direction (macOS → iOS)
- Check console logs for migration messages

**Expected Console Output (iOS export):**
```
[EXPORT] exportCanvasState called
[EXPORT] Migrating N PKDrawing strokes to active layer
[EXPORT] Encoding LayerManager with 2 layers
[EXPORT] LayerManager encoded to XXXX bytes
```

**Expected Console Output (macOS import):**
```
Restoring draft work for method: Draw Map
[IMPORT] Decoding LayerManager from XXXX bytes
[IMPORT] Restored LayerManager with 2 layers
[IMPORT] Successfully decoded N strokes into model  // Should be > 0 now
```

**Related Issues:**
- Builds on DR-0008 (LayerManager persistence)
- **BLOCKED by DR-0010** (Cross-device sync not working - CloudKit external storage issue)
- Uses DrawingLayer's cross-platform Codable implementation

**Known Limitation:**
Cross-platform draft restoration is **technically implemented** but **functionally blocked** by DR-0010. The PKDrawing → DrawingStroke conversion works, but CloudKit doesn't sync the draft data across devices. Same-device persistence works perfectly on both platforms.

---
