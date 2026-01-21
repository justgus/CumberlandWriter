import Foundation

/// Protocol defining AI provider capabilities for image generation and content analysis
/// Shared infrastructure for ER-0009 (Image Generation) and ER-0010 (Content Analysis)
///
/// Conforming types must implement both image generation and text analysis capabilities.
/// Providers should handle their own authentication, rate limiting, and error handling.
protocol AIProviderProtocol {

    /// Human-readable name of the provider
    /// Example: "Apple Intelligence", "OpenAI (ChatGPT)"
    var name: String { get }

    /// Whether this provider is currently available for use
    /// May depend on OS version, API key presence, network status, etc.
    var isAvailable: Bool { get }

    /// Whether this provider requires an API key for authentication
    /// Apple Intelligence returns false, third-party providers return true
    var requiresAPIKey: Bool { get }

    /// Optional provider-specific metadata (model version, capabilities, etc.)
    var metadata: AIProviderMetadata? { get }

    // MARK: - ER-0009: Image Generation

    /// Generate an image from a text prompt
    /// - Parameter prompt: The text description of the desired image
    /// - Returns: Image data in PNG or JPEG format
    /// - Throws: `AIProviderError` if generation fails
    func generateImage(prompt: String) async throws -> Data

    // MARK: - ER-0010: Content Analysis

    /// Analyze text for a specific task (entity extraction, relationship inference, etc.)
    /// - Parameters:
    ///   - text: The text to analyze
    ///   - task: The type of analysis to perform
    /// - Returns: Analysis result containing extracted entities, relationships, or calendar data
    /// - Throws: `AIProviderError` if analysis fails
    func analyzeText(_ text: String, for task: AnalysisTask) async throws -> AnalysisResult
}

// MARK: - Supporting Types

/// Metadata about a provider's capabilities
struct AIProviderMetadata {
    /// Model version or identifier (e.g., "gpt-4", "dall-e-3")
    var modelVersion: String?

    /// Maximum prompt length supported
    var maxPromptLength: Int?

    /// Supported image formats (for image generation)
    var supportedImageFormats: [String]?

    /// Rate limit information
    var rateLimit: RateLimit?

    /// Licensing information for generated content
    var licenseInfo: LicenseInfo?
}

/// Rate limiting information
struct RateLimit {
    /// Requests per minute
    var requestsPerMinute: Int

    /// Maximum requests per day
    var requestsPerDay: Int?
}

/// Licensing information for AI-generated content
struct LicenseInfo {
    /// License type (e.g., "Proprietary", "CC BY 4.0")
    var licenseType: String

    /// Attribution requirements
    var attributionRequired: Bool

    /// Commercial use allowed
    var commercialUseAllowed: Bool

    /// Full license text or URL
    var licenseURL: URL?
}

// MARK: - Analysis Task Types

/// Types of analysis that can be performed on text
enum AnalysisTask: Codable {
    /// Extract entities (characters, locations, artifacts)
    case entityExtraction

    /// Infer relationships between entities
    case relationshipInference

    /// Extract calendar system information
    case calendarExtraction

    /// Combined analysis (all of the above)
    case comprehensive
}

// MARK: - Analysis Results

/// Result of text analysis
struct AnalysisResult: Codable {
    /// Extracted entities (for entityExtraction or comprehensive tasks)
    var entities: [Entity]?

    /// Inferred relationships (for relationshipInference or comprehensive tasks)
    var relationships: [Relationship]?

    /// Extracted calendar structure (for calendarExtraction or comprehensive tasks)
    var calendar: CalendarStructure?

    /// Provider-specific metadata about the analysis
    var metadata: AnalysisMetadata?
}

/// Metadata about an analysis operation
struct AnalysisMetadata: Codable {
    /// Time taken to perform analysis
    var processingTime: TimeInterval?

    /// Model used for analysis
    var modelVersion: String?

    /// Tokens or characters processed
    var tokensProcessed: Int?
}

/// Extracted entity from text
struct Entity: Codable, Identifiable {
    var id = UUID()

    /// Entity name
    var name: String

    /// Entity type (Character, Location, Artifact, etc.)
    var type: EntityType

    /// Confidence score (0.0 to 1.0)
    var confidence: Double

    /// Context snippet from surrounding text
    var context: String?

    /// Original text span (for highlighting) - not persisted
    /// This property is excluded from Codable conformance
    var textRange: Range<String.Index>?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, confidence, context
        // textRange is intentionally excluded from coding
    }
}

/// Types of entities that can be extracted
enum EntityType: String, Codable {
    case character = "Character"
    case location = "Location"
    case building = "Building"
    case artifact = "Artifact"
    case vehicle = "Vehicle"
    case organization = "Organization"
    case event = "Event"
    case other = "Other"

    /// Map to Card kind
    func toCardKind() -> Kinds {
        switch self {
        case .character: return .characters
        case .location: return .locations
        case .building: return .buildings
        case .artifact: return .artifacts
        case .vehicle: return .vehicles
        case .organization: return .characters // Use characters for organizations
        case .event: return .scenes // Use scenes for events
        case .other: return .rules // Use rules for other entities
        }
    }
}

/// Inferred relationship between entities
struct Relationship: Codable, Identifiable {
    var id = UUID()

    /// Source entity name
    var source: String

    /// Target entity name
    var target: String

    /// Relationship type
    var type: RelationshipType

    /// Confidence score (0.0 to 1.0)
    var confidence: Double

    /// Context snippet
    var context: String?
}

/// Types of relationships between entities
enum RelationshipType: String, Codable {
    case owns = "owns"
    case uses = "uses"
    case location = "location" // Entity is at location
    case memberOf = "memberOf"
    case trainedAt = "trainedAt"
    case bornIn = "bornIn"
    case commands = "commands"
    case companion = "companion"
    case enemy = "enemy"
    case parent = "parent"
    case child = "child"
    case other = "other"
}

/// Extracted calendar structure from text
struct CalendarStructure: Codable {
    /// Calendar name (e.g., "Eldarian Calendar")
    var name: String?

    /// Time divisions (moments, cycles, days, months, years, etc.)
    var divisions: [TimeDivisionData]

    /// Named eras or ages
    var eras: [String]?

    /// Festivals or special events
    var festivals: [Festival]?

    /// Confidence score for the extraction
    var confidence: Double
}

/// Time division data extracted from text
struct TimeDivisionData: Codable {
    var name: String
    var pluralName: String
    var length: Int?
    var isVariable: Bool

    /// Convert to TimeDivision model
    func toTimeDivision() -> TimeDivision {
        TimeDivision(
            name: name,
            pluralName: pluralName,
            length: length ?? 1,
            isVariable: isVariable
        )
    }
}

/// Festival or special event in calendar
struct Festival: Codable {
    var name: String
    var date: String? // Text description of when it occurs
}

// MARK: - Protocol Extensions

extension AIProviderProtocol {
    /// Default implementation for metadata (providers can override)
    var metadata: AIProviderMetadata? { nil }
}
