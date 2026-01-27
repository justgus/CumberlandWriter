# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Cumberland** is a multi-platform worldbuilding and narrative design application built with SwiftUI and SwiftData. It helps writers organize characters, scenes, locations, relationships, timelines, and maps for complex storytelling projects.

**Platforms**: macOS 26.0+, iOS 26.0+, iPadOS 26.0+, visionOS 26.0+

**Key Technologies**: SwiftUI, SwiftData, CloudKit, PencilKit, MapKit, RealityKit (visionOS)

## Development Environment Requirements

**CRITICAL**: This project uses cutting-edge Apple technologies and deployment targets.

### Minimum Versions - DO NOT ASSUME OLDER VERSIONS

- **Xcode**: 26.2+ (build 17C52)
- **macOS**: 26.2+
- **iOS/iPadOS**: 26.2+
- **visionOS**: 26.2+
- **Swift**: 5.0+ with upcoming features enabled

**NEVER assume features, APIs, or behaviors from earlier versions of Xcode or any Apple platform.**

### Official Documentation

When researching APIs, features, or behaviors, ONLY reference current documentation:

- **Xcode 26 Release Notes**: https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes
- **macOS 26 APIs**: https://developer.apple.com/documentation/macos-release-notes/
- **iOS 26 APIs**: https://developer.apple.com/documentation/ios-ipados-release-notes/
- **visionOS 26 APIs**: https://developer.apple.com/documentation/visionos-release-notes/
- **SwiftData Documentation**: https://developer.apple.com/documentation/swiftdata
- **Swift Testing (not XCTest)**: https://developer.apple.com/documentation/testing

### Key Technology Features Used

This project uses **modern** Swift and SwiftUI features that may not exist in older SDKs:

- **Swift Testing** framework (NOT XCTest) - introduced in Xcode 26
- **SwiftData** with Schema versioning and migrations
- **@Observable** macro (Swift 5.9+)
- **#Predicate** macro for SwiftData queries
- **Upcoming Swift features** enabled via compiler flags
- **Apple Intelligence APIs** (iOS 26.2+, macOS 26.2+, visionOS 26.2+)

### Verification Steps

Before making assumptions about API availability or behavior:

1. **Check the deployment target**: All platforms target version 26.0 minimum
2. **Verify API availability**: Use `@available` checks or `#available` for runtime checks
3. **Consult current documentation**: Use the URLs above, not outdated Stack Overflow answers
4. **Test on the actual platform**: Code that works in older SDKs may not compile or behave correctly with newer deployment targets

### Common Pitfalls to Avoid

- ❌ Assuming XCTest instead of Swift Testing
- ❌ Using deprecated SwiftData patterns from WWDC 2023
- ❌ Referencing earlier than iOS 26 API documentation
- ❌ Assuming CloudKit behaviors from older SDK versions
- ❌ Using pre-Swift 5.9 concurrency patterns
- ❌ Ignoring Swift 6 language mode compatibility

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

### Understanding and Using RelationTypes

**CRITICAL CONCEPT**: RelationTypes define bidirectional relationships with directional verbiage.

**Format**: `"forward/backward"`
- **First part (before slash)**: How the SOURCE card relates to the TARGET card
- **Second part (after slash)**: How the TARGET card relates to the SOURCE card

**Key Properties**:
- Relationships are **bidirectional** (always stored as CardEdge from source to target)
- Verbiage is **directional** (describes the relationship in each direction)
- Can be **reversed** without changing meaning

**Examples**:
```swift
// "owns/owned-by" RelationType
Aria → "owns/owned-by" → Shadowblade
  ↑                        ↑
  SOURCE                  TARGET

Reading: "Aria owns Shadowblade" AND "Shadowblade is owned-by Aria"

// Same relationship, reversed perspective:
Shadowblade → "owned-by/owns" → Aria
  ↑                              ↑
  SOURCE                        TARGET

Reading: "Shadowblade is owned-by Aria" AND "Aria owns Shadowblade"
```

**More Examples**:
- `"uses/used-by"` - Character uses Artifact / Artifact used-by Character
- `"born-in/birthplace-of"` - Character born-in Location / Location birthplace-of Character
- `"part-of/contains"` - Building part-of Location / Location contains Building
- `"appears-in/features"` - Character appears-in Scene / Scene features Character

**When Creating Relationships in Code**:
1. Determine SOURCE and TARGET cards
2. Choose appropriate RelationType
3. Use the FIRST part of the slash for the forward relationship
4. The SECOND part describes the reverse (automatically understood)
5. Store as CardEdge from source to target

**AI Relationship Inference** (Phase 6):
- Parse sentence structure to identify relationships
- Determine source and target entities
- Select RelationType where FIRST part matches the inferred relationship
- Example: "Aria drew the Shadowblade"
  - Source: Aria
  - Target: Shadowblade
  - Action: "drew" → implies ownership/usage
  - RelationType: "owns/owned-by" OR "uses/used-by"
  - Result: Aria → "owns/owned-by" → Shadowblade

**See**: `Model/RelationType.swift` for all available relationship types

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

### Known Testing Issues

**Test Import Configuration (As of 2026-01-21)**

The test targets currently have a configuration issue where `@testable import Cumberland` fails with "Unable to find module dependency: 'Cumberland'".

**DO NOT attempt to fix this without explicit user direction.** Previous attempts to resolve this issue by:
- Modifying TEST_HOST and BUNDLE_LOADER settings
- Editing scheme configurations
- Changing test target dependencies
- Adjusting project.pbxproj directly

...have all failed. The root cause appears to be related to multi-platform test target configuration and requires manual intervention in Xcode's GUI.

**Temporary workaround**: Test files for new features have been renamed to `.swift.skip` to prevent compilation until the test infrastructure is properly configured.

If tasked with test-related work, verify with the user first that test targets can successfully import the main module before proceeding.
