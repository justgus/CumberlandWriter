//
//  VisualElementExtractorTests.swift
//  CumberlandTests
//
//  Created for ER-0021: AI-Powered Visual Element Extraction
//  Phase 1: Core Infrastructure Tests
//
//  Swift Testing suite that exercises VisualElementExtractor end-to-end using
//  the AppleIntelligenceProvider. Covers character, building, scene, and artifact
//  extraction; camera angle inference for grand vs. humble buildings; partial
//  object detection; validation of empty/short input; and prompt generation
//  for Apple Intelligence, OpenAI, and Anthropic providers. Also tests Codable
//  round-trip and hasSufficientData helper.
//

import Foundation
import Testing
@testable import Cumberland

struct VisualElementExtractorTests {

    // MARK: - Test Data

    /// Captain Evilin Drake - Character description from ER-0021 test plan
    let captainDrakeDescription = """
    Captain Evilin Drake is a tall woman with long straight dark hair that she
    wears in a ponytail most days. Lithe and thin, she can be seen most days
    wearing her orange astronaut's jumpsuit. She is quick to laugh, with a
    strong chin, short nose, bright green eyes. She grew up on Mars Colony
    Seven and spent ten years commanding deep space missions before retiring
    to teach at the Interplanetary Academy.
    """

    /// Grand building description - Tests low angle camera inference
    let grandBuildingDescription = """
    The Magic Academy of Felthome stands as an imposing structure with grand
    gates and soaring towers that pierce the sky. Its majestic stone walls
    are adorned with ancient runes that glow softly in the moonlight.
    """

    /// Humble building description - Tests high angle camera inference
    let humbleShackDescription = """
    A small thatched shack sits on the outskirts of the village, its modest
    walls barely holding together. The humble dwelling has seen better days,
    with a tiny window and a simple wooden door.
    """

    /// Tense scene description - Tests dark lighting inference
    let tenseSceneDescription = """
    At La Porte Cafe, a tense confrontation unfolds between rival gang leaders.
    The argument escalates as accusations fly across the dimly lit room, shadows
    dancing on the walls as the standoff intensifies.
    """

    /// Artifact with partial description - Tests partial object handling
    let artifactPartialDescription = """
    The hilt of the legendary Shadowblade is crafted from ancient metal, with
    intricate runes carved into its surface and a glowing crystal embedded at
    its pommel.
    """

    // MARK: - Basic Extraction Tests

    @Test
    func testCharacterExtraction() async throws {
        let provider = AppleIntelligenceProvider()
        let extractor = VisualElementExtractor(provider: provider)

        let elements = try await extractor.extractVisualElements(
            from: captainDrakeDescription,
            cardKind: .characters
        )

        // Verify basic properties
        #expect(elements.cardKind == .characters)
        #expect(elements.extractionConfidence > 0.0)
        #expect(elements.sourceText == captainDrakeDescription)

        // Verify physical build extraction
        #expect(elements.physicalBuild != nil, "Should extract physical build")
        if let build = elements.physicalBuild {
            #expect(build.lowercased().contains("tall") || build.lowercased().contains("lithe"))
        }

        // Verify hair extraction
        #expect(elements.hair != nil, "Should extract hair description")
        if let hair = elements.hair {
            #expect(hair.lowercased().contains("hair"))
        }

        // Verify eyes extraction
        #expect(elements.eyes != nil, "Should extract eye description")
        if let eyes = elements.eyes {
            #expect(eyes.lowercased().contains("eyes") || eyes.lowercased().contains("green"))
        }

        // Verify clothing extraction
        #expect(elements.clothing != nil, "Should extract clothing")
        if let clothing = elements.clothing {
            #expect(clothing.lowercased().contains("jumpsuit") || clothing.lowercased().contains("orange"))
        }

        // Verify expression inference (from "quick to laugh")
        #expect(elements.expression != nil, "Should infer expression from personality")
        if let expression = elements.expression {
            #expect(expression.lowercased().contains("friendly") || expression.lowercased().contains("smile"))
        }

        // Verify backstory is NOT extracted as visual elements
        #expect(elements.physicalBuild?.contains("Mars Colony") == nil, "Should filter out backstory")
        #expect(elements.clothing?.contains("Interplanetary Academy") == nil, "Should filter out education")
    }

    @Test
    func testGrandBuildingCameraAngle() async throws {
        let provider = AppleIntelligenceProvider()
        let extractor = VisualElementExtractor(provider: provider)

        let elements = try await extractor.extractVisualElements(
            from: grandBuildingDescription,
            cardKind: .buildings
        )

        // Verify low angle camera for grand buildings
        #expect(elements.cameraAngle == .lowAngleLookingUp, "Grand buildings should use low angle shot")
        #expect(elements.narrativeImportance == "grand")
        #expect(elements.framing == .wideEstablishing)
    }

    @Test
    func testHumbleBuildingCameraAngle() async throws {
        let provider = AppleIntelligenceProvider()
        let extractor = VisualElementExtractor(provider: provider)

        let elements = try await extractor.extractVisualElements(
            from: humbleShackDescription,
            cardKind: .buildings
        )

        // Verify high angle camera for humble buildings
        #expect(elements.cameraAngle == .highAngleLookingDown, "Humble buildings should use high angle shot")
        #expect(elements.narrativeImportance == "humble")
        #expect(elements.framing == .wideEstablishing)
    }

    @Test
    func testSceneMoodInference() async throws {
        let provider = AppleIntelligenceProvider()
        let extractor = VisualElementExtractor(provider: provider)

        let elements = try await extractor.extractVisualElements(
            from: tenseSceneDescription,
            cardKind: .scenes
        )

        // Verify scene mood extraction
        #expect(elements.isSceneWithMood == true, "Scenes should be marked as having mood")
        #expect(elements.mood != nil, "Should extract mood from scene")
        #expect(elements.lightingStyle == .dark, "Tense scenes should use dark lighting")
    }

    @Test
    func testArtifactPartialExtraction() async throws {
        let provider = AppleIntelligenceProvider()
        let extractor = VisualElementExtractor(provider: provider)

        let elements = try await extractor.extractVisualElements(
            from: artifactPartialDescription,
            cardKind: .artifacts
        )

        // Verify partial object handling
        #expect(elements.showPartial == "hilt only", "Should recognize partial object description")
        #expect(elements.framing == .closeUp, "Partial objects should use close-up framing")
    }

    // MARK: - Validation Tests

    @Test
    func testEmptyTextValidation() async throws {
        let provider = AppleIntelligenceProvider()
        let extractor = VisualElementExtractor(provider: provider)

        await #expect(throws: AIProviderError.self) {
            try await extractor.extractVisualElements(from: "", cardKind: .characters)
        }
    }

    @Test
    func testShortTextValidation() async throws {
        let provider = AppleIntelligenceProvider()
        let extractor = VisualElementExtractor(provider: provider)

        let shortText = "A tall woman" // Only 3 words, should fail (minimum 10)

        await #expect(throws: AIProviderError.self) {
            try await extractor.extractVisualElements(from: shortText, cardKind: .characters)
        }
    }

    // MARK: - Provider-Specific Prompt Tests

    @Test
    func testAppleIntelligenceConceptGeneration() async throws {
        let provider = AppleIntelligenceProvider()
        let extractor = VisualElementExtractor(provider: provider)

        let elements = try await extractor.extractVisualElements(
            from: captainDrakeDescription,
            cardKind: .characters
        )

        let concepts = elements.generateConceptsForAppleIntelligence()

        // Apple Intelligence uses multiple short concepts
        #expect(concepts.count > 0, "Should generate at least one concept")

        // Each concept should be <= 95 characters
        for concept in concepts {
            #expect(concept.count <= 95, "Concepts should be <= 95 chars for Apple Intelligence")
        }

        // Concepts should contain visual elements
        let allConcepts = concepts.joined(separator: " ")
        #expect(allConcepts.lowercased().contains("tall") ||
                allConcepts.lowercased().contains("orange") ||
                allConcepts.lowercased().contains("jumpsuit"),
                "Concepts should include extracted visual elements")
    }

    @Test
    func testOpenAIPromptGeneration() async throws {
        let provider = AppleIntelligenceProvider()
        let extractor = VisualElementExtractor(provider: provider)

        let elements = try await extractor.extractVisualElements(
            from: captainDrakeDescription,
            cardKind: .characters
        )

        let prompt = elements.generatePromptForOpenAI()

        // OpenAI uses single structured prompt
        #expect(prompt.count > 0, "Should generate prompt")
        #expect(prompt.contains("portrait") || prompt.contains("woman"),
                "Should mention character subject")

        // Should include visual elements
        #expect(prompt.lowercased().contains("tall") ||
                prompt.lowercased().contains("orange") ||
                prompt.lowercased().contains("jumpsuit"),
                "Should include extracted visual elements")
    }

    @Test
    func testAnthropicPromptGeneration() async throws {
        let provider = AppleIntelligenceProvider()
        let extractor = VisualElementExtractor(provider: provider)

        let elements = try await extractor.extractVisualElements(
            from: captainDrakeDescription,
            cardKind: .characters
        )

        let prompt = elements.generatePromptForAnthropic()

        // Anthropic uses similar format to OpenAI
        #expect(prompt.count > 0, "Should generate prompt")
        #expect(prompt.contains("portrait") || prompt.contains("woman"),
                "Should mention character subject")
    }

    // MARK: - Codable Tests

    @Test
    func testVisualElementsCodable() throws {
        // Create sample visual elements
        var elements = VisualElements(
            sourceText: "Test description",
            cardKind: .characters,
            extractionConfidence: 0.85
        )
        elements.physicalBuild = "tall, athletic"
        elements.hair = "long dark hair"
        elements.eyes = "bright green eyes"
        elements.clothing = "orange jumpsuit"
        elements.cameraAngle = .eyeLevel
        elements.framing = .mediumShot
        elements.lightingStyle = .neutral

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(elements)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(VisualElements.self, from: data)

        // Verify
        #expect(decoded.sourceText == elements.sourceText)
        #expect(decoded.cardKind == elements.cardKind)
        #expect(decoded.extractionConfidence == elements.extractionConfidence)
        #expect(decoded.physicalBuild == elements.physicalBuild)
        #expect(decoded.hair == elements.hair)
        #expect(decoded.eyes == elements.eyes)
        #expect(decoded.clothing == elements.clothing)
        #expect(decoded.cameraAngle == elements.cameraAngle)
        #expect(decoded.framing == elements.framing)
        #expect(decoded.lightingStyle == elements.lightingStyle)
    }

    // MARK: - Helper Property Tests

    @Test
    func testHasSufficientData() {
        // Empty elements
        var elements = VisualElements(
            sourceText: "Test",
            cardKind: .characters,
            extractionConfidence: 0.5
        )
        #expect(elements.hasSufficientData == false, "Empty elements should not have sufficient data")

        // Add some character data
        elements.physicalBuild = "tall"
        elements.hair = "dark hair"
        elements.clothing = "jumpsuit"
        #expect(elements.hasSufficientData == true, "Elements with 3+ properties should have sufficient data")
    }

    @Test
    func testCinematicFramingDisplayNames() {
        #expect(CameraAngle.lowAngleLookingUp.displayName == "low angle shot looking up")
        #expect(CameraAngle.highAngleLookingDown.displayName == "high angle shot looking down")
        #expect(CameraAngle.eyeLevel.displayName == "eye-level perspective")

        #expect(Framing.closeUp.displayName == "close-up")
        #expect(Framing.mediumShot.displayName == "medium shot")
        #expect(Framing.wideEstablishing.displayName == "wide establishing shot")

        #expect(LightingStyle.dramatic.description == "dramatic lighting with strong shadows")
        #expect(LightingStyle.dark.description == "dark moody lighting")
        #expect(LightingStyle.bright.description == "bright cheerful lighting")
    }
}
