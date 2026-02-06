//
//  CardEditorFormFields.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//  Extracted from CardEditorView.swift
//

import SwiftUI

/// Main form fields for CardEditorView
/// Name, subtitle, author, and detailed text fields
struct CardEditorFormFields: View {

    @Bindable var viewModel: CardEditorViewModel

    let kind: Kinds
    let focusedField: FocusState<CardEditorFocusField?>.Binding
    let onInsertDefaultAuthor: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Name field
            TextField("Name", text: $viewModel.name, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.title2.weight(.semibold))
                .lineLimit(2...4)
                .focused(focusedField, equals: .name)

            // Subtitle field
            TextField("Subtitle (optional)", text: $viewModel.subtitle, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1...3)
                .focused(focusedField, equals: .subtitle)

            // Author field
            HStack {
                TextField("Author (optional)", text: $viewModel.author)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .focused(focusedField, equals: .author)

                #if os(macOS)
                Button {
                    onInsertDefaultAuthor()
                } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                }
                .buttonStyle(.borderless)
                .help("Insert default author from settings")
                #endif
            }

            Divider()

            // Detailed text field
            TextField(
                kind == .scenes ? "Scene Description" : "Detailed Text",
                text: $viewModel.detailedText,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .font(.body)
            .lineLimit(6...20)
            .focused(focusedField, equals: .details)
            #if os(iOS)
            .textInputAutocapitalization(.sentences)
            #endif
        }
        .padding()
    }
}

/// Focus field enum for CardEditor
enum CardEditorFocusField: Hashable {
    case name
    case subtitle
    case author
    case details
}
