//
//  CardRelationshipSheets.swift
//  Cumberland
//
//  Extracted from CardRelationshipView.swift as part of ER-0022 Phase 4.5
//  Contains all sheet presentation views used by CardRelationshipView.
//

import SwiftUI
import SwiftData

// MARK: - RelationType Creation Sheet

/// Sheet for creating a new RelationType with forward and inverse labels.
struct RelationTypeCreatorSheet: View {
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
                    TextField("Forward label (e.g., 'appears in')", text: $forwardLabel)
                        .textFieldStyle(.roundedBorder)
                    TextField("Inverse label (e.g., 'dramatis personae')", text: $inverseLabel)
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

// MARK: - RelationType Picker Sheet

/// Sheet for selecting an existing RelationType from a list.
struct RelationTypePickerSheet: View {
    let sourceKind: Kinds
    let targetKind: Kinds
    let types: [RelationType]
    let initialSelectedCode: String?

    var onPick: (RelationType?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var themeManager: ThemeManager

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
            .environmentObject(themeManager)
        }
    }
}

// MARK: - Existing Card Picker Sheet (Multi-Select)

/// Sheet for selecting one or more existing cards to create relationships with.
struct ExistingCardPickerSheet: View {
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
                                Text(verbatim: card.name)
                                    .font(.body)
                                if !card.subtitle.isEmpty {
                                    Text(verbatim: card.subtitle)
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

// MARK: - Change Card Type Sheet

/// Sheet for changing a card's type, with warning about relationship deletion.
struct ChangeCardTypeSheet: View {
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
