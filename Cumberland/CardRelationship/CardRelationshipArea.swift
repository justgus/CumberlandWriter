//
//  CardRelationshipArea.swift
//  Cumberland
//
//  Extracted from CardRelationshipView.swift as part of ER-0022 Phase 4.5
//  Contains the related cards display area for CardRelationshipView.
//

import SwiftUI

/// The main content area displaying related cards in CardRelationshipView.
struct CardRelationshipArea: View {
    let primaryName: String
    let selectedKind: Kinds
    let relatedCards: [Card]
    @Binding var selectedRelatedCard: Card?
    let areaCornerRadius: CGFloat

    // Decoration provider
    let decorationProvider: (Card) -> String?

    // Actions
    let onDropItems: ([String]) -> Bool
    let onAddExisting: () -> Void
    let onEditSelected: () -> Void
    let onChangeRelationType: () -> Void
    let onRemoveRelationship: () -> Void

    // State for context menu
    let hasExistingCandidates: Bool
    let hasRetypeChoices: Bool

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Background
                areaBackground

                // Content
                Group {
                    if relatedCards.isEmpty {
                        emptyState
                    } else {
                        cardGridContent
                    }
                }
                .padding(12)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .dropDestination(for: String.self) { items, _ in
                return onDropItems(items)
            }
            .contextMenu {
                contextMenuContent
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: areaCornerRadius, style: .continuous))
        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Subviews

    private var areaBackground: some View {
        let areaBackground = selectedKind.backgroundColor(for: scheme)
        return RoundedRectangle(cornerRadius: areaCornerRadius, style: .continuous)
            .fill(areaBackground)
            .overlay {
                RoundedRectangle(cornerRadius: areaCornerRadius, style: .continuous)
                    .stroke(selectedKind.accentColor(for: scheme).opacity(0.25), lineWidth: 1)
            }
            .innerShadow(cornerRadius: areaCornerRadius,
                         color: .black.opacity(0.35),
                         radius: 12,
                         offset: CGSize(width: 0, height: 3))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.and.text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No related \(selectedKind.title.lowercased())")
                .font(.headline)
            Text("Link cards of this kind to '\(primaryName)' to see them here.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cardGridContent: some View {
        ZStack(alignment: .topLeading) {
            CardViewer(
                cards: relatedCards,
                decorationProvider: decorationProvider,
                onSelect: { card in
                    selectedRelatedCard = card
                },
                selectedCardID: selectedRelatedCard?.id,
                showAIBadge: false
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selectedKind.accentColor(for: scheme).opacity(0.12), lineWidth: 1)
                )
                .innerShadow(
                    cornerRadius: 12,
                    color: .black.opacity(scheme == .dark ? 0.45 : 0.30),
                    radius: scheme == .dark ? 6 : 5,
                    offset: CGSize(width: 0, height: scheme == .dark ? 2 : 1.5)
                )
                .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.08), radius: 6, x: 0, y: 2)
        )
        .padding(4)
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            onAddExisting()
        } label: {
            Label("Add Existing \(selectedKind.title.dropLastIfPluralized())…", systemImage: "link.badge.plus")
        }
        .disabled(!hasExistingCandidates)

        Button {
            onEditSelected()
        } label: {
            Label("Edit Selected", systemImage: "pencil")
        }
        .disabled(selectedRelatedCard == nil)

        Button {
            onChangeRelationType()
        } label: {
            Label("Change Relationship Type…", systemImage: "arrow.triangle.2.circlepath")
        }
        .disabled(selectedRelatedCard == nil || !hasRetypeChoices)

        Divider()

        Button(role: .destructive) {
            onRemoveRelationship()
        } label: {
            Label("Remove Relationship", systemImage: "link")
                .symbolVariant(.slash)
        }
        .disabled(selectedRelatedCard == nil)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("CardRelationshipArea - Empty") {
    CardRelationshipArea(
        primaryName: "Test Character",
        selectedKind: .locations,
        relatedCards: [],
        selectedRelatedCard: .constant(nil),
        areaCornerRadius: 16,
        decorationProvider: { _ in nil },
        onDropItems: { _ in false },
        onAddExisting: {},
        onEditSelected: {},
        onChangeRelationType: {},
        onRemoveRelationship: {},
        hasExistingCandidates: true,
        hasRetypeChoices: true
    )
    .frame(height: 300)
    .padding()
}
#endif
