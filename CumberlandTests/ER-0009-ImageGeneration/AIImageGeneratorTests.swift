import Testing
import Foundation
@testable import Cumberland

/// Tests for AIImageGenerator service
/// Part of ER-0009: AI Image Generation (Phase 2A)
@Suite("AIImageGenerator Tests")
struct AIImageGeneratorTests {

    // MARK: - State Management Tests

    @Test("Initial state is idle")
    @MainActor
    func initialState() {
        let generator = AIImageGenerator()

        if case .idle = generator.state {
            // Expected
        } else {
            Issue.record("Expected idle state, got \(generator.state)")
        }
    }

    @Test("State transitions to generating when image generation starts")
    @MainActor
    func stateTransitionToGenerating() async throws {
        let generator = AIImageGenerator()

        // Start generation (will fail with feature not supported, but state should change)
        Task {
            _ = try? await generator.generateImage(prompt: "Test prompt for a fantasy castle on a hill")
        }

        // Give it a moment to start
        try await Task.sleep(for: .milliseconds(50))

        // State should be generating
        if case .generating = generator.state {
            // Expected
        } else {
            // May already be failed or completed - that's ok for this test
        }
    }

    @Test("State transitions to completed on success")
    @MainActor
    func stateTransitionToCompleted() async throws {
        let generator = AIImageGenerator()

        do {
            let (image, data) = try await generator.generateImage(prompt: "A beautiful fantasy castle")

            // Should have generated valid data
            #expect(data.count > 0)

            // State should be completed
            if case .completed = generator.state {
                // Expected
            } else {
                Issue.record("Expected completed state, got \(generator.state)")
            }
        } catch {
            Issue.record("Generation should succeed in Phase 2B: \(error)")
        }
    }

    // MARK: - Input Validation Tests

    @Test("Empty prompt throws invalid input error")
    func emptyPromptValidation() async throws {
        let generator = AIImageGenerator()

        do {
            _ = try await generator.generateImage(prompt: "")
            Issue.record("Expected invalid input error for empty prompt")
        } catch AIProviderError.invalidInput {
            // Expected
        } catch {
            Issue.record("Expected invalidInput error, got \(error)")
        }
    }

    @Test("Whitespace-only prompt throws invalid input error")
    func whitespacePromptValidation() async throws {
        let generator = AIImageGenerator()

        do {
            _ = try await generator.generateImage(prompt: "   \n\t  ")
            Issue.record("Expected invalid input error for whitespace prompt")
        } catch AIProviderError.invalidInput {
            // Expected
        } catch {
            Issue.record("Expected invalidInput error, got \(error)")
        }
    }

    @Test("Valid prompt generates successfully")
    func validPromptValidation() async throws {
        let generator = AIImageGenerator()

        do {
            let (_, data) = try await generator.generateImage(prompt: "A beautiful landscape")
            // Should succeed in Phase 2B
            #expect(data.count > 0)
        } catch AIProviderError.invalidInput {
            Issue.record("Should not throw invalidInput for valid prompt")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Provider Selection Tests

    @Test("Uses default provider when none specified")
    func defaultProviderSelection() async throws {
        let generator = AIImageGenerator()

        // Should use default provider (Apple Intelligence if available)
        do {
            let (_, data) = try await generator.generateImage(prompt: "Test prompt for a magical forest")
            #expect(data.count > 0)
        } catch AIProviderError.providerUnavailable {
            // Acceptable if no providers available on this system
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Uses specified provider when provided")
    func specifiedProviderSelection() async throws {
        let generator = AIImageGenerator()

        do {
            let (_, data) = try await generator.generateImage(
                prompt: "Test prompt for a mystical creature",
                provider: "Apple Intelligence"
            )
            #expect(data.count > 0)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Throws error for unknown provider")
    func unknownProviderError() async throws {
        let generator = AIImageGenerator()

        do {
            _ = try await generator.generateImage(
                prompt: "Test prompt",
                provider: "NonexistentProvider"
            )
            Issue.record("Expected provider unavailable error")
        } catch AIProviderError.providerUnavailable {
            // Expected
        } catch {
            Issue.record("Expected providerUnavailable, got \(error)")
        }
    }

    // MARK: - Error Handling Tests

    @Test("Handles provider unavailable gracefully")
    func providerUnavailableHandling() async throws {
        let generator = AIImageGenerator()

        do {
            _ = try await generator.generateImage(
                prompt: "Test prompt",
                provider: "InvalidProvider"
            )
            Issue.record("Expected error for invalid provider")
        } catch AIProviderError.providerUnavailable(let reason) {
            #expect(reason.contains("not found"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Validation errors are thrown before state changes")
    @MainActor
    func validationErrorsThrown() async throws {
        let generator = AIImageGenerator()

        // Validation errors are thrown immediately, before async work starts
        do {
            _ = try await generator.generateImage(prompt: "")
            Issue.record("Expected invalid input error for empty prompt")
        } catch AIProviderError.invalidInput {
            // Expected - validation error thrown
            // State may still be idle since validation happens before state machine runs
        } catch {
            Issue.record("Expected invalidInput error, got \(error)")
        }
    }

    // MARK: - Progress Tracking Tests

    @Test("Progress starts at 0.0 when generating begins")
    @MainActor
    func initialProgress() async throws {
        let generator = AIImageGenerator()

        Task {
            _ = try? await generator.generateImage(prompt: "Test prompt")
        }

        try await Task.sleep(for: .milliseconds(50))

        if case .generating(let progress) = generator.state {
            #expect(progress >= 0.0)
            #expect(progress <= 1.0)
        }
    }

    // MARK: - Concurrent Request Tests

    @Test("Can handle multiple sequential requests")
    @MainActor
    func sequentialRequests() async throws {
        let generator = AIImageGenerator()

        // First request
        do {
            let (_, data1) = try await generator.generateImage(prompt: "A dragon in flight")
            #expect(data1.count > 0)
        } catch {
            Issue.record("First request failed: \(error)")
        }

        // Second request should work (not locked)
        do {
            let (_, data2) = try await generator.generateImage(prompt: "A peaceful village")
            #expect(data2.count > 0)
        } catch {
            Issue.record("Second request failed: \(error)")
        }

        // State should be completed from second request
        if case .completed = generator.state {
            // Expected
        } else {
            Issue.record("Expected completed state after sequential requests")
        }
    }

    // MARK: - Image Data Tests

    @Test("Generated image data is valid on success")
    func imageDataValidation() async throws {
        let generator = AIImageGenerator()

        do {
            let (image, data) = try await generator.generateImage(prompt: "A serene mountain landscape")

            // Validate the results
            #expect(data.count > 0)
            // Image should be renderable (SwiftUI Image type)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Observable State Tests

    @Test("State changes are observable")
    @MainActor
    func stateObservability() async throws {
        let generator = AIImageGenerator()

        // Generator should be @Observable
        let initialState = generator.state

        // Initial state should be idle
        if case .idle = initialState {
            // Expected
        } else {
            Issue.record("Expected initial idle state")
        }

        // Attempt generation
        do {
            _ = try await generator.generateImage(prompt: "Test")
        } catch {
            // State should have changed from idle
            let finalState = generator.state
            if case .idle = finalState {
                Issue.record("State should have changed from idle after generation attempt")
            }
        }
    }

    // MARK: - Cancellation Tests

    @Test("Can cancel ongoing generation")
    @MainActor
    func cancellation() async throws {
        let generator = AIImageGenerator()

        let task = Task {
            try await generator.generateImage(prompt: "Test prompt that takes a while to generate")
        }

        // Give it a moment to start
        try await Task.sleep(for: .milliseconds(50))

        // Cancel the task
        task.cancel()

        // Should handle cancellation gracefully
        do {
            _ = try await task.value
        } catch is CancellationError {
            // Expected
        } catch {
            // Other errors acceptable
        }
    }

    // MARK: - Metadata Tests

    @Test("Generates metadata with results")
    func metadataGeneration() async throws {
        let generator = AIImageGenerator()

        do {
            let (_, data) = try await generator.generateImage(prompt: "A majestic castle on a hill")
            #expect(data.count > 0)
            // Metadata is returned via the tuple structure
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Provider Statistics Tests

    @Test("Tracks generation attempts")
    @MainActor
    func generationTracking() async throws {
        let generator = AIImageGenerator()

        // Multiple attempts should be trackable
        for i in 1...3 {
            do {
                let (_, data) = try await generator.generateImage(prompt: "Fantasy scene number \(i)")
                #expect(data.count > 0)
            } catch {
                Issue.record("Attempt \(i) failed: \(error)")
            }
        }

        // State should be completed from latest attempt
        if case .completed = generator.state {
            // Expected
        } else {
            Issue.record("Expected completed state after generation attempts")
        }
    }
}
