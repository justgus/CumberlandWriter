import Foundation

/// Anthropic (Claude) provider for AI content analysis
/// Requires API key from https://console.anthropic.com
/// Note: Anthropic does not currently support image generation
class AnthropicProvider: AIProviderProtocol {

    // MARK: - AIProviderProtocol Conformance

    var name: String {
        "Anthropic Claude Opus 4.5"
    }

    var isAvailable: Bool {
        // Available on all platforms as long as we have network
        return true
    }

    var requiresAPIKey: Bool {
        true
    }

    var usesSheetBasedUI: Bool {
        false
    }

    var metadata: AIProviderMetadata? {
        AIProviderMetadata(
            modelVersion: "Claude Opus 4.5",
            maxPromptLength: 200000, // Claude supports up to 200k tokens
            supportedImageFormats: nil, // Anthropic doesn't generate images
            rateLimit: RateLimit(
                requestsPerMinute: 40, // Opus has slightly lower limits
                requestsPerDay: nil
            ),
            licenseInfo: LicenseInfo(
                licenseType: "Proprietary - Anthropic",
                attributionRequired: false,
                commercialUseAllowed: true, // Subject to Anthropic terms
                licenseURL: URL(string: "https://www.anthropic.com/legal/commercial-terms")
            )
        )
    }

    // MARK: - Constants

    private let apiEndpoint = "https://api.anthropic.com/v1/messages"
    private let model = "claude-opus-4-5-20251101" // Claude Opus 4.5 (November 2024) - Most capable model
    private let apiVersion = "2023-06-01" // Anthropic API version

    // MARK: - URLSession Configuration

    /// Custom URLSession with longer timeout for AI operations
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120 // 2 minutes for text analysis
        config.timeoutIntervalForResource = 180 // 3 minutes total
        return URLSession(configuration: config)
    }()

    // MARK: - Image Generation (Not Supported)

    func generateImage(prompt: String) async throws -> Data {
        throw AIProviderError.featureNotSupported(
            feature: "Image generation is not supported by Anthropic. Please use Apple Intelligence or OpenAI for image generation."
        )
    }

    // MARK: - Content Analysis

    func analyzeText(_ text: String, for task: AnalysisTask) async throws -> AnalysisResult {
        guard !text.isEmpty else {
            throw AIProviderError.invalidInput(reason: "Text cannot be empty")
        }

        // Get API key from keychain
        guard let apiKey = try? KeychainHelper.shared.retrieveAPIKey(for: "anthropic"), !apiKey.isEmpty else {
            throw AIProviderError.invalidAPIKey
        }

        #if DEBUG
        print("🧠 [Anthropic] Analyzing text with Claude Opus 4.5")
        print("   Task: \(task)")
        print("   Text length: \(text.count) characters")
        #endif

        switch task {
        case .entityExtraction:
            return try await extractEntities(from: text, apiKey: apiKey)
        case .relationshipInference:
            return try await inferRelationships(from: text, apiKey: apiKey)
        case .calendarExtraction:
            return try await extractCalendar(from: text, apiKey: apiKey)
        case .visualElementExtraction:
            // ER-0021: Visual element extraction
            // Placeholder - actual extraction will be done by VisualElementExtractor
            // Future: Could use Claude for sophisticated visual element extraction
            return AnalysisResult(entities: nil, relationships: nil, calendars: nil, metadata: nil)
        case .comprehensive:
            return try await performComprehensiveAnalysis(of: text, apiKey: apiKey)
        }
    }

    // MARK: - Private Analysis Methods

    /// Extract entities AND relationships using Claude (Phase 3 + ER-0020)
    private func extractEntities(from text: String, apiKey: String) async throws -> AnalysisResult {
        let systemPrompt = """
        You are an expert at analyzing creative writing to identify worldbuilding elements and relationships between them.

        Extract characters, locations, buildings, artifacts, vehicles, organizations, events, and historical events.
        Use "historical_event" for named time periods, eras, wars, treaties, and significant background events.

        ALSO extract relationships between entities based on the verbs and sentence structure in the text.

        Return results as a JSON object:
        {
          "entities": [
            {
              "name": "Entity Name",
              "type": "character|location|building|artifact|vehicle|organization|event|historical_event",
              "confidence": 0.0-1.0,
              "context": "Brief surrounding text"
            }
          ],
          "relationships": [
            {
              "source": "Source Entity Name",
              "target": "Target Entity Name",
              "forwardVerb": "verb describing source → target",
              "inverseVerb": "verb describing target → source",
              "confidence": 0.0-1.0,
              "context": "The sentence containing the relationship"
            }
          ]
        }

        For relationships:
        - Use the ACTUAL VERB from the text (e.g., "wields", "discovered", "writes", "dispatched")
        - Generate appropriate inverse verb (e.g., "is wielded by", "discovered by", "is written by", "dispatched by")

        CRITICAL: Focus on PERSISTENT CONNECTIONS, not temporary actions or prepositional phrases

        **HIGH confidence (0.9+): Subject-Verb-Direct Object relationships**
        - "Captain discovered Codex" → Captain → discovered/discovered by → Codex (0.95)
        - "Dean dispatched courier" → Dean → dispatched/dispatched by → courier (0.95)
        - "Character owns artifact" → Character → owns/owned by → artifact (0.9)

        **AVOID or use LOW confidence (<0.7): Prepositional phrases and momentary actions**
        - "descended the steps OF the Observatory" → SKIP (OF = prepositional phrase, not direct object)
        - "walked INTO the building" → SKIP (INTO = prepositional phrase)
        - "sitting ON the chair" → SKIP (temporary physical position)
        - "running THROUGH the forest" → SKIP (momentary movement)

        **Focus on meaningful entity relationships:**
        - Ownership, creation, discovery, employment, leadership, membership, containment
        - Avoid: temporary movements, physical descriptions, prepositional locations

        - Only include clear, explicit relationships (confidence > 0.7)
        - Both source and target must be entities you extracted in the "entities" array

        Only include entities that are proper nouns or specific named things.
        """

        let userPrompt = """
        Analyze this text and extract all entities and relationships:

        \(text)
        """

        let response = try await callClaude(systemPrompt: systemPrompt, userPrompt: userPrompt, apiKey: apiKey)

        let (entities, relationships) = parseEntitiesAndRelationships(from: response)

        return AnalysisResult(entities: entities, relationships: relationships, calendars: nil, metadata: nil)
    }

    /// Infer relationships using Claude (Phase 6 - placeholder)
    private func inferRelationships(from text: String, apiKey: String) async throws -> AnalysisResult {
        // Phase 6 implementation
        // Note: Relationship inference is done locally by SuggestionEngine using RelationshipInference
        // Providers do NOT perform relationship inference via AI
        return AnalysisResult(entities: nil, relationships: [], calendars: nil, metadata: nil)
    }

    /// Extract calendar structure using Claude (Phase 7)
    private func extractCalendar(from text: String, apiKey: String) async throws -> AnalysisResult {
        let systemPrompt = """
        You are an expert at analyzing fantasy and sci-fi narrative text to identify custom calendar systems.
        Extract ALL calendar system definitions including time divisions, month names, day names, eras, and festivals.

        Return results as a JSON object with a "calendars" array:
        {
          "calendars": [
            {
              "name": "Calendar Name",
              "divisions": [
                {
                  "name": "day",
                  "pluralName": "days",
                  "length": 24,
                  "isVariable": false
                },
                {
                  "name": "week",
                  "pluralName": "weeks",
                  "length": 7,
                  "isVariable": false
                },
                {
                  "name": "month",
                  "pluralName": "months",
                  "length": 30,
                  "isVariable": true
                },
                {
                  "name": "year",
                  "pluralName": "years",
                  "length": 12,
                  "isVariable": false
                }
              ],
              "eras": ["Era Name"],
              "festivals": [
                {
                  "name": "Festival Name",
                  "date": "timing description"
                }
              ],
              "confidence": 0.95
            }
          ]
        }

        Important:
        - Extract ALL calendar systems mentioned in the text (e.g., if both "Imperium Calendar" and "Old Republic Calendar" are described, return both)
        - Extract numeric values (days per month, months per year, days per week)
        - Set "isVariable" to true for divisions with varying lengths
        - Use "confidence" between 0.0-1.0 based on how clearly each calendar is defined
        - If NO calendar systems are described, return {"calendars": []}
        """

        let userPrompt = """
        Analyze this text and extract ALL calendar system definitions:

        \(text)
        """

        let response = try await callClaude(systemPrompt: systemPrompt, userPrompt: userPrompt, apiKey: apiKey)

        let calendars = parseCalendars(from: response)

        return AnalysisResult(entities: nil, relationships: nil, calendars: calendars, metadata: nil)
    }

    /// Perform comprehensive analysis
    private func performComprehensiveAnalysis(of text: String, apiKey: String) async throws -> AnalysisResult {
        let entitiesResult = try await extractEntities(from: text, apiKey: apiKey)
        let relationshipsResult = try await inferRelationships(from: text, apiKey: apiKey)
        let calendarResult = try await extractCalendar(from: text, apiKey: apiKey)

        return AnalysisResult(
            entities: entitiesResult.entities,
            relationships: relationshipsResult.relationships,
            calendars: calendarResult.calendars,
            metadata: nil
        )
    }

    /// Call Claude API for text analysis
    private func callClaude(systemPrompt: String, userPrompt: String, apiKey: String) async throws -> String {
        guard let url = URL(string: apiEndpoint) else {
            throw AIProviderError.invalidResponse(reason: "Invalid API endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.3 // Lower temperature for more consistent analysis
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make request with custom timeout and better error handling
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch let error as NSError {
            // Handle timeout and network errors specifically
            if error.domain == NSURLErrorDomain {
                if error.code == NSURLErrorTimedOut {
                    throw AIProviderError.networkError(
                        underlying: NSError(
                            domain: "Anthropic",
                            code: -1001,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Request timed out. Claude analysis can take 30-60 seconds. Please try again or use Apple Intelligence for faster results."
                            ]
                        )
                    )
                } else if error.code == NSURLErrorNotConnectedToInternet {
                    throw AIProviderError.networkError(
                        underlying: NSError(
                            domain: "Anthropic",
                            code: error.code,
                            userInfo: [NSLocalizedDescriptionKey: "No internet connection. Please check your network and try again."]
                        )
                    )
                }
            }
            throw AIProviderError.networkError(underlying: error)
        }

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.networkError(underlying: NSError(domain: "Anthropic", code: -1))
        }

        #if DEBUG
        print("📡 [Anthropic] HTTP Status: \(httpResponse.statusCode)")
        #endif

        // Handle errors
        if httpResponse.statusCode == 429 {
            throw AIProviderError.rateLimitExceeded(retryAfter: nil)
        }

        if httpResponse.statusCode == 401 {
            #if DEBUG
            print("⚠️ [Anthropic] Invalid API key (401)")
            #endif
            throw AIProviderError.invalidAPIKey
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(AnthropicErrorResponse.self, from: data) {
                #if DEBUG
                print("⚠️ [Anthropic] API Error: \(errorResponse.error.message)")
                #endif
                throw AIProviderError.invalidResponse(reason: errorResponse.error.message)
            }
            #if DEBUG
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("⚠️ [Anthropic] HTTP \(httpResponse.statusCode)")
            print("   Response: \(String(responseString.prefix(500)))")
            #endif
            throw AIProviderError.invalidResponse(reason: "HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        #if DEBUG
        let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode"
        print("📥 [Anthropic] Raw response (first 1000 chars): \(String(rawResponse.prefix(1000)))")
        #endif

        guard let json = try? JSONDecoder().decode(AnthropicMessageResponse.self, from: data),
              let content = json.content.first?.text else {
            #if DEBUG
            print("⚠️ [Anthropic] Failed to decode Claude response structure")
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("   Raw data: \(String(rawResponse.prefix(500)))")
            }
            #endif
            throw AIProviderError.invalidResponse(reason: "Failed to decode Claude response")
        }

        #if DEBUG
        print("✅ [Anthropic] Successfully decoded response")
        print("   Content (first 500 chars): \(String(content.prefix(500)))")
        #endif

        return content
    }

    // MARK: - Parsing Helpers

    /// Extract JSON from Claude's response (may be wrapped in markdown code blocks)
    private func extractJSON(from response: String) -> String {
        // Claude often wraps JSON in ```json ... ``` markdown blocks
        // Try to extract just the JSON part

        var text = response

        // Look for ```json opening
        if let jsonStart = text.range(of: "```json") {
            text = String(text[jsonStart.upperBound...])
            // Find the closing ```
            if let jsonEnd = text.range(of: "```") {
                text = String(text[..<jsonEnd.lowerBound])
                return text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
        }

        // Look for generic ``` code blocks
        if let codeStart = text.range(of: "```") {
            text = String(text[codeStart.upperBound...])
            if let codeEnd = text.range(of: "```") {
                text = String(text[..<codeEnd.lowerBound])
                let cleaned = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                // Check if this looks like JSON
                if cleaned.hasPrefix("{") || cleaned.hasPrefix("[") {
                    return cleaned
                }
            }
        }

        // No code blocks found - assume the response IS the JSON
        return response.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    /// Parse entities AND relationships from JSON response (ER-0020)
    private func parseEntitiesAndRelationships(from jsonString: String) -> (entities: [Entity], relationships: [DetectedRelationship]) {
        let extractedJSON = extractJSON(from: jsonString)

        guard let jsonData = extractedJSON.data(using: .utf8) else {
            #if DEBUG
            print("⚠️ [Anthropic] Failed to convert response to data")
            #endif
            return ([], [])
        }

        // Try parsing as EntityAndRelationshipResponse first (ER-0020 format)
        if let json = try? JSONDecoder().decode(EntityAndRelationshipResponse.self, from: jsonData) {
            #if DEBUG
            print("✅ [Anthropic] Parsed \(json.entities.count) entities and \(json.relationships.count) relationships from response")
            #endif

            let entities = json.entities.map { entityData in
                Entity(
                    name: entityData.name,
                    type: EntityType(rawValue: entityData.type) ?? .location,
                    confidence: entityData.confidence,
                    context: entityData.context
                )
            }

            let relationships = json.relationships.map { relData in
                DetectedRelationship(
                    sourceEntityName: relData.source,
                    targetEntityName: relData.target,
                    forwardVerb: relData.forwardVerb,
                    inverseVerb: relData.inverseVerb,
                    confidence: relData.confidence,
                    context: relData.context ?? ""
                )
            }

            return (entities, relationships)
        }

        // Fall back to old EntityExtractionResponse format (backward compatibility)
        if let json = try? JSONDecoder().decode(EntityExtractionResponse.self, from: jsonData) {
            #if DEBUG
            print("✅ [Anthropic] Parsed \(json.entities.count) entities from response (legacy format, no relationships)")
            #endif

            let entities = json.entities.map { entityData in
                Entity(
                    name: entityData.name,
                    type: EntityType(rawValue: entityData.type) ?? .location,
                    confidence: entityData.confidence,
                    context: entityData.context
                )
            }

            return (entities, [])
        }

        #if DEBUG
        print("⚠️ [Anthropic] Failed to parse entity/relationship extraction response")
        print("   Original response (first 500 chars): \(String(jsonString.prefix(500)))")
        print("   Extracted JSON (first 500 chars): \(String(extractedJSON.prefix(500)))")
        #endif
        return ([], [])
    }

    /// Parse entities from JSON response (backward compatibility - kept for other methods if needed)
    private func parseEntities(from jsonString: String) -> [Entity] {
        let (entities, _) = parseEntitiesAndRelationships(from: jsonString)
        return entities
    }

    /// Parse calendar structures from JSON response
    private func parseCalendars(from jsonString: String) -> [CalendarStructure] {
        let extractedJSON = extractJSON(from: jsonString)

        guard let jsonData = extractedJSON.data(using: .utf8),
              let json = try? JSONDecoder().decode(CalendarExtractionResponse.self, from: jsonData) else {
            #if DEBUG
            print("⚠️ [Anthropic] Failed to parse calendar extraction response")
            print("   Original response (first 500 chars): \(String(jsonString.prefix(500)))")
            print("   Extracted JSON (first 500 chars): \(String(extractedJSON.prefix(500)))")
            #endif
            return []
        }

        #if DEBUG
        print("✅ [Anthropic] Parsed \(json.calendars.count) calendar(s) from response")
        #endif

        return json.calendars.map { calendarData in
            CalendarStructure(
                name: calendarData.name,
                divisions: calendarData.divisions.map { divisionData in
                    TimeDivisionData(
                        name: divisionData.name,
                        pluralName: divisionData.pluralName,
                        length: divisionData.length,
                        isVariable: divisionData.isVariable
                    )
                },
                eras: calendarData.eras,
                festivals: calendarData.festivals.map { festivalData in
                    Festival(name: festivalData.name, date: festivalData.date)
                },
                confidence: calendarData.confidence
            )
        }
    }
}

// MARK: - Response Structures

/// Anthropic Messages API response
private struct AnthropicMessageResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ContentBlock]
    let model: String

    struct ContentBlock: Codable {
        let type: String
        let text: String?
    }
}

/// Anthropic error response
private struct AnthropicErrorResponse: Codable {
    let error: ErrorDetail

    struct ErrorDetail: Codable {
        let type: String
        let message: String
    }
}

/// Entity extraction response format
private struct EntityExtractionResponse: Codable {
    let entities: [EntityData]

    struct EntityData: Codable {
        let name: String
        let type: String
        let confidence: Double
        let context: String
    }
}

/// Combined entity and relationship extraction response format (ER-0020)
private struct EntityAndRelationshipResponse: Codable {
    let entities: [EntityData]
    let relationships: [RelationshipData]

    struct EntityData: Codable {
        let name: String
        let type: String
        let confidence: Double
        let context: String
    }

    struct RelationshipData: Codable {
        let source: String
        let target: String
        let forwardVerb: String
        let inverseVerb: String
        let confidence: Double
        let context: String?
    }
}

/// Calendar extraction response format
private struct CalendarExtractionResponse: Codable {
    let calendars: [CalendarData]

    struct CalendarData: Codable {
        let name: String
        let divisions: [TimeDivisionData]
        let eras: [String]
        let festivals: [FestivalData]
        let confidence: Double

        struct TimeDivisionData: Codable {
            let name: String
            let pluralName: String
            let length: Int?
            let isVariable: Bool
        }

        struct FestivalData: Codable {
            let name: String
            let date: String
        }
    }
}
