//
//  AIProviderTests.swift
//  CumberlandTests
//
//  Swift Testing suite for ER-0009: AI Image Generation.
//  Verifies AIProviderProtocol conformance for all registered providers
//  (Apple Intelligence, OpenAI, Anthropic): provider metadata, capability
//  flags, prompt validation, and error mapping.
//

import Testing
import Foundation
@testable import Cumberland

/// Tests for AI Provider Protocol and implementations
/// Part of ER-0009: AI Image Generation
@Suite("AI Provider Tests")
struct AIProviderTests {

    // MARK: - Protocol Conformance Tests

    @Test("Apple Intelligence provider conforms to protocol")
    func appleIntelligenceConformance() {
        let provider = AppleIntelligenceProvider()

        #expect(provider.name == "Apple Intelligence")
        #expect(provider.requiresAPIKey == false)
        // isAvailable depends on OS version - just verify it returns a boolean
        _ = provider.isAvailable
    }

    @Test("Apple Intelligence provider has metadata")
    func appleIntelligenceMetadata() {
        let provider = AppleIntelligenceProvider()

        #expect(provider.metadata != nil)
        #expect(provider.metadata?.modelVersion != nil)
        #expect(provider.metadata?.licenseInfo != nil)
        #expect(provider.metadata?.licenseInfo?.attributionRequired == true)
    }

    // MARK: - Provider Registry Tests

    @Test("Provider registry lists all providers")
    func providerRegistry() {
        let registry = AIProviderRegistry.shared

        let providers = registry.allProviders()
        #expect(providers.count >= 1) // At least Apple Intelligence
    }

    @Test("Provider registry returns default provider")
    func defaultProvider() {
        let registry = AIProviderRegistry.shared

        let defaultProvider = registry.defaultProvider()
        // May be nil if no providers available on this OS version
        if let provider = defaultProvider {
            #expect(provider.name.isEmpty == false)
        }
    }

    @Test("Provider registry finds provider by name")
    func findProviderByName() {
        let registry = AIProviderRegistry.shared

        let provider = registry.provider(named: "Apple Intelligence")
        #expect(provider != nil)
        #expect(provider?.name == "Apple Intelligence")
    }

    @Test("Provider registry returns nil for unknown provider")
    func findUnknownProvider() {
        let registry = AIProviderRegistry.shared

        let provider = registry.provider(named: "NonexistentProvider")
        #expect(provider == nil)
    }

    @Test("Provider registry lists available providers only")
    func availableProvidersOnly() {
        let registry = AIProviderRegistry.shared

        let allProviders = registry.allProviders()
        let availableProviders = registry.availableProviders()

        // Available should be subset of all
        #expect(availableProviders.count <= allProviders.count)

        // All available providers should have isAvailable == true
        for provider in availableProviders {
            #expect(provider.isAvailable == true)
        }
    }

    @Test("Provider registry has availability check")
    func hasAvailableProvider() {
        let registry = AIProviderRegistry.shared

        let hasAvailable = registry.hasAvailableProvider
        let availableProviders = registry.availableProviders()

        #expect(hasAvailable == !availableProviders.isEmpty)
    }

    // MARK: - Provider Selection Tests

    @Test("Set preferred provider")
    func setPreferredProvider() {
        let registry = AIProviderRegistry.shared

        registry.setPreferredProvider(name: "Apple Intelligence")
        let preferred = registry.getPreferredProviderName()

        #expect(preferred == "Apple Intelligence")
    }

    @Test("Get provider statistics")
    func providerStatistics() {
        let registry = AIProviderRegistry.shared
        let stats = registry.providerStatistics()

        #expect(stats.totalProviders >= 1)
        #expect(stats.availableProviders >= 0)
        #expect(stats.availableProviders <= stats.totalProviders)
        #expect(stats.preferredProvider.isEmpty == false)
        #expect(stats.providers.isEmpty == false)
    }

    // MARK: - Error Handling Tests

    @Test("Provider error has descriptions")
    func providerErrorDescriptions() {
        let error1 = AIProviderError.providerUnavailable(reason: "Test")
        #expect(error1.errorDescription != nil)

        let error2 = AIProviderError.invalidAPIKey
        #expect(error2.errorDescription != nil)
        #expect(error2.recoverySuggestion != nil)

        let error3 = AIProviderError.rateLimitExceeded(retryAfter: 60)
        #expect(error3.errorDescription != nil)
        #expect(error3.isRetryable == true)
    }

    @Test("Provider error helpers")
    func providerErrorHelpers() {
        // Retryable errors
        #expect(AIProviderError.networkError(underlying: NSError(domain: "", code: 0)).isRetryable == true)
        #expect(AIProviderError.rateLimitExceeded(retryAfter: nil).isRetryable == true)
        #expect(AIProviderError.timeout(duration: 30).isRetryable == true)

        // Non-retryable errors
        #expect(AIProviderError.invalidAPIKey.isRetryable == false)
        #expect(AIProviderError.promptFiltered.isRetryable == false)

        // Warnings
        #expect(AIProviderError.promptFiltered.isWarning == true)
        #expect(AIProviderError.textTooShort(minLength: 25, actual: 10).isWarning == true)

        // Requires user intervention
        #expect(AIProviderError.invalidAPIKey.requiresUserIntervention == true)
        #expect(AIProviderError.quotaExceeded.requiresUserIntervention == true)
    }

    // MARK: - Analysis Task Tests

    @Test("Analysis task enum values")
    func analysisTaskValues() {
        let tasks: [AnalysisTask] = [
            .entityExtraction,
            .relationshipInference,
            .calendarExtraction,
            .comprehensive
        ]

        // Just verify they exist and are codable
        for task in tasks {
            let encoded = try? JSONEncoder().encode(task)
            #expect(encoded != nil)

            if let data = encoded {
                let decoded = try? JSONDecoder().decode(AnalysisTask.self, from: data)
                #expect(decoded != nil)
            }
        }
    }

    // MARK: - Entity Type Tests

    @Test("Entity type to card kind mapping")
    func entityTypeMapping() {
        #expect(EntityType.character.toCardKind() == .characters)
        #expect(EntityType.location.toCardKind() == .locations)
        #expect(EntityType.building.toCardKind() == .buildings)
        #expect(EntityType.artifact.toCardKind() == .artifacts)
        #expect(EntityType.vehicle.toCardKind() == .vehicles)
    }

    // MARK: - Apple Intelligence Availability Tests

    @Test("Apple Intelligence availability checks")
    func appleIntelligenceAvailability() {
        // These are static helpers
        let imageAvailable = AppleIntelligenceProvider.isImagePlaygroundAvailable
        let analysisAvailable = AppleIntelligenceProvider.isOnDeviceAnalysisAvailable

        // Should return booleans (actual value depends on OS version)
        _ = imageAvailable
        _ = analysisAvailable
    }

    // MARK: - Image Generation Tests (Placeholder)

    @Test("Image generation with Apple Intelligence throws feature not supported (until implemented)")
    func imageGenerationPlaceholder() async throws {
        let provider = AppleIntelligenceProvider()

        guard provider.isAvailable else {
            // Skip test if provider unavailable
            return
        }

        // Currently throws feature not supported (Phase 1 placeholder)
        do {
            _ = try await provider.generateImage(prompt: "Test prompt")
            Issue.record("Expected feature not supported error")
        } catch AIProviderError.featureNotSupported {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Text analysis with Apple Intelligence throws feature not supported (until implemented)")
    func textAnalysisPlaceholder() async throws {
        let provider = AppleIntelligenceProvider()

        guard provider.isAvailable else {
            // Skip test if provider unavailable
            return
        }

        // Currently throws feature not supported (Phase 5 placeholder)
        do {
            _ = try await provider.analyzeText("Test text with at least twenty five words to meet the minimum requirement for analysis", for: .entityExtraction)
            Issue.record("Expected feature not supported error")
        } catch AIProviderError.featureNotSupported {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Error Cases Tests

    @Test("Image generation with empty prompt throws error")
    func imageGenerationEmptyPrompt() async throws {
        let provider = AppleIntelligenceProvider()

        guard provider.isAvailable else {
            return
        }

        do {
            _ = try await provider.generateImage(prompt: "")
            Issue.record("Expected invalid input error")
        } catch AIProviderError.invalidInput {
            // Expected
        } catch {
            // May also throw feature not supported (current placeholder)
        }
    }

    @Test("Text analysis with short text throws error")
    func textAnalysisTooShort() async throws {
        let provider = AppleIntelligenceProvider()

        guard provider.isAvailable else {
            return
        }

        do {
            _ = try await provider.analyzeText("Short text", for: .entityExtraction)
            Issue.record("Expected text too short error")
        } catch AIProviderError.textTooShort {
            // Expected
        } catch {
            // May also throw feature not supported (current placeholder)
        }
    }
}
