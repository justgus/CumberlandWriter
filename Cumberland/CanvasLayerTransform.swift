//
//  CanvasLayerTransform.swift
//  Cumberland
//
//  General-purpose Comparable.clamped(to:) extension used across the app.
//  The original canvas transform logic, coordinate helpers, and CGFloat/Double
//  conversions have been extracted to BoardEngine (ER-0026).
//

import Foundation

// MARK: - Clamped Extension

extension Comparable {
    @inlinable
    public func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
