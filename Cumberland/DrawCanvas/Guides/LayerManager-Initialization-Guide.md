# LayerManager Initialization Guide

## Overview

The LayerManager initialization system is designed to handle both **new drawings** and **existing drawings created before the layer system was implemented**. It provides automatic migration and manual initialization options.

---

## Automatic Initialization (Recommended)

### How It Works

The `DrawingCanvasView` automatically calls `ensureLayerManager()` when it appears:

```swift
.onAppear {
    // Auto-initialize LayerManager for new and existing drawings
    canvasState.ensureLayerManager()
}
```

### What `ensureLayerManager()` Does

1. **Checks if LayerManager exists** - If it already exists, does nothing
2. **Creates LayerManager** - If missing, creates a new one with a default base layer
3. **Migrates existing content** - If there's existing drawing data:
   - **iOS/iPadOS**: Moves `drawing: PKDrawing` to base layer
   - **macOS**: Moves `macOSStrokes` to base layer
   - Names it "Base Layer (Migrated)"
   - Clears old stroke data (macOS only)

### Scenarios Handled Automatically

#### Scenario 1: Brand New Drawing
```swift
// User creates a new drawing
let model = DrawingCanvasModel()
// DrawingCanvasView appears
// → ensureLayerManager() creates LayerManager with empty base layer
// → Ready to use!
```

#### Scenario 2: Existing Drawing (Pre-Layer System)
```swift
// Loaded from disk/database - has drawing data but no LayerManager
let model = loadDrawing(id: "old-map")
// model.drawing has content
// model.layerManager == nil
// DrawingCanvasView appears
// → ensureLayerManager() creates LayerManager
// → Migrates existing drawing to base layer
// → User can now apply fills and use layers!
```

#### Scenario 3: Drawing with LayerManager Already
```swift
// Recent drawing with layer system
let model = loadDrawing(id: "new-map")
// model.layerManager already exists
// DrawingCanvasView appears
// → ensureLayerManager() sees it exists, does nothing
// → Works normally
```

---

## Manual Initialization (Advanced)

If you need to initialize LayerManager before showing the view, you can call it directly:

### Option 1: When Creating New Drawings

```swift
// In your view model or creation logic
func createNewMap() -> DrawingCanvasModel {
    let model = DrawingCanvasModel()
    model.ensureLayerManager() // Explicitly initialize

    // Optionally apply a default fill
    model.layerManager?.applyFillToBaseLayer(
        LayerFill(fillType: .land, customColor: nil, opacity: 1.0)
    )

    return model
}
```

### Option 2: When Loading Existing Drawings

```swift
// After loading from persistence
func loadDrawing(id: UUID) -> DrawingCanvasModel {
    let model = decodeFromDisk(id: id)

    // Ensure layer manager exists (handles migration)
    model.ensureLayerManager()

    return model
}
```

### Option 3: Batch Migration

If you need to migrate multiple existing drawings:

```swift
func migrateAllDrawings() {
    let allDrawings = loadAllDrawingsFromDatabase()

    for drawing in allDrawings {
        // This will migrate each one
        drawing.ensureLayerManager()

        // Optionally save back to database
        saveDrawing(drawing)
    }
}
```

---

## Integration with MapWizardView

### Current State (MapWizardView.swift)

```swift
@State private var drawingCanvasModel: DrawingCanvasModel = DrawingCanvasModel()
```

### No Changes Needed!

The `DrawingCanvasView` will automatically call `ensureLayerManager()` when it appears. However, if you want to initialize it earlier (e.g., to set a default fill), you can add it to `onAppear`:

```swift
// In MapWizardView
DrawingCanvasView(canvasState: $drawingCanvasModel)
    .onAppear {
        // Optional: Set default fill for exterior maps
        if isExteriorMap {
            drawingCanvasModel.ensureLayerManager()
            drawingCanvasModel.layerManager?.applyFillToBaseLayer(
                LayerFill(fillType: .land, customColor: nil, opacity: 1.0)
            )
        }
    }
```

---

## Persistence Considerations

### What Gets Saved

The LayerManager is now part of DrawingCanvasModel's state. If you're using Codable or SwiftData, you need to ensure it's persisted.

#### If Using Codable

The `LayerManager` is already `Codable`, but `DrawingCanvasModel` might need updates to encode/decode it. Check if you have custom Codable conformance.

#### If Using SwiftData

Add `layerManager` to your SwiftData model's stored properties. Since LayerManager conforms to Codable, SwiftData can handle it.

### Example: Adding to Card Model

If maps are stored in your `Card` model:

```swift
@Model
class Card {
    // ... existing properties ...

    // Add this if not already present
    var drawingCanvasData: Data? // Encoded DrawingCanvasModel

    func saveDrawing(_ model: DrawingCanvasModel) throws {
        // Ensure LayerManager is initialized before saving
        model.ensureLayerManager()

        let encoder = JSONEncoder()
        drawingCanvasData = try encoder.encode(model)
    }

    func loadDrawing() -> DrawingCanvasModel? {
        guard let data = drawingCanvasData else { return nil }

        let decoder = JSONDecoder()
        let model = try? decoder.decode(DrawingCanvasModel.self, from: data)

        // Ensure migration happens for old drawings
        model?.ensureLayerManager()

        return model
    }
}
```

---

## Migration Details

### iOS/iPadOS (PencilKit)

**Before Migration:**
```swift
DrawingCanvasModel {
    drawing: PKDrawing (has content)
    layerManager: nil
}
```

**After Migration:**
```swift
DrawingCanvasModel {
    drawing: PKDrawing (same content - PencilKit needs it here)
    layerManager: LayerManager {
        layers: [
            DrawingLayer(order: 0) {
                name: "Base Layer (Migrated)"
                drawing: PKDrawing (copy of content)
                layerFill: nil
            }
        ]
    }
}
```

### macOS (Custom Strokes)

**Before Migration:**
```swift
DrawingCanvasModel {
    macOSStrokes: [DrawingStroke] (has content)
    layerManager: nil
}
```

**After Migration:**
```swift
DrawingCanvasModel {
    macOSStrokes: [] (CLEARED - moved to layer)
    layerManager: LayerManager {
        layers: [
            DrawingLayer(order: 0) {
                name: "Base Layer (Migrated)"
                macosStrokes: [DrawingStroke] (moved here)
                layerFill: nil
            }
        ]
    }
}
```

**Important:** On macOS, the old `macOSStrokes` array is cleared because the strokes are now managed by the LayerManager. This prevents duplication in rendering.

---

## Testing the Migration

### Test Case 1: New Drawing
1. Create a new drawing (doesn't matter how)
2. Open it in DrawingCanvasView
3. Check: `model.layerManager` should exist
4. Check: Base layer should be empty
5. Apply a fill → Should work immediately

### Test Case 2: Old Drawing with Content
1. Load a drawing created before layer system
2. It has `drawing.bounds.isEmpty == false` or `macOSStrokes.count > 0`
3. Open it in DrawingCanvasView
4. Check: `model.layerManager` should exist
5. Check: Base layer named "Base Layer (Migrated)"
6. Check: Content visible on canvas
7. Apply a fill → Fill appears behind existing content ✓

### Test Case 3: Drawing with Layers Already
1. Load a recent drawing with LayerManager
2. Open it in DrawingCanvasView
3. Check: LayerManager unchanged
4. Everything works normally

---

## Troubleshooting

### Problem: Palette says "No layer manager"
**Cause:** `ensureLayerManager()` wasn't called or failed
**Solution:** Call `model.ensureLayerManager()` manually

### Problem: Content disappeared after migration
**Cause:** (macOS only) Old strokes were cleared but layer rendering isn't working
**Solution:** Check that `DrawingCanvasViewMacOS` is rendering layers correctly

### Problem: Duplicate content visible
**Cause:** (macOS only) Old strokes weren't cleared, AND layer is rendering
**Solution:** Ensure migration clears `macOSStrokes` array

### Problem: Fill doesn't appear
**Cause:** Fill rendering not integrated or base layer missing
**Solution:** Verify `canvasBackgroundView` includes fill rendering code

---

## Best Practices

### ✅ DO

- **Let automatic initialization handle it** - `onAppear` calls it for you
- **Call `ensureLayerManager()` before accessing layers** - If doing manual setup
- **Save LayerManager with your drawings** - Include in persistence
- **Test migration with old drawings** - Ensure content isn't lost

### ❌ DON'T

- **Don't assume LayerManager exists** - Always use `ensureLayerManager()` or check for nil
- **Don't call `ensureLayerManager()` in a loop** - It's idempotent but wasteful
- **Don't manually create LayerManager** - Use `ensureLayerManager()` for consistency
- **Don't forget to persist it** - Add to your Codable/SwiftData model

---

## Summary

**The LayerManager initialization is fully automatic!**

1. ✅ **New drawings** → Auto-initialized on first view appearance
2. ✅ **Old drawings** → Auto-migrated on first view appearance
3. ✅ **Existing layer drawings** → Left unchanged
4. ✅ **Manual control** → Call `ensureLayerManager()` anytime
5. ✅ **Safe to call multiple times** → Idempotent operation

**You don't need to do anything special** - just use `DrawingCanvasView` and it handles everything!

---

## Quick Reference

```swift
// Automatic (recommended)
DrawingCanvasView(canvasState: $model)
// → LayerManager auto-initialized on appear

// Manual (if needed)
model.ensureLayerManager()
// → Safe to call anytime, idempotent

// With default fill
model.ensureLayerManager()
model.layerManager?.applyFillToBaseLayer(
    LayerFill(fillType: .water, customColor: nil, opacity: 1.0)
)

// Check if initialized
if model.layerManager != nil {
    // Layer system ready
}
```
