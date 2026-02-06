# Terrain Generation System - Design & Mathematics

## Overview

The terrain generation system creates realistic elevation-based maps with water percentage control and world-scale elevation mapping. This document explains the complete mathematical model and implementation.

---

## Core Concepts

### 1. Local Elevation (-1.0 to 1.0)

The elevation map represents **local terrain variance** within THIS specific map:

- **`-1.0`**: Deepest point in this map (maximum underwater depth)
- **`0.0`**: Sea level / water table
- **`1.0`**: Highest peak in this map

**Key Insight**: These values are relative to THIS map only, not absolute world elevations.

### 2. World Elevation Scaling

Local elevation is converted to real-world elevation using a scale constant:

```
worldElevation (miles) = localElevation × scaleConstant
```

**Scale Constants by Map Size:**

| Map Size (sq mi) | Scale Name | Scale Constant | Range (miles) |
|------------------|------------|----------------|---------------|
| ≥ 1000 | Continental | 6.0 | ±6 mi |
| 100-1000 | State/Regional | Parabolic 1.0→6.0 | ±1 to ±6 mi |
| 1-100 | Small/Local | Parabolic 0.0→1.0 | 0 to ±1 mi |

**Parabolic Scaling Formulas:**

```swift
// State scale (100-1000 sq mi)
let t = (sqMiles - 100) / 900  // Normalize to [0,1]
scaleConstant = 1.0 + 5.0 * t * t  // Quadratic easing

// Small scale (1-100 sq mi)
let t = (sqMiles - 1) / 99
scaleConstant = 1.0 * t * t
```

**Examples:**
- **Continental (2000 sq mi)**: localElev = 0.5 → worldElev = 0.5 × 6.0 = **3.0 miles** above sea level
- **State (500 sq mi)**: localElev = -0.3 → worldElev = -0.3 × 3.56 = **-1.07 miles** below sea level
- **Village (10 sq mi)**: localElev = 1.0 → worldElev = 1.0 × 0.01 = **0.01 miles** (53 feet) above sea level

---

## Water Percentage System

### Concept

Base layer type determines what percentage of the terrain should be underwater (negative elevations).

### Water Percentages by Terrain Type

| Terrain Type | Water % | Description |
|--------------|---------|-------------|
| Sandy | 2% | Desert/beach - minimal water |
| Rocky | 5% | Badlands - scattered water sources |
| Mountain | 7% | Mountain ranges - alpine lakes |
| Snow | 15% | Tundra/glacial - meltwater features |
| Land | 40% | Grasslands/plains - rivers, ponds |
| Forested | 60% | Forest/jungle - abundant waterways |
| Ice | 66% | Arctic/ice sheets - ice-covered water |
| Water | 90% | Ocean/archipelago - dominant water |

### Mathematical Implementation

**Goal**: Shift elevation distribution so that X% of pixels have elevation < 0.

**Algorithm:**

1. **Generate Raw Fractal Noise**
   ```swift
   elevation = fractalNoise2D(x, y, octaves: 6, persistence: 0.5)
   // Returns values roughly in [-1, 1] with normal distribution
   ```

2. **Remap to Full Range**
   ```swift
   // Stretch actual [min, max] to [-1, 1]
   remapped = 2.0 * (elevation - min) / (max - min) - 1.0
   ```

3. **Calculate Target Percentile**
   ```swift
   // Sort all elevations
   sorted = elevations.sorted()

   // Find value at Nth percentile
   index = Int(waterPercentage × count)
   percentileValue = sorted[index]
   ```

4. **Shift Distribution**
   ```swift
   // Shift so percentile value becomes 0.0 (sea level)
   shift = -percentileValue
   adjusted = (elevation + shift).clamped(to: -1...1)
   ```

### Example: Water Type (90% water)

Given 100,000 elevation samples from fractal noise:

1. Raw noise generates values roughly -0.8 to 0.8 (normal distribution)
2. Remap to full -1.0 to 1.0 range
3. Sort elevations and find 90th percentile → value = **0.6**
4. Shift all values down by 0.6:
   - Old percentile value 0.6 → new value 0.0 (sea level)
   - All values below old 0.6 are now negative (underwater)
   - Result: ~90% of terrain is underwater

**Verification:**
```
[ElevationMap] Final elevations:
  - Min: -1.000
  - Max: 0.400
  - Avg: -0.320
  - Water: 90.1% (target: 90%)
```

---

## Color System

### Mean Colors by Terrain Type

Each terrain type has a characteristic mean color:

| Type | Mean Color (RGB) | Description |
|------|------------------|-------------|
| Sandy | (0.90, 0.75, 0.50) | Tan/beige |
| Rocky | (0.35, 0.25, 0.20) | Dark brown |
| Mountain | (0.30, 0.25, 0.20) | Darker brown |
| Snow | (0.95, 0.95, 0.95) | White/grey |
| Land | (0.45, 0.70, 0.30) | Green |
| Forested | (0.20, 0.50, 0.15) | Dark green |
| Ice | (0.70, 0.85, 0.95) | Light blue |
| Water | (0.20, 0.50, 0.80) | Medium blue (for islands) |

### Water Color (Depth-Based)

Water uses HSB color space for depth variation:

```swift
hue = 0.55  // Blue (constant)
saturation = 0.70  // Constant

// Depth affects brightness
depth = -elevation  // Convert negative to positive (0.0 to 1.0)
brightness = 0.7 - (depth × 0.4)  // 0.7 (shallow) to 0.3 (deep)

// Add noise texture
brightness = brightness × (1.0 + noise × 0.05)
finalBrightness = brightness.clamped(to: 0.2...0.8)
```

**Water Depth Examples:**
- **Shallow** (elev = -0.1): brightness = 0.66 → Light blue
- **Medium** (elev = -0.5): brightness = 0.50 → Medium blue
- **Deep** (elev = -1.0): brightness = 0.30 → Dark blue

### Land Color (Elevation-Based)

Land uses brightness variation on the mean color:

```swift
// Elevation 0.0 (sea level) to 1.0 (peak)
elevationBrightness = 0.85 + (elevation × 0.30)  // 0.85 to 1.15

// Add noise texture
noiseBrightness = 1.0 + (noise × 0.05)  // 0.95 to 1.05

totalBrightness = elevationBrightness × noiseBrightness
```

**Land Elevation Examples:**
- **Sea Level** (elev = 0.0): brightness = 0.85 → Darker
- **Mid-Elevation** (elev = 0.5): brightness = 1.0 → Mean color
- **Peak** (elev = 1.0): brightness = 1.15 → Lighter

---

## Complete Rendering Pipeline

### Step-by-Step Process

1. **Initialize**
   ```swift
   let waterPct = terrainType.waterPercentage  // e.g., 0.90 for Water
   let worldScale = calculateWorldScale(sqMiles)  // e.g., 6.0 for continental
   let meanColor = meanColorFor(terrainType)  // e.g., green for Land
   ```

2. **Generate Elevation Map**
   ```swift
   elevationMap = ElevationMap(
       width: 512,
       height: 512,
       seed: terrainSeed,
       waterPercentage: waterPct  // Apply skewing
   )
   ```

3. **For Each Pixel**
   ```swift
   let elevation = elevationMap.elevationInterpolated(at: point)  // -1 to 1
   let noise = textureNoise.noise2D(x, y)  // -1 to 1

   if elevation < 0 {
       // Underwater
       color = colorForWater(depth: -elevation, noise: noise)
   } else {
       // Land
       color = colorForLand(
           baseColor: meanColor,
           elevation: elevation,
           noise: noise
       )
   }
   ```

4. **Render**
   ```swift
   context.setFillColor(color.cgColor)
   context.fill(rect)
   ```

---

## Performance Characteristics

### Memory Usage

- **Elevation Map**: 512×512 × 8 bytes = **2 MB** per map
- **Rendered Terrain**: 2048×2048 × 4 bytes = **16 MB** per cached image

### Generation Time

- **Fractal Noise**: ~50ms for 512×512
- **Sorting for Percentile**: ~10ms for 262,144 samples
- **Rendering**: ~500ms for 2048×2048 (1M pixels)
- **Total First Render**: ~560ms
- **Subsequent Renders**: <1ms (cached)

### Scaling

| Canvas Size | Elevation Res | Samples | Gen Time |
|-------------|---------------|---------|----------|
| 512×512 | 512×512 | 262K | ~300ms |
| 1024×1024 | 512×512 | 262K | ~500ms |
| 2048×2048 | 512×512 | 262K | ~900ms |
| 4096×4096 | 512×512 | 262K | ~2000ms |

*Note: Elevation resolution capped at 512×512 for memory efficiency*

---

## Verification & Testing

### Expected Results by Terrain Type

**Sandy (2% water)**
- Water: ~2%
- Land (tan): ~98%
- Visual: Desert with rare oases

**Land (40% water)**
- Water: ~40%
- Land (green): ~60%
- Visual: Plains with rivers, lakes

**Water (90% water)**
- Water: ~90%
- Land (green islands): ~10%
- Visual: Ocean with archipelago

### Debug Output Example

```
[ElevationMap] Generated 512×512 elevations (raw fractal noise):
  - Min: -0.823
  - Max: 0.781
[ElevationMap] Remapped to full -1.0 to 1.0 range
[ElevationMap] Applied water skewing: target=90%, shift=-0.622
[ElevationMap] Final elevations:
  - Min: -1.000
  - Max: 0.378
  - Avg: -0.298
  - Water: 89.8% (target: 90%)

[TerrainPattern] World elevation scale: ±6.00 miles
[TerrainPattern] Rendering complete:
  - Water: 234,567 pixels (89.8%)
  - Land: 26,657 pixels (10.2%)
```

---

## Design Decisions & Rationale

### Why -1 to 1 Range?

- **Intuitive**: 0 = sea level, negative = underwater, positive = above water
- **Symmetric**: Equal range for depths and heights
- **Flexible**: Easy to scale to world elevations

### Why Percentile-Based Skewing?

- **Precise Control**: Achieves exact target percentages
- **Distribution-Independent**: Works with any noise distribution
- **Predictable**: Deterministic results for same seed

### Why Parabolic Scaling?

- **Smooth Transitions**: Gradual change between scale categories
- **Physical Realism**: Small maps have minimal elevation variance
- **User Expectations**: Aligns with mental model of map scales

### Why Separate Water/Land Colors?

- **Realism**: Water depth affects color differently than land elevation
- **Flexibility**: Independent control of water and terrain appearance
- **Performance**: Simple branch, no complex biome logic

---

## Future Enhancements

Potential improvements to consider:

1. **Erosion Simulation**: Modify elevation based on water flow
2. **Temperature/Latitude**: Affect colors based on map position
3. **Seasonal Variation**: Different colors for seasons
4. **Custom Color Palettes**: User-defined color schemes
5. **Export Heightmap**: Save elevation data for external tools
6. **Real-Time Preview**: Show water% slider effect instantly

---

*Document Version: 1.0*
*Last Updated: 2025-12-31*
*System: Cumberland Terrain Generation v2.0*
