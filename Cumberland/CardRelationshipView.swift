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
    @State private var shouldCleanupPendingOnCancel: Bool = false
    @State private var pendingExistingCards: [Card] = []

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

    // NEW: Manage Relation Types sheet
    @State private var isPresentingManageRelationTypes: Bool = false

    // Change card type state
    @State private var isPresentingChangeCardType: Bool = false
    @State private var selectedNewCardType: Kinds = .characters

    // Full-size image viewer
    @State private var showFullSizeImage: Bool = false

    private let areaCornerRadius: CGFloat = 16

    var relationTypeFilter: RelationType? = nil

    private let citesCode: String = "cites"
    private let defaultNonSourceCode: String = "references"
    private let canonicalSceneProjectCode: String = "stories/is-storied-by"

    @State private var headerImage: Image?

    private func masterCards(for kind: Kinds) -> [Card] {
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

            topControls

            Divider()

            relatedArea(areaBackground: areaBackground)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding()
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
        .task(id: primary.imageFileURL) {
            await loadHeaderImage()
        }
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
                isPresentingCreateRelationType = false
                if shouldCleanupPendingOnCancel, let card = pendingNewCard {
                    cleanupAndDelete(card)
                }
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
        .sheet(isPresented: $isPresentingEditCard) {
            if let card = selectedRelatedCard {
                CardEditorView(mode: .edit(card: card) {
                    isPresentingEditCard = false
                })
                .frame(minWidth: 560, minHeight: 520)
            }
        }
        // NEW: present manager
        .sheet(isPresented: $isPresentingManageRelationTypes) {
            RelationTypesManagerView()
                .frame(minWidth: 680, minHeight: 420)
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
            selectedRelatedCard = nil
        }
        .sheet(isPresented: $isPresentingChangeCardType) {
            ChangeCardTypeSheet(
                currentKind: primary.kind,
                cardName: primary.name,
                selectedKind: $selectedNewCardType
            ) { newKind in
                changeCardType(to: newKind)
                isPresentingChangeCardType = false
            } onCancel: {
                isPresentingChangeCardType = false
            }
        }
    } //end var body

    private var hasFullSizeImage: Bool {
        primary.imageFileURL != nil || primary.originalImageData != nil
    }

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
                VStack(alignment: .leading, spacing: 6) {
                    Text(primary.name)
                        .font(.title3).bold()
                    if !primary.subtitle.isEmpty {
                        Text(primary.subtitle)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .frame(minWidth: 160, alignment: .leading)
                .layoutPriority(3)

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
                        .layoutPriority(0)
                }

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
                        .contentShape(Rectangle())
                        // Double-tap must come before single-tap
                        .onTapGesture(count: 2) {
                            if hasFullSizeImage {
                                showFullSizeImage = true
                            }
                        }
                        .onTapGesture(count: 1) {
                            // Single tap could do something else, or just nothing
                        }
                        #if os(macOS)
                        .onHover { hovering in
                            if hovering && hasFullSizeImage {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        #endif
                        #if os(iOS)
                        .onLongPressGesture(minimumDuration: 0.5) {
                            if hasFullSizeImage {
                                showFullSizeImage = true
                            }
                        }
                        #endif
                        .contextMenu {
                            if hasFullSizeImage {
                                Button {
                                    showFullSizeImage = true
                                } label: {
                                    Label("View Full Size", systemImage: "arrow.up.left.and.arrow.down.right")
                                }
                                #if os(macOS)
                                .keyboardShortcut(.space)
                                #endif
                            }
                        }
                }
            }
        }
    }

    private var topControls: some View {
        HStack(spacing: 8) {
            #if !os(visionOS)
            Text("Related Kind:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            #endif
            Picker(selection: $selectedKind) {
                ForEach(Kinds.orderedCases) { kind in
                    Label(kind.title, systemImage: kind.systemImage)
                        .tag(kind)
                }
            } label: { EmptyView() }
            .labelsHidden()
            .pickerStyle(.menu)
            .glassButtonStyle()

            let addTitle: String = (selectedKind == primary.kind)
                ? "Add Sub \(selectedKind.title.dropLastIfPluralized())"
                : "Add \(selectedKind.title.dropLastIfPluralized())"

            Button {
                isPresentingAddCard = true
            } label: {
                #if os(macOS)
                Label(addTitle, systemImage: "plus")
                #else
                Label(addTitle, systemImage: "plus")
                    .labelStyle(.iconOnly)
                #endif
            }
            .help("Create a new \(selectedKind.title.dropLastIfPluralized()) and relate it to “\(primary.name)”")

            Button {
                presentExistingPicker()
            } label: {
                #if os(macOS)
                Label("Add Existing \(selectedKind.title.dropLastIfPluralized())…", systemImage: "link.badge.plus")
                #else
                Label("Add Existing \(selectedKind.title.dropLastIfPluralized())…", systemImage: "link.badge.plus")
                    .labelStyle(.iconOnly)
                #endif
            }
            .disabled(availableExistingCandidates(for: selectedKind).isEmpty)

            Button {
                isPresentingEditCard = true
            } label: {
                #if os(macOS)
                Label("Edit Selected", systemImage: "pencil")
                #else
                Label("Edit Selected", systemImage: "pencil")
                    .labelStyle(.iconOnly)
                #endif
            }
            .disabled(selectedRelatedCard == nil)
            .help("Edit the selected related card")

            Button {
                presentRetypePickerForSelection()
            } label: {
                #if os(macOS)
                Label("Change Relationship Type…", systemImage: "arrow.triangle.2.circlepath")
                #else
                Label("Change Relationship Type…", systemImage: "arrow.triangle.2.circlepath")
                    .labelStyle(.iconOnly)
                #endif
            }
            .disabled(selectedRelatedCard == nil || applicableRetypeChoices().isEmpty)
            .help("Change the relationship type between the selected card and “\(primary.name)”")

            Button(role: .destructive) {
                if let card = selectedRelatedCard {
                    removeRelationship(between: card, and: primary)
                }
            } label: {
                #if os(macOS)
                Label("Remove Relationship", systemImage: "link")
                    .symbolVariant(.slash)
                #else
                Label("Remove Relationship", systemImage: "link")
                    .symbolVariant(.slash)
                    .labelStyle(.iconOnly)
                #endif
            }
            .disabled(selectedRelatedCard == nil)
            .help("Remove the relationship between the selected card and “\(primary.name)”")

            Divider().frame(height: 18)

            // Change Card Type button
            Button {
                selectedNewCardType = primary.kind
                isPresentingChangeCardType = true
            } label: {
                #if os(macOS)
                Label("Change Card Type…", systemImage: "arrow.triangle.swap")
                #else
                Label("Change Card Type…", systemImage: "arrow.triangle.swap")
                    .labelStyle(.iconOnly)
                #endif
            }
            .help("Change the type of \"\(primary.name)\" (will remove all relationships)")

            // NEW: Manage Relation Types
            Button {
                isPresentingManageRelationTypes = true
            } label: {
                #if os(macOS)
                Label("Manage Relation Types…", systemImage: "link")
                #else
                Label("Manage Relation Types…", systemImage: "link")
                    .labelStyle(.iconOnly)
                #endif
            }
            .help("Create, edit, reassign, or delete relation types")

            Spacer()
        }
    }

    private func relatedArea(areaBackground: Color) -> some View {
        GeometryReader { proxy in
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
                        ZStack(alignment: .topLeading) {
                            CardViewer(
                                cards: masterCardsForSelectedKind,
                                decorationProvider: { card in
                                    relationDecoration(for: card)
                                },
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
                }
                .padding(12)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .dropDestination(for: String.self) { items, _ in
                return handleDrop(items: items)
            }
            .contextMenu {
                addExistingContextMenuItem()
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

                Divider()

                Button(role: .destructive) {
                    if let card = selectedRelatedCard {
                        removeRelationship(between: card, and: primary)
                    }
                } label: {
                    Label("Remove Relationship", systemImage: "link")
                        .symbolVariant(.slash)
                }
                .disabled(selectedRelatedCard == nil)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: areaCornerRadius, style: .continuous))
        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func addExistingContextMenuItem() -> some View {
        Button {
            presentExistingPicker()
        } label: {
            Label("Add Existing \(selectedKind.title.dropLastIfPluralized())…", systemImage: "link.badge.plus")
        }
        .disabled(availableExistingCandidates(for: selectedKind).isEmpty)
    }

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

    private func canonicalizedTypeFor(source: Card, target: Card, proposed: RelationType?) -> RelationType? {
        if source.kind == .scenes && target.kind == .projects {
            let fetch = FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == canonicalSceneProjectCode })
            if let canonical = try? modelContext.fetch(fetch).first {
                return canonical
            } else {
                let t = RelationType(code: canonicalSceneProjectCode, forwardLabel: "stories", inverseLabel: "is storied by", sourceKind: .scenes, targetKind: .projects)
                modelContext.insert(t)

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

        if let proposed, proposed.matches(from: source.kind, to: target.kind) {
            return proposed
        }
        return nil
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
                chosenType = ensureRelationType(code: citesCode, forward: "cites", inverse: "cited by", sourceKind: .sources, targetKind: nil)
            } else {
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

        guard let enforcedType = canonicalizedTypeFor(source: dropped, target: primary, proposed: chosenType) else {
            return false
        }

        createEdgeIfNeeded(from: dropped, to: primary, type: enforcedType, appendToEnd: true)
        return true
    }

    @MainActor
    private func handleNewCardCreated(_ newCard: Card) {
        if let fixedType = relationTypeFilter {
            let enforced = canonicalizedTypeFor(source: newCard, target: primary, proposed: fixedType)
            if let enforced {
                createEdgeIfNeeded(from: newCard, to: primary, type: enforced, appendToEnd: true)
            }
            shouldCleanupPendingOnCancel = false
            return
        }

        if selectedKind == .sources {
            let cites = ensureRelationType(code: "cites", forward: "cites", inverse: "cited by", sourceKind: .sources, targetKind: nil)
            if let enforced = canonicalizedTypeFor(source: newCard, target: primary, proposed: cites) {
                createEdgeIfNeeded(from: newCard, to: primary, type: enforced, appendToEnd: true)
            }
            shouldCleanupPendingOnCancel = false
            return
        }

        let types = nonCitesRelationTypes(applicableFrom: selectedKind, to: primary.kind)

        if types.isEmpty {
            pendingNewCard = newCard
            relationTypeChoices = []
            selectedRelationTypeCode = nil
            shouldCleanupPendingOnCancel = true
            isPresentingCreateRelationType = true
        } else if types.count == 1 {
            let only = types[0]
            if only.code == defaultNonSourceCode {
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
                    pendingNewCard = newCard
                    relationTypeChoices = types
                    selectedRelationTypeCode = types.first?.code
                    shouldCleanupPendingOnCancel = true
                    isPresentingPickRelationType = true
                }
            }
        } else if types.count == 2 {
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
            pendingNewCard = newCard
            relationTypeChoices = types
            selectedRelationTypeCode = types.first?.code
            shouldCleanupPendingOnCancel = true
            isPresentingPickRelationType = true
        }
    }

    @MainActor
    private func handleExistingCardsPicked(_ cards: [Card]) {
        guard !cards.isEmpty else { return }

        if let fixedType = relationTypeFilter {
            for c in cards {
                if let enforced = canonicalizedTypeFor(source: c, target: primary, proposed: fixedType) {
                    createEdgeIfNeeded(from: c, to: primary, type: enforced, appendToEnd: true)
                }
            }
            return
        }

        if selectedKind == .sources {
            let cites = ensureRelationType(code: "cites", forward: "cites", inverse: "cited by", sourceKind: .sources, targetKind: nil)
            for c in cards {
                if let enforced = canonicalizedTypeFor(source: c, target: primary, proposed: cites) {
                    createEdgeIfNeeded(from: c, to: primary, type: enforced, appendToEnd: true)
                }
            }
            return
        }

        let types = nonCitesRelationTypes(applicableFrom: selectedKind, to: primary.kind)

        if types.isEmpty {
            pendingExistingCards = cards
            relationTypeChoices = []
            selectedRelationTypeCode = nil
            shouldCleanupPendingOnCancel = false
            isPresentingCreateRelationType = true
        } else if types.count == 1 {
            let only = types[0]
            if only.code == defaultNonSourceCode {
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
            pendingExistingCards = cards
            relationTypeChoices = types
            selectedRelationTypeCode = types.first?.code
            shouldCleanupPendingOnCancel = false
            isPresentingPickRelationType = true
        }
    }

    private func mirrorType(for type: RelationType, sourceKind: Kinds, targetKind: Kinds) -> RelationType {
        let desiredCode = makeCode(forward: type.inverseLabel, inverse: type.forwardLabel)
        if let existing = fetchRelationType(code: desiredCode) {
            return existing
        }

        ensureMirror(forwardLabel: type.forwardLabel, inverseLabel: type.inverseLabel, sourceKind: sourceKind, targetKind: targetKind)
        if let exact = fetchRelationType(code: desiredCode) {
            return exact
        }
        let all = (try? modelContext.fetch(FetchDescriptor<RelationType>())) ?? []
        if let match = all.first(where: {
            ($0.sourceKindRaw == targetKind.rawValue || $0.sourceKindRaw == nil) &&
            ($0.targetKindRaw == sourceKind.rawValue || $0.targetKindRaw == nil) &&
            $0.forwardLabel == type.inverseLabel &&
            $0.inverseLabel == type.forwardLabel
        }) {
            return match
        }
        var codeToUse = makeCode(forward: type.inverseLabel, inverse: type.forwardLabel)
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

    @MainActor
    private func ensureReverseEdge(forwardEdge: CardEdge, appendToEnd: Bool) {
        guard let src = forwardEdge.from, let dst = forwardEdge.to, let t = forwardEdge.type else { return }
        let srcID: UUID? = src.id
        let dstID: UUID? = dst.id
        let existsFetch = FetchDescriptor<CardEdge>(predicate: #Predicate {
            $0.from?.id == dstID && $0.to?.id == srcID
        })
        if let found = try? modelContext.fetch(existsFetch), found.isEmpty == false {
            return
        }

        let mirror = mirrorType(for: t, sourceKind: src.kind, targetKind: dst.kind)

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
        guard let enforcedType = canonicalizedTypeFor(source: source, target: target, proposed: type) else {
            return
        }

        let sourceIDOpt: UUID? = source.id
        let targetIDOpt: UUID? = target.id
        let typeCodeOpt: String? = enforcedType.code
        let existsFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate {
                $0.from?.id == sourceIDOpt && $0.to?.id == targetIDOpt && $0.type?.code == typeCodeOpt
            }
        )
        if let found = try? modelContext.fetch(existsFetch), found.isEmpty == false {
            if let existingEdge = found.first {
                ensureReverseEdge(forwardEdge: existingEdge, appendToEnd: appendToEnd)
            }
            return
        }

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

        ensureReverseEdge(forwardEdge: edge, appendToEnd: appendToEnd)
    }

    @MainActor
    private func retypeEdge(from source: Card, to target: Card, newType: RelationType) {
        guard let enforced = canonicalizedTypeFor(source: source, target: target, proposed: newType) else { return }

        let sourceIDOpt: UUID? = source.id
        let targetIDOpt: UUID? = target.id
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == sourceIDOpt && $0.to?.id == targetIDOpt },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        guard let edge = try? modelContext.fetch(fetch).first else { return }

        if edge.type?.code == enforced.code { return }

        edge.type = enforced
        try? modelContext.save()

        let reverseFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == targetIDOpt && $0.to?.id == sourceIDOpt },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        if let reverseEdge = try? modelContext.fetch(reverseFetch).first {
            let mirror = mirrorType(for: enforced, sourceKind: source.kind, targetKind: target.kind)
            reverseEdge.type = mirror
            try? modelContext.save()
        } else {
            ensureReverseEdge(forwardEdge: edge, appendToEnd: true)
        }
    }

    @MainActor
    private func removeRelationship(between a: Card, and b: Card) {
        let aID: UUID? = a.id
        let bID: UUID? = b.id

        if let t = relationTypeFilter {
            let forwardCode: String? = t.code
            let fwdFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == aID && $0.to?.id == bID && $0.type?.code == forwardCode })
            let fwd = (try? modelContext.fetch(fwdFetch)) ?? []

            let mirror = mirrorType(for: t, sourceKind: a.kind, targetKind: b.kind)
            let mirrorCode: String? = mirror.code
            let revFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == bID && $0.to?.id == aID && $0.type?.code == mirrorCode })
            let rev = (try? modelContext.fetch(revFetch)) ?? []

            for e in fwd { modelContext.delete(e) }
            for e in rev { modelContext.delete(e) }
        } else {
            let abFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == aID && $0.to?.id == bID })
            let baFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == bID && $0.to?.id == aID })
            let ab = (try? modelContext.fetch(abFetch)) ?? []
            let ba = (try? modelContext.fetch(baFetch)) ?? []
            for e in ab { modelContext.delete(e) }
            for e in ba { modelContext.delete(e) }
        }

        try? modelContext.save()
        if selectedRelatedCard?.id == a.id {
            selectedRelatedCard = nil
        }
    }

    @MainActor
    private func cleanupAndDelete(_ card: Card) {
        card.cleanupBeforeDeletion(in: modelContext)
        modelContext.delete(card)
        try? modelContext.save()
    }

    /// Change the card type and remove all relationships
    /// This is a destructive operation that cannot be undone
    private func changeCardType(to newKind: Kinds) {
        guard newKind != primary.kind else { return }

        // Fetch all edges where this card is either source or target
        let cardID: UUID? = primary.id
        let fetchFrom = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == cardID })
        let fetchTo = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.to?.id == cardID })

        let edgesFrom = (try? modelContext.fetch(fetchFrom)) ?? []
        let edgesTo = (try? modelContext.fetch(fetchTo)) ?? []

        // Delete all relationships
        for edge in edgesFrom + edgesTo {
            modelContext.delete(edge)
        }

        // Change the card type
        primary.kindRaw = newKind.rawValue

        // Save changes
        try? modelContext.save()

        #if DEBUG
        print("✅ [CardRelationshipView] Changed card type from \(primary.kind.title) to \(newKind.title)")
        print("   Removed \(edgesFrom.count + edgesTo.count) relationships")
        #endif
    }

    private func fetchRelationType(code: String) -> RelationType? {
        let fetch = FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == code })
        return try? modelContext.fetch(fetch).first
    }

    @discardableResult
    private func ensureRelationType(code: String, forward: String, inverse: String, sourceKind: Kinds? = nil, targetKind: Kinds? = nil) -> RelationType {
        if let existing = fetchRelationType(code: code) {
            ensureMirror(forwardLabel: forward, inverseLabel: inverse, sourceKind: sourceKind, targetKind: targetKind)
            return existing
        }
        let type = RelationType(code: code, forwardLabel: forward, inverseLabel: inverse, sourceKind: sourceKind, targetKind: targetKind)
        modelContext.insert(type)
        ensureMirror(forwardLabel: forward, inverseLabel: inverse, sourceKind: sourceKind, targetKind: targetKind)
        try? modelContext.save()
        return type
    }

    private func ensureMirror(forwardLabel: String, inverseLabel: String, sourceKind: Kinds?, targetKind: Kinds?) {
        let mirrorForward = inverseLabel
        let mirrorInverse = forwardLabel
        let mirrorSource = targetKind
        let mirrorTarget = sourceKind

        let desiredCode = makeCode(forward: mirrorForward, inverse: mirrorInverse)
        if fetchRelationType(code: desiredCode) != nil {
            return
        }

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

        if source == .scenes && target == .projects {
            return fetched.filter { $0.code == canonicalSceneProjectCode }
        }

        return fetched.filter { $0.code != citesCode && relationTypeApplies($0, from: source, to: target) }
    }

    private func availableExistingCandidates(for kind: Kinds) -> [Card] {
        let kindRaw = kind.rawValue
        let fetch = FetchDescriptor<Card>(predicate: #Predicate {
            $0.kindRaw == kindRaw
        })
        let allOfKind = (try? modelContext.fetch(fetch)) ?? []

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
        print("Existing candidates for \(selectedKind): \(candidates.count)")
        #endif
    }

    private func applicableRetypeChoices() -> [RelationType] {
        let fromKind = selectedKind
        let toKind = primary.kind

        if fromKind == .scenes && toKind == .projects {
            let t = fetchRelationType(code: canonicalSceneProjectCode)
                ?? ensureRelationType(code: canonicalSceneProjectCode, forward: "stories", inverse: "is storied by", sourceKind: .scenes, targetKind: .projects)
            return [t]
        }

        _ = fetchRelationType(code: defaultNonSourceCode)
            ?? ensureRelationType(code: defaultNonSourceCode, forward: "references", inverse: "referenced by", sourceKind: nil, targetKind: nil)

        let fetch = FetchDescriptor<RelationType>(sortBy: [SortDescriptor(\.code, order: .forward)])
        let all = (try? modelContext.fetch(fetch)) ?? []
        return all.filter { relationTypeApplies($0, from: fromKind, to: toKind) && ($0.code != citesCode || fromKind == .sources) }
    }

    @MainActor
    private func presentRetypePickerForSelection() {
        guard let card = selectedRelatedCard else { return }
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
}

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

// MARK: - Change Card Type Sheet

private struct ChangeCardTypeSheet: View {
    let currentKind: Kinds
    let cardName: String
    @Binding var selectedKind: Kinds
    let onChange: (Kinds) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Current Type: **\(currentKind.title)**")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Current Card Type")
                }

                Section {
                    Picker("New Type", selection: $selectedKind) {
                        ForEach(Kinds.orderedCases.filter { $0 != .structure }, id: \.self) { kind in
                            Label {
                                Text(kind.title)
                            } icon: {
                                Image(systemName: kind.systemImage)
                                    .foregroundStyle(kind.accentColor(for: .light))
                            }
                            .tag(kind)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Select New Type")
                } footer: {
                    Text("Changing the card type will remove ALL relationships for \"\(cardName)\". This cannot be undone.")
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Change Card Type")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Change Type") {
                        showingConfirmation = true
                    }
                    .disabled(selectedKind == currentKind)
                }
            }
            .alert("Confirm Type Change", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Change Type", role: .destructive) {
                    onChange(selectedKind)
                }
            } message: {
                Text("Change \"\(cardName)\" from \(currentKind.title) to \(selectedKind.title)? This will DELETE ALL RELATIONSHIPS and cannot be undone.")
            }
        }
    }
}
