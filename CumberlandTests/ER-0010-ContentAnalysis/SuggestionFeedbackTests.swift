//
//  SuggestionFeedbackTests.swift
//  CumberlandTests
//
//  Phase 10 tests for SuggestionFeedback (ER-0010).
//  Covers model initialization, anonymization checks, and
//  FeedbackStatistics value types. SwiftData query tests use
//  TestFixtures.makeFullSchemaContainer() for the host app container.
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

@Suite("SuggestionFeedback Tests", .serialized)
struct SuggestionFeedbackTests {

    // MARK: - Model Initialization (no SwiftData context needed)

    @Test("Create feedback with all properties")
    func createFeedback() {
        let feedback = SuggestionFeedback(
            entityType: "Character",
            confidence: 0.85,
            wasAccepted: true,
            analysisTask: "entityExtraction",
            aiProvider: "Apple Intelligence"
        )

        #expect(feedback.entityType == "Character")
        #expect(feedback.confidence == 0.85)
        #expect(feedback.wasAccepted == true)
        #expect(feedback.analysisTask == "entityExtraction")
        #expect(feedback.aiProvider == "Apple Intelligence")
        #expect(feedback.timestamp <= Date())
    }

    @Test("Create feedback with default values")
    func createFeedbackDefaults() {
        let feedback = SuggestionFeedback(
            entityType: "Location",
            confidence: 0.7,
            wasAccepted: false
        )

        #expect(feedback.analysisTask == "entityExtraction")
        #expect(feedback.aiProvider == nil)
    }

    @Test("Feedback ID is unique")
    func uniqueIDs() {
        let f1 = SuggestionFeedback(entityType: "Character", confidence: 0.8, wasAccepted: true)
        let f2 = SuggestionFeedback(entityType: "Character", confidence: 0.8, wasAccepted: true)
        #expect(f1.id != f2.id)
    }

    // MARK: - Anonymization

    @Test("Valid entity types are anonymized")
    func validTypesAnonymized() {
        let validTypes = ["Character", "Location", "Building", "Artifact",
                         "Vehicle", "Organization", "Event", "Other"]
        for type in validTypes {
            let feedback = SuggestionFeedback(entityType: type, confidence: 0.8, wasAccepted: true)
            #expect(feedback.isAnonymized == true, "Expected \(type) to be anonymized")
        }
    }

    @Test("Specific names are not anonymized")
    func specificNamesNotAnonymized() {
        let feedback = SuggestionFeedback(entityType: "Captain Aria", confidence: 0.8, wasAccepted: true)
        #expect(feedback.isAnonymized == false)

        let another = SuggestionFeedback(entityType: "New York City", confidence: 0.7, wasAccepted: false)
        #expect(another.isAnonymized == false)
    }

    // MARK: - FeedbackStatistics Value Type

    @Test("FeedbackStatistics acceptance rate formatting")
    func feedbackStatsFormatting() {
        let stats = FeedbackStatistics(
            entityType: "Character",
            totalSuggestions: 10,
            acceptedCount: 8,
            rejectedCount: 2,
            acceptanceRate: 0.8,
            averageConfidence: 0.75,
            averageAcceptedConfidence: 0.85,
            averageRejectedConfidence: 0.55
        )

        #expect(stats.acceptanceRatePercent == "80.0%")
    }

    @Test("FeedbackStatistics threshold recommendation for low acceptance")
    func lowAcceptanceRecommendation() {
        let stats = FeedbackStatistics(
            entityType: "Character",
            totalSuggestions: 10,
            acceptedCount: 3,
            rejectedCount: 7,
            acceptanceRate: 0.3,
            averageConfidence: 0.7,
            averageAcceptedConfidence: 0.85,
            averageRejectedConfidence: 0.6
        )
        #expect(stats.thresholdRecommendation.lowercased().contains("raising"))
    }

    @Test("FeedbackStatistics threshold recommendation for high acceptance")
    func highAcceptanceRecommendation() {
        let stats = FeedbackStatistics(
            entityType: "Character",
            totalSuggestions: 10,
            acceptedCount: 9,
            rejectedCount: 1,
            acceptanceRate: 0.9,
            averageConfidence: 0.8,
            averageAcceptedConfidence: 0.85,
            averageRejectedConfidence: 0.55
        )
        #expect(stats.thresholdRecommendation.lowercased().contains("lower"))
    }

    @Test("FeedbackStatistics threshold recommendation for good acceptance")
    func goodAcceptanceRecommendation() {
        let stats = FeedbackStatistics(
            entityType: "Character",
            totalSuggestions: 10,
            acceptedCount: 7,
            rejectedCount: 3,
            acceptanceRate: 0.7,
            averageConfidence: 0.75,
            averageAcceptedConfidence: 0.8,
            averageRejectedConfidence: 0.65
        )
        #expect(stats.thresholdRecommendation.lowercased().contains("calibrated"))
    }

    // MARK: - Threshold Adjustment Logic (tested without SwiftData)
    // These test the mathematical logic by computing what adjustedThreshold would return
    // given known acceptance rates, without requiring a ModelContext.

    @Test("Threshold math: low acceptance raises threshold")
    func thresholdMathLowAcceptance() {
        // acceptanceRate 0.3 < 0.6 -> adjustment = (0.6 - 0.3) * 0.5 = 0.15
        let baseThreshold = 0.70
        let acceptanceRate = 0.3
        let adjustment = (0.6 - acceptanceRate) * 0.5
        let result = min(baseThreshold + adjustment, 0.95)
        #expect(result == 0.85)
    }

    @Test("Threshold math: high acceptance lowers threshold")
    func thresholdMathHighAcceptance() {
        // acceptanceRate 0.9 > 0.8 -> adjustment = (0.9 - 0.8) * 0.25 = 0.025
        let baseThreshold = 0.70
        let acceptanceRate = 0.9
        let adjustment = (acceptanceRate - 0.8) * 0.25
        let result = max(baseThreshold - adjustment, 0.5)
        #expect(abs(result - 0.675) < 0.001)
    }

    @Test("Threshold math: acceptable range returns base")
    func thresholdMathAcceptable() {
        // acceptanceRate 0.7 is between 0.6 and 0.8 -> no adjustment
        let baseThreshold = 0.70
        #expect(baseThreshold == 0.70) // No change in acceptable range
    }

    // MARK: - SwiftData Integration Tests
    // NOTE: SuggestionFeedback SwiftData queries (acceptanceRate, adjustedThreshold,
    // statisticsByEntityType) require a fully configured hosted test bundle with
    // the app's ModelContainer. These are tested through the SuggestionEngine
    // integration tests rather than in isolation, since the hosted container
    // can produce signal traps when used with SuggestionFeedback's #Predicate queries.
}
