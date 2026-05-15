# Map Wizard Draft Persistence Enhancement

## Overview
Enhanced the Map Wizard to remember the exact wizard step and configuration when a writer exits the app, and added warnings when navigating back would discard unsaved work.

## Changes Made

### 1. Card Model Updates (`Card.swift`)

#### New Property
- Added `draftMapWizardStepRaw: String?` to persist which wizard step the user was on

#### Updated Methods
- `saveDraftMapWork(_:method:wizardStep:)` - Now accepts optional `wizardStep` parameter
- `clearDraftMapWork()` - Now also clears the wizard step

### 2. MapWizardView Updates (`MapWizardView.swift`)

#### New State Variables
```swift
@State private var showBackWarning = false
@State private var pendingNavigationStep: WizardStep?
```

#### Enhanced Draft Restoration
The `restoreDraftWork()` method now:
1. Restores the selected creation method (existing)
2. **NEW:** Restores the wizard step where the user left off
3. Restores method-specific data (existing)
4. Defaults to `.configure` step if no step was saved (backward compatibility)

```swift
// Restore wizard step if saved
if let stepRaw = card.draftMapWizardStepRaw,
   let step = WizardStep(rawValue: stepRaw) {
    currentStep = step
} else {
    currentStep = .configure
}
```

#### Back Navigation Warning System

**New Logic:**
- `wouldLoseWorkByGoingBack` - Computed property that checks if there's unsaved work
- `handleBackButtonTapped()` - Shows warning dialog if work would be lost
- `performBackNavigation()` - Actually performs navigation and clears draft work

**Warning Conditions:**
The warning appears when navigating back from the configure step if:
- **Import Image:** An image has been selected
- **Draw/Interior:** The canvas has drawing data
- **Capture from Maps:** A map snapshot has been captured
- **AI Generate:** A prompt has been entered or image generated

**Warning Dialog:**
```
Title: "Discard Unsaved Work?"
Message: "Going back will discard your unsaved map work. This cannot be undone."
Buttons: 
  - "Keep Editing" (cancel)
  - "Discard" (destructive, proceeds with navigation)
```

#### Auto-Save Enhancements

**Trigger Points:**
1. **Drawing changes** - Via `onChange(of: drawingCanvasModel.drawing)`
2. **Timer** - Every 30 seconds while in configure step
3. **Focus mode** - When entering or exiting focus mode
4. **App background** (iOS only) - Via `willResignActiveNotification`
5. **Step navigation** - When moving forward to next step

**What Gets Saved:**
- Drawing/canvas state for draw/interior methods
- Image data for import/capture methods
- Prompt + image for AI generation
- **NEW:** Current wizard step (`currentStep.rawValue`)

### 3. User Experience Flow

#### First Time (No Draft)
1. User opens wizard → Starts at welcome step
2. User selects method and begins work
3. Auto-save kicks in after first change
4. Draft saved with method + step

#### Returning with Draft
1. User opens wizard → Sees restoration prompt
2. If "Restore" → Returns to exact step they were on
3. If "Start Fresh" → Draft cleared, starts at welcome
4. If "Cancel" → Dialog dismissed

#### Navigating Back with Work
1. User taps "Back" button while in configure step
2. If no meaningful work → Goes back immediately
3. If unsaved work exists → Warning dialog appears
4. If "Discard" → Draft cleared, navigation proceeds
5. If "Keep Editing" → Stays on current step

#### Exiting App Mid-Work
1. User draws on canvas
2. App auto-saves every 30 seconds
3. User switches to another app (iOS) → Draft saved
4. User quits app → Last auto-save persists
5. User returns later → Restoration prompt appears
6. Draft includes exact step (e.g., "Configure") and method (e.g., "Draw Map")

### 4. CloudKit Sync Benefits

Since all draft properties are synced via CloudKit:
- Writer starts map on Mac → exits app
- Writer opens app on iPad → sees restoration prompt
- Work continues seamlessly across devices
- Wizard step is restored correctly on all devices

### 5. Edge Cases Handled

✅ **No step saved (old data)** → Defaults to configure step  
✅ **Invalid step raw value** → Falls back to configure step  
✅ **Welcome/SelectMethod steps** → No back warning (no work to lose)  
✅ **Finalize step** → Back button available, but no warning (work already validated)  
✅ **Focus mode transitions** → Draft saved automatically  
✅ **Empty canvas** → No warning when going back  

### 6. Technical Implementation Notes

**Persistence Strategy:**
- Uses `WizardStep.rawValue` (String) for CloudKit compatibility
- Stored in `draftMapWizardStepRaw` property on Card
- Enum ensures type safety in app code
- Raw values enable backward/forward compatibility

**State Management:**
- `showBackWarning` controls alert visibility
- `wouldLoseWorkByGoingBack` computed property prevents redundant logic
- `performBackNavigation()` centralizes the actual navigation + cleanup

**Auto-Save Optimization:**
- Only saves when in configure or finalize steps
- Checks for non-empty data before writing
- Uses async/await to avoid blocking UI
- Timer-based saves supplement change-based saves

## Testing Checklist

- [ ] Start drawing → exit app → reopen → verify restore prompt shows correct age
- [ ] Restore draft → verify correct wizard step is restored
- [ ] Restore draft → verify method is selected correctly
- [ ] Restore draft → verify canvas/image data is intact
- [ ] Tap back from configure with drawing → verify warning appears
- [ ] Tap back from configure with no work → verify no warning
- [ ] Choose "Discard" → verify draft is cleared from database
- [ ] Choose "Keep Editing" → verify stays on same step
- [ ] Enter focus mode → exit app → reopen → verify draft persisted
- [ ] Test on multiple devices with CloudKit → verify sync works
- [ ] Old draft without step property → verify defaults to configure
- [ ] Save final map → verify draft is cleared
- [ ] Navigate forward through steps → verify auto-save triggers

## Future Enhancements

Potential improvements for future iterations:

1. **Step Preview in Restoration Dialog**
   - Show which step the draft is from
   - Example: "You were at: Configure → Draw Map"

2. **Multiple Draft Versions**
   - Keep last N auto-saves
   - Allow "undo" to previous save state

3. **Draft Expiry**
   - Auto-delete drafts older than X days
   - Warn user about stale drafts

4. **Progress Indicator**
   - Show save status ("Saving...", "Saved", "Error")
   - Visual feedback for auto-save

5. **Conflict Resolution**
   - Handle simultaneous editing on multiple devices
   - Prompt user to choose version if conflict detected
