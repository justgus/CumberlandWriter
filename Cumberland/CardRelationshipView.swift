// CardRelationshipView.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// Minimal glass-like container used for the primary header, similar in spirit to AdaptiveGlassToolbar.
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let tint: Color?
    let interactive: Bool
    let content: Content

    init(cornerRadius: CGFloat = 12, tint: Color? = nil, interactive: Bool = true, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.interactive = interactive
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.separator.opacity(0.6), lineWidth: 0.5)
                )
                .overlay(
                    Group {
                        if let tint {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(tint.opacity(0.10))
                                .allowsHitTesting(false)
                        }
                    }
                )
        } //end ZStack
        .compositingGroup()
        .shadow(color: .black.opacity(0.08), radius: interactive ? 6 : 4, x: 0, y: interactive ? 3 : 2)
        .overlay(
            // Host the provided content with reasonable padding
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(12)
        )
    }
} //end GlassCard

extension String {
    func dropLastIfPluralized() -> String {
        // Simple pluralization logic - drop 's' if the word ends with 's' and is longer than 1 character
        if self.count > 1 && self.hasSuffix("s") {
            return String(self.dropLast())
        }
        return self
    }
} //end extension String

/****
 * The main view.   this View shows a primary card in a panel on top, a small toolbar with some rudimentary controls
 *  with a collection of related cards in the lower panel.
 */
struct CardRelationshipView: View {
    let primary: Card

    @Query(sort: \Card.name, order: .forward) private var allCards: [Card]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @Environment(NavigationCoordinator.self) private var navigationCoordinator

    @State private var selectedKind: Kinds = .projects

    // Track selection inside the related area
    @State private var selectedRelatedCard: Card? = nil

    // Add flow state
    @State private var isPresentingAddCard: Bool = false
    @State private var pendingNewCard: Card? = nil
    // If true, and the relation type flow is canceled/dismissed, delete pendingNewCard
    @State private var shouldCleanupPendingOnCancel: Bool = false
    // Existing-cards batch awaiting relation type choice/creation
    @State private var pendingExistingCards: [Card] = []

    // Existing-card flow state (snapshot-driven)
    private struct ExistingPickerState: Identifiable {
        let id = UUID()
        let kind: Kinds
        let candidates: [Card]
        let initiallySelected: Set<UUID>
    }
    @State private var existingPickerState: ExistingPickerState?

    // Choose/create relation type state
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

    private let areaCornerRadius: CGFloat = 16

    // Optional relation type filter for this view (nil = any; drop uses default)
    var relationTypeFilter: RelationType? = nil

    // Relation type codes
    private let citesCode: String = "cites"
    private let defaultNonSourceCode: String = "references"
    private let canonicalSceneProjectCode: String = "stories/is-storied-by"

    // Header image for the primary card
    @State private var headerImage: Image?

    private func masterCards(for kind: Kinds) -> [Card] {
        // Fetch edges where to.id == primary.id (and optionally type.code == filter.code), then filter by from.kind in-memory
        let predicate: Predicate<CardEdge>
        let primaryIDOpt: UUID? = primary.id
        if let t = relationTypeFilter {
            let typeCodeOpt: String? = t.code
            predicate = #Predicate {
                $0.to?.id == primaryIDOpt && $0.type?.code == typeCodeOpt
            }
        } else {
            predicate = #Predicate {
                $0.to?.id == primaryIDOpt
            }
        }
        let fetch = FetchDescriptor<CardEdge>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        let edges = (try? modelContext.fetch(fetch)) ?? []
        let cards = edges.compactMap { $0.from }.filter { $0.kind == kind }
        // Unique + preserve first occurrence
        var seen: Set<UUID> = []
        var ordered: [Card] = []
        for c in cards {
            if !seen.contains(c.id) {
                seen.insert(c.id)
                ordered.append(c)
            }
        }
        return ordered
    }

    private var masterCardsForSelectedKind: [Card] {
        masterCards(for: selectedKind)
    }

    private func firstAvailableKind() -> Kinds? {
        for kind in Kinds.orderedCases {
            if !masterCards(for: kind).isEmpty {
                return kind
            }
        }
        return nil
    }

    private func hasRelated(for kind: Kinds) -> Bool {
        !masterCards(for: kind).isEmpty
    }

    var body: some View {
        let pageBackground: Color = primary.kind.backgroundColor(for: scheme).opacity(scheme == .dark ? 0.15 : 0.10)
        let areaBackground: Color = selectedKind.backgroundColor(for: scheme)

        VStack(alignment: .leading, spacing: 12) {
            GlassCard(cornerRadius: areaCornerRadius, tint: primary.kind.accentColor(for: scheme).opacity(0.2), interactive: false) {
                primaryHeader
            }

            AdaptiveGlassToolbar(tint: selectedKind.accentColor(for: scheme).opacity(0.3), interactive: true) {
                topControls
            }

            Divider()

            // Related area fills remaining window space; does not grow with inner content.
            relatedArea(areaBackground: areaBackground)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding()
        // Ensure this view takes the full window height so relatedArea gets a definite height.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(pageBackground)
        .navigationTitle("Relationships: \(primary.name)")
        .task {
            if !hasRelated(for: selectedKind), let initial = firstAvailableKind() {
                selectedKind = initial
            }
        }
        .task {
            await loadHeaderImage()
        }
        .task(id: primary.id) {
            await loadHeaderImage()
        }
        // MARK: - Sheets for Add flow
        .sheet(isPresented: $isPresentingAddCard) {
            CardEditorView(mode: .create(kind: selectedKind) { newCard in
                isPresentingAddCard = false
                handleNewCardCreated(newCard)
            })
            .frame(minWidth: 560, minHeight: 520)
        }
        // Existing cards picker (snapshot-based)
        .sheet(item: $existingPickerState) { state in
            ExistingCardPickerSheet(
                kind: state.kind,
                candidates: state.candidates,
                initiallySelected: state.initiallySelected
            ) { picked in
                existingPickerState = nil
                guard !picked.isEmpty else { return }
                // Batch relation-type resolution and apply to all
                handleExistingCardsPicked(picked)
            }
            .frame(minWidth: 520, minHeight: 420)
        }
        .sheet(isPresented: $isPresentingCreateRelationType) {
            RelationTypeCreatorSheet(
                sourceKind: selectedKind,
                targetKind: primary.kind
            ) { newType in
                // Success path: created a type; apply to any pending items (new or existing)
                shouldCleanupPendingOnCancel = false
                isPresentingCreateRelationType = false

                if let card = pendingNewCard {
                    createEdgeIfNeeded(from: card, to: primary, type: newType, appendToEnd: true)
                    pendingNewCard = nil
                }
                if !pendingExistingCards.isEmpty {
                    for card in pendingExistingCards {
                        createEdgeIfNeeded(from: card, to: primary, type: newType, appendToEnd: true)
                    }
                    pendingExistingCards = []
                }
            } onCancel: {
                // User canceled — delete pending card if any (only for new card flow)
                isPresentingCreateRelationType = false
                if shouldCleanupPendingOnCancel, let card = pendingNewCard {
                    cleanupAndDelete(card)
                }
                // Never delete existing cards
                pendingNewCard = nil
                pendingExistingCards = []
                shouldCleanupPendingOnCancel = false
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
                isPresentingPickRelationType = false
                if let type = chosen {
                    // Apply to any pending items (new or existing)
                    if let card = pendingNewCard {
                        createEdgeIfNeeded(from: card, to: primary, type: type, appendToEnd: true)
                        shouldCleanupPendingOnCancel = false
                    }
                    if !pendingExistingCards.isEmpty {
                        for card in pendingExistingCards {
                            createEdgeIfNeeded(from: card, to: primary, type: type, appendToEnd: true)
                        }
                    }
                } else {
                    // Canceled — delete pending new card only; never delete existing
                    if shouldCleanupPendingOnCancel, let card = pendingNewCard {
                        cleanupAndDelete(card)
                    }
                }
                pendingNewCard = nil
                pendingExistingCards = []
                relationTypeChoices = []
                selectedRelationTypeCode = nil
            }
            .frame(minWidth: 420, minHeight: 320)
        }
        // Retype sheet for existing edge
        .sheet(isPresented: $isPresentingRetype) {
            RelationTypePickerSheet(
                sourceKind: selectedKind,
                targetKind: primary.kind,
                types: retypeChoices,
                selectedCode: retypeSelectedCode
            ) { chosen in
                isPresentingRetype = false
                guard let chosen, let card = selectedRelatedCard else { return }
                retypeEdge(from: card, to: primary, newType: chosen)
                retypeChoices = []
                retypeSelectedCode = nil
            }
            .frame(minWidth: 420, minHeight: 320)
        }
        // Edit selected related card
        .sheet(isPresented: $isPresentingEditCard) {
            if let card = selectedRelatedCard {
                CardEditorView(mode: .edit(card: card) {
                    isPresentingEditCard = false
                })
                .frame(minWidth: 560, minHeight: 520)
            }
        }
        // Also handle dismissals (e.g., swipe/escape) that bypass our cancel buttons.
        .onChange(of: isPresentingCreateRelationType) { _, isPresented in
            if !isPresented, shouldCleanupPendingOnCancel, let card = pendingNewCard {
                cleanupAndDelete(card)
                pendingNewCard = nil
                shouldCleanupPendingOnCancel = false
            }
            if !isPresented {
                pendingExistingCards = []
            }
        }
        .onChange(of: isPresentingPickRelationType) { _, isPresented in
            if !isPresented, shouldCleanupPendingOnCancel, let card = pendingNewCard {
                cleanupAndDelete(card)
                pendingNewCard = nil
                shouldCleanupPendingOnCancel = false
            }
            if !isPresented {
                pendingExistingCards = []
            }
        }
        .onChange(of: selectedKind) { _, _ in
            // Clear selection when changing lanes
            selectedRelatedCard = nil
        }
    } //end var body

    private var primaryHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: primary.kind.systemImage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(primary.kind.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .top, spacing: 10) {
                // Ensure the name/subtitle never collapses
                VStack(alignment: .leading, spacing: 6) {
                    Text(primary.name)
                        .font(.title3).bold()
                    if !primary.subtitle.isEmpty {
                        Text(primary.subtitle)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } //end if subtitle is not empty
                }
                .frame(minWidth: 160, alignment: .leading)
                .layoutPriority(3) // highest priority: keep visible

                // Detailed text (if any) — allow it to yield space and wrap
                if !primary.detailedText.isEmpty {
                    let maxLines = (headerImage == nil) ? 10 : 6
                    Text(primary.detailedText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(maxLines)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(0) // lower than name/subtitle
                }

                // Primary image to the right of the detailed text (if available)
                if let headerImage {
                    headerImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(.quaternary, lineWidth: 0.8)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                        .accessibilityLabel("Card Image")
                }
            } //end HStack
        } //end VStack
    } //end primary header

    private var topControls: some View {
        HStack(spacing: 8) {
            Text("Related Kind:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Picker(selection: $selectedKind) {
                ForEach(Kinds.orderedCases) { kind in
                    Label(kind.title, systemImage: kind.systemImage)
                        .tag(kind)
                }
            } label: {
                EmptyView()
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .glassButtonStyle()

            // Dynamic Add button label depending on whether we're adding the same kind as the primary
            let addTitle: String = (selectedKind == primary.kind)
                ? "Add Sub \(selectedKind.title.dropLastIfPluralized())"
                : "Add \(selectedKind.title.dropLastIfPluralized())"

            Button {
                isPresentingAddCard = true
            } label: {
                Label(addTitle, systemImage: "plus")
            }
            .help("Create a new \(selectedKind.title.dropLastIfPluralized()) and relate it to “\(primary.name)”")

            Button {
                presentExistingPicker()
            } label: {
                Label("Add Existing \(selectedKind.title.dropLastIfPluralized())…", systemImage: "link.badge.plus")
            }
            .disabled(availableExistingCandidates(for: selectedKind).isEmpty)

            // Restore Edit button
            Button {
                isPresentingEditCard = true
            } label: {
                Label("Edit Selected", systemImage: "pencil")
            }
            .disabled(selectedRelatedCard == nil)
            .help("Edit the selected related card")

            // New: Change Relationship Type…
            Button {
                presentRetypePickerForSelection()
            } label: {
                Label("Change Relationship Type…", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(selectedRelatedCard == nil || applicableRetypeChoices().isEmpty)
            .help("Change the relationship type between the selected card and “\(primary.name)”")

            Spacer()
        }
    }

    private func relatedArea(areaBackground: Color) -> some View {
        GeometryReader { proxy in
            // Fill the offered space from the parent (window), independent of inner content.
            ZStack {
                RoundedRectangle(cornerRadius: areaCornerRadius, style: .continuous)
                    .fill(areaBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: areaCornerRadius, style: .continuous)
                            .stroke(selectedKind.accentColor(for: scheme).opacity(0.25), lineWidth: 1)
                    }
                    .innerShadow(cornerRadius: areaCornerRadius,
                                 color: .black.opacity(0.35),
                                 radius: 12,
                                 offset: CGSize(width: 0, height: 3))

                Group {
                    if masterCardsForSelectedKind.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "rectangle.and.text.magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                            Text("No related \(selectedKind.title.lowercased())")
                                .font(.headline)
                            Text("Link cards of this kind to “\(primary.name)” to see them here.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Inner neutral “content well” sized to fill the area.
                        ZStack(alignment: .topLeading) {
                            CardViewer(
                                cards: masterCardsForSelectedKind,
                                decorationProvider: { card in
                                    relationDecoration(for: card)
                                },
                                onSelect: { card in
                                    selectedRelatedCard = card
                                },
                                selectedCardID: selectedRelatedCard?.id
                            )
                            // CardViewer fills the parent, its own ScrollView handles overflow.
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.background) // neutral system background for contrast
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(selectedKind.accentColor(for: scheme).opacity(0.12), lineWidth: 1)
                                )
                                // Add a subtle inner shadow so the CardViewer appears inset "inside" the well
                                .innerShadow(
                                    cornerRadius: 12,
                                    color: .black.opacity(scheme == .dark ? 0.45 : 0.30),
                                    radius: scheme == .dark ? 6 : 5,
                                    offset: CGSize(width: 0, height: scheme == .dark ? 2 : 1.5)
                                )
                                // Keep a soft outer shadow for separation from the colored area
                                .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.08), radius: 6, x: 0, y: 2)
                        )
                        .padding(4) // breathing room inside the colored area
                    }
                }
                .padding(12)
            } //end ZStack
            // Explicitly size the ZStack to the GeometryReader’s available size.
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            // Make the whole area interactive for right-clicks.
            .contentShape(Rectangle())
            // Accept drops across the full area.
            .dropDestination(for: String.self) { items, _ in
                return handleDrop(items: items)
            }
            // One context menu for both empty and non-empty states
            .contextMenu {
                addExistingContextMenuItem()
                // Context edit if there is a selection
                Button {
                    isPresentingEditCard = true
                } label: {
                    Label("Edit Selected", systemImage: "pencil")
                }
                .disabled(selectedRelatedCard == nil)

                Button {
                    presentRetypePickerForSelection()
                } label: {
                    Label("Change Relationship Type…", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(selectedRelatedCard == nil || applicableRetypeChoices().isEmpty)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: areaCornerRadius, style: .continuous))
        // Give it a sensible minimum, but let it expand to fill remaining space from the parent.
        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: .infinity, alignment: .top)
    }

    // Context menu item builder
    @ViewBuilder
    private func addExistingContextMenuItem() -> some View {
        Button {
            presentExistingPicker()
        } label: {
            Label("Add Existing \(selectedKind.title.dropLastIfPluralized())…", systemImage: "link.badge.plus")
        }
        .disabled(availableExistingCandidates(for: selectedKind).isEmpty)
    }

    // Provide the decoration text for a given related card.
    // If a filter is active, we can return its forward label directly.
    // Otherwise, fetch the first edge from this card to the primary and return its type's forward label.
    private func relationDecoration(for card: Card) -> String? {
        if let t = relationTypeFilter {
            return t.forwardLabel
        }
        let cardIDOpt: UUID? = card.id
        let primaryIDOpt: UUID? = primary.id
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate {
                $0.from?.id == cardIDOpt && $0.to?.id == primaryIDOpt
            }
        )
        if let edge = try? modelContext.fetch(fetch).first {
            return edge.type?.forwardLabel
        }
        return nil
    }

    // MARK: - Canonicalization and validation

    private func canonicalizedTypeFor(source: Card, target: Card, proposed: RelationType?) -> RelationType? {
        // If Scene -> Project, force canonical type
        if source.kind == .scenes && target.kind == .projects {
            let fetch = FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == canonicalSceneProjectCode })
            if let canonical = try? modelContext.fetch(fetch).first {
                return canonical
            } else {
                // Create if missing (should be present from seeding) + create its mirror
                let t = RelationType(code: canonicalSceneProjectCode, forwardLabel: "stories", inverseLabel: "is storied by", sourceKind: .scenes, targetKind: .projects)
                modelContext.insert(t)

                // Ensure mirror exists: Projects -> Scenes with swapped labels
                let mirrorCode = "is-storied-by/stories"
                let existsMirror = (try? modelContext.fetch(FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == mirrorCode })))?.first
                if existsMirror == nil {
                    let mirror = RelationType(code: mirrorCode, forwardLabel: "is storied by", inverseLabel: "stories", sourceKind: .projects, targetKind: .scenes)
                    modelContext.insert(mirror)
                }

                try? modelContext.save()
                return t
            }
        }

        // Otherwise, return proposed if it matches the kinds
        if let proposed, proposed.matches(from: source.kind, to: target.kind) {
            return proposed
        }

        // No valid type
        return nil
    }

    // MARK: - Drop handling extracted to reduce type-checking complexity
    @MainActor
    private func handleDrop(items: [String]) -> Bool {
        guard let idString = items.first, let uuid = UUID(uuidString: idString) else {
            return false
        }
        // Fetch dropped
        let cardFetch = FetchDescriptor<Card>(predicate: #Predicate { $0.id == uuid })
        guard let dropped = try? modelContext.fetch(cardFetch).first else { return false }
        guard dropped.id != primary.id else { return false }

        // Decide relation type: filter or default
        var chosenType: RelationType?
        if let t = relationTypeFilter {
            chosenType = t
        } else {
            if dropped.kind == .sources {
                // Sources may only "cites" -> ensure and use it (Option A: target = any)
                chosenType = ensureRelationType(code: citesCode, forward: "cites", inverse: "cited by", sourceKind: .sources, targetKind: nil)
            } else {
                // Non-sources: consider only types that apply to selectedKind -> primary.kind and are not "cites"
                let types = nonCitesRelationTypes(applicableFrom: selectedKind, to: primary.kind)
                if types.isEmpty {
                    chosenType = nil
                } else if types.count == 1 {
                    let only = types[0]
                    chosenType = (only.code == defaultNonSourceCode) ? nil : only
                } else if types.count == 2 {
                    if let nonRef = types.first(where: { $0.code != defaultNonSourceCode }) {
                        chosenType = nonRef
                    } else {
                        chosenType = nil
                    }
                } else {
                    chosenType = nil
                }
            }
        }

        // Enforce canonicalization (e.g., Scene→Project)
        guard let enforcedType = canonicalizedTypeFor(source: dropped, target: primary, proposed: chosenType) else {
            return false
        }

        // Create both forward and reverse edges (if missing), appending to end of their lanes
        createEdgeIfNeeded(from: dropped, to: primary, type: enforcedType, appendToEnd: true)
        return true
    }

    // MARK: - Add flow helpers

    @MainActor
    private func handleNewCardCreated(_ newCard: Card) {
        // If this view is constrained to a specific relation type, use it (but still canonicalize).
        if let fixedType = relationTypeFilter {
            let enforced = canonicalizedTypeFor(source: newCard, target: primary, proposed: fixedType)
            if let enforced {
                createEdgeIfNeeded(from: newCard, to: primary, type: enforced, appendToEnd: true)
            }
            shouldCleanupPendingOnCancel = false
            return
        }

        // Sources: must use "cites" (auto-use/create; no picker). Option A: target = any.
        if selectedKind == .sources {
            let cites = ensureRelationType(code: "cites", forward: "cites", inverse: "cited by", sourceKind: .sources, targetKind: nil)
            if let enforced = canonicalizedTypeFor(source: newCard, target: primary, proposed: cites) {
                createEdgeIfNeeded(from: newCard, to: primary, type: enforced, appendToEnd: true)
            }
            shouldCleanupPendingOnCancel = false
            return
        }

        // Otherwise, consider all available RelationTypes EXCEPT "cites", applicable to selectedKind -> primary.kind
        let types = nonCitesRelationTypes(applicableFrom: selectedKind, to: primary.kind)

        if types.isEmpty {
            // No usable types exist — prompt to create one
            pendingNewCard = newCard
            relationTypeChoices = []
            selectedRelationTypeCode = nil
            shouldCleanupPendingOnCancel = true
            isPresentingCreateRelationType = true
        } else if types.count == 1 {
            let only = types[0]
            if only.code == defaultNonSourceCode {
                // Only 'references' exists — require explicit choice
                pendingNewCard = newCard
                relationTypeChoices = types
                selectedRelationTypeCode = types.first?.code
                shouldCleanupPendingOnCancel = true
                isPresentingPickRelationType = true
            } else {
                if let enforced = canonicalizedTypeFor(source: newCard, target: primary, proposed: only) {
                    createEdgeIfNeeded(from: newCard, to: primary, type: enforced, appendToEnd: true)
                    shouldCleanupPendingOnCancel = false
                } else {
                    // No valid type after enforcement; fall back to picker
                    pendingNewCard = newCard
                    relationTypeChoices = types
                    selectedRelationTypeCode = types.first?.code
                    shouldCleanupPendingOnCancel = true
                    isPresentingPickRelationType = true
                }
            }
        } else if types.count == 2 {
            // If one is 'references', use the other; else ambiguous -> picker
            if let nonRef = types.first(where: { $0.code != defaultNonSourceCode }) {
                if let enforced = canonicalizedTypeFor(source: newCard, target: primary, proposed: nonRef) {
                    createEdgeIfNeeded(from: newCard, to: primary, type: enforced, appendToEnd: true)
                    shouldCleanupPendingOnCancel = false
                } else {
                    pendingNewCard = newCard
                    relationTypeChoices = types
                    selectedRelationTypeCode = types.first?.code
                    shouldCleanupPendingOnCancel = true
                    isPresentingPickRelationType = true
                }
            } else {
                pendingNewCard = newCard
                relationTypeChoices = types
                selectedRelationTypeCode = types.first?.code
                shouldCleanupPendingOnCancel = true
                isPresentingPickRelationType = true
            }
        } else {
            // >= 3 — show picker
            pendingNewCard = newCard
            relationTypeChoices = types
            selectedRelationTypeCode = types.first?.code
            shouldCleanupPendingOnCancel = true
            isPresentingPickRelationType = true
        }
    }

    // Existing cards picked (batch)
    @MainActor
    private func handleExistingCardsPicked(_ cards: [Card]) {
        guard !cards.isEmpty else { return }

        // If constrained to a specific relation type, use it for all (after canonicalization)
        if let fixedType = relationTypeFilter {
            for c in cards {
                if let enforced = canonicalizedTypeFor(source: c, target: primary, proposed: fixedType) {
                    createEdgeIfNeeded(from: c, to: primary, type: enforced, appendToEnd: true)
                }
            }
            return
        }

        // Sources: must use "cites" for all
        if selectedKind == .sources {
            let cites = ensureRelationType(code: "cites", forward: "cites", inverse: "cited by", sourceKind: .sources, targetKind: nil)
            for c in cards {
                if let enforced = canonicalizedTypeFor(source: c, target: primary, proposed: cites) {
                    createEdgeIfNeeded(from: c, to: primary, type: enforced, appendToEnd: true)
                }
            }
            return
        }

        // Otherwise, consider available non-“cites” types applicable to selectedKind -> primary.kind
        let types = nonCitesRelationTypes(applicableFrom: selectedKind, to: primary.kind)

        if types.isEmpty {
            // No usable types exist — prompt to create one, then apply to all
            pendingExistingCards = cards
            relationTypeChoices = []
            selectedRelationTypeCode = nil
            // Do NOT mark shouldCleanupPendingOnCancel; we never delete existing cards
            shouldCleanupPendingOnCancel = false
            isPresentingCreateRelationType = true
        } else if types.count == 1 {
            let only = types[0]
            if only.code == defaultNonSourceCode {
                // Only 'references' exists — require explicit choice for batch
                pendingExistingCards = cards
                relationTypeChoices = types
                selectedRelationTypeCode = types.first?.code
                shouldCleanupPendingOnCancel = false
                isPresentingPickRelationType = true
            } else {
                for c in cards {
                    if let enforced = canonicalizedTypeFor(source: c, target: primary, proposed: only) {
                        createEdgeIfNeeded(from: c, to: primary, type: enforced, appendToEnd: true)
                    }
                }
            }
        } else if types.count == 2 {
            // If one is 'references', use the other; else ambiguous -> picker
            if let nonRef = types.first(where: { $0.code != defaultNonSourceCode }) {
                for c in cards {
                    if let enforced = canonicalizedTypeFor(source: c, target: primary, proposed: nonRef) {
                        createEdgeIfNeeded(from: c, to: primary, type: enforced, appendToEnd: true)
                    }
                }
            } else {
                pendingExistingCards = cards
                relationTypeChoices = types
                selectedRelationTypeCode = types.first?.code
                shouldCleanupPendingOnCancel = false
                isPresentingPickRelationType = true
            }
        } else {
            // >= 3 — show picker
            pendingExistingCards = cards
            relationTypeChoices = types
            selectedRelationTypeCode = types.first?.code
            shouldCleanupPendingOnCancel = false
            isPresentingPickRelationType = true
        }
    }

    // MARK: - Mirror helpers (types + edges)

    private func mirrorType(for type: RelationType, sourceKind: Kinds, targetKind: Kinds) -> RelationType {
        // Expected code derived from labels with swapped order
        let desiredCode = makeCode(forward: type.inverseLabel, inverse: type.forwardLabel)
        if let existing = fetchRelationType(code: desiredCode) {
            return existing
        }

        // If not found, ensure/create mirror with swapped kinds and labels
        ensureMirror(forwardLabel: type.forwardLabel, inverseLabel: type.inverseLabel, sourceKind: sourceKind, targetKind: targetKind)
        // Try to fetch again (with or without suffix)
        if let exact = fetchRelationType(code: desiredCode) {
            return exact
        }
        // Fallback: find any applicable type that matches swapped kinds and swapped labels
        let all = (try? modelContext.fetch(FetchDescriptor<RelationType>())) ?? []
        if let match = all.first(where: {
            ($0.sourceKindRaw == targetKind.rawValue || $0.sourceKindRaw == nil) &&
            ($0.targetKindRaw == sourceKind.rawValue || $0.targetKindRaw == nil) &&
            $0.forwardLabel == type.inverseLabel &&
            $0.inverseLabel == type.forwardLabel
        }) {
            return match
        }
        // As a last step, create one with a unique code.
        var codeToUse = desiredCode
        var suffix = 1
        while fetchRelationType(code: codeToUse) != nil {
            suffix += 1
            codeToUse = makeCode(forward: type.inverseLabel, inverse: type.forwardLabel, suffix: suffix)
        }
        let mirror = RelationType(code: codeToUse, forwardLabel: type.inverseLabel, inverseLabel: type.forwardLabel, sourceKind: targetKind, targetKind: sourceKind)
        modelContext.insert(mirror)
        try? modelContext.save()
        return mirror
    }

    // Create the reverse edge if it doesn’t exist, using the mirror type.
    @MainActor
    private func ensureReverseEdge(forwardEdge: CardEdge, appendToEnd: Bool) {
        guard let src = forwardEdge.from, let dst = forwardEdge.to, let t = forwardEdge.type else { return }
        // Avoid duplicates
        let srcID: UUID? = src.id
        let dstID: UUID? = dst.id
        let existsFetch = FetchDescriptor<CardEdge>(predicate: #Predicate {
            $0.from?.id == dstID && $0.to?.id == srcID
        })
        if let found = try? modelContext.fetch(existsFetch), found.isEmpty == false {
            return
        }

        // Compute mirror type
        let mirror = mirrorType(for: t, sourceKind: src.kind, targetKind: dst.kind)

        // Determine createdAt for reverse lane
        let createdAt: Date
        if appendToEnd {
            let mirrorCode: String? = mirror.code
            let fetchForMax = FetchDescriptor<CardEdge>(
                predicate: #Predicate {
                    $0.to?.id == srcID && $0.type?.code == mirrorCode
                },
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let existing = (try? modelContext.fetch(fetchForMax)) ?? []
            let last = existing.last?.createdAt ?? (forwardEdge.createdAt)
            createdAt = last.addingTimeInterval(0.001)
        } else {
            createdAt = forwardEdge.createdAt
        }

        let reverse = CardEdge(from: dst, to: src, type: mirror, note: forwardEdge.note, createdAt: createdAt)
        modelContext.insert(reverse)
        try? modelContext.save()
    }

    @MainActor
    private func createEdgeIfNeeded(from source: Card, to target: Card, type: RelationType) {
        createEdgeIfNeeded(from: source, to: target, type: type, appendToEnd: true)
    }

    @MainActor
    private func createEdgeIfNeeded(from source: Card, to target: Card, type: RelationType, appendToEnd: Bool) {
        // Enforce canonical type for Scene→Project
        guard let enforcedType = canonicalizedTypeFor(source: source, target: target, proposed: type) else {
            return
        }

        // Avoid duplicates (compare scalar fields)
        let sourceIDOpt: UUID? = source.id
        let targetIDOpt: UUID? = target.id
        let typeCodeOpt: String? = enforcedType.code
        let existsFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate {
                $0.from?.id == sourceIDOpt && $0.to?.id == targetIDOpt && $0.type?.code == typeCodeOpt
            }
        )
        if let found = try? modelContext.fetch(existsFetch), found.isEmpty == false {
            // Even if forward exists, make sure reverse exists
            if let existingEdge = found.first {
                ensureReverseEdge(forwardEdge: existingEdge, appendToEnd: appendToEnd)
            }
            return
        }

        // Determine createdAt: append to end by default
        let createdAt: Date
        if appendToEnd {
            let fetchForMax = FetchDescriptor<CardEdge>(
                predicate: #Predicate {
                    $0.to?.id == targetIDOpt && $0.type?.code == typeCodeOpt
                },
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let existing = (try? modelContext.fetch(fetchForMax)) ?? []
            let last = existing.last?.createdAt ?? Date()
            createdAt = last.addingTimeInterval(0.001)
        } else {
            createdAt = Date()
        }

        let edge = CardEdge(from: source, to: target, type: enforcedType, note: nil, createdAt: createdAt)
        modelContext.insert(edge)
        try? modelContext.save()

        // Ensure reverse edge exists using mirror type
        ensureReverseEdge(forwardEdge: edge, appendToEnd: appendToEnd)
    }

    // Retype the existing edge between source and target (and mirror in reverse)
    @MainActor
    private func retypeEdge(from source: Card, to target: Card, newType: RelationType) {
        // Canonicalize; if Scene→Project, this will force the canonical type regardless of chosen
        guard let enforced = canonicalizedTypeFor(source: source, target: target, proposed: newType) else { return }

        let sourceIDOpt: UUID? = source.id
        let targetIDOpt: UUID? = target.id
        // Fetch all edges from source->target (any type); if multiple, retype the first
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == sourceIDOpt && $0.to?.id == targetIDOpt },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        guard let edge = try? modelContext.fetch(fetch).first else { return }

        // If already the same type, nothing to do
        if edge.type?.code == enforced.code { return }

        edge.type = enforced
        try? modelContext.save()

        // Also retype reverse edge if present
        let reverseFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == targetIDOpt && $0.to?.id == sourceIDOpt },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        if let reverseEdge = try? modelContext.fetch(reverseFetch).first {
            let mirror = mirrorType(for: enforced, sourceKind: source.kind, targetKind: target.kind)
            reverseEdge.type = mirror
            try? modelContext.save()
        } else {
            // If reverse edge missing, create it now to keep pairs consistent
            ensureReverseEdge(forwardEdge: edge, appendToEnd: true)
        }
    }

    // Delete a pending card safely (including its image files/caches)
    @MainActor
    private func cleanupAndDelete(_ card: Card) {
        card.cleanupBeforeDeletion()
        modelContext.delete(card)
        try? modelContext.save()
    }

    // MARK: - RelationType helpers

    private func fetchRelationType(code: String) -> RelationType? {
        let fetch = FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == code })
        return try? modelContext.fetch(fetch).first
    }

    // Ensure a forward type exists and also ensure its mirror exists.
    @discardableResult
    private func ensureRelationType(code: String, forward: String, inverse: String, sourceKind: Kinds? = nil, targetKind: Kinds? = nil) -> RelationType {
        if let existing = fetchRelationType(code: code) {
            // Ensure its mirror exists even if forward already did
            ensureMirror(forwardLabel: forward, inverseLabel: inverse, sourceKind: sourceKind, targetKind: targetKind)
            return existing
        }
        let type = RelationType(code: code, forwardLabel: forward, inverseLabel: inverse, sourceKind: sourceKind, targetKind: targetKind)
        modelContext.insert(type)

        // Create the mirror pair
        ensureMirror(forwardLabel: forward, inverseLabel: inverse, sourceKind: sourceKind, targetKind: targetKind)

        try? modelContext.save()
        return type
    }

    // Create the inverted relation type if it doesn't exist yet.
    private func ensureMirror(forwardLabel: String, inverseLabel: String, sourceKind: Kinds?, targetKind: Kinds?) {
        // Mirror swaps source/target kinds and swaps labels.
        let mirrorForward = inverseLabel
        let mirrorInverse = forwardLabel
        let mirrorSource = targetKind
        let mirrorTarget = sourceKind

        // Prefer a code derived from labels "inverse/forward" to be symmetric with the forward "forward/inverse".
        let desiredCode = makeCode(forward: mirrorForward, inverse: mirrorInverse)
        if fetchRelationType(code: desiredCode) != nil {
            return
        }

        // If that desired code collides, add a numeric suffix until unique.
        var codeToUse = desiredCode
        var suffix = 1
        while fetchRelationType(code: codeToUse) != nil {
            suffix += 1
            codeToUse = makeCode(forward: mirrorForward, inverse: mirrorInverse, suffix: suffix)
        }

        let mirror = RelationType(code: codeToUse, forwardLabel: mirrorForward, inverseLabel: mirrorInverse, sourceKind: mirrorSource, targetKind: mirrorTarget)
        modelContext.insert(mirror)
    }

    private func relationTypeApplies(_ t: RelationType, from source: Kinds, to target: Kinds) -> Bool {
        let sourceOK = (t.sourceKindRaw == nil) || (t.sourceKindRaw == source.rawValue)
        let targetOK = (t.targetKindRaw == nil) || (t.targetKindRaw == target.rawValue)
        return sourceOK && targetOK
    }

    private func nonCitesRelationTypes(applicableFrom source: Kinds, to target: Kinds) -> [RelationType] {
        let fetch = FetchDescriptor<RelationType>(sortBy: [SortDescriptor(\.code, order: .forward)])
        let fetched = (try? modelContext.fetch(fetch)) ?? []

        // Special case: Scene→Project — only allow the canonical type
        if source == .scenes && target == .projects {
            return fetched.filter { $0.code == canonicalSceneProjectCode }
        }

        return fetched.filter { $0.code != citesCode && relationTypeApplies($0, from: source, to: target) }
    }

    // MARK: - Existing picker helpers

    private func availableExistingCandidates(for kind: Kinds) -> [Card] {
        // Fetch all cards of the selected kind (predicate avoids the problematic "!= UUID")
        let kindRaw = kind.rawValue
        let fetch = FetchDescriptor<Card>(predicate: #Predicate {
            $0.kindRaw == kindRaw
        })
        let allOfKind = (try? modelContext.fetch(fetch)) ?? []

        // Exclude the primary in-memory and deduplicate by UUID just in case
        let filtered = allOfKind.filter { $0.id != primary.id }
        var seen: Set<UUID> = []
        var unique: [Card] = []
        for c in filtered {
            if !seen.contains(c.id) {
                seen.insert(c.id)
                unique.append(c)
            }
        }

        return unique.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    @MainActor
    private func presentExistingPicker() {
        let candidates = availableExistingCandidates(for: selectedKind)
        let initiallySelected: Set<UUID> = []
        existingPickerState = ExistingPickerState(
            kind: selectedKind,
            candidates: candidates,
            initiallySelected: initiallySelected
        )
        #if DEBUG
        // Quick diagnostics if needed
        print("Existing candidates for \(selectedKind): \(candidates.count)")
        #endif
    }

    // MARK: - Retype helpers

    private func applicableRetypeChoices() -> [RelationType] {
        // Constrain by kinds and special-case Scene→Project to canonical only
        let fromKind = selectedKind
        let toKind = primary.kind
        if fromKind == .scenes && toKind == .projects {
            if let t = fetchRelationType(code: canonicalSceneProjectCode) {
                return [t]
            } else {
                return []
            }
        }
        // Otherwise, all applicable types (including references) but excluding "cites" unless source is Sources
        let fetch = FetchDescriptor<RelationType>(sortBy: [SortDescriptor(\.code, order: .forward)])
        let all = (try? modelContext.fetch(fetch)) ?? []
        return all.filter { relationTypeApplies($0, from: fromKind, to: toKind) && ($0.code != citesCode || fromKind == .sources) }
    }

    @MainActor
    private func presentRetypePickerForSelection() {
        guard let card = selectedRelatedCard else { return }
        // Only allow retyping if an edge exists
        let cardIDOpt: UUID? = card.id
        let primaryIDOpt: UUID? = primary.id
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == cardIDOpt && $0.to?.id == primaryIDOpt },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        guard let edge = try? modelContext.fetch(fetch).first else { return }

        let choices = applicableRetypeChoices()
        guard !choices.isEmpty else { return }
        retypeChoices = choices
        retypeSelectedCode = edge.type?.code ?? choices.first?.code
        isPresentingRetype = true
    }

    // MARK: - Header image loading

    @MainActor
    private func loadHeaderImage() async {
        // Prefer thumbnail for header; fall back to full if needed
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

    // MARK: - Code building helpers (shared with creator)

    private func sanitize(_ s: String) -> String {
        let lowered = s.lowercased()
        let replaced = lowered.replacingOccurrences(of: " ", with: "-")
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-")
        let filtered = String(replaced.unicodeScalars.filter { allowed.contains($0) })
        // collapse repeating dashes
        var result = filtered
        while result.contains("--") {
            result = result.replacingOccurrences(of: "--", with: "-")
        }
        return result
    }

    private func makeCode(forward: String, inverse: String, suffix: Int? = nil) -> String {
        let base = "\(sanitize(forward))/\(sanitize(inverse))"
        if let suffix {
            return "\(base)-\(suffix)"
        } else {
            return base
        }
    }
} //end CardRelationshipView

// MARK: - RelationType creation sheet

private struct RelationTypeCreatorSheet: View {
    let sourceKind: Kinds
    let targetKind: Kinds
    var onCreate: (RelationType) -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    @State private var forwardLabel: String = ""
    @State private var inverseLabel: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create Relation Type")
                .font(.title3).bold()

            GroupBox("Applies To") {
                HStack(spacing: 8) {
                    Label(sourceKind.title, systemImage: sourceKind.systemImage)
                        .labelStyle(.titleAndIcon)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    Label(targetKind.title, systemImage: targetKind.systemImage)
                        .labelStyle(.titleAndIcon)
                    Spacer()
                }
            }

            GroupBox("Labels") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Forward label (e.g., “appears in”)", text: $forwardLabel)
                        .textFieldStyle(.roundedBorder)
                    TextField("Inverse label (e.g., “dramatis personae”)", text: $inverseLabel)
                        .textFieldStyle(.roundedBorder)
                    if let err = errorMessage, !err.isEmpty {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)

            HStack {
                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    Task { await createType() }
                } label: {
                    Label("Create", systemImage: "checkmark.circle.fill")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid || isSaving)
            }
        }
        .padding()
        .frame(minWidth: 420, minHeight: 300, alignment: .topLeading)
    }

    private var isValid: Bool {
        !forwardLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !inverseLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @MainActor
    private func createType() async {
        guard isValid else { return }
        isSaving = true
        defer { isSaving = false }

        let forward = forwardLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let inverse = inverseLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        var code = makeCode(forward: forward, inverse: inverse)

        // Ensure code uniqueness by adding a numeric suffix if needed
        var suffix = 1
        while codeExists(code) {
            suffix += 1
            code = makeCode(forward: forward, inverse: inverse, suffix: suffix)
        }

        let type = RelationType(
            code: code,
            forwardLabel: forward,
            inverseLabel: inverse,
            sourceKind: sourceKind,
            targetKind: targetKind
        )
        modelContext.insert(type)

        // Also create the mirror if missing: swap kinds and labels
        createMirrorIfMissing(forwardLabel: forward, inverseLabel: inverse, sourceKind: sourceKind, targetKind: targetKind)

        try? modelContext.save()
        onCreate(type)
        dismiss()
    }

    private func codeExists(_ code: String) -> Bool {
        let fetch = FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == code })
        if let found = try? modelContext.fetch(fetch) {
            return !found.isEmpty
        }
        return false
    }

    private func sanitize(_ s: String) -> String {
        let lowered = s.lowercased()
        let replaced = lowered.replacingOccurrences(of: " ", with: "-")
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-")
        let filtered = String(replaced.unicodeScalars.filter { allowed.contains($0) })
        var result = filtered
        while result.contains("--") {
            result = result.replacingOccurrences(of: "--", with: "-")
        }
        return result
    }

    private func makeCode(forward: String, inverse: String, suffix: Int? = nil) -> String {
        let base = "\(sanitize(forward))/\(sanitize(inverse))"
        if let suffix {
            return "\(base)-\(suffix)"
        } else {
            return "\(base)"
        }
    }

    private func createMirrorIfMissing(forwardLabel: String, inverseLabel: String, sourceKind: Kinds, targetKind: Kinds) {
        let mirrorForward = inverseLabel
        let mirrorInverse = forwardLabel
        let mirrorSource = targetKind
        let mirrorTarget = sourceKind

        var mirrorCode = makeCode(forward: mirrorForward, inverse: mirrorInverse)
        var suffix = 1
        while codeExists(mirrorCode) {
            suffix += 1
            mirrorCode = makeCode(forward: mirrorForward, inverse: mirrorInverse, suffix: suffix)
        }

        // If a type with that code already exists, do nothing; else insert mirror.
        let fetch = FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == mirrorCode })
        if let found = try? modelContext.fetch(fetch), found.isEmpty == false {
            return
        }

        let mirror = RelationType(
            code: mirrorCode,
            forwardLabel: mirrorForward,
            inverseLabel: mirrorInverse,
            sourceKind: mirrorSource,
            targetKind: mirrorTarget
        )
        modelContext.insert(mirror)
    }
}

// MARK: - RelationType picker sheet

private struct RelationTypePickerSheet: View {
    let sourceKind: Kinds
    let targetKind: Kinds
    let types: [RelationType]
    let initialSelectedCode: String?

    var onPick: (RelationType?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @State private var selectedCode: String?
    @State private var isPresentingCreate: Bool = false

    init(sourceKind: Kinds, targetKind: Kinds, types: [RelationType], selectedCode: String?, onPick: @escaping (RelationType?) -> Void) {
        self.sourceKind = sourceKind
        self.targetKind = targetKind
        self.types = types
        self.initialSelectedCode = selectedCode
        self.onPick = onPick
        self._selectedCode = State(initialValue: selectedCode ?? types.first?.code)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Relation Type")
                .font(.title3).bold()

            GroupBox("Applies To") {
                HStack(spacing: 8) {
                    Label(sourceKind.title, systemImage: sourceKind.systemImage)
                        .labelStyle(.titleAndIcon)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    Label(targetKind.title, systemImage: targetKind.systemImage)
                        .labelStyle(.titleAndIcon)
                    Spacer()
                }
            }

            GroupBox("Available Types") {
                VStack(alignment: .leading, spacing: 8) {
                    if types.isEmpty {
                        Text("No applicable relation types.")
                            .foregroundStyle(.secondary)
                    } else {
                        List(selection: Binding(get: {
                            selectedCode.map { Set([ $0 ]) } ?? Set<String>()
                        }, set: { newSet in
                            selectedCode = newSet.first
                        })) {
                            ForEach(types, id: \.code) { t in
                                HStack(spacing: 8) {
                                    Text(t.code).font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 180, alignment: .leading)
                                    Text(t.forwardLabel)
                                    Text("↔︎")
                                        .foregroundStyle(.secondary)
                                    Text(t.inverseLabel)
                                    Spacer()
                                }
                                .tag(t.code)
                            }
                        }
                        #if canImport(UIKit)
                        .environment(\.editMode, .constant(.active))
                        #endif
                        .frame(minHeight: 180)
                    }
                }
            }

            Spacer(minLength: 0)

            HStack {
                Button("New Relation Type…") {
                    isPresentingCreate = true
                }
                .keyboardShortcut("N", modifiers: [.command])

                Spacer()

                Button("Cancel") {
                    onPick(nil)
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    if let code = selectedCode, let chosen = types.first(where: { $0.code == code }) {
                        onPick(chosen)
                    } else {
                        onPick(nil)
                    }
                    dismiss()
                } label: {
                    Label("Choose", systemImage: "checkmark.circle.fill")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedCode == nil)
            }
        }
        .padding()
        .frame(minWidth: 420, minHeight: 320, alignment: .topLeading)
        .sheet(isPresented: $isPresentingCreate) {
            RelationTypeCreatorSheet(
                sourceKind: sourceKind,
                targetKind: targetKind
            ) { newType in
                // Immediately return the created type and close both sheets
                onPick(newType)
                isPresentingCreate = false
                dismiss()
            } onCancel: {
                isPresentingCreate = false
            }
            .frame(minWidth: 420, minHeight: 300)
        }
    }
}

// MARK: - Existing Card Picker Sheet (multi-select)

private struct ExistingCardPickerSheet: View {
    let kind: Kinds
    let candidates: [Card]
    let initiallySelected: Set<UUID>
    var onDone: ([Card]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selection: Set<UUID> = []

    init(kind: Kinds, candidates: [Card], initiallySelected: Set<UUID> = [], onDone: @escaping ([Card]) -> Void) {
        self.kind = kind
        self.candidates = candidates
        self.initiallySelected = initiallySelected
        self.onDone = onDone
        self._selection = State(initialValue: initiallySelected)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Existing \(kind.title.dropLastIfPluralized())")
                .font(.title3).bold()

            if candidates.isEmpty {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No \(kind.title.lowercased()) found.")
                            .foregroundStyle(.secondary)
                        Text("Create a new one to add.")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                GroupBox("\(candidates.count) available") {
                    List(candidates, id: \.id, selection: $selection) { card in
                        HStack(spacing: 8) {
                            Image(systemName: card.kind.systemImage)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading) {
                                Text(card.name)
                                    .font(.body)
                                if !card.subtitle.isEmpty {
                                    Text(card.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                    #if canImport(UIKit)
                    .environment(\.editMode, .constant(.active))
                    #endif
                    .frame(minHeight: 240, maxHeight: .infinity)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    let picked = candidates.filter { selection.contains($0.id) }
                    onDone(picked)
                    dismiss()
                } label: {
                    Label("Add", systemImage: "link.badge.plus")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selection.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 420, alignment: .topLeading)
    }
}

import struct SwiftUI.Image
