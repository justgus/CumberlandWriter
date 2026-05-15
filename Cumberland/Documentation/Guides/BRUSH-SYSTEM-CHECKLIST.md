# Brush System Implementation Checklist

Track your progress implementing the advanced brush and layer system for map drawing.

---

## Phase 1: Core Infrastructure (Weeks 1-2)

### Layer System
- [ ] **DrawingLayer.swift** - Created starter template ✓
  - [ ] Test layer creation
  - [ ] Test layer serialization (Codable)
  - [ ] Test isEmpty property
  - [ ] Add unit tests
  
- [ ] **LayerManager.swift**
  - [ ] Basic structure with layers array
  - [ ] `createLayer(name:type:)` method
  - [ ] `deleteLayer(id:)` method
  - [ ] `activeLayer` computed property
  - [ ] `duplicateLayer(id:)` method
  - [ ] `moveLayer(from:to:)` method
  - [ ] `mergeLayer(id:into:)` method
  - [ ] `toggleVisibility(id:)` method
  - [ ] `toggleLock(id:)` method
  - [ ] `setOpacity(id:opacity:)` method
  - [ ] `exportComposite()` method
  - [ ] `exportLayer(id:)` method
  - [ ] Add Observable macro
  - [ ] Add unit tests

### Brush System Foundation
- [ ] **MapBrush.swift**
  - [ ] Define MapBrush struct with all properties
  - [ ] BrushCategory enum
  - [ ] BrushPattern enum
  - [ ] Codable conformance
  - [ ] Add sample brushes for testing
  - [ ] Add unit tests

- [ ] **BrushSet.swift**
  - [ ] Define BrushSet struct
  - [ ] MapType enum
  - [ ] Codable conformance
  - [ ] defaultLayers property
  - [ ] Add unit tests

- [ ] **BrushRegistry.swift**
  - [ ] Singleton implementation
  - [ ] installedBrushSets storage
  - [ ] activeBrushSetID property
  - [ ] `loadBuiltInBrushSets()` method
  - [ ] `installBrushSet(_:)` method
  - [ ] `uninstallBrushSet(id:)` method
  - [ ] `exportBrushSet(id:)` method
  - [ ] `importBrushSet(from:)` method
  - [ ] `createCustomBrushSet(name:mapType:)` method
  - [ ] Add Observable macro
  - [ ] Add unit tests

### Integration with Existing Code
- [ ] **Update DrawingCanvasModel.swift**
  - [ ] Add layerManager property
  - [ ] Add selectedBrush property
  - [ ] Update export methods for layers
  - [ ] Update import methods for layers
  - [ ] Add migration from legacy single-layer format

---

## Phase 2: Built-In Brush Sets (Week 3)

### Exterior Map Brush Set
- [ ] **ExteriorMapBrushSet.swift**
  - [ ] File structure created
  - [ ] Terrain brushes (7 brushes)
    - [ ] Mountains
    - [ ] Hills
    - [ ] Valley
    - [ ] Plains
    - [ ] Desert
    - [ ] Tundra
    - [ ] Cliffs
  - [ ] Water brushes (6 brushes)
    - [ ] Ocean
    - [ ] River
    - [ ] Stream
    - [ ] Lake
    - [ ] Marsh
    - [ ] Coastline
  - [ ] Vegetation brushes (5 brushes)
    - [ ] Forest
    - [ ] Single Tree
    - [ ] Jungle
    - [ ] Grassland
    - [ ] Farmland
  - [ ] Roads & Paths brushes (6 brushes)
    - [ ] Highway
    - [ ] Road
    - [ ] Path
    - [ ] Trail
    - [ ] Railroad
    - [ ] Bridge
  - [ ] Structures brushes (6 brushes)
    - [ ] City
    - [ ] Town
    - [ ] Village
    - [ ] Building
    - [ ] Castle
    - [ ] Tower
  - [ ] Default layers configured
  - [ ] BrushSet metadata complete

### Interior/Architectural Brush Set
- [ ] **InteriorMapBrushSet.swift**
  - [ ] File structure created
  - [ ] Architectural brushes (7 brushes)
    - [ ] Wall
    - [ ] Door
    - [ ] Window
    - [ ] Archway
    - [ ] Column
    - [ ] Pillar
    - [ ] Stairs
  - [ ] Room features (4 brushes)
    - [ ] Floor tile
    - [ ] Carpet
    - [ ] Water feature
    - [ ] Pit/Hole
  - [ ] Furniture brushes (5 brushes)
    - [ ] Table
    - [ ] Chair
    - [ ] Bed
    - [ ] Chest
    - [ ] Bookshelf
  - [ ] Dungeon brushes (5 brushes)
    - [ ] Secret Door
    - [ ] Trap
    - [ ] Rubble
    - [ ] Torch/Sconce
    - [ ] Portcullis
  - [ ] Cave Wall brush
  - [ ] Measurement & Grid brushes (4 brushes)
    - [ ] Grid overlay (square)
    - [ ] Grid overlay (hex)
    - [ ] Measurement tool
    - [ ] Scale indicator
  - [ ] Default layers configured
  - [ ] BrushSet metadata complete

### Registry Integration
- [ ] Register built-in brush sets in BrushRegistry
- [ ] Test brush set switching
- [ ] Test brush access by category

---

## Phase 3: Brush Engine & Rendering (Weeks 4-5)

### Core Brush Engine
- [ ] **BrushEngine.swift**
  - [ ] Main render function signature
  - [ ] `renderSolidStroke()` implementation
  - [ ] `renderDashedStroke()` implementation
  - [ ] `renderDottedStroke()` implementation
  - [ ] `renderTexturedStroke()` implementation
  - [ ] `renderStippledStroke()` implementation
  - [ ] `renderStampPattern()` implementation
  - [ ] Pattern generator helpers
    - [ ] `generateTreePattern(at:size:)`
    - [ ] `generateMountainPattern(points:)`
    - [ ] `generateBuildingPattern(rect:)`
  - [ ] Smoothing algorithm
  - [ ] Pressure sensitivity support
  - [ ] Taper support (start/end)

### PencilKit Integration
- [ ] **BrushEngine+PencilKit.swift**
  - [ ] Map MapBrush to PKInkingTool
  - [ ] Custom rendering for unsupported patterns
  - [ ] Hybrid approach implementation
  - [ ] Test on iOS/iPadOS

### macOS Native Rendering
- [ ] **BrushEngine+macOS.swift**
  - [ ] Enhanced DrawingStroke with brush metadata
  - [ ] Pattern rendering with Core Graphics
  - [ ] Stamp brush CGPath implementation
  - [ ] Texture application with CGPattern
  - [ ] Test on macOS

### Multi-Layer Rendering
- [ ] Composite rendering function
- [ ] Apply layer opacity during compositing
- [ ] Apply layer blend modes during compositing
- [ ] Optimize for performance (caching, etc.)

---

## Phase 4: UI Redesign (Week 6)

### Brush Palette View
- [ ] **BrushPaletteView.swift**
  - [ ] Basic layout structure
  - [ ] Brush set selector dropdown
  - [ ] Category filter pills
  - [ ] Brush grid display
  - [ ] Brush selection handling
  - [ ] Brush properties panel
    - [ ] Size slider
    - [ ] Color picker
    - [ ] Opacity slider
  - [ ] Search/filter functionality
  - [ ] Responsive design
  - [ ] Dark mode support

### Layer Panel View
- [ ] **LayerPanelView.swift**
  - [ ] Basic layout structure
  - [ ] Layer list display
  - [ ] Layer row design
    - [ ] Visibility toggle (eye icon)
    - [ ] Lock toggle (lock icon)
    - [ ] Layer name
    - [ ] Active indicator
  - [ ] Layer reordering (drag & drop)
  - [ ] Active layer properties
    - [ ] Opacity slider
    - [ ] Blend mode picker
  - [ ] Layer operations toolbar
    - [ ] New layer button
    - [ ] Merge button
    - [ ] Delete button
  - [ ] Responsive design
  - [ ] Dark mode support

### Canvas Layout Update
- [ ] **DrawingCanvasView.swift** updates
  - [ ] New three-column layout (HStack)
  - [ ] Integrate BrushPaletteView (leading)
  - [ ] Keep canvas in center
  - [ ] Integrate LayerPanelView (trailing)
  - [ ] Dividers between sections
  - [ ] Responsive behavior
  - [ ] Handle sidebar collapse (optional)

### Toolbar Updates
- [ ] Remove old tool selection (now in brush palette)
- [ ] Keep zoom controls
- [ ] Keep undo/redo
- [ ] Add layer-specific tools
- [ ] Streamline for new workflow

---

## Phase 5: Advanced Features (Weeks 7-8)

### Snap to Grid
- [ ] **GridSnapping.swift**
  - [ ] Snap algorithm for points
  - [ ] Configurable snap tolerance
  - [ ] Visual feedback during snapping
  - [ ] Per-brush snap settings
  - [ ] Integration with brush engine

### Shape Tools
- [ ] **ShapeTools.swift**
  - [ ] Rectangle tool
  - [ ] Ellipse tool
  - [ ] Line tool (straight)
  - [ ] Polygon tool
  - [ ] Apply active brush styling to shapes
  - [ ] Preview during drawing
  - [ ] Integration with toolbar

### Symbol Library
- [ ] **SymbolLibrary.swift**
  - [ ] Symbol data model
  - [ ] Built-in symbol collection
  - [ ] Symbol browser UI
  - [ ] Drag-and-drop placement
  - [ ] Symbol scaling/rotation
  - [ ] Custom symbol import
  - [ ] Integration with brush system

### Text Annotation Tool
- [ ] **TextAnnotationTool.swift**
  - [ ] Text placement on canvas
  - [ ] Font picker
  - [ ] Size and style controls
  - [ ] Color customization
  - [ ] Leader line support
  - [ ] Text along path (advanced)
  - [ ] Integration with annotations layer

### Smart Brushes
- [ ] **SmartBrushes.swift**
  - [ ] Road brush auto-intersection
  - [ ] River brush terrain following
  - [ ] Wall brush auto-connection
  - [ ] Pattern brush seamless tiling
  - [ ] Context-aware brush behavior

---

## Phase 6: Import/Export & Sharing (Week 9)

### Brush Set I/O
- [ ] **BrushSetIO.swift**
  - [ ] BrushSetPackage structure
  - [ ] `exportBrushSet(_:)` method
  - [ ] `importBrushSet(from:)` method
  - [ ] `exportAsCumberlandBrushSet(_:)` method
  - [ ] `importFromFile(_:)` method
  - [ ] Validation and error handling

### Community Brush Set Format
- [ ] Define `.cumberland-brushset` format spec
- [ ] manifest.json structure
- [ ] Texture and preview image bundling
- [ ] Version compatibility handling
- [ ] Documentation

### Brush Set Browser
- [ ] **BrushSetBrowserView.swift**
  - [ ] Installed brush sets list
  - [ ] Brush set preview UI
  - [ ] Install from file button
  - [ ] Uninstall/delete functionality
  - [ ] Brush set details view
  - [ ] Search and filter

---

## Phase 7: Integration & Polish (Week 10)

### MapWizardView Integration
- [ ] **MapWizardView.swift** updates
  - [ ] Add brushRegistry state
  - [ ] Add layerManager state
  - [ ] Add selectedBrush state
  - [ ] Pass to canvas views
  - [ ] Auto-configure brush set based on map type
  - [ ] Update draw config view
  - [ ] Update interior config view

### Persistence Updates
- [ ] **DrawingCanvasModel** persistence
  - [ ] `exportCanvasStateWithLayers()` method
  - [ ] `importCanvasStateWithLayers(_:)` method
  - [ ] EnhancedCanvasState structure
  - [ ] Migration from legacy format
  - [ ] Test save/restore workflow

### Performance Optimization
- [ ] Profile rendering performance
- [ ] Implement layer caching
- [ ] Lazy rendering of off-screen content
- [ ] Optimize brush pattern generation
- [ ] Background layer flattening
- [ ] Memory usage optimization

### Keyboard Shortcuts
- [ ] **BrushSystemShortcuts.swift**
  - [ ] Cmd+L: New Layer
  - [ ] Cmd+Shift+L: Toggle Layers Panel
  - [ ] Cmd+B: Toggle Brush Palette
  - [ ] Cmd+Shift+B: Switch Brush Set
  - [ ] Cmd+[: Previous Brush
  - [ ] Cmd+]: Next Brush
  - [ ] H: Hand Tool (pan)
  - [ ] B: Brush Tool
  - [ ] E: Eraser Tool
  - [ ] S: Shape Tool
  - [ ] T: Text Tool
  - [ ] 1-9: Quick select favorites

### Accessibility
- [ ] VoiceOver labels for all controls
- [ ] Keyboard navigation support
- [ ] High contrast mode support
- [ ] Reduced motion support
- [ ] Text labels for icon-only buttons

---

## Phase 8: Testing & Documentation (Week 11)

### Unit Tests
- [ ] **BrushSystemTests.swift**
  - [ ] MapBrush creation and properties
  - [ ] BrushSet creation and brush access
  - [ ] BrushRegistry installation/uninstallation
  - [ ] Brush filtering and search

- [ ] **LayerManagerTests.swift**
  - [ ] Layer creation
  - [ ] Layer deletion
  - [ ] Layer reordering
  - [ ] Layer merging
  - [ ] Layer visibility/locking
  - [ ] Layer export

- [ ] **BrushEngineTests.swift**
  - [ ] Solid stroke rendering
  - [ ] Pattern rendering
  - [ ] Stamp rendering
  - [ ] Smoothing algorithm
  - [ ] Pressure sensitivity

- [ ] **BrushSetIOTests.swift**
  - [ ] Export brush set
  - [ ] Import brush set
  - [ ] Invalid data handling
  - [ ] Version compatibility

### UI Tests
- [ ] Brush selection workflow
- [ ] Layer creation and management
- [ ] Drawing on canvas
- [ ] Switching brush sets
- [ ] Import/export operations

### Performance Tests
- [ ] Large map rendering (10+ layers)
- [ ] Complex brush patterns
- [ ] Layer compositing performance
- [ ] Memory usage with many layers
- [ ] Export performance

### Documentation
- [ ] **BRUSH-SYSTEM-USER-GUIDE.md**
  - [ ] Getting started
  - [ ] Using brush palettes
  - [ ] Managing layers
  - [ ] Creating maps step-by-step
  - [ ] Tips and best practices

- [ ] **CREATING-CUSTOM-BRUSHES.md**
  - [ ] Brush anatomy
  - [ ] Creating a simple brush
  - [ ] Advanced brush properties
  - [ ] Testing your brushes
  - [ ] Sharing brush sets

- [ ] **BRUSH-SET-FORMAT-SPEC.md**
  - [ ] File format specification
  - [ ] manifest.json schema
  - [ ] Asset requirements
  - [ ] Validation rules
  - [ ] Examples

- [ ] **API Documentation**
  - [ ] Add DocC comments to all public APIs
  - [ ] Generate documentation
  - [ ] Add code examples
  - [ ] Update README

---

## Additional Features (Future Phases)

### High Priority
- [ ] Brush favorites system
- [ ] Brush size presets
- [ ] Color palettes
- [ ] Layer blend modes (extended)
- [ ] Layer groups

### Medium Priority
- [ ] Brush pressure curves
- [ ] Symmetry tools
- [ ] Path tools
- [ ] Transform tools
- [ ] Reference images layer

### Low Priority
- [ ] Brush animation
- [ ] Brush randomization
- [ ] Procedural patterns
- [ ] Layer effects
- [ ] History panel

---

## Pre-Release Checklist

### Quality Assurance
- [ ] All unit tests passing
- [ ] All UI tests passing
- [ ] No memory leaks detected
- [ ] Performance targets met
- [ ] Accessibility audit completed
- [ ] Cross-platform testing (iOS, iPadOS, macOS)

### Documentation
- [ ] User guide complete
- [ ] API documentation complete
- [ ] Tutorial videos recorded (optional)
- [ ] Change log updated
- [ ] README updated

### Polish
- [ ] UI/UX review completed
- [ ] Icons and graphics finalized
- [ ] Animations smooth and polished
- [ ] Error messages clear and helpful
- [ ] Dark mode thoroughly tested

### Community
- [ ] Sample brush sets created
- [ ] Example maps created
- [ ] Sharing mechanism tested
- [ ] Feedback collection plan

---

## Progress Tracking

**Started:** [Date]  
**Target Completion:** [Date]  
**Current Phase:** Phase 1 - Core Infrastructure  

**Completed Phases:**
- [x] Planning and Architecture

**In Progress:**
- [ ] Phase 1: Core Infrastructure

**Blocked/Issues:**
- (None yet)

---

## Notes

Use this section for implementation notes, discoveries, and decisions made during development.

### Implementation Notes
- 

### Design Decisions
- 

### Challenges & Solutions
- 

### Performance Observations
- 

---

**Remember:** Start with the MVP (Phases 1-4) before adding advanced features. Get the core working first, then enhance!

**Next File to Create:** `LayerManager.swift` (after reviewing `DrawingLayer.swift`)
