//
//  SourceEditorSheet.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-09.
//  DR-0082: Source creation/editing sheet
//  Creates Source model first, then auto-generates linked Card on save
//

import SwiftUI
import SwiftData

/// Sheet for creating or editing a bibliographic Source
/// On save, automatically creates/updates the linked Card (kind=.sources)
struct SourceEditorSheet: View {
    /// Pass nil to create a new Source, or an existing Source to edit
    let existingSource: Source?
    var onSave: ((Source) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Form state
    @State private var title: String = ""
    @State private var authors: String = ""
    @State private var containerTitle: String = ""
    @State private var publisher: String = ""
    @State private var year: Int?
    @State private var volume: String = ""
    @State private var issue: String = ""
    @State private var pages: String = ""
    @State private var doi: String = ""
    @State private var url: String = ""
    @State private var accessedDate: Date?
    @State private var license: String = ""
    @State private var notes: String = ""

    private var isEditing: Bool { existingSource != nil }

    var body: some View {
        NavigationStack {
            Form {
                // Required fields
                Section("Basic Information") {
                    TextField("Title *", text: $title)
                    TextField("Authors", text: $authors)
                }

                // Publication details
                Section("Publication Details") {
                    TextField("Container / Journal", text: $containerTitle)
                    TextField("Publisher", text: $publisher)
                    HStack {
                        // Use custom format to avoid commas in year (e.g., "1949" not "1,949")
                        TextField("Year", value: $year, format: .number.grouping(.never))
                            .frame(maxWidth: 100)
                        TextField("Volume", text: $volume)
                        TextField("Issue", text: $issue)
                    }
                    TextField("Pages", text: $pages)
                }

                // Digital references
                Section("Digital References") {
                    TextField("DOI", text: $doi)
                    TextField("URL", text: $url)
                    DatePicker("Accessed Date", selection: Binding(
                        get: { accessedDate ?? Date() },
                        set: { accessedDate = $0 }
                    ), displayedComponents: .date)
                    if accessedDate != nil {
                        Button("Clear Accessed Date", role: .destructive) {
                            accessedDate = nil
                        }
                        .font(.caption)
                    }
                }

                // Additional info
                Section("Additional Information") {
                    TextField("License", text: $license)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Preview
                Section("Citation Preview (Chicago)") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Short Form:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(previewChicagoShort)
                            .font(.footnote)
                            .italic()

                        Divider()

                        Text("Bibliography:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(previewChicagoBibliography)
                            .font(.footnote)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Source" : "New Source")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        saveSource()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let source = existingSource {
                    loadFromSource(source)
                }
            }
        }
    }

    // MARK: - Preview Helpers

    private var previewChicagoShort: String {
        let authorPart = authors.isEmpty ? "" : authors
        let yearStr = year.map { String($0) } ?? ""
        let titlePart = title.isEmpty ? "" : "\"\(title)\""
        return [authorPart, titlePart, yearStr].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    private var previewChicagoBibliography: String {
        var parts: [String] = []
        if !authors.isEmpty { parts.append(authors) }
        if !title.isEmpty { parts.append("\"\(title).\"") }
        if !containerTitle.isEmpty { parts.append(containerTitle) }
        if !volume.isEmpty { parts.append(volume) }
        if !issue.isEmpty { parts.append("no. \(issue)") }
        if !pages.isEmpty { parts.append(pages) }
        if !publisher.isEmpty { parts.append(publisher) }
        if let y = year { parts.append(String(y)) }
        if !doi.isEmpty { parts.append(doi) }
        if !url.isEmpty { parts.append(url) }
        return parts.joined(separator: " ")
    }

    // MARK: - Load/Save

    private func loadFromSource(_ source: Source) {
        title = source.title
        authors = source.authors
        containerTitle = source.containerTitle ?? ""
        publisher = source.publisher ?? ""
        year = source.year
        volume = source.volume ?? ""
        issue = source.issue ?? ""
        pages = source.pages ?? ""
        doi = source.doi ?? ""
        url = source.url ?? ""
        accessedDate = source.accessedDate
        license = source.license ?? ""
        notes = source.notes ?? ""
    }

    private func saveSource() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        if let source = existingSource {
            // Update existing source
            updateSource(source)
            // Update linked card if exists
            if let card = source.sourceCard {
                card.name = trimmedTitle
                card.subtitle = authors
            }
            onSave?(source)
        } else {
            // Create new source
            let newSource = Source(
                title: trimmedTitle,
                authors: authors,
                containerTitle: containerTitle.isEmpty ? nil : containerTitle,
                publisher: publisher.isEmpty ? nil : publisher,
                year: year,
                volume: volume.isEmpty ? nil : volume,
                issue: issue.isEmpty ? nil : issue,
                pages: pages.isEmpty ? nil : pages,
                doi: doi.isEmpty ? nil : doi,
                url: url.isEmpty ? nil : url,
                accessedDate: accessedDate,
                license: license.isEmpty ? nil : license,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(newSource)

            // Auto-create linked Card
            let newCard = Card(
                kind: .sources,
                name: trimmedTitle,
                subtitle: authors,
                detailedText: ""
            )
            modelContext.insert(newCard)

            // Link bidirectionally
            newSource.sourceCard = newCard
            newCard.sourceRef = newSource

            try? modelContext.save()
            onSave?(newSource)
        }

        dismiss()
    }

    private func updateSource(_ source: Source) {
        source.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        source.authors = authors
        source.containerTitle = containerTitle.isEmpty ? nil : containerTitle
        source.publisher = publisher.isEmpty ? nil : publisher
        source.year = year
        source.volume = volume.isEmpty ? nil : volume
        source.issue = issue.isEmpty ? nil : issue
        source.pages = pages.isEmpty ? nil : pages
        source.doi = doi.isEmpty ? nil : doi
        source.url = url.isEmpty ? nil : url
        source.accessedDate = accessedDate
        source.license = license.isEmpty ? nil : license
        source.notes = notes.isEmpty ? nil : notes
    }
}

// MARK: - Preview

#Preview("New Source") {
    SourceEditorSheet(existingSource: nil)
}

#Preview("Edit Source") {
    let source = Source(
        title: "The Hero with a Thousand Faces",
        authors: "Joseph Campbell",
        publisher: "Princeton University Press",
        year: 1949
    )
    return SourceEditorSheet(existingSource: source)
}
