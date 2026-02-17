//
//  GeometryExtensions.swift
//  BoardEngine
//
//  Geometry helper extensions for coordinate transforms and value clamping.
//  Extracted from Cumberland's CanvasLayerTransform utilities.
//

import SwiftUI
import Foundation

// MARK: - CGFloat / Double Bridging

extension CGFloat {
    /// Convert CGFloat to Double for use in board coordinate calculations.
    @inlinable
    public var dg: Double { Double(self) }
}

extension Double {
    /// Convert Double to CGFloat for use in SwiftUI layout.
    @inlinable
    public var cg: CGFloat { CGFloat(self) }
}

// MARK: - Clamping

extension Comparable {
    /// Clamp a value to a closed range.
    @inlinable
    public func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - CGSize Helpers

extension CGSize {
    /// Clamp both dimensions to maximum values.
    public func clamped(maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        CGSize(width: min(width, maxWidth), height: min(height, maxHeight))
    }

    /// Scale both dimensions by a scalar factor.
    public func scaled(by scalar: CGFloat) -> CGSize {
        CGSize(width: width * scalar, height: height * scalar)
    }
}
