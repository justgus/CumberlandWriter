//
//  MurderBoardTest.md
//  Cumberland
//
//  Created by Mike Stoddard on 10/26/25.
//

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:30:12] IA-23 INVESTIGATION RESULT
Test: IA-23.1: Isolation
Result: SUCCESS: Context menu appeared and functioned correctly
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:30:17] IA-23 INVESTIGATION RESULT
Test: IA-23.1: Isolation
Result: Context menu action executed successfully
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[IA-23] Starting test: IA-23.2a: Position Only
Description: Test CardView with only .position() applied to identify if position transform breaks contextMenu.
Instructions: Right-click on the transformed card. Note if context menu appears and if position is correct.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:30:28] IA-23 INVESTIGATION RESULT
Test: IA-23.2a: Position Only
Result: SUCCESS: Context menu works with .position() transform
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 IA-23 CURRENT TEST CONSOLE LOG
═══════════════════════════════════════════
Test: IA-23.2a: Position Only
Description: Test CardView with only .position() applied to identify if position transform breaks contextMenu.
Result: SUCCESS: Context menu works with .position() transform

Gesture Log:
  [16:30:28] RESULT: SUCCESS: Context menu works with .position() transform
═══════════════════════════════════════════

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:31:00] IA-23 INVESTIGATION RESULT
Test: IA-23.2a: Position Only
Result: FAILED: Context menu appeared but .position() caused issues
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:31:06] IA-23 INVESTIGATION RESULT
Test: IA-23.2a: Position Only
Result: SUCCESS: Context menu works with .position() transform
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[IA-23] Starting test: IA-23.2b: Scale Only
Description: Test CardView with only .scaleEffect() applied to identify if scale transform breaks contextMenu.
Instructions: Right-click on the transformed card. Note if context menu appears and if position is correct.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:31:24] IA-23 INVESTIGATION RESULT
Test: IA-23.2b: Scale Only
Result: SUCCESS: Context menu works with .scaleEffect() transform
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[IA-23] Starting test: IA-23.2c: Offset Only
Description: Test CardView with only .offset() applied to identify if offset transform breaks contextMenu.
Instructions: Right-click on the transformed card. Note if context menu appears and if position is correct.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:31:35] IA-23 INVESTIGATION RESULT
Test: IA-23.2c: Offset Only
Result: SUCCESS: Context menu works with .offset() transform
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[IA-23] Starting test: IA-23.2d: Position + Scale
Description: Test CardView with .position() + .scaleEffect() to identify combination effects.
Instructions: Right-click on the card with combined transforms. Test if context menu works and appears at correct location.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:31:43] IA-23 INVESTIGATION RESULT
Test: IA-23.2d: Position + Scale
Result: SUCCESS: Context menu works with .position() + .scaleEffect()
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[IA-23] Starting test: IA-23.2e: Position + Offset
Description: Test CardView with .position() + .offset() to identify combination effects.
Instructions: Right-click on the card with combined transforms. Test if context menu works and appears at correct location.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:31:51] IA-23 INVESTIGATION RESULT
Test: IA-23.2e: Position + Offset
Result: SUCCESS: Context menu works with .position() + .offset()
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[IA-23] Starting test: IA-23.2f: Scale + Offset
Description: Test CardView with .scaleEffect() + .offset() to identify combination effects.
Instructions: Right-click on the card with combined transforms. Test if context menu works and appears at correct location.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:31:59] IA-23 INVESTIGATION RESULT
Test: IA-23.2f: Scale + Offset
Result: SUCCESS: Context menu works with .scaleEffect() + .offset()
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[IA-23] Starting test: IA-23.2g: All Transforms
Description: Test CardView with all three transforms (.position + .scaleEffect + .offset) - the full MurderBoardView scenario.
Instructions: Right-click on the card with combined transforms. Test if context menu works and appears at correct location.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:32:07] IA-23 INVESTIGATION RESULT
Test: IA-23.2g: All Transforms
Result: SUCCESS: Context menu works with all transforms (.position + .scaleEffect + .offset)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[IA-23] Starting test: IA-23.3: Basic Gestures
Description: Test if ANY gestures work on transformed CardView (onTapGesture, onHover) to verify event routing.
Instructions: Try: 1) Regular tap, 2) Hover over card, 3) Long press, 4) Right-click. Check which gestures work.
[IA-23 Gesture] [16:32:24] HOVER: Entered hover state
[IA-23 Gesture] [16:32:24] HOVER: Exited hover state
[IA-23 Gesture] [16:32:25] HOVER: Entered hover state
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:32:36] IA-23 INVESTIGATION RESULT
Test: IA-23.3: Basic Gestures
Result: Context menu appeared despite transforms - basic gestures also work
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[IA-23 Gesture] [16:32:36] CONTEXT: Context menu activated
[IA-23 Gesture] [16:32:36] HOVER: Exited hover state
[IA-23 Gesture] [16:32:38] HOVER: Entered hover state
[IA-23 Gesture] [16:32:44] LONG PRESS: Long press gesture detected
[IA-23 Gesture] [16:32:48] LONG PRESS: Long press gesture detected
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:32:58] IA-23 INVESTIGATION RESULT
Test: IA-23.3: Basic Gestures
Result: Context menu appeared despite transforms - basic gestures also work
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[IA-23 Gesture] [16:32:58] CONTEXT: Context menu activated
[IA-23 Gesture] [16:32:58] HOVER: Exited hover state
[IA-23 Gesture] [16:32:58] HOVER: Entered hover state
[IA-23 Gesture] [16:33:00] TAP: Tap gesture #1 detected
[IA-23 Gesture] [16:33:05] HOVER: Exited hover state

[IA-23] Starting test: IA-23.4: Alternatives
Description: Test alternative context menu approaches: longPressGesture, platform-native menus, popover menus.
Instructions: Test alternative approaches: Long press the first card, or click the button for popover menu.
[IA-23 Gesture] [16:33:25] ALTERNATIVE: Long press detected - could trigger menu
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:33:25] IA-23 INVESTIGATION RESULT
Test: IA-23.4: Alternatives
Result: Alternative approach: Long press gesture works as context menu trigger
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[IA-23 Gesture] [16:33:36] ALTERNATIVE: Long press detected - could trigger menu
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:33:36] IA-23 INVESTIGATION RESULT
Test: IA-23.4: Alternatives
Result: Alternative approach: Long press gesture works as context menu trigger
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[IA-23 Gesture] [16:33:54] ALTERNATIVE: Popover menu action 2

[IA-23] Starting test: IA-23.5: Hierarchy
Description: Analyze view hierarchy and test for parent view interference with context menu events.
Instructions: Right-click the card inside the complex view hierarchy. Check if overlays interfere with context menu.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[16:34:41] IA-23 INVESTIGATION RESULT
Test: IA-23.5: Hierarchy
Result: Context menu works despite view hierarchy complexity
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 IA-25 DIRECT NSMENUS APPROACH  
═══════════════════════════════════════════
After IA-24 overlay approach failed, implementing platform-native context menus

[IA-25] Implementation: IA-25.1: Direct NSMenu Implementation
Status: ✅ COMPLETED
- Removed SwiftUI contextMenu overlay completely
- Implemented DirectContextMenuHandler using NSViewRepresentable  
- NSView captures rightMouseDown and Ctrl+click before SwiftUI gestures
- Creates native NSMenu with "Remove from Board" option

[IA-25] TESTING REQUIRED:
□ Right-click context menu appears at all zoom levels
□ "Remove from Board" removes correct card  
□ Menu appears at correct screen position
□ Drag gestures still work (should not interfere)
□ Works with transforms applied (position, scale, offset)
═══════════════════════════════════════════
