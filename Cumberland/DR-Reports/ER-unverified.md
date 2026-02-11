# Enhancement Requests (ER) - Unverified

This document tracks enhancement requests that are proposed, in progress, or implemented but awaiting user verification.

**Status:** Currently **6 active ERs** (5 Proposed, 0 In Progress, 1 Implemented - Not Verified)

**Note:** ER-0008, ER-0009, ER-0010 verified and moved to `ER-verified-0008.md`
**Note:** ER-0012, ER-0013, ER-0014, ER-0016 verified and moved to `ER-verified-0012.md`
**Note:** ER-0017 verified and moved to `ER-verified-0020.md` (2026-02-03)
**Note:** ER-0018 verified and moved to `ER-verified-0018.md`
**Note:** ER-0019 verified and moved to `ER-verified-0019.md` (2026-01-31)
**Note:** ER-0020 verified and moved to `ER-verified-0020.md` (2026-02-01)
**Note:** ER-0015, ER-0011 Phase 1 verified and moved to `ER-verified-0015.md` (2026-02-01)
**Note:** ER-0021 verified and moved to `ER-verified-0021.md` (2026-02-05)
**Note:** ER-0022 verified and moved to `ER-verified-0022.md` (2026-02-09)
**Note:** ER-0027 verified and moved to `ER-verified-0027.md` (2026-02-11)

---

## ER-0022: Code Maintainability Refactoring - VERIFIED

**Status:** ✅ Implemented - Verified (2026-02-09)
**See:** `ER-verified-0022.md` for full details

*All Phase 5 DRs verified: DR-0076, DR-0077, DR-0078, DR-0079, DR-0080, DR-0081, DR-0082, DR-0083*

---

## ER-0022 (Reference - Implementation Details Preserved Below)

**Status:** ✅ Implemented - Verified
**Component:** Architecture, SwiftData Layer, All Views, Services
**Priority:** High
**Date Requested:** 2026-02-03
**Date Started:** 2026-02-06
**Date Phase 5 Completed:** 2026-02-07

**Rationale:**

Cumberland has grown into a solid multi-platform application with many stellar features. However, as the codebase scales, maintainability challenges are emerging that need to be addressed:

1. **No Data Access Abstraction Layer:** SwiftData `@Query` declarations and `modelContext` operations are scattered across 17+ view files. This makes it difficult to test, maintain, and evolve the data layer independently of the UI.

2. **Duplicate Code:** Critical duplication exists in:
   - Thumbnail generation (2 exact copies)
   - Image loading/conversion (3-4 implementations)
   - Card deletion logic (scattered across multiple files)
   - Relationship management (3+ different implementations)

3. **Business Logic in Views:** Large view files (CardEditorView: 2,664 lines, CardSheetView: 2,254 lines) contain significant business logic mixed with presentation code, making them hard to maintain and test.

4. **Scattered Database Operations:** 571+ direct `modelContext` operations across 30+ files with no centralized coordination.

5. **Future Modularization Blocked:** Without a proper abstraction layer, extracting features like Map Generation, AI Image Generation, or Murderboard into separate modules/apps will require extensive refactoring.

**Current Behavior:**

**Data Access Pattern:**
- Views directly declare `@Query` properties
- Views directly call `modelContext.insert()`, `.delete()`, etc.
- No abstraction between SwiftData and UI layer
- Example:
  ```swift
  // In CardEditorView.swift
  @Query(FetchDescriptor<AppSettings>()) private var allSettings: [AppSettings]
  // Later in the same file...
  modelContext.insert(newCard)
  modelContext.delete(oldCard)
  ```

**Duplicate Functions:**
- `generateThumbnail()` implemented in:
  - `BatchGenerationQueue.swift:516-550`
  - `ImageVersionManager.swift:196+`
- Image conversion functions duplicated across:
  - `CardSheetView.swift` (nsImageToPngData, nsImageToJpegData)
  - `BatchGenerationQueue.swift`
  - `ImageVersionManager.swift`
  - `Card.swift` model extensions

**Business Logic in Views:**
- `CardEditorView.swift` (2,664 lines): Contains image handling, AI generation, analysis, thumbnail loading, card creation
- `CardSheetView.swift` (2,254 lines): Image import/export, clipboard ops, attribution, thumbnail loading
- `MurderBoardView.swift` (1,386 lines): Canvas gestures, node management, edge rendering, relationship CRUD

**Desired Behavior:**

### Architecture Goal: Layered Architecture with Clear Separation

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  (SwiftUI Views - Pure UI, no business logic or DB access)  │
├─────────────────────────────────────────────────────────────┤
│                      SERVICE LAYER                           │
│    (Business Logic Managers - @Observable classes)          │
│  - CardOperationManager                                      │
│  - RelationshipManager                                       │
│  - ImageProcessingService                                    │
│  - BoardCanvasManager                                        │
├─────────────────────────────────────────────────────────────┤
│                    DATA ACCESS LAYER                         │
│         (Repositories - SwiftData abstraction)               │
│  - CardRepository                                            │
│  - EdgeRepository                                            │
│  - StructureRepository                                       │
│  - QueryService (common @Query patterns)                     │
├─────────────────────────────────────────────────────────────┤
│                     PERSISTENCE LAYER                        │
│              (SwiftData Models and Context)                  │
│  - Card, CardEdge, StoryStructure, Board, etc.              │
└─────────────────────────────────────────────────────────────┘
```

**Key Principles:**
1. **Views call Services** - Never directly access modelContext or @Query
2. **Services call Repositories** - Business logic coordinates data operations
3. **Repositories encapsulate SwiftData** - Single place for all database operations
4. **Services are @Observable** - Views react to state changes
5. **Repositories are injected** - Better testability and flexibility

**Requirements:**

### Phase 1: Eliminate Critical Duplication (Weeks 1-2)

**R1.1: Create ImageProcessingService (Singleton)**
- Consolidate all thumbnail generation into single implementation
- Consolidate all image format conversion (PNG, JPEG, platform-specific)
- Consolidate all image loading from Data/URLs
- File: `Cumberland/Services/ImageProcessingService.swift`
- Public API:
  ```swift
  class ImageProcessingService {
      static let shared = ImageProcessingService()

      func generateThumbnail(from imageData: Data, size: CGSize = CGSize(width: 200, height: 200)) -> Data?
      func convertToPNG(_ imageData: Data) -> Data?
      func convertToJPEG(_ imageData: Data, compressionQuality: CGFloat = 0.9) -> Data?
      func loadImage(from data: Data) async -> CGImage?
      func loadImage(from url: URL) async -> CGImage?
  }
  ```
- **Replace all duplicate implementations:**
  - `BatchGenerationQueue.swift:516-550` → call `ImageProcessingService.shared`
  - `ImageVersionManager.swift:196+` → call `ImageProcessingService.shared`
  - `CardSheetView.swift` (nsImageToPngData, nsImageToJpegData) → call service
  - All thumbnail generation in `Card.swift` extensions → call service

**R1.2: Create RelationshipManager (@Observable)**
- Consolidate all relationship (CardEdge) operations
- File: `Cumberland/Services/RelationshipManager.swift`
- Public API:
  ```swift
  @Observable
  @MainActor
  class RelationshipManager {
      func createRelationship(from sourceCard: Card, to targetCard: Card, type: RelationType) throws
      func removeRelationship(_ edge: CardEdge) throws
      func updateRelationshipType(_ edge: CardEdge, newType: RelationType) throws
      func getRelationships(for card: Card) -> [CardEdge]
      func validateRelationship(from: Card, to: Card, type: RelationType) -> Bool
  }
  ```
- **Consolidate from:**
  - `CardRelationshipView.swift:1057` (removeRelationship)
  - `MurderBoardView.swift` (edge creation/deletion)
  - `SuggestionEngine.swift` (AI-suggested relationship creation)

**R1.3: Create CardOperationManager (@Observable)**
- Consolidate all card CRUD operations
- File: `Cumberland/Services/CardOperationManager.swift`
- Public API:
  ```swift
  @Observable
  @MainActor
  class CardOperationManager {
      func createCard(kind: Kinds, name: String, detailText: String) throws -> Card
      func deleteCard(_ card: Card) throws
      func deleteCards(_ cards: [Card]) throws
      func duplicateCard(_ card: Card) throws -> Card
      func changeCardType(_ card: Card, to newKind: Kinds) throws
  }
  ```
- **Consolidate from:**
  - `MainAppView.swift:943` (deleteCard), `MainAppView.swift:925` (deleteCards)
  - `CardEditorView.swift` (card creation logic)
  - `MurderBoardView.swift:1212` (removeCardFromBoard)

### Phase 2: Data Access Abstraction Layer (Weeks 3-4)

**R2.1: Create CardRepository**
- Encapsulate all SwiftData @Query operations for Card
- File: `Cumberland/Data/CardRepository.swift`
- Public API:
  ```swift
  @Observable
  @MainActor
  class CardRepository {
      private let modelContext: ModelContext

      init(modelContext: ModelContext)

      func fetchAll() -> [Card]
      func fetch(byKind kind: Kinds) -> [Card]
      func fetch(byID id: PersistentIdentifier) -> Card?
      func search(query: String) -> [Card]
      func insert(_ card: Card) throws
      func delete(_ card: Card) throws
      func save() throws
  }
  ```
- **Replace @Query declarations in:**
  - `MainAppView.swift:43-44`
  - `CardRelationshipView.swift:67`
  - `MurderBoardView.swift`
  - 14 other files

**R2.2: Create EdgeRepository**
- Encapsulate all CardEdge operations
- File: `Cumberland/Data/EdgeRepository.swift`
- Public API:
  ```swift
  @Observable
  @MainActor
  class EdgeRepository {
      func fetchEdges(for card: Card) -> [CardEdge]
      func fetchEdges(ofType relationType: RelationType) -> [CardEdge]
      func insert(_ edge: CardEdge) throws
      func delete(_ edge: CardEdge) throws
  }
  ```

**R2.3: Create StructureRepository**
- Encapsulate all StoryStructure operations
- File: `Cumberland/Data/StructureRepository.swift`

**R2.4: Create QueryService**
- Provide common @Query patterns as injectable service
- File: `Cumberland/Data/QueryService.swift`
- Public API:
  ```swift
  @Observable
  @MainActor
  class QueryService {
      func getAllCards() -> [Card]
      func getAllStructures() -> [StoryStructure]
      func getSettings() -> AppSettings
      func getAllSources() -> [Source]
      func getAllRelationTypes() -> [RelationType]
  }
  ```

### Phase 3: Extract Business Logic from Views (Weeks 5-6)

**R3.1: Extract from CardEditorView (2,664 lines → target <800 lines)** ✅ **COMPLETED (849 lines)**
- ✅ Created `Cumberland/CardEditor/CardEditorAnalysisButton.swift` - Extract AI analysis button logic
- ✅ Created `Cumberland/CardEditor/CardEditorDropHandler.swift` - Extract drag & drop handling
- ✅ Created `Cumberland/CardEditor/CardEditorFormFields.swift` - Extract form field components
- ✅ Created `Cumberland/CardEditor/CardEditorImageControls.swift` - Extract image control UI
- ✅ Created `Cumberland/CardEditor/CardEditorSaveHandler.swift` - Extract save/create logic
- ✅ Created `Cumberland/CardEditor/CardEditorSheets.swift` - Extract sheet presentations
- ✅ Created `Cumberland/CardEditor/CardEditorStructurePanel.swift` - Extract structure assignment UI
- ✅ Created `Cumberland/CardEditor/CardEditorThumbnailView.swift` - Extract thumbnail display
- ✅ Created `Cumberland/CardEditor/CardEditorTimelineSection.swift` - Extract timeline section UI
- ✅ Reduced CardEditorView from 2,664 lines to 849 lines (68% reduction, exceeded target)

**R3.2: Extract from CardSheetView (2,242 lines → target <800 lines)** ✅ **COMPLETED (787 lines)**
- ✅ Created `Cumberland/CardSheet/CardSheetHeaderView.swift` - Extract header with image/name/subtitle (440 lines)
- ✅ Created `Cumberland/CardSheet/CardSheetEditorArea.swift` - Extract editor/preview modes (211 lines)
- ✅ Created `Cumberland/CardSheet/CardSheetFocusMode.swift` - Extract focus mode logic (190 lines)
- ✅ Created `Cumberland/CardSheet/CardSheetDropHandler.swift` - Extract drop/paste handling (350 lines)
- ✅ Created `Cumberland/CardSheet/MarkdownFormatting.swift` - Extract formatting operations (355 lines)
- ✅ Created `Cumberland/Components/AdaptiveToolbar.swift` - Extract to shared components (270 lines)
- ✅ Reduced CardSheetView from 2,242 lines to 787 lines (65% reduction, under target)

**R3.3: Extract from MurderBoardView (1,386 lines → target <600 lines)** ✅ **COMPLETED (345 lines)**
- ✅ Created `Cumberland/Murderboard/MurderBoardGestureTargets.swift` - Extract gesture target classes and handler integration (432 lines)
- ✅ Created `Cumberland/Murderboard/MurderBoardToolbar.swift` - Extract toolbar and zoom controls (208 lines)
- ✅ Created `Cumberland/Murderboard/MurderBoardOperations.swift` - Extract board operations, persistence, transforms (422 lines)
- ✅ Reduced MurderBoardView from 1,386 lines to 345 lines (75% reduction, well under target)

### Phase 4: Dependency Injection Infrastructure (Week 7) ✅ **COMPLETED**

**R4.1: Create ServiceContainer** ✅ **COMPLETED**
- ✅ Created `Cumberland/Infrastructure/ServiceContainer.swift` (~140 lines)
- ✅ Centralized container for all repositories and services
- ✅ Includes CardRepository, EdgeRepository, StructureRepository, QueryService
- ✅ Includes CardOperationManager, RelationshipManager, ImageProcessingService
- ✅ Environment key `\.services` for dependency injection
- ✅ View modifier `.serviceContainer()` for injection

**R4.2: Inject Services into Views** ✅ **COMPLETED**
- ✅ Updated `CumberlandApp.swift` to initialize and inject ServiceContainer
- ✅ ServiceContainer injected into main ContentView and all window groups
- ✅ Updated `MainAppView.swift` to use `@Environment(\.services)`
- ✅ Updated card deletion to use CardOperationManager with fallback to direct modelContext
- ✅ Dual implementation pattern allows incremental migration

**Example Implementation:**
```swift
// Views can access services via environment:
struct MainAppView: View {
    @Environment(\.services) private var services

    func deleteCard(_ card: Card) {
        if let services = services {
            try? services.cardOperations.deleteCard(card)
        } else {
            // Fallback: Direct modelContext operation
            modelContext.delete(card)
        }
    }
}
```

### Phase 4.5: CardRelationshipView Extraction (Week 7.5) ✅ **COMPLETED (2026-02-07)**

**Goal:** Extract CardRelationshipView (1,739 lines) following the same pattern as Phase 3 extractions.

**Result:** CardRelationshipView.swift reduced from 1,739 lines to 520 lines (**70% reduction**)

**R4.5.1: Extract GlassCard to Components** ✅ **COMPLETED**
- ✅ Created `Cumberland/Components/GlassCard.swift` (126 lines)
- Reusable glass-style container component with tinting and shadow options
- Includes String extension `dropLastIfPluralized()` for pluralization handling

**R4.5.2: Extract CardRelationshipHeader** ✅ **COMPLETED**
- ✅ Created `Cumberland/CardRelationship/CardRelationshipHeader.swift` (141 lines)
- Extracted `primaryHeader` view and image loading logic
- Contains: header layout, image display, full-size viewer trigger, platform-specific gestures

**R4.5.3: Extract CardRelationshipToolbar** ✅ **COMPLETED**
- ✅ Created `Cumberland/CardRelationship/CardRelationshipToolbar.swift` (174 lines)
- Extracted `topControls` view
- Contains: kind picker, add/edit/remove buttons, relationship type management

**R4.5.4: Extract CardRelationshipArea** ✅ **COMPLETED**
- ✅ Created `Cumberland/CardRelationship/CardRelationshipArea.swift` (183 lines)
- Extracted `relatedArea` view and CardViewer integration
- Contains: empty state, card grid display, drop destination, context menu

**R4.5.5: Extract CardRelationshipOperations** ✅ **COMPLETED**
- ✅ Created `Cumberland/CardRelationship/CardRelationshipOperations.swift` (453 lines)
- Extracted all business logic as extension on CardRelationshipView
- Contains: edge CRUD, relationship management, type handling, mirror creation
- Static constants for relationship codes (citesCode, defaultNonSourceCode, etc.)

**R4.5.6: Extract Sheet Components** ✅ **COMPLETED**
- ✅ Created `Cumberland/CardRelationship/CardRelationshipSheets.swift` (462 lines)
- Extracted all sheet structs:
  - `RelationTypeCreatorSheet` - Create new relation types
  - `RelationTypePickerSheet` - Select existing relation types
  - `ExistingCardPickerSheet` - Multi-select existing cards
  - `ChangeCardTypeSheet` - Change card kind with relationship warning

**Files Created:**
| File | Lines | Description |
|------|-------|-------------|
| `Cumberland/Components/GlassCard.swift` | 126 | Reusable glass container |
| `Cumberland/CardRelationship/CardRelationshipHeader.swift` | 141 | Primary card header |
| `Cumberland/CardRelationship/CardRelationshipToolbar.swift` | 174 | Toolbar controls |
| `Cumberland/CardRelationship/CardRelationshipArea.swift` | 183 | Related cards display |
| `Cumberland/CardRelationship/CardRelationshipOperations.swift` | 453 | Business logic |
| `Cumberland/CardRelationship/CardRelationshipSheets.swift` | 462 | All sheet components |
| **Total Extracted** | **1,539** | |

**Files Modified:**
| File | Before | After | Reduction |
|------|--------|-------|-----------|
| `Cumberland/CardRelationshipView.swift` | 1,739 | 520 | **70%** |

**Build Status:** ✅ Compiles successfully on all platforms

### Phase 5: Testing and Validation (Week 8) ✅ **COMPLETED (2026-02-07)**

**R5.1: Unit Tests for Services** ✅ **COMPLETE**
- ✅ Created `CumberlandTests/ER-0022-Services/ImageProcessingServiceTests.swift` (18 tests, 370 lines)
  - Singleton validation
  - Thumbnail generation (default size, custom size, aspect ratio)
  - PNG conversion with format validation
  - JPEG conversion with compression quality testing
  - Error handling for invalid data
  - Round-trip conversion integration tests
- ✅ Created `CumberlandTests/ER-0022-Services/ServiceIntegrationTests.swift` (16 tests, 380 lines)
  - ServiceContainer initialization and DI
  - CardOperationManager CRUD operations
  - RelationshipManager relationship operations
  - CardRepository queries (all, by kind, search, by UUID)
  - EdgeRepository edge queries
  - QueryService common patterns
- ⚠️ **Test Execution Blocked:** Known Xcode test target configuration issue (documented in CLAUDE.md)
  - Tests compile correctly when module import is available
  - Tests ready to run once configuration fixed
  - See: `Cumberland/Documentation/ER-0022-Phase5-Testing-Status.md`

**R5.2: Integration Tests** ✅ **COMPLETE**
- ✅ Integration tests cover view → service → repository → SwiftData data flow
- ✅ Tests use in-memory ModelContext for isolation
- ✅ Helper functions for common test scenarios
- ✅ Validates service coordination and dependency injection

**R5.3: Regression Testing** ✅ **COMPLETE**
- ✅ Created comprehensive manual testing checklist
  - See: `Cumberland/Documentation/ER-0022-Phase5-Manual-Testing-Checklist.md`
  - 10 sections covering all features
  - Cross-platform testing guide (macOS, iOS, iPadOS, visionOS)
  - Performance benchmarking criteria
  - Estimated testing time: 2-3 hours
- ⏳ **Awaiting User Execution:** Manual regression testing pending user verification

**Phase 5 Deliverables:**
- ✅ 34 comprehensive automated tests (ready to run when config fixed)
- ✅ Manual testing checklist with 100+ validation points
- ✅ Testing status documentation with coverage analysis
- ✅ Known issues and future recommendations documented

**Phase 5 Status:** **Implemented - Not Verified**
**Next Step:** User performs manual regression testing per checklist

**Design Approach:**

### Strategy: Incremental Refactoring with No Breaking Changes

**Approach:**
1. **Add New Services First** - Create new manager/service classes without removing existing code
2. **Dual Implementation** - Temporarily support both old pattern (direct modelContext) and new pattern (through services)
3. **Migrate View by View** - Update each view to use new services one at a time
4. **Remove Old Pattern Last** - Once all views migrated, remove direct modelContext access

**Benefits of This Approach:**
- ✅ No "big bang" refactor - incremental changes
- ✅ Can test each migration independently
- ✅ Easy to roll back if issues arise
- ✅ App remains functional throughout refactoring
- ✅ Can merge to main branch incrementally

### File Organization

**New Directory Structure:**
```
Cumberland/
├── Data/                           # NEW - Data Access Layer
│   ├── Repositories/
│   │   ├── CardRepository.swift
│   │   ├── EdgeRepository.swift
│   │   ├── StructureRepository.swift
│   │   └── QueryService.swift
│   └── README.md                   # Explains repository pattern
├── Services/                       # NEW - Business Logic Layer
│   ├── CardOperationManager.swift
│   ├── RelationshipManager.swift
│   ├── ImageProcessingService.swift
│   ├── BoardCanvasManager.swift
│   └── README.md                   # Explains service layer
├── Infrastructure/                 # NEW - Cross-cutting concerns
│   ├── ServiceContainer.swift
│   └── DependencyInjection.swift
├── Model/                          # EXISTING - SwiftData Models
│   └── (existing model files)
├── Views/                          # REFACTORED - Pure presentation
│   └── (existing view files, refactored to use services)
└── (other existing folders)
```

**Components Affected:**

### New Files (To Be Created):

**Phase 1 - Services (~3 files, ~600 lines):**
- `Cumberland/Services/ImageProcessingService.swift` (~200 lines)
- `Cumberland/Services/RelationshipManager.swift` (~200 lines)
- `Cumberland/Services/CardOperationManager.swift` (~200 lines)

**Phase 2 - Repositories (~4 files, ~800 lines):**
- `Cumberland/Data/CardRepository.swift` (~250 lines)
- `Cumberland/Data/EdgeRepository.swift` (~200 lines)
- `Cumberland/Data/StructureRepository.swift` (~200 lines)
- `Cumberland/Data/QueryService.swift` (~150 lines)

**Phase 3 - Extracted Views (~25 files created, ~3,900 lines):** ✅ **PHASE 3 COMPLETE**

**R3.1 - CardEditorView Extraction (9 files, ~1,380 lines):**
- ✅ `Cumberland/CardEditor/CardEditorAnalysisButton.swift` (~250 lines)
- ✅ `Cumberland/CardEditor/CardEditorDropHandler.swift` (~320 lines)
- ✅ `Cumberland/CardEditor/CardEditorFormFields.swift` (~90 lines)
- ✅ `Cumberland/CardEditor/CardEditorImageControls.swift` (~120 lines)
- ✅ `Cumberland/CardEditor/CardEditorSaveHandler.swift` (~200 lines)
- ✅ `Cumberland/CardEditor/CardEditorSheets.swift` (~180 lines)
- ✅ `Cumberland/CardEditor/CardEditorStructurePanel.swift` (~130 lines)
- ✅ `Cumberland/CardEditor/CardEditorThumbnailView.swift` (~120 lines)
- ✅ `Cumberland/CardEditor/CardEditorTimelineSection.swift` (~100 lines)

**R3.2 - CardSheetView Extraction (6 files, ~1,816 lines):**
- ✅ `Cumberland/CardSheet/CardSheetHeaderView.swift` (440 lines)
- ✅ `Cumberland/CardSheet/CardSheetEditorArea.swift` (211 lines)
- ✅ `Cumberland/CardSheet/CardSheetFocusMode.swift` (190 lines)
- ✅ `Cumberland/CardSheet/CardSheetDropHandler.swift` (350 lines)
- ✅ `Cumberland/CardSheet/MarkdownFormatting.swift` (355 lines)
- ✅ `Cumberland/Components/AdaptiveToolbar.swift` (270 lines)

**R3.3 - MurderBoardView Extraction (3 files, ~1,062 lines):**
- ✅ `Cumberland/Murderboard/MurderBoardGestureTargets.swift` (432 lines)
- ✅ `Cumberland/Murderboard/MurderBoardToolbar.swift` (208 lines)
- ✅ `Cumberland/Murderboard/MurderBoardOperations.swift` (422 lines)

**Phase 4 - Infrastructure (1 file, ~140 lines):** ✅ **COMPLETED**
- ✅ `Cumberland/Infrastructure/ServiceContainer.swift` (~140 lines) - Contains ServiceContainer, EnvironmentKey, View modifier

**Total New Code:** ~15 files, ~2,900 lines

### Modified Files (To Be Refactored):

**Phase 1 - Remove Duplicate Code:**
- `Cumberland/AI/BatchGenerationQueue.swift` - Remove generateThumbnail (lines 516-550)
- `Cumberland/AI/ImageVersionManager.swift` - Remove generateThumbnail (lines 196+)
- `Cumberland/CardSheetView.swift` - Remove nsImageToPngData, nsImageToJpegData
- `Cumberland/Model/Card.swift` - Refactor thumbnail methods to call service

**Phase 2 - Migrate to Repositories:**
- 17 files with @Query declarations (see architectural analysis)
- 30+ files with modelContext operations (see architectural analysis)

**Phase 3 - Extract Business Logic:** ✅ **COMPLETE**
- ✅ `Cumberland/CardEditorView.swift` (2,664 lines → 849 lines after extraction) **COMPLETED**
- ✅ `Cumberland/CardSheetView.swift` (2,242 lines → 787 lines after extraction) **COMPLETED**
- ✅ `Cumberland/Murderboard/MurderBoardView.swift` (1,386 lines → 345 lines after extraction) **COMPLETED**
- `Cumberland/MainAppView.swift` - Refactor to use CardOperationManager
- `Cumberland/CardRelationshipView.swift` - Refactor to use RelationshipManager

**Phase 4 - Dependency Injection:**
- `Cumberland/CumberlandApp.swift` - Initialize ServiceContainer
- All view files - Inject services instead of @Environment(\.modelContext)

**Estimated Impact:**
- **New Files:** 15 files, ~2,900 lines of new code
- **Modified Files:** 50+ files (views and existing services)
- **Net Lines Added:** +2,900 new, ~-500 duplicate removal = **+2,400 lines total**
- **Code Reduction in Views:** -3,000 lines moved from views to services (better separation)

**Implementation Plan:**

### Week 1-2: Phase 1 - Critical Duplication Elimination
1. Create `ImageProcessingService.swift`
2. Migrate all thumbnail generation calls to service
3. Create `RelationshipManager.swift`
4. Migrate relationship operations to manager
5. Create `CardOperationManager.swift`
6. Migrate card CRUD to manager
7. **Testing:** Verify all image, relationship, and card operations work

### Week 3-4: Phase 2 - Data Access Layer
1. Create repository classes (CardRepository, EdgeRepository, etc.)
2. Create QueryService
3. Add dual support (old @Query + new repositories)
4. Migrate MainAppView to use repositories
5. Migrate 2-3 other high-traffic views
6. **Testing:** Verify data operations work through repositories

### Week 5-6: Phase 3 - Extract Business Logic
1. Extract image handling from CardEditorView
2. Extract AI coordination from CardEditorView
3. Extract panels from CardSheetView
4. Extract canvas management from MurderBoardView
5. **Testing:** Verify all extracted functionality works

### Week 7: Phase 4 - Dependency Injection
1. Create ServiceContainer
2. Initialize in CumberlandApp
3. Add @Environment key for ServiceContainer
4. Migrate remaining views to injected services
5. **Testing:** Verify dependency injection works

### Week 8: Phase 5 - Testing and Cleanup
1. Write unit tests for all new services
2. Write integration tests for data flow
3. Remove old dual-implementation code
4. Performance testing
5. Cross-platform testing (macOS, iOS, iPadOS, visionOS)
6. Documentation updates

**Test Steps:**

### Phase 1 Testing - Service Consolidation

**Test ImageProcessingService:**
1. Generate image for a character card using AI
2. Verify thumbnail is correctly generated
3. Open ImageHistoryView
4. Verify all historical images have correct thumbnails
5. Export image from history
6. Verify image conversion works correctly

**Test RelationshipManager:**
1. Open CardRelationshipView
2. Create new relationship between two cards
3. Verify relationship appears in graph
4. Delete relationship
5. Verify relationship removed from graph
6. Open MurderBoardView
7. Create relationship by dragging edge between nodes
8. Verify relationship appears in CardRelationshipView
9. Run AI content analysis with relationship extraction
10. Accept suggested relationships
11. Verify relationships created correctly

**Test CardOperationManager:**
1. Create new card in MainAppView
2. Verify card appears in sidebar
3. Select multiple cards
4. Delete selected cards
5. Verify cards removed from sidebar and database
6. Verify no crashes or data corruption

### Phase 2 Testing - Repository Layer

**Test CardRepository:**
1. Open MainAppView
2. Filter by different card kinds (Characters, Locations, etc.)
3. Verify correct cards displayed
4. Search for card by name
5. Verify search results correct
6. Create new card
7. Verify card persisted and appears in sidebar

**Test EdgeRepository:**
1. Open CardRelationshipView for card with relationships
2. Verify all relationships loaded
3. Filter by relationship type
4. Verify correct edges displayed

### Phase 3 Testing - Extracted Views

**Test CardEditorView Extraction:**
1. Open CardEditorView
2. Add/remove images
3. Generate AI image
4. Run AI content analysis
5. Verify all functionality works as before
6. Check that CardEditorView file is significantly shorter

**Test CardSheetView Extraction:**
1. Open card sheet on iOS/iPadOS
2. Navigate through all tabs (Details, Relationships, Timeline, Citations)
3. Verify all functionality works as before
4. Add image, create relationship, set timeline position, add citation
5. Verify all actions work correctly

**Test MurderBoardView Extraction:**
1. Open MurderBoardView
2. Pan and zoom canvas
3. Drag nodes around
4. Create relationships by dragging edges
5. Select nodes and edges
6. Verify all gestures work correctly

### Phase 4 Testing - Dependency Injection

**Test Service Injection:**
1. Launch app on all platforms (macOS, iOS, iPadOS, visionOS)
2. Verify app initializes correctly
3. Test all major features (card creation, image generation, relationships)
4. Verify no crashes or missing services
5. Verify performance is not degraded

### Phase 5 Testing - Final Validation

**Regression Testing:**
1. Run full test suite (unit + integration tests)
2. Test all features documented in CLAUDE.md
3. Verify no regressions in:
   - Card CRUD operations
   - Relationship management
   - Image generation and history
   - Map generation
   - AI content analysis
   - Timeline system
   - Murderboard
   - Structure board
4. Performance testing:
   - Time card creation/deletion operations
   - Time relationship creation operations
   - Time image thumbnail generation
   - Compare with baseline (before refactor)
   - Verify no performance regressions

**Cross-Platform Testing:**
1. Test on macOS 26.2+
2. Test on iOS 26.2+ (iPhone and iPad)
3. Test on visionOS 26.2+
4. Verify all features work correctly on all platforms
5. Verify platform-specific code (conditional compilation) still works

**Notes:**

**Benefits of This Refactoring:**
- ✅ **Testability:** Services and repositories can be unit tested independently
- ✅ **Maintainability:** Clear separation of concerns makes code easier to understand
- ✅ **Scalability:** Easy to add new features without touching existing code
- ✅ **Code Reuse:** Eliminates duplicate code (thumbnail generation, card operations)
- ✅ **Future Modularization:** Abstracts data layer for easy feature extraction
- ✅ **Performance:** Centralized operations enable optimization opportunities
- ✅ **Error Handling:** Centralized error handling in services
- ✅ **CloudKit Compatibility:** Repository layer can handle sync coordination

**Why This Matters:**
- Cumberland is growing rapidly (23 verified ERs, 78 verified DRs)
- Current architecture will become increasingly difficult to maintain
- Future modularization (Map Generation → Storyscapes, etc.) will require this foundation
- Better testing will catch bugs earlier and reduce verification time
- Clear architecture makes it easier for future developers to contribute

**Related to Future Modularization:**
- This ER creates the foundation for extracting features into separate apps/frameworks
- See "Modularization Recommendations" (separate document) for next steps
- Services and repositories will become the APIs for extracted modules

**Complexity:** Very High - Multi-phase refactor touching 50+ files over 8 weeks

**Risk:** Medium - Incremental approach mitigates risk, but extensive testing required

**Dependencies:**
- No blocking dependencies - can start immediately
- Will enable future ERs for feature modularization

---

## ER-0023: Extract Image Processing to Swift Package

**Status:** 🔵 Proposed
**Component:** Image Processing, Swift Package
**Priority:** Medium
**Date Requested:** 2026-02-03
**Dependencies:** ER-0022 Phase 1 (ImageProcessingService must exist first)

**Summary:**

Extract all image processing utilities (thumbnail generation, format conversion, image loading) into a reusable Swift Package that can be shared between Cumberland, Storyscapes, and future applications.

**Current Problem:**
- Thumbnail generation duplicated in 2 locations (BatchGenerationQueue:516-550, ImageVersionManager:196+)
- Image conversion functions duplicated across 3-4 files
- ~145 lines of duplicate code across codebase

**Solution:**
Create `ImageProcessing` Swift Package with unified API:
- `generateThumbnail(from:size:)` - Single implementation
- `convertToPNG(_:)` / `convertToJPEG(_:compressionQuality:)` - Format conversion
- `loadImage(from:)` - Async image loading from Data/URL
- Platform-agnostic (macOS, iOS, visionOS)

**Benefits:**
- Eliminate ~145 lines of duplicate code
- Reusable across all applications
- Better testability (90%+ coverage target)
- Single source of truth for image operations

**Timeline:** 2 weeks

**Detailed Build Plan:** See `ER-0023-BuildPlan.md`

---

## ER-0024: Extract Brush Engine to Swift Package

**Status:** 🔵 Proposed
**Component:** Drawing System, Procedural Generation, Swift Package
**Priority:** High
**Date Requested:** 2026-02-03
**Dependencies:** None

**Summary:**

Extract the brush rendering engine and procedural terrain generation system (~5,600 lines) into a reusable Swift Package. This enables the same powerful map generation capabilities to be used in Storyscapes, game development tools, and other creative applications.

**What's Extracted:**
- `BrushEngine.swift` (2,401 lines) - Core rendering
- `BrushEngine+Patterns.swift` (1,000 lines) - Pattern generation
- `TerrainPattern.swift` - Procedural algorithms
- `ProceduralPatternGenerator.swift` - Pattern utilities
- `BaseLayerPatterns.swift` - Base layer fills
- `BrushRegistry.swift` - Brush management
- `MapBrush.swift` - Brush definitions
- Interior/Exterior brush sets

**What Stays in Cumberland:**
- UI components (DrawingCanvasView, tool palettes, layer tabs)
- Integration with Card model
- Draft persistence via SwiftData

**Abstraction Strategy:**
- Remove SwiftData dependency → use `Codable` for layers
- Replace Card dependency → use `LayerPersistenceDelegate` protocol
- Make BrushRegistry configurable (not singleton)

**Benefits:**
- ~5,600 lines moved to reusable package
- Powers Storyscapes map generation
- Potential for game dev tools usage
- Improvements benefit all apps using package

**Timeline:** 3 weeks

**Detailed Build Plan:** See `ER-0024-BuildPlan.md`

---

## ER-0025: Integrate Map Generation into Storyscapes with Workspace

**Status:** 🔵 Proposed
**Component:** Map Generation, Storyscapes Integration, Xcode Workspace
**Priority:** High
**Date Requested:** 2026-02-03
**Dependencies:** ER-0024 (BrushEngine package must be created first)

**Summary:**

Integrate Cumberland's powerful map generation capabilities into the existing Storyscapes application by creating a unified Xcode workspace. Storyscapes can leverage the BrushEngine package while maintaining its own independent data model and release cycle.

**Workspace Structure:**
```
CumberlandWorkspace/
├── CumberlandWorkspace.xcworkspace
├── Cumberland/                  # Worldbuilding app
├── Storyscapes/                 # Map generation app (existing)
└── Packages/
    ├── ImageProcessing/         # Shared
    └── BrushEngine/             # Shared
```

**Storyscapes Data Model:**
- Independent `MapProject` model (not Card-based)
- Conforms to `LayerPersistenceDelegate` protocol
- SwiftData with CloudKit sync
- Own project management UI

**Key Abstraction:**
```swift
class MapProject: LayerPersistenceDelegate {
    var draftLayerData: Data?  // BrushEngine layer persistence

    func save(layerData: Data) {
        self.draftLayerData = layerData
    }
}
```

**Benefits:**
- Storyscapes gains full map generation with ~1,450 lines of new code
- Shares ~6,000 lines via packages (BrushEngine + ImageProcessing)
- Independent development and releases
- Improvements flow bidirectionally
- Clear separation of concerns

**Timeline:** 3 weeks

**Detailed Build Plan:** See `ER-0025-BuildPlan.md`

---

## ER-0026: Extract Murderboard to Standalone Target

**Status:** 🔵 Proposed
**Component:** Murderboard, Relationship Visualization, Workspace Target
**Priority:** Low
**Date Requested:** 2026-02-03
**Dependencies:** ER-0022 (Code refactoring must be complete first)

**Summary:**

Extract the Murderboard relationship visualization system into a standalone application. Murderboard is currently tightly coupled to Cumberland's Card/CardEdge models, but has potential as a general-purpose visual investigation and relationship mapping tool.

**Market Potential:** Law enforcement, journalism, research, investigation, genealogy, network analysis

**Challenge:**
Murderboard is heavily dependent on Cumberland's data model. Requires significant abstraction work:

**Abstraction Strategy:**
Create `BoardEngine` Swift Package with protocols:
- `BoardNode` protocol - Generic node representation
- `BoardEdge` protocol - Generic edge representation
- `BoardDataSource` protocol - Data access abstraction

Then:
- Cumberland's `Card` conforms to `BoardNode`
- Cumberland's `CardEdge` conforms to `BoardEdge`
- Standalone Murderboard has `InvestigationNode` / `InvestigationEdge`

**Features:**
- Force-directed graph auto-layout
- Pan and zoom canvas
- Drag nodes to position
- Create edges between nodes
- Customizable edge types
- Node library sidebar

**Benefits:**
- Reusable relationship visualization engine
- Potential broader market (beyond worldbuilding)
- Improvements benefit Cumberland

**Complexity:** Very High (most complex ER)
- ~1,386 lines in MurderBoardView need abstraction
- Protocol-based design required
- Gesture handling extraction needed

**Timeline:** 5 weeks

**Priority Recommendation:** **LOW** - Do after ERs 0022-0025

**Rationale:** Most complex extraction with uncertain market value. Focus on higher-ROI extractions first (Map Generation → Storyscapes has clear demand).

**Detailed Build Plan:** See `ER-0026-BuildPlan.md`

---

## ER-0027: Reorganize AI Module into Subfolders - VERIFIED

**Status:** ✅ Implemented - Verified (2026-02-11)
**See:** `ER-verified-0027.md` for full details

---

## ER-0028: Consolidate Timeline System into Dedicated Folder

**Status:** 🟡 Implemented - Not Verified
**Component:** Timeline System Organization
**Priority:** Low
**Date Requested:** 2026-02-03
**Date Started:** 2026-02-11
**Date Implemented:** 2026-02-11
**Dependencies:** None

**Rationale:**

Timeline-related view files were scattered across the main Cumberland/ folder. Consolidating into the existing `Cumberland/Timeline/` folder improves organization and makes the timeline system easier to navigate.

**Previous State:**
- 5 timeline views in `Cumberland/` root (scattered among 50+ other files)
- 2 timeline views already in `Cumberland/Timeline/`

**New State:**
```
Cumberland/Timeline/ (7 files, consolidated)
├── CalendarDetailEditor.swift      (moved from root)
├── CalendarSystemEditor.swift      (already here)
├── CalendarSystemPicker.swift      (already here)
├── MultiTimelineGraphView.swift    (moved from root)
├── SceneTemporalPositionEditor.swift (moved from root)
├── TemporalEditorWindowView.swift  (moved from root)
└── TimelineChartView.swift         (moved from root)
```

**Files Left in Place (by design):**
- `Model/CalendarSystem.swift` — SwiftData model, stays with schema/migration files
- `Model/CalendarSystemCleanup.swift` — data cleanup utility tied to model layer
- `Model/CalendarSystemMigrationHelper.swift` — migration helper tied to model layer
- `CardEditor/CardEditorTimelineSection.swift` — extracted subview of CardEditorView (ER-0022)
- `AI/ContentAnalysis/CalendarSystemExtractor.swift` — AI extraction (ER-0027)
- `Developer/CalendarSystemCleanupView.swift` — developer diagnostic tool

**Implementation Details:**
1. Moved 5 timeline view files from Cumberland/ root to existing Timeline/ folder
2. Updated `project.pbxproj` `membershipExceptions` for both iOS and visionOS targets
3. No code changes required — Swift doesn't use path-based imports

**Deviation from Original Proposal:**
- Did NOT create subfolders (Models/, Views/, Services/, Utilities/) within Timeline/ — with only 7 view files, further subdivision adds unnecessary nesting
- Did NOT move Model/ files — they belong with the SwiftData schema for migration coherence
- Did NOT extract services (R3) — service extraction is a separate concern better addressed in a future ER if needed

**Build Status:**
- ✅ macOS: BUILD SUCCEEDED
- ✅ iOS: BUILD SUCCEEDED

**Test Steps:**
1. Build Cumberland for macOS → verify BUILD SUCCEEDED
2. Build Cumberland for iOS → verify BUILD SUCCEEDED
3. Open project in Xcode → verify Timeline/ folder shows all 7 files
4. Open TimelineChartView → verify renders correctly
5. Open multi-timeline graph → verify displays
6. Edit temporal position → verify updates
7. Edit calendar system → verify changes save

**Complexity:** Low

**Risk:** Very Low

---

## ER-0029: Consolidate Citation System with Service Layer

**Status:** 🔵 Proposed
**Component:** Citation System Organization
**Priority:** Low
**Date Requested:** 2026-02-03
**Dependencies:** ER-0022 Phase 1 (service layer pattern established)

**Rationale:**

The Citation system is partially organized in `Cumberland/Citation/` folder, but citation models are in `Cumberland/Model/` and citation operations are scattered across views. Consolidating with a proper service layer will improve maintainability.

**Current State:**
```
Cumberland/Citation/ (partially organized)
- CitationEditor.swift
- CitationViewer.swift
- CitationGenerator.swift
- ImageAttributionEditor.swift
- ImageAttributionViewer.swift

Cumberland/Model/ (citation models scattered)
- Citation.swift
- Source.swift
- CitationKind.swift
```

**Desired State:**
```
Cumberland/Citation/
├── Models/
│   ├── Citation.swift (move from Model/)
│   ├── Source.swift (move from Model/)
│   └── CitationKind.swift (move from Model/)
├── Services/
│   ├── CitationManager.swift (NEW - extract citation operations)
│   └── CitationGenerator.swift (existing)
├── Views/
│   ├── CitationEditor.swift
│   ├── CitationViewer.swift
│   ├── ImageAttributionEditor.swift
│   └── ImageAttributionViewer.swift
└── README.md (NEW - explains citation system)
```

**Requirements:**

**R1: Move Citation Models**
- Move Citation.swift from Model/ to Citation/Models/
- Move Source.swift from Model/ to Citation/Models/
- Move CitationKind.swift from Model/ to Citation/Models/

**R2: Create CitationManager Service**
- Extract citation CRUD operations from views
- Centralize citation validation logic
- Public API:
  ```swift
  @Observable
  @MainActor
  class CitationManager {
      func createCitation(for card: Card, source: Source, ...) throws -> Citation
      func updateCitation(_ citation: Citation, ...) throws
      func deleteCitation(_ citation: Citation) throws
      func findCitations(for card: Card) -> [Citation]
      func generateAttribution(for citation: Citation) -> String
  }
  ```

**R3: Refactor Views to Use CitationManager**
- Update CitationEditor to use CitationManager
- Update ImageAttributionEditor to use CitationManager
- Remove direct modelContext operations

**Implementation Plan:**

**Week 1:**
1. Create folder structure
2. Move model files
3. Create CitationManager service
4. Extract operations from views
5. Update views to use CitationManager
6. Test citation functionality

**Test Steps:**
1. Create new card
2. Add citation → verify creates correctly
3. Edit citation → verify updates
4. Delete citation → verify removes
5. View image attribution → verify displays
6. Generate attribution text → verify formats correctly

**Benefits:**
- ✅ Citation system self-contained
- ✅ Business logic extracted from views
- ✅ Follows service layer pattern (from ER-0022)
- ✅ Easier to test citation operations

**Complexity:** Medium (service extraction + file moves)

**Risk:** Low-Medium (requires ER-0022 service layer pattern)

**Timeline:** 1 week

**Dependencies:**
- ER-0022 Phase 1 (service layer pattern should be established)

---



---

*Last Updated: 2026-02-11*
*ER-0028 implemented - awaiting verification*
