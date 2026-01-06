# Discrepancy Reports (DR) - Unverified Issues

This document tracks discrepancy reports that have been resolved but are awaiting user verification.

**Status:** Currently **1 unverified DR**

---

## DR-0029: Base layer image recalculated on visibility toggle and restore

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms (iOS, macOS, visionOS)
**Component:** DrawingCanvasView, DrawingCanvasViewMacOS, BaseLayerImageCache
**Severity:** High (Performance)
**Date Identified:** 2026-01-06
**Date Resolved:** 2026-01-06

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

**Test Steps:**

**Test 1: Visibility Toggle Performance**
1. Create a new map with Land terrain base layer (exterior)
2. Wait for initial terrain generation (~1-2 seconds first time)
3. Observe console: should see "[BaseLayerImageCache] Cache MISS" and "Terrain cached"
4. Toggle base layer visibility OFF (eye icon to grey)
5. Toggle base layer visibility ON (eye icon to blue)
6. **Expected:** Terrain appears INSTANTLY (< 0.1 seconds)
7. Observe console: should see "[BaseLayerImageCache] Cache HIT"
8. Toggle visibility OFF/ON several more times
9. **Expected:** Always instant with cache HIT messages

**Test 2: Pattern Caching (Interior Maps)**
1. Create a new interior map with Wood floor
2. Wait for initial pattern generation
3. Toggle base layer visibility OFF then ON
4. **Expected:** Pattern appears instantly (cache HIT)
5. Try with other patterns (Tile, Stone, etc.)
6. **Expected:** All patterns use cache after first render

**Test 3: Map Restore Performance**
1. Create map with Land terrain
2. Wait for terrain generation
3. Save the map
4. Close and reopen the app (or load a different map)
5. Load the saved map
6. **Expected:** Terrain appears instantly from cache
7. Observe console: should see cache HIT

**Test 4: macOS Performance**
1. Repeat Tests 1-3 on macOS
2. **Expected:** Same instant performance from shared cache

**Test 5: Memory Management**
1. Create multiple maps with different terrains/patterns
2. Toggle visibility on all of them
3. **Expected:** All use cache, no crashes
4. Console should show cache size tracking
5. If cache exceeds ~100MB, oldest entries evicted

---

## Template for Adding New DRs

When a new issue is identified or resolved but not yet verified, add it here using this template:

```markdown
## DR-XXXX: [Brief Title]

**Status:** 🟡 Resolved - Not Verified
**Platform:** iOS / macOS / visionOS / All platforms
**Component:** [Component Name]
**Severity:** Critical / High / Medium / Low
**Date Identified:** YYYY-MM-DD
**Date Resolved:** YYYY-MM-DD

**Description:**
[Detailed description of the issue]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Fix Applied:**
[Description of the fix]

**Test Steps:**
1. [How to verify the fix]
2. [Expected results]

---
```

## Status Indicators

Per DR-GUIDELINES.md:
- 🟡 **Resolved - Not Verified** - Claude can mark when implementation is complete
- ✅ **Resolved - Verified** - Only USER can mark after testing

---

*When user verifies a DR, move it to the appropriate DR-verified-XXXX-YYYY.md file*
