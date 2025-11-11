// CardDetailTab.swift
import SwiftUI

enum CardDetailTab: String, CaseIterable, Identifiable {
    case details = "Details"
    case relationships = "Relationships"
    case aggregateText = "Aggregate" // New: AggregateTextView for Chapters
    case board = "Board" // Structural Spine (Projects) or Murder Board (Worlds/Characters/Scenes)
    case timeline = "Timeline" // Timeline chart (Timelines only)
    case mapWizard = "Map Wizard" // Map creation/editing wizard (Maps only)

    var id: String { rawValue }
    var title: String { rawValue }

    var systemImage: String {
        switch self {
        case .details: return "rectangle.and.text.magnifyingglass"
        case .relationships: return "link"
        case .aggregateText: return "text.justify"
        case .board: return "square.grid.3x1.folder.fill.badge.plus"
        case .timeline: return "chart.bar.yaxis"
        case .mapWizard: return "map.fill"
        }
    }

    var helpText: String {
        switch self {
        case .details: return "Show Details"
        case .relationships: return "Manage Relationships"
        case .aggregateText: return "Aggregate Text"
        case .board: return "Board"
        case .timeline: return "Timeline Chart"
        case .mapWizard: return "Create or Edit Map"
        }
    }

    // MARK: - Availability and coercion helpers

    // Tabs available for a given Kind
    static func allowedTabs(for kind: Kinds) -> [CardDetailTab] {
        var tabs: [CardDetailTab] = [.details, .relationships]
        // Chapters: Aggregate Text as the third option
        if kind == .chapters {
            tabs.append(.aggregateText)
        }
        // Projects: Structure Board (existing)
        if kind == .projects {
            tabs.append(.board)
        }
        // Worlds, Characters, and Scenes: Murder Board
        if kind == .worlds || kind == .characters || kind == .scenes {
            tabs.append(.board)
        }
        if kind == .timelines {
            tabs.append(.timeline)
        }
        // Maps: Map Wizard
        if kind == .maps {
            tabs.append(.mapWizard)
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

