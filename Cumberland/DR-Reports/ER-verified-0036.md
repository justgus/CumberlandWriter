# ER-0036: Edge Count Sentinel — Live Desync Detection and Recovery

**Status:** ✅ Verified
**Component:** Card Model / RelationshipManager / EdgeIntegrityMonitor / Views
**Priority:** Critical
**Date Requested:** 2026-02-21
**Date Implemented:** 2026-02-21
**Date Verified:** 2026-02-22
**Depends On:** DR-0098, ER-0035

**Rationale:**
ER-0035 provided developer diagnostic tools to detect SwiftData relationship array desynchronization after the fact. However, production users had no way to detect or recover from desync events. During ER-0035 testing, a live desync was observed on the "DC Metro Area" card (FetchDescriptor reported 41 out/41 in edges, but relationship arrays reported 0/0). The desync self-corrected on app relaunch, but if any code path had acted on the stale empty arrays during the desync window, data loss could have occurred (as in DR-0098).

ER-0036 adds a live sentinel system: cached edge counts on each Card maintained by a centralized RelationshipManager gateway, enabling runtime detection of desync events and automatic recovery via FetchDescriptor.

**Key Architectural Requirement:**
All relationship creates and deletes go through RelationshipManager. Increment/decrement logic lives in one place. All non-RelationshipManager creation and deletion paths were instrumented with sentinel calls.

**Requirements (all met):**
1. Card Model — `cachedOutgoingEdgeCount: Int = 0` and `cachedIncomingEdgeCount: Int = 0`
2. EdgeIntegrityMonitor service — `checkIntegrity`, `recover`, `recalculateCounts`, `incrementCounts`/`decrementCounts`
3. RelationshipManager as single edge gateway — increment/decrement in create/delete + `removeAllEdges(for:)`
4. Refactored edge creation paths — all instrumented with `incrementCounts`
5. Refactored edge deletion paths — all instrumented with `decrementCounts`
6. ServiceContainer registration — `edgeIntegrityMonitor` registered, `cardOperations.relationshipManager` wired
7. Banner UX — `DesyncBannerModifier` with auto-dismissing capsule
8. View consistency checks — CardRelationshipView, MurderBoardView, CumberlandBoardDataSource
9. One-time backfill — `backfillEdgeCountsIfNeeded(container:)` guarded by UserDefaults

**Implementation Details:**

All 9 requirements implemented across 10 phases plus additional fixes during verification:

1. **Card Model** — Added `cachedOutgoingEdgeCount` and `cachedIncomingEdgeCount` to `Card.swift`
2. **EdgeIntegrityMonitor** — New service (`Services/EdgeIntegrityMonitor.swift`, ~120 lines) with OSLog production logging
3. **RelationshipManager** — Increment/decrement in `createRelationship()`, `createReverseEdge()`, `removeRelationship()`, `removeEdge()`. New `removeAllEdges(for:)` bulk method.
4. **Edge creation paths refactored** — `CardRelationshipOperations`, `SuggestionEngine`, `MurderBoardView` fallback, `CumberlandApp` backfill, `FixIncompleteRelationshipsView`
5. **Edge deletion paths refactored** — `CardOperationManager.changeCardType()`, `Card.cleanupBeforeDeletion()`, `EdgeRepository`, `MurderBoardView.deleteEdgePairDirectly()`, `CardRelationshipOperations` fallbacks
6. **ServiceContainer** — Registered monitor, wired cross-references
7. **Banner UX** — `DesyncBannerModifier` (~45 lines)
8. **View consistency checks** — `.task(id:)` sentinel checks + desync-aware `CumberlandBoardDataSource.edges(for:)`
9. **Backfill** — One-time migration guarded by UserDefaults key

**Additional fixes during verification testing:**

10. **Reverse edge creation bug fix** — `ensureReverseEdge()` in both `CardRelationshipOperations` and `SuggestionEngine` used predicates without type filters, causing only the first reverse edge to be created between two cards. Fixed by adding `$0.type?.code == mirrorCode` filter.
11. **RelationshipAuditView cached count columns** — Added Out(C)/In(C) columns, "Recalculate Cached Counts" button, cached count mismatch stats in summary.
12. **Duplicate card detection and merge** — Added duplicate card detection (same name + same kind) to RelationshipAuditView with per-card and bulk delete with edge migration and content merge.
13. **Card deletion safety** — Fixed `cleanupBeforeDeletion()` to handle `calendarSystemRef` (cascade) and `calendarSystem` (nullify) relationships before deletion, preventing "Unexpected backing data for snapshot creation" crashes.
14. **CardRepository.delete() cleanup** — Added missing `cleanupBeforeDeletion()` calls to `CardRepository.delete()` single and batch methods.
15. **Audit view card deletion** — Changed from direct `modelContext.delete(card)` to `services.cardOperations.deleteCard()` to follow the CardOperationManager pattern.

**Verification Notes:**
- Cached counts (Out(C)/In(C)) remain stable and correct even when SwiftData relationship arrays desync
- DC Metro Area desync (41,41,0,0) confirmed: cached counts stayed at 41,41 while arrays showed 0,0 — sentinel architecture validated
- Desync self-corrects on fresh view load (SwiftData re-faults arrays), so banner doesn't fire for transient desyncs
- `CumberlandBoardDataSource.edges(for:)` fallback correctly catches desyncs during board rendering
- Reverse edge fix confirmed: adding 9 scenes now produces correct forward + reverse edge pairs
- Duplicate card deletion works correctly after CalendarSystem cleanup fix
- Build succeeds: `xcodebuild -scheme Cumberland-macOS`

**Files Created:**
- `Cumberland/Services/EdgeIntegrityMonitor.swift` — ~120 lines
- `Cumberland/Components/DesyncBannerModifier.swift` — ~45 lines

**Files Modified:**
- `Cumberland/Model/Card.swift` — 2 cached count properties + CalendarSystem cleanup in `cleanupBeforeDeletion()`
- `Cumberland/Services/RelationshipManager.swift` — Increment/decrement + `removeAllEdges(for:)`
- `Cumberland/Infrastructure/ServiceContainer.swift` — Register monitor + wire cross-references
- `Cumberland/Services/CardOperationManager.swift` — `relationshipManager` property + `changeCardType()` refactor
- `Cumberland/CardRelationship/CardRelationshipOperations.swift` — Increment/decrement + type-filtered `ensureReverseEdge`
- `Cumberland/AI/ContentAnalysis/SuggestionEngine.swift` — Increment + type-filtered `ensureReverseEdge`
- `Cumberland/Murderboard/MurderBoardView.swift` — Increment/decrement + sentinel check + banner
- `Cumberland/Murderboard/CumberlandBoardDataSource.swift` — Desync-aware edge query
- `Cumberland/Data/EdgeRepository.swift` — Increment/decrement
- `Cumberland/CardRelationshipView.swift` — Sentinel check + banner
- `Cumberland/CumberlandApp.swift` — Backfill function + call + reset key
- `Cumberland/Diagnostic Views/RelationshipAuditView.swift` — Cached count columns + duplicate detection/merge
- `Cumberland/Data/CardRepository.swift` — Added `cleanupBeforeDeletion` to delete methods

**Related Issues:**
- DR-0098: Complete Relationship Loss for Single Card (root cause — verified)
- ER-0035: Relationship Diagnostic Tools and Safety Guards (verified)

---

*Verified: 2026-02-22*
