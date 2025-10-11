// Citation.swift
import Foundation
import SwiftData

@Model
final class Citation {
    // Stable identity for SwiftUI/collections
    var id: UUID = UUID()

    // CloudKit: relationships must be optional, and inverses are declared on Card.citations / Source.citations.
    var card: Card?
    var source: Source?

    // Store raw to keep the model schema simple; expose computed enum
    var kindRaw: String = CitationKind.quote.rawValue
    var locator: String = ""
    var excerpt: String = ""
    var contextNote: String?
    var createdAt: Date = Date()

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
