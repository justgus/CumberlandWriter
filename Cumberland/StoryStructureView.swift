//
//  StoryStructureView.swift
//  Cumberland
//
//  Created by Assistant on 10/10/25.
//

import SwiftUI
import SwiftData

struct StoryStructureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoryStructure.name, order: .forward) private var structures: [StoryStructure]

    // Use a stable UUID-based selection to avoid Hashable conformance on @Model classes.
    @State private var selectedStructureID: UUID?
    private var selectedStructure: StoryStructure? {
        guard let id = selectedStructureID else { return nil }
        return structures.first(where: { $0.id == id })
    }

    @State private var showingNewStructureSheet = false
    @State private var showingTemplateSheet = false

    // Left pane sizing
    private let sidebarMinWidth: CGFloat = 260
    private let sidebarIdealWidth: CGFloat = 320
    private let sidebarMaxWidth: CGFloat = 480

    var body: some View {
        // Two-pane layout to avoid nested NavigationSplitView
        HStack(spacing: 0) {
            sidebar
                .frame(minWidth: sidebarMinWidth, idealWidth: sidebarIdealWidth, maxWidth: sidebarMaxWidth)
                .overlay(Divider(), alignment: .trailing)

            // Detail
            Group {
                if let structure = selectedStructure {
                    StructureDetailView(structure: structure)
                } else {
                    ContentPlaceholderView(
                        title: "Select a Structure",
                        subtitle: "Choose a story structure to view and edit its elements.",
                        systemImage: "list.number"
                    )
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Story Structures")
        .sheet(isPresented: $showingNewStructureSheet) {
            NewStructureSheet()
        }
        .sheet(isPresented: $showingTemplateSheet) {
            StructureTemplateSheet()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("Add Structure", systemImage: "plus") {
                    Button("Custom Structure") {
                        showingNewStructureSheet = true
                    }

                    Button("From Template") {
                        showingTemplateSheet = true
                    }
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
        .onAppear {
            // Auto-select the first structure if nothing is selected
            if selectedStructureID == nil, let first = structures.first {
                selectedStructureID = first.id
            }
        }
        .onChange(of: structures) { _, newList in
            // Maintain selection if possible; otherwise select first available
            if let sel = selectedStructureID, newList.contains(where: { $0.id == sel }) {
                // keep
            } else {
                selectedStructureID = newList.first?.id
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedStructureID) {
            Section("Your Structures") {
                ForEach(structures) { structure in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(structure.name)
                                .font(.callout)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Text("\((structure.elements ?? []).count) elements")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .tag(structure.id as UUID?)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedStructureID = structure.id
                    }
                }
                .onDelete(perform: deleteStructures)
            }

            Section("Quick Actions") {
                Button {
                    showingTemplateSheet = true
                } label: {
                    Text("Create from Template")
                }
                .buttonStyle(GlassButtonStyle())

                Button {
                    showingNewStructureSheet = true
                } label: {
                    Text("Create Custom Structure")
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Deletion

    private func deleteStructures(offsets: IndexSet) {
        withAnimation {
            let toDelete = offsets.map { structures[$0] }
            // Clear selection if we are deleting the selected structure
            if let sel = selectedStructureID, toDelete.contains(where: { $0.id == sel }) {
                selectedStructureID = nil
            }
            for item in toDelete {
                modelContext.delete(item)
            }
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete structures: \(error)")
            }
        }
    }
}

struct StructureDetailView: View {
    @Bindable var structure: StoryStructure
    @Environment(\.modelContext) private var modelContext

    @State private var newElementName = ""
    @State private var showingAddElement = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                TextField("Structure Name", text: $structure.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .textFieldStyle(.plain)

                Text("\((structure.elements ?? []).count) elements")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Divider()

            // Elements list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach((structure.elements ?? []).sorted { $0.orderIndex < $1.orderIndex }) { element in
                        StructureElementRow(element: element)
                    }

                    // Add element button
                    Button(action: { showingAddElement = true }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Element")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(GlassButtonStyle())
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(structure.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("Add Element", isPresented: $showingAddElement) {
            TextField("Element name", text: $newElementName)
            Button("Add") {
                addElement()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for the new structural element.")
        }
    }

    private func addElement() {
        let trimmed = newElementName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Determine next order index from current count (nil-safe)
        let nextIndex = (structure.elements ?? []).count

        let newElement = StructureElement(
            name: trimmed,
            orderIndex: nextIndex
        )
        // Establish inverse relationship and initialize array if needed
        newElement.storyStructure = structure
        if structure.elements == nil { structure.elements = [] }
        structure.elements?.append(newElement)
        newElementName = ""

        do {
            try modelContext.save()
        } catch {
            print("Failed to save new element: \(error)")
        }
    }
}

struct StructureElementRow: View {
    @Bindable var element: StructureElement
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 12) {
            // Order indicator
            Text("\(element.orderIndex + 1)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            // Color indicator
            Circle()
                .fill(element.displayColor)
                .frame(width: 12, height: 12)
                .glassEffect(GlassEffect.regular, in: Circle())

            // Element details
            VStack(alignment: .leading, spacing: 2) {
                TextField("Element name", text: $element.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .textFieldStyle(.plain)

                TextField("Description (optional)", text: $element.elementDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textFieldStyle(.plain)
            }

            Spacer()

            // Assigned cards count
            Text("\((element.assignedCards ?? []).count)")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.secondary.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassEffect(GlassEffect.regular, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal)
    }
}

// MARK: - Sheet Views

struct NewStructureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var structureName = ""
    @State private var elements: [String] = [""]

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                elementsSection
            }
            .navigationTitle("New Structure")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createStructure()
                    }
                    .disabled(structureName.isEmpty || elements.allSatisfy { $0.isEmpty })
                }
            }
        }
    }

    @ViewBuilder
    private var detailsSection: some View {
        Section("Structure Details") {
            TextField("Structure Name", text: $structureName)
                .font(.headline)
        }
    }

    @ViewBuilder
    private var elementsSection: some View {
        Section("Elements") {
            ForEach(elements.indices, id: \.self) { index in
                NewElementRow(
                    index: index,
                    text: Binding(
                        get: { elements[index] },
                        set: { elements[index] = $0 }
                    ),
                    canRemove: elements.count > 1,
                    onRemove: { elements.remove(at: index) }
                )
            }

            Button {
                elements.append("")
            } label: {
                Label("Add Element", systemImage: "plus.circle")
            }
            .buttonStyle(GlassButtonStyle())
        }
    }

    private func createStructure() {
        let structure = StoryStructure(name: structureName)

        let validElements = elements.filter { !$0.isEmpty }
        if structure.elements == nil { structure.elements = [] }
        for (index, elementName) in validElements.enumerated() {
            let element = StructureElement(name: elementName, orderIndex: index)
            element.storyStructure = structure
            structure.elements?.append(element)
        }

        modelContext.insert(structure)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save structure: \(error)")
        }
    }

    private struct NewElementRow: View {
        let index: Int
        @Binding var text: String
        let canRemove: Bool
        let onRemove: () -> Void

        var body: some View {
            HStack {
                TextField("Element \(index + 1)", text: $text)

                if canRemove {
                    Button(role: .destructive, action: onRemove) {
                        Label("Remove", systemImage: "minus.circle")
                            .labelStyle(.iconOnly)
                    }
                    .foregroundStyle(.red)
                    .help("Remove this element")
                }
            }
        }
    }
}

struct StructureTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                ForEach(StoryStructure.predefinedTemplates, id: \.name) { template in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.name)
                            .font(.headline)

                        Text(template.elements.joined(separator: " • "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        createFromTemplate(template)
                    }
                }
            }
            .navigationTitle("Structure Templates")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func createFromTemplate(_ template: (name: String, elements: [String])) {
        let structure = StoryStructure.createFromTemplate(template)
        modelContext.insert(structure)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save template structure: \(error)")
        }
    }
}

#Preview {
    StoryStructureView()
        .modelContainer(for: [StoryStructure.self, StructureElement.self, Card.self], inMemory: true)
}
