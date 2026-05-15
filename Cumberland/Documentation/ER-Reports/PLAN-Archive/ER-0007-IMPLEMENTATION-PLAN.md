# ER-0007: Unify Map Rendering - Detailed Implementation Plan

**Status:** Awaiting User Approval
**Created:** 2026-01-09
**Estimated Scope:** Large (3-5 days implementation + testing)

---

## Executive Summary

This plan rewrites Lake and River brush rendering to use elevation-based methodology matching the base layer terrain system. The goal is **perfect visual consistency** - brushed water features should look exactly like base layer water features.

**Key Changes:**
1. ✅ **COMPLETED**: Base layer elevation threshold standardized to 0.1
2. ✅ **COMPLETED**: Redundant brushes removed (Ocean, Sea, Stream, Waterfall)
3. **Lake Brush**: Rewrite to generate elevation maps and render pixel-by-pixel
4. **River Brush**: Rewrite with width scaling, consistent meandering, and valley elevation maps

---

## Prerequisites (Already Complete)

### ✅ Phase 0: Foundation Work
- [x] Base layer standardized to single elevation threshold (0.1)
  - Modified `compositionLandType()` in TerrainPattern.swift
  - Modified `compositionForestedType()` in TerrainPattern.swift
  - Build verified: ✅ Success
- [x] Redundant brushes removed (ER-0005)
  - Removed Ocean, Sea, Stream, Waterfall from ExteriorMapBrushSet.swift
  - Removed `renderOceanBrush()` and `renderSeaBrush()` from BrushEngine.swift
  - Build verified: ✅ Success

---

## Phase 1: Lake Brush Elevation-Based Rendering

### Objective
Make Lake brush produce **exactly the same output** as base layer water terrain features using elevation maps.

### Technical Approach

#### 1.1 Generate Elevation Map for Lake Region

```swift
/// ER-0007: Render lake using elevation-based rendering (matches base layer exactly)
static func renderLakeBrush(
    brush: MapBrush,
    points: [CGPoint],
    color: Color,
    width: CGFloat,
    context: CGContext,
    terrainMetadata: TerrainMapMetadata? = nil
) {
    // Step 1: Calculate bounding box
    let boundingBox = calculateBoundingBox(points: points, padding: width * 2.0)

    // Step 2: Generate elevation map (just like base layer)
    let elevationMap = ElevationMap(
        width: Int(boundingBox.width),
        height: Int(boundingBox.height),
        seed: Int.random(in: 0...10000),
        waterPercentage: 0.6, // 60% water, 40% beach/land
        scale: (terrainMetadata?.physicalSizeMiles ?? 100.0) / 100.0,
        octaves: 6
    )

    // Step 3: Create path for point-in-polygon testing
    let lakePath = CGMutablePath()
    lakePath.move(to: points[0])
    for i in 1..<points.count {
        lakePath.addLine(to: points[i])
    }
    lakePath.closeSubpath()

    // Step 4: Render pixel-by-pixel using elevation thresholds
    // (See detailed pixel rendering code below)
}
```

#### 1.2 Pixel-by-Pixel Rendering with Elevation Thresholds

```swift
// Create bitmap context for pixel-perfect rendering
let bitmapContext = CGContext(...)

for y in 0..<imageHeight {
    for x in 0..<imageWidth {
        let canvasPoint = CGPoint(x: CGFloat(x) + minX, y: CGFloat(y) + minY)

        // Only render pixels within lake stroke path
        guard lakePath.contains(canvasPoint) else { continue }

        // Get elevation at this pixel
        let elevation = elevationMap.elevationAt(x: x, y: y)

        // ER-0007: Use same thresholds as base layer (standardized to 0.1)
        let pixelColor: CGColor
        if elevation < 0.1 {
            // Sandy beach (matches base layer exactly)
            pixelColor = CGColor(red: 0.90, green: 0.75, blue: 0.50, alpha: 1)
        } else if elevation < 0.0 {
            // Shallow water (lighter, near shore)
            pixelColor = CGColor(red: 0.45, green: 0.65, blue: 0.85, alpha: 1)
        } else {
            // Deep water (darker, center)
            pixelColor = CGColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1)
        }

        bitmapContext.setFillColor(pixelColor)
        bitmapContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
    }
}

// Draw rendered bitmap to main context
if let image = bitmapContext.makeImage() {
    context.draw(image, in: boundingBox)
}
```

### Implementation Steps

**1.1.1** Add helper function to calculate bounding box with padding
- File: `BrushEngine.swift`
- Function: `calculateBoundingBox(points:padding:) -> CGRect`
- ~10 lines of code

**1.1.2** Rewrite `renderLakeBrush()` function completely
- File: `BrushEngine.swift` (lines ~937-1058, currently 121 lines)
- Replace entire function with elevation-based rendering
- ~150 lines of new code
- Add detailed comments explaining elevation thresholds

**1.1.3** Test lake rendering
- Create test map with base layer water terrain
- Draw lake with brush
- Visually compare: should be **indistinguishable**
- Test different scales (5mi, 50mi, 500mi)
- Verify organically varying beach widths

### Expected Outcome
- Lake brush produces **exactly the same visual output** as base layer lakes
- Extremely large sandy areas of varying shape and width
- Perfect visual consistency
- Build success, no errors

### Estimated Time: 4-6 hours

---

## Phase 2: River Brush Valley/Basin Rendering

### Objective
Fix three river issues simultaneously:
1. **Width Scaling**: Long rivers should be wider than short rivers
2. **Consistent Meandering**: All rivers meander equally (long rivers don't straighten)
3. **Valley/Basin Rendering**: Use elevation maps to show river valleys

### Technical Approach

#### 2.1 Calculate River Width Based on Path Length

```swift
/// Calculate total path length
func calculatePathLength(points: [CGPoint]) -> CGFloat {
    var length: CGFloat = 0
    for i in 1..<points.count {
        let dx = points[i].x - points[i-1].x
        let dy = points[i].y - points[i-1].y
        length += hypot(dx, dy)
    }
    return length
}

/// Scale river width logarithmically with path length
let pathLength = calculatePathLength(points: points)
let scaleFactor = 1.0 + log10(max(pathLength / 100.0, 1.0))
let riverWidth = baseWidth * scaleFactor

// Examples:
// 100pt path: width × 1.0 (narrow creek)
// 1000pt path: width × 2.0 (river)
// 10000pt path: width × 3.0 (major river)
```

#### 2.2 Distance-Based Meandering (Fixes Long River Straightening)

**Current Problem:** Meandering applied per segment accumulates error, making long rivers straight.

**Solution:** Apply meandering based on distance along path, not per segment.

```swift
/// Generate meandered river path with consistent sinusoidal pattern
func generateConsistentMeanderedPath(
    centerPath: [CGPoint],
    riverWidth: CGFloat
) -> [CGPoint] {
    let wavelength: CGFloat = 200.0 // Fixed meander wavelength
    let amplitude = riverWidth * 0.5 // Meander amplitude scales with width

    var meanderedPath: [CGPoint] = []
    var accumulatedDistance: CGFloat = 0

    for i in 0..<centerPath.count {
        if i > 0 {
            let dx = centerPath[i].x - centerPath[i-1].x
            let dy = centerPath[i].y - centerPath[i-1].y
            accumulatedDistance += hypot(dx, dy)
        }

        // Calculate meander offset based on accumulated distance
        let phase = (accumulatedDistance / wavelength) * 2.0 * .pi
        let meanderOffset = sin(phase) * amplitude

        // Apply offset perpendicular to path direction
        let perpendicular = calculatePerpendicular(at: i, points: centerPath)
        let meanderedPoint = CGPoint(
            x: centerPath[i].x + perpendicular.x * meanderOffset,
            y: centerPath[i].y + perpendicular.y * meanderOffset
        )

        meanderedPath.append(meanderedPoint)
    }

    return meanderedPath
}
```

**Result:** Long rivers meander just as much as short rivers because meandering is based on physical distance, not segment count.

#### 2.3 Valley/Basin Elevation Map Generation

**Concept:** Rivers flow in valleys. Generate elevation map showing valley cross-section.

```swift
/// Generate elevation map for river valley
func generateRiverValleyElevationMap(
    centerPath: [CGPoint],
    riverWidth: CGFloat,
    valleyWidth: CGFloat
) -> ElevationMap {
    // Valley width is 5-15× river width
    // For major river (100pt wide), valley could be 500-1500pt wide

    let boundingBox = calculateBoundingBox(points: centerPath, padding: valleyWidth)
    let imageWidth = Int(boundingBox.width)
    let imageHeight = Int(boundingBox.height)

    // Create elevation map
    var elevations: [Double] = Array(repeating: 0.5, count: imageWidth * imageHeight)

    for y in 0..<imageHeight {
        for x in 0..<imageWidth {
            let point = CGPoint(x: CGFloat(x) + boundingBox.minX, y: CGFloat(y) + boundingBox.minY)

            // Calculate distance from point to river centerline
            let distToRiver = minimumDistance(from: point, to: centerPath)

            // Elevation profile (cross-section):
            // - River center (distance 0): elevation -0.3 (deepest)
            // - River edge (distance riverWidth/2): elevation -0.2
            // - Flood plain (distance < valleyWidth/3): elevation -0.05 to 0.05
            // - Valley walls (distance < valleyWidth/2): elevation 0.05 to 0.2
            // - Beyond valley: elevation 0.2+ (uplands)

            if distToRiver < riverWidth / 2 {
                // River channel (water)
                elevations[y * imageWidth + x] = -0.3 + (distToRiver / (riverWidth / 2)) * 0.1
            } else if distToRiver < valleyWidth / 3 {
                // Flood plain (wet/muddy)
                let t = (distToRiver - riverWidth / 2) / (valleyWidth / 3 - riverWidth / 2)
                elevations[y * imageWidth + x] = -0.2 + t * 0.25 // -0.2 to 0.05
            } else if distToRiver < valleyWidth / 2 {
                // Valley walls (sandy/grassy transition)
                let t = (distToRiver - valleyWidth / 3) / (valleyWidth / 2 - valleyWidth / 3)
                elevations[y * imageWidth + x] = 0.05 + t * 0.15 // 0.05 to 0.2
            } else {
                // Beyond valley (normal terrain)
                elevations[y * imageWidth + x] = 0.2
            }
        }
    }

    return ElevationMap(elevations: elevations, width: imageWidth, height: imageHeight)
}
```

#### 2.4 Render River Using Elevation Thresholds

```swift
// Render river pixel-by-pixel
for y in 0..<imageHeight {
    for x in 0..<imageWidth {
        let elevation = elevationMap.elevationAt(x: x, y: y)

        let pixelColor: CGColor
        if elevation < -0.2 {
            // River water (deepest part)
            pixelColor = CGColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1)
        } else if elevation < 0.0 {
            // Flood plain / wet basin (muddy color)
            pixelColor = CGColor(red: 0.80, green: 0.75, blue: 0.60, alpha: 1)
        } else if elevation < 0.15 {
            // Sandy banks / dry basin
            pixelColor = CGColor(red: 0.90, green: 0.75, blue: 0.50, alpha: 1)
        } else {
            // Valley walls / surrounding terrain (grass)
            pixelColor = CGColor(red: 0.45, green: 0.70, blue: 0.30, alpha: 1)
        }

        bitmapContext.setFillColor(pixelColor)
        bitmapContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
    }
}
```

### Implementation Steps

**2.1.1** Add path length calculation helper
- File: `BrushEngine.swift`
- Function: `calculatePathLength(points:) -> CGFloat`
- ~8 lines of code

**2.1.2** Add perpendicular calculation helper
- File: `BrushEngine.swift`
- Function: `calculatePerpendicular(at:points:) -> CGPoint`
- ~15 lines of code

**2.1.3** Add minimum distance helper
- File: `BrushEngine.swift`
- Function: `minimumDistance(from:to:) -> CGFloat`
- ~20 lines of code

**2.1.4** Rewrite river meandering algorithm
- File: `BrushEngine.swift`
- Replace `generateProceduralRiverPath()` function
- Current: ~40 lines, segment-based
- New: ~60 lines, distance-based
- Add detailed comments

**2.1.5** Add river valley elevation map generator
- File: `BrushEngine.swift`
- New function: `generateRiverValleyElevationMap()`
- ~80-100 lines of code
- Well-commented elevation profile

**2.1.6** Rewrite river rendering section in `renderWaterBrush()`
- File: `BrushEngine.swift` (lines ~736-870)
- Current: ~134 lines with sandy banks approach
- New: ~200 lines with elevation-based valley rendering
- Calculate river width from path length
- Generate meandered path (consistent algorithm)
- Generate valley elevation map
- Render pixel-by-pixel with elevation thresholds

**2.1.7** Test river rendering
- Short river (100pt): Should be narrow, meander
- Medium river (1000pt): Should be wider, meander equally
- Long river (10000pt): Should be very wide (3× base), meander equally
- Verify valley effect visible
- Test on different map scales

### Expected Outcome
- River width scales logarithmically with path length
- All rivers meander consistently (no straightening)
- Valley/basin effect visible (especially for long rivers)
- Extremely wide boundaries for major rivers (500-1500pt valleys)
- Build success, no errors

### Estimated Time: 8-12 hours

---

## Phase 3: Integration & Testing

### 3.1 Update Phase Status in ER-0007 Documentation
- Mark Phase 1 as complete
- Mark Phase 2 as complete
- Update implementation progress

### 3.2 Comprehensive Testing Plan

#### Test Suite 1: Lake Brush
1. **Visual Consistency Test**
   - Create map with base layer water terrain (e.g., Coastal Plains)
   - Draw lake with brush next to base layer lake
   - Result: Should be **indistinguishable**

2. **Scale Test**
   - Create 3 maps: 5mi, 50mi, 500mi
   - Draw identical lake strokes on each
   - Verify elevation-based rendering adapts to scale
   - Beach widths should vary naturally based on elevation

3. **Edge Cases**
   - Very small lake (narrow brush width)
   - Very large lake (wide brush width)
   - Complex irregular shape
   - Verify no crashes, performance acceptable

#### Test Suite 2: River Brush
1. **Width Scaling Test**
   - Draw short river (100pt path length)
   - Draw medium river (1000pt path length)
   - Draw long river (10000pt path length)
   - Verify: Long river is visibly wider (up to 3× base width)

2. **Meandering Consistency Test**
   - Draw short meandering river
   - Draw long meandering river
   - Visual inspection: Both should meander equally
   - Measure meander amplitude relative to river width

3. **Valley Effect Test**
   - Draw major river (very long path)
   - Zoom out to see full extent
   - Verify valley visible: water → flood plain → sandy banks → grass
   - Valley should affect large area (500-1500pt wide)

4. **Scale Test**
   - Draw rivers on 5mi, 50mi, 500mi maps
   - Verify valley proportions appropriate for scale
   - Very large maps: valleys may cover significant map area

#### Test Suite 3: Cross-Platform
1. **macOS Test**
   - All tests above on macOS
   - Performance check (rendering time acceptable?)

2. **iOS Test** (if applicable)
   - All tests above on iOS
   - Touch interface works correctly
   - Performance check

### 3.3 Performance Testing
- **Baseline**: Time to draw lake/river stroke (before changes)
- **After ER-0007**: Time to draw lake/river stroke (after changes)
- **Acceptable**: < 2× baseline (generating elevation maps adds overhead)
- **If slow**: Consider caching elevation maps per brush stroke

### 3.4 Documentation Updates
- Update ER-0007 status to "Implemented - Not Verified"
- Add test results
- Create before/after comparison screenshots (if possible)
- Update DR-0032 status (already expanded to ER-0007)

### Estimated Time: 4-6 hours

---

## Risk Assessment

### High Risk Areas

1. **Performance**: Pixel-by-pixel rendering may be slow
   - **Mitigation**: Profile performance, add caching if needed
   - **Fallback**: Reduce image resolution for elevation maps

2. **Visual Artifacts**: Elevation map boundaries may create visible edges
   - **Mitigation**: Ensure smooth transitions at edges
   - **Fallback**: Add edge blending/smoothing

3. **Memory Usage**: Large elevation maps (1500×1500 pixels) consume memory
   - **Mitigation**: Use appropriate data types (Float32 vs Double)
   - **Fallback**: Implement streaming/tiled rendering

### Medium Risk Areas

1. **Meandering Algorithm**: Distance-based approach may have edge cases
   - **Mitigation**: Extensive testing with various path shapes
   - **Fallback**: Revert to hybrid approach (distance + smoothing)

2. **Valley Width**: Very wide valleys may overwhelm small maps
   - **Mitigation**: Cap valley width relative to map size
   - **Fallback**: Add user-configurable valley width multiplier

### Low Risk Areas

1. **Build Failures**: Code structure changes may break builds
   - **Mitigation**: Incremental testing, build after each phase
   - **Rollback**: Git version control for easy reversion

2. **Backward Compatibility**: Old brush strokes render differently
   - **Expected**: This is intentional (improvement)
   - **Mitigation**: Document visual changes clearly

---

## File Modification Summary

### Files to Modify

**BrushEngine.swift** (~300 lines changed total)
- Add helper functions:
  - `calculateBoundingBox(points:padding:)` (+10 lines)
  - `calculatePathLength(points:)` (+8 lines)
  - `calculatePerpendicular(at:points:)` (+15 lines)
  - `minimumDistance(from:to:)` (+20 lines)
  - `generateRiverValleyElevationMap()` (+80-100 lines)
- Rewrite functions:
  - `renderLakeBrush()` (~121 lines → ~150 lines)
  - `generateProceduralRiverPath()` (~40 lines → ~60 lines)
  - River rendering section in `renderWaterBrush()` (~134 lines → ~200 lines)

**ElevationMap.swift** (possibly)
- May need to add initializer for pre-computed elevation arrays
- May need helper for distance-to-path calculations
- Estimated: +30-50 lines if needed

**TerrainPattern.swift** (✅ already modified)
- Base layer thresholds standardized to 0.1

**ExteriorMapBrushSet.swift** (✅ already modified)
- Redundant brushes removed

### Lines of Code Estimate
- **Added**: ~400-500 lines
- **Modified**: ~300-400 lines
- **Removed**: ~350 lines (already done in ER-0005)
- **Net Change**: +350-550 lines

---

## Success Criteria

### Must Have (P0)
1. ✅ Base layer elevation threshold standardized to 0.1
2. ✅ Redundant brushes removed (Ocean, Sea, Stream, Waterfall)
3. ☐ Lake brush produces visually identical output to base layer lakes
4. ☐ River width scales with path length (logarithmic formula)
5. ☐ Rivers meander consistently regardless of length
6. ☐ River valleys visible with appropriate width (5-15× river width)
7. ☐ All builds succeed (macOS, iOS)
8. ☐ No crashes or errors during testing

### Should Have (P1)
9. ☐ Performance < 2× baseline rendering time
10. ☐ Elevation-based rendering works on all tested map scales (5mi, 50mi, 500mi)
11. ☐ Valley effect clearly visible for long rivers
12. ☐ Smooth transitions between elevation zones (no visible banding)

### Nice to Have (P2)
13. ☐ User-configurable valley width multipliers
14. ☐ Caching system for elevation maps (performance optimization)
15. ☐ Before/after comparison screenshots

---

## Approval Checklist

Before proceeding, user should confirm:

- [ ] **Lake rendering approach approved**: Generate elevation maps, use `elevation < 0.1` threshold
- [ ] **River width scaling approved**: `width * (1 + log10(pathLength/100))` formula
- [ ] **River meandering approved**: Distance-based sinusoidal pattern with fixed wavelength
- [ ] **River valley width approved**: 5-15× river width (adjustable if needed)
- [ ] **Elevation thresholds approved**: Water `< -0.2`, flood plain `< 0`, sand `< 0.15`, grass `> 0.15`
- [ ] **Implementation scope approved**: ~12-18 hours estimated development time
- [ ] **Risk mitigation strategies approved**: Performance profiling, caching fallbacks, etc.

---

## Next Steps After Approval

1. **Implement Phase 1** (Lake brush) - 4-6 hours
2. **Test & verify Phase 1** - 1-2 hours
3. **Get user feedback on Phase 1** before proceeding
4. **Implement Phase 2** (River brush) - 8-12 hours
5. **Test & verify Phase 2** - 2-3 hours
6. **Integration testing** - 1-2 hours
7. **Documentation & final review** - 1-2 hours

**Total Estimated Time**: 16-28 hours across 3-5 days

---

## Questions for User

1. Should I proceed with Phase 1 (Lake brush) immediately after approval?
2. Do you want to review/approve after Phase 1 before I start Phase 2?
3. Any adjustments to formulas or thresholds before I begin?
4. Any specific test cases or edge cases you want me to focus on?
5. Performance targets: What's acceptable rendering time per stroke?

---

**End of Implementation Plan**

**Status**: Awaiting user approval to proceed
