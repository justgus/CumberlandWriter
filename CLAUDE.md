# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Cumberland** is a multi-platform worldbuilding and narrative design application built with SwiftUI and SwiftData. It helps writers organize characters, scenes, locations, relationships, timelines, and maps for complex storytelling projects.

**Platforms**: macOS 26.0+, iOS 26.0+, iPadOS 26.0+, visionOS 26.0+

**Key Technologies**: SwiftUI, SwiftData, CloudKit, PencilKit, MapKit, RealityKit (visionOS)

## Building and Testing

### Build Commands

```bash
# Build for macOS
xcodebuild -scheme Cumberland-macOS -configuration Debug build

# Build for iOS
xcodebuild -scheme "Cumberland IOS" -configuration Debug -sdk iphonesimulator build

# Build for visionOS
xcodebuild -scheme Cumberland_visionOS -configuration Debug build

# Run tests
xcodebuild test -scheme Cumberland-macOS -configuration Debug
```

### Running in Xcode

Open `Cumberland.xcodeproj` and select the appropriate scheme:
- **Cumberland-macOS** - macOS app
- **Cumberland IOS** - iOS/iPadOS app
- **Cumberland_visionOS** - visionOS app

## Core Architecture

### Data Model (SwiftData)

All models are in `Cumberland/Model/`:

- **Card** - Central entity for all content (characters, scenes, locations, maps, etc.)
  - Uses `kindRaw` string for CloudKit compatibility (use `kind` computed property in code)
  - Supports original image storage via `originalImageData` (external storage)
  - Draft map work saved in `draftMapWorkData` for cross-device editing
  - Many-to-many relationships with `StructureElement` (story structure assignments)
  - Edges represented via `CardEdge` (directed graph relationships)

- **StoryStructure** & **StructureElement** - Story structure templates (e.g., "Three-Act Structure")
  - Elements can be assigned to multiple cards (many-to-many)
  - Use `StructureAssignmentManager` for assignments

- **Board** & **BoardNode** - Visual canvas for relationship mapping (Murderboard)

- **Source** & **Citation** - Research source tracking with automatic attribution

- **RelationType** - Custom relationship types between cards

**Schema Versioning**: Currently on `AppSchemaV5`. See `Migrations.swift` for migration history.

### CloudKit Sync

- Container: `iCloud.CumberlandCloud`
- All models use defaults for CloudKit compatibility (no non-optional properties without defaults)
- External storage (`@Attribute(.externalStorage)`) automatically uses CKAsset
- Schema migrations handled via `AppMigrations` plan

### State Management

- `@Observable` used for view models (e.g., `DrawingCanvasModel`, `LayerManager`)
- `@State` for local UI state
- `@AppStorage` for persisted user preferences
- SwiftData `@Query` for database queries

## Major Features

### 1. Map Wizard (`MapWizardView.swift`)

Multi-step wizard for creating maps through four methods:

1. **Import Image** - File picker, Photos picker, drag & drop
2. **Draw** - Full PencilKit drawing canvas with brush system
3. **Capture from Maps** - MapKit integration with location search
4. **AI Generate** - Placeholder for future AI generation

**Drawing System** (`Cumberland/DrawCanvas/`):
- **DrawingCanvasView.swift** - Main canvas UI with zoom/pan
- **LayerManager.swift** - Multi-layer drawing system (similar to Photoshop layers)
- **BrushEngine.swift** - Custom brush system with terrain patterns
- **BrushRegistry.swift** - Centralized brush management
- **TerrainPattern.swift** - Procedural terrain generation
- **BaseLayerPatterns.swift** - Base layer fill types (sand, rock, water, etc.)

Key concepts:
- Layers have types (base, terrain, water, walls, features, etc.)
- Base layer uses procedural fills based on terrain type
- Active layer shown in PencilKit canvas, others composited underneath
- Draft persistence allows resuming work across devices

### 2. Structure Board (`StructureBoardView.swift`)

Kanban-style board for organizing scenes within a story structure:
- **Backlog Lane** - Unassigned scenes
- **Structure Element Lanes** - Scenes assigned to story beats
- Drag & drop between lanes
- Zoom controls and "Fit to Width" functionality

### 3. Murderboard (`Cumberland/Murderboard/MurderBoardView.swift`)

Visual relationship mapping canvas:
- Nodes represent cards
- Edges represent relationships with custom types
- Pan and zoom canvas
- Real-time relationship visualization

### 4. Card Detail Views

Multiple tabs for comprehensive card editing:
- **Details** - Name, subtitle, detailed text, images
- **Relationships** - Graph-based relationship editor
- **Timeline** - Temporal positioning
- **Citations** - Research source tracking
- **Structure** - Story structure assignments

### 5. Cross-Platform Features

#### macOS-specific:
- Window-based card editing (`CardEditorWindowView.swift`)
- Native scrolling and gestures
- Toolbar customization

#### iOS/iPadOS-specific:
- Sheet-based editing (`CardSheetView.swift`)
- Apple Pencil support in drawing canvas
- Touch-optimized UI

#### visionOS:
- Ornament-based controls (`Cumberland/visionOS/OrnamentViews.swift`)
- Spatial UI adaptations
- RealityKit integration (early stages)

## Issue Tracking Systems

This project uses two complementary tracking systems in `Cumberland/DR-Reports/`:

### Discrepancy Reports (DR)
**For bugs, defects, and unintended behavior**

- Active DRs in `DR-unverified.md`
- Verified DRs archived in `DR-verified-XXXX-YYYY.md` batches
- Guidelines in `DR-GUIDELINES.md`
- **Only Claude can mark as "Resolved - Not Verified"**
- **Only user can mark as "Verified" after testing**

### Enhancement Requests (ER)
**For new features, improvements, and planned changes**

- Active ERs in `ER-unverified.md`
- Verified ERs archived in `ER-verified-XXXX.md` batches
- Guidelines in `ER-Guidelines.md`
- Same verification workflow as DRs

**When implementing fixes or features**:
1. Document in appropriate file (DR or ER)
2. Include file:line references
3. Mark as "Resolved/Implemented - Not Verified" when done
4. Leave verification status for user to confirm

## Important Patterns

### SwiftData Queries

```swift
// Basic query
@Query private var cards: [Card]

// Filtered query
@Query(filter: #Predicate<Card> { $0.kind == .characters })
private var characters: [Card]

// Sorted query
@Query(sort: \Card.name, order: .forward)
private var sortedCards: [Card]
```

### CloudKit-Safe Relationships

All relationships must be optional for CloudKit:

```swift
@Relationship(deleteRule: .cascade, inverse: \Citation.card)
var citations: [Citation]? = []  // Optional with default
```

### External Storage for Large Data

```swift
@Attribute(.externalStorage)
var originalImageData: Data?  // Synced as CKAsset
```

### Drawing Canvas Integration

```swift
// Initialize canvas with layer support
@State private var canvasState = DrawingCanvasModel()

// Ensure layer manager exists (auto-initialization)
canvasState.ensureLayerManager()

// Sync drawing with active layer
canvasState.syncDrawingWithActiveLayer()

// Convert drawing to image
let imageData = canvasState.renderToImageData()
```

### Image Storage

- Use `Card.setOriginalImageData(_:)` to set images
- Thumbnails auto-generated on save
- Local cache in `imageFileURL` (not synced)
- Original stored in `originalImageData` (synced)

## Documentation References

Comprehensive documentation in `Cumberland/Documentation/`:

- `Implementation-Status.md` - Map Wizard feature tracking
- `Phase4-DrawingCanvas-Summary.md` - Drawing system details
- `TERRAIN-SYSTEM-DESIGN.md` (in DrawCanvas/) - Terrain generation math

Drawing system documentation in `Cumberland/DrawCanvas/Guides/`:

- `BRUSH-ENGINE-DOCUMENTATION-INDEX.md` - Brush system overview
- `LayerManager-Initialization-Guide.md` - Layer system details
- `MAP_DRAWING_PERSISTENCE_QUICK_REFERENCE.md` - Draft persistence

visionOS documentation in `Cumberland/visionOS/`:

- `visionOS-Adaptation-Plan.md` - Platform adaptation strategy
- `visionOS-Quick-Testing-Guide.md` - Testing procedures

## Common Development Scenarios

### Adding a New Card Kind

1. Add to `Kinds` enum in `Model/Kinds.swift`
2. Update sidebar in `MainAppView.swift`
3. Add column visibility `@AppStorage` property
4. Update filtering logic in `filteredCards` computed property

### Adding a New Brush

1. Create brush configuration in `BrushRegistry.shared.registerBrush()`
2. Define pattern generation in `ProceduralPatternGenerator.swift`
3. Add to appropriate brush set (Exterior/Interior)
4. Update `BrushGridView.swift` to display in palette

### Adding a New Layer Type

1. Add case to `LayerType` enum in `DrawingLayer.swift`
2. Update `defaultName` computed property
3. Add to creation menus in `LayersTabView.swift`
4. Implement rendering if needed in `LayerCompositeView`

### Modifying SwiftData Schema

1. Create new schema version in `Migrations.swift` (e.g., `AppSchemaV6`)
2. Add migration stage (lightweight or custom)
3. Update `AppMigrations.schemas` and `AppMigrations.stages`
4. Test migration thoroughly before deploying

## Platform Conditionals

Use platform checks for platform-specific code:

```swift
#if os(macOS)
// macOS-only code
#elseif os(iOS)
// iOS-only code
#elseif os(visionOS)
// visionOS-only code
#endif

// Framework availability
#if canImport(PencilKit)
import PencilKit
#endif
```

## Key Files to Know

### Entry Points
- `CumberlandApp.swift` - App initialization, SwiftData setup
- `MainAppView.swift` - Main navigation and sidebar

### Core Views
- `CardSheetView.swift` - iOS/iPadOS card detail sheet (large, complex view)
- `CardEditorView.swift` - Card editing form
- `CardRelationshipView.swift` - Relationship graph editor
- `MapWizardView.swift` - Map creation wizard
- `DrawingCanvasView.swift` - Drawing canvas UI

### Data Models
- `Model/Card.swift` - Central entity
- `Model/StoryStructure.swift` - Story structure system
- `Model/Board.swift` - Visual board system
- `Model/Migrations.swift` - Schema versioning

### Drawing System
- `DrawCanvas/DrawingCanvasView.swift` - Canvas UI
- 'DrawCanvas/DrawingCanvasViewMacOS.swift' - Canvas UI on macOS uses different Kit
- `DrawCanvas/LayerManager.swift` - Layer management
- `DrawCanvas/BrushEngine.swift` - Brush rendering
- `DrawCanvas/TerrainPattern.swift` - Procedural generation

### Utilities
- `Images/ImageStore.swift` - Local image caching
- `Citation/CitationGenerator.swift` - Automatic attribution

## Code Style Notes

- Use `// MARK:` for code organization
- Document complex algorithms (see `TerrainPattern.swift` for examples)
- Prefer SwiftUI over UIKit/AppKit when possible
- Use computed properties for derived state
- Keep views focused - extract subviews when body gets large
- Use descriptive variable names (avoid abbreviations)

## Performance Considerations

- Drawing operations use high-quality 2x rendering
- Large images stored externally (CloudKit CKAsset)
- Queries optimized with predicates and fetch limits
- Layer compositing happens on-demand during rendering
- Terrain generation cached per layer

## Testing

Tests in `CumberlandTests/`:
- `CitationTests.swift` - Citation system tests
- `StoryStructureTests.swift` - Structure assignment tests
- Currently limited test coverage - opportunity for expansion
