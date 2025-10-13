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

    // MARK: - Availability and coercion helpers

    // Tabs available for a given Kind (e.g., Board only for Projects)
    static func allowedTabs(for kind: Kinds) -> [CardDetailTab] {
        var tabs: [CardDetailTab] = [.details, .relationships]
        if kind == .projects {
            tabs.append(.board)
        }
        return tabs
    }

    // Coerce a desired tab to a valid one for the given Kind
    static func coerce(_ desired: CardDetailTab, for kind: Kinds) -> CardDetailTab {
        let allowed = allowedTabs(for: kind)
        return allowed.contains(desired) ? desired : .details
    }

    // Failable mapping from a raw string with fallback to Details
    static func from(raw: String?, default def: CardDetailTab = .details) -> CardDetailTab {
        guard let raw, let v = CardDetailTab(rawValue: raw) else { return def }
        return v
    }
}

