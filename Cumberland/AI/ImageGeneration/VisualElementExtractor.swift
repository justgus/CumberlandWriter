//
//  VisualElementExtractor.swift
//  Cumberland
//
//  Created for ER-0021: AI-Powered Visual Element Extraction
//  Phase 1: Core Infrastructure
//

import Foundation

/// Visual element extraction orchestrator
/// Uses AI providers to extract visual elements from narrative descriptions
/// Optimizes prompts for image generation based on provider capabilities
/// ER-0021: AI-Powered Visual Element Extraction for Image Generation
class VisualElementExtractor {

    // MARK: - Properties

    private let provider: AIProviderProtocol
    private let settings: AISettings

    // Performance optimization: Cache extracted elements to avoid re-extracting same text
    private var extractionCache: [String: VisualElements] = [:]
    private let cacheMaxSize = 20 // Maximum cached extractions

    // MARK: - Initialization

    init(provider: AIProviderProtocol, settings: AISettings = .shared) {
        self.provider = provider
        self.settings = settings
    }

    // MARK: - Public API

    /// Extract visual elements from a card description
    /// - Parameters:
    ///   - text: The narrative description to analyze
    ///   - cardKind: The type of card being analyzed
    /// - Returns: Extracted visual elements optimized for image generation
    /// - Throws: AIProviderError if extraction fails
    func extractVisualElements(from text: String, cardKind: Kinds) async throws -> VisualElements {
        // Validate input
        guard !text.isEmpty else {
            throw AIProviderError.invalidInput(reason: "Text cannot be empty")
        }

        let wordCount = text.split(separator: " ").count
        guard wordCount >= 10 else {
            throw AIProviderError.textTooShort(minLength: 10, actual: wordCount)
        }

        // Performance optimization: Check cache first
        let cacheKey = "\(cardKind.rawValue):\(text.prefix(200))" // Use first 200 chars as key
        if let cached = extractionCache[cacheKey] {
            #if DEBUG
            print("✅ [VisualElementExtractor] Using cached extraction")
            #endif
            return cached
        }

        // Edge case: Truncate very long descriptions to prevent performance issues
        // Maximum 2000 words (~4000 tokens for most providers)
        let maxWords = 2000
        let truncatedText: String
        if wordCount > maxWords {
            let words = text.split(separator: " ", maxSplits: maxWords, omittingEmptySubsequences: true)
            truncatedText = words.prefix(maxWords).joined(separator: " ")
            #if DEBUG
            print("⚠️ [VisualElementExtractor] Description truncated from \(wordCount) to \(maxWords) words")
            #endif
        } else {
            truncatedText = text
        }

        #if DEBUG
        print("🎨 [VisualElementExtractor] Extracting visual elements")
        print("   Provider: \(provider.name)")
        print("   Card kind: \(cardKind.rawValue)")
        print("   Word count: \(wordCount) (using \(min(wordCount, maxWords)))")
        #endif

        // Build extraction prompt based on card type
        let extractionPrompt = buildExtractionPrompt(for: cardKind, text: truncatedText)

        // Call AI provider with visual extraction task
        let result = try await provider.analyzeText(extractionPrompt, for: .visualElementExtraction)

        // Parse response into VisualElements
        let elements = parseVisualElements(from: result, cardKind: cardKind, sourceText: text)

        #if DEBUG
        print("✅ [VisualElementExtractor] Extraction complete")
        print("   Confidence: \(String(format: "%.0f", elements.extractionConfidence * 100))%")
        print("   Has sufficient data: \(elements.hasSufficientData)")
        if let framing = elements.framing, let angle = elements.cameraAngle {
            print("   Cinematic framing: \(framing.displayName), \(angle.displayName)")
        }
        #endif

        // Store in cache for future use
        extractionCache[cacheKey] = elements

        // Limit cache size to prevent memory growth
        if extractionCache.count > cacheMaxSize {
            // Remove oldest entry (first key in dictionary)
            if let firstKey = extractionCache.keys.first {
                extractionCache.removeValue(forKey: firstKey)
            }
        }

        return elements
    }

    // MARK: - Extraction Prompts

    /// Build card-type-specific extraction prompt
    private func buildExtractionPrompt(for cardKind: Kinds, text: String) -> String {
        let basePrompt = """
        You are analyzing a description for visual image generation. Extract ONLY the visual elements that would appear in an image.
        Ignore backstory, personality traits (unless they translate to visible expression), relationships, and narrative context.

        Description to analyze:
        \(text)

        """

        switch cardKind {
        case .characters:
            return basePrompt + """

            Extract the following visual elements for a CHARACTER PORTRAIT:

            1. PHYSICAL BUILD: Height, body type, distinctive features (e.g., "tall, lithe, athletic")
            2. HAIR: Color, length, style (e.g., "long straight dark hair in ponytail")
            3. EYES: Color, distinctive features (e.g., "bright green eyes")
            4. FACIAL FEATURES: Notable characteristics (e.g., "strong chin, short nose")
            5. SKIN TONE: If specified (e.g., "pale", "olive", "dark brown")
            6. CLOTHING: What they're wearing (e.g., "orange astronaut jumpsuit")
            7. ACCESSORIES: Items worn or carried (e.g., "silver necklace", "leather gloves")
            8. EXPRESSION: Visual demeanor - translate personality traits to visible expressions
               - "quick to laugh" → "warm smile, friendly expression"
               - "commanding" → "confident posture, direct gaze"
               - "mysterious" → "shadowed features, enigmatic expression"
            9. POSE: Body position or posture (e.g., "standing confidently", "seated")

            CRITICAL RULES:
            - Filter out backstory (birthplace, education, history)
            - Filter out relationships (family, friends, enemies)
            - Filter out temporal qualifiers ("most days", "usually")
            - Translate abstract personality traits to visible expressions
            - Include only what would be visible in a portrait

            Return structured data with confidence score (0.0-1.0) based on clarity of visual descriptions.
            """

        case .locations:
            return basePrompt + """

            Extract the following visual elements for a NEUTRAL LOCATION VIEW:

            1. PRIMARY FEATURES: Main landscape or scene elements (e.g., ["twin moons", "rolling sand dunes"])
            2. SCALE: Size and scope (e.g., "vast", "intimate", "expansive")
            3. ARCHITECTURE: Buildings or structures present
            4. VEGETATION: Plants, trees, natural elements
            5. TERRAIN: Ground features (mountains, water, desert)
            6. COLORS: Dominant colors if specified

            IMPORTANT: This is a NEUTRAL location view (not a scene).
            - Use even, documentary lighting
            - No dramatic mood or atmosphere
            - No lighting effects unless part of the location itself (e.g., "bioluminescent flora")
            - Objective, establishing shot perspective

            Example: "La Porte Cafe" → warm, welcoming interior with neutral lighting
            vs "Tense confrontation at La Porte Cafe" → would be a scene (not this task)

            Return structured data with confidence score.
            """

        case .scenes:
            return basePrompt + """

            Extract the following visual elements for a SCENE (Location + Mood):

            1. PRIMARY FEATURES: Main scene elements from location
            2. LIGHTING: Time of day, quality of light, lighting mood
               - Analyze scene events for mood indicators:
               - "confrontation", "battle", "argument" → dark, dramatic lighting
               - "celebration", "party", "joy" → bright, warm lighting
               - "mystery", "investigation" → atmospheric, shadowy lighting
               - "romance", "tender" → soft, warm lighting
            3. ATMOSPHERE: Weather, air quality, atmospheric conditions
            4. MOOD: Emotional tone derived from scene events
            5. COLORS: Color palette influenced by mood
            6. EMOTIONAL TONE: Overall feeling of the scene

            CRITICAL: Scenes include MOOD and LIGHTING based on narrative events.
            - Analyze the scene description for emotional indicators
            - Translate narrative tension/joy/fear into visual lighting and color
            - Dark scenes = dramatic shadows, moody lighting
            - Joyful scenes = bright, warm colors

            Example: "Tense confrontation at La Porte Cafe"
            → Dark shadows, dramatic lighting, tense atmosphere

            Return structured data with confidence score.
            """

        case .artifacts:
            return basePrompt + """

            Extract the following visual elements for an ARTIFACT:

            1. OBJECT TYPE: What kind of object (e.g., "sword", "amulet", "book")
            2. PARTIAL vs COMPLETE: Only show described parts
               - If description mentions hilt but not blade → "hilt only"
               - If full object described → show complete object
               - DO NOT hallucinate missing details
            3. SIZE AND SCALE: Dimensions if specified
            4. MATERIALS: What it's made of (e.g., ["ancient metal", "glowing crystal"])
            5. COLORS AND TEXTURES: Surface appearance
            6. CONDITION: Age and state (e.g., "pristine", "battle-worn", "ancient")
            7. DISTINCTIVE FEATURES: Runes, gems, patterns, decorations
            8. FRAMING: Determine shot framing
               - Detail-focused → close-up
               - Full object → medium shot
            9. LIGHTING: Lighting style
               - Legendary/important artifact → dramatic lighting
               - Common object → neutral lighting

            IMPORTANT: Only show what's actually described. Don't invent missing parts.

            Return structured data with confidence score.
            """

        case .buildings:
            return basePrompt + """

            Extract the following visual elements for a BUILDING:

            1. ARCHITECTURAL STYLE: Style and features (e.g., "gothic", "modern", "fantasy")
            2. SIZE AND SCALE: Determined from description
            3. MATERIALS: Construction materials
            4. CONDITION: State of repair (e.g., "maintained", "ruined", "ancient")
            5. DISTINCTIVE FEATURES: Towers, gates, decorations
            6. SETTING: Surroundings and context
            7. NARRATIVE IMPORTANCE: Determine perspective from narrative cues
               - "grand", "impressive", "towering", "majestic", "imposing" → LOW ANGLE (looking up)
               - "humble", "small", "modest", "simple", "tiny" → HIGH ANGLE (looking down)
               - No size indicators → eye-level perspective

            CRITICAL CINEMATIC FRAMING:
            The camera angle should reflect narrative importance:
            - Grand, impressive buildings → viewer looks UP (low angle shot)
            - Humble, small buildings → viewer looks DOWN (high angle, aerial view)
            - Neutral buildings → eye-level

            Example: "The Magic Academy of Felthome, with its grand gates and soaring towers"
            → Low angle shot looking up at impressive gates (makes it feel grand)

            Example: "A thatched shack on the outskirts of the village"
            → High angle shot looking down at small shack (makes it feel humble)

            Return structured data with confidence score and narrative_importance field.
            """

        case .vehicles:
            return basePrompt + """

            Extract the following visual elements for a VEHICLE:

            1. VEHICLE TYPE: Kind of vehicle (e.g., "ship", "airship", "carriage", "dragon")
            2. SIZE AND SCALE: Dimensions if specified
            3. DESIGN: Visual design and construction
            4. MATERIALS: What it's made of
            5. CONDITION: Age and state
            6. DISTINCTIVE FEATURES: Sails, armor, decorations
            7. MOTION STATE: At rest or in motion
            8. FRAMING: Based on narrative role
               - Heroic ship → dynamic angle
               - Transport → neutral perspective

            Return structured data with confidence score.
            """

        default:
            // Generic fallback
            return basePrompt + """

            Extract visual elements suitable for image generation:

            1. MAIN SUBJECT: Primary focus of the image
            2. SETTING: Background and context
            3. COLORS: Dominant colors if specified
            4. LIGHTING: Light conditions
            5. ATMOSPHERE: Overall mood

            Return structured data with confidence score.
            """
        }
    }

    // MARK: - Response Parsing

    /// Parse AI provider response into VisualElements model
    private func parseVisualElements(
        from result: AnalysisResult,
        cardKind: Kinds,
        sourceText: String
    ) -> VisualElements {
        // Create base VisualElements
        var elements = VisualElements(
            sourceText: sourceText,
            cardKind: cardKind,
            extractionConfidence: 0.7 // Default confidence
        )

        // Parse provider response
        // For now, we'll use a simple text parsing approach
        // TODO: Update providers to return structured VisualElements data
        // This is a placeholder that will be updated when providers support visualElementExtraction

        // Use metadata if available
        if result.metadata != nil {
            elements.extractionConfidence = 0.75 // Increase if provider provided metadata
        }

        // Simple heuristic extraction as fallback
        // This will be replaced when providers return structured visual data
        elements = performBasicExtraction(from: sourceText, for: cardKind)

        return elements
    }

    /// Perform basic extraction using text analysis (fallback until providers updated)
    private func performBasicExtraction(from text: String, for cardKind: Kinds) -> VisualElements {
        var elements = VisualElements(
            sourceText: text,
            cardKind: cardKind,
            extractionConfidence: 0.6 // Lower confidence for basic extraction
        )

        let lowercasedText = text.lowercased()

        switch cardKind {
        case .characters:
            // Look for physical descriptors
            if lowercasedText.contains("tall") || lowercasedText.contains("short") ||
               lowercasedText.contains("lithe") || lowercasedText.contains("athletic") {
                elements.physicalBuild = extractPhrase(from: text, containing: ["tall", "short", "lithe", "athletic", "thin", "muscular"])
            }

            // Look for hair descriptions
            if lowercasedText.contains("hair") {
                elements.hair = extractPhrase(from: text, containing: ["hair"])
            }

            // Look for eye descriptions
            if lowercasedText.contains("eyes") {
                elements.eyes = extractPhrase(from: text, containing: ["eyes"])
            }

            // Look for facial features
            if lowercasedText.contains("chin") || lowercasedText.contains("nose") ||
               lowercasedText.contains("cheek") || lowercasedText.contains("jaw") ||
               lowercasedText.contains("brow") || lowercasedText.contains("forehead") ||
               lowercasedText.contains("lips") || lowercasedText.contains("mouth") ||
               lowercasedText.contains("face") {
                elements.facialFeatures = extractPhrase(from: text, containing: ["chin", "nose", "cheek", "jaw", "brow", "forehead", "lips", "mouth", "face"])
            }

            // Look for clothing
            if lowercasedText.contains("wearing") || lowercasedText.contains("dressed") ||
               lowercasedText.contains("uniform") || lowercasedText.contains("robe") {
                elements.clothing = extractPhrase(from: text, containing: ["wearing", "dressed", "uniform", "robe", "cloak", "armor", "suit"])
            }

            // Infer expression from personality traits
            if lowercasedText.contains("laugh") || lowercasedText.contains("cheerful") {
                elements.expression = "warm smile, friendly expression"
            } else if lowercasedText.contains("stern") || lowercasedText.contains("serious") {
                elements.expression = "serious expression, focused gaze"
            } else if lowercasedText.contains("mysterious") {
                elements.expression = "enigmatic expression, shadowed features"
            }

        case .buildings:
            // Infer narrative importance from descriptive words
            if lowercasedText.contains("grand") || lowercasedText.contains("impressive") ||
               lowercasedText.contains("towering") || lowercasedText.contains("majestic") ||
               lowercasedText.contains("imposing") {
                elements.narrativeImportance = "grand"
                elements.cameraAngle = .lowAngleLookingUp
                elements.framing = .wideEstablishing
            } else if lowercasedText.contains("humble") || lowercasedText.contains("small") ||
                      lowercasedText.contains("modest") || lowercasedText.contains("tiny") {
                elements.narrativeImportance = "humble"
                elements.cameraAngle = .highAngleLookingDown
                elements.framing = .wideEstablishing
            } else {
                elements.narrativeImportance = "neutral"
                elements.cameraAngle = .eyeLevel
                elements.framing = .mediumShot
            }

        case .scenes:
            elements.isSceneWithMood = true

            // Analyze scene for mood indicators
            if lowercasedText.contains("confront") || lowercasedText.contains("battle") ||
               lowercasedText.contains("tense") || lowercasedText.contains("argument") {
                elements.mood = "tense, confrontational"
                elements.lightingStyle = .dark
            } else if lowercasedText.contains("celebrat") || lowercasedText.contains("joy") ||
                      lowercasedText.contains("party") || lowercasedText.contains("festival") {
                elements.mood = "joyful, celebratory"
                elements.lightingStyle = .bright
            } else if lowercasedText.contains("mystery") || lowercasedText.contains("investigate") {
                elements.mood = "mysterious, intriguing"
                elements.lightingStyle = .dark
            } else if lowercasedText.contains("romantic") || lowercasedText.contains("tender") {
                elements.mood = "romantic, intimate"
                elements.lightingStyle = .soft
            }

        case .artifacts:
            // Check if only partial object described
            if lowercasedText.contains("hilt") && !lowercasedText.contains("blade") {
                elements.showPartial = "hilt only"
                elements.framing = .closeUp
            }

            // Determine lighting based on narrative importance
            if lowercasedText.contains("legendary") || lowercasedText.contains("ancient") ||
               lowercasedText.contains("powerful") {
                elements.lightingStyle = .dramatic
            } else {
                elements.lightingStyle = .neutral
            }

        default:
            break
        }

        // Edge case: Adjust confidence based on extraction results
        // If we extracted very little data, lower the confidence
        let extractedPropertyCount = countExtractedProperties(elements)
        if extractedPropertyCount == 0 {
            elements.extractionConfidence = 0.3 // Very low confidence - no visual elements found
        } else if extractedPropertyCount == 1 {
            elements.extractionConfidence = 0.5 // Low confidence - sparse data
        } else if extractedPropertyCount >= 4 {
            elements.extractionConfidence = 0.75 // Good confidence - substantial data
        }
        // Otherwise keep default 0.6

        return elements
    }

    /// Count how many properties were successfully extracted
    private func countExtractedProperties(_ elements: VisualElements) -> Int {
        var count = 0

        // Count non-nil, non-empty properties
        if elements.physicalBuild != nil && !elements.physicalBuild!.isEmpty { count += 1 }
        if elements.hair != nil && !elements.hair!.isEmpty { count += 1 }
        if elements.eyes != nil && !elements.eyes!.isEmpty { count += 1 }
        if elements.facialFeatures != nil && !elements.facialFeatures!.isEmpty { count += 1 }
        if elements.skinTone != nil && !elements.skinTone!.isEmpty { count += 1 }
        if elements.clothing != nil && !elements.clothing!.isEmpty { count += 1 }
        if elements.accessories != nil && !elements.accessories!.isEmpty { count += 1 }
        if elements.expression != nil && !elements.expression!.isEmpty { count += 1 }
        if elements.pose != nil && !elements.pose!.isEmpty { count += 1 }
        if elements.primaryFeatures != nil && !elements.primaryFeatures!.isEmpty { count += 1 }
        if elements.scale != nil && !elements.scale!.isEmpty { count += 1 }
        if elements.architecture != nil && !elements.architecture!.isEmpty { count += 1 }
        if elements.vegetation != nil && !elements.vegetation!.isEmpty { count += 1 }
        if elements.objectType != nil && !elements.objectType!.isEmpty { count += 1 }
        if elements.materials != nil && !elements.materials!.isEmpty { count += 1 }
        if elements.condition != nil && !elements.condition!.isEmpty { count += 1 }
        if elements.architecturalStyle != nil && !elements.architecturalStyle!.isEmpty { count += 1 }
        if elements.vehicleType != nil && !elements.vehicleType!.isEmpty { count += 1 }
        if elements.vehicleDesign != nil && !elements.vehicleDesign!.isEmpty { count += 1 }
        if elements.motionState != nil && !elements.motionState!.isEmpty { count += 1 }
        if elements.colors != nil && !elements.colors!.isEmpty { count += 1 }
        if elements.mood != nil && !elements.mood!.isEmpty { count += 1 }
        if elements.backgroundSetting != nil && !elements.backgroundSetting!.isEmpty { count += 1 }
        if elements.lighting != nil && !elements.lighting!.isEmpty { count += 1 }
        if elements.atmosphere != nil && !elements.atmosphere!.isEmpty { count += 1 }

        return count
    }

    /// Extract a targeted phrase containing specific keywords from text
    /// DR-0072: Rewritten to extract precise phrases instead of full sentences
    private func extractPhrase(from text: String, containing keywords: [String]) -> String? {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))

        for sentence in sentences {
            let lowercased = sentence.lowercased()
            for keyword in keywords {
                if lowercased.contains(keyword.lowercased()) {
                    // Try to extract just the relevant descriptive phrase
                    if let extracted = extractTargetedPhrase(from: sentence, keyword: keyword) {
                        return extracted
                    }
                }
            }
        }

        return nil
    }

    /// Extract a targeted descriptive phrase around a keyword
    /// DR-0072: Extracts only the relevant visual description, not the full sentence
    private func extractTargetedPhrase(from sentence: String, keyword: String) -> String? {
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()

        // For "hair" keyword, extract hair description specifically
        if keyword.lowercased() == "hair" {
            // Pattern: "with [adjectives] hair [that/which details]"
            // or "has [adjectives] hair"
            // Extract from "with" or "has" up to and including "hair" + optional clause
            if let hairRange = lowercased.range(of: "hair") {
                let beforeHair = String(lowercased[..<hairRange.lowerBound])

                // Find start of hair description (look for "with", "has", comma, or sentence start)
                var startIdx = trimmed.startIndex
                if let withRange = beforeHair.range(of: "with", options: .backwards) {
                    startIdx = trimmed.index(withRange.upperBound, offsetBy: 1)
                } else if let hasRange = beforeHair.range(of: "has", options: .backwards) {
                    startIdx = trimmed.index(hasRange.upperBound, offsetBy: 1)
                } else if let commaRange = beforeHair.range(of: ",", options: .backwards) {
                    startIdx = trimmed.index(commaRange.upperBound, offsetBy: 1)
                }

                // Find end of hair description (look for "that", "which", "while", comma, or sentence end)
                let afterHairStart = hairRange.upperBound
                var endIdx = trimmed.endIndex
                let afterHair = String(lowercased[afterHairStart...])

                if let thatRange = afterHair.range(of: " that ") {
                    endIdx = trimmed.index(afterHairStart, offsetBy: thatRange.lowerBound.utf16Offset(in: afterHair))
                } else if let whichRange = afterHair.range(of: " which ") {
                    endIdx = trimmed.index(afterHairStart, offsetBy: whichRange.lowerBound.utf16Offset(in: afterHair))
                } else if let whileRange = afterHair.range(of: " while ") {
                    endIdx = trimmed.index(afterHairStart, offsetBy: whileRange.lowerBound.utf16Offset(in: afterHair))
                } else if let commaRange = afterHair.range(of: ",") {
                    endIdx = trimmed.index(afterHairStart, offsetBy: commaRange.lowerBound.utf16Offset(in: afterHair))
                } else {
                    // Include up to 6 words after "hair"
                    let words = afterHair.split(separator: " ")
                    if words.count > 6 {
                        if let sixthWord = words.prefix(6).last {
                            if let range = afterHair.range(of: String(sixthWord)) {
                                endIdx = trimmed.index(afterHairStart, offsetBy: range.upperBound.utf16Offset(in: afterHair))
                            }
                        }
                    }
                }

                let extracted = String(trimmed[startIdx..<endIdx]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !extracted.isEmpty {
                    return extracted
                }
            }
        }

        // For physical descriptors (tall, short, athletic, etc.), extract adjectives
        else if ["tall", "short", "athletic", "lithe", "thin", "muscular"].contains(keyword.lowercased()) {
            // Look for pattern: "is a [adjectives] [noun]" or "[adjectives] [noun]"
            if let isARange = lowercased.range(of: "is a ") {
                let afterIsA = trimmed.index(isARange.upperBound, offsetBy: 0)
                let remainder = String(trimmed[afterIsA...])

                // Extract up to "with" or comma or end
                var endIdx = remainder.endIndex
                if let withRange = remainder.range(of: " with ") {
                    endIdx = withRange.lowerBound
                } else if let commaRange = remainder.range(of: ",") {
                    endIdx = commaRange.lowerBound
                } else {
                    // Take up to 5 words
                    let words = remainder.split(separator: " ")
                    if words.count > 5 {
                        if let fifthWord = words.prefix(5).last {
                            if let range = remainder.range(of: String(fifthWord)) {
                                endIdx = range.upperBound
                            }
                        }
                    }
                }

                let extracted = String(remainder[..<endIdx]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !extracted.isEmpty {
                    return extracted
                }
            }
        }

        // For "wearing" or "dressed", extract clothing description
        else if ["wearing", "dressed"].contains(keyword.lowercased()) {
            if let wearingRange = lowercased.range(of: keyword.lowercased()) {
                let afterWearing = trimmed.index(wearingRange.upperBound, offsetBy: 1)
                let remainder = String(trimmed[afterWearing...])

                // Extract up to period, comma, or "while"
                var endIdx = remainder.endIndex
                if let periodRange = remainder.range(of: ".") {
                    endIdx = periodRange.lowerBound
                } else if let whileRange = remainder.range(of: " while ") {
                    endIdx = whileRange.lowerBound
                } else {
                    // Take up to 6 words
                    let words = remainder.split(separator: " ")
                    if words.count > 6 {
                        if let sixthWord = words.prefix(6).last {
                            if let range = remainder.range(of: String(sixthWord)) {
                                endIdx = range.upperBound
                            }
                        }
                    }
                }

                let extracted = String(remainder[..<endIdx]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !extracted.isEmpty && !extracted.starts(with: "her ") && !extracted.starts(with: "his ") {
                    return extracted
                }
            }
        }

        // For "eyes", extract eye description
        else if keyword.lowercased() == "eyes" {
            if let eyesRange = lowercased.range(of: "eyes") {
                // Look backwards for adjectives before "eyes", stopping at comma
                let beforeEyes = String(lowercased[..<eyesRange.lowerBound])

                // Find the last comma before "eyes" to avoid pulling in other features
                let relevantText: String
                if let lastComma = beforeEyes.range(of: ",", options: .backwards) {
                    // Take text after the last comma
                    relevantText = String(beforeEyes[lastComma.upperBound...])
                } else {
                    // No comma, use all text before eyes
                    relevantText = beforeEyes
                }

                // Extract descriptive words (adjectives/colors) before "eyes"
                let words = relevantText.split(separator: " ").map(String.init)

                // Take last 2-3 words (color/descriptors)
                let startOffset = max(0, words.count - 3)
                let descriptors = words.suffix(from: startOffset)

                if !descriptors.isEmpty {
                    let extracted = descriptors.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines) + " eyes"
                    return extracted
                }
            }
        }

        // FALLBACK: General descriptive phrase extraction
        // DR-0072: For keywords not matching specific patterns (e.g., "chin", "nose", "jumpsuit"),
        // extract the local descriptive phrase around the keyword
        if let keywordRange = lowercased.range(of: keyword.lowercased()) {
            let beforeKeyword = String(lowercased[..<keywordRange.lowerBound])
            let afterKeywordStart = keywordRange.upperBound
            let afterKeyword = String(lowercased[afterKeywordStart...])

            // Find start of phrase: look backwards for comma, "with", "and", "has", or beginning
            var startIdx = trimmed.startIndex
            let boundaryWords = ["with", "and", "has", "including"]

            for boundary in boundaryWords {
                if let range = beforeKeyword.range(of: boundary + " ", options: .backwards) {
                    let possibleStart = trimmed.index(range.upperBound, offsetBy: 0)
                    if possibleStart > startIdx {
                        startIdx = possibleStart
                    }
                }
            }

            // Also check for comma
            if let commaRange = beforeKeyword.range(of: ",", options: .backwards) {
                let possibleStart = trimmed.index(commaRange.upperBound, offsetBy: 1)
                if possibleStart > startIdx {
                    startIdx = possibleStart
                }
            }

            // If we're still at the beginning and the sentence is long, try to find a more specific start
            if startIdx == trimmed.startIndex && trimmed.count > 40 {
                // Take last 5-8 words before keyword
                let words = beforeKeyword.split(separator: " ")
                if words.count > 8 {
                    let relevantWords = words.suffix(8)
                    if let firstRelevantWord = relevantWords.first {
                        if let range = beforeKeyword.range(of: String(firstRelevantWord), options: .backwards) {
                            startIdx = trimmed.index(trimmed.startIndex, offsetBy: range.lowerBound.utf16Offset(in: beforeKeyword))
                        }
                    }
                }
            }

            // Find end of phrase: look forward for phrase boundaries
            var endIdx = trimmed.endIndex

            // Special handling for comma-separated lists (e.g., "strong chin, short nose")
            // Include up to 2 items after the keyword if separated by commas
            let clauseBoundaries = [" that ", " which ", " while ", "."]
            var foundClauseBoundary = false

            // First check for clause boundaries (these definitely end the phrase)
            for boundary in clauseBoundaries {
                if let range = afterKeyword.range(of: boundary) {
                    let possibleEnd = trimmed.index(afterKeywordStart, offsetBy: range.lowerBound.utf16Offset(in: afterKeyword))
                    if possibleEnd < endIdx {
                        endIdx = possibleEnd
                        foundClauseBoundary = true
                    }
                }
            }

            // If no clause boundary, look for commas but be smarter about lists
            if !foundClauseBoundary {
                // Count commas in the phrase - if we have a list, include 1-2 items after keyword
                let commas = afterKeyword.components(separatedBy: ",")
                if commas.count > 1 && commas.count <= 3 {
                    // Looks like a list - take up to second comma or 8 words, whichever comes first
                    let words = afterKeyword.split(separator: " ")
                    let wordLimit = min(8, words.count)

                    if wordLimit > 0 {
                        let limitedPhrase = words.prefix(wordLimit).joined(separator: " ")
                        // Find second comma or use end
                        let secondCommaIndex = commas.count > 2 ? 2 : commas.count
                        let upToSecondComma = commas.prefix(secondCommaIndex).joined(separator: ",")

                        // Use whichever is shorter
                        let targetPhrase = upToSecondComma.count < limitedPhrase.count ? upToSecondComma : limitedPhrase

                        if let range = afterKeyword.range(of: targetPhrase) {
                            endIdx = trimmed.index(afterKeywordStart, offsetBy: range.upperBound.utf16Offset(in: afterKeyword))
                        }
                    }
                } else if let firstComma = afterKeyword.range(of: ",") {
                    // Single comma or no comma - stop at first comma
                    endIdx = trimmed.index(afterKeywordStart, offsetBy: firstComma.lowerBound.utf16Offset(in: afterKeyword))
                }
            }

            // If still no boundary, take up to 6 words after keyword
            if endIdx == trimmed.endIndex {
                let words = afterKeyword.split(separator: " ")
                if words.count > 6 {
                    if let sixthWord = words.prefix(6).last {
                        if let range = afterKeyword.range(of: String(sixthWord)) {
                            endIdx = trimmed.index(afterKeywordStart, offsetBy: range.upperBound.utf16Offset(in: afterKeyword))
                        }
                    }
                }
            }

            // Extract the phrase
            let extracted = String(trimmed[startIdx..<endIdx]).trimmingCharacters(in: .whitespacesAndNewlines)

            // Validate: make sure it's not too long (avoid full sentence)
            let wordCount = extracted.split(separator: " ").count
            if !extracted.isEmpty && wordCount <= 12 {
                return extracted
            }
        }

        // Ultimate fallback: return nil (don't extract full sentence)
        return nil
    }
}

// MARK: - Convenience Extensions

extension VisualElementExtractor {
    /// Extract visual elements and generate provider-specific prompt
    func extractAndGeneratePrompt(
        from text: String,
        cardKind: Kinds,
        for provider: AIProviderProtocol
    ) async throws -> (elements: VisualElements, prompt: String) {
        let elements = try await extractVisualElements(from: text, cardKind: cardKind)

        // Generate provider-specific prompt
        let prompt: String
        if provider.name.contains("Apple") {
            // For Apple Intelligence, we'll return concepts joined
            let concepts = elements.generateConceptsForAppleIntelligence()
            prompt = concepts.joined(separator: " | ")
        } else if provider.name.contains("OpenAI") {
            prompt = elements.generatePromptForOpenAI()
        } else if provider.name.contains("Anthropic") {
            prompt = elements.generatePromptForAnthropic()
        } else {
            // Default to OpenAI format
            prompt = elements.generatePromptForOpenAI()
        }

        return (elements, prompt)
    }
}
