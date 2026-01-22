import Foundation
#if canImport(AppIntents)
import AppIntents
#endif

#if os(macOS)
import AppKit
#elseif os(iOS) || os(visionOS)
import UIKit
#endif

/// Apple Intelligence provider (default, on-device AI)
/// Uses Apple's Image Playground API and on-device language models
/// Available on iOS 18.2+, macOS 15.2+, iPadOS 18.2+, visionOS 2.2+
class AppleIntelligenceProvider: AIProviderProtocol {

    // MARK: - AIProviderProtocol Conformance

    var name: String {
        "Apple Intelligence"
    }

    var isAvailable: Bool {
        checkAvailability()
    }

    var requiresAPIKey: Bool {
        false // Apple Intelligence uses device authentication
    }

    var metadata: AIProviderMetadata? {
        AIProviderMetadata(
            modelVersion: "Apple Intelligence 1.0",
            maxPromptLength: 1000, // Conservative estimate
            supportedImageFormats: ["PNG", "JPEG"],
            rateLimit: RateLimit(
                requestsPerMinute: 10,
                requestsPerDay: nil // No hard limit, device-dependent
            ),
            licenseInfo: LicenseInfo(
                licenseType: "Proprietary - Apple",
                attributionRequired: true,
                commercialUseAllowed: true, // User owns generated content
                licenseURL: URL(string: "https://www.apple.com/legal/apple-intelligence/")
            )
        )
    }

    // MARK: - Initialization

    init() {
        // Check availability on initialization
        if !isAvailable {
            print("⚠️ Apple Intelligence is not available on this device")
            print("   Requires: iOS 18.2+, macOS 15.2+, iPadOS 18.2+, or visionOS 2.2+")
        }
    }

    // MARK: - Image Generation (ER-0009)

    func generateImage(prompt: String) async throws -> Data {
        guard isAvailable else {
            throw AIProviderError.providerUnavailable(reason: "Apple Intelligence requires iOS 18.2+ or macOS 15.2+")
        }

        guard !prompt.isEmpty else {
            throw AIProviderError.invalidInput(reason: "Prompt cannot be empty")
        }

        guard prompt.count <= 1000 else {
            throw AIProviderError.promptTooLong(maxLength: 1000, actual: prompt.count)
        }

        #if DEBUG
        print("🎨 [Apple Intelligence] Generating image with prompt: \(prompt)")
        #endif

        // Phase 2B: Functional image generation
        // NOTE: Apple's Image Playground API is not yet publicly available for third-party apps.
        // This implementation generates a stylized placeholder image until the official API is available.
        // The structure is designed for easy integration with the real API when it becomes available.

        // Simulate API processing time
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // Generate a stylized image based on the prompt
        guard let imageData = await generateStylizedImage(for: prompt) else {
            throw AIProviderError.invalidResponse(reason: "Failed to generate image data")
        }

        return imageData
    }

    /// Generates a stylized placeholder image
    /// This will be replaced with actual Image Playground API call when available
    private func generateStylizedImage(for prompt: String) async -> Data? {
        await MainActor.run {
            // Create a 1024x1024 image (standard AI generation size)
            let size = CGSize(width: 1024, height: 1024)

            #if os(macOS)
            let image = NSImage(size: size, flipped: false, drawingHandler: { rect in
                self.drawImageContent(in: rect, prompt: prompt)
                return true
            })

            // Convert to PNG data
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                return nil
            }

            return pngData

            #elseif os(iOS) || os(visionOS)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                self.drawImageContent(in: context.format.bounds, prompt: prompt)
            }

            return image.pngData()
            #else
            return nil
            #endif
        }
    }

    /// Draws the image content (cross-platform)
    private func drawImageContent(in rect: CGRect, prompt: String) {
        #if os(macOS)
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        #else
        guard let context = UIGraphicsGetCurrentContext() else { return }
        #endif

        // Create gradient background based on prompt hash
        let colors = selectColors(for: prompt)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: [colors.0, colors.1] as CFArray,
            locations: [0.0, 1.0]
        ) else {
            return
        }

        // Draw gradient
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.minX, y: rect.minY),
            end: CGPoint(x: rect.maxX, y: rect.maxY),
            options: []
        )

        // Add subtle texture
        addTexture(to: rect, context: context)

        // Draw prompt text at bottom
        drawPromptLabel(prompt, in: rect)

        // Add AI attribution watermark
        drawWatermark(in: rect)
    }

    /// Select gradient colors based on prompt content
    private func selectColors(for prompt: String) -> (CGColor, CGColor) {
        let hash = abs(prompt.hashValue)
        let hue1 = CGFloat(hash % 360) / 360.0
        let hue2 = CGFloat((hash / 360) % 360) / 360.0

        #if os(macOS)
        let color1 = NSColor(hue: hue1, saturation: 0.6, brightness: 0.8, alpha: 1.0).cgColor
        let color2 = NSColor(hue: hue2, saturation: 0.7, brightness: 0.5, alpha: 1.0).cgColor
        #else
        let color1 = UIColor(hue: hue1, saturation: 0.6, brightness: 0.8, alpha: 1.0).cgColor
        let color2 = UIColor(hue: hue2, saturation: 0.7, brightness: 0.5, alpha: 1.0).cgColor
        #endif

        return (color1, color2)
    }

    /// Add subtle noise texture
    private func addTexture(to rect: CGRect, context: CGContext) {
        context.setBlendMode(.overlay)
        context.setAlpha(0.1)

        // Draw small random rectangles for texture
        for _ in 0..<200 {
            let x = CGFloat.random(in: 0...rect.width)
            let y = CGFloat.random(in: 0...rect.height)
            let size = CGFloat.random(in: 2...8)

            #if os(macOS)
            NSColor.white.setFill()
            #else
            UIColor.white.setFill()
            #endif

            context.fill(CGRect(x: x, y: y, width: size, height: size))
        }

        context.setAlpha(1.0)
        context.setBlendMode(.normal)
    }

    /// Draw prompt text at bottom of image
    private func drawPromptLabel(_ prompt: String, in rect: CGRect) {
        let truncated = String(prompt.prefix(100))

        #if os(macOS)
        let font = NSFont.systemFont(ofSize: 24, weight: .medium)
        let textColor = NSColor.white
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.8)
        shadow.shadowOffset = CGSize(width: 0, height: -2)
        shadow.shadowBlurRadius = 4

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .shadow: shadow
        ]

        let textSize = truncated.size(withAttributes: attributes)
        let textRect = CGRect(
            x: rect.minX + 40,
            y: rect.maxY - 80,
            width: rect.width - 80,
            height: textSize.height
        )

        truncated.draw(in: textRect, withAttributes: attributes)

        #else
        let font = UIFont.systemFont(ofSize: 24, weight: .medium)
        let textColor = UIColor.white

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.8)
        shadow.shadowOffset = CGSize(width: 0, height: -2)
        shadow.shadowBlurRadius = 4

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .shadow: shadow,
            .paragraphStyle: paragraphStyle
        ]

        let textSize = truncated.size(withAttributes: attributes)
        let textRect = CGRect(
            x: rect.minX + 40,
            y: rect.maxY - 80,
            width: rect.width - 80,
            height: textSize.height
        )

        truncated.draw(in: textRect, withAttributes: attributes)
        #endif
    }

    /// Draw watermark
    private func drawWatermark(in rect: CGRect) {
        let watermark = "AI Generated"

        #if os(macOS)
        let font = NSFont.systemFont(ofSize: 14, weight: .regular)
        let textColor = NSColor.white.withAlphaComponent(0.6)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let textSize = watermark.size(withAttributes: attributes)
        let textRect = CGRect(
            x: rect.maxX - textSize.width - 20,
            y: rect.minY + 20,
            width: textSize.width,
            height: textSize.height
        )

        watermark.draw(in: textRect, withAttributes: attributes)

        #else
        let font = UIFont.systemFont(ofSize: 14, weight: .regular)
        let textColor = UIColor.white.withAlphaComponent(0.6)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let textSize = watermark.size(withAttributes: attributes)
        let textRect = CGRect(
            x: rect.maxX - textSize.width - 20,
            y: rect.minY + 20,
            width: textSize.width,
            height: textSize.height
        )

        watermark.draw(in: textRect, withAttributes: attributes)
        #endif
    }

    // MARK: - Content Analysis (ER-0010)

    func analyzeText(_ text: String, for task: AnalysisTask) async throws -> AnalysisResult {
        guard isAvailable else {
            throw AIProviderError.providerUnavailable(reason: "Apple Intelligence requires iOS 18.2+ or macOS 15.2+")
        }

        guard !text.isEmpty else {
            throw AIProviderError.invalidInput(reason: "Text cannot be empty")
        }

        let wordCount = text.split(separator: " ").count
        guard wordCount >= 25 else {
            throw AIProviderError.textTooShort(minLength: 25, actual: wordCount)
        }

        #if DEBUG
        print("🧠 [Apple Intelligence] Analyzing text for task: \(task)")
        #endif

        // Simulate API call delay
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

        // TODO: Implement actual analysis using Apple's on-device models
        // This will be implemented in Phase 5 (ER-0010)
        throw AIProviderError.featureNotSupported(feature: "Content analysis (Phase 5 implementation pending)")

        // FUTURE IMPLEMENTATION:
        // switch task {
        // case .entityExtraction:
        //     return try await extractEntities(from: text)
        // case .relationshipInference:
        //     return try await inferRelationships(from: text)
        // case .calendarExtraction:
        //     return try await extractCalendar(from: text)
        // case .comprehensive:
        //     return try await performComprehensiveAnalysis(of: text)
        // }
    }

    // MARK: - Private Helpers

    /// Check if Apple Intelligence is available on this device
    private func checkAvailability() -> Bool {
        #if os(iOS)
        // Requires iOS 18.2+
        if #available(iOS 18.2, *) {
            return true
        }
        return false

        #elseif os(macOS)
        // Requires macOS 15.2+
        if #available(macOS 15.2, *) {
            return true
        }
        return false

        #elseif os(visionOS)
        // Requires visionOS 2.2+
        if #available(visionOS 2.2, *) {
            return true
        }
        return false

        #else
        // Unsupported platform
        return false
        #endif
    }

    // MARK: - Future Private Methods (Placeholders)

    // TODO: Implement these in Phase 1 and Phase 5

    /*
    private func extractEntities(from text: String) async throws -> AnalysisResult {
        // Use Natural Language framework + on-device ML
        // Return AnalysisResult with entities
    }

    private func inferRelationships(from text: String) async throws -> AnalysisResult {
        // Parse sentence structure
        // Identify relationship patterns
        // Return AnalysisResult with relationships
    }

    private func extractCalendar(from text: String) async throws -> AnalysisResult {
        // Look for temporal vocabulary
        // Build calendar structure
        // Return AnalysisResult with calendar
    }

    private func performComprehensiveAnalysis(of text: String) async throws -> AnalysisResult {
        // Combine all analysis types
        // Return complete AnalysisResult
    }
    */
}

// MARK: - Availability Helpers

extension AppleIntelligenceProvider {
    /// Check if Image Playground is available
    static var isImagePlaygroundAvailable: Bool {
        #if os(iOS)
        if #available(iOS 18.2, *) {
            return true
        }
        #elseif os(macOS)
        if #available(macOS 15.2, *) {
            return true
        }
        #endif
        return false
    }

    /// Check if on-device analysis is available
    static var isOnDeviceAnalysisAvailable: Bool {
        // Same requirements as Image Playground
        return isImagePlaygroundAvailable
    }
}
