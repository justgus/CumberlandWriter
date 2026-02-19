//
//  NodeEditorSheet.swift
//  MurderboardApp
//
//  Sheet for creating a new investigation node.
//

import SwiftUI

struct NodeEditorSheet: View {
    let onCreate: (String, String, NodeCategory) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var subtitle: String = ""
    @State private var selectedCategory: NodeCategory = .person

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Node")
                .font(.title3.bold())

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)

            TextField("Subtitle (optional)", text: $subtitle)
                .textFieldStyle(.roundedBorder)

            Picker("Category", selection: $selectedCategory) {
                ForEach(NodeCategory.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.systemImage)
                        .tag(category)
                }
            }
            .pickerStyle(.menu)

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create") {
                    guard !name.isEmpty else { return }
                    onCreate(name, subtitle, selectedCategory)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 300, minHeight: 250)
    }
}
