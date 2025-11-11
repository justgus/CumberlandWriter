# Phase 1.5: Testing Checklist ✓

## Pre-Testing Setup

- [ ] Build project successfully
- [ ] No compiler warnings in new files
- [ ] Run on macOS simulator/device
- [ ] Run on iOS simulator/device
- [ ] Run on iPad simulator/device (if available)

---

## Drag & Drop Tests

### Basic Functionality

#### macOS
- [ ] Drag PNG from Finder → wizard
- [ ] Drag JPEG from Finder → wizard
- [ ] Drag HEIC from Finder → wizard
- [ ] Drag from Desktop → wizard
- [ ] Drag from Downloads → wizard
- [ ] Drag from iCloud Drive → wizard

#### iOS
- [ ] Drag PNG from Files app
- [ ] Drag JPEG from Files app
- [ ] Drag from Photos app
- [ ] Drag from iCloud Drive (in Files)

#### iPadOS (if available)
- [ ] Drag from Split View (Files on one side, wizard on other)
- [ ] Drag from Slide Over
- [ ] Drag from Photos in Split View

### Visual Feedback

- [ ] Default state: Gray dashed border
- [ ] Drag over: Border turns blue
- [ ] Drag over: Background gets blue tint
- [ ] Drag over: Icon changes to filled
- [ ] Drag over: Text changes to "Drop image here"
- [ ] Drag exit: All visual changes revert
- [ ] Animation is smooth (not jarring)

### Edge Cases

- [ ] Drag non-image file (should be rejected)
- [ ] Drag text file (should be rejected)
- [ ] Drag PDF (may work depending on image content)
- [ ] Drag multiple files (should accept first only)
- [ ] Drag very large file (>50MB) - should work but may be slow
- [ ] Rapid drag in/out multiple times
- [ ] Drop while another operation is in progress

---

## Metadata Extraction Tests

### Basic Metadata

- [ ] PNG shows dimensions
- [ ] PNG shows file size
- [ ] PNG shows format ("PNG")
- [ ] JPEG shows dimensions
- [ ] JPEG shows file size
- [ ] JPEG shows format ("JPEG")

### Camera Metadata (use iPhone/camera photo)

- [ ] Camera make displays (e.g., "Apple")
- [ ] Camera model displays (e.g., "iPhone 15 Pro")
- [ ] Date taken displays (if available)

### GPS Metadata (use geotagged photo)

- [ ] "📍 GPS location data available" appears
- [ ] Only shows for images with GPS data
- [ ] Doesn't show for screenshots

### Resolution

- [ ] DPI displays when available
- [ ] Shows as "72 DPI", "300 DPI", etc.
- [ ] Formats correctly with units

### Metadata Panel Layout

- [ ] Panel appears below image preview
- [ ] All rows are aligned
- [ ] Icons are blue
- [ ] Labels are gray
- [ ] Values are bold
- [ ] GroupBox has proper title
- [ ] Scrolls if many fields (on small screens)

### Missing Metadata

- [ ] Screenshot: No camera info (correct)
- [ ] Generated image: Minimal metadata (correct)
- [ ] Corrupted EXIF: Still shows basic metadata
- [ ] No metadata at all: Panel doesn't appear (or appears empty)

---

## File Picker Tests

### File Browser

- [ ] Click "Choose from Files" opens picker
- [ ] Can navigate folders
- [ ] Only shows image files
- [ ] Can select PNG
- [ ] Can select JPEG
- [ ] Can select HEIC
- [ ] Cancel closes picker without importing
- [ ] Select + Open imports image
- [ ] Metadata extracts correctly

### Photos Picker

- [ ] Click "Choose from Photos" opens picker
- [ ] Shows Photos library
- [ ] Shows iCloud Photos (if enabled)
- [ ] Can browse albums
- [ ] Can search photos
- [ ] Select photo imports it
- [ ] Cancel closes picker
- [ ] Metadata extracts correctly

---

## Import Workflow Tests

### Complete Flow: Drag & Drop

1. [ ] Start wizard on Map card
2. [ ] Select "Import Image" method
3. [ ] See drop zone
4. [ ] Drag image file over zone
5. [ ] Zone highlights blue
6. [ ] Drop image
7. [ ] Image loads and displays
8. [ ] Metadata panel appears
9. [ ] "Continue" button enables
10. [ ] Click "Continue"
11. [ ] Finalize step shows preview
12. [ ] Click "Save Map to Card"
13. [ ] Card updates with image
14. [ ] Wizard resets to Welcome

### Complete Flow: File Browser

1. [ ] Start wizard
2. [ ] Select "Import Image"
3. [ ] Click "Choose from Files"
4. [ ] File picker opens
5. [ ] Navigate to image
6. [ ] Select and open
7. [ ] Image loads
8. [ ] Metadata appears
9. [ ] Continue → Finalize → Save
10. [ ] Works correctly

### Complete Flow: Photos Picker

1. [ ] Start wizard
2. [ ] Select "Import Image"
3. [ ] Click "Choose from Photos"
4. [ ] Photos picker opens
5. [ ] Select photo
6. [ ] Image loads (async)
7. [ ] Metadata appears
8. [ ] Continue → Finalize → Save
9. [ ] Works correctly

---

## Preview Tests

### macOS Preview

- [ ] NSImage renders correctly
- [ ] Image scales to fit
- [ ] Aspect ratio maintained
- [ ] Rounded corners applied
- [ ] Shadow visible
- [ ] No distortion

### iOS Preview

- [ ] UIImage renders correctly
- [ ] Image scales to fit
- [ ] Aspect ratio maintained
- [ ] Rounded corners applied
- [ ] Shadow visible
- [ ] No distortion

### Preview Quality

- [ ] High-res images look sharp
- [ ] Low-res images don't look worse
- [ ] Colors accurate
- [ ] Transparency handled (if PNG)

---

## State Management Tests

### Image Replacement

- [ ] Import image A
- [ ] Click "Choose Different Image"
- [ ] Import image B
- [ ] Image A is replaced
- [ ] Metadata updates to image B
- [ ] Previous metadata cleared

### Multiple Sessions

- [ ] Import → Save → Wizard resets
- [ ] Start new import
- [ ] Previous image not visible
- [ ] Previous metadata not visible
- [ ] Can import different image
- [ ] No state leakage between sessions

### Navigation

- [ ] Back button works at Configure step
- [ ] Continue button disabled until image loaded
- [ ] Continue button enables after load
- [ ] Back/Continue preserves state within session
- [ ] Back from Finalize shows same preview

---

## Cross-Platform Tests

### macOS Specific

- [ ] Finder drag works
- [ ] Desktop drag works
- [ ] NSImage rendering correct
- [ ] File picker is macOS native
- [ ] Photos picker is macOS native

### iOS Specific

- [ ] Files app drag works
- [ ] Photos app drag works
- [ ] UIImage rendering correct
- [ ] File picker is iOS native
- [ ] Photos picker is iOS native
- [ ] Works in portrait
- [ ] Works in landscape

### iPadOS Specific

- [ ] Split View drag works
- [ ] Slide Over drag works
- [ ] Larger canvas space used well
- [ ] Metadata panel readable
- [ ] Apple Pencil not interfering (not a drawing tool here)

---

## Error Handling Tests

### Corrupted Files

- [ ] Corrupt image file: Fails gracefully
- [ ] Partially downloaded file: Doesn't crash
- [ ] Wrong file extension: Attempts to load anyway

### Permission Issues

- [ ] No Files access: Shows permission prompt
- [ ] No Photos access: Shows permission prompt
- [ ] Access denied: Shows error or instructions

### Memory Issues

- [ ] Very large file (100MB+): May be slow but works
- [ ] Multiple large files in sequence: No memory leak
- [ ] Background memory cleanup on reset

---

## Accessibility Tests

### VoiceOver (if enabled)

- [ ] Drop zone is announced
- [ ] Drag state announced
- [ ] Image preview announced
- [ ] Metadata rows announced
- [ ] Buttons are labeled
- [ ] Navigation is clear

### Keyboard Navigation

- [ ] Tab cycles through buttons
- [ ] Return activates focused button
- [ ] Escape cancels pickers
- [ ] No keyboard traps

### Dynamic Type (if enabled)

- [ ] Text scales appropriately
- [ ] Layout doesn't break
- [ ] Buttons still readable
- [ ] Metadata panel adapts

---

## Performance Tests

### Load Times

- [ ] Small image (<1MB): Instant
- [ ] Medium image (1-5MB): <1 second
- [ ] Large image (5-20MB): <3 seconds
- [ ] Very large (20MB+): Works but may be slow

### Metadata Extraction Times

- [ ] Typical image: <100ms
- [ ] Complex EXIF: <500ms
- [ ] No metadata: <50ms

### UI Responsiveness

- [ ] Drag feedback: Immediate
- [ ] Drop action: <500ms to start loading
- [ ] Preview render: <1 second
- [ ] Metadata display: <100ms after image load

### Memory Usage

- [ ] No leaks after multiple imports
- [ ] Memory released after wizard reset
- [ ] No retention of previous images

---

## Integration Tests

### With Card Model

- [ ] Image saves to Card.originalImageData
- [ ] Thumbnail generated correctly
- [ ] File extension inferred correctly
- [ ] Card persists after save
- [ ] Image visible in card detail view

### With SwiftData

- [ ] modelContext.save() succeeds
- [ ] Changes persist after app restart
- [ ] No duplicate images created
- [ ] Proper cleanup on errors

### With Other Wizard Steps

- [ ] Import → Finalize works
- [ ] Import → Back → Import again works
- [ ] Welcome → Import → Draw (switch methods) works
- [ ] Import doesn't interfere with Drawing phase

---

## Regression Tests (Phase 1.0 Features)

### Original Import Still Works

- [ ] File picker import (original flow)
- [ ] Photos picker import (original flow)
- [ ] Preview display (original)
- [ ] Save to card (original)
- [ ] Wizard navigation (original)

### Drawing Canvas Still Works (Phase 4)

- [ ] Can select "Draw Map"
- [ ] Drawing canvas appears
- [ ] Tools work correctly
- [ ] Save drawing works
- [ ] No interference with import features

---

## Sign-Off

### Test Summary

**Date:** _______________  
**Tester:** _______________  
**Platform:** macOS / iOS / iPadOS (circle one)  
**Device/Simulator:** _______________

### Results

- Total Tests: _____
- Passed: _____
- Failed: _____
- Skipped: _____

### Critical Issues Found

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

### Non-Critical Issues Found

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

### Overall Assessment

- [ ] ✅ Ready for production
- [ ] ⚠️ Ready with minor issues
- [ ] ❌ Not ready (critical issues)

### Notes

_________________________________________________
_________________________________________________
_________________________________________________
_________________________________________________

---

## Quick Smoke Test (5 Minutes)

If you only have 5 minutes, test these critical paths:

### Smoke Test: Drag & Drop
1. [ ] Drag image from Finder/Files
2. [ ] Drop zone highlights
3. [ ] Image loads
4. [ ] Metadata shows
5. [ ] Save to card works

### Smoke Test: File Picker
1. [ ] Click "Choose from Files"
2. [ ] Select image
3. [ ] Preview appears
4. [ ] Metadata appears
5. [ ] Save works

### Smoke Test: Photos Picker
1. [ ] Click "Choose from Photos"
2. [ ] Select photo
3. [ ] Loads correctly
4. [ ] Save works

**If all smoke tests pass:** Probably good to go! ✅  
**If any fail:** Run full test suite above ⚠️

---

**Checklist Version:** 1.5  
**Last Updated:** November 11, 2025  
**Phase:** 1.5 (Drag & Drop + Metadata)
