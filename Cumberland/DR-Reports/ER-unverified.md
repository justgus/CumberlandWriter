# Enhancement Requests (ER) — Unverified

- Guidelines: [Cumberland/DR-Reports/ER-Guidelines.md]

---

## ER-0032: Add Search and Multi-Filter to Backlog Sidebar

**Status:** 🔵 Proposed
**Component:** MurderBoard — Backlog Sidebar (`SidebarPanel.swift`, `MurderBoardView.swift`)
**Priority:** P1
**Date Requested:** 2026-02-17
**Date Revised:** 2026-02-18
**Depends On:** ER-0031

**Rationale:**
The backlog sidebar currently supports only single-kind filtering via a dropdown menu. For boards with many cards, users need text search and combinable filters to find relevant cards quickly.

**Current Behavior:**
- Single `selectedKindFilter: Kinds?` filters the `backlogCards` computed property (`MurderBoardView.swift:92-104`).
- No text search in the sidebar.
- Sort is alphabetical by name only (`MurderBoardView.swift:101-103`).
- Cumberland has an existing `SwiftDataSearchEngine` (`Cumberland/Search/SearchEngine.swift`) that performs case-insensitive, diacritic-insensitive search across `Card.normalizedSearchText` with ranked results by field (name > subtitle > details > author).
- `MainAppView.swift` uses a `TextField`-based search in card lists (not `.searchable`) with `allCardsKindFilter` dropdown.

**Desired Behavior:**
Users can search backlog cards by text, combine kind filter with text search, and sort by different criteria.

**Requirements:**
1. **Text search**: Search-as-you-type filtering on card name, subtitle, and detailedText. Use the existing `Card.normalizedSearchText` field for matching.
2. **Combined filters**: Kind filter + text search applied simultaneously. The existing kind dropdown remains; text search is additive.
3. **Sort options**: Name (A-Z, current default), Name (Z-A), Kind grouping.
4. **Debounce**: 250ms debounce on text input to avoid excessive re-filtering.
5. **Persist filters per board**: When ER-0034 lands, filter state should scope to the active board. Until then, persist globally via `@AppStorage`.

**Design Approach:**
- Add a `TextField` search bar to `SidebarPanel.sidebarHeader()`, following the pattern used in `MainAppView.swift` card lists. Avoid `.searchable` modifier since the sidebar is an overlay panel, not a `NavigationStack` destination.
- Extend `MurderBoardView.backlogCards` computed property to apply text filter against `card.normalizedSearchText.contains(normalizedQuery)`.
- Add a sort `Picker` or `Menu` beside the existing kind filter dropdown.
- Reuse `SwiftDataSearchEngine`'s normalization approach (`.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()`) for the query string.

**Components Affected:**
- `Cumberland/SidebarPanel.swift` — add search `TextField` to header, sort picker
- `Cumberland/Murderboard/MurderBoardView.swift` — extend `backlogCards` with text filter, add `@State var backlogSearchText: String`, add sort state
- No new files or types needed

**Implementation Details:**
- Add `@Binding var searchText: String` and `@Binding var sortOption: BacklogSortOption` to `SidebarPanel`.
- Define `BacklogSortOption` enum: `.nameAscending`, `.nameDescending`, `.kindGrouped`.
- In `MurderBoardView.backlogCards`, after kind filtering, apply: `filtered.filter { $0.normalizedSearchText.contains(normalizedQuery) }`, then sort by selected option.
- Debounce via `.onChange(of: searchText)` with `Task.sleep(for: .milliseconds(250))` and cancellation.
- Persist sort option: `@AppStorage("MurderBoard.backlogSort")`.
- Persist search text is intentionally NOT done (ephemeral per session).

**Test Steps:**
1. Type a search query in the sidebar; verify results filter to matching cards after ~250ms.
2. Combine kind filter + text search; verify both constraints apply.
3. Clear search text; verify full backlog returns.
4. Change sort option; verify order updates.
5. Relaunch app; verify sort option persists but search text resets.
6. Regression: verify drag-and-drop, swipe actions (ER-0031), and multi-select still work with active search/filter.

**Notes:**
- The existing `SwiftDataSearchEngine` is designed for the global search overlay and returns `SearchResult` objects. For the backlog sidebar, in-memory filtering on the already-queried `allCards` array is simpler and avoids a second database round-trip. The normalization logic should be shared but the search path is different.

---

## Recently Verified

- **ER-0031:** Enhance Existing Backlog Sidebar — ✅ Verified 2026-02-19 → [ER-verified-0031.md](./ER-verified-0031.md)
- **ER-0033:** Wire Gesture Callbacks in MurderBoard App — ✅ Verified 2026-02-19 → [ER-verified-0033.md](./ER-verified-0033.md)

---

*Last Updated: 2026-02-19*
