//
//  PotentialCard.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-21.
//  Part of Phase 3: Potential Card System for real-time entity detection
//
//  Represents an unconfirmed entity reference detected in scene text.
//  Writers can confirm these to create formal card relationships or dismiss false positives.
//

import Foundation
import SwiftUI

/// Represents a potential entity reference detected in scene text.
/// These are unconfirmed suggestions that the writer can promote to confirmed cards.
struct PotentialCard: Identifiable, Hashable {
    /// Unique identifier
    let id: UUID

    /// The kind of card this might be (character, artifact, location, etc.)
    let kind: Kinds

    /// Detected or suggested name
    let name: String

    /// Detection confidence (0.0 to 1.0)
    /// - 1.0: Exact match with existing card
    /// - 0.7-0.9: Fuzzy match or strong pattern
    /// - 0.4-0.6: Capitalized noun phrase or context keyword
    /// - < 0.4: Weak detection, might be filtered out
    let confidence: Float

    /// Text range where this entity was detected (if applicable)
    let textRange: Range<String.Index>?

    /// The scene this potential card belongs to
    let sceneID: UUID

    /// Whether the writer has dismissed this suggestion
    var dismissed: Bool = false

    /// If confirmed, the UUID of the associated confirmed card
    var confirmedCardID: UUID?

    /// Detection source (for debugging and refinement)
    let detectionSource: DetectionSource

    init(
        id: UUID = UUID(),
        kind: Kinds,
        name: String,
        confidence: Float,
        textRange: Range<String.Index>? = nil,
        sceneID: UUID,
        dismissed: Bool = false,
        confirmedCardID: UUID? = nil,
        detectionSource: DetectionSource = .manual
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.confidence = confidence
        self.textRange = textRange
        self.sceneID = sceneID
        self.dismissed = dismissed
        self.confirmedCardID = confirmedCardID
        self.detectionSource = detectionSource
    }

    /// Detection source for analytics and refinement
    enum DetectionSource: String, Codable, Hashable {
        case exactMatch = "Exact Match"
        case fuzzyMatch = "Fuzzy Match"
        case capitalizationPattern = "Capitalization Pattern"
        case contextKeyword = "Context Keyword"
        case previousMention = "Previously Mentioned"
        case manual = "Manual Creation"
    }

    /// Visual indicator color based on confirmation state
    var indicatorColor: Color {
        if confirmedCardID != nil {
            return colorForKind(kind)
        } else {
            return colorForKind(kind).opacity(0.5)
        }
    }

    /// Border style based on confirmation state
    var borderStyle: StrokeStyle {
        if confirmedCardID != nil {
            return StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        } else {
            return StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [4, 4])
        }
    }

    /// Helper to get color for card kind
    private func colorForKind(_ kind: Kinds) -> Color {
        switch kind {
        case .characters: return .blue
        case .artifacts: return .orange
        case .vehicles: return .green
        case .locations: return .purple
        case .buildings: return .brown
        case .chronicles: return .cyan
        default: return .gray
        }
    }
}

/// State management for scene context including potential and confirmed cards
@Observable
class SceneContext {
    /// Currently active scene ID
    var activeSceneID: UUID?

    /// Potential cards detected in the active scene
    var potentialCards: [PotentialCard] = []

    /// Confirmed cards explicitly linked to the active scene
    var confirmedCards: [Card] = []

    /// All potential cards sorted by confidence (highest first)
    var sortedPotentialCards: [PotentialCard] {
        potentialCards
            .filter { !$0.dismissed && $0.confirmedCardID == nil }
            .sorted { $0.confidence > $1.confidence }
    }

    /// Location card (potential or confirmed) - always shown first in Context Gutter
    var locationCard: PotentialCard? {
        potentialCards.first { $0.kind == .locations && !$0.dismissed }
    }

    /// Confirmed location card (if any)
    var confirmedLocation: Card? {
        confirmedCards.first { $0.kind == .locations }
    }

    // MARK: - Potential Card Management

    /// Add a new potential card
    func addPotentialCard(_ card: PotentialCard) {
        // Avoid duplicates based on name and kind
        guard !potentialCards.contains(where: { $0.name == card.name && $0.kind == card.kind }) else {
            return
        }
        potentialCards.append(card)
    }

    /// Confirm a potential card by linking it to an existing or new card
    func confirmPotential(_ potential: PotentialCard, asCard card: Card) {
        if let index = potentialCards.firstIndex(where: { $0.id == potential.id }) {
            var updated = potentialCards[index]
            updated.confirmedCardID = card.id
            potentialCards[index] = updated

            // Add to confirmed cards if not already present
            if !confirmedCards.contains(where: { $0.id == card.id }) {
                confirmedCards.append(card)
            }
        }
    }

    /// Dismiss a potential card (mark as false positive)
    func dismissPotential(_ potential: PotentialCard) {
        if let index = potentialCards.firstIndex(where: { $0.id == potential.id }) {
            var updated = potentialCards[index]
            updated.dismissed = true
            potentialCards[index] = updated
        }
    }

    /// Remove a potential card entirely
    func removePotential(_ potential: PotentialCard) {
        potentialCards.removeAll { $0.id == potential.id }
    }

    /// Clear all potential cards (when switching scenes)
    func clearPotentialCards() {
        potentialCards.removeAll()
    }

    // MARK: - Confirmed Card Management

    /// Add a confirmed card to the scene context
    func addConfirmedCard(_ card: Card) {
        if !confirmedCards.contains(where: { $0.id == card.id }) {
            confirmedCards.append(card)
        }
    }

    /// Remove a confirmed card from the scene context
    func removeConfirmedCard(_ card: Card) {
        confirmedCards.removeAll { $0.id == card.id }
    }

    /// Clear all confirmed cards (when switching scenes)
    func clearConfirmedCards() {
        confirmedCards.removeAll()
    }

    // MARK: - Scene Switching

    /// Clear all context when switching to a new scene
    func clearForNewScene() {
        potentialCards.removeAll()
        confirmedCards.removeAll()
        activeSceneID = nil
    }

    /// Load context for a specific scene
    func loadForScene(_ sceneID: UUID, potentials: [PotentialCard], confirmed: [Card]) {
        clearForNewScene()
        activeSceneID = sceneID
        potentialCards = potentials
        confirmedCards = confirmed
    }
}
