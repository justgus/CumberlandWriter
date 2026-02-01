import Foundation

/// OpenAI provider for DALL-E 3 image generation
/// Requires API key from https://platform.openai.com/api-keys
class OpenAIProvider: AIProviderProtocol {

    // MARK: - AIProviderProtocol Conformance

    var name: String {
        "OpenAI DALL-E 3"
    }

    var isAvailable: Bool {
        // Available on all platforms as long as we have network
        return true
    }

    var requiresAPIKey: Bool {
        true
    }

    var metadata: AIProviderMetadata? {
        AIProviderMetadata(
            modelVersion: "DALL-E 3",
            maxPromptLength: 4000, // DALL-E 3 supports up to 4000 characters
            supportedImageFormats: ["PNG"],
            rateLimit: RateLimit(
                requestsPerMinute: 5, // Conservative - actual limit depends on tier
                requestsPerDay: nil
            ),
            licenseInfo: LicenseInfo(
                licenseType: "Proprietary - OpenAI",
                attributionRequired: true,
                commercialUseAllowed: true, // Subject to OpenAI terms
                licenseURL: URL(string: "https://openai.com/policies/terms-of-use")
            )
        )
    }

    // MARK: - Constants

    private let apiEndpoint = "https://api.openai.com/v1/images/generations"
    private let defaultImageSize = "1024x1024" // DALL-E 3 default
    private let model = "dall-e-3"

    // MARK: - URLSession Configuration

    /// Custom URLSession with longer timeout for AI operations
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120 // 2 minutes for text analysis
        config.timeoutIntervalForResource = 180 // 3 minutes total
        return URLSession(configuration: config)
    }()

    // MARK: - Image Generation

    func generateImage(prompt: String) async throws -> Data {
        guard !prompt.isEmpty else {
            throw AIProviderError.invalidInput(reason: "Prompt cannot be empty")
        }

        guard prompt.count <= 4000 else {
            throw AIProviderError.promptTooLong(maxLength: 4000, actual: prompt.count)
        }

        // Get API key from keychain
        guard let apiKey = try? KeychainHelper.shared.retrieveAPIKey(for: "openai"), !apiKey.isEmpty else {
            throw AIProviderError.invalidAPIKey
        }

        #if DEBUG
        print("🎨 [OpenAI] Generating image with DALL-E 3")
        print("   Prompt: \(prompt)")
        #endif

        // Create request
        guard let url = URL(string: apiEndpoint) else {
            throw AIProviderError.invalidResponse(reason: "Invalid API endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Request body
        let requestBody: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "n": 1,
            "size": defaultImageSize,
            "response_format": "b64_json" // Get base64 encoded image
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make request with custom timeout
        let (data, response) = try await urlSession.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.networkError(underlying: NSError(domain: "OpenAI", code: -1))
        }

        // Handle rate limiting
        if httpResponse.statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
            let seconds = retryAfter.flatMap(Double.init)
            throw AIProviderError.rateLimitExceeded(retryAfter: seconds)
        }

        // Handle authentication errors
        if httpResponse.statusCode == 401 {
            throw AIProviderError.invalidAPIKey
        }

        // Handle quota exceeded
        if httpResponse.statusCode == 429 || httpResponse.statusCode == 403 {
            throw AIProviderError.quotaExceeded
        }

        // Handle general errors
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw AIProviderError.invalidResponse(reason: errorResponse.error.message)
            }
            throw AIProviderError.invalidResponse(reason: "HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        guard let json = try? JSONDecoder().decode(OpenAIImageResponse.self, from: data),
              let imageData = json.data.first?.b64_json,
              let decodedData = Data(base64Encoded: imageData) else {
            throw AIProviderError.invalidResponse(reason: "Failed to decode image data")
        }

        #if DEBUG
        print("✅ [OpenAI] Successfully generated image (\(decodedData.count) bytes)")
        #endif

        return decodedData
    }

    // MARK: - Content Analysis

    func analyzeText(_ text: String, for task: AnalysisTask) async throws -> AnalysisResult {
        guard !text.isEmpty else {
            throw AIProviderError.invalidInput(reason: "Text cannot be empty")
        }

        let wordCount = text.split(separator: " ").count
        guard wordCount >= 25 else {
            throw AIProviderError.textTooShort(minLength: 25, actual: wordCount)
        }

        // Get API key from keychain
        guard let apiKey = try? KeychainHelper.shared.retrieveAPIKey(for: "openai"), !apiKey.isEmpty else {
            throw AIProviderError.invalidAPIKey
        }

        #if DEBUG
        print("🧠 [OpenAI] Analyzing text for task: \(task)")
        print("   Text length: \(text.count) characters, \(wordCount) words")
        #endif

        let startTime = Date()

        // Perform analysis based on task type
        let result: AnalysisResult

        switch task {
        case .entityExtraction:
            result = try await extractEntities(from: text, apiKey: apiKey)
        case .relationshipInference:
            result = try await inferRelationships(from: text, apiKey: apiKey)
        case .calendarExtraction:
            result = try await extractCalendar(from: text, apiKey: apiKey)
        case .comprehensive:
            result = try await performComprehensiveAnalysis(of: text, apiKey: apiKey)
        }

        #if DEBUG
        let processingTime = Date().timeIntervalSince(startTime)
        print("✅ [OpenAI] Analysis complete in \(String(format: "%.2f", processingTime))s")
        print("   Entities: \(result.entities?.count ?? 0)")
        print("   Relationships: \(result.relationships?.count ?? 0)")
        #endif

        return result
    }

    // MARK: - Private Analysis Methods

    /// Extract entities AND relationships using GPT-4 (Phase 3 + ER-0020)
    private func extractEntities(from text: String, apiKey: String) async throws -> AnalysisResult {
        let systemPrompt = """
        You are an expert at analyzing fantasy and sci-fi narrative text to identify key entities and relationships between them.

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

        let response = try await callGPT4(systemPrompt: systemPrompt, userPrompt: userPrompt, apiKey: apiKey)

        let (entities, relationships) = parseEntitiesAndRelationships(from: response)

        return AnalysisResult(entities: entities, relationships: relationships, calendars: nil, metadata: nil)
    }

    /// Infer relationships using GPT-4 (Phase 6 - placeholder)
    private func inferRelationships(from text: String, apiKey: String) async throws -> AnalysisResult {
        // Phase 6 implementation
        return AnalysisResult(entities: nil, relationships: [], calendars: nil, metadata: nil)
    }

    /// Extract calendar structure using GPT-4 (Phase 7)
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

        let response = try await callGPT4(systemPrompt: systemPrompt, userPrompt: userPrompt, apiKey: apiKey)

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

    /// Call GPT-4 API for text analysis
    private func callGPT4(systemPrompt: String, userPrompt: String, apiKey: String) async throws -> String {
        let endpoint = "https://api.openai.com/v1/chat/completions"

        guard let url = URL(string: endpoint) else {
            throw AIProviderError.invalidResponse(reason: "Invalid API endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "gpt-4-turbo-preview",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.3, // Lower temperature for more consistent analysis
            "response_format": ["type": "json_object"] // Request JSON response
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
                            domain: "OpenAI",
                            code: -1001,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Request timed out. GPT-4 analysis can take 30-60 seconds. Please try again or use Apple Intelligence for faster results."
                            ]
                        )
                    )
                } else if error.code == NSURLErrorNotConnectedToInternet {
                    throw AIProviderError.networkError(
                        underlying: NSError(
                            domain: "OpenAI",
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
            throw AIProviderError.networkError(underlying: NSError(domain: "OpenAI", code: -1))
        }

        // Handle errors
        if httpResponse.statusCode == 429 {
            throw AIProviderError.rateLimitExceeded(retryAfter: nil)
        }

        if httpResponse.statusCode == 401 {
            throw AIProviderError.invalidAPIKey
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw AIProviderError.invalidResponse(reason: errorResponse.error.message)
            }
            throw AIProviderError.invalidResponse(reason: "HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        guard let json = try? JSONDecoder().decode(OpenAIChatResponse.self, from: data),
              let content = json.choices.first?.message.content else {
            throw AIProviderError.invalidResponse(reason: "Failed to decode GPT-4 response")
        }

        return content
    }

    /// Parse entities AND relationships from JSON string (ER-0020)
    private func parseEntitiesAndRelationships(from jsonString: String) -> (entities: [Entity], relationships: [DetectedRelationship]) {
        guard let jsonData = jsonString.data(using: .utf8) else {
            #if DEBUG
            print("⚠️ [OpenAI] Failed to convert JSON string to data")
            #endif
            return ([], [])
        }

        // Try parsing as EntityAndRelationshipResponse first (ER-0020 format)
        if let wrappedResponse = try? JSONDecoder().decode(EntityAndRelationshipResponse.self, from: jsonData) {
            #if DEBUG
            print("✅ [OpenAI] Parsed \(wrappedResponse.entities.count) entities and \(wrappedResponse.relationships.count) relationships from wrapped JSON")
            #endif

            let entities = wrappedResponse.entities.map { json in
                Entity(
                    name: json.name,
                    type: EntityType(rawValue: json.type) ?? .other,
                    confidence: json.confidence,
                    context: json.context
                )
            }

            let relationships = wrappedResponse.relationships.map { relData in
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

        // Try parsing as wrapped object (GPT-4 with response_format: json_object) - backward compatibility
        if let wrappedResponse = try? JSONDecoder().decode(EntityResponse.self, from: jsonData) {
            #if DEBUG
            print("✅ [OpenAI] Parsed \(wrappedResponse.entities.count) entities from wrapped JSON (legacy format, no relationships)")
            #endif
            let entities = wrappedResponse.entities.map { json in
                Entity(
                    name: json.name,
                    type: EntityType(rawValue: json.type) ?? .other,
                    confidence: json.confidence,
                    context: json.context
                )
            }
            return (entities, [])
        }

        // Fallback: try parsing as direct array - backward compatibility
        if let jsonArray = try? JSONDecoder().decode([EntityJSON].self, from: jsonData) {
            #if DEBUG
            print("✅ [OpenAI] Parsed \(jsonArray.count) entities from array JSON (legacy format, no relationships)")
            #endif
            let entities = jsonArray.map { json in
                Entity(
                    name: json.name,
                    type: EntityType(rawValue: json.type) ?? .other,
                    confidence: json.confidence,
                    context: json.context
                )
            }
            return (entities, [])
        }

        #if DEBUG
        print("⚠️ [OpenAI] Failed to parse entities/relationships JSON")
        print("   Raw JSON (first 500 chars): \(String(jsonString.prefix(500)))")
        #endif
        return ([], [])
    }

    /// Parse entities from JSON string (backward compatibility - kept for other methods if needed)
    private func parseEntities(from jsonString: String) -> [Entity] {
        let (entities, _) = parseEntitiesAndRelationships(from: jsonString)
        return entities
    }

    /// Parse calendars from JSON string
    private func parseCalendars(from jsonString: String) -> [CalendarStructure]? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            #if DEBUG
            print("⚠️ [OpenAI] Failed to convert JSON string to data")
            #endif
            return nil
        }

        // Try parsing wrapped calendars response
        if let wrappedResponse = try? JSONDecoder().decode(CalendarResponse.self, from: jsonData) {
            let calendarsJSON = wrappedResponse.calendars

            guard !calendarsJSON.isEmpty else {
                #if DEBUG
                print("ℹ️ [OpenAI] No calendars found in text")
                #endif
                return []
            }

            #if DEBUG
            print("✅ [OpenAI] Parsed \(calendarsJSON.count) calendar(s)")
            #endif

            // Convert JSON to CalendarStructure array
            let calendars = calendarsJSON.map { calendarJSON in
                let divisions = calendarJSON.divisions.map { div in
                    TimeDivisionData(
                        name: div.name,
                        pluralName: div.pluralName,
                        length: div.length,
                        isVariable: div.isVariable
                    )
                }

                let festivals = calendarJSON.festivals?.map { fest in
                    Festival(name: fest.name, date: fest.date)
                }

                #if DEBUG
                print("   - \(calendarJSON.name ?? "Unnamed"): confidence \(Int(calendarJSON.confidence * 100))%")
                #endif

                return CalendarStructure(
                    name: calendarJSON.name,
                    divisions: divisions,
                    eras: calendarJSON.eras,
                    festivals: festivals,
                    confidence: calendarJSON.confidence
                )
            }

            return calendars
        }

        #if DEBUG
        print("⚠️ [OpenAI] Failed to parse calendars JSON")
        print("   Raw JSON (first 500 chars): \(String(jsonString.prefix(500)))")
        #endif
        return nil
    }
}

// MARK: - GPT-4 Response Types

private struct OpenAIChatResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}

private struct EntityJSON: Codable {
    let name: String
    let type: String
    let confidence: Double
    let context: String?
}

private struct EntityResponse: Codable {
    let entities: [EntityJSON]
}

/// Combined entity and relationship extraction response format (ER-0020)
private struct EntityAndRelationshipResponse: Codable {
    let entities: [EntityJSON]
    let relationships: [RelationshipJSON]
}

private struct RelationshipJSON: Codable {
    let source: String
    let target: String
    let forwardVerb: String
    let inverseVerb: String
    let confidence: Double
    let context: String?
}

private struct CalendarJSON: Codable {
    let name: String?
    let divisions: [TimeDivisionJSON]
    let eras: [String]?
    let festivals: [FestivalJSON]?
    let confidence: Double
}

private struct TimeDivisionJSON: Codable {
    let name: String
    let pluralName: String
    let length: Int
    let isVariable: Bool
}

private struct FestivalJSON: Codable {
    let name: String
    let date: String
}

private struct CalendarResponse: Codable {
    let calendars: [CalendarJSON]
}

// MARK: - API Response Types

private struct OpenAIImageResponse: Codable {
    let created: Int
    let data: [ImageData]

    struct ImageData: Codable {
        let b64_json: String?
        let url: String?
        let revised_prompt: String?
    }
}

private struct OpenAIErrorResponse: Codable {
    let error: ErrorDetail

    struct ErrorDetail: Codable {
        let message: String
        let type: String
        let code: String?
    }
}
