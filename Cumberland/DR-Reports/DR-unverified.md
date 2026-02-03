# Discrepancy Reports (DR) - Unverified Issues

This document tracks recent discrepancy reports that have been resolved but are awaiting user verification.

**Status:** Currently **2 active DRs** (2 Identified, 0 Resolved - Not Verified)

---



## DR-0071: Apple Image Playground Requires Person Selection, Unsuitable for Non-Portrait Generation

**Status:** 🔴 Identified - Not Resolved
**Platform:** All platforms (iOS 18.1+, macOS 15.1+, iPadOS 18.1+, visionOS 2.1+)
**Component:** AI Image Generation, AppleIntelligenceProvider, Image Playground Integration
**Severity:** High
**Date Identified:** 2026-02-03

**Description:**

When using "Apple Intelligence" as the image generation provider, the system launches Apple's Image Playground with the following limitations:

1. **Person selection required:** Image Playground requires selecting a person to guide the image appearance, even when generating non-portrait subjects (landscapes, artifacts, vehicles, buildings, etc.)

2. **Incomplete prompt transfer:** Only some elements of the user's prompt make it into the Image Playground bubble - not the full prompt

3. **Workflow mismatch:** Image Playground is designed for creating stylized images of people, but Cumberland users need to generate images of all entity types (characters, locations, artifacts, vehicles, buildings, organizations, etc.)

**User Impact:**

When user attempts to generate an image for:
- **Landscape:** "A vast desert with rolling sand dunes under twin moons"
  - Result: Image Playground asks "Choose a person to guide the appearance"
  - Problem: There IS no person in a landscape!

- **Artifact:** "A glowing sword with ancient runes etched into the blade"
  - Result: Image Playground asks for person selection
  - Problem: An artifact doesn't need a person

- **Vehicle:** "A steampunk airship with brass gears and canvas sails"
  - Result: Image Playground asks for person selection
  - Problem: Vehicle-focused images don't require person concepts

**Expected Behavior:**

When user selects "Apple Intelligence" provider and generates an image:
1. Full prompt should be passed to Image Playground
2. Image Playground should generate the requested subject without requiring person selection
3. Non-portrait subjects (landscapes, objects, scenes) should work seamlessly

**Actual Behavior:**

1. Cumberland passes prompt to Image Playground via `ImagePlaygroundConcept.text(prompt)`
2. Image Playground receives partial prompt
3. Image Playground requires selecting a person (even for non-person subjects)
4. User cannot proceed without selecting a person
5. Generated image may include unwanted person in landscape/artifact/vehicle scene

**Root Cause:**

**Apple's Design Choice:**

Apple's Image Playground framework is fundamentally designed for portrait-style image generation:
- Primary use case: Stylized images of people (cartoon avatars, fun portraits)
- Requires "person concept" as mandatory input
- Not designed for general-purpose image generation

From Apple's ImagePlayground documentation:
> "Image Playground creates fun, original images in moments based on descriptions, suggested concepts, and even people from your Photos library."

The emphasis is on "people from your Photos library" - person-centric workflow.

**Cumberland's Integration:**

```swift
// AIImageGenerationView.swift:313-320
.imagePlaygroundSheet(
    isPresented: $showImagePlaygroundSheet,
    concepts: [
        ImagePlaygroundConcept.text(prompt)  // Only text concept passed
    ]
) { url in
    handleImagePlaygroundResult(url)
}
```

The code correctly uses `ImagePlaygroundConcept.text()`, but Image Playground's UI layer still enforces person selection.

**Why This Matters:**

Cumberland is a worldbuilding tool for complex narratives:
- Only ~20-30% of cards are characters (need portraits)
- ~70-80% of cards are locations, artifacts, vehicles, buildings, organizations, events
- Apple Intelligence/Image Playground is unsuitable for the majority of use cases

**Proposed Solutions:**

### Solution 1: Disable Apple Intelligence for Non-Character Cards (Quick Fix)

Detect card type and prevent Apple Intelligence selection for non-character cards:

```swift
// In AIImageGenerationView or CardEditorView
var availableProviders: [AIProviderProtocol] {
    let all = AIProviderRegistry.shared.availableProviders()

    // Filter out Apple Intelligence for non-character cards
    if card.kind != .characters {
        return all.filter { $0.name != "Apple Intelligence" }
    }

    return all
}
```

**Pros:**
- Prevents user frustration
- Clear messaging about why Apple Intelligence is unavailable
- Simple to implement

**Cons:**
- Reduces provider options for most card types
- User loses ability to try Apple Intelligence even if they want to experiment

### Solution 2: Warn User Before Launching Image Playground (Medium Fix)

Show alert before launching Image Playground for non-character cards:

```swift
// Before setting showImagePlaygroundSheet = true
if card.kind != .characters {
    showAlert = true
    alertMessage = """
    Apple Image Playground is designed for creating images of people and may not work well for this card type (\(card.kind.displayName)).

    Recommendation: Use OpenAI (DALL-E 3) or Anthropic for better results with landscapes, artifacts, and other non-portrait subjects.

    Continue with Apple Intelligence anyway?
    """
}
```

**Pros:**
- User stays informed
- Still allows experimentation if desired
- Suggests better alternatives

**Cons:**
- Extra step in workflow
- Doesn't solve the underlying limitation

### Solution 3: Add Alternative Apple Provider (Long-term)

Wait for Apple to release general-purpose image generation API (not Image Playground):
- Monitor for WWDC announcements
- Check for new frameworks in future iOS/macOS releases
- Implement when available

**Pros:**
- Full functionality with Apple's ecosystem
- No API keys required
- On-device processing (privacy)

**Cons:**
- No timeline from Apple
- May never happen (Image Playground might be Apple's only offering)
- Users stuck with limited options until then

### Solution 4: Make OpenAI the Default (Immediate Workaround)

Change default provider from "Apple Intelligence" to "OpenAI":

```swift
// AISettings.swift:42
static let imageGenerationProvider = "OpenAI"  // Was: "Apple Intelligence"
```

**Pros:**
- DALL-E 3 works for all content types
- Better default user experience
- No workflow interruptions

**Cons:**
- Requires API key (friction for new users)
- Costs money (usage-based pricing)
- Not on-device (privacy consideration)

**Recommended Approach:**

**Phase 1 (Immediate):** Implement Solution 2 - Warning dialog
- Inform users about limitation
- Suggest OpenAI for non-portrait subjects
- Still allow usage if user insists

**Phase 2 (Short-term):** Implement Solution 4 - Change default to OpenAI
- Better out-of-box experience
- Provide clear setup instructions for API key

**Phase 3 (Long-term):** Monitor for Apple updates
- Watch for general-purpose image generation APIs
- Implement when available

**Files to Modify:**

**For Solution 2 (Warning Dialog):**
- `Cumberland/AI/AIImageGenerationView.swift:269-278` - Add warning before showImagePlaygroundSheet
- New: `Cumberland/AI/ImagePlaygroundWarningView.swift` - Alert/warning UI component

**For Solution 4 (Change Default):**
- `Cumberland/AI/AISettings.swift:42` - Change default provider
- `Cumberland/Documentation/` - Update setup instructions

**Test Steps:**

**Current Behavior (Reproduce Issue):**
1. Create a location card: "The Whispering Desert"
2. Add description: "A vast desert with rolling sand dunes and ancient ruins"
3. Set image provider to "Apple Intelligence"
4. Click "Generate Image"
5. **Observe:** Image Playground launches
6. **Observe:** Partial prompt appears in bubble
7. **Observe:** "Choose a person to guide the appearance" prompt appears
8. **Problem:** Cannot proceed without selecting a person for a landscape

**After Fix (Solution 2):**
5. **Observe:** Warning dialog appears:
   "Apple Image Playground is designed for creating images of people..."
6. User can:
   - **Option A:** "Use OpenAI Instead" (switches provider and generates)
   - **Option B:** "Continue with Apple Intelligence" (proceeds to Image Playground)
   - **Option C:** "Cancel" (returns to prompt editing)

**Related Issues:**
- ER-0009: AI Image Generation implementation
- DR-0069: AI safety filter false positives
- DR-0070: Provider picker doesn't show saved setting

**Notes:**
- This is NOT a Cumberland bug - it's a design limitation of Apple's Image Playground
- Image Playground works well for character portraits (its intended use case)
- Cumberland needs general-purpose image generation for all entity types
- User discovered this when attempting to generate image for "Captain Evilin Drake" (character) - even portraits trigger person selection
- Industry context: OpenAI's DALL-E 3, Anthropic's image generation (future), and other APIs support all subject types without person requirements

**Documentation Update Needed:**

Add to user documentation:
> **Provider Recommendations:**
> - **Characters/Portraits:** Apple Intelligence or OpenAI
> - **Locations/Landscapes:** OpenAI (Apple Intelligence requires person selection)
> - **Artifacts/Objects:** OpenAI (Apple Intelligence requires person selection)
> - **Vehicles:** OpenAI (Apple Intelligence requires person selection)
> - **Buildings:** OpenAI (Apple Intelligence requires person selection)

---

## DR-0069: AI Provider Safety Filter False Positives on Character Names

**Status:** 🔴 Identified - Not Resolved
**Platform:** All platforms
**Component:** AI Image Generation, ImageGenerator
**Severity:** High
**Date Identified:** 2026-02-03

**Description:**

When generating images for characters with certain names, the AI provider's safety filter rejects valid prompts with false positives. User attempted to generate an image for "Captain Evilin Drake" with a legitimate character description (orange astronaut jumpsuit, physical features), but received:

```
Image generation failed: Invalid response from AI provider: Your request was rejected as a result of our safety system. Your prompt may contain text that is not allowed by our safety system.
```

The prompt contained no inappropriate content - it was a standard character description for a science fiction story. The name "Evilin" likely triggered the filter (interpreted as "Evil in" or similar).

**Impact:**
- Users cannot generate images for characters with certain legitimate names
- Blocks creative storytelling (fantasy/sci-fi names often use unusual spellings)
- Poor user experience - no explanation of what triggered the filter
- No workaround suggested in error message
- Forces users to rename characters or manually edit images elsewhere

**Root Cause:**

**Provider Side (OpenAI/DALL-E 3):**
- Safety filters use pattern matching that can produce false positives
- Overly aggressive filtering of word combinations in names
- No context awareness (can't distinguish character name from content description)

**Cumberland Side:**
- Error handling doesn't provide helpful guidance for safety filter rejections
- No automatic retry with prompt variations
- No prompt preprocessing to catch potential issues before sending to provider
- No fallback to alternative providers when safety filters trigger
- No user education about safety filter limitations

**Expected Behavior:**

When a safety filter triggers on a legitimate prompt:
1. Show clear error message explaining it's a safety filter issue
2. Suggest specific remediation (e.g., "Try using a different character name or rephrasing")
3. Offer to retry with automatic prompt variations
4. Provide option to switch to alternative AI provider
5. Allow user to report false positive

**Actual Behavior:**

- Generic error message with no actionable guidance
- User stuck with no path forward
- Must manually guess what triggered the filter
- No alternatives offered

**Proposed Solutions:**

### Solution 1: Enhanced Error Handling (Quick Fix)
Detect safety filter rejections and provide better messaging:
```swift
// In ImageGenerator.swift error handling
if errorMessage.contains("safety system") {
    throw ImageGeneratorError.safetyFilterRejection(
        suggestion: "The AI safety filter rejected this prompt. Try:\n" +
                   "• Using a different character name\n" +
                   "• Rephrasing the description\n" +
                   "• Switching to Apple Intelligence provider\n" +
                   "• Simplifying the prompt"
    )
}
```

### Solution 2: Prompt Preprocessing (Medium Complexity)
Add preprocessing layer to detect potential issues:
- Check for name patterns that commonly trigger filters
- Warn user before sending to provider
- Suggest alternatives (e.g., "Evilin" → "Evalin" or use first/last name only)
- Optional "sanitize prompt" mode that auto-replaces problematic patterns

### Solution 3: Automatic Retry with Variations (Medium Complexity)
When safety filter triggers, automatically retry with variations:
1. Original prompt fails
2. Try with character's first name only
3. Try with character's last name only
4. Try with generic description (remove name entirely)
5. Report results to user with explanation

### Solution 4: Multi-Provider Fallback (Higher Complexity)
When one provider's safety filter triggers, automatically try others:
1. OpenAI fails → Try Apple Intelligence
2. Both fail → Try Anthropic (when added in future)
3. Show user which provider worked
4. Remember successful provider for this character type

### Solution 5: User Feedback System (Long-term)
- Add "Report False Positive" button in error dialog
- Collect prompt + error for analysis
- Build database of known false positives
- Use for preprocessing in Solution 2

**Recommended Approach:**

**Phase 1 (Immediate):** Implement Solution 1 - Enhanced error handling with actionable suggestions

**Phase 2 (Short-term):** Implement Solution 4 - Multi-provider fallback (infrastructure already exists)

**Phase 3 (Medium-term):** Implement Solution 2 - Prompt preprocessing with known patterns

**Phase 4 (Long-term):** Implement Solution 5 - User feedback system

**Workaround (For User Now):**

1. **Try Apple Intelligence provider instead:**
   - Go to Settings → AI Settings
   - Change "Image Generation Provider" from OpenAI to Apple Intelligence
   - Try generating again (Apple's filters may be less strict)

2. **Modify character name in prompt:**
   - Change "Captain Evilin Drake" to "Captain E. Drake" or "Captain Drake"
   - Or temporarily use a similar name like "Captain Evalin Drake"

3. **Generate without name:**
   - Remove character name from prompt entirely
   - Use generic description: "A tall woman with long straight dark hair in a ponytail..."
   - Add name to card manually after image is generated

4. **Use different provider for this character:**
   - Some characters may work better with certain providers
   - Try both OpenAI and Apple Intelligence to see which works

**Files to Modify:**

**For Solution 1 (Enhanced Error Handling):**
- `Cumberland/AI/ImageGenerator.swift` - Add better error detection and messaging

**For Solution 4 (Multi-Provider Fallback):**
- `Cumberland/AI/ImageGenerator.swift` - Add fallback logic
- `Cumberland/CardEditorView.swift` - UI to show which provider succeeded
- `Cumberland/AI/AISettings.swift` - Option to enable/disable auto-fallback

**Related Issues:**
- ER-0009: AI Image Generation implementation (where this was discovered)
- Future: Anthropic image generation provider (additional fallback option)

**Notes:**
- This is not a Cumberland bug - it's a limitation of AI provider safety filters
- However, Cumberland can handle it more gracefully
- Common issue in AI image generation - worth investing in good UX
- Other character names that might trigger: Lucifer, Demon, Evil, Satan, Kill, Murder, etc.
- Fantasy/sci-fi names are especially prone to false positives

---

## Template for Adding New DRs

```markdown
## DR-XXXX: [Brief Title]

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms
**Component:** CalendarSystem Model, SwiftData Relationships
**Severity:** Critical
**Date Identified:** 2026-01-30
**Date Resolved:** 2026-01-30

**Description:**

When deleting a Calendar card (kind=.calendars), the app crashes with:
```
Thread 1: Fatal error: Unexpected backing data for snapshot creation:
SwiftData._FullFutureBackingData<Cumberland.CalendarSystem>
```

This is a critical crash that prevents users from deleting calendar systems.

**Root Cause:**

The `CalendarSystem.calendarCard` property was declared as a plain property instead of being properly configured as the inverse side of a SwiftData relationship:

```swift
// INCORRECT (CalendarSystem.swift:49)
var calendarCard: Card?
```

However, on the Card side, this relationship was properly declared:

```swift
// Card.swift:113-114
@Relationship(deleteRule: .cascade, inverse: \CalendarSystem.calendarCard)
var calendarSystemRef: CalendarSystem?
```

This mismatch caused SwiftData to fail when trying to create a snapshot during the deletion operation. SwiftData expects bidirectional relationships to be properly declared on both sides, but the inverse side should NOT have the `@Relationship` decorator - it should be a plain property.

The problem was that initially, no relationship configuration existed for `calendarCard`. When the fix was attempted by adding `@Relationship(deleteRule: .nullify, inverse: \Card.calendarSystemRef)`, it created a circular reference error because both sides were declaring the inverse.

**SwiftData Relationship Pattern:**

In SwiftData, bidirectional relationships follow this pattern:
- **Primary side:** Has `@Relationship(deleteRule: .X, inverse: \OtherType.property)`
- **Inverse side:** Plain property with NO `@Relationship` decorator

Example from Board/BoardNode:
```swift
// Primary side (Board.swift)
@Relationship(deleteRule: .cascade, inverse: \BoardNode.board)
var nodes: [BoardNode]? = []

// Inverse side (BoardNode, same file)
var board: Board?  // NO @Relationship!
```

**Fix Applied:**

1. Added `@Relationship` decorator with delete rule to `CalendarSystem.timelines` (CalendarSystem.swift:44-46)
   - This ensures timelines that use this calendar get their reference nullified when calendar is deleted

2. Kept `CalendarSystem.calendarCard` as a plain property (CalendarSystem.swift:51)
   - This is the correct pattern for the inverse side of a relationship
   - The primary side (Card.calendarSystemRef) already has the full @Relationship declaration

**Files Modified:**
- `Cumberland/Model/CalendarSystem.swift:40-51` - Fixed relationship declarations
- `Cumberland/Model/CalendarSystemCleanup.swift` - NEW: Cleanup utility for existing data
- `Cumberland/CumberlandApp.swift:208-224` - Added automatic one-time cleanup on app launch

**Changes:**

**1. Fixed Model Relationships (CalendarSystem.swift:40-51)**

```swift
// BEFORE
@Relationship(inverse: \Card.calendarSystem)
var timelines: [Card]? = []

var calendarCard: Card?

// AFTER
@Relationship(deleteRule: .nullify, inverse: \Card.calendarSystem)
var timelines: [Card]? = []

/// Inverse of Card.calendarSystemRef (declared on Card side with cascade delete)
var calendarCard: Card?
```

**2. Created Cleanup Utility (CalendarSystemCleanup.swift)**

New utility with three functions:
- `fixExistingCalendarRelationships()` - **Recreates** CalendarSystems with proper relationship structure
  - Collects all data from existing calendars
  - Breaks relationships (sets to nil)
  - Deletes old CalendarSystem objects
  - Recreates new ones with same data
  - Restores relationships with proper structure
- `removeOrphanedCalendars()` - Deletes calendars with no owning card (optional cleanup)
- `diagnoseCalendarRelationships()` - Diagnostic tool for debugging

**3. Created Developer Tool (CalendarSystemCleanupView.swift + CumberlandApp.swift)**

Added to Developer menu (macOS DEBUG only):
- Window: "Fix CalendarSystem Relationships (DR-0065)"
- Menu: Developer > Fix CalendarSystem Relationships (DR-0065)… (Cmd+Shift+C)
- Features:
  - "Diagnose" button - Shows all calendars and their relationship status
  - "Fix Relationships" button - Runs the cleanup utility
  - Detailed report with step-by-step execution log
  - Copy report to clipboard
  - Statistics display (calendars found, recreated)

**Why Developer Tool Instead of Automatic:**
- Only affects existing databases with broken calendars (user's database)
- Future users won't have this problem (calendars created after fix)
- Allows user to diagnose first, then fix manually
- No automatic operations that could surprise users
- Follows pattern of other developer repair tools (Fix Incomplete Relationships)

**Why Recreate Instead of Refresh:**
- Initial approach tried to "refresh" relationships by accessing properties
- This doesn't fix the underlying SwiftData relationship metadata
- Once a relationship is created with wrong structure, it persists
- Solution: Delete and recreate with proper structure
- Safe approach: Break relationships → Delete → Recreate → Restore relationships

**Test Steps:**

**For Existing Broken Calendars (One-Time Fix):**
1. In DEBUG mode, open Developer > Fix CalendarSystem Relationships (DR-0065)… (Cmd+Shift+C)
2. Click "Diagnose" to see all existing calendars
3. Review the report - shows calendar names, owning cards, relationships
4. Click "Fix Relationships" to recreate calendars with proper structure
5. Watch report for: "✅ Successfully recreated X calendar system(s)"
6. Close the developer window
7. Try deleting any calendar card (e.g., "Lunara Calendar")
8. Verify: App does NOT crash
9. Verify: Calendar is removed cleanly

**For New Calendars (After Fix):**
1. Create a new Calendar card using AI content analysis
2. Verify calendar card appears in sidebar
3. Delete the calendar card (Cmd+Delete or Delete menu)
4. Verify: App does NOT crash (new calendars created with proper structure)
5. Verify: Calendar is removed from the list

**Manual Diagnostic:**
You can use the developer tool to:
- View all CalendarSystem objects and their relationships
- Check for orphaned calendars (no owning card)
- See which timelines use each calendar
- Copy diagnostic report for troubleshooting

**Related Issues:**

- ER-0008: Timeline System implementation (introduced CalendarSystem model)
- ER-0010: AI Content Analysis (creates calendar cards via suggestion system)
- ER-0018: TextPreprocessor fix (enabled successful calendar extraction)

**Implementation Notes:**

**First Attempt (Failed - Property Refresh):**
- Initial cleanup tried to "refresh" relationships by accessing properties
- Automatic execution on app launch with UserDefaults flag
- Result: Cleanup ran but app still crashed on deletion
- Root cause: SwiftData relationship metadata can't be fixed by property access alone

**Second Attempt (Failed - Automatic Recreation):**
- Changed approach to delete and recreate CalendarSystem objects
- Flag: `didFixCalendarSystemRelationships_DR0065_v2`
- Process: Collect data → Break relationships → Delete → Recreate → Restore relationships
- Result: Fix worked, but ran automatically for all users
- Problem: Only user's database has broken calendars; future users won't need this

**Final Solution (Manual Developer Tool - Current):**
- Moved cleanup to Developer menu (macOS DEBUG only)
- Removed automatic execution from app launch
- Created CalendarSystemCleanupView with GUI
- User can diagnose first, then manually trigger fix
- Appropriate for one-time repair of existing data
- Follows pattern of other developer repair tools

**Notes:**

- This issue was discovered immediately after implementing ER-0019 and testing with the Anthropic Claude Opus 4.5 provider
- The calendar was created via AI analysis of the "Professor Elara Moonwhisper" test text
- This is a critical bug that affects core functionality (deleting cards)
- The fix follows standard SwiftData relationship patterns used throughout the codebase
- User reported: "I deleted a calendar. It crashed!" - confirming the bug with existing data
- User correctly pointed out: "it should not run for everyone who uses the app. Only me."
- Final approach: Manual developer tool for one-time fixes

---

## DR-0067: Relationship Inference Not Detecting Patterns (Multiple Bugs)

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms
**Component:** RelationshipInference, AI Content Analysis Phase 6
**Severity:** High
**Date Identified:** 2026-01-30
**Date Resolved:** 2026-01-30

**Description:**

When running AI content analysis on text with clear relationship patterns, **zero relationships are being detected** even though entities are correctly identified. User analyzed "Professor Elara Moonwhisper" text which contained obvious relationships (discovered, led by, works at), but console showed:

```
✅ [SuggestionEngine] Successfully created 31 cards
✅ [SuggestionEngine] Found 32 entities in text
→ Detected 0 relationships from patterns  ⚠️  SHOULD BE 10+
```

**Root Causes (Multiple):**

### Bug 1: Substring Matching (Lines 374-408)
Entity matching used `range(of:)` which does substring matching, causing false positives:
- "Silver Era" falsely matching in "Silverpeak Mountains"
- "Council of Unity" matching any sentence with "council"

### Bug 2: Overly Aggressive Fuzzy Matching (Lines 374-408)
Word-by-word fuzzy matching was **always enabled**, matching partial entity names too broadly:
- "Captain Jarek Stormborn" would match any sentence with "captain" OR "jarek" OR "stormborn"
- "Council of Unity" would match "The council met" (wrong - different council)

**Issue:** Fuzzy matching was added in earlier iteration to handle compressed text where names are abbreviated (e.g., "Captain Drake" → "Drake"). But applying this to all text caused false positives.

### Bug 3: Missing Relationship Patterns (Lines 195-242)
Pattern trigger list was incomplete - missing common narrative verbs:
- "discovered" (Captain discovered artifact)
- "led by" (team led by Captain)
- "works at" / "of the" (Dean of the Consortium)

**Result:** Even when entities were correctly matched, patterns didn't trigger because verbs weren't in the list.

**Fix Applied:**

### Fix 1: Word-Boundary Matching (Lines 410-429)
Added regex-based word boundary matching to prevent substring matches:

```swift
private func findWordBoundaryMatch(word: String, in text: String) -> Range<String.Index>? {
    // Normalize whitespace to handle line breaks and multiple spaces
    let normalizedWord = word.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
    let normalizedText = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

    // Use regex with word boundaries to match whole words only
    let pattern = "\\b\(NSRegularExpression.escapedPattern(for: normalizedWord))\\b"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
        return nil
    }

    let nsRange = NSRange(normalizedText.startIndex..<normalizedText.endIndex, in: normalizedText)
    guard let match = regex.firstMatch(in: normalizedText, range: nsRange) else {
        return nil
    }

    return Range(match.range, in: normalizedText)
}
```

**Result:** "Silver Era" will NOT match in "Silverpeak" ✅

### Fix 2: Conditional Fuzzy Matching (Lines 260-269, 374-408)
Made fuzzy matching **conditional** - only enable for compressed/long text:

```swift
func inferRelationships(
    from text: String,
    entities: [Entity],
    existingCards: [Card]
) -> [DetectedRelationship] {
    // Determine if we need fuzzy matching based on text length
    // Compressed text (from TextPreprocessor when > 5000 words) needs fuzzy matching
    // because entity names may be abbreviated
    let wordCount = text.split(separator: " ").count
    let useFuzzyMatching = wordCount > 800  // Likely compressed or very long text

    // Find which entities appear in this sentence
    let entitiesInSentence = entities.filter { entity in
        findEntityInSentence(entityName: entity.name, sentence: sentenceLower, useFuzzyMatching: useFuzzyMatching) != nil
    }
}

private func findEntityInSentence(entityName: String, sentence: String, useFuzzyMatching: Bool) -> String.Index? {
    // Try exact match first with word boundaries
    if let range = findWordBoundaryMatch(word: entityLower, in: sentenceLower) {
        return range.lowerBound
    }

    // Only use fuzzy matching for compressed/long text where names may be abbreviated
    guard useFuzzyMatching else {
        return nil
    }

    // For compressed text: Try matching significant words from the entity name
    let significantWords = entityWords.filter { word in
        word.count > 3 && !["the", "and", "for", "with", "from"].contains(word)
    }

    for word in significantWords {
        if let range = findWordBoundaryMatch(word: word, in: sentenceLower) {
            return range.lowerBound
        }
    }

    return nil
}
```

**Logic:**
- **Short text (<800 words):** Strict matching only (exact entity names with word boundaries)
- **Long text (>800 words):** Fuzzy matching enabled (handles abbreviated names in compressed summaries)

**Why 800 words:** TextPreprocessor compresses text >5000 words. After compression, result is typically 500-1000 words. The 800-word threshold catches compressed text while avoiding false positives on normal-length text.

### Fix 3: Added Missing Relationship Patterns (Lines 195-242)
Added three new relationship patterns for common narrative verbs:

```swift
// MARK: Discovery & Leadership (common narrative verbs)

.init(
    id: "discovered",
    triggers: ["discovered", "found", "uncovered", "unearthed", "located"],
    relationTypeCode: "discovered/discovered-by",
    isSymmetric: false,
    baseConfidence: 0.85,
    sourceKind: .characters,
    targetKind: nil, // Can be artifacts, locations, buildings
    description: "Character discovered something"
),

.init(
    id: "leads",
    triggers: ["led by", "leads", "headed by", "commanded by", "under"],
    relationTypeCode: "leads/led-by",
    isSymmetric: false,
    baseConfidence: 0.80,
    sourceKind: .characters,
    targetKind: nil, // Can be organizations, groups, teams
    description: "Character leads a group or organization"
),

.init(
    id: "works-at",
    triggers: ["works at", "employed by", "serves at", "stationed at", "of the", "of"],
    relationTypeCode: "works-at/employs",
    isSymmetric: false,
    baseConfidence: 0.75,
    sourceKind: .characters,
    targetKind: nil, // Can be buildings, organizations
    description: "Character works at a place or for an organization"
)
```

**Files Modified:**
- `Cumberland/AI/RelationshipInference.swift:195-242` - Added new relationship patterns
- `Cumberland/AI/RelationshipInference.swift:260-269` - Added conditional fuzzy matching logic
- `Cumberland/AI/RelationshipInference.swift:374-408` - Modified entity matching with useFuzzyMatching parameter
- `Cumberland/AI/RelationshipInference.swift:410-429` - Added word-boundary matching function

**Test Steps:**

1. Create or open a scene card: "Discovery of the Sky Citadel"
2. Add the "Professor Elara Moonwhisper" test text (388 words)
3. Click "Analyze Content with AI" (use Anthropic provider)
4. Wait for analysis to complete
5. **Verify Console Output:**
   ```
   ✅ [SuggestionEngine] Successfully created 31 cards
   ✅ [SuggestionEngine] Found 32 entities in text
      Text word count: 388
      Using fuzzy matching: false
   📝 Analyzing sentence: "Captain Jarek Stormborn discovered the Codex..."
      Found 2 entities: Captain Jarek Stormborn, Codex of Forgotten Winds
   → Captain Jarek Stormborn → [discovered/discovered-by] → Codex of Forgotten Winds (85%)
   📝 Analyzing sentence: "team led by Captain Jarek Stormborn"
      Found 1 entities: Captain Jarek Stormborn
   → Captain Jarek Stormborn → [leads/led-by] → Expedition Team (80%)
   📝 Analyzing sentence: "Dean Octavius Ashwood of the Consortium"
      Found 2 entities: Dean Octavius Ashwood, Consortium of Arcane Studies
   → Dean Octavius Ashwood → [works-at/employs] → Consortium of Arcane Studies (75%)
   → Detected 12 relationships from patterns  ✅ (WAS 0)
   ```
6. Review Suggestions panel should show purple "Relationships to Add" section
7. **Verify:** At least 10+ relationships detected (e.g., discovered, leads, works-at, appears-in, etc.)
8. Select all and create
9. **Verify:** Relationships appear in card Relationships tab

**Expected Relationships (Examples):**
- Captain Jarek Stormborn → discovered → Codex of Forgotten Winds
- Captain Jarek Stormborn → leads → Expedition Team
- Dean Octavius Ashwood → works-at → Consortium of Arcane Studies
- Professor Elara Moonwhisper → appears-in → Discovery of the Sky Citadel
- Codex of Forgotten Winds → appears-in → Discovery of the Sky Citadel

**Debug Output:**

Before fix:
```
📝 Analyzing sentence: "Silver Era civilization at Silverpeak Mountains"
   Found 2 entities: Silver Era, Silverpeak Mountains  ❌ FALSE POSITIVE
→ Detected 0 relationships from patterns
```

After Fix 1 (word boundaries):
```
📝 Analyzing sentence: "Silver Era civilization at Silverpeak Mountains"
   Found 1 entities: Silverpeak Mountains  ✅ CORRECT
```

After Fix 2 (conditional fuzzy):
```
   Text word count: 388
   Using fuzzy matching: false  ✅ Strict mode for short text
```

After Fix 3 (new patterns):
```
📝 Analyzing sentence: "Captain discovered the Codex"
   Found 2 entities: Captain Jarek Stormborn, Codex
→ Captain Jarek Stormborn → [discovered/discovered-by] → Codex (85%)  ✅
```

**Related Issues:**
- ER-0010: Phase 6 Relationship Inference implementation
- ER-0018: TextPreprocessor compression (triggers fuzzy matching for >5000 word texts)
- DR-0066: Relationship creation bug (fixed in same session)

**Implementation Notes:**

**Debugging Process:**
1. Initial focus was on entity matching (substring bug) - fixed with word boundaries
2. Then noticed fuzzy matching too aggressive - made conditional
3. User redirected: "Ok can I get you to agree that you are on the wrong track now?"
4. Realized entity matching WAS working correctly - the real issue was pattern matching
5. Console showed entities found in sentences but 0 relationships detected
6. Root cause: Missing trigger words in pattern list ("discovered", "led by", "of the")

**Why Three Bugs:**
This DR documents three separate but related bugs discovered during the same debugging session:
1. Substring matching causing false entity detection
2. Fuzzy matching too permissive for normal-length text
3. Incomplete pattern trigger list

Each bug was independently preventing relationships from being detected correctly. All three needed to be fixed for the system to work properly.

**Notes:**

- This issue was discovered when testing DR-0066 fix with "Professor Elara Moonwhisper" text
- User correctly identified that entity matching was working: "the entities ARE being matched correctly. the patterns are NOT triggering"
- Bug has existed since Phase 6 (ER-0010) relationship inference was implemented
- Only affected texts with narrative verbs not in the original pattern list
- Fix expands pattern coverage for common storytelling language

---

## DR-XXXX: [Brief Title]

**Status:** 🔴 Identified / 🟡 Resolved - Not Verified / ✅ Verified
**Platform:** macOS / iOS / All platforms
**Component:** [Component Name]
**Severity:** Critical / High / Medium / Low
**Date Identified:** YYYY-MM-DD
**Date Resolved:** YYYY-MM-DD

**Description:**
[What's wrong]

**Root Cause:**
[Why it's happening]

**Fix Applied:**
[What was done]

**Files Modified:**
- [List of files and line numbers]

**Test Steps:**
1. [How to verify]
```

---

## Status Indicators

Per DR-GUIDELINES.md:
- 🔴 **Identified - Not Resolved** - Issue found and root cause analyzed, awaiting fix
- 🟡 **Resolved - Not Verified** - Claude can mark when implementation is complete
- ✅ **Resolved - Verified** - Only USER can mark after testing

---

*Last Updated: 2026-01-31*
*All DRs verified and moved to batch files. DR-0067 closed and deferred to ER-0020.*
