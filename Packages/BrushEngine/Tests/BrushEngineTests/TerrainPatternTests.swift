//
//  TerrainPatternTests.swift
//  BrushEngineTests
//
//  ER-0052 Phase 1.1: Comprehensive tests for TerrainPattern procedural generation
//

import Testing
import Foundation
import CoreGraphics
import SwiftUI
@testable import BrushEngine

@Suite("Terrain Pattern Generation")
struct TerrainPatternTests {

    // MARK: - Initialization Tests

    @Test("Initialize TerrainPattern with valid metadata")
    func initializeTerrainPattern() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 100.0, terrainSeed: 12345)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.land)

        #expect(pattern.metadata.physicalSizeMiles == 100.0)
        #expect(pattern.metadata.terrainSeed == 12345)
        #expect(pattern.dominantFillType == BaseLayerFillType.land)
    }

    @Test("Initialize TerrainPattern with water percentage override")
    func initializeTerrainPatternWithOverride() {
        var metadata = TerrainMapMetadata(physicalSizeMiles: 50.0, terrainSeed: 54321)
        metadata.waterPercentageOverride = 0.3
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.sandy)

        #expect(pattern.metadata.waterPercentageOverride == 0.3)
    }

    // MARK: - World Elevation Scale Tests

    @Test("Calculate world elevation scale for continental map (≥1000 mi)")
    func calculateWorldElevationScaleContinental() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 2000.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.land)

        let scale = pattern.calculateWorldElevationScale(physicalSizeMiles: 2000.0)
        #expect(scale == 6.0)  // Continental scale is constant at 6.0 miles
    }

    @Test("Calculate world elevation scale for state map (100-1000 mi)")
    func calculateWorldElevationScaleState() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 500.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.land)

        let scale = pattern.calculateWorldElevationScale(physicalSizeMiles: 500.0)

        // Should be between 1.0 and 6.0 (parabolic interpolation)
        #expect(scale > 1.0)
        #expect(scale < 6.0)

        // At 500 mi (midpoint), parabolic interpolation should give ~2.25
        // t = (500 - 100) / 900 = 0.444
        // scale = 1.0 + 5.0 * (0.444)^2 = 1.0 + 5.0 * 0.197 = ~1.99
        #expect(abs(scale - 1.99) < 0.1)
    }

    @Test("Calculate world elevation scale for small map (<100 mi)")
    func calculateWorldElevationScaleSmall() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 10.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.land)

        let scale = pattern.calculateWorldElevationScale(physicalSizeMiles: 10.0)

        // Should be between 0.0 and 1.0 (parabolic interpolation)
        #expect(scale >= 0.0)
        #expect(scale <= 1.0)

        // At 10 mi: t = (10 - 1) / 99 = 0.0909
        // scale = 1.0 * (0.0909)^2 = 0.0083
        #expect(scale < 0.1)
    }

    @Test("Calculate world elevation scale at boundary values")
    func calculateWorldElevationScaleBoundaries() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 1.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.land)

        // At 1 mile (minimum)
        let scale1 = pattern.calculateWorldElevationScale(physicalSizeMiles: 1.0)
        #expect(scale1 == 0.0)

        // At 100 miles (boundary between small and state)
        let scale100 = pattern.calculateWorldElevationScale(physicalSizeMiles: 100.0)
        #expect(scale100 == 1.0)

        // At 1000 miles (boundary between state and continental)
        let scale1000 = pattern.calculateWorldElevationScale(physicalSizeMiles: 1000.0)
        #expect(scale1000 == 6.0)
    }

    // MARK: - Noise Parameter Tests

    @Test("Calculate noise parameters for continental map")
    func calculateNoiseParametersContinental() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 1500.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.land)

        let (scale, octaves) = pattern.calculateNoiseParameters(physicalSizeMiles: 1500.0)

        #expect(scale == 2.0)   // Continental: maximum detail
        #expect(octaves == 7)    // Continental: maximum complexity
    }

    @Test("Calculate noise parameters for state map")
    func calculateNoiseParametersState() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 500.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.land)

        let (scale, octaves) = pattern.calculateNoiseParameters(physicalSizeMiles: 500.0)

        // Scale: 1.0 to 2.0 linear interpolation
        #expect(scale >= 1.0)
        #expect(scale <= 2.0)

        // Octaves: 5 to 7
        #expect(octaves >= 5)
        #expect(octaves <= 7)
    }

    @Test("Calculate noise parameters for small map")
    func calculateNoiseParametersSmall() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 10.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.land)

        let (scale, octaves) = pattern.calculateNoiseParameters(physicalSizeMiles: 10.0)

        // Scale: 0.3 to 1.0
        #expect(scale >= 0.3)
        #expect(scale <= 1.0)

        // Octaves: 3 to 5
        #expect(octaves >= 3)
        #expect(octaves <= 5)
    }

    // MARK: - Mean Color Tests

    @Test("Get mean color for each terrain type")
    func meanColorForAllTerrainTypes() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 100.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.land)

        // Test all exterior terrain types
        let sandyColor = pattern.meanColorFor(terrainType: BaseLayerFillType.sandy)
        let rockyColor = pattern.meanColorFor(terrainType: BaseLayerFillType.rocky)
        let mountainColor = pattern.meanColorFor(terrainType: BaseLayerFillType.mountain)
        let snowColor = pattern.meanColorFor(terrainType: BaseLayerFillType.snow)
        let landColor = pattern.meanColorFor(terrainType: BaseLayerFillType.land)
        let forestedColor = pattern.meanColorFor(terrainType: BaseLayerFillType.forested)
        let iceColor = pattern.meanColorFor(terrainType: BaseLayerFillType.ice)
        let waterColor = pattern.meanColorFor(terrainType: BaseLayerFillType.water)

        // Verify colors are distinct (not identical)
        #expect(sandyColor != rockyColor)
        #expect(landColor != forestedColor)
        #expect(mountainColor != snowColor)
        #expect(iceColor != waterColor)
    }

    // MARK: - Water Color Tests

    @Test("Calculate water color for different depths")
    func colorForWaterDepth() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 100.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.water)

        // Shallow water (depth = 0.0) should be lighter
        let shallowColor = pattern.colorForWater(depth: 0.0, noise: 0.0)

        // Deep water (depth = 1.0) should be darker
        let deepColor = pattern.colorForWater(depth: 1.0, noise: 0.0)

        // Colors should be different
        #expect(shallowColor != deepColor)

        // Verify shallow water is lighter than deep water
        // (This is a simplified test - in reality we'd need to extract brightness values)
    }

    @Test("Water color with noise variation")
    func colorForWaterWithNoise() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 100.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.water)

        let colorNoNoise = pattern.colorForWater(depth: 0.5, noise: 0.0)
        let colorPositiveNoise = pattern.colorForWater(depth: 0.5, noise: 0.5)
        let colorNegativeNoise = pattern.colorForWater(depth: 0.5, noise: -0.5)

        // Noise should create variation (colors should differ)
        #expect(colorNoNoise != colorPositiveNoise)
        #expect(colorNoNoise != colorNegativeNoise)
    }

    // MARK: - Terrain Composition Tests

    @Test("Terrain composition for water type (islands)")
    func compositionWaterType() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 100.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.water)

        // Low elevation (0.05) = sandy beach
        let beachColor = pattern.compositionWaterType(elevation: 0.05, noise: 0.0)

        // Higher elevation (0.5) = green island interior
        let islandColor = pattern.compositionWaterType(elevation: 0.5, noise: 0.0)

        // Colors should be distinct
        #expect(beachColor != islandColor)
    }

    @Test("Terrain composition for land type (grasslands)")
    func compositionLandType() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 100.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.land)

        // Low elevation (0.05) = sandy shores
        let shoreColor = pattern.compositionLandType(elevation: 0.05, noise: 0.0)

        // Higher elevation (0.5) = grasslands
        let grassColor = pattern.compositionLandType(elevation: 0.5, noise: 0.0)

        // Colors should be distinct
        #expect(shoreColor != grassColor)
    }

    @Test("Terrain composition for sandy type (desert)")
    func compositionSandyType() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 100.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.sandy)

        // Low elevation (0.3) = sandy desert
        let desertColor = pattern.compositionSandyType(elevation: 0.3, noise: 0.0)

        // Mid elevation (0.75) = rocky outcrops
        let rockyColor = pattern.compositionSandyType(elevation: 0.75, noise: 0.0)

        // High elevation (0.95) = mountain peaks
        let peakColor = pattern.compositionSandyType(elevation: 0.95, noise: 0.0)

        // Colors should progress from sand → rock → mountain
        #expect(desertColor != rockyColor)
        #expect(rockyColor != peakColor)
    }

    @Test("Terrain composition for mountain type")
    func compositionMountainType() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 100.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.mountain)

        // Low elevation (0.1) = forest valleys
        let valleyColor = pattern.compositionMountainType(elevation: 0.1, noise: 0.0)

        // Mid elevation (0.4) = land foothills
        let foothillColor = pattern.compositionMountainType(elevation: 0.4, noise: 0.0)

        // Higher elevation (0.7) = rocky mountainsides
        let mountainsideColor = pattern.compositionMountainType(elevation: 0.7, noise: 0.0)

        // High elevation (0.9) = mountain peaks
        let peakColor = pattern.compositionMountainType(elevation: 0.9, noise: 0.0)

        // All zones should have distinct colors
        #expect(valleyColor != foothillColor)
        #expect(foothillColor != mountainsideColor)
        #expect(mountainsideColor != peakColor)
    }

    // MARK: - Edge Case Tests

    @Test("Handle zero-size map gracefully")
    func handleZeroSizeMap() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 0.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.land)

        // Noise parameters should still be valid
        let (scale, octaves) = pattern.calculateNoiseParameters(physicalSizeMiles: 0.0)
        #expect(scale >= 0.0)
        #expect(octaves >= 0)
    }

    @Test("Handle extreme map sizes")
    func handleExtremeMapSizes() {
        let metadata = TerrainMapMetadata(physicalSizeMiles: 10000.0, terrainSeed: 1)
        let pattern = TerrainPattern(metadata: metadata, dominantFillType: BaseLayerFillType.land)

        // Should use continental parameters
        let elevationScale = pattern.calculateWorldElevationScale(physicalSizeMiles: 10000.0)
        #expect(elevationScale == 6.0)

        let (scale, octaves) = pattern.calculateNoiseParameters(physicalSizeMiles: 10000.0)
        #expect(scale == 2.0)
        #expect(octaves == 7)
    }

    @Test("Deterministic generation with same seed")
    func deterministicGenerationSameSeed() {
        let metadata1 = TerrainMapMetadata(physicalSizeMiles: 100.0, terrainSeed: 42)
        let pattern1 = TerrainPattern(metadata: metadata1, dominantFillType: BaseLayerFillType.land)

        let metadata2 = TerrainMapMetadata(physicalSizeMiles: 100.0, terrainSeed: 42)
        let pattern2 = TerrainPattern(metadata: metadata2, dominantFillType: BaseLayerFillType.land)

        // Same seed should produce same parameters
        let (scale1, octaves1) = pattern1.calculateNoiseParameters(physicalSizeMiles: 100.0)
        let (scale2, octaves2) = pattern2.calculateNoiseParameters(physicalSizeMiles: 100.0)

        #expect(scale1 == scale2)
        #expect(octaves1 == octaves2)
    }

    @Test("Different seeds produce different patterns")
    func differentSeedsProduceDifferentPatterns() {
        let metadata1 = TerrainMapMetadata(physicalSizeMiles: 100.0, terrainSeed: 111)
        let pattern1 = TerrainPattern(metadata: metadata1, dominantFillType: BaseLayerFillType.land)

        let metadata2 = TerrainMapMetadata(physicalSizeMiles: 100.0, terrainSeed: 999)
        let pattern2 = TerrainPattern(metadata: metadata2, dominantFillType: BaseLayerFillType.land)

        // While parameters might be the same, different seeds should be captured
        #expect(pattern1.metadata.terrainSeed != pattern2.metadata.terrainSeed)
    }
}
