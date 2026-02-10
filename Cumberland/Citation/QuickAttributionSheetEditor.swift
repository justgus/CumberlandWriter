//
//  QuickAttributionSheetEditor.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//  Extracted from CardEditorView.swift
//
//  Inline attribution editor displayed when a user drops an image or URL onto a
//  card. Collects source title, authors, URL, locator, excerpt, and note, then
//  creates or reuses a Source record and inserts a Citation. Supports both image
//  and web-citation citation kinds. Extracted to reduce CardEditorView complexity.
//

import SwiftUI
import SwiftData

/// Quick attribution editor for dropped content
struct QuickAttributionSheetEditor: View {
    let card: Card
    let kind: CitationKind
    let suggestedURL: URL?
    let prefilledExcerpt: String?
    var onSave: (Citation) -> Void
    var onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var sourceTitle: String = ""
    @State private var sourceAuthors: String = ""
    @State private var sourceURLString: String = ""
    @State private var locator: String = ""
    @State private var excerpt: String = ""
    @State private var note: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(kind == .image ? "Image Attribution" : "Add Citation")
                .font(.title3).bold()

            GroupBox("Source") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Title (e.g., site, collection, book, etc.)", text: $sourceTitle)
                    TextField("Authors (optional)", text: $sourceAuthors)
                    TextField("URL (optional)", text: $sourceURLString)
                        .urlEntryTraits()
                }
            }

            GroupBox("Details") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: kind == .image ? "photo" : "text.quote")
                        Text("Kind: \(kind.displayName)")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    TextField("Locator (e.g., fig. 2, p. 42, 00:12:15)", text: $locator)
                    TextField("Excerpt (optional)", text: $excerpt)
                    TextField("Note (optional)", text: $note)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Button("Skip") {
                    onSkip()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    saveAttribution()
                } label: {
                    Label("Save", systemImage: "checkmark.circle.fill")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding()
        .onAppear {
            if let u = suggestedURL {
                sourceURLString = u.absoluteString
                // If title empty, infer from host
                if sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    sourceTitle = (u.host ?? "").isEmpty ? "Web Source" : (u.host ?? "Web Source")
                }
            }
            if let prefill = prefilledExcerpt, excerpt.isEmpty {
                excerpt = prefill
            }
        }
    }

    private var canSave: Bool {
        // Allow save if at least a title or a URL is provided
        let hasTitle = !sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasURL = !sourceURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasTitle || hasURL
    }

    @MainActor
    private func saveAttribution() {
        // Normalize fields
        let title = sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let authors = sourceAuthors.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlStr = sourceURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        let loc = locator.trimmingCharacters(in: .whitespacesAndNewlines)
        let exc = excerpt.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteVal = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let finalTitle: String = title.isEmpty
            ? (URL(string: urlStr)?.host ?? (kind == .image ? "Image Source" : "Source"))
            : title

        // Fetch existing Source with same title, or create new one
        let src = fetchOrCreateSource(title: finalTitle, authors: authors, urlStr: urlStr)

        let citation = Citation(card: card,
                                source: src,
                                kind: kind,
                                locator: loc,
                                excerpt: exc,
                                contextNote: noteVal.isEmpty ? nil : noteVal,
                                createdAt: Date())
        modelContext.insert(citation)
        try? modelContext.save()

        onSave(citation)
        dismiss()
    }

    /// Fetches an existing Source with matching title, or creates a new one if none exists.
    /// This prevents duplicate Sources for repeated attributions (e.g., multiple AI-generated images).
    @MainActor
    private func fetchOrCreateSource(title: String, authors: String, urlStr: String) -> Source {
        // Try to find existing Source with same title (case-insensitive match)
        let titleToMatch = title
        var fetchDescriptor = FetchDescriptor<Source>(
            predicate: #Predicate { $0.title == titleToMatch }
        )
        fetchDescriptor.fetchLimit = 1

        if let existingSource = try? modelContext.fetch(fetchDescriptor).first {
            // Update authors/URL if they were empty and now have values
            if existingSource.authors.isEmpty && !authors.isEmpty {
                existingSource.authors = authors
            }
            if existingSource.url == nil && !urlStr.isEmpty {
                existingSource.url = urlStr
                existingSource.accessedDate = Date()
            }
            return existingSource
        }

        // No existing source found, create new one
        let newSource = Source(
            title: title,
            authors: authors,
            url: urlStr.isEmpty ? nil : urlStr,
            accessedDate: urlStr.isEmpty ? nil : Date()
        )
        modelContext.insert(newSource)
        return newSource
    }
}

// MARK: - Cross-platform input traits helpers

private extension View {
    @ViewBuilder
    func urlEntryTraits() -> some View {
        #if os(iOS) || os(tvOS) || os(visionOS)
        if #available(iOS 15.0, tvOS 15.0, visionOS 1.0, *) {
            self
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
        } else {
            // Fallback for older OSes
            self
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        #else
        // macOS: no-op
        self
        #endif
    }
}
