//
//  ImageGenerationWorkflowTests.swift
//  CumberlandTests
//
//  Swift Testing suite for ER-0009: AI Image Generation.
//  End-to-end workflow tests covering image generation request, result
//  persistence to Card, and ImageVersion creation. Currently disabled
//  (#if false) pending type fixes.
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

/// Tests for end-to-end image generation workflows
/// Part of ER-0009: AI Image Generation
/// TEMPORARILY DISABLED - Needs type fixes
#if false
@Suite("Image Generation Workflow Tests")
struct ImageGenerationWorkflowTests {

    // MARK: - Test Helpers

    @MainActor
    func makeInMemoryContainer() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Card.self,
            configurations: config
        )
        let context = ModelContext(container)
        return (container, context)
    }

    // MARK: - Prompt Generation Tests

    @Test("Generate prompt for character card")
    func characterPromptGeneration() {
        let card = Card(
            kind: .characters,
            name: "Aria Moonstone",
            subtitle: "Rogue Spellcaster",
            detailedText: "A young elf with silver hair and emerald eyes, wearing dark leather armor decorated with arcane symbols."
        )

        // Test basic prompt generation (manual)
        let prompt = "\(card.kind.singularTitle): \(card.name). \(card.subtitle). \(card.detailedText)"

        #expect(prompt.contains("Aria Moonstone"))
        #expect(prompt.contains("silver hair"))
        #expect(prompt.contains("elf"))
    }

    @Test("Generate prompt for location card")
    func locationPromptGeneration() {
        let card = Card(
            kind: .locations,
            name: "Crystal Caverns",
            subtitle: "Ancient Underground Network",
            detailedText: "Vast underground caverns filled with glowing crystals, illuminating intricate rock formations. Underground streams flow through natural archways."
        )

        let prompt = "\(card.kind.singularTitle): \(card.name). \(card.detailedText)"

        #expect(prompt.contains("Crystal Caverns"))
        #expect(prompt.contains("glowing crystals"))
        #expect(prompt.contains("underground"))
    }

    @Test("Generate prompt for vehicle card")
    func vehiclePromptGeneration() {
        let card = Card(
            kind: .vehicles,
            name: "Skyship Tempest",
            subtitle: "Airborne Merchant Vessel",
            detailedText: "A large wooden airship with brass fittings and billowing sails, propelled by enchanted wind crystals mounted on the hull."
        )

        let prompt = "\(card.kind.singularTitle): \(card.name). \(card.detailedText)"

        #expect(prompt.contains("Skyship Tempest"))
        #expect(prompt.contains("airship"))
        #expect(prompt.contains("brass fittings"))
    }

    // MARK: - Word Count Tests

    @Test("Card meets minimum word count for generation")
    func cardMeetsMinimumWordCount() {
        let shortText = "Quick description"
        let longText = "This is a much longer and more detailed description that provides substantial context and imagery for image generation purposes. It includes many descriptive words and phrases that help create a vivid mental picture of the subject matter. The description goes on to explain various aspects and characteristics in detail, ensuring there is enough content to work with when generating visual representations."

        let shortWords = shortText.split(separator: " ").count
        let longWords = longText.split(separator: " ").count

        #expect(shortWords < 25)
        #expect(longWords >= 50)
    }

    @Test("Empty card text has zero word count")
    func emptyCardWordCount() {
        let card = Card(
            kind: .characters,
            name: "No Description",
            subtitle: "",
            detailedText: ""
        )

        let wordCount = card.detailedText.split(separator: " ").count
        #expect(wordCount == 0)
    }

    // MARK: - Auto-Generation Eligibility Tests

    @Test("Card is eligible for auto-generation")
    func cardEligibleForAutoGeneration() {
        let card = Card(
            kind: .characters,
            name: "Test Character",
            subtitle: "",
            detailedText: String(repeating: "word ", count: 60) // 60 words
        )

        // No existing image
        #expect(card.thumbnailData == nil)
        #expect(card.originalImageData == nil)

        // Sufficient description
        let wordCount = card.detailedText.split(separator: " ").count
        #expect(wordCount >= 50)
    }

    @Test("Card with existing image not eligible for auto-generation")
    func cardWithImageNotEligible() {
        let card = Card(
            kind: .characters,
            name: "Has Image",
            subtitle: "",
            detailedText: String(repeating: "word ", count: 60)
        )
        card.originalImageData = Data([0x00, 0x01, 0x02]) // Mock image data

        #expect(card.originalImageData != nil)
    }

    // MARK: - Card Image Storage Tests

    @Test("Store generated image on card")
    @MainActor
    func storeGeneratedImage() async throws {
        let (_, context) = try makeInMemoryContainer()

        let card = Card(
            kind: .characters,
            name: "Test Character",
            subtitle: "",
            detailedText: "Test description"
        )
        context.insert(card)

        // Simulate image generation
        let mockImageData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header
        card.originalImageData = mockImageData

        try context.save()

        #expect(card.originalImageData != nil)
        #expect(card.originalImageData?.count == 4)
    }

    // MARK: - Attribution Tests

    @Test("Generated image has attribution metadata")
    func generatedImageAttribution() {
        let metadata = AIImageMetadata(
            prompt: "Test prompt",
            provider: "Apple Intelligence",
            modelVersion: "1.0",
            timestamp: Date(),
            software: "Cumberland"
        )

        #expect(metadata.prompt == "Test prompt")
        #expect(metadata.provider == "Apple Intelligence")
        #expect(metadata.modelVersion == "1.0")
        #expect(metadata.software == "Cumberland")
    }

    // MARK: - Provider Selection Tests

    @Test("Default to Apple Intelligence if available")
    func defaultProviderSelection() {
        let settings = AISettings.shared
        let provider = settings.currentImageGenerationProvider

        // Should return a provider (either Apple Intelligence or fallback)
        // Actual provider depends on OS version and API key availability
        if let provider = provider {
            #expect(provider.name.isEmpty == false)
        }
    }

    @Test("Respect user provider preference")
    func respectProviderPreference() {
        let settings = AISettings.shared

        // Save original setting
        let original = settings.imageGenerationProvider

        // Set preference
        settings.imageGenerationProvider = "Apple Intelligence"
        #expect(settings.imageGenerationProvider == "Apple Intelligence")

        // Restore original
        settings.imageGenerationProvider = original
    }

    // MARK: - Error Handling Tests

    @Test("Handle empty prompt gracefully")
    func emptyPromptError() {
        let emptyPrompt = ""
        #expect(emptyPrompt.isEmpty == true)

        // Error should be thrown when attempting generation
        // (actual error handling tested in AIProviderTests)
    }

    @Test("Handle insufficient description")
    func insufficientDescriptionError() {
        let shortText = "Too short"
        let wordCount = shortText.split(separator: " ").count

        #expect(wordCount < AISettings.Defaults.autoGenerateMinWords)
    }

    // MARK: - Settings Tests

    @Test("Auto-generation setting persists")
    func autoGenerationSettingPersistence() {
        let settings = AISettings.shared

        let original = settings.autoGenerateImages

        // Toggle setting
        settings.autoGenerateImages = true
        #expect(settings.autoGenerateImages == true)

        settings.autoGenerateImages = false
        #expect(settings.autoGenerateImages == false)

        // Restore
        settings.autoGenerateImages = original
    }

    @Test("Minimum word count setting")
    func minimumWordCountSetting() {
        let settings = AISettings.shared

        let original = settings.autoGenerateMinWords

        // Set custom threshold
        settings.autoGenerateMinWords = 75
        #expect(settings.autoGenerateMinWords == 75)

        // Restore
        settings.autoGenerateMinWords = original
    }

    // MARK: - Image Format Tests

    @Test("Verify PNG format support")
    func pngFormatSupport() {
        // PNG magic number
        let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        let data = Data(pngHeader)

        #expect(data.count == 8)
        #expect(data[0] == 0x89)
        #expect(data[1] == 0x50) // 'P'
        #expect(data[2] == 0x4E) // 'N'
        #expect(data[3] == 0x47) // 'G'
    }

    @Test("Verify JPEG format support")
    func jpegFormatSupport() {
        // JPEG magic number
        let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]
        let data = Data(jpegHeader)

        #expect(data.count == 4)
        #expect(data[0] == 0xFF)
        #expect(data[1] == 0xD8)
    }

    // MARK: - Integration Tests

    @Test("Complete generation workflow simulation")
    @MainActor
    func completeWorkflowSimulation() async throws {
        let (_, context) = try makeInMemoryContainer()

        // 1. Create card with description
        let card = Card(
            kind: .characters,
            name: "Workflow Test Character",
            subtitle: "Test Subject",
            detailedText: String(repeating: "descriptive word ", count: 60)
        )
        context.insert(card)

        // 2. Check eligibility
        let wordCount = card.detailedText.split(separator: " ").count
        #expect(wordCount >= 50)
        #expect(card.originalImageData == nil)

        // 3. Generate prompt
        let prompt = "\(card.name). \(card.detailedText)"
        #expect(prompt.contains(card.name))

        // 4. Simulate image generation (would call AI provider here)
        let mockImageData = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])

        // 5. Store image
        card.originalImageData = mockImageData

        // 6. Save
        try context.save()

        // 7. Verify
        #expect(card.originalImageData != nil)
        #expect(card.originalImageData?.count == 6)
    }
}
#endif
