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
    @Query private var structures: [StoryStructure]
    
    @State private var selectedStructure: StoryStructure?
    @State private var showingNewStructureSheet = false
    @State private var showingTemplateSheet = false
    
    var body: some View {
        NavigationSplitView {
            // Structure list
            List(selection: $selectedStructure) {
                Section("Your Structures") {
                    ForEach(structures) { structure in
                        NavigationLink(value: structure) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(structure.name)
                                    .font(.headline)
                                
                                Text("\((structure.elements ?? []).count) elements")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
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
            .navigationTitle("Story Structures")
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
        } detail: {
            if let structure = selectedStructure {
                StructureDetailView(structure: structure)
            } else {
                ContentPlaceholderView(
                    title: "Select a Structure",
                    subtitle: "Choose a story structure to view and edit its elements.",
                    systemImage: "list.number"
                )
            }
        }
        .sheet(isPresented: $showingNewStructureSheet) {
            NewStructureSheet()
        }
        .sheet(isPresented: $showingTemplateSheet) {
            StructureTemplateSheet()
        }
    }
    
    private func deleteStructures(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(structures[index])
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
        .modelContainer(for: [StoryStructure.self, StructureElement.self], inMemory: true)
}
