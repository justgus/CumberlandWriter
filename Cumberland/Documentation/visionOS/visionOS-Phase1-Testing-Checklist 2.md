# visionOS Phase 1 Testing Checklist

**Testing Date:** ___________  
**Tester:** ___________  
**Build:** ___________  

---

## Pre-Testing Setup

- [ ] **Open Cumberland project in Xcode**
- [ ] **Select visionOS simulator** (or device if available)
  - Recommended: Apple Vision Pro simulator
- [ ] **Build and run** the app
- [ ] **Verify no build errors or warnings** specific to visionOS

---

## Test 1: App Launch & Initial State

### Expected Behavior
- App launches successfully on visionOS
- Three-pane NavigationSplitView appears as a floating window
- Ornaments are visible (bottom and trailing)
- No crashes or visual glitches

### Test Steps
1. Launch Cumberland on visionOS simulator
2. Observe the window layout
3. Check for ornaments:
   - Bottom ornament: "New Card" and "Edit" buttons
   - Trailing ornament: "Settings" button

### Results
- [ ] **Pass** - App launches, ornaments visible
- [ ] **Fail** - Issue: _______________________________

---

## Test 2: Bottom Ornament - Primary Actions

### Expected Behavior
- Bottom ornament contains "New Card" and "Edit" buttons
- Buttons use glass background effect
- Buttons are interactive with gaze/pinch
- Edit button is disabled when no card selected
- New Card button is disabled when Structure is selected

### Test Steps
1. **New Card button** (when Projects selected):
   - [ ] Button is enabled
   - [ ] Tap/pinch to open card creation sheet
   - [ ] Sheet appears modally
   - [ ] Create a test project card
   - [ ] Sheet dismisses after creation
   - [ ] New card appears in list

2. **New Card button** (when Structure selected):
   - [ ] Select "Structure" from sidebar
   - [ ] New Card button should be disabled (grayed out)

3. **Edit button** (no card selected):
   - [ ] Select "All Cards" or any kind
   - [ ] With no card selected, Edit button should be disabled

4. **Edit button** (card selected):
   - [ ] Select a card from the list
   - [ ] Edit button should become enabled
   - [ ] Tap/pinch Edit button
   - [ ] Card editor sheet should open
   - [ ] Make a change and save
   - [ ] Changes should reflect in list

5. **Glass effect**:
   - [ ] Ornament buttons have translucent glass appearance
   - [ ] Background content is slightly visible through ornament

### Results
- [ ] **Pass** - All primary actions work correctly
- [ ] **Fail** - Issue: _______________________________

---

## Test 3: Trailing Ornament - Settings

### Expected Behavior
- Settings button appears on trailing edge
- Tapping opens Settings sheet
- Glass background effect applied

### Test Steps
1. Locate Settings button on trailing ornament
2. Tap/pinch Settings button
3. Settings sheet should open
4. Dismiss settings
5. Ornament remains visible and functional

### Results
- [ ] **Pass** - Settings ornament works
- [ ] **Fail** - Issue: _______________________________

---

## Test 4: Detail Column Ornament - Tab Picker

### Expected Behavior
- When a card is selected, trailing ornament appears on detail column
- Contains segmented picker for switching between tabs
- Only shows tabs available for that card type
- Glass background effect applied

### Test Steps
1. **No card selected:**
   - [ ] No tab picker ornament on detail column

2. **Select a Project card:**
   - [ ] Tab picker ornament appears on detail column (trailing edge)
   - [ ] Shows tabs: Details, Relationships, Board
   - [ ] Tap each tab and verify content switches
   - [ ] Details: CardSheetView appears
   - [ ] Relationships: CardRelationshipView appears
   - [ ] Board: StructureBoardView appears

3. **Select a Chapter card:**
   - [ ] Tab picker shows: Details, Relationships, Aggregate
   - [ ] All tabs switch correctly

4. **Select a Timeline card:**
   - [ ] Tab picker shows: Details, Relationships, Timeline
   - [ ] Timeline tab shows TimelineChartView

5. **Select a World card:**
   - [ ] Tab picker shows: Details, Relationships, Board
   - [ ] Board tab shows MurderBoardView

6. **Select a Character or Scene card:**
   - [ ] Tab picker shows: Details, Relationships, Board
   - [ ] Board tab shows MurderBoardView

7. **Select a card of another type** (Maps, Locations, Buildings, Vehicles, Artifacts, Rules, Sources):
   - [ ] Tab picker shows: Details, Relationships (no Board/Timeline)

### Results
- [ ] **Pass** - Tab picker ornament works for all card types
- [ ] **Fail** - Issue: _______________________________

---

## Test 5: Card List Interaction (visionOS-specific sizing)

### Expected Behavior
- Card list rows are larger on visionOS (48pt thumbnails vs 40pt)
- Vertical padding increased (8pt vs 4pt)
- Hover effect (lift) appears on gaze

### Test Steps
1. View the card list (Projects, Characters, or any kind with cards)
2. **Visual inspection:**
   - [ ] Rows appear larger/more spacious than iOS
   - [ ] Thumbnails are bigger
3. **Hover effect:**
   - [ ] Move gaze over a card row
   - [ ] Row should "lift" slightly (visual elevation)
4. **Selection:**
   - [ ] Pinch/tap to select a card
   - [ ] Detail view updates correctly

### Results
- [ ] **Pass** - Card list sizing and hover work
- [ ] **Fail** - Issue: _______________________________

---

## Test 6: Navigation Between Card Types

### Expected Behavior
- Sidebar navigation works smoothly
- Ornaments remain visible during navigation
- Tab picker updates based on selected card kind

### Test Steps
1. Navigate through sidebar:
   - [ ] Projects
   - [ ] Worlds
   - [ ] Characters
   - [ ] Scenes
   - [ ] Chapters
   - [ ] Timelines
   - [ ] Structure
   - [ ] All Cards
2. For each:
   - [ ] Content column updates
   - [ ] Ornaments remain accessible
   - [ ] No visual glitches

### Results
- [ ] **Pass** - Navigation works smoothly
- [ ] **Fail** - Issue: _______________________________

---

## Test 7: Search Functionality

### Expected Behavior
- Search bar appears in navigation
- Searching filters cards
- Ornaments remain functional during search

### Test Steps
1. Tap search bar in navigation
2. Type a search query (e.g., "test")
3. Card list filters to matching cards
4. Select a filtered card
5. Detail view shows correctly
6. Tab picker ornament appears (if applicable)
7. Clear search
8. Full list reappears

### Results
- [ ] **Pass** - Search works with ornaments
- [ ] **Fail** - Issue: _______________________________

---

## Test 8: Card Creation Flow (Full Workflow)

### Expected Behavior
- Complete card creation from ornament button
- All fields editable
- Card saves and appears in list

### Test Steps
1. Select "Projects" from sidebar
2. Tap "New Card" button on bottom ornament
3. In card editor:
   - [ ] Enter name: "visionOS Test Project"
   - [ ] Enter subtitle: "Testing ornaments"
   - [ ] Add some detailed text
   - [ ] (Optional) Add thumbnail
4. Tap Save/Done
5. Sheet dismisses
6. New card appears in Projects list
7. Select the new card
8. Detail view shows correct information

### Results
- [ ] **Pass** - Full creation workflow works
- [ ] **Fail** - Issue: _______________________________

---

## Test 9: Card Editing Flow

### Expected Behavior
- Edit existing card via ornament button
- Changes save correctly

### Test Steps
1. Select an existing card
2. Tap "Edit" button on bottom ornament
3. Make changes to name, subtitle, or detailed text
4. Tap Save/Done
5. Sheet dismisses
6. Changes reflect in detail view
7. Changes persist after navigating away and back

### Results
- [ ] **Pass** - Editing workflow works
- [ ] **Fail** - Issue: _______________________________

---

## Test 10: Ornament Persistence & Visibility

### Expected Behavior
- Ornaments remain visible and accessible at all times
- Don't disappear during interactions
- Don't obscure important content

### Test Steps
1. Navigate to various card types
2. Open and close sheets
3. Switch between tabs
4. Scroll through long card lists
5. Throughout, verify:
   - [ ] Bottom ornament remains visible
   - [ ] Trailing ornament remains visible
   - [ ] Tab picker ornament appears/disappears appropriately
   - [ ] Ornaments don't block important UI elements

### Results
- [ ] **Pass** - Ornaments persist correctly
- [ ] **Fail** - Issue: _______________________________

---

## Test 11: Developer Boards (DEBUG Build Only)

### Expected Behavior
- In DEBUG builds, Developer Boards button appears on bottom ornament
- Opens DeveloperBoardsView sheet

### Test Steps (if DEBUG build)
1. Verify "Developer Boards" button appears on bottom ornament
2. Tap Developer Boards button
3. DeveloperBoardsView sheet opens
4. Inspect board data (if any)
5. Dismiss sheet
6. Ornaments remain functional

### Results
- [ ] **Pass** - Developer Boards accessible
- [ ] **N/A** - Not a DEBUG build
- [ ] **Fail** - Issue: _______________________________

---

## Test 12: Gaze & Pinch Interaction Quality

### Expected Behavior
- All ornament buttons respond to gaze + pinch
- Visual feedback on hover (focus ring, highlight)
- Interaction feels natural and responsive

### Test Steps
1. Use gaze to focus on each ornament button
2. Verify focus indicator appears
3. Perform pinch gesture to activate
4. Button should respond immediately
5. Repeat for:
   - [ ] New Card button
   - [ ] Edit button
   - [ ] Settings button
   - [ ] Tab picker segments (when visible)

### Results
- [ ] **Pass** - Gaze/pinch interactions feel natural
- [ ] **Fail** - Issue: _______________________________

---

## Test 13: Ornament Glass Material

### Expected Behavior
- All ornaments use `.glassBackgroundEffect()`
- Translucent appearance
- Blurs content behind
- Reflects ambient light/color

### Test Steps
1. **Visual inspection** of all ornaments:
   - [ ] Bottom ornament has glass effect
   - [ ] Trailing settings ornament has glass effect
   - [ ] Detail tab picker ornament has glass effect
2. Move window or adjust lighting (if on device)
3. Observe glass effect adapts to environment

### Results
- [ ] **Pass** - Glass effects look correct
- [ ] **Fail** - Issue: _______________________________

---

## Test 14: Structure View (No Card List)

### Expected Behavior
- When Structure is selected, no card list appears
- StoryStructureView shows instead
- Ornaments remain visible but New Card is disabled

### Test Steps
1. Select "Structure" from sidebar
2. Content column shows StoryStructureView (not card list)
3. Bottom ornament:
   - [ ] New Card button is disabled
   - [ ] Edit button is disabled (no card selected)
4. Ornaments don't interfere with StoryStructureView

### Results
- [ ] **Pass** - Structure view works with ornaments
- [ ] **Fail** - Issue: _______________________________

---

## Test 15: Multi-Window Support (Future Consideration)

### Expected Behavior
- Currently Phase 1 uses single window
- Note any limitations or opportunities for Phase 2 window management

### Observations
- Can multiple windows be opened manually?
- How do ornaments behave with multiple instances?
- Any spatial computing features underutilized?

### Notes
_______________________________________________________
_______________________________________________________

---

## Test 16: Keyboard Accessibility (if available)

### Expected Behavior
- Ornament buttons accessible via keyboard navigation
- Focus order makes sense

### Test Steps (if keyboard connected)
1. Use Tab key to navigate
2. Verify focus order:
   - Sidebar → Content list → Detail → Ornaments
3. Press Return/Space to activate focused button
4. Verify keyboard shortcuts still work (if any)

### Results
- [ ] **Pass** - Keyboard navigation works
- [ ] **N/A** - No keyboard tested
- [ ] **Fail** - Issue: _______________________________

---

## Test 17: VoiceOver Support (Accessibility)

### Expected Behavior
- All ornament buttons have proper accessibility labels
- VoiceOver announces button purpose clearly

### Test Steps (if VoiceOver available)
1. Enable VoiceOver on visionOS
2. Navigate to ornaments
3. Verify labels:
   - [ ] "New Card" button announced
   - [ ] "Edit" button announced
   - [ ] "Settings" button announced
   - [ ] Tab picker segments announced
4. Actions work with VoiceOver gestures

### Results
- [ ] **Pass** - VoiceOver works correctly
- [ ] **N/A** - VoiceOver not tested
- [ ] **Fail** - Issue: _______________________________

---

## Test 18: Performance & Stability

### Expected Behavior
- App runs smoothly without lag
- Ornaments don't cause performance issues
- No memory leaks or crashes

### Test Steps
1. Use app continuously for 5-10 minutes
2. Create, edit, and delete multiple cards
3. Navigate between many card types
4. Switch tabs frequently
5. Open and close sheets repeatedly
6. Monitor for:
   - [ ] Lag or frame drops
   - [ ] Visual glitches
   - [ ] Crashes or hangs
   - [ ] Memory warnings

### Results
- [ ] **Pass** - App performs well
- [ ] **Fail** - Issue: _______________________________

---

## Test 19: Backward Compatibility (Non-visionOS)

### Expected Behavior
- macOS and iOS builds still work correctly
- Toolbars remain functional (no ornaments on these platforms)

### Test Steps
1. **Switch to macOS target** and build
   - [ ] App builds without errors
   - [ ] Traditional toolbar appears (no ornaments)
   - [ ] All buttons functional
   - [ ] Tab picker in toolbar works

2. **Switch to iOS target** and build
   - [ ] App builds without errors
   - [ ] iOS toolbars appear correctly
   - [ ] No ornament code runs
   - [ ] Tab picker in detail toolbar works

### Results
- [ ] **Pass** - macOS and iOS unaffected
- [ ] **Fail** - Issue: _______________________________

---

## Test 20: Edge Cases & Error Handling

### Test Steps
1. **Empty state:**
   - [ ] Delete all cards (or start fresh)
   - [ ] Ornaments still visible and functional
   - [ ] Create new card from ornament works

2. **Very long card list:**
   - [ ] Create 50+ cards (or use existing dataset)
   - [ ] Scroll performance is good
   - [ ] Ornaments don't disappear during scroll

3. **Rapid interactions:**
   - [ ] Quickly tap ornament buttons multiple times
   - [ ] No duplicate sheets or crashes
   - [ ] App handles rapid input gracefully

4. **Orientation changes (if applicable):**
   - [ ] Ornaments reposition correctly
   - [ ] No layout issues

### Results
- [ ] **Pass** - Edge cases handled
- [ ] **Fail** - Issue: _______________________________

---

## Overall Phase 1 Assessment

### Summary
- **Total Tests:** 20
- **Passed:** _____ / 20
- **Failed:** _____ / 20
- **N/A:** _____ / 20

### Critical Issues (Must Fix Before Shipping)
1. _______________________________________________________
2. _______________________________________________________
3. _______________________________________________________

### Minor Issues (Nice to Have)
1. _______________________________________________________
2. _______________________________________________________
3. _______________________________________________________

### Recommendations for Phase 2
- _______________________________________________________
- _______________________________________________________
- _______________________________________________________

---

## Sign-Off

**Tester Signature:** _______________________________  
**Date:** _______________________________  
**Ready for Phase 2?** [ ] Yes  [ ] No  [ ] With Fixes

---

**Notes:**
- This checklist covers Phase 1 implementation (ornaments + basic visionOS support)
- For Phase 2 testing (window management), see separate checklist
- Report all issues to development team with screenshots/recordings if possible
