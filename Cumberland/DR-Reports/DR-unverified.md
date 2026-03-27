# Discrepancy Reports (DR) - Unverified Issues

- Guidelines: [Cumberland/DR-Reports/DR-Guidelines.md]

This document tracks recent discrepancy reports that are open or awaiting user verification.

**Status:** Currently **0 open DRs** | **4 resolved, awaiting verification**

---

## DR-0102: TestFixtures Factory Methods Bypass Service Layer — Crash on context.insert()

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms
**Component:** CumberlandTests/TestFixtures.swift
**Severity:** High

**Description:**
TestFixtures `createSample*()` factory methods call `context.insert(card)` directly instead of using `CardOperationManager.createCard()`. This bypasses the service layer introduced in ER-0022 (2026-02-06), causing a crash at `TestFixtures.swift:177` when tests run in Xcode.

**Expected Behavior:**
Test factories should use the same service APIs that production code uses — specifically `CardOperationManager.createCard()` — to create and persist cards.

**Actual Behavior:**
Factories construct `Card()` manually and call raw `context.insert(card)`, skipping `context.save()` and any service-layer validation. The test halts at line 177 (`context.insert(card)` inside `createSampleCharacter`).

**Root Cause Analysis:**
TestFixtures was originally created on 2026-01-20 (ER-7/8/9/10), before the ER-0022 service refactor (2026-02-06). When tests were rewritten on 2026-03-25 ("Fixing and adding Tests part 1"), the factory methods were carried forward without being updated to delegate to `CardOperationManager`. The `CardOperationManagerTests` file itself correctly uses the service API, but all other test files rely on the pre-refactor TestFixtures pattern.

**Impact:**
- 10 of 11 active test files with persistence bypass the service layer
- Tests exercise a code path production code no longer uses
- Crash at `context.insert(card)` blocks test execution

**Date Identified:** 2026-03-27

**Resolution:**

**Fix Date:** 2026-03-27

**Implementation:**

1. **Added `CardOperationManager`-backed factory method** (TestFixtures.swift)
   - New private helper `makeCardViaManager()` creates a `CardOperationManager` from the provided context and delegates to `createCard()`
   - All `createSample*()` card factories (`createSampleCharacter`, `createSampleLocation`, `createSampleTimeline`, `createSampleScene`, `createSampleArtifact`) now call the manager when a context is provided
   - When `context` is `nil`, cards are still created without persistence (for pure model tests)

2. **Non-card factories updated in DR-0105**
   - `createRelationType()`, `createBoard()`, `createEdge()` now delegate to their respective service managers (RelationTypeManager, BoardManager, RelationshipManager) per DR-0103/DR-0104/DR-0105

**Files Affected:**
- `CumberlandTests/TestFixtures.swift` - Updated card factory methods to use CardOperationManager

**Test Steps:**
1. Open Cumberland project in Xcode
2. Select the CumberlandTests scheme
3. Run tests (Cmd+U)
4. Verify tests no longer crash at TestFixtures.swift:177
5. Verify card-creating tests pass (CardModelTests, BoardModelTests, etc.)

**Related Issues:**
- ER-0022: Code Maintainability Refactoring (introduced the service layer)
- ER-0036: Edge Count Sentinel (CardOperationManager integrates with RelationshipManager)

---

## DR-0103: RelationTypeManager Service — Centralize RelationType CRUD

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms
**Component:** Cumberland/Services/RelationTypeManager.swift
**Severity:** Medium (code quality / maintainability)

**Description:**
RelationType creation, mirror management, and shared utilities (`sanitize()`, `makeCode()`) were duplicated across 6+ files: CardRelationshipOperations, CardRelationshipSheets, RelationTypeFormView, SuggestionEngine, SceneProjectRelationDiagnosticsView, and CumberlandApp. No centralized `RelationTypeManager` service existed, unlike `CardOperationManager` and `RelationshipManager` which were created during ER-0022.

**Root Cause:**
ER-0022 Phase 1 created services for Card and CardEdge operations but did not create equivalent services for RelationType CRUD. The original intent was a single module providing all persistence-layer access.

**Date Identified:** 2026-03-27

**Resolution:**

**Fix Date:** 2026-03-27

**Implementation:**

1. **Created `RelationTypeManager`** (`Cumberland/Services/RelationTypeManager.swift`)
   - Core CRUD: `createRelationType()`, `ensureRelationType()`, `deleteRelationType()`
   - Mirror management: `ensureMirror()`, `mirrorType()`
   - Queries: `fetchRelationType()`, `fetchAll()`, `fetchApplicable()`
   - Static utilities: `sanitize()`, `makeCode()`

2. **Updated `ServiceContainer`** (`Cumberland/Infrastructure/ServiceContainer.swift`)
   - Added `relationTypeManager` property, wired `relationshipManager.relationTypeManager` cross-reference

3. **Updated 7 production callers to delegate:**
   - `CardRelationshipOperations.swift` — `sanitize()`, `makeCode()` delegate to static methods; `ensureRelationType()`, `mirrorType()` accept optional `services` parameter
   - `CardRelationshipSheets.swift` — `createType()` fully delegates to `RelationTypeManager.ensureRelationType()`; removed local `sanitize`, `makeCode`, `codeExists`, `createMirrorIfMissing`
   - `RelationTypeFormView.swift` — `save()` delegates to manager for create/fetch; removed local `ensureMirror`, `fetchType`, `sanitize`, `makeCode`, `codeExists`
   - `RelationshipManager.swift` — `getMirrorType()` delegates to `RelationTypeManager.mirrorType()` when available
   - `SuggestionEngine.swift` — `findOrCreateRelationType()` delegates to manager; removed `getMirrorType()`, `makeRelationTypeCode()`
   - `SceneProjectRelationDiagnosticsView.swift` — `ensureCanonicalType()` delegates to manager
   - `CumberlandApp.swift` — `seedRelationTypesIfNeeded()` delegates to manager; removed local `sanitize()`

**Files Affected:**
- `Cumberland/Services/RelationTypeManager.swift` (new)
- `Cumberland/Infrastructure/ServiceContainer.swift`
- `Cumberland/CardRelationship/CardRelationshipOperations.swift`
- `Cumberland/CardRelationship/CardRelationshipSheets.swift`
- `Cumberland/RelationTypeFormView.swift`
- `Cumberland/Services/RelationshipManager.swift`
- `Cumberland/AI/ContentAnalysis/SuggestionEngine.swift`
- `Cumberland/SceneProjectRelationDiagnosticsView.swift`
- `Cumberland/CumberlandApp.swift`

**Test Steps:**
1. Build Cumberland-macOS scheme — verify no errors
2. Create a new RelationType via the Relationship editor — verify creation works
3. Edit an existing RelationType — verify save works
4. Use Content Analysis suggestion engine — verify RelationType creation
5. Verify seeding works on fresh launch (delete app data, relaunch)

**Related Issues:**
- ER-0022: Code Maintainability Refactoring (original service layer work)
- DR-0102: TestFixtures factory bypass (identified the gap)

---

## DR-0104: BoardManager Service — Centralize Board/BoardNode CRUD

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms
**Component:** Cumberland/Services/BoardManager.swift
**Severity:** Medium (code quality / maintainability)

**Description:**
Board creation, node management, and `fetchOrCreatePrimaryBoard()` logic were scattered across Board.swift (model), CumberlandBoardDataSource, and DeveloperBoardsView. No centralized `BoardManager` service existed.

**Root Cause:**
Same gap as DR-0103 — ER-0022 did not create a Board service manager.

**Date Identified:** 2026-03-27

**Resolution:**

**Fix Date:** 2026-03-27

**Implementation:**

1. **Created `BoardManager`** (`Cumberland/Services/BoardManager.swift`)
   - Board CRUD: `createBoard()`, `deleteBoard()`, `fetchOrCreatePrimaryBoard()`
   - Node management: `addNode()`, `removeNode()`, `togglePin()`
   - Queries: `fetchBoard()`, `fetchAllBoards()`

2. **Updated `ServiceContainer`** — Added `boardManager` property

3. **Updated 3 production callers to delegate:**
   - `Board.swift` — `fetchOrCreatePrimaryBoard()` now a thin wrapper delegating to `BoardManager`
   - `CumberlandBoardDataSource.swift` — `loadBoard()` delegates to `BoardManager.fetchOrCreatePrimaryBoard()`
   - `DeveloperBoardsView.swift` — `deleteBoard()` and `deleteNode()` delegate to `BoardManager`

**Files Affected:**
- `Cumberland/Services/BoardManager.swift` (new)
- `Cumberland/Infrastructure/ServiceContainer.swift`
- `Cumberland/Model/Board.swift`
- `Cumberland/Murderboard/CumberlandBoardDataSource.swift`
- `Cumberland/Diagnostic Views/DeveloperBoardsView.swift`

**Test Steps:**
1. Build Cumberland-macOS scheme — verify no errors
2. Open a card's Murderboard — verify board loads correctly
3. Add/remove nodes on the Murderboard — verify persistence
4. Open DeveloperBoardsView — verify board/node deletion works

**Related Issues:**
- ER-0022: Code Maintainability Refactoring
- DR-0103: RelationTypeManager (companion service)

---

## DR-0105: Test Infrastructure — Migrate Factories to Service Managers

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms
**Component:** CumberlandTests/TestFixtures.swift
**Severity:** Medium (test quality)

**Description:**
`TestFixtures.createRelationType()`, `createBoard()`, and `createEdge()` factory methods used raw `context.insert()` without delegating to the new service managers (RelationTypeManager, BoardManager, RelationshipManager). Additionally, ER-0008 test files (TemporalPositioningTests, MultiTimelineTests) had ~21 inline `RelationType()` + ~25 inline `CardEdge()` creations that bypassed service infrastructure entirely.

**Root Cause:**
DR-0103 and DR-0104 created the missing managers. DR-0105 completes the test-side migration.

**Date Identified:** 2026-03-27

**Resolution:**

**Fix Date:** 2026-03-27

**Implementation:**

1. **Updated TestFixtures factories:**
   - `createRelationType()` — delegates to `RelationTypeManager.ensureRelationType()` (idempotent, with save)
   - `createBoard()` — delegates to `BoardManager.createBoard()`
   - `createEdge()` — delegates to `RelationshipManager.createRelationship(createReverse: false)` with fallback for already-exists case

2. **Migrated ER-0008 inline creations:**
   - `TemporalPositioningTests.swift` — 13 inline RelationType creations replaced with shared `makeAppearsInType()` helper using `TestFixtures.createRelationType()`; 13 inline CardEdge creations replaced with `TestFixtures.createEdge()`
   - `MultiTimelineTests.swift` — 5 inline RelationType creations replaced with shared helper; 7 inline CardEdge creations replaced with `TestFixtures.createEdge()`

**Files Affected:**
- `CumberlandTests/TestFixtures.swift`
- `CumberlandTests/ER-0008-Timeline/TemporalPositioningTests.swift`
- `CumberlandTests/ER-0008-Timeline/MultiTimelineTests.swift`

**Test Steps:**
1. Build Cumberland-macOS scheme — verify no errors
2. Run all tests (Cmd+U) — verify tests pass
3. Verify no inline `RelationType()` + `context.insert()` patterns remain in ER-0008 tests

**Related Issues:**
- DR-0102: TestFixtures card factory bypass (first fix in this series)
- DR-0103: RelationTypeManager (dependency)
- DR-0104: BoardManager (dependency)

---

## Recently Verified

- **DR-0099:** iOS/visionOS Targets Missing File Memberships — Build Failures — ✅ Verified 2026-02-27 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0100:** Auxiliary Windows Restore on App Launch Instead of Main UI — ✅ Verified 2026-02-27 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0101:** Theme Color Swatches Not Visible in Settings Picker — ✅ Verified 2026-02-27 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0098:** Complete Relationship Loss for Single Card — ✅ Verified 2026-02-22 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0096:** BoardGestureIntegration Modifies @Binding State During View Body Evaluation — ✅ Verified 2026-02-18 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0095:** Map Wizard Cannot Save Drawn Map — ✅ Verified 2026-02-16 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0094:** Image History Restore Does Not Update CardEditorView — ✅ Verified 2026-02-14 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0092:** visionOS Settings Presented as Modal Sheet Instead of Window — ✅ Verified 2026-02-12 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0093:** visionOS Developer Tools Presented as Modal Sheet Instead of Window — ✅ Verified 2026-02-12 -> [Batch 10](./DR-verified-0091-0100.md)

---

## Status Indicators

Per DR-GUIDELINES.md:
- 🔴 **Identified - Not Resolved** - Issue found and root cause analyzed, awaiting fix
- 🟡 **Resolved - Not Verified** - Claude can mark when implementation is complete
- ✅ **Resolved - Verified** - Only USER can mark after testing

---

*Last Updated: 2026-03-27*
