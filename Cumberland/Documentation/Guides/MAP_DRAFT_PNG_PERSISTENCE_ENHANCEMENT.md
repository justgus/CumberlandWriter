# Map Draft PNG Persistence Enhancement

## Overview

The Map Wizard now persists drawing work as **PNG snapshots** instead of complete canvas state. This provides better cross-device compatibility and ensures that drawing work can be continued seamlessly on any device (Mac, iPad, iPhone) without requiring complex state restoration.

## Key Changes

### 1. **Wizard Locking to Configure Step**

When a user starts drawing a map, the wizard now "locks" to the configure step. This means:

- **On first launch**: User goes through: Welcome → Select Method → Configure
- **On restoration**: User goes **directly to Configure** with their selected method loaded
- **No more re-selection**: Once work begins, the user doesn't have to go through preliminary screens again

This provides a much more focused workflow - the writer can start drawing, leave the app, come back on another device, and immediately continue where they left off.

### 2. **PNG-Based Persistence**

#### Why PNG?

- **Universal compatibility**: PNG works on all platforms (iOS, iPadOS, macOS)
- **Simple restoration**: Just load the image and display it
- **CloudKit friendly**: PNG is a standard format that syncs efficiently
- **No state dependencies**: Doesn't rely on PencilKit or platform-specific drawing state

#### How It Works

**Auto-Save (every 30 seconds):**
```swift
// For draw/interior methods:
draftData = drawingCanvasModel.exportCanvasAsPNG()

// This captures:
// - Background color
// - Grid overlay (if enabled)
// - All drawing strokes
// - Full canvas dimensions
```

**Restoration:**
```swift
// Load the PNG snapshot
importedImageData = draftData

// Try legacy format first (backward compatibility)
do {
    try drawingCanvasModel.importCanvasState(draftData)
} catch {
    // PNG format - display as reference
    drawingCanvasModel.importCanvasFromPNG(draftData)
}
```

The drawing canvas shows the restored PNG, and the user can continue drawing on top of it.

### 3. **Implementation Details**

#### DrawingCanvasModel (DrawingCanvasView.swift)

**New Methods:**

```swift
/// Export the full canvas (including background) as PNG for draft persistence
func exportCanvasAsPNG() -> Data?

/// Import a PNG image as the canvas background/starting point
func importCanvasFromPNG(_ data: Data)
```

**Platform-Specific Handling:**

- **iOS/iPadOS (PencilKit)**: Uses `UIGraphicsImageRenderer` to composite:
  - Background color
  - Grid overlay
  - PencilKit drawing
  
- **macOS (Native Drawing)**: Uses bitmap representation to capture:
  - Background
  - Grid
  - All strokes

#### MacOSDrawingView (DrawingCanvasViewMacOS.swift)

**New Methods:**

```swift
/// Export canvas as PNG at the actual canvas size (not scaled)
func exportAsPNGData() -> Data?

/// Import a PNG image as a background layer for the canvas
func importPNGAsBackground(from pngData: Data)
```

The macOS implementation creates a high-quality bitmap representation of the entire canvas, including all strokes and visual settings.

#### MapWizardView (MapWizardView.swift)

**Changed Behaviors:**

1. **Auto-Save**:
   - Changed from `exportCanvasState()` to `exportCanvasAsPNG()`
   - Includes fallback to `exportAsImageData()` if PNG export fails
   - Logs the byte count for debugging

2. **Restoration**:
   - Always sets `currentStep = .configure` when draft exists
   - No longer respects saved wizard step - locks to configure
   - Tries legacy format first (backward compatibility)
   - Falls back to PNG import

3. **Draft Clearing**:
   - Draft is cleared only when map is finalized
   - Going back from configure still clears draft (with warning)

### 4. **Cross-Device Workflow**

**Example Scenario:**

1. **iPad - Start Drawing**
   - User opens Map Wizard
   - Selects "Draw Map"
   - Starts drawing a dungeon map
   - After 30 seconds, PNG snapshot auto-saves to SwiftData
   - CloudKit syncs the PNG (as CKAsset)

2. **Mac - Continue Drawing**
   - User opens same card on Mac
   - Map Wizard shows: "You have unsaved map work from 2 minutes ago. Restore?"
   - User taps "Restore"
   - Wizard **jumps directly to Configure** step
   - PNG loads showing the partial dungeon map
   - User continues drawing (adds rooms, annotations)
   - Another PNG snapshot auto-saves

3. **iPhone - Review and Finalize**
   - User opens card on iPhone
   - Wizard restores the latest PNG
   - User reviews the completed map
   - Taps "Finalize"
   - Map is saved to `originalImageData`
   - Draft is cleared

### 5. **Backward Compatibility**

The implementation maintains backward compatibility with existing draft data:

```swift
// Try to restore as legacy canvas state format
do {
    try drawingCanvasModel.importCanvasState(draftData)
    print("[DRAFT] Restored legacy canvas state format")
} catch {
    // New PNG format
    drawingCanvasModel.importCanvasFromPNG(draftData)
    print("[DRAFT] Restored PNG snapshot as canvas reference")
}
```

If the draft data is in the old `CanvasStateData` format, it will decode and restore properly. If it's PNG data, it imports as a visual reference.

### 6. **Trade-offs**

**What We Gain:**
- ✅ Simple, universal format (PNG)
- ✅ Works identically on all platforms
- ✅ Easy to debug (can view the PNG in any image viewer)
- ✅ Efficient CloudKit sync
- ✅ No platform-specific state dependencies

**What We Lose:**
- ❌ Individual stroke editing history (can't undo strokes from previous sessions)
- ❌ Layer separation (all strokes are flattened)
- ❌ Grid settings persistence (grid is baked into PNG)
- ❌ Zoom level restoration (starts at default zoom)

**Mitigation:**
- Users can still undo/redo within a single session
- Most drawing work is additive (adding more strokes)
- Grid can be toggled back on for continued work
- Zoom controls are easily accessible

## Testing Checklist

- [ ] **Fresh Drawing on iOS**
  - Start new map, draw for 30+ seconds, verify PNG auto-saves
  
- [ ] **Fresh Drawing on macOS**
  - Start new map, draw for 30+ seconds, verify PNG auto-saves
  
- [ ] **Cross-Device Restoration (iOS → macOS)**
  - Draw on iOS, wait for sync, open on macOS, verify restoration prompt
  - Check that wizard jumps directly to Configure step
  
- [ ] **Cross-Device Restoration (macOS → iOS)**
  - Draw on macOS, wait for sync, open on iOS, verify restoration prompt
  - Check that wizard jumps directly to Configure step
  
- [ ] **Restoration Rejection**
  - Have draft work, choose "Start Fresh"
  - Verify wizard goes through normal flow (Welcome → Select Method → Configure)
  
- [ ] **Large Canvas**
  - Create 4096×4096 canvas, draw complex map
  - Verify PNG export completes successfully
  - Check file size is reasonable (<10MB)
  
- [ ] **Grid Overlay**
  - Enable grid, draw strokes
  - Verify PNG includes grid lines
  - After restoration, verify user can continue drawing
  
- [ ] **Background Color**
  - Change background to beige/parchment
  - Verify PNG includes background color
  - After restoration, verify background color is preserved
  
- [ ] **Finalize and Clear**
  - Complete a map, tap Finalize
  - Re-open wizard
  - Verify NO restoration prompt (draft was cleared)
  
- [ ] **Multiple Sessions**
  - Draw → close app
  - Re-open → restore → draw more → close app
  - Re-open → restore
  - Verify latest work is shown
  
- [ ] **Backward Compatibility**
  - Use old draft format (CanvasStateData)
  - Verify it still restores properly
  - Continue work, verify new saves are PNG

## Future Enhancements

### Possible Improvements:

1. **Layered Approach**
   - Save PNG + stroke data
   - PNG for quick visual restoration
   - Stroke data for full editing capability
   
2. **Compression**
   - Use JPEG for photos/complex drawings
   - Use PNG for line art/simple maps
   - Automatically choose best format
   
3. **Resolution Options**
   - Save lower-res PNG for drafts
   - Full-res only on finalization
   - Reduces sync time and storage
   
4. **Visual Diff**
   - Show what changed since last save
   - Highlight new strokes in different color
   - Help user remember where they left off
   
5. **Session Recording**
   - Record drawing session as video/animation
   - Play back to show evolution of map
   - Export as animated GIF or video

## Conclusion

The PNG-based persistence provides a simple, robust solution for cross-device map drawing continuity. By locking the wizard to the configure step and saving periodic snapshots, writers can seamlessly continue their creative work without friction or data loss.

The trade-off of losing individual stroke history is acceptable for most use cases, as the primary goal is to **not lose work** rather than to enable complex editing across sessions. For complex edits, users can complete their work in a single session where full undo/redo is available.
