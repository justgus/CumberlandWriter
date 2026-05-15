//
//  RelationTypeFormView.swift
//  Cumberland
//
//  Form for creating or editing a RelationType. Collects the unique code,
//  forward label (source→target), and inverse label (target→source), then
//  either inserts a new RelationType or updates the existing one in the
//  SwiftData context.
//

import SwiftUI
import SwiftData

struct RelationTypeFormView: View {
    enum Mode: Equatable {
        case create
        case edit(RelationType)
    }

    let mode: Mode
    var onDone: (RelationType) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var code: String = ""
    @State private var forwardLabel: String = ""
    @State private var inverseLabel: String = ""
    @State private var sourceKind: Kinds? = nil
    @State private var targetKind: Kinds? = nil
    @State private var autoEnsureMirror: Bool = true

    @State private var errorMessage: String?

    init(mode: Mode, initialSourceKind: Kinds? = nil, initialTargetKind: Kinds? = nil, onDone: @escaping (RelationType) -> Void) {
        self.mode = mode
        self.onDone = onDone
        switch mode {
        case .create:
            _sourceKind = State(initialValue: initialSourceKind)
            _targetKind = State(initialValue: initialTargetKind)
        case .edit(let t):
            _code = State(initialValue: t.code)
            _forwardLabel = State(initialValue: t.forwardLabel)
            _inverseLabel = State(initialValue: t.inverseLabel)
            _sourceKind = State(initialValue: t.sourceKind)
            _targetKind = State(initialValue: t.targetKind)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(modeTitle)
                .font(.title3.bold())

            GroupBox("Labels") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Forward label", text: $forwardLabel)
                        .textFieldStyle(.roundedBorder)
                    TextField("Inverse label", text: $inverseLabel)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 8) {
                        Button {
                            swapLabels()
                        } label: {
                            Label("Swap labels", systemImage: "arrow.left.arrow.right")
                        }
                        .buttonStyle(.bordered)
                        .help("Swap the forward and inverse labels.")

                        Spacer()

                        Toggle("Create/Update Mirror Pair", isOn: $autoEnsureMirror)
                            .toggleStyle(.switch)
                            .help("Ensure a mirrored relation type with swapped kinds and labels exists.")
                    }
                }
            }

            GroupBox("Kinds (optional)") {
                HStack(spacing: 12) {
                    kindPicker(title: "From", selection: $sourceKind)
                    Image(systemName: "arrow.right").foregroundStyle(.secondary)
                    kindPicker(title: "To", selection: $targetKind)
                    Spacer()
                }
            }

            GroupBox("Code") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("code", text: $code)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption.monospaced())
                    Button {
                        code = makeCode(forward: forwardLabel, inverse: inverseLabel)
                    } label: {
                        Label("Generate from labels", systemImage: "wand.and.stars")
                    }
                    .disabled(forwardLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              inverseLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if let err = errorMessage, !err.isEmpty {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
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
                    Task { await save() }
                } label: {
                    Label("Save", systemImage: "checkmark.circle.fill")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding()
        .onAppear {
            if case .create = mode, code.isEmpty, !forwardLabel.isEmpty, !inverseLabel.isEmpty {
                code = makeCode(forward: forwardLabel, inverse: inverseLabel)
            }
        }
    }

    private var modeTitle: String {
        switch mode {
        case .create: return "New Relation Type"
        case .edit: return "Edit Relation Type"
        }
    }

    private var isValid: Bool {
        !forwardLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !inverseLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // DR-0103: Delegate to RelationTypeManager for save, mirror, and code operations
    @MainActor
    private func save() async {
        guard isValid else { return }
        let mgr = RelationTypeManager(modelContext: modelContext)

        if case .create = mode {
            if mgr.fetchRelationType(code: code) != nil {
                errorMessage = "A relation type with code \"\(code)\" already exists."
                return
            }
            do {
                let t = try mgr.createRelationType(code: code, forwardLabel: forwardLabel, inverseLabel: inverseLabel, sourceKind: sourceKind, targetKind: targetKind)
                if autoEnsureMirror {
                    mgr.ensureMirror(forwardLabel: forwardLabel, inverseLabel: inverseLabel, sourceKind: sourceKind, targetKind: targetKind)
                    try? modelContext.save()
                }
                onDone(t)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        } else if case .edit(let existing) = mode {
            if existing.code != code, mgr.fetchRelationType(code: code) != nil {
                errorMessage = "A relation type with code \"\(code)\" already exists."
                return
            }
            existing.code = code
            existing.forwardLabel = forwardLabel
            existing.inverseLabel = inverseLabel
            existing.sourceKind = sourceKind
            existing.targetKind = targetKind
            if autoEnsureMirror {
                mgr.ensureMirror(forwardLabel: forwardLabel, inverseLabel: inverseLabel, sourceKind: sourceKind, targetKind: targetKind)
            }
            try? modelContext.save()
            onDone(existing)
            dismiss()
        }
    }

    private func kindPicker(title: String, selection: Binding<Kinds?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Menu {
                Button {
                    selection.wrappedValue = nil
                } label: {
                    Label("Any", systemImage: "circle.dotted")
                }
                Divider()
                ForEach(Kinds.orderedCases) { k in
                    Button {
                        selection.wrappedValue = k
                    } label: {
                        Label(k.title, systemImage: k.systemImage)
                    }
                }
            } label: {
                HStack {
                    if let k = selection.wrappedValue {
                        Label(k.title, systemImage: k.systemImage)
                    } else {
                        Label("Any", systemImage: "circle.dotted")
                    }
                    Image(systemName: "chevron.down").font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
            }
        }
    }

    // DR-0103: Delegate to RelationTypeManager static utilities
    private func makeCode(forward: String, inverse: String, suffix: Int? = nil) -> String {
        RelationTypeManager.makeCode(forward: forward, inverse: inverse, suffix: suffix)
    }

    private func swapLabels() {
        (forwardLabel, inverseLabel) = (inverseLabel, forwardLabel)
    }
}

extension RelationTypeFormView.Mode: Identifiable {
    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let t): return "edit-\(t.code)"
        }
    }
}
