// CardRelationshipView.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CardRelationshipView: View {
    let primary: Card

    @Query(sort: \Card.name, order: .forward) private var allCards: [Card]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @State private var selectedKind: Kinds = .projects

    // Add flow state
    @State private var isPresentingAddCard: Bool = false
    @State private var pendingNewCard: Card? = nil
    // If true, and the relation type flow is canceled/dismissed, delete pendingNewCard
    @State private var shouldCleanupPendingOnCancel: Bool = false

    // Choose/create relation type state
    @State private var isPresentingCreateRelationType: Bool = false
    @State private var isPresentingPickRelationType: Bool = false
    @State private var relationTypeChoices: [RelationType] = []
    @State private var selectedRelationTypeCode: String?

    private let areaCornerRadius: CGFloat = 16

    // Optional relation type filter for this view (nil = any; drop uses default)
    var relationTypeFilter: RelationType? = nil

    // Relation type codes
    private let citesCode: String = "cites"
    private let defaultNonSourceCode: String = "references"

    private func masterCards(for kind: Kinds) -> [Card] {
        // Find edges where to == primary and from.kind == kind (respect filter if provided)
        let predicate: Predicate<CardEdge>
        if let t = relationTypeFilter {
            let typeCode = t.code
            let primaryID = primary.id
            let rawValue = kind.rawValue
            predicate = #Predicate { $0.to.id == primaryID && $0.from.kindRaw == rawValue && $0.type.code == typeCode }
        } else {
            let primaryID = primary.id
            let rawValue = kind.rawValue
            predicate = #Predicate { $0.to.id == primaryID && $0.from.kindRaw == rawValue }
        }
        let fetch = FetchDescriptor<CardEdge>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        let edges = (try? modelContext.fetch(fetch)) ?? []
        let cards = edges.map { $0.from }
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
        let headerBackground: Color = primary.kind.backgroundColor(for: scheme)

        VStack(alignment: .leading, spacing: 12) {
            primaryHeader
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(headerBackground, in: RoundedRectangle(cornerRadius: areaCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: areaCornerRadius, style: .continuous)
                        .stroke(primary.kind.accentColor(for: scheme).opacity(0.25), lineWidth: 1)
                }
                .innerShadow(cornerRadius: areaCornerRadius,
                             color: .black.opacity(0.18),
                             radius: 6,
                             offset: CGSize(width: 0, height: 2))
                .padding(.top, 8)

            topControls

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
        // MARK: - Sheets for Add flow
        .sheet(isPresented: $isPresentingAddCard) {
            CardEditorView(mode: .create(kind: selectedKind) { newCard in
                isPresentingAddCard = false
                handleNewCardCreated(newCard)
            })
            .frame(minWidth: 560, minHeight: 520)
        }
        .sheet(isPresented: $isPresentingCreateRelationType) {
            RelationTypeCreatorSheet(
                sourceKind: selectedKind,
                targetKind: primary.kind
            ) { newType in
                // Success path: we created a type and will create the edge — no cleanup needed.
                shouldCleanupPendingOnCancel = false
                isPresentingCreateRelationType = false
                if let card = pendingNewCard {
                    createEdgeIfNeeded(from: card, to: primary, type: newType, appendToEnd: true)
                    pendingNewCard = nil
                }
            } onCancel: {
                // User canceled — delete pending card if any.
                isPresentingCreateRelationType = false
                if shouldCleanupPendingOnCancel, let card = pendingNewCard {
                    cleanupAndDelete(card)
                }
                pendingNewCard = nil
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
                if let type = chosen, let card = pendingNewCard {
                    // Success path — relate and keep the card.
                    createEdgeIfNeeded(from: card, to: primary, type: type, appendToEnd: true)
                    shouldCleanupPendingOnCancel = false
                } else {
                    // Canceled — delete pending card.
                    if shouldCleanupPendingOnCancel, let card = pendingNewCard {
                        cleanupAndDelete(card)
                    }
                }
                pendingNewCard = nil
                relationTypeChoices = []
                selectedRelationTypeCode = nil
            }
            .frame(minWidth: 420, minHeight: 320)
        }
        // Also handle dismissals (e.g., swipe/escape) that bypass our cancel buttons.
        .onChange(of: isPresentingCreateRelationType) { _, isPresented in
            if !isPresented, shouldCleanupPendingOnCancel, let card = pendingNewCard {
                cleanupAndDelete(card)
                pendingNewCard = nil
                shouldCleanupPendingOnCancel = false
            }
        }
        .onChange(of: isPresentingPickRelationType) { _, isPresented in
            if !isPresented, shouldCleanupPendingOnCancel, let card = pendingNewCard {
                cleanupAndDelete(card)
                pendingNewCard = nil
                shouldCleanupPendingOnCancel = false
            }
        }
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
            Text(primary.name)
                .font(.title3).bold()
            if !primary.subtitle.isEmpty {
                Text(primary.subtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

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
                                }
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
            }
            // Explicitly size the ZStack to the GeometryReader’s available size.
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            // Accept drops across the full area.
            .dropDestination(for: String.self) { items, _ in
                return handleDrop(items: items)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: areaCornerRadius, style: .continuous))
        // Give it a sensible minimum, but let it expand to fill remaining space from the parent.
        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: .infinity, alignment: .top)
    }

    // Provide the decoration text for a given related card.
    // If a filter is active, we can return its forward label directly.
    // Otherwise, fetch the first edge from this card to the primary and return its type's forward label.
    private func relationDecoration(for card: Card) -> String? {
        if let t = relationTypeFilter {
            return t.forwardLabel
        }
        let fromID = card.id
        let toID = primary.id
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from.id == fromID && $0.to.id == toID }
        )
        if let edge = try? modelContext.fetch(fetch).first {
            return edge.type.forwardLabel
        }
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
                    // ambiguous with no valid types — reject drop (no silent default)
                    chosenType = nil
                } else if types.count == 1 {
                    let only = types[0]
                    // If the only type is 'references', require explicit choice — reject drop
                    chosenType = (only.code == defaultNonSourceCode) ? nil : only
                } else if types.count == 2 {
                    // If exactly two and one is 'references', use the other; otherwise ambiguous -> reject
                    if let nonRef = types.first(where: { $0.code != defaultNonSourceCode }) {
                        chosenType = nonRef
                    } else {
                        chosenType = nil
                    }
                } else {
                    // >= 3 non-cites types — ambiguous -> reject
                    chosenType = nil
                }
            }
        }
        guard let type = chosenType else { return false }

        // Avoid duplicates (compare primitive values only)
        let fromID = dropped.id
        let toID = primary.id
        let typeCode = type.code
        let existsFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from.id == fromID && $0.to.id == toID && $0.type.code == typeCode }
        )
        if let found = try? modelContext.fetch(existsFetch), found.isEmpty == false {
            return false
        }

        // Append to end by using createdAt slightly after current max
        let fetchForMax = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.to.id == toID && $0.type.code == typeCode },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let existing = (try? modelContext.fetch(fetchForMax)) ?? []
        let last = existing.last?.createdAt ?? Date()
        let newDate = last.addingTimeInterval(0.001)

        let edge = CardEdge(from: dropped, to: primary, type: type, note: nil, createdAt: newDate)
        modelContext.insert(edge)
        try? modelContext.save()
        return true
    }

    // MARK: - Add flow helpers

    @MainActor
    private func handleNewCardCreated(_ newCard: Card) {
        // If this view is constrained to a specific relation type, use it.
        if let fixedType = relationTypeFilter {
            createEdgeIfNeeded(from: newCard, to: primary, type: fixedType, appendToEnd: true)
            shouldCleanupPendingOnCancel = false
            return
        }

        // Sources: must use "cites" (auto-use/create; no picker). Option A: target = any.
        if selectedKind == .sources {
            let cites = ensureRelationType(code: citesCode, forward: "cites", inverse: "cited by", sourceKind: .sources, targetKind: nil)
            createEdgeIfNeeded(from: newCard, to: primary, type: cites, appendToEnd: true)
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
                // Use the single non-references type
                createEdgeIfNeeded(from: newCard, to: primary, type: only, appendToEnd: true)
                shouldCleanupPendingOnCancel = false
            }
        } else if types.count == 2 {
            // If one is 'references', use the other; else ambiguous -> picker
            if let nonRef = types.first(where: { $0.code != defaultNonSourceCode }) {
                createEdgeIfNeeded(from: newCard, to: primary, type: nonRef, appendToEnd: true)
                shouldCleanupPendingOnCancel = false
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

    @MainActor
    private func createEdgeIfNeeded(from source: Card, to target: Card, type: RelationType) {
        createEdgeIfNeeded(from: source, to: target, type: type, appendToEnd: true)
    }

    @MainActor
    private func createEdgeIfNeeded(from source: Card, to target: Card, type: RelationType, appendToEnd: Bool) {
        let fromID = source.id
        let toID = target.id
        let typeCode = type.code
        let existsFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from.id == fromID && $0.to.id == toID && $0.type.code == typeCode }
        )
        if let found = try? modelContext.fetch(existsFetch), found.isEmpty == false {
            return
        }

        // Determine createdAt: append to end by default
        let createdAt: Date
        if appendToEnd {
            let fetchForMax = FetchDescriptor<CardEdge>(
                predicate: #Predicate { $0.to.id == toID && $0.type.code == typeCode },
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let existing = (try? modelContext.fetch(fetchForMax)) ?? []
            let last = existing.last?.createdAt ?? Date()
            createdAt = last.addingTimeInterval(0.001)
        } else {
            createdAt = Date()
        }

        let edge = CardEdge(from: source, to: target, type: type, note: nil, createdAt: createdAt)
        modelContext.insert(edge)
        try? modelContext.save()
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

    @discardableResult
    private func ensureRelationType(code: String, forward: String, inverse: String, sourceKind: Kinds? = nil, targetKind: Kinds? = nil) -> RelationType {
        if let existing = fetchRelationType(code: code) {
            // If it already exists, use it as-is (it may be global).
            return existing
        }
        let type = RelationType(code: code, forwardLabel: forward, inverseLabel: inverse, sourceKind: sourceKind, targetKind: targetKind)
        modelContext.insert(type)
        try? modelContext.save()
        return type
    }

    private func relationTypeApplies(_ t: RelationType, from source: Kinds, to target: Kinds) -> Bool {
        let sourceOK = (t.sourceKindRaw == nil) || (t.sourceKindRaw == source.rawValue)
        let targetOK = (t.targetKindRaw == nil) || (t.targetKindRaw == target.rawValue)
        return sourceOK && targetOK
    }

    private func nonCitesRelationTypes(applicableFrom source: Kinds, to target: Kinds) -> [RelationType] {
        let fetch = FetchDescriptor<RelationType>(sortBy: [SortDescriptor(\.code, order: .forward)])
        let fetched = (try? modelContext.fetch(fetch)) ?? []
        return fetched.filter { $0.code != citesCode && relationTypeApplies($0, from: source, to: target) }
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
                    TextField("Inverse label (e.g., “is appeared by”)", text: $inverseLabel)
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
        return filtered.replacingOccurrences(of: "--", with: "-")
    }

    private func makeCode(forward: String, inverse: String, suffix: Int? = nil) -> String {
        let base = "\(sanitize(forward))/\(sanitize(inverse))"
        if let suffix {
            return "\(base)-\(suffix)"
        } else {
            return base
        }
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
                        // On UIKit platforms (iOS/Catalyst), force selection mode without showing edit UI.
                        #if canImport(UIKit)
                        .environment(\.editMode, .constant(.active))
                        #endif
                        .frame(minHeight: 180)
                    }
                }
            }

            Spacer(minLength: 0)

            HStack {
                Button("Cancel") {
                    onPick(nil)
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

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
    }
}

import struct SwiftUI.Image
