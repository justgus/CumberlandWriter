//
//  CardViewer.swift
//  Cumberland
//
//  Scrollable grid host for a collection of CardView tiles. Supports optional
//  per-card decoration text (e.g. relation-type labels), tap-selection with
//  external selection highlighting, and AI badge visibility toggling. Used
//  in relationship views, structure boards, and search results.
//

import SwiftUI
import SwiftData

struct CardViewer: View {
    let cards: [Card]

    // Optional provider for per-card decoration text (e.g., relation type label)
    var decorationProvider: ((Card) -> String?)? = nil

    // Optional tap-selection callback and externally-controlled selection highlight
    var onSelect: ((Card) -> Void)? = nil
    var selectedCardID: UUID? = nil

    // Control whether AI badges are shown on cards (ER-0009)
    var showAIBadge: Bool = true

    // MARK: - Tunable layout constants
    private let columnWidth: CGFloat = 420       // match your desired max card width
    private let columnSpacing: CGFloat = 16
    private let itemSpacing: CGFloat = 16
    private let contentPadding: CGFloat = 16

    // Prefer columns about 5 cards tall before wrapping
    private let preferredCardsPerColumn: Int = 5

    // Preference to collect measured heights for each card at columnWidth
    private struct ItemHeightsKey: PreferenceKey {
        static var defaultValue: [UUID: CGFloat] = [:]
        static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
            value.merge(nextValue(), uniquingKeysWith: { _, new in new })
        }
    }

    // Local state to hold measured heights
    @State private var itemHeights: [UUID: CGFloat] = [:]

    // MARK: - Sorting: by Kind order, then by Name
    private var sortedCards: [Card] {
        let kindOrder = Kinds.orderedCases
        func kindIndex(_ kind: Kinds) -> Int {
            kindOrder.firstIndex(of: kind) ?? Int.max
        }
        return cards.sorted { lhs, rhs in
            let li = kindIndex(lhs.kind)
            let ri = kindIndex(rhs.kind)
            if li != ri {
                return li < ri
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    var body: some View {
        // Compute a preferred column height that roughly fits 5 cards (based on measured/estimated average)
        let preferredHeight = preferredColumnHeight(
            for: sortedCards,
            heights: itemHeights,
            itemsPerColumn: preferredCardsPerColumn,
            itemSpacing: itemSpacing
        )

        // Compute columns once we have measurements/estimates
        let columns = makeColumns(
            from: sortedCards,
            heights: itemHeights,
            maxColumnHeight: preferredHeight,
            itemSpacing: itemSpacing
        )

        // Actual scrolling content: both directions
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            LazyHStack(alignment: .top, spacing: columnSpacing) {
                ForEach(columns.indices, id: \.self) { colIndex in
                    VStack(alignment: .leading, spacing: itemSpacing) {
                        ForEach(columns[colIndex]) { card in
                            let isSelected = (selectedCardID == card.id)
                            CardView(card: card, decorationText: decorationProvider?(card), showAIBadge: showAIBadge)
                                .frame(width: columnWidth, alignment: .topLeading)
                                .overlay(
                                    // Subtle selection ring
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.accentColor.opacity(isSelected ? 0.9 : 0.0), lineWidth: 2)
                                        .animation(.easeInOut(duration: 0.15), value: isSelected)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onSelect?(card)
                                }
                        }
                    }
                    .frame(width: columnWidth, alignment: .topLeading)
                }
            }
            .padding(.horizontal, contentPadding)
            .padding(.vertical, contentPadding)
        }
        // Measurement layer rendered as an overlay so it does NOT affect layout size.
        .overlay(alignment: .topLeading) {
            VStack(spacing: itemSpacing) {
                ForEach(sortedCards) { card in
                    CardView(card: card, decorationText: decorationProvider?(card), showAIBadge: showAIBadge)
                        .frame(width: columnWidth, alignment: .topLeading)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: ItemHeightsKey.self,
                                    value: [card.id: geo.size.height]
                                )
                            }
                        )
                }
            }
            .frame(width: columnWidth) // constrain measurement width
            .opacity(0.001)            // effectively invisible but still measures
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
        .onPreferenceChange(ItemHeightsKey.self) { newHeights in
            // Update measured heights when cards change size
            if newHeights != itemHeights {
                itemHeights = newHeights
            }
        }
    }

    // MARK: - Column packing (top-to-bottom, then left-to-right)
    private func makeColumns(
        from items: [Card],
        heights: [UUID: CGFloat],
        maxColumnHeight: CGFloat,
        itemSpacing: CGFloat
    ) -> [[Card]] {
        guard maxColumnHeight > 0 else { return [items] }

        var columns: [[Card]] = [[]]
        var currentHeight: CGFloat = 0

        for card in items {
            let h = heights[card.id] ?? estimatedHeightFallback(for: card)
            let added = (columns.last?.isEmpty == false) ? (itemSpacing + h) : h

            if currentHeight + added <= maxColumnHeight || columns.last?.isEmpty == true {
                columns[columns.count - 1].append(card)
                currentHeight += added
            } else {
                // Start a new column
                columns.append([card])
                currentHeight = h
            }
        }

        return columns
    }

    // Compute a preferred column height that fits approximately N cards (plus spacing),
    // using the average of available measured heights (falling back to estimates).
    private func preferredColumnHeight(
        for items: [Card],
        heights: [UUID: CGFloat],
        itemsPerColumn: Int,
        itemSpacing: CGFloat
    ) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        let sampleHeights: [CGFloat] = items.map { card in
            heights[card.id] ?? estimatedHeightFallback(for: card)
        }
        let average = sampleHeights.reduce(0, +) / CGFloat(sampleHeights.count)
        let count = max(1, min(itemsPerColumn, items.count))
        let totalSpacing = itemSpacing * CGFloat(max(0, count - 1))
        return average * CGFloat(count) + totalSpacing
    }

    // If we don't yet have a measured height, return a conservative estimate
    private func estimatedHeightFallback(for card: Card) -> CGFloat {
        // Rough estimate based on a typical card with some text.
        // This will be replaced quickly once measurements arrive.
        switch card.sizeCategory {
        case .compact:  return 120
        case .standard: return 160
        case .large:    return 220
        }
    }
}

#Preview {
    // Sample data with lorem to vary heights
    func loremLines(_ count: Int) -> String {
        let base = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt."
        return (1...count).map { "\($0). \(base)" }.joined(separator: "\n")
    }

    let samples: [Card] = [
        Card(kind: .projects,   name: "Project Alpha",   subtitle: "Kickoff",          detailedText: loremLines(4),  sizeCategory: .standard),
        Card(kind: .worlds,     name: "World: Aether",   subtitle: "Geography",        detailedText: loremLines(2),  sizeCategory: .compact),
        Card(kind: .characters, name: "Character: Mira", subtitle: "Scout",            detailedText: loremLines(8),  sizeCategory: .large),
        Card(kind: .scenes,     name: "Scene: Market",   subtitle: "Evening bustle",   detailedText: loremLines(6),  sizeCategory: .standard),
        Card(kind: .vehicles,   name: "Vehicle: Skiff",  subtitle: "Courier",          detailedText: loremLines(3),  sizeCategory: .compact),
        Card(kind: .characters, name: "Character: Aiden",subtitle: "Pilot",            detailedText: loremLines(5),  sizeCategory: .standard),
        Card(kind: .projects,   name: "Project Beta",    subtitle: "Planning",         detailedText: loremLines(10), sizeCategory: .large),
        Card(kind: .worlds,     name: "World: Nox",      subtitle: "Nightside Colony", detailedText: loremLines(7),  sizeCategory: .standard),
        Card(kind: .vehicles,   name: "Vehicle: Hauler", subtitle: "Freight",          detailedText: loremLines(3),  sizeCategory: .compact),
        Card(kind: .scenes,     name: "Scene: Docks",    subtitle: "Foggy morning",    detailedText: loremLines(9),  sizeCategory: .large)
    ]

    return NavigationStack {
        CardViewer(cards: samples, onSelect: { _ in }, selectedCardID: samples.first?.id)
            .navigationTitle("Column Flow Card Viewer")
    }
    .modelContainer(for: Card.self, inMemory: true)
}
