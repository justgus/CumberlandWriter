# Discrepancy Reports (DR) - Unverified Issues

This document tracks discrepancy reports that have been resolved but are awaiting user verification.

**Status:** Currently **9 unverified DRs** (2 Resolved, 7 Open)

---

## DR-0051: CardEditorView Fixed to Narrow Width on macOS Sheet - Doesn't Fill Available Space

**Status:** 🔴 Open
**Platform:** macOS
**Component:** CardEditorView
**Severity:** Medium
**Date Identified:** 2026-01-24

**Description:**

On macOS, CardEditorView is displayed in a resizable sheet but appears artificially narrow (~430 points width) even when the sheet is resized larger. The editor doesn't respond to sheet resizing and remains fixed at a narrow width, making it look scrunched up on macOS displays where more horizontal space is available.

**Current Behavior:**
- CardEditorView displayed in a sheet on macOS
- Sheet is resizable by user (can be made larger or smaller)
- CardEditorView content remains fixed at ~430 points width
- Content does not grow when sheet is expanded
- Content does not shrink when sheet is reduced
- Looks cramped and doesn't utilize available screen real estate

**Expected Behavior:**
- CardEditorView should fill the available width of the sheet
- When user resizes sheet larger, content should grow to fill
- When user resizes sheet smaller, content should shrink accordingly
- Should feel native to macOS with proper use of available space
- Should maintain minimum width for usability (520 points currently)

**Root Cause:**

**File:** `Cumberland/CardEditorView.swift:164`
```swift
#if os(visionOS)
private let maxCardWidth: CGFloat = 640
#else
private let thumbnailSide: CGFloat = 72
private let thumbnailTopPadding: CGFloat = 8
private let maxCardWidth: CGFloat = 430  // ← TOO NARROW FOR MACOS
#endif
```

All content sections use `.frame(maxWidth: maxCardWidth)`:
- Line 240: FlipCardContainer
- Line 275: Image action buttons
- Line 289: Citation viewer
- Line 308: Save/Cancel buttons
- Line 727: Card surface

This hard limit prevents the view from expanding beyond 430 points, even though:
1. The containing VStack has `.frame(minWidth: 520)` (line 311)
2. The sheet can be resized much larger on macOS
3. macOS displays have plenty of horizontal space

**Proposed Solution:**

**Option 1: Use .infinity for maxWidth on macOS**
```swift
#if os(macOS)
private let maxCardWidth: CGFloat = .infinity
#elseif os(visionOS)
private let maxCardWidth: CGFloat = 640
#else
private let maxCardWidth: CGFloat = 430  // iOS/iPadOS
#endif
```

**Option 2: Use GeometryReader to adapt to container**
- Remove fixed maxCardWidth
- Use GeometryReader to get available width
- Calculate appropriate max width based on available space

**Option 3: Platform-specific maxWidth that's reasonable but larger**
```swift
#if os(macOS)
private let maxCardWidth: CGFloat = 800  // Allow wider on macOS
#elseif os(visionOS)
private let maxCardWidth: CGFloat = 640
#else
private let maxCardWidth: CGFloat = 430  // iOS/iPadOS
#endif
```

**Affected Code:**
- `Cumberland/CardEditorView.swift:164` - maxCardWidth constant
- `Cumberland/CardEditorView.swift:240,275,289,308,727` - All .frame(maxWidth:) calls

**Test Steps:**

1. Open Cumberland on macOS
2. Edit or create a card (opens CardEditorView sheet)
3. Observe initial width (narrow, ~430 points)
4. Resize sheet by dragging corner to make it wider
5. **Current**: Content remains narrow, doesn't fill sheet
6. **Expected**: Content grows to fill available width (up to reasonable max like 800)

**Verification Criteria:**

- [ ] CardEditorView expands to fill wider sheets
- [ ] CardEditorView shrinks when sheet is made smaller
- [ ] Minimum width preserved (520 points)
- [ ] Maximum width reasonable for macOS (suggest 800-1000 points)
- [ ] Content is readable and well-spaced at all sizes
- [ ] Works correctly on iOS/iPadOS (should not affect those platforms)

**User Impact:** Medium - Affects macOS usability and aesthetics, makes editor feel cramped

**Priority:** Medium - UI/UX improvement for macOS

**Workaround:** Users can work with narrow editor, but it's not optimal for macOS

---

## DR-0052: OpenAI Entity Extraction Has Two Critical Bugs (0 Entities + Wrong Card Types)

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms (macOS, iOS, iPadOS, visionOS)
**Component:** OpenAIProvider / Content Analysis (ER-0010)
**Severity:** High
**Date Identified:** 2026-01-24
**Date Resolved:** 2026-01-24

**Description:**

When using OpenAI provider for entity extraction (Phase 5, ER-0010), there were two critical bugs:

**Bug 1:** Analysis completes successfully but returns 0 entities due to JSON parsing failure
**Bug 2:** After Bug 1 fix, entities are extracted but all cards created are "rules" instead of proper types (character, location, building, etc.)

**Observed Behavior:**

Console output during testing:
```
🔍 [EntityExtractor] Extracting entities from text
   Provider: OpenAI DALL-E 3
   Word count: 2235
   Confidence threshold: 0.7
📝 [TextPreprocessor] Preprocessing long text (2235 words)
✅ [TextPreprocessor] Condensed 2235 → 740 words (33.1%) in 0.07s
   Extracted 26 key entities
   Found 45 relevant sentences
🧠 [OpenAI] Analyzing text for task: entityExtraction
   Text length: 4501 characters, 740 words
⚠️ [OpenAI] Failed to parse entities JSON  ← ISSUE HERE
✅ [OpenAI] Analysis complete in 88.75s
   Entities: 0  ← RESULT: 0 ENTITIES
   Relationships: 0
```

**Expected Behavior:**
- GPT-4 returns entity JSON
- JSON is parsed successfully
- Entities are extracted and displayed in suggestion sheet

**Root Cause:**

**Mismatch between response format and parsing logic:**

1. **OpenAIProvider.swift:270** - Request configuration:
   ```swift
   "response_format": ["type": "json_object"]  // Requests JSON OBJECT
   ```

2. **OpenAIProvider.swift:201** - System prompt (BEFORE fix):
   ```swift
   Return results as a JSON array with this structure:
   [  // ← Asking for ARRAY
     {
       "name": "Entity Name",
       ...
     }
   ]
   ```

3. **OpenAIProvider.swift:338** - Parsing code (BEFORE fix):
   ```swift
   let jsonArray = try? JSONDecoder().decode([EntityJSON].self, from: jsonData)
   // ← Trying to parse as ARRAY
   ```

**Issue:** When `response_format: json_object` is specified, GPT-4 wraps responses in an object like:
```json
{
  "entities": [...]
}
```

But we were asking for an array and trying to parse as an array, causing parsing failure.

**Resolution:**

**File:** `Cumberland/AI/OpenAIProvider.swift`

**Change 1:** Updated system prompt (lines 198-211):
```swift
Return results as a JSON object with an "entities" array:
{
  "entities": [
    {
      "name": "Entity Name",
      "type": "character|location|building|artifact|vehicle|organization|event",
      "confidence": 0.0-1.0,
      "context": "Brief surrounding text"
    }
  ]
}
```

**Change 2:** Added wrapper struct (after line 370):
```swift
private struct EntityResponse: Codable {
    let entities: [EntityJSON]
}
```

**Change 3:** Updated parsing logic (lines 336-368) to try both formats:
```swift
// Try parsing as wrapped object first (GPT-4 with response_format: json_object)
if let wrappedResponse = try? JSONDecoder().decode(EntityResponse.self, from: jsonData) {
    return wrappedResponse.entities.map { ... }
}

// Fallback: try parsing as direct array
if let jsonArray = try? JSONDecoder().decode([EntityJSON].self, from: jsonData) {
    return jsonArray.map { ... }
}
```

**Change 4:** Added better debug logging to show first 500 chars of raw JSON on failure

---

### Bug 2: All Entities Created as "Rules" Cards (Case-Sensitivity Issue)

After fixing Bug 1, entities were successfully extracted but all cards created were of kind "rules" instead of their proper types (character, location, building, etc.).

**Root Cause:**

**Case mismatch between GPT-4 response and EntityType rawValues:**

1. **OpenAIProvider.swift:206** - GPT-4 prompt asks for lowercase types:
   ```swift
   "type": "character|location|building|artifact|vehicle|organization|event"
   ```

2. **AIProviderProtocol.swift:167-174** - EntityType rawValues were CAPITALIZED (BEFORE fix):
   ```swift
   enum EntityType: String, Codable {
       case character = "Character"  // ← Capital C
       case location = "Location"    // ← Capital L
       case building = "Building"    // ← Capital B
       // etc.
   ```

3. **OpenAIProvider.swift:348** - Parsing with fallback to .other:
   ```swift
   type: EntityType(rawValue: json.type) ?? .other
   // GPT returns "character", tries to match "Character", fails → defaults to .other
   ```

4. **AIProviderProtocol.swift:186** - .other maps to .rules:
   ```swift
   case .other: return .rules  // All entities became rules!
   ```

**Resolution for Bug 2:**

**File:** `Cumberland/AI/AIProviderProtocol.swift`

**Change 5:** Updated EntityType rawValues to lowercase (lines 167-174):
```swift
enum EntityType: String, Codable {
    case character = "character"      // Changed from "Character"
    case location = "location"        // Changed from "Location"
    case building = "building"        // Changed from "Building"
    case artifact = "artifact"        // Changed from "Artifact"
    case vehicle = "vehicle"          // Changed from "Vehicle"
    case organization = "organization" // Changed from "Organization"
    case event = "event"              // Changed from "Event"
    case other = "other"              // Changed from "Other"
```

Now the rawValues match what GPT-4 returns, so parsing works correctly and entities map to their proper card kinds.

---

**Affected Code:**
- `Cumberland/AI/OpenAIProvider.swift:198-211` - System prompt (Bug 1)
- `Cumberland/AI/OpenAIProvider.swift:336-368` - Parsing logic (Bug 1)
- `Cumberland/AI/OpenAIProvider.swift:370-373` - EntityResponse struct (Bug 1)
- `Cumberland/AI/AIProviderProtocol.swift:167-174` - EntityType rawValues (Bug 2)

**Test Steps:**

1. Build and run Cumberland on macOS
2. Create a Scene card
3. Paste chapter-length prose from `TEST-SCENE-CHAPTER-LENGTH.md`
4. Set Settings → AI → Provider to "OpenAI"
5. Click "Analyze" button
6. **Before Bug 1 fix**: Console shows "Failed to parse entities JSON", 0 entities returned
7. **After Bug 1 fix**: Console shows "Parsed N entities from wrapped JSON", entities appear in suggestion sheet
8. **Before Bug 2 fix**: Select entities and create cards → all cards are kind "rules"
9. **After Bug 2 fix**: Select entities and create cards → cards have correct kinds (characters, locations, buildings, artifacts, vehicles, etc.)

**Verification Criteria:**

- [ ] OpenAI entity extraction returns entities (not 0) — Bug 1 fixed
- [ ] Console shows "✅ Parsed N entities from wrapped JSON" — Bug 1 fixed
- [ ] Suggestion sheet displays extracted entities — Bug 1 fixed
- [ ] Entities have proper names, types, and confidence scores — Both bugs fixed
- [ ] At least 15+ entities extracted from test scene (expected ~30-37)
- [ ] Cards created with CORRECT kinds (not all "rules") — Bug 2 fixed
  - Characters → .characters kind
  - Locations → .locations kind
  - Buildings → .buildings kind
  - Artifacts → .artifacts kind
  - Vehicles → .vehicles kind
  - Organizations → .characters kind (acceptable mapping)
  - Events → .scenes kind (acceptable mapping)

**User Impact:** High - OpenAI entity extraction completely non-functional (Bug 1), then created wrong card types (Bug 2)

**Priority:** High - Critical bugs in Phase 5 implementation

**Workaround:** Use Apple Intelligence provider instead (not affected by these bugs)

**Related:**
- ER-0010 Phase 5 (Content Analysis MVP)
- DR-0050 (Timeout issue - resolved separately)

---

## DR-0050: OpenAI Content Analysis Timeout with Default URLSession Settings

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms (macOS, iOS, iPadOS, visionOS)
**Component:** OpenAIProvider / Content Analysis (ER-0010)
**Severity:** High
**Date Identified:** 2026-01-24
**Date Resolved:** 2026-01-24

**Description:**

When using OpenAI as the AI provider for content analysis (ER-0010 Phase 5), GPT-4 API calls to `/v1/chat/completions` timeout after ~60 seconds with error code -1001. This occurs because:
1. GPT-4 text analysis can take 30-120 seconds for complex entity extraction
2. Default URLSession timeout (60s) is too short for AI operations
3. Error messages were not user-friendly (showed raw NSURLError)

**Error Observed:**
```
Task <UUID>.<N> finished with error [-1001]
Error Domain=NSURLErrorDomain Code=-1001 "The request timed out."
https://api.openai.com/v1/chat/completions
```

**Current Behavior (Before Fix):**
- OpenAI content analysis times out after 60 seconds
- Generic error message: "The request timed out."
- No guidance for users on how to resolve
- Apple Intelligence works fine (on-device, fast)

**Expected Behavior:**
- OpenAI requests should have sufficient timeout for AI operations
- Clear error messages with actionable guidance
- Suggest fallback to Apple Intelligence if timeout occurs

**Root Cause:**

OpenAIProvider used `URLSession.shared` with default configuration:
- `timeoutIntervalForRequest`: 60 seconds (too short)
- `timeoutIntervalForResource`: 7 days (fine)

**Resolution:**

**Files Modified:**
- `Cumberland/AI/OpenAIProvider.swift:48-54` - Added custom URLSession with longer timeout
- `Cumberland/AI/OpenAIProvider.swift:276-303` - Improved timeout error handling
- `Cumberland/CardEditorView.swift:1133-1160` - User-friendly error messages in UI

**Changes:**

1. **Custom URLSession Configuration (OpenAIProvider.swift:48-54):**
   ```swift
   private lazy var urlSession: URLSession = {
       let config = URLSessionConfiguration.default
       config.timeoutIntervalForRequest = 120  // 2 minutes
       config.timeoutIntervalForResource = 180 // 3 minutes
       return URLSession(configuration: config)
   }()
   ```

2. **Better Error Handling (OpenAIProvider.swift:276-303):**
   - Catch NSURLErrorTimedOut specifically
   - Provide helpful message suggesting Apple Intelligence
   - Detect network connectivity issues

3. **User-Friendly UI Messages (CardEditorView.swift:1133-1160):**
   - Timeout: "Try using Apple Intelligence (faster, on-device)"
   - Missing API Key: "Add your API key in Settings → AI"
   - Network errors: Specific troubleshooting steps

**Test Steps:**

1. Set AI provider to OpenAI in Settings → AI
2. Ensure OpenAI API key is configured (or intentionally leave blank to test error)
3. Create/edit a card with 100+ word description
4. Click "Analyze" button
5. **Expected (with API key)**: Analysis completes within 2 minutes or times out with helpful message
6. **Expected (without API key)**: Clear error: "OpenAI API key is missing or invalid"

**Verification Criteria:**

- [ ] OpenAI analysis completes successfully with valid API key (or times out with helpful message)
- [ ] Timeout errors show actionable guidance
- [ ] Missing API key error is clear and helpful
- [ ] Apple Intelligence continues to work fast (~1-3 seconds)

**User Impact:** High - Blocks content analysis for users preferring OpenAI over Apple Intelligence

**Priority:** High - Core ER-0010 functionality

**Related:** ER-0010 Phase 5 (Content Analysis MVP)

---

## DR-0043: Duplicate RelationType Entries Created Despite Deduplication Logic

**Status:** 🔴 Open
**Platform:** All platforms (macOS, iOS, iPadOS, visionOS)
**Component:** RelationType / CumberlandApp seeding
**Severity:** Medium
**Date Identified:** 2026-01-24

**Description:**

Duplicate RelationType entries are appearing in the database despite the presence of deduplication logic in the seeding code (`seedRelationTypesIfNeeded`). Users observe multiple RelationType entries with identical or very similar labels when viewing relationship type pickers or in the RelationTypes diagnostics view.

**Current Behavior:**
- Duplicate RelationType entries exist in the database
- Same relationship types appear multiple times in UI pickers
- Affects user experience when selecting relationship types
- May cause confusion about which type to use

**Expected Behavior:**
- Each unique RelationType code should exist only once in the database
- Seeding logic should prevent duplicate creation
- No duplicate entries should appear in UI pickers

**Possible Root Causes:**

1. **Race Condition During App Launch:**
   - Multiple simultaneous calls to `seedRelationTypesIfNeeded` on different devices
   - CloudKit sync merging duplicate entries created before sync completes

2. **Code Mismatch:**
   - Different codes with same labels (e.g., "part-of/has-member" vs "part-of/has-member-2")
   - Automatic mirror type creation generating duplicates

3. **Manual Creation:**
   - User or diagnostic tools creating duplicate entries manually
   - Fix Incomplete Relationships tool creating mirror types that duplicate existing ones

4. **CloudKit Sync Issues:**
   - Conflict resolution creating duplicate objects
   - Same RelationType created on multiple devices before initial sync

**Affected Code:**

`Cumberland/CumberlandApp.swift:517-554` - `seedRelationTypesIfNeeded` function
```swift
static func seedRelationTypesIfNeeded(container: ModelContainer) async {
    let existing = (try? context.fetch(fetch)) ?? []
    var existingCodes = Set(existing.map { $0.code })

    for s in relationTypeSeeds {
        if existingCodes.contains(s.code) {
            continue  // Should prevent duplicates by code
        }
        // ... insert new type
    }
}
```

`Cumberland/CumberlandApp.swift:1299-1334` - `ensureMirrorType` function (Fix Incomplete Relationships)
- Creates mirror types dynamically
- May create duplicates if multiple devices run fix simultaneously

**Steps to Reproduce:**
1. Use app across multiple devices with CloudKit sync enabled
2. Observe RelationType picker or diagnostics view
3. **Note**: Exact reproduction steps unclear - may be timing-dependent

**Potential Solutions:**

1. **Add Unique Constraint Check:**
   - Before inserting, query for existing type with same code
   - Use @MainActor to ensure serial execution

2. **Batch Fetch and Merge:**
   - Fetch all RelationTypes at startup
   - Merge duplicates by code, keeping oldest
   - Delete merged duplicates

3. **CloudKit Deduplication:**
   - Add server-side unique constraint on `code` field
   - Handle merge conflicts by preferring existing record

4. **Diagnostic Tool Enhancement:**
   - Add "Find and Merge Duplicates" function to RelationTypesDiagnosticsView
   - Allow user to manually clean up duplicates

**Workaround:**
- Manually delete duplicate RelationType entries via RelationTypesDiagnosticsView
- Note: May require reassigning relationships to non-duplicate type first

**Impact:**
- **Medium** - Affects UX but doesn't break core functionality
- Confusing for users selecting relationship types
- Database bloat with duplicate entries
- May cause unexpected behavior if different duplicates are used for same logical relationship

**Priority:** Medium - Should be fixed to maintain data integrity

---

## DR-0042: Apple Pencil Not Working with Gesture-Based Brushes on iOS

**Status:** ✅ Resolved - Not Verified
**Platform:** iOS/iPadOS only
**Component:** DrawingCanvasView / UIPanGestureRecognizer
**Severity:** High
**Date Identified:** 2026-01-19
**Date Resolved:** 2026-01-24

**Description:**

When using gesture-based brushes (Walls, Furniture/Stamps) on iOS, the Apple Pencil does not trigger the drawing gesture. Only finger touch works. This is inconsistent with the rest of the app where the Apple Pencil works perfectly for all other interactions (tapping to create maps, setting display parameters, moving the tool palette, changing brushes, etc.).

**Current Behavior:**
- **With Finger Touch**: Walls and furniture draw correctly with dotted preview and final rendering
- **With Apple Pencil**:
  - All UI interactions work (tap buttons, move palette, select brushes, etc.)
  - Drawing gestures do NOT work - nothing happens when dragging with Pencil
  - User must switch to finger to draw walls/furniture
  - Area fill brushes (Carpet, Water Feature, Rubble) work fine with Pencil (they use PencilKit)

**Expected Behavior:**
- Apple Pencil should work identically to finger for gesture-based brushes
- When dragging with Pencil over canvas with Wall/Furniture brush selected:
  - Dotted preview should appear
  - Final wall/furniture should render on touch end
- Consistent behavior: if Pencil works for UI, it should work for drawing

**Root Cause:**

The `UIPanGestureRecognizer` added for gesture-based brushes (DR-0031/ER-0004 implementation) is not configured to recognize Apple Pencil touches. By default, `UIPanGestureRecognizer` only recognizes finger touches unless explicitly configured to allow stylus input.

**Affected Code:**

`Cumberland/DrawCanvas/DrawingCanvasView.swift:1226-1229`
```swift
// ER-0004: Add gesture recognizer for advanced brush drawing
let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrawingGesture(_:)))
panGesture.delegate = context.coordinator
canvasView.addGestureRecognizer(panGesture)
```

**Solution:**

Configure the gesture recognizer to accept stylus input:

```swift
let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrawingGesture(_:)))
panGesture.delegate = context.coordinator
panGesture.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber, UITouch.TouchType.stylus.rawValue as NSNumber]
canvasView.addGestureRecognizer(panGesture)
```

**Steps to Reproduce:**
1. Launch app on iPad with Apple Pencil
2. Create interior map
3. Select Wall brush from tool palette
4. Try to draw wall with Apple Pencil
5. **Observe**: Nothing happens - no preview, no wall
6. Try drawing same wall with finger
7. **Observe**: Preview appears, wall draws correctly

**Workaround:**
- Use finger instead of Apple Pencil for walls and furniture
- Area fill brushes (which use PencilKit) work fine with Pencil

**Impact:**
- **High** - Breaks expected workflow for iPad + Apple Pencil users
- Users must constantly switch between Pencil (for UI) and finger (for drawing)
- Inconsistent user experience
- Particularly problematic for architectural work (walls, furniture) where precision is important

**Priority:** High - This significantly degrades the iPad drawing experience

**Resolution:**

Applied the documented solution by configuring the gesture recognizer to accept both direct touch (finger) and stylus (Apple Pencil) input:

`Cumberland/DrawCanvas/DrawingCanvasView.swift:1229-1231`
```swift
// DR-0042: Allow Apple Pencil input for gesture-based brushes
panGesture.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber, UITouch.TouchType.stylus.rawValue as NSNumber]
```

The fix is a single line added after creating the `UIPanGestureRecognizer`. This configures the gesture recognizer to accept both finger touches (`.direct`) and Apple Pencil input (`.stylus`), ensuring consistent behavior across input methods.

**Verification Steps:**
1. Launch app on iPad with Apple Pencil
2. Create interior map
3. Select Wall brush from tool palette
4. Draw wall with Apple Pencil
5. **Expected**: Preview appears, wall draws correctly (same as finger)
6. Test Furniture/Stamps brush with Pencil
7. **Expected**: Works identically to finger input

---

## DR-0041: Vegetation and Terrain Brushes Should Render as Area Fills

**Status:** 🔴 Open
**Platform:** All platforms (macOS, iOS, iPadOS)
**Component:** BrushEngine / ExteriorMapBrushSet
**Severity:** Medium
**Date Identified:** 2026-01-19

**Description:**

Several exterior vegetation and terrain brushes currently render as line strokes but should render as area fills (similar to how the Marsh brush works). These brushes represent terrain features that naturally cover areas rather than follow linear paths.

**Affected Brushes:**

**Vegetation Category:**
- Forest
- Single Tree
- Grassland
- Plains
- Jungle

**Terrain Category:**
- Desert
- Tundra

**Special Case:**
- **Farmland** - Should render as area fill with rectangular "fields" pattern

**Current Behavior:**
- These brushes follow the drawn path as a line
- Vegetation/terrain texture applied along the stroke
- No area fill - only renders where the path was drawn
- Inconsistent with Marsh brush which fills enclosed areas

**Expected Behavior:**
- User draws a freeform closed or open path
- Brush fills the enclosed area (or area around path) with appropriate pattern:
  - **Forest**: Dense tree pattern scattered throughout area
  - **Single Tree**: Sparse individual trees
  - **Grassland**: Grass texture fill
  - **Plains**: Open grass/prairie texture
  - **Jungle**: Dense vegetation with variety
  - **Desert**: Sandy texture with occasional dunes
  - **Tundra**: Cold, sparse ground cover
  - **Farmland**: Rectangular field pattern (plowed rows in grid layout)

**Reference Implementation:**
- **Marsh brush** already works this way - fills areas with marsh/wetland texture
- Same rendering approach should apply to vegetation/terrain brushes

**Design Notes:**

1. **Area Detection:**
   - For closed paths: Fill interior
   - For open paths: Could fill area with some buffer distance, or require closed paths

2. **Pattern Distribution:**
   - Trees: Scattered with random spacing (avoid grid appearance)
   - Grassland/Plains: Organic texture fill
   - Desert: Sandy base with dune shapes
   - Farmland: Grid of rectangular fields at consistent angles

3. **Density Control:**
   - Could use brush width parameter to control density
   - Forest: Dense (many trees)
   - Single Tree: Sparse (few trees)
   - Grassland: Medium coverage

**Steps to Reproduce Current Issue:**
1. Create exterior map
2. Select Forest brush
3. Draw closed loop to define forest area
4. **Observe**: Only the path line has forest texture, interior is empty
5. Compare to Marsh brush which fills the interior

**Impact:**
- Users cannot create realistic area-based terrain features
- Have to draw many overlapping strokes to simulate area coverage (tedious)
- Maps look less professional with line-based vegetation
- Inconsistent with realistic map-making (forests are areas, not lines)

**Affected Files:**
- `Cumberland/DrawCanvas/BrushEngine.swift` - May need new area fill rendering for vegetation
- `Cumberland/DrawCanvas/ExteriorMapBrushSet.swift` - Brush definitions
- Possibly need new pattern generators in `Cumberland/DrawCanvas/ProceduralPatternGenerator.swift`

**Related:**
- Marsh brush already demonstrates the desired behavior
- Interior area fill brushes (Carpet, Water Feature, Rubble) work correctly
- This is about extending area fill to exterior terrain brushes

**Priority:** Medium - Affects map quality and user workflow, but has workaround (draw many strokes)

---

## DR-0040: Brush Set Picker Text Overflow on iOS

**Status:** 🔴 Open
**Platform:** iOS/iPadOS only
**Component:** BrushGridView / Tool Palette
**Severity:** Medium
**Date Identified:** 2026-01-19

**Description:**

In the "Brushes for Generic" section of the tool palette on iOS, when a brush set is selected, the UI layout breaks with text overflowing into the section below.

**Current Behavior:**
- Before selection: "Brush Set:" label and count visible with picker arrows (correct)
- After selecting a brush set (e.g., "Basic Tools", "Exterior Brushes"):
  - Picker text has insufficient width
  - Selected brush set name wraps/overflows vertically
  - "Brush Set:" label overflows into next section
  - Brush count (e.g., "42") overflows into next section

**Expected Behavior:**
- Picker should have sufficient horizontal width for full brush set name
- No text should overflow into adjacent sections
- Layout should remain clean and readable

**Steps to Reproduce:**
1. Open iOS app
2. Create any map (interior or exterior)
3. Open tool palette
4. Navigate to "Brushes for Generic" section
5. Tap picker and select a brush set
6. Observe text overflow into section below

**Root Cause:**
Likely insufficient frame width or missing layout constraints for the Picker view on iOS.

**Affected Files:**
- `Cumberland/DrawCanvas/BrushGridView.swift` - Brush selection UI
- Wherever "Brushes for Generic" picker is implemented

**Impact:**
- Poor UX on iOS - UI appears broken
- Difficult to read selected brush set name
- Overlapping text reduces usability

---

## DR-0038: Draft Interior Drawing Settings Not Remembered Between View Loads

**Status:** 🔴 Open
**Platform:** All platforms (macOS, iOS, iPadOS)
**Component:** MapWizardView / Draft Persistence
**Severity:** Medium
**Date Identified:** 2026-01-10

**Description:**

When working on interior/architectural maps in the Map Wizard, drawing settings such as snap to grid, grid type, grid size, and background color (parchment) are not remembered between view loads or app restarts. Users must re-configure these settings every time they return to work on their map draft.

**Current Behavior:**
- User configures interior map settings:
  - Snap to Grid: ON
  - Grid Type: Square
  - Grid Size: 5 ft
  - Background: Parchment
- User draws on map, then dismisses Map Wizard
- User reopens the same map draft
- **Settings are reset to defaults:**
  - Snap to Grid: OFF (or default state)
  - Grid Type: Reset
  - Grid Size: Reset
  - Background: White (instead of Parchment)

**Expected Behavior:**
- All interior map drawing settings should persist with the draft
- When user reopens a draft, settings should restore exactly as configured
- Settings should be specific to each map draft (not global app settings)
- Cross-platform persistence via CloudKit (settings sync between devices)

**Affected Settings:**
1. **Snap to Grid** (toggle) - Reverts to default
2. **Grid Type** (Square/Hex) - Not remembered
3. **Grid Size** (1 ft, 5 ft, 10 ft, Custom) - Not remembered
4. **Background Color** (White, Dark, Parchment, Gray) - Reverts to White

**Impact:**
- User frustration - must reconfigure settings on every session
- Workflow interruption - breaks creative flow
- Inconsistent experience - exterior map settings may persist differently
- Particularly annoying for long-term projects with specific grid requirements

**Steps to Reproduce:**
1. Open Map Wizard → Interior/Architectural tab
2. Create new interior map or load existing draft
3. Configure settings:
   - Toggle "Snap to Grid" ON
   - Set Grid Type to "Square"
   - Set Grid Size to "5 ft"
   - Set Background to "Parchment"
4. Draw some strokes on the canvas
5. Close Map Wizard (or save draft and quit app)
6. Reopen the same map draft
7. **Observe**: Settings have reverted to defaults

**Expected Fix:**

1. **Persist settings in draft data**:
   - Add properties to `Card.draftMapWorkData` or create dedicated settings object
   - Store: `snapToGrid`, `gridType`, `gridSize`, `gridSpacing`, `backgroundColor`
   - Encode/decode with other draft data

2. **Restore settings on draft load**:
   - When loading draft in MapWizardView, extract settings from persisted data
   - Set `@State` variables to match saved settings
   - Apply settings to canvas (grid overlay, snapping behavior, background)

3. **Save settings on change**:
   - Update persisted data when user changes any setting
   - Use auto-save mechanism (similar to stroke persistence)
   - Ensure settings saved before view dismissal

4. **Cross-platform compatibility**:
   - Settings should sync via CloudKit with draft data
   - Verify Codable conformance for all setting types
   - Test on iOS and macOS

**Files Likely Affected:**
- `Cumberland/MapWizardView.swift` - Settings state management, persistence hooks
- `Cumberland/Model/Card.swift` - Draft data structure (may need new properties)
- `Cumberland/DrawCanvas/DrawingCanvasView.swift` - May need to expose settings to persistence layer
- `Cumberland/DrawCanvas/DrawingCanvasModel.swift` - Settings storage in canvas model

**Possible Implementation:**

**Option 1: Extend Draft Map Work Data**
```swift
struct DraftMapWorkData: Codable {
    var layerManagerData: Data?
    var canvasSize: CGSize?
    // NEW: Interior settings
    var snapToGrid: Bool?
    var gridType: String? // "square" or "hex"
    var gridSpacing: Double? // 1.0, 5.0, 10.0, etc.
    var backgroundColor: String? // "white", "parchment", etc.
}
```

**Option 2: Dedicated Settings Object**
```swift
struct InteriorMapSettings: Codable {
    var snapToGrid: Bool = false
    var showGrid: Bool = true
    var gridType: GridType = .square
    var gridSpacing: Double = 5.0
    var gridUnits: String = "ft"
    var backgroundColor: String = "white"
}

// In DraftMapWorkData:
var interiorSettings: InteriorMapSettings?
```

**Notes:**
- This affects user experience significantly for users working on detailed floor plans or dungeon maps
- Snap to grid is particularly important for architectural accuracy
- Background color affects mood and readability (parchment is popular for fantasy maps)
- May be related to how exterior map settings are (or aren't) persisted
- Consider whether these should be per-draft or global app preferences with per-draft overrides

**Related Issues:**
- May be same issue for exterior maps (need to verify if exterior settings persist)
- Grid overlay rendering may also need to respect persisted settings


## DR-0039: Saved Strokes/Settings Failed to Restore During Drawing Canvas Restoration

**Status:** 🔴 Open
**Platform:** macOS (likely affects all platforms)
**Component:** DrawCanvas / Draft Persistence / LayerManager
**Severity:** High
**Date Identified:** 2026-01-11

**Description:**

When restoring a draft interior/architectural map, the saved drawing strokes are not being properly decoded and restored. The draft restoration process shows that stroke data exists (LayerManager with 2 layers is decoded) but the strokes themselves are lost during the import process, resulting in a blank canvas.

**Console Log Evidence:**
```
Restoring draft work for method: Interior / Architectural
[IMPORT] Decoding LayerManager from 729 bytes
[IMPORT] Restored LayerManager with 2 layers
[IMPORT] LayerManager has no content for this platform - falling back to legacy import
[DR-0004.3] importDrawingData called with 2 bytes
[DR-0004.3] Successfully decoded 0 strokes into model
[DR-0012] macOS - Created PKInkingTool with width: 5.0
✅ Restored drawing canvas state
📍 Restored to step: Configure
✅ Draft restoration complete - currentStep: Configure, method: Interior / Architectural
[DR-0004.3] makeNSView called, model has 0 strokes
```

**Key Observations from Logs:**
1. LayerManager decodes successfully (729 bytes → 2 layers)
2. Error message: "LayerManager has no content for this platform"
3. Falls back to "legacy import"
4. Legacy import receives only **2 bytes** of drawing data
5. Result: **0 strokes** successfully decoded
6. Canvas displays blank despite having saved work

**Steps to Reproduce:**
1. Create a new interior/architectural map in Map Wizard
2. Configure settings (grid, background, etc.)
3. Draw several strokes with interior brushes (walls, furniture, etc.)
4. Save/close the map draft (or quit app)
5. Reopen the same draft
6. **Observe**: Canvas is blank, all strokes are gone

**Expected Behavior:**
- All saved strokes should restore correctly
- LayerManager content should be compatible across platforms
- Drawing data should decode completely (not just 2 bytes)
- Canvas should display all previously drawn strokes

**Actual Behavior:**
- LayerManager reports "no content for this platform"
- Falls back to legacy import which receives minimal data (2 bytes)
- Decoding results in 0 strokes
- User loses all their work

**Root Cause Hypotheses:**

**1. Platform-Specific LayerManager Data**
- LayerManager may be saving data in a platform-specific format
- macOS restoration can't read data saved on macOS (self-incompatibility)
- The "no content for this platform" message suggests platform detection logic issue

**2. Drawing Data Encoding Issue**
- Strokes are being saved to LayerManager but not to the legacy format
- Legacy import path expects drawing data in different location/format
- Only 2 bytes being passed suggests data is truncated or pointer/size issue

**3. Codable/Data Corruption**
- LayerManager decodes (729 bytes) but stroke data within is corrupted
- DrawingStroke array may not be properly encoded/decoded
- CloudKit sync could be corrupting binary data

**Files Likely Affected:**
- `Cumberland/DrawCanvas/DrawingCanvasView.swift` - Draft save/restore logic
- `Cumberland/DrawCanvas/DrawingCanvasViewMacOS.swift` - macOS-specific import
- `Cumberland/DrawCanvas/LayerManager.swift` - Layer persistence, platform detection
- `Cumberland/DrawCanvas/DrawingLayer.swift` - DrawingStroke Codable implementation
- `Cumberland/MapWizardView.swift` - Draft orchestration

**Investigation Needed:**

**1. Check LayerManager Platform Logic:**
```swift
// Where is "no content for this platform" message generated?
// What determines platform compatibility?
// Is macOS data being marked as iOS-only or vice versa?
```

**2. Check Drawing Data Export:**
```swift
// In LayerManager or DrawingCanvasView, where is drawing data exported?
// Why are only 2 bytes being passed to legacy import?
// Should legacy import even be used when LayerManager decodes successfully?
```

**3. Check DrawingStroke Encoding:**
```swift
// Verify DrawingStroke.encode() is saving all fields including brushID
// Verify array encoding isn't being truncated
// Check if Optional fields are causing decode failures
```

**4. Check Platform Macro Logic:**
```swift
// Search for #if os(macOS) / #if os(iOS) that might affect persistence
// Ensure macOS can read macOS-saved data (not just cross-platform)
```

**Workarounds:**
- None currently - users lose work when closing/reopening drafts

**Impact:**
- **Critical workflow blocker** - users cannot save work
- Affects all interior map drawing (likely affects exterior maps too)
- Data loss issue - user work disappears
- Prevents iterative map creation over multiple sessions

**Priority:** HIGH - This is a data loss bug that prevents basic app functionality

---

## Template for Adding New DRs

When a new issue is identified or resolved but not yet verified, add it here using this template:

```markdown
## DR-XXXX: [Brief Title]

**Status:** 🟡 Resolved - Not Verified
**Platform:** iOS / macOS / visionOS / All platforms
**Component:** [Component Name]
**Severity:** Critical / High / Medium / Low
**Date Identified:** YYYY-MM-DD
**Date Resolved:** YYYY-MM-DD

**Description:**
[Detailed description of the issue]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Fix Applied:**
[Description of the fix]

**Test Steps:**
1. [How to verify the fix]
2. [Expected results]

---
```

## Status Indicators

Per DR-GUIDELINES.md:
- 🔴 **Identified - Not Resolved** - Issue found and root cause analyzed, awaiting fix
- 🟡 **Resolved - Not Verified** - Claude can mark when implementation is complete
- ✅ **Resolved - Verified** - Only USER can mark after testing

---

*When user verifies a DR, move it to the appropriate DR-verified-XXXX-YYYY.md file*
