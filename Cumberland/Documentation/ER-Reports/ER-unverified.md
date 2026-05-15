# Enhancement Requests (ER) — Unverified

- Guidelines: [Cumberland/Documentation/ER-Reports/ER-Guidelines.md]

**Purpose:** This file contains enhancement requests that have been completed and are awaiting verification. These are features we have most recently implemented and require testing/verification.

**Status:** Currently **2 complete unverified ERs**

---

## ER-0060: Implement Decorative Backplate Images Throughout App

**Status:** 🟡 Implemented - Not Verified
**Component:** UI/UX / Theming System
**Priority:** Medium (visual enhancement)
**Date Requested:** 2026-04-23
**Date Started:** 2026-04-23
**Date Implemented:** 2026-04-23
**Requested By:** User
**Implemented By:** Claude

### Rationale

Enhance visual appeal and thematic richness of Cumberland by integrating decorative backplate images in appropriate locations throughout the app. Backplates should reinforce thematic context (writing, worldbuilding) while maintaining readability and not distracting from primary content.

### Current State

- Backplate assets already exist in `Assets.xcassets/Backplates/`
- Organization: `Backplates/{Theme}/{Mode}/{Item}.imageset`
- **Themes**: Default, Halloween, Purple, Whimsical
- **Modes**: Light, Dark (theme-aware variants)
- **Items**: Castle, Cat, Codex, Couple, Key, Lines, Pen, Sextant, Ship, Sword, Tree, Watch
- **Aspect Ratio**: 4:1 (width:height) - wide, horizontal images
- Currently **not implemented** anywhere in the app

### Desired Behavior

Backplates should appear as subtle, themed decorative backgrounds in strategic locations:
- Low opacity (3-25% depending on context)
- Theme-aware (reads from ThemeManager)
- Respect light/dark mode
- Do not interfere with text readability or interactive elements
- Enhance thematic immersion

### Requirements

1. ✅ Create `BackplateManager` utility to handle backplate loading and theme-awareness
2. ✅ Support current theme + mode selection (Default/Halloween/Purple/Whimsical × Light/Dark)
3. ✅ Implement opacity controls appropriate to each context
4. ✅ Apply backplates to approved locations (see Design Approach)
5. ✅ Ensure accessibility - backplates must not reduce contrast below WCAG standards
6. ✅ Support dynamic theme switching (backplates update when theme changes)

### Design Approach - Placement Decisions

**✅ USER APPROVED - READY FOR IMPLEMENTATION**

#### 1. Project Writer - Manuscript View
**APPROVED:** **Option A - PEN at top behind chapter tabs**
- Placement: Behind chapter tab strip at top of manuscript view
- Opacity: 12-15%
- Rationale: Reinforces writing context, visible but not distracting from tabs

---

#### 2. Project Writer - Dashboard View
**APPROVED:** **SEXTANT in project header**

- Backplate: SEXTANT (navigation/exploration theme)
- Placement: Project header area (top section with project title/metadata)
- Opacity: 10-15%
- Rationale: Wide 4:1 aspect ratio fits horizontal header perfectly, navigation theme fits worldbuilding context, provides visual anchor without interfering with status glyph area

---

#### 3. Empty States (No Content)
**APPROVED:** Kind-specific backplates at 15-25% opacity

**Complete Kind → Backplate Mappings:**
- **No Projects:** PEN
- **No Worlds:** TREE
- **No Characters:** CAT
- **No Chapters:** PEN
- **No Scenes:** PEN
- **No Timelines:** WATCH
- **No Calendars:** WATCH
- **No Maps:** SHIP
- **No Locations:** CASTLE
- **No Buildings:** CASTLE
- **No Vehicles:** SHIP
- **No Artifacts:** SWORD
- **No Chronicles:** CODEX
- **No Rules:** CODEX
- **No Sources:** CODEX
- **No Structure:** CODEX

---

#### 4. Additional Placements
**APPROVED:**

**Structure Selection Sheet:**
- Backplate: CODEX
- Placement: Behind structure list
- Opacity: 8-12%

**Map Wizard:**
- Backplate: SHIP
- Placement: Behind wizard steps
- Opacity: 10-15%

**Settings/Preferences:**
- Backplate: KEY
- Placement: Behind settings panels
- Opacity: 8-12%

---

### Components Affected

**New Files to Create:**
- `Cumberland/Utilities/BackplateManager.swift` - Centralized backplate loading and theme integration
- `Cumberland/Views/Shared/BackplateView.swift` - Reusable SwiftUI view component

**Files to Modify:**
- `Cumberland/ProjectWriter/ManuscriptWritingSurfaceView.swift` - Add backplate to manuscript view
- `Cumberland/ProjectWriter/ProjectDashboardView.swift` - Add backplate to project header
- `Cumberland/Views/EmptyStateView.swift` (or create if doesn't exist) - Add kind-specific backplates
- Additional files based on approved optional placements

### Implementation Plan (Once Approved)

**Phase 1: Infrastructure**
1. Create `BackplateManager` with theme-aware loading
2. Create `BackplateView` reusable component
3. Add opacity and positioning controls

**Phase 2: Core Placements**
1. Implement Manuscript View backplate (PEN or LINES)
2. Implement Dashboard header backplate (WATCH/SEXTANT/CODEX)
3. Implement empty state backplates with kind mapping

**Phase 3: Optional Enhancements**
1. Structure Sheet backplate (if approved)
2. Map Wizard backplate (if approved)
3. Settings backplate (if approved)

**Phase 4: Polish**
1. Verify accessibility (contrast ratios)
2. Test dynamic theme switching
3. Ensure smooth transitions
4. Verify light/dark mode variants

### Technical Considerations

**BackplateManager Design:**
```swift
class BackplateManager: ObservableObject {
    static let shared = BackplateManager()

    enum BackplateItem: String, CaseIterable {
        case castle, cat, codex, couple, key, lines, pen, sextant, ship, sword, tree, watch
    }

    func loadBackplate(item: BackplateItem, theme: ThemeName, mode: ColorScheme) -> Image?
    func backplateForKind(_ kind: Kinds) -> BackplateItem?
}
```

**BackplateView Design:**
```swift
struct BackplateView: View {
    let item: BackplateManager.BackplateItem
    let opacity: Double
    @Environment(ThemeManager.self) var themeManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        // Load and display backplate with theme awareness
    }
}
```

### Accessibility Considerations

- Backplate opacity must preserve text contrast ratios (WCAG AA: 4.5:1 for normal text)
- Users with motion sensitivity: No animated backplates
- Backplates are purely decorative (no semantic meaning)
- All interactive elements must maintain sufficient contrast

### Test Steps (Once Implemented)

**Theme Awareness:**
1. Open Manuscript View with Default theme
2. Verify backplate appears with correct theme variant
3. Switch to Halloween theme
4. Verify backplate updates to Halloween variant
5. Test all four themes (Default, Halloween, Purple, Whimsical)

**Light/Dark Mode:**
1. Switch app to Dark Mode
2. Verify backplate uses dark mode variant
3. Switch to Light Mode
4. Verify backplate uses light mode variant
5. Test "System" preference (auto dark mode at night)

**Empty States:**
1. Create new project with no characters
2. Navigate to Characters view
3. Verify appropriate backplate appears in empty state (COUPLE or CAT)
4. Repeat for each kind

**Opacity and Readability:**
1. Verify all text remains readable over backplates
2. Test with various theme colors
3. Ensure interactive elements are clearly visible
4. Check contrast ratios with accessibility tools

### Implementation Details

**Files Created:**
- `Cumberland/BackplateEnum.swift` (lines 1-137) - Extended existing structure with complete functionality:
  - Added all 12 SubjectType cases
  - Implemented `getImage()` methods with theme and color scheme support
  - Added `subjectForKind()` mapping for all 16 Card kinds
  - Added `themeTypeFromThemeManager()` for theme integration

- `Cumberland/Views/Shared/BackplateView.swift` (lines 1-111) - Reusable SwiftUI component:
  - Theme-aware backplate display using BackplateEnum
  - Automatic light/dark mode switching
  - Convenience modifiers: `.backplate()` and `.emptyStateBackplate()`
  - Integrated with ThemeManager via @EnvironmentObject

**Files Modified:**

1. **ManuscriptWritingSurfaceView.swift** (line 373-386):
   - Added PEN backplate behind chapter tab strip
   - Opacity: 13% with 95% surface color overlay
   - Integrated with ZStack for layered effect

2. **ProjectDashboardView.swift** (lines 89-130):
   - Added SEXTANT backplate to project header
   - Opacity: 12%
   - Wrapped header in container with backplate background

3. **ContentPlaceholderView.swift** (lines 13, 69-87):
   - Added `kind: Kinds?` parameter for empty states
   - Integrated BackplateView based on kind
   - Conditional display: backplates for empty states, theme images otherwise

4. **MainAppView.swift** (line 1256):
   - Pass `selectedKind` to ContentPlaceholderView
   - Enables kind-appropriate backplates for all empty states

5. **StructureSelectionSheet.swift** (lines 150-164):
   - Added CODEX backplate behind structure template list
   - Opacity: 10% with 85% surface overlay
   - Applied to List background via ZStack

6. **MapWizardView.swift** (lines 220-226):
   - Added SHIP backplate to method selection step
   - Opacity: 12%
   - Conditional display only on .selectMethod step

7. **SettingsView.swift** (lines 148-195):
   - Added KEY backplate to all settings panels
   - Opacity: 10%
   - Applied to detail pane background

**Integration Points:**
- All backplates read from existing asset catalog: `Assets.xcassets/Backplates/`
- Theme-aware via ThemeManager.currentTheme.id
- Color scheme responsive via @Environment(\.colorScheme)
- No new assets needed - fully integrated with existing structure

### Notes

- Backplates are 4:1 aspect ratio - best suited for horizontal/wide spaces
- Opacity levels carefully tuned per context (8-20%) for readability
- All backplates tested with Dark/Light mode switching
- Theme switching support built-in via BackplateEnum
- Build successful - no compilation errors
- **Ready for user verification and testing**

---

## ER-0059: Distinguish Add Chapter/Add Scene Buttons with Kind-Specific Icons

**Status:** 🟢 Implemented - Not Verified
**Component:** Project Writer / Manuscript View
**Priority:** Medium (UX improvement)
**Date Requested:** 2026-04-23
**Date Implemented:** 2026-04-23
**Implemented By:** Claude

### Request

Both "Add Chapter" and "Add Scene" buttons appeared on the Manuscript View simultaneously using the same generic "+" icon, making them difficult to distinguish at a glance.

### Solution

Replaced generic "+" icon with **kind-specific icons plus badge overlay**:

**Add Chapter Button** (`ManuscriptWritingSurfaceView.swift:355-366`):
```swift
ZStack(alignment: .topTrailing) {
    Image(systemName: "text.book.closed")  // Chapter icon
        .font(.system(size: 14))
    Image(systemName: "plus.circle.fill")  // Plus badge
        .font(.system(size: 10))
        .offset(x: 4, y: -4)
}
```

**Add Scene Button** (`ManuscriptWritingSurfaceView.swift:677-688`):
```swift
ZStack(alignment: .topTrailing) {
    Image(systemName: "film")              // Scene icon
        .font(.system(size: 14))
    Image(systemName: "plus.circle.fill")  // Plus badge
        .font(.system(size: 10))
        .offset(x: 4, y: -4)
}
```

### Visual Design

- Base icon uses established kind icons from `Kinds.systemImage`:
  - **Chapter**: `"text.book.closed"` (book icon)
  - **Scene**: `"film"` (film strip icon)
- Small `"plus.circle.fill"` badge positioned at top-right corner
- Badge offset (+4, -4) creates clear overlay without obscuring base icon
- Both use themed text color for consistency

### Benefits

✅ Immediate visual distinction between Chapter and Scene creation
✅ Reinforces kind identity (same icons used throughout app)
✅ Plus badge clearly indicates "add/create" action
✅ Compact design fits in existing button space
✅ Consistent with iOS/macOS design patterns

### Files Changed

- `Cumberland/ProjectWriter/ManuscriptWritingSurfaceView.swift` (lines 355-366, 677-688)

### Verification Steps

1. Open a Project in Manuscript view
2. Locate the Chapter tab strip at the top
3. Verify "Add Chapter" button shows book icon with plus badge
4. Scroll to bottom of manuscript
5. Verify "Add Scene" button shows film icon with plus badge
6. Confirm both buttons are easily distinguishable
7. Test creating a chapter and scene to verify buttons work correctly

---

## Recently Verified

- **ER-0037:** Theming System — Multi-Color Themes, Background Images & User-Defined Themes — ✅ Verified 2026-03-03 -> [ER-verified-0037.md](./ER-verified-0037.md)
- **ER-0039:** Cross-Platform Feasibility — Windows — ✅ Verified 2026-02-24 -> [ER-verified-0039.md](./ER-verified-0039.md)
- **ER-0040:** Cross-Platform Feasibility — Linux — ✅ Verified 2026-02-24 -> [ER-verified-0040.md](./ER-verified-0040.md)
- **ER-0041:** Cross-Platform Feasibility — Android — ✅ Verified 2026-02-24 -> [ER-verified-0041.md](./ER-verified-0041.md)
- **ER-0038:** Localization Infrastructure — ✅ Verified 2026-02-23 -> [ER-verified-0038.md](./ER-verified-0038.md)
- **ER-0036:** Edge Count Sentinel — Live Desync Detection and Recovery — ✅ Verified 2026-02-22 -> [ER-verified-0036.md](./ER-verified-0036.md)
- **ER-0035:** Relationship Diagnostic Tools and Safety Guards — ✅ Verified 2026-02-21 -> [ER-verified-0035.md](./ER-verified-0035.md)
- **ER-0032:** Add Search and Multi-Filter to Backlog Sidebar — ✅ Verified 2026-02-20 -> [ER-verified-0032.md](./ER-verified-0032.md)
- **ER-0031:** Enhance Existing Backlog Sidebar — ✅ Verified 2026-02-19 -> [ER-verified-0031.md](./ER-verified-0031.md)
- **ER-0033:** Wire Gesture Callbacks in MurderBoard App — ✅ Verified 2026-02-19 -> [ER-verified-0033.md](./ER-verified-0033.md)


*Last Updated: 2026-04-13*
