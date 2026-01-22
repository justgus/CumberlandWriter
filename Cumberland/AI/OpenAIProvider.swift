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

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

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
        // OpenAI could do this with GPT-4, but not implementing for MVP
        throw AIProviderError.featureNotSupported(feature: "Content analysis not yet implemented for OpenAI")
    }
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
