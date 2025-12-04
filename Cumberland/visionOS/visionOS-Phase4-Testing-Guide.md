# visionOS Phase 4 Testing Guide

**Phase:** 4 - Interaction Model Updates  
**Focus:** Spatial input, accessibility, and keyboard navigation  
**Estimated Testing Time:** 30-45 minutes

---

## Quick Start

### Prerequisites
- visionOS simulator running
- Cumberland app built with Phase 4 changes
- Optional: Bluetooth keyboard for keyboard shortcut testing
- Optional: VoiceOver enabled (Settings → Accessibility → VoiceOver)

---

## Test Sections

### 1. Card List Spatial Input (10 min)

#### Gaze + Pinch Selection
1. **Open any card type** (Projects, Characters, etc.)
2. **Look at different cards** in the list
3. **Verify hover highlight** appears on the card you're looking at
4. **Pinch to select** a card
5. **Verify detail view** updates correctly

**Expected:**
- Smooth hover highlights appear under your gaze
- Entire card row area responds to gaze (not just text)
- Pinch gesture selects card immediately
- Visual feedback is subtle but clear

**Pass/Fail:** ☐

---

#### Visual Comfort
1. **Scan through card list** quickly
2. **Check spacing** between cards
3. **Check text size** of card names and subtitles
4. **Check thumbnail clarity**

**Expected:**
- Card rows feel comfortable to read at spatial distance
- Names are easily readable (title3 font)
- Thumbnails are clear and appropriately sized (52pt)
- Vertical spacing (10pt) feels natural

**Pass/Fail:** ☐

---

#### Context Menu
1. **Look at a card** in the list
2. **Long press** (or pinch and hold) to open context menu
3. **Verify menu sections** appear correctly
4. **Test each menu option:**
   - Edit Card → Opens floating editor window
   - View Details → Selects card in main window
   - Delete Card → Removes card (confirm first!)

**Expected:**
- Context menu appears with 3 sections (Primary, Future, Destructive)
- Section dividers are visible
- Menu items have clear labels and icons
- Actions execute correctly

**Pass/Fail:** ☐

---

### 2. Ornament Interaction (10 min)

#### Primary Actions (Bottom Ornament)
1. **Look at bottom ornament**
2. **Test New Card button:**
   - Pinch to activate
   - Verify floating editor window opens
   - Close window with Done/Cancel
3. **Select a card** in the list
4. **Test Edit button:**
   - Pinch to activate
   - Verify floating editor window opens for selected card
5. **Try with Structure selected:**
   - New Card button should be disabled (grayed out)

**Expected:**
- Buttons respond to gaze + pinch
- Hover effects appear on gaze
- Glass background effect visible
- Disabled states are clear

**Pass/Fail:** ☐

---

#### Settings Ornament (Leading Edge)
1. **Look at leading edge** of window
2. **Notice icon-only Settings button**
3. **Hover over Settings button:**
   - Text "Settings" should appear
4. **Pinch Settings button:**
   - Settings sheet should open
5. **Test close button:**
   - X button should be visible next to Settings
   - Pinch to dismiss settings

**Expected:**
- Settings button expands on hover (animated)
- Close button always visible
- Both buttons have glass background
- Settings sheet opens/closes correctly

**Pass/Fail:** ☐

---

#### Detail Tab Picker (Top Ornament)
1. **Select any card** with multiple tabs available
2. **Look at top of detail column**
3. **Tab picker ornament** should appear
4. **Test switching tabs:**
   - Look at different tab segments
   - Pinch to select
   - Verify view changes appropriately

**Expected:**
- Segmented picker with multiple options
- Clear visual indication of selected tab
- Smooth transitions between views
- Glass background effect on picker

**Pass/Fail:** ☐

---

### 3. Keyboard Navigation (10 min)

#### Primary Shortcuts
Test each keyboard shortcut:

1. **⌘N** - New Card
   - Should open floating editor window
   
2. **⌘E** - Edit Card
   - Should open editor for selected card
   - Should do nothing if no card selected
   
3. **⌘,** - Settings
   - Should open Settings sheet
   
4. **Escape** - Close/Dismiss
   - Should close Settings sheet if open
   - Test in editor windows too
   
5. **⌘⇧D** (DEBUG only) - Developer Boards
   - Should open Developer Boards sheet

**Expected:**
- All shortcuts respond immediately
- No conflicts with system shortcuts
- Disabled actions don't trigger

**Pass/Fail:** ☐

---

#### Tab Navigation
1. **Press Tab key** repeatedly
2. **Verify focus moves** through UI in logical order:
   - Sidebar items
   - Card list
   - Ornament buttons
   - Tab picker
   - Detail view controls

**Expected:**
- Focus indicator visible on each element
- Focus order follows visual layout (left to right, top to bottom)
- No focus traps (can always navigate away)

**Pass/Fail:** ☐

---

### 4. VoiceOver Accessibility (10 min)

#### Setup
1. **Enable VoiceOver** in visionOS Settings
2. **Return to Cumberland**
3. **Use pinch + drag** to navigate (VoiceOver navigation gesture)

---

#### Sidebar Navigation
1. **Navigate to sidebar**
2. **Swipe through items:**
   - Structure
   - All Cards
   - Each card type

**Expected:**
- Each item announces clearly: "Projects, view all projects"
- Hints provide context about what each item does
- Current selection is announced

**Pass/Fail:** ☐

---

#### Card List
1. **Navigate to card list**
2. **Swipe through cards**

**Expected:**
- Each card announces: "[Card Name], [Kind]"
- Hint: "Double tap to view details"
- Selected state is announced

**Pass/Fail:** ☐

---

#### Ornaments
1. **Navigate to bottom ornament**
2. **Swipe through buttons:**
   - New Card
   - Edit Card
   - Developer Boards (DEBUG)

**Expected:**
- Each button announces: "[Action]"
- Hints explain what action does
- Disabled states announced: "Unavailable, [reason]"

**Pass/Fail:** ☐

---

#### Settings Ornament
1. **Navigate to leading ornament**
2. **Activate Settings button**
3. **Navigate through Settings sheet**
4. **Find and activate close button**

**Expected:**
- Settings button: "Settings, button, opens application settings"
- Close button: "Close Settings, button, dismisses the settings window"
- Sheet dismisses when close is activated

**Pass/Fail:** ☐

---

### 5. Edge Cases & Stress Tests (5 min)

#### Empty States
1. **Navigate to card type with no cards**
2. **Verify empty state message** is clear
3. **Verify Create button** is accessible

**Expected:**
- Empty state properly announced by VoiceOver
- Create button visible and functional

**Pass/Fail:** ☐

---

#### Many Cards
1. **Navigate to card type with many cards** (20+)
2. **Scroll through list** with gaze + pinch-drag
3. **Verify performance** remains smooth

**Expected:**
- Scrolling is smooth, no lag
- Hover effects still responsive
- Cards load efficiently

**Pass/Fail:** ☐

---

#### Context Menu with No Selection
1. **Deselect all cards** (click in empty area)
2. **Try opening context menu** on a card
3. **Select Edit or View Details**

**Expected:**
- Context menu still works
- Actions select the card first, then execute

**Pass/Fail:** ☐

---

#### Multiple Windows
1. **Open New Card** (floating window)
2. **Switch back to main window**
3. **Open Edit Card** (another floating window)
4. **Verify both editor windows** are accessible

**Expected:**
- Multiple editor windows can coexist
- Can switch between windows easily
- Each window maintains its state

**Pass/Fail:** ☐

---

## Common Issues & Solutions

### Issue: Hover effects not appearing
**Solution:** Ensure you're looking directly at the card row, not past it. Try adjusting head position.

### Issue: Context menu won't open
**Solution:** Try a longer press/hold. visionOS context menus require ~1 second hold.

### Issue: Keyboard shortcuts not working
**Solution:** Ensure window has focus. Click in the window first, then try shortcuts.

### Issue: VoiceOver navigation feels stuck
**Solution:** Use pinch + drag to move focus. Swipe left/right to navigate between items.

### Issue: Text too small to read
**Solution:** This is expected! Phase 4 optimizes for spatial distance. Text should be readable at ~3 feet.

---

## Success Criteria

### Must Pass (Critical)
- ☐ All card rows respond to gaze + pinch
- ☐ Context menus open and function correctly
- ☐ All keyboard shortcuts work
- ☐ VoiceOver announces all interactive elements clearly
- ☐ Hover effects appear on all interactive elements

### Should Pass (Important)
- ☐ Tab navigation follows logical order
- ☐ Text is comfortably readable at spatial distance
- ☐ Multiple editor windows work simultaneously
- ☐ Empty states are accessible and clear
- ☐ Scrolling performance is smooth with many cards

### Nice to Have (Polish)
- ☐ Hover effects feel natural and smooth
- ☐ Animations are subtle and pleasant
- ☐ Visual hierarchy is immediately clear
- ☐ All gestures feel intuitive

---

## Bug Report Template

If you find issues, document them like this:

**Bug:** [Short description]  
**Platform:** visionOS [version]  
**Reproducibility:** Always / Sometimes / Rare  
**Steps:**
1. [Step 1]
2. [Step 2]
3. [etc.]

**Expected:** [What should happen]  
**Actual:** [What actually happens]  
**Severity:** Critical / Major / Minor / Cosmetic

---

## Final Checklist

Before marking Phase 4 as fully tested:

- ☐ All test sections completed
- ☐ All "Must Pass" criteria met
- ☐ All bugs documented (if any)
- ☐ Performance is acceptable
- ☐ No regressions on macOS/iOS (quick sanity check)

---

## Time Tracking

**Spatial Input Tests:** _____ min  
**Ornament Tests:** _____ min  
**Keyboard Tests:** _____ min  
**VoiceOver Tests:** _____ min  
**Edge Cases:** _____ min  
**Total Time:** _____ min

---

## Notes

Use this space for any observations, suggestions, or feedback:

---

**Tester Name:** _________________  
**Date:** _________________  
**Build:** _________________  
**Result:** ☐ Pass ☐ Pass with issues ☐ Fail

---

**Document created:** November 11, 2025  
**Related:** visionOS-Phase4-Implementation-Summary.md
