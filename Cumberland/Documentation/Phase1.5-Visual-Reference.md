# Phase 1.5: Visual Reference Guide

## UI States

### State 1: Empty Drop Zone (Default)

```
┌─────────────────────────────────────────────┐
│                                             │
│                                             │
│               📷 (gray icon)                │
│                                             │
│         Drag & drop image here              │
│                                             │
│                    or                       │
│                                             │
│   [📁 Choose from Files] [📸 Photos]       │
│                                             │
│                                             │
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
   Dashed gray border (inactive)
```

### State 2: Drag Over (Targeted)

```
┌═════════════════════════════════════════════┐
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░   📷 (blue fill)   ░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░ Drop image here ░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
└═════════════════════════════════════════════┘
   Blue border (solid), Blue background tint
```

### State 3: Image Loaded with Metadata

```
┌─────────────────────────────────────────────┐
│  ┌─────────────────────────────────────┐   │
│  │                                     │   │
│  │                                     │   │
│  │         [IMAGE PREVIEW]             │   │
│  │                                     │   │
│  │                                     │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─ Image Information ─────────────────┐   │
│  │ 📐 Dimensions    1920 × 1080         │   │
│  │ 📄 File Size     2.4 MB              │   │
│  │ 🖼️  Format        PNG                 │   │
│  │ 📏 Resolution    300 DPI             │   │
│  │ 📷 Camera        iPhone 15 Pro       │   │
│  │ 📍 GPS location data available       │   │
│  └──────────────────────────────────────┘   │
│                                             │
│        [Choose Different Image]             │
└─────────────────────────────────────────────┘
```

---

## Metadata Display Variations

### Minimal Metadata (PNG without EXIF)

```
┌─ Image Information ──────────┐
│ 📐 Dimensions    800 × 600    │
│ 📄 File Size     1.2 MB       │
│ 🖼️  Format        PNG          │
└───────────────────────────────┘
```

### Full Metadata (JPEG from Camera)

```
┌─ Image Information ────────────────┐
│ 📐 Dimensions    4032 × 3024        │
│ 📄 File Size     5.8 MB             │
│ 🖼️  Format        JPEG               │
│ 📏 Resolution    72 DPI             │
│ 📷 Camera        Canon EOS R5       │
│ 📍 GPS location data available      │
└─────────────────────────────────────┘
```

### Screenshot (No Camera Data)

```
┌─ Image Information ────────────────┐
│ 📐 Dimensions    2560 × 1440        │
│ 📄 File Size     892 KB             │
│ 🖼️  Format        PNG                │
│ 📏 Resolution    144 DPI            │
└─────────────────────────────────────┘
```

---

## Animation Sequence

### Drag Enter Animation

```
Frame 1 (0ms):
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│   📷 (gray)          │
│   Drag & drop...     │
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

Frame 2 (100ms):
┌─────────────────────┐
│ ░ 📷 (blue starting) │
│ ░ Drop image...      │
└─────────────────────┘

Frame 3 (200ms):
┌═════════════════════┐
│ ░░ 📷 (blue fill)    │
│ ░░ Drop image here   │
└═════════════════════┘
```

### Drag Exit Animation

```
Frame 1 (0ms):
┌═════════════════════┐
│ ░░ 📷 (blue fill)    │
│ ░░ Drop image here   │
└═════════════════════┘

Frame 2 (100ms):
┌─────────────────────┐
│ ░ 📷 (fading)        │
│ ░ Drag & drop...     │
└─────────────────────┘

Frame 3 (200ms):
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│   📷 (gray)          │
│   Drag & drop...     │
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

---

## Interaction Flows

### Flow 1: Drag & Drop Success

```
User drags image file over wizard
              ↓
    isDragTargeted = true
              ↓
    Border: gray → blue
    Icon: outlined → filled
    Text: "Drag..." → "Drop..."
    Background: clear → blue tint
              ↓
        User drops image
              ↓
    handleDrop() called
              ↓
    loadImage(data:) executed
              ↓
    importedImageData = data
    imageMetadata = extract()
              ↓
    View updates to preview state
              ↓
    Shows image + metadata panel
              ↓
    "Continue" button enabled
```

### Flow 2: Drag & Drop Cancel

```
User drags image file over wizard
              ↓
    isDragTargeted = true
    (visual feedback)
              ↓
    User drags away (exit)
              ↓
    isDragTargeted = false
              ↓
    Border: blue → gray
    Background: tint → clear
    Icon: filled → outlined
    Text: "Drop..." → "Drag..."
              ↓
    Back to default state
```

### Flow 3: File Picker Import

```
User clicks "Choose from Files"
              ↓
    isImportingImage = true
              ↓
    File browser appears
              ↓
    User navigates & selects image
              ↓
    result = .success(url)
              ↓
    loadImage(from: url) called
              ↓
    Same as drag & drop from here...
```

---

## Metadata Row Component

### Structure

```
┌──────────────────────────────────┐
│ [Icon] [Label      ] [Value]     │
│  20px   80px fixed   flexible    │
└──────────────────────────────────┘
```

### Examples

```
📐 Dimensions    1920 × 1080
│  │            │
│  │            └─ Value (.bold, .caption)
│  └─ Label (.secondary, .caption)
└─ Icon (.blue, SF Symbol)
```

```
📷 Camera        iPhone 15 Pro
│  │            │
│  │            └─ Device name
│  └─ "Camera"
└─ camera.fill icon
```

```
📍 GPS location data available
│  │
│  └─ Info text (no label/value split)
└─ location.fill icon
```

---

## Color Palette

### Default State
- **Border**: `Color.secondary.opacity(0.3)` (light gray dashed)
- **Icon**: `Color.secondary` (gray)
- **Text**: `Color.secondary` (gray)
- **Background**: `Color.clear`

### Targeted State
- **Border**: `Color.blue` (solid)
- **Icon**: `Color.blue` (filled variant)
- **Text**: `Color.blue`
- **Background**: `Color.blue.opacity(0.1)` (subtle tint)

### Metadata Display
- **Icons**: `Color.blue`
- **Labels**: `Color.secondary` (.caption)
- **Values**: `Color.primary` (.bold, .caption)
- **GroupBox**: Default material

---

## Typography

### Drop Zone
- **Title** (targeted): `.headline` + `.blue`
- **Title** (default): `.headline` + `.secondary`
- **"or" text**: `.caption` + `.tertiary`

### Metadata Panel
- **Panel Title**: `.headline`
- **Labels**: `.caption` + `.secondary`
- **Values**: `.caption` + `.bold`
- **GPS text**: `.caption` + `.secondary`

### Buttons
- **Button Text**: `.body` (system default)
- **Save Button**: `.headline`

---

## Layout Specifications

### Drop Zone
- **Width**: `maxWidth: .infinity`
- **Height**: `300pt`
- **Padding**: System default (varies by platform)
- **Corner Radius**: `12pt`
- **Border Dash**: `[8, 4]` pattern

### Image Preview
- **Max Height**: `400pt`
- **Scaling**: `.scaledToFit`
- **Corner Radius**: `12pt`
- **Shadow**: `radius: 5`

### Metadata Panel
- **GroupBox**: System default
- **Row Spacing**: `12pt`
- **Icon Width**: `20pt`
- **Label Width**: `80pt` (fixed)
- **Value Width**: Flexible

---

## Platform Differences

### macOS
```
Drop Zone:
- Large hover area
- Precise mouse targeting
- Drag from Finder shows file icon
- Quick Look preview available (external)

Preview:
- NSImage rendering
- Native image quality
- Color management
```

### iOS/iPadOS
```
Drop Zone:
- Touch-optimized sizing
- Drag from Files app
- Drag from Photos app
- Split View drag support

Preview:
- UIImage rendering
- Retina display handling
- HDR support (if available)
```

---

## Accessibility

### VoiceOver Labels
- Drop Zone: "Drag and drop image here, or choose from files or photos"
- Targeted: "Drop zone active, release to import image"
- Preview: "Imported map image, {dimensions}, {file size}"
- Metadata: Each row announces "{label}: {value}"

### Dynamic Type
- All text scales with system font size
- Metadata rows reflow if needed
- Buttons expand to fit text

### Keyboard Navigation
- Tab through buttons
- Space/Return to activate
- Escape to cancel file picker

---

## Error States (Future Enhancement)

### Potential Error Scenarios

```
┌─────────────────────────────────────────────┐
│              ⚠️                              │
│                                             │
│      Unable to load image                   │
│                                             │
│  The file may be corrupted or in an        │
│  unsupported format.                        │
│                                             │
│          [Try Another Image]                │
└─────────────────────────────────────────────┘
```

```
┌─────────────────────────────────────────────┐
│              ⚠️                              │
│                                             │
│      Image too large                        │
│                                             │
│  Maximum file size is 50 MB.                │
│  This image is 87 MB.                       │
│                                             │
│          [Choose Different]                 │
└─────────────────────────────────────────────┘
```

*Note: Error states not yet implemented, currently fails silently*

---

## Testing Checklist

### Visual Verification
- [ ] Drop zone has dashed border by default
- [ ] Border becomes solid blue on drag over
- [ ] Icon changes from outlined to filled
- [ ] Background gets blue tint when targeted
- [ ] Animation is smooth (200ms)
- [ ] Preview image displays correctly
- [ ] Metadata panel appears below image
- [ ] All metadata fields align properly
- [ ] Icons are correct color (blue)
- [ ] Text is correct size/weight

### Interaction Verification
- [ ] Drag enter triggers visual change
- [ ] Drag exit reverts visual change
- [ ] Drop imports image
- [ ] File picker button works
- [ ] Photos picker button works
- [ ] "Choose Different" replaces image
- [ ] Metadata updates on new image

### Cross-Platform Verification
- [ ] macOS: Drag from Finder works
- [ ] iOS: Drag from Files works
- [ ] iPadOS: Drag from Split View works
- [ ] All platforms: Preview renders
- [ ] All platforms: Metadata displays

---

## Design Philosophy

### Principles Applied

1. **Visual Feedback**
   - Immediate response to user actions
   - Clear affordances (dashed border = drop zone)
   - Animation reinforces interaction

2. **Progressive Disclosure**
   - Metadata hidden until relevant
   - Only shows fields that exist
   - GPS indicator, not raw coordinates

3. **Multi-Path Access**
   - Drag & drop for efficiency
   - Buttons for discoverability
   - Equal functionality, different preferences

4. **Information Hierarchy**
   - Image preview largest (most important)
   - Metadata secondary (reference)
   - Actions tertiary (buttons)

5. **Graceful Degradation**
   - Missing metadata fields = don't show
   - Failed extraction = empty panel
   - Unsupported format = try anyway

---

**Reference Version:** Phase 1.5  
**Last Updated:** November 11, 2025
