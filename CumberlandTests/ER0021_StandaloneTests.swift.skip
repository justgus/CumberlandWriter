//
//  ER0021_StandaloneTests.swift
//  CumberlandTests
//
//  Standalone tests for ER-0021 that test core functionality.
//  Can be run independently of full app build.
//
//  Swift Testing suite for the VisualElements data model (ER-0021). Tests
//  property assignment for all card kinds (character, location, building,
//  artifact, scene, vehicle), cinematic framing enum display names, the
//  hasSufficientData threshold helper, Codable round-trip encoding, and
//  prompt generation methods for Apple Intelligence, OpenAI, and Anthropic.
//

import Foundation
import Testing

/// Standalone tests for ER-0021 VisualElements model
/// These tests verify the data model works correctly independent of extraction logic
struct ER0021_VisualElementsModelTests {

    // MARK: - VisualElements Creation Tests

    @Test
    func testVisualElementsInitialization() {
        let elements = VisualElements(
            sourceText: "A tall warrior with dark hair",
            cardKind: Kinds.characters,
            extractionConfidence: 0.75
        )

        #expect(elements.sourceText == "A tall warrior with dark hair")
        #expect(elements.cardKind == .characters)
        #expect(elements.extractionConfidence == 0.75)
        #expect(elements.extractedAt != nil)
    }

    @Test
    func testCharacterPropertiesAssignment() {
        var elements = VisualElements(
            sourceText: "Test",
            cardKind: Kinds.characters,
            extractionConfidence: 0.8
        )

        elements.physicalBuild = "tall, athletic"
        elements.hair = "long dark hair"
        elements.eyes = "bright green eyes"
        elements.clothing = "leather armor"
        elements.expression = "confident smile"

        #expect(elements.physicalBuild == "tall, athletic")
        #expect(elements.hair == "long dark hair")
        #expect(elements.eyes == "bright green eyes")
        #expect(elements.clothing == "leather armor")
        #expect(elements.expression == "confident smile")
    }

    @Test
    func testLocationPropertiesAssignment() {
        var elements = VisualElements(
            sourceText: "Test",
            cardKind: Kinds.locations,
            extractionConfidence: 0.7
        )

        elements.primaryFeatures = ["rolling hills", "ancient forest"]
        elements.scale = "vast, expansive"
        elements.architecture = "stone cottages"
        elements.vegetation = "oak trees, wildflowers"

        #expect(elements.primaryFeatures?.count == 2)
        #expect(elements.scale == "vast, expansive")
        #expect(elements.architecture == "stone cottages")
        #expect(elements.vegetation == "oak trees, wildflowers")
    }

    @Test
    func testBuildingPropertiesAssignment() {
        var elements = VisualElements(
            sourceText: "Test",
            cardKind: Kinds.buildings,
            extractionConfidence: 0.8
        )

        elements.architecturalStyle = "gothic cathedral"
        elements.narrativeImportance = "grand"
        elements.scale = "towering, massive"
        elements.cameraAngle = .lowAngleLookingUp
        elements.framing = .wideEstablishing

        #expect(elements.architecturalStyle == "gothic cathedral")
        #expect(elements.narrativeImportance == "grand")
        #expect(elements.cameraAngle == .lowAngleLookingUp)
        #expect(elements.framing == .wideEstablishing)
    }

    @Test
    func testArtifactPropertiesAssignment() {
        var elements = VisualElements(
            sourceText: "Test",
            cardKind: Kinds.artifacts,
            extractionConfidence: 0.75
        )

        elements.objectType = "ancient sword"
        elements.materials = ["dark metal", "glowing crystal"]
        elements.condition = "pristine"
        elements.showPartial = "hilt only"
        elements.framing = .closeUp
        elements.lightingStyle = .dramatic

        #expect(elements.objectType == "ancient sword")
        #expect(elements.materials?.count == 2)
        #expect(elements.showPartial == "hilt only")
        #expect(elements.framing == .closeUp)
        #expect(elements.lightingStyle == .dramatic)
    }

    @Test
    func testScenePropertiesAssignment() {
        var elements = VisualElements(
            sourceText: "Test",
            cardKind: Kinds.scenes,
            extractionConfidence: 0.7
        )

        elements.isSceneWithMood = true
        elements.mood = "tense, confrontational"
        elements.atmosphere = "foggy, mysterious"
        elements.lightingStyle = .dark
        elements.colors = ["deep shadows", "muted blues"]

        #expect(elements.isSceneWithMood == true)
        #expect(elements.mood == "tense, confrontational")
        #expect(elements.lightingStyle == .dark)
        #expect(elements.colors?.count == 2)
    }

    @Test
    func testVehiclePropertiesAssignment() {
        var elements = VisualElements(
            sourceText: "Test",
            cardKind: Kinds.vehicles,
            extractionConfidence: 0.8
        )

        elements.vehicleType = "airship"
        elements.vehicleDesign = "sleek hull with ornate decorations"
        elements.scale = "massive"
        elements.motionState = "in flight"
        elements.materials = ["polished wood", "brass fittings"]

        #expect(elements.vehicleType == "airship")
        #expect(elements.vehicleDesign == "sleek hull with ornate decorations")
        #expect(elements.motionState == "in flight")
        #expect(elements.materials?.count == 2)
    }

    // MARK: - Cinematic Framing Tests

    @Test
    func testCameraAngleEnum() {
        #expect(CameraAngle.lowAngleLookingUp.displayName == "low angle shot looking up")
        #expect(CameraAngle.highAngleLookingDown.displayName == "high angle shot looking down")
        #expect(CameraAngle.eyeLevel.displayName == "eye-level perspective")
        #expect(CameraAngle.aerialView.displayName == "aerial view")
        #expect(CameraAngle.dramaticAngle.displayName == "dramatic angle")
    }

    @Test
    func testFramingEnum() {
        #expect(Framing.closeUp.displayName == "close-up")
        #expect(Framing.mediumShot.displayName == "medium shot")
        #expect(Framing.fullShot.displayName == "full shot")
        #expect(Framing.wideEstablishing.displayName == "wide establishing shot")
    }

    @Test
    func testLightingStyleEnum() {
        #expect(LightingStyle.dramatic.description == "dramatic lighting with strong shadows")
        #expect(LightingStyle.soft.description == "soft warm lighting")
        #expect(LightingStyle.neutral.description == "neutral even lighting")
        #expect(LightingStyle.dark.description == "dark moody lighting")
        #expect(LightingStyle.bright.description == "bright cheerful lighting")
    }

    // MARK: - Helper Properties Tests

    @Test
    func testHasSufficientDataEmpty() {
        let elements = VisualElements(
            sourceText: "Test",
            cardKind: Kinds.characters,
            extractionConfidence: 0.5
        )

        #expect(elements.hasSufficientData == false, "Empty elements should not have sufficient data")
    }

    @Test
    func testHasSufficientDataWithProperties() {
        var elements = VisualElements(
            sourceText: "Test",
            cardKind: Kinds.characters,
            extractionConfidence: 0.7
        )

        elements.physicalBuild = "tall"
        elements.hair = "dark"
        elements.eyes = "green"
        elements.clothing = "armor"

        #expect(elements.hasSufficientData == true, "Elements with 4+ properties should have sufficient data")
    }

    @Test
    func testHasSufficientDataSparseProperties() {
        var elements = VisualElements(
            sourceText: "Test",
            cardKind: Kinds.characters,
            extractionConfidence: 0.5
        )

        elements.physicalBuild = "tall"
        elements.hair = "dark"

        #expect(elements.hasSufficientData == false, "Elements with <3 properties should not have sufficient data")
    }

    // MARK: - Codable Tests

    @Test
    func testCodableRoundTrip() throws {
        var original = VisualElements(
            sourceText: "A grand cathedral with soaring spires",
            cardKind: Kinds.buildings,
            extractionConfidence: 0.85
        )

        original.architecturalStyle = "gothic"
        original.scale = "massive, towering"
        original.cameraAngle = .lowAngleLookingUp
        original.framing = .wideEstablishing
        original.lightingStyle = .dramatic
        original.materials = ["stone", "stained glass"]

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(VisualElements.self, from: data)

        // Verify
        #expect(decoded.sourceText == original.sourceText)
        #expect(decoded.cardKind == original.cardKind)
        #expect(decoded.extractionConfidence == original.extractionConfidence)
        #expect(decoded.architecturalStyle == original.architecturalStyle)
        #expect(decoded.scale == original.scale)
        #expect(decoded.cameraAngle == original.cameraAngle)
        #expect(decoded.framing == original.framing)
        #expect(decoded.lightingStyle == original.lightingStyle)
        #expect(decoded.materials?.count == 2)
    }

    @Test
    func testCodableWithOptionalNilValues() throws {
        let original = VisualElements(
            sourceText: "Minimal description",
            cardKind: Kinds.characters,
            extractionConfidence: 0.4
        )

        // Encode with mostly nil values
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(VisualElements.self, from: data)

        // Verify nil values preserved
        #expect(decoded.physicalBuild == nil)
        #expect(decoded.hair == nil)
        #expect(decoded.eyes == nil)
        #expect(decoded.clothing == nil)
        #expect(decoded.cameraAngle == nil)
    }

    // MARK: - Prompt Generation Tests (Basic)

    @Test
    func testAppleIntelligenceConceptsNotEmpty() {
        var elements = VisualElements(
            sourceText: "A tall warrior with long dark hair",
            cardKind: Kinds.characters,
            extractionConfidence: 0.8
        )

        elements.physicalBuild = "tall, athletic"
        elements.hair = "long dark hair"
        elements.clothing = "leather armor"

        let concepts = elements.generateConceptsForAppleIntelligence()

        #expect(concepts.count > 0, "Should generate at least one concept")

        // Verify each concept is within Apple Intelligence limit
        for concept in concepts {
            #expect(concept.count <= 95, "Each concept should be <= 95 chars for Apple Intelligence")
        }
    }

    @Test
    func testOpenAIPromptGeneration() {
        var elements = VisualElements(
            sourceText: "A grand gothic cathedral",
            cardKind: Kinds.buildings,
            extractionConfidence: 0.85
        )

        elements.architecturalStyle = "gothic"
        elements.scale = "massive"
        elements.cameraAngle = .lowAngleLookingUp
        elements.framing = .wideEstablishing

        let prompt = elements.generatePromptForOpenAI()

        #expect(prompt.count > 0, "Should generate non-empty prompt")
        #expect(prompt.lowercased().contains("gothic"), "Should include architectural style")
        #expect(prompt.lowercased().contains("building") || prompt.lowercased().contains("cathedral"), "Should mention subject")
    }

    @Test
    func testAnthropicPromptGeneration() {
        var elements = VisualElements(
            sourceText: "Ancient sword with glowing runes",
            cardKind: Kinds.artifacts,
            extractionConfidence: 0.8
        )

        elements.objectType = "sword"
        elements.materials = ["ancient metal"]
        elements.lightingStyle = .dramatic

        let prompt = elements.generatePromptForAnthropic()

        #expect(prompt.count > 0, "Should generate non-empty prompt")
        #expect(prompt.lowercased().contains("sword"), "Should include object type")
    }
}
