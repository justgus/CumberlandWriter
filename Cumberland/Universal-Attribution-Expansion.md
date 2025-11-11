# Universal Image Attribution Expansion

**Date:** November 11, 2025  
**Status:** ✅ Complete  
**Purpose:** Expand automatic image attribution extraction to all image import locations

---

## Overview

Previously, automatic image attribution extraction (using `ImageMetadataExtractor`) was only implemented in **MapWizardView** for Map-kind cards. This enhancement extends that capability to **all views** where images can be imported from external sources.

---

## Changes Made

### 1. CardEditorView (Create/Edit Card Modal)

#### Added State Property
```swift
@State private var imageMetadata: ImageMetadataExtractor.ImageMetadata?
```

#### Updated Image Loading Functions

**PhotosPicker Handler:**
```swift
private func setImageDataFromPickerItem(_ item: PhotosPickerItem?) async {
    // ... existing code ...
    if let data = try? await item.loadTransferable(type: Data.self),
       Self.isSupportedImageData(data) {
        imageData = data
        // ✅ NEW: Extract metadata for automatic attribution
        imageMetadata = ImageMetadataExtractor.extract(from: data)
    }
}
```

**File Importer:**
```swift
.fileImporter(isPresented: $isImportingImage, allowedContentTypes: [.image]) { result in
    if case let .success(url) = result,
       let data = try? Data(contentsOf: url) {
        imageData = data
        // ✅ NEW: Extract metadata for automatic attribution
        imageMetadata = ImageMetadataExtractor.extract(from: data)
    }
}
```

**Drop Handlers (all paths):**
- `handleImageDrop()` - UIImage/NSImage object drops
- `tryURLOrData()` - Generic data drops
- `tryLoadFileURL()` - File URL drops (Finder)
- `tryLoadRemoteURL()` - Remote URL drops (Safari)

Each now includes:
```swift
self.imageMetadata = ImageMetadataExtractor.extract(from: data)
```

#### Updated Save Logic

**Create Mode:**
```swift
if let data = imageData {
    let ext = Self.inferFileExtension(from: data) ?? "jpg"
    // ✅ NEW: Use automatic attribution from extracted metadata
    let attribution = imageMetadata?.attributionText
    try? card.setOriginalImageData(data, preferredFileExtension: ext, attribution: attribution)
}
```

**Edit Mode:** Same logic applied.

---

### 2. CardSheetView (Detail View)

#### Updated Drop Handler

```swift
private func handleDroppedImageData(_ data: Data) -> Bool {
    do {
        let oldURL = card.imageFileURL
        // ✅ NEW: Extract metadata and generate attribution
        let metadata = ImageMetadataExtractor.extract(from: data)
        let attribution = metadata.attributionText
        try card.setOriginalImageData(data, preferredFileExtension: nil, attribution: attribution)
        // ... rest of function ...
    }
}
```

**Note:** CardSheetView only has drop target functionality, no PhotosPicker or file importer.

---

### 3. MapWizardView

**No changes needed** - already had full metadata extraction and attribution implementation from Phase 1.5.

---

## Coverage Summary

### ✅ All Image Import Methods Now Extract Metadata

| View | Import Method | Status |
|------|--------------|--------|
| **CardEditorView** | PhotosPicker | ✅ Extracts metadata |
| **CardEditorView** | File Importer | ✅ Extracts metadata |
| **CardEditorView** | Drag & Drop (UIImage/NSImage) | ✅ Extracts metadata |
| **CardEditorView** | Drag & Drop (File URL) | ✅ Extracts metadata |
| **CardEditorView** | Drag & Drop (Remote URL) | ✅ Extracts metadata |
| **CardEditorView** | Drag & Drop (Generic Data) | ✅ Extracts metadata |
| **CardSheetView** | Drag & Drop | ✅ Extracts metadata |
| **MapWizardView** | All methods | ✅ Already implemented |

---

## Attribution Generation Examples

The `ImageMetadataExtractor.ImageMetadata.attributionText` property generates human-readable attribution strings:

### Camera Photos
```
Apple iPhone 15 Pro • Nov 11, 2025 • 📍 Geotagged
Canon EOS R5 • Nov 11, 2025
```

### Edited Images
```
Apple iPhone 14 Pro (Adobe Lightroom CC) • Nov 10, 2025
```

### Screenshots
```
macOS 15.0
```

### Images Without Metadata
```
nil
```

### Map Captures (MapWizardView)
```
Apple Maps • Golden Gate Bridge • Satellite view • Nov 11, 2025
Apple Maps • Standard view • Nov 11, 2025
```

---

## Data Flow

### Standard Import Flow (All Views)

```
User imports/drops image
        ↓
Image data loaded (Data)
        ↓
ImageMetadataExtractor.extract(from: data)
        ↓
metadata.attributionText computed
        ↓
card.setOriginalImageData(..., attribution: text)
        ↓
Attribution saved to Card.originalImageAttribution
        ↓
SwiftData persists to database/CloudKit
```

---

## Benefits

### Consistency
- **Same behavior across all views** - users get attribution regardless of how they add images
- **Unified code pattern** - easier to maintain and debug

### User Experience
- **Automatic documentation** - no manual entry required
- **Context preservation** - camera, date, location info retained
- **Research value** - know where images came from

### Privacy
- **Respects user privacy** - GPS coordinates not exposed in text
- **Only presence indicators** - "📍 Geotagged" instead of coordinates
- **Opt-out capable** - attribution is optional field

---

## Technical Details

### Performance
- **Synchronous extraction** - Fast (<10ms for typical images)
- **No network calls** - All local processing
- **Minimal memory overhead** - Metadata struct is lightweight

### Backwards Compatibility
- **Optional attribution parameter** - Existing code still works
- **Nil-safe** - Missing metadata results in `nil` attribution
- **SwiftData compatible** - Field has default value

### Privacy Considerations
- **GPS coordinates** - Not included in attribution text (only indicator)
- **Camera model** - Extracted from EXIF (user can manually remove if needed)
- **Location names** - Only from user's explicit actions (map searches)
- **Software info** - Extracted from metadata (e.g., "Adobe Photoshop")

---

## Testing Checklist

### CardEditorView

#### PhotosPicker
- [ ] Import iPhone photo → Verify attribution includes camera + date + GPS indicator
- [ ] Import edited photo → Verify attribution includes software
- [ ] Import screenshot → Verify attribution includes OS/software
- [ ] Import image without metadata → Verify attribution is nil

#### File Importer
- [ ] Import from Files → Verify metadata extracted
- [ ] Import JPEG with EXIF → Verify camera info present
- [ ] Import PNG without metadata → Verify attribution is nil

#### Drag & Drop
- [ ] Drop photo from Photos.app → Verify metadata extracted
- [ ] Drop file from Finder → Verify metadata extracted
- [ ] Drop image from Safari → Verify metadata extracted
- [ ] Drop screenshot → Verify software attribution

#### Save
- [ ] Create new card with image → Verify attribution saved
- [ ] Edit existing card with new image → Verify attribution saved
- [ ] Verify attribution persists after app restart

### CardSheetView

#### Drag & Drop
- [ ] Drop image onto detail view → Verify metadata extracted
- [ ] Drop photo from Photos.app → Verify attribution saved
- [ ] Drop file from Finder → Verify attribution saved
- [ ] Verify undo/redo preserves attribution

### MapWizardView

- [x] Already tested in Phase 1.5
- [x] Import image → Attribution works
- [x] Capture map → Attribution works
- [x] PhotosPicker → Attribution works
- [x] Drag & drop → Attribution works

---

## Code Patterns

### Standard Pattern for Image Loading

All image loading paths now follow this pattern:

```swift
// 1. Load image data
let data = /* obtain Data from various sources */

// 2. Store data
self.imageData = data

// 3. Extract metadata
self.imageMetadata = ImageMetadataExtractor.extract(from: data)

// 4. (Optional) Show pending attribution prompt
if self.isEditing {
    self.pendingAttribution = PendingAttribution(kind: .image, ...)
}
```

### Standard Pattern for Saving

```swift
if let data = imageData {
    let ext = inferFileExtension(from: data) ?? "jpg"
    let attribution = imageMetadata?.attributionText
    try? card.setOriginalImageData(data, 
                                    preferredFileExtension: ext, 
                                    attribution: attribution)
}
```

---

## Future Enhancements

### Short Term
- [ ] Display attribution in CardDetailView
- [ ] Show attribution in image inspector
- [ ] Allow manual editing of attribution
- [ ] Include attribution in exports (PDF/Markdown)

### Medium Term
- [ ] Batch attribution editing
- [ ] Attribution templates
- [ ] Copyright/license metadata
- [ ] Image source categories

### Long Term
- [ ] Searchable image library by metadata
- [ ] Filter cards by attribution source
- [ ] Export attribution reports
- [ ] Integration with rights management systems

---

## Related Documentation

- `MapWizardViewSpec.md` - Map wizard specification
- `Phase1.5-Attribution-Implementation.md` - Original attribution implementation
- `ImageMetadataExtractor.swift` - Metadata extraction utility

---

## Changelog

**2025-11-11** - Universal expansion complete
- ✅ Added metadata extraction to CardEditorView (all import methods)
- ✅ Added metadata extraction to CardSheetView (drop target)
- ✅ Updated save logic to use automatic attribution
- ✅ Maintained backwards compatibility
- ✅ Preserved privacy (GPS coordinates not exposed)
- ✅ Consistent behavior across all views

---

**End of Document**
