# ER-0022 Phase 5: Manual Regression Testing Checklist

**Date:** 2026-02-07
**Purpose:** Validate that ER-0022 Phases 1-4 implementation has not introduced regressions
**Estimated Time:** 2-3 hours
**Platforms:** macOS, iOS, iPadOS (visionOS optional)

---

## Testing Instructions

1. **Launch Cumberland** on target platform
2. **Work through each section** sequentially
3. **Check ✅** each item as you complete it
4. **Note any issues** in the "Issues Found" section at bottom
5. **Test on multiple platforms** if possible

---

## Section 1: ServiceContainer Initialization (Phase 4)

**Goal:** Verify dependency injection infrastructure works correctly

### Startup Tests
- [x] App launches without crashes on macOS
- [x] App launches without crashes on iOS
- [x] App launches without crashes on iPadOS
- [x] No console errors related to ServiceContainer initialization
- [x] No console warnings about missing services

### Service Availability Tests
- [x] Create a new character card → succeeds (tests CardOperationManager)
- [x] Create a relationship → succeeds (tests RelationshipManager)
- [x] Generate AI image → succeeds (tests ImageProcessingService)

**Expected:** All services should be available through `@Environment(\.services)` in views.

**Issues Found:** _____________________________________________

---

## Section 2: ImageProcessingService (Phase 1)

**Goal:** Verify image processing consolidation works and no duplicate code is active

### Thumbnail Generation Tests
- [x] Generate AI image for a character card
- [x] Verify thumbnail appears in card list
- [x] Thumbnail is correctly sized (~200x200px)
- [x] Thumbnail maintains aspect ratio

### Image History Tests
- [x] Open AI Image Generation view
- [x] Generate 2-3 images for a card
- [x] Open Image History view
- [x] All historical images have thumbnails
- [x] Thumbnails load quickly (<1 second each)
- [x] Select a historical image → view full size

### Image Export Tests
- [ ] Export an image as PNG
- [ ] Verify PNG file opens correctly in Preview/Photos
- [ ] Export an image as JPEG
- [ ] Verify JPEG file opens correctly
- [ ] JPEG file size is smaller than PNG (compression works)

### Format Conversion Tests
- [x] Import a JPEG image via drag & drop
- [x] Cumberland stores it correctly
- [x] Import a PNG image
- [x] Cumberland stores it correctly
- [x] Import a HEIC image (iOS/macOS)
- [x] Cumberland converts and stores it

**Code Validation:**
- [x] Open `BatchGenerationQueue.swift:516-550` → thumbnail code should be REMOVED or call ImageProcessingService
- [x] Open `ImageVersionManager.swift:196+` → thumbnail code should call ImageProcessingService.shared

**Expected:** All thumbnail generation flows through `ImageProcessingService.shared.generateThumbnail()`.

**Issues Found:** _____________________________________________

1. No export UI found.  Unable to complete image export tests.  

---

## Section 3: CardOperationManager (Phase 1)

**Goal:** Verify card CRUD operations are centralized and work correctly

### Card Creation Tests
- [x] Create character card → appears in sidebar
- [x] Create location card → appears in sidebar
- [x] Create artifact card → appears in sidebar
- [x] Card names are correct
- [x] Card kinds are correct
- [x] All cards persist after app restart

### Card Deletion Tests
- [x] Select a single card → delete → card removed
- [x] Verify card gone from sidebar
- [x] Verify card gone from database (restart app, check it's not there)
- [ ] Select multiple cards (3-4) → delete all → all removed
- [ ] Verify mass deletion works correctly

### Card Duplication Tests
- [ ] Create a card with image, detailed text, timeline data
- [ ] Duplicate the card
- [ ] Verify duplicate has "(Copy)" suffix
- [ ] Verify duplicate copies all properties (text, image, etc.)
- [ ] Verify duplicate is a separate entity (edit duplicate doesn't affect original)

### Card Type Change Tests
- [x] Create a character card
- [x] Change its type to location (if UI supports this)
- [x] Verify type change persists

**Code Validation:**
- [x] Open `MainAppView.swift:943` (deleteCard) → should call `CardOperationManager.deleteCard()`
- [x] Open `MainAppView.swift:925` (deleteCards) → should call `CardOperationManager.deleteCards()`
- [x] Card creation in views should use `CardOperationManager.createCard()`

**Expected:** All card operations flow through `CardOperationManager`.

**Issues Found:** _____________________________________________

1. Unable to select multiple Cards from Card List.  Select button allows selection but only performs bacth image generation.  
2. Unable to delete multiple Cards (no UI exposed).  
3. Unable to duplicate cards (no UI exposed)

---

## Section 4: RelationshipManager (Phase 1)

**Goal:** Verify relationship operations are centralized and work correctly

### Relationship Creation (CardRelationshipView)
- [x] Open CardRelationshipView for a character
- [x] Create relationship to another character ("knows" or "friend-of")
- [x] Relationship appears in graph view
- [x] Both forward and reverse edges created
- [x] Relationship persists after closing and reopening view

### Relationship Creation (MurderBoardView)
- [x] Open MurderBoardView
- [ ] Drag edge between two nodes
- [ ] Select relationship type
- [ ] Verify edge appears on board
- [ ] Open CardRelationshipView for one of the cards
- [ ] Verify relationship appears there too (data sync works)

### Relationship Deletion
- [x] In CardRelationshipView, delete a relationship
- [x] Relationship removed from graph
- [x] Open MurderBoardView → relationship not shown there either
- [x] Relationship deletion persists after app restart

### Duplicate Prevention
- [x] Create relationship A → B ("owns")
- [x] Try to create same relationship again A → B ("owns")
- [x] Should be prevented or show warning
- [x] Only one edge A → B of type "owns" exists

### AI Relationship Extraction
- [x] Create a card with detailed text mentioning another card
  - Example: "Aragorn wields the sword Andúril"
- [x] Run AI content analysis
- [x] Accept suggested relationships
- [x] Verify relationships created correctly through RelationshipManager
- [x] Relationships appear in CardRelationshipView

**Code Validation:**
- [x] Open `CardRelationshipView.swift:1057` → removeRelationship should use RelationshipManager
- [x] Open `MurderBoardView.swift` → edge creation should use RelationshipManager
- [x] Open `SuggestionEngine.swift` → AI relationship creation should use RelationshipManager

**Expected:** All relationship operations flow through `RelationshipManager`.

**Issues Found:** _____________________________________________

1. Scrolling Murder board Backlog list also scrolls the Murderboard
2. Unable to drag to create edges in Murderboard View. UI superseded by dragging of nodes.  No other UI exposed to create edges in Murderboard View.
   
---

## Section 5: CardRepository (Phase 2)

**Goal:** Verify data access layer abstracts SwiftData queries correctly

### Fetch All Cards
- [x] Open MainAppView with several cards
- [x] Sidebar shows all cards
- [x] Cards are sorted alphabetically

### Fetch by Kind
- [ ] Filter by "Characters" → only characters shown
- [ ] Filter by "Locations" → only locations shown
- [ ] Filter by "Artifacts" → only artifacts shown
- [ ] Switch between filters → correct cards shown each time

### Search
- [ ] Enter search query in sidebar search box
- [ ] Results update as you type
- [ ] Search finds cards by name
- [ ] Search finds cards by subtitle
- [ ] Search finds cards by detailed text content
- [ ] Clear search → all cards shown again

### Fetch by UUID
- [ ] Copy a card's UUID from detail view (if shown)
- [ ] Test that card can be fetched by UUID programmatically
  - (This is internal, may need code inspection)

**Code Validation:**
- [x] Open `MainAppView.swift:43-44` → should use `@Environment(\.services)` instead of `@Query`
- [x] Card filtering should call `services.cardRepository.fetch(byKind:)`
- [x] Search should call `services.cardRepository.search(query:)`

**Expected:** Views access cards through `CardRepository`, not direct `@Query`.

**Issues Found:** _____________________________________________

1. No search or filter UI controls in All Cards list.  Cannot filter.  
2. No UUID's exposed in App.  No way to test UUID fetch internally.  

---

## Section 6: EdgeRepository (Phase 2)

**Goal:** Verify edge queries are abstracted correctly

### Fetch Edges for Card
- [x] Open CardRelationshipView for card with 3+ relationships
- [x] All relationships load correctly
- [ ] No duplicate edges shown
- [ ] Both incoming and outgoing edges shown

### Fetch Edges by Type
- [ ] Filter relationships by type ("owns", "knows", etc.)
- [ ] Only edges of that type shown
- [ ] Filter updates graph display correctly

**Code Validation:**
- [x] Open `CardRelationshipView.swift` → edge queries should use `EdgeRepository`
- [x] MurderBoardView edge loading should use `EdgeRepository`

**Expected:** Edge queries flow through `EdgeRepository`, not direct `@Query`.

**Issues Found:** _____________________________________________

1. Edges are bi-directional.  They are only shown on the MurderboardView.  These tests are inappropriate.    

---

## Section 7: Full Feature Regression Testing

**Goal:** Ensure ER-0022 changes haven't broken existing features

### Map Wizard (Not touched by ER-0022, should work identically)
- [x] Open Map Wizard
- [x] Import image → works
- [x] Draw on canvas → works
- [x] Capture from Maps → works
- [x] Save map to card → works

### AI Image Generation (Uses ImageProcessingService now)
- [x] Generate image for character
- [x] Image generates successfully
- [x] Thumbnail created automatically
- [x] Image appears in card detail view
- [x] Image history tracks all versions

### Structure Board (Not touched, should work)
- [x] Open Structure Board
- [x] Drag scenes between lanes
- [x] Scenes move correctly
- [x] Board state persists

### Timeline System (Not touched, should work)
- [x] Open Timeline view
- [x] Create chronicle card with temporal position
- [x] Timeline displays correctly
- [ ] Multi-timeline view shows multiple calendars

### Citation System (Not touched, should work)
- [x] Create source
- [ ] Add citation to card
- [ ] Citation displays in Citations tab
- [ ] Attribution generation works

### visionOS (If testing on visionOS)
- [x] App launches on visionOS
- [x] Card creation works
- [x] Ornament controls work
- [x] No visionOS-specific regressions

**Issues Found:** _____________________________________________

1. No UI exists to add citation to card (citation UI only exists for Images currently).
2. When creating Sources there is no place to put the publication details.  Also the source detail text should contain the quote pulled from the source.

---

## Section 8: Performance Testing

**Goal:** Verify ER-0022 hasn't degraded performance

### Card Operations Performance
- [x] Create 10 cards rapidly
- [x] All cards appear immediately in sidebar
- [x] No lag or stuttering
- [ ] Delete 10 cards at once
- [ ] Deletion completes in <2 seconds

### Relationship Performance
- [ ] Create 20 relationships on MurderBoard
- [ ] Board remains responsive
- [ ] Edge rendering smooth
- [ ] No frame drops when panning/zooming

### Image Processing Performance
- [ ] Generate 5 AI images for one card
- [ ] Each thumbnail generates in <1 second
- [x] Image History view loads quickly
- [x] No memory warnings

### Search Performance
- [ ] Database with 100+ cards
- [ ] Search query returns results in <500ms
- [ ] Search is responsive as you type
- [ ] No stuttering or lag

**Baseline Expectations:**
- Card creation: <100ms
- Card deletion: <50ms per card
- Relationship creation: <50ms
- Thumbnail generation: <500ms for 200x200
- Search: <500ms for database with 100 cards

**Issues Found:** _____________________________________________

1. No UI exists that allows the deletion of 10 edges at once.  
2. Image thumbnails take longer than 1 second to generate.  This peformance metric is ivalid.  
3. Other performance tests deferred until Database is of sufficient size (i.e. mor than 20 relationships to one card and more than 100 cards).  

---

## Section 9: Cross-Platform Testing

**Goal:** Verify services work correctly on all platforms

### macOS Testing
- [x] All Section 1-8 tests pass on macOS
- [x] Window management works
- [x] Keyboard shortcuts work
- [x] NSImage-based code paths work (ImageProcessingService)

### iOS Testing
- [x] All Section 1-8 tests pass on iPhone
- [x] Touch gestures work
- [x] Sheet presentations work
- [x] UIImage-based code paths work (ImageProcessingService)

### iPadOS Testing
- [x] All Section 1-8 tests pass on iPad
- [x] Split view works (if applicable)
- [x] Apple Pencil works (drawing canvas)
- [x] Multitasking works

### visionOS Testing (Optional)
- [x] App launches and initializes ServiceContainer
- [x] Basic features work (card creation, relationships)
- [x] No visionOS-specific crashes

**Issues Found:** _____________________________________________

---

## Section 10: Error Handling and Edge Cases

**Goal:** Verify robust error handling

### Invalid Data Handling
- [x] Try to create card with empty name → handled gracefully
- [ ] Try to create relationship to deleted card → handled gracefully
- [x] Try to create duplicate relationship → prevented or warned

### Memory Pressure
- [X] Generate 10+ large AI images
- [x] App handles memory pressure
- [x] Thumbnails still generate correctly
- [x] No crashes under memory pressure

### Data Corruption Prevention
- [ ] Delete card with 10+ relationships
- [ ] All associated edges deleted (no orphaned edges)
- [ ] No database corruption errors
- [ ] App remains stable

**Issues Found:** _____________________________________________

1. No UI exists that allows the creation of relationship to non existant card.  Invalid test criteria.  

---

## Issues Found Summary

**Critical Issues (App crashes, data loss):**
```
```

**Major Issues (Features broken, significant regressions):**
```
1. Unable to drag to create edges in Murderboard View. UI superseded by dragging of nodes.  No other UI exposed to create edges in Murderboard View.   
2. No search or filter UI controls in All Cards list.  Cannot filter.  
3. No export UI found.  Unable to complete image export tests.  
4. Unable to select multiple Cards from Card List.  Select button allows selection but only performs bacth image generation.  
5. Unable to delete multiple Cards (no UI exposed).  
6. Unable to duplicate cards (no UI exposed)
7. No UI exists to add citation to card (citation UI only exists for Images currently).
```

**Minor Issues (UI glitches, performance degradation):**
```
1. No UUID's exposed in App.  No way to test UUID fetch internally.  
2. Edges are bi-directional.  They are only shown on the MurderboardView.  These tests are inappropriate.    
3. When creating Sources there is no place to put the publication details.  Also the source detail text should contain the quote pulled from the source.
```

**Nice-to-Fix (Cosmetic, low priority):**
```
1. Scrolling Murder board Backlog list also scrolls the Murderboard
```

**Do not Fix (App is operating proeprly, Feature should not exist or invalid test criteria)**
```
1. No UI exists that allows the deletion of 10 edges at once.  
2. Image thumbnails take longer than 1 second to generate.  This peformance metric is ivalid.  
3. Other performance tests deferred until Database is of sufficient size (i.e. mor than 20 relationships to one card and more than 100 cards).  
4. No UI exists that allows the creation of relationship to non existant card.  Invalid test criteria.  
```

---

## Test Completion Summary

**Date Tested:** _______________
**Tester:** _______________
**Platform(s):** _______________
**Build/Version:** _______________

**Test Results:**
- [ ] ✅ All tests passed - No issues found
- [ ] ⚠️ Minor issues found - Document above
- [x] 🔴 Major issues found - Requires fixes before Phase 5 completion

**Overall Assessment:**
```
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
```

**Recommendation:**
- [ ] ✅ Mark ER-0022 Phase 5 as COMPLETE
- [ ] ⚠️ Fix minor issues then mark complete
- [x] 🔴 Fix critical/major issues before marking complete

---

## Next Steps

### If Tests Pass
1. ✅ Mark all checklist items as complete
2. ✅ Update `ER-unverified.md` → mark Phase 5 as "Implemented - Not Verified"
3. ✅ Request user verification
4. ✅ Once user verifies, move ER-0022 to verified archive

### If Issues Found
1. 🔴 Document all issues in "Issues Found Summary" above
2. 🔴 Create new DRs for critical/major issues
3. 🔴 Fix issues
4. 🔴 Re-run affected test sections
5. ✅ Proceed to "If Tests Pass" once resolved

### Optional: Fix Test Configuration
1. 💭 If user wants automated tests to run
2. 💭 Fix Xcode test target configuration (requires manual GUI work)
3. 💭 Run automated tests in `ImageProcessingServiceTests.swift` and `ServiceIntegrationTests.swift`
4. 💭 Verify all 34 automated tests pass
5. ✅ Add test execution to regular development workflow

---

*Manual Testing Checklist created: 2026-02-07*
*Ready for User Execution*
*Estimated time: 2-3 hours for comprehensive testing*
