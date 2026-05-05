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

*Last Updated: 2026-04-30*
