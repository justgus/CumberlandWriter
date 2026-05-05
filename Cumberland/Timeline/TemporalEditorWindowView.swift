//
//  TemporalEditorWindowView.swift
//  Cumberland
//
//  Created on 2026-01-29.
//  DR-0061: Window wrapper for SceneTemporalPositionEditor on macOS
//
//  macOS-only window wrapper that hosts SceneTemporalPositionEditor in a
//  separate NSWindow/scene opened via openWindow environment action. Resolves
//  the scene, timeline, and connecting CardEdge from model context by ID.
//

#if os(macOS)
import SwiftUI
import SwiftData

/// Notification posted when temporal editor window closes
extension Notification.Name {
    static let temporalEditorDidClose = Notification.Name("TemporalEditorDidClose")
}

/// Window wrapper for SceneTemporalPositionEditor on macOS
/// This resolves DR-0061 by using a proper window instead of a buggy sheet presentation
@available(macOS 26.0, *)
struct TemporalEditorWindowView: View {
    let editorRequest: AppModel.TemporalEditorRequest

    @Environment(\.modelContext) private var modelContext
    @Environment(\.services) private var services
    @Environment(\.dismiss) private var dismiss

    @State private var scene: Card?
    @State private var timeline: Card?
    @State private var edge: CardEdge?

    var body: some View {
        Group {
            if let scene, let timeline, let edge {
                SceneTemporalPositionEditor(
                    scene: scene,
                    timeline: timeline,
                    edge: edge
                )
                .frame(minWidth: 560, minHeight: 640)
            } else {
                ProgressView("Loading temporal editor...")
                    .frame(minWidth: 560, minHeight: 640)
            }
        }
        .task {
            await loadEntities()
        }
        .onDisappear {
            // Notify timeline view to reload data
            print("🪟 [TemporalEditorWindowView] Window closing, posting notification")
            NotificationCenter.default.post(name: .temporalEditorDidClose, object: nil)
        }
    }

    @MainActor
    private func loadEntities() async {
        print("🪟 [TemporalEditorWindowView] === LOADING ENTITIES ===")
        print("🪟 [TemporalEditorWindowView] SceneID: \(editorRequest.sceneID)")
        print("🪟 [TemporalEditorWindowView] TimelineID: \(editorRequest.timelineID)")
        print("🪟 [TemporalEditorWindowView] ModelContext: \(modelContext)")

        guard let cardRepo = services?.cardRepository,
              let edgeRepo = services?.edgeRepository else {
            print("🪟 [TemporalEditorWindowView] ⚠️ Repositories not available in ServiceContainer")
            return
        }

        // Fetch scene using CardRepository
        scene = cardRepo.fetch(byUUID: editorRequest.sceneID)
        print("🪟 [TemporalEditorWindowView] Scene fetched: \(scene?.name ?? "nil")")

        // Fetch timeline using CardRepository
        timeline = cardRepo.fetch(byUUID: editorRequest.timelineID)
        print("🪟 [TemporalEditorWindowView] Timeline fetched: \(timeline?.name ?? "nil")")

        // Fetch edge using EdgeRepository
        if let sceneCard = scene, let timelineCard = timeline {
            // Fetch all outgoing edges from scene and find the one pointing to this timeline
            let edges = edgeRepo.fetchOutgoing(from: sceneCard)
            edge = edges.first { $0.to?.id == timelineCard.id }

            if let edge = edge {
                print("🪟 [TemporalEditorWindowView] Edge found:")
                print("   - temporalPosition: \(edge.temporalPosition?.description ?? "nil")")
                print("   - duration: \(edge.duration?.description ?? "nil")")
                print("   - context: \(edge.modelContext != nil ? "has context" : "NO CONTEXT")")
            } else {
                print("🪟 [TemporalEditorWindowView] ⚠️ Edge NOT found")
            }
        } else {
            print("🪟 [TemporalEditorWindowView] ⚠️ Cannot fetch edge - missing scene or timeline")
        }

        print("🪟 [TemporalEditorWindowView] === LOADING COMPLETE ===")
    }
}
#endif
