// SourcesView.swift
import SwiftUI
import SwiftData

struct SourcesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Source.title, order: .forward) private var sources: [Source]

    @State private var selection: Source?
    @State private var isPresentingNew: Bool = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(sources) { s in
                    Text(s.title)
                        .tag(s as Source?)
                }
                .onDelete(perform: delete)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingNew = true
                    } label: {
                        Label("New Source", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let s = selection {
                SourceEditorView(source: s)
                    .padding()
            } else {
                ContentPlaceholderView(
                    title: "Select a source",
                    subtitle: "Choose a source from the list or create a new one."
                )
            }
        }
        .sheet(isPresented: $isPresentingNew) {
            NewSourceSheet { created in
                selection = created
            }
            .frame(minWidth: 420, minHeight: 320)
        }
    }

    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            guard sources.indices.contains(idx) else { continue }
            let s = sources[idx]
            // Delete dependent citations
            let targetID = s.id
            let fetch = FetchDescriptor<Citation>(predicate: #Predicate { $0.source.id == targetID })
            if let cites = try? modelContext.fetch(fetch) {
                for c in cites { modelContext.delete(c) }
            }
            modelContext.delete(s)
        }
        try? modelContext.save()
    }
}

private struct SourceEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var source: Source

    var body: some View {
        Form {
            Section("Title & Authors") {
                TextField("Title", text: $source.title)
                TextField("Authors", text: $source.authors)
            }
            Section("Publication") {
                TextField("Container (Journal/Book/Site)", text: Binding(get: { source.containerTitle ?? "" }, set: { source.containerTitle = $0.isEmpty ? nil : $0 }))
                TextField("Publisher", text: Binding(get: { source.publisher ?? "" }, set: { source.publisher = $0.isEmpty ? nil : $0 }))
                TextField("Year", value: Binding(get: { source.year }, set: { source.year = $0 }), format: .number)
                TextField("Volume", text: Binding(get: { source.volume ?? "" }, set: { source.volume = $0.isEmpty ? nil : $0 }))
                TextField("Issue", text: Binding(get: { source.issue ?? "" }, set: { source.issue = $0.isEmpty ? nil : $0 }))
                TextField("Pages", text: Binding(get: { source.pages ?? "" }, set: { source.pages = $0.isEmpty ? nil : $0 }))
            }
            Section("Links & Rights") {
                TextField("DOI", text: Binding(get: { source.doi ?? "" }, set: { source.doi = $0.isEmpty ? nil : $0 }))
                TextField("URL", text: Binding(get: { source.url ?? "" }, set: { source.url = $0.isEmpty ? nil : $0 }))
                DatePicker("Accessed", selection: Binding(get: { source.accessedDate ?? Date() }, set: { source.accessedDate = $0 }), displayedComponents: .date)
                TextField("License", text: Binding(get: { source.license ?? "" }, set: { source.license = $0.isEmpty ? nil : $0 }))
            }
            Section("Notes") {
                TextField("Notes", text: Binding(get: { source.notes ?? "" }, set: { source.notes = $0.isEmpty ? nil : $0 }))
            }
        }
        .onDisappear {
            try? modelContext.save()
        }
    }
}

private struct NewSourceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title: String = ""
    @State private var authors: String = ""

    var onCreate: (Source) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Source").font(.title3).bold()
            Form {
                TextField("Title", text: $title)
                TextField("Authors", text: $authors)
            }
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Create") {
                    let s = Source(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                   authors: authors.trimmingCharacters(in: .whitespacesAndNewlines))
                    modelContext.insert(s)
                    try? modelContext.save()
                    onCreate(s)
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
}

#Preview {
    SourcesView()
        .modelContainer(for: [Source.self, Citation.self], inMemory: true)
}

