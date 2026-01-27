import Foundation
import SwiftUI
import NaturalLanguage
#if canImport(ImagePlayground)
import ImagePlayground
#endif

#if canImport(AppIntents)
import AppIntents
#endif

#if os(macOS)
import AppKit
#elseif os(iOS) || os(visionOS)
import UIKit
#endif

/// Apple Intelligence provider (default, on-device AI)
/// Uses Apple's ImagePlayground framework for image generation
/// Available on iOS 18.1+, macOS 15.1+, iPadOS 18.1+, visionOS 2.1+
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

    var usesSheetBasedUI: Bool {
        true // Apple Intelligence uses .imagePlaygroundSheet() modifier
    }

    var metadata: AIProviderMetadata? {
        AIProviderMetadata(
            modelVersion: "ImagePlayground",
            maxPromptLength: nil, // Handled by Image Playground UI
            supportedImageFormats: ["PNG", "JPEG"],
            rateLimit: RateLimit(
                requestsPerMinute: 10, // Estimated
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
            print("⚠️ Image Playground is not available on this device")
            print("   Requires: iOS 18.1+, macOS 15.1+, iPadOS 18.1+, or visionOS 2.1+")
        }
    }

    // MARK: - Image Generation (ER-0009)

    func generateImage(prompt: String) async throws -> Data {
        // Apple Intelligence uses sheet-based UI via ImagePlayground framework
        // This method should not be called directly. Use .imagePlaygroundSheet() modifier in SwiftUI instead.
        throw AIProviderError.featureNotSupported(
            feature: "Direct API call. Apple Intelligence uses .imagePlaygroundSheet() modifier for image generation."
        )
    }


    // MARK: - Content Analysis (ER-0010)

    func analyzeText(_ text: String, for task: AnalysisTask) async throws -> AnalysisResult {
        guard isAvailable else {
            throw AIProviderError.providerUnavailable(reason: "Apple Intelligence requires iOS 18.1+ or macOS 15.1+")
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
        print("   Text length: \(text.count) characters, \(wordCount) words")
        #endif

        let startTime = Date()

        // Perform analysis based on task type
        var result: AnalysisResult

        switch task {
        case .entityExtraction:
            result = try await extractEntities(from: text)
        case .relationshipInference:
            result = try await inferRelationships(from: text)
        case .calendarExtraction:
            result = try await extractCalendar(from: text)
        case .comprehensive:
            result = try await performComprehensiveAnalysis(of: text)
        }

        // Add metadata
        let processingTime = Date().timeIntervalSince(startTime)
        result.metadata = AnalysisMetadata(
            processingTime: processingTime,
            modelVersion: "NaturalLanguage Framework",
            tokensProcessed: wordCount
        )

        #if DEBUG
        print("✅ [Apple Intelligence] Analysis complete in \(String(format: "%.2f", processingTime))s")
        print("   Entities: \(result.entities?.count ?? 0)")
        print("   Relationships: \(result.relationships?.count ?? 0)")
        #endif

        return result
    }

    // MARK: - Private Helpers

    /// Check if Image Playground is available on this device
    private func checkAvailability() -> Bool {
        #if canImport(ImagePlayground)
        #if os(iOS)
        // ImagePlayground requires iOS 18.1+
        if #available(iOS 18.1, *) {
            return true
        }
        return false

        #elseif os(macOS)
        // ImagePlayground requires macOS 15.1+
        if #available(macOS 15.1, *) {
            return true
        }
        return false

        #elseif os(visionOS)
        // ImagePlayground requires visionOS 2.1+ (estimated)
        if #available(visionOS 2.1, *) {
            return true
        }
        return false

        #else
        // Unsupported platform
        return false
        #endif
        #else
        // ImagePlayground framework not available
        return false
        #endif
    }

    // MARK: - Private Analysis Methods

    /// Extract entities using NaturalLanguage framework
    private func extractEntities(from text: String) async throws -> AnalysisResult {
        var entities: [Entity] = []

        // Use NLTagger for named entity recognition
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.personalName, .placeName, .organizationName]

        // Extract named entities
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            guard let tag = tag, tags.contains(tag) else { return true }

            let entityName = String(text[tokenRange])

            // Determine entity type
            let entityType: EntityType
            switch tag {
            case .personalName:
                entityType = .character
            case .placeName:
                entityType = .location
            case .organizationName:
                entityType = .organization
            default:
                entityType = .other
            }

            // Extract context (surrounding text)
            let contextRange = extractContext(for: tokenRange, in: text)
            let context = String(text[contextRange])

            // Create entity with confidence
            let entity = Entity(
                name: entityName,
                type: entityType,
                confidence: 0.75, // NL framework doesn't provide confidence scores, use default
                context: context,
                textRange: tokenRange
            )

            entities.append(entity)
            return true
        }

        // Use pattern matching to find potential artifacts, vehicles, buildings
        entities.append(contentsOf: extractCustomEntities(from: text))

        // Remove duplicates (case-insensitive)
        entities = removeDuplicateEntities(entities)

        #if DEBUG
        print("   Found \(entities.count) entities via NaturalLanguage framework")
        #endif

        return AnalysisResult(entities: entities, relationships: nil, calendars: nil, metadata: nil)
    }

    /// Extract custom entities using pattern matching (artifacts, vehicles, buildings)
    private func extractCustomEntities(from text: String) -> [Entity] {
        var entities: [Entity] = []

        // Patterns for identifying artifacts, vehicles, and buildings
        let artifactPatterns = [
            "\\bthe\\s+([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)(?:\\s+sword|\\s+blade|\\s+weapon|\\s+amulet|\\s+ring|\\s+staff|\\s+book|\\s+crown|\\s+shield)",
            "\\b([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)\\s+of\\s+(?:Power|Light|Darkness|Shadow|Fire|Ice|Magic)"
        ]

        let vehiclePatterns = [
            "\\bthe\\s+([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)(?:\\s+ship|\\s+vessel|\\s+boat|\\s+airship|\\s+dragon)",
            "\\baboard\\s+the\\s+([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)"
        ]

        let buildingPatterns = [
            "\\bthe\\s+([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)(?:\\s+Temple|\\s+Tower|\\s+Castle|\\s+Palace|\\s+Hall|\\s+Cathedral|\\s+Fortress|\\s+Academy)",
            "\\b(?:Temple|Tower|Castle|Palace|Hall|Cathedral|Fortress|Academy)\\s+of\\s+([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)"
        ]

        // Extract artifacts
        for pattern in artifactPatterns {
            entities.append(contentsOf: extractWithPattern(pattern, type: .artifact, in: text))
        }

        // Extract vehicles
        for pattern in vehiclePatterns {
            entities.append(contentsOf: extractWithPattern(pattern, type: .vehicle, in: text))
        }

        // Extract buildings
        for pattern in buildingPatterns {
            entities.append(contentsOf: extractWithPattern(pattern, type: .building, in: text))
        }

        return entities
    }

    /// Extract entities using regex pattern
    private func extractWithPattern(_ pattern: String, type: EntityType, in text: String) -> [Entity] {
        var entities: [Entity] = []

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return entities
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        for match in matches {
            guard match.numberOfRanges > 1 else { continue }
            let entityRange = match.range(at: 1)
            guard entityRange.location != NSNotFound else { continue }

            let entityName = nsText.substring(with: entityRange)

            // Extract context
            let fullMatchRange = match.range
            let startIndex = text.index(text.startIndex, offsetBy: fullMatchRange.location)
            let endIndex = text.index(startIndex, offsetBy: fullMatchRange.length)
            let tokenRange = startIndex..<endIndex
            let contextRange = extractContext(for: tokenRange, in: text)
            let context = String(text[contextRange])

            let entity = Entity(
                name: entityName,
                type: type,
                confidence: 0.70, // Lower confidence for pattern matching
                context: context,
                textRange: tokenRange
            )

            entities.append(entity)
        }

        return entities
    }

    /// Extract context around a token range
    private func extractContext(for range: Range<String.Index>, in text: String) -> Range<String.Index> {
        let contextRadius = 50 // characters before and after

        let startOffset = text.distance(from: text.startIndex, to: range.lowerBound)
        let endOffset = text.distance(from: text.startIndex, to: range.upperBound)

        let contextStart = max(0, startOffset - contextRadius)
        let contextEnd = min(text.count, endOffset + contextRadius)

        let contextStartIndex = text.index(text.startIndex, offsetBy: contextStart)
        let contextEndIndex = text.index(text.startIndex, offsetBy: contextEnd)

        return contextStartIndex..<contextEndIndex
    }

    /// Remove duplicate entities (case-insensitive)
    private func removeDuplicateEntities(_ entities: [Entity]) -> [Entity] {
        var seen = Set<String>()
        var unique: [Entity] = []

        for entity in entities {
            let key = entity.name.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(entity)
            }
        }

        return unique
    }

    /// Infer relationships using sentence parsing (Phase 6 - placeholder for now)
    private func inferRelationships(from text: String) async throws -> AnalysisResult {
        // Phase 6 implementation - relationship inference
        // For now, return empty relationships
        return AnalysisResult(entities: nil, relationships: [], calendars: nil, metadata: nil)
    }

    /// Extract calendar structure (Phase 7 - placeholder for now)
    private func extractCalendar(from text: String) async throws -> AnalysisResult {
        // Phase 7 implementation - calendar extraction
        // For now, return nil calendars
        return AnalysisResult(entities: nil, relationships: nil, calendars: nil, metadata: nil)
    }

    /// Perform comprehensive analysis (all tasks combined)
    private func performComprehensiveAnalysis(of text: String) async throws -> AnalysisResult {
        // Combine all analysis types
        let entitiesResult = try await extractEntities(from: text)
        let relationshipsResult = try await inferRelationships(from: text)
        let calendarResult = try await extractCalendar(from: text)

        return AnalysisResult(
            entities: entitiesResult.entities,
            relationships: relationshipsResult.relationships,
            calendars: calendarResult.calendars,
            metadata: nil
        )
    }
}

// MARK: - Availability Helpers

extension AppleIntelligenceProvider {
    /// Check if Image Playground is available
    static var isImagePlaygroundAvailable: Bool {
        #if canImport(ImagePlayground)
        #if os(iOS)
        if #available(iOS 18.1, *) {
            return true
        }
        #elseif os(macOS)
        if #available(macOS 15.1, *) {
            return true
        }
        #elseif os(visionOS)
        if #available(visionOS 2.1, *) {
            return true
        }
        #endif
        #endif
        return false
    }

    /// Check if on-device analysis is available
    static var isOnDeviceAnalysisAvailable: Bool {
        // Same requirements as Image Playground
        return isImagePlaygroundAvailable
    }
}
