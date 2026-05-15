# Map Wizard Draft Persistence - Bug Fixes

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

**Problem:**
- When restoring drawing drafts, the code called `drawingCanvasModel.importCanvasFromPNG(draftData)`
- That method **clears the canvas** instead of loading the PNG data
- The drawing was saved but never actually restored, leaving users with a blank canvas

**Fix:**
Changed the restoration logic to set the PNG as `importedImageData` instead:

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
        // The canvas remains clear for new drawing on top
        print("[DRAFT] Restored PNG snapshot as background image")
    }
```

**Impact:**
- Drawing work is now properly restored and visible to users
- The PNG displays as a background/reference while the canvas allows new drawing on top
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

## User Experience Improvements

### Before Fixes
1. ❌ "Restore" button did nothing - drawing stayed blank
2. ❌ Switching cards showed old card's drawing on new card
3. ❌ Always returned to configure step, even if saved from finalize
4. ❌ No warning when switching cards with unsaved work

### After Fixes
1. ✅ "Restore" button properly loads saved drawing data
2. ✅ Wizard step is restored exactly where user left off
3. ✅ Switching cards prompts to save work first
4. ✅ Switching cards completely resets wizard state
5. ✅ New card's draft is loaded immediately after switch

---

## Testing Checklist

### Wizard Step Restoration
- [ ] Save draft from configure step → restore → verify returns to configure
- [ ] Save draft from finalize step → restore → verify returns to finalize
- [ ] Old draft without step property → verify defaults to configure

### Drawing Data Restoration
- [ ] Draw on canvas → exit app → reopen → tap restore → verify drawing visible
- [ ] Import image → exit app → reopen → tap restore → verify image visible
- [ ] Capture from Maps → exit app → reopen → tap restore → verify map visible
- [ ] AI generate → exit app → reopen → tap restore → verify prompt and image

### Card Switching
- [ ] Draw on Card A → switch to Card B → verify warning appears
- [ ] Choose "Save & Switch" → verify Card A draft saved, Card B loaded clean
- [ ] Choose "Discard & Switch" → verify Card A draft not saved, Card B loaded
- [ ] Switch to Card B that has draft → verify restore prompt for Card B
- [ ] No drawing on Card A → switch to Card B → verify no warning

### Edge Cases
- [ ] Switch cards in focus mode → verify works correctly
- [ ] Switch cards with auto-save timer running → verify timer stops/restarts
- [ ] Switch cards rapidly → verify no crashes or state corruption
- [ ] Multi-device sync → draw on Mac, switch cards on iPad → verify correct behavior

---

## Technical Notes

### State Management
- `currentCardID` tracks which card the wizard is currently working with
- Card change is detected via `.onChange(of: card.id)`
- All wizard state is reset when switching cards via `resetWizard()`

### Data Flow
1. User draws on canvas for Card A
2. Auto-save writes to `Card A.draftMapWorkData`
3. User switches to Card B via context menu
4. System detects `card.id` change
5. If unsaved work: show save dialog
6. After save/discard: `resetWizard()` called
7. `currentCardID` updated to Card B's ID
8. `checkForDraftWork()` called for Card B
9. If Card B has draft: show restore prompt

### Backward Compatibility
- Old drafts without `draftMapWizardStepRaw` default to `.configure` step
- PNG snapshot format works for both new and legacy drawing data
- Legacy canvas state format (with PencilKit strokes) still supported via `importCanvasState()`

---

## Files Modified

1. **MapWizardView.swift**
   - Fixed `restoreDraftWork()` to restore wizard step
   - Fixed drawing restoration to use `importedImageData` instead of clearing canvas
   - Added `currentCardID` state variable
   - Added `showCardChangeWarning` state variable
   - Added `.onChange(of: card.id)` modifier
   - Added card change warning alert
   - Added `hasUnsavedWork` computed property
   - Added `handleCardChange()` method
   - Enhanced `resetWizard()` to clear drawing canvas and AI state
   - Enhanced `.onAppear` to track initial card ID

2. **Card.swift**
   - No changes needed (already has `draftMapWizardStepRaw` property)

---

## Future Enhancements

1. **Multi-Card Session Management**
   - Remember wizard state for multiple cards simultaneously
   - Quick-switch between card drafts without losing state

2. **Draft Thumbnails**
   - Show thumbnail of draft work in restoration dialog
   - Visual preview in card context menu if draft exists

3. **Undo Card Switch**
   - "Oops, go back to previous card" action
   - Temporarily cache previous card's wizard state

4. **Batch Operations**
   - "Save all open drafts" action
   - Warn if closing app with multiple cards having unsaved work
