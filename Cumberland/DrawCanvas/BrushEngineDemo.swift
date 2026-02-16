//
//  BrushEngineDemo.swift
//  Cumberland
//
//  Demo and test utilities for the brush rendering engine
//

import SwiftUI
import CoreGraphics
import BrushEngine

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Brush Engine Demo

/// Demonstrates all brush rendering capabilities
struct BrushEngineDemo {
    
    // MARK: - Demo Scene Generators
    
    /// Generate a complete demo map showing all brush types
    static func generateDemoMap(size: CGSize) -> CGImage? {
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            cgContext.setFillColor(UIColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 1.0).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Demo each brush category
            demoTerrainBrushes(in: cgContext, bounds: CGRect(x: 20, y: 20, width: size.width/2 - 30, height: size.height/3 - 30))
            demoWaterBrushes(in: cgContext, bounds: CGRect(x: size.width/2 + 10, y: 20, width: size.width/2 - 30, height: size.height/3 - 30))
            demoVegetationBrushes(in: cgContext, bounds: CGRect(x: 20, y: size.height/3 + 10, width: size.width/2 - 30, height: size.height/3 - 30))
            demoStructureBrushes(in: cgContext, bounds: CGRect(x: size.width/2 + 10, y: size.height/3 + 10, width: size.width/2 - 30, height: size.height/3 - 30))
            demoRoadBrushes(in: cgContext, bounds: CGRect(x: 20, y: 2*size.height/3 + 10, width: size.width - 40, height: size.height/3 - 30))
        }
        
        return image.cgImage
        
        #elseif canImport(AppKit)
        let image = NSImage(size: size)
        image.lockFocus()
        
        guard let cgContext = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }
        
        // Background
        cgContext.setFillColor(NSColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 1.0).cgColor)
        cgContext.fill(CGRect(origin: .zero, size: size))
        
        // Demo each brush category
        demoTerrainBrushes(in: cgContext, bounds: CGRect(x: 20, y: 20, width: size.width/2 - 30, height: size.height/3 - 30))
        demoWaterBrushes(in: cgContext, bounds: CGRect(x: size.width/2 + 10, y: 20, width: size.width/2 - 30, height: size.height/3 - 30))
        demoVegetationBrushes(in: cgContext, bounds: CGRect(x: 20, y: size.height/3 + 10, width: size.width/2 - 30, height: size.height/3 - 30))
        demoStructureBrushes(in: cgContext, bounds: CGRect(x: size.width/2 + 10, y: size.height/3 + 10, width: size.width/2 - 30, height: size.height/3 - 30))
        demoRoadBrushes(in: cgContext, bounds: CGRect(x: 20, y: 2*size.height/3 + 10, width: size.width - 40, height: size.height/3 - 30))
        
        image.unlockFocus()
        
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        return nil
        #endif
    }
    
    // MARK: - Category Demos
    
    private static func demoTerrainBrushes(in context: CGContext, bounds: CGRect) {
        // Draw label
        drawLabel("Terrain", in: context, at: CGPoint(x: bounds.minX + 10, y: bounds.minY + 10))
        
        // Mountain range
        let mountainPath = [
            CGPoint(x: bounds.minX + 20, y: bounds.midY),
            CGPoint(x: bounds.minX + 80, y: bounds.midY),
            CGPoint(x: bounds.minX + 140, y: bounds.midY),
            CGPoint(x: bounds.minX + 200, y: bounds.midY)
        ]
        
        let mountains = BrushEngine.generateMountainPattern(points: mountainPath, width: 15, style: .jagged)
        context.setStrokeColor(CGColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0))
        context.setLineWidth(1.5)
        context.addPath(mountains)
        context.strokePath()
        
        // Hills
        let hillPath = [
            CGPoint(x: bounds.minX + 20, y: bounds.maxY - 40),
            CGPoint(x: bounds.minX + 100, y: bounds.maxY - 40),
            CGPoint(x: bounds.minX + 180, y: bounds.maxY - 40)
        ]
        
        let hills = BrushEngine.generateHillPattern(points: hillPath, width: 12)
        context.setStrokeColor(CGColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0))
        context.addPath(hills)
        context.strokePath()
    }
    
    private static func demoWaterBrushes(in context: CGContext, bounds: CGRect) {
        // Draw label
        drawLabel("Water", in: context, at: CGPoint(x: bounds.minX + 10, y: bounds.minY + 10))
        
        // Coastline
        let coastPath = [
            CGPoint(x: bounds.minX + 20, y: bounds.midY),
            CGPoint(x: bounds.minX + 80, y: bounds.midY - 10),
            CGPoint(x: bounds.minX + 140, y: bounds.midY + 5),
            CGPoint(x: bounds.minX + 200, y: bounds.midY - 5)
        ]
        
        let coastline = ProceduralPatternGenerator.generateDetailedCoastline(
            points: coastPath,
            width: 8,
            detail: .medium,
            erosion: 0.6
        )
        
        context.setStrokeColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0))
        context.setLineWidth(2.0)
        context.addPath(coastline)
        context.strokePath()
        
        // Water waves below
        let wavePath = [
            CGPoint(x: bounds.minX + 20, y: bounds.maxY - 40),
            CGPoint(x: bounds.minX + 200, y: bounds.maxY - 40)
        ]
        
        let waves = BrushEngine.generateWaterPattern(points: wavePath, width: 10, waveSize: 1.0)
        context.setStrokeColor(CGColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 0.7))
        context.addPath(waves)
        context.strokePath()
    }
    
    private static func demoVegetationBrushes(in context: CGContext, bounds: CGRect) {
        // Draw label
        drawLabel("Vegetation", in: context, at: CGPoint(x: bounds.minX + 10, y: bounds.minY + 10))
        
        // Forest pattern
        let forestPath = [
            CGPoint(x: bounds.minX + 40, y: bounds.midY),
            CGPoint(x: bounds.minX + 180, y: bounds.midY)
        ]
        
        let trees = BrushEngine.generateForestPattern(points: forestPath, width: 12, density: 1.0)
        
        context.setFillColor(CGColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0))
        context.setStrokeColor(CGColor(red: 0.15, green: 0.4, blue: 0.15, alpha: 1.0))
        context.setLineWidth(1.0)
        
        for (position, treePath) in trees {
            context.saveGState()
            context.translateBy(x: position.x, y: position.y)
            context.addPath(treePath)
            context.fillPath()
            context.addPath(treePath)
            context.strokePath()
            context.restoreGState()
        }
    }
    
    private static func demoStructureBrushes(in context: CGContext, bounds: CGRect) {
        // Draw label
        drawLabel("Structures", in: context, at: CGPoint(x: bounds.minX + 10, y: bounds.minY + 10))
        
        // Building pattern
        let buildingPath = [
            CGPoint(x: bounds.minX + 40, y: bounds.midY),
            CGPoint(x: bounds.minX + 180, y: bounds.midY)
        ]
        
        let buildings = BrushEngine.generateBuildingPattern(points: buildingPath, width: 15)
        
        let buildingColor = CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        
        for (rect, style) in buildings {
            style.render(in: rect, context: context, color: buildingColor)
        }
    }
    
    private static func demoRoadBrushes(in context: CGContext, bounds: CGRect) {
        // Draw label
        drawLabel("Roads", in: context, at: CGPoint(x: bounds.minX + 10, y: bounds.minY + 10))
        
        // Highway
        let highwayPath = [
            CGPoint(x: bounds.minX + 40, y: bounds.minY + 50),
            CGPoint(x: bounds.maxX - 40, y: bounds.minY + 50)
        ]
        
        let highway = BrushEngine.generateRoadPattern(points: highwayPath, width: 20, roadType: .highway)
        context.setStrokeColor(CGColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0))
        context.setLineWidth(2.0)
        context.addPath(highway)
        context.strokePath()
        
        // Standard road
        let roadPath = [
            CGPoint(x: bounds.minX + 40, y: bounds.midY),
            CGPoint(x: bounds.maxX - 40, y: bounds.midY)
        ]
        
        let road = BrushEngine.generateRoadPattern(points: roadPath, width: 15, roadType: .standard)
        context.setStrokeColor(CGColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0))
        context.addPath(road)
        context.strokePath()
        
        // Path (dashed)
        let pathPath = [
            CGPoint(x: bounds.minX + 40, y: bounds.maxY - 40),
            CGPoint(x: bounds.maxX - 40, y: bounds.maxY - 40)
        ]
        
        BrushEngine.dottedStroke(points: pathPath, color: .gray, width: 3, context: context)
    }
    
    private static func drawLabel(_ text: String, in context: CGContext, at point: CGPoint) {
        #if canImport(UIKit)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(at: point)
        
        #elseif canImport(AppKit)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: NSColor.black
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(at: point)
        #endif
    }
    
    // MARK: - Individual Pattern Demos
    
    /// Generate demo of mountain patterns with different styles
    static func generateMountainStylesDemo(size: CGSize) -> CGImage? {
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            let yPositions: [CGFloat] = [size.height * 0.2, size.height * 0.5, size.height * 0.8]
            let styles: [MountainStyle] = [.jagged, .rounded, .layered]
            let labels = ["Jagged", "Rounded", "Layered"]
            
            for (index, style) in styles.enumerated() {
                let y = yPositions[index]
                let path = [
                    CGPoint(x: 50, y: y),
                    CGPoint(x: 200, y: y),
                    CGPoint(x: 350, y: y)
                ]
                
                let mountains = BrushEngine.generateMountainPattern(points: path, width: 20, style: style)
                cgContext.setStrokeColor(UIColor.darkGray.cgColor)
                cgContext.setLineWidth(2.0)
                cgContext.addPath(mountains)
                cgContext.strokePath()
                
                drawLabel(labels[index], in: cgContext, at: CGPoint(x: 10, y: y - 10))
            }
        }
        return image.cgImage
        #else
        return nil
        #endif
    }
    
    /// Generate demo of coastline detail levels
    static func generateCoastlineDetailDemo(size: CGSize) -> CGImage? {
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            let yPositions: [CGFloat] = [size.height * 0.15, size.height * 0.35, size.height * 0.55, size.height * 0.75]
            let details: [CoastlineDetail] = [.low, .medium, .high, .veryHigh]
            let labels = ["Low Detail", "Medium Detail", "High Detail", "Very High Detail"]
            
            for (index, detail) in details.enumerated() {
                let y = yPositions[index]
                let path = [
                    CGPoint(x: 100, y: y),
                    CGPoint(x: 200, y: y),
                    CGPoint(x: 300, y: y)
                ]
                
                let coastline = ProceduralPatternGenerator.generateDetailedCoastline(
                    points: path,
                    width: 15,
                    detail: detail,
                    erosion: 0.7
                )
                
                cgContext.setStrokeColor(UIColor.blue.cgColor)
                cgContext.setLineWidth(2.0)
                cgContext.addPath(coastline)
                cgContext.strokePath()
                
                drawLabel(labels[index], in: cgContext, at: CGPoint(x: 10, y: y - 10))
            }
        }
        return image.cgImage
        #else
        return nil
        #endif
    }
    
    /// Generate demo of pressure-sensitive stroke
    static func generatePressureSensitiveDemo(size: CGSize) -> CGImage? {
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Simulate pressure curve (low -> high -> low)
            var points: [CGPoint] = []
            var pressures: [CGFloat] = []
            
            let numPoints = 50
            for i in 0..<numPoints {
                let t = CGFloat(i) / CGFloat(numPoints - 1)
                let x = 50 + t * (size.width - 100)
                let y = size.height / 2 + sin(t * .pi * 2) * 50
                
                // Pressure: starts low, peaks in middle, ends low
                let pressure = sin(t * .pi)
                
                points.append(CGPoint(x: x, y: y))
                pressures.append(pressure)
            }
            
            // Render with pressure
            let brush = MapBrush.basicPen
            
            // Combine points and pressures into tuples for the function
            let pointsWithPressure = zip(points, pressures).map { ($0, $1) }
            
            BrushEngine.renderPressureSensitiveStroke(
                pointsWithPressure: pointsWithPressure,
                brush: brush,
                color: Color.black,
                baseWidth: 20.0,
                context: cgContext
            )
            
            drawLabel("Pressure-Sensitive Stroke", in: cgContext, at: CGPoint(x: 50, y: 30))
        }
        return image.cgImage
        #else
        return nil
        #endif
    }
    
    // MARK: - Performance Tests
    
    /// Measure rendering performance for different brush types
    static func measureRenderingPerformance() -> [String: TimeInterval] {
        var results: [String: TimeInterval] = [:]
        
        let testPoints = (0..<100).map { i in
            CGPoint(x: CGFloat(i * 5), y: 100 + sin(CGFloat(i) * 0.1) * 50)
        }
        
        let size = CGSize(width: 600, height: 300)
        
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        // Test solid stroke
        let solidStart = Date()
        _ = renderer.image { context in
            BrushEngine.renderSolidStroke(
                points: testPoints,
                color: Color.black,
                width: 5,
                brush: .basicPen,
                context: context.cgContext
            )
        }
        results["Solid"] = Date().timeIntervalSince(solidStart)
        
        // Test stippled stroke
        let stippledStart = Date()
        _ = renderer.image { context in
            BrushEngine.renderStippledStroke(
                points: testPoints,
                color: Color.black,
                width: 5,
                context: context.cgContext
            )
        }
        results["Stippled"] = Date().timeIntervalSince(stippledStart)
        
        // Test mountain pattern
        let mountainStart = Date()
        _ = renderer.image { context in
            let pattern = BrushEngine.generateMountainPattern(points: testPoints, width: 10, style: .jagged)
            BrushEngine.renderPatternStroke(pattern: pattern, color: Color.black, width: 2, context: context.cgContext)
        }
        results["Mountain"] = Date().timeIntervalSince(mountainStart)
        
        // Test coastline
        let coastlineStart = Date()
        _ = renderer.image { context in
            let pattern = ProceduralPatternGenerator.generateDetailedCoastline(
                points: testPoints,
                width: 10,
                detail: .high,
                erosion: 0.7
            )
            context.cgContext.addPath(pattern)
            context.cgContext.strokePath()
        }
        results["Coastline"] = Date().timeIntervalSince(coastlineStart)
        
        // Test forest pattern
        let forestStart = Date()
        _ = renderer.image { context in
            let trees = BrushEngine.generateForestPattern(points: testPoints, width: 10, density: 1.0)
            BrushEngine.renderStampPattern(stamps: trees, color: .green, context: context.cgContext)
        }
        results["Forest"] = Date().timeIntervalSince(forestStart)
        
        #endif
        
        return results
    }
    
    /// Print performance results
    static func printPerformanceResults() {
        print("=== Brush Engine Performance Test ===")
        let results = measureRenderingPerformance()
        
        for (name, time) in results.sorted(by: { $0.value < $1.value }) {
            print("\(name): \(String(format: "%.4f", time))s")
        }
        print("====================================")
    }
}

// MARK: - SwiftUI Preview Helpers

#if DEBUG
struct BrushEngineDemoView: View {
    @State private var selectedDemo: DemoType = .all
    
    enum DemoType: String, CaseIterable {
        case all = "All Brushes"
        case mountains = "Mountain Styles"
        case coastlines = "Coastline Detail"
        case pressure = "Pressure Sensitivity"
    }
    
    var body: some View {
        VStack {
            Picker("Demo", selection: $selectedDemo) {
                ForEach(DemoType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            if let image = generateDemoImage() {
                #if canImport(UIKit)
                Image(uiImage: UIImage(cgImage: image))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                #elseif canImport(AppKit)
                Image(nsImage: NSImage(cgImage: image, size: .zero))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                #endif
            }
            
            Button("Run Performance Tests") {
                BrushEngineDemo.printPerformanceResults()
            }
            .padding()
        }
    }
    
    func generateDemoImage() -> CGImage? {
        let size = CGSize(width: 800, height: 600)
        
        switch selectedDemo {
        case .all:
            return BrushEngineDemo.generateDemoMap(size: size)
        case .mountains:
            return BrushEngineDemo.generateMountainStylesDemo(size: size)
        case .coastlines:
            return BrushEngineDemo.generateCoastlineDetailDemo(size: size)
        case .pressure:
            return BrushEngineDemo.generatePressureSensitiveDemo(size: size)
        }
    }
}

#Preview {
    BrushEngineDemoView()
}
#endif
