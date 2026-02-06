# Full-Size Image Gesture Guide

## How to View Full-Size Images

### On iPhone/iPad
```
┌─────────────────────────┐
│   Card Thumbnail        │
│   [Photo Image]         │
│                         │
│   👆 Long Press (0.5s)  │
│   or                    │
│   👆👆 Double Tap       │
│                         │
└─────────────────────────┘
```

### On Mac
```
┌─────────────────────────┐
│   Card Thumbnail        │
│   [Photo Image]         │
│                         │
│   🖱️🖱️ Double Click     │
│   or                    │
│   🖱️➜ Right Click Menu  │
│                         │
└─────────────────────────┘
```

### On visionOS
```
┌─────────────────────────┐
│   Card Thumbnail        │
│   [Photo Image]         │
│                         │
│   👀 Long Look          │
│   or                    │
│   👆 Spatial Gesture    │
│                         │
└─────────────────────────┘
```

## Full-Size Viewer Controls

### Zoom & Pan
```
┌───────────────────────────────────┐
│                                   │
│      🖼️ Full Size Image           │
│                                   │
│  🤏 Pinch: Zoom 1x - 5x          │
│  ☝️ Drag: Pan (when zoomed)      │
│  👆👆 Double-tap: Toggle 1x/2x   │
│  👆 Single tap: Dismiss          │
│                                   │
│                          [✕ Close]│
└───────────────────────────────────┘
```

## Context Menu Option (All Platforms)
```
Right-click/Long press on thumbnail:
┌──────────────────────────┐
│ ↗️ View Full Size        │
│ ────────────────────────  │
│ 🖼️ Choose Image…         │
│ 🗑️ Remove Image          │
└──────────────────────────┘
```

## Where It Works

✅ **CardView** - Main card display in lists/boards
✅ **CardEditorView** - While editing a card
✅ **ImageAttributionViewer** - In details panel with attribution

## Quick Tips

1. **Fast access:** Double-tap/click is fastest
2. **Explore details:** Pinch to zoom up to 5x
3. **Compare regions:** Pan around when zoomed
4. **Quick dismiss:** Single tap anywhere to close
5. **Keyboard users:** Press Esc to close viewer

## Visual Feedback

### While Viewing
- Black background eliminates distractions
- Image scales smoothly with gestures
- Close button stays accessible in top-right
- Works in both portrait and landscape

### Zoom States
- **1x (default):** Image fits screen
- **2x:** Quick zoom via double-tap
- **Custom:** Pinch for any scale 1x-5x
- **Reset:** Double-tap when zoomed returns to 1x

## Platform Integration

| Platform | Primary Gesture | Alternative | Context Menu |
|----------|----------------|-------------|--------------|
| iPhone   | Long Press     | Double Tap  | ✓            |
| iPad     | Long Press     | Double Tap  | ✓            |
| Mac      | Double Click   | —           | ✓            |
| visionOS | Long Look      | —           | ✓            |

## Accessibility

- **VoiceOver:** Announces "Card image, double tap to view full size"
- **Keyboard:** Esc key closes viewer
- **Switch Control:** All actions accessible
- **Voice Control:** "Show full size" supported via context menu
