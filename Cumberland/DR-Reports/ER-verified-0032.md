# Enhancement Requests (ER) — Verified Batch 32

---

## ER-0032: Add Search and Multi-Filter to Backlog Sidebar

**Status:** ✅ Implemented - Verified
**Component:** MurderBoard — Backlog Sidebar (`SidebarPanel.swift`, `MurderBoardView.swift`, `InvestigationSidebarPanel.swift`, `InvestigationBoardView.swift`)
**Priority:** P1
**Date Requested:** 2026-02-17
**Date Revised:** 2026-02-18
**Date Implemented:** 2026-02-20
**Date Verified:** 2026-02-20
**Depends On:** ER-0031

**Rationale:**
The backlog sidebar currently supports only single-kind filtering via a dropdown menu. For boards with many cards, users need text search and combinable filters to find relevant cards quickly.

**Desired Behavior:**
Users can search backlog cards by text, combine kind filter with text search, and sort by different criteria. Selection uses standard platform metaphor (click, cmd+click, shift+click on macOS).

**Requirements:**
1. **Text search**: Search-as-you-type filtering on card name, subtitle, and detailedText. Use the existing `Card.normalizedSearchText` field for matching.
2. **Combined filters**: Kind filter + text search applied simultaneously. The existing kind dropdown remains; text search is additive.
3. **Sort options**: Name (A-Z, current default), Name (Z-A), Kind grouping.
4. **Debounce**: 250ms debounce on text input to avoid excessive re-filtering.
5. **Persist filters per board**: When ER-0034 lands, filter state should scope to the active board. Until then, persist globally via `@AppStorage`.
6. **Standard selection**: Click selects one, cmd+click toggles, shift+click range-selects (macOS). Click on selected deselects all.
7. **Both apps**: Features implemented in both Cumberland and MurderBoard standalone.

**Components Affected:**
- `Cumberland/SidebarPanel.swift` — search TextField, sort picker, standard selection metaphor, `onModifierTap` modifier
- `Cumberland/Murderboard/MurderBoardView.swift` — search/sort state, backlogCards filter, body refactoring
- `MurderBoard/Views/InvestigationSidebarPanel.swift` — search TextField, sort picker, standard selection metaphor, `onModifierTap` modifier
- `MurderBoard/Views/InvestigationBoardView.swift` — search/sort state, backlogNodes filter

**Implementation Details:**

### Cumberland App
- **`BacklogSortOption` enum** defined in `MurderBoardView.swift` with cases `.nameAscending`, `.nameDescending`, `.kindGrouped`.
- **`SidebarPanel`** receives `@Binding var searchText`, `@Binding var sortOption`, and `let hasActiveSearch: Bool`.
- **Search TextField** in `sidebarHeader()` with magnifying glass icon, "Search cards..." placeholder, and clear button.
- **Sort Menu** beside the kind filter dropdown with checkmark on active option.
- **`backlogCards`** delegates to `applySearchFilter(to:)` and `applySortOption(to:)` helper functions.
- **Debounce** via `.onChange(of: backlogSearchText)` with 250ms `Task.sleep`.
- **Body refactored** into `boardContent` and `boardWithStateHandlers` to avoid type-checker timeouts.

### MurderBoard Standalone App
- **`InvestigationBacklogSortOption` enum** with `.nameAscending`, `.nameDescending`, `.categoryGrouped`.
- **In-memory search** normalizes `name + subtitle` inline (no `normalizedSearchText` field on `InvestigationNode`).
- Same search/sort/debounce pattern as Cumberland.

### Standard Selection Metaphor (Both Apps)
- **Removed**: Checkbox circles from MurderBoard rows, long-press-to-select from Cumberland rows.
- **macOS**: Click selects one (click on selected deselects all), Cmd+Click toggles individual, Shift+Click range-selects.
- **iOS/visionOS**: Tap selects one, tap on selected deselects all.
- **`onModifierTap`** view modifier using `NSViewRepresentable` on macOS with `super.mouseDown()` pass-through for drag support.
- **Info button** (i) added to Cumberland `SidebarCardRow` for detail sheet access.

---

*Verified: 2026-02-20*
