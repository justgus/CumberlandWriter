# Quick Reference: Map Drawing Persistence

## What Changed?

### Before
- Saved complete canvas state (drawing data + settings)
- Restored to same wizard step (could be welcome, selectMethod, configure)
- Required platform-specific restoration logic

### After
- **Saves PNG snapshots** every 30 seconds
- **Always restores to configure step** (skips welcome and selectMethod)
- Works identically on iOS, iPadOS, and macOS

## User Experience

### Starting Fresh
1. Open Map Wizard
2. Tap "Draw Map"
3. Start drawing
4. After 30 seconds, work auto-saves as PNG
5. Close app

### Continuing Work (Same Device)
1. Re-open card → Map Wizard
2. See prompt: "You have unsaved map work from X ago. Restore?"
3. Tap "Restore"
4. **Wizard jumps directly to drawing canvas** (no welcome screens)
5. See your previous work
6. Continue drawing

### Continuing Work (Different Device)
1. Draw on iPad
2. Wait ~30 seconds for CloudKit sync
3. Open same card on Mac
4. See restoration prompt
5. Tap "Restore"
6. **Wizard jumps directly to drawing canvas**
7. See your iPad work
8. Continue drawing on Mac

### Starting Fresh (When Draft Exists)
1. See restoration prompt
2. Tap "Start Fresh"
3. Wizard goes through normal flow: Welcome → Select Method → Configure
4. Canvas is blank

## Technical Notes

### Auto-Save Behavior
- **Frequency**: Every 30 seconds
- **Format**: PNG image (includes background, grid, and all strokes)
- **Storage**: SwiftData with `@Attribute(.externalStorage)`
- **Sync**: Automatic via CloudKit (uses CKAsset)

### File Sizes
- Typical canvas (2048×2048): ~500KB - 2MB
- Large canvas (4096×4096): ~2MB - 8MB
- Complex drawings: Can be larger

### What's Saved
- ✅ All drawing strokes (flattened)
- ✅ Background color
- ✅ Grid overlay (if enabled)
- ✅ Canvas size
- ❌ Individual strokes (for editing)
- ❌ Undo/redo history
- ❌ Zoom level
- ❌ Active tool selection

### What's NOT Saved
Individual stroke data is not preserved between sessions. This means:
- You **can** continue drawing on top of previous work
- You **cannot** undo strokes from a previous session
- You **cannot** edit individual strokes after restoration

**Workaround**: Complete complex editing in a single session where full undo/redo is available.

## Code Examples

### Exporting Canvas as PNG (DrawingCanvasModel)
```swift
let pngData = drawingCanvasModel.exportCanvasAsPNG()
card.saveDraftMapWork(pngData, method: "Draw Map")
```

### Restoring from PNG (MapWizardView)
```swift
// Try legacy format first
do {
    try drawingCanvasModel.importCanvasState(draftData)
} catch {
    // New PNG format
    drawingCanvasModel.importCanvasFromPNG(draftData)
}

// Jump directly to configure step
currentStep = .configure
```

### macOS PNG Export (MacOSDrawingView)
```swift
func exportAsPNGData() -> Data? {
    let bitmapRep = NSBitmapImageRep(...)
    // Render canvas into bitmap
    draw(bounds)
    return bitmapRep.representation(using: .png, properties: [:])
}
```

## Troubleshooting

### Draft Not Restoring
**Symptoms**: Restoration prompt doesn't appear, or canvas is blank after restoration

**Possible Causes**:
1. Draft data is corrupted
2. PNG export failed during save
3. CloudKit sync hasn't completed

**Solutions**:
- Check console logs for "[DRAFT]" messages
- Verify `card.draftMapWorkData` is not nil
- Wait longer for CloudKit sync (can take 30-60 seconds)
- Try "Start Fresh" and recreate the work

### PNG Too Large
**Symptoms**: Sync is slow, app uses too much memory

**Possible Causes**:
1. Canvas size is too large (>4096×4096)
2. Very complex drawing with many strokes

**Solutions**:
- Use smaller canvas size (2048×2048 is recommended)
- Simplify the drawing
- Finalize the map to clear the draft

### Strokes Lost After Restoration
**Symptoms**: Some strokes are missing after restoring on another device

**Possible Causes**:
1. Auto-save didn't complete before switching devices
2. CloudKit sync failed

**Solutions**:
- Wait 30+ seconds after drawing before switching devices
- Check network connection on both devices
- Re-draw the missing strokes (they will be saved in next auto-save)

## Best Practices

1. **Save Intentionally**: Wait 30 seconds after drawing before closing the app
2. **Verify Sync**: Check that CloudKit sync completes before switching devices
3. **Work in Sessions**: Complete complex editing in one session to preserve undo/redo
4. **Finalize When Done**: Tap "Finalize" to save the final map and clear the draft
5. **Use Reasonable Canvas Sizes**: 2048×2048 is optimal for most maps

## Migration from Old Format

Existing drafts in the old `CanvasStateData` format will still restore correctly. The code tries legacy format first:

```swift
do {
    try drawingCanvasModel.importCanvasState(draftData)
    print("Restored legacy format")
} catch {
    drawingCanvasModel.importCanvasFromPNG(draftData)
    print("Restored PNG format")
}
```

After restoration, the next auto-save will use the new PNG format.
