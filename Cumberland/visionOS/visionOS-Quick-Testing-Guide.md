# Quick Start: Testing visionOS Phase 1

**Goal:** Verify that Cumberland's visionOS ornaments work correctly in the simulator.

---

## Setup (2 minutes)

1. **Open your Cumberland project in Xcode**
2. **Select visionOS destination:**
   - Click the device selector at the top (next to "Cumberland")
   - Choose "My Mac (Designed for iPad)" or any iOS simulator first to verify no build errors
   - Then select **Apple Vision Pro** (simulator)
3. **Build and run:** Press `Command+R`
4. **Wait for visionOS simulator to launch**

---

## Quick Visual Check (5 minutes)

Once the app opens in the visionOS simulator:

### ✅ Check 1: Ornaments Are Visible
Look for these UI elements floating around the window:

- **Bottom of window:** Two (or three) buttons
  - "New Card" button (plus icon)
  - "Edit" button (pencil icon)
  - [DEBUG builds only] "Developer Boards" button (wrench icon)

- **Right side of window:** One button
  - "Settings" button (gear icon)

**If you see these ornaments:** ✅ Basic integration works!

### ✅ Check 2: Ornaments Are Interactive
- **Use your trackpad/mouse** to simulate gaze:
  - Move cursor over "New Card" button
  - You should see a focus ring or highlight
  - Click to open card creation sheet
  - Cancel the sheet

- **Try Settings button:**
  - Click Settings button on the right side
  - Settings sheet should open
  - Close it

**If these work:** ✅ Interactions are functional!

### ✅ Check 3: Detail Tab Picker (when card selected)
- **Select a card from the list** (e.g., a Project)
- **Look at the right side of the detail pane:**
  - You should see a **segmented picker** ornament
  - Shows tabs like "Details," "Relationships," "Board"
- **Click between tabs:**
  - Details → should show CardSheetView
  - Relationships → should show relationship view
  - Board → should show board view (for Projects)

**If tab switching works:** ✅ Detail ornament works!

### ✅ Check 4: Card List Sizing
- **Look at the card list:**
  - Thumbnails should be slightly larger than on iOS
  - More vertical spacing between rows
  - Hover over a row with your cursor → it should "lift" slightly

**If sizing looks good:** ✅ visionOS refinements applied!

---

## Quick Functional Test (5 minutes)

### Test: Create and Edit a Card

1. **Click "New Card" button** (bottom ornament)
2. **In the sheet:**
   - Name: "visionOS Test Card"
   - Subtitle: "Testing ornaments"
   - Add some detail text
3. **Save and dismiss**
4. **New card appears in list**
5. **Select the new card**
6. **Click "Edit" button** (bottom ornament)
7. **Change the name** to "visionOS Test (Edited)"
8. **Save and dismiss**
9. **Verify change appears** in list

**If this flow works end-to-end:** ✅ Phase 1 is functional!

---

## Check Backward Compatibility (5 minutes)

### Test macOS Build
1. **Change destination** to "My Mac" (macOS)
2. **Build and run** (Command+R)
3. **Verify:**
   - Traditional toolbar appears at top (NOT ornaments)
   - All buttons work
   - Tab picker in toolbar works
   - No visual glitches

### Test iOS Build
1. **Change destination** to an iOS simulator (e.g., iPhone 15 Pro)
2. **Build and run**
3. **Verify:**
   - iOS toolbars appear (NOT ornaments)
   - Settings button on content column
   - Tab picker on detail column
   - No crashes

**If both platforms still work:** ✅ No regressions!

---

## Expected Results Summary

| Test | Expected | Status |
|------|----------|--------|
| Ornaments visible (visionOS) | Bottom + trailing ornaments appear | [ ] |
| Ornaments interactive | Buttons clickable, sheets open | [ ] |
| Detail tab picker | Appears when card selected | [ ] |
| Card list sizing | Larger thumbnails, hover effect | [ ] |
| Create card flow | New card via ornament works | [ ] |
| Edit card flow | Edit via ornament works | [ ] |
| macOS compatibility | Toolbar (not ornaments) works | [ ] |
| iOS compatibility | iOS toolbars work | [ ] |

---

## If Something Doesn't Work

### Common Issues & Fixes

**Issue:** Ornaments don't appear on visionOS
- **Check:** Is the build target actually visionOS? (not "My Mac (Designed for iPad)")
- **Fix:** Select "Apple Vision Pro" explicitly

**Issue:** Build errors about `ornament` modifier not found
- **Check:** Xcode version supports visionOS (Xcode 15.2+)
- **Fix:** Update Xcode if needed

**Issue:** Ornaments appear on macOS/iOS (they shouldn't)
- **Check:** Conditional compilation (`#if os(visionOS)`)
- **Fix:** Verify conditionals in MainAppView.swift

**Issue:** Buttons in ornaments are not responding
- **Check:** Are buttons disabled? (Edit requires card selection)
- **Fix:** Select a card first, then try Edit button

**Issue:** Tab picker ornament doesn't appear
- **Check:** Is a card selected? Is it forcing CardSheetView (search mode)?
- **Fix:** Select a card and clear search

---

## Full Testing

For **comprehensive testing**, use the detailed checklist:
- See `visionOS-Phase1-Testing-Checklist.md`
- 20 test scenarios covering all edge cases
- Accessibility, performance, and edge case testing

---

## Reporting Issues

If you find bugs during testing:

1. **Note the scenario:**
   - What were you doing when the issue occurred?
   - Which card type? Which ornament?

2. **Capture details:**
   - Screenshot or screen recording
   - Xcode console output (if errors)
   - Device/simulator version

3. **Document:**
   - Add to the testing checklist's "Fail" section
   - Create a GitHub issue (if using version control)
   - Note severity: Critical (blocks usage) vs Minor (cosmetic)

---

## Success Criteria

**Phase 1 is ready to ship if:**
- ✅ All ornaments appear and work on visionOS
- ✅ Card creation/editing via ornaments works
- ✅ Tab switching via ornament works
- ✅ No regressions on macOS or iOS
- ✅ No crashes or major visual glitches

**You can move to Phase 2 planning!**

---

## Next Steps After Testing

### If all tests pass:
1. ✅ Mark Phase 1 as complete in `visionOS-Adaptation-Plan.md`
2. Consider Phase 3 visual refinements (optional)
3. Plan Phase 2 (multi-window support)

### If issues found:
1. Document all issues
2. Prioritize: Critical vs Nice-to-have
3. Fix critical issues before moving forward
4. Re-test after fixes

---

**Happy Testing! 🚀**

You're about to see Cumberland in spatial computing for the first time!
