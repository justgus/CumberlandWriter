//
//  CardEditorWindowView.swift
//  Cumberland
//
//  Created for visionOS Phase 2: Spatial Window Management
//
//  visionOS-only wrapper that opens CardEditorView in a separate floating
//  window via AppModel.CardEditorRequest, enabling side-by-side card editing
//  in the spatial computing environment.
//

#if os(visionOS)
import SwiftUI
import SwiftData

/// Wrapper view for card editor windows in visionOS
/// This allows card editors to open as separate floating windows
/// instead of modal sheets, enabling side-by-side editing workflows
struct CardEditorWindowView: View {
    
    let editorRequest: AppModel.CardEditorRequest
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext
    @Environment(AppModel.self) private var appModel
    
    // Query for the card if we're in edit mode
    @Query private var cards: [Card]
    
    private var card: Card? {
        switch editorRequest.mode {
        case .edit(let cardID):
            return cards.first { $0.id == cardID }
        case .create:
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch editorRequest.mode {
                case .create(let kind):
                    CardEditorView(mode: .create(kind: kind) { newCard in
                        // After creating, close this window and select the card in main view
                        dismiss()
                    })
                    
                case .edit( _):
                    if let card = card {
                        CardEditorView(mode: .edit(card: card) {
                            // After editing, just close this window
                            dismiss()
                        })
                    } else {
                        ContentUnavailableView(
                            "Card Not Found",
                            systemImage: "exclamationmark.triangle",
                            description: Text("This card may have been deleted.")
                        )
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 760, minHeight: 720)
        .glassBackgroundEffect()
    }
}

#endif
