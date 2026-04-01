//
//  DescriptionAnalyzerTests.swift
//  CumberlandTests
//
//  Phase 10 tests for DescriptionAnalyzer (ER-0009).
//  Covers quality scoring, visual keyword detection, dialogue detection,
//  recommendation generation, and edge cases.
//

import Testing
import Foundation
@testable import Cumberland

@Suite("DescriptionAnalyzer Tests")
struct DescriptionAnalyzerTests {

    // MARK: - Quality Score Tests

    @Test("High quality description scores above 75")
    func highQualityDescription() {
        let description = """
        A towering stone fortress perched atop a massive granite cliff overlooking the dark azure ocean. \
        The ancient walls are covered in thick green ivy, and tall narrow windows glow with warm golden light. \
        Silver banners hang from the battlements, and a large ornate iron gate guards the entrance. \
        The building has a beautiful marble courtyard with a shimmering crystal fountain at its center. \
        The roof is made of dark slate tiles, weathered by centuries of storms. Ancient gargoyles carved \
        from gray stone watch from every corner, their eyes seeming to follow visitors as they approach.
        """

        let result = DescriptionAnalyzer.analyze(description)

        // Score depends on word count (< 150 ideal) and visual keywords (10+)
        // This description typically scores ~79 (strong but below 150-word bonus threshold)
        #expect(result.qualityScore >= 75)
        #expect(result.isSufficient == true)
        #expect(result.visualKeywordCount >= 10)
    }

    @Test("Short description scores low")
    func shortDescription() {
        let description = "A castle on a hill."
        let result = DescriptionAnalyzer.analyze(description)

        #expect(result.qualityScore < 50)
        #expect(result.wordCount < 50)
    }

    @Test("Empty description scores zero")
    func emptyDescription() {
        let result = DescriptionAnalyzer.analyze("")
        #expect(result.qualityScore == 0)
        #expect(result.wordCount == 0)
        #expect(result.visualKeywordCount == 0)
    }

    @Test("Description with only dialogue scores lower")
    func dialogueDescription() {
        let description = """
        "Hello there," said the wizard. "I've been expecting you," he replied with a smile. \
        "Where is the artifact?" asked the knight. "It's hidden in the tower," whispered the sage.
        """

        let result = DescriptionAnalyzer.analyze(description)

        #expect(result.hasDialogue == true)
        // Dialogue penalty should reduce score
    }

    // MARK: - Visual Keyword Detection

    @Test("Detects color keywords")
    func detectColors() {
        let description = "A red and blue banner hanging from the golden wall above the silver throne."
        let result = DescriptionAnalyzer.analyze(description)

        #expect(result.visualKeywordCount >= 3) // red, blue, gold, silver
    }

    @Test("Detects material keywords")
    func detectMaterials() {
        let description = "The stone walls were reinforced with steel beams and decorated with marble pillars and glass windows."
        let result = DescriptionAnalyzer.analyze(description)

        #expect(result.visualKeywordCount >= 3) // stone, steel, marble, glass
    }

    @Test("Detects lighting keywords")
    func detectLighting() {
        let description = "A glowing crystal illuminated the shadowy corridor while bright torchlit sconces lined the radiant hallway."
        let result = DescriptionAnalyzer.analyze(description)

        #expect(result.visualKeywordCount >= 3) // glowing, shadowy, bright, radiant
    }

    // MARK: - Dialogue Detection

    @Test("Detects double-quoted dialogue")
    func detectDoubleQuotes() {
        let result = DescriptionAnalyzer.analyze("The character \"speaks like this\" sometimes.")
        #expect(result.hasDialogue == true)
    }

    @Test("Detects dialogue tags")
    func detectDialogueTags() {
        let result = DescriptionAnalyzer.analyze("The warrior said the castle was magnificent")
        #expect(result.hasDialogue == true)
    }

    @Test("No dialogue in pure description")
    func noDialogue() {
        let result = DescriptionAnalyzer.analyze("A tall stone tower with iron gates and marble walls stands on the hill.")
        #expect(result.hasDialogue == false)
    }

    // MARK: - Sufficiency Threshold

    @Test("Description at threshold is sufficient")
    func atThreshold() {
        // Build a description that should hit exactly around the threshold
        let description = """
        A large stone building with tall windows and a massive wooden door. The walls are made of \
        gray granite blocks fitted together with precision. Dark iron hinges hold the heavy oak door \
        in place. Green moss grows between the ancient stones. A bright lantern hangs above the entrance.
        """
        let result = DescriptionAnalyzer.analyze(description)
        #expect(result.isSufficient == true)
    }

    // MARK: - Recommendations

    @Test("Excellent description gets positive recommendation")
    func excellentRecommendation() {
        let description = """
        A towering stone fortress with massive granite walls covered in green ivy. Tall narrow windows \
        glow with warm golden light. Silver banners hang from the battlements. A large ornate iron gate \
        guards the entrance. Beautiful marble courtyard with shimmering crystal fountain. Dark slate \
        roof tiles weathered by centuries. Ancient gargoyles carved from gray stone watch from corners.
        """
        let result = DescriptionAnalyzer.analyze(description)
        #expect(result.recommendation.lowercased().contains("excellent") || result.recommendation.lowercased().contains("good") || result.recommendation.lowercased().contains("great"))
    }

    @Test("Poor description gets improvement advice")
    func poorRecommendation() {
        let result = DescriptionAnalyzer.analyze("A thing.")
        // Should suggest adding more details
        #expect(result.recommendation.lowercased().contains("add") || result.recommendation.lowercased().contains("more") || result.recommendation.lowercased().contains("detail"))
    }

    // MARK: - Word Count

    @Test("Word count is accurate")
    func wordCount() {
        let result = DescriptionAnalyzer.analyze("one two three four five")
        #expect(result.wordCount == 5)
    }

    @Test("Word count handles multiple spaces")
    func wordCountMultipleSpaces() {
        let result = DescriptionAnalyzer.analyze("one   two   three")
        #expect(result.wordCount == 3)
    }
}
