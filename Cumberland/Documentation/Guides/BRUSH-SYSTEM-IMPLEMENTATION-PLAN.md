# Advanced Brush System & Layers Implementation Plan

## Executive Summary

This plan details the implementation of a professional-grade brush system with layers specifically designed for cartography and architectural drawing in the Map Wizard. The system will support multiple brush sets (exterior maps, interior/architectural, custom), layer management, and a redesigned UI optimized for map creation.

---

## Phase 1: Core Infrastructure (Week 1-2)

### 1.1 Layer System Foundation

**Files to Create:**
- `DrawingLayer.swift` - Layer model and management
- `LayerManager.swift` - Layer stack management and operations

**Key Types:**

```swift
/// Represents a single drawing layer with its own content and properties
@Observable
class DrawingLayer: Identifiable, Codable {
    let id: UUID
    var name: String
    var isVisible: Bool
    var isLocked: Bool
    var opacity: CGFloat
    var blendMode: CGBlendMode
    
    // Platform-specific drawing data
    #if canImport(PencilKit)
    var drawing: PKDrawing
    #endif
    var macosStrokes: [DrawingStroke] // For macOS native
    
    // Layer type affects available brushes
    var layerType: LayerType
    var order: Int // Z-index for rendering
}

enum LayerType: String, CaseIterable, Codable {
    case terrain = "Terrain"
    case landscape = "Landscape Features"
    case structures = "Structures"
    case annotations = "Annotations"
    case reference = "Reference"
}
```

**LayerManager Implementation:**
```swift
@Observable
class LayerManager {
    var layers: [DrawingLayer] = []
    var activeLayerID: UUID?
    
    var activeLayer: DrawingLayer? {
        layers.first { $0.id == activeLayerID }
    }
    
    // Layer Operations
    func createLayer(name: String, type: LayerType) -> DrawingLayer
    func deleteLayer(id: UUID)
    func duplicateLayer(id: UUID) -> DrawingLayer
    func moveLayer(from: Int, to: Int)
    func mergeLayer(id: UUID, into targetID: UUID)
    
    // Visibility & Locking
    func toggleVisibility(id: UUID)
    func toggleLock(id: UUID)
    func setOpacity(id: UUID, opacity: CGFloat)
    
    // Export
    func exportComposite() -> Data? // Flattened all layers
    func exportLayer(id: UUID) -> Data?
}
```

### 1.2 Brush System Foundation

**Files to Create:**
- `MapBrush.swift` - Brush model and properties
- `BrushSet.swift` - Brush collection and metadata
- `BrushEngine.swift` - Brush rendering logic
- `BrushRegistry.swift` - Central brush management

**Key Types:**

```swift
/// Defines a single brush with rendering properties
struct MapBrush: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String // SF Symbol name
    var category: BrushCategory
    
    // Visual Properties
    var baseColor: Color?
    var defaultWidth: CGFloat
    var minWidth: CGFloat
    var maxWidth: CGFloat
    
    // Behavior Properties
    var opacity: CGFloat
    var blendMode: CGBlendMode
    var pressureSensitivity: Bool
    var taperStart: Bool
    var taperEnd: Bool
    
    // Pattern/Texture
    var patternType: BrushPattern
    var textureImage: Data? // Optional custom texture
    var spacing: CGFloat // For stamp-like brushes
    var scatterAmount: CGFloat
    
    // Constraints
    var requiresLayer: LayerType?
    var snapToGrid: Bool
    var smoothing: CGFloat // Path smoothing 0-1
}

enum BrushCategory: String, CaseIterable, Codable {
    case basic = "Basic"
    case terrain = "Terrain"
    case water = "Water Features"
    case roads = "Roads & Paths"
    case vegetation = "Vegetation"
    case structures = "Structures"
    case architectural = "Architectural"
    case symbols = "Symbols"
    case text = "Text"
}

enum BrushPattern: String, Codable {
    case solid
    case dashed
    case dotted
    case stippled
    case textured
    case stamp // For symbols, trees, etc.
}
```

**BrushSet Implementation:**
```swift
/// A collection of brushes for a specific map type
struct BrushSet: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var mapType: MapType
    var brushes: [MapBrush]
    var defaultLayers: [LayerType]
    var thumbnail: Data?
    var author: String?
    var version: String
    var isBuiltIn: Bool
    var isInstalled: Bool
}

enum MapType: String, CaseIterable, Codable {
    case exterior = "Exterior/World Maps"
    case interior = "Interior/Architectural"
    case hybrid = "Hybrid"
    case custom = "Custom"
}
```

**BrushRegistry Implementation:**
```swift
@Observable
class BrushRegistry {
    static let shared = BrushRegistry()
    
    var installedBrushSets: [BrushSet] = []
    var activeBrushSetID: UUID?
    
    var activeBrushSet: BrushSet? {
        installedBrushSets.first { $0.id == activeBrushSetID }
    }
    
    // Registry Management
    func loadBuiltInBrushSets()
    func installBrushSet(_ brushSet: BrushSet) throws
    func uninstallBrushSet(id: UUID) throws
    func exportBrushSet(id: UUID) -> Data?
    func importBrushSet(from data: Data) throws -> BrushSet
    
    // Brush Set Creation
    func createCustomBrushSet(name: String, mapType: MapType) -> BrushSet
}
```

---

## Phase 2: Built-In Brush Sets (Week 3)

### 2.1 Exterior Map Brush Set

**File:** `BrushSets/ExteriorMapBrushSet.swift`

**Brushes to Implement:**

1. **Terrain Category:**
   - Mountain brush (triangular peaks pattern)
   - Hill brush (rounded bump pattern)
   - Valley brush (inverted hill pattern)
   - Plains brush (simple fill)
   - Desert brush (stippled texture)
   - Tundra brush (sparse stipple)

2. **Water Features Category:**
   - Ocean/Sea brush (wavy lines, blue)
   - River brush (smooth flowing lines, tapered)
   - Stream brush (thin river variant)
   - Lake brush (enclosed water body)
   - Marsh/Swamp brush (mixed water/land texture)
   - Waterfall brush (vertical cascade symbol)

3. **Vegetation Category:**
   - Forest brush (clustered tree symbols)
   - Single Tree brush (individual tree stamp)
   - Jungle brush (dense tree pattern)
   - Grassland brush (sparse grass texture)
   - Farmland brush (rectangular field pattern)

4. **Roads & Paths Category:**
   - Highway brush (thick double line)
   - Road brush (medium single line)
   - Path brush (dashed line)
   - Trail brush (dotted line)
   - Railroad brush (line with cross-ties)
   - Bridge brush (special road segment)

5. **Structures Category:**
   - City brush (cluster of rectangles)
   - Town brush (smaller cluster)
   - Village brush (few buildings)
   - Single Building brush (simple rectangle)
   - Castle brush (fortified structure symbol)
   - Tower brush (small circular structure)

6. **Coastline & Borders:**
   - Coastline brush (irregular edge with wave texture)
   - Border brush (dashed/dotted political boundary)
   - Cliff brush (hatched edge)

**Default Layers:**
- Terrain (base)
- Water
- Vegetation
- Roads
- Structures
- Labels

### 2.2 Interior/Architectural Brush Set

**File:** `BrushSets/InteriorMapBrushSet.swift`

**Brushes to Implement:**

1. **Architectural Elements:**
   - Wall brush (thick solid line, snap to grid)
   - Door brush (gap with arc swing indicator)
   - Window brush (gap with cross marks)
   - Archway brush (curved opening)
   - Column brush (filled circle stamp)
   - Pillar brush (square stamp)
   - Stairs brush (parallel lines with direction arrow)

2. **Room Features:**
   - Floor tile brush (grid pattern)
   - Carpet brush (textured fill)
   - Water feature brush (pool/fountain fill)
   - Pit/Hole brush (dark fill with edge hatching)

3. **Furniture (stamps):**
   - Table brush (rectangle with border)
   - Chair brush (small square with back)
   - Bed brush (rectangle with pillow indication)
   - Chest brush (small rectangle)
   - Bookshelf brush (rectangle with lines)

4. **Dungeon Specific:**
   - Secret Door brush (wall with hidden indicator)
   - Trap brush (symbol overlay)
   - Rubble brush (scattered stone texture)
   - Torch/Sconce brush (wall-mounted light symbol)
   - Portcullis brush (grated gate)
   - Cave Wall brush (irregular natural wall)

5. **Measurement & Grid:**
   - Grid overlay brush (square grid)
   - Hex overlay brush (hexagonal grid)
   - Measurement tool (distance line with numbers)
   - Scale indicator brush

**Default Layers:**
- Base Floor
- Walls
- Doors & Windows
- Furniture
- Features
- Grid
- Annotations

---

## Phase 3: Brush Engine & Rendering (Week 4-5)

### 3.1 Brush Rendering Engine

**File:** `BrushEngine.swift`

**Key Components:**

```swift
class BrushEngine {
    // Render a brush stroke
    static func render(
        brush: MapBrush,
        points: [CGPoint],
        context: CGContext,
        layer: DrawingLayer
    )
    
    // Specialized renderers
    private static func renderSolidStroke(...)
    private static func renderTexturedStroke(...)
    private static func renderStampPattern(...)
    private static func renderDashedStroke(...)
    
    // Pattern generators
    private static func generateTreePattern(at point: CGPoint, size: CGFloat) -> CGPath
    private static func generateMountainPattern(points: [CGPoint]) -> CGPath
    private static func generateBuildingPattern(rect: CGRect) -> CGPath
}
```

### 3.2 PencilKit Integration

**File:** `BrushEngine+PencilKit.swift`

- Map MapBrush properties to PKInkingTool configurations
- Custom tool rendering for patterns not supported by PencilKit
- Hybrid approach: use PencilKit for basic strokes, custom rendering for advanced brushes

### 3.3 macOS Native Rendering

**File:** `BrushEngine+macOS.swift`

- Enhanced DrawingStroke to include brush metadata
- Pattern rendering using Core Graphics
- Stamp brush implementation with CGPath
- Texture application using CGPattern

---

## Phase 4: UI Redesign (Week 6)

### 4.1 Brush Palette (Leading Sidebar)

**File:** `BrushPaletteView.swift`

**Layout:**
```
┌────────────────────┐
│  Brush Set: [Menu] │
├────────────────────┤
│                    │
│  [Category Pills]  │
│                    │
├────────────────────┤
│                    │
│  ┌──┐ ┌──┐ ┌──┐   │
│  │🖊│ │🏔│ │🌊│   │  <- Brush icons in grid
│  └──┘ └──┘ └──┘   │
│  ┌──┐ ┌──┐ ┌──┐   │
│  │🌲│ │🏠│ │📍│   │
│  └──┘ └──┘ └──┘   │
│                    │
├────────────────────┤
│  Brush Properties  │
│  Size: [slider]    │
│  Color: [picker]   │
│  Opacity: [slider] │
└────────────────────┘
```

**Implementation:**
```swift
struct BrushPaletteView: View {
    @Binding var selectedBrush: MapBrush?
    let brushSet: BrushSet
    @State private var selectedCategory: BrushCategory?
    @State private var searchText: String = ""
    
    var filteredBrushes: [MapBrush] {
        // Filter by category and search
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Brush Set selector
            // Category filter pills
            // Brush grid
            // Properties panel
        }
        .frame(width: 240)
    }
}
```

### 4.2 Layer Panel (Trailing Sidebar)

**File:** `LayerPanelView.swift`

**Layout:**
```
┌────────────────────┐
│  Layers  [+ New]   │
├────────────────────┤
│  👁 🔒 Annotations │ <- Active
│  👁 🔒 Structures  │
│  👁 🔒 Roads       │
│  👁 🔒 Water       │
│  👁 🔒 Terrain     │
├────────────────────┤
│  Opacity: [slider] │
│  Blend: [menu]     │
│  [Merge] [Delete]  │
└────────────────────┘
```

**Implementation:**
```swift
struct LayerPanelView: View {
    @Binding var layerManager: LayerManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Layer list with reordering
            // Layer properties for active layer
            // Layer operations
        }
        .frame(width: 220)
    }
}
```

### 4.3 Updated Canvas Layout

**File:** `DrawingCanvasView+BrushSystem.swift`

```swift
HStack(spacing: 0) {
    // Leading: Brush Palette
    BrushPaletteView(...)
        .background(.ultraThinMaterial)
    
    Divider()
    
    // Center: Canvas with toolbar on top
    VStack(spacing: 0) {
        DrawingToolbar(...)
        Divider()
        CanvasView(...)
    }
    
    Divider()
    
    // Trailing: Layer Panel
    LayerPanelView(...)
        .background(.ultraThinMaterial)
}
```

---

## Phase 5: Advanced Features (Week 7-8)

### 5.1 Snap to Grid

**File:** `GridSnapping.swift`

- Snap brush strokes to grid intersections
- Configurable snap tolerance
- Visual feedback during snapping

### 5.2 Shape Tools

**File:** `ShapeTools.swift`

- Rectangle tool (for buildings)
- Ellipse tool (for circular structures)
- Line tool (for straight roads/walls)
- Polygon tool (for custom shapes)
- All shapes use active brush styling

### 5.3 Symbol Library

**File:** `SymbolLibrary.swift`

- Pre-made symbols for common map elements
- Drag-and-drop placement
- Customizable symbol sets
- Integration with brush system

### 5.4 Text Annotation

**File:** `TextAnnotationTool.swift`

- Place text labels on maps
- Font selection and styling
- Automatic leader lines
- Text along paths (for rivers, roads)

### 5.5 Smart Brushes

**File:** `SmartBrushes.swift`

- Road brush that auto-intersects
- River brush that follows terrain
- Wall brush that auto-connects
- Pattern brushes that tile seamlessly

---

## Phase 6: Import/Export & Sharing (Week 9)

### 6.1 Brush Set Import/Export

**File:** `BrushSetIO.swift`

```swift
struct BrushSetPackage: Codable {
    let metadata: BrushSetMetadata
    let brushes: [MapBrush]
    let previewImages: [String: Data] // brush id -> preview
    let textures: [String: Data] // texture id -> image data
}

class BrushSetIO {
    static func exportBrushSet(_ brushSet: BrushSet) throws -> Data
    static func importBrushSet(from data: Data) throws -> BrushSet
    static func exportAsCumberlandBrushSet(_ brushSet: BrushSet) throws -> URL
    static func importFromFile(_ url: URL) throws -> BrushSet
}
```

### 6.2 Community Brush Set Format

**File Format:** `.cumberland-brushset` (JSON-based package)

**Structure:**
```
.cumberland-brushset/
├── manifest.json
├── brushes/
│   ├── brush-001.json
│   ├── brush-002.json
│   └── ...
├── textures/
│   ├── texture-001.png
│   └── ...
└── previews/
    ├── thumbnail.png
    └── brush-previews/
```

### 6.3 Brush Set Browser

**File:** `BrushSetBrowserView.swift`

- Browse installed brush sets
- Install new brush sets from files
- Preview brushes before installing
- Manage/delete installed sets
- (Future: online brush set library)

---

## Phase 7: Integration & Polish (Week 10)

### 7.1 MapWizardView Integration

**Updates to MapWizardView.swift:**

```swift
// Add brush system initialization
@State private var brushRegistry: BrushRegistry = BrushRegistry.shared
@State private var layerManager: LayerManager = LayerManager()
@State private var selectedBrush: MapBrush?

// Pass to canvas
private var drawConfigView: some View {
    HStack(spacing: 0) {
        BrushPaletteView(
            selectedBrush: $selectedBrush,
            brushSet: brushRegistry.activeBrushSet!
        )
        
        Divider()
        
        DrawingCanvasView(
            canvasState: $drawingCanvasModel,
            layerManager: $layerManager,
            selectedBrush: $selectedBrush
        )
        
        Divider()
        
        LayerPanelView(layerManager: $layerManager)
    }
}

// Auto-select brush set based on map type
private func configureForMapType(_ mapType: MapCreationMethod) {
    switch mapType {
    case .draw:
        brushRegistry.activeBrushSetID = brushRegistry.exteriorBrushSetID
    case .interior:
        brushRegistry.activeBrushSetID = brushRegistry.interiorBrushSetID
    default:
        break
    }
}
```

### 7.2 Persistence

**Updates to DrawingCanvasModel:**

```swift
// Enhanced export to include layers
func exportCanvasStateWithLayers() -> Data? {
    let state = EnhancedCanvasState(
        layers: layerManager.exportLayers(),
        brushSetID: brushRegistry.activeBrushSetID,
        canvasSize: canvasSize,
        backgroundColor: backgroundColor.toHex(),
        gridSettings: exportGridSettings()
    )
    return try? JSONEncoder().encode(state)
}

// Enhanced import
func importCanvasStateWithLayers(_ data: Data) throws {
    let state = try JSONDecoder().decode(EnhancedCanvasState.self, from: data)
    // Restore everything
}
```

### 7.3 Performance Optimization

- Lazy rendering of off-screen layers
- Caching of composited layer images
- Efficient brush pattern generation
- Background layer flattening for complex maps

### 7.4 Keyboard Shortcuts

**File:** `BrushSystemShortcuts.swift`

```
Cmd+L: New Layer
Cmd+Shift+L: Show/Hide Layers Panel
Cmd+B: Show/Hide Brush Palette
Cmd+Shift+B: Switch Brush Set
Cmd+[: Previous Brush
Cmd+]: Next Brush
H: Hand Tool (pan)
B: Brush Tool
E: Eraser Tool
S: Shape Tool
T: Text Tool
Numbers 1-9: Quick select favorite brushes
```

---

## Phase 8: Testing & Documentation (Week 11)

### 8.1 Unit Tests

**Files:**
- `BrushSystemTests.swift`
- `LayerManagerTests.swift`
- `BrushEngineTests.swift`
- `BrushSetIOTests.swift`

### 8.2 UI Tests

- Brush selection and application
- Layer management operations
- Import/export workflows

### 8.3 Performance Tests

- Large map rendering
- Many layers performance
- Complex brush patterns

### 8.4 Documentation

**Files to Create:**
- `BRUSH-SYSTEM-USER-GUIDE.md`
- `CREATING-CUSTOM-BRUSHES.md`
- `BRUSH-SET-FORMAT-SPEC.md`
- API documentation comments

---

## Additional Features to Consider

### High Priority

1. **Brush Favorites:**
   - Quick access to frequently used brushes
   - Customizable favorites bar

2. **Brush Size Presets:**
   - Small, Medium, Large quick toggles
   - Remember last used size per brush

3. **Color Palettes:**
   - Themed color palettes for map styles
   - Custom palette creation
   - Save/load palettes

4. **Layer Blend Modes:**
   - Normal, Multiply, Screen, Overlay, etc.
   - Visual preview of blend effects

5. **Layer Groups:**
   - Organize related layers
   - Collapse/expand groups
   - Apply operations to entire group

### Medium Priority

6. **Brush Pressure Curves:**
   - Customize pressure response
   - Width and opacity curves
   - Preview pressure behavior

7. **Symmetry Tools:**
   - Radial symmetry for castles, fortifications
   - Mirror symmetry for balanced maps

8. **Path Tools:**
   - Bezier curve paths
   - Apply brushes along paths
   - Useful for roads, rivers

9. **Transform Tools:**
   - Move, rotate, scale selected regions
   - Per-layer transformations

10. **Reference Images:**
    - Import reference images
    - Opacity control
    - Non-exported reference layer

### Low Priority

11. **Brush Animation:**
    - Animated brush previews
    - Demonstrate brush behavior

12. **Brush Randomization:**
    - Randomize color/size within range
    - More organic/natural results

13. **Procedural Patterns:**
    - Generate terrain patterns algorithmically
    - Perlin noise for organic textures

14. **Layer Effects:**
    - Drop shadow
    - Glow
    - Stroke outline

15. **History Panel:**
    - Visual undo/redo history
    - Step backward/forward

---

## File Structure Summary

```
Cumberland/
├── MapWizard/
│   ├── Drawing/
│   │   ├── Core/
│   │   │   ├── DrawingCanvasView.swift (updated)
│   │   │   ├── DrawingCanvasModel.swift (updated)
│   │   │   └── DrawingCanvasViewMacOS.swift (updated)
│   │   ├── Layers/
│   │   │   ├── DrawingLayer.swift (new)
│   │   │   ├── LayerManager.swift (new)
│   │   │   └── LayerPanelView.swift (new)
│   │   ├── Brushes/
│   │   │   ├── MapBrush.swift (new)
│   │   │   ├── BrushSet.swift (new)
│   │   │   ├── BrushEngine.swift (new)
│   │   │   ├── BrushEngine+PencilKit.swift (new)
│   │   │   ├── BrushEngine+macOS.swift (new)
│   │   │   ├── BrushRegistry.swift (new)
│   │   │   ├── BrushPaletteView.swift (new)
│   │   │   └── BrushSetBrowserView.swift (new)
│   │   ├── BrushSets/
│   │   │   ├── ExteriorMapBrushSet.swift (new)
│   │   │   ├── InteriorMapBrushSet.swift (new)
│   │   │   └── BrushSetIO.swift (new)
│   │   ├── Tools/
│   │   │   ├── GridSnapping.swift (new)
│   │   │   ├── ShapeTools.swift (new)
│   │   │   ├── SymbolLibrary.swift (new)
│   │   │   ├── TextAnnotationTool.swift (new)
│   │   │   └── SmartBrushes.swift (new)
│   │   └── UI/
│   │       ├── BrushPropertyPanel.swift (new)
│   │       ├── LayerPropertiesPanel.swift (new)
│   │       └── BrushSystemShortcuts.swift (new)
│   └── MapWizardView.swift (updated)
├── Tests/
│   ├── BrushSystemTests.swift (new)
│   ├── LayerManagerTests.swift (new)
│   └── BrushEngineTests.swift (new)
└── Documentation/
    ├── BRUSH-SYSTEM-IMPLEMENTATION-PLAN.md (this file)
    ├── BRUSH-SYSTEM-USER-GUIDE.md (new)
    ├── CREATING-CUSTOM-BRUSHES.md (new)
    └── BRUSH-SET-FORMAT-SPEC.md (new)
```

---

## Dependencies

### Swift Packages (if any needed)
- None required - using built-in PencilKit and Core Graphics

### Asset Requirements
- SF Symbols for brush icons
- Sample texture images for default brushes
- Example maps for documentation

---

## Success Metrics

1. **Performance:**
   - Smooth drawing with 60fps on target devices
   - Layer switching < 100ms
   - Export of complex maps < 5 seconds

2. **Usability:**
   - Brush selection within 2 taps
   - Layer operations intuitive and discoverable
   - No learning curve for basic brushes

3. **Flexibility:**
   - Support for 50+ brushes per set
   - 10+ layers without performance degradation
   - Custom brush sets work seamlessly

4. **Quality:**
   - Professional-looking maps with default brushes
   - Smooth, anti-aliased rendering
   - High-resolution export (4K+)

---

## Migration Path

### For Existing Maps
1. Detect legacy canvas data (no layers)
2. Create single "Legacy" layer
3. Import existing drawing to legacy layer
4. Maintain backward compatibility

### For Users
1. Preserve existing workflow
2. Introduce layers gradually
3. Show tutorial on first use
4. Provide "Simple Mode" without layers option

---

## Timeline Summary

- **Week 1-2:** Core infrastructure (layers + brushes)
- **Week 3:** Built-in brush sets
- **Week 4-5:** Rendering engine
- **Week 6:** UI redesign
- **Week 7-8:** Advanced features
- **Week 9:** Import/export
- **Week 10:** Integration & polish
- **Week 11:** Testing & documentation

**Total:** ~11 weeks for full implementation

**MVP (Minimum Viable Product):** Weeks 1-6 (6 weeks)
- Core layer system
- Basic brush sets (exterior + interior)
- Simple rendering
- Updated UI

---

## Notes & Considerations

1. **Platform Differences:**
   - PencilKit on iOS/iPadOS provides Apple Pencil support
   - macOS needs custom rendering for brushes
   - Ensure feature parity across platforms

2. **Performance:**
   - Complex brushes (patterns, stamps) may be slower
   - Consider caching rendered patterns
   - Profile regularly during development

3. **User Experience:**
   - Don't overwhelm users with too many options
   - Provide sensible defaults
   - Make common tasks easy

4. **Extensibility:**
   - Design for future brush types
   - Allow plugins/extensions eventually
   - Keep file formats forward-compatible

5. **Accessibility:**
   - Ensure brush icons are clear
   - Provide text labels option
   - Support keyboard navigation

---

## Questions to Resolve

1. Should we support brush opacity at stroke level or just at layer level?
   - **Recommendation:** Both - per-brush default + real-time adjustment

2. How many layers is a reasonable limit?
   - **Recommendation:** 20 layers max with warning at 10+

3. Should we allow animated/procedural brushes?
   - **Recommendation:** Phase 2 feature after core system is stable

4. What's the brush set file size limit for imports?
   - **Recommendation:** 50MB max, warn at 20MB

5. Should layers have their own undo stacks?
   - **Recommendation:** No - unified undo across all layers (simpler UX)

---

## End of Implementation Plan

This plan provides a complete roadmap for implementing a professional-grade brush and layer system. Adjust timelines based on team size and priorities. Focus on MVP first (Phases 1-4) before adding advanced features.

**Next Steps:**
1. Review and approve this plan
2. Create GitHub issues/tasks for Phase 1
3. Set up development branch
4. Begin implementation with `DrawingLayer.swift`
