# Brush System Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         MapWizardView                                    │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                     Drawing Configuration View                     │  │
│  │  ┌────────────┬──────────────────────────┬──────────────────────┐ │  │
│  │  │            │                          │                      │ │  │
│  │  │   Brush    │     Canvas Area          │    Layer Panel       │ │  │
│  │  │   Palette  │                          │                      │ │  │
│  │  │            │  ┌────────────────────┐  │  ┌────────────────┐ │ │  │
│  │  │  [Brush    │  │    Toolbar         │  │  │ Layers:        │ │ │  │
│  │  │   Set ▼]   │  ├────────────────────┤  │  │ ☑ Annotations  │ │ │  │
│  │  │            │  │                    │  │  │ ☑ Structures   │ │ │  │
│  │  │ ┌────────┐ │  │   Multi-Layer      │  │  │ ☑ Roads        │ │ │  │
│  │  │ │Category│ │  │   Drawing Canvas   │  │  │ ☑ Water        │ │ │  │
│  │  │ └────────┘ │  │                    │  │  │ ☑ Terrain ◀──  │ │ │  │
│  │  │            │  │  ┌──────────────┐  │  │  │                │ │ │  │
│  │  │ 🖊 🏔 🌊   │  │  │   Layer 5    │  │  │  │ Opacity: ████  │ │ │  │
│  │  │ 🌲 🏠 📍   │  │  │   Layer 4    │  │  │  │ Blend: Normal▼ │ │ │  │
│  │  │ ═══ ··· ▢  │  │  │   Layer 3    │  │  │  │                │ │ │  │
│  │  │            │  │  │   Layer 2    │  │  │  │ [Merge Delete] │ │ │  │
│  │  │ Properties │  │  │   Layer 1    │  │  │  └────────────────┘ │ │  │
│  │  │ ──────────│  │  └──────────────┘  │  │                      │ │  │
│  │  │ Size: ▬▬●─│  │                    │  │                      │ │  │
│  │  │ Color: 🎨 │  │                    │  │                      │ │  │
│  │  │ Opacity:  │  │                    │  │                      │ │  │
│  │  └────────────┴──────────────────────┴──────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    BrushRegistry                            │
│                    (Singleton)                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  installedBrushSets: [BrushSet]                    │    │
│  │  - Exterior Map Brush Set                          │    │
│  │  - Interior/Architectural Brush Set                │    │
│  │  - Custom Set 1                                    │    │
│  │  - Custom Set 2                                    │    │
│  └────────────────────────────────────────────────────┘    │
│                           │                                 │
│                           ▼                                 │
│  ┌────────────────────────────────────────────────────┐    │
│  │  activeBrushSet: BrushSet                          │    │
│  │    - brushes: [MapBrush]                           │    │
│  │    - defaultLayers: [LayerType]                    │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    BrushPaletteView                         │
│                                                             │
│  Shows: activeBrushSet.brushes                              │
│  Filters by: category, search                               │
│  Selects: → selectedBrush                                   │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                 DrawingCanvasModel                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  selectedBrush: MapBrush?                           │   │
│  │  layerManager: LayerManager                         │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           │
                ┌──────────┴──────────┐
                ▼                     ▼
┌────────────────────────┐  ┌─────────────────────────┐
│    LayerManager        │  │   BrushEngine           │
│                        │  │                         │
│  layers: [Layer]       │  │  render(brush, points)  │
│  activeLayer: Layer    │  │                         │
│                        │  │  - renderSolid()        │
│  createLayer()         │  │  - renderTextured()     │
│  deleteLayer()         │  │  - renderStamp()        │
│  mergeLayer()          │  │  - renderPattern()      │
└────────────────────────┘  └─────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│         DrawingLayer                    │
│  ┌───────────────────────────────────┐  │
│  │  id: UUID                         │  │
│  │  name: String                     │  │
│  │  isVisible: Bool                  │  │
│  │  isLocked: Bool                   │  │
│  │  opacity: CGFloat                 │  │
│  │  blendMode: LayerBlendMode        │  │
│  │  layerType: LayerType             │  │
│  │  drawing: PKDrawing (iOS)         │  │
│  │  macosStrokes: [Stroke] (macOS)   │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## Brush Rendering Pipeline

```
User draws on canvas
        │
        ▼
┌────────────────────────────┐
│  Input: Touch/Mouse Points │
│  [p1, p2, p3, ... pn]      │
└────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  Check: selectedBrush                   │
│  - What brush is active?                │
│  - What are its properties?             │
│  - Which layer should receive it?       │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  Preprocessing                          │
│  - Apply smoothing                      │
│  - Snap to grid (if enabled)            │
│  - Apply pressure sensitivity           │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  BrushEngine.render()                   │
│                                         │
│  Switch on brush.patternType:          │
│  ├─ .solid → renderSolidStroke()        │
│  ├─ .dashed → renderDashedStroke()      │
│  ├─ .dotted → renderDottedStroke()      │
│  ├─ .textured → renderTexturedStroke()  │
│  ├─ .stippled → renderStippledStroke()  │
│  └─ .stamp → renderStampPattern()       │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  Platform-specific rendering            │
│                                         │
│  iOS/iPadOS:                            │
│  └─ PKDrawing.append(stroke)            │
│                                         │
│  macOS:                                 │
│  └─ CGContext draw path with style      │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  Add to activeLayer                     │
│  - Mark layer as modified               │
│  - Trigger display update               │
│  - Register undo action                 │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  Composite Rendering                    │
│  For each layer (bottom to top):        │
│    if layer.isVisible:                  │
│      - Apply layer.opacity              │
│      - Apply layer.blendMode            │
│      - Render layer content             │
└─────────────────────────────────────────┘
```

## Brush Set Structure

```
BrushSet: "Exterior Maps"
├── Metadata
│   ├── name: "Exterior Maps"
│   ├── version: "1.0"
│   ├── author: "Built-in"
│   └── mapType: .exterior
│
├── Default Layers
│   ├── Terrain (base)
│   ├── Water
│   ├── Vegetation
│   ├── Roads
│   ├── Structures
│   └── Annotations
│
└── Brushes (grouped by category)
    │
    ├── Terrain (7 brushes)
    │   ├── Mountains
    │   ├── Hills
    │   ├── Valley
    │   ├── Plains
    │   ├── Desert
    │   ├── Tundra
    │   └── Cliffs
    │
    ├── Water Features (6 brushes)
    │   ├── Ocean
    │   ├── River
    │   ├── Stream
    │   ├── Lake
    │   ├── Marsh
    │   └── Coastline
    │
    ├── Vegetation (5 brushes)
    │   ├── Forest
    │   ├── Single Tree
    │   ├── Jungle
    │   ├── Grassland
    │   └── Farmland
    │
    ├── Roads & Paths (6 brushes)
    │   ├── Highway
    │   ├── Road
    │   ├── Path
    │   ├── Trail
    │   ├── Railroad
    │   └── Bridge
    │
    └── Structures (6 brushes)
        ├── City
        ├── Town
        ├── Village
        ├── Building
        ├── Castle
        └── Tower
```

## Layer Compositing Example

```
Final Rendered Map = Composite of all visible layers

Layer 5: Annotations (opacity: 1.0, blend: normal)
   ┌──────────────────────────────────┐
   │  "Dragon's Peak"  📍             │
   │                      🗡 "Dungeon"│
   └──────────────────────────────────┘
                 ↓ Composite with ↓
Layer 4: Structures (opacity: 1.0, blend: normal)
   ┌──────────────────────────────────┐
   │        🏰                         │
   │             🏠🏠🏠               │
   └──────────────────────────────────┘
                 ↓ Composite with ↓
Layer 3: Roads (opacity: 1.0, blend: normal)
   ┌──────────────────────────────────┐
   │    ═══╗                          │
   │       ║                          │
   │       ╚═══════                   │
   └──────────────────────────────────┘
                 ↓ Composite with ↓
Layer 2: Water (opacity: 0.8, blend: multiply)
   ┌──────────────────────────────────┐
   │  ┌─────┐  ~~~~~~~~~~~~~~~~~~~~~~│
   │  │Lake │  ~~~~~~River~~~~~~~~~~~│
   │  └─────┘  ~~~~~~~~~~~~~~~~~~~~~~│
   └──────────────────────────────────┘
                 ↓ Composite with ↓
Layer 1: Terrain (opacity: 1.0, blend: normal)
   ┌──────────────────────────────────┐
   │    /\/\/\    ╱╲╱╲               │
   │   Mountains   Hills              │
   │   ▓▓▓▓▓▓▓▓   ░░░░░  Plains      │
   └──────────────────────────────────┘
                 ↓
   ┌──────────────────────────────────┐
   │ Final Composited Map Image       │
   │                                  │
   │  All layers blended together     │
   │  with their respective opacity   │
   │  and blend modes applied         │
   └──────────────────────────────────┘
```

## Brush Property Examples

### Mountain Brush (Stamp Pattern)
```
MapBrush {
    name: "Mountains"
    category: .terrain
    patternType: .stamp
    defaultWidth: 40
    
    Rendering:
    For each point along path:
      ┌─────┐
      │ /\  │  Draw triangle
      │/  \ │  at this point
      └─────┘
      
    Result: /\/\/\/\/\ (mountain range)
}
```

### River Brush (Textured with Taper)
```
MapBrush {
    name: "River"
    category: .water
    patternType: .textured
    defaultWidth: 20
    baseColor: .blue
    taperStart: true
    taperEnd: true
    
    Rendering:
    ┌───────────────────────────┐
    │ \                         │  Start: thin (source)
    │  ───                      │
    │     ════                  │  Middle: wide
    │        ════               │
    │           ═══             │  End: thin (joins ocean)
    │              ─            │
    └───────────────────────────┘
}
```

### Wall Brush (Solid with Grid Snap)
```
MapBrush {
    name: "Wall"
    category: .architectural
    patternType: .solid
    defaultWidth: 10
    snapToGrid: true
    
    Rendering:
    Grid: · · · · · ·
          · · · · · ·
          · · · · · ·
    
    Draw:  ┌───────┐
           │       │  Snaps to grid intersections
           │       │  Creates straight walls
           └───────┘
}
```

### Forest Brush (Stamp with Scatter)
```
MapBrush {
    name: "Forest"
    category: .vegetation
    patternType: .stamp
    spacing: 30
    scatterAmount: 10
    
    Rendering:
    Along path, place tree symbols with scatter:
    
      🌲  🌲    🌲   🌲
         🌲  🌲   🌲    🌲
      🌲    🌲  🌲  🌲
         🌲  🌲    🌲
}
```

## State Management Flow

```
                    ┌──────────────────┐
                    │   User Action    │
                    └────────┬─────────┘
                             │
            ┌────────────────┼────────────────┐
            ▼                ▼                ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │Select Brush  │  │Select Layer  │  │  Draw Stroke │
    └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
           │                 │                  │
           ▼                 ▼                  ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │selectedBrush │  │activeLayerID │  │Points Array  │
    │    Updated   │  │   Updated    │  │   Captured   │
    └──────────────┘  └──────────────┘  └──────┬───────┘
                                               │
                                               ▼
                                        ┌──────────────┐
                                        │BrushEngine   │
                                        │  .render()   │
                                        └──────┬───────┘
                                               │
                                               ▼
                                        ┌──────────────┐
                                        │ Add to Layer │
                                        └──────┬───────┘
                                               │
                                               ▼
                                        ┌──────────────┐
                                        │Mark Modified │
                                        │Register Undo │
                                        └──────┬───────┘
                                               │
                                               ▼
                                        ┌──────────────┐
                                        │Update Display│
                                        └──────────────┘
```

## Implementation Phases Visual

```
Phase 1: Foundation (Weeks 1-2)
┌────────────────────────────────────────┐
│ ✓ DrawingLayer                         │
│ ✓ LayerManager                         │
│ ✓ MapBrush (struct)                    │
│ ✓ BrushSet (struct)                    │
│ ✓ BrushRegistry                        │
└────────────────────────────────────────┘
            ↓
Phase 2: Brush Sets (Week 3)
┌────────────────────────────────────────┐
│ ✓ ExteriorMapBrushSet (30 brushes)    │
│ ✓ InteriorMapBrushSet (25 brushes)    │
│ ✓ Load built-in sets                   │
└────────────────────────────────────────┘
            ↓
Phase 3: Rendering (Weeks 4-5)
┌────────────────────────────────────────┐
│ ✓ BrushEngine core                     │
│ ✓ Pattern renderers                    │
│ ✓ PencilKit integration                │
│ ✓ macOS Core Graphics integration      │
└────────────────────────────────────────┘
            ↓
Phase 4: UI (Week 6)
┌────────────────────────────────────────┐
│ ✓ BrushPaletteView                     │
│ ✓ LayerPanelView                       │
│ ✓ Updated DrawingCanvasView layout     │
└────────────────────────────────────────┘
            ↓
Phase 5-8: Advanced Features & Polish
┌────────────────────────────────────────┐
│ ✓ Snap to grid                         │
│ ✓ Shape tools                          │
│ ✓ Symbol library                       │
│ ✓ Text annotations                     │
│ ✓ Import/Export brush sets             │
│ ✓ Testing & Documentation              │
└────────────────────────────────────────┘
```

---

This visual guide should help you understand how all the pieces fit together!
