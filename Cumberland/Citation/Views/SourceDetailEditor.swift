//
//  SourceDetailEditor.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-09.
//  DR-0082: Source Detail Editor for Source cards
//

import SwiftUI
import SwiftData

/// Detail editor for Source cards, displayed when viewing a Source card
/// Bridges Card (kind=.sources) with the Source model for citations
struct SourceDetailEditor: View {
    @Bindable var card: Card
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Basic card info (synced to Source)
                basicInfoSection

                Divider()

                // Source-specific fields
                if let source = card.sourceRef {
                    sourceFieldsSection(source: source)
                } else {
                    createSourcePrompt
                }
            }
            .padding()
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Source Title", text: $card.name)
                .textFieldStyle(.roundedBorder)
                .onChange(of: card.name) { _, newValue in
                    // Sync title to linked Source
                    card.sourceRef?.title = newValue
                }

            Text("Authors")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Author(s)", text: $card.subtitle)
                .textFieldStyle(.roundedBorder)
                .onChange(of: card.subtitle) { _, newValue in
                    // Sync authors to linked Source
                    card.sourceRef?.authors = newValue
                }
        }
    }

    // MARK: - Create Source Prompt

    private var createSourcePrompt: some View {
        VStack(spacing: 12) {
            Label("No Bibliographic Data", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(.orange)

            Text("This source card needs bibliographic data to be used in citations.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Create Bibliographic Source") {
                // Create Source with current card values
                let newSource = Source(
                    title: card.name,
                    authors: card.subtitle
                )
                modelContext.insert(newSource)
                // Link bidirectionally
                newSource.sourceCard = card
                card.sourceRef = newSource
                // Force save to ensure relationship is persisted
                try? modelContext.save()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - Source Fields Section

    @ViewBuilder
    private func sourceFieldsSection(source: Source) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Publication Details
            GroupBox("Publication Details") {
                VStack(alignment: .leading, spacing: 8) {
                    fieldRow(label: "Container/Journal", text: Binding(
                        get: { source.containerTitle ?? "" },
                        set: { source.containerTitle = $0.isEmpty ? nil : $0 }
                    ))

                    fieldRow(label: "Publisher", text: Binding(
                        get: { source.publisher ?? "" },
                        set: { source.publisher = $0.isEmpty ? nil : $0 }
                    ))

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Year")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Year", value: Binding(
                                get: { source.year },
                                set: { source.year = $0 }
                            ), format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Volume")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Vol", text: Binding(
                                get: { source.volume ?? "" },
                                set: { source.volume = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Issue")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("No.", text: Binding(
                                get: { source.issue ?? "" },
                                set: { source.issue = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                    }

                    fieldRow(label: "Pages", text: Binding(
                        get: { source.pages ?? "" },
                        set: { source.pages = $0.isEmpty ? nil : $0 }
                    ))
                }
            }

            // Digital/Web Details
            GroupBox("Digital References") {
                VStack(alignment: .leading, spacing: 8) {
                    fieldRow(label: "DOI", text: Binding(
                        get: { source.doi ?? "" },
                        set: { source.doi = $0.isEmpty ? nil : $0 }
                    ))

                    fieldRow(label: "URL", text: Binding(
                        get: { source.url ?? "" },
                        set: { source.url = $0.isEmpty ? nil : $0 }
                    ))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accessed Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        DatePicker("", selection: Binding(
                            get: { source.accessedDate ?? Date() },
                            set: { source.accessedDate = $0 }
                        ), displayedComponents: .date)
                        .labelsHidden()

                        if source.accessedDate != nil {
                            Button("Clear Date") {
                                source.accessedDate = nil
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // License & Notes
            GroupBox("Additional Information") {
                VStack(alignment: .leading, spacing: 8) {
                    fieldRow(label: "License", text: Binding(
                        get: { source.license ?? "" },
                        set: { source.license = $0.isEmpty ? nil : $0 }
                    ))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: Binding(
                            get: { source.notes ?? "" },
                            set: { source.notes = $0.isEmpty ? nil : $0 }
                        ))
                        .frame(minHeight: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }

            // Chicago-style preview
            GroupBox("Citation Preview (Chicago)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Short Form:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(source.chicagoShort)
                        .font(.footnote)
                        .italic()

                    Divider()

                    Text("Bibliography:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(source.chicagoBibliography)
                        .font(.footnote)
                }
            }
        }
    }

    // MARK: - Helper Views

    private func fieldRow(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(label, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Preview

#Preview("Source Detail Editor") {
    @Previewable @State var previewCard: Card = {
        let card = Card(kind: .sources, name: "The Hero with a Thousand Faces", subtitle: "Joseph Campbell", detailedText: "")
        return card
    }()

    NavigationStack {
        SourceDetailEditor(card: previewCard)
            .navigationTitle("Edit Source")
    }
}
