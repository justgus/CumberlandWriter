//
//  EdgeLabelSheet.swift
//  MurderboardApp
//
//  Sheet for entering a label when creating an edge.
//

import SwiftUI

struct EdgeLabelSheet: View {
    let onConfirm: (String) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var label: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connection Label")
                .font(.title3.bold())

            Text("Describe how these nodes are related.")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("e.g. \"knows\", \"witnessed\", \"owns\"", text: $label)
                .textFieldStyle(.roundedBorder)

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Connect") {
                    onConfirm(label)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(minWidth: 300, minHeight: 180)
    }
}
