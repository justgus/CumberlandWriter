//
//  CardSheetEditorArea.swift
//  Cumberland
//
//  Extracted from CardSheetView.swift as part of ER-0022 Phase 3.2.
//  Provides the three-mode content area (Edit / Preview / Split) for card
//  detail text. Edit mode uses a TextEditor with markdown formatting shortcuts;
//  Preview mode renders CommonMark via AttributedString; Split shows both.
//

import SwiftUI
import UniformTypeIdentifiers

/// Editor area modes
enum CardSheetEditorMode: String, CaseIterable, Identifiable {
    case edit = "Edit"
    case preview = "Preview"
    case split = "Split"

    var id: String { rawValue }
}

/// Editor area view for CardSheetView containing markdown editing and preview
struct CardSheetEditorArea: View {
    let card: Card
    @Binding var editorMode: CardSheetEditorMode
    @Binding var detailsDraft: String
    @Binding var detailsSelection: NSRange
    @FocusState.Binding var focusedField: CardSheetFieldFocus?

    let toolbarItems: [AdaptiveToolbar.Item]
    let onSaveDetailsIfDirty: (String) -> Void
    let onTextDrop: ([NSItemProvider]) -> Bool
    let onIndent: (Bool) -> Void  // isOutdent

    private var isDetailsEditable: Bool {
        editorMode != .preview
    }

    private static let textDropTypes: [UTType] = [.plainText, .text, .url]

    var body: some View {
        switch editorMode {
        case .edit:
            editorStack
        case .preview:
            previewStack
        case .split:
            splitStack
        }
    }

    // MARK: - Editor Stack

    @ViewBuilder
    private var editorStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            AdaptiveToolbar(items: toolbarItems)
                .disabled(!isDetailsEditable)
                .glassToolbarStyle()
                .controlSize(.small)
                .labelStyle(.iconOnly)
                .accessibilityElement(children: .contain)

            RichTextEditor(
                text: $detailsDraft,
                selectedRange: $detailsSelection,
                isFirstResponder: focusedField == .details,
                editable: isDetailsEditable,
                onTab: { onIndent(false) },
                onBacktab: { onIndent(true) }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
                    .allowsHitTesting(false)
            )
            .onDrop(of: Self.textDropTypes, isTargeted: nil) { providers in
                onTextDrop(providers)
            }
        }
        .onAppear {
            detailsDraft = card.detailedText
        }
        .onChange(of: focusedField) { _, newFocus in
            if newFocus != .details {
                onSaveDetailsIfDirty("Edit Details")
            } else {
                if detailsSelection.length == 0 && detailsSelection.location == 0 {
                    detailsSelection = NSRange(location: (detailsDraft as NSString).length, length: 0)
                }
            }
        }
    }

    // MARK: - Preview Stack

    @ViewBuilder
    private var previewStack: some View {
        Group {
            if !detailsDraft.isEmpty {
                RichTextEditor(
                    text: $detailsDraft,
                    selectedRange: $detailsSelection,
                    isFirstResponder: false,
                    editable: false
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.regularMaterial)
                        .allowsHitTesting(false)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    detailsDraft = card.detailedText
                    editorMode = .edit
                    focusedField = .details
                }
            } else {
                Text("No details yet.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                            .allowsHitTesting(false)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        detailsDraft = card.detailedText
                        editorMode = .edit
                        focusedField = .details
                    }
            }
        }
    }

    // MARK: - Split Stack

    @ViewBuilder
    private var splitStack: some View {
        #if os(macOS)
        HStack(spacing: 16) {
            editorStack
            previewStack
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        #else
        VStack(alignment: .leading, spacing: 16) {
            editorStack
            previewStack
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        #endif
    }
}

// MARK: - Mode Picker

struct CardSheetModePicker: View {
    @Binding var editorMode: CardSheetEditorMode

    var body: some View {
        Picker("Mode", selection: $editorMode) {
            ForEach(CardSheetEditorMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Editor Mode")
    }
}

// MARK: - RichTextEditor (fallback if not defined elsewhere)

/// Fallback RichTextEditor if the custom one isn't available
struct RichTextEditor: View {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    let isFirstResponder: Bool
    let editable: Bool
    var onTab: (() -> Void)? = nil
    var onBacktab: (() -> Void)? = nil

    init(text: Binding<String>,
         selectedRange: Binding<NSRange>,
         isFirstResponder: Bool,
         editable: Bool,
         onTab: (() -> Void)? = nil,
         onBacktab: (() -> Void)? = nil) {
        self._text = text
        self._selectedRange = selectedRange
        self.isFirstResponder = isFirstResponder
        self.editable = editable
        self.onTab = onTab
        self.onBacktab = onBacktab
    }

    var body: some View {
        TextEditor(text: $text)
            .disabled(!editable)
    }
}

// MARK: - Glass Toolbar Style Extension

extension View {
    func glassToolbarStyle() -> some View {
        self
    }
}
