//
//  DescriptionAnalyzer.swift
//  Cumberland
//
//  Created by Claude Code on 1/23/26.
//  Part of ER-0009 Phase 3A: Smart Prompt Extraction
//

import Foundation

/// Analyzes card descriptions to determine suitability for AI image generation
/// Provides quality scores and recommendations
struct DescriptionAnalyzer {

    // MARK: - Analysis Result

    /// Result of description analysis
    struct AnalysisResult {
        /// Word count of the description
        let wordCount: Int

        /// Quality score (0-100%)
        let qualityScore: Int

        /// Whether description is sufficient for image generation
        var isSufficient: Bool {
            qualityScore >= minimumQualityThreshold
        }

        /// Recommendation message for user
        let recommendation: String

        /// Visual keyword count
        let visualKeywordCount: Int

        /// Has dialogue (indicates non-visual content)
        let hasDialogue: Bool
    }

    // MARK: - Configuration

    /// Minimum word count for image generation
    static let minimumWordCount = 50

    /// Minimum quality score to enable image generation (default: 50%)
    static let minimumQualityThreshold = 50

    /// Ideal word count for good image generation
    static let idealWordCount = 150

    // MARK: - Public Methods

    /// Analyze a card description for image generation suitability
    /// - Parameter description: The card's detailed text
    /// - Returns: Analysis result with quality score and recommendations
    static func analyze(_ description: String) -> AnalysisResult {
        // Word count
        let wordCount = countWords(in: description)

        // Visual keyword detection
        let visualKeywords = detectVisualKeywords(in: description)

        // Dialogue detection
        let hasDialogue = detectDialogue(in: description)

        // Calculate quality score
        let qualityScore = calculateQualityScore(
            wordCount: wordCount,
            visualKeywordCount: visualKeywords.count,
            hasDialogue: hasDialogue
        )

        // Generate recommendation
        let recommendation = generateRecommendation(
            wordCount: wordCount,
            qualityScore: qualityScore,
            visualKeywordCount: visualKeywords.count,
            hasDialogue: hasDialogue
        )

        return AnalysisResult(
            wordCount: wordCount,
            qualityScore: qualityScore,
            recommendation: recommendation,
            visualKeywordCount: visualKeywords.count,
            hasDialogue: hasDialogue
        )
    }

    // MARK: - Private Helpers

    /// Count words in text
    private static func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    /// Detect visual keywords in text
    private static func detectVisualKeywords(in text: String) -> [String] {
        let lowercased = text.lowercased()
        var found: [String] = []

        // Visual descriptors
        let visualKeywords = [
            // Colors
            "red", "blue", "green", "yellow", "orange", "purple", "black", "white",
            "gray", "brown", "gold", "silver", "crimson", "azure", "emerald",

            // Sizes
            "large", "small", "huge", "tiny", "massive", "towering", "tall", "short",

            // Materials
            "stone", "wood", "metal", "glass", "leather", "silk", "steel", "marble",

            // Lighting
            "bright", "dark", "glowing", "shimmering", "shadowy", "radiant",

            // Moods
            "beautiful", "ugly", "elegant", "rugged", "ornate", "simple",

            // Physical features
            "face", "eyes", "hair", "hands", "building", "tower", "wall", "door",
            "window", "roof", "mountain", "forest", "river", "ocean", "sky"
        ]

        for keyword in visualKeywords {
            if lowercased.contains(keyword) {
                found.append(keyword)
            }
        }

        return found
    }

    /// Detect dialogue in text (indicates non-visual content)
    private static func detectDialogue(in text: String) -> Bool {
        // Check for quotation marks
        if text.contains("\"") || text.contains("'") {
            return true
        }

        // Check for dialogue tags
        let dialogueTags = ["said", "asked", "replied", "shouted", "whispered", "exclaimed"]
        let lowercased = text.lowercased()

        for tag in dialogueTags {
            if lowercased.contains(" \(tag) ") || lowercased.contains(" \(tag),") {
                return true
            }
        }

        return false
    }

    /// Calculate quality score based on multiple factors
    private static func calculateQualityScore(wordCount: Int, visualKeywordCount: Int, hasDialogue: Bool) -> Int {
        var score = 0

        // Word count scoring (0-40 points)
        if wordCount < minimumWordCount {
            score += Int((Double(wordCount) / Double(minimumWordCount)) * 40.0)
        } else if wordCount < idealWordCount {
            score += 40 + Int(((Double(wordCount) - Double(minimumWordCount)) / (Double(idealWordCount) - Double(minimumWordCount))) * 20.0)
        } else {
            score += 60 // Max points for word count
        }

        // Visual keyword scoring (0-30 points)
        let keywordScore = min(visualKeywordCount * 3, 30)
        score += keywordScore

        // Dialogue penalty (-10 points if present)
        if hasDialogue {
            score -= 10
        }

        // Bonus for rich descriptions (10 points)
        if wordCount >= idealWordCount && visualKeywordCount >= 10 {
            score += 10
        }

        return max(0, min(100, score))
    }

    /// Generate user-facing recommendation message
    private static func generateRecommendation(wordCount: Int, qualityScore: Int, visualKeywordCount: Int, hasDialogue: Bool) -> String {
        if qualityScore >= 80 {
            return "Excellent! This description should generate a great image."
        }

        if qualityScore >= 60 {
            return "Good description. Image generation should work well."
        }

        if qualityScore >= minimumQualityThreshold {
            return "Sufficient description for image generation. Adding more visual details would improve results."
        }

        // Below threshold - provide specific advice
        var issues: [String] = []

        if wordCount < minimumWordCount {
            issues.append("Add more details (\(wordCount)/\(minimumWordCount) words)")
        }

        if visualKeywordCount < 3 {
            issues.append("Include more visual descriptions (colors, sizes, materials)")
        }

        if hasDialogue {
            issues.append("Focus on visual details rather than dialogue")
        }

        if issues.isEmpty {
            return "Add more visual details to improve image generation quality."
        }

        return issues.joined(separator: ". ") + "."
    }
}
