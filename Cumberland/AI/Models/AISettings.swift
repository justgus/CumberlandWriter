//
//  AISettings.swift
//  Cumberland
//
//  Singleton for persisting AI provider preferences and behaviour settings
//  via UserDefaults. Provides typed accessors for preferred provider name,
//  confidence threshold, max suggestions, auto-suggestion toggle, and API
//  key management (delegated to KeychainHelper). Views use @AppStorage with
//  the published key constants for reactive updates.
//

import Foundation
import SwiftUI

/// AI settings for image generation and content analysis
/// Manages user preferences for AI provider selection and behavior
///
/// Settings are persisted using UserDefaults
/// Views should use @AppStorage with these keys for reactive updates
class AISettings {

    // MARK: - Singleton

    static let shared = AISettings()

    private init() {}

    // MARK: - UserDefaults Keys

    struct Keys {
        static let preferredProvider = "ai_preferredProvider" // Legacy key for migration
        static let analysisProvider = "ai_analysisProvider"
        static let imageGenerationProvider = "ai_imageGenerationProvider"
        static let aiEnabled = "ai_enabled"
        static let autoGenerateImages = "aiGeneration_autoGenerate"
        static let autoGenerateMinWords = "aiGeneration_autoGenerateMinWords"
        static let imageHistoryLimit = "aiGeneration_historyLimit"
        static let alwaysShowAttributionOverlay = "aiAttribution_alwaysShowOverlay"
        static let copyrightTemplate = "aiAttribution_copyrightTemplate"
        static let analysisEnabled = "aiAnalysis_enabled"
        static let analysisScope = "aiAnalysis_scope"
        static let confidenceThreshold = "aiAnalysis_confidenceThreshold"
        static let enabledEntityTypes = "aiAnalysis_enabledEntityTypes"
        static let analysisMinWordCount = "aiAnalysis_minWordCount"
        static let enableLearning = "aiAnalysis_enableLearning"
    }

    // MARK: - Defaults

    struct Defaults {
        static let preferredProvider = "Apple Intelligence" // Legacy default
        static let analysisProvider = "Apple Intelligence"
        static let imageGenerationProvider = "Apple Intelligence"
        static let aiEnabled = true
        static let autoGenerateImages = false
        static let autoGenerateMinWords = 50
        static let imageHistoryLimit = 5
        static let alwaysShowAttributionOverlay = false
        static let copyrightTemplate = "© {YEAR} {USER}. AI-assisted artwork."
        static let analysisEnabled = true
        static let analysisScope = AnalysisScope.moderate
        static let confidenceThreshold = 0.70
        static let enabledEntityTypes = EntityTypeFlags.all
        static let analysisMinWordCount = 25
        static let enableLearning = true
    }

    // MARK: - Provider Settings

    /// AI provider for content analysis (entity extraction, relationship inference)
    var analysisProvider: String {
        get {
            // Check if already migrated
            if let provider = UserDefaults.standard.string(forKey: Keys.analysisProvider) {
                return provider
            }
            // Migration: use legacy preferredProvider if set
            if let legacyProvider = UserDefaults.standard.string(forKey: Keys.preferredProvider) {
                // Migrate the legacy value
                UserDefaults.standard.set(legacyProvider, forKey: Keys.analysisProvider)
                return legacyProvider
            }
            return Defaults.analysisProvider
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.analysisProvider) }
    }

    /// AI provider for image generation
    var imageGenerationProvider: String {
        get {
            // Check if already migrated
            if let provider = UserDefaults.standard.string(forKey: Keys.imageGenerationProvider) {
                return provider
            }
            // Migration: use legacy preferredProvider if set
            if let legacyProvider = UserDefaults.standard.string(forKey: Keys.preferredProvider) {
                // Migrate the legacy value
                UserDefaults.standard.set(legacyProvider, forKey: Keys.imageGenerationProvider)
                return legacyProvider
            }
            return Defaults.imageGenerationProvider
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.imageGenerationProvider) }
    }

    /// Legacy property for backward compatibility
    /// Reading returns analysisProvider, writing sets both providers
    @available(*, deprecated, message: "Use analysisProvider or imageGenerationProvider instead")
    var preferredProvider: String {
        get { analysisProvider }
        set {
            analysisProvider = newValue
            imageGenerationProvider = newValue
        }
    }

    /// Whether AI features are enabled at all
    var aiEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.aiEnabled) as? Bool ?? Defaults.aiEnabled }
        set { UserDefaults.standard.set(newValue, forKey: Keys.aiEnabled) }
    }

    // MARK: - ER-0009: Image Generation Settings

    /// Enable auto-generation of images
    var autoGenerateImages: Bool {
        get { UserDefaults.standard.object(forKey: Keys.autoGenerateImages) as? Bool ?? Defaults.autoGenerateImages }
        set { UserDefaults.standard.set(newValue, forKey: Keys.autoGenerateImages) }
    }

    /// Minimum words in description required for auto-generation
    var autoGenerateMinWords: Int {
        get { UserDefaults.standard.object(forKey: Keys.autoGenerateMinWords) as? Int ?? Defaults.autoGenerateMinWords }
        set { UserDefaults.standard.set(newValue, forKey: Keys.autoGenerateMinWords) }
    }

    /// Number of previous image versions to keep
    var imageHistoryLimit: Int {
        get { UserDefaults.standard.object(forKey: Keys.imageHistoryLimit) as? Int ?? Defaults.imageHistoryLimit }
        set { UserDefaults.standard.set(newValue, forKey: Keys.imageHistoryLimit) }
    }

    /// Always show attribution overlay (vs subtle badge)
    var alwaysShowAttributionOverlay: Bool {
        get { UserDefaults.standard.object(forKey: Keys.alwaysShowAttributionOverlay) as? Bool ?? Defaults.alwaysShowAttributionOverlay }
        set { UserDefaults.standard.set(newValue, forKey: Keys.alwaysShowAttributionOverlay) }
    }

    /// Copyright text template for AI-generated images
    var copyrightTemplate: String {
        get { UserDefaults.standard.string(forKey: Keys.copyrightTemplate) ?? Defaults.copyrightTemplate }
        set { UserDefaults.standard.set(newValue, forKey: Keys.copyrightTemplate) }
    }

    // MARK: - ER-0010: Content Analysis Settings

    /// Enable AI assistant for content analysis
    var analysisEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.analysisEnabled) as? Bool ?? Defaults.analysisEnabled }
        set { UserDefaults.standard.set(newValue, forKey: Keys.analysisEnabled) }
    }

    /// Analysis scope (conservative, moderate, aggressive)
    var analysisScope: String {
        get { UserDefaults.standard.string(forKey: Keys.analysisScope) ?? Defaults.analysisScope.rawValue }
        set { UserDefaults.standard.set(newValue, forKey: Keys.analysisScope) }
    }

    /// Minimum confidence threshold for suggestions (0.0 to 1.0)
    var confidenceThreshold: Double {
        get { UserDefaults.standard.object(forKey: Keys.confidenceThreshold) as? Double ?? Defaults.confidenceThreshold }
        set { UserDefaults.standard.set(newValue, forKey: Keys.confidenceThreshold) }
    }

    /// Entity types to extract (bitmask)
    var enabledEntityTypes: Int {
        get { UserDefaults.standard.object(forKey: Keys.enabledEntityTypes) as? Int ?? Defaults.enabledEntityTypes }
        set { UserDefaults.standard.set(newValue, forKey: Keys.enabledEntityTypes) }
    }

    /// Minimum word count for analysis
    var analysisMinWordCount: Int {
        get { UserDefaults.standard.object(forKey: Keys.analysisMinWordCount) as? Int ?? Defaults.analysisMinWordCount }
        set { UserDefaults.standard.set(newValue, forKey: Keys.analysisMinWordCount) }
    }

    /// Enable learning from user feedback
    var enableLearning: Bool {
        get { UserDefaults.standard.object(forKey: Keys.enableLearning) as? Bool ?? Defaults.enableLearning }
        set { UserDefaults.standard.set(newValue, forKey: Keys.enableLearning) }
    }

    // MARK: - API Keys (via Keychain)

    /// Check if an API key is set for a provider
    func hasAPIKey(for provider: String) -> Bool {
        KeychainHelper.shared.hasAPIKey(for: provider)
    }

    /// Get API key for a provider
    func getAPIKey(for provider: String) throws -> String? {
        try KeychainHelper.shared.retrieveAPIKey(for: provider)
    }

    /// Set API key for a provider
    func setAPIKey(_ key: String, for provider: String) throws {
        try KeychainHelper.shared.saveAPIKey(key, for: provider)
    }

    /// Delete API key for a provider
    func deleteAPIKey(for provider: String) throws {
        try KeychainHelper.shared.deleteAPIKey(for: provider)
    }

    // MARK: - Provider Availability

    /// Get provider for a specific task
    /// - Parameter task: The task type (analysis or imageGeneration)
    /// - Returns: The appropriate provider for the task
    func provider(for task: AITask) -> String {
        switch task {
        case .analysis:
            return analysisProvider
        case .imageGeneration:
            return imageGenerationProvider
        }
    }

    /// Get current provider for analysis (or default if unavailable)
    var currentAnalysisProvider: AIProviderProtocol? {
        AIProviderRegistry.shared.provider(named: analysisProvider)
            ?? AIProviderRegistry.shared.defaultProvider()
    }

    /// Get current provider for image generation (or default if unavailable)
    var currentImageGenerationProvider: AIProviderProtocol? {
        AIProviderRegistry.shared.provider(named: imageGenerationProvider)
            ?? AIProviderRegistry.shared.defaultProvider()
    }

    /// Legacy: Get current provider (returns analysis provider)
    @available(*, deprecated, message: "Use currentAnalysisProvider or currentImageGenerationProvider")
    var currentProvider: AIProviderProtocol? {
        currentAnalysisProvider
    }

    /// Check if current provider is available
    var isProviderAvailable: Bool {
        currentAnalysisProvider != nil || currentImageGenerationProvider != nil
    }

    /// Get list of available providers
    var availableProviders: [AIProviderProtocol] {
        AIProviderRegistry.shared.availableProviders()
    }

    // MARK: - Feature Availability

    /// Check if image generation is available
    var isImageGenerationAvailable: Bool {
        aiEnabled && currentImageGenerationProvider != nil
    }

    /// Check if content analysis is available
    var isContentAnalysisAvailable: Bool {
        aiEnabled && analysisEnabled && currentAnalysisProvider != nil
    }

    // MARK: - Reset Settings

    /// Reset all settings to defaults
    func resetToDefaults() {
        analysisProvider = Defaults.analysisProvider
        imageGenerationProvider = Defaults.imageGenerationProvider
        aiEnabled = true

        // Image generation
        autoGenerateImages = false
        autoGenerateMinWords = 50
        imageHistoryLimit = 5
        alwaysShowAttributionOverlay = false
        copyrightTemplate = "© {YEAR} {USER}. AI-assisted artwork."

        // Content analysis
        analysisEnabled = true
        analysisScope = AnalysisScope.moderate.rawValue
        confidenceThreshold = 0.70
        enabledEntityTypes = EntityTypeFlags.all
        analysisMinWordCount = 25
        enableLearning = true

        #if DEBUG
        print("✓ [AISettings] Reset to defaults")
        #endif
    }

    // MARK: - Helpers

    /// Get analysis scope enum
    var analysisScopeEnum: AnalysisScope {
        get { AnalysisScope(rawValue: analysisScope) ?? .moderate }
        set { analysisScope = newValue.rawValue }
    }

    /// Format copyright template with current values
    func formattedCopyright(user: String = "User") -> String {
        let year = Calendar.current.component(.year, from: Date())
        return copyrightTemplate
            .replacingOccurrences(of: "{YEAR}", with: "\(year)")
            .replacingOccurrences(of: "{USER}", with: user)
    }

    /// Check if an entity type is enabled
    func isEntityTypeEnabled(_ type: EntityType) -> Bool {
        let flag = EntityTypeFlags.flag(for: type)
        return (enabledEntityTypes & flag) != 0
    }

    /// Enable or disable an entity type
    func setEntityType(_ type: EntityType, enabled: Bool) {
        let flag = EntityTypeFlags.flag(for: type)
        if enabled {
            enabledEntityTypes |= flag
        } else {
            enabledEntityTypes &= ~flag
        }
    }
}

// MARK: - AI Task Type

/// Type of AI task to perform
enum AITask {
    case analysis           // Content analysis, entity extraction
    case imageGeneration    // Image generation for cards/maps
}

// MARK: - Analysis Scope

enum AnalysisScope: String, CaseIterable {
    case conservative = "conservative"
    case moderate = "moderate"
    case aggressive = "aggressive"

    var displayName: String {
        switch self {
        case .conservative: return String(localized: "Conservative")
        case .moderate:     return String(localized: "Moderate")
        case .aggressive:   return String(localized: "Aggressive")
        }
    }

    var description: String {
        switch self {
        case .conservative: return String(localized: "Fewer suggestions with high confidence")
        case .moderate:     return String(localized: "Balanced suggestions")
        case .aggressive:   return String(localized: "More suggestions with lower confidence")
        }
    }

    /// Confidence threshold for this scope
    var defaultThreshold: Double {
        switch self {
        case .conservative: return 0.80
        case .moderate: return 0.70
        case .aggressive: return 0.60
        }
    }
}

// MARK: - Entity Type Flags

struct EntityTypeFlags {
    static let character: Int = 1 << 0       // 1
    static let location: Int = 1 << 1        // 2
    static let building: Int = 1 << 2        // 4
    static let artifact: Int = 1 << 3        // 8
    static let vehicle: Int = 1 << 4         // 16
    static let organization: Int = 1 << 5    // 32
    static let event: Int = 1 << 6           // 64
    static let historicalEvent: Int = 1 << 7 // 128
    static let other: Int = 1 << 8           // 256

    static let all: Int = character | location | building | artifact |
                          vehicle | organization | event | historicalEvent | other

    static func flag(for type: EntityType) -> Int {
        switch type {
        case .character: return character
        case .location: return location
        case .building: return building
        case .artifact: return artifact
        case .vehicle: return vehicle
        case .organization: return organization
        case .event: return event
        case .historicalEvent: return historicalEvent
        case .other: return other
        }
    }

    static func entityType(for flag: Int) -> EntityType? {
        switch flag {
        case character: return .character
        case location: return .location
        case building: return .building
        case artifact: return .artifact
        case vehicle: return .vehicle
        case organization: return .organization
        case event: return .event
        case historicalEvent: return .historicalEvent
        case other: return .other
        default: return nil
        }
    }
}

// MARK: - Settings Validation

extension AISettings {
    /// Validate current settings
    /// Returns nil if valid, error message if invalid
    func validate() -> String? {
        // Confidence threshold must be 0.0 to 1.0
        if confidenceThreshold < 0.0 || confidenceThreshold > 1.0 {
            return "Confidence threshold must be between 0.0 and 1.0"
        }

        // History limit must be positive
        if imageHistoryLimit < 0 {
            return "Image history limit must be non-negative"
        }

        // Min word counts must be positive
        if autoGenerateMinWords < 1 {
            return "Auto-generate minimum words must be positive"
        }

        if analysisMinWordCount < 1 {
            return "Analysis minimum word count must be positive"
        }

        return nil // Valid
    }

    /// Check if settings are valid
    var isValid: Bool {
        validate() == nil
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension AISettings {
    /// Print current settings (Debug only)
    func printSettings() {
        print("""

        🔧 [AISettings] Current Settings:
        Analysis Provider: \(analysisProvider)
        Image Generation Provider: \(imageGenerationProvider)
        AI Enabled: \(aiEnabled)

        Image Generation:
        - Auto-generate: \(autoGenerateImages)
        - Min words: \(autoGenerateMinWords)
        - History limit: \(imageHistoryLimit)
        - Show overlay: \(alwaysShowAttributionOverlay)

        Content Analysis:
        - Enabled: \(analysisEnabled)
        - Scope: \(analysisScope)
        - Confidence: \(confidenceThreshold)
        - Min words: \(analysisMinWordCount)
        - Learning: \(enableLearning)

        """)
    }
}
#endif
