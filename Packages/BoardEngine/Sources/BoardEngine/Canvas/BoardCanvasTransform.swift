//
//  BoardCanvasTransform.swift
//  BoardEngine
//
//  Coordinate-space conversion utilities for the board canvas.
//  Provides worldToView and viewToWorld transforms using a uniform
//  scale + translation model: v = w * S + T
//

import SwiftUI
import Foundation

// MARK: - Transform Helper

/// Transform utilities for board canvas coordinate space operations.
public struct BoardCanvasTransform {
    /// Convert world coordinates to view coordinates.
    /// View <- World: v = w*S + T
    @inlinable
    public static func worldToView(_ world: CGPoint, scale s: Double, panX: Double, panY: Double) -> CGPoint {
        CGPoint(x: world.x.dg * s + panX, y: world.y.dg * s + panY)
    }

    /// Convert view coordinates to world coordinates.
    /// World <- View: w = (v - T) / S
    @inlinable
    public static func viewToWorld(_ view: CGPoint, scale s: Double, panX: Double, panY: Double) -> CGPoint {
        let ss = max(s, 0.000001)
        return CGPoint(x: (view.x.dg - panX) / ss, y: (view.y.dg - panY) / ss)
    }

    /// Calculate the view canvas rectangle in world coordinates.
    public static func viewCanvasRect(worldForWindowSize size: CGSize, scale s: Double, panX: Double, panY: Double) -> CGRect {
        let originWorld = viewToWorld(.zero, scale: s, panX: panX, panY: panY)
        let ss = max(s, 0.000001)
        let wWorld = size.width.dg / ss
        let hWorld = size.height.dg / ss
        return CGRect(x: originWorld.x, y: originWorld.y, width: wWorld, height: hWorld)
    }

    /// Calculate the world center corresponding to the view window's geometric center.
    public static func worldCenter(forWindowSize size: CGSize, scale s: Double, panX: Double, panY: Double) -> CGPoint {
        let cView = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        return viewToWorld(cView, scale: s, panX: panX, panY: panY)
    }
}

// MARK: - Transform View Modifier

/// View modifier that applies the canvas transform (scale + translation) as an affine transform.
public struct BoardTransformModifier: ViewModifier {
    public let debugEnabled: Bool
    public let zoomScale: Double
    public let panX: Double
    public let panY: Double

    public init(debugEnabled: Bool = false, zoomScale: Double, panX: Double, panY: Double) {
        self.debugEnabled = debugEnabled
        self.zoomScale = zoomScale
        self.panX = panX
        self.panY = panY
    }

    public func body(content: Content) -> some View {
        #if DEBUG
        if debugEnabled {
            return AnyView(content)
        }
        #endif

        let s = CGFloat(zoomScale)
        let t = CGAffineTransform(scaleX: s, y: s)
            .concatenating(CGAffineTransform(translationX: CGFloat(panX), y: CGFloat(panY)))
        return AnyView(
            content.transformEffect(t)
        )
    }
}
