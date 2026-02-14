# Enhancement Requests (ER) - Unverified

This document tracks enhancement requests that are proposed, in progress, or implemented but awaiting user verification.

**Status:** Currently **3 active ERs** (3 Proposed, 0 In Progress, 0 Implemented - Not Verified)

**Note:** ER-0008, ER-0009, ER-0010 verified and moved to `ER-verified-0008.md`
**Note:** ER-0012, ER-0013, ER-0014, ER-0016 verified and moved to `ER-verified-0012.md`
**Note:** ER-0017 verified and moved to `ER-verified-0020.md` (2026-02-03)
**Note:** ER-0018 verified and moved to `ER-verified-0018.md`
**Note:** ER-0019 verified and moved to `ER-verified-0019.md` (2026-01-31)
**Note:** ER-0020 verified and moved to `ER-verified-0020.md` (2026-02-01)
**Note:** ER-0015, ER-0011 Phase 1 verified and moved to `ER-verified-0015.md` (2026-02-01)
**Note:** ER-0021 verified and moved to `ER-verified-0021.md` (2026-02-05)
**Note:** ER-0022 verified and moved to `ER-verified-0022.md` (2026-02-09)
**Note:** ER-0023 verified and moved to `ER-verified-0023.md` (2026-02-14)
**Note:** ER-0027 verified and moved to `ER-verified-0027.md` (2026-02-11)
**Note:** ER-0028 verified and moved to `ER-verified-0028.md` (2026-02-11)

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

## ER-0028: Consolidate Timeline System into Dedicated Folder - VERIFIED

**Status:** ✅ Implemented - Verified (2026-02-11)
**See:** `ER-verified-0028.md` for full details

---

## ER-0029: Consolidate Citation System with Service Layer - VERIFIED

**Status:** ✅ Implemented - Verified (2026-02-12)
**See:** `ER-verified-0029.md` for full details
**Component:** Citation System Organization
**Priority:** Low
**Date Requested:** 2026-02-03
**Date Implemented:** 2026-02-12
**Dependencies:** ER-0022 Phase 1 (service layer pattern established)

**Rationale:**

The Citation system had 7 view files in `Cumberland/Citation/` with duplicated CRUD operations scattered across views. Citation models remain in `Cumberland/Model/` (per convention from ER-0028). Consolidation adds a service layer and organizes views into subdirectories.

**Implementation:**

**R1: Reorganize Citation Directory** ✅
- Created `Citation/Views/` subdirectory
- Created `Citation/Services/` subdirectory
- Moved 7 view files from `Citation/` to `Citation/Views/`:
  - CitationEditor.swift, CitationViewer.swift, ImageAttributionEditor.swift,
    ImageAttributionViewer.swift, QuickAttributionSheetEditor.swift,
    SourceDetailEditor.swift, SourceEditorSheet.swift
- Model files (Citation.swift, Source.swift, CitationKind.swift, PendingAttribution.swift) remain in `Model/` for schema/migration coherence

**R2: Create CitationManager Service** ✅
- Created `Citation/Services/CitationManager.swift` (~135 lines)
- Extracts all citation CRUD from 5 view files into centralized service
- Public API:
  ```swift
  @MainActor
  final class CitationManager {
      func createCitation(card:source:kind:locator:excerpt:contextNote:) -> Citation
      func updateCitation(_:source:kind:locator:excerpt:contextNote:)
      func deleteCitation(_:)
      func fetchCitations(for card:) -> [Citation]
      func fetchImageCitations(for card:) -> [Citation]
      func createSource(title:authors:) -> Source  // with duplicate check
      func fetchOrCreateSource(title:authors:urlString:) -> Source  // with field merging
      func findSource(byTitle:) -> Source?
  }
  ```

**R3: Refactor Views to Use CitationManager** ✅
- Updated CitationEditor.swift — `createSource()` and `saveCitation()` use CitationManager
- Updated CitationViewer.swift — `reloadCitations()` and `deleteCitation()` use CitationManager
- Updated ImageAttributionEditor.swift — `createSource()` and `saveCitation()` use CitationManager
- Updated ImageAttributionViewer.swift — `reloadImageCitations()` and `deleteAttribution()` use CitationManager
- Updated QuickAttributionSheetEditor.swift — `saveAttribution()` and `fetchOrCreateSource()` use CitationManager

**R4: Update Build Configuration** ✅
- Added 8 new file paths to iOS target membershipExceptions in project.pbxproj
- Added 8 new file paths to visionOS target membershipExceptions in project.pbxproj

**R5: CitationViewer UI Improvements** ✅
- Changed header from "Citations" to "Citations (double-click to edit)" for discoverability
- Added Edit button (blue) to swipe actions alongside existing Delete button

**R6: CitationSummaryView — Read-Only Citation Summary** ✅
- Created `Citation/Views/CitationSummaryView.swift` (~76 lines)
- Compact, read-only summary for CardSheetView and CardRelationshipView
- Uses SwiftData relationship property (`card.citations`) directly — no lifecycle timing issues
- Color-coded dots by citation kind, Chicago short source titles, locator display
- Hidden when card has no citations

**Final Directory Structure:**
```
Cumberland/Citation/
├── Services/
│   └── CitationManager.swift (NEW - centralized CRUD)
└── Views/
    ├── CitationEditor.swift (moved, refactored)
    ├── CitationViewer.swift (moved, refactored)
    ├── ImageAttributionEditor.swift (moved, refactored)
    ├── ImageAttributionViewer.swift (moved, refactored)
    ├── QuickAttributionSheetEditor.swift (moved, refactored)
    ├── SourceDetailEditor.swift (moved)
    └── SourceEditorSheet.swift (moved)

Cumberland/Model/ (unchanged)
├── Citation.swift
├── Source.swift
├── CitationKind.swift
└── PendingAttribution.swift
```

**Build Status:** ✅ macOS and iOS build successfully

**Test Steps:**
1. Create new card
2. Add citation → verify creates correctly
3. Edit citation → verify updates
4. Delete citation → verify removes
5. View image attribution → verify displays
6. Add image attribution → verify creates with source
7. Quick attribution (drop image) → verify source fetch-or-create works

**Files Created:**
- `Cumberland/Citation/Services/CitationManager.swift`
- `Cumberland/Citation/Views/CitationSummaryView.swift`

**Files Moved (Citation/ → Citation/Views/):**
- CitationEditor.swift, CitationViewer.swift, ImageAttributionEditor.swift,
  ImageAttributionViewer.swift, QuickAttributionSheetEditor.swift,
  SourceDetailEditor.swift, SourceEditorSheet.swift

**Files Modified:**
- `Cumberland/Citation/Views/CitationEditor.swift` — uses CitationManager
- `Cumberland/Citation/Views/CitationViewer.swift` — uses CitationManager, updated header text, added Edit swipe action
- `Cumberland/Citation/Views/ImageAttributionEditor.swift` — uses CitationManager
- `Cumberland/Citation/Views/ImageAttributionViewer.swift` — uses CitationManager
- `Cumberland/Citation/Views/QuickAttributionSheetEditor.swift` — uses CitationManager
- `Cumberland/CardSheetView.swift` — added CitationSummaryView
- `Cumberland/CardRelationshipView.swift` — added CitationSummaryView
- `Cumberland.xcodeproj/project.pbxproj` — iOS and visionOS membershipExceptions updated

---

*Last Updated: 2026-02-14*
*ER-0023 verified and moved to ER-verified-0023.md*
