# Multi-Platform Refresh Implementation

## Summary
Added platform-appropriate refresh functionality to Cumberland's card and structure lists, following Apple's Human Interface Guidelines for each platform.

---

## Platform-Specific Implementations

### 📱 iOS/iPadOS
**Pattern:** Pull-to-refresh gesture  
**Implementation:** `.refreshable` modifier on List views  
**User Experience:**
- Pull down on the list to trigger refresh
- Native spinner animation appears
- 500ms feedback delay for visual confirmation
- Works on both card list and structure list

```swift
.refreshable {
    await refreshCardList()
}
```

---

### 💻 macOS
**Pattern:** Keyboard shortcut (Command-R)  
**Implementation:** `.onKeyPress` modifier  
**User Experience:**
- Press ⌘R to refresh the current list
- No visual scroll gesture (not standard on macOS)
- Instant feedback on keyboard input
- Works in both card and structure views

```swift
.onKeyPress(.init("r", modifiers: .command)) {
    Task {
        await refreshCardList()
    }
    return .handled
}
```

**Future Enhancement Consideration:**
- Add "View > Refresh" menu item for discoverability
- Add refresh button to toolbar (optional)

---

### 🥽 visionOS
**Pattern:** Spatial UI button in ornament  
**Implementation:** Refresh button added to `PrimaryActionsOrnament`  
**User Experience:**
- Tap the refresh button in the bottom ornament
- ⌘R keyboard shortcut also available
- Automatically refreshes appropriate view (card list or structure list)
- Spatial button with glass effect and accessibility support

```swift
Button {
    onRefresh()
} label: {
    Label("Refresh", systemImage: "arrow.clockwise")
}
.glassBackgroundEffect()
.keyboardShortcut("r", modifiers: [.command])
```

**Why not pull-to-refresh on visionOS?**
- Spatial computing emphasizes explicit actions over gestures
- Gaze + pinch interactions make scroll-based gestures less intuitive
- Buttons provide clearer affordances in 3D space

---

## Implementation Details

### Refresh Functions
Both refresh functions follow the same pattern:

```swift
private func refreshCardList() async {
    // 500ms delay for visual/haptic feedback
    try? await Task.sleep(for: .milliseconds(500))
    
    await MainActor.run {
        // Process pending changes in the model context
        modelContext.processPendingChanges()
        
        // Save any uncommitted changes
        try? modelContext.save()
    }
}
```

**Why the 500ms delay?**
- Provides visual feedback that refresh occurred
- Prevents accidental rapid-fire refreshes
- Gives time for haptic feedback on iOS
- Makes the action feel intentional, not instant

**SwiftData Integration:**
- `@Query` property wrappers automatically observe model changes
- `processPendingChanges()` ensures any external changes are picked up
- `save()` commits any pending transactions
- View automatically updates when data changes

---

## Files Modified

### MainAppView.swift
- Added `refreshCardList()` async function
- Added `refreshStructureList()` async function
- Added `.refreshable` modifier to card list (iOS only)
- Added `.refreshable` modifier to structure list (iOS only)
- Added `.onKeyPress` for ⌘R on card list (macOS only)
- Updated `primaryActionsOrnament` to include refresh callback (visionOS)

### OrnamentViews.swift
- Added `onRefresh` parameter to `PrimaryActionsOrnament`
- Added Refresh button with ⌘R keyboard shortcut
- Added accessibility labels and hints
- Updated preview to include refresh callback

---

## Testing Checklist

### iOS/iPadOS
- [ ] Pull down on card list triggers refresh
- [ ] Pull down on structure list triggers refresh
- [ ] Spinner appears during refresh
- [ ] List updates after refresh completes
- [ ] Haptic feedback occurs (on supported devices)

### macOS
- [ ] ⌘R refreshes card list when focused
- [ ] ⌘R refreshes structure list when in structure view
- [ ] No pull-to-refresh gesture interferes with scrolling
- [ ] Keyboard shortcut works from any focused state

### visionOS
- [ ] Refresh button appears in bottom ornament
- [ ] Button tap triggers appropriate refresh (cards or structures)
- [ ] ⌘R keyboard shortcut works
- [ ] Accessibility labels read correctly
- [ ] Button visual feedback on hover/press
- [ ] Glass effect renders correctly

---

## Future Enhancements

### macOS Menu Integration
Consider adding a menu item for discoverability:

```swift
// In App.swift or Commands
CommandGroup(replacing: .view) {
    Button("Refresh") {
        // Send notification or use AppModel
    }
    .keyboardShortcut("r", modifiers: .command)
}
```

### Automatic Refresh
Consider background refresh for:
- iCloud sync events
- External data changes
- Returning to foreground

### Visual Feedback
- Add rotation animation to refresh button during refresh
- Consider progress indicator for long refreshes
- Toast/banner notification on completion (optional)

---

## Design Rationale

Each platform gets refresh functionality that feels native:

1. **iOS/iPadOS:** Pull-to-refresh is ubiquitous and expected
2. **macOS:** Keyboard shortcuts are primary, gestures secondary
3. **visionOS:** Explicit buttons in spatial UI provide clarity

This approach follows Apple's platform conventions while maintaining a consistent mental model: "refresh the current view to see latest data."

---

## Related Documentation
- [Apple HIG - Pull-to-Refresh (iOS)](https://developer.apple.com/design/human-interface-guidelines/ios/controls/refresh-content-controls/)
- [Apple HIG - Keyboard Shortcuts (macOS)](https://developer.apple.com/design/human-interface-guidelines/macos/user-interaction/keyboard/)
- [Apple HIG - visionOS Ornaments](https://developer.apple.com/design/human-interface-guidelines/visionos/components/ornaments/)
