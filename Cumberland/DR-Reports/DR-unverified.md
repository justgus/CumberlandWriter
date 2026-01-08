# Discrepancy Reports (DR) - Unverified Issues

This document tracks discrepancy reports that have been resolved but are awaiting user verification.

**Status:** Currently **1 unverified DR** (1 Not Resolved)

---

## DR-0031: Advanced Brush Rendering Not Executed for River/Water Brushes on macOS

**Status:** 🔴 Identified - Not Resolved
**Platform:** macOS
**Component:** DrawCanvas/macOS Drawing System
**Severity:** High
**Date Identified:** 2026-01-08

**Description:**
When drawing with the River brush on a Water Feature layer on macOS, only a simple blue line is rendered instead of the expected procedurally-generated river with meandering curves and variable width. Setting a breakpoint at `BrushEngine.swift:684` (where advanced river rendering begins) confirms the code is never reached.

**Root Cause:**
On macOS, the drawing system does NOT use the BrushEngine's advanced rendering at all. The macOS-specific drawing path is entirely separate:

1. **Drawing Flow on macOS:**
   - `DrawingCanvasViewMacOS.swift:362-426` - `drawStroke()` method
   - This method renders strokes as simple NSBezierPath curves with basic color and width
   - No brush category checking, no pattern generation, no procedural effects
   - Just: set color, set width, draw path

2. **BrushEngine Integration Missing:**
   - The advanced rendering in `BrushEngine.renderWaterBrush` (lines 668-749) is never called from macOS code
   - `BrushEngine+macOS.swift` exists but `renderStrokeForMacOS()` (line 98) just calls the basic `renderStroke()` method
   - The category-based rendering (`renderWaterBrush`, `renderTerrainBrush`, etc.) is never invoked on macOS

3. **Brush Information Lost:**
   - When a stroke is saved (line 146-154), only basic properties are stored: points, color, lineWidth, toolType
   - The `selectedBrush` is referenced at mouseDown (line 100) but only to get color and width
   - Brush ID, category, and pattern information are not stored with the stroke

**Affected Code:**
- `Cumberland/DrawCanvas/DrawingCanvasViewMacOS.swift:362-426` - drawStroke() and drawCurrentStroke()
- `Cumberland/DrawCanvas/DrawingCanvasViewMacOS.swift:136-169` - mouseUp() - stroke finalization
- `Cumberland/DrawCanvas/BrushEngine+macOS.swift:98-128` - renderStrokeForMacOS()

**Expected Behavior:**
Drawing with the River brush should produce:
- Natural meandering curves using sinusoidal displacement
- Variable width along the path with tapered ends
- Filled polygon between left/right banks
- Semi-transparent water effect with subtle center line detail

**Actual Behavior:**
A simple solid blue line with constant width is drawn using NSBezierPath.

**Proposed Solution:**
1. Store brush metadata with each stroke (brush ID, category, pattern type)
2. In `drawStroke()`, check if the stroke was made with an advanced brush
3. If yes, extract the original brush from BrushRegistry and call `BrushEngine.renderAdvancedStroke()`
4. Otherwise, use the current simple path rendering

Alternatively, integrate BrushEngine rendering during stroke creation in `drawCurrentStroke()` for real-time preview.

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
