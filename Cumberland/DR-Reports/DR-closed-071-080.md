# Discrepancy Reports (DR) - Closed Issues (DR-0071 to DR-0080)

This file contains closed DRs that will not be verified. These issues were either resolved and verified, or closed for other reasons (external limitations, design changes, superseded by other work).

**Total Closed DRs in this batch:** 3
- DR-0071: ⚪ Closed - Will be addressed by ER-0021
- DR-0072: ✅ Verified - Closed
- DR-0073: ✅ Verified - Closed

---

## DR-0073: VisualElementReviewView Sheet Does Not Resize When Advanced Options Expanded

**Status:** ✅ Verified - Closed
**Date Reported:** 2026-02-04
**Date Resolved:** 2026-02-04
**Platform:** macOS (likely affects iOS/visionOS as well)
**Component:** ER-0021, VisualElementReviewView, UI Layout
**Severity:** Medium
**Related:** ER-0021 (AI-Powered Visual Element Extraction)

**Description:**

When user clicks "Show Advanced Options" in the VisualElementReviewView sheet, the advanced cinematic framing controls appear, but the sheet does not resize to accommodate the additional content. This causes the interface to become clipped at the original portrait size, making the bottom controls inaccessible.

**Steps to Reproduce:**
1. Create a character card with description (e.g., Captain Evilin Drake)
2. Click "Generate Image" → "Extract & Review"
3. VisualElementReviewView sheet appears with extracted elements
4. Click "Show Advanced Options" button
5. Advanced options (Camera Angle, Framing, Lighting Style pickers) appear
6. **BUG:** Sheet does not resize, content becomes clipped

**Expected Behavior:**
- Sheet should dynamically resize when advanced options are shown
- All controls should remain accessible
- User should be able to scroll or view all content without clipping

**Actual Behavior:**
- Sheet maintains original height
- Advanced options render but are clipped
- Bottom controls (Preview, Generate button) become inaccessible

**Root Cause:**
- Sheet uses fixed frame size: `.frame(minWidth: 600, minHeight: 500)`
- SwiftUI sheets do not automatically resize when content changes
- `ScrollView` wraps content but sheet frame is fixed

**Resolution:**

**Phase 1 Fix (Failed - Frame Only):**
Initial attempt only modified frame sizing (minHeight 500 → 700) but didn't address sheet presentation behavior.

**Phase 2 Fix (Failed - Misunderstood Problem):**
Attempted to use `.presentationSizing()` modifiers to resize sheet - but sheets are modal and cannot be resized by user.

**Phase 3 Fix (Current - Layout Redesign):**
Re-laid out advanced options to fit in standard modal sheet:
1. **Changed picker style**: `.segmented` → `.menu` (dropdown menus are more compact)
2. **Horizontal layout**: Labels on left (180pt width), pickers on right
3. **Removed incorrect modifiers**: Removed `.presentationSizing()` and `.presentationContentInteraction()`
4. **Standard sheet size**: 600pt min width, 650pt min height fits all content
5. Menu pickers accommodate any label length without horizontal overflow

**Root Cause:**
- Segmented pickers with 4-5 options and long labels ("Low Angle Looking Up", etc.) were too wide for standard sheet
- User cannot resize modal sheets - need to fit content to sheet, not sheet to content
- Menu-style pickers solve this by using vertical dropdown space instead of horizontal width

**Files Modified:**
- `Cumberland/AI/VisualElementReviewView.swift:90-92` - Simplified frame sizing
- `Cumberland/AI/VisualElementReviewView.swift:715-773` - Changed cinematicFramingView to use menu pickers with horizontal layout

**Verification Steps:**
1. Open VisualElementReviewView with any card description
2. Click "Show Advanced Options"
3. Verify all controls remain visible and accessible
4. Verify sheet height accommodates all content
5. Test on macOS, iOS, and visionOS if possible

---

## DR-0072: Visual Element Extraction Returns Full Sentences Instead of Targeted Phrases

**Status:** ✅ Verified - Closed
**Date Reported:** 2026-02-04
**Date Resolved:** 2026-02-04
**Platform:** All platforms
**Component:** ER-0021, VisualElementExtractor, Text Parsing
**Severity:** High
**Related:** ER-0021 (AI-Powered Visual Element Extraction)

**Description:**

The `extractPhrase()` method in `VisualElementExtractor` returns entire sentences containing keywords instead of extracting just the relevant visual phrases. This causes severe duplication in the generated prompt.

**Example:**

For character description:
```
Captain Evie Drake is a tall, piratical woman with long straight dark hair
that she wears in a ponytail while flying.
```

**Current Behavior:**
- Physical Build: "Captain Evie Drake is a tall, piratical woman with long straight dark hair that she wears in a ponytail while flying"
- Hair: "Captain Evie Drake is a tall, piratical woman with long straight dark hair that she wears in a ponytail while flying"

**Result:** The SAME sentence appears in multiple categories, causing massive duplication in the generated prompt.

**Expected Behavior:**
- Physical Build: "tall, piratical woman"
- Hair: "long straight dark hair in ponytail"

Each category should contain ONLY the relevant visual phrase, not the entire sentence.

**Root Cause:**

The `extractPhrase()` method at `VisualElementExtractor.swift:416` returns the entire sentence containing the keyword:
```swift
private func extractPhrase(from text: String, containing keywords: [String]) -> String? {
    let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
    for sentence in sentences {
        for keyword in keywords {
            if sentence.lowercased().contains(keyword.lowercased()) {
                return sentence.trimmingCharacters(in: .whitespacesAndNewlines) // ❌ Returns full sentence
            }
        }
    }
    return nil
}
```

**Resolution:**

Rewrote `extractPhrase()` and added `extractTargetedPhrase()` with layered extraction strategy:

**Phase 1 Fix (Too Aggressive - Revised):**
Initial fix used only specific pattern matching which missed important details:
- Lost "strong chin, short nose" in facial features (no pattern match)
- Lost "orange jumpsuit" in clothing (no "wearing" keyword)

**Phase 2 Fix (Too Aggressive - Issues Found):**
Initial fallback had issues:
- Eyes: Included "nose, bright green eyes" instead of just "bright green eyes"
- Facial features: Returned blank instead of "strong chin, short nose"

**Phase 3 Fix (Partial - Issues Found):**
Fixed boundary detection and comma-separated list handling but facial features still blank.

**Phase 4 Fix (Current - Missing Extraction Logic):**
Root cause identified: Facial features extraction code was missing entirely!

1. **Eyes Pattern** (refined):
   - Find last comma before "eyes" to isolate eye description
   - Extract 2-3 words after comma: "bright green eyes" ✓

2. **Fallback Extraction** (refined for comma-separated lists):
   - Recognizes comma-separated lists for "strong chin, short nose"
   - Includes up to 2 items in list (8 words max)
   - Stops at clause boundaries ("that", "which", "while")

3. **Facial Features Extraction** (NEWLY ADDED):
   - Added missing extraction logic for facial features
   - Searches for keywords: "chin", "nose", "cheek", "jaw", "brow", "forehead", "lips", "mouth", "face"
   - Uses fallback extraction to capture comma-separated lists
   - Example: "strong chin, short nose" now extracted correctly ✓

**Root Cause:**
The extraction method had prompts telling AI about facial features but no heuristic code to actually extract them from the text. Physical build, hair, eyes, and clothing were extracted but facial features, skin tone, accessories, and pose were never implemented.

**Files Modified:**
- `Cumberland/AI/VisualElementExtractor.swift:363-373` - Added facial features extraction logic
- `Cumberland/AI/VisualElementExtractor.swift:624-730` - Refined eyes pattern and fallback list detection

**Verification Steps:**
1. Create character: "Captain Evie Drake is a tall, piratical woman with strong chin, short nose, long straight dark hair that she wears in a ponytail while flying. She wears an orange jumpsuit."
2. Click "Extract & Review"
3. Verify Physical Build: "tall, piratical woman" (NOT full sentence)
4. Verify Facial Features: "strong chin, short nose" (NOT blank, NOT full sentence)
5. Verify Hair: "long straight dark hair" (NOT full sentence with "while flying")
6. Verify Clothing: "orange jumpsuit" (NOT blank)
7. Verify no duplication across categories
8. Check generated prompt has no repeated phrases
9. Test with various character descriptions

---

## DR-0071: Apple Image Playground Requires Person Selection, Unsuitable for Non-Portrait Generation

**Status:** ⚪ Closed - Will be addressed by ER-0021
**Date Closed:** 2026-02-03
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

**Reason for Closure:**
This issue will be addressed by ER-0021 Phase 4 (Apple Intelligence Multiple Concepts Fix). The fix sends multiple short concepts instead of one long prompt, which aligns better with Image Playground's expected format. While person selection may still be required by Apple's UI, the concept-based approach should improve compatibility. Closed as "Will be addressed by ER-0021."

---
