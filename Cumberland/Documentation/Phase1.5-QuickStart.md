# Phase 1.5: Quick Start Guide

## What's New in Phase 1.5? 🎉

Two major enhancements to the Import Image workflow:

1. **Drag & Drop** - Drag images directly from Finder/Files into the wizard
2. **Metadata Extraction** - See image details (size, dimensions, camera info, GPS)

---

## How to Use: Drag & Drop

### Basic Usage

1. **Start the wizard** on a Map card
2. **Select "Import Image"** method
3. **Drag an image file** from Finder/Files
4. **Drop it** onto the dashed-border zone
5. ✨ Image loads automatically with metadata!

### What You'll See

**Before dropping:**
- Dashed gray border
- Gray photo icon
- "Drag & drop image here" text

**While dragging over:**
- Solid blue border
- Blue filled icon
- Blue background tint
- "Drop image here" text

**After dropping:**
- Image preview
- Metadata panel below
- "Choose Different Image" button
- "Continue" button enabled

---

## How to Use: Metadata Viewing

### What Metadata Is Shown?

The wizard automatically extracts and displays:

**Always Available:**
- 📐 **Dimensions** - Width × Height in pixels
- 📄 **File Size** - Human-readable (MB/KB)
- 🖼️ **Format** - PNG, JPEG, HEIC, etc.

**If Available:**
- 📏 **Resolution** - DPI (dots per inch)
- 📷 **Camera** - Device that created the image
- 📍 **GPS** - Location data indicator

### Example Metadata Panel

```
┌─ Image Information ──────────────────┐
│ 📐 Dimensions    1920 × 1080          │
│ 📄 File Size     2.4 MB               │
│ 🖼️  Format        PNG                  │
│ 📏 Resolution    300 DPI              │
│ 📷 Camera        iPhone 15 Pro        │
│ 📍 GPS location data available        │
└───────────────────────────────────────┘
```

---

## Three Ways to Import

### 1. Drag & Drop (NEW!)
- **Fastest** for desktop workflows
- Drag from Finder (macOS) or Files (iOS)
- Visual feedback as you drag
- **Best for:** Quickly adding images you can see

### 2. File Browser
- Click "Choose from Files" button
- Browse your file system
- Filter shows only images
- **Best for:** Finding images in specific folders

### 3. Photos Library
- Click "Choose from Photos" button
- Access Photos app library
- Includes iCloud Photos
- **Best for:** Using photos you've already organized

---

## Platform Support

### macOS
✅ Drag from Finder  
✅ Drag from Desktop  
✅ Drag from other apps  
✅ File browser  
✅ Photos library  

### iOS
✅ Drag from Files app  
✅ Drag from Photos app  
✅ File browser  
✅ Photos library  

### iPadOS
✅ Drag from Split View  
✅ Drag from Slide Over  
✅ Drag from Files app  
✅ File browser  
✅ Photos library  

---

## Tips & Tricks

### Tip 1: Check Image Quality
Use the metadata panel to verify dimensions and resolution before importing.

**Good for high-quality printing:**
- Resolution: 300 DPI or higher
- Dimensions: Large enough for your needs

**Good for screen display:**
- Resolution: 72-150 DPI is fine
- File size: Smaller is faster

### Tip 2: GPS Data
If you see "📍 GPS location data available", the image was taken at a specific location.

**Useful for:**
- Real-world setting maps
- Location scouting
- Verifying image source

### Tip 3: File Size Awareness
Check file size to manage storage:
- **< 1 MB** - Small, fast to load
- **1-5 MB** - Standard size
- **> 5 MB** - Large, may be slow on mobile

### Tip 4: Camera Info
Camera model tells you the source:
- **iPhone/Android** - Likely a photo
- **DSLR** - Professional photography
- **No camera** - Probably a screenshot or generated image

---

## Workflow Examples

### Scenario 1: Fantasy Map from Artist

```
1. Artist sends you "kingdom_map.png"
2. Save to Downloads folder
3. Open Map Wizard → Import Image
4. Drag from Downloads into wizard
5. Check metadata:
   - 4096 × 3072 (high res! ✅)
   - 8.2 MB (large file)
   - PNG (good for maps)
6. Continue → Save to card
```

### Scenario 2: Screenshot from Map Generator

```
1. Generate map on website
2. Take screenshot (⌘⇧4 on Mac)
3. Screenshot saved to Desktop
4. Drag directly from Desktop into wizard
5. Check metadata:
   - 2560 × 1440 (good res)
   - 892 KB (small! ✅)
   - PNG
   - No camera (screenshot ✅)
6. Continue → Save
```

### Scenario 3: Photo from Location Scouting

```
1. Take photo of location with iPhone
2. Photo syncs to iCloud Photos
3. Click "Choose from Photos"
4. Select photo from library
5. Check metadata:
   - 4032 × 3024 (phone camera res)
   - 5.8 MB
   - JPEG
   - iPhone 15 Pro
   - GPS data available ✅ (location preserved!)
6. Continue → Save
```

---

## Common Questions

### Q: What image formats are supported?
**A:** All standard formats:
- PNG (recommended for maps)
- JPEG/JPG
- HEIC (iPhone photos)
- TIFF
- BMP
- GIF (static images)
- WebP (on supported systems)

### Q: What happens to the metadata?
**A:** Currently, metadata is **displayed but not saved**. It's used for preview and verification only. Future enhancement may store it with the card.

### Q: Can I import multiple images at once?
**A:** Not yet. Batch import is **flagged for Phase 3+**. For now, import one image per card, then create additional cards as needed.

### Q: What if metadata extraction fails?
**A:** The image still imports successfully. The metadata panel either:
- Shows partial information (some fields)
- Doesn't appear at all (no metadata)

This is normal for generated images or screenshots.

### Q: Can I edit metadata?
**A:** No, metadata is read-only and extracted from the source file. To change metadata, edit the image file externally, then re-import.

### Q: Does drag & drop work on mobile?
**A:** Yes! On iOS/iPadOS, drag from:
- Files app
- Photos app
- Safari (long-press image)
- Other apps with drag support

### Q: Can I drop multiple files?
**A:** Only the first file will be processed. Multiple-file drop support is deferred to batch import (Phase 3+).

---

## Troubleshooting

### Problem: Drag doesn't highlight the zone
**Solution:** Make sure you're dragging an image file. Non-image files are ignored.

### Problem: Drop doesn't import
**Solution:** 
- Check file format is supported
- Try using "Choose from Files" button instead
- Verify file isn't corrupted (open in Preview/Photos)

### Problem: No metadata appears
**Solution:** This is normal for:
- Screenshots (no camera data)
- Generated images (no EXIF)
- Optimized images (stripped metadata)

The image will still import successfully.

### Problem: Image looks wrong in preview
**Solution:**
- Check the source file in another app
- Try re-saving the image
- Verify format is supported

### Problem: "Choose Different Image" doesn't work
**Solution:** File picker/Photos picker needs permission:
- macOS: Grant file access in System Settings
- iOS: Enable Files/Photos access in Settings → Privacy

---

## Keyboard Shortcuts

### macOS
- **⌘V** - Paste image from clipboard (future enhancement)
- **Space** - Quick Look preview in file browser
- **Tab** - Navigate between buttons
- **Return** - Activate focused button
- **Esc** - Cancel file/photos picker

### iOS/iPadOS
- **Tab** (with keyboard) - Navigate buttons
- **Return** - Activate focused button
- **Esc** - Cancel picker

---

## Integration with Wizard Flow

### Complete Import Workflow

```
Welcome
   ↓
Select Method → Choose "Import Image"
   ↓
Configure:
   ├─ Option A: Drag & drop image
   ├─ Option B: Choose from Files
   └─ Option C: Choose from Photos
   ↓
Image loads + metadata extracted
   ↓
Preview + metadata panel displayed
   ↓
Click "Continue" (now enabled)
   ↓
Finalize:
   ├─ Review preview
   └─ Click "Save Map to Card"
   ↓
Card updated with image
   ↓
Wizard resets to Welcome
```

---

## Best Practices

### ✅ Do This

- **Check dimensions** before importing
- **Use PNG** for maps with sharp lines
- **Use JPEG** for photos/realistic images
- **Verify file size** if storage is limited
- **Use drag & drop** for speed

### ❌ Avoid This

- **Don't** import extremely large files (>50MB) on mobile
- **Don't** import corrupted images
- **Don't** expect to edit metadata in the wizard
- **Don't** try to drop non-image files

---

## Performance Tips

### Fast Imports
- Use smaller files (<5MB) for speed
- PNG compresses well for maps
- JPEG compresses well for photos
- Drag & drop is fastest method

### Slow Imports
If imports are slow:
- Check file size (maybe too large)
- Try saving image at lower resolution
- Use compression tools externally
- Switch to file browser (may be faster)

---

## What's Next?

### Already Available
- ✅ Phase 4: Drawing Canvas (completed earlier)
  - Draw custom maps with PencilKit
  - Multiple tools (pen, marker, pencil, eraser)
  - Full color customization

### Coming Soon
- 🚧 Phase 5: Maps Integration
  - Capture from Apple Maps
  - Location search
  - Geographic coordinates

### Future Enhancements
- 📋 Batch import (multiple images at once)
- 📋 Metadata storage (save to card)
- 📋 Paste from clipboard
- 📋 Image editing tools
- 📋 GPS map overlay

---

## Need Help?

### Resources
- **Main Spec**: `MapWizardViewSpec.md`
- **Implementation Details**: `Phase1.5-DragDrop-Metadata-Summary.md`
- **Visual Reference**: `Phase1.5-Visual-Reference.md`
- **Code**: `MapWizardView.swift`, `ImageMetadataExtractor.swift`

### Contact
File issues or ask questions through your normal development workflow.

---

**Quick Start Version:** 1.5  
**Last Updated:** November 11, 2025  
**Status:** ✅ Complete & Ready to Use
