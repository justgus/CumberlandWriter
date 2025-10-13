// CardDetailTab.swift
import SwiftUI

enum CardDetailTab: String, CaseIterable, Identifiable {
    case details = "Details"
    case relationships = "Relationships"
    case board = "Board" // Structural Spine (Projects only)

    var id: String { rawValue }
    var title: String { rawValue }

    var systemImage: String {
        switch self {
        case .details: return "rectangle.and.text.magnifyingglass"
        case .relationships: return "point.3.connected.trianglepath.dotted"
        case .board: return "square.grid.3x1.folder.fill.badge.plus"
        }
    }

    var helpText: String {
        switch self {
        case .details: return "Show Details"
        case .relationships: return "Manage Relationships"
        case .board: return "Structural Spine"
        }
    }
}
