//
//  CumberlandApp.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/1/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

@main
struct CumberlandApp: App {
    @State private var searchRouter = SearchRouter()
    @State private var selectionRouter = CardSelectionRouter()
    @State private var projectRouter = ProjectSelectionRouter()

    // Keep the container in state so we can replace it after a hard reset.
    @State private var modelContainer: ModelContainer

    init() {
        _modelContainer = State(initialValue: Self.buildContainerWithDestructiveFallback())
        // Seed default relation types and default settings after container creation
        Self.ensureDefaultRelationTypes(in: modelContainer)
        Self.ensureDefaultAppSettings(in: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(searchRouter)
                .environment(selectionRouter)
                .environment(projectRouter)
        }
        .modelContainer(modelContainer)
        .commands {
            // Custom Commands to open the SwiftUI About window by id
            AboutCommands()

            // Author insertion command bound to the focused author field in CardEditorView (macOS)
            #if os(macOS)
                AuthorCommands()
            #endif

            CommandGroup(after: .textEditing) {
                Button("Search…") {
                    searchRouter.open()
                }
                .keyboardShortcut("k", modifiers: .command)
            }

            CommandMenu("Developer") {
                #if os(macOS)
                Button("Relation Types") {
                    openDiagnosticsWindow(id: "relationTypesDiagnostics")
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .help("Show all relation types in the store")

                Button("Last 50 Edges") {
                    openDiagnosticsWindow(id: "recentEdgesDiagnostics")
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .help("Show the 50 most recently created edges")
                Divider()
                #endif

                Button(role: .destructive) {
                    wipeAllData()
                } label: {
                    Text("Reset All Data")
                }
                .keyboardShortcut(.delete, modifiers: [.command, .shift])
                .help("Deletes all Cards and their stored images from this device")

                Divider()

                Button(role: .destructive) {
                    destructiveResetStore()
                } label: {
                    Text("Hard Reset SwiftData Store")
                }
                .keyboardShortcut(.delete, modifiers: [.command, .option, .shift])
                .help("Deletes the on-disk SwiftData store files and recreates an empty store")
            }
        }

        // Custom About window scene (macOS)
        #if os(macOS)
        Window("About Cumberland", id: "about") {
            AboutView()
        }
        // Keep the window sized to its content; no toolbar for a clean About window
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
        #endif

        // Diagnostics windows (macOS)
        #if os(macOS)
        Window("Relation Types", id: "relationTypesDiagnostics") {
            RelationTypesDiagnosticsView()
                .frame(minWidth: 420, minHeight: 360)
        }
        .modelContainer(modelContainer)

        Window("Last 50 Edges", id: "recentEdgesDiagnostics") {
            RecentEdgesDiagnosticsView()
                .frame(minWidth: 560, minHeight: 420)
        }
        .modelContainer(modelContainer)
        #endif

        // macOS Settings window (appears under the app menu as “Settings…”)
        #if os(macOS)
        Settings {
            // Let SettingsView's NavigationSplitView be the root.
            SettingsView()
        }
        // Keep a non-centered, compact title bar
        .windowToolbarStyle(.unified)
        // Inject the same model container into the Settings scene
        .modelContainer(modelContainer)
        #endif
    }

    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    private func openDiagnosticsWindow(id: String) {
        openWindow(id: id)
    }
    #endif

    // MARK: - Store construction and destructive reset

    private static func appSupportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Cumberland", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func storeURL() -> URL {
        appSupportDirectory().appendingPathComponent("Cumberland.sqlite", conformingTo: .data)
    }

    private static func destroyStoreFiles(at sqliteURL: URL) {
        let fm = FileManager.default
        let base = sqliteURL.path
        let urls = [
            sqliteURL,
            URL(fileURLWithPath: base + "-wal"),
            URL(fileURLWithPath: base + "-shm")
        ]
        for u in urls {
            try? fm.removeItem(at: u)
        }
    }

    private static func buildContainerWithDestructiveFallback() -> ModelContainer {
        let schema = Schema(AppSchema.models)
        let url = storeURL()
        let configuration = ModelConfiguration(url: url)

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: AppMigrations.self,
                configurations: [configuration]
            )
        } catch {
            print("ModelContainer init failed (\(error)). Performing destructive reset of SwiftData store.")
            destroyStoreFiles(at: url)
            do {
                return try ModelContainer(
                    for: schema,
                    migrationPlan: AppMigrations.self,
                    configurations: [configuration]
                )
            } catch {
                fatalError("Could not create ModelContainer even after destructive reset: \(error)")
            }
        }
    }

    // Seed both "references" and "cites" relation types
    private static func ensureDefaultRelationTypes(in container: ModelContainer) {
        let context = ModelContext(container)
        context.autosaveEnabled = false

        // Upsert helper with optional source/target kind constraints.
        func ensureType(code: String, forward: String, inverse: String, sourceKind: Kinds? = nil, targetKind: Kinds? = nil) {
            let fetch = FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == code })
            if let existing = try? context.fetch(fetch), let t = existing.first {
                // If "cites" was previously seeded as Any→Any, correct it to Sources→Any.
                if code == "cites" {
                    let desiredSource = sourceKind?.rawValue
                    let desiredTarget = targetKind?.rawValue // nil for Any
                    if t.sourceKindRaw != desiredSource || t.targetKindRaw != desiredTarget {
                        t.sourceKindRaw = desiredSource
                        t.targetKindRaw = desiredTarget
                    }
                }
                return
            }
            let def = RelationType(code: code,
                                   forwardLabel: forward,
                                   inverseLabel: inverse,
                                   sourceKind: sourceKind,
                                   targetKind: targetKind)
            context.insert(def)
        }

        // "references" remains global (Any → Any)
        ensureType(code: "references", forward: "references", inverse: "referenced by", sourceKind: nil, targetKind: nil)
        // "cites" must be constrained to Sources → Any (Option A)
        ensureType(code: "cites", forward: "cites", inverse: "cited by", sourceKind: .sources, targetKind: nil)

        try? context.save()
    }

    // Ensure the singleton AppSettings row exists with default values
    private static func ensureDefaultAppSettings(in container: ModelContainer) {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let fetch = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.singletonKey == "AppSettingsSingleton" }
        )
        if let existing = try? context.fetch(fetch), existing.first != nil {
            return
        }
        let defaults = AppSettings() // uses your default values
        context.insert(defaults)
        try? context.save()
    }

    // Deletes the on-disk store and rebuilds a fresh container, then re-injects it.
    private func destructiveResetStore() {
        Card.purgeAllImageCaches()

        let url = Self.storeURL()
        Self.destroyStoreFiles(at: url)

        let fresh = Self.buildContainerWithDestructiveFallback()
        Self.ensureDefaultRelationTypes(in: fresh)
        Self.ensureDefaultAppSettings(in: fresh)
        modelContainer = fresh

        selectionRouter.clear()
        projectRouter.clear()
        print("SwiftData store hard reset complete.")
    }

    // MARK: - Logical data reset (keeps store but deletes all rows)

    @MainActor
    private func wipeAllData() {
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        do {
            // Delete citations and sources first (if present)
            if let citations = try? context.fetch(FetchDescriptor<Citation>()) {
                for c in citations { context.delete(c) }
            }
            if let sources = try? context.fetch(FetchDescriptor<Source>()) {
                for s in sources { context.delete(s) }
            }

            let allCards = try context.fetch(FetchDescriptor<Card>())
            let allEdges = try context.fetch(FetchDescriptor<CardEdge>())
            for edge in allEdges {
                context.delete(edge)
            }
            for card in allCards {
                card.cleanupBeforeDeletion()
                context.delete(card)
            }
            try context.save()
            Card.purgeAllImageCaches()
            selectionRouter.clear()
            projectRouter.clear()
        } catch {
            print("Failed to wipe data: \(error)")
        }
    }
}

// MARK: - Commands

private struct AboutCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About Cumberland") {
                openWindow(id: "about")
            }
        }
    }
}

#if os(macOS)
private struct AuthorCommands: Commands {
    // This pulls the action exposed by CardEditorView when the Author field is focused.
    @FocusedValue(\.insertDefaultAuthor) private var insertDefaultAuthor: (() -> Void)?

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Button("Insert Default Author") {
                insertDefaultAuthor?()
            }
            .keyboardShortcut(KeyEquivalent("A"), modifiers: [.command, .shift])
            .disabled(insertDefaultAuthor == nil)
        }
    }
}
#endif

