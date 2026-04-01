//
//  PromptExtractorTests.swift
//  CumberlandTests
//
//  Phase 10 tests for PromptExtractor (ER-0009).
//  Covers prompt extraction, variations, kind prefixes,
//  sensitive term handling, and visual keyword extraction.
//

import Testing
import Foundation
@testable import Cumberland

@Suite("PromptExtractor Tests")
struct PromptExtractorTests {

    // MARK: - Basic Prompt Extraction

    @Test("Extract prompt from character description")
    func extractCharacterPrompt() {
        let description = """
        A tall warrior with dark hair and piercing blue eyes. She wears a leather breastplate \
        over a crimson tunic and carries a silver longsword at her side. Her face bears a thin \
        scar across the left cheek from an old battle wound.
        """
        let prompt = PromptExtractor.extractPrompt(from: description, cardName: "Aria", cardKind: .characters)

        #expect(prompt != nil)
        #expect(prompt!.contains("Aria"))
        #expect(prompt!.contains("portrait"))
    }

    @Test("Extract prompt from location description")
    func extractLocationPrompt() {
        let description = """
        A vast desert stretching endlessly under a blazing sun. Golden sand dunes rise and fall \
        like frozen ocean waves. Sparse vegetation clings to life near the occasional oasis.
        """
        let prompt = PromptExtractor.extractPrompt(from: description, cardName: "Sunscorch Desert", cardKind: .locations)

        #expect(prompt != nil)
        #expect(prompt!.contains("Sunscorch Desert"))
        #expect(prompt!.lowercased().contains("landscape"))
    }

    @Test("Returns nil for description under 50 characters")
    func tooShortDescription() {
        let prompt = PromptExtractor.extractPrompt(from: "A dark cave.", cardName: "Cave", cardKind: .locations)
        #expect(prompt == nil)
    }

    // MARK: - Kind-Based Prefixes

    @Test("Character kind uses portrait prefix")
    func characterPrefix() {
        let prefix = PromptExtractor.kindToPromptPrefix(.characters)
        #expect(prefix.lowercased().contains("portrait"))
    }

    @Test("Location kind uses landscape prefix")
    func locationPrefix() {
        let prefix = PromptExtractor.kindToPromptPrefix(.locations)
        #expect(prefix.lowercased().contains("landscape"))
    }

    @Test("Building kind uses architectural prefix")
    func buildingPrefix() {
        let prefix = PromptExtractor.kindToPromptPrefix(.buildings)
        #expect(prefix.lowercased().contains("architectural"))
    }

    @Test("Vehicle kind uses technical prefix")
    func vehiclePrefix() {
        let prefix = PromptExtractor.kindToPromptPrefix(.vehicles)
        #expect(prefix.lowercased().contains("technical"))
    }

    @Test("Artifact kind uses rendering prefix")
    func artifactPrefix() {
        let prefix = PromptExtractor.kindToPromptPrefix(.artifacts)
        #expect(prefix.lowercased().contains("rendering"))
    }

    @Test("Default kind uses concept art prefix")
    func defaultPrefix() {
        let prefix = PromptExtractor.kindToPromptPrefix(.projects)
        #expect(prefix.lowercased().contains("concept"))
    }

    // MARK: - Prompt Variations

    @Test("Extract multiple prompt variations")
    func promptVariations() {
        let description = """
        A massive stone fortress perched on a cliff overlooking the dark ocean. Tall towers with \
        glowing windows pierce the cloudy sky. Ancient walls covered in green moss and ivy.
        """
        let variations = PromptExtractor.extractPromptVariations(
            from: description,
            cardName: "Stormhold",
            cardKind: .buildings
        )

        #expect(variations.count >= 2) // Should have detailed + simple at minimum
    }

    @Test("Variations empty for short description")
    func variationsEmpty() {
        let variations = PromptExtractor.extractPromptVariations(
            from: "Short.",
            cardName: "X",
            cardKind: .characters
        )
        #expect(variations.isEmpty)
    }

    // MARK: - Sensitive Term Handling

    @Test("Artifact with weapon name omits name from prompt")
    func weaponArtifactOmitsName() {
        let description = """
        A gleaming steel blade with an ornate golden hilt encrusted with emerald gems. The weapon \
        radiates a faint blue glow and ancient runes are etched along the fuller of the blade.
        """
        let prompt = PromptExtractor.extractPrompt(
            from: description,
            cardName: "Shadowblade Sword",
            cardKind: .artifacts
        )

        #expect(prompt != nil)
        // For weapon-named artifacts, the prompt should lead with description, not the name
        #expect(!prompt!.hasPrefix("A detailed rendering of Shadowblade Sword"))
    }

    @Test("Non-weapon artifact includes name normally")
    func nonWeaponArtifactIncludesName() {
        let description = """
        A large leather-bound tome with gold leaf lettering on the cover. The ancient book contains \
        maps and diagrams of forgotten kingdoms. Its pages are yellowed with age but still legible.
        """
        let prompt = PromptExtractor.extractPrompt(
            from: description,
            cardName: "Tome of Ages",
            cardKind: .artifacts
        )

        #expect(prompt != nil)
        #expect(prompt!.contains("Tome of Ages"))
    }

    // MARK: - Dialogue Filtering

    @Test("Dialogue is filtered from prompts")
    func dialogueFiltered() {
        let description = """
        A grand throne room with towering marble pillars and a golden ceiling. \
        "Who goes there?" asked the guard. "I am the rightful heir," she said loudly. \
        The floor is polished obsidian that reflects the light from crystal chandeliers above.
        """
        let prompt = PromptExtractor.extractPrompt(
            from: description,
            cardName: "Throne Room",
            cardKind: .buildings
        )

        #expect(prompt != nil)
        // Prompt should contain visual descriptions but not dialogue
        #expect(!prompt!.contains("Who goes there"))
    }

    // MARK: - Visual Keyword Categories

    @Test("VisualKeyword displayValue returns correct value")
    func visualKeywordDisplay() {
        let color = PromptExtractor.VisualKeyword.color("red")
        let mood = PromptExtractor.VisualKeyword.mood("dark")
        let material = PromptExtractor.VisualKeyword.material("stone")
        let physical = PromptExtractor.VisualKeyword.physical("tall")
        let lighting = PromptExtractor.VisualKeyword.lighting("glowing")

        #expect(color.displayValue == "red")
        #expect(mood.displayValue == "dark")
        #expect(material.displayValue == "stone")
        #expect(physical.displayValue == "tall")
        #expect(lighting.displayValue == "glowing")
    }
}
