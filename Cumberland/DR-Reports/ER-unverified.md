# Enhancement Requests (ER) - Unverified

This document tracks enhancement requests that are proposed, in progress, or implemented but awaiting user verification.

**Status:** Currently **3 active ERs** (3 Proposed, 0 In Progress, 0 Implemented - Not Verified)

**Note:** ER-0008, ER-0009, ER-0010 verified and moved to `ER-verified-0008.md`
**Note:** ER-0012, ER-0013, ER-0014, ER-0016 verified and moved to `ER-verified-0012.md`
**Note:** ER-0018 verified and moved to `ER-verified-0018.md`
**Note:** ER-0019 verified and moved to `ER-verified-0019.md` (2026-01-31)
**Note:** ER-0020 verified and moved to `ER-verified-0020.md` (2026-02-01)

---

## ER-0011: Image Sharing and Linking Between Cards

**Status:** 🔵 Proposed
**Component:** Card Model, CardEditorView, Image Management
**Priority:** Medium
**Date Requested:** 2026-01-22

**Rationale:**

Writers often need the same image to appear on multiple cards. For example:
- Multiple scenes taking place in the same location
- Character cards for the same person at different life stages
- Multiple cards referencing the same artifact or building
- Location cards showing the same map at different zoom levels

Currently, each card stores its own copy of image data. To use the same image on multiple cards, users must:
1. Export the image from the first card
2. Import it into each subsequent card

This is tedious and inefficient, resulting in:
- **Storage waste**: Same image data duplicated across multiple cards
- **Workflow friction**: Extra steps to share images between cards
- **Update difficulty**: To change the image, must update each card individually
- **Sync issues**: Easy to accidentally use different versions of "the same" image

**Current Behavior:**

- Each Card stores its own `originalImageData` and `thumbnailData`
- No mechanism to reference another card's image
- No "Copy Image" or "Paste Image" functionality
- Images must be manually re-imported for each card

**Requested Behavior:**

### Option 1: Copy/Paste Image (Simple)

Add clipboard-based image sharing:

**Copy Image:**
- Context menu or button on card images: "Copy Image"
- Copies image data to system clipboard
- Works across cards in the same session

**Paste Image:**
- "Paste Image" button/menu when editing a card
- Pastes image from clipboard
- Still creates independent copies (no linking)

**Benefits:**
- Simple to implement
- Familiar UX pattern
- Works within app session

**Limitations:**
- Still duplicates image data
- No cross-session persistence
- If source image changes, copies don't update

### Option 2: Image Linking (Advanced)

Multiple cards reference the same stored image:

**Shared Image Storage:**
- New `SharedImage` model with `id`, `originalImageData`, `thumbnailData`
- Card has optional `sharedImage: SharedImage?` relationship
- Falls back to local `originalImageData` if no shared image

**Use Cases:**
- "Use image from card..." picker shows all cards with images
- Selecting a card links to that card's image
- Or: "Share this image" makes it available to other cards
- Changing the shared image updates all linked cards

**Benefits:**
- Storage efficient (one copy of image data)
- Update once, changes everywhere
- Clear visual indication when images are linked

**Limitations:**
- More complex data model changes
- Schema migration required
- Need UI to show/manage links
- What happens if source card is deleted?

### Option 3: Hybrid Approach (Recommended)

Implement both features with progressive disclosure:

**Phase 1: Copy/Paste (Quick Win)**
- Add "Copy Image" and "Paste Image" functionality
- Immediate user value with minimal changes
- No data model changes required

**Phase 2: Image Linking (Future Enhancement)**
- Add `SharedImage` model and relationships
- Offer "Link to image from..." when pasting
- User chooses: Copy (independent) vs Link (shared)
- Provides efficiency benefits for power users

**Design Decisions:**

1. **Deletion Behavior (for linked images):**
   - **Option A**: Delete shared image when last card is deleted
   - **Option B**: Keep orphaned shared images (with cleanup tool)
   - **Option C**: Convert to local image on last card

2. **Attribution Tracking:**
   - For AI-generated images with citations, should copies/links preserve attribution?
   - Recommendation: Yes, preserve AI metadata and citations

3. **Edit Behavior:**
   - Should editing a linked image affect all cards? (probably no)
   - Provide "Make Unique" option to break the link

**Proposed Implementation:**

### Phase 1: Copy/Paste (ER-0011-A)

**Files to Modify:**
- `CardEditorView.swift` - Add copy/paste buttons
- `CardSheetView.swift` - Add copy/paste to image context menu
- New: `ImageClipboardManager.swift` - Handle clipboard operations

**UI Changes:**
- "Copy Image" button/menu item on card images
- "Paste Image" button appears when clipboard has image
- Visual feedback (toast/alert) confirming copy/paste

**Keyboard Shortcuts:**
- Cmd+C when image is focused: Copy image
- Cmd+V when editing card: Paste image

### Phase 2: Image Linking (ER-0011-B) - Future

**Files to Modify:**
- `Model/Card.swift` - Add optional `sharedImage` relationship
- New: `Model/SharedImage.swift` - Shared image model
- `Model/Migrations.swift` - Add AppSchemaV7 migration
- `CardEditorView.swift` - "Link to image from card..." picker
- Visual indicator showing when image is linked

**Migration Strategy:**
- All existing cards keep local `originalImageData`
- New `sharedImage?` relationship is optional
- Backward compatible with existing cards

**Expected Benefits:**

**User Experience:**
- **Faster workflow**: Copy/paste eliminates export/import steps
- **Consistency**: Same image guaranteed to be identical across cards
- **Flexibility**: Choose between independent copies or linked images

**Performance:**
- **Storage savings**: Linked images stored once (for Option 2)
- **Sync efficiency**: Less data to sync to CloudKit (for Option 2)
- **Memory efficiency**: Single image cache for linked images

**Use Cases:**

1. **Location Scenes**: Multiple scenes in "The Dragon's Lair" all show the same map
2. **Character Development**: Same character at different story points shares core appearance
3. **Reference Images**: Architectural details shared across multiple building cards
4. **Map Hierarchy**: Parent location and child locations share overview map

**Testing Scenarios:**

1. **Copy/Paste Within Session:**
   - Copy image from Card A
   - Paste into Card B
   - Verify image appears correctly
   - Verify AI metadata preserved (if applicable)

2. **Cross-Device (future):**
   - Copy image on Mac
   - Universal clipboard to iPad
   - Paste into card on iPad

3. **Large Images:**
   - Copy/paste high-resolution image
   - Verify performance acceptable
   - Verify thumbnail regeneration works

4. **Attribution Preservation:**
   - Copy AI-generated image with citation
   - Paste into new card
   - Verify citation/attribution appears in Image Attribution panel

**Related Issues:**

- ER-0009: AI Image Generation (attribution should be preserved)
- Image storage and caching system
- CloudKit sync considerations for large images

**Priority Justification:**

**Medium Priority** because:
- **Pain point identified**: User requested this specific feature
- **Common use case**: Location scenes especially benefit
- **Quick win**: Phase 1 (copy/paste) is relatively simple
- **Not blocking**: Workarounds exist (export/import)
- **Lower than ER-8/9/10**: Timeline and AI features higher priority

**Recommendation:**

Implement **Phase 1 (Copy/Paste)** first as part of ER-0009 completion or as standalone ER-0011. This provides immediate user value with minimal complexity. Consider Phase 2 (Image Linking) as a future enhancement if users request it after experiencing copy/paste.


## ER-0017: AI Image Generation - Batch Processing and History Management

**Status:** 🔵 Proposed
**Component:** AI System, Card Image Management, CardEditorView
**Priority:** Medium
**Date Requested:** 2026-01-29
**Related:** ER-0009 (Image Generation features split out)

**Rationale:**

During implementation of ER-0008, ER-0009, and ER-0010 (Phases 1-8), the core AI functionality was completed successfully:
- ✅ Apple Intelligence integration
- ✅ OpenAI/DALL-E 3 integration
- ✅ Multi-provider selection UI
- ✅ Auto-generation on card save
- ✅ Map Wizard AI generation

However, advanced workflow features (Phases 9.5-9.7 and Phase 10) were deferred to keep ER-0009 focused on core functionality. This ER captures those deferred features for future implementation.

**Current Behavior:**

Users can:
- Generate images one card at a time
- Auto-generate on save (if enabled)
- Regenerate by manually triggering generation again (overwrites existing)

Users cannot:
- Select multiple cards and generate images in batch
- Track generation history (previous versions)
- Revert to an earlier generated version
- Compare different generated versions side-by-side

**Desired Behavior:**

### Feature 9.5: Batch Generation

**Multi-Select and Queue:**
1. In card list/grid views, enable multi-selection mode
2. User selects multiple cards without images (or with images to regenerate)
3. Click "Generate Images for Selected" toolbar action
4. System queues generation requests with:
   - Progress tracking (5 of 20 complete)
   - Per-card status (queued/generating/complete/failed)
   - Cancellation support
   - Rate limit awareness (throttle requests if needed)

**Queue Management:**
- Show active generation queue in UI (sidebar or sheet)
- Display card name, generation status, elapsed time
- Allow removing items from queue before they start
- Handle failures gracefully (continue queue, report errors)
- Respect provider rate limits (e.g., 5 requests/minute for DALL-E)

**Batch Results Review:**
- After completion, show summary sheet:
  - "20 of 22 images generated successfully"
  - List of failures with reasons
  - Option to retry failed cards
  - Option to review generated images before saving

### Feature 9.6: Regeneration History

**Version Tracking:**
- When regenerating an image, save the previous version before replacing
- Store up to N previous versions (configurable, default: 5)
- Each version includes:
  - Image data
  - Generation timestamp
  - Prompt used
  - Provider used (Apple Intelligence, OpenAI, etc.)
  - Generation metadata (model version, settings)

**History UI:**
- In Card Editor, show "Image History" button/disclosure
- Display versions as thumbnail grid with timestamps
- Select any version to view full size
- Actions:
  - "Restore this version" (set as current image)
  - "Delete this version" (free up space)
  - "Compare" (side-by-side with current)
  - "Export" (save version to files)

**Storage Management:**
- Versions stored in `@Attribute(.externalStorage)` like main images
- Configurable history limit (1-10 versions)
- "Clear All History" option in settings (keep only current)
- Automatic cleanup when limit exceeded (FIFO)

**History Model:**
```swift
@Model
class ImageVersion {
    var card: Card?
    var imageData: Data?
    var generatedAt: Date
    var prompt: String
    var provider: String
    var modelVersion: String?
    var versionNumber: Int
}
```

### Feature 9.7 & Phase 10: Comprehensive Testing

**Testing Infrastructure:**
- Unit tests for batch queue management
- Unit tests for history storage/retrieval
- Integration tests for multi-provider workflows
- UI tests for batch generation flows
- Performance tests for large batches (100+ cards)

**Cross-Platform Testing:**
- macOS, iOS, iPadOS, visionOS testing
- CloudKit sync testing for history data
- Offline/online scenarios
- Error handling and recovery

**Documentation:**
- User guide for batch generation workflows
- API documentation for batch queue system
- Performance characteristics and limits
- Troubleshooting guide

**Requirements:**

### Batch Generation Requirements:
1. Support selecting 1-100 cards for batch generation
2. Queue system with pause/resume/cancel capabilities
3. Progress tracking with estimated time remaining
4. Handle provider rate limits gracefully
5. Show per-card generation status in real-time
6. Generate results summary after completion
7. Allow retry of failed generations

### History Management Requirements:
1. Store up to N previous versions per card (default: 5)
2. Each version includes prompt, provider, timestamp, metadata
3. UI to browse, compare, restore, and delete versions
4. Automatic cleanup when history limit exceeded
5. External storage for version data (same as main image)
6. Export individual versions to files
7. Settings to configure history limit and cleanup behavior

### Testing Requirements:
1. Unit test coverage for queue management
2. Unit test coverage for history storage
3. Integration tests for full workflows
4. Cross-platform testing (all 4 platforms)
5. CloudKit sync testing
6. Performance testing (batch of 100 cards)
7. Error handling and edge case tests

**Design Approach:**

### Batch Generation Architecture:
- `BatchGenerationQueue` class manages generation queue
- Each queue item: `BatchGenerationTask(card, prompt, provider, status)`
- Queue worker respects rate limits, processes sequentially
- UI observes queue state via `@Observable` or Combine
- Results collected in `BatchGenerationResult` structure

### History Storage:
- Add `imageVersions` relationship to Card model
- `ImageVersion` model with external storage for data
- Limit enforced on insert (delete oldest if > limit)
- UI layer reads versions on demand (not loaded by default)

### Settings:
- `imageHistoryLimit` (1-10, default: 5)
- `batchGenerationMaxConcurrent` (1-5, default: 1)
- `batchGenerationRespectRateLimits` (bool, default: true)

**Components Affected:**
- Card model (add `imageVersions` relationship)
- AI image generation system (add versioning on regenerate)
- Card list/grid views (add multi-select mode, batch action)
- CardEditorView (add history UI)
- AISettings (add batch and history settings)
- New: `BatchGenerationQueue.swift`
- New: `BatchGenerationView.swift` (queue status UI)
- New: `ImageHistoryView.swift` (version browser)
- New: `ImageVersion.swift` (model)

**Test Steps:**

### Batch Generation:
1. Select 10 cards without images
2. Click "Generate Images for Selected"
3. Observe queue progress (should complete all 10)
4. Verify all cards have images after completion
5. Test failure handling (disconnect network mid-batch)
6. Test cancellation (cancel batch mid-queue)
7. Test rate limiting (verify delays between requests)

### History Management:
1. Generate image for a card
2. Regenerate image (should save previous as version)
3. Open image history UI
4. Verify previous version is shown
5. Restore previous version (should become current)
6. Generate 5 more times (should have 5 versions)
7. Generate again (oldest should be deleted)
8. Test "Clear All History" (should keep only current)

**Implementation Phases:**

**Phase 1: Batch Generation Queue (1 week)**
- Implement `BatchGenerationQueue` class
- Add multi-select to card list views
- Create batch generation UI
- Implement queue worker with rate limiting
- Test with 10-20 cards

**Phase 2: History Storage (1 week)**
- Add `ImageVersion` model
- Add `imageVersions` relationship to Card
- Implement version saving on regenerate
- Implement automatic cleanup (FIFO when limit exceeded)
- Add history limit setting

**Phase 3: History UI (1 week)**
- Create `ImageHistoryView` for browsing versions
- Add restore, delete, compare, export actions
- Integrate into CardEditorView
- Test version management workflows

**Phase 4: Testing & Polish (1-2 weeks)**
- Write unit tests for queue and history
- Cross-platform testing
- Performance testing (large batches)
- Documentation updates
- Bug fixes

**Priority:** Medium - Nice-to-have features for power users, but core functionality exists

**Complexity:** High - Requires queue management, data model changes, complex UI

**Dependencies:**
- ER-0009 (builds on existing image generation system)
- Requires multi-select support in card list views

**Benefits:**
- ✅ More efficient workflow for generating many images
- ✅ Ability to experiment with different prompts without losing previous results
- ✅ Better quality control (compare versions before committing)
- ✅ Undo support for image generation
- ✅ Professional workflow for content creators

**Notes:**
- Split from ER-0009 Phases 9.5-9.7 and Phase 10 to keep ER-0009 focused
- ER-0009 Phases 1-8 are complete and ready for verification
- This ER can be implemented independently after ER-0009 is verified
- Consider user feedback on history limit and batch size before finalizing implementation

---

## ER-0015: Improve Empty Analysis Results Message

**Status:** 🔵 Proposed
**Component:** SuggestionReviewView, SuggestionEngine
**Priority:** Low
**Date Requested:** 2026-01-22
**Related:** ER-0010 (AI Content Analysis)

**Rationale:**

When AI content analysis finds no entities or relationships in the text, the empty state message could be more helpful. The current message is generic and doesn't guide users on how to improve their results.

**Current Behavior:**

```swift
Text("No Suggestions Found")
    .font(.title2)
Text("The AI couldn't find any entities or relationships in the text.\n\nTry adding more descriptive details to your card.")
```

**Requested Behavior:**

Provide more actionable guidance:
- Suggest including proper nouns (character names, location names)
- Mention specific relationship patterns the AI looks for
- Link to examples or help documentation
- Show minimum text length recommendations
- Offer to try a different AI provider (if multiple available)

**Priority:** Low - Nice-to-have UX improvement

---

## Status Indicators

Per ER-Guidelines.md:
- 🔵 **Proposed** - Enhancement identified and documented, awaiting implementation
- 🟡 **In Progress** - Claude is actively working on this enhancement
- 🟡 **Implemented - Not Verified** - Claude completed implementation, ready for user testing
- ✅ **Implemented - Verified** - Only USER can mark after testing (move to verified batch)

---

*When user verifies an ER, move it to the appropriate ER-verified-XXXX.md file*
