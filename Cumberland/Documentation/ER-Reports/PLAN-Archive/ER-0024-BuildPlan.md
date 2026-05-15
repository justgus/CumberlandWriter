# ER-0024: Extract Brush Engine to Swift Package - Build Plan

**Status:** 🔵 Proposed
**Component:** Drawing System, Procedural Generation, Swift Package
**Priority:** High
**Date Requested:** 2026-02-03
**Dependencies:** None (can proceed independently)

---

## Overview

Extract the brush rendering engine and procedural terrain generation system into a reusable Swift Package. This will enable the same powerful map generation capabilities to be used in Storyscapes, game development tools, and other creative applications.

**Key Benefit:** Reuse sophisticated procedural generation algorithms across multiple products without code duplication.

---

## Current State Analysis

### Existing DrawCanvas System

The Cumberland DrawCanvas folder contains ~14,000 lines across 22 files:

**Core Rendering Engine (~4,800 lines):**
- `BrushEngine.swift` (2,401 lines) - Main rendering logic
- `BrushEngine+Patterns.swift` (1,000 lines) - Pattern generation
- `TerrainPattern.swift` - Procedural terrain algorithms
- `ProceduralPatternGenerator.swift` - Pattern utilities
- `BaseLayerPatterns.swift` - Base layer fills

**Brush System (~800 lines):**
- `BrushRegistry.swift` - Brush management
- `MapBrush.swift` - Brush definitions
- `InteriorMapBrushSet.swift` - Interior brushes
- `ExteriorMapBrushSet.swift` - Exterior brushes

**Layer Management (~800 lines):**
- `LayerManager.swift` - Layer state (@Observable)
- `DrawingLayer.swift` - Layer model
- `DrawingCanvasModel.swift` - Canvas state

**UI Components (~7,600 lines - NOT extracting):**
- `DrawingCanvasView.swift` (2,425 lines)
- `DrawingCanvasViewMacOS.swift` (1,001 lines)
- `FloatingToolPalette.swift`
- `InspectorTabView.swift`
- `LayersTabView.swift`
- `ToolsTabView.swift`
- Other UI components

**What We're Extracting:** Core rendering engine + brush system (~5,600 lines)

**What Stays in Cumberland:** UI layer, canvas views, integration with Card model

---

## Package Architecture

### Package Structure

```
BrushEngine/
├── Package.swift
├── Sources/
│   └── BrushEngine/
│       ├── Core/
│       │   ├── BrushEngine.swift                  # Main rendering engine
│       │   ├── BrushEngineProtocol.swift          # Protocol for extensibility
│       │   └── BrushEngineError.swift             # Error types
│       ├── Brushes/
│       │   ├── BrushRegistry.swift                # Brush management
│       │   ├── MapBrush.swift                     # Brush definition
│       │   ├── BrushSet.swift                     # Brush set protocol
│       │   ├── InteriorBrushSet.swift             # Interior brushes
│       │   └── ExteriorBrushSet.swift             # Exterior brushes
│       ├── Patterns/
│       │   ├── TerrainPattern.swift               # Terrain algorithms
│       │   ├── ProceduralPatternGenerator.swift   # Pattern utilities
│       │   ├── BaseLayerPatterns.swift            # Base fills
│       │   └── PatternType.swift                  # Pattern enums
│       ├── Layers/
│       │   ├── DrawingLayer.swift                 # Layer model (decoupled from SwiftData)
│       │   ├── LayerType.swift                    # Layer type enum
│       │   └── LayerRenderer.swift                # Layer compositing
│       └── Utilities/
│           ├── ColorExtensions.swift              # Color utilities
│           └── CGContextExtensions.swift          # Drawing utilities
└── Tests/
    └── BrushEngineTests/
        ├── BrushEngineTests.swift
        ├── TerrainPatternTests.swift
        ├── BrushRegistryTests.swift
        └── LayerTests.swift
```

---

## Abstraction Strategy

### Challenge: Remove Cumberland Dependencies

**Current Dependencies to Remove:**
1. **Card Model:** LayerManager stores references to Card.draftMapWorkData
2. **SwiftData:** DrawingLayer uses @Model macro
3. **Cumberland-Specific Types:** Some enums tied to Cumberland UI

### Solution: Create Abstraction Layer

#### 1. Replace Card Dependency with Protocol

**Before (Cumberland-specific):**
```swift
// LayerManager.swift
@Observable
class LayerManager {
    var card: Card?

    func saveDraftWork() {
        guard let card = card else { return }
        let data = serialize()
        card.draftMapWorkData = data
    }
}
```

**After (Generic):**
```swift
// LayerManager.swift in BrushEngine package
@Observable
public class LayerManager {
    public weak var persistenceDelegate: LayerPersistenceDelegate?

    public func saveDraftWork() {
        let data = serialize()
        persistenceDelegate?.save(layerData: data)
    }
}

// Protocol for persistence
public protocol LayerPersistenceDelegate: AnyObject {
    func save(layerData: Data)
    func loadDraftWork() -> Data?
}
```

**Then in Cumberland:**
```swift
// Card+LayerPersistence.swift
extension Card: LayerPersistenceDelegate {
    func save(layerData: Data) {
        self.draftMapWorkData = layerData
    }

    func loadDraftWork() -> Data? {
        return draftMapWorkData
    }
}

// When creating LayerManager:
let layerManager = LayerManager()
layerManager.persistenceDelegate = card
```

#### 2. Replace SwiftData @Model with Codable

**Before (Cumberland-specific):**
```swift
// DrawingLayer.swift
@Model
class DrawingLayer {
    var name: String
    var isVisible: Bool
    var layerTypeRaw: String
    // ... stored in SwiftData
}
```

**After (Generic):**
```swift
// DrawingLayer.swift in BrushEngine package
public struct DrawingLayer: Codable, Identifiable {
    public var id: UUID
    public var name: String
    public var isVisible: Bool
    public var layerType: LayerType
    public var pkDrawingData: Data?
    public var opacity: Double
    public var blendMode: BlendMode

    public init(id: UUID = UUID(), name: String, layerType: LayerType, ...) {
        self.id = id
        self.name = name
        // ...
    }
}

// LayerManager holds array of layers
public class LayerManager {
    public var layers: [DrawingLayer] = []

    // Serialization for persistence
    public func serialize() -> Data? {
        try? JSONEncoder().encode(layers)
    }

    public func deserialize(from data: Data) {
        if let decodedLayers = try? JSONDecoder().decode([DrawingLayer].self, from: data) {
            self.layers = decodedLayers
        }
    }
}
```

#### 3. Make BrushRegistry Independent

**Before (Singleton with hardcoded brushes):**
```swift
class BrushRegistry {
    static let shared = BrushRegistry()

    private init() {
        registerAllBrushes() // Hardcoded Cumberland brushes
    }
}
```

**After (Configurable):**
```swift
public class BrushRegistry {
    private var brushes: [String: MapBrush] = [:]

    public init() {
        // Empty - consumers register their own brushes
    }

    public func registerBrush(_ brush: MapBrush) {
        brushes[brush.id] = brush
    }

    public func registerBrushSet(_ brushSet: BrushSet) {
        for brush in brushSet.brushes {
            registerBrush(brush)
        }
    }
}

// Then in Cumberland:
let registry = BrushRegistry()
registry.registerBrushSet(ExteriorBrushSet())
registry.registerBrushSet(InteriorBrushSet())
```

---

## Public API Design

### Core BrushEngine API

```swift
// BrushEngine.swift
@available(macOS 26.0, iOS 26.0, *)
public final class BrushEngine {

    public init() {
        // Initialize engine
    }

    // MARK: - Brush Rendering

    /// Render a brush stroke to a CGContext
    /// - Parameters:
    ///   - brush: The brush to render
    ///   - points: Array of points for the stroke
    ///   - context: CGContext to draw into
    ///   - size: Size of the canvas
    public func renderBrushStroke(
        brush: MapBrush,
        points: [CGPoint],
        to context: CGContext,
        canvasSize: CGSize
    ) {
        // Rendering logic
    }

    /// Render terrain pattern
    /// - Parameters:
    ///   - pattern: Terrain pattern to render
    ///   - rect: Area to fill
    ///   - context: CGContext to draw into
    public func renderTerrainPattern(
        pattern: TerrainPattern,
        in rect: CGRect,
        to context: CGContext
    ) {
        // Pattern rendering
    }

    // MARK: - Base Layer

    /// Render base layer fill
    /// - Parameters:
    ///   - fillType: Type of base layer fill
    ///   - size: Canvas size
    /// - Returns: CGImage of base layer
    public func renderBaseLayer(
        fillType: BaseLayerFillType,
        size: CGSize
    ) -> CGImage? {
        // Base layer rendering
    }
}
```

### BrushRegistry API

```swift
public class BrushRegistry {
    public init()

    public func registerBrush(_ brush: MapBrush)
    public func registerBrushSet(_ brushSet: BrushSet)
    public func getBrush(id: String) -> MapBrush?
    public func getAllBrushes() -> [MapBrush]
    public func getBrushesByCategory(_ category: BrushCategory) -> [MapBrush]
}

public protocol BrushSet {
    var brushes: [MapBrush] { get }
    var category: BrushCategory { get }
}
```

### LayerManager API

```swift
@Observable
public class LayerManager {
    public var layers: [DrawingLayer]
    public var activeLayerIndex: Int
    public weak var persistenceDelegate: LayerPersistenceDelegate?

    public init(layers: [DrawingLayer] = [])

    // Layer Management
    public func addLayer(_ layer: DrawingLayer)
    public func removeLayer(at index: Int)
    public func moveLayer(from: Int, to: Int)
    public func duplicateLayer(at index: Int)

    // Active Layer
    public var activeLayer: DrawingLayer? { get }
    public func setActiveLayer(index: Int)

    // Rendering
    public func compositeLayers(size: CGSize) -> CGImage?

    // Persistence
    public func serialize() -> Data?
    public func deserialize(from data: Data)
    public func saveDraftWork()
    public func loadDraftWork()
}
```

---

## Implementation Plan

### Phase 1: Package Creation and Core Extraction (Week 1)

**Step 1.1: Create Package Structure**
```bash
swift package init --name BrushEngine --type library
```

**Step 1.2: Extract Core Rendering Engine**

Files to extract from Cumberland:
1. `BrushEngine.swift` → `Sources/BrushEngine/Core/BrushEngine.swift`
2. `BrushEngine+Patterns.swift` → `Sources/BrushEngine/Patterns/TerrainPattern.swift`
3. `TerrainPattern.swift` → `Sources/BrushEngine/Patterns/TerrainPattern.swift`
4. `ProceduralPatternGenerator.swift` → `Sources/BrushEngine/Patterns/ProceduralPatternGenerator.swift`
5. `BaseLayerPatterns.swift` → `Sources/BrushEngine/Patterns/BaseLayerPatterns.swift`

**Modifications needed:**
- Remove `import SwiftData` statements
- Change access levels to `public`
- Remove Cumberland-specific dependencies
- Add `@available` annotations

**Step 1.3: Extract Brush System**

Files to extract:
1. `BrushRegistry.swift` → `Sources/BrushEngine/Brushes/BrushRegistry.swift`
2. `MapBrush.swift` → `Sources/BrushEngine/Brushes/MapBrush.swift`
3. `InteriorMapBrushSet.swift` → `Sources/BrushEngine/Brushes/InteriorBrushSet.swift`
4. `ExteriorMapBrushSet.swift` → `Sources/BrushEngine/Brushes/ExteriorBrushSet.swift`

**Modifications needed:**
- Make BrushRegistry non-singleton (or make singleton optional)
- Remove hardcoded initialization
- Make brush registration explicit

**Step 1.4: Extract Layer System**

Files to extract/rewrite:
1. `DrawingLayer.swift` → Convert from @Model to Codable struct
2. `LayerManager.swift` → Add persistence delegate protocol

**Major changes:**
- Remove SwiftData dependency
- Add `LayerPersistenceDelegate` protocol
- Make serialization explicit (JSON encoding)

### Phase 2: Testing (Week 1-2)

**Step 2.1: Unit Tests for BrushEngine**

```swift
// BrushEngineTests.swift
import XCTest
@testable import BrushEngine

final class BrushEngineTests: XCTestCase {
    var engine: BrushEngine!

    override func setUp() {
        engine = BrushEngine()
    }

    func testRenderBrushStroke() {
        let brush = MapBrush(id: "test", name: "Test Brush", ...)
        let points = [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 100)]

        // Create test context
        let size = CGSize(width: 200, height: 200)
        guard let context = CGContext(...) else {
            XCTFail("Failed to create context")
            return
        }

        // Render stroke
        engine.renderBrushStroke(brush: brush, points: points, to: context, canvasSize: size)

        // Verify rendering occurred (check pixels, etc.)
    }

    func testTerrainPatternRendering() {
        // Test terrain pattern generation
    }

    func testBaseLayerRendering() {
        // Test base layer fills
    }
}
```

**Step 2.2: Unit Tests for Brushes**

```swift
// BrushRegistryTests.swift
func testRegisterBrush() {
    let registry = BrushRegistry()
    let brush = MapBrush(id: "test", name: "Test", ...)

    registry.registerBrush(brush)

    XCTAssertNotNil(registry.getBrush(id: "test"))
}

func testRegisterBrushSet() {
    let registry = BrushRegistry()
    let brushSet = ExteriorBrushSet()

    registry.registerBrushSet(brushSet)

    XCTAssertGreaterThan(registry.getAllBrushes().count, 0)
}
```

**Step 2.3: Unit Tests for Layers**

```swift
// LayerTests.swift
func testLayerSerialization() {
    let layer = DrawingLayer(name: "Test Layer", layerType: .terrain)
    let data = try? JSONEncoder().encode(layer)

    XCTAssertNotNil(data)

    let decoded = try? JSONDecoder().decode(DrawingLayer.self, from: data!)
    XCTAssertEqual(decoded?.name, "Test Layer")
}

func testLayerManager() {
    let manager = LayerManager()
    let layer1 = DrawingLayer(name: "Layer 1", layerType: .base)
    let layer2 = DrawingLayer(name: "Layer 2", layerType: .terrain)

    manager.addLayer(layer1)
    manager.addLayer(layer2)

    XCTAssertEqual(manager.layers.count, 2)
}
```

### Phase 3: Cumberland Integration (Week 2)

**Step 3.1: Add Package Dependency**
```swift
// Cumberland.xcodeproj
// File > Add Package Dependencies > Add Local...
// Select BrushEngine package
```

**Step 3.2: Create Cumberland Adapter Layer**

Create new file: `Cumberland/DrawCanvas/BrushEngineAdapter.swift`

```swift
import BrushEngine

/// Adapter that connects BrushEngine package to Cumberland's Card model
class BrushEngineAdapter {
    let layerManager: LayerManager
    let brushRegistry: BrushRegistry
    let engine: BrushEngine

    init(card: Card?) {
        self.layerManager = LayerManager()
        self.brushRegistry = BrushRegistry()
        self.engine = BrushEngine()

        // Set persistence delegate
        if let card = card {
            layerManager.persistenceDelegate = card
        }

        // Register Cumberland's brush sets
        brushRegistry.registerBrushSet(ExteriorBrushSet())
        brushRegistry.registerBrushSet(InteriorBrushSet())

        // Load draft work if exists
        layerManager.loadDraftWork()
    }
}

// Make Card conform to persistence protocol
extension Card: LayerPersistenceDelegate {
    func save(layerData: Data) {
        self.draftMapWorkData = layerData
    }

    func loadDraftWork() -> Data? {
        return draftMapWorkData
    }
}
```

**Step 3.3: Update DrawingCanvasView**

**Before:**
```swift
// DrawingCanvasView.swift
import SwiftUI

struct DrawingCanvasView: View {
    @State private var canvasState = DrawingCanvasModel()

    var body: some View {
        // Canvas rendering
    }
}
```

**After:**
```swift
// DrawingCanvasView.swift
import SwiftUI
import BrushEngine  // NEW

struct DrawingCanvasView: View {
    @State private var adapter: BrushEngineAdapter  // NEW
    let card: Card?

    init(card: Card?) {
        self.card = card
        self._adapter = State(initialValue: BrushEngineAdapter(card: card))
    }

    var body: some View {
        // Use adapter.layerManager, adapter.brushRegistry, adapter.engine
    }
}
```

**Step 3.4: Update Other DrawCanvas Components**

Files to update:
- `DrawingCanvasViewMacOS.swift` - Use BrushEngine package
- `DrawingCanvasModel.swift` - Refactor to use LayerManager from package
- `FloatingToolPalette.swift` - Use BrushRegistry from package
- `LayersTabView.swift` - Use LayerManager from package
- `ToolsTabView.swift` - Use BrushRegistry from package

**Cumberland Files to DELETE after migration:**
- `Cumberland/DrawCanvas/BrushEngine.swift` (moved to package)
- `Cumberland/DrawCanvas/BrushEngine+Patterns.swift` (moved to package)
- `Cumberland/DrawCanvas/TerrainPattern.swift` (moved to package)
- `Cumberland/DrawCanvas/ProceduralPatternGenerator.swift` (moved to package)
- `Cumberland/DrawCanvas/BaseLayerPatterns.swift` (moved to package)
- `Cumberland/DrawCanvas/BrushRegistry.swift` (moved to package)
- `Cumberland/DrawCanvas/MapBrush.swift` (moved to package)
- Original `DrawingLayer.swift` (replaced with package version)
- Parts of `LayerManager.swift` (replaced with package version)

**Code Reduction in Cumberland:** ~5,600 lines removed (moved to package)

### Phase 4: Storyscapes Integration (Week 3)

**Step 4.1: Add Package to Storyscapes**
```swift
// Storyscapes.xcodeproj
// File > Add Package Dependencies
// Add BrushEngine package (same as Cumberland)
```

**Step 4.2: Create Storyscapes Persistence Layer**

Since Storyscapes may have its own data model (not Card), create adapter:

```swift
// Storyscapes/MapProject.swift
class MapProject: LayerPersistenceDelegate {
    var draftLayerData: Data?

    func save(layerData: Data) {
        self.draftLayerData = layerData
    }

    func loadDraftWork() -> Data? {
        return draftLayerData
    }
}

// Storyscapes/MapEditor.swift
import BrushEngine

class MapEditor {
    let layerManager: LayerManager
    let brushRegistry: BrushRegistry
    let engine: BrushEngine
    let project: MapProject

    init(project: MapProject) {
        self.project = project
        self.layerManager = LayerManager()
        self.brushRegistry = BrushRegistry()
        self.engine = BrushEngine()

        // Connect persistence
        layerManager.persistenceDelegate = project

        // Register brushes
        brushRegistry.registerBrushSet(ExteriorBrushSet())
        brushRegistry.registerBrushSet(InteriorBrushSet())

        // Load existing work
        layerManager.loadDraftWork()
    }

    func renderMap() -> CGImage? {
        return layerManager.compositeLayers(size: CGSize(width: 2048, height: 2048))
    }
}
```

**Benefit:** Storyscapes gets full map generation capabilities with ~200 lines of glue code

---

## Testing Strategy

### Unit Tests (Package Level)

**Coverage Goals:** 80%+ for core rendering, 90%+ for layer management

**Key Test Scenarios:**
1. Render each terrain pattern type
2. Render each brush type
3. Composite multiple layers
4. Serialize/deserialize layers
5. Base layer generation for all fill types
6. Brush stroke with various parameters
7. Layer visibility toggling
8. Layer opacity blending
9. Add/remove/reorder layers
10. Error handling (invalid brushes, corrupt data)

### Integration Tests (Cumberland Level)

**Test Scenarios:**
1. **Map Wizard:**
   - Create new map with drawing
   - Apply terrain brushes
   - Add multiple layers
   - Export as image
   - Verify rendering quality

2. **Draft Persistence:**
   - Create map with layers
   - Save draft work
   - Close and reopen card
   - Verify layers restored correctly

3. **Cross-Device:**
   - Create map on macOS
   - Sync to iOS via CloudKit
   - Verify draft work loads correctly
   - Continue editing on iOS
   - Sync back to macOS

### Integration Tests (Storyscapes Level)

**Test Scenarios:**
1. Create new map project
2. Use same brushes as Cumberland
3. Export high-resolution map
4. Verify rendering matches Cumberland quality

---

## Documentation

### Package Documentation

**README.md:**
```markdown
# BrushEngine

A powerful procedural brush rendering engine for map and terrain generation.

## Features

- Procedural terrain patterns (grassland, forest, mountains, water, etc.)
- Customizable brush system with pattern generation
- Layer compositing with blend modes
- Base layer fills with procedural textures
- Platform-agnostic rendering (macOS, iOS, visionOS)

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/yourorg/BrushEngine.git", from: "1.0.0")
]
```

## Usage

### Basic Rendering

```swift
import BrushEngine

let engine = BrushEngine()
let registry = BrushRegistry()

// Register brushes
registry.registerBrushSet(ExteriorBrushSet())

// Create layer manager
let layerManager = LayerManager()

// Add layers
let baseLayer = DrawingLayer(name: "Base", layerType: .base)
let terrainLayer = DrawingLayer(name: "Terrain", layerType: .terrain)
layerManager.addLayer(baseLayer)
layerManager.addLayer(terrainLayer)

// Render
let mapImage = layerManager.compositeLayers(size: CGSize(width: 2048, height: 2048))
```

### Custom Persistence

```swift
class MyMapData: LayerPersistenceDelegate {
    func save(layerData: Data) {
        // Save to your data model
    }

    func loadDraftWork() -> Data? {
        // Load from your data model
    }
}

let layerManager = LayerManager()
layerManager.persistenceDelegate = myMapData
```

## Requirements

- macOS 26.0+
- iOS 26.0+
- visionOS 26.0+
- Swift 6.0+

## License

MIT License
```

### API Documentation

Full DocC comments for all public APIs (similar to ER-0023).

---

## Success Criteria

- [ ] Package builds on all platforms
- [ ] Unit tests passing (80%+ coverage)
- [ ] Cumberland integrated successfully
- [ ] Map generation still works in Cumberland
- [ ] Storyscapes integrated successfully
- [ ] Same visual quality as before extraction
- [ ] Code reduction: ~5,600 lines moved from Cumberland to package
- [ ] Documentation complete
- [ ] No performance regressions (<10% variance)

---

## Risks and Mitigations

### Risk 1: Visual Quality Regression

**Risk:** Extracted rendering may not match Cumberland's current quality

**Mitigation:**
- Extensive visual comparison testing
- Render same map before/after and compare pixel-perfect
- User testing to verify quality

### Risk 2: Performance Impact

**Risk:** Abstraction layer may slow down rendering

**Mitigation:**
- Profile before and after
- Benchmark critical paths
- Optimize if needed

### Risk 3: Breaking Cumberland Features

**Risk:** Extraction may break draft persistence or layer management

**Mitigation:**
- Comprehensive integration testing
- Test cross-device sync (CloudKit)
- Test all map wizard features

---

## Timeline Estimate

**Total Duration:** 3 weeks

- **Week 1:**
  - Create package structure
  - Extract core rendering engine
  - Extract brush system
  - Extract layer system
  - Write unit tests

- **Week 2:**
  - Cumberland integration
  - Create adapter layer
  - Update DrawCanvas views
  - Testing and refinement

- **Week 3:**
  - Storyscapes integration
  - Cross-platform testing
  - Documentation
  - Final cleanup

---

## Dependencies

**None** - Can proceed independently of other ERs

**Benefits other ERs:**
- ER-0025 (Storyscapes) depends on this

---

*Last Updated: 2026-02-03*
