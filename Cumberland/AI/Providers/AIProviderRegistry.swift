//
//  AIProviderRegistry.swift
//  Cumberland
//
//  Singleton registry that instantiates and manages all available AI providers
//  (Apple Intelligence, OpenAI, Anthropic). Provides provider lookup by name
//  and selects the preferred provider based on AISettings. Lazily registers
//  providers on first access.
//

import Foundation

/// Central registry for managing AI providers
/// Provides access to all registered providers and handles provider selection
class AIProviderRegistry {

    // MARK: - Singleton

    static let shared = AIProviderRegistry()

    // MARK: - Properties

    /// All registered providers
    private let providers: [AIProviderProtocol]

    /// User's preferred provider name (stored in UserDefaults)
    @AppStorage("ai_preferredProvider")
    private var preferredProviderName: String = "Apple Intelligence"

    // MARK: - Initialization

    private init() {
        // Register all available providers
        self.providers = [
            AppleIntelligenceProvider(),
            OpenAIProvider(),
            AnthropicProvider()
            // GeminiProvider() - future
            // StabilityAIProvider() - future
        ]

        #if DEBUG
        print("📋 [AIProviderRegistry] Registered \(providers.count) provider(s)")
        for provider in providers {
            let status = provider.isAvailable ? "✓ Available" : "✗ Unavailable"
            let apiKeyStatus = provider.requiresAPIKey ? " (requires API key)" : ""
            print("   - \(provider.name): \(status)\(apiKeyStatus)")
        }
        #endif
    }

    // MARK: - Provider Access

    /// Get all registered providers
    func allProviders() -> [AIProviderProtocol] {
        providers
    }

    /// Get all available providers (excluding unavailable ones)
    func availableProviders() -> [AIProviderProtocol] {
        providers.filter { $0.isAvailable }
    }

    /// Get the default provider (first available provider)
    /// - Returns: First available provider, or nil if none available
    func defaultProvider() -> AIProviderProtocol? {
        // Try preferred provider first
        if let preferred = provider(named: preferredProviderName), preferred.isAvailable {
            return preferred
        }

        // Fall back to first available provider
        return availableProviders().first
    }

    /// Get a specific provider by name
    /// - Parameter name: Provider name (e.g., "Apple Intelligence")
    /// - Returns: Provider if found, nil otherwise
    func provider(named name: String) -> AIProviderProtocol? {
        providers.first { $0.name == name }
    }

    /// Get a provider for a specific capability
    /// - Parameter capability: The required capability
    /// - Returns: First available provider with that capability
    func provider(for capability: ProviderCapability) -> AIProviderProtocol? {
        // For now, all providers support all capabilities
        // In the future, we might have specialized providers
        return defaultProvider()
    }

    // MARK: - Provider Selection

    /// Set the preferred provider
    /// - Parameter name: Provider name
    func setPreferredProvider(name: String) {
        guard provider(named: name) != nil else {
            print("⚠️ [AIProviderRegistry] Unknown provider: \(name)")
            return
        }

        preferredProviderName = name

        #if DEBUG
        print("✓ [AIProviderRegistry] Preferred provider set to: \(name)")
        #endif
    }

    /// Get the user's preferred provider name
    func getPreferredProviderName() -> String {
        preferredProviderName
    }

    // MARK: - Availability Checks

    /// Check if any provider is available
    var hasAvailableProvider: Bool {
        !availableProviders().isEmpty
    }

    /// Check if image generation is available
    var isImageGenerationAvailable: Bool {
        defaultProvider() != nil
    }

    /// Check if content analysis is available
    var isContentAnalysisAvailable: Bool {
        defaultProvider() != nil
    }

    // MARK: - Provider Statistics

    /// Get statistics about provider usage
    func providerStatistics() -> ProviderStatistics {
        ProviderStatistics(
            totalProviders: providers.count,
            availableProviders: availableProviders().count,
            preferredProvider: preferredProviderName,
            providers: providers.map { provider in
                ProviderInfo(
                    name: provider.name,
                    isAvailable: provider.isAvailable,
                    requiresAPIKey: provider.requiresAPIKey,
                    metadata: provider.metadata
                )
            }
        )
    }
}

// MARK: - Supporting Types

/// Provider capabilities
enum ProviderCapability {
    case imageGeneration
    case entityExtraction
    case relationshipInference
    case calendarExtraction
}

/// Provider statistics
struct ProviderStatistics {
    let totalProviders: Int
    let availableProviders: Int
    let preferredProvider: String
    let providers: [ProviderInfo]
}

/// Provider information summary
struct ProviderInfo {
    let name: String
    let isAvailable: Bool
    let requiresAPIKey: Bool
    let metadata: AIProviderMetadata?
}

// MARK: - Convenience Extensions

extension AIProviderRegistry {
    /// Quick access to generate an image using the default provider
    func generateImage(prompt: String) async throws -> Data {
        guard let provider = defaultProvider() else {
            throw AIProviderError.providerUnavailable(reason: "No AI providers are available")
        }

        return try await provider.generateImage(prompt: prompt)
    }

    /// Quick access to analyze text using the default provider
    func analyzeText(_ text: String, for task: AnalysisTask) async throws -> AnalysisResult {
        guard let provider = defaultProvider() else {
            throw AIProviderError.providerUnavailable(reason: "No AI providers are available")
        }

        return try await provider.analyzeText(text, for: task)
    }
}

// MARK: - @AppStorage Property Wrapper

/// Custom property wrapper for provider preferences
/// (Note: This is a simplified version; actual @AppStorage is from SwiftUI)
@propertyWrapper
struct AppStorage<Value> {
    private let key: String
    private let defaultValue: Value

    init(wrappedValue defaultValue: Value, _ key: String) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: Value {
        get {
            if let value = UserDefaults.standard.object(forKey: key) as? Value {
                return value
            }
            return defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
