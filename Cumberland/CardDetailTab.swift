// CardDetailTab.swift
import SwiftUI

enum CardDetailTab: String, CaseIterable, Identifiable {
    case details = "Details"
    case relationships = "Relationships"
    case board = "Board" // Structural Spine (Projects) or Murder Board (Worlds/Characters)
    case timeline = "Timeline" // Timeline chart (Timelines only)

    var id: String { rawValue }
    var title: String { rawValue }

    var systemImage: String {
        switch self {
        case .details: return "rectangle.and.text.magnifyingglass"
        case .relationships: return "point.3.connected.trianglepath.dotted"
        case .board: return "square.grid.3x1.folder.fill.badge.plus"
        case .timeline: return "chart.bar.xaxis"
        }
    }

    var helpText: String {
        switch self {
        case .details: return "Show Details"
        case .relationships: return "Manage Relationships"
        case .board: return "Board"
        case .timeline: return "Timeline Chart"
        }
    }

    // MARK: - Availability and coercion helpers

    // Tabs available for a given Kind
    static func allowedTabs(for kind: Kinds) -> [CardDetailTab] {
        var tabs: [CardDetailTab] = [.details, .relationships]
        // Projects: Structure Board (existing)
        if kind == .projects {
            tabs.append(.board)
        }
        // Worlds and Characters: Murder Board
        if kind == .worlds || kind == .characters {
            tabs.append(.board)
        }
        if kind == .timelines {
            tabs.append(.timeline)
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
}    // MARK: - Availability and coercion helpers

