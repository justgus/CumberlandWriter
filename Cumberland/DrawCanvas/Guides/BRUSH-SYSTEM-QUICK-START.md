# Brush System Implementation - Quick Start Guide

## What We're Building

A professional cartography toolkit with:
- **Layer System:** Multiple drawing layers with visibility, opacity, and blend modes
- **Specialized Brushes:** Terrain, water, roads, vegetation, structures, architectural elements
- **Brush Sets:** Switchable collections for exterior maps vs. interior/architectural maps
- **Advanced Tools:** Snap to grid, shape tools, symbol library, text annotations
- **Import/Export:** Share custom brush sets with the community

## Architecture Overview

```
DrawingCanvasView
├── BrushPaletteView (Leading Sidebar)
│   ├── Brush Set Selector
│   ├── Category Filter
│   ├── Brush Grid
│   └── Brush Properties
├── Canvas (Center)
│   ├── Toolbar
│   └── Multi-Layer Canvas
│       ├── Layer N (Annotations)
│       ├── Layer 2 (Structures)
│       └── Layer 1 (Terrain)
└── LayerPanelView (Trailing Sidebar)
    ├── Layer Stack
    ├── Layer Properties
    └── Layer Operations
```

## Key New Classes

### 1. DrawingLayer
```swift
@Observable
class DrawingLayer {
    var name: String
    var isVisible: Bool
    var isLocked: Bool
    var opacity: CGFloat
    var layerType: LayerType
    // Contains drawing data
}
```

### 2. LayerManager
```swift
@Observable
class LayerManager {
    var layers: [DrawingLayer]
    var activeLayer: DrawingLayer?
    
    func createLayer(...)
    func deleteLayer(...)
    func mergeLayer(...)
}
```

### 3. MapBrush
```swift
struct MapBrush {
    var name: String
    var category: BrushCategory
    var pattern: BrushPattern
    var defaultWidth: CGFloat
    var opacity: CGFloat
    // Visual and behavior properties
}
```

### 4. BrushSet
```swift
struct BrushSet {
    var name: String
    var mapType: MapType // exterior, interior, etc.
    var brushes: [MapBrush]
    var defaultLayers: [LayerType]
}
```

### 5. BrushRegistry
```swift
@Observable
class BrushRegistry {
    static let shared = BrushRegistry()
    var installedBrushSets: [BrushSet]
    var activeBrushSet: BrushSet?
}
```

### 6. BrushEngine
```swift
class BrushEngine {
    static func render(
        brush: MapBrush,
        points: [CGPoint],
        context: CGContext
    )
}
```

## Built-In Brush Sets

### Exterior Map Brushes
- **Terrain:** Mountains, hills, valleys, plains
- **Water:** Rivers, lakes, oceans, coastlines
- **Vegetation:** Forests, trees, grasslands
- **Roads:** Highways, roads, paths, railroads
- **Structures:** Cities, towns, buildings, castles

### Interior/Architectural Brushes
- **Walls:** Regular walls, cave walls
- **Openings:** Doors, windows, archways
- **Features:** Stairs, columns, pillars
- **Furniture:** Tables, chairs, beds, chests
- **Dungeon:** Secret doors, traps, rubble

## Sample Brushes

### Mountain Brush
```swift
MapBrush(
    name: "Mountains",
    icon: "mountain.2",
    category: .terrain,
    patternType: .stamp,
    defaultWidth: 40,
    requiresLayer: .terrain,
    snapToGrid: false
)
```

### Wall Brush (Interior)
```swift
MapBrush(
    name: "Wall",
    icon: "rectangle.fill",
    category: .architectural,
    patternType: .solid,
    defaultWidth: 10,
    requiresLayer: .walls,
    snapToGrid: true
)
```

### River Brush
```swift
MapBrush(
    name: "River",
    icon: "drop.fill",
    category: .water,
    patternType: .textured,
    defaultWidth: 20,
    baseColor: .blue,
    taperStart: true,
    taperEnd: true,
    smoothing: 0.8
)
```

## Implementation Order

### Phase 1: Foundation (Weeks 1-2)
**Priority: CRITICAL**
1. Create `DrawingLayer.swift`
2. Create `LayerManager.swift`
3. Create `MapBrush.swift`
4. Create `BrushSet.swift`
5. Create `BrushRegistry.swift`

**Start Here:** `DrawingLayer.swift` - this is the foundation for everything else.

### Phase 2: Brush Sets (Week 3)
**Priority: HIGH**
1. Create `ExteriorMapBrushSet.swift` with ~30 brushes
2. Create `InteriorMapBrushSet.swift` with ~25 brushes
3. Initialize in `BrushRegistry.loadBuiltInBrushSets()`

### Phase 3: Rendering (Weeks 4-5)
**Priority: HIGH**
1. Create `BrushEngine.swift`
2. Implement solid, textured, stamp rendering
3. Integrate with PencilKit (iOS) and Core Graphics (macOS)

### Phase 4: UI (Week 6)
**Priority: HIGH**
1. Create `BrushPaletteView.swift`
2. Create `LayerPanelView.swift`
3. Update `DrawingCanvasView.swift` with new layout

### Phase 5: Advanced Features (Weeks 7-8)
**Priority: MEDIUM**
- Grid snapping
- Shape tools
- Symbol library
- Text annotations

### Phase 6: Import/Export (Week 9)
**Priority: MEDIUM**
- Brush set file format
- Import/export UI
- Validation

## Quick Win: Start Small

### Minimal Viable Implementation (2 days)
1. Create basic `DrawingLayer` class
2. Create `LayerManager` with add/delete
3. Add 5 simple brushes to a basic `BrushSet`
4. Create simple `BrushPaletteView` (list view)
5. Integrate with existing canvas

This proves the concept and provides immediate value!

## Integration with MapWizardView

```swift
// In MapWizardView.swift
@State private var layerManager: LayerManager = LayerManager()
@State private var selectedBrush: MapBrush?

private var drawConfigView: some View {
    HStack(spacing: 0) {
        BrushPaletteView(selectedBrush: $selectedBrush)
        DrawingCanvasView(
            canvasState: $drawingCanvasModel,
            layerManager: $layerManager,
            selectedBrush: $selectedBrush
        )
        LayerPanelView(layerManager: $layerManager)
    }
}

// Auto-configure for map type
private func configureForMapType() {
    if selectedMethod == .interior {
        BrushRegistry.shared.activeBrushSetID = .interior
    } else {
        BrushRegistry.shared.activeBrushSetID = .exterior
    }
}
```

## Testing Strategy

### Unit Tests
```swift
@Test("Layer creation and management")
func testLayerManagement() {
    let manager = LayerManager()
    let layer = manager.createLayer(name: "Test", type: .terrain)
    #expect(manager.layers.count == 1)
    #expect(manager.activeLayer?.id == layer.id)
}

@Test("Brush rendering")
func testBrushRender() {
    let brush = MapBrush(name: "Test", category: .basic)
    let points = [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 100)]
    // Test rendering doesn't crash
}
```

## Common Patterns

### Adding a New Brush
```swift
let mountainBrush = MapBrush(
    id: UUID(),
    name: "Mountains",
    icon: "mountain.2.fill",
    category: .terrain,
    baseColor: .brown,
    defaultWidth: 40,
    minWidth: 20,
    maxWidth: 80,
    opacity: 1.0,
    blendMode: .normal,
    patternType: .stamp,
    requiresLayer: .terrain,
    snapToGrid: false,
    smoothing: 0.5
)
```

### Creating a New Layer
```swift
let terrainLayer = layerManager.createLayer(
    name: "Terrain",
    type: .terrain
)
layerManager.activeLayerID = terrainLayer.id
```

### Rendering a Brush Stroke
```swift
BrushEngine.render(
    brush: selectedBrush,
    points: drawingPath.points,
    context: graphicsContext,
    layer: activeLayer
)
```

## File Organization

```
Drawing/
├── Core/
│   ├── DrawingCanvasView.swift (existing, update)
│   ├── DrawingCanvasModel.swift (existing, update)
│   └── DrawingCanvasViewMacOS.swift (existing, update)
├── Layers/
│   ├── DrawingLayer.swift (NEW)
│   ├── LayerManager.swift (NEW)
│   └── LayerPanelView.swift (NEW)
├── Brushes/
│   ├── MapBrush.swift (NEW)
│   ├── BrushSet.swift (NEW)
│   ├── BrushEngine.swift (NEW)
│   ├── BrushRegistry.swift (NEW)
│   └── BrushPaletteView.swift (NEW)
└── BrushSets/
    ├── ExteriorMapBrushSet.swift (NEW)
    └── InteriorMapBrushSet.swift (NEW)
```

## Next Actions

1. ✅ Read implementation plan
2. ⬜ Create `DrawingLayer.swift` (start here!)
3. ⬜ Create `LayerManager.swift`
4. ⬜ Create `MapBrush.swift`
5. ⬜ Create simple test in MapWizardView
6. ⬜ Iterate and expand

## Key Decisions Made

1. **Layers:** Observable class with per-layer properties
2. **Brushes:** Value type (struct) for easy copying/serialization
3. **Rendering:** Hybrid PencilKit + custom Core Graphics
4. **UI:** Sidebars for brushes (leading) and layers (trailing)
5. **Brush Sets:** Switchable collections, installed/managed by registry
6. **File Format:** JSON-based for brush sets with embedded assets

## Performance Targets

- **60fps** drawing on target devices
- **< 100ms** layer switching
- **< 5s** export of complex maps (10+ layers)
- **< 2 taps** to select any brush

## Questions?

Refer to the full implementation plan (`BRUSH-SYSTEM-IMPLEMENTATION-PLAN.md`) for:
- Detailed class definitions
- Complete brush lists
- UI mockups
- Testing strategies
- Timeline breakdowns

Good luck! Start with Phase 1 and build incrementally. 🚀
