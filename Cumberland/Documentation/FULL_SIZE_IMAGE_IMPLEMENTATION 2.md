# Full-Size Image Viewer Implementation

## Overview
This implementation adds platform-appropriate gestures to view high-resolution card images across the app in `CardView`, `CardEditorView`, and `ImageAttributionViewer`.

## Files Created/Modified

### New Files
- **FullSizeImageViewer.swift** - Full-screen image viewer with zoom, pan, and dismiss gestures

### Modified Files
- **CardView.swift** - Added `.fullSizeImageGesture(for: card)` to thumbnail
- **CardEditorView.swift** - Added gesture support and context menu option for full-size viewing
- **ImageAttributionViewer.swift** - Added thumbnail display with full-size gesture support

## Platform-Specific Gestures

### iOS/iPadOS
- **Primary:** Long press (0.5 seconds) on thumbnail
- **Alternative:** Double-tap on thumbnail
- **Universal:** "View Full Size" in context menu

### macOS
- **Primary:** Double-click on thumbnail
- **Alternative:** Right-click → "View Full Size"

### visionOS
- **Primary:** Long look (extended gaze) - inherited from long press gesture
- **Alternative:** Context menu via spatial gesture

## Features

### FullSizeImageViewer
- **Full-screen black background** for optimal viewing
- **Pinch-to-zoom** (1x to 5x scale)
- **Pan gesture** when zoomed in
- **Double-tap to toggle** between fit and 2x zoom
- **Single tap to dismiss**
- **Close button** with keyboard shortcut (Esc)
- **Loads high-resolution image** from `card.imageFileURL` or `card.originalImageData`

### Integration Points

#### CardView
```swift
thumbnail
    .resizable()
    .scaledToFit()
    .fullSizeImageGesture(for: card)
```

#### CardEditorView
- Gesture support on thumbnail during editing
- Context menu option added when image exists
- State management for full-screen presentation

#### ImageAttributionViewer
- Now displays a 120pt thumbnail of the card image
- Thumbnail supports full-size gesture
- Context menu with "View Full Size" option
- Graceful fallback when no image exists

## User Experience

### Discovery
1. **Long press** is the iOS standard for "peek" actions (familiar from Haptic Touch)
2. **Context menu** makes the feature discoverable for all users
3. **Double-tap/click** provides quick access for power users

### Image Quality Priority
1. Attempts to load from `imageFileURL` (local cache, best quality)
2. Falls back to `originalImageData` (synced original)
3. Gracefully handles missing images with error message

### Zoom & Pan Behavior
- **Single-finger pan** moves image when zoomed
- **Pinch gesture** smoothly scales between 1x and 5x
- **Double-tap** toggles between fit-to-screen and 2x zoom
- **Reset on dismiss** ensures consistent starting state

## Accessibility
- All gestures include keyboard alternatives
- Close button labeled with "Close (Esc)" hint
- Image loading states handled gracefully
- Works with VoiceOver and full keyboard navigation

## Technical Notes

### Performance
- Loads full-resolution images on-demand
- Uses efficient `CGImage` decoding from Card model
- Minimal state management for smooth interactions

### Memory Management
- Image viewer dismissed on single tap or close button
- `fullScreenCover` ensures proper lifecycle management
- State resets between presentations

### Platform Adaptations
- macOS: Minimum window size (600x400)
- iOS: Status bar hidden for immersive viewing
- visionOS: Spatial gestures work naturally

## Testing Recommendations

1. **Test gestures on each platform:**
   - iOS: Long press and double-tap
   - macOS: Double-click and context menu
   - visionOS: Long look and spatial interactions

2. **Test with various image states:**
   - Cards with only thumbnailData
   - Cards with originalImageData
   - Cards with imageFileURL
   - Cards with no image

3. **Test zoom interactions:**
   - Pinch to zoom smoothness
   - Pan gesture at different zoom levels
   - Double-tap toggle behavior
   - Reset on dismiss

4. **Test accessibility:**
   - VoiceOver navigation
   - Keyboard-only navigation (Esc to close)
   - Dynamic Type support

## Future Enhancements

Potential improvements for future iterations:
- Share button for exporting image
- Image metadata overlay (EXIF info)
- Rotation gesture support
- Multi-touch gestures on iPad
- Gallery mode for cards with multiple images
- Thumbnail strip for quick navigation
