# Map Wizard Draft Persistence - Bug Fixes (v2)

## Issues Identified and Fixed

### 1. ❌ **Wizard Step Not Being Restored**

**Problem:**
- The documentation claimed the wizard step was being restored from `draftMapWizardStepRaw`
- The actual code in `restoreDraftWork()` was hardcoded to always restore to `.configure` step
- The saved wizard step in the database was being completely ignored

**Fix:**
Added the missing wizard step restoration logic:

```swift
// Restore wizard step if saved, otherwise default to configure
if let stepRaw = card.draftMapWizardStepRaw,
   let step = WizardStep(rawValue: stepRaw) {
    currentStep = step
    print("[DRAFT] Restored wizard to step: \(step.rawValue)")
} else {
    // Default to configure step for backward compatibility
    currentStep = .configure
    print("[DRAFT] No saved step, defaulting to configure")
}
```

**Impact:**
- Users will now return to the exact step they were on (welcome, selectMethod, configure, or finalize)
- Backward compatible with existing drafts that don't have a saved step

---

### 2. ❌ **Drawing Canvas Data Not Being Restored** 

**Problem #1: Restoration Logic**
- When restoring drawing drafts, the code called `drawingCanvasModel.importCanvasFromPNG(draftData)`
- That method **clears the canvas** instead of loading the PNG data
- The drawing was saved but never actually restored, leaving users with a blank canvas

**Problem #2: No Display Layer**
- Even after fixing the restoration to set `importedImageData`, the drawing canvas view had no support for displaying background images
- The `drawConfigView` and `interiorConfigView` only showed `DrawingCanvasView` without any background layer
- The restored PNG had nowhere to be displayed

**Fix Part 1 - Restoration:**
Changed the restoration logic to set the PNG as `importedImageData`:

```swift
case .draw, .interior:
    // For drawing methods, restore the PNG snapshot
    importedImageData = draftData
    
    // Try to restore as legacy canvas state format for backward compatibility
    do {
        try drawingCanvasModel.importCanvasState(draftData)
        print("[DRAFT] Restored legacy canvas state format")
    } catch {
        // PNG format - set as imported image so it displays in the wizard
        print("[DRAFT] Restored PNG snapshot as background image")
    }
```

**Fix Part 2 - Display Layer:**
Modified both `drawConfigView` and `interiorConfigView` to show the restored draft as a background:

```swift
// Drawing canvas with optional background image from restored draft
ZStack {
    // Show restored draft image as background if available
    if let data = importedImageData {
        #if os(macOS)
        if let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .opacity(0.7) // Make it transparent so user knows they can draw over it
        }
        #else
        if let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .opacity(0.7)
        }
        #endif
    }
    
    // Drawing canvas on top
    DrawingCanvasView(canvasState: $drawingCanvasModel)
}
```

**Additional Features:**
- Green "Draft Restored" indicator badge in header when draft is loaded
- Option to clear draft background via "Clear Draft Background" button in canvas options menu
- 70% opacity on background image makes it clear this is a reference layer users can draw over

**Impact:**
- Drawing work is now properly restored and visible to users
- Users can see their previous work and draw on top of it
- Clear visual feedback that a draft was restored
- Option to remove the background if not needed
- Legacy canvas state format (with drawing strokes) still supported for old drafts

---

### 3. ❌ **Card Switching Keeps Old Drawing Data**

**Problem:**
- When switching to a different card via context menu, the wizard kept the old card's drawing on screen
- No warning was shown about losing unsaved work
- The wizard state was never reset for the new card

**Fix:**
Added comprehensive card change detection:

1. **Track current card ID:**
```swift
@State private var currentCardID: UUID?
```

2. **Detect card changes:**
```swift
.onChange(of: card.id) { oldID, newID in
    guard oldID != newID else { return }
    
    if hasUnsavedWork {
        showCardChangeWarning = true
    } else {
        handleCardChange()
    }
}
```

3. **Show warning if there's unsaved work:**
```swift
.alert("Save Current Work?", isPresented: $showCardChangeWarning) {
    Button("Save & Switch", role: .cancel) {
        Task {
            await autoSaveDraftWork()
            handleCardChange()
        }
    }
    Button("Discard & Switch", role: .destructive) {
        handleCardChange()
    }
} message: {
    Text("You have unsaved work on the current map. Would you like to save it before switching to another card?")
}
```

4. **Handle the card change:**
```swift
private func handleCardChange() {
    // Reset wizard completely
    resetWizard()
    
    // Update card ID
    currentCardID = card.id
    
    // Check if new card has draft work
    checkForDraftWork()
}
```

5. **Enhanced resetWizard() to clear all state:**
```swift
private func resetWizard() {
    currentStep = .welcome
    selectedMethod = nil
    importedImageData = nil
    imageMetadata = nil
    
    // NEW: Reset drawing canvas
    drawingCanvasModel = DrawingCanvasModel()
    
    // NEW: Reset AI generation
    generationPrompt = ""
    generationError = nil
    
    // Reset map state...
    // Exit focus mode...
    // Stop auto-save timer...
}
```

**Impact:**
- Users are warned before switching cards if they have unsaved work
- Option to save current work before switching
- Wizard completely resets for the new card
- New card's draft is properly loaded (if it has one)
- No more ghost drawings from previous cards

---

## Root Cause Analysis

The core issue was that **the draft system was saving correctly but not restoring correctly**:

1. **Auto-save works:** Draft data (4.4 MB in your case) was being saved to the database
2. **Detection works:** The app correctly detected draft data exists and prompted to restore
3. **Restoration broken:** The restoration code set variables but the UI had no way to display them

The problem was a **disconnect between the data layer and the UI layer**:
- Data restoration set `importedImageData` ✅
- Drawing views didn't check `importedImageData` ❌
- Result: Data restored but invisible to user

---

## User Experience Improvements

### Before Fixes
1. ❌ "Restore" button did nothing - drawing stayed blank (but data was saved!)
2. ❌ Switching cards showed old card's drawing on new card
3. ❌ Always returned to configure step, even if saved from finalize
4. ❌ No warning when switching cards with unsaved work
5. ❌ No visual feedback that draft was restored

### After Fixes
1. ✅ "Restore" button properly loads saved drawing with visual indicator
2. ✅ Wizard step is restored exactly where user left off
3. ✅ Switching cards prompts to save work first
4. ✅ Switching cards completely resets wizard state
5. ✅ New card's draft is loaded immediately after switch
6. ✅ "Draft Restored" badge shows when draft is active
7. ✅ Option to clear restored draft background
8. ✅ 70% opacity makes reference layer purpose clear

---

## Testing Checklist

### Wizard Step Restoration
- [ ] Save draft from configure step → restore → verify returns to configure ✨
- [ ] Save draft from finalize step → restore → verify returns to finalize ✨
- [ ] Old draft without step property → verify defaults to configure

### Drawing Data Restoration  
- [ ] Draw on canvas → exit app → reopen → tap restore → **verify drawing visible** ✨✨✨
- [ ] Verify "Draft Restored" badge appears ✨
- [ ] Verify can draw on top of restored image ✨
- [ ] Verify can clear draft background via menu ✨
- [ ] Import image → exit app → reopen → tap restore → verify image visible
- [ ] Capture from Maps → exit app → reopen → tap restore → verify map visible
- [ ] AI generate → exit app → reopen → tap restore → verify prompt and image

### Card Switching
- [ ] Draw on Card A → switch to Card B → verify warning appears ✨
- [ ] Choose "Save & Switch" → verify Card A draft saved, Card B loaded clean ✨
- [ ] Choose "Discard & Switch" → verify Card A draft not saved, Card B loaded ✨
- [ ] Switch to Card B that has draft → verify restore prompt for Card B ✨
- [ ] No drawing on Card A → switch to Card B → verify no warning ✨

### Edge Cases
- [ ] Switch cards in focus mode → verify works correctly
- [ ] Switch cards with auto-save timer running → verify timer stops/restarts
- [ ] Switch cards rapidly → verify no crashes or state corruption
- [ ] Multi-device sync → draw on Mac, switch cards on iPad → verify correct behavior
- [ ] Very large drawings (4+ MB) → verify performance is acceptable

---

## Technical Implementation Summary

### Files Modified

1. **MapWizardView.swift**
   - Fixed `restoreDraftWork()` to restore wizard step
   - Fixed drawing restoration to use `importedImageData` 
   - Added card change detection with `currentCardID` tracking
   - Added `.onChange(of: card.id)` modifier
   - Added card change warning alert
   - Enhanced `resetWizard()` to clear all state
   - Modified `drawConfigView` to show background layer
   - Modified `interiorConfigView` to show background layer
   - Added "Draft Restored" indicator badges
   - Added "Clear Draft Background" menu options

2. **Card.swift**
   - No changes needed (already has all required properties)

### Key Architectural Decisions

1. **Background Layer Approach**
   - Use `ZStack` to layer background image under drawing canvas
   - 70% opacity on background makes layering obvious to users
   - Allows drawing new content on top of restored work
   - Preserved PencilKit's native drawing capabilities

2. **Card Change Detection**
   - Use `.onChange(of: card.id)` for reactive detection
   - Store `currentCardID` to track current state
   - Full wizard reset ensures clean slate for new card
   - Immediate draft check after switch maintains continuity

3. **Visual Feedback**
   - Green badge signals "something was restored"
   - Opacity clearly differentiates background from active canvas
   - Menu option provides escape hatch if draft unwanted
   - Consistent with iOS/macOS design patterns

---

## Performance Considerations

- Large PNG files (4+ MB) load synchronously on main thread
- Consider async image loading for very large drafts
- `ZStack` with large images may impact scrolling performance
- Canvas export/import happens on main thread during auto-save

**Recommendations for future optimization:**
- Move PNG export to background thread
- Cache decoded images to avoid repeated decoding
- Show loading indicator for large draft restorations
- Consider downscaling very large draft PNGs for display (keep full resolution for save)

---

## Backward Compatibility

✅ **Old drafts without wizard step** → Default to configure  
✅ **Legacy canvas state format** → Still supported via `importCanvasState()`  
✅ **Existing PNG snapshots** → Display correctly as background  
✅ **Cards without drafts** → No changes to behavior  
✅ **CloudKit sync** → All properties already sync correctly  

---

## Future Enhancements

1. **Multi-Card Session Management**
   - Remember wizard state for multiple cards simultaneously
   - Quick-switch between card drafts without losing state

2. **Draft Thumbnails**
   - Show thumbnail of draft work in restoration dialog
   - Visual preview in card context menu if draft exists

3. **Async Image Loading**
   - Load large draft images asynchronously
   - Show progress indicator during load

4. **Drawing Merge Options**
   - "Continue drawing" (current behavior - background layer)
   - "Replace draft" (clear and start fresh)
   - "Merge layers" (flatten background into canvas)

5. **Draft History**
   - Keep last N auto-saves
   - Allow "undo to previous draft" functionality
   - Show draft timestamps in restoration UI

6. **Batch Operations**
   - "Save all open drafts" action
   - Warn if closing app with multiple cards having unsaved work
   - Draft management panel to view/delete old drafts
