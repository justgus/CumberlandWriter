// FocusFullScreen.swift
import SwiftUI

#if os(iOS)

/// Simple full-screen editor used as a placeholder for iOS Focus mode.
/// Replace with your custom full-screen experience if desired.
struct FocusFullScreen<Toolbar: View>: View {
    @Binding var isPresented: Bool
    let title: String
    @Binding var detailsText: String
    @Binding var selection: NSRange
    let toolbar: Toolbar
    let onExit: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                // Toolbar area
                toolbar
                    .glassToolbarStyle()

                // Basic editor
                TextEditor(text: $detailsText)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onExit()
                        isPresented = false
                    } label: {
                        Label("Exit", systemImage: "xmark.circle.fill")
                    }
                }
            }
        }
    }
}

#endif
