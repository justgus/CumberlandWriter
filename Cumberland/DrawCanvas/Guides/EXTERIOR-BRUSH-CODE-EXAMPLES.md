# Using the Exterior Brush Set - Code Examples

This guide shows how to work with the Exterior Map Brush Set programmatically in your Swift code.

## Getting Started

### Accessing the Brush Registry

```swift
import SwiftUI

// Access the shared brush registry
let registry = BrushRegistry.shared

// Get the exterior brush set
if let exteriorSet = registry.installedBrushSets.first(where: { 
    $0.mapType == .exterior && $0.isBuiltIn 
}) {
    print("Exterior brush set loaded with \(exteriorSet.brushCount) brushes")
}
```

### Loading the Exterior Brush Set

```swift
// The exterior brush set is automatically loaded on app launch
// But you can manually install it if needed:
registry.installExteriorBrushSet()

// Get the brush set ID for future reference
if let exteriorID = registry.exteriorBrushSetID {
    print("Exterior brush set ID: \(exteriorID)")
}
```

---

## Finding Brushes

### Get Brushes by Category

```swift
guard let exteriorSet = registry.activeBrushSet else { return }

// Get all terrain brushes
let terrainBrushes = exteriorSet.brushes(in: .terrain)
print("Found \(terrainBrushes.count) terrain brushes")

// Get all water brushes
let waterBrushes = exteriorSet.brushes(in: .water)

// Get all structure brushes
let structureBrushes = exteriorSet.brushes(in: .structures)
```

### Get Brushes by Name

```swift
guard let exteriorSet = registry.activeBrushSet else { return }

// Find a specific brush by name
if let riverBrush = exteriorSet.brushes.first(where: { $0.name == "River" }) {
    print("Found River brush with width \(riverBrush.defaultWidth)")
}

// Multiple brush lookup
let brushNames = ["Mountains", "Forest", "City"]
let selectedBrushes = brushNames.compactMap { name in
    exteriorSet.brushes.first { $0.name == name }
}
```

### Get All Categories

```swift
guard let exteriorSet = registry.activeBrushSet else { return }

// Get all categories represented in the brush set
let categories = exteriorSet.categories
print("Available categories: \(categories.map { $0.rawValue }.joined(separator: ", "))")

// Get brushes organized by category
let brushesByCategory = exteriorSet.brushesByCategory
for (category, brushes) in brushesByCategory {
    print("\(category.rawValue): \(brushes.count) brushes")
}
```

---

## Setting Active Brushes

### Select a Brush

```swift
// Set the active brush set
registry.setActiveBrushSet(id: exteriorSetID)

// Select a specific brush by ID
registry.selectBrush(id: brushID)

// Get the currently selected brush
if let selectedBrush = registry.selectedBrush {
    print("Selected: \(selectedBrush.name)")
}
```

### Navigate Between Brushes

```swift
// Select next brush in the set
registry.selectNextBrush()

// Select previous brush
registry.selectPreviousBrush()

// Select first brush in a category
if let firstTerrainBrush = exteriorSet.brushes(in: .terrain).first {
    registry.selectBrush(id: firstTerrainBrush.id)
}
```

---

## Working with Brush Properties

### Reading Brush Properties

```swift
guard let brush = registry.selectedBrush else { return }

// Basic properties
print("Brush: \(brush.name)")
print("Icon: \(brush.icon)")
print("Category: \(brush.category.rawValue)")

// Visual properties
print("Width: \(brush.defaultWidth) (min: \(brush.minWidth), max: \(brush.maxWidth))")
print("Opacity: \(brush.opacity)")
print("Color: \(brush.color?.description ?? "User-selected")")

// Behavior properties
print("Pattern: \(brush.patternType.rawValue)")
print("Smoothing: \(brush.smoothing)")
print("Pressure sensitive: \(brush.pressureSensitivity)")

// Special features
if brush.taperStart || brush.taperEnd {
    print("Has tapering")
}
if brush.snapToGrid {
    print("Snaps to grid")
}
if brush.scatterAmount > 0 {
    print("Scatter amount: \(brush.scatterAmount)")
}
```

### Modifying Brush Properties

```swift
guard let originalBrush = registry.selectedBrush else { return }

// Create a modified copy
let modifiedBrush = originalBrush.modified(
    name: "Custom River",
    defaultWidth: 12.0,
    opacity: 0.8,
    baseColor: .blue
)

// Note: You cannot modify built-in brushes directly
// Create a custom brush set instead
let customSet = registry.createCustomBrushSet(
    name: "My Custom Set",
    mapType: .custom
)

// Add modified brush to custom set
try? registry.addBrushToSet(brush: modifiedBrush, setID: customSet.id)
```

---

## Creating Layer Managers

### Auto-Create Layers from Brush Set

```swift
guard let exteriorSet = registry.activeBrushSet else { return }

// Create a layer manager with default layers
let layerManager = exteriorSet.createDefaultLayerManager()

print("Created \(layerManager.layers.count) layers:")
for layer in layerManager.layers {
    print("  - \(layer.name) (\(layer.layerType.rawValue))")
}

// The active layer is automatically set
if let activeLayer = layerManager.activeLayer {
    print("Active layer: \(activeLayer.name)")
}
```

### Manual Layer Setup

```swift
let layerManager = LayerManager()

// Clear default layer
if let defaultLayer = layerManager.layers.first {
    layerManager.deleteLayer(id: defaultLayer.id)
}

// Create custom layers
let terrainLayer = DrawingLayer(
    name: "Base Terrain",
    order: 0,
    layerType: .terrain
)
layerManager.layers.append(terrainLayer)

let waterLayer = DrawingLayer(
    name: "Rivers & Lakes",
    order: 1,
    layerType: .water
)
layerManager.layers.append(waterLayer)

// Set active layer
layerManager.activeLayerID = terrainLayer.id
```

---

## Filtering Brushes

### Search Functionality

```swift
// Search across all brush sets
let searchResults = registry.searchBrushes(query: "river")
print("Found \(searchResults.count) matching brushes")

for brush in searchResults {
    print("  - \(brush.name) in \(brush.category.rawValue)")
}
```

### Filter by Multiple Criteria

```swift
guard let exteriorSet = registry.activeBrushSet else { return }

// Get all stamp brushes in vegetation category
let vegetationStamps = exteriorSet.brushes.filter { brush in
    brush.category == .vegetation && 
    brush.patternType == .stamp
}
print("Vegetation stamps: \(vegetationStamps.map { $0.name })")

// Get brushes with high scatter
let scatteredBrushes = exteriorSet.brushes.filter { 
    $0.scatterAmount > 0.5 
}
print("High scatter brushes: \(scatteredBrushes.map { $0.name })")

// Get brushes that snap to grid
let gridBrushes = exteriorSet.brushes.filter { 
    $0.snapToGrid 
}
print("Grid-snapping brushes: \(gridBrushes.map { $0.name })")
```

---

## Using Brushes in SwiftUI Views

### Brush Selector View

```swift
struct BrushSelectorView: View {
    @State private var registry = BrushRegistry.shared
    @State private var selectedCategory: BrushCategory?
    
    var filteredBrushes: [MapBrush] {
        guard let brushSet = registry.activeBrushSet else { return [] }
        
        if let category = selectedCategory {
            return brushSet.brushes(in: category)
        }
        return brushSet.brushes
    }
    
    var body: some View {
        VStack {
            // Category filter
            Picker("Category", selection: $selectedCategory) {
                Text("All").tag(nil as BrushCategory?)
                ForEach(BrushCategory.allCases) { category in
                    Text(category.rawValue).tag(category as BrushCategory?)
                }
            }
            .pickerStyle(.segmented)
            
            // Brush grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                ForEach(filteredBrushes) { brush in
                    BrushButton(brush: brush, isSelected: registry.selectedBrushID == brush.id) {
                        registry.selectBrush(id: brush.id)
                    }
                }
            }
        }
    }
}

struct BrushButton: View {
    let brush: MapBrush
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: brush.icon)
                    .font(.title2)
                    .foregroundStyle(brush.color ?? .primary)
                
                Text(brush.name)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
```

### Brush Properties Panel

```swift
struct BrushPropertiesView: View {
    @Binding var brush: MapBrush?
    
    var body: some View {
        if let brush = brush {
            Form {
                Section("Brush Info") {
                    LabeledContent("Name", value: brush.name)
                    LabeledContent("Category", value: brush.category.rawValue)
                    LabeledContent("Pattern", value: brush.patternType.rawValue)
                }
                
                Section("Size") {
                    LabeledContent("Default Width", value: String(format: "%.1f", brush.defaultWidth))
                    LabeledContent("Min Width", value: String(format: "%.1f", brush.minWidth))
                    LabeledContent("Max Width", value: String(format: "%.1f", brush.maxWidth))
                }
                
                Section("Behavior") {
                    LabeledContent("Opacity", value: String(format: "%.0f%%", brush.opacity * 100))
                    LabeledContent("Smoothing", value: String(format: "%.0f%%", brush.smoothing * 100))
                    
                    if brush.pressureSensitivity {
                        Label("Pressure Sensitive", systemImage: "hand.draw")
                    }
                    if brush.snapToGrid {
                        Label("Snaps to Grid", systemImage: "square.grid.3x3")
                    }
                }
                
                if brush.scatterAmount > 0 || brush.rotationVariation > 0 {
                    Section("Variation") {
                        if brush.scatterAmount > 0 {
                            LabeledContent("Scatter", value: String(format: "%.1f", brush.scatterAmount))
                        }
                        if brush.rotationVariation > 0 {
                            LabeledContent("Rotation", value: String(format: "%.0f°", brush.rotationVariation))
                        }
                        if brush.sizeVariation > 0 {
                            LabeledContent("Size", value: String(format: "%.0f%%", brush.sizeVariation * 100))
                        }
                    }
                }
                
                if let layerType = brush.requiresLayer {
                    Section("Layer") {
                        Label(layerType.rawValue, systemImage: layerType.icon)
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "No Brush Selected",
                systemImage: "paintbrush",
                description: Text("Select a brush to view its properties")
            )
        }
    }
}
```

---

## Statistics and Analysis

### Brush Set Statistics

```swift
func analyzeBrushSet(_ brushSet: BrushSet) {
    print("=== Brush Set Analysis ===")
    print("Name: \(brushSet.name)")
    print("Type: \(brushSet.mapType.rawValue)")
    print("Total Brushes: \(brushSet.brushCount)")
    print()
    
    // Category breakdown
    print("Categories:")
    for category in brushSet.categories {
        let count = brushSet.brushes(in: category).count
        print("  \(category.rawValue): \(count)")
    }
    print()
    
    // Pattern type distribution
    let patternCounts = Dictionary(grouping: brushSet.brushes, by: { $0.patternType })
    print("Pattern Types:")
    for (pattern, brushes) in patternCounts.sorted(by: { $0.value.count > $1.value.count }) {
        print("  \(pattern.rawValue): \(brushes.count)")
    }
    print()
    
    // Special features
    let pressureSensitive = brushSet.brushes.filter { $0.pressureSensitivity }.count
    let snapToGrid = brushSet.brushes.filter { $0.snapToGrid }.count
    let withScatter = brushSet.brushes.filter { $0.scatterAmount > 0 }.count
    let withTaper = brushSet.brushes.filter { $0.taperStart || $0.taperEnd }.count
    
    print("Special Features:")
    print("  Pressure Sensitive: \(pressureSensitive)")
    print("  Snap to Grid: \(snapToGrid)")
    print("  With Scatter: \(withScatter)")
    print("  With Taper: \(withTaper)")
    print()
    
    // Average properties
    let avgWidth = brushSet.brushes.map { $0.defaultWidth }.reduce(0, +) / Double(brushSet.brushCount)
    let avgOpacity = brushSet.brushes.map { $0.opacity }.reduce(0, +) / Double(brushSet.brushCount)
    let avgSmoothing = brushSet.brushes.map { $0.smoothing }.reduce(0, +) / Double(brushSet.brushCount)
    
    print("Average Properties:")
    print("  Width: \(String(format: "%.1f", avgWidth))")
    print("  Opacity: \(String(format: "%.0f%%", avgOpacity * 100))")
    print("  Smoothing: \(String(format: "%.0f%%", avgSmoothing * 100))")
}

// Use it
if let exteriorSet = registry.installedBrushSets.first(where: { $0.mapType == .exterior }) {
    analyzeBrushSet(exteriorSet)
}
```

---

## Integration with Drawing System

### Apply Brush to Drawing Context

```swift
func applyBrush(_ brush: MapBrush, to context: CGContext, points: [CGPoint]) {
    // Set basic properties
    context.setLineWidth(brush.defaultWidth)
    context.setAlpha(brush.opacity)
    context.setBlendMode(brush.blendMode.cgBlendMode)
    
    // Set color
    if let brushColor = brush.color {
        #if os(iOS)
        UIColor(brushColor).setStroke()
        #else
        NSColor(brushColor).setStroke()
        #endif
    }
    
    // Apply pattern-specific rendering
    switch brush.patternType {
    case .solid:
        drawSolidStroke(context: context, points: points, brush: brush)
    case .dashed:
        drawDashedStroke(context: context, points: points, brush: brush)
    case .dotted:
        drawDottedStroke(context: context, points: points, brush: brush)
    case .stamp:
        drawStampPattern(context: context, points: points, brush: brush)
    // ... other patterns
    default:
        break
    }
}
```

---

## Best Practices

### 1. Always Check for Nil

```swift
// Always safely unwrap
guard let brushSet = registry.activeBrushSet else {
    print("No active brush set")
    return
}

guard let selectedBrush = registry.selectedBrush else {
    print("No brush selected")
    return
}
```

### 2. Cache Frequently Used Brushes

```swift
class MapDrawingViewModel: ObservableObject {
    private let registry = BrushRegistry.shared
    
    // Cache commonly used brushes
    lazy var riverBrush: MapBrush? = {
        registry.activeBrushSet?.brushes.first { $0.name == "River" }
    }()
    
    lazy var forestBrush: MapBrush? = {
        registry.activeBrushSet?.brushes.first { $0.name == "Forest" }
    }()
    
    lazy var roadBrush: MapBrush? = {
        registry.activeBrushSet?.brushes.first { $0.name == "Road" }
    }()
}
```

### 3. Handle Built-In vs Custom Brushes

```swift
func modifyBrush(_ brush: MapBrush) {
    if brush.isBuiltIn {
        // Cannot modify built-in brushes
        print("Create a custom brush instead")
        
        // Create modified copy in custom set
        let modifiedBrush = brush.modified(name: "Custom \(brush.name)")
        // Add to custom set...
    } else {
        // Can modify custom brushes
        // Update brush...
    }
}
```

---

## Testing Code

```swift
import Testing

@Test("Exterior brush set loads correctly")
func testExteriorBrushSetLoading() async throws {
    let registry = BrushRegistry()
    registry.installExteriorBrushSet()
    
    #expect(registry.exteriorBrushSetID != nil)
    
    guard let exteriorSet = registry.getBrushSet(id: registry.exteriorBrushSetID!) else {
        throw TestError.brushSetNotFound
    }
    
    #expect(exteriorSet.brushCount == 37)
    #expect(exteriorSet.mapType == .exterior)
    #expect(exteriorSet.isBuiltIn)
}

@Test("Can find specific brushes")
func testFindBrushes() async throws {
    let registry = BrushRegistry()
    registry.installExteriorBrushSet()
    
    guard let exteriorSet = registry.getBrushSet(id: registry.exteriorBrushSetID!) else {
        throw TestError.brushSetNotFound
    }
    
    // Test finding by name
    let riverBrush = exteriorSet.brushes.first { $0.name == "River" }
    #expect(riverBrush != nil)
    #expect(riverBrush?.category == .water)
    
    // Test finding by category
    let terrainBrushes = exteriorSet.brushes(in: .terrain)
    #expect(terrainBrushes.count > 0)
}

enum TestError: Error {
    case brushSetNotFound
}
```

---

## Next Steps

- See `ExteriorBrushSetPreview.swift` for a complete preview implementation
- See `ExteriorBrushSetTests.swift` for comprehensive test examples
- Check `EXTERIOR-BRUSH-QUICK-REFERENCE.md` for usage guidelines
- Review `BRUSH-SYSTEM-IMPLEMENTATION-PLAN.md` for architecture details

---

**Happy Coding! 🎨**
