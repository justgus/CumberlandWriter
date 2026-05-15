# Phase 1.5 Enhancement: Automatic Citation Creation from Image Metadata

**Status:** ✅ Complete  
**Date:** November 11, 2025  
**Purpose:** Automatically create image attribution Citations from extracted metadata when importing images or capturing maps

---

## Overview

This enhancement integrates with the existing **Citation system** to automatically create image attribution citations when users import images through the MapWizardView. Instead of manually creating citations through the ImageAttributionEditor, the system now:

1. Extracts metadata from imported images (camera, software, date, GPS)
2. Captures metadata from map snapshots (location, date, map type)
3. **Automatically creates a Citation** with `kind = .image` linked to an appropriate Source
4. Populates citation fields (locator, contextNote) with extracted metadata

---

## Understanding the Existing Citation System

### Models

**Citation** (`Citation.swift`):
- Links a **Card** to a **Source**
- Has a **kind** (`.quote`, `.paraphrase`, `.image`, `.data`)
- Contains:
  - `locator`: Location within source (e.g., "p. 42", "fig. 2", "00:12:15")
  - `excerpt`: Direct quote or description
  - `contextNote`: Additional context or notes
  - `createdAt`: Timestamp

**Source** (`Source.swift`):
- Represents the origin of content (book, article, website, etc.)
- Contains bibliographic information (title, authors, year, publisher, etc.)
- Can have multiple citations across different cards

**Relationship:**
```
Card ←→ Citation ←→ Source
     (many)     (many)
```

### Existing UI

**ImageAttributionViewer** - Displays image citations for a card  
**ImageAttributionEditor** - Manual creation/editing of image citations

---

## Implementation

### Changes Made

#### MapWizardView.swift

**Updated `saveMap()` function:**
```swift
private func saveMap() {
    guard let data = importedImageData else { return }
    
    // Save to card (reusing existing image infrastructure)
    let ext = inferFileExtension(from: data) ?? "jpg"
    try? card.setOriginalImageData(data, preferredFileExtension: ext)
    
    // Create automatic image attribution citation from metadata
    createAutomaticImageCitation()
    
    try? modelContext.save()
    
    // Reset wizard
    resetWizard()
}
```

**New function: `createAutomaticImageCitation()`**

This function:
1. Examines `mapMetadata` (for map captures) or `imageMetadata` (for imported images)
2. Determines appropriate source information
3. Finds or creates a Source record
4. Creates a Citation with `kind = .image`
5. Populates citation fields with metadata

---

## Citation Creation Logic

### For Map Captures (mapMetadata present)

**Source:**
- **Title:** `"Apple Maps"`
- **Authors:** `"Apple Inc."`

**Citation:**
- **Locator:** Location name (e.g., "Golden Gate Bridge") or map type
- **Context Note:** 
  - Map type (Standard/Satellite/Hybrid)
  - Capture date
  - Center coordinates (for reference)

**Example Citation:**
```
Source: Apple Maps (Apple Inc.)
Locator: Golden Gate Bridge
Context Note: Satellite map view • Captured Nov 11, 2025 • Center: 37.8199, -122.4783
```

---

### For Imported Images with Camera Metadata

**Source:**
- **Title:** Camera model (e.g., "iPhone 15 Pro")
- **Authors:** Camera make (e.g., "Apple")

**Citation:**
- **Locator:** Date taken + dimensions
- **Context Note:** Software, format, GPS indicator

**Example Citation:**
```
Source: iPhone 15 Pro (Apple)
Locator: Nov 11, 2025 • 4032 × 3024
Context Note: Software: iOS 17.1 • Format: HEIC • 📍 Geotagged
```

---

### For Images from Software (no camera, but has software metadata)

**Source:**
- **Title:** Software name (e.g., "Adobe Photoshop CC 2025")
- **Authors:** `"Digital Image"`

**Citation:**
- **Locator:** Dimensions + format
- **Context Note:** None

**Example Citation:**
```
Source: Adobe Photoshop CC 2025 (Digital Image)
Locator: 1920 × 1080 • PNG
```

---

### For Generic Images (no useful metadata)

**No citation created** - User can manually add attribution if desired

---

## Source Deduplication

The system **reuses existing Sources** when possible:

```swift
let fetchDescriptor = FetchDescriptor<Source>(
    predicate: #Predicate<Source> { source in
        source.title == sourceTitle && source.authors == sourceAuthors
    }
)

let existingSource = try? modelContext.fetch(fetchDescriptor).first
```

This means:
- Multiple iPhone photos → Single "iPhone 15 Pro (Apple)" Source
- Multiple map captures → Single "Apple Maps (Apple Inc.)" Source
- Keeps the Source list clean and organized

---

## Data Flow

### Import Image Flow

```
User imports/drops image
        ↓
loadImage(data:) called
        ↓
ImageMetadataExtractor.extract(from: data)
        ↓
Metadata stored in @State imageMetadata
        ↓
User proceeds through wizard
        ↓
saveMap() called
        ↓
card.setOriginalImageData(data)
        ↓
createAutomaticImageCitation() called
        ↓
Examine imageMetadata
        ↓
Determine source title/authors from camera/software
        ↓
Find or create Source
        ↓
Create Citation with metadata in fields
        ↓
modelContext.save()
        ↓
Citation visible in ImageAttributionViewer
```

### Map Capture Flow

```
User searches/navigates map
        ↓
User clicks "Capture Map"
        ↓
MKMapSnapshotter creates snapshot
        ↓
MapCaptureMetadata created (location, date, type, coords)
        ↓
User confirms capture
        ↓
Data moved to importedImageData
        ↓
User proceeds through wizard
        ↓
saveMap() called
        ↓
card.setOriginalImageData(data)
        ↓
createAutomaticImageCitation() called
        ↓
Examine mapMetadata
        ↓
Source: "Apple Maps (Apple Inc.)"
        ↓
Find or create Source
        ↓
Create Citation with location/date/coords
        ↓
modelContext.save()
        ↓
Citation visible in ImageAttributionViewer
```

---

## Example Citations in UI

When viewing a card with an imported map image, the **ImageAttributionViewer** will show:

```
┌─ Image attribution ──────────────────────┐
│                                   [+]     │
│                                          │
│  Apple Maps, "Apple Maps," 2025          │
│  Golden Gate Bridge — Satellite map...   │
│                              [⋮]          │
│  ────────────────────────────────────    │
│  iPhone 15 Pro, "iPhone 15 Pro," 2025    │
│  Nov 11, 2025 • 4032 × 3024 — Soft...    │
│                              [⋮]          │
└──────────────────────────────────────────┘
```

Users can:
- Click **[+]** to add additional manual attributions
- Click **[⋮]** to edit or delete automatic citations
- View full citation details by clicking on entries

---

## Integration with Existing Features

### Works With:
- ✅ **ImageAttributionViewer** - Displays automatic citations
- ✅ **ImageAttributionEditor** - Can edit automatic citations
- ✅ **Source management** - Sources are created/reused properly
- ✅ **Citation deletion** - Users can remove automatic citations if unwanted
- ✅ **CloudKit sync** - Citations sync like any other data

### Doesn't Interfere With:
- ✅ Manual citation creation (still available)
- ✅ Other citation kinds (quotes, paraphrases, data)
- ✅ Existing card image workflows
- ✅ Other card types (only runs in MapWizardView)

---

## Privacy Considerations

### GPS Coordinates
- **Map captures:** Coordinates stored in `contextNote` for user reference
- **Photo GPS:** Presence indicated ("📍 Geotagged") but coordinates NOT stored
- **User control:** Citations can be edited or deleted to remove location data

### Camera/Software Information
- Extracted from standard EXIF metadata (public fields)
- No private/sensitive data exposed
- Users can manually edit or delete citations

---

## Benefits

### For Writers
1. **Zero-effort attribution** - Automatic tracking of image sources
2. **Professional documentation** - Proper sourcing for research/publication
3. **Organization** - Easy to see where images came from
4. **Context preservation** - Technical details available for reference

### For App Quality
1. **Data richness** - More context for user's content
2. **Integration** - Uses existing Citation system (no new fields/models)
3. **User control** - Automatic citations can be edited/removed
4. **Extensibility** - Foundation for citation reports/exports

---

## Testing Checklist

### Map Captures
- [x] Capture named location → Citation created with location name
- [x] Capture unnamed location → Citation created with map type
- [x] Multiple captures → Single "Apple Maps" Source reused
- [x] Citation appears in ImageAttributionViewer
- [x] Citation can be edited through ImageAttributionEditor
- [x] Citation can be deleted

### Imported Images
- [x] iPhone photo with EXIF → Citation with camera + date + GPS indicator
- [x] DSLR photo → Citation with camera + date
- [x] Screenshot → Citation with software name
- [x] Edited image (Photoshop) → Citation with software
- [x] Generic image (no metadata) → No citation created
- [x] Multiple photos from same camera → Same Source reused
- [x] Citation appears in ImageAttributionViewer

### Edge Cases
- [x] Import image, then manually add another citation → Both coexist
- [x] Delete automatic citation → Remains deleted (no recreation)
- [x] Edit automatic citation → Stays edited
- [x] Image with partial metadata (camera but no date) → Citation created
- [x] Source deduplication works across different cards

### Integration
- [x] Citations sync via SwiftData/CloudKit
- [x] Card deletion cascades to citations properly
- [x] Source deletion behavior correct (shouldn't happen if citations exist)

---

## Future Enhancements

### Short Term
- [ ] User preference: Enable/disable automatic citation creation
- [ ] Smarter Source matching (fuzzy match camera models)
- [ ] Batch import → Multiple citations created automatically

### Medium Term
- [ ] Citation templates (custom formatting)
- [ ] Export citations to bibliography formats
- [ ] Filter/search cards by image source
- [ ] Metadata editing before citation creation

### Long Term
- [ ] Image library view with citation filtering
- [ ] Automatic copyright/license detection
- [ ] Integration with external image databases (Getty, Unsplash)
- [ ] OCR of image watermarks for attribution

---

## Comparison with Initial Incorrect Approach

### ❌ What We Almost Did (Wrong)
- Add `originalImageAttribution: String?` field to Card model
- Store attribution as plain text string
- Display attribution separately from citations
- Duplicate attribution system alongside existing citations

### ✅ What We Actually Did (Correct)
- Reuse existing `Citation` model with `kind = .image`
- Leverage existing `Source` model for attribution sources
- Integrate with existing `ImageAttributionViewer` UI
- Automatically create proper relational data

### Why the Correct Approach is Better
1. **No model changes** - Uses existing infrastructure
2. **Relational data** - Sources can be shared across cards
3. **Existing UI** - ImageAttributionViewer shows automatic citations
4. **User control** - Citations can be edited/deleted like any other
5. **Consistency** - All attributions go through same system
6. **Extensibility** - Citations already support export/reports

---

## Code Walkthrough

### Key Function: `createAutomaticImageCitation()`

```swift
private func createAutomaticImageCitation() {
    // Determine source and citation details based on image origin
    let sourceTitle: String
    let sourceAuthors: String
    let locator: String
    let contextNote: String?
    
    if let mapMeta = mapMetadata {
        // Map capture logic...
    } else if let metadata = imageMetadata {
        if let camera = metadata.cameraModel ?? metadata.cameraMake {
            // Camera photo logic...
        } else if let software = metadata.software {
            // Software/screenshot logic...
        } else {
            // No useful metadata - don't create citation
            return
        }
    } else {
        // No metadata - don't create citation
        return
    }
    
    // Find or create the source
    let fetchDescriptor = FetchDescriptor<Source>(
        predicate: #Predicate<Source> { source in
            source.title == sourceTitle && source.authors == sourceAuthors
        }
    )
    
    let existingSource = try? modelContext.fetch(fetchDescriptor).first
    let source: Source
    
    if let existing = existingSource {
        source = existing
    } else {
        source = Source(
            title: sourceTitle,
            authors: sourceAuthors,
            accessedDate: Date()
        )
        modelContext.insert(source)
    }
    
    // Create the citation
    let citation = Citation(
        card: card,
        source: source,
        kind: .image,
        locator: locator,
        excerpt: "",
        contextNote: contextNote,
        createdAt: Date()
    )
    
    modelContext.insert(citation)
}
```

---

## Related Files

- `Citation.swift` - Citation model
- `Source.swift` - Source model
- `CitationKind.swift` - Citation kind enum (includes `.image`)
- `ImageAttributionViewer.swift` - UI to display image citations
- `ImageAttributionEditor.swift` - UI to create/edit citations manually
- `ImageMetadataExtractor.swift` - Extracts EXIF/metadata from images
- `MapWizardView.swift` - **Modified** to create automatic citations

---

## Changelog

**2025-11-11** - Initial implementation
- ✅ Implemented `createAutomaticImageCitation()` in MapWizardView
- ✅ Automatic citation creation for map captures
- ✅ Automatic citation creation for imported images with metadata
- ✅ Source deduplication logic
- ✅ Integration with existing Citation/Source system
- ✅ No model changes required
- ✅ Privacy-conscious (GPS coordinates not stored for photos)

---

**End of Document**
