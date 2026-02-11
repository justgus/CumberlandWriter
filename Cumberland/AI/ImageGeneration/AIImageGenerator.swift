//
//  AIImageGenerator.swift
//  Cumberland
//
//  Created by Claude Code on 1/21/26.
//  ER-0009: AI Image Generation for Cards
//

import Foundation
import SwiftUI
import OSLog

/// Service for generating images from text prompts using AI providers
/// Part of ER-0009: AI Image Generation MVP
@Observable
final class AIImageGenerator {

    // MARK: - Properties

    /// Current generation state
    enum GenerationState {
        case idle
        case generating(progress: Double)
        case completed(image: Image, data: Data)
        case failed(error: AIProviderError)
    }

    /// Current state of the generator
    private(set) var state: GenerationState = .idle

    /// The AI provider registry
    private let providerRegistry: AIProviderRegistry

    /// Logger for debugging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "AIImageGenerator")

    // MARK: - Initialization

    init(providerRegistry: AIProviderRegistry = .shared) {
        self.providerRegistry = providerRegistry
    }

    // MARK: - Public API

    /// Generate an image from a text prompt
    /// - Parameters:
    ///   - prompt: The text description of the image to generate
    ///   - provider: Optional specific provider to use (defaults to current provider)
    /// - Returns: Tuple of (SwiftUI Image, raw Data) for display and storage
    func generateImage(
        prompt: String,
        provider: String? = nil
    ) async throws -> (image: Image, data: Data) {

        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIProviderError.invalidInput(reason: "Prompt cannot be empty")
        }

        // Update state to generating
        await MainActor.run {
            self.state = .generating(progress: 0.0)
        }

        logger.info("Starting image generation with prompt: '\(prompt)'")

        do {
            // Get the provider
            let providerToUse: any AIProviderProtocol
            if let providerName = provider {
                guard let p = providerRegistry.provider(named: providerName) else {
                    throw AIProviderError.providerUnavailable(reason: "Provider '\(providerName)' not found")
                }
                providerToUse = p
            } else {
                guard let p = providerRegistry.defaultProvider() else {
                    throw AIProviderError.providerUnavailable(reason: "No AI providers available")
                }
                providerToUse = p
            }

            logger.debug("Using provider: \(providerToUse.name)")

            // Simulate progress updates (actual progress would come from provider callbacks)
            Task { @MainActor in
                self.state = .generating(progress: 0.3)
            }

            // Generate the image
            let imageData = try await providerToUse.generateImage(prompt: prompt)

            guard !imageData.isEmpty else {
                throw AIProviderError.invalidResponse(reason: "Provider returned empty image data")
            }

            // Convert to SwiftUI Image
            guard let image = convertDataToImage(imageData) else {
                throw AIProviderError.invalidResponse(reason: "Could not create image from provider data")
            }

            logger.info("Image generation completed successfully")

            // Update state to completed
            await MainActor.run {
                self.state = .completed(image: image, data: imageData)
            }

            return (image: image, data: imageData)

        } catch let error as AIProviderError {
            logger.error("Image generation failed: \(error.localizedDescription)")
            await MainActor.run {
                self.state = .failed(error: error)
            }
            throw error
        } catch {
            let providerError = AIProviderError.unknown(underlying: error)
            logger.error("Image generation failed with unexpected error: \(error.localizedDescription)")
            await MainActor.run {
                self.state = .failed(error: providerError)
            }
            throw providerError
        }
    }

    /// Reset the generator state to idle
    func reset() {
        state = .idle
    }

    // MARK: - Private Helpers

    /// Convert raw image data to SwiftUI Image
    private func convertDataToImage(_ data: Data) -> Image? {
        #if os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #else
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #endif
    }
}

// MARK: - Convenience Extensions

extension AIImageGenerator {

    /// Check if generation is currently in progress
    var isGenerating: Bool {
        if case .generating = state {
            return true
        }
        return false
    }

    /// Get current progress (0.0 to 1.0) if generating
    var progress: Double? {
        if case .generating(let progress) = state {
            return progress
        }
        return nil
    }

    /// Get the generated image if completed
    var generatedImage: Image? {
        if case .completed(let image, _) = state {
            return image
        }
        return nil
    }

    /// Get the generated image data if completed
    var generatedImageData: Data? {
        if case .completed(_, let data) = state {
            return data
        }
        return nil
    }

    /// Get the error if failed
    var error: AIProviderError? {
        if case .failed(let error) = state {
            return error
        }
        return nil
    }
}
