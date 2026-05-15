# Phase 1 Architecture Diagram

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Cumberland Map Wizard                        │
│                        Advanced Brush & Layer System                 │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                           USER INTERFACE                              │
│                         (Phase 4 - Future)                            │
├──────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │ BrushPaletteView│  │ DrawingCanvasView│  │  LayerPanelView │     │
│  │                 │  │                  │  │                 │     │
│  │ - Brush Grid    │  │ - Canvas Display │  │ - Layer List    │     │
│  │ - Categories    │  │ - Tool Toolbar   │  │ - Properties    │     │
│  │ - Properties    │  │ - Zoom Controls  │  │ - Operations    │     │
│  └────────┬────────┘  └────────┬─────────┘  └────────┬────────┘     │
│           │                    │                      │              │
└───────────┼────────────────────┼──────────────────────┼──────────────┘
            │                    │                      │
            ▼                    ▼                      ▼
┌──────────────────────────────────────────────────────────────────────┐
│                        BUSINESS LOGIC LAYER                           │
│                         (Phase 1 - ✅ Complete)                       │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     BrushRegistry (Singleton)                │   │
│  │  - installedBrushSets: [BrushSet]                           │   │
│  │  - activeBrushSetID: UUID?                                  │   │
│  │  - selectedBrushID: UUID?                                   │   │
│  │                                                              │   │
│  │  Methods:                                                    │   │
│  │  - loadBuiltInBrushSets()                                   │   │
│  │  - installBrushSet(), uninstallBrushSet()                   │   │
│  │  - setActiveBrushSet(), selectBrush()                       │   │
│  │  - exportBrushSet(), importBrushSet()                       │   │
│  │  - searchBrushes(), brushes(in:)                            │   │
│  └──────────────────────────┬───────────────────────────────────┘   │
│                             │                                        │
│                             │ contains                               │
│                             ▼                                        │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                        BrushSet                              │   │
│  │  - id, name, description, mapType                           │   │
│  │  - brushes: [MapBrush]                                      │   │
│  │  - defaultLayers: [LayerType]                               │   │
│  │  - isBuiltIn, isInstalled                                   │   │
│  │                                                              │   │
│  │  Methods:                                                    │   │
│  │  - addBrush(), removeBrush(), updateBrush()                 │   │
│  │  - brushes(in: BrushCategory)                               │   │
│  │  - createDefaultLayerManager()                              │   │
│  └──────────────────────────┬───────────────────────────────────┘   │
│                             │                                        │
│                             │ contains                               │
│                             ▼                                        │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                        MapBrush                              │   │
│  │  - id, name, icon, category                                 │   │
│  │  - Visual: baseColor, width, opacity, blendMode             │   │
│  │  - Behavior: pressureSensitivity, tapering, smoothing       │   │
│  │  - Pattern: patternType, textureImage, spacing              │   │
│  │  - Effects: scatterAmount, rotationVariation                │   │
│  │  - Constraints: requiresLayer, snapToGrid                   │   │
│  └──────────────────────────┬───────────────────────────────────┘   │
│                             │                                        │
│                             │ used by                                │
│                             ▼                                        │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                      BrushEngine                             │   │
│  │  Static Methods:                                             │   │
│  │  - createPKTool(from:color:width:) -> PKTool               │   │
│  │  - renderStroke(brush:points:color:width:context:)         │   │
│  │  - smoothPath(points:amount:) -> [CGPoint]                 │   │
│  │  - snapToGrid(points:gridSpacing:) -> [CGPoint]            │   │
│  │                                                              │   │
│  │  Pattern Renderers:                                          │   │
│  │  - renderSolidStroke()                                      │   │
│  │  - renderDashedStroke()                                     │   │
│  │  - renderDottedStroke()                                     │   │
│  │  - renderStippledStroke()                                   │   │
│  │  - renderStampStroke()                                      │   │
│  │  - renderHatchedStroke()                                    │   │
│  │  - renderCrossHatchedStroke()                               │   │
│  │  - renderTexturedStroke() [Phase 3]                         │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     LayerManager                             │   │
│  │  - layers: [DrawingLayer]                                   │   │
│  │  - activeLayerID: UUID?                                     │   │
│  │                                                              │   │
│  │  Methods:                                                    │   │
│  │  - createLayer(), deleteLayer(), duplicateLayer()           │   │
│  │  - moveLayer(), mergeLayer()                                │   │
│  │  - toggleVisibility(), toggleLock()                         │   │
│  │  - setOpacity(), setBlendMode()                             │   │
│  │  - exportComposite(), exportLayer()                         │   │
│  └──────────────────────────┬───────────────────────────────────┘   │
│                             │                                        │
│                             │ manages                                │
│                             ▼                                        │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                      DrawingLayer                            │   │
│  │  - id, name, order                                          │   │
│  │  - isVisible, isLocked                                      │   │
│  │  - opacity, blendMode                                       │   │
│  │  - layerType: LayerType                                     │   │
│  │  - drawing: PKDrawing (iOS/iPadOS)                          │   │
│  │  - macosStrokes: [DrawingStroke] (macOS)                    │   │
│  │                                                              │   │
│  │  Methods:                                                    │   │
│  │  - isEmpty: Bool                                            │   │
│  │  - markModified()                                           │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                         PERSISTENCE LAYER                             │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────┐  ┌─────────────────────┐                   │
│  │ BrushSetCollection  │  │   LayerManager      │                   │
│  │                     │  │   (Codable)         │                   │
│  │ Saved to:           │  │                     │                   │
│  │ Cumberland_         │  │ Embedded in:        │                   │
│  │ BrushSets.json      │  │ Canvas state or     │                   │
│  │                     │  │ Draft data          │                   │
│  └─────────────────────┘  └─────────────────────┘                   │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   BrushSetPackage                            │   │
│  │                                                              │   │
│  │  File format: .cumberland-brushset (JSON)                   │   │
│  │  Contains:                                                   │   │
│  │  - metadata: BrushSetMetadata                               │   │
│  │  - brushes: [MapBrush]                                      │   │
│  │  - previewImages: [String: Data]                            │   │
│  │  - textures: [String: Data]                                 │   │
│  │  - thumbnailImage: Data?                                    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagrams

### 1. Drawing Workflow

```
User draws on canvas
        │
        ▼
┌───────────────────┐
│ Input points      │ [CGPoint]
│ collected         │
└─────────┬─────────┘
          │
          ▼
┌───────────────────────────┐
│ BrushRegistry.selected    │
│ Brush retrieved           │
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ BrushEngine.renderStroke  │
│ - Apply brush properties  │
│ - Apply smoothing         │
│ - Render pattern          │
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ LayerManager.activeLayer  │
│ - Add stroke to layer     │
│ - Mark layer modified     │
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ Canvas updates            │
│ Display rendered stroke   │
└───────────────────────────┘
```

### 2. Layer Compositing

```
Export request
        │
        ▼
┌───────────────────────────┐
│ LayerManager              │
│ .exportComposite()        │
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ Get all visible layers    │
│ Sort by order (z-index)   │
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ Create graphics context   │
│ Draw background           │
└─────────┬─────────────────┘
          │
          ▼
    ┌─────────┐
    │ For each│
    │ layer   │
    └────┬────┘
         │
         ▼
┌───────────────────────────┐
│ Apply layer properties:   │
│ - Set opacity             │
│ - Set blend mode          │
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ Draw layer content:       │
│ - PKDrawing if available  │
│ - macosStrokes if any     │
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ Restore context state     │
└─────────┬─────────────────┘
          │
          ▼
    ┌─────────┐
    │ Next    │
    │ layer   │
    └────┬────┘
         │
         ▼
┌───────────────────────────┐
│ Export final image        │
│ Return PNG data           │
└───────────────────────────┘
```

### 3. Brush Set Import

```
User selects .cumberland-brushset file
        │
        ▼
┌───────────────────────────┐
│ Read file data            │
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ Decode BrushSetPackage    │
│ - Metadata                │
│ - Brushes                 │
│ - Textures                │
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ Convert to BrushSet       │
│ Check for ID conflicts    │
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ BrushRegistry             │
│ .installBrushSet()        │
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ Add to installed sets     │
│ Save registry to disk     │
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ UI updates with new set   │
└───────────────────────────┘
```

---

## Type Relationships

```
BrushCategory ◄───┐
                  │
LayerType ◄───────┼───┐
                  │   │
LayerBlendMode ◄──┼───┼───┐
                  │   │   │
                  │   │   │
┌─────────────────▼───▼───▼───────────────────┐
│              MapBrush                        │
│  - category: BrushCategory                  │
│  - requiresLayer: LayerType?                │
│  - blendMode: LayerBlendMode                │
└──────────────────┬──────────────────────────┘
                   │
                   │ *
┌──────────────────▼──────────────────────────┐
│              BrushSet                        │
│  - brushes: [MapBrush]                      │
│  - defaultLayers: [LayerType]               │
└──────────────────┬──────────────────────────┘
                   │
                   │ *
┌──────────────────▼──────────────────────────┐
│           BrushRegistry                      │
│  - installedBrushSets: [BrushSet]           │
│  - selectedBrush: MapBrush?                 │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│           DrawingLayer                       │
│  - layerType: LayerType                     │
│  - blendMode: LayerBlendMode                │
│  - drawing: PKDrawing                       │
│  - macosStrokes: [DrawingStroke]            │
└──────────────────┬──────────────────────────┘
                   │
                   │ *
┌──────────────────▼──────────────────────────┐
│           LayerManager                       │
│  - layers: [DrawingLayer]                   │
│  - activeLayer: DrawingLayer?               │
└──────────────────────────────────────────────┘
```

---

## Platform-Specific Implementations

```
┌─────────────────────────────────────────────────────────────┐
│                     DrawingLayer                            │
└───────────────────────┬─────────────────────────────────────┘
                        │
           ┌────────────┴────────────┐
           │                         │
           ▼                         ▼
┌──────────────────┐      ┌──────────────────┐
│  iOS/iPadOS      │      │     macOS        │
│                  │      │                  │
│  drawing:        │      │  macosStrokes:   │
│  PKDrawing       │      │  [DrawingStroke] │
│                  │      │                  │
│  Uses PencilKit  │      │  Custom CGPath   │
│  natively        │      │  rendering       │
└──────────────────┘      └──────────────────┘
```

```
┌─────────────────────────────────────────────────────────────┐
│                      BrushEngine                            │
└───────────────────────┬─────────────────────────────────────┘
                        │
           ┌────────────┴────────────┐
           │                         │
           ▼                         ▼
┌──────────────────┐      ┌──────────────────┐
│  With PencilKit  │      │  Core Graphics   │
│                  │      │                  │
│  createPKTool()  │      │  renderStroke()  │
│                  │      │                  │
│  Direct PKTool   │      │  Custom pattern  │
│  conversion      │      │  rendering       │
└──────────────────┘      └──────────────────┘
```

---

## Enumerations Hierarchy

```
BrushCategory (10 cases)
├── basic
├── terrain
├── water
├── roads
├── vegetation
├── structures
├── architectural
├── symbols
├── text
└── effects

LayerType (11 cases)
├── terrain
├── water
├── vegetation
├── roads
├── structures
├── walls
├── features
├── furniture
├── annotations
├── reference
└── generic

BrushPattern (8 cases)
├── solid
├── dashed
├── dotted
├── stippled
├── textured
├── stamp
├── hatched
└── crossHatched

LayerBlendMode (16 cases)
├── normal
├── multiply
├── screen
├── overlay
├── darken
├── lighten
├── colorBurn
├── colorDodge
├── softLight
├── hardLight
├── difference
├── exclusion
├── hue
├── saturation
├── color
└── luminosity

MapType (4 cases)
├── exterior
├── interior
├── hybrid
└── custom
```

---

## Key Design Patterns Used

1. **Singleton Pattern**
   - `BrushRegistry.shared` - Single source of truth for brushes

2. **Observable Pattern**
   - All manager classes use `@Observable` for SwiftUI integration
   - Automatic UI updates when data changes

3. **Strategy Pattern**
   - `BrushEngine` uses different rendering strategies based on `BrushPattern`

4. **Repository Pattern**
   - `BrushRegistry` manages brush set storage and retrieval

5. **Factory Pattern**
   - Static factory methods on `MapBrush` (`.basicPen`, `.marker`, etc.)
   - `BrushSet.createDefaultLayerManager()`

6. **Composite Pattern**
   - `LayerManager` composites multiple `DrawingLayer`s
   - `BrushSet` groups multiple `MapBrush`es

7. **Value Semantics**
   - `MapBrush`, `BrushSet`, `DrawingStroke` are structs (value types)
   - Predictable copying and passing behavior

8. **Codable Protocol**
   - All data models conform to `Codable` for serialization
   - Enables persistence and import/export

---

## Extension Points for Future Phases

### Phase 2: Built-In Brush Sets
- Add concrete brush implementations to `BrushRegistry.loadBuiltInBrushSets()`
- Create specialized brushes for cartography

### Phase 3: Enhanced Rendering
- Extend `BrushEngine` with texture support
- Add pattern generators (trees, mountains, buildings)
- Create platform-specific optimizations

### Phase 4: UI Components
- Build `BrushPaletteView` using `BrushRegistry`
- Build `LayerPanelView` using `LayerManager`
- Integrate with existing `DrawingCanvasView`

### Phase 5: Advanced Features
- Smart brushes with context awareness
- Procedural pattern generation
- Tool integration (shapes, symbols, text)

---

## Thread Safety Considerations

- `BrushRegistry` is accessed via singleton on main thread
- `LayerManager` mutations should happen on main thread (SwiftUI context)
- Rendering in `BrushEngine` is stateless (thread-safe static methods)
- Export operations could be moved to background threads for large canvases

---

## Memory Management

- Layers contain drawing data (can be large)
- Brush textures stored as `Data` (can be large)
- Consider lazy loading for:
  - Brush preview images
  - Layer thumbnails
  - Off-screen layer content

---

## Testing Strategy

### Unit Tests
- [x] Layer creation, deletion, reordering
- [x] Layer property changes (opacity, visibility, blend mode)
- [x] Brush set installation/uninstallation
- [x] Brush registry selection logic
- [x] Import/export serialization

### Integration Tests
- [ ] Layer compositing with multiple blend modes
- [ ] Brush rendering with various patterns
- [ ] End-to-end drawing workflow

### UI Tests
- [ ] Brush palette interaction (Phase 4)
- [ ] Layer panel operations (Phase 4)
- [ ] Drawing canvas integration (Phase 4)
