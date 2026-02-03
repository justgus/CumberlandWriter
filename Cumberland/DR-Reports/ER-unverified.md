# Enhancement Requests (ER) - Unverified

This document tracks enhancement requests that are proposed, in progress, or implemented but awaiting user verification.

**Status:** Currently **1 active ER** (1 Proposed, 0 In Progress, 0 Implemented - Not Verified)

**Note:** ER-0008, ER-0009, ER-0010 verified and moved to `ER-verified-0008.md`
**Note:** ER-0012, ER-0013, ER-0014, ER-0016 verified and moved to `ER-verified-0012.md`
**Note:** ER-0017 verified and moved to `ER-verified-0020.md` (2026-02-03)
**Note:** ER-0018 verified and moved to `ER-verified-0018.md`
**Note:** ER-0019 verified and moved to `ER-verified-0019.md` (2026-01-31)
**Note:** ER-0020 verified and moved to `ER-verified-0020.md` (2026-02-01)
**Note:** ER-0015, ER-0011 Phase 1 verified and moved to `ER-verified-0015.md` (2026-02-01)

---

## ER-0021: AI-Powered Visual Element Extraction for Image Generation

**Status:** 🔵 Proposed
**Component:** AI Image Generation, All Providers, Visual Analysis System
**Priority:** Critical
**Date Requested:** 2026-02-03
**Date Updated:** 2026-02-03 (expanded scope)
**Related:** DR-0071 (Apple Image Playground portrait-only limitation), ER-0010 (AI Content Analysis)

**Rationale:**

**This is a core Cumberland feature - automatic, intelligent image generation from card descriptions.**

Currently, image generation uses the raw card description as the prompt. This has multiple problems:

1. **Narrative descriptions aren't visual prompts:** Character descriptions like "Captain Evilin Drake is a tall woman with long straight dark hair that she wears in a ponytail most days" contain narrative elements that don't translate well to image generation.

2. **Important visual details get lost:** Mixed with personality traits, backstory, and context that image generators can't use.

3. **Provider-specific optimization needed:**
   - Apple Intelligence needs multiple short concepts (~100 chars each)
   - OpenAI works better with structured prompts
   - Anthropic (future) may have different requirements

4. **User shouldn't need to write two descriptions:** Writers want to focus on worldbuilding, not crafting image generation prompts.

**User Vision:**
> "Our input for characters will be based on the single description on the card. I think we should expand ER-0021 for apple intelligence (and possibly the other providers as well) to include AI analysis of the text to extract the specific descriptive elements for character portraits. This will be one of the primary features of Cumberland and I would like it to work flawlessly."

**Core Principle:** Cumberland should intelligently extract visual elements from narrative descriptions and generate optimized prompts for any provider.

**Current Behavior:**

**What happens now:**
1. User writes narrative character description in card's detailed text
2. User clicks "Generate Image"
3. Cumberland passes raw description text directly to provider
4. Image generator receives narrative prose (not optimized visual prompt)
5. Results are suboptimal:
   - Apple Intelligence: truncates at ~100 chars, loses details
   - OpenAI: processes narrative prose, results may miss key visual details
   - All providers: personality traits like "quick to laugh" don't translate visually

**Example Card Description:**
```
Captain Evilin Drake is a tall woman with long straight dark hair that she
wears in a ponytail most days. Lithe and thin, she can be seen most days
wearing her orange astronaut's jumpsuit. She is quick to laugh, with a
strong chin, short nose, bright green eyes. She grew up on Mars Colony
Seven and spent ten years commanding deep space missions before retiring
to teach at the Interplanetary Academy.
```

**Problems:**
- **Narrative prose:** "grew up on Mars Colony Seven" is backstory, not visual
- **Temporal qualifiers:** "most days" is unnecessary for image generation
- **Non-visual traits:** "quick to laugh" doesn't directly translate to appearance
- **Length:** 450+ characters with mixed visual and non-visual content
- **Unstructured:** Visual details scattered throughout text
- **No provider optimization:** Same raw text sent to all providers

**Desired Behavior:**

**AI-Powered Visual Element Extraction:**

1. **Automatic Analysis:**
   - When user clicks "Generate Image", Cumberland automatically analyzes the card description
   - Uses AI (Apple Intelligence or OpenAI) to extract visual elements only
   - Identifies: physical build, hair, facial features, clothing, expression, props, setting
   - Filters out: backstory, personality traits (unless expressible visually), temporal qualifiers

2. **Provider-Specific Optimization:**

**For Apple Intelligence:**
```swift
// Extracted visual elements split into multiple concepts
.imagePlaygroundSheet(
    isPresented: $showImagePlaygroundSheet,
    concepts: [
        ImagePlaygroundConcept.text("tall woman, lithe and thin build"),
        ImagePlaygroundConcept.text("long straight dark hair in ponytail"),
        ImagePlaygroundConcept.text("bright green eyes, strong chin, short nose"),
        ImagePlaygroundConcept.text("orange astronaut jumpsuit"),
        ImagePlaygroundConcept.text("confident friendly expression")
    ]
)
```

**For OpenAI (DALL-E 3):**
```swift
// Extracted visual elements combined into optimized prompt
let optimizedPrompt = """
Portrait of a tall, lithe woman with long straight dark hair worn in a ponytail.
Bright green eyes, strong chin, short nose. Wearing an orange astronaut jumpsuit.
Confident, friendly expression.
"""
```

**For Anthropic (future):**
```swift
// Provider-specific format optimization
// Adapt to Anthropic's prompt engineering best practices
```

3. **Transparent Process:**
   - User sees extracted visual elements before generation (review step)
   - Can edit or approve
   - System learns from user corrections (optional)

4. **Visual Translation:**
   - "quick to laugh" → "friendly expression, warm smile"
   - "commanding presence" → "confident posture, direct gaze"
   - Non-visual elements → filtered out or translated

**Benefits:**
- ✅ **Single source of truth:** User writes one description, system handles optimization
- ✅ **Provider-agnostic:** Works optimally with any image generation provider
- ✅ **Intelligent filtering:** Removes backstory, keeps visual elements
- ✅ **Visual translation:** Converts personality traits to visual cues
- ✅ **Preserves all visual details:** Nothing lost in character limit constraints
- ✅ **Professional results:** Optimized prompts = better image quality
- ✅ **Writer-friendly:** No need to learn prompt engineering

**Requirements:**

**Phase 1: AI-Powered Visual Analysis**

1. **New Analysis Task: Visual Element Extraction**
   - Add to `AnalysisTask` enum (alongside entityExtraction, relationshipInference, etc.)
   - Create `VisualElementExtractor` class (similar to `EntityExtractor`)
   - Integrate with existing AI provider infrastructure

2. **Visual Element Categories:**

   **For Characters/Portraits:**
   - Physical build (height, body type, distinctive features)
   - Hair (color, length, style)
   - Eyes (color, shape, expression)
   - Face (structure, distinctive features)
   - Skin tone (if specified)
   - Clothing/costume (style, color, material)
   - Accessories/props (jewelry, weapons, tools)
   - Expression/demeanor (translated from personality)
   - Pose/composition (standing, sitting, action pose)
   - Background/setting (if relevant to character)
   - **Framing:** Portrait (head/shoulders), medium shot, full body

   **For Locations (Neutral View):**
   - Primary features (mountains, water, buildings)
   - Architectural style (if buildings present)
   - Scale indicators (vast, intimate, expansive)
   - Vegetation/terrain
   - Physical characteristics only (no mood/lighting)
   - **Default framing:** Establishing shot, neutral perspective
   - **Examples:** "Alys' Apartment", "La Porte Cafe" (as places, no emotion)

   **For Scenes (Location + Mood):**
   - All location elements PLUS:
   - Lighting (time of day, quality of light)
   - Weather/atmospheric conditions
   - Mood/atmosphere (bright and humorous, dark and foreboding)
   - Emotional tone (derived from scene events)
   - Colors/palette (influenced by mood)
   - **Framing:** Based on narrative importance and emotional intent
   - **Examples:** "The tense confrontation at La Porte Cafe" (location + dark mood)

   **For Artifacts/Objects:**
   - Object type (sword, amulet, book, etc.)
   - **Partial vs Complete:** Only show described parts (sword hilt if blade not mentioned)
   - Size and scale
   - Materials (metal, wood, crystal)
   - Colors and textures
   - Condition (ancient, pristine, worn)
   - Distinctive features (runes, gems, patterns)
   - **Framing:** Close-up if detail-focused, medium if showing full object
   - **Lighting:** Dramatic lighting to emphasize importance
   - Background/context (neutral or relevant setting)

   **For Buildings:**
   - Architectural style and features
   - Size and scale (from description)
   - Materials and construction
   - Condition (maintained, ruined, ancient)
   - Distinctive features (towers, gates, decorations)
   - **Narrative importance determines perspective:**
     - **Grand/Impressive:** Low angle, looking up (Magic Academy of Felthome)
     - **Humble/Small:** High angle, looking down (thatched shack on outskirts)
     - **Neutral:** Eye-level perspective (typical building)
   - Setting/surroundings

   **For Vehicles:**
   - Vehicle type (ship, airship, carriage, dragon)
   - Size and scale
   - Design and construction
   - Materials and textures
   - Condition and age
   - Distinctive features (sails, armor, decorations)
   - **Framing:** Based on narrative role (heroic ship = dynamic angle, transport = neutral)
   - Motion implied if appropriate

3. **Cinematic Framing and Narrative Perspective (NEW):**

   **CRITICAL INSIGHT:** The visualization should reflect the narrative importance and emotional intent, not just physical description.

   **Camera Angles/Perspectives in Image Generation:**
   Modern image generators (DALL-E 3, Midjourney, Stable Diffusion) understand cinematic language:
   - ✅ "low angle shot looking up" - Makes subject appear grand/imposing
   - ✅ "high angle shot looking down" - Makes subject appear small/vulnerable
   - ✅ "eye-level perspective" - Neutral, documentary view
   - ✅ "aerial view" - God's eye view, shows layout
   - ✅ "close-up of" - Focus on specific detail
   - ✅ "wide establishing shot" - Shows full context
   - ✅ "dramatic angle" - Dynamic, cinematic composition
   - ✅ "from below" / "from above" - Directional perspective

   **Framing Inference Rules:**

   **For Buildings:**
   - **Narrative indicators for perspective:**
     - "grand", "impressive", "towering", "majestic", "imposing" → **Low angle, looking up**
       - Example: "The Magic Academy of Felthome, with its grand gates and soaring towers"
       - Prompt includes: "low angle shot looking up at grand gates"
     - "humble", "small", "modest", "simple", "tiny" → **High angle, looking down**
       - Example: "A thatched shack on the outskirts of the village"
       - Prompt includes: "aerial view looking down at small thatched shack"
     - No size indicators → **Eye-level perspective**

   **For Artifacts:**
   - **Only show what's described:**
     - If description mentions hilt but not blade → "close-up of ornate sword hilt"
     - If full sword described → "full length view of ancient sword"
     - Don't hallucinate missing details
   - **Importance determines framing:**
     - Legendary artifact → "dramatic lighting, close-up emphasizing details"
     - Common object → "neutral lighting, clear view"

   **For Scenes vs Locations:**
   - **Location Card (neutral):** "La Porte Cafe, interior view, warm lighting, cozy atmosphere"
   - **Scene Card (with mood):** Analyze scene events:
     - Tense confrontation → "dark shadows, dramatic lighting, tense atmosphere"
     - Romantic moment → "soft lighting, warm colors, intimate framing"
     - Action sequence → "dynamic angle, motion implied, intense lighting"

   **Mood/Lighting Inference from Scene Context:**
   - If card kind is `.scenes`, analyze the scene description for emotional indicators
   - "confrontation", "battle", "argument" → dark, dramatic lighting
   - "celebration", "party", "joy" → bright, warm lighting
   - "mystery", "investigation", "discovery" → atmospheric, shadowy lighting
   - "romance", "tender", "intimate" → soft, warm lighting

4. **AI-Powered Extraction Logic:**
   - Use NaturalLanguage framework for parsing (Apple Intelligence)
   - Use OpenAI structured output for complex extraction (OpenAI provider)
   - Extract visual elements with confidence scores
   - **NEW:** Analyze narrative context for framing/perspective inference
   - **NEW:** Distinguish between neutral location vs scene-with-mood
   - **NEW:** Identify narrative importance indicators (grand, humble, legendary, etc.)
   - Filter out non-visual content (backstory, relationships, internal states)
   - Translate abstract traits to visual cues:
     - "quick to laugh" → "warm smile, friendly expression"
     - "commanding" → "confident posture, direct gaze"
     - "mysterious" → "shadowed features, enigmatic expression"
   - **NEW:** Translate narrative importance to camera angles:
     - "grand entrance" → "low angle shot"
     - "humble dwelling" → "aerial view"
     - "legendary sword" → "dramatic lighting, close-up"

4. **Provider-Specific Prompt Generation:**
   - **Apple Intelligence:** Split into multiple ~95 char concepts
   - **OpenAI:** Single structured prompt with optimal formatting
   - **Anthropic (future):** Provider-specific format
   - Use provider metadata to determine best format

5. **User Review & Correction:**
   - Show extracted visual elements before generation
   - Allow editing/adding/removing elements
   - "Generate with these visual elements" vs "Edit visual elements"
   - Optional: Learn from user corrections (ML improvement)

6. **Fallback Handling:**
   - If visual extraction fails, fall back to smart text cleanup
   - Remove obvious non-visual content (dates, relationships, backstory)
   - Warn user if extraction confidence is low

**Design Approach:**

### Architecture Overview

```
Card Description (Narrative)
    ↓
Visual Element Extractor (AI-powered)
    ↓
Visual Element Model (Structured data)
    ↓
Provider-Specific Formatter
    ↓
Optimized Prompt (Provider-specific format)
    ↓
Image Generation
```

### Component Design

**1. Visual Element Model**

```swift
/// Represents extracted visual elements from a description
struct VisualElements {
    // Metadata
    var sourceText: String
    var cardType: Kinds
    var extractionConfidence: Double
    var extractedAt: Date

    // Character-specific
    var physicalBuild: String?           // "tall, lithe, athletic"
    var hair: String?                    // "long straight dark hair in ponytail"
    var eyes: String?                    // "bright green eyes"
    var facialFeatures: String?          // "strong chin, short nose"
    var skinTone: String?                // "pale", "olive", "dark brown"
    var clothing: String?                // "orange astronaut jumpsuit"
    var accessories: [String]?           // ["silver necklace", "leather gloves"]
    var expression: String?              // "friendly smile, warm expression"
    var pose: String?                    // "standing confidently", "seated"

    // Location-specific
    var primaryFeatures: [String]?       // ["twin moons", "rolling sand dunes"]
    var scale: String?                   // "vast", "intimate"
    var lighting: String?                // "sunset", "ethereal glow"
    var atmosphere: String?              // "mysterious", "welcoming"
    var isSceneWithMood: Bool            // true if scene card with emotional context

    // Artifact-specific
    var objectType: String?              // "sword", "amulet"
    var materials: [String]?             // ["ancient metal", "glowing crystal"]
    var condition: String?               // "pristine", "battle-worn"
    var showPartial: String?             // "hilt only" if blade not described

    // Building-specific
    var architecturalStyle: String?      // "gothic", "modern", "fantasy"
    var narrativeImportance: String?     // "grand", "humble", "neutral"

    // Common to all types
    var colors: [String]?                // ["orange", "silver", "green"]
    var mood: String?                    // "heroic", "mysterious", "tense"
    var backgroundSetting: String?       // "throne room", "desert landscape"

    // **NEW: Cinematic Framing**
    var cameraAngle: CameraAngle?        // Inferred from narrative context
    var framing: Framing?                // Close-up, medium, wide, etc.
    var lighting: LightingStyle?         // Dramatic, soft, neutral, dark

    /// Generate provider-specific prompt with cinematic framing
    func generatePrompt(for provider: AIProviderProtocol) -> String {
        // Provider-specific logic with framing included
    }

    /// Generate multiple concepts for Apple Intelligence
    func generateConcepts(maxLength: Int = 95) -> [String] {
        // Split into appropriate concepts
    }
}

/// Camera angle for cinematic framing
enum CameraAngle {
    case lowAngleLookingUp      // Grand, impressive subjects
    case highAngleLookingDown   // Humble, small subjects
    case eyeLevel               // Neutral perspective
    case aerialView             // Bird's eye view
    case dramaticAngle          // Dynamic, cinematic
}

/// Shot framing
enum Framing {
    case closeUp                // Detail focus (artifact hilt, facial features)
    case mediumShot             // Character upper body, partial object
    case fullShot               // Full character, complete object
    case wideEstablishing       // Full scene, location context
}

/// Lighting style
enum LightingStyle {
    case dramatic               // High contrast, shadows
    case soft                   // Warm, gentle, romantic
    case neutral                // Even, documentary
    case dark                   // Moody, mysterious, foreboding
    case bright                 // Cheerful, optimistic, clear
}
```

**2. Visual Element Extractor**

Create `VisualElementExtractor.swift` (similar to `EntityExtractor.swift`):

```swift
class VisualElementExtractor {

    /// Extract visual elements from card description using AI
    func extractVisualElements(
        from text: String,
        cardType: Kinds,
        provider: AIProviderProtocol
    ) async throws -> VisualElements {

        // Build extraction prompt based on card type
        let extractionPrompt = buildExtractionPrompt(for: cardType, text: text)

        // Use AI to extract structured visual data
        let result = try await provider.analyzeText(
            extractionPrompt,
            for: .visualElementExtraction  // New analysis task
        )

        // Parse response into VisualElements model
        let elements = parseVisualElements(from: result, cardType: cardType)

        return elements
    }

    /// Build card-type-specific extraction prompt
    private func buildExtractionPrompt(for cardType: Kinds, text: String) -> String {
        switch cardType {
        case .characters:
            return """
            Analyze this character description and extract ONLY the visual elements that would appear in a portrait.
            Ignore backstory, relationships, personality traits unless they translate to visible expression.

            Extract:
            - Physical build (height, body type)
            - Hair (color, length, style)
            - Eyes (color, distinctive features)
            - Facial features
            - Clothing and costume
            - Accessories or props
            - Expression/demeanor (visual only)
            - Pose or composition

            Description: \(text)

            Return structured data with confidence scores.
            """

        case .locations:
            return """
            Analyze this location description and extract visual elements for a landscape/scene image.
            Focus on what would be visible in the image.

            Extract:
            - Primary landscape features
            - Scale and scope
            - Time of day / lighting
            - Weather conditions
            - Color palette
            - Mood and atmosphere
            - Architectural elements if any

            Description: \(text)
            """

        case .artifacts, .vehicles, .buildings:
            return """
            Analyze this object description and extract visual elements.

            Extract:
            - Object type and form
            - Size and scale
            - Materials and textures
            - Colors and finish
            - Condition (age, wear)
            - Distinctive features (decorations, markings)
            - Lighting/presentation

            Description: \(text)
            """

        default:
            return """
            Extract visual elements from this description for image generation.
            Focus only on what would be visible in an image.

            Description: \(text)
            """
        }
    }
}
```

**3. Provider-Specific Prompt Formatter**

```swift
extension VisualElements {

    /// Generate optimized prompt for OpenAI DALL-E 3
    func generatePromptForOpenAI() -> String {
        guard cardType == .characters else {
            return generateGenericPrompt()
        }

        var parts: [String] = []

        // Start with portrait format
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

        // Clothing
        if let clothing = clothing {
            parts.append("wearing \(clothing)")
        }

        // Expression
        if let expression = expression {
            parts.append(expression)
        }

        // Setting
        if let setting = backgroundSetting {
            parts.append("in \(setting)")
        }

        return parts.joined(separator: ". ") + "."
    }

    /// Generate multiple concepts for Apple Intelligence Image Playground
    func generateConceptsForAppleIntelligence(maxLength: Int = 95) -> [String] {
        var concepts: [String] = []

        // Physical build
        if let build = physicalBuild, build.count <= maxLength {
            concepts.append(build)
        }

        // Hair
        if let hair = hair, hair.count <= maxLength {
            concepts.append(hair)
        }

        // Facial features (combine if short enough)
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

        // Clothing
        if let clothing = clothing, clothing.count <= maxLength {
            concepts.append(clothing)
        }

        // Expression
        if let expression = expression, expression.count <= maxLength {
            concepts.append(expression)
        }

        // Ensure we have at least one concept
        if concepts.isEmpty {
            concepts.append(String(sourceText.prefix(maxLength)))
        }

        return concepts
    }
}
```

### Approach: AI-Powered Extraction (Recommended)

**Leverage Cumberland's existing AI infrastructure:**

**For Apple Intelligence Provider:**
- Use NaturalLanguage framework + custom prompt to extract visual elements
- Already integrated, on-device, no API key required
- Fast and private

**For OpenAI Provider:**
- Use structured output (JSON mode) for precise extraction
- More sophisticated understanding of complex descriptions
- Handles edge cases better (unusual descriptions, mixed content)

**Hybrid Approach (Best):**
- Try Apple Intelligence first (fast, free, private)
- Fall back to OpenAI if confidence is low or Apple Intelligence unavailable
- Use whichever provider user has configured for content analysis

**Benefits:**
- ✅ Sophisticated understanding of narrative descriptions
- ✅ Can handle complex, mixed content (visual + non-visual)
- ✅ Learns patterns (visual vs. non-visual)
- ✅ Provider-agnostic (works with any AI backend)
- ✅ Future-proof (can add more sophisticated extraction as AI improves)

### Concrete Examples: How Framing Works in Practice

**Example 1: Grand Building**

**Card Description:**
```
The Magic Academy of Felthome rises majestically from the clifftop, its
grand gates flanked by towering statues of ancient mages. The entrance hall
features soaring marble columns that reach toward a vaulted ceiling painted
with constellations. Students approaching the academy for the first time are
always struck by its imposing presence.
```

**Extracted Visual Elements:**
- Primary Features: "grand gates", "towering statues", "marble columns"
- Architectural Style: "majestic classical architecture"
- Scale: "soaring", "towering"
- **Narrative Importance: "grand", "imposing"**
- **Camera Angle: lowAngleLookingUp** (inferred from "grand", "imposing", "soaring")
- **Framing: wideEstablishing**
- **Lighting: dramatic** (emphasizes grandeur)

**Generated Prompt (OpenAI):**
```
Wide establishing shot from low angle looking up at the grand gates of a
majestic magic academy. Towering marble statues of ancient mages flank the
entrance. Soaring columns visible beyond gates. Classical fantasy
architecture. Dramatic lighting emphasizing imposing presence.
```

**Result:** Image shows academy from student's perspective, looking up at the impressive gates, conveying narrative intent of grandeur.

---

**Example 2: Humble Building**

**Card Description:**
```
A small thatched shack sits on the outskirts of the village, barely visible
behind overgrown brambles. The roof sags in the middle, and one window has
been patched with old boards. Smoke rises weakly from a crooked chimney.
```

**Extracted Visual Elements:**
- Primary Features: "thatched shack", "sagging roof", "patched window"
- Condition: "old", "worn", "overgrown"
- Scale: "small", "barely visible"
- **Narrative Importance: "humble", "small"**
- **Camera Angle: highAngleLookingDown** (inferred from "small", "outskirts")
- **Framing: wideEstablishing** (shows context)
- **Lighting: neutral** (documentary view)

**Generated Prompt (OpenAI):**
```
Aerial view looking down at a small thatched shack on village outskirts.
Sagging roof with crooked chimney. Overgrown brambles around building.
Patched window. Shows humble, worn condition. Neutral lighting.
```

**Result:** Image shows shack from above, emphasizing its small, neglected state, conveying narrative intent of humbleness.

---

**Example 3: Artifact (Partial View)**

**Card Description:**
```
The Sword of Dawn's hilt is wrapped in ancient leather, still soft despite
centuries of age. An enormous ruby sits at the pommel, catching light with
inner fire. Runes spiral down the grip, their meaning lost to time.
```

**Extracted Visual Elements:**
- Object Type: "sword"
- **Show Partial: "hilt only"** (blade not mentioned in description)
- Materials: "ancient leather wrap", "ruby pommel"
- Distinctive Features: "spiral runes", "ruby with inner fire"
- Condition: "ancient but well-preserved"
- **Camera Angle: eyeLevel**
- **Framing: closeUp** (detail focus)
- **Lighting: dramatic** (emphasizes ruby's inner fire)

**Generated Prompt (OpenAI):**
```
Close-up of ancient sword hilt only. Leather-wrapped grip with spiral runes.
Large ruby pommel glowing with inner fire. Dramatic lighting catching the
ruby's glow. Ancient but well-preserved. Do not show blade.
```

**Result:** Image shows ONLY the hilt (as described), with dramatic lighting on the ruby. Doesn't hallucinate a blade that wasn't described.

---

**Example 4: Scene with Mood (vs Neutral Location)**

**Location Card: "La Porte Cafe"**
```
La Porte Cafe occupies a corner building with tall windows overlooking the
harbor. Inside, small round tables are arranged between support columns.
The bar runs along the back wall, bottles gleaming on glass shelves.
```

**Generated Prompt (Neutral Location View):**
```
Interior view of corner cafe with tall harbor-facing windows. Small round
tables between columns. Bar along back wall with gleaming bottles on glass
shelves. Warm, welcoming atmosphere. Eye-level perspective.
```

**Scene Card: "Tense Confrontation at La Porte Cafe"**
```
[Same location description as above, BUT card is kind=.scenes, and scene
description includes: "Marcus slammed his hand on the table. 'You're lying,'
he growled. The other patrons fell silent, watching nervously."]
```

**Extracted Visual Elements:**
- All location elements PLUS:
- **isSceneWithMood: true**
- **Mood: "tense", "confrontational"**
- **Lighting: dark** (inferred from "tense confrontation")
- **Atmosphere: "dramatic tension"**

**Generated Prompt (Scene with Mood):**
```
Interior of corner cafe, dark dramatic lighting creating shadows. Small
tables between columns. Bar in background. Tense, confrontational atmosphere.
Dark moody lighting emphasizing dramatic tension. One table in focus with
harsh lighting.
```

**Result:** SAME physical space, but scene version has dark, dramatic lighting to match the tense confrontation, whereas location version is warm and welcoming.

---

These examples demonstrate the **sophisticated visual storytelling** that ER-0021 will enable.

**Implementation Plan:**

**Phase 1: Core Infrastructure (1-2 weeks)**
1. Create `VisualElements` model with card-type-specific properties
2. Create `VisualElementExtractor` class
3. Add `.visualElementExtraction` to `AnalysisTask` enum
4. Implement extraction prompts for each card type
5. Integrate with existing AIProviderProtocol
6. Unit tests for extraction logic

**Phase 2: Provider-Specific Formatting (1 week)**
1. Implement `generateConceptsForAppleIntelligence()` in VisualElements
2. Implement `generatePromptForOpenAI()` in VisualElements
3. Add provider detection in AIImageGenerationView
4. Route to appropriate formatter based on provider
5. Test with all providers

**Phase 3: User Review & Editing (1 week)**
1. Create `VisualElementReviewView` UI
2. Show extracted elements before generation
3. Allow editing individual elements
4. "Generate with these elements" action
5. Save user corrections for learning (optional)

**Phase 4: Integration & Polish (1 week)**
1. Integrate into AIImageGenerationView workflow
2. Add fallback for extraction failures
3. Performance optimization
4. Handle edge cases (very long descriptions, minimal descriptions)
5. Cross-platform testing (macOS, iOS, iPadOS, visionOS)

**Phase 5: Testing & Refinement (1-2 weeks)**
1. Comprehensive testing with real character descriptions
2. Test all card types (characters, locations, artifacts, vehicles, buildings)
3. Validate generation quality improvements
4. User acceptance testing
5. Documentation updates

**Components Affected:**

**New Files:**
- `Cumberland/AI/VisualElements.swift` - Visual element model (~200 lines)
- `Cumberland/AI/VisualElementExtractor.swift` - Extraction logic (~400 lines)
- `Cumberland/AI/VisualElementReviewView.swift` - Review/edit UI (~300 lines)

**Modified Files:**
- `Cumberland/AI/AIProviderProtocol.swift` - Add .visualElementExtraction task
- `Cumberland/AI/AIImageGenerationView.swift` - Integration with extraction workflow
- `Cumberland/AI/AppleIntelligenceProvider.swift` - Handle new analysis task
- `Cumberland/AI/OpenAIProvider.swift` - Handle new analysis task with structured output
- `Cumberland/AI/AnalysisTask.swift` - Add visualElementExtraction case
- `Cumberland/AI/AISettings.swift` - Optional: Add visual extraction settings

**Test Steps:**

**Phase 1: Visual Element Extraction (Character)**
1. Create character card: "Captain Evilin Drake"
2. Add narrative description:
   ```
   Captain Evilin Drake is a tall woman with long straight dark hair that she
   wears in a ponytail most days. Lithe and thin, she can be seen most days
   wearing her orange astronaut's jumpsuit. She is quick to laugh, with a
   strong chin, short nose, bright green eyes. She grew up on Mars Colony
   Seven and spent ten years commanding deep space missions before retiring
   to teach at the Interplanetary Academy.
   ```
3. Click "Generate Image"
4. **Verify:** Visual Element Review sheet appears (not immediate generation)
5. **Verify:** Extracted elements shown with categories:
   - Physical Build: "tall, lithe and thin"
   - Hair: "long straight dark hair in ponytail"
   - Eyes: "bright green eyes"
   - Facial Features: "strong chin, short nose"
   - Clothing: "orange astronaut jumpsuit"
   - Expression: "confident friendly expression" (translated from "quick to laugh")
6. **Verify:** Backstory filtered out: "Mars Colony Seven", "Interplanetary Academy" NOT in elements
7. User can edit any element
8. Click "Generate with these elements"

**Phase 2: Apple Intelligence Provider**
9. With provider set to "Apple Intelligence"
10. **Verify:** Image Playground launches with multiple concepts:
    - "tall, lithe and thin"
    - "long straight dark hair in ponytail"
    - "bright green eyes, strong chin, short nose"
    - "orange astronaut jumpsuit"
    - "confident friendly expression"
11. **Verify:** Each concept ≤95 characters
12. Complete generation
13. **Verify:** Generated image includes all visual elements

**Phase 3: OpenAI Provider**
14. Change provider to "OpenAI"
15. Generate same card
16. **Verify:** Visual Element Review shows same extracted elements
17. Click "Generate with these elements"
18. **Verify:** Single optimized prompt sent to OpenAI:
    ```
    Portrait of a tall, lithe woman with long straight dark hair in a ponytail.
    Bright green eyes, strong chin, short nose. Wearing an orange astronaut
    jumpsuit. Confident, friendly expression.
    ```
19. **Verify:** Generation succeeds, image quality high

**Phase 4: Non-Character Cards (Location)**
20. Create location card: "The Whispering Desert"
21. Add description:
    ```
    The Whispering Desert stretches for hundreds of miles under twin moons.
    Rolling sand dunes shimmer with an ethereal blue glow at night. Ancient
    ruins dot the landscape, half-buried temples from the Silver Era
    civilization. The desert earned its name from the haunting sounds the
    wind makes through the stone archways. Travelers report feeling watched
    by unseen eyes.
    ```
22. Click "Generate Image"
23. **Verify:** Extracted elements:
    - Primary Features: "rolling sand dunes", "ancient ruins", "half-buried temples"
    - Lighting: "ethereal blue glow", "twin moons"
    - Atmosphere: "mysterious, haunting"
    - Colors: "blue", "sand"
24. **Verify:** Subjective content filtered: "travelers report feeling watched" (not visual)
25. Generate and verify quality

**Phase 5: Non-Character Cards (Artifact)**
26. Create artifact card: "The Codex of Forgotten Winds"
27. Add description: "An ancient leather-bound tome with silver runes etched into the cover..."
28. **Verify:** Extraction works for artifacts
29. **Verify:** Object-specific elements extracted (materials, condition, distinctive features)

**Phase 6: Edge Cases**
30. Create card with minimal description: "A tall elf."
31. **Verify:** Extraction handles short descriptions gracefully
32. **Verify:** Low confidence warning shown
33. Create card with very long description (1000+ words)
34. **Verify:** Extraction prioritizes most important visual details
35. **Verify:** Generation succeeds with key elements preserved

**Phase 7: User Editing**
36. Extract elements from any character
37. In review UI, click "Edit" on "Hair" element
38. Change from "long dark hair" to "short silver hair"
39. Click "Generate with these elements"
40. **Verify:** Modified element used in generation
41. **Verify:** Generated image reflects user's edit

**Priority:** Critical - Core Cumberland feature for flawless image generation

**Complexity:** High - Requires new AI analysis task, models, UI, provider integration

**Dependencies:**
- ER-0009 (builds on existing image generation system)
- ER-0010 (leverages existing AI content analysis infrastructure)
- DR-0071 (partially addresses Image Playground limitations)

**Benefits:**
- ✅ **Writer-friendly:** Single narrative description, automatic visual extraction
- ✅ **Provider-agnostic:** Works optimally with any image provider
- ✅ **Intelligent filtering:** Removes backstory, keeps only visual elements
- ✅ **Visual translation:** Converts personality to visual expression
- ✅ **Quality improvement:** Optimized prompts = better images
- ✅ **Professional workflow:** Review extracted elements before generation
- ✅ **Learning system:** Can improve from user corrections
- ✅ **Handles all card types:** Characters, locations, artifacts, vehicles, buildings

**Notes:**
- User vision: "This will be one of the primary features of Cumberland and I would like it to work flawlessly."
- **EXPANDED SCOPE (2026-02-03):** Added cinematic framing and narrative perspective analysis
- User desirement: "What I'm describing here may not be possible, but it is a 'desirement'"
  - **Good news: It IS possible!** Modern image generators understand camera angles and cinematic language
  - Low angle/high angle, close-up/wide, dramatic lighting all work in DALL-E 3, Midjourney, etc.
- Scope expanded from simple prompt splitting → full AI-powered visual analysis → cinematic storytelling
- Key distinctions:
  - **Location vs Scene:** Neutral view vs mood-infused view
  - **Narrative importance:** Grand buildings = low angle, humble shacks = high angle
  - **Partial views:** Only show what's described (sword hilt without blade if blade not mentioned)
  - **Mood inference:** Scene events influence lighting and atmosphere
- Discovered through user observation during DR-0069/DR-0071 investigation
- Apple's Image Playground supports multiple concepts but needs intelligent extraction
- This is the "killer feature" that differentiates Cumberland from generic worldbuilding tools
- Allows writers to focus on narrative, system handles sophisticated visual generation automatically
- Requires deep understanding of both visual elements AND narrative intent

---


