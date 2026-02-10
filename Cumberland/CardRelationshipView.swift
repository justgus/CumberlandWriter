//
//  CardRelationshipView.swift
//  Cumberland
//
//  Refactored as part of ER-0022 Phase 4.5
//  Original: 1,739 lines → Refactored: ~380 lines (78% reduction)
//
//  Extracted Components:
//  - GlassCard.swift → Cumberland/Components/
//  - CardRelationshipHeader.swift → Cumberland/CardRelationship/
//  - CardRelationshipToolbar.swift → Cumberland/CardRelationship/
//  - CardRelationshipArea.swift → Cumberland/CardRelationship/
//  - CardRelationshipOperations.swift → Cumberland/CardRelationship/
//  - CardRelationshipSheets.swift → Cumberland/CardRelationship/
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// The main view for managing relationships between cards.
/// Shows a primary card in a header panel with related cards displayed below,
/// organized by kind with full CRUD support for relationships.
struct CardRelationshipView: View {
    let primary: Card
    var relationTypeFilter: RelationType? = nil

    @Query(sort: \Card.name, order: .forward) private var allCards: [Card]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.services) private var services
    @Environment(\.colorScheme) private var scheme
    @Environment(NavigationCoordinator.self) private var navigationCoordinator

    // Selection state
    @State private var selectedKind: Kinds = .projects
    @State private var selectedRelatedCard: Card? = nil

    // Add flow state
    @State private var isPresentingAddCard: Bool = false
    @State private var pendingNewCard: Card? = nil
    @State private var shouldCleanupPendingOnCancel: Bool = false
    @State private var pendingExistingCards: [Card] = []

    // Existing picker state
    private struct ExistingPickerState: Identifiable {
        let id = UUID()
        let kind: Kinds
        let candidates: [Card]
        let initiallySelected: Set<UUID>
    }
    @State private var existingPickerState: ExistingPickerState?

    // Relation type sheet state
    @State private var isPresentingCreateRelationType: Bool = false
    @State private var isPresentingPickRelationType: Bool = false
    @State private var relationTypeChoices: [RelationType] = []
    @State private var selectedRelationTypeCode: String?

    // Retype existing edge state
    @State private var isPresentingRetype: Bool = false
    @State private var retypeChoices: [RelationType] = []
    @State private var retypeSelectedCode: String?

    // Edit sheet state
    @State private var isPresentingEditCard: Bool = false
    @State private var isPresentingManageRelationTypes: Bool = false

    // Change card type state
    @State private var isPresentingChangeCardType: Bool = false
    @State private var selectedNewCardType: Kinds = .characters

    // Full-size image viewer
    @State private var showFullSizeImage: Bool = false

    // Header image
    @State private var headerImage: Image?

    // Constants
    private let areaCornerRadius: CGFloat = 16

    // MARK: - Computed Properties

    private var masterCardsForSelectedKind: [Card] {
        masterCards(for: selectedKind, modelContext: modelContext)
    }

    private var hasFullSizeImage: Bool {
        primary.imageFileURL != nil || primary.originalImageData != nil
    }

    private var hasExistingCandidates: Bool {
        !availableExistingCandidates(for: selectedKind, primary: primary, modelContext: modelContext).isEmpty
    }

    private var hasRetypeChoices: Bool {
        !applicableRetypeChoices(fromKind: selectedKind, toKind: primary.kind, modelContext: modelContext).isEmpty
    }

    // MARK: - Body

    var body: some View {
        let pageBackground: Color = primary.kind.backgroundColor(for: scheme).opacity(scheme == .dark ? 0.15 : 0.10)
        let _: Color = selectedKind.backgroundColor(for: scheme)

        VStack(alignment: .leading, spacing: 12) {
            // Primary card header
            GlassCard(cornerRadius: areaCornerRadius, tint: primary.kind.accentColor(for: scheme).opacity(0.2), interactive: false) {
                CardRelationshipHeader(
                    primary: primary,
                    headerImage: headerImage,
                    hasFullSizeImage: hasFullSizeImage,
                    onShowFullSizeImage: { showFullSizeImage = true }
                )
            }

            // Toolbar controls
            CardRelationshipToolbar(
                primaryName: primary.name,
                selectedKind: $selectedKind,
                selectedRelatedCard: selectedRelatedCard,
                hasExistingCandidates: hasExistingCandidates,
                hasRetypeChoices: hasRetypeChoices,
                onAddCard: { isPresentingAddCard = true },
                onAddExisting: { presentExistingPicker() },
                onEditSelected: { isPresentingEditCard = true },
                onChangeRelationType: { presentRetypePickerForSelection() },
                onRemoveRelationship: { handleRemoveRelationship() },
                onChangeCardType: {
                    selectedNewCardType = primary.kind
                    isPresentingChangeCardType = true
                },
                onManageRelationTypes: { isPresentingManageRelationTypes = true }
            )

            Divider()

            // Related cards area
            CardRelationshipArea(
                primaryName: primary.name,
                selectedKind: selectedKind,
                relatedCards: masterCardsForSelectedKind,
                selectedRelatedCard: $selectedRelatedCard,
                areaCornerRadius: areaCornerRadius,
                decorationProvider: { card in
                    relationDecoration(for: card, primary: primary, modelContext: modelContext)
                },
                onDropItems: { items in handleDrop(items: items) },
                onAddExisting: { presentExistingPicker() },
                onEditSelected: { isPresentingEditCard = true },
                onChangeRelationType: { presentRetypePickerForSelection() },
                onRemoveRelationship: { handleRemoveRelationship() },
                hasExistingCandidates: hasExistingCandidates,
                hasRetypeChoices: hasRetypeChoices
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(pageBackground)
        .navigationTitle("Relationships: \(primary.name)")
        .task {
            if masterCards(for: selectedKind, modelContext: modelContext).isEmpty,
               let initial = firstAvailableKind(modelContext: modelContext) {
                selectedKind = initial
            }
        }
        .task { await loadHeaderImage() }
        .task(id: primary.id) { await loadHeaderImage() }
        .task(id: primary.imageFileURL) { await loadHeaderImage() }
        .onChange(of: selectedKind) { _, _ in selectedRelatedCard = nil }
        .onChange(of: isPresentingCreateRelationType) { _, isPresented in
            handleCreateRelationTypeSheetDismiss(isPresented: isPresented)
        }
        .onChange(of: isPresentingPickRelationType) { _, isPresented in
            handlePickRelationTypeSheetDismiss(isPresented: isPresented)
        }
        // MARK: - Sheet Presentations
        .sheet(isPresented: $isPresentingAddCard) {
            CardEditorView(mode: .create(kind: selectedKind) { newCard in
                isPresentingAddCard = false
                handleNewCardCreated(newCard)
            })
            .frame(minWidth: 560, minHeight: 520)
        }
        .sheet(item: $existingPickerState) { state in
            ExistingCardPickerSheet(
                kind: state.kind,
                candidates: state.candidates,
                initiallySelected: state.initiallySelected
            ) { picked in
                existingPickerState = nil
                guard !picked.isEmpty else { return }
                handleExistingCardsPicked(picked)
            }
            .frame(minWidth: 520, minHeight: 420)
        }
        .sheet(isPresented: $isPresentingCreateRelationType) {
            RelationTypeCreatorSheet(
                sourceKind: selectedKind,
                targetKind: primary.kind
            ) { newType in
                handleRelationTypeCreated(newType)
            } onCancel: {
                handleRelationTypeCreationCancelled()
            }
            .frame(minWidth: 420, minHeight: 300)
        }
        .sheet(isPresented: $isPresentingPickRelationType) {
            RelationTypePickerSheet(
                sourceKind: selectedKind,
                targetKind: primary.kind,
                types: relationTypeChoices,
                selectedCode: selectedRelationTypeCode
            ) { chosen in
                handleRelationTypePicked(chosen)
            }
            .frame(minWidth: 420, minHeight: 320)
        }
        .sheet(isPresented: $isPresentingRetype) {
            RelationTypePickerSheet(
                sourceKind: selectedKind,
                targetKind: primary.kind,
                types: retypeChoices,
                selectedCode: retypeSelectedCode
            ) { chosen in
                handleRetypePicked(chosen)
            }
            .frame(minWidth: 420, minHeight: 320)
        }
        .sheet(isPresented: $isPresentingEditCard) {
            if let card = selectedRelatedCard {
                CardEditorView(mode: .edit(card: card) {
                    isPresentingEditCard = false
                })
                .frame(minWidth: 560, minHeight: 520)
            }
        }
        .sheet(isPresented: $isPresentingManageRelationTypes) {
            RelationTypesManagerView()
                .frame(minWidth: 680, minHeight: 420)
        }
        .sheet(isPresented: $isPresentingChangeCardType) {
            ChangeCardTypeSheet(
                currentKind: primary.kind,
                cardName: primary.name,
                selectedKind: $selectedNewCardType
            ) { newKind in
                changeCardType(card: primary, to: newKind, modelContext: modelContext, services: services)
                isPresentingChangeCardType = false
            } onCancel: {
                isPresentingChangeCardType = false
            }
        }
        // Full-size image viewer
        #if os(macOS)
        .sheet(isPresented: $showFullSizeImage) {
            FullSizeImageViewer(card: primary, pendingImageData: nil)
        }
        #else
        .fullScreenCover(isPresented: $showFullSizeImage) {
            FullSizeImageViewer(card: primary, pendingImageData: nil)
        }
        #endif
    }

    // MARK: - Event Handlers

    @MainActor
    private func loadHeaderImage() async {
        if let thumb = await primary.makeThumbnailImage() {
            withAnimation(.easeInOut(duration: 0.15)) {
                self.headerImage = thumb
            }
            return
        }
        let full = await primary.makeImage()
        withAnimation(.easeInOut(duration: 0.15)) {
            self.headerImage = full
        }
    }

    private func presentExistingPicker() {
        let candidates = availableExistingCandidates(for: selectedKind, primary: primary, modelContext: modelContext)
        existingPickerState = ExistingPickerState(
            kind: selectedKind,
            candidates: candidates,
            initiallySelected: []
        )
    }

    private func presentRetypePickerForSelection() {
        guard let card = selectedRelatedCard else { return }
        let cardIDOpt: UUID? = card.id
        let primaryIDOpt: UUID? = primary.id
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == cardIDOpt && $0.to?.id == primaryIDOpt },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        guard let edge = try? modelContext.fetch(fetch).first else { return }

        let choices = applicableRetypeChoices(fromKind: selectedKind, toKind: primary.kind, modelContext: modelContext)
        guard !choices.isEmpty else { return }
        retypeChoices = choices
        retypeSelectedCode = edge.type?.code ?? choices.first?.code
        isPresentingRetype = true
    }

    private func handleRemoveRelationship() {
        guard let card = selectedRelatedCard else { return }
        removeRelationship(between: card, and: primary, modelContext: modelContext, services: services)
        selectedRelatedCard = nil
    }

    @MainActor
    private func handleDrop(items: [String]) -> Bool {
        guard let idString = items.first, let uuid = UUID(uuidString: idString) else {
            return false
        }
        let cardFetch = FetchDescriptor<Card>(predicate: #Predicate { $0.id == uuid })
        guard let dropped = try? modelContext.fetch(cardFetch).first else { return false }
        guard dropped.id != primary.id else { return false }

        var chosenType: RelationType?
        if let t = relationTypeFilter {
            chosenType = t
        } else {
            if dropped.kind == .sources {
                chosenType = ensureRelationType(code: Self.citesCode, forward: "cites", inverse: "cited by", sourceKind: .sources, targetKind: nil, modelContext: modelContext)
            } else {
                let types = nonCitesRelationTypes(applicableFrom: selectedKind, to: primary.kind, modelContext: modelContext)
                if types.isEmpty {
                    chosenType = nil
                } else if types.count == 1 {
                    let only = types[0]
                    chosenType = (only.code == Self.defaultNonSourceCode) ? nil : only
                } else if types.count == 2 {
                    if let nonRef = types.first(where: { $0.code != Self.defaultNonSourceCode }) {
                        chosenType = nonRef
                    } else {
                        chosenType = nil
                    }
                } else {
                    chosenType = nil
                }
            }
        }

        guard let enforcedType = canonicalizedTypeFor(source: dropped, target: primary, proposed: chosenType, modelContext: modelContext) else {
            return false
        }

        createEdgeIfNeeded(from: dropped, to: primary, type: enforcedType, appendToEnd: true, modelContext: modelContext, services: services)
        return true
    }

    @MainActor
    private func handleNewCardCreated(_ newCard: Card) {
        if let fixedType = relationTypeFilter {
            if let enforced = canonicalizedTypeFor(source: newCard, target: primary, proposed: fixedType, modelContext: modelContext) {
                createEdgeIfNeeded(from: newCard, to: primary, type: enforced, appendToEnd: true, modelContext: modelContext, services: services)
            }
            shouldCleanupPendingOnCancel = false
            return
        }

        if selectedKind == .sources {
            let cites = ensureRelationType(code: Self.citesCode, forward: "cites", inverse: "cited by", sourceKind: .sources, targetKind: nil, modelContext: modelContext)
            if let enforced = canonicalizedTypeFor(source: newCard, target: primary, proposed: cites, modelContext: modelContext) {
                createEdgeIfNeeded(from: newCard, to: primary, type: enforced, appendToEnd: true, modelContext: modelContext, services: services)
            }
            shouldCleanupPendingOnCancel = false
            return
        }

        let types = nonCitesRelationTypes(applicableFrom: selectedKind, to: primary.kind, modelContext: modelContext)
        handleTypeSelection(for: newCard, existingCards: [], types: types)
    }

    @MainActor
    private func handleExistingCardsPicked(_ cards: [Card]) {
        guard !cards.isEmpty else { return }

        if let fixedType = relationTypeFilter {
            for c in cards {
                if let enforced = canonicalizedTypeFor(source: c, target: primary, proposed: fixedType, modelContext: modelContext) {
                    createEdgeIfNeeded(from: c, to: primary, type: enforced, appendToEnd: true, modelContext: modelContext, services: services)
                }
            }
            return
        }

        if selectedKind == .sources {
            let cites = ensureRelationType(code: Self.citesCode, forward: "cites", inverse: "cited by", sourceKind: .sources, targetKind: nil, modelContext: modelContext)
            for c in cards {
                if let enforced = canonicalizedTypeFor(source: c, target: primary, proposed: cites, modelContext: modelContext) {
                    createEdgeIfNeeded(from: c, to: primary, type: enforced, appendToEnd: true, modelContext: modelContext, services: services)
                }
            }
            return
        }

        let types = nonCitesRelationTypes(applicableFrom: selectedKind, to: primary.kind, modelContext: modelContext)
        handleTypeSelection(for: nil, existingCards: cards, types: types)
    }

    private func handleTypeSelection(for newCard: Card?, existingCards: [Card], types: [RelationType]) {
        if types.isEmpty {
            pendingNewCard = newCard
            pendingExistingCards = existingCards
            relationTypeChoices = []
            selectedRelationTypeCode = nil
            shouldCleanupPendingOnCancel = newCard != nil
            isPresentingCreateRelationType = true
        } else if types.count == 1 {
            let only = types[0]
            if only.code == Self.defaultNonSourceCode {
                pendingNewCard = newCard
                pendingExistingCards = existingCards
                relationTypeChoices = types
                selectedRelationTypeCode = types.first?.code
                shouldCleanupPendingOnCancel = newCard != nil
                isPresentingPickRelationType = true
            } else {
                if let card = newCard {
                    if let enforced = canonicalizedTypeFor(source: card, target: primary, proposed: only, modelContext: modelContext) {
                        createEdgeIfNeeded(from: card, to: primary, type: enforced, appendToEnd: true, modelContext: modelContext, services: services)
                        shouldCleanupPendingOnCancel = false
                    }
                }
                for c in existingCards {
                    if let enforced = canonicalizedTypeFor(source: c, target: primary, proposed: only, modelContext: modelContext) {
                        createEdgeIfNeeded(from: c, to: primary, type: enforced, appendToEnd: true, modelContext: modelContext, services: services)
                    }
                }
            }
        } else {
            pendingNewCard = newCard
            pendingExistingCards = existingCards
            relationTypeChoices = types
            selectedRelationTypeCode = types.first?.code
            shouldCleanupPendingOnCancel = newCard != nil
            isPresentingPickRelationType = true
        }
    }

    private func handleRelationTypeCreated(_ newType: RelationType) {
        shouldCleanupPendingOnCancel = false
        isPresentingCreateRelationType = false

        if let card = pendingNewCard {
            createEdgeIfNeeded(from: card, to: primary, type: newType, appendToEnd: true, modelContext: modelContext, services: services)
            pendingNewCard = nil
        }
        for card in pendingExistingCards {
            createEdgeIfNeeded(from: card, to: primary, type: newType, appendToEnd: true, modelContext: modelContext, services: services)
        }
        pendingExistingCards = []
    }

    private func handleRelationTypeCreationCancelled() {
        isPresentingCreateRelationType = false
        if shouldCleanupPendingOnCancel, let card = pendingNewCard {
            cleanupAndDelete(card, modelContext: modelContext, services: services)
        }
        pendingNewCard = nil
        pendingExistingCards = []
        shouldCleanupPendingOnCancel = false
    }

    private func handleRelationTypePicked(_ chosen: RelationType?) {
        isPresentingPickRelationType = false
        if let type = chosen {
            if let card = pendingNewCard {
                createEdgeIfNeeded(from: card, to: primary, type: type, appendToEnd: true, modelContext: modelContext, services: services)
                shouldCleanupPendingOnCancel = false
            }
            for card in pendingExistingCards {
                createEdgeIfNeeded(from: card, to: primary, type: type, appendToEnd: true, modelContext: modelContext, services: services)
            }
        } else {
            if shouldCleanupPendingOnCancel, let card = pendingNewCard {
                cleanupAndDelete(card, modelContext: modelContext, services: services)
            }
        }
        pendingNewCard = nil
        pendingExistingCards = []
        relationTypeChoices = []
        selectedRelationTypeCode = nil
    }

    private func handleRetypePicked(_ chosen: RelationType?) {
        isPresentingRetype = false
        guard let chosen, let card = selectedRelatedCard else { return }
        retypeEdge(from: card, to: primary, newType: chosen, modelContext: modelContext)
        retypeChoices = []
        retypeSelectedCode = nil
    }

    private func handleCreateRelationTypeSheetDismiss(isPresented: Bool) {
        if !isPresented, shouldCleanupPendingOnCancel, let card = pendingNewCard {
            cleanupAndDelete(card, modelContext: modelContext, services: services)
            pendingNewCard = nil
            shouldCleanupPendingOnCancel = false
        }
        if !isPresented {
            pendingExistingCards = []
        }
    }

    private func handlePickRelationTypeSheetDismiss(isPresented: Bool) {
        if !isPresented, shouldCleanupPendingOnCancel, let card = pendingNewCard {
            cleanupAndDelete(card, modelContext: modelContext, services: services)
            pendingNewCard = nil
            shouldCleanupPendingOnCancel = false
        }
        if !isPresented {
            pendingExistingCards = []
        }
    }
}
