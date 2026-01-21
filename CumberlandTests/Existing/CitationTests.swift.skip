// CitationTests.swift
import Testing
import SwiftData
@testable import Cumberland
import Foundation

@Suite("Citation and Image Attribution Persistence")
struct CitationTests {

    // Helper to create an in-memory container and a context
    private func makeInMemoryContainer() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Card.self, Source.self, Citation.self, configurations: config)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return (container, context)
    }

    @Test("Create and fetch image attributions for a card")
    @MainActor
    func createAndFetchImageAttributions() async throws {
        let (_, ctx) = try makeInMemoryContainer()

        // Create a card and a source
        let card = Card(
            name: "Card A",
            subtitle: "Sub",
            detailedText: "Details",
            author: nil,
            sizeCategory: .standard
        )
        let src = Source(title: "Image Source", authors: "A. Author")
        ctx.insert(card)
        ctx.insert(src)
        try ctx.save()

        // Create an image attribution (Citation kind .image)
        let c = Citation(card: card, source: src, kind: .image, locator: "fig. 2", excerpt: "Sunset", contextNote: "Cover image", createdAt: Date())
        ctx.insert(c)
        try ctx.save()

        // Fetch with the same predicate used in the UI
        let cardID = card.id
        let fetch = FetchDescriptor<Citation>(
            predicate: #Predicate { $0.card?.id == cardID && $0.kindRaw == CitationKind.image.rawValue },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let results = try ctx.fetch(fetch)

        #expect(results.count == 1)
        let found = try #require(results.first)
        #expect(found.card?.id == card.id)
        #expect(found.source?.id == src.id)
        #expect(found.kind == .image)
        #expect(found.locator == "fig. 2")
        #expect(found.excerpt == "Sunset")
        #expect(found.contextNote == "Cover image")
    }

    @Test("Edit image attribution and persist changes")
    @MainActor
    func editImageAttribution() async throws {
        let (_, ctx) = try makeInMemoryContainer()

        let card = Card(
            name: "Card B",
            subtitle: "",
            detailedText: "",
            author: nil,
            sizeCategory: .standard
        )
        let src1 = Source(title: "First Source", authors: "F. Author")
        let src2 = Source(title: "Second Source", authors: "S. Author")

        ctx.insert(card)
        ctx.insert(src1)
        ctx.insert(src2)
        try ctx.save()

        let c = Citation(card: card, source: src1, kind: .image, locator: "p. 10", excerpt: "Original", contextNote: nil, createdAt: Date())
        ctx.insert(c)
        try ctx.save()

        // Edit fields (simulate ImageAttributionEditor.saveCitation update path)
        c.source = src2
        c.kind = .image // remains image
        c.locator = "p. 12"
        c.excerpt = "Updated"
        c.contextNote = "Revised note"
        try ctx.save()

        let fetch = FetchDescriptor<Citation>(
            predicate: #Predicate { $0.card?.id == card.id && $0.kindRaw == CitationKind.image.rawValue }
        )
        let results = try ctx.fetch(fetch)
        #expect(results.count == 1)
        let updated = try #require(results.first)
        #expect(updated.source?.id == src2.id)
        #expect(updated.locator == "p. 12")
        #expect(updated.excerpt == "Updated")
        #expect(updated.contextNote == "Revised note")
    }

    @Test("Fetch all citations for a card in createdAt order")
    @MainActor
    func fetchAllCitationsOrdered() async throws {
        let (_, ctx) = try makeInMemoryContainer()

        let card = Card(
            name: "Card C",
            subtitle: "",
            detailedText: "",
            author: nil,
            sizeCategory: .standard
        )
        let s1 = Source(title: "S1", authors: "A1")
        let s2 = Source(title: "S2", authors: "A2")
        let s3 = Source(title: "S3", authors: "A3")

        ctx.insert(card)
        ctx.insert(s1); ctx.insert(s2); ctx.insert(s3)
        try ctx.save()

        let t0 = Date()
        let c1 = Citation(card: card, source: s1, kind: .quote,      locator: "p. 1",   excerpt: "E1", contextNote: nil,    createdAt: t0.addingTimeInterval(0.1))
        let c2 = Citation(card: card, source: s2, kind: .paraphrase, locator: "p. 2",   excerpt: "E2", contextNote: "N2",  createdAt: t0.addingTimeInterval(0.2))
        let c3 = Citation(card: card, source: s3, kind: .data,       locator: "tbl. 3", excerpt: "",   contextNote: nil,    createdAt: t0.addingTimeInterval(0.3))

        ctx.insert(c1); ctx.insert(c2); ctx.insert(c3)
        try ctx.save()

        // Same fetch used by CitationsSection (all kinds for the card)
        let fetch = FetchDescriptor<Citation>(
            predicate: #Predicate { $0.card?.id == card.id },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let results = try ctx.fetch(fetch)

        #expect(results.map { $0.source?.title ?? "" } == ["S1", "S2", "S3"])
        #expect(results[0].kind == .quote)
        #expect(results[1].kind == .paraphrase)
        #expect(results[2].kind == .data)
    }

    @Test("Citation.kind computed property mirrors kindRaw")
    @MainActor
    func citationKindComputedProperty() async throws {
        let (_, ctx) = try makeInMemoryContainer()

        let card = Card(
            name: "Card D",
            subtitle: "",
            detailedText: "",
            author: nil,
            sizeCategory: .standard
        )
        let src = Source(title: "Ref", authors: "Auth")
        ctx.insert(card); ctx.insert(src)
        try ctx.save()

        let c = Citation(card: card, source: src, kind: .quote, locator: "", excerpt: "", createdAt: Date())
        ctx.insert(c)
        try ctx.save()

        #expect(c.kindRaw == CitationKind.quote.rawValue)
        #expect(c.kind == .quote)

        // Update via computed property
        c.kind = .data
        try ctx.save()

        #expect(c.kindRaw == CitationKind.data.rawValue)
        #expect(c.kind == .data)
    }
}
