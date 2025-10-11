// SearchResult.swift
import Foundation
import SwiftData

// MARK: - Search Result Types

struct SearchResult: Identifiable, Hashable {
    let id = UUID()
    let card: Card
    let matchType: MatchType
    let preview: String
    let matchRange: Range<String.Index>?
    
    enum MatchType: String, CaseIterable {
        case name = "Name"
        case subtitle = "Subtitle" 
        case details = "Details"
        case author = "Author"
        
        var systemImage: String {
            switch self {
            case .name: return "textformat"
            case .subtitle: return "text.below.photo"
            case .details: return "doc.text"
            case .author: return "person"
            }
        }
    }
    
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Search Engine

@Observable
final class SearchEngine {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func search(_ query: String, maxResults: Int = 50) async -> [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedQuery = trimmedQuery
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
        
        // Fetch all cards
        let fetchDescriptor = FetchDescriptor<Card>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        guard let allCards = try? modelContext.fetch(fetchDescriptor) else {
            return []
        }
        
        var results: [SearchResult] = []
        
        for card in allCards {
            // Search in name
            if let range = findMatch(in: card.name, query: normalizedQuery) {
                let preview = createPreview(from: card.name, range: range, query: trimmedQuery)
                results.append(SearchResult(
                    card: card,
                    matchType: .name,
                    preview: preview,
                    matchRange: range
                ))
            }
            
            // Search in subtitle
            if !card.subtitle.isEmpty,
               let range = findMatch(in: card.subtitle, query: normalizedQuery) {
                let preview = createPreview(from: card.subtitle, range: range, query: trimmedQuery)
                results.append(SearchResult(
                    card: card,
                    matchType: .subtitle,
                    preview: preview,
                    matchRange: range
                ))
            }
            
            // Search in detailed text
            if !card.detailedText.isEmpty,
               let range = findMatch(in: card.detailedText, query: normalizedQuery) {
                let preview = createPreview(from: card.detailedText, range: range, query: trimmedQuery)
                results.append(SearchResult(
                    card: card,
                    matchType: .details,
                    preview: preview,
                    matchRange: range
                ))
            }
            
            // Search in author
            if let author = card.author, !author.isEmpty,
               let range = findMatch(in: author, query: normalizedQuery) {
                let preview = createPreview(from: author, range: range, query: trimmedQuery)
                results.append(SearchResult(
                    card: card,
                    matchType: .author,
                    preview: preview,
                    matchRange: range
                ))
            }
            
            // Stop if we have enough results
            if results.count >= maxResults {
                break
            }
        }
        
        // Sort results by relevance (name matches first, then by card name)
        return results.sorted { lhs, rhs in
            if lhs.matchType == .name && rhs.matchType != .name {
                return true
            }
            if lhs.matchType != .name && rhs.matchType == .name {
                return false
            }
            return lhs.card.name < rhs.card.name
        }
    }
    
    private func findMatch(in text: String, query: String) -> Range<String.Index>? {
        let normalizedText = text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
        
        return normalizedText.range(of: query)
    }
    
    private func createPreview(from text: String, range: Range<String.Index>, query: String, contextLength: Int = 60) -> String {
        let beforeContext = max(0, contextLength / 2)
        let afterContext = contextLength - beforeContext
        
        let startIndex = text.index(range.lowerBound, offsetBy: -beforeContext, limitedBy: text.startIndex) ?? text.startIndex
        let endIndex = text.index(range.upperBound, offsetBy: afterContext, limitedBy: text.endIndex) ?? text.endIndex
        
        var preview = String(text[startIndex..<endIndex])
        
        // Add ellipsis if we truncated
        if startIndex > text.startIndex {
            preview = "…" + preview
        }
        if endIndex < text.endIndex {
            preview = preview + "…"
        }
        
        // Clean up whitespace and line breaks for display
        preview = preview
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        
        return preview
    }
}