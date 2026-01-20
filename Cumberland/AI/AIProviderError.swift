import Foundation

/// Errors that can occur when using AI providers
enum AIProviderError: LocalizedError {

    // MARK: - Availability Errors

    /// Provider is not available (OS version, API key missing, etc.)
    case providerUnavailable(reason: String)

    /// Feature not supported by this provider
    case featureNotSupported(feature: String)

    // MARK: - Authentication Errors

    /// API key is missing or invalid
    case invalidAPIKey

    /// API key is missing from keychain
    case missingAPIKey

    /// Authentication failed
    case authenticationFailed(reason: String)

    // MARK: - Request Errors

    /// Invalid prompt or text input
    case invalidInput(reason: String)

    /// Prompt exceeds maximum length
    case promptTooLong(maxLength: Int, actual: Int)

    /// Text is too short for meaningful analysis
    case textTooShort(minLength: Int, actual: Int)

    // MARK: - API Errors

    /// Network request failed
    case networkError(underlying: Error)

    /// API returned an error
    case apiError(statusCode: Int, message: String?)

    /// Rate limit exceeded
    case rateLimitExceeded(retryAfter: TimeInterval?)

    /// Quota exceeded (daily/monthly limit)
    case quotaExceeded

    // MARK: - Response Errors

    /// API returned invalid or malformed response
    case invalidResponse(reason: String)

    /// Failed to decode response
    case decodingError(underlying: Error)

    /// Generated image data is invalid
    case invalidImageData

    /// Analysis result is incomplete or invalid
    case invalidAnalysisResult(reason: String)

    // MARK: - Content Policy Errors

    /// Content violates provider's content policy
    case contentPolicyViolation(reason: String)

    /// Prompt was filtered or rejected
    case promptFiltered

    // MARK: - Timeout Errors

    /// Request timed out
    case timeout(duration: TimeInterval)

    /// Generation or analysis took too long
    case operationTimeout

    // MARK: - Unknown Errors

    /// Unknown error occurred
    case unknown(underlying: Error?)

    // MARK: - LocalizedError Conformance

    var errorDescription: String? {
        switch self {
        case .providerUnavailable(let reason):
            return "AI provider is unavailable: \(reason)"

        case .featureNotSupported(let feature):
            return "Feature not supported: \(feature)"

        case .invalidAPIKey:
            return "Invalid API key. Please check your settings."

        case .missingAPIKey:
            return "API key is required. Please add your API key in settings."

        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"

        case .invalidInput(let reason):
            return "Invalid input: \(reason)"

        case .promptTooLong(let maxLength, let actual):
            return "Prompt is too long. Maximum: \(maxLength) characters, provided: \(actual)"

        case .textTooShort(let minLength, let actual):
            return "Text is too short for analysis. Minimum: \(minLength) words, provided: \(actual)"

        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"

        case .apiError(let statusCode, let message):
            if let message = message {
                return "API error (\(statusCode)): \(message)"
            }
            return "API error: HTTP \(statusCode)"

        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limit exceeded. Please try again in \(Int(retryAfter)) seconds."
            }
            return "Rate limit exceeded. Please try again later."

        case .quotaExceeded:
            return "Quota exceeded. You've reached your daily limit for this service."

        case .invalidResponse(let reason):
            return "Invalid response from AI provider: \(reason)"

        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"

        case .invalidImageData:
            return "Generated image data is invalid or corrupted."

        case .invalidAnalysisResult(let reason):
            return "Analysis result is invalid: \(reason)"

        case .contentPolicyViolation(let reason):
            return "Content policy violation: \(reason)"

        case .promptFiltered:
            return "Your prompt was filtered due to content policy. Please try a different prompt."

        case .timeout(let duration):
            return "Request timed out after \(Int(duration)) seconds."

        case .operationTimeout:
            return "Operation took too long and was cancelled."

        case .unknown(let error):
            if let error = error {
                return "Unknown error: \(error.localizedDescription)"
            }
            return "An unknown error occurred."
        }
    }

    var failureReason: String? {
        switch self {
        case .providerUnavailable:
            return "The AI provider cannot be used at this time."

        case .invalidAPIKey, .missingAPIKey:
            return "API key authentication failed."

        case .rateLimitExceeded, .quotaExceeded:
            return "Usage limit reached."

        case .networkError:
            return "Network connection failed."

        case .contentPolicyViolation, .promptFiltered:
            return "Content does not meet provider guidelines."

        default:
            return nil
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .providerUnavailable:
            return "Try a different AI provider or check if your device supports this feature."

        case .invalidAPIKey, .missingAPIKey:
            return "Go to Settings and add or update your API key."

        case .promptTooLong:
            return "Shorten your prompt and try again."

        case .textTooShort:
            return "Add more details to your description and try again."

        case .rateLimitExceeded:
            return "Wait a few minutes before trying again, or use a different provider."

        case .quotaExceeded:
            return "Wait until tomorrow for your quota to reset, or upgrade your plan."

        case .networkError:
            return "Check your internet connection and try again."

        case .contentPolicyViolation, .promptFiltered:
            return "Modify your prompt to comply with content guidelines and try again."

        default:
            return "Please try again. If the problem persists, contact support."
        }
    }
}

// MARK: - Error Helper Extensions

extension AIProviderError {
    /// Whether this error is recoverable by retrying
    var isRetryable: Bool {
        switch self {
        case .networkError, .timeout, .operationTimeout, .apiError(500...599, _):
            return true
        case .rateLimitExceeded:
            return true // After waiting
        default:
            return false
        }
    }

    /// Whether this error should be logged as a warning vs error
    var isWarning: Bool {
        switch self {
        case .promptFiltered, .contentPolicyViolation, .textTooShort, .promptTooLong:
            return true
        default:
            return false
        }
    }

    /// Whether this error requires user intervention
    var requiresUserIntervention: Bool {
        switch self {
        case .invalidAPIKey, .missingAPIKey, .quotaExceeded, .contentPolicyViolation:
            return true
        default:
            return false
        }
    }
}
