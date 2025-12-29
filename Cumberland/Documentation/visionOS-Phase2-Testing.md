# Cumberland visionOS Phase 2: Testing Guide

**Version:** 1.0  
**Date:** November 9, 2025  
**Phase:** 2 - Spatial Window Management

---

## Testing Environment Setup

### Requirements
- Xcode 16.0 or later
- visionOS 2.0 SDK or later
- visionOS Simulator (recommended for Phase 2 testing)
- Optional: Apple Vision Pro device for final validation

### Build Configuration
1. Open Cumberland.xcodeproj in Xcode
2. Select visionOS destination
3. Build and run (⌘R)
4. Wait for app to launch in visionOS simulator

---

## Test Plan Overview

This guide covers:
1. ✅ Functional testing (core features work)
2. ✅ Window management testing (spatial behaviors)
3. ✅ Data integrity testing (SwiftData sync)
4. ✅ Platform regression testing (macOS/iOS unchanged)
5. ✅ Edge case testing (error handling)

---

## 1. Functional Testing

### Test 1.1: Create New Card via Ornament

**Objective:** Verify new card creation opens a floating window

**Steps:**
1. Launch Cumberland on visionOS
2. Select a card kind from sidebar (e.g., "Characters")
3. Tap **New Card** button in bottom ornament
4. Observe a new window appears

**Expected Results:**
- ✅ New floating window opens
- ✅ Window title shows "New Character" (or appropriate kind)
- ✅ Card editor form is visible with empty fields
- ✅ Close button appears in toolbar
- ✅ Main window remains visible and interactive

**Pass Criteria:** All expected results met

---

### Test 1.2: Fill and Save New Card

**Objective:** Verify card creation actually saves data

**Steps:**
1. Complete Test 1.1 (card editor window open)
2. Fill in card details:
   - Name: "Test Character"
   - Subtitle: "Protagonist"
   - Author: "Your Name"
   - Details: "A test character for validation"
3. Tap **Save** button
4. Observe window closes

**Expected Results:**
- ✅ Editor window closes automatically
- ✅ New card appears in main window's card list
- ✅ Card has correct name "Test Character"
- ✅ Card thumbnail shows default image or uploaded image

**Pass Criteria:** Card successfully created and visible in list

---

### Test 1.3: Cancel New Card

**Objective:** Verify canceling doesn't create a card

**Steps:**
1. Open new card editor (Test 1.1)
2. Fill in some data
3. Tap **Close** button in toolbar
4. Confirm cancellation (if prompted)

**Expected Results:**
- ✅ Editor window closes
- ✅ No new card appears in list
- ✅ Main window remains in previous state

**Pass Criteria:** No card created, UI returns to previous state

---

### Test 1.4: Edit Existing Card

**Objective:** Verify editing opens a separate window

**Steps:**
1. Select an existing card from the list
2. Tap **Edit** button in bottom ornament
3. Observe new window opens

**Expected Results:**
- ✅ New floating window opens
- ✅ Window title shows "Edit [Card Name]"
- ✅ Form is pre-filled with card's current data
- ✅ Close button appears in toolbar
- ✅ Main window shows selected card's detail view

**Pass Criteria:** Editor window opens with correct data

---

### Test 1.5: Save Edited Card

**Objective:** Verify edits persist correctly

**Steps:**
1. Complete Test 1.4 (card editor open)
2. Modify the card's subtitle: "Updated Protagonist"
3. Tap **Save** button
4. Observe window closes

**Expected Results:**
- ✅ Editor window closes
- ✅ Main window's detail view updates with new subtitle
- ✅ Card list shows updated subtitle (if visible)

**Pass Criteria:** Changes reflected in main window immediately

---

### Test 1.6: Empty State Create Button

**Objective:** Verify placeholder view button works

**Steps:**
1. Select a card kind with no existing cards (or delete all cards)
2. Observe empty state placeholder
3. Tap **Create [Kind]** button in placeholder

**Expected Results:**
- ✅ Card editor window opens (same as ornament button)
- ✅ Form is ready for new card creation

**Pass Criteria:** Consistent behavior with ornament button

---

## 2. Window Management Testing

### Test 2.1: Multiple Editor Windows

**Objective:** Verify multiple editors can be open simultaneously

**Steps:**
1. Select "Characters" from sidebar
2. Tap **New Card** ornament button → Window 1 opens
3. Return focus to main window
4. Select "Worlds" from sidebar
5. Tap **New Card** ornament button → Window 2 opens
6. Verify both windows are visible

**Expected Results:**
- ✅ Two editor windows open simultaneously
- ✅ Each window has independent content
- ✅ Windows can be positioned separately
- ✅ Switching between windows works smoothly

**Pass Criteria:** Multiple windows coexist without issues

---

### Test 2.2: Window Positioning

**Objective:** Verify windows can be repositioned in space

**Steps:**
1. Open a card editor window
2. Use visionOS window controls to move the window
3. Position window to left of main window
4. Open a second editor window
5. Position window to right of main window

**Expected Results:**
- ✅ Windows can be moved freely in 3D space
- ✅ Windows retain their positions when focus changes
- ✅ No automatic repositioning or snapping (unless system default)

**Pass Criteria:** User has full control over window placement

---

### Test 2.3: Window Focus and Interaction

**Objective:** Verify focus handling works correctly

**Steps:**
1. Open card editor window
2. Tap main window → main window gains focus
3. Interact with card list (select different card)
4. Tap editor window → editor window gains focus
5. Type in editor form fields

**Expected Results:**
- ✅ Focus switches correctly between windows
- ✅ Main window remains fully interactive when editor is open
- ✅ Editor receives keyboard input when focused

**Pass Criteria:** Natural focus behavior, no blocked interactions

---

### Test 2.4: Window Closing

**Objective:** Verify windows close properly

**Steps:**
1. Open 3 card editor windows
2. Close windows in different orders:
   - Close middle window via toolbar button
   - Close first window via system gesture
   - Close last window via toolbar button

**Expected Results:**
- ✅ Windows close without errors
- ✅ Main window remains open
- ✅ No crashes or hung states

**Pass Criteria:** All windows close cleanly

---

## 3. Data Integrity Testing

### Test 3.1: Real-Time List Updates

**Objective:** Verify main window updates when card is created in editor

**Steps:**
1. Select "Characters" from sidebar
2. Note current card count in list
3. Open new card editor
4. Create and save a new character
5. Observe main window's card list

**Expected Results:**
- ✅ Card list automatically updates
- ✅ New card appears in list
- ✅ No manual refresh needed
- ✅ Card appears with correct data

**Pass Criteria:** SwiftData @Query observes change automatically

---

### Test 3.2: Real-Time Detail Updates

**Objective:** Verify detail view updates when card is edited in window

**Steps:**
1. Select a card from the list
2. Observe detail view shows current subtitle
3. Open card editor window
4. Change subtitle to something new
5. Save editor window
6. Observe detail view in main window

**Expected Results:**
- ✅ Detail view updates automatically
- ✅ New subtitle appears without selecting card again

**Pass Criteria:** Detail view reflects latest data

---

### Test 3.3: Multiple Editors on Same Card

**Objective:** Verify behavior when editing same card in two windows (edge case)

**Steps:**
1. Select a card from the list
2. Tap **Edit** ornament button → Editor Window 1 opens
3. Make a change in Window 1 but don't save yet
4. Tap **Edit** ornament button again → Editor Window 2 opens
5. Both windows show the same card

**Expected Results:**
- ✅ Second window opens (system allows it)
- ✅ Both windows show the same initial data
- ⚠️ If both windows are saved, last save wins (expected behavior)

**Pass Criteria:** No crash, data remains consistent (though UX could be improved in future)

**Note:** This is an edge case. Future enhancement could detect duplicate windows and bring existing window to front instead.

---

### Test 3.4: Editing While Viewing Different Card

**Objective:** Verify no interference between editor and main window selection

**Steps:**
1. Select Card A from list
2. Tap **Edit** → Editor window for Card A opens
3. Return to main window
4. Select Card B from list
5. Observe detail view shows Card B
6. Return to editor window
7. Verify editor still shows Card A

**Expected Results:**
- ✅ Editor window remains locked to Card A
- ✅ Main window can navigate freely to other cards
- ✅ No data confusion between windows

**Pass Criteria:** Windows are independent, no cross-contamination

---

## 4. Platform Regression Testing

### Test 4.1: macOS Sheet Presentation

**Objective:** Verify macOS still uses modal sheets

**Steps:**
1. Build and run Cumberland on macOS
2. Select a card kind
3. Click **New Card** toolbar button
4. Observe sheet appears

**Expected Results:**
- ✅ Modal sheet covers main window
- ✅ Main window content is dimmed
- ✅ No floating window behavior

**Pass Criteria:** macOS behavior unchanged from before Phase 2

---

### Test 4.2: iOS Sheet Presentation

**Objective:** Verify iOS still uses modal sheets

**Steps:**
1. Build and run Cumberland on iOS simulator
2. Select a card kind
3. Tap **New Card** toolbar button
4. Observe sheet appears

**Expected Results:**
- ✅ Modal sheet slides up from bottom
- ✅ Main window content visible behind sheet (or fully covered on iPhone)
- ✅ No floating window behavior

**Pass Criteria:** iOS behavior unchanged from before Phase 2

---

### Test 4.3: iPadOS Sheet Presentation

**Objective:** Verify iPadOS still uses modal sheets

**Steps:**
1. Build and run Cumberland on iPad simulator
2. Select a card kind
3. Tap **New Card** toolbar button
4. Observe sheet appears

**Expected Results:**
- ✅ Modal sheet appears (centered or full-screen based on size class)
- ✅ Standard iPadOS sheet gestures work
- ✅ No floating window behavior

**Pass Criteria:** iPadOS behavior unchanged from before Phase 2

---

## 5. Edge Case Testing

### Test 5.1: Deleting Card While Editor is Open

**Objective:** Verify graceful handling when card is deleted externally

**Steps:**
1. Select a card from list
2. Open editor window for that card
3. Return to main window
4. Delete the card (context menu → Delete)
5. Confirm deletion
6. Return to editor window

**Expected Results:**
- ✅ Editor window shows "Card Not Found" state
- ✅ User sees friendly error message
- ✅ No crash or data corruption

**Pass Criteria:** Graceful degradation, clear error message

**Implementation Note:** CardEditorWindowView already handles this with:
```swift
if let card = card {
    // Show editor
} else {
    ContentUnavailableView("Card Not Found", ...)
}
```

---

### Test 5.2: Opening Editor for Structure (Invalid State)

**Objective:** Verify structure selection doesn't allow card creation

**Steps:**
1. Select "Structure" from sidebar
2. Observe **New Card** ornament button state

**Expected Results:**
- ✅ **New Card** button is disabled (grayed out)
- ✅ Cannot tap button
- ✅ No editor window opens

**Pass Criteria:** UI prevents invalid action

---

### Test 5.3: Opening Editor When No Kind Selected

**Objective:** Verify graceful handling of ambiguous state

**Steps:**
1. Launch app (no sidebar selection yet)
2. Attempt to tap **New Card** ornament button

**Expected Results:**
- ✅ Button should be disabled OR
- ✅ Opens editor with default kind (e.g., Projects)

**Pass Criteria:** No crash, reasonable default behavior

**Implementation Note:** Check `currentCreationKind` logic in MainAppView

---

### Test 5.4: Memory Stress Test

**Objective:** Verify performance with many open windows

**Steps:**
1. Open 10 card editor windows
2. Interact with each window (type in fields)
3. Switch between windows frequently
4. Monitor memory usage in Xcode

**Expected Results:**
- ✅ App remains responsive
- ✅ No memory warnings
- ✅ Windows render correctly

**Pass Criteria:** Acceptable performance (subjective, but no crashes)

**Note:** visionOS has system limits on window count. This test verifies Cumberland doesn't add unnecessary overhead.

---

## 6. Accessibility Testing

### Test 6.1: VoiceOver Navigation

**Objective:** Verify screen reader support in floating windows

**Steps:**
1. Enable VoiceOver in visionOS settings
2. Open card editor window
3. Navigate through form fields with VoiceOver

**Expected Results:**
- ✅ All form fields are announced correctly
- ✅ Buttons have meaningful labels
- ✅ VoiceOver can navigate entire editor

**Pass Criteria:** Full VoiceOver support

---

### Test 6.2: Keyboard Navigation

**Objective:** Verify keyboard-only workflow

**Steps:**
1. Connect Bluetooth keyboard to device/simulator
2. Open card editor window
3. Navigate form using Tab key
4. Submit form using Enter key

**Expected Results:**
- ✅ Tab cycles through all interactive elements
- ✅ Keyboard shortcuts work (if implemented)
- ✅ Can complete entire workflow without pointer

**Pass Criteria:** Full keyboard accessibility

---

## Test Results Template

Use this template to record test results:

```
┌──────────────────────────────────────────────────────────┐
│ Cumberland visionOS Phase 2 Test Results                 │
├──────────────────────────────────────────────────────────┤
│ Date: _______________                                    │
│ Tester: _______________                                  │
│ Build: _______________                                   │
│ Device/Simulator: _______________                        │
└──────────────────────────────────────────────────────────┘

1. Functional Testing
   [ ] Test 1.1: Create New Card via Ornament
   [ ] Test 1.2: Fill and Save New Card
   [ ] Test 1.3: Cancel New Card
   [ ] Test 1.4: Edit Existing Card
   [ ] Test 1.5: Save Edited Card
   [ ] Test 1.6: Empty State Create Button

2. Window Management Testing
   [ ] Test 2.1: Multiple Editor Windows
   [ ] Test 2.2: Window Positioning
   [ ] Test 2.3: Window Focus and Interaction
   [ ] Test 2.4: Window Closing

3. Data Integrity Testing
   [ ] Test 3.1: Real-Time List Updates
   [ ] Test 3.2: Real-Time Detail Updates
   [ ] Test 3.3: Multiple Editors on Same Card
   [ ] Test 3.4: Editing While Viewing Different Card

4. Platform Regression Testing
   [ ] Test 4.1: macOS Sheet Presentation
   [ ] Test 4.2: iOS Sheet Presentation
   [ ] Test 4.3: iPadOS Sheet Presentation

5. Edge Case Testing
   [ ] Test 5.1: Deleting Card While Editor is Open
   [ ] Test 5.2: Opening Editor for Structure
   [ ] Test 5.3: Opening Editor When No Kind Selected
   [ ] Test 5.4: Memory Stress Test

6. Accessibility Testing
   [ ] Test 6.1: VoiceOver Navigation
   [ ] Test 6.2: Keyboard Navigation

Issues Found:
────────────────────────────────────────────────────────────

Overall Status: [ ] PASS  [ ] FAIL  [ ] NEEDS WORK

Notes:
────────────────────────────────────────────────────────────

```

---

## Known Issues / Expected Behaviors

### Issue 1: Multiple Editors for Same Card
**Behavior:** System allows opening multiple editor windows for the same card.  
**Expected:** Last saved change wins. No crash, but could be UX improvement.  
**Future Fix:** Phase 3 could detect duplicate windows and reuse existing window.

### Issue 2: Window Position Not Persisted
**Behavior:** Window positions reset between app launches.  
**Expected:** This is visionOS default behavior (system manages spatial arrangement).  
**Future Fix:** Could implement custom persistence if needed.

### Issue 3: Sheet State Variables Still Exist on visionOS
**Behavior:** `showingCardEditor` and `showingEditCardEditor` state variables exist but are never set to true on visionOS.  
**Expected:** Harmless, but could be refactored for cleanliness.  
**Future Fix:** Phase 3 could conditionally compile these variables away on visionOS.

---

## Performance Benchmarks

### Target Metrics

| Metric | Target | Acceptable | Needs Work |
|--------|--------|------------|------------|
| Editor window open time | < 0.5s | < 1s | > 1s |
| Save operation time | < 0.2s | < 0.5s | > 0.5s |
| List refresh after save | Immediate | < 0.1s | > 0.1s |
| Memory per editor window | < 50 MB | < 100 MB | > 100 MB |

Record actual metrics during testing for reference.

---

## Regression Checklist

Before marking Phase 2 complete, verify these features still work:

- [ ] Card creation on macOS/iOS (modal sheets)
- [ ] Card editing on macOS/iOS (modal sheets)
- [ ] Three-pane navigation works on all platforms
- [ ] Search functionality unchanged
- [ ] Card deletion works
- [ ] Relationship creation works
- [ ] Board views render correctly
- [ ] Timeline views render correctly
- [ ] Settings view accessible
- [ ] Image upload/attribution works in editors

---

## Troubleshooting

### Problem: Editor window doesn't open
**Possible Causes:**
- Build target not set to visionOS
- `#if os(visionOS)` conditional compilation issue
- Missing environment variable injection

**Debug Steps:**
1. Verify `openWindow` environment variable is available
2. Check Xcode console for errors
3. Confirm CumberlandApp.swift has WindowGroup for CardEditorRequest

### Problem: Changes don't persist
**Possible Causes:**
- SwiftData context not shared correctly
- onComplete closure not saving
- Model container misconfiguration

**Debug Steps:**
1. Set breakpoint in CardEditorView's save action
2. Verify modelContext.save() is called
3. Check SwiftData logs for errors

### Problem: Multiple editors interfere with each other
**Expected Behavior:**
- Each editor has independent state
- Last save wins if editing same card

**Debug Steps:**
1. Verify each CardEditorWindowView has separate @Query
2. Check card IDs are unique
3. Confirm no shared @State between windows

---

## Sign-Off

Phase 2 is ready for production when:
- [ ] All functional tests pass
- [ ] All window management tests pass
- [ ] All data integrity tests pass
- [ ] All platform regression tests pass
- [ ] At least 80% of edge case tests pass
- [ ] No critical bugs identified
- [ ] Performance meets acceptable targets

**Tested by:** _______________  
**Date:** _______________  
**Approved by:** _______________  
**Date:** _______________

---

**Happy Testing! 🚀**
