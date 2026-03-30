//
//  TestFixtures.swift
//  CumberlandTests
//
//  Shared test data for ER-0008 (Timeline), ER-0009 (Image Generation), and
//  ER-0010 (Content Analysis) test suites. Provides sample CalendarSystem
//  objects (Gregorian, Eldarian, Galactic Standard), rich narrative descriptions
//  for entity/relationship/calendar extraction tests, sample Card factory
//  methods, and mock AI response JSON strings.
//

import Foundation
import SwiftData
@testable import Cumberland

/// Test fixtures for ER-0008, ER-0009, ER-0010 testing
/// Provides sample data for use across test suites
enum TestFixtures {

    // MARK: - ER-0008: Calendar Systems

    /// Standard Gregorian calendar for testing
    static var gregorianCalendar: CalendarSystem {
        CalendarSystem(
            name: "Gregorian",
            divisions: [
                TimeDivision(name: "second", pluralName: "seconds", length: 60, isVariable: false),
                TimeDivision(name: "minute", pluralName: "minutes", length: 60, isVariable: false),
                TimeDivision(name: "hour", pluralName: "hours", length: 24, isVariable: false),
                TimeDivision(name: "day", pluralName: "days", length: 7, isVariable: false),
                TimeDivision(name: "week", pluralName: "weeks", length: 4, isVariable: true),
                TimeDivision(name: "month", pluralName: "months", length: 12, isVariable: true),
                TimeDivision(name: "year", pluralName: "years", length: 10, isVariable: false),
                TimeDivision(name: "decade", pluralName: "decades", length: 10, isVariable: false),
                TimeDivision(name: "century", pluralName: "centuries", length: 10, isVariable: false)
            ]
        )
    }

    /// Fantasy calendar for testing custom time systems
    static var eldarianCalendar: CalendarSystem {
        CalendarSystem(
            name: "Eldarian Calendar",
            divisions: [
                TimeDivision(name: "moment", pluralName: "moments", length: 100, isVariable: false),
                TimeDivision(name: "cycle", pluralName: "cycles", length: 10, isVariable: false),
                TimeDivision(name: "shift", pluralName: "shifts", length: 2, isVariable: false), // day/night
                TimeDivision(name: "day", pluralName: "days", length: 28, isVariable: false),
                TimeDivision(name: "moon", pluralName: "moons", length: 13, isVariable: false),
                TimeDivision(name: "year", pluralName: "years", length: 100, isVariable: false),
                TimeDivision(name: "age", pluralName: "ages", length: 1, isVariable: false) // Era
            ]
        )
    }

    /// Sci-fi calendar for testing
    static var galacticStandardCalendar: CalendarSystem {
        CalendarSystem(
            name: "Galactic Standard Time",
            divisions: [
                TimeDivision(name: "cycle", pluralName: "cycles", length: 100, isVariable: false),
                TimeDivision(name: "shift", pluralName: "shifts", length: 10, isVariable: false),
                TimeDivision(name: "rotation", pluralName: "rotations", length: 100, isVariable: false),
                TimeDivision(name: "orbit", pluralName: "orbits", length: 500, isVariable: false),
                TimeDivision(name: "epoch", pluralName: "epochs", length: 1000, isVariable: false)
            ]
        )
    }

    // MARK: - ER-0008: Scene Descriptions for Timeline Testing

    /// Scene description with temporal references
    static let temporalSceneDescription = """
    The Council of Elders convened on the thirteenth moon of the year 1,247 \
    in the Age of Starlight. The meeting began at the third cycle after dawn \
    and lasted for five cycles, during which the fate of the realm was debated.
    """

    /// Scene description with ordinal references (backward compatibility)
    static let ordinalSceneDescription = """
    In the beginning, there was chaos. Then came order. Finally, peace.
    """

    // MARK: - ER-0009: Image Generation Test Data

    /// Prompt for testing image generation
    static let characterImagePrompt = """
    Portrait of a noble elven warrior with silver hair and piercing blue eyes, \
    wearing ornate silver armor adorned with celestial motifs, standing in a \
    moonlit forest clearing
    """

    /// Prompt for location image generation
    static let locationImagePrompt = """
    Sprawling fantasy cityscape built into towering crystalline cliffs, with \
    glowing bridges connecting spires, waterfalls cascading between levels, \
    painted in warm sunset colors
    """

    /// Prompt for artifact image generation
    static let artifactImagePrompt = """
    Ancient sword with a blade of starlight, wrapped in ethereal blue flames, \
    resting on a pedestal of dark stone, surrounded by magical runes
    """

    // MARK: - ER-0010: Content Analysis Test Descriptions

    /// Rich character description for entity extraction
    static let richCharacterDescription = """
    Sir Aldric the Bold, Knight-Commander of the Silver Legion, stood before \
    the throne of Queen Elara in the Grand Hall of Thornhaven. His companion, \
    the ranger Marcus Swiftwind, waited by the massive oak doors. Aldric carried \
    the legendary Sword of Dawn, a gift from the ancient wizard Merlin, keeper \
    of the Eternal Flame. His armor bore the crest of House Valorian, a silver \
    lion on a field of blue.
    """

    /// Location-rich description for entity extraction
    static let richLocationDescription = """
    The caravan departed from the bustling port city of Westport at dawn, \
    traveling through the Whispering Woods where the ancient trees spoke in \
    forgotten tongues. By midday, they reached the ruins of Kael'thas, the \
    fallen capital of the First Empire. In the distance, the Crystal Mountains \
    gleamed under the twin suns, and beyond them lay the Shadowlands, a place \
    no traveler returned from.
    """

    /// Artifact-rich description for entity extraction
    static let richArtifactDescription = """
    The hero's inventory included the Amulet of Protection, gifted by the druids, \
    the Staff of Elements wielded by the archmage, and the Shield of Ancients \
    recovered from the Temple of Storms. Most precious was the Ring of Kings, \
    a relic from the Age of Heroes, said to grant its bearer dominion over time itself.
    """

    /// Description with relationships for inference testing
    static let relationshipRichDescription = """
    Captain Sarah Reynolds commanded the USS Voyager from her seat on the bridge. \
    Her first officer, Commander James Chen, stood beside her, reviewing star charts \
    with the ship's AI, Aether. Reynolds was born on Mars Colony and trained at \
    Starfleet Academy on Earth. She drew her sidearm, a plasma pistol issued to all \
    command officers, and nodded to Chen. Together, they had served aboard the Voyager \
    for five years, exploring the Andromeda Sector.
    """

    /// Description with calendar references for extraction testing
    static let calendarExtractionDescription = """
    The Eldarian year consists of thirteen moons, each moon containing exactly \
    twenty-eight days. Each day is divided into ten cycles, and each cycle into \
    one hundred moments. The current era, known as the Age of Starlight, began \
    one thousand years ago when the First Star fell from the heavens. The ancient \
    calendars speak of previous ages: the Age of Ice, lasting three thousand years, \
    and before that, the Age of Fire, which endured for five hundred years. Each age \
    begins with a great celestial event visible across the realm. Major festivals \
    include the Festival of First Light on the first day of the first moon, and \
    the Harvest of Stars on the twenty-eighth day of the thirteenth moon.
    """

    /// Short description below minimum length
    static let tooShortDescription = "A hero with a sword."

    /// Empty description
    static let emptyDescription = ""

    // MARK: - Service-Layer Card Creation Helper (DR-0102)

    /// Creates a card through CardOperationManager, matching production code paths.
    /// Falls back to direct construction when no context is provided (pure model tests).
    @MainActor
    private static func createCardViaManager(
        kind: Kinds,
        name: String,
        subtitle: String,
        detailedText: String,
        context: ModelContext?
    ) -> Card {
        if let context = context {
            let mgr = CardOperationManager(modelContext: context)
            // Service handles insert + save
            if let card = try? mgr.createCard(kind: kind, name: name, subtitle: subtitle, detailedText: detailedText) {
                return card
            }
        }
        // No context provided or manager threw — return unmanaged card for pure model tests
        return Card(kind: kind, name: name, subtitle: subtitle, detailedText: detailedText)
    }

    // MARK: - Sample Cards for Testing

    /// Create a sample character card
    @MainActor
    static func createSampleCharacter(name: String = "Sir Aldric", context: ModelContext? = nil) -> Card {
        createCardViaManager(
            kind: .characters,
            name: name,
            subtitle: "Knight-Commander",
            detailedText: richCharacterDescription,
            context: context
        )
    }

    /// Create a sample location card
    @MainActor
    static func createSampleLocation(name: String = "Westport", context: ModelContext? = nil) -> Card {
        createCardViaManager(
            kind: .locations,
            name: name,
            subtitle: "Port City",
            detailedText: "A bustling port city on the western coast, known for its shipyards and markets.",
            context: context
        )
    }

    /// Create a sample timeline card
    /// Note: calendarSystem, epochDate, and epochDescription properties will be added in AppSchemaV6
    /// For now, this creates a basic timeline card with the calendar info in detailedText
    @MainActor
    static func createSampleTimeline(name: String = "Main Timeline", calendar: CalendarSystem? = nil, context: ModelContext? = nil) -> Card {
        var detailedText = "The beginning of the Age of Starlight"

        if let calendar = calendar {
            detailedText += "\n\nCalendar System: \(calendar.name)"
            detailedText += "\nEpoch: January 1, 1970"
        }

        return createCardViaManager(
            kind: .timelines,
            name: name,
            subtitle: calendar?.name ?? "",
            detailedText: detailedText,
            context: context
        )
    }

    /// Create a sample scene card
    @MainActor
    static func createSampleScene(name: String = "The Council Meeting", context: ModelContext? = nil) -> Card {
        createCardViaManager(
            kind: .scenes,
            name: name,
            subtitle: "",
            detailedText: temporalSceneDescription,
            context: context
        )
    }

    // MARK: - Mock AI Responses

    /// Mock entity extraction result
    static let mockEntityExtractionResult = """
    {
        "entities": [
            {
                "name": "Sir Aldric the Bold",
                "type": "Character",
                "confidence": 0.95,
                "context": "Knight-Commander of the Silver Legion"
            },
            {
                "name": "Queen Elara",
                "type": "Character",
                "confidence": 0.92,
                "context": "ruler, on throne"
            },
            {
                "name": "Marcus Swiftwind",
                "type": "Character",
                "confidence": 0.90,
                "context": "ranger, companion"
            },
            {
                "name": "Thornhaven",
                "type": "Location",
                "confidence": 0.88,
                "context": "has Grand Hall"
            },
            {
                "name": "Sword of Dawn",
                "type": "Artifact",
                "confidence": 0.93,
                "context": "legendary, carried by Aldric"
            }
        ]
    }
    """

    /// Mock relationship inference result
    static let mockRelationshipInferenceResult = """
    {
        "relationships": [
            {
                "source": "Sir Aldric",
                "target": "Sword of Dawn",
                "type": "owns",
                "confidence": 0.91
            },
            {
                "source": "Sir Aldric",
                "target": "Thornhaven",
                "type": "location",
                "confidence": 0.85
            },
            {
                "source": "Sir Aldric",
                "target": "Marcus Swiftwind",
                "type": "companion",
                "confidence": 0.92
            }
        ]
    }
    """

    // MARK: - Full Schema Container Helper

    /// Returns the host app's `ModelContainer` and a fresh `ModelContext`.
    ///
    /// **DR-0102 (2026-03-29):** CumberlandTests is a *hosted* test bundle —
    /// Cumberland.app launches first and creates the process-wide
    /// `ModelContainer`. Creating a *second* container in the same process
    /// (even with an identical schema) causes SwiftData to hit an internal
    /// precondition failure (`EXC_BREAKPOINT` on `context.insert()`).
    ///
    /// The fix: reuse the host app's container via
    /// `CumberlandApp.sharedContainer` and hand each test a new
    /// `ModelContext` so tests don't pollute each other.
    @MainActor
    static func makeFullSchemaContainer() throws -> (ModelContainer, ModelContext) {
        guard let container = CumberlandApp.sharedContainer else {
            fatalError("CumberlandApp.sharedContainer is nil — tests must run inside the hosted app.")
        }
        let context = ModelContext(container)
        context.autosaveEnabled = false

        // Wipe all data so each test starts with a clean store.
        // Delete in dependency order: edges first, then nodes, then top-level entities.
        try context.delete(model: CardEdge.self)
        try context.delete(model: BoardNode.self)
        try context.delete(model: Citation.self)
        try context.delete(model: StructureElement.self)
        try context.delete(model: StoryStructure.self)
        try context.delete(model: Board.self)
        try context.delete(model: ImageVersion.self)
        try context.delete(model: Source.self)
        try context.delete(model: RelationType.self)
        try context.delete(model: Card.self)
        try context.delete(model: CalendarSystem.self)
        try context.delete(model: AppSettings.self)
        try context.save()

        return (container, context)
    }

    // MARK: - Additional Card Factories

    /// Create a sample artifact card
    @MainActor
    static func createSampleArtifact(name: String = "Sword of Dawn", context: ModelContext? = nil) -> Card {
        createCardViaManager(
            kind: .artifacts,
            name: name,
            subtitle: "Legendary Weapon",
            detailedText: "A blade of starlight, forged in the First Age.",
            context: context
        )
    }

    // MARK: - RelationType Factory (DR-0105: delegates to RelationTypeManager)

    @MainActor
    static func createRelationType(
        code: String = "owns/owned-by",
        forward: String = "owns",
        inverse: String = "owned-by",
        sourceKind: Kinds? = nil,
        targetKind: Kinds? = nil,
        context: ModelContext
    ) -> RelationType {
        let mgr = RelationTypeManager(modelContext: context)
        return mgr.ensureRelationType(
            code: code,
            forwardLabel: forward,
            inverseLabel: inverse,
            sourceKind: sourceKind,
            targetKind: targetKind
        )
    }

    // MARK: - Board Factory (DR-0105: delegates to BoardManager)

    @MainActor
    static func createBoard(name: String = "Test Board", primaryCard: Card? = nil, context: ModelContext) -> Board {
        let mgr = BoardManager(modelContext: context)
        return (try? mgr.createBoard(name: name, primaryCard: primaryCard)) ?? Board(name: name, primaryCard: primaryCard)
    }

    // MARK: - Edge Factory (DR-0105: delegates to RelationshipManager)

    @MainActor
    @discardableResult
    static func createEdge(from source: Card, to target: Card, type: RelationType, context: ModelContext) -> CardEdge {
        let mgr = RelationshipManager(modelContext: context)
        if let edge = try? mgr.createRelationship(from: source, to: target, type: type, createReverse: false) {
            return edge
        }
        // Fallback for duplicate-exists case — fetch the existing edge
        let srcID: UUID? = source.id
        let dstID: UUID? = target.id
        let typeCode: String? = type.code
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == srcID && $0.to?.id == dstID && $0.type?.code == typeCode }
        )
        if let existing = try? context.fetch(fetch).first {
            return existing
        }
        // Last resort: raw insert (shouldn't reach here)
        let edge = CardEdge(from: source, to: target, type: type)
        context.insert(edge)
        try? context.save()
        return edge
    }

    /// Mock calendar extraction result
    static let mockCalendarExtractionResult = """
    {
        "calendar": {
            "name": "Eldarian Calendar",
            "divisions": [
                {"name": "moment", "plural": "moments", "length": 100, "variable": false},
                {"name": "cycle", "plural": "cycles", "length": 10, "variable": false},
                {"name": "day", "plural": "days", "length": 28, "variable": false},
                {"name": "moon", "plural": "moons", "length": 13, "variable": false},
                {"name": "year", "plural": "years", "length": 1000, "variable": false},
                {"name": "age", "plural": "ages", "length": 1, "variable": false}
            ],
            "eras": [
                "Age of Starlight",
                "Age of Ice",
                "Age of Fire"
            ],
            "festivals": [
                "Festival of First Light",
                "Harvest of Stars"
            ]
        }
    }
    """
}
