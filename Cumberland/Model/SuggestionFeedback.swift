//
//  SuggestionFeedback.swift
//  Cumberland
//
//  SwiftData model tracking anonymised user feedback on AI entity suggestions
//  (ER-0010). Stores entity kind and confidence level (no actual names for
//  privacy) plus accepted/rejected flag. Used by SuggestionEngine to tune
//  confidence thresholds over time.
//

import Foundation
import SwiftData

/// Suggestion Feedback model for learning user preferences
/// Part of ER-0010: AI Assistant for Content Analysis
///
/// Stores anonymized feedback about entity suggestions (accepted/rejected)
/// Used to improve suggestion quality over time by adjusting confidence thresholds
///
/// Privacy: No actual entity names are stored, only types and confidence levels
@Model
final class SuggestionFeedback {

    // MARK: - Identity

    /// Unique identifier
    var id: UUID

    // MARK: - Suggestion Information

    /// Entity type that was suggested
    /// Example: "Character", "Location", "Artifact"
    var entityType: String

    /// Confidence score of the suggestion (0.0 to 1.0)
    var confidence: Double

    /// Whether the user accepted the suggestion
    var wasAccepted: Bool

    // MARK: - Context

    /// Analysis task that generated this suggestion
    var analysisTask: String // "entityExtraction", "relationshipInference", etc.

    /// AI provider used for the analysis
    var aiProvider: String?

    // MARK: - Metadata

    /// When this feedback was recorded
    var timestamp: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        entityType: String,
        confidence: Double,
        wasAccepted: Bool,
        analysisTask: String = "entityExtraction",
        aiProvider: String? = nil
    ) {
        self.id = id
        self.entityType = entityType
        self.confidence = confidence
        self.wasAccepted = wasAccepted
        self.analysisTask = analysisTask
        self.aiProvider = aiProvider
        self.timestamp = Date()
    }
}

// MARK: - Feedback Query Extensions

extension SuggestionFeedback {

    /// Get acceptance rate for a specific entity type
    /// - Parameters:
    ///   - entityType: The entity type to query
    ///   - modelContext: SwiftData context
    ///   - limit: Maximum number of recent feedbacks to consider (default: 20)
    /// - Returns: Acceptance rate (0.0 to 1.0) or nil if no feedback exists
    static func acceptanceRate(
        for entityType: String,
        in modelContext: ModelContext,
        limit: Int = 20
    ) -> Double? {
        let descriptor = FetchDescriptor<SuggestionFeedback>(
            predicate: #Predicate { $0.entityType == entityType },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        guard let feedbacks = try? modelContext.fetch(descriptor).prefix(limit),
              !feedbacks.isEmpty else {
            return nil
        }

        let acceptedCount = feedbacks.filter { $0.wasAccepted }.count
        return Double(acceptedCount) / Double(feedbacks.count)
    }

    /// Get adjusted confidence threshold for an entity type based on feedback
    /// - Parameters:
    ///   - entityType: The entity type to query
    ///   - baseThreshold: Base confidence threshold (default: 0.70)
    ///   - modelContext: SwiftData context
    /// - Returns: Adjusted threshold (0.0 to 1.0)
    static func adjustedThreshold(
        for entityType: String,
        baseThreshold: Double = 0.70,
        in modelContext: ModelContext
    ) -> Double {
        guard let acceptanceRate = acceptanceRate(for: entityType, in: modelContext, limit: 20) else {
            return baseThreshold // No feedback yet, use base
        }

        // If acceptance rate is low (< 60%), raise the threshold
        // If acceptance rate is high (> 80%), we can lower it slightly
        if acceptanceRate < 0.6 {
            // Poor acceptance - raise threshold by up to 0.2
            let adjustment = (0.6 - acceptanceRate) * 0.5 // Scale 0-0.2
            return min(baseThreshold + adjustment, 0.95)
        } else if acceptanceRate > 0.8 {
            // Good acceptance - can lower threshold slightly
            let adjustment = (acceptanceRate - 0.8) * 0.25 // Scale 0-0.05
            return max(baseThreshold - adjustment, 0.5)
        }

        return baseThreshold // Acceptable range, no adjustment
    }

    /// Get feedback statistics for all entity types
    /// - Parameter modelContext: SwiftData context
    /// - Returns: Dictionary of entity type → statistics
    static func statisticsByEntityType(
        in modelContext: ModelContext
    ) -> [String: FeedbackStatistics] {
        let descriptor = FetchDescriptor<SuggestionFeedback>()

        guard let allFeedback = try? modelContext.fetch(descriptor) else {
            return [:]
        }

        // Group by entity type
        let grouped = Dictionary(grouping: allFeedback, by: { $0.entityType })

        // Calculate statistics for each type
        return grouped.mapValues { feedbacks in
            let total = feedbacks.count
            let accepted = feedbacks.filter { $0.wasAccepted }.count
            let rejected = total - accepted

            let avgConfidence = feedbacks.map { $0.confidence }.reduce(0.0, +) / Double(total)
            let avgAcceptedConfidence = feedbacks.filter { $0.wasAccepted }
                .map { $0.confidence }
                .reduce(0.0, +) / Double(max(accepted, 1))
            let avgRejectedConfidence = feedbacks.filter { !$0.wasAccepted }
                .map { $0.confidence }
                .reduce(0.0, +) / Double(max(rejected, 1))

            return FeedbackStatistics(
                entityType: feedbacks.first?.entityType ?? "Unknown",
                totalSuggestions: total,
                acceptedCount: accepted,
                rejectedCount: rejected,
                acceptanceRate: Double(accepted) / Double(total),
                averageConfidence: avgConfidence,
                averageAcceptedConfidence: avgAcceptedConfidence,
                averageRejectedConfidence: avgRejectedConfidence
            )
        }
    }

    /// Clear old feedback (keep only recent N entries per entity type)
    /// - Parameters:
    ///   - keepCount: Number of recent entries to keep per entity type (default: 50)
    ///   - modelContext: SwiftData context
    static func pruneOldFeedback(
        keepCount: Int = 50,
        in modelContext: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<SuggestionFeedback>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        let allFeedback = try modelContext.fetch(descriptor)
        let grouped = Dictionary(grouping: allFeedback, by: { $0.entityType })

        for (_, feedbacks) in grouped {
            if feedbacks.count > keepCount {
                // Delete oldest entries beyond keepCount
                for feedback in feedbacks.dropFirst(keepCount) {
                    modelContext.delete(feedback)
                }
            }
        }

        try modelContext.save()
    }
}

// MARK: - Supporting Types

/// Statistics about suggestion feedback for an entity type
struct FeedbackStatistics {
    let entityType: String
    let totalSuggestions: Int
    let acceptedCount: Int
    let rejectedCount: Int
    let acceptanceRate: Double
    let averageConfidence: Double
    let averageAcceptedConfidence: Double
    let averageRejectedConfidence: Double

    /// Format acceptance rate as percentage
    var acceptanceRatePercent: String {
        String(format: "%.1f%%", acceptanceRate * 100)
    }

    /// Recommendation for threshold adjustment
    var thresholdRecommendation: String {
        if acceptanceRate < 0.5 {
            return "Consider raising confidence threshold (low acceptance)"
        } else if acceptanceRate > 0.85 {
            return "Can lower confidence threshold (high acceptance)"
        } else {
            return "Threshold is well-calibrated"
        }
    }
}

// MARK: - Privacy Extensions

extension SuggestionFeedback {
    /// Verify this feedback contains no personally identifiable information
    /// All feedback should be anonymized (no entity names, only types)
    var isAnonymized: Bool {
        // Entity type should be generic ("Character", not "John Smith")
        let validTypes = ["Character", "Location", "Building", "Artifact",
                         "Vehicle", "Organization", "Event", "Other"]
        return validTypes.contains(entityType)
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension SuggestionFeedback {
    /// Create sample feedback for testing
    static func createSampleFeedback(in modelContext: ModelContext) {
        let types = ["Character", "Location", "Artifact", "Building"]
        let tasks = ["entityExtraction", "relationshipInference", "calendarExtraction"]

        for _ in 0..<20 {
            let feedback = SuggestionFeedback(
                entityType: types.randomElement()!,
                confidence: Double.random(in: 0.5...0.95),
                wasAccepted: Bool.random(),
                analysisTask: tasks.randomElement()!,
                aiProvider: "Apple Intelligence"
            )
            modelContext.insert(feedback)
        }

        try? modelContext.save()
    }
}
#endif
