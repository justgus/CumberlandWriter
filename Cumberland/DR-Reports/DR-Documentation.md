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
