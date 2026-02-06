//
//  CardEditorStructurePanel.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//  Extracted from CardEditorView.swift
//

import SwiftUI

/// Structure creation panel for Project cards
struct CardEditorStructurePanel: View {

    @Bindable var viewModel: CardEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Attach Story Structure", isOn: $viewModel.attachStructure)
                .font(.headline)

            if viewModel.attachStructure {
                Picker("Source", selection: $viewModel.structureSource) {
                    ForEach(StructureSource.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.structureSource == .template {
                    templateStructureEditor
                } else {
                    customStructureEditor
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private var templateStructureEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            let templates = StoryStructure.predefinedTemplates

            Picker("Template", selection: $viewModel.selectedTemplateIndex) {
                ForEach(templates.indices, id: \.self) { index in
                    Text(templates[index].name).tag(index)
                }
            }
            .onChange(of: viewModel.selectedTemplateIndex) { _, newIndex in
                guard templates.indices.contains(newIndex) else { return }
                let template = templates[newIndex]
                viewModel.structureName = template.name
                viewModel.editableElements = template.elements.map { EditableElement(name: $0) }
            }

            TextField("Structure Name", text: $viewModel.structureName)
                .textFieldStyle(.roundedBorder)

            structureElementsList
        }
    }

    @ViewBuilder
    private var customStructureEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Structure Name", text: $viewModel.structureName)
                .textFieldStyle(.roundedBorder)

            structureElementsList

            Button {
                viewModel.editableElements.append(EditableElement(name: "New Element"))
            } label: {
                Label("Add Element", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderless)
        }
    }

    @ViewBuilder
    private var structureElementsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Elements (\(viewModel.editableElements.count))")
                    .font(.subheadline.bold())

                Spacer()

                Toggle(isOn: $viewModel.isReordering) {
                    Text("Reorder")
                        .font(.caption)
                }
                .toggleStyle(.button)
            }

            List {
                ForEach($viewModel.editableElements) { $element in
                    HStack {
                        TextField("Element Name", text: $element.name)
                            .textFieldStyle(.plain)

                        if !viewModel.isReordering {
                            Button(role: .destructive) {
                                viewModel.editableElements.removeAll { $0.id == element.id }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .onMove { indices, newOffset in
                    viewModel.editableElements.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            .frame(height: 200)
            .listStyle(.plain)
            #if !os(macOS)
            .environment(\.editMode, viewModel.isReordering ? .constant(.active) : .constant(.inactive))
            #endif
        }
    }
}
