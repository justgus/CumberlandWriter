# Enhancement Requests (ER) — Verified Batch 35

---

## ER-0035: Relationship Diagnostic Tools and Safety Guards

**Status:** ✅ Implemented - Verified
**Component:** CardEdge / Diagnostic Views / Services
**Priority:** Critical
**Date Requested:** 2026-02-20
**Date Implemented:** 2026-02-21
**Date Verified:** 2026-02-21
**Depends On:** DR-0098

**Rationale:**
Following the data loss incident in DR-0098 (all CardEdge relationships for a single Card spontaneously deleted), Cumberland needs diagnostic tools to detect relationship integrity issues and safety guards to prevent future data loss on edge deletion code paths.

**Current Behavior:**
- No logging when edges are deleted, making post-incident investigation impossible
- `changeCardType()` silently deletes all edges without logging
- Existing "Validate Relationships" tool uses relationship arrays (potentially stale) instead of fetch-based queries
- No way to audit per-card edge counts or detect orphaned edges
- No snapshot/export capability for edge data

**Desired Behavior:**
Users and developers can audit relationship integrity, detect anomalies, and have visibility into all edge deletion events via logging.

**Requirements:**
1. **RelationshipAuditView** — New diagnostic view with:
   - Per-card edge audit using `FetchDescriptor<CardEdge>` (not relationship arrays)
   - Outgoing/incoming edge counts per card
   - Discrepancy detection (fetch count vs. relationship array count)
   - Orphan edge detection (edges where `from` or `to` is nil)
   - Edge-per-card summary table, sortable by name/count/kind
   - Cards with 0 edges highlighted as potential data loss victims
   - "Repair orphan edges" action
   - "Export edge snapshot" to clipboard as JSON
2. **Edge deletion logging** — `[EdgeAudit]` prefixed `print()` logs on ALL edge deletion code paths:
   - `CardOperationManager.changeCardType()` and `deleteCard()`
   - `Card.cleanupBeforeDeletion()`
   - `RelationshipManager.removeRelationship()` and `removeEdge()`
   - `EdgeRepository.delete()` methods
   - `MurderBoardView.deleteEdgePairDirectly()`
   - `CardRelationshipOperations` fallback `changeCardType()` and `removeRelationship()`
3. **Safety guard on `changeCardType()`** — Log edge count before deletion; return count to callers
4. **Enhanced "Validate All Relationships"** — Upgrade existing DeveloperToolsView action to use fetch-based queries and report discrepancies
5. **Integration** — Add RelationshipAuditView to DeveloperToolsView under "Data Integrity"

**Implementation Details:**

All 5 requirements implemented:

1. **RelationshipAuditView** (`Diagnostic Views/RelationshipAuditView.swift` — NEW, ~340 lines):
   - Run Audit button fetches all edges via `FetchDescriptor` for each card
   - Summary shows total cards, zero-edge cards, discrepancy cards, orphan edges
   - Per-card table with columns: Name, Kind, Out(Fetch), In(Fetch), Out(Array), In(Array), Status
   - Sortable by name/edge count/kind/discrepancy, filterable by all/zero-edges/discrepancies
   - "Delete Orphan Edges" action removes edges with nil from/to
   - "Export Edge Snapshot" copies full JSON to clipboard
   - Integrated into DeveloperToolsView on both macOS/iOS and visionOS

2. **Edge deletion logging** — `[EdgeAudit]` prefix, `#if DEBUG` guarded, in 7 files:
   - `CardOperationManager.swift`: `deleteCard()` logs out/in counts; `changeCardType()` logs per-edge details
   - `Card.swift`: `cleanupBeforeDeletion()` logs every edge being deleted
   - `RelationshipManager.swift`: `removeRelationship()` (typed and untyped) and `removeEdge()` log counts
   - `EdgeRepository.swift`: `delete(_:)` (single) and `delete(_:)` (batch) log per-edge
   - `MurderBoardView.swift`: `deleteEdgePairDirectly()` logs fwd/rev/symmetric counts
   - `CardRelationshipOperations.swift`: fallback `changeCardType()` and `removeRelationship()` log counts

3. **Safety guard**: `changeCardType()` now returns `Int` (edge count deleted), is `@discardableResult`

4. **Enhanced validate**: DeveloperToolsView `.validateAllRelationships` now:
   - Fetches all edges via `FetchDescriptor`, removes orphans (nil from/to/type)
   - Per-card discrepancy detection (fetch count vs array count)
   - Reports both orphan count and discrepancy count

5. **Integration**: NavigationLink added to DeveloperToolsView in both `dataIntegrityContent` (macOS/iOS) and `visionOSBody` (visionOS)

**Components Affected:**
- `Cumberland/Diagnostic Views/RelationshipAuditView.swift` — **NEW**
- `Cumberland/Diagnostic Views/DeveloperToolsView.swift` — Nav link added, validate action enhanced
- `Cumberland/Services/CardOperationManager.swift` — Logging + safety guard
- `Cumberland/Model/Card.swift` — Logging on `cleanupBeforeDeletion()`
- `Cumberland/Services/RelationshipManager.swift` — Logging on `removeRelationship()` and `removeEdge()`
- `Cumberland/Data/EdgeRepository.swift` — Logging on `delete()` methods
- `Cumberland/Murderboard/MurderBoardView.swift` — Logging on `deleteEdgePairDirectly()`
- `Cumberland/CardRelationship/CardRelationshipOperations.swift` — Logging on fallback `changeCardType()` and `removeRelationship()`

**Test Steps:**
1. Open Developer Tools -> Data Integrity
2. Tap "Relationship Audit View" -> Run Audit
3. Verify per-card edge counts are correct (Out(F)/In(F) should match Out(A)/In(A))
4. Verify no orphan edges reported (or repair them if found)
5. Tap "Export Edge Snapshot" -> paste into text editor, verify valid JSON
6. Run "Validate All Relationships" -> verify message shows 0 orphans, 0 discrepancies
7. In Console.app: filter for `[EdgeAudit]` — delete a relationship in the app and verify log output
8. Perform a card type change — verify `[EdgeAudit] changeCardType:` log appears with edge details

**Verification Notes:**
- User confirmed: 95 cards audited, 18 with 0 edges, 1 with discrepancies (DC Metro Area — SwiftData desync), 0 orphans, 780 total edges
- Discrepancy on "DC Metro Area" card confirmed as live SwiftData relationship array desynchronization (Out(F)=41, In(F)=41, Out(A)=0, In(A)=0) — self-corrected on relaunch
- This live detection validates the FetchDescriptor-based approach and confirms the root cause theory for DR-0098
- All logging is `#if DEBUG` guarded — no impact on release builds
- Build verified: `xcodebuild -scheme Cumberland-macOS` succeeds

**Related Issues:**
- DR-0098: Complete Relationship Loss for Single Card (root cause investigation)
- ER-0036: Edge Count Sentinel — Live Desync Detection and Recovery (production-facing fix, proposed)

---

*Verified: 2026-02-21*
