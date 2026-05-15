# macOS Drawing Implementation Guide

## Overview

This guide explains the macOS drawing implementation for the Map Wizard's drawing canvas. Since PencilKit is only available on iOS/iPadOS, we've created a custom `NSView`-based solution for macOS that supports mouse and trackpad input.

## Architecture

### Key Components

1. **`DrawingCanvasViewMacOS`** - SwiftUI wrapper using `NSViewRepresentable`
2. **`MacOSDrawingView`** - Custom `NSView` that handles mouse events and rendering
3. **`DrawingCanvasModel`** - Shared observable model (works for both iOS and macOS)
4. **`DrawingStroke`** - Represents a single stroke with points, color, width, and tool type

## How It Works

### Mouse Event Handling

The `MacOSDrawingView` overrides three key NSView mouse event methods:

```swift
override func mouseDown(with event: NSEvent) {
    // 1. Convert mouse location to view coordinates
    // 2. Save current state for undo
    // 3. Start a new stroke with current tool settings
}

override func mouseDragged(with event: NSEvent) {
    // 1. Get current mouse location
    // 2. Add point to the current stroke
    // 3. Trigger redraw
}

override func mouseUp(with event: NSEvent) {
    // 1. Finalize the stroke
    // 2. Add to completed strokes array
    // 3. Clear current stroke
}
```

### Rendering

Drawing is performed in the `draw(_ dirtyRect:)` method using Core Graphics:

1. **Background** - Fill with canvas background color
2. **Grid** (optional) - Draw grid lines if enabled
3. **Completed Strokes** - Draw all finalized strokes
4. **Current Stroke** - Draw the stroke being created

### Stroke Smoothing

Strokes use **quadratic Bezier curves** for smooth lines:

```swift
for i in 1..<stroke.points.count {
    let current = stroke.points[i]
    if i < stroke.points.count - 1 {
        let next = stroke.points[i + 1]
        let midPoint = CGPoint(
            x: (current.x + next.x) / 2,
            y: (current.y + next.y) / 2
        )
        context.addQuadCurve(to: midPoint, control: current)
    }
}
```

This creates smooth curves instead of jagged lines.

### Tool Implementation

Different tool types have different rendering behaviors:

- **Pen**: Solid line with full opacity
- **Pencil**: Slightly transparent (0.8 alpha) for texture
- **Marker**: More transparent (0.4 alpha) and wider stroke
- **Eraser**: Uses `.clear` blend mode to remove content
- **Lasso**: Not yet implemented (placeholder)

## Features

### ✅ Implemented

- Mouse/trackpad drawing with smooth curves
- Multiple tool types (pen, pencil, marker, eraser)
- Color picker with quick color swatches
- Adjustable line width
- Background color options
- Optional grid overlay
- Zoom in/out/reset
- Undo/redo (50 action history)
- Clear canvas
- Export as PNG image
- Save/load stroke data (JSON encoding)

### 🚧 Potential Enhancements

1. **Pressure Sensitivity**
   - Add support for pressure-sensitive tablets using `NSEvent.pressure`
   - Vary line width based on pressure

2. **Advanced Eraser**
   - Currently erases entire screen region
   - Could implement stroke-level erasing (remove individual strokes)

3. **Shape Tools**
   - Rectangle, circle, line tools
   - Ruler/straight line support (toggle exists but not implemented)

4. **Layers**
   - Multiple drawing layers
   - Layer visibility and ordering

5. **Selection Tools**
   - Implement lasso tool for selecting/moving drawn content
   - Copy/paste functionality

6. **Performance**
   - For very complex drawings, consider caching rendered content
   - Use dirty rectangles for partial redraws

## Usage Example

```swift
struct ContentView: View {
    @State private var canvasModel = DrawingCanvasModel()
    
    var body: some View {
        DrawingCanvasView(canvasState: $canvasModel)
            .frame(width: 800, height: 600)
    }
}
```

## Integration with Map Wizard

The drawing canvas is integrated into the Map Wizard's "Draw Map" workflow:

1. User selects "Draw Map" method
2. Canvas is displayed in configure step
3. User draws their map
4. On completion, the drawing is exported as PNG
5. Image data is saved to the Card's map attachment

The canvas supports **Focus Mode** for full-screen drawing:
- Press `⌘⇧F` to enter focus mode
- Press `Esc` to exit

## Technical Notes

### Memory Management

- Undo stack is limited to 50 actions to prevent memory issues
- Strokes are stored as lightweight point arrays
- Export creates image only when needed

### Thread Safety

- All drawing operations occur on the main thread
- Mouse events are naturally main-thread
- SwiftUI binding updates trigger view refresh

### Cross-Platform Compatibility

The code uses conditional compilation to support both platforms:

```swift
#if os(macOS)
// macOS-specific NSView drawing
#elseif canImport(PencilKit) && canImport(UIKit)
// iOS PencilKit implementation
#endif
```

## File Structure

```
DrawingCanvasView.swift
├── DrawingCanvasView (SwiftUI View)
├── DrawingCanvasModel (@Observable)
├── DrawingToolbar (SwiftUI View)
├── Platform-specific canvas implementations
└── Helper views (Grid, Placeholder, etc.)

DrawingCanvasViewMacOS.swift (macOS only)
├── DrawingCanvasViewMacOS (NSViewRepresentable)
├── MacOSDrawingView (NSView)
├── DrawingStroke (struct)
└── Codable helpers for save/load
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘Z` | Undo (when implemented with NSResponder) |
| `⌘⇧Z` | Redo (when implemented with NSResponder) |
| `⌘⇧F` | Toggle Focus Mode |
| `⌘+` | Zoom In (when implemented) |
| `⌘-` | Zoom Out (when implemented) |
| `⌘0` | Reset Zoom (when implemented) |

## Testing Recommendations

1. **Basic Drawing**
   - Draw with mouse
   - Draw with trackpad
   - Test all tool types

2. **Edge Cases**
   - Very fast mouse movements
   - Single-point strokes (clicks)
   - Drawing at canvas boundaries

3. **Performance**
   - Draw many complex strokes
   - Test zoom at different levels
   - Test undo/redo with full stack

4. **State Management**
   - Switch tools mid-stroke
   - Change colors and verify new strokes use new color
   - Test canvas size changes

## Troubleshooting

### Issue: Strokes appear jagged

**Solution**: Ensure Bezier curve smoothing is enabled in `drawStroke(_:in:)`

### Issue: Drawing is slow with many strokes

**Solution**: Consider implementing dirty rectangle optimization or stroke caching

### Issue: Colors don't match selected color

**Solution**: Verify `updateTool()` is called when color changes

### Issue: Undo/redo not working

**Solution**: Check that toolbar is calling the macOS view methods, not the PencilKit undo manager

## Future Considerations

### Metal Rendering

For significantly better performance with complex drawings, consider using Metal for rendering:

```swift
class MetalDrawingView: NSView {
    var metalLayer: CAMetalLayer?
    
    override func makeBackingLayer() -> CALayer {
        let layer = CAMetalLayer()
        layer.device = MTLCreateSystemDefaultDevice()
        metalLayer = layer
        return layer
    }
}
```

### Vectorization

Current implementation stores raw point arrays. For large maps, consider:
- Stroke simplification algorithms (Douglas-Peucker)
- Cubic Bezier path storage
- SVG export capability

## Conclusion

This implementation provides robust drawing functionality on macOS using standard AppKit APIs. It's designed to match the iOS PencilKit experience while working naturally with mouse and trackpad input. The architecture is extensible for adding more sophisticated features in the future.
