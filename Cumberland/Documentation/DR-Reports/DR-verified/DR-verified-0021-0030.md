## DR-0021: Layer visibility toggle not working

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** LayerManager, Layers Tab, DrawingCanvasView, DrawingCanvasViewMacOS
**Severity:** High
**Date Identified:** 2026-01-03
**Date Resolved:** 2026-01-03
**Date Verified:** 2026-01-03

**Description:**
When setting a layer's visibility to "off" or "not visible" in the Layers Tab on the tool palette (including the base layer), the layer should be hidden from view until toggled back on.

**Root Cause:**
The base layer rendering code in both DrawingCanvasView (iOS) and DrawingCanvasViewMacOS (macOS) was not checking the layer's `isVisible` property before rendering.

**Fix Applied:**

1. **DrawingCanvasView.canvasBackgroundView** (DrawingCanvasView.swift:135-137)
   - Added `baseLayer.isVisible` check before rendering base layer (iOS/visionOS)
   
2. **DrawingCanvasViewMacOS.draw()** (DrawingCanvasViewMacOS.swift:179-181)
   - Added `baseLayer.isVisible` check before rendering base layer (macOS)

**Files Modified:**
- DrawingCanvasView.swift
- DrawingCanvasViewMacOS.swift

---

## DR-0022: Interior surfaces regenerate during pan/zoom operations

**Status:** ✅ Verified
**Platform:** All platforms
**Component:** ProceduralPatternView, DrawingCanvasView, DrawingCanvasViewMacOS
**Severity:** High
**Date Identified:** 2026-01-03
**Date Resolved:** 2026-01-03
**Date Verified:** 2026-01-03

**Description:**
Similar to the terrain rendering system, interior floor patterns (wood, tile, stone, etc.) should be cached and not regenerate during pan, zoom, show, or hide operations. Previously, patterns regenerated unnecessarily, causing performance issues.

**Root Cause Analysis:**
ProceduralPatternUIView (iOS) and DrawingCanvasViewMacOS (macOS) were regenerating patterns on every draw call instead of caching the rendered result.

**Fix Applied:**

1. **ProceduralPatternUIView** (DrawingCanvasView.swift:1606-1645)
   - Added `cachedPatternImage` and `cachedCacheKey` properties
   - Generate cache key: `fillType_patternSeed_mapScale_width×height`
   - Check cache before regenerating pattern
   - Use UIGraphicsImageRenderer to generate and cache pattern image
   - Reuse cached image on subsequent draw calls

2. **DrawingCanvasViewMacOS** (DrawingCanvasViewMacOS.swift:63-64, 237-279)
   - Added `patternCache` dictionary
   - Generate same cache key format as iOS
   - Create bitmap context for pattern rendering
   - Cache CGImage and reuse on subsequent draws
   - Pattern only regenerates when cache key changes

**Files Modified:**
- DrawingCanvasView.swift (iOS/visionOS pattern caching)
- DrawingCanvasViewMacOS.swift (macOS pattern caching)

---

## DR-0023: Strokes not added to layers with visibility control

**Status:** ✅ Verified
**Platform:** All platforms
**Component:** DrawingCanvasView, DrawingCanvasViewMacOS, LayerManager, LayersTabView
**Severity:** High
**Date Identified:** 2026-01-03
**Date Resolved:** 2026-01-03
**Date Verified:** 2026-01-03

**Description:**
When drawing strokes on the canvas, they should be added to the currently selected layer and respect layer visibility. Previously, strokes were saved to the model's main drawing properties instead of being associated with individual layers, and layer visibility didn't affect stroke rendering.

**Root Cause Analysis:**

**iOS/visionOS:**
- `canvasViewDrawingDidChange` delegate saved to `model.drawing` only
- PKCanvasView displayed `model.drawing` without layer awareness
- No layer switching mechanism when user selected different layer

**macOS:**
- `mouseUp` handler appended strokes to `model.macOSStrokes`
- Rendering code drew from `model.macOSStrokes` without visibility check
- No layer-aware rendering

**Fix Applied:**

1. **DrawingCanvasView.swift:1195-1200** (iOS stroke saving)
   - Updated `canvasViewDrawingDidChange` to save strokes to `activeLayer.drawing` in real-time
   - Added lock check: only save if `!activeLayer.isLocked`

2. **DrawingCanvasViewMacOS.swift:148-159** (macOS stroke saving)
   - Updated `mouseUp` to save strokes to `activeLayer.macosStrokes` instead of `model.macOSStrokes`
   - Added lock check and backward compatibility fallback

3. **DrawingCanvasViewMacOS.swift:305-326** (macOS rendering with visibility)
   - Replaced simple model stroke rendering with layer-aware rendering
   - Iterate through `layerManager.sortedLayers` (bottom to top)
   - Check `layer.isVisible` before drawing each layer's strokes
   - Respect `layer.opacity` during rendering

4. **LayersTabView.swift:106-115** (iOS layer switching)
   - When user taps a layer, load that layer's `PKDrawing` into canvas
   - Updates `canvasState.drawing = selectedLayer.drawing`

**Files Modified:**
- DrawingCanvasView.swift (iOS stroke saving + layer system integration)
- DrawingCanvasViewMacOS.swift (macOS stroke saving + visibility rendering)
- LayersTabView.swift (layer switching for iOS)

**Implementation Notes:**

**iOS Behavior:**
- PKCanvasView can only display one drawing at a time
- When switching layers, the canvas shows that layer's content
- Only the active layer's strokes are editable on screen
- All layers are composited when exporting

**macOS Behavior:**
- All visible layers render simultaneously in correct order
- Layer opacity and visibility are respected
- Active layer receives new strokes
- Non-active layers remain visible but non-editable

---

## DR-0024: Strokes deleted when autosave runs

**Status:** ✅ Verified
**Platform:** All platforms
**Component:** DrawingCanvasView, AutoSave, LayerManager
**Severity:** Critical
**Date Identified:** 2026-01-03
**Date Resolved:** 2026-01-03
**Date Verified:** 2026-01-03

**Description:**
When the system's autosave mechanism triggered, all strokes on the currently selected/active layer were deleted. This critical data loss bug was caused by obsolete migration code in the export function that was overwriting layer strokes with stale model-level drawing data.

**Root Cause Analysis:**

The bug was caused by an interaction between DR-0023 (real-time layer stroke saving) and obsolete migration code in `exportCanvasState()`.

**Before DR-0023:**
- Strokes were saved to `model.drawing` (iOS) and `model.macOSStrokes` (macOS)
- Export would migrate these strokes to the active layer during save

**After DR-0023:**
- Strokes save directly to `activeLayer.drawing` and `activeLayer.macosStrokes` in real-time
- BUT `model.drawing` is ALSO updated (for PKCanvasView display binding)
- Migration code remained in export, creating a conflict

**The Data Loss Sequence:**

1. User draws on Layer 2 → strokes saved to both `model.drawing` AND `layer2.drawing` ✓
2. User switches to view Base Layer → `baseLayer.drawing` loads into `model.drawing`
3. Now `model.drawing` contains the **base layer's empty drawing**
4. But `activeLayerID` still points to Layer 2
5. **Autosave triggers** → `exportCanvasState()` runs
6. Migration code: `activeLayer.drawing = drawing`
7. This **overwrites Layer 2's strokes** with the **empty base layer drawing**
8. LayerManager is encoded with Layer 2 now empty
9. **Strokes permanently deleted**

**Why This Happened:**
- `model.drawing` is **view state** (which layer is displayed on screen)
- `activeLayerID` is **editing state** (which layer receives new strokes)
- These two can be out of sync (viewing one layer while another is active)
- Migration code assumed `model.drawing` always contained the active layer's strokes
- This assumption broke with layer switching

**Fix Applied:**

**DrawingCanvasView.swift:539-544** - Removed migration code from export

Deleted the entire migration block that was:
- Copying `model.drawing` → `activeLayer.drawing` (iOS)
- Copying `model.macOSStrokes` → `activeLayer.macosStrokes` (macOS)
- Converting PKDrawing to DrawingStroke format

**Why Removal is Safe:**
1. DR-0023 already saves strokes to layers in real-time (no migration needed)
2. LayerManager's Codable implementation properly serializes layer strokes
3. Import code correctly restores strokes from layers
4. Migration was obsolete and dangerous after DR-0023

**Files Modified:**
- DrawingCanvasView.swift (removed lines 542-591, added explanatory comment)

---


## DR-0024: iOS canvas layers do not all display at once

**Status:** ✅ Verified
**Platform:** iOS
**Component:** DrawingCanvasView, LayerManager
**Severity:** Critical
**Date Identified:** 2026-01-03
**Date Resolved:** 2026-01-03
**Date Verified:** 2026-01-03

**Description:**
On iOS, only the currently selected/active layer was visible on the canvas. All other layers were hidden regardless of their visibility settings (eye icon state). This prevented users from seeing the composite view of all visible layers, which is essential for map creation workflows.

**Root Cause:**
On iOS, PencilKitCanvasView only displays a single `PKDrawing` object bound to `canvasState.drawing`. Unlike macOS (which iterates through all visible layers in its draw method), iOS was showing only one drawing at a time—typically just the active layer's drawing—causing all other layers to be hidden.

**Fix Applied:**
Created LayerCompositeView to render all visible non-active layers as images underneath the PencilKitCanvasView, matching macOS's multi-layer compositing behavior.

**Files Modified:**
- DrawingCanvasView.swift:73-80 (added LayerCompositeView to canvas stack)
- DrawingCanvasView.swift:95-98 (onChange handler for layer switching)
- DrawingCanvasView.swift:133-136 (onAppear sync)
- DrawingCanvasView.swift:1357-1396 (new LayerCompositeView struct)

---

## DR-0026: Switching from Base Layer deletes strokes on target layer (iOS)

**Status:** ✅ Verified
**Platform:** iOS
**Component:** DrawingCanvasView, LayerManager, ER-0002 implementation
**Severity:** Critical - Data Loss
**Date Identified:** 2026-01-03
**Date Resolved:** 2026-01-03
**Date Verified:** 2026-01-03

**Description:**
When the Base Layer was selected and the user attempted to draw, ER-0002 correctly redirected selection to the topmost content layer. However, on iOS, this automatic layer switch deleted all existing strokes on the target layer.

**Root Cause:**
In `canvasViewDrawingDidChange`, when ER-0002's `getTargetLayerForStrokes()` switched the active layer from base to a content layer, the code immediately saved the canvas's current drawing (empty base layer) to the target layer, overwriting existing strokes.

**Fix Applied:**
Added layer switch detection that loads the target layer's drawing into the canvas instead of saving when a switch occurs, preventing data loss.

**Files Modified:**
- DrawingCanvasView.swift:333-353 (activeLayerDrawing, syncDrawingWithActiveLayer)
- DrawingCanvasView.swift:95-98 (onChange for layer sync)
- DrawingCanvasView.swift:1186-1219 (canvasViewDrawingDidChange with switch detection)

---

## DR-0025: iOS eye icon has no effect on Layer visibility

**Status:** ✅ Resolved - Verified
**Platform:** iOS
**Component:** DrawingCanvasView, LayerManager, LayerCompositeView
**Severity:** High
**Date Identified:** 2026-01-03
**Date Resolved:** 2026-01-06
**Date Verified:** 2026-01-06

**Description:**
On iOS, toggling the eye icon in the Layers tab has no effect on layer visibility. Layers remain visible even when the eye icon is set to grey (hidden state). The visibility filter in LayerCompositeView is not working as expected.

**Steps to Reproduce:**
1. Create a map on iOS with multiple layers
2. Add strokes to multiple layers
3. Toggle eye icon to grey (hidden) for a layer
4. Observe that layer's strokes still display

**Expected Behavior:**
- Eye icon enabled (blue): Layer is visible and composited into canvas
- Eye icon disabled (grey): Layer is hidden from canvas, strokes not displayed

**Actual Behavior:**
Eye icon toggles between blue and grey, but layer strokes remain visible regardless of state.

**Root Cause:**
LayerCompositeView was not reactive to changes in layer visibility. The issue had two parts:

1. **Missing .id() modifier**: LayerCompositeView lacked an identity that incorporated visibility state, so SwiftUI didn't know when to recreate the view
2. **Observable array limitation**: Swift's @Observable macro doesn't automatically trigger change notifications when properties of objects *within* an array are modified (e.g., `layer.isVisible`)

**Fix Applied:**
**Date Fixed:** 2026-01-06

**Part 1: Added .id() modifier to LayerCompositeView** (DrawingCanvasView.swift:82)
```swift
.id(layerManager.layers.map { "\($0.id)_\($0.isVisible)_\($0.order)" }.joined())
```
This creates a unique identity string that changes whenever any layer's visibility or order changes.

**Part 2: Trigger observation updates in LayerManager** (LayerManager.swift)
Added `layers = layers` reassignment to all methods that modify layer properties:
- `toggleVisibility()` (line 390)
- `setVisibility()` (line 398)
- `toggleLock()` (line 406)
- `setLock()` (line 414)
- `setOpacity()` (line 423)
- `setBlendMode()` (line 432)
- `renameLayer()` (line 443)
- `showAllLayers()` (line 486)
- `hideAllExcept()` (line 495)
- `lockAllExcept()` (line 505)
- `unlockAllLayers()` (line 515)

This reassignment triggers the @Observable system to notify observers that the layers array changed, which in turn causes the .id() modifier to re-evaluate.

**Files Modified:**
- DrawingCanvasView.swift (added .id modifier)
- LayerManager.swift (added observation triggers to 11 methods)

**Verification Results:**
✅ Eye icon toggle now hides/shows layers correctly
✅ Multiple layers can have different visibility states
✅ LayerCompositeView updates immediately when visibility changes

---

## DR-0027: Masking panel obscures strokes on non-active layers (iOS)

**Status:** ✅ Resolved - Verified
**Platform:** iOS
**Component:** DrawingCanvasView, LayerCompositeView
**Severity:** Critical
**Date Identified:** 2026-01-03
**Date Resolved:** 2026-01-06
**Date Verified:** 2026-01-06

**Description:**
A mysterious invisible masking panel obscures strokes on non-active layers when zoomed out below 50%. The visible rectangle shrinks proportionally with zoom level. At 49% zoom, approximately 49% of width/height is visible (upper left corner). At 25% zoom (minimum), only ~25% of width/height is visible. The active layer always displays all strokes everywhere, but non-active layers are partially masked.

**Steps to Reproduce:**
1. Create map on iOS with multiple layers
2. Draw strokes across entire canvas on multiple layers
3. Zoom out to 49% or less
4. Observe non-active layers

**Expected Behavior:**
All visible layers should display their strokes across the entire canvas at all zoom levels, just like the active layer does.

**Actual Behavior:**
- At zoom < 50%: Non-active layer strokes are masked/clipped
- Visible rectangle in upper left corner shrinks as zoom decreases
- At 49% zoom: ~49% x 49% visible rectangle
- At 25% zoom: ~25% x 25% visible rectangle
- Active layer shows all strokes everywhere (correct)
- Non-active layers show strokes only in shrinking rectangle (wrong)

**Root Cause:**
The issue was resolved by the same fix applied for DR-0025. The LayerCompositeView reactivity improvements (`.id()` modifier and observation triggers) caused SwiftUI to properly recreate the view, which resolved the masking issues.

**Fix Applied:**
Same fix as DR-0025:
- Added `.id()` modifier to LayerCompositeView (DrawingCanvasView.swift:82)
- Added observation triggers in LayerManager methods

**Files Modified:**
- DrawingCanvasView.swift (added .id modifier)
- LayerManager.swift (added observation triggers to 11 methods)

**Verification Results:**
✅ All layers display strokes across entire canvas at all zoom levels
✅ No masking or clipping occurs on non-active layers
✅ Works correctly from 25% to 100% zoom

---

## DR-0028: Strokes dim and invert colors when layer is not selected (iOS)

**Status:** ✅ Resolved - Verified
**Platform:** iOS
**Component:** DrawingCanvasView, LayerCompositeView
**Severity:** High
**Date Identified:** 2026-01-03
**Date Resolved:** 2026-01-06
**Date Verified:** 2026-01-06

**Description:**
Strokes on non-active layers appear dimmed and have inverted colors. Most notably, black strokes change to white when their layer is not selected. This is counterintuitive and makes it difficult to see the actual stroke colors.

**Steps to Reproduce:**
1. Create map on iOS with multiple layers
2. Draw black strokes on Layer 1
3. Draw black strokes on Layer 2
4. Select Layer 1 as active
5. Observe Layer 2 strokes

**Expected Behavior:**
All layers should display strokes in their original colors at full intensity, regardless of which layer is active. Black strokes should appear black on all layers.

**Actual Behavior:**
- Active layer: Strokes display correctly in original colors
- Non-active layers: Strokes appear dimmed/inverted
- Black strokes on non-active layers appear white
- Effect is counterintuitive and confusing

**Root Cause:**
The issue was resolved by the same fix applied for DR-0025. The LayerCompositeView reactivity improvements (`.id()` modifier and observation triggers) caused SwiftUI to properly recreate and render the view with correct colors.

**Fix Applied:**
Same fix as DR-0025:
- Added `.id()` modifier to LayerCompositeView (DrawingCanvasView.swift:82)
- Added observation triggers in LayerManager methods
- UIKit-based LayerCompositeView with light mode trait collection (DrawingCanvasView.swift:1410-1415)

**Files Modified:**
- DrawingCanvasView.swift (added .id modifier and UIKit implementation with light mode)
- LayerManager.swift (added observation triggers to 11 methods)

**Verification Results:**
✅ All stroke colors display correctly on all layers
✅ No color inversion or dimming occurs
✅ Black strokes appear black regardless of active layer

---

## DR-0029: Base layer image recalculated on visibility toggle and restore

**Status:** ✅ Resolved - Verified
**Platform:** All platforms (iOS, macOS, visionOS)
**Component:** DrawingCanvasView, DrawingCanvasViewMacOS, BaseLayerImageCache
**Severity:** High (Performance)
**Date Identified:** 2026-01-06
**Date Resolved:** 2026-01-06
**Date Verified:** 2026-01-07

**Description:**
When toggling the visibility of the base layer (eye icon), or when restoring a drawing that has a visible base layer, the base layer image is regenerated from scratch instead of using a cached version. For procedural terrain or complex patterns, this causes a significant performance delay (1-2 seconds for 2048x2048 terrain). No UI feedback is provided to indicate that processing is happening.

**Steps to Reproduce:**
1. Create a map with procedural terrain base layer (Land, Water, etc.)
2. Wait for initial terrain generation (1-2 seconds)
3. Toggle base layer visibility off (eye icon to grey)
4. Toggle base layer visibility on (eye icon to blue)
5. Observe 1-2 second delay with no feedback

**OR:**

1. Create a map with procedural terrain base layer
2. Save the map
3. Close and reopen the app
4. Load the saved map
5. Observe 1-2 second delay with no feedback during restore

**Expected Behavior:**
- Toggling base layer visibility should be instant (use cached image)
- Restoring a map should show progress indicator while generating base layer
- Base layer image should only regenerate when actual parameters change (type, scale, seed)

**Actual Behavior:**
- Toggling visibility causes full regeneration (1-2 second freeze)
- Restoring causes full regeneration with no UI feedback
- User has no indication that processing is happening

**Impact:**
- Poor user experience due to unexplained delays
- Wastes computational resources regenerating identical images
- No feedback during restore makes app feel unresponsive

**Root Cause:**
The base layer terrain and pattern caching (DR-0016.5, DR-0022) used instance-level cache variables in the view classes. When base layer visibility was toggled OFF, the view was removed from the hierarchy, destroying the cache. When toggled back ON, a new view instance was created with an empty cache, forcing full regeneration.

**Fix Applied:**
**Date Resolved:** 2026-01-06

Implemented a shared, singleton-based BaseLayerImageCache that persists across view recreation and visibility toggles.

**1. Created BaseLayerImageCache (new file)**
- Singleton pattern with thread-safe access
- Cache storage: [cacheKey: PlatformImage]
- Memory management: ~100MB limit with FIFO eviction
- Automatic cache clearing on memory warnings
- Cache key format: "fillType_patternSeed_terrainSeed_widthxheight"

**2. Updated iOS Terrain Rendering** (DrawingCanvasView.swift:1644-1670)
- Removed instance variables: `cachedTerrainImage`, `cachedCacheKey`
- Now uses: `BaseLayerImageCache.shared.get(cacheKey)` and `.set(cacheKey, image:)`
- Cache persists when view is recreated after visibility toggle

**3. Updated iOS Pattern Rendering** (DrawingCanvasView.swift:1710-1738)
- Removed instance variables: `cachedPatternImage`, `cachedCacheKey`
- Now uses shared cache for wood, tile, stone, etc. patterns
- Cache persists across visibility toggles

**4. Updated macOS Terrain Rendering** (DrawingCanvasViewMacOS.swift:202-249)
- Removed instance dictionary: `terrainCache: [String: CGImage]`
- Now uses shared cache with NSImage ↔ CGImage conversion
- Cache persists across visibility toggles

**5. Updated macOS Pattern Rendering** (DrawingCanvasViewMacOS.swift:254-301)
- Removed instance dictionary: `patternCache: [String: CGImage]`
- Now uses shared cache for all interior patterns
- Cache persists across visibility toggles

**Files Modified:**
- BaseLayerImageCache.swift (NEW - shared cache manager)
- DrawingCanvasView.swift (iOS terrain and pattern views)
- DrawingCanvasViewMacOS.swift (macOS terrain and pattern rendering)

**Result:**
✅ Toggling base layer visibility is now instant (uses cached image)
✅ Restoring maps reuses cached base layer (if canvas size matches)
✅ Memory-efficient with automatic eviction when limit reached
✅ Thread-safe cache access

**Note on Progress Indicator:**
The progress indicator during restore was deferred. Since the cache now persists, most restores will be instant. For truly first-time generation, the delay is already expected (same as initial creation). Can be added in future ER if needed.

**Verification Results:**
✅ **Test 1: Visibility Toggle Performance**
- Land terrain base layer created and rendered
- Initial generation cached properly
- Toggling visibility OFF then ON shows INSTANT rendering
- Console confirms cache HIT messages
- Multiple toggles all instant with cache hits

✅ **Test 2: Pattern Caching (Interior Maps)**
- Wood floor pattern tested
- Visibility toggle shows instant pattern restoration
- Multiple pattern types (Tile, Stone) all use cache after first render

✅ **Test 3: Map Restore Performance**
- Map with terrain saved and reloaded
- Terrain appears instantly from cache on restore
- Console confirms cache HIT

✅ **Test 4: macOS Performance**
- All tests verified on macOS
- Shared cache works correctly across platforms
- NSImage ↔ CGImage conversion transparent

✅ **Test 5: Memory Management**
- Multiple maps with different terrains tested
- Cache size tracking confirmed in console
- No crashes or memory issues observed

---

## DR-0030: Missing "Add Card" UI on iOS/iPadOS and misplaced Settings button

**Status:** ✅ Resolved - Verified
**Platform:** iOS/iPadOS, macOS
**Component:** MainAppView, CumberlandApp, Toolbar
**Severity:** High (Feature Missing on iOS)
**Date Identified:** 2026-01-07
**Date Resolved:** 2026-01-07
**Date Verified:** 2026-01-07

**Description:**
On iOS/iPadOS, there is no visible UI control in the content list to create a new Card (Map, Scene, Character, etc.). The "New Card" button exists on macOS in the primaryAction toolbar placement, but the Settings button occupies prime toolbar real estate on both platforms. Additionally, both iOS and macOS provide a "Cumberland" menu with a "Settings" item that brings up system app settings, making the toolbar Settings button redundant.

**Current State:**

**iOS/iPadOS** (MainAppView.swift:508-516):
- Settings button appears in navigationBarTrailing placement of content column
- NO "New Card" button visible in toolbar
- Users can only create cards through:
  - Empty state "Create Card" button (only when no cards exist)
  - No other visible UI affordance

**macOS** (MainAppView.swift:262-270, 273-279):
- Settings button in navigation placement (left side)
- "New Card" button in primaryAction placement
- Settings button functionality redundant with menu system

**Expected Behavior:**
1. **iOS/iPadOS**: "Add Card" button should be prominently visible in the content list toolbar
2. **macOS**: "Add Card" button placement should be consistent and accessible
3. **All Platforms**: Settings/Preferences should be in the Cumberland menu, not as a toolbar button
4. **All Platforms**: Toolbar space should prioritize primary actions (creating content) over secondary actions (settings)

**Actual Behavior:**
1. **iOS/iPadOS**: No "Add Card" button visible - hidden functionality
2. **macOS**: Settings button takes up toolbar space unnecessarily
3. **Both Platforms**: Cumberland menu already has "Settings" → system preferences (appropriate)
4. **Inconsistency**: Settings accessed via button, not menu item like other apps

**Impact:**
- **Critical on iOS/iPadOS**: Users cannot discover how to create new cards
- **Poor UX**: Settings button occupies space that should be used for "Add Card"
- **Inconsistent**: App doesn't follow platform conventions (preferences in menu)
- **Hidden Feature**: Card creation is not discoverable on iOS without empty state

**Fix Applied:**
**Date Resolved:** 2026-01-07

Implemented comprehensive UI reorganization following platform conventions:

**1. Added Preferences Menu Command** (CumberlandApp.swift:734-745)
- Created PreferencesCommands struct to replace default Settings menu
- Replaces .appSettings CommandGroup with "Preferences..." menu item
- Keyboard shortcut: Cmd+, (standard macOS convention)
- Opens settings window via openWindow(id: "settings")

**2. Converted Settings Scene to Window** (CumberlandApp.swift:240-248)
- Changed from `Settings { }` scene to `Window("Preferences", id: "settings") { }`
- Retains all SettingsView functionality
- Accessible via menu command (no longer auto-generated menu)
- Uses .windowResizability(.contentSize) for proper window behavior

**3. Removed macOS Settings Toolbar Button** (MainAppView.swift:260-263)
- Removed .navigation ToolbarItem with Settings button
- Freed up toolbar space for primary actions
- Settings now accessed exclusively via Cumberland > Preferences... menu

**4. Added iOS New Card Button** (MainAppView.swift:497-509)
- Replaced Settings button in .navigationBarTrailing placement with New Card button
- Uses same showingCardEditor state as macOS primaryAction button
- Includes .disabled(isStructureSelected) to match macOS behavior
- Always visible when viewing card lists

**Implementation Details:**

**CumberlandApp.swift:**
```swift
private struct PreferencesCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Preferences...") {
                openWindow(id: "settings")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
```

**Result:**
✅ iOS users now have prominent "+" button to create cards
✅ macOS Preferences accessed via standard Cumberland menu (Cmd+,)
✅ Toolbar space optimized for content creation actions
✅ Consistent with platform conventions (Preferences in menu, not toolbar)
✅ Empty state "Create Card" button remains as fallback

**Note on visionOS:**
visionOS retains its Settings ornament UI as it wasn't mentioned in the DR scope. Can be addressed in future ER if needed.

**Files Modified:**
- CumberlandApp.swift:
  - Lines 190: Added PreferencesCommands() to .commands block
  - Lines 240-248: Converted Settings scene to Window with id "settings"
  - Lines 734-745: Created PreferencesCommands struct
- MainAppView.swift:
  - Lines 260-263: Removed macOS Settings toolbar button
  - Lines 497-509: Added iOS New Card toolbar button

**Verification Results:**
✅ **Test 1: macOS Preferences Menu**
- Cumberland menu shows "Preferences..." item (not "Settings")
- Cmd+, keyboard shortcut opens Preferences window
- Preferences window displays all settings correctly
- No Settings gear icon in main window toolbar

✅ **Test 2: iOS New Card Button**
- "+" (New Card) button visible in top-right toolbar on iPad
- Tapping "+" opens card creation sheet
- Card created successfully
- "+" button remains visible after creating cards

✅ **Test 3: iOS Settings Access**
- Cumberland settings available in iOS Settings app
- Follows standard iOS pattern (no in-app Settings button needed)

✅ **Test 4: macOS Toolbar Consistency**
- Only "New Card" and "Edit" buttons in primaryAction area
- New card creation works identically to before
- Toolbar is cleaner without redundant Settings button

✅ **Test 5: Empty State Behavior**
- Empty state "Create Card" button still available as fallback
- After creating first card, "+" toolbar button remains visible
- Both creation methods work correctly

---
