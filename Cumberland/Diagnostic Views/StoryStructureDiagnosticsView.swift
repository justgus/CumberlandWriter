//
//  StoryStructureDiagnosticsView.swift
//  Cumberland
//
//  Developer diagnostic view listing all StructureElement records across all
//  StoryStructures, showing parent structure name, element name, sort order,
//  and count of assigned cards. Useful for verifying story-structure data
//  integrity. Accessed from DeveloperToolsView.
//

import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

// Developer diagnostics: list all StructureElements across all StoryStructures.
struct StoryStructureDiagnosticsView: View {
    @Environment(\.modelContext) private var modelContext

    // Fetch all elements; we’ll sort/filter in-memory for flexibility across relationships.
    @Query private var elements: [StructureElement]
    @Query private var structures: [StoryStructure]

    @State private var searchText: String = ""
    @State private var sortMode: SortMode = .structureThenOrder

    enum SortMode: String, CaseIterable, Identifiable {
        case structureThenOrder = "Structure • Order"
        case name = "Name"
        case orderOnly = "Order Only"

        var id: String { rawValue }
    }

    private var structureNameByID: [PersistentIdentifier: String] {
        var dict: [PersistentIdentifier: String] = [:]
        for s in structures {
            dict[s.persistentModelID] = s.name
        }
        return dict
    }

    private func structureName(for element: StructureElement) -> String {
        if let s = element.storyStructure {
            return s.name
        }
        // Fallback by ID map in case of faulting
        if let id = element.storyStructure?.persistentModelID,
           let name = structureNameByID[id] {
            return name
        }
        return "—"
    }

    private var filtered: [StructureElement] {
        let base = elements
        let searched: [StructureElement]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searched = base
        } else {
            let needle = searchText.lowercased()
            searched = base.filter { e in
                let sName = structureName(for: e).lowercased()
                return e.name.lowercased().contains(needle)
                    || (e.elementDescription.lowercased().contains(needle))
                    || sName.contains(needle)
            }
        }

        switch sortMode {
        case .structureThenOrder:
            return searched.sorted {
                let lhsS = structureName(for: $0)
                let rhsS = structureName(for: $1)
                if lhsS == rhsS {
                    return $0.orderIndex < $1.orderIndex
                }
                return lhsS.localizedCaseInsensitiveCompare(rhsS) == .orderedAscending
            }
        case .name:
            return searched.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .orderOnly:
            return searched.sorted { $0.orderIndex < $1.orderIndex }
        }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Story Structure (Live)")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Picker("Sort", selection: $sortMode) {
                            ForEach(SortMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
        }
        .searchable(text: $searchText, placement: .automatic, prompt: "Search elements or structures")
    }

    private var content: some View {
        Group {
            if elements.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.number")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Story Structure Elements")
                        .font(.title2.bold())
                    Text("Create structures and elements, then return to see them listed here.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    // Render header as a normal row to avoid macOS Section diffing crashes.
                    headerRow
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)

                    ForEach(filtered, id: \.persistentModelID) { element in
                        row(for: element)
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Text("Structure").font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text("Element").font(.caption).foregroundStyle(.secondary).frame(width: 220, alignment: .leading)
            Text("Order").font(.caption).foregroundStyle(.secondary).frame(width: 50, alignment: .trailing)
            Text("Assigned").font(.caption).foregroundStyle(.secondary).frame(width: 70, alignment: .trailing)
        }
        .textCase(nil)
    }

    private func row(for element: StructureElement) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(structureName(for: element))
                .font(.body)
                .lineLimit(1)

            Spacer()

            Text(element.name.isEmpty ? "—" : element.name)
                .font(.body)
                .lineLimit(2)
                .frame(width: 220, alignment: .leading)

            Text("\(element.orderIndex)")
                .font(.body.monospacedDigit())
                .frame(width: 50, alignment: .trailing)

            let assignedCount = (element.assignedCards ?? []).count
            Text("\(assignedCount)")
                .font(.body.monospacedDigit())
                .frame(width: 70, alignment: .trailing)
        }
        .contextMenu {
            #if os(macOS)
            if let s = element.storyStructure {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(s.name, forType: .string)
                } label: {
                    Label("Copy Structure Name", systemImage: "doc.on.doc")
                }
            }
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(element.name, forType: .string)
            } label: {
                Label("Copy Element Name", systemImage: "doc.on.doc")
            }
            #else
            // Non-macOS: omit clipboard actions in diagnostics
            EmptyView()
            #endif
        }
    }
}

#Preview("Story Structure Diagnostics – Empty") {
    StoryStructureDiagnosticsView()
        .modelContainer(for: [StoryStructure.self, StructureElement.self, Card.self], inMemory: true)
}

#Preview("Story Structure Diagnostics – Sample") {
    StoryStructureDiagnosticsView()
        .modelContainer(sampleStoryStructureContainer)
}

// MARK: - Preview helpers

private let sampleStoryStructureContainer: ModelContainer = {
    let container = try! ModelContainer(
        for: StoryStructure.self,
        StructureElement.self,
        Card.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext

    let s1 = StoryStructure(name: "Three-Act")
    let s2 = StoryStructure(name: "Hero’s Journey")
    let e1 = StructureElement(name: "Act I", elementDescription: "", orderIndex: 0); e1.storyStructure = s1
    let e2 = StructureElement(name: "Act II", elementDescription: "", orderIndex: 1); e2.storyStructure = s1
    let e3 = StructureElement(name: "Act III", elementDescription: "", orderIndex: 2); e3.storyStructure = s1
    let e4 = StructureElement(name: "Call to Adventure", elementDescription: "", orderIndex: 0); e4.storyStructure = s2
    let e5 = StructureElement(name: "Refusal of the Call", elementDescription: "", orderIndex: 1); e5.storyStructure = s2

    [s1, s2].forEach { ctx.insert($0) }
    [e1, e2, e3, e4, e5].forEach { ctx.insert($0) }

    try? ctx.save()
    return container
}()
