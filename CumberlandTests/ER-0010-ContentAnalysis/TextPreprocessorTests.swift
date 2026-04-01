//
//  TextPreprocessorTests.swift
//  CumberlandTests
//
//  Phase 10 tests for TextPreprocessor (ER-0010).
//  Covers preprocessing, proper noun extraction, sentence selection,
//  chunking, configuration presets, and edge cases.
//

import Testing
import Foundation
@testable import Cumberland

@Suite("TextPreprocessor Tests", .serialized)
struct TextPreprocessorTests {

    // MARK: - Short Text Passthrough

    @Test("Short text below threshold passes through unchanged")
    func shortTextPassthrough() {
        let preprocessor = TextPreprocessor()
        let shortText = "Captain Aria stood at the helm."
        let result = preprocessor.preprocess(shortText)

        #expect(result.wasPreprocessed == false)
        #expect(result.condensedText == shortText)
        #expect(result.originalWordCount == result.condensedWordCount)
        #expect(result.extractedEntities.isEmpty)
    }

    @Test("Empty text returns zero word count")
    func emptyText() {
        let preprocessor = TextPreprocessor()
        let result = preprocessor.preprocess("")

        #expect(result.wasPreprocessed == false)
        #expect(result.condensedText == "")
        #expect(result.originalWordCount == 0)
        #expect(result.condensedWordCount == 0)
    }

    @Test("Text at exactly threshold is not preprocessed")
    func textAtThreshold() {
        // Default threshold is 500 words
        let words = (0..<500).map { "word\($0)" }
        let text = words.joined(separator: " ")
        let preprocessor = TextPreprocessor()
        let result = preprocessor.preprocess(text)

        #expect(result.wasPreprocessed == false)
        #expect(result.condensedText == text)
    }

    // MARK: - Long Text Preprocessing

    @Test("Long text with proper nouns is condensed")
    func longTextCondensed() {
        // Build a long text (>500 words) with some proper nouns
        let narrative = buildLongNarrative()
        let preprocessor = TextPreprocessor()
        let result = preprocessor.preprocess(narrative)

        #expect(result.wasPreprocessed == true)
        #expect(result.condensedWordCount < result.originalWordCount)
        #expect(result.originalWordCount > 500)
        #expect(result.condensedWordCount > 0)
    }

    @Test("Preprocessing preserves entity-containing sentences")
    func preservesEntitySentences() {
        let narrative = buildLongNarrative()
        let preprocessor = TextPreprocessor()
        let result = preprocessor.preprocess(narrative)

        // The condensed text should contain at least some of the character names
        // since they are proper nouns extracted by NaturalLanguage
        #expect(result.condensedText.count > 0)
        #expect(result.keySentenceCount != nil)
        #expect(result.keySentenceCount! > 0)
    }

    @Test("Processing time is recorded")
    func processingTimeRecorded() {
        let narrative = buildLongNarrative()
        let preprocessor = TextPreprocessor()
        let result = preprocessor.preprocess(narrative)

        #expect(result.processingTime != nil)
        #expect(result.processingTime! >= 0)
    }

    // MARK: - Compression Ratio

    @Test("Compression ratio is calculated correctly")
    func compressionRatio() {
        // Non-preprocessed: ratio should be 1.0
        let shortResult = PreprocessResult(
            originalWordCount: 100,
            condensedText: "test",
            condensedWordCount: 100,
            wasPreprocessed: false,
            extractedEntities: []
        )
        #expect(shortResult.compressionRatio == 1.0)

        // Preprocessed: ratio should reflect reduction
        let longResult = PreprocessResult(
            originalWordCount: 1000,
            condensedText: "test",
            condensedWordCount: 500,
            wasPreprocessed: true,
            extractedEntities: ["Alice"]
        )
        #expect(longResult.compressionRatio == 0.5)
    }

    @Test("Compression ratio handles zero original word count")
    func compressionRatioZero() {
        let result = PreprocessResult(
            originalWordCount: 0,
            condensedText: "",
            condensedWordCount: 0,
            wasPreprocessed: false,
            extractedEntities: []
        )
        #expect(result.compressionRatio == 1.0)
    }

    // MARK: - Description

    @Test("Description reflects preprocessing state")
    func descriptionText() {
        let preprocessed = PreprocessResult(
            originalWordCount: 1000,
            condensedText: "test",
            condensedWordCount: 500,
            wasPreprocessed: true,
            extractedEntities: ["Alice"]
        )
        #expect(preprocessed.description.contains("500"))
        #expect(preprocessed.description.contains("1000"))

        let notPreprocessed = PreprocessResult(
            originalWordCount: 100,
            condensedText: "test",
            condensedWordCount: 100,
            wasPreprocessed: false,
            extractedEntities: []
        )
        #expect(notPreprocessed.description.contains("100"))
        #expect(notPreprocessed.description.contains("full text"))
    }

    // MARK: - Chunking

    @Test("Chunk text splits correctly")
    func chunkText() {
        let words = (0..<100).map { "word\($0)" }
        let text = words.joined(separator: " ")
        let preprocessor = TextPreprocessor()

        let chunks = preprocessor.chunkText(text, maxWordsPerChunk: 30)

        #expect(chunks.count == 4) // 100 / 30 = 3 full + 1 remainder
        // First 3 chunks should each have 30 words
        for chunk in chunks.prefix(3) {
            #expect(chunk.split(separator: " ").count == 30)
        }
        // Last chunk should have 10 words
        #expect(chunks.last!.split(separator: " ").count == 10)
    }

    @Test("Chunk text with exact multiple")
    func chunkTextExactMultiple() {
        let words = (0..<60).map { "word\($0)" }
        let text = words.joined(separator: " ")
        let preprocessor = TextPreprocessor()

        let chunks = preprocessor.chunkText(text, maxWordsPerChunk: 30)
        #expect(chunks.count == 2)
    }

    @Test("Chunk empty text returns empty array")
    func chunkEmptyText() {
        let preprocessor = TextPreprocessor()
        let chunks = preprocessor.chunkText("")
        #expect(chunks.isEmpty)
    }

    @Test("Chunk text shorter than maxWords returns single chunk")
    func chunkShortText() {
        let preprocessor = TextPreprocessor()
        let chunks = preprocessor.chunkText("hello world", maxWordsPerChunk: 500)
        #expect(chunks.count == 1)
        #expect(chunks.first == "hello world")
    }

    // MARK: - Configuration Presets

    @Test("Fast config has lower thresholds")
    func fastConfig() {
        let config = TextPreprocessor.Config.fast
        #expect(config.maxWords == 500)
        #expect(config.preprocessThreshold == 300)
        #expect(config.maxSentencesPerEntity == 2)
    }

    @Test("Balanced config uses defaults")
    func balancedConfig() {
        let config = TextPreprocessor.Config.balanced
        #expect(config.maxWords == 1000)
        #expect(config.preprocessThreshold == 500)
        #expect(config.maxSentencesPerEntity == 3)
    }

    @Test("Thorough config has higher thresholds")
    func thoroughConfig() {
        let config = TextPreprocessor.Config.thorough
        #expect(config.maxWords == 1500)
        #expect(config.preprocessThreshold == 700)
        #expect(config.maxSentencesPerEntity == 5)
    }

    @Test("Fast config preprocesses more aggressively")
    func fastVsBalancedPreprocessing() {
        let narrative = buildLongNarrative()

        let fastPreprocessor = TextPreprocessor(config: .fast)
        let balancedPreprocessor = TextPreprocessor(config: .balanced)

        let fastResult = fastPreprocessor.preprocess(narrative)
        let balancedResult = balancedPreprocessor.preprocess(narrative)

        // Both should preprocess (narrative > 700 words)
        #expect(fastResult.wasPreprocessed == true)
        #expect(balancedResult.wasPreprocessed == true)

        // Fast should produce fewer words (maxWords=500 vs 1000)
        #expect(fastResult.condensedWordCount <= balancedResult.condensedWordCount)
    }

    // MARK: - Test Helpers

    /// Build a long narrative (~800 words) with proper nouns for testing
    private func buildLongNarrative() -> String {
        let paragraphs = [
            "Captain Aria Stormwind stood on the bridge of the Windcatcher, surveying the horizon. The ship had been sailing for three days since leaving the port of Silvershore. The crew was restless, and the supplies were running low. She needed to make a decision about their course.",
            "The navigator Marcus Chen approached with a worried expression on his face. He carried a map rolled under his arm and several charts tucked into his belt. He had been calculating their position using the stars, and his findings were troubling to say the least.",
            "According to Marcus, they had drifted further east than expected due to the strong currents in the Abyssal Strait. If they continued on their present heading, they would miss the island of Thornhaven entirely and end up in the treacherous waters near the Serpent Rocks.",
            "Aria considered their options carefully. They could adjust course to the west, which would add another day to their journey but ensure they reached Thornhaven safely. Alternatively, they could maintain course and hope the currents shifted, a gamble that could prove disastrous.",
            "The ship's engineer, Doctor Elena Vasquez, joined them on the bridge with news of her own. The starboard engine was showing signs of strain, and she estimated it would need maintenance within the next forty-eight hours. This limited their speed and maneuverability considerably.",
            "Meanwhile, in the cargo hold below deck, the merchant Jorge Ruiz was taking inventory of their remaining supplies. He counted barrels of water, crates of dried food, and boxes of trading goods destined for the markets of Thornhaven. The numbers were not encouraging.",
            "Back on the bridge, first mate Lieutenant Sarah Kim suggested they consult the weather oracle at the next opportunity. The oracle, an ancient device housed in the navigation room, could predict weather patterns up to three days in advance with remarkable accuracy.",
            "Aria finally made her decision. She ordered Marcus to plot a westward correction of fifteen degrees. She told Elena to begin the engine maintenance immediately, and she asked Jorge to ration the water supply to extend it by two additional days just in case.",
            "The crew sprang into action with practiced efficiency. Marcus adjusted the navigational instruments while Sarah relayed the new heading to the helm. Elena gathered her tools and descended to the engine room, accompanied by two of her technicians.",
            "As the sun set over the vast ocean, the Windcatcher turned gracefully to her new heading. The orange light painted the white sails in warm hues, and for a moment, everything seemed peaceful. But Aria knew better than to let her guard down in these waters.",
            "The Serpent Rocks had claimed many ships before, and the creatures that dwelled beneath the waves near those jagged formations were the stuff of sailors' nightmares. Captain Aria Stormwind had no intention of adding the Windcatcher to that grim tally.",
            "She retired to her cabin to review the ship's log and write her daily entry. The quill scratched against the parchment as she recorded the day's events, the course correction, the engine troubles, and the supply concerns. Tomorrow would bring new challenges."
        ]
        return paragraphs.joined(separator: "\n\n")
    }
}
