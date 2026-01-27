# Discrepancy Reports (DR) - Batch 5: DR-0041 to DR-0050

This file contains verified discrepancy reports DR-0041 through DR-0050.

**Batch Status:** 🚧 In Progress (1/10 verified)

---

## DR-0051: CardEditorView Fixed to Narrow Width on macOS Sheet - Doesn't Fill Available Space

**Status:** ✅ Verified
**Platform:** macOS
**Component:** CardEditorView
**Severity:** Medium
**Date Identified:** 2026-01-24
**Date Resolved:** 2026-01-25
**Date Verified:** 2026-01-25

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

- [x] CardEditorView expands to fill wider sheets
- [x] CardEditorView shrinks when sheet is made smaller
- [x] Minimum width preserved (520 points)
- [x] Maximum width reasonable for macOS (900 idealWidth, 1200 maxWidth)
- [x] Content is readable and well-spaced at all sizes
- [x] Works correctly on iOS/iPadOS (should not affect those platforms)

**User Impact:** Medium - Affects macOS usability and aesthetics, makes editor feel cramped

**Priority:** Medium - UI/UX improvement for macOS

**Workaround:** Users can work with narrow editor, but it's not optimal for macOS

**Resolution:**

The issue required two fixes: removing `.presentationSizing(.fitted)` from the sheet presentation AND setting `maxCardWidth` to `.infinity` in CardEditorView.

**Root Cause Analysis:**

The problem was a combination of:
1. **CardEditorView** had `maxCardWidth: 430` limiting content width
2. **MainAppView** sheet presentation used `.presentationSizing(.fitted)` which sized the sheet to fit the narrow content
3. Together, these created a narrow sheet that didn't fill available macOS screen space

**Changes Made:**

**File 1:** `Cumberland/CardEditorView.swift:156-168`

Changed from:
```swift
#if os(visionOS)
private let maxCardWidth: CGFloat = 640
#else
private let maxCardWidth: CGFloat = 430  // Too narrow for macOS
#endif
```

To:
```swift
#if os(macOS)
private let maxCardWidth: CGFloat = .infinity  // Fill available width on macOS (DR-0051)
#elseif os(visionOS)
private let maxCardWidth: CGFloat = 640
#else  // iOS/iPadOS
private let maxCardWidth: CGFloat = 430
#endif
```

**File 2:** `Cumberland/MainAppView.swift:212-220, 233-241`

Changed edit sheet from:
```swift
NavigationView {
    CardEditorView(mode: .edit(card: card) { ... })
}
.frame(minWidth: 760, minHeight: 720)
.presentationSizing(.fitted)  // ← THIS WAS THE MAIN PROBLEM
```

To:
```swift
NavigationStack {
    CardEditorView(mode: .edit(card: card) { ... })
}
.frame(minWidth: 760, idealWidth: 900, maxWidth: 1200, minHeight: 720)
// .presentationSizing(.fitted) REMOVED
```

Also updated create sheet similarly for consistency.

**Key Changes:**
1. **NavigationView → NavigationStack**: NavigationView is deprecated, NavigationStack is modern
2. **Removed `.presentationSizing(.fitted)`**: This was constraining sheet to content's intrinsic size
3. **Added `idealWidth` and `maxWidth`**: Provides good default size (900) with reasonable maximum (1200)
4. **Set `maxCardWidth = .infinity`**: Allows content to expand to fill available sheet width

**Effect:**
- Sheet opens at 900 points wide (idealWidth) instead of narrow 430
- Sheet is resizable from 760 to 1200 points
- CardEditorView content fills the sheet width dynamically
- Content expands/contracts as user resizes sheet
- iOS/iPadOS behavior unchanged (still uses 430 points max)
- visionOS behavior unchanged (still uses 640 points max)

**Build Status:** ✅ macOS build succeeds with zero errors

**Verification Steps:**

1. Open Cumberland on macOS
2. Edit or create a card (opens CardEditorView sheet)
3. Observe width - should be wider (~900 points default) instead of cramped at 430
4. Resize sheet by dragging corner
5. Content should expand/contract to fill available width (up to 1200 points)
6. Verify minimum width still enforced (760 points)
7. On iOS/iPadOS, verify width remains at 430 (no change)

---
