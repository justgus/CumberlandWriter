# Map Draft Work Persistence Implementation

## Overview

The Map Wizard now automatically saves work-in-progress to the backend database (SwiftData), enabling seamless cross-device continuity. Users can start working on a map on one device and pick up exactly where they left off on another device via CloudKit sync.

## Architecture

### Database Schema (Card.swift)

Three new fields were added to the `Card` model:

```swift
@Attribute(.externalStorage)
var draftMapWorkData: Data?

var draftMapWorkTimestamp: Date?

var draftMapMethodRaw: String?
```

- **draftMapWorkData**: Stores the serialized draft work (drawing data, imported images, or method-specific data). Uses external storage for efficient CloudKit sync via CKAsset.
- **draftMapWorkTimestamp**: Timestamp of the last draft save, allowing UI to show "how long ago" work was saved.
- **draftMapMethodRaw**: The map creation method (draw, interior, importImage, etc.) so the wizard can restore the correct UI state.

### Canvas State Serialization (DrawingCanvasView.swift)

The `DrawingCanvasModel` now supports complete state export/import:

```swift
func exportCanvasState() -> Data?
func importCanvasState(_ data: Data) throws
```

This captures:
- PencilKit drawing data
- Canvas size, zoom level
- Background color
- Grid settings (visibility, spacing, type, color)

A new `CanvasStateData` struct is Codable and contains all necessary state information.

### Auto-Save Mechanism (MapWizardView.swift)

#### Restoration on Launch

When the Map Wizard opens:
1. `checkForDraftWork()` runs in `.onAppear`
2. If draft work exists, shows an alert asking if the user wants to restore or start fresh
3. If restored, `restoreDraftWork()` loads the appropriate state based on the saved method

#### Periodic Auto-Save

- Timer starts when user begins working in the configure step
- Saves every 30 seconds automatically
- `autoSaveDraftWork()` serializes current state based on the selected method:
  - **Draw/Interior**: Saves complete canvas state (drawing + settings)
  - **Import Image**: Saves the imported image data
  - **Capture from Maps**: Saves map snapshot + metadata (coordinates, map type, location)
  - **AI Generate**: Saves prompt + any generated image

#### Manual Save Triggers

Draft work is also saved when:
- User navigates forward/back between wizard steps
- User exits the wizard (save happens in `resetWizard()`)

#### Final Save

When the user finalizes their map:
1. `saveMap()` stores the final image to `originalImageData`
2. `clearDraftMapWork()` removes the draft since work is now complete
3. Auto-save timer stops

## Data Structures

### Method-Specific Containers

For complex methods that need to store metadata alongside image data:

```swift
struct MapCaptureMetadataContainer: Codable {
    let imageData: Data
    let metadata: MapCaptureMetadata?
}

struct AIGenerationDraft: Codable {
    let prompt: String
    let generatedImageData: Data?
}
```

These containers enable rich restoration of context (e.g., showing the location name and coordinates for a map capture).

### Color Serialization

Color hex encoding/decoding extensions enable storing SwiftUI `Color` values in JSON:

```swift
extension Color {
    func toHex() -> String
    init(hex: String)
}
```

## CloudKit Sync Behavior

- `draftMapWorkData` uses `@Attribute(.externalStorage)`, so SwiftData automatically uses CKAsset for efficient binary data sync
- Draft work syncs across devices just like any other Card property
- Users can start drawing on iPad, then continue on Mac seamlessly
- Conflicts are handled by SwiftData's merge policies (last-write-wins by default)

## User Experience

### First Launch
- No prompt; user starts fresh

### Subsequent Launches with Draft
- Alert shows: "You have unsaved map work from 2 hours ago. Would you like to continue where you left off?"
- Options:
  - **Restore**: Loads saved state and continues work
  - **Start Fresh**: Deletes draft and begins anew
  - **Cancel**: Closes alert without action

### During Work
- Auto-save happens silently every 30 seconds
- No UI indication (to avoid distraction)
- Work is automatically saved when navigating between steps

### On Finalization
- Draft is cleared since the map is now "published"
- Next time wizard opens, user starts with a clean slate

## Future Enhancements

Potential improvements:

1. **Manual Save Button**: Give users explicit control over when to save drafts
2. **Draft Version History**: Store multiple draft versions with timestamps
3. **Draft Preview in Card List**: Show a badge or indicator when a card has unsaved draft work
4. **Conflict Resolution UI**: If CloudKit reports a sync conflict, allow user to choose which version to keep
5. **Draft Expiration**: Automatically delete drafts older than N days
6. **Background Persistence**: Save drafts when app enters background (using scene phase)

## Testing Considerations

When testing this feature:

1. **Cross-Device Sync**: 
   - Start work on Device A
   - Wait for CloudKit sync (~5-30 seconds)
   - Open wizard on Device B
   - Verify restoration prompt appears with correct data

2. **Method-Specific Restoration**:
   - Test each map creation method separately
   - Verify settings (grid, colors, canvas size) restore correctly
   - Check that drawing strokes are identical after restoration

3. **Draft Clearing**:
   - Finalize a map
   - Reopen wizard
   - Verify no restoration prompt appears (draft was cleared)

4. **Large Canvases**:
   - Test with 4096×4096 canvas and complex drawings
   - Verify external storage handles large data efficiently
   - Check that sync completes successfully

## Implementation Notes

- The auto-save timer must be invalidated (`stopAutoSave()`) to prevent memory leaks
- Drawing changes are monitored via `.onChange(of: drawingCanvasModel.drawing)` to start auto-save
- The restoration logic handles missing or corrupted data gracefully (using `try?` for decoding)
- For macOS native drawing (non-PencilKit), the `macosCanvasView` handles stroke serialization
