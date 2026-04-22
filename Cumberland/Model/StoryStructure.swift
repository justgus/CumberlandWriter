//
//  StoryStructure.swift
//  Cumberland
//
//  Created by Assistant on 10/10/25.
//
//  SwiftData models for story structure templates. StoryStructure holds a
//  named template (e.g. "Three-Act Structure") containing an ordered list
//  of StructureElement beats. StructureAssignmentManager provides helpers
//  for adding and removing cards from elements via the many-to-many
//  StructureElement.assignedCards relationship.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class StoryStructure {
    // CloudKit: provide default
    var id: UUID = UUID()

    // Basic info
    var name: String = "" // e.g., "Three-Act Structure", "Hero's Journey", "Beginning-Middle-End"
    var projectID: UUID? // Optional: link to a specific project

    // The actual structure elements (CloudKit: relationship must be optional)
    @Relationship(deleteRule: .cascade, inverse: \StructureElement.storyStructure)
    var elements: [StructureElement]? = []

    // Custom arc data (for user-created structures)
    // Stored as JSON-encoded CustomArc
    var customArcData: Data?

    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    init(name: String, projectID: UUID? = nil) {
        self.name = name
        self.projectID = projectID
    }

    /// Computed property to access the custom arc (if present)
    var customArc: CustomArc? {
        get {
            guard let data = customArcData else { return nil }
            return try? JSONDecoder().decode(CustomArc.self, from: data)
        }
        set {
            if let arc = newValue {
                customArcData = try? JSONEncoder().encode(arc)
            } else {
                customArcData = nil
            }
            modifiedAt = Date()
        }
    }

    /// Whether this is a custom (user-created) structure
    var isCustom: Bool {
        return customArcData != nil
    }
}

@Model
final class StructureElement {
    // CloudKit: provide default
    var id: UUID = UUID()
    
    var name: String = "" // e.g., "Act 1", "Inciting Incident", "Climax"
    var elementDescription: String = "" // Optional description of this element
    var orderIndex: Int = 0 // For maintaining order
    
    // Color customization (optional)
    var colorHue: Double? // Store hue as 0.0-1.0
    
    // Relationship back to the structure
    var storyStructure: StoryStructure?
    
    // Cards that are assigned to this structural element (many-to-many)
    @Relationship(deleteRule: .nullify, inverse: \Card.structureElements)
    var assignedCards: [Card]? = []
    
    var createdAt: Date = Date()
    
    init(name: String, elementDescription: String = "", orderIndex: Int) {
        self.name = name
        self.elementDescription = elementDescription
        self.orderIndex = orderIndex
    }
    
    // Computed color property
    var displayColor: Color {
        if let hue = colorHue {
            return Color(hue: hue, saturation: 0.6, brightness: 0.8)
        }
        // Generate a color based on the order index if no custom color is set
        let hue = Double(orderIndex % 12) / 12.0 // Cycle through 12 hues
        return Color(hue: hue, saturation: 0.5, brightness: 0.7)
    }
}

// MARK: - Structure Assignment Helpers

struct StructureAssignmentManager {
    let modelContext: ModelContext
    
    // Many-to-many: get all structure elements a card is assigned to
    func getStructureElements(for card: Card) -> [StructureElement] {
        card.structureElements ?? []
    }
    
    // For legacy callers expecting a single element; returns the first if present
    func getStructureElement(for card: Card) -> StructureElement? {
        card.structureElements?.first
    }
    
    // Add assignment (no removal from others)
    func assignCard(_ card: Card, to element: StructureElement?) {
        guard let element else { return }
        if element.assignedCards == nil { element.assignedCards = [] }
        if !(element.assignedCards?.contains(where: { $0.id == card.id }) ?? false) {
            element.assignedCards?.append(card)
        }
        // Caller decides when to save
    }
    
    // Remove assignment from a specific element
    func unassignCard(_ card: Card, from element: StructureElement) {
        guard element.assignedCards != nil else { return }
        element.assignedCards?.removeAll { $0.id == card.id }
    }
    
    // Replace assignments with exactly the provided set
    func setAssignments(for card: Card, to elements: [StructureElement]) {
        // Remove from any elements not in the new set
        let current = Set((card.structureElements ?? []).map { $0.id })
        let desired = Set(elements.map { $0.id })
        
        // Remove from elements not desired
        for el in (card.structureElements ?? []) where !desired.contains(el.id) {
            el.assignedCards?.removeAll { $0.id == card.id }
        }
        // Add to desired elements not yet present
        for el in elements where !current.contains(el.id) {
            if el.assignedCards == nil { el.assignedCards = [] }
            el.assignedCards?.append(card)
        }
    }
}

// Predefined structure templates
extension StoryStructure {
    static let predefinedTemplates: [(name: String, elements: [String])] = [
        // Narrative templates
        ("Three-Act Structure", ["Act 1", "Act 2", "Act 3"]),
        ("Beginning-Middle-End", ["Beginning", "Middle", "End"]),
        ("Five-Act Structure", ["Exposition", "Rising Action", "Climax", "Falling Action", "Resolution"]),
        // Formal 12-stage Hero's Journey (Vogler-style)
        ("Hero's Journey (Formal)", [
            "Ordinary World",
            "Call to Adventure",
            "Refusal of the Call",
            "Meeting the Mentor",
            "Crossing the First Threshold",
            "Tests, Allies, Enemies",
            "Approach to the Inmost Cave",
            "Ordeal",
            "Reward (Seizing the Sword)",
            "The Road Back",
            "Resurrection",
            "Return with the Elixir"
        ]),
        // Retain the simplified variant for quick outlines
        ("Hero's Journey (Simplified)", ["Ordinary World", "Call to Adventure", "Trials", "Transformation", "Return"]),
        ("Four-Part Structure", ["Setup", "Confrontation", "Resolution", "Epilogue"]),
        ("Save the Cat", ["Opening Image", "Setup", "Catalyst", "Debate", "Break into Two", "B Story", "Fun and Games", "Midpoint", "Bad Guys Close In", "All Is Lost", "Dark Night of the Soul", "Break into Three", "Finale", "Final Image"]),
        
        // Novel (common beat-style outline)
        ("Novel", [
            "Opening Image",
            "Hook",
            "Inciting Incident",
            "Key Event",
            "First Plot Point",
            "First Pinch Point",
            "Midpoint",
            "Second Pinch Point",
            "Second Plot Point",
            "Climax",
            "Resolution",
            "Epilogue"
        ]),
        
        // Short Story (compact narrative arc)
        ("Short Story", [
            "Setup",
            "Inciting Incident",
            "Rising Action",
            "Climax",
            "Falling Action",
            "Resolution"
        ]),
        
        // Screenplay removed (duplicate of Save the Cat)
        // If desired later, add a distinct Screenplay variant (e.g., three-act/sequence method)
        
        // Term Paper (academic coursework)
        ("Term Paper", [
            "Title Page",
            "Abstract",
            "Introduction",
            "Literature Review",
            "Methodology",
            "Results",
            "Discussion",
            "Conclusion",
            "References",
            "Appendices"
        ]),
        
        // Academic Paper (IMRaD-style)
        ("Academic Paper", [
            "Title",
            "Abstract",
            "Keywords",
            "Introduction",
            "Methods",
            "Results",
            "Discussion",
            "Conclusion",
            "Acknowledgments",
            "References",
            "Supplementary Material"
        ]),
        
        // Technical Document (engineering/docs)
        ("Technical Document", [
            "Title",
            "Revision History",
            "Overview",
            "Requirements",
            "Architecture",
            "Design",
            "Implementation",
            "API Reference",
            "Usage Examples",
            "Configuration",
            "Deployment",
            "Troubleshooting",
            "Security Considerations",
            "Performance",
            "Glossary",
            "Appendix"
        ]),
        
        // White Paper (product/strategy)
        ("White Paper", [
            "Title",
            "Executive Summary",
            "Problem Statement",
            "Background",
            "Proposed Solution",
            "Benefits",
            "Implementation Considerations",
            "Case Studies",
            "Conclusion",
            "Call to Action",
            "References"
        ])
    ].sorted { lhs, rhs in
        lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
    
    static func createFromTemplate(_ template: (name: String, elements: [String]), for projectID: UUID? = nil) -> StoryStructure {
        let structure = StoryStructure(name: template.name, projectID: projectID)

        for (index, elementName) in template.elements.enumerated() {
            let element = StructureElement(name: elementName, orderIndex: index)
            element.storyStructure = structure            // ensure inverse
            if structure.elements == nil { structure.elements = [] }
            structure.elements?.append(element)
        }

        return structure
    }

    /// Returns the narrative arc for this structure
    ///
    /// Each story structure has an inherent dramatic tension or complexity curve.
    /// This arc is used for:
    /// 1. Dashboard visualization (sparkline with variable line thickness)
    /// 2. Scene mapping algorithm when switching between structures
    ///
    /// For custom structures, returns the user-defined CustomArc if available.
    /// For predefined structures, returns the associated arc type.
    /// Fallback: LinearArc (straight line).
    var narrativeArc: NarrativeArc {
        // If this is a custom structure with custom arc data, use that
        if let customArc = customArc {
            return customArc
        }

        // Otherwise use predefined arcs based on name
        switch name {
        // Narrative Structures
        case "Three-Act Structure":
            return ThreeActArc()
        case "Beginning-Middle-End":
            return BeginningMiddleEndArc()
        case "Five-Act Structure":
            return FiveActArc()
        case "Four-Part Structure":
            return FourPartArc()
        case "Hero's Journey (Formal)":
            return HerosJourneyFormalArc()
        case "Hero's Journey (Simplified)":
            return HerosJourneySimplifiedArc()
        case "Save the Cat":
            return SaveTheCatArc()
        case "Novel":
            return NovelArc()
        case "Short Story":
            return ShortStoryArc()

        // Non-Narrative Structures (Complexity-Based)
        case "Academic Paper":
            return AcademicPaperArc()
        case "Term Paper":
            return TermPaperArc()
        case "Technical Document":
            return TechnicalDocumentArc()
        case "White Paper":
            return WhitePaperArc()

        // Fallback for unrecognized structures
        default:
            return LinearArc()
        }
    }
}

