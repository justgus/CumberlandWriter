// CitationManagerTests.swift
// CumberlandTests

import Testing
import SwiftData
import Foundation
@testable import Cumberland

@Suite("CitationManager Tests", .serialized)
struct CitationManagerTests {

    @MainActor
    private func makeManager() throws -> (CitationManager, ModelContext) {
        let ctx = try TestFixtures.makeIsolatedContext()
        let mgr = CitationManager(modelContext: ctx)
        return (mgr, ctx)
    }

    // MARK: - Citation CRUD

    @Test("createCitation links card to source with correct fields")
    @MainActor
    func createCitationLinks() async throws {
        let (mgr, ctx) = try makeManager()
        let card = TestFixtures.createSampleCharacter(name: "Hero", context: ctx)
        let source = Source(title: "Encyclopedia", authors: "Author")
        ctx.insert(source)
        try ctx.save()

        let citation = mgr.createCitation(card: card, source: source, kind: .quote, locator: "p. 42", excerpt: "A great hero")

        #expect(citation.card?.id == card.id)
        #expect(citation.source?.id == source.id)
        #expect(citation.kind == .quote)
        #expect(citation.locator == "p. 42")
        #expect(citation.excerpt == "A great hero")
    }

    @Test("updateCitation changes all editable fields")
    @MainActor
    func updateCitationFields() async throws {
        let (mgr, ctx) = try makeManager()
        let card = TestFixtures.createSampleCharacter(context: ctx)
        let src1 = Source(title: "Src1", authors: "A1")
        let src2 = Source(title: "Src2", authors: "A2")
        ctx.insert(src1); ctx.insert(src2)
        try ctx.save()

        let citation = mgr.createCitation(card: card, source: src1, kind: .quote, locator: "p.1")
        mgr.updateCitation(citation, source: src2, kind: .paraphrase, locator: "p.2", excerpt: "Updated", contextNote: "Note")

        #expect(citation.source?.id == src2.id)
        #expect(citation.kind == .paraphrase)
        #expect(citation.locator == "p.2")
        #expect(citation.excerpt == "Updated")
        #expect(citation.contextNote == "Note")
    }

    @Test("deleteCitation removes from context")
    @MainActor
    func deleteCitationRemoves() async throws {
        let (mgr, ctx) = try makeManager()
        let card = TestFixtures.createSampleCharacter(context: ctx)
        let source = Source(title: "Src", authors: "A")
        ctx.insert(source)
        try ctx.save()

        let citation = mgr.createCitation(card: card, source: source, kind: .quote)
        mgr.deleteCitation(citation)

        let remaining = try ctx.fetch(FetchDescriptor<Citation>())
        #expect(remaining.isEmpty)
    }

    @Test("fetchCitations returns sorted by createdAt")
    @MainActor
    func fetchCitationsSorted() async throws {
        let (mgr, ctx) = try makeManager()
        let card = TestFixtures.createSampleCharacter(context: ctx)
        let src = Source(title: "Src", authors: "A")
        ctx.insert(src)
        try ctx.save()

        // Create in reverse order with explicit timestamps
        let c1 = Citation(card: card, source: src, kind: .quote, locator: "first", excerpt: "", createdAt: Date(timeIntervalSince1970: 100))
        let c2 = Citation(card: card, source: src, kind: .data, locator: "second", excerpt: "", createdAt: Date(timeIntervalSince1970: 200))
        ctx.insert(c1); ctx.insert(c2)
        try ctx.save()

        let results = mgr.fetchCitations(for: card)
        #expect(results.count == 2)
        #expect(results.first?.locator == "first")
        #expect(results.last?.locator == "second")
    }

    @Test("fetchImageCitations filters by kind == .image")
    @MainActor
    func fetchImageCitationsFiltered() async throws {
        let (mgr, ctx) = try makeManager()
        let card = TestFixtures.createSampleCharacter(context: ctx)
        let src = Source(title: "Src", authors: "A")
        ctx.insert(src)
        try ctx.save()

        let imgCit = Citation(card: card, source: src, kind: .image, locator: "fig.1", excerpt: "", createdAt: Date())
        let quoteCit = Citation(card: card, source: src, kind: .quote, locator: "p.1", excerpt: "", createdAt: Date())
        ctx.insert(imgCit); ctx.insert(quoteCit)
        try ctx.save()

        let results = mgr.fetchImageCitations(for: card)
        #expect(results.count == 1)
        #expect(results.first?.kind == .image)
    }

    // MARK: - Source CRUD

    @Test("createSource detects duplicate by title and returns existing")
    @MainActor
    func createSourceDedup() async throws {
        let (mgr, _) = try makeManager()
        let first = mgr.createSource(title: "My Source", authors: "Author1")
        let second = mgr.createSource(title: "My Source", authors: "Author2")

        #expect(first.id == second.id)
    }

    @Test("createSource creates new when no duplicate")
    @MainActor
    func createSourceNew() async throws {
        let (mgr, _) = try makeManager()
        let first = mgr.createSource(title: "Source A", authors: "A")
        let second = mgr.createSource(title: "Source B", authors: "B")

        #expect(first.id != second.id)
    }

    @Test("fetchOrCreateSource sets accessedDate when URL provided")
    @MainActor
    func fetchOrCreateSetsAccessedDate() async throws {
        let (mgr, _) = try makeManager()
        let source = mgr.fetchOrCreateSource(title: "Web Source", authors: "Author", urlString: "https://example.com")

        #expect(source.url == "https://example.com")
        #expect(source.accessedDate != nil)
    }
}
