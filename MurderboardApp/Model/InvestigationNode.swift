//
//  InvestigationNode.swift
//  MurderboardApp
//
//  SwiftData model for a node on the investigation board.
//  Represents a person, place, clue, event, or other entity.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class InvestigationNode {
    var id: UUID = UUID()
    var name: String = ""
    var subtitle: String = ""
    var posX: Double = 0.0
    var posY: Double = 0.0
    var zIndex: Double = 0.0
    var pinned: Bool = false

    /// Category of this node (person, place, clue, event, etc.).
    var categoryRaw: String = "person"

    /// Hex color string for custom accent.
    var colorHex: String = "#FF6B6B"

    /// The board this node belongs to.
    var board: InvestigationBoard?

    init(
        name: String,
        subtitle: String = "",
        category: NodeCategory = .person,
        colorHex: String = "#FF6B6B",
        posX: Double = 0,
        posY: Double = 0
    ) {
        self.id = UUID()
        self.name = name
        self.subtitle = subtitle
        self.categoryRaw = category.rawValue
        self.colorHex = colorHex
        self.posX = posX
        self.posY = posY
    }

    var category: NodeCategory {
        get { NodeCategory(rawValue: categoryRaw) ?? .person }
        set { categoryRaw = newValue.rawValue }
    }
}

// MARK: - Node Category

enum NodeCategory: String, CaseIterable, Codable, Sendable {
    case person
    case place
    case clue
    case event
    case document
    case weapon
    case vehicle
    case organization

    var systemImage: String {
        switch self {
        case .person: "person.fill"
        case .place: "mappin.and.ellipse"
        case .clue: "magnifyingglass"
        case .event: "calendar"
        case .document: "doc.text.fill"
        case .weapon: "exclamationmark.triangle.fill"
        case .vehicle: "car.fill"
        case .organization: "building.2.fill"
        }
    }

    var displayName: String {
        switch self {
        case .person: "Person"
        case .place: "Place"
        case .clue: "Clue"
        case .event: "Event"
        case .document: "Document"
        case .weapon: "Weapon"
        case .vehicle: "Vehicle"
        case .organization: "Organization"
        }
    }

    var defaultColor: Color {
        switch self {
        case .person: .red
        case .place: .blue
        case .clue: .orange
        case .event: .purple
        case .document: .gray
        case .weapon: .pink
        case .vehicle: .green
        case .organization: .indigo
        }
    }
}
