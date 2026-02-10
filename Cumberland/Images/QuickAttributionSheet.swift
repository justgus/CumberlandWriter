//
//  QuickAttributionSheet.swift
//  Cumberland
//
//  Lightweight attribution capture sheet presented immediately after a user
//  drops or pastes an image. Pre-fills URL and excerpt from the drop payload
//  and lets the user save a Citation or skip attribution entirely.
//

import SwiftUI
import SwiftData
import Combine

struct QuickAttributionSheet: View {
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
    // Optional license for images
    @State private var license: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(kind == .image ? "Image Attribution" : "Add Citation")
                .font(.title3).bold()

            GroupBox("Source") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField(kind == .image ? "Source Title (e.g., site, collection, museum)" : "Title (e.g., site, collection, book, etc.)", text: $sourceTitle)
                    TextField(kind == .image ? "Creator/Photographer (optional)" : "Authors (optional)", text: $sourceAuthors)
                    TextField("URL (optional)", text: $sourceURLString)
                        .urlEntryTraits()

                    if kind == .image {
                        TextField("License (e.g., CC BY 4.0, Public Domain) — optional", text: $license)
                    }
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

                    TextField(kind == .image ? "Locator (e.g., fig. 2, 00:12:15)" : "Locator (e.g., fig. 2, p. 42, 00:12:15)", text: $locator)
                    TextField(kind == .image ? "Caption/Alt text (optional)" : "Excerpt (optional)", text: $excerpt)
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
                    sourceTitle = (u.host ?? "").isEmpty ? (kind == .image ? "Image Source" : "Web Source")
                                                          : (u.host ?? (kind == .image ? "Image Source" : "Web Source"))
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
        let licenseVal = license.trimmingCharacters(in: .whitespacesAndNewlines)

        let finalTitle: String = title.isEmpty
            ? (URL(string: urlStr)?.host ?? (kind == .image ? "Image Source" : "Source"))
            : title

        let src = Source(
            title: finalTitle,
            authors: authors,
            url: urlStr.isEmpty ? nil : urlStr,
            accessedDate: urlStr.isEmpty ? nil : Date(),
            license: licenseVal.isEmpty ? nil : licenseVal
        )
        modelContext.insert(src)

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
}

// Cross-platform input traits helpers (used by the URL TextField)
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
