// Citation.swift
import Foundation
import SwiftData

@Model
final class Citation {
    // Stable identity for SwiftUI/collections
    var id: UUID

    @Relationship(deleteRule: .cascade) var card: Card
    @Relationship(deleteRule: .cascade) var source: Source

    // Store raw to keep the model schema simple; expose computed enum
    var kindRaw: String
    var locator: String
    var excerpt: String
    var contextNote: String?
    var createdAt: Date

    init(card: Card,
         source: Source,
         kind: CitationKind,
         locator: String,
         excerpt: String,
         contextNote: String? = nil,
         createdAt: Date = Date(),
         id: UUID = UUID()) {
        self.id = id
        self.card = card
        self.source = source
        self.kindRaw = kind.rawValue
        self.locator = locator
        self.excerpt = excerpt
        self.contextNote = contextNote
        self.createdAt = createdAt
    }

    var kind: CitationKind {
        get { CitationKind(rawValue: kindRaw) ?? .quote }
        set { kindRaw = newValue.rawValue }
    }
}
