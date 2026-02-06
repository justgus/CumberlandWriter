//
//  VisualElements.swift
//  Cumberland
//
//  Created for ER-0021: AI-Powered Visual Element Extraction
//  Phase 1: Core Infrastructure
//

import Foundation

// MARK: - Visual Elements Model

/// Represents extracted visual elements from a narrative description
/// Used to generate optimized image generation prompts
/// ER-0021: AI-Powered Visual Element Extraction for Image Generation
struct VisualElements: Codable {
    // MARK: - Metadata

    /// Source text that was analyzed
    var sourceText: String

    /// Type of card being analyzed
    var cardKind: Kinds

    /// Confidence score for the extraction (0.0 to 1.0)
    var extractionConfidence: Double

    /// When the extraction was performed
    var extractedAt: Date

    /// Flag to indicate using original prompt instead of extracted elements
    /// Used when extraction returns insufficient data but original prompt exists
    var useOriginalPrompt: Bool = false

    // MARK: - Character-Specific Elements

    /// Physical build and body type (e.g., "tall, lithe, athletic")
    var physicalBuild: String?

    /// Hair description (e.g., "long straight dark hair in ponytail")
    var hair: String?

    /// Eye description (e.g., "bright green eyes")
    var eyes: String?

    /// Facial features (e.g., "strong chin, short nose")
    var facialFeatures: String?

    /// Skin tone if specified (e.g., "pale", "olive", "dark brown")
    var skinTone: String?

    /// Clothing and costume (e.g., "orange astronaut jumpsuit")
    var clothing: String?

    /// Accessories worn or carried (e.g., ["silver necklace", "leather gloves"])
    var accessories: [String]?

    /// Expression and demeanor (e.g., "friendly smile, warm expression")
    /// Translated from personality traits like "quick to laugh"
    var expression: String?

    /// Pose or posture (e.g., "standing confidently", "seated")
    var pose: String?

    // MARK: - Location-Specific Elements

    /// Primary landscape or scene features (e.g., ["twin moons", "rolling sand dunes"])
    var primaryFeatures: [String]?

    /// Scale and scope (e.g., "vast", "intimate", "expansive")
    var scale: String?

    /// Architectural elements if present
    var architecture: String?

    /// Vegetation and terrain
    var vegetation: String?

    /// Whether this is a scene with mood (vs neutral location)
    var isSceneWithMood: Bool

    // MARK: - Artifact-Specific Elements

    /// Type of object (e.g., "sword", "amulet", "book")
    var objectType: String?

    /// Materials and textures (e.g., ["ancient metal", "glowing crystal"])
    var materials: [String]?

    /// Condition and age (e.g., "pristine", "battle-worn", "ancient")
    var condition: String?

    /// Partial view specification (e.g., "hilt only" if blade not described)
    var showPartial: String?

    // MARK: - Building-Specific Elements

    /// Architectural style (e.g., "gothic", "modern", "fantasy")
    var architecturalStyle: String?

    /// Narrative importance for framing (e.g., "grand", "humble", "neutral")
    var narrativeImportance: String?

    // MARK: - Vehicle-Specific Elements

    /// Vehicle type (e.g., "ship", "airship", "carriage")
    var vehicleType: String?

    /// Design and construction details
    var vehicleDesign: String?

    /// Motion state (e.g., "at anchor", "in flight", "moving")
    var motionState: String?

    // MARK: - Common Elements (All Types)

    /// Colors mentioned in description
    var colors: [String]?

    /// Overall mood or atmosphere
    var mood: String?

    /// Background or setting context
    var backgroundSetting: String?

    /// Lighting conditions (e.g., "sunset", "ethereal glow", "dramatic")
    var lighting: String?

    /// Atmospheric conditions (e.g., "foggy", "clear", "stormy")
    var atmosphere: String?

    // MARK: - Cinematic Framing (ER-0021 Extended Scope)

    /// Camera angle inferred from narrative context
    var cameraAngle: CameraAngle?

    /// Shot framing (close-up, medium, wide, etc.)
    var framing: Framing?

    /// Lighting style for mood
    var lightingStyle: LightingStyle?

    // MARK: - Initialization

    init(
        sourceText: String,
        cardKind: Kinds,
        extractionConfidence: Double = 0.0,
        extractedAt: Date = Date()
    ) {
        self.sourceText = sourceText
        self.cardKind = cardKind
        self.extractionConfidence = extractionConfidence
        self.extractedAt = extractedAt
        self.isSceneWithMood = (cardKind == .scenes)
    }

    // MARK: - Provider-Specific Prompt Generation

    /// Generate appearance description for Apple Intelligence (character portraits)
    /// This provides a consolidated appearance string that Image Playground uses
    func generateAppearanceDescription() -> String? {
        guard cardKind == .characters else { return nil }

        var parts: [String] = []

        // Physical build is the foundation
        if let build = physicalBuild {
            parts.append(build)
        }

        // Add key visual identifiers
        if let hair = hair {
            parts.append(hair)
        }

        if let eyes = eyes {
            parts.append(eyes)
        }

        if let facial = facialFeatures {
            parts.append(facial)
        }

        if let tone = skinTone {
            parts.append("\(tone) skin")
        }

        // Return consolidated appearance or nil if no data
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    /// Generate multiple concepts for Apple Intelligence Image Playground
    /// Apple Intelligence works best with multiple short concepts (~95 chars each)
    func generateConceptsForAppleIntelligence(maxLength: Int = 95) -> [String] {
        var concepts: [String] = []

        switch cardKind {
        case .characters:
            // Appearance (physical description) - REQUIRED by Image Playground
            if let appearance = generateAppearanceDescription() {
                if appearance.count <= maxLength {
                    concepts.append(appearance)
                } else {
                    // Split appearance into smaller parts if too long
                    if let build = physicalBuild, build.count <= maxLength {
                        concepts.append(build)
                    }
                    if let hair = hair, hair.count <= maxLength {
                        concepts.append(hair)
                    }

                    // Facial features (combine eyes and facial if they fit)
                    var facialConcept = ""
                    if let eyes = eyes {
                        facialConcept = eyes
                    }
                    if let facial = facialFeatures {
                        let combined = facialConcept.isEmpty ? facial : "\(facialConcept), \(facial)"
                        if combined.count <= maxLength {
                            facialConcept = combined
                        }
                    }
                    if !facialConcept.isEmpty {
                        concepts.append(facialConcept)
                    }
                }
            }

            // Clothing
            if let clothing = clothing, clothing.count <= maxLength {
                concepts.append(clothing)
            }

            // Expression
            if let expression = expression, expression.count <= maxLength {
                concepts.append(expression)
            }

        case .locations, .scenes:
            // Primary features
            if let features = primaryFeatures {
                for feature in features {
                    if feature.count <= maxLength {
                        concepts.append(feature)
                    }
                }
            }

            // Lighting and atmosphere (important for scenes)
            if isSceneWithMood {
                if let lighting = lighting, lighting.count <= maxLength {
                    concepts.append(lighting)
                }
                if let mood = mood, mood.count <= maxLength {
                    concepts.append("\(mood) atmosphere")
                }
            }

        case .artifacts:
            // Object type and materials
            if let objType = objectType, let materials = materials, !materials.isEmpty {
                let concept = "\(objType) made of \(materials.joined(separator: ", "))"
                if concept.count <= maxLength {
                    concepts.append(concept)
                } else if objType.count <= maxLength {
                    concepts.append(objType)
                }
            }

            // Condition
            if let condition = condition, condition.count <= maxLength {
                concepts.append(condition)
            }

        case .buildings:
            // Architectural style
            if let style = architecturalStyle, style.count <= maxLength {
                concepts.append(style)
            }

            // Framing based on narrative importance
            if let importance = narrativeImportance, let angle = cameraAngle {
                let framingConcept = "\(importance) building, \(angle.displayName)"
                if framingConcept.count <= maxLength {
                    concepts.append(framingConcept)
                }
            }

        default:
            // Generic fallback
            if let setting = backgroundSetting, setting.count <= maxLength {
                concepts.append(setting)
            }
        }

        // Ensure we have at least one concept
        if concepts.isEmpty {
            // Fallback: use first 95 chars of source text
            concepts.append(String(sourceText.prefix(maxLength)))
        }

        return concepts
    }

    /// Generate optimized prompt for OpenAI DALL-E 3
    /// OpenAI works best with a single, structured descriptive prompt
    func generatePromptForOpenAI() -> String {
        var parts: [String] = []

        // Add camera angle/framing if specified
        if let angle = cameraAngle, let framing = framing {
            parts.append("\(framing.displayName) \(angle.displayName)")
        }

        switch cardKind {
        case .characters:
            parts.append("Portrait of")

            // Physical description
            if let build = physicalBuild {
                parts.append(build)
            }

            if let hair = hair {
                parts.append("with \(hair)")
            }

            if let eyes = eyes {
                parts.append(eyes)
            }

            if let facial = facialFeatures {
                parts.append(facial)
            }

            if let tone = skinTone {
                parts.append("\(tone) skin")
            }

            // Clothing
            if let clothing = clothing {
                parts.append("Wearing \(clothing)")
            }

            // Accessories
            if let accessories = accessories, !accessories.isEmpty {
                parts.append("with \(accessories.joined(separator: ", "))")
            }

            // Expression
            if let expression = expression {
                parts.append(expression)
            }

            // Pose
            if let pose = pose {
                parts.append(pose)
            }

        case .locations, .scenes:
            if isSceneWithMood {
                // Scene with mood
                if let features = primaryFeatures, !features.isEmpty {
                    parts.append(features.joined(separator: ", "))
                }

                // Mood and lighting critical for scenes
                if let lightingStyle = lightingStyle {
                    parts.append(lightingStyle.description)
                }

                if let mood = mood {
                    parts.append("\(mood) atmosphere")
                }
            } else {
                // Neutral location
                if let features = primaryFeatures, !features.isEmpty {
                    parts.append("View of \(features.joined(separator: ", "))")
                }

                if let arch = architecture {
                    parts.append("with \(arch)")
                }
            }

            if let scale = scale {
                parts.append("\(scale) scale")
            }

        case .artifacts:
            // Partial vs complete view
            if let partial = showPartial {
                parts.append("Close-up of \(partial)")
            } else if let objType = objectType {
                parts.append(objType)
            }

            if let materials = materials, !materials.isEmpty {
                parts.append("made of \(materials.joined(separator: ", "))")
            }

            if let condition = condition {
                parts.append(condition)
            }

            // Dramatic lighting for important artifacts
            if lightingStyle == .dramatic {
                parts.append("dramatic lighting emphasizing details")
            }

        case .buildings:
            if let style = architecturalStyle {
                parts.append("\(style) building")
            }

            // Framing based on narrative importance
            if let importance = narrativeImportance {
                if importance.contains("grand") || importance.contains("impressive") {
                    // Already set cameraAngle = lowAngleLookingUp
                    parts.append("imposing and majestic")
                } else if importance.contains("humble") || importance.contains("small") {
                    // Already set cameraAngle = highAngleLookingDown
                    parts.append("modest and simple")
                }
            }

        case .vehicles:
            if let vType = vehicleType {
                parts.append(vType)
            }

            if let design = vehicleDesign {
                parts.append(design)
            }

            if let motion = motionState {
                parts.append(motion)
            }

        default:
            // Generic description
            if let setting = backgroundSetting {
                parts.append(setting)
            }
        }

        // Add setting/background context
        if let setting = backgroundSetting, !parts.joined(separator: " ").contains(setting) {
            parts.append("in \(setting)")
        }

        // Add colors if specified
        if let colors = colors, !colors.isEmpty {
            parts.append("Colors: \(colors.joined(separator: ", "))")
        }

        let prompt = parts.joined(separator: ". ")
        return prompt.isEmpty ? sourceText : prompt + "."
    }

    /// Generate prompt for Anthropic (future)
    func generatePromptForAnthropic() -> String {
        // Future: Anthropic-specific formatting
        // For now, use OpenAI format as baseline
        return generatePromptForOpenAI()
    }
}

// MARK: - Supporting Enums

/// Camera angle for cinematic framing
enum CameraAngle: String, Codable {
    case lowAngleLookingUp      // Grand, impressive subjects (palaces, towers)
    case highAngleLookingDown   // Humble, small subjects (huts, small buildings)
    case eyeLevel               // Neutral perspective (most content)
    case aerialView             // Bird's eye view (maps, layouts)
    case dramaticAngle          // Dynamic, cinematic (action scenes)

    var displayName: String {
        switch self {
        case .lowAngleLookingUp: return "low angle shot looking up"
        case .highAngleLookingDown: return "high angle shot looking down"
        case .eyeLevel: return "eye-level perspective"
        case .aerialView: return "aerial view"
        case .dramaticAngle: return "dramatic angle"
        }
    }
}

/// Shot framing
enum Framing: String, Codable {
    case closeUp                // Detail focus (artifact hilt, facial features)
    case mediumShot             // Character upper body, partial object
    case fullShot               // Full character, complete object
    case wideEstablishing       // Full scene, location context

    var displayName: String {
        switch self {
        case .closeUp: return "close-up"
        case .mediumShot: return "medium shot"
        case .fullShot: return "full shot"
        case .wideEstablishing: return "wide establishing shot"
        }
    }
}

/// Lighting style
enum LightingStyle: String, Codable {
    case dramatic               // High contrast, shadows (important artifacts, tense scenes)
    case soft                   // Warm, gentle, romantic
    case neutral                // Even, documentary (neutral locations)
    case dark                   // Moody, mysterious, foreboding (tense confrontations)
    case bright                 // Cheerful, optimistic, clear (joyful celebrations)

    var description: String {
        switch self {
        case .dramatic: return "dramatic lighting with strong shadows"
        case .soft: return "soft warm lighting"
        case .neutral: return "neutral even lighting"
        case .dark: return "dark moody lighting"
        case .bright: return "bright cheerful lighting"
        }
    }
}

// MARK: - Convenience Extensions

extension VisualElements {
    /// Check if extraction has sufficient data for generation
    var hasSufficientData: Bool {
        switch cardKind {
        case .characters:
            // Need at least one of: build, hair, eyes, or clothing
            return physicalBuild != nil || hair != nil || eyes != nil || clothing != nil

        case .locations, .scenes:
            // Need primary features
            return primaryFeatures != nil && !(primaryFeatures?.isEmpty ?? true)

        case .artifacts:
            // Need object type
            return objectType != nil

        case .buildings:
            // Need architectural style or primary description
            return architecturalStyle != nil || backgroundSetting != nil

        case .vehicles:
            // Need vehicle type
            return vehicleType != nil

        default:
            // For other types, check if we have any setting
            return backgroundSetting != nil
        }
    }

    /// Get a summary of extracted elements for display
    var summaryDescription: String {
        var elements: [String] = []

        if let build = physicalBuild { elements.append("Build: \(build)") }
        if let hair = hair { elements.append("Hair: \(hair)") }
        if let eyes = eyes { elements.append("Eyes: \(eyes)") }
        if let clothing = clothing { elements.append("Clothing: \(clothing)") }
        if let features = primaryFeatures, !features.isEmpty {
            elements.append("Features: \(features.joined(separator: ", "))")
        }
        if let objType = objectType { elements.append("Type: \(objType)") }

        return elements.joined(separator: "\n")
    }
}
