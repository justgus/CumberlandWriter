# Discrepancy Reports (DR) - Closed Issues (DR-0061 to DR-0070)

This file contains closed DRs that will not be verified. These issues were closed for reasons other than resolution (e.g., external limitations, design changes, superseded by other work).

**Total Closed DRs in this batch:** 1

---

## DR-0069: AI Provider Safety Filter False Positives on Character Names

**Status:** ⚪ Closed - Known Issue (External Limitation)
**Date Closed:** 2026-02-03
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

**Reason for Closure:**
External limitation in AI provider safety systems. Cannot be "fixed" in Cumberland code. Closed as "Known Issue" with workarounds documented. Future enhancements may improve handling (better error messages, multi-provider fallback), but the underlying limitation remains.

---
