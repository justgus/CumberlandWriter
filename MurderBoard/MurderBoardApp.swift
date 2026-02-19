//
//  MurderboardApp.swift
//  MurderboardApp
//
//  Standalone investigation board app powered by BoardEngine.
//  Uses SwiftData for persistence and BoardEngine for the
//  visual canvas, gestures, and layout system.
//

import SwiftUI
import SwiftData

@main
struct MurderboardApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            InvestigationBoard.self,
            InvestigationNode.self,
            InvestigationEdge.self,
        ])
        let config = ModelConfiguration("MurderboardStore", isStoredInMemoryOnly: false)
        container = try! ModelContainer(for: schema, configurations: [config])
    }

    var body: some Scene {
        WindowGroup {
            MurderBoardRootView()
        }
        .modelContainer(container)
    }
}
