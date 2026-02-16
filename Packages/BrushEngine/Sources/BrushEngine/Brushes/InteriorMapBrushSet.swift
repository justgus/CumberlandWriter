//
//  InteriorMapBrushSet.swift
//  BrushEngine
//
//  Interior/Architectural Brush Set - Professional brushes for indoor maps and floor plans
//

import SwiftUI
import Foundation

// MARK: - Interior Map Brush Set

/// Creates the built-in brush set optimized for interior/architectural maps
public struct InteriorMapBrushSet {

    /// Create the complete interior map brush set
    public static func create() -> BrushSet {
        var brushSet = BrushSet(
            name: "Interior & Architectural",
            description: "Professional tools for indoor maps, floor plans, dungeons, and architectural layouts",
            mapType: .interior,
            brushes: [],
            defaultLayers: [
                .terrain,      // Base floor
                .walls,
                .structures,   // Doors & windows
                .furniture,
                .features,
                .annotations,
                .reference     // Grid overlay
            ],
            author: "Cumberland",
            version: "1.0",
            isBuiltIn: true,
            isInstalled: true
        )
        
        // Add all brushes
        brushSet.brushes = [
            createArchitecturalBrushes(),
            createDoorWindowBrushes(),
            createRoomFeatureBrushes(),
            createFurnitureBrushes(),
            createDungeonBrushes(),
            createGridBrushes()
        ].flatMap { $0 }
        
        return brushSet
    }
    
    // MARK: - Architectural Element Brushes
    
    private static func createArchitecturalBrushes() -> [MapBrush] {
        return [
            MapBrush(
                name: "Wall",
                icon: "rectangle.portrait.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.2, green: 0.2, blue: 0.2),
                defaultWidth: 8.0,
                minWidth: 4.0,
                maxWidth: 16.0,
                opacity: 1.0,
                patternType: .solid,
                requiresLayer: .walls,
                snapToGrid: true,
                smoothing: 0.1,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Thick Wall",
                icon: "rectangle.portrait.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.15, green: 0.15, blue: 0.15),
                defaultWidth: 14.0,
                minWidth: 10.0,
                maxWidth: 24.0,
                opacity: 1.0,
                patternType: .solid,
                requiresLayer: .walls,
                snapToGrid: true,
                smoothing: 0.1,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Thin Wall",
                icon: "rectangle.portrait",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.25, green: 0.25, blue: 0.25),
                defaultWidth: 4.0,
                minWidth: 2.0,
                maxWidth: 8.0,
                opacity: 1.0,
                patternType: .solid,
                requiresLayer: .walls,
                snapToGrid: true,
                smoothing: 0.1,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Cave Wall",
                icon: "moon.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.3, green: 0.25, blue: 0.2),
                defaultWidth: 12.0,
                minWidth: 8.0,
                maxWidth: 20.0,
                opacity: 0.85,
                patternType: .solid,
                spacing: 1.0,
                scatterAmount: 0.8,
                rotationVariation: 5.0,
                requiresLayer: .walls,
                smoothing: 0.4,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Column",
                icon: "circle.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.4, green: 0.4, blue: 0.4),
                defaultWidth: 10.0,
                minWidth: 5.0,
                maxWidth: 20.0,
                opacity: 0.9,
                patternType: .stamp,
                spacing: 20.0,
                requiresLayer: .features,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Pillar",
                icon: "square.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.35, green: 0.35, blue: 0.35),
                defaultWidth: 12.0,
                minWidth: 6.0,
                maxWidth: 24.0,
                opacity: 0.9,
                patternType: .stamp,
                spacing: 20.0,
                requiresLayer: .features,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Stairs Up",
                icon: "arrow.up.right",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5),
                defaultWidth: 15.0,
                minWidth: 10.0,
                maxWidth: 25.0,
                opacity: 0.8,
                patternType: .hatched,
                spacing: 3.0,
                requiresLayer: .features,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Stairs Down",
                icon: "arrow.down.right",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.45, green: 0.45, blue: 0.45),
                defaultWidth: 15.0,
                minWidth: 10.0,
                maxWidth: 25.0,
                opacity: 0.8,
                patternType: .hatched,
                spacing: 3.0,
                requiresLayer: .features,
                snapToGrid: true,
                isBuiltIn: true
            )
        ]
    }
    
    // MARK: - Door & Window Brushes
    
    private static func createDoorWindowBrushes() -> [MapBrush] {
        return [
            MapBrush(
                name: "Door",
                icon: "door.left.hand.open",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.6, green: 0.4, blue: 0.2),
                defaultWidth: 6.0,
                minWidth: 4.0,
                maxWidth: 10.0,
                opacity: 0.9,
                patternType: .stamp,
                spacing: 15.0,
                requiresLayer: .structures,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Double Door",
                icon: "door.garage.double.bay.open",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.6, green: 0.4, blue: 0.2),
                defaultWidth: 12.0,
                minWidth: 8.0,
                maxWidth: 16.0,
                opacity: 0.9,
                patternType: .stamp,
                spacing: 20.0,
                requiresLayer: .structures,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Secret Door",
                icon: "lock.rectangle.on.rectangle",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.5, green: 0.3, blue: 0.1),
                defaultWidth: 6.0,
                minWidth: 4.0,
                maxWidth: 10.0,
                opacity: 0.7,
                patternType: .stamp,
                spacing: 15.0,
                requiresLayer: .structures,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Window",
                icon: "square.split.2x2",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.7, green: 0.8, blue: 0.9),
                defaultWidth: 5.0,
                minWidth: 3.0,
                maxWidth: 10.0,
                opacity: 0.8,
                patternType: .stamp,
                spacing: 12.0,
                requiresLayer: .structures,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Archway",
                icon: "arrowtriangle.up.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.4, green: 0.4, blue: 0.35),
                defaultWidth: 8.0,
                minWidth: 6.0,
                maxWidth: 14.0,
                opacity: 0.85,
                patternType: .stamp,
                spacing: 18.0,
                requiresLayer: .structures,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Portcullis",
                icon: "line.3.horizontal.decrease",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.3, green: 0.3, blue: 0.3),
                defaultWidth: 8.0,
                minWidth: 5.0,
                maxWidth: 12.0,
                opacity: 0.9,
                patternType: .hatched,
                spacing: 2.0,
                requiresLayer: .structures,
                snapToGrid: true,
                isBuiltIn: true
            )
        ]
    }
    
    // MARK: - Room Feature Brushes
    
    private static func createRoomFeatureBrushes() -> [MapBrush] {
        return [
            MapBrush(
                name: "Floor Tile",
                icon: "square.grid.3x3",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.8, green: 0.8, blue: 0.75),
                defaultWidth: 25.0,
                minWidth: 15.0,
                maxWidth: 50.0,
                opacity: 0.5,
                patternType: .hatched,
                spacing: 5.0,
                requiresLayer: .terrain,
                snapToGrid: true,
                smoothing: 0.7,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Stone Floor",
                icon: "circle.grid.3x3",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6),
                defaultWidth: 25.0,
                minWidth: 15.0,
                maxWidth: 50.0,
                opacity: 0.4,
                patternType: .stippled,
                spacing: 2.0,
                scatterAmount: 0.5,
                requiresLayer: .terrain,
                smoothing: 0.7,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Carpet",
                icon: "square.fill.on.square.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.7, green: 0.2, blue: 0.2),
                defaultWidth: 20.0,
                minWidth: 10.0,
                maxWidth: 40.0,
                opacity: 0.6,
                patternType: .solid,
                requiresLayer: .terrain,
                smoothing: 0.8,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Water Feature",
                icon: "drop.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.3, green: 0.5, blue: 0.8),
                defaultWidth: 15.0,
                minWidth: 8.0,
                maxWidth: 30.0,
                opacity: 0.7,
                patternType: .solid,
                requiresLayer: .features,
                smoothing: 0.9,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Pit",
                icon: "circle.dotted",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1),
                defaultWidth: 12.0,
                minWidth: 6.0,
                maxWidth: 25.0,
                opacity: 0.8,
                patternType: .hatched,
                spacing: 2.0,
                requiresLayer: .features,
                smoothing: 0.6,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Rubble",
                icon: "scribble.variable",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.5, green: 0.5, blue: 0.45),
                defaultWidth: 15.0,
                minWidth: 8.0,
                maxWidth: 30.0,
                opacity: 0.7,
                patternType: .stippled,
                spacing: 3.0,
                scatterAmount: 0.8,
                requiresLayer: .features,
                smoothing: 0.5,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Torch",
                icon: "flame.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.9, green: 0.6, blue: 0.2),
                defaultWidth: 6.0,
                minWidth: 4.0,
                maxWidth: 10.0,
                opacity: 0.85,
                patternType: .stamp,
                spacing: 15.0,
                requiresLayer: .features,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Trap",
                icon: "exclamationmark.triangle.fill",
                category: .symbols,
                baseColor: Color(.sRGB, red: 0.9, green: 0.2, blue: 0.2),
                defaultWidth: 8.0,
                minWidth: 5.0,
                maxWidth: 15.0,
                opacity: 0.75,
                patternType: .stamp,
                spacing: 20.0,
                requiresLayer: .features,
                snapToGrid: true,
                isBuiltIn: true
            )
        ]
    }
    
    // MARK: - Furniture Brushes
    
    private static func createFurnitureBrushes() -> [MapBrush] {
        return [
            MapBrush(
                name: "Table",
                icon: "rectangle.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.6, green: 0.4, blue: 0.2),
                defaultWidth: 15.0,
                minWidth: 8.0,
                maxWidth: 30.0,
                opacity: 0.8,
                patternType: .stamp,
                spacing: 20.0,
                requiresLayer: .furniture,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Round Table",
                icon: "circle.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.65, green: 0.45, blue: 0.25),
                defaultWidth: 12.0,
                minWidth: 6.0,
                maxWidth: 24.0,
                opacity: 0.8,
                patternType: .stamp,
                spacing: 18.0,
                requiresLayer: .furniture,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Chair",
                icon: "square.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.55, green: 0.35, blue: 0.15),
                defaultWidth: 6.0,
                minWidth: 4.0,
                maxWidth: 10.0,
                opacity: 0.8,
                patternType: .stamp,
                spacing: 12.0,
                requiresLayer: .furniture,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Bed",
                icon: "bed.double.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.7, green: 0.6, blue: 0.5),
                defaultWidth: 15.0,
                minWidth: 10.0,
                maxWidth: 25.0,
                opacity: 0.8,
                patternType: .stamp,
                spacing: 25.0,
                requiresLayer: .furniture,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Chest",
                icon: "shippingbox.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.5, green: 0.3, blue: 0.1),
                defaultWidth: 8.0,
                minWidth: 5.0,
                maxWidth: 15.0,
                opacity: 0.85,
                patternType: .stamp,
                spacing: 15.0,
                requiresLayer: .furniture,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Bookshelf",
                icon: "books.vertical.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.4, green: 0.3, blue: 0.2),
                defaultWidth: 10.0,
                minWidth: 6.0,
                maxWidth: 18.0,
                opacity: 0.85,
                patternType: .stamp,
                spacing: 18.0,
                requiresLayer: .furniture,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Altar",
                icon: "crown.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.6, green: 0.6, blue: 0.5),
                defaultWidth: 18.0,
                minWidth: 12.0,
                maxWidth: 30.0,
                opacity: 0.9,
                patternType: .stamp,
                spacing: 25.0,
                requiresLayer: .furniture,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Barrel",
                icon: "cylinder.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.5, green: 0.35, blue: 0.2),
                defaultWidth: 6.0,
                minWidth: 4.0,
                maxWidth: 12.0,
                opacity: 0.8,
                patternType: .stamp,
                spacing: 12.0,
                requiresLayer: .furniture,
                snapToGrid: true,
                isBuiltIn: true
            )
        ]
    }
    
    // MARK: - Dungeon-Specific Brushes
    
    private static func createDungeonBrushes() -> [MapBrush] {
        return [
            MapBrush(
                name: "Dungeon Wall",
                icon: "rectangle.portrait.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.25, green: 0.2, blue: 0.15),
                defaultWidth: 10.0,
                minWidth: 6.0,
                maxWidth: 18.0,
                opacity: 1.0,
                patternType: .solid,
                requiresLayer: .walls,
                snapToGrid: true,
                smoothing: 0.1,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Dungeon Floor",
                icon: "square.grid.3x3.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.4, green: 0.35, blue: 0.3),
                defaultWidth: 30.0,
                minWidth: 20.0,
                maxWidth: 60.0,
                opacity: 0.4,
                patternType: .stippled,
                spacing: 2.0,
                scatterAmount: 0.6,
                requiresLayer: .terrain,
                smoothing: 0.8,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Iron Door",
                icon: "shield.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.3, green: 0.3, blue: 0.35),
                defaultWidth: 7.0,
                minWidth: 5.0,
                maxWidth: 12.0,
                opacity: 0.95,
                patternType: .stamp,
                spacing: 15.0,
                requiresLayer: .structures,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Prison Bars",
                icon: "line.3.horizontal",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.2, green: 0.2, blue: 0.2),
                defaultWidth: 6.0,
                minWidth: 4.0,
                maxWidth: 10.0,
                opacity: 0.9,
                patternType: .hatched,
                spacing: 1.5,
                requiresLayer: .walls,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Chasm",
                icon: "arrow.down.circle.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.05, green: 0.05, blue: 0.05),
                defaultWidth: 15.0,
                minWidth: 8.0,
                maxWidth: 35.0,
                opacity: 0.9,
                patternType: .solid,
                requiresLayer: .features,
                smoothing: 0.6,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Lava",
                icon: "flame.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.9, green: 0.3, blue: 0.1),
                defaultWidth: 12.0,
                minWidth: 6.0,
                maxWidth: 30.0,
                opacity: 0.8,
                patternType: .solid,
                requiresLayer: .features,
                smoothing: 0.7,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Statue",
                icon: "figure.stand",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5),
                defaultWidth: 10.0,
                minWidth: 6.0,
                maxWidth: 20.0,
                opacity: 0.9,
                patternType: .stamp,
                spacing: 20.0,
                requiresLayer: .furniture,
                snapToGrid: true,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Sarcophagus",
                icon: "rectangle.portrait.fill",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.45, green: 0.4, blue: 0.35),
                defaultWidth: 12.0,
                minWidth: 8.0,
                maxWidth: 20.0,
                opacity: 0.9,
                patternType: .stamp,
                spacing: 20.0,
                requiresLayer: .furniture,
                snapToGrid: true,
                isBuiltIn: true
            )
        ]
    }
    
    // MARK: - Grid & Measurement Brushes
    
    private static func createGridBrushes() -> [MapBrush] {
        return [
            MapBrush(
                name: "Square Grid 5ft",
                icon: "grid",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5),
                defaultWidth: 1.0,
                minWidth: 0.5,
                maxWidth: 2.0,
                opacity: 0.3,
                patternType: .hatched,
                spacing: 25.0,
                requiresLayer: .reference,
                snapToGrid: true,
                smoothing: 0.0,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Square Grid 10ft",
                icon: "grid",
                category: .architectural,
                baseColor: Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5),
                defaultWidth: 1.5,
                minWidth: 0.5,
                maxWidth: 3.0,
                opacity: 0.4,
                patternType: .hatched,
                spacing: 50.0,
                requiresLayer: .reference,
                snapToGrid: true,
                smoothing: 0.0,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Measurement Line",
                icon: "ruler",
                category: .symbols,
                baseColor: Color(.sRGB, red: 0.8, green: 0.2, blue: 0.2),
                defaultWidth: 2.0,
                minWidth: 1.0,
                maxWidth: 4.0,
                opacity: 0.8,
                patternType: .solid,
                requiresLayer: .annotations,
                smoothing: 0.0,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Scale Marker",
                icon: "arrow.left.and.right",
                category: .symbols,
                baseColor: Color(.sRGB, red: 0.2, green: 0.2, blue: 0.2),
                defaultWidth: 3.0,
                minWidth: 2.0,
                maxWidth: 6.0,
                opacity: 0.9,
                patternType: .stamp,
                spacing: 30.0,
                requiresLayer: .annotations,
                isBuiltIn: true
            )
        ]
    }
}

// MARK: - Brush Registry Extension

extension BrushRegistry {
    /// Create and install the interior map brush set
    public func installInteriorBrushSet() {
        let interiorSet = InteriorMapBrushSet.create()
        
        // Only install if not already present
        if !installedBrushSets.contains(where: { $0.name == interiorSet.name }) {
            installedBrushSets.append(interiorSet)
        }
    }
    
    /// Get the interior brush set ID
    public var interiorBrushSetID: UUID? {
        installedBrushSets.first { $0.mapType == .interior && $0.isBuiltIn }?.id
    }
}
