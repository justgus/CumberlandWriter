# Discrepancy Reports 0201-0210 (Verified)

This file contains verified and resolved Discrepancy Reports (DRs) numbered 0201 through 0210.

**Status Legend:**
- ✅ Resolved - Verified: Fix implemented and confirmed working by user testing

---

## DR-0203: BoardManager Bypasses BoardRepository Pattern

**Reported:** 2026-04-29
**Verified:** 2026-04-30
**Component:** Services/BoardManager.swift, Data/BoardRepository.swift (NEW)
**Severity:** High - Violates separation of concerns for platform independence
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring
**Related DR:** DR-0128 (MurderBoardView repository migration)

**Issue:**
BoardManager contained both business logic AND data access code, preventing platform independence. All CRUD operations directly used modelContext instead of going through a dedicated repository.

**Original Problems:**
- BoardManager mixed business logic with data access
- Direct modelContext.insert(), delete(), save(), fetch() calls throughout
- No separation between "what to do" (business logic) and "how to store it" (data access)
- Made platform porting difficult (would need to modify BoardManager for different database)

**Resolution:**

**Created BoardRepository.swift (Data Layer):**
- New repository in Data folder for all Board/BoardNode CRUD operations
- Encapsulates all SwiftData queries and operations
- Methods:
  - `createBoard(name:primaryCard:)` - Create board with basic config
  - `createBoard(name:primaryCard:zoomScale:panX:panY:)` - Create with full config
  - `deleteBoard(_:)` - Delete board (cascade deletes nodes)
  - `updateBoard(_:name:zoomScale:panX:panY:backlogKindRaw:)` - Update properties
  - `createNode(board:card:posX:posY:pinned:)` - Create node
  - `deleteNode(_:)` - Delete node
  - `updateNode(_:posX:posY:pinned:)` - Update node properties
  - `save()` - Persist changes
  - `fetchBoard(byPrimaryCard:)` - Query by primary card
  - `fetchAllBoards()` - Query all boards sorted by name
  - `fetchBoard(byUUID:)` - Query by UUID

**Refactored BoardManager.swift (Business Logic Layer):**
- Added `private let boardRepository: BoardRepository`
- Changed all CRUD methods to delegate to repository
- Kept business logic:
  - Auto-naming boards based on card
  - Ensuring primary card presence on board
  - Validating and clamping transform state (zoom/pan bounds)
  - Duplicate node detection
  - Toggle operations
- Example refactoring:
  ```swift
  // Before:
  func deleteBoard(_ board: Board) throws {
      modelContext.delete(board)
      try modelContext.save()
  }

  // After:
  func deleteBoard(_ board: Board) throws {
      try boardRepository.deleteBoard(board)
  }
  ```

**Updated ServiceContainer.swift:**
- Added `boardRepository: BoardRepository` to repositories section
- Initialized alongside other repositories
- Updated comments to clarify BoardManager uses BoardRepository internally

**Architecture Achieved:**
```
Views/UI Layer
    ↓
Services Layer (BoardManager - Business Logic)
    ↓
Data Layer (BoardRepository - CRUD Operations)
    ↓
SwiftData/Database
```

**Final Achievement:**
- ✅ Complete separation of business logic from data access
- ✅ BoardRepository encapsulates ALL database operations
- ✅ BoardManager focuses ONLY on business rules
- ✅ Platform independence achieved (can swap data layer for different platforms)
- ✅ Consistent with ER-0022 Phase 2 repository pattern
- ✅ 200 lines of new repository code
- ✅ 176 lines of refactored business logic

**Files Created:**
- Data/BoardRepository.swift (NEW - 200 lines)

**Files Modified:**
- Services/BoardManager.swift (business logic extraction)
- Infrastructure/ServiceContainer.swift (added boardRepository)

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0202: ER-0022 Phase 2 Incomplete - RelationTypeManager.swift Bypasses Repository

**Reported:** 2026-04-27
**Resolved:** 2026-05-12
**Verified:** 2026-05-12
**Component:** Services/RelationTypeManager.swift
**Severity:** High - Service bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
RelationTypeManager.swift:96 calls `modelContext.delete(type)` directly instead of using appropriate repository method.

**Impact:**
- Bypasses centralized deletion logic
- No cleanup for edges using this type
- Violates single-responsibility principle

**Resolution:** 2026-05-12

**RelationTypeManager.swift Enhancement:**
- Added EdgeRepository property to RelationTypeManager (line 26)
- Enhanced deleteRelationType() to fetch all edges using the type and delete them via EdgeRepository (lines 97-129)
- Added comprehensive debug logging for edge cleanup tracking
- Properly handles bidirectional edge deletion and integrity monitoring
- Direct modelContext.delete() now only occurs after all edge cleanup is complete

**Edge Cleanup Process:**
1. Fetch all edges using the RelationType via EdgeRepository.fetch(ofType:)
2. For each edge, delete the relationship via EdgeRepository.deleteRelationship()
   - This ensures both forward and reverse edges are deleted
   - EdgeIntegrityMonitor counts are properly decremented
3. Only after all edges are cleaned up, delete the RelationType itself

**Final Achievement:**
- ✅ Proper edge cleanup before RelationType deletion
- ✅ Bidirectional relationship integrity maintained
- ✅ Debug logging for tracking cleanup operations
- ✅ No orphaned edges after RelationType deletion

**Files Modified:**
- Services/RelationTypeManager.swift

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0204: ER-0022 Phase 2 Incomplete - CardOperationManager.swift Bypasses Repositories

**Reported:** 2026-04-27
**Resolved:** 2026-05-12
**Verified:** 2026-05-12
**Component:** Services/CardOperationManager.swift
**Severity:** Critical - Service layer bypasses repositories
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring
**Related DR:** DR-0176 (same file, Card creation)

**Issue:**
CardOperationManager.swift has 4 locations calling `modelContext.delete()` directly for cards and edges instead of using CardRepository.delete() and EdgeRepository.deleteRelationship().

**Impact:**
- Service layer duplicates repository logic
- Reverse relationships not deleted
- EdgeIntegrityMonitor counts not updated
- Violates single-responsibility principle

**Resolution:** 2026-05-12

**CardOperationManager.swift Migrations:**
- Updated deleteCard() to use CardRepository.deleteCard() (line 72)
- Updated deleteCards() to use CardRepository.deleteCards() (line 80)
- Updated changeCardType() fallback to use EdgeRepository.deleteAllRelationships() and fetchAll() (line 148)
- All 4 direct modelContext.delete() calls have been replaced with repository methods

**Deletion Methods:**
1. **deleteCard()**: Uses CardRepository.deleteCard() which handles:
   - cleanupBeforeDeletion() (image files, caches, local data)
   - Proper cascade deletion of edges and citations

2. **deleteCards()**: Uses CardRepository.deleteCards() for bulk deletion

3. **changeCardType() fallback**: Uses EdgeRepository for edge cleanup:
   - Fetches all edges via fetchAll(for:)
   - Deletes via deleteAllRelationships(for:)
   - Zeroes integrity counts

**Final Achievement:**
- ✅ All card deletion uses CardRepository
- ✅ All edge deletion uses EdgeRepository
- ✅ Proper cleanup hooks executed
- ✅ Integrity monitoring maintained

**Files Modified:**
- Services/CardOperationManager.swift

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0205: ER-0022 Phase 2 Incomplete - RelationshipManager.swift Bypasses EdgeRepository

**Reported:** 2026-04-27
**Resolved:** 2026-05-12
**Verified:** 2026-05-12
**Component:** Services/RelationshipManager.swift
**Severity:** Critical - Service layer bypasses EdgeRepository
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring
**Related DR:** DR-0140 (same file, CardEdge creation)

**Issue:**
RelationshipManager.swift has 7 locations calling `modelContext.delete()` directly for edges instead of using EdgeRepository.deleteRelationship().

**Impact:**
- Service layer duplicates EdgeRepository logic
- Reverse relationships not deleted (data integrity failure)
- EdgeIntegrityMonitor counts not updated
- Violates single-responsibility principle

**Resolution:** 2026-05-12

**RelationshipManager.swift Migrations:**
- Updated removeRelationship() to use EdgeRepository.deleteRelationship() and deleteAllRelationships() (lines 90-105)
- Updated removeEdge() to use EdgeRepository.deleteEdge() (line 114)
- Updated removeAllEdges() to use EdgeRepository.deleteAllRelationships() and fetchAll() (lines 129-135)
- All 7 direct modelContext.delete() calls have been replaced with repository methods

**Locations Fixed:**
- Line 140 (edge) → EdgeRepository.deleteRelationship()
- Line 144 (edge) → EdgeRepository.deleteRelationship()
- Line 159 (edge) → EdgeRepository.deleteAllRelationships()
- Line 163 (edge) → EdgeRepository.deleteAllRelationships()
- Line 178 (edge) → EdgeRepository.deleteEdge()
- Line 208 (edge) → EdgeRepository.deleteAllRelationships()
- Line 216 (edge) → EdgeRepository.deleteAllRelationships()

**Final Achievement:**
- ✅ All edge deletion uses EdgeRepository
- ✅ Bidirectional relationships properly maintained
- ✅ EdgeIntegrityMonitor counts properly updated
- ✅ Complete data integrity preserved

**Files Modified:**
- Services/RelationshipManager.swift

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0210: RelationshipManager Loses Note Parameter When Creating Bidirectional Relationships

**Reported:** 2026-05-15
**Resolved:** 2026-05-15
**Verified:** 2026-05-15
**Component:** Services/RelationshipManager.swift, Data/EdgeRepository.swift
**Severity:** Medium - Data loss in relationship notes
**Test Failure:** ServiceIntegrationTests.swift:218

**Issue:**
When creating a bidirectional relationship with a note using `RelationshipManager.createRelationship()`, the note parameter was being lost. The test `ServiceIntegrationTests::testCreateRelationship` failed at line 218 when verifying that the edge note was saved correctly.

**Root Cause:**
RelationshipManager.createRelationship() has two code paths:
1. When `createReverse: true` (default): Calls `edgeRepository.createRelationship()` which did NOT accept a `note` parameter
2. When `createReverse: false`: Calls `edgeRepository.insertSingleEdge()` which DID accept a `note` parameter

Since the default behavior is to create bidirectional relationships (`createReverse: true`), the note was always being lost in normal usage.

**Expected Behavior:**
Relationship notes should be saved on the forward edge regardless of whether the relationship is bidirectional or unidirectional.

**Actual Behavior:**
Notes were only saved when explicitly creating unidirectional relationships with `createReverse: false`.

**Resolution:**

**Implementation:**

1. **EdgeRepository.swift:213** - Added `note` parameter to `createRelationship()` method
   ```swift
   func createRelationship(
       from source: Card,
       to target: Card,
       relationType: RelationType,
       note: String? = nil,  // ← Added parameter
       sortIndex: Double? = nil
   ) throws
   ```

2. **EdgeRepository.swift:223-226** - Set note on forward edge when provided
   ```swift
   let forwardEdge = CardEdge(from: source, to: target, type: relationType)
   if let note = note {
       forwardEdge.note = note  // ← Added
   }
   ```

3. **RelationshipManager.swift:64** - Pass note parameter through to EdgeRepository
   ```swift
   try edgeRepository.createRelationship(
       from: sourceCard,
       to: targetCard,
       relationType: type,
       note: note  // ← Added
   )
   ```

**Result:**
✅ Test now passes - relationship notes are properly saved for both bidirectional and unidirectional edges
✅ Note parameter is consistently handled across all relationship creation paths

**Files Modified:**
- `Cumberland/Data/EdgeRepository.swift` - Added note parameter and logic
- `Cumberland/Services/RelationshipManager.swift` - Pass note through to EdgeRepository

**Verification:**
Test `ServiceIntegrationTests::testCreateRelationship` passes with exit code 0. User confirmed fix works correctly.

**Status:** ✅ Resolved - Verified

---

*Last Updated: 2026-05-15*
