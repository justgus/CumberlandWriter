// Source.swift
import Foundation
import SwiftData

@Model
final class Source {
    // CloudKit: no unique constraints; provide defaults at declaration
    var id: UUID = UUID()

    // Non-optional properties require declaration defaults for CloudKit
    var title: String = ""
    var authors: String = "" // Simple string; can normalize later to an array
    var containerTitle: String?
    var publisher: String?
    var year: Int?
    var volume: String?
    var issue: String?
    var pages: String?
    var doi: String?
    var url: String?
    var accessedDate: Date?
    var license: String?
    var notes: String?

    // Inverse collection for Citation.source
    @Relationship(deleteRule: .cascade, inverse: \Citation.source)
    var citations: [Citation]? = []

    init(id: UUID = UUID(),
         title: String,
         authors: String,
         containerTitle: String? = nil,
         publisher: String? = nil,
         year: Int? = nil,
         volume: String? = nil,
         issue: String? = nil,
         pages: String? = nil,
         doi: String? = nil,
         url: String? = nil,
         accessedDate: Date? = nil,
         license: String? = nil,
         notes: String? = nil) {
        self.id = id
        self.title = title
        self.authors = authors
        self.containerTitle = containerTitle
        self.publisher = publisher
        self.year = year
        self.volume = volume
        self.issue = issue
        self.pages = pages
        self.doi = doi
        self.url = url
        self.accessedDate = accessedDate
        self.license = license
        self.notes = notes
    }
}

extension Source {
    var chicagoShort: String {
        // A very basic Chicago-like short form; refine as needed
        let author = authors.isEmpty ? "" : authors
        let yearStr = year.map { String($0) } ?? ""
        let titlePart = title.isEmpty ? "" : "“\(title)”"
        return [author, titlePart, yearStr].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var chicagoBibliography: String {
        var parts: [String] = []
        if !authors.isEmpty { parts.append(authors) }
        if !title.isEmpty { parts.append("“\(title).”") }
        if let container = containerTitle, !container.isEmpty { parts.append(container) }
        if let volume, !volume.isEmpty { parts.append(volume) }
        if let issue, !issue.isEmpty { parts.append("no. \(issue)") }
        if let pages, !pages.isEmpty { parts.append(pages) }
        if let publisher, !publisher.isEmpty { parts.append(publisher) }
        if let year { parts.append(String(year)) }
        if let doi, !doi.isEmpty { parts.append(doi) }
        if let url, !url.isEmpty { parts.append(url) }
        return parts.joined(separator: " ")
    }
}
