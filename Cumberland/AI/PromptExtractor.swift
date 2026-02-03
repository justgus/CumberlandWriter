//
//  PromptExtractor.swift
//  Cumberland
//
//  Created by Claude Code on 1/23/26.
//  Part of ER-0009 Phase 3A: Smart Prompt Extraction
//

import Foundation

/// Extracts AI image generation prompts from card descriptions
/// Analyzes text to find visual keywords and generates contextual prompts
struct PromptExtractor {

    // MARK: - Public Methods

    /// Extract an AI image generation prompt from a card's description
    /// - Parameters:
    ///   - description: The card's detailed text
    ///   - cardName: The card's name
    ///   - cardKind: The type of card (character, location, etc.)
    /// - Returns: A suggested prompt, or nil if description is insufficient
    static func extractPrompt(from description: String, cardName: String, cardKind: Kinds) -> String? {
        // Require minimum content
        guard description.count >= 50 else { return nil }

        // Get visual keywords from description
        let keywords = extractVisualKeywords(from: description)

        // Build prompt based on card kind and keywords
        return buildPrompt(cardName: cardName, cardKind: cardKind, keywords: keywords, fullDescription: description)
    }

    /// Generate multiple prompt variations for user to choose from
    /// - Parameters:
    ///   - description: The card's detailed text
    ///   - cardName: The card's name
    ///   - cardKind: The type of card
    /// - Returns: Array of suggested prompts (may be empty if description insufficient)
    static func extractPromptVariations(from description: String, cardName: String, cardKind: Kinds) -> [String] {
        guard description.count >= 50 else { return [] }

        let keywords = extractVisualKeywords(from: description)
        var prompts: [String] = []

        // Variation 1: Detailed with keywords
        if let detailed = buildPrompt(cardName: cardName, cardKind: cardKind, keywords: keywords, fullDescription: description) {
            prompts.append(detailed)
        }

        // Variation 2: Simple with style
        prompts.append(buildSimplePrompt(cardName: cardName, cardKind: cardKind))

        // Variation 3: Atmospheric
        if let atmospheric = buildAtmosphericPrompt(cardName: cardName, cardKind: cardKind, keywords: keywords, fullDescription: description) {
            prompts.append(atmospheric)
        }

        return prompts
    }

    // MARK: - Private Helpers

    /// Extract visual keywords from description text
    private static func extractVisualKeywords(from text: String) -> [VisualKeyword] {
        var keywords: [VisualKeyword] = []
        let lowercased = text.lowercased()

        // Colors
        for color in colorKeywords {
            if lowercased.contains(color.lowercased()) {
                keywords.append(.color(color))
            }
        }

        // Physical attributes
        for attribute in physicalAttributes {
            if lowercased.contains(attribute.lowercased()) {
                keywords.append(.physical(attribute))
            }
        }

        // Moods and atmospheres
        for mood in moodKeywords {
            if lowercased.contains(mood.lowercased()) {
                keywords.append(.mood(mood))
            }
        }

        // Materials and textures
        for material in materialKeywords {
            if lowercased.contains(material.lowercased()) {
                keywords.append(.material(material))
            }
        }

        // Lighting
        for lighting in lightingKeywords {
            if lowercased.contains(lighting.lowercased()) {
                keywords.append(.lighting(lighting))
            }
        }

        return keywords
    }

    /// Build a detailed prompt with extracted keywords
    private static func buildPrompt(cardName: String, cardKind: Kinds, keywords: [VisualKeyword], fullDescription: String) -> String? {
        // Check if card name might trigger content filters (weapon/violence terms)
        let sensitivePrefixes = ["weapon", "gun", "rifle", "pistol", "sword", "blade", "knife", "axe", "bomb", "explosive"]
        let nameWords = cardName.lowercased().split(separator: " ").map(String.init)
        let hasSensitiveTerm = nameWords.contains { word in
            sensitivePrefixes.contains(where: { word.contains($0) })
        }

        // Extract visual description
        let visualDescription = extractVisualDescription(from: fullDescription)

        // For artifacts with weapon terms, prioritize description to avoid content filters
        if cardKind == .artifacts && hasSensitiveTerm && !visualDescription.isEmpty {
            // Lead with description, no card name
            return visualDescription
        } else {
            // Normal: style prefix + card name + description
            let stylePrefix = kindToPromptPrefix(cardKind)
            return "\(stylePrefix) \(cardName). \(visualDescription)"
        }
    }

    /// Extract visual description from full text
    /// Takes multiple sentences up to ~400 characters, filtering out dialogue
    private static func extractVisualDescription(from text: String) -> String {
        // If description is short enough, use it all (after filtering dialogue)
        if text.count <= 400 {
            // Remove dialogue if present
            let filtered = filterDialogue(from: text)
            return filtered.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Otherwise, extract first few visual sentences up to ~400 chars
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        var result = ""
        var charCount = 0

        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip empty sentences
            if trimmed.isEmpty { continue }

            // Skip dialogue
            if trimmed.contains("\"") || trimmed.contains("said") || trimmed.contains("asked") {
                continue
            }

            // Add sentence if it fits
            let withPunctuation = trimmed + "."
            if charCount + withPunctuation.count <= 400 {
                if !result.isEmpty {
                    result += " "
                }
                result += withPunctuation
                charCount += withPunctuation.count
            } else {
                break
            }
        }

        return result.isEmpty ? String(text.prefix(400)) : result
    }

    /// Remove dialogue from text
    private static func filterDialogue(from text: String) -> String {
        // Simple filter: remove quoted text
        var result = text
        while let startQuote = result.firstIndex(of: "\""),
              let endQuote = result[result.index(after: startQuote)...].firstIndex(of: "\"") {
            result.removeSubrange(startQuote...endQuote)
        }
        return result
    }

    /// Build a simple prompt without full description
    private static func buildSimplePrompt(cardName: String, cardKind: Kinds) -> String {
        // Check for sensitive terms
        let sensitivePrefixes = ["weapon", "gun", "rifle", "pistol", "sword", "blade", "knife", "axe", "bomb", "explosive"]
        let nameWords = cardName.lowercased().split(separator: " ").map(String.init)
        let hasSensitiveTerm = nameWords.contains { word in
            sensitivePrefixes.contains(where: { word.contains($0) })
        }

        // For artifacts with weapon terms, use generic description
        if cardKind == .artifacts && hasSensitiveTerm {
            return "An artifact with intricate details, high quality professional artwork, detailed"
        }

        let stylePrefix = kindToPromptPrefix(cardKind)
        return "\(stylePrefix) \(cardName), high quality professional artwork, detailed"
    }

    /// Build an atmospheric prompt focusing on mood
    private static func buildAtmosphericPrompt(cardName: String, cardKind: Kinds, keywords: [VisualKeyword], fullDescription: String) -> String? {
        // Check for sensitive terms
        let sensitivePrefixes = ["weapon", "gun", "rifle", "pistol", "sword", "blade", "knife", "axe", "bomb", "explosive"]
        let nameWords = cardName.lowercased().split(separator: " ").map(String.init)
        let hasSensitiveTerm = nameWords.contains { word in
            sensitivePrefixes.contains(where: { word.contains($0) })
        }

        let moodKeywords = keywords.filter {
            if case .mood = $0 { return true }
            return false
        }

        let lightingKeywords = keywords.filter {
            if case .lighting = $0 { return true }
            return false
        }

        // For artifacts with weapon terms, use description-based approach
        if cardKind == .artifacts && hasSensitiveTerm {
            let firstSentence = extractVisualSentence(from: fullDescription)
            if !firstSentence.isEmpty {
                let atmosphere = (moodKeywords + lightingKeywords).map(\.displayValue).joined(separator: ", ")
                if !atmosphere.isEmpty {
                    return "\(firstSentence), \(atmosphere) atmosphere, cinematic lighting"
                } else {
                    return "\(firstSentence), cinematic lighting, dramatic composition"
                }
            }
            return nil // Can't build atmospheric prompt without description
        }

        // Require at least some mood/lighting keywords OR extract first sentence for context
        if moodKeywords.isEmpty && lightingKeywords.isEmpty {
            // No atmospheric keywords, but we can still create an atmospheric variant
            // by using first visual sentence with cinematic styling
            let firstSentence = extractVisualSentence(from: fullDescription)
            let stylePrefix = kindToPromptPrefix(cardKind)
            return "\(stylePrefix) \(cardName). \(firstSentence), cinematic lighting, dramatic composition"
        }

        let stylePrefix = kindToPromptPrefix(cardKind)
        let atmosphere = (moodKeywords + lightingKeywords).map(\.displayValue).joined(separator: ", ")

        return "\(stylePrefix) \(cardName), \(atmosphere) atmosphere, cinematic composition"
    }

    /// Extract first visual sentence (non-dialogue) from description
    private static func extractVisualSentence(from text: String) -> String {
        // Split into sentences
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))

        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip dialogue
            if trimmed.contains("\"") || trimmed.contains("said") || trimmed.contains("asked") {
                continue
            }

            // Skip very short sentences
            if trimmed.count < 20 {
                continue
            }

            // Take first valid sentence, limit to ~100 chars
            let limited = String(trimmed.prefix(100))
            return limited
        }

        // Fallback: take first 100 chars
        return String(text.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Convert card kind to prompt prefix
    /// Internal visibility for use in AIImageGenerationView fallback
    static func kindToPromptPrefix(_ kind: Kinds) -> String {
        switch kind {
        case .characters:
            return "A detailed portrait of"
        case .locations:
            return "A landscape illustration of"
        case .buildings:
            return "Architectural concept art of"
        case .vehicles:
            return "Technical illustration of"
        case .artifacts:
            return "A detailed rendering of"
        case .maps:
            return "A map illustration of"
        case .worlds:
            return "A world map or globe visualization of"
        default:
            return "Concept art for"
        }
    }

    // MARK: - Keyword Collections

    private static let colorKeywords = [
        "red", "blue", "green", "yellow", "orange", "purple", "black", "white",
        "gray", "brown", "gold", "silver", "crimson", "azure", "emerald",
        "amber", "violet", "scarlet", "ebony", "ivory", "bronze", "copper"
    ]

    private static let physicalAttributes = [
        "tall", "short", "large", "small", "massive", "tiny", "towering",
        "slender", "muscular", "thin", "broad", "narrow", "wide", "deep",
        "ancient", "young", "old", "weathered", "pristine", "ruined"
    ]

    private static let moodKeywords = [
        "dark", "bright", "ominous", "cheerful", "mysterious", "serene",
        "chaotic", "peaceful", "menacing", "welcoming", "forbidding",
        "inviting", "eerie", "warm", "cold", "hostile", "friendly"
    ]

    private static let materialKeywords = [
        "stone", "wood", "metal", "glass", "crystal", "leather", "cloth",
        "marble", "granite", "steel", "iron", "brass", "silk", "velvet",
        "fur", "scales", "feathers"
    ]

    private static let lightingKeywords = [
        "glowing", "shimmering", "shadowy", "bright", "dim", "radiant",
        "luminous", "dark", "lit", "illuminated", "moonlit", "sunlit",
        "torchlit", "candlelit", "twilight", "dawn", "dusk"
    ]

    // MARK: - Supporting Types

    /// Visual keyword categories
    enum VisualKeyword {
        case color(String)
        case physical(String)
        case mood(String)
        case material(String)
        case lighting(String)

        var displayValue: String {
            switch self {
            case .color(let value),
                 .physical(let value),
                 .mood(let value),
                 .material(let value),
                 .lighting(let value):
                return value
            }
        }
    }
}
