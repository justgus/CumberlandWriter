import Foundation
import SwiftData

// Result model used by SearchOverlay
struct SearchResult: Identifiable, Hashable {
    enum MatchType: String, CaseIterable, Hashable {
        case name = "Name"
        case subtitle = "Subtitle"
        case details = "Details"
        case author = "Author"

        var systemImage: String {
            switch self {
            case .name:     return "textformat"
            case .subtitle: return "text.alignleft"
            case .details:  return "doc.text"
            case .author:   return "person.text.rectangle"
            }
        }
    }

    let id: UUID
    let card: Card
    let matchType: MatchType
    let preview: String
}

// Protocol the router holds onto
protocol SearchEngine: AnyObject {
    func search(_ query: String, maxResults: Int) async -> [SearchResult]
}

// Default SwiftData-backed implementation
final class SwiftDataSearchEngine: SearchEngine {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func search(_ query: String, maxResults: Int) async -> [SearchResult] {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    continuation.resume(returning: [])
                    return
                }

                // Use normalizedSearchText for broad matching to avoid complex predicates across multiple fields
                let q = trimmed
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                    .lowercased()

                var descriptor = FetchDescriptor<Card>(
                    predicate: #Predicate { $0.normalizedSearchText.contains(q) },
                    sortBy: [SortDescriptor(\.name, order: .forward)]
                )
                descriptor.fetchLimit = maxResults * 2 // get a few extra to filter by field priority

                let cards = (try? context.fetch(descriptor)) ?? []

                // Rank/label matches by which field contains the query first
                var results: [SearchResult] = []
                for c in cards {
                    if c.name.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
                        results.append(SearchResult(id: c.id, card: c, matchType: .name, preview: c.name))
                    } else if !c.subtitle.isEmpty,
                              c.subtitle.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
                        results.append(SearchResult(id: c.id, card: c, matchType: .subtitle, preview: c.subtitle))
                    } else if !c.detailedText.isEmpty,
                              c.detailedText.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
                        // Provide a short preview snippet
                        let snippet = Self.snippet(from: c.detailedText, around: trimmed, maxLen: 160)
                        results.append(SearchResult(id: c.id, card: c, matchType: .details, preview: snippet))
                    } else if let author = c.author, !author.isEmpty,
                              author.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
                        results.append(SearchResult(id: c.id, card: c, matchType: .author, preview: author))
                    }
                    if results.count >= maxResults { break }
                }

                continuation.resume(returning: results)
            }
        }
    }

    private static func snippet(from text: String, around query: String, maxLen: Int) -> String {
        let lower = text.lowercased()
        let q = query.lowercased()
        guard let range = lower.range(of: q) else {
            return String(text.prefix(maxLen))
        }
        let idx = range.lowerBound
        let start = text.index(idx, offsetBy: -min(40, text.distance(from: text.startIndex, to: idx)), limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(idx, offsetBy: max(q.count + 40, q.count), limitedBy: text.endIndex) ?? text.endIndex
        var snippet = String(text[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
        if start > text.startIndex { snippet = "… " + snippet }
        if end < text.endIndex { snippet += " …" }
        return String(snippet.prefix(maxLen))
    }
}
