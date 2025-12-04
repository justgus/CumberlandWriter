//
//  ExteriorMapBrushSet.swift
//  Cumberland
//
//  Exterior/World Map Brush Set - Professional brushes for outdoor cartography
//

import SwiftUI
import Foundation

// MARK: - Exterior Map Brush Set

/// Creates the built-in brush set optimized for exterior/world maps
struct ExteriorMapBrushSet {
    
    /// Create the complete exterior map brush set
    static func create() -> BrushSet {
        var brushSet = BrushSet(
            name: "Exterior Maps",
            description: "Professional tools for outdoor maps with terrain, rivers, forests, and settlements",
            mapType: .exterior,
            brushes: [],
            defaultLayers: [
                .terrain,
                .water,
                .vegetation,
                .roads,
                .structures,
                .annotations
            ],
            author: "Cumberland",
            version: "1.0",
            isBuiltIn: true,
            isInstalled: true
        )
        
        // Add all brushes
        brushSet.brushes = [
            createBasicBrushes(),
            createTerrainBrushes(),
            createWaterBrushes(),
            createVegetationBrushes(),
            createRoadBrushes(),
            createStructureBrushes(),
            createBorderBrushes()
        ].flatMap { $0 }
        
        return brushSet
    }
    
    // MARK: - Basic Brushes
    
    private static func createBasicBrushes() -> [MapBrush] {
        return [
            MapBrush(
                name: "Pen",
                icon: "pencil",
                category: .basic,
                defaultWidth: 3.0,
                minWidth: 1.0,
                maxWidth: 10.0,
                patternType: .solid,
                smoothing: 0.3,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Fine Pen",
                icon: "pencil.line",
                category: .basic,
                defaultWidth: 1.5,
                minWidth: 0.5,
                maxWidth: 3.0,
                patternType: .solid,
                smoothing: 0.2,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Marker",
                icon: "highlighter",
                category: .basic,
                defaultWidth: 12.0,
                minWidth: 5.0,
                maxWidth: 30.0,
                opacity: 0.5,
                patternType: .solid,
                smoothing: 0.6,
                isBuiltIn: true
            )
        ]
    }
    
    // MARK: - Terrain Brushes
    
    private static func createTerrainBrushes() -> [MapBrush] {
        return [
            MapBrush(
                name: "Mountains",
                icon: "mountain.2.fill",
                category: .terrain,
                baseColor: Color(.sRGB, red: 0.4, green: 0.3, blue: 0.2),
                defaultWidth: 20.0,
                minWidth: 10.0,
                maxWidth: 50.0,
                opacity: 0.8,
                patternType: .stamp,
                spacing: 15.0,
                scatterAmount: 0.3,
                rotationVariation: 15.0,
                sizeVariation: 0.4,
                requiresLayer: .terrain,
                smoothing: 0.4,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Hills",
                icon: "mount.fill",
                category: .terrain,
                baseColor: Color(.sRGB, red: 0.5, green: 0.6, blue: 0.4),
                defaultWidth: 15.0,
                minWidth: 8.0,
                maxWidth: 35.0,
                opacity: 0.7,
                patternType: .stamp,
                spacing: 12.0,
                scatterAmount: 0.25,
                rotationVariation: 20.0,
                sizeVariation: 0.3,
                requiresLayer: .terrain,
                smoothing: 0.5,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Valley",
                icon: "triangle.fill",
                category: .terrain,
                baseColor: Color(.sRGB, red: 0.4, green: 0.5, blue: 0.3),
                defaultWidth: 18.0,
                minWidth: 10.0,
                maxWidth: 40.0,
                opacity: 0.6,
                patternType: .hatched,
                spacing: 8.0,
                requiresLayer: .terrain,
                smoothing: 0.6,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Plains",
                icon: "rectangle.fill",
                category: .terrain,
                baseColor: Color(.sRGB, red: 0.8, green: 0.85, blue: 0.6),
                defaultWidth: 25.0,
                minWidth: 15.0,
                maxWidth: 60.0,
                opacity: 0.4,
                patternType: .solid,
                requiresLayer: .terrain,
                smoothing: 0.8,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Desert",
                icon: "sun.max.fill",
                category: .terrain,
                baseColor: Color(.sRGB, red: 0.9, green: 0.8, blue: 0.5),
                defaultWidth: 20.0,
                minWidth: 10.0,
                maxWidth: 50.0,
                opacity: 0.5,
                patternType: .stippled,
                spacing: 3.0,
                scatterAmount: 0.6,
                requiresLayer: .terrain,
                smoothing: 0.7,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Tundra",
                icon: "snowflake",
                category: .terrain,
                baseColor: Color(.sRGB, red: 0.85, green: 0.9, blue: 0.95),
                defaultWidth: 18.0,
                minWidth: 10.0,
                maxWidth: 45.0,
                opacity: 0.5,
                patternType: .stippled,
                spacing: 5.0,
                scatterAmount: 0.4,
                requiresLayer: .terrain,
                smoothing: 0.6,
                isBuiltIn: true
            )
        ]
    }
    
    // MARK: - Water Feature Brushes
    
    private static func createWaterBrushes() -> [MapBrush] {
        return [
            MapBrush(
                name: "Ocean",
                icon: "water.waves",
                category: .water,
                baseColor: Color(.sRGB, red: 0.2, green: 0.4, blue: 0.7),
                defaultWidth: 30.0,
                minWidth: 20.0,
                maxWidth: 80.0,
                opacity: 0.6,
                patternType: .solid,
                requiresLayer: .water,
                smoothing: 0.8,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Sea",
                icon: "drop.fill",
                category: .water,
                baseColor: Color(.sRGB, red: 0.25, green: 0.45, blue: 0.75),
                defaultWidth: 25.0,
                minWidth: 15.0,
                maxWidth: 60.0,
                opacity: 0.65,
                patternType: .solid,
                requiresLayer: .water,
                smoothing: 0.8,
                isBuiltIn: true
            ),
            MapBrush(
                name: "River",
                icon: "arrow.down.forward.and.arrow.up.backward",
                category: .water,
                baseColor: Color(.sRGB, red: 0.3, green: 0.5, blue: 0.8),
                defaultWidth: 8.0,
                minWidth: 3.0,
                maxWidth: 20.0,
                opacity: 0.7,
                taperStart: true,
                taperEnd: true,
                patternType: .solid,
                requiresLayer: .water,
                smoothing: 0.9,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Stream",
                icon: "wind",
                category: .water,
                baseColor: Color(.sRGB, red: 0.35, green: 0.55, blue: 0.85),
                defaultWidth: 4.0,
                minWidth: 1.5,
                maxWidth: 8.0,
                opacity: 0.7,
                taperStart: true,
                taperEnd: true,
                patternType: .solid,
                requiresLayer: .water,
                smoothing: 0.85,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Lake",
                icon: "circle.fill",
                category: .water,
                baseColor: Color(.sRGB, red: 0.28, green: 0.48, blue: 0.78),
                defaultWidth: 20.0,
                minWidth: 10.0,
                maxWidth: 50.0,
                opacity: 0.65,
                patternType: .solid,
                requiresLayer: .water,
                smoothing: 0.9,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Marsh",
                icon: "aqi.medium",
                category: .water,
                baseColor: Color(.sRGB, red: 0.4, green: 0.5, blue: 0.4),
                defaultWidth: 15.0,
                minWidth: 8.0,
                maxWidth: 35.0,
                opacity: 0.6,
                patternType: .stippled,
                spacing: 4.0,
                scatterAmount: 0.5,
                requiresLayer: .water,
                smoothing: 0.7,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Waterfall",
                icon: "arrow.down.circle.fill",
                category: .water,
                baseColor: Color(.sRGB, red: 0.3, green: 0.6, blue: 0.9),
                defaultWidth: 10.0,
                minWidth: 5.0,
                maxWidth: 20.0,
                opacity: 0.8,
                patternType: .stamp,
                spacing: 15.0,
                requiresLayer: .water,
                isBuiltIn: true
            )
        ]
    }
    
    // MARK: - Vegetation Brushes
    
    private static func createVegetationBrushes() -> [MapBrush] {
        return [
            MapBrush(
                name: "Forest",
                icon: "tree.fill",
                category: .vegetation,
                baseColor: Color(.sRGB, red: 0.2, green: 0.6, blue: 0.3),
                defaultWidth: 15.0,
                minWidth: 8.0,
                maxWidth: 40.0,
                opacity: 0.7,
                patternType: .stamp,
                spacing: 8.0,
                scatterAmount: 0.4,
                rotationVariation: 360.0,
                sizeVariation: 0.3,
                requiresLayer: .vegetation,
                smoothing: 0.5,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Single Tree",
                icon: "tree",
                category: .vegetation,
                baseColor: Color(.sRGB, red: 0.25, green: 0.65, blue: 0.35),
                defaultWidth: 12.0,
                minWidth: 6.0,
                maxWidth: 25.0,
                opacity: 0.8,
                patternType: .stamp,
                spacing: 20.0,
                rotationVariation: 360.0,
                sizeVariation: 0.25,
                requiresLayer: .vegetation,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Jungle",
                icon: "leaf.fill",
                category: .vegetation,
                baseColor: Color(.sRGB, red: 0.15, green: 0.55, blue: 0.25),
                defaultWidth: 18.0,
                minWidth: 10.0,
                maxWidth: 45.0,
                opacity: 0.75,
                patternType: .stamp,
                spacing: 6.0,
                scatterAmount: 0.6,
                rotationVariation: 360.0,
                sizeVariation: 0.4,
                requiresLayer: .vegetation,
                smoothing: 0.6,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Grassland",
                icon: "leaf",
                category: .vegetation,
                baseColor: Color(.sRGB, red: 0.5, green: 0.7, blue: 0.4),
                defaultWidth: 20.0,
                minWidth: 10.0,
                maxWidth: 50.0,
                opacity: 0.5,
                patternType: .stippled,
                spacing: 2.0,
                scatterAmount: 0.7,
                requiresLayer: .vegetation,
                smoothing: 0.7,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Farmland",
                icon: "square.grid.3x2.fill",
                category: .vegetation,
                baseColor: Color(.sRGB, red: 0.7, green: 0.75, blue: 0.5),
                defaultWidth: 15.0,
                minWidth: 8.0,
                maxWidth: 35.0,
                opacity: 0.6,
                patternType: .hatched,
                spacing: 5.0,
                requiresLayer: .vegetation,
                snapToGrid: true,
                smoothing: 0.3,
                isBuiltIn: true
            )
        ]
    }
    
    // MARK: - Road & Path Brushes
    
    private static func createRoadBrushes() -> [MapBrush] {
        return [
            MapBrush(
                name: "Highway",
                icon: "road.lanes",
                category: .roads,
                baseColor: Color(.sRGB, red: 0.3, green: 0.3, blue: 0.3),
                defaultWidth: 12.0,
                minWidth: 8.0,
                maxWidth: 25.0,
                opacity: 0.9,
                patternType: .solid,
                requiresLayer: .roads,
                smoothing: 0.7,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Road",
                icon: "rectangle.portrait.fill",
                category: .roads,
                baseColor: Color(.sRGB, red: 0.4, green: 0.4, blue: 0.4),
                defaultWidth: 7.0,
                minWidth: 4.0,
                maxWidth: 15.0,
                opacity: 0.85,
                patternType: .solid,
                requiresLayer: .roads,
                smoothing: 0.6,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Path",
                icon: "point.topleft.down.curvedto.point.bottomright.up.fill",
                category: .roads,
                baseColor: Color(.sRGB, red: 0.5, green: 0.4, blue: 0.3),
                defaultWidth: 4.0,
                minWidth: 2.0,
                maxWidth: 8.0,
                opacity: 0.8,
                patternType: .dashed,
                spacing: 4.0,
                requiresLayer: .roads,
                smoothing: 0.5,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Trail",
                icon: "footprints",
                category: .roads,
                baseColor: Color(.sRGB, red: 0.6, green: 0.5, blue: 0.4),
                defaultWidth: 2.5,
                minWidth: 1.5,
                maxWidth: 5.0,
                opacity: 0.7,
                patternType: .dotted,
                spacing: 3.0,
                requiresLayer: .roads,
                smoothing: 0.4,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Railroad",
                icon: "train.side.front.car",
                category: .roads,
                baseColor: Color(.sRGB, red: 0.2, green: 0.2, blue: 0.2),
                defaultWidth: 5.0,
                minWidth: 3.0,
                maxWidth: 10.0,
                opacity: 0.9,
                patternType: .dashed,
                spacing: 8.0,
                requiresLayer: .roads,
                smoothing: 0.8,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Bridge",
                icon: "point.topleft.down.curvedto.point.bottomright.up",
                category: .roads,
                baseColor: Color(.sRGB, red: 0.5, green: 0.4, blue: 0.3),
                defaultWidth: 8.0,
                minWidth: 5.0,
                maxWidth: 15.0,
                opacity: 0.85,
                patternType: .solid,
                requiresLayer: .roads,
                smoothing: 0.7,
                isBuiltIn: true
            )
        ]
    }
    
    // MARK: - Structure Brushes
    
    private static func createStructureBrushes() -> [MapBrush] {
        return [
            MapBrush(
                name: "City",
                icon: "building.2.fill",
                category: .structures,
                baseColor: Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6),
                defaultWidth: 25.0,
                minWidth: 15.0,
                maxWidth: 50.0,
                opacity: 0.8,
                patternType: .stamp,
                spacing: 5.0,
                scatterAmount: 0.2,
                requiresLayer: .structures,
                snapToGrid: true,
                smoothing: 0.3,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Town",
                icon: "building.fill",
                category: .structures,
                baseColor: Color(.sRGB, red: 0.65, green: 0.6, blue: 0.55),
                defaultWidth: 18.0,
                minWidth: 10.0,
                maxWidth: 35.0,
                opacity: 0.8,
                patternType: .stamp,
                spacing: 6.0,
                scatterAmount: 0.25,
                requiresLayer: .structures,
                snapToGrid: true,
                smoothing: 0.3,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Village",
                icon: "house.fill",
                category: .structures,
                baseColor: Color(.sRGB, red: 0.7, green: 0.65, blue: 0.6),
                defaultWidth: 12.0,
                minWidth: 8.0,
                maxWidth: 25.0,
                opacity: 0.8,
                patternType: .stamp,
                spacing: 8.0,
                scatterAmount: 0.3,
                requiresLayer: .structures,
                snapToGrid: true,
                smoothing: 0.3,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Building",
                icon: "square.fill",
                category: .structures,
                baseColor: Color(.sRGB, red: 0.6, green: 0.55, blue: 0.5),
                defaultWidth: 8.0,
                minWidth: 4.0,
                maxWidth: 18.0,
                opacity: 0.85,
                patternType: .stamp,
                spacing: 15.0,
                requiresLayer: .structures,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Castle",
                icon: "sparkles.rectangle.stack.fill",
                category: .structures,
                baseColor: Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5),
                defaultWidth: 20.0,
                minWidth: 12.0,
                maxWidth: 40.0,
                opacity: 0.9,
                patternType: .stamp,
                spacing: 30.0,
                requiresLayer: .structures,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Tower",
                icon: "circle.fill",
                category: .structures,
                baseColor: Color(.sRGB, red: 0.55, green: 0.5, blue: 0.45),
                defaultWidth: 10.0,
                minWidth: 5.0,
                maxWidth: 20.0,
                opacity: 0.85,
                patternType: .stamp,
                spacing: 20.0,
                requiresLayer: .structures,
                snapToGrid: true,
                isBuiltIn: true
            )
        ]
    }
    
    // MARK: - Coastline & Border Brushes
    
    private static func createBorderBrushes() -> [MapBrush] {
        return [
            MapBrush(
                name: "Coastline",
                icon: "water.waves.and.arrow.down",
                category: .terrain,
                baseColor: Color(.sRGB, red: 0.4, green: 0.4, blue: 0.3),
                defaultWidth: 4.0,
                minWidth: 2.0,
                maxWidth: 8.0,
                opacity: 0.7,
                patternType: .solid,
                spacing: 2.0,
                scatterAmount: 0.8,
                rotationVariation: 10.0,
                sizeVariation: 0.3,
                requiresLayer: .terrain,
                smoothing: 0.3,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Border",
                icon: "rectangle.dashed",
                category: .symbols,
                baseColor: Color(.sRGB, red: 0.8, green: 0.2, blue: 0.2),
                defaultWidth: 3.0,
                minWidth: 1.5,
                maxWidth: 6.0,
                opacity: 0.8,
                patternType: .dashed,
                spacing: 6.0,
                scatterAmount: 0.6,
                rotationVariation: 15.0,
                smoothing: 0.4,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Cliff",
                icon: "arrow.down.right",
                category: .terrain,
                baseColor: Color(.sRGB, red: 0.3, green: 0.25, blue: 0.2),
                defaultWidth: 6.0,
                minWidth: 3.0,
                maxWidth: 12.0,
                opacity: 0.8,
                patternType: .hatched,
                spacing: 3.0,
                scatterAmount: 0.7,
                rotationVariation: 20.0,
                sizeVariation: 0.4,
                requiresLayer: .terrain,
                smoothing: 0.3,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Mountain Ridge",
                icon: "triangle",
                category: .terrain,
                baseColor: Color(.sRGB, red: 0.35, green: 0.3, blue: 0.25),
                defaultWidth: 5.0,
                minWidth: 2.5,
                maxWidth: 10.0,
                opacity: 0.85,
                patternType: .solid,
                spacing: 2.5,
                scatterAmount: 0.7,
                rotationVariation: 25.0,
                sizeVariation: 0.35,
                requiresLayer: .terrain,
                smoothing: 0.2,
                isBuiltIn: true
            )
        ]
    }
}

// MARK: - Brush Registry Extension

extension BrushRegistry {
    /// Create and install the exterior map brush set
    func installExteriorBrushSet() {
        let exteriorSet = ExteriorMapBrushSet.create()
        
        // Only install if not already present
        if !installedBrushSets.contains(where: { $0.name == exteriorSet.name }) {
            installedBrushSets.append(exteriorSet)
        }
    }
    
    /// Get the exterior brush set ID
    var exteriorBrushSetID: UUID? {
        installedBrushSets.first { $0.mapType == .exterior && $0.isBuiltIn }?.id
    }
}
