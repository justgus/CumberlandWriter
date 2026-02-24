//
//  SourcesView.swift
//  Cumberland
//
//  Two-column view for browsing and managing Source records. Left column is a
//  searchable list of sources sorted by title; right column shows the detail
//  editor for the selected source. Supports add and delete operations.
//

import SwiftUI
import SwiftData

struct SourcesView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Query(sort: \Source.title, order: .forward) private var sources: [Source]

    @State private var selection: Source?
    @State private var isPresentingNew: Bool = false

    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .sheet(isPresented: $isPresentingNew) {
            NewSourceSheet { created in
                selection = created
            }
            .frame(minWidth: 520, minHeight: 420)
            .environmentObject(themeManager)
        }
    }
    
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // Header with glass effect
            HStack {
                Text("Sources")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    isPresentingNew = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                }
                .glassButtonStyle()
            }
            .padding()
            .glassSurfaceStyle(cornerRadius: 0, interactive: false)
            
            // Sources list with glass styling
            if sources.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("No Sources")
                        .font(.title2.bold())
                    
                    Text("Create your first source to get started")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Add Source") {
                        isPresentingNew = true
                    }
                    .glassButtonStyle(prominent: true)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selection) {
                    ForEach(sources, id: \.id) { source in
                        SourceRowView(source: source)
                            .tag(source as Source?)
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.plain)
            }
        }
    }
    
    private var detailContent: some View {
        Group {
            if let selectedSource = selection {
                SourceDetailView(source: selectedSource)
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundStyle(.quaternary)
                    
                    VStack(spacing: 8) {
                        Text("Select a Source")
                            .font(.title.bold())
                        
                        Text("Choose a source from the list or create a new one to get started.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .glassSurfaceStyle(cornerRadius: 20, interactive: false)
                .padding()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            guard sources.indices.contains(idx) else { continue }
            let source = sources[idx]
            
            // Delete dependent citations
            let targetID = source.id
            let fetch = FetchDescriptor<Citation>(predicate: #Predicate { $0.source?.id == targetID })
            if let citations = try? modelContext.fetch(fetch) {
                for citation in citations { 
                    modelContext.delete(citation) 
                }
            }
            modelContext.delete(source)
        }
        try? modelContext.save()
    }
}

// MARK: - Source Row View

private struct SourceRowView: View {
    let source: Source
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: source.title)
                .font(.headline)
                .lineLimit(2)
            
            if !source.authors.isEmpty {
                Text(source.authors)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            HStack {
                if let year = source.year, year > 0 {
                    Text(String(year))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let container = source.containerTitle, !container.isEmpty {
                    Text("• \(container)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Source Detail View

private struct SourceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var source: Source
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.title.isEmpty ? "Untitled Source" : source.title)
                            .font(.largeTitle.bold())
                        
                        if !source.authors.isEmpty {
                            Text(source.authors)
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .glassSurfaceStyle(cornerRadius: 16, tint: .blue, interactive: false)
                
                // Publication Details
                GlassFormSection("Publication Details", tint: .green) {
                    VStack(spacing: 16) {
                        formRow("Title", text: $source.title)
                        formRow("Authors", text: $source.authors)
                        formRow("Container", text: Binding(
                            get: { source.containerTitle ?? "" },
                            set: { source.containerTitle = $0.isEmpty ? nil : $0 }
                        ))
                        formRow("Publisher", text: Binding(
                            get: { source.publisher ?? "" },
                            set: { source.publisher = $0.isEmpty ? nil : $0 }
                        ))
                        
                        HStack(spacing: 16) {
                            formRow("Year", text: Binding(
                                get: { source.year == nil || source.year == 0 ? "" : String(source.year!) },
                                set: { source.year = Int($0) }
                            ))
                            formRow("Volume", text: Binding(
                                get: { source.volume ?? "" },
                                set: { source.volume = $0.isEmpty ? nil : $0 }
                            ))
                            formRow("Issue", text: Binding(
                                get: { source.issue ?? "" },
                                set: { source.issue = $0.isEmpty ? nil : $0 }
                            ))
                            formRow("Pages", text: Binding(
                                get: { source.pages ?? "" },
                                set: { source.pages = $0.isEmpty ? nil : $0 }
                            ))
                        }
                    }
                    .padding()
                }
                
                // Digital Information
                GlassFormSection("Digital Information", tint: .orange) {
                    VStack(spacing: 16) {
                        formRow("DOI", text: Binding(
                            get: { source.doi ?? "" },
                            set: { source.doi = $0.isEmpty ? nil : $0 }
                        ))
                        formRow("URL", text: Binding(
                            get: { source.url ?? "" },
                            set: { source.url = $0.isEmpty ? nil : $0 }
                        ))
                        
                        HStack {
                            Text("Accessed")
                                .font(.headline)
                            Spacer()
                            DatePicker("", selection: Binding(
                                get: { source.accessedDate ?? Date() },
                                set: { source.accessedDate = $0 }
                            ), displayedComponents: .date)
                            .labelsHidden()
                        }
                        
                        formRow("License", text: Binding(
                            get: { source.license ?? "" },
                            set: { source.license = $0.isEmpty ? nil : $0 }
                        ))
                    }
                    .padding()
                }
                
                // Notes
                GlassFormSection("Notes", tint: .purple) {
                    TextEditor(text: Binding(
                        get: { source.notes ?? "" },
                        set: { source.notes = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 100)
                    .padding()
                }
            }
            .padding()
        }
        .onDisappear {
            try? modelContext.save()
        }
    }
    
    private func formRow(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.headline)
                .frame(width: 80, alignment: .leading)
            
            TextField(label, text: text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassSurfaceStyle(cornerRadius: 8, interactive: true)
        }
    }
}

// MARK: - New Source Sheet

private struct NewSourceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title: String = ""
    @State private var authors: String = ""

    var onCreate: (Source) -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("New Source")
                        .font(.largeTitle.bold())
                    Text("Add a new source to your library")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .glassSurfaceStyle(cornerRadius: 16, tint: .blue, interactive: false)
            
            // Form
            GlassFormSection("Source Information", tint: .green) {
                VStack(spacing: 16) {
                    HStack {
                        Text("Title")
                            .font(.headline)
                            .frame(width: 80, alignment: .leading)
                        
                        TextField("Enter source title", text: $title)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .glassSurfaceStyle(cornerRadius: 8, interactive: true)
                    }
                    
                    HStack {
                        Text("Authors")
                            .font(.headline)
                            .frame(width: 80, alignment: .leading)
                        
                        TextField("Enter author names", text: $authors)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .glassSurfaceStyle(cornerRadius: 8, interactive: true)
                    }
                }
                .padding()
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .glassButtonStyle()
                
                Spacer()
                
                Button("Create Source") {
                    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedAuthors = authors.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let newSource = Source(title: trimmedTitle, authors: trimmedAuthors)
                    modelContext.insert(newSource)
                    try? modelContext.save()
                    onCreate(newSource)
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .glassButtonStyle(prominent: true)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    SourcesView()
        .modelContainer(for: [Source.self, Citation.self], inMemory: true)
}
