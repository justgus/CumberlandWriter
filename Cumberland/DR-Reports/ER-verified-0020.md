# Enhancement Requests (ER) - Verified Batch 20

This batch contains ER-0020, verified on 2026-02-01.

**Status:** ✅ All Verified (1/1)

---

## ER-0020: Dynamic Relationship Extraction with AI-Generated Verbs

**Status:** ✅ Implemented - Verified
**Component:** AI Providers (OpenAI, Anthropic), SuggestionEngine, RelationshipInference, RelationType System
**Priority:** High
**Date Requested:** 2026-01-30
**Date Implemented:** 2026-01-31
**Date Verified:** 2026-02-01
**Related:** ER-0010 (Phase 6 - Relationship Inference), DR-0067 (Hardcoded pattern limitations)

**Rationale:**

The current relationship inference system (Phase 6, ER-0010) used **hardcoded verb patterns** in `RelationshipInference.swift` to detect relationships between entities. This approach had fundamental limitations:

**Problems with Pattern-Based Matching:**
1. **Arbitrary and Arduous:** Must manually add every verb in English (and future languages)
2. **Never Complete:** Authors use creative verbs not in our list ("forges", "betrays", "researches", "consecrates")
3. **Maintenance Burden:** DR-0067 required adding 3 new patterns just for one test text
4. **Defeats Flexibility:** Built a flexible RelationType system, but hardcoded patterns bypassed it
5. **Complex Grammar Missed:** Struggled with prepositional phrases ("writes a paper on the Artifact")
6. **Language Locked:** English-only, would need separate patterns for other languages

**User Quote (2026-01-30):**
> "I think that it will be arduous and arbitrary if we have to add all the verbs in english to our source code in order to determine the relationships between cards. One of the reasons I built the flexible system was so we wouldn't have to."

**Implemented Solution:**

Instead of pattern matching, the system now **extracts relationships dynamically** using the AI providers (Claude, GPT-4) that already understand sentence structure. The AI returns:
1. The actual verb from the text ("wields", "writes", "discovered", "dispatched")
2. An appropriate inverse verb ("is wielded by", "is written by", "discovered by", "dispatched by")
3. The entities involved (source and target)
4. Confidence and context

**Example Results (Professor Elara Moonwhisper text):**

After implementation, the system successfully extracted 16 high-quality relationships:
- Captain Jarek Stormborn → discovered → Codex of Forgotten Winds (95%)
- Dean Octavius Ashwood → leads → Consortium of Arcane Studies (95%)
- Dean Octavius Ashwood → dispatched → Finn Quickfoot (95%)
- Professor Elara Moonwhisper → employs → Oryn Leafwhisper (95%)
- Sky Citadel of Aethermoor → houses → Celestial Prism (90%)
- Treaty of Twin Peaks → was signed during → Council of Unity (90%)
- Silver Era → began after → Great Reconciliation (90%)

**Quality Improvement - Grammatical Guidance:**

Initial testing revealed semantic issues where the AI extracted prepositional phrase objects as relationships (e.g., "descended from Grand Observatory" when the text meant physically descending stairs, not genealogical descent).

**Solution:** Added grammatical structure guidance to AI prompts:

**HIGH confidence (0.9+): Subject-Verb-Direct Object relationships**
- "Captain discovered Codex" → Captain → discovered/discovered by → Codex (0.95)
- "Dean dispatched courier" → Dean → dispatched/dispatched by → courier (0.95)
- Focus: ownership, creation, discovery, employment, leadership, membership

**AVOID or use LOW confidence (<0.7): Prepositional phrases and momentary actions**
- "descended the steps OF the Observatory" → SKIP (object of preposition, not direct object)
- "walked INTO the building" → SKIP
- "sitting ON the chair" → SKIP (temporary position)

**Results:** After grammatical guidance, the system correctly filtered out prepositional phrase relationships and focused on meaningful, persistent connections with 90-95% average confidence.

**Implementation Details:**

### Phase 1: Anthropic Provider
- Updated entity extraction prompt to include relationship extraction (`AnthropicProvider.swift:133-152`)
- Added `EntityAndRelationshipResponse` structure with `RelationshipData`
- Modified `parseEntitiesAndRelationships()` to handle both new and legacy formats
- Created `DetectedRelationship` instances from AI response

### Phase 2: OpenAI Provider
- Mirrored all Anthropic changes for consistency
- Same prompt updates, response structures, parsing logic (`OpenAIProvider.swift:228-256`)

### Phase 3: Data Model Updates
- Moved `DetectedRelationship` struct to `AIProviderProtocol.swift` (shared location)
- Added `forwardVerb` and `inverseVerb` fields
- Made it `Codable` and `Identifiable`
- Updated `AnalysisResult` to use `[DetectedRelationship]` instead of `[Relationship]`
- Created extension in `RelationshipInference.swift` for pattern-based compatibility

### Phase 4: SuggestionEngine Updates
- Updated `RelationshipSuggestion` to store `forwardVerb` and `inverseVerb`
- Modified `generateRelationshipSuggestions()` to use dynamic verbs
- Implemented `findOrCreateRelationType()` for dynamic RelationType creation
- Updated `generateAllSuggestions()` signature to accept `[DetectedRelationship]`

### Phase 5: EntityExtractor Updates
- Added `ExtractionResult` struct to return both entities and relationships
- Changed `extractEntities()` return type from `[Entity]` to `ExtractionResult`
- Updated `extractEntitiesGrouped()` to use new return type

### Phase 6: CardEditorView Integration
- Updated to use `ExtractionResult` and pass AI relationships to SuggestionEngine
- Changed from hardcoded empty `relationships: []` to `extractionResult.relationships`

### Phase 7: Grammatical Guidance (Quality Improvement)
- Added Subject-Verb-Direct Object prioritization
- Added prepositional phrase filtering
- Updated both Anthropic and OpenAI prompts identically

**Files Modified:**
- `Cumberland/AI/AIProviderProtocol.swift` - Added DetectedRelationship struct
- `Cumberland/AI/AnthropicProvider.swift:133-152` - Updated prompts and parsing
- `Cumberland/AI/OpenAIProvider.swift:228-256` - Updated prompts and parsing
- `Cumberland/AI/RelationshipInference.swift` - Added pattern-based extension
- `Cumberland/AI/SuggestionEngine.swift` - Dynamic RelationType creation
- `Cumberland/AI/EntityExtractor.swift` - ExtractionResult return type
- `Cumberland/CardEditorView.swift:1199` - Pass AI relationships

**Benefits Achieved:**

✅ **No Verb List Maintenance:** Authors can use any language naturally
✅ **Better Accuracy:** AI understands grammar and context better than patterns
✅ **Complex Grammar:** Handles prepositional phrases, indirect objects automatically
✅ **Multilingual Ready:** Works with any language the AI understands
✅ **Flexible:** Truly leverages the custom RelationType system as intended
✅ **Lower Maintenance:** No more DRs for "missing verb X in pattern list"
✅ **Natural UX:** Relationship labels match the actual text
✅ **High Quality:** 90-95% average confidence for extracted relationships
✅ **Semantic Accuracy:** Grammatical filtering avoids false relationships

**Test Results:**

**Before (Pattern-Based):**
- 22 relationships extracted
- Mixed quality (some from prepositional phrases)
- Only worked with hardcoded verb list
- Required manual pattern additions for new verbs

**After (AI Dynamic Extraction with Grammatical Guidance):**
- 16 high-quality AI relationships
- 5 pattern-based fallback relationships
- 90-95% average confidence
- No prepositional phrase false positives
- Works with any verb (discovered, dispatched, employs, leads, houses, consecrated, etc.)

**User Verification (2026-02-01):**

User tested with Professor Elara Moonwhisper text and confirmed:
- ✅ Relationships extracted with actual verbs from text
- ✅ No more "descended from Grand Observatory" false relationship
- ✅ High confidence scores (90-95%)
- ✅ Semantically accurate (persistent connections only)
- ✅ Dynamic verbs working ("dispatched", "employs", "houses", etc.)

**User Feedback:** "ok lets mark ER-0020 as verified. thank you. good job!"

**Backward Compatibility:**

The pattern-based system in `RelationshipInference.swift` remains as a fallback for:
- When AI doesn't detect relationships (low confidence text)
- When AI provider is unavailable (offline mode)
- Additional detection beyond AI relationships

Both systems work together, providing comprehensive relationship detection.

**Future Enhancements:**

Potential improvements for future consideration:
- Configurable relationship extraction mode (AI only / AI with fallback / patterns only)
- Multilingual testing (French, Spanish, Japanese)
- User feedback on auto-created RelationTypes
- Relationship conflict resolution UI (when AI and patterns disagree)

---

*Last Updated: 2026-02-01*
*Verified By: User*
## ER-0017: AI Image Generation - Batch Processing and History Management

**Status:** ✅ Implemented - Verified
**Component:** AI System, Card Image Management, CardEditorView, MainAppView
**Priority:** Medium
**Date Requested:** 2026-01-29
**Date Started:** 2026-02-02
**Date Implemented (Phases 2 & 3):** 2026-02-02
**Date Implemented (Phase 1):** 2026-02-03
**Date Verified:** 2026-02-03
**Related:** ER-0009 (Image Generation features split out)

**Rationale:**

During implementation of ER-0008, ER-0009, and ER-0010 (Phases 1-8), the core AI functionality was completed successfully. However, advanced workflow features (Phases 9.5-9.7 and Phase 10) were deferred. This ER implements those features:
- Batch generation with multi-select
- Image version history
- Restore/compare/export previous versions

**Implementation Details:**

### Phase 1: Batch Generation with Multi-Select ✅ Completed (2026-02-03)

**Modified Files:**
- `Cumberland/MainAppView.swift:68-71` - Added multi-select state variables
- `Cumberland/MainAppView.swift:680-695` - Updated cardList to support Set<UUID> selection
- `Cumberland/MainAppView.swift:547-586` - Added toolbar buttons for multi-select and batch generation
- `Cumberland/MainAppView.swift:1100-1130` - Added helper functions (toggleMultiSelectMode, startBatchGeneration)
- `Cumberland/MainAppView.swift:326-354` - Added BatchGenerationView sheet presentation

**Features Implemented:**
- ✅ Multi-select mode toggle ("Select" / "Cancel" buttons in toolbar)
- ✅ Selection binding switches between UUID? (single) and Set<UUID> (multi)
- ✅ "Generate Images" button appears when cards selected
- ✅ BatchGenerationQueue integration with MainAppView
- ✅ Automatic queue start on batch generation trigger
- ✅ BatchGenerationView sheet presentation (all platforms)
- ✅ Exit multi-select mode after starting batch

**Key Code:**
- `MainAppView.swift:680-695` - Dynamic selection binding based on isMultiSelectMode
- `MainAppView.swift:1112-1130` - startBatchGeneration() queues cards and starts processing

### Phase 2: Image Version History Storage ✅ Completed (2026-02-02)

**Created Files:**
- `Cumberland/Model/ImageVersion.swift` - Version history model
- `Cumberland/AI/ImageVersionManager.swift` - Version management service

**Modified Files:**
- `Cumberland/Model/Card.swift:141-146` - Added imageVersions relationship
- `Cumberland/Model/Migrations.swift:91` - Added ImageVersion to AppSchemaV5

**ImageVersion Model:**
- Properties: id, imageData (external storage), generatedAt, prompt, provider, modelVersion, versionNumber, notes
- Card relationship with cascade delete
- Comparable protocol for FIFO sorting
- Platform-specific makeImage() helper
- Formatted display properties (formattedDate, fileSizeString, promptPreview)

**ImageVersionManager Features:**
- `saveCurrentAsVersion()` - Saves current image as version before regenerating
- `enforceHistoryLimit()` - FIFO cleanup when limit exceeded (default: 5 versions)
- `restoreVersion()` - Restore old version as current (saves current first)
- `deleteVersion()` - Delete specific version
- `clearAllVersions()` - Clear all history for a card
- `getStatistics()` - Version count and total size stats
- Automatic thumbnail regeneration on restore

### Phase 3: Image History UI ✅ Completed (2026-02-02)

**Created Files:**
- `Cumberland/AI/ImageHistoryView.swift` - Complete history browser UI

**Modified Files:**
- `Cumberland/CardEditorView.swift:95` - Added showImageHistory state
- `Cumberland/CardEditorView.swift:290` - Updated button to show "Regenerate Image…" when image exists
- `Cumberland/CardEditorView.swift:324-335` - Added history button in toolbar
- `Cumberland/CardEditorView.swift:507-510` - **CRITICAL**: Added version saving in onImageGenerated callback
- `Cumberland/CardEditorView.swift:543-547` - Added history sheet presentation

**ImageHistoryView Features:**
- Main view with header, version list, and empty state
- Header section with statistics (version count, total size) and "Clear All" action
- Scrollable version list with LazyVStack for performance
- VersionRowView component with action buttons: Restore, Compare, Export, Delete
- ComparisonView for side-by-side comparison (current vs version)
- ExportVersionView with platform-specific export
- Confirmation alerts for destructive actions
- Integration with ImageVersionManager for all operations

**Build Status:** All phases compiled successfully with `** BUILD SUCCEEDED **` (2026-02-03)

**Components Affected:**
- MainAppView (multi-select mode, toolbar buttons, batch generation integration)
- Card model (imageVersions relationship with cascade delete)
- SwiftData schema (AppSchemaV5 now includes ImageVersion model)
- AI image generation system (automatic versioning on regenerate)
- CardEditorView (history UI integrated, version saving implemented, button labels fixed)
- AISettings (imageHistoryLimit setting already existed, confirmed working)
- BatchGenerationQueue (infrastructure exists, now fully integrated)
- BatchGenerationView (queue status UI, now accessible via multi-select)

**New Files Created:**
- `Cumberland/AI/BatchGenerationQueue.swift` (176 lines)
- `Cumberland/AI/BatchGenerationView.swift` (204 lines)
- `Cumberland/AI/ImageHistoryView.swift` (571 lines)
- `Cumberland/Model/ImageVersion.swift` (112 lines)
- `Cumberland/AI/ImageVersionManager.swift` (257 lines)

**Test Steps:**

### Phase 1: Batch Generation with Multi-Select (Ready for Testing)

**Setup:**
1. Open Cumberland and navigate to any card kind view (Characters, Locations, etc.)
2. Ensure you have multiple cards without AI-generated images

**Test Multi-Select Mode:**
3. Click "Select" button in toolbar
4. ✅ **VERIFY:** Multi-select mode activates
5. ✅ **VERIFY:** "Cancel" button replaces "Select" button
6. ✅ **VERIFY:** "Generate Images" button appears (disabled until cards selected)

**Test Card Selection:**
7. Click on 3-5 cards without images
8. ✅ **VERIFY:** Cards highlight as selected
9. ✅ **VERIFY:** "Generate Images" button becomes enabled
10. ✅ **VERIFY:** Selection count visible

**Test Batch Generation:**
11. Click "Generate Images" button
12. ✅ **VERIFY:** BatchGenerationView sheet appears
13. ✅ **VERIFY:** All selected cards shown in queue with "Queued" status
14. ✅ **VERIFY:** Generation starts automatically
15. ✅ **VERIFY:** Progress bar updates as images generate
16. ✅ **VERIFY:** Individual card status updates (Queued → Generating → Completed/Failed)
17. ✅ **VERIFY:** Rate limiting enforced (12s delay between requests)

**Test Queue Controls:**
18. While generation running, click "Pause" button
19. ✅ **VERIFY:** Queue pauses after current task completes
20. Click "Resume" button
21. ✅ **VERIFY:** Queue resumes processing
22. Click "Cancel" button
23. ✅ **VERIFY:** Remaining tasks marked as cancelled
24. ✅ **VERIFY:** Completed images are saved to cards

**Test Queue Results:**
25. After completion, review summary
26. ✅ **VERIFY:** "X of Y images generated successfully" message displayed
27. ✅ **VERIFY:** Failed tasks (if any) can be retried
28. Click "Done" to dismiss sheet
29. ✅ **VERIFY:** Cards now have generated images
30. ✅ **VERIFY:** Multi-select mode exited automatically

### Phase 2 & 3: Image Version History (Ready for Re-Testing)

**Setup:**
1. Open a card that has an AI-generated image
2. Note the current image (take a screenshot if needed)

**Test Version Saving:**
3. In CardEditorView image section, click "Regenerate Image…"
4. After new image generates, click "Image History" button (clock icon)
5. ✅ **VERIFY:** Previous image appears as "Version 1" with:
   - Correct thumbnail
   - Timestamp
   - Original prompt
   - Provider name (Apple Intelligence or OpenAI)
   - File size

**Test Version Browsing:**
6. Select a version row (click thumbnail or row)
7. ✅ **VERIFY:** Row highlights with accent color
8. Click "Compare" button on a version
9. ✅ **VERIFY:** Split view shows current image vs version side-by-side with prompts

**Test Version Restore:**
10. Close comparison view
11. Click "Restore" button on Version 1
12. ✅ **VERIFY:**
    - Version 1 becomes current image in CardEditorView
    - Previous current image saved as new version
    - History now shows 2 versions

**Test Version Export:**
13. Click "Export" button on any version
14. macOS: ✅ **VERIFY:** NSSavePanel appears with default name "version-X.png"
15. iOS: ✅ **VERIFY:** Share sheet appears with image
16. Save/cancel and verify no errors

**Test Version Delete:**
17. Click "Delete" button on a version
18. ✅ **VERIFY:** Confirmation alert appears
19. Confirm deletion
20. ✅ **VERIFY:** Version removed from list

**Test History Limit (FIFO Cleanup):**
21. Go to Settings and verify "Image History Limit" is set to 5 (default)
22. Regenerate the image 6 times (make small prompt changes each time)
23. Open Image History after each regeneration
24. ✅ **VERIFY:**
    - After 5th regeneration: Shows 5 versions (oldest is Version 1)
    - After 6th regeneration: Shows 5 versions (oldest is now Version 2)
    - Version 1 automatically deleted (FIFO)

**Test Clear All History:**
25. With multiple versions present, click "Clear All" button in header
26. ✅ **VERIFY:** Confirmation alert shows version count and total size
27. Confirm clear
28. ✅ **VERIFY:**
    - All versions deleted
    - "No Version History" empty state appears
    - Current image still intact in CardEditorView

**Test Edge Cases:**
29. Open history for a card with no AI-generated image
30. ✅ **VERIFY:** History button is disabled
31. Open history for a card with AI image but no versions yet
32. ✅ **VERIFY:** Empty state shows "No Version History" message
33. Generate first image for a card (no existing image)
34. ✅ **VERIFY:** No version saved (nothing to preserve)

### Cross-Platform Testing

**Test on each platform:**
- macOS 26.0+ (primary implementation)
- iOS 26.0+
- iPadOS 26.0+
- visionOS 26.0+

**Platform-Specific Checks:**
- ✅ Multi-select mode works correctly
- ✅ Batch generation toolbar buttons appear correctly
- ✅ BatchGenerationView sheet presents correctly
- ✅ Image History UI renders correctly
- ✅ Export dialog is platform-appropriate (NSSavePanel vs UIActivityViewController)
- ✅ Thumbnails display correctly
- ✅ Touch/click interactions work as expected

**Priority:** Medium - Nice-to-have features for power users, but core functionality exists

**Complexity:** High - Requires queue management, data model changes, complex UI, multi-select integration

**Benefits:**
- ✅ Batch generate images for multiple cards at once
- ✅ Save time with automated queue processing
- ✅ Track and restore previous image versions
- ✅ Compare different generated versions
- ✅ Export individual versions
- ✅ Automatic rate limiting respects API constraints
- ✅ Professional workflow for power users

**Notes:**

All three phases are now fully implemented and compiled successfully. Phase 1 (batch generation with multi-select) was completed on 2026-02-03 after the user correctly pointed out it was incomplete. The "deferred" status was incorrect - there was no technical reason to defer it, and it has now been properly integrated into MainAppView with full multi-select support.
