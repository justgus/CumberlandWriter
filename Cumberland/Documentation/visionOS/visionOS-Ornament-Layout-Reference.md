# visionOS Ornament Layout Reference

**Visual guide to Cumberland's visionOS ornament placement and appearance**

---

## Window Layout Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Cumberland Window                                │
│  ┌───────────────┬─────────────────┬────────────────────────────┐  │
│  │               │                 │                            │  │
│  │   SIDEBAR     │  CONTENT LIST   │      DETAIL VIEW           │  │
│  │               │                 │                            │  │
│  │  - Structure  │  [Card 1]       │  ┌──────────────────────┐  │  │
│  │  - All Cards  │  [Card 2]       │  │                      │  │  │
│  │  - Projects   │  [Card 3]       │  │   Card details...    │  │  │
│  │  - Worlds     │  [Card 4]       │  │                      │  │  │
│  │  - Characters │  [Card 5]       │  │                      │  │  │
│  │  - Scenes     │  ...            │  │                      │  │  │
│  │  - ...        │                 │  │                      │  │  │
│  │               │                 │  └──────────────────────┘  │  │
│  └───────────────┴─────────────────┴────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

        ORNAMENTS (Floating UI Elements):
        
        ┌────────────────────────────────┐
        │  ⊕ New Card  ✎ Edit  🛠 Debug │  ← Bottom ornament (PRIMARY ACTIONS)
        └────────────────────────────────┘
                (centered at bottom)

                                        ┌──────────┐
                                        │  ⚙️ Settings│  ← Trailing ornament (SETTINGS)
                                        └──────────┘
                                        (right side, main window)

                                        ┌─────────────────────────┐
                                        │ Details | Relationships │  ← Trailing ornament (TAB PICKER)
                                        │ Board   | Timeline      │  (right side, detail column)
                                        └─────────────────────────┘
```

---

## Ornament 1: Primary Actions (Bottom)

### Location
- **Attachment:** `.scene(.bottom)`
- **Position:** Centered at the bottom edge of the window
- **Always visible:** Yes

### Contents
- **Button 1:** New Card (`+` icon)
  - **Enabled when:** Any card type selected (except Structure)
  - **Disabled when:** Structure is selected
  - **Action:** Opens card creation sheet

- **Button 2:** Edit (`✎` pencil icon)
  - **Enabled when:** A card is selected
  - **Disabled when:** No card selected
  - **Action:** Opens card editor sheet

- **Button 3 (DEBUG only):** Developer Boards (`🛠` wrench icon)
  - **Only appears in:** DEBUG builds
  - **Always enabled**
  - **Action:** Opens DeveloperBoardsView sheet

### Visual Style
```
┌──────────────────────────────────────────────┐
│  [Glass background with blur]                │
│  ┌──────────┐  ┌──────────┐  ┌────────────┐ │
│  │ ⊕ New    │  │ ✎ Edit   │  │ 🛠 Debug    │ │
│  │   Card   │  │          │  │   Boards   │ │
│  └──────────┘  └──────────┘  └────────────┘ │
│   (16pt spacing between buttons)             │
└──────────────────────────────────────────────┘
```

### Interaction
- **Hover:** Focus ring appears, button highlights
- **Gaze:** System focus indicator
- **Pinch/Tap:** Button activates, sheet opens

---

## Ornament 2: Settings (Trailing, Main Window)

### Location
- **Attachment:** `.scene(.trailing)`
- **Position:** Right side of the main window, mid-height
- **Always visible:** Yes

### Contents
- **Button:** Settings (`⚙️` gear icon)
  - **Always enabled**
  - **Action:** Opens Settings sheet

### Visual Style
```
┌─────────────┐
│  [Glass]    │
│  ┌───────┐  │
│  │ ⚙️     │  │
│  │ Settings│  │
│  └───────┘  │
└─────────────┘
```

### Interaction
- **Hover:** Focus ring, highlight
- **Gaze:** System focus
- **Pinch/Tap:** Opens Settings

---

## Ornament 3: Detail Tab Picker (Trailing, Detail Column)

### Location
- **Attachment:** `.scene(.trailing)`
- **Position:** Right side of the detail column
- **Visibility:** Only when:
  - A card is selected
  - Not in forced CardSheetView mode (e.g., not in search)
  - Multiple tabs available for that card type

### Contents
- **Segmented Picker** with available tabs:
  - **All cards:** Details, Relationships
  - **Projects:** + Board (Structure)
  - **Worlds/Characters/Scenes:** + Board (Murder Board)
  - **Chapters:** + Aggregate Text
  - **Timelines:** + Timeline Chart

### Visual Style
```
┌──────────────────────────────────────────┐
│  [Glass background with blur]            │
│  ┌──────────────────────────────────┐   │
│  │  Details | Relationships | Board │   │
│  │    ●           ○             ○    │   │  ← Selected = filled circle
│  └──────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

### Interaction
- **Hover:** Segment highlights
- **Gaze:** Focus indicator on segment
- **Pinch/Tap:** Switch to selected tab, detail view updates

### Example Configurations

**For a Project card:**
```
┌────────────────────────────────────────┐
│  Details | Relationships | Board       │
│    ●           ○             ○          │
└────────────────────────────────────────┘
```

**For a Chapter card:**
```
┌──────────────────────────────────────────┐
│  Details | Relationships | Aggregate     │
│    ○           ●             ○            │
└──────────────────────────────────────────┘
```

**For a Timeline card:**
```
┌──────────────────────────────────────────┐
│  Details | Relationships | Timeline      │
│    ○           ○             ●            │
└──────────────────────────────────────────┘
```

**For a Map/Location/Building/etc. card:**
```
┌────────────────────────────────┐
│  Details | Relationships       │
│    ●           ○                │
└────────────────────────────────┘
```

---

## Glass Background Effect

All ornaments use `.glassBackgroundEffect()` which provides:

### Visual Properties
- **Translucency:** ~70-80% opaque (system-controlled)
- **Blur:** Content behind is blurred
- **Color reflection:** Picks up ambient color from environment
- **Depth:** Subtle shadow/elevation to float above window

### Example Appearance
```
┌─────────────────────────────────┐
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │  ← Frosted glass texture
│  ░  ⊕ New Card   ✎ Edit      ░  │  ← Buttons on glass
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
└─────────────────────────────────┘
   ↑                           ↑
   Blurred content shows through
```

---

## Ornament Behavior

### On Window Resize
- Ornaments **reposition** relative to window edges
- Bottom ornament stays centered at bottom
- Trailing ornaments stay on right side
- Automatically adjust to new window size

### On Navigation
- **Primary Actions ornament:** Always visible
  - New Card button enables/disables based on sidebar selection
  - Edit button enables/disables based on card selection
- **Settings ornament:** Always visible
- **Detail Tab Picker ornament:** Conditional
  - Appears when card selected
  - Disappears when no card selected
  - Content updates based on card type

### On Sheet Presentation
- Ornaments **remain visible** when sheets open
- Ornaments **slightly dimmed** (system behavior)
- Still interactive (can dismiss sheet and use ornament again)

### On Search
- All ornaments remain visible
- Tab picker ornament **disappears** (search forces CardSheetView)
- Reappears when search is cleared

---

## Platform Comparison

### visionOS (Ornaments)
```
┌─────────────────────────────────────┐
│   Cumberland Window                 │
│  ┌────────────────────────────┐    │
│  │                            │    │
│  │      Content               │    │
│  │                            │    │
│  └────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
        ↓
  ┌──────────────┐     ┌──────┐
  │ ⊕  ✎         │     │  ⚙️   │
  └──────────────┘     └──────┘
   Bottom ornament    Trailing ornament
```

### macOS (Toolbar)
```
┌─────────────────────────────────────┐
│ ⚙️ Settings    ⊕ New  ✎ Edit  [...] │  ← Toolbar at top
├─────────────────────────────────────┤
│   Cumberland Window                 │
│  ┌────────────────────────────┐    │
│  │                            │    │
│  │      Content               │    │
│  │                            │    │
│  └────────────────────────────┘    │
└─────────────────────────────────────┘
```

### iOS (Toolbars in Navigation)
```
┌─────────────────────────────────────┐
│ < Content                       ⚙️   │  ← Nav bar (content column)
├─────────────────────────────────────┤
│                                     │
│      [Card List]                    │
│                                     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ < Detail          Details|Rels|... │  ← Nav bar (detail column)
├─────────────────────────────────────┤
│                                     │
│      [Card Details]                 │
│                                     │
└─────────────────────────────────────┘
```

---

## User Interaction Flow

### Creating a Card (via Ornament)
1. **User looks at bottom ornament**
   - Gaze focuses on "New Card" button
   - Focus ring appears
2. **User pinches** (or taps)
   - Button activates with haptic feedback
3. **Sheet slides up** from bottom
   - Ornament dims slightly (system behavior)
   - Sheet contains CardEditorView
4. **User fills in fields** (name, subtitle, etc.)
5. **User taps Save**
   - Sheet dismisses
   - New card appears in list
   - Ornament returns to full brightness

### Switching Tabs (via Detail Ornament)
1. **User selects a card** from list
   - Detail tab picker ornament appears (trailing edge)
   - Default tab (Details) is selected
2. **User looks at tab picker ornament**
   - Gaze focuses on "Relationships" segment
   - Segment highlights
3. **User pinches**
   - Tab switches immediately
   - Detail view animates to CardRelationshipView
   - Selected segment updates (filled circle)
4. **User looks at "Board" segment** (if available)
   - Repeats process
   - Detail view switches to board view

---

## Spatial Depth & Layout

### Z-Order (Front to Back)
1. **Modal sheets** (frontmost)
2. **Ornaments** (floating above window)
3. **Window content** (main UI)
4. **Window background** (glass/material)
5. **Environment** (user's space, furthest back)

### Ornament Elevation
- Ornaments appear **~10-20pt** above window surface
- Subtle shadow creates depth perception
- Parallax effect when moving head (on device)

---

## Accessibility

### VoiceOver Labels
- **New Card button:** "New Card, button, creates a new card"
- **Edit button:** "Edit, button, edit the selected card" (disabled if no selection)
- **Settings button:** "Settings, button, opens settings"
- **Tab segments:** "Details tab, selected" / "Relationships tab, not selected"

### Keyboard Navigation
- Tab key cycles through ornament buttons
- Arrow keys navigate segmented picker
- Return/Space activates focused element

### Focus Order
1. Sidebar
2. Content list
3. Detail view
4. Bottom ornament (left to right: New Card → Edit → Debug)
5. Trailing ornaments (top to bottom: Settings → Tab Picker)

---

## Performance Considerations

### GPU Usage
- Glass effects use Metal shaders
- Optimized by system for visionOS
- No performance impact on macOS/iOS (ornaments not rendered)

### Memory
- Ornament views are lightweight
- Lazy evaluation via computed properties
- Only tab picker renders conditionally

### Animation
- System handles ornament transitions
- Smooth 60fps animations
- Haptic feedback on device (simulated in simulator)

---

## Troubleshooting Visual Issues

### Ornaments Not Visible
- **Check:** Is destination set to "Apple Vision Pro"?
- **Check:** Are you in the visionOS simulator (not "My Mac (Designed for iPad)")?
- **Fix:** Explicitly select visionOS target

### Ornaments Appear Cut Off
- **Cause:** Window too small
- **Fix:** Resize simulator window to larger size
- **Note:** Ornaments auto-position, but need minimum space

### Glass Effect Not Showing
- **Check:** Is `.glassBackgroundEffect()` applied in OrnamentViews.swift?
- **Note:** Simulator may have reduced visual fidelity vs device

### Ornaments Overlapping Content
- **Rare:** Should not happen with default attachment anchors
- **Fix:** Adjust `.scene(.bottom)` / `.scene(.trailing)` positions

---

## Design Intent

### Why Ornaments?
- **Native to visionOS:** Designed for spatial computing
- **Non-intrusive:** Float outside window, don't block content
- **Discoverable:** Persistent presence guides users
- **Flexible:** Easy to add/remove actions without redesigning UI

### Why Bottom for Primary Actions?
- **Reachability:** Easy to pinch from comfortable hand position
- **Expectation:** Bottom = actions (iOS pattern)
- **Visibility:** Always in peripheral vision

### Why Trailing for Settings & Tabs?
- **Hierarchy:** Secondary actions on the side
- **Spatial logic:** Right side = controls/options (Western UI convention)
- **Separation:** Primary actions (bottom) vs secondary (side)

---

## Future Enhancements (Phase 2+)

### Potential Additions
- **Leading ornament:** Quick access to recent cards or favorites
- **Top ornament:** Global search or filters
- **Context-sensitive ornaments:** Appear only when relevant (e.g., "Add Relationship" when in Relationships tab)

### Phase 2 (Multi-Window)
- Ornaments will adapt to individual windows
- Floating editor windows may have their own ornaments (Save/Cancel)

### Phase 4 (3D/Immersive)
- Ornaments in 3D volumes (e.g., board editing tools)
- Immersive space may hide ornaments entirely (focused writing mode)

---

**Use this guide to understand the visual layout and behavior of Cumberland's visionOS ornaments during testing!**
