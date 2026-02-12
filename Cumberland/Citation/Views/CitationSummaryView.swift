//
//  CitationSummaryView.swift
//  Cumberland
//
//  Compact, read-only citation summary for embedding in card detail views
//  (CardSheetView, CardRelationshipView). Shows citation count and a brief
//  list of sources when citations exist; hidden when none.
//

import SwiftUI
import SwiftData

struct CitationSummaryView: View {
    let card: Card

    private var citations: [Citation] {
        card.citations ?? []
    }

    var body: some View {
        if !citations.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "quote.bubble")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(citations.count) Citation\(citations.count == 1 ? "" : "s")")
                        .font(.caption).bold()
                        .foregroundStyle(.secondary)
                }

                ForEach(Array(citations.prefix(5)), id: \.id) { c in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(kindColor(c.kind))
                            .frame(width: 6, height: 6)
                        Text(c.source?.chicagoShort ?? c.source?.title ?? "Untitled")
                            .font(.caption2)
                            .lineLimit(1)
                        if !c.locator.isEmpty {
                            Text("(\(c.locator))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                }

                if citations.count > 5 {
                    Text("+ \(citations.count - 5) more")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.background.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.quaternary, lineWidth: 0.5)
            )
        }
    }

    private func kindColor(_ kind: CitationKind) -> Color {
        switch kind {
        case .quote:      return .blue
        case .paraphrase: return .green
        case .image:      return .orange
        case .data:       return .purple
        }
    }
}
