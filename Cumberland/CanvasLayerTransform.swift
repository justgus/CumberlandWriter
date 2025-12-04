//
//  MBTransform.swift
//  Cumberland
//
//  Created by Assistant on 11/1/25.
//

import SwiftUI
import Foundation

// MARK: - Transform Helper

/// Transform utilities for MurderBoardView coordinate space operations
struct CanvasLayerTransform {
    /// Convert world coordinates to view coordinates
    /// View ← World: v = w*S + T
    static func worldToView(_ world: CGPoint, scale s: Double, panX: Double, panY: Double) -> CGPoint {
        CGPoint(x: world.x.dg * s + panX, y: world.y.dg * s + panY)
    }
    
    /// Convert view coordinates to world coordinates
    /// World ← View: w = (v - T) / S
    static func viewToWorld(_ view: CGPoint, scale s: Double, panX: Double, panY: Double) -> CGPoint {
        let ss = max(s, 0.000001)
        return CGPoint(x: (view.x.dg - panX) / ss, y: (view.y.dg - panY) / ss)
    }
    
    /// Calculate the view canvas rectangle in world coordinates
    static func viewCanvasRect(worldForWindowSize size: CGSize, scale s: Double, panX: Double, panY: Double) -> CGRect {
        let originWorld = viewToWorld(.zero, scale: s, panX: panX, panY: panY)
        let ss = max(s, 0.000001)
        let wWorld = size.width.dg / ss
        let hWorld = size.height.dg / ss
        return CGRect(x: originWorld.x, y: originWorld.y, width: wWorld, height: hWorld)
    }
    
    /// Calculate the world center corresponding to the view window's geometric center
    static func worldCenter(forWindowSize size: CGSize, scale s: Double, panX: Double, panY: Double) -> CGPoint {
        let cView = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        return viewToWorld(cView, scale: s, panX: panX, panY: panY)
    }
}

// MARK: - Transform View Modifiers

/// View modifier that applies transform scaling and translation
struct CanvasLayerTransformModifier: ViewModifier {
    let debugEnabled: Bool
    let zoomScale: Double
    let panX: Double
    let panY: Double
    
    func body(content: Content) -> some View {
        #if DEBUG
        if debugEnabled {
            // In debug passthrough, render untransformed so overlays/diagnostics can align
            return AnyView(content)
        }
        #endif
        
        // Apply a single affine: scale, then translate.
        // This keeps rendering and hit-testing aligned for context menus on macOS.
        let s = CGFloat(zoomScale)
        let t = CGAffineTransform(scaleX: s, y: s)
            .concatenating(CGAffineTransform(translationX: CGFloat(panX), y: CGFloat(panY)))
        return AnyView(
            content.transformEffect(t)
        )
    }
}

// MARK: - Helper Extensions

extension CGFloat {
    public var dg: Double { Double(self) }
}

extension Double {
    public var cg: CGFloat { CGFloat(self) }
}

extension Comparable {
    @inlinable
    public func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

extension CGSize {
    public func clamped(maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        CGSize(width: min(width, maxWidth), height: min(height, maxHeight))
    }
    
    public func scaled(by scalar: CGFloat) -> CGSize {
        CGSize(width: width * scalar, height: height * scalar)
    }
}
