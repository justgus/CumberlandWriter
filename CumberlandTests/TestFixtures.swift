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

    // MARK: - Sample Cards for Testing

    /// Create a sample character card
    static func createSampleCharacter(name: String = "Sir Aldric", context: ModelContext? = nil) -> Card {
        let card = Card(
            kind: .characters,
            name: name,
            subtitle: "Knight-Commander",
            detailedText: richCharacterDescription
        )

        if let context = context {
            context.insert(card)
        }

        return card
    }

    /// Create a sample location card
    static func createSampleLocation(name: String = "Westport", context: ModelContext? = nil) -> Card {
        let card = Card(
            kind: .locations,
            name: name,
            subtitle: "Port City",
            detailedText: "A bustling port city on the western coast, known for its shipyards and markets."
        )

        if let context = context {
            context.insert(card)
        }

        return card
    }

    /// Create a sample timeline card
    /// Note: calendarSystem, epochDate, and epochDescription properties will be added in AppSchemaV6
    /// For now, this creates a basic timeline card with the calendar info in detailedText
    static func createSampleTimeline(name: String = "Main Timeline", calendar: CalendarSystem? = nil, context: ModelContext? = nil) -> Card {
        var detailedText = "The beginning of the Age of Starlight"
        
        if let calendar = calendar {
            detailedText += "\n\nCalendar System: \(calendar.name)"
            detailedText += "\nEpoch: January 1, 1970"
        }
        
        let card = Card(
            kind: .timelines,
            name: name,
            subtitle: calendar?.name ?? "",
            detailedText: detailedText
        )

        if let context = context {
            context.insert(card)
        }

        return card
    }

    /// Create a sample scene card
    static func createSampleScene(name: String = "The Council Meeting", context: ModelContext? = nil) -> Card {
        let card = Card(
            kind: .scenes,
            name: name,
            subtitle: "",
            detailedText: temporalSceneDescription
        )

        if let context = context {
            context.insert(card)
        }

        return card
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
