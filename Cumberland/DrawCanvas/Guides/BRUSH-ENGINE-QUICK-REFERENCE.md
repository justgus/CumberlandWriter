# Brush Engine Quick Reference

## 🎯 Common Tasks

### Render a Brush Stroke

```swift
// Basic rendering
BrushEngine.renderStroke(
    brush: myBrush,
    points: strokePoints,
    color: .black,
    width: 5.0,
    context: cgContext
)

// Advanced rendering (uses procedural patterns for terrain/water/etc)
BrushEngine.renderAdvancedStroke(
    brush: myBrush,
    points: strokePoints,
    color: .blue,
    width: 10.0,
    context: cgContext
)
```

### Generate Specific Patterns

```swift
// Mountains
let mountains = BrushEngine.generateMountainPattern(
    points: path,
    width: 15,
    style: .jagged  // .jagged, .rounded, .layered
)

// Coastline
let coast = ProceduralPatternGenerator.generateDetailedCoastline(
    points: path,
    width: 20,
    detail: .high,  // .low, .medium, .high, .veryHigh
    erosion: 0.7    // 0.0-1.0
)

// Forest
let trees = BrushEngine.generateForestPattern(
    points: path,
    width: 12,
    density: 1.5    // 0.5-2.0 typical
)

// Cliff
let cliff = ProceduralPatternGenerator.generateDetailedCliff(
    points: path,
    width: 15,
    height: 30,
    dropDirection: .down,  // .up or .down
    weathering: 0.6        // 0.0-1.0
)

// Ridge
let ridge = ProceduralPatternGenerator.generateNaturalRidge(
    points: path,
    width: 12,
    prominence: 1.0  // 0.5-2.0 typical
)

// River (meandering)
let river = ProceduralPatternGenerator.generateMeanderingRiver(
    startPoint: start,
    endPoint: end,
    width: 15,
    meanderAmount: 0.5  // 0.0-1.0
)

// Lake
let lake = ProceduralPatternGenerator.generateIrregularLake(
    center: center,
    radius: 100,
    irregularity: 0.3  // 0.0-1.0
)

// Buildings
let buildings = BrushEngine.generateBuildingPattern(
    points: path,
    width: 15
)

// Roads
let road = BrushEngine.generateRoadPattern(
    points: path,
    width: 20,
    roadType: .highway  // .path, .standard, .highway
)
```

### Path Utilities

```swift
// Smooth a path
let smoothed = BrushEngine.smoothPath(
    points,
    amount: 0.5  // 0.0-1.0
)

// Snap to grid
let snapped = BrushEngine.snapToGrid(
    points,
    gridSpacing: 20
)
```

---

## 🎨 Brush Categories & Auto-Rendering

When you use `renderAdvancedStroke()`, the engine automatically picks the right pattern based on brush category:

| Category | Auto Pattern | Brush Name Keywords |
|----------|-------------|---------------------|
| `.terrain` | Mountains, cliffs, ridges | "mountain", "cliff", "ridge", "hill" |
| `.water` | Coastlines, rivers, waves | "coast", "river", "wave", "ocean" |
| `.vegetation` | Trees, forests | "forest", "tree", "jungle" |
| `.roads` | Roads with lines | "highway", "road", "path" |
| `.structures` | Building stamps | "building", "city", "tower" |

---

## 📱 Platform-Specific

### iOS/iPadOS (PencilKit)

```swift
#if canImport(PencilKit)

// Create PencilKit tool from brush
let tool = BrushEngine.createAdvancedPKTool(
    from: brush,
    color: .black,
    width: 5.0
)
canvasView.tool = tool

// Configure canvas for brush
BrushEngine.configurePKCanvasView(canvasView, for: brush)

// Extract pressure from stroke
let pointsWithPressure = BrushEngine.extractPressureData(from: pkStroke)

// Render with pressure
BrushEngine.renderPressureSensitiveStroke(
    pointsWithPressure: pointsWithPressure,
    brush: brush,
    color: .black,
    baseWidth: 10.0,
    context: cgContext
)

#endif
```

### macOS (AppKit)

```swift
#if os(macOS)

// Render to NSImage
let image = BrushEngine.renderStrokeForMacOS(
    brush: brush,
    points: points,
    color: .black,
    width: 5.0,
    in: bounds
)

// Get pressure from event
let pressure = BrushEngine.extractPressureFromEvent(event)

// Composite layers
let composite = BrushEngine.compositeLayersForMacOS(
    layers: layers,
    size: size,
    backgroundColor: .white
)

// Export to PNG
let pngData = BrushEngine.exportLayerToPNG(layer, size: size)

#endif
```

---

## 🔧 Integration with Canvas

### Setup

```swift
import DrawingCanvasIntegration

@State private var drawingState = DrawingCanvasIntegration.DrawingState()

// Configure
drawingState.activeBrush = BrushRegistry.shared.selectedBrush
drawingState.activeColor = .black
drawingState.activeWidth = 5.0
```

### During Drawing

```swift
// Touch/drag started
.onChanged { value in
    DrawingCanvasIntegration.processTouchInput(
        location: value.location,
        pressure: value.pressure,  // or 1.0 for mouse
        state: &drawingState
    )
}

// Touch/drag ended
.onEnded { _ in
    DrawingCanvasIntegration.completeStroke(
        state: &drawingState,
        layer: activeLayer,
        context: cgContext
    )
}
```

### Rendering

```swift
// Render single layer
let layerImage = DrawingCanvasIntegration.renderLayer(
    layer,
    size: canvasSize
)

// Composite all layers
let composite = DrawingCanvasIntegration.compositeLayersToImage(
    layers: allLayers,
    size: canvasSize,
    backgroundColor: .white
)

// Real-time preview
let preview = DrawingCanvasIntegration.generateStrokePreview(
    brush: brush,
    points: currentPoints,
    color: color,
    width: width,
    size: canvasSize
)
```

### Export

```swift
// Export all layers
let pngData = DrawingCanvasIntegration.exportToPNG(
    layers: layers,
    size: canvasSize,
    backgroundColor: .white,
    scale: 2.0  // or 3.0 for retina
)

// Export single layer
let layerData = DrawingCanvasIntegration.exportLayerToPNG(
    layer: layer,
    size: canvasSize,
    scale: 2.0
)

// Save to file
try pngData.write(to: fileURL)
```

---

## 🎭 Pattern Rendering

### Render Generated Pattern

```swift
// After generating a CGPath pattern...

BrushEngine.renderPatternStroke(
    pattern: generatedPath,
    color: .brown,
    width: 2.0,
    context: cgContext
)
```

### Render Stamp Pattern

```swift
// After generating stamps ([(CGPoint, CGPath)])...

BrushEngine.renderStampPattern(
    stamps: treeStamps,
    color: .green,
    context: cgContext
)
```

### Render Buildings

```swift
let buildings = BrushEngine.generateBuildingPattern(points: path, width: 15)

for (rect, style) in buildings {
    style.render(
        in: rect,
        context: cgContext,
        color: UIColor.gray.cgColor
    )
}
```

---

## 🧪 Testing & Demo

### Run Performance Test

```swift
BrushEngineDemo.printPerformanceResults()

// Output:
// === Brush Engine Performance Test ===
// Solid: 0.0023s
// Stippled: 0.0087s
// Mountain: 0.0156s
// Coastline: 0.0243s
// Forest: 0.0198s
// ====================================
```

### Generate Demo Images

```swift
// All brush types
let demoMap = BrushEngineDemo.generateDemoMap(
    size: CGSize(width: 800, height: 600)
)

// Mountain styles
let mountainDemo = BrushEngineDemo.generateMountainStylesDemo(
    size: CGSize(width: 400, height: 300)
)

// Coastline details
let coastDemo = BrushEngineDemo.generateCoastlineDetailDemo(
    size: CGSize(width: 400, height: 400)
)

// Pressure sensitivity
let pressureDemo = BrushEngineDemo.generatePressureSensitiveDemo(
    size: CGSize(width: 400, height: 200)
)
```

---

## 🛠️ Brush Configuration

### Create Custom Brush

```swift
let customBrush = MapBrush(
    name: "Custom Mountain",
    icon: "mountain.2.fill",
    category: .terrain,
    baseColor: .brown,
    defaultWidth: 15.0,
    opacity: 1.0,
    blendMode: .normal,
    pressureSensitivity: true,
    taperStart: true,
    taperEnd: true,
    patternType: .solid,
    smoothing: 0.5,
    isBuiltIn: false
)
```

### Modify Brush Properties

```swift
var brush = MapBrush.basicPen

// Enable pressure sensitivity
brush.pressureSensitivity = true

// Add tapering
brush.taperStart = true
brush.taperEnd = true

// Adjust smoothing
brush.smoothing = 0.7

// Enable grid snapping
brush.snapToGrid = true
```

---

## 📊 Procedural Parameters

### Noise Functions

```swift
// Simple noise (0.0-1.0)
let n = ProceduralPatternGenerator.noise(x, y, seed: 0)

// Fractional Brownian Motion (layered noise)
let fbm = ProceduralPatternGenerator.fbm(x, y, octaves: 4)
// octaves: 1-6 typical, more = more detail
```

### Pattern Quality vs Performance

| Detail Level | Subdivisions | Render Time | Use Case |
|--------------|--------------|-------------|----------|
| Low | 2 | Fast | Zoomed out views |
| Medium | 4 | Moderate | Standard maps |
| High | 8 | Slower | Detailed maps |
| Very High | 16 | Slow | Print/export |

---

## 🎯 Best Practices

### Performance

```swift
// ✅ Good: Cache generated patterns
let pattern = BrushEngine.generateMountainPattern(...)
// Store pattern, reuse for multiple renders

// ❌ Bad: Regenerate every frame
for frame in frames {
    let pattern = BrushEngine.generateMountainPattern(...)
    // Regenerating is expensive
}
```

### Smoothing

```swift
// Light smoothing for precise control
brush.smoothing = 0.3

// Medium smoothing for natural look (recommended)
brush.smoothing = 0.5

// Heavy smoothing for very smooth curves
brush.smoothing = 0.8
```

### Detail Levels

```swift
// Adjust detail based on zoom level
let zoomLevel = currentZoom / maxZoom

let detail: CoastlineDetail = zoomLevel > 0.75 ? .high :
                              zoomLevel > 0.5 ? .medium : .low

let coastline = ProceduralPatternGenerator.generateDetailedCoastline(
    points: path,
    width: width,
    detail: detail,
    erosion: 0.7
)
```

---

## 🚨 Common Issues

### Issue: Jagged Lines

**Solution:** Increase smoothing
```swift
brush.smoothing = 0.7  // Higher = smoother
```

### Issue: Pattern Too Dense

**Solution:** Reduce density/spacing
```swift
// For forests
let trees = BrushEngine.generateForestPattern(
    points: path,
    width: width,
    density: 0.5  // Lower = fewer trees
)

// For stamps
brush.spacing = 8.0  // Higher = more space between stamps
```

### Issue: Performance Lag

**Solution:** Use lower detail or cache patterns
```swift
// Lower detail
let coast = ProceduralPatternGenerator.generateDetailedCoastline(
    points: path,
    width: width,
    detail: .low,  // Instead of .high
    erosion: 0.5
)

// Or cache the result
private var cachedPattern: CGPath?
```

### Issue: Pressure Not Working

**Solution:** Check platform and enable sensitivity
```swift
// Enable pressure sensitivity
brush.pressureSensitivity = true

// On iOS, use PencilKit
#if canImport(PencilKit)
let tool = BrushEngine.createAdvancedPKTool(from: brush, ...)
#endif

// On macOS, extract from event
#if os(macOS)
let pressure = BrushEngine.extractPressureFromEvent(event)
#endif
```

---

## 📚 More Info

- **Full Documentation:** `PHASE-3-1-IMPLEMENTATION-COMPLETE.md`
- **Integration Guide:** `DrawingCanvasIntegration.swift`
- **Visual Examples:** `BrushEngineDemo.swift`
- **Implementation Plan:** `BRUSH-SYSTEM-IMPLEMENTATION-PLAN.md`

---

**Quick Reference v1.0** | Phase 3.1 | Cumberland Map Wizard
