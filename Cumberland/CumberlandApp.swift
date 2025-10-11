//
//  CumberlandApp.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/10/25.
//

import SwiftUI
import SwiftData
import OSLog

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@main
struct CumberlandApp: App {

    @State private var appModel = AppModel()

    // Persisted appearance preference (mirrors AppSettings.colorSchemePreferenceRaw)
    @AppStorage("AppSettings.colorSchemePreferenceRaw")
    private var colorSchemeRaw: String = ColorSchemePreference.system.rawValue

    // Build the app's SwiftData container using your schema.
    // If opening the on-disk store fails, we fall back to local on-disk, then in-memory.
    private static func makeContainer() -> ModelContainer {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "SwiftData")

        // Construct a Schema from the current model list. This avoids the migration-plan overload entirely.
        let schema = Schema(AppSchema.models)

        // 1) Try CloudKit-backed configuration first.
        do {
            let cloudConfig = ModelConfiguration("iCloud.CumberlandCloud")
            let container = try ModelContainer(
                for: schema,
                configurations: [cloudConfig]
            )
            logger.info("SwiftData ModelContainer initialized with CloudKit.")
            return container
        } catch {
            logger.error("CloudKit ModelContainer initialization failed: \(String(describing: error))")
        }

        // 2) Fall back to a local on-disk store (no CloudKit).
        do {
            let localConfig = ModelConfiguration() // default on-disk location
            let container = try ModelContainer(
                for: schema,
                configurations: [localConfig]
            )
            logger.warning("Using local on-disk SwiftData store (CloudKit unavailable).")
            return container
        } catch {
            logger.error("Local on-disk ModelContainer initialization failed: \(String(describing: error))")
        }

        // 3) Last resort: in-memory store so the app remains usable during development.
        do {
            let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(
                for: schema,
                configurations: [memoryConfig]
            )
            logger.warning("Using in-memory SwiftData store as a fallback.")
            return container
        } catch {
            fatalError("SwiftData in-memory fallback failed to initialize: \(error)")
        }
    }

    @State private var modelContainer: ModelContainer = makeContainer()

    // Map persisted raw value to ColorScheme for app-wide application
    private var appPreferredColorScheme: ColorScheme? {
        ColorSchemePreference(rawValue: colorSchemeRaw)?.resolvedColorScheme
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .modelContainer(modelContainer)
                .preferredColorScheme(appPreferredColorScheme)
                // Keep the window’s toolbar translucent
                #if os(macOS)
                .toolbarBackground(.ultraThinMaterial, for: .windowToolbar)
                .toolbarBackground(.visible, for: .windowToolbar)
                #endif
                // Seed relation types once the container is available
                .task {
                    await CumberlandApp.seedRelationTypesIfNeeded(container: modelContainer)
                }
        }
        #if os(macOS)
        .commands {
            AboutCommands()
            #if DEBUG
            DeveloperCommands()
            #endif
        }
        #endif

        #if os(visionOS)
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .preferredColorScheme(appPreferredColorScheme)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        #endif

        #if os(macOS)
        // Dedicated Settings scene for macOS
        Settings {
            SettingsView()
                .modelContainer(modelContainer)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 520, minHeight: 380)
        }

        // About window scene for macOS
        Window("About Cumberland", id: "about") {
            AboutView()
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 420, minHeight: 260)
        }
        .windowResizability(.contentSize)

        // Developer diagnostic windows (DEBUG only, some use in-memory samples, some live)
        #if DEBUG
        // Existing sample-backed diagnostics
        Window("Diagnostics: Swimlane Viewer", id: "dev.swimlane") {
            DevSwimlaneWindow()
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 960, minHeight: 560)
        }

        Window("Diagnostics: Card Relationship", id: "dev.cardRelationship") {
            DevCardRelationshipWindow()
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 880, minHeight: 560)
        }

        Window("Diagnostics: Card Sheet", id: "dev.cardSheet") {
            DevCardSheetWindow()
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 720, minHeight: 560)
        }

        Window("Diagnostics: Card Editor", id: "dev.cardEditor") {
            DevCardEditorWindow()
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 720, minHeight: 560)
        }

        Window("Diagnostics: Image Attribution", id: "dev.imageAttribution") {
            DevImageAttributionWindow()
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 560, minHeight: 460)
        }

        // New diagnostics that use the live ModelContainer
        Window("Diagnostics: Recent Edges", id: "dev.recentEdges") {
            RecentEdgesDiagnosticsView()
                .modelContainer(modelContainer) // live container
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 720, minHeight: 520)
        }

        Window("Diagnostics: Relation Types", id: "dev.relationTypes") {
            RelationTypesDiagnosticsView()
                .modelContainer(modelContainer) // live container
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 720, minHeight: 520)
        }

        // New: Story Structure diagnostics (live container)
        Window("Diagnostics: Story Structure", id: "dev.storyStructure") {
            StoryStructureDiagnosticsView()
                .modelContainer(modelContainer) // live container
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 720, minHeight: 520)
        }
        #endif
        #endif
     }
}

private extension CumberlandApp {
    struct SeedDescriptor: Hashable {
        let code: String
        let forward: String
        let inverse: String
        let source: Kinds?
        let target: Kinds?
    }

    // Canonical, idempotent seed set. Codes are stable and human labels are user-facing.
    static var relationTypeSeeds: [SeedDescriptor] {
        [
            // Global (Any → Any)
            .init(code: "references", forward: "references", inverse: "referenced by", source: nil, target: nil),
            .init(code: "related-to/related-to", forward: "related to", inverse: "related to", source: nil, target: nil),
            .init(code: "same-as/same-as", forward: "same as", inverse: "same as", source: nil, target: nil),
            .init(code: "includes/part-of", forward: "includes", inverse: "part of", source: nil, target: nil),
            .init(code: "depends-on/required-by", forward: "depends on", inverse: "required by", source: nil, target: nil),
            .init(code: "precedes/follows", forward: "precedes", inverse: "follows", source: nil, target: nil),
            .init(code: "uses/used-by", forward: "uses", inverse: "used by", source: nil, target: nil),
            .init(code: "inspired-by/inspires", forward: "inspired by", inverse: "inspires", source: nil, target: nil),
            .init(code: "derived-from/basis-for", forward: "derived from", inverse: "basis for", source: nil, target: nil),

            // Scoped (specific Kinds)

            // Bibliographic: Sources → Any
            .init(code: "cites", forward: "cites", inverse: "cited by", source: .sources, target: nil),

            // Characters ↔ Scenes
            .init(code: "appears-in/is-appeared-by", forward: "appears in", inverse: "is appeared by", source: .characters, target: .scenes),

            // Scenes ↔ Worlds
            .init(code: "set-in/contains-scene", forward: "set in", inverse: "contains scene", source: .scenes, target: .worlds),

            // Scenes ↔ Chapters (compose)
            .init(code: "part-of/has-scene", forward: "part of", inverse: "has scene", source: .scenes, target: .chapters),

            // Scenes ↔ Timelines
            .init(code: "describes/described-by", forward: "describes", inverse: "described by", source: .scenes, target: .timelines),

            // Projects ↔ Worlds (setting)
            .init(code: "set-in/setting-for", forward: "set in", inverse: "setting for", source: .projects, target: .worlds),

            // Worlds ↔ Rules (application)
            .init(code: "applies/applied-to", forward: "applies", inverse: "applied to", source: .worlds, target: .rules),

            // Locations ↔ Maps
            .init(code: "appears-on/shows", forward: "appears on", inverse: "shows", source: .locations, target: .maps),

            // Locations ↔ Worlds
            .init(code: "located-in/contains", forward: "located in", inverse: "contains", source: .locations, target: .worlds),

            // Buildings ↔ Locations
            .init(code: "housed-in/contains-building", forward: "housed in", inverse: "contains building", source: .buildings, target: .locations),

            // Characters ↔ Vehicles
            .init(code: "pilots/piloted-by", forward: "pilots", inverse: "piloted by", source: .characters, target: .vehicles),

            // Characters ↔ Artifacts
            .init(code: "owns/owned-by", forward: "owns", inverse: "owned by", source: .characters, target: .artifacts),

            // Projects hierarchy
            .init(code: "parent-of/child-of", forward: "parent of", inverse: "child of", source: .projects, target: .projects),

            // Chapters ↔ Projects (compose)
            .init(code: "part-of/has-member", forward: "part of", inverse: "has member", source: .chapters, target: .projects),

            // Maps ↔ Worlds
            .init(code: "maps/mapped-by", forward: "maps", inverse: "mapped by", source: .maps, target: .worlds),

            // Characters ↔ Characters (relationships inside cast)
            .init(code: "allies-with/allies-with", forward: "allies with", inverse: "allies with", source: .characters, target: .characters),
            .init(code: "conflicts-with/conflicts-with", forward: "conflicts with", inverse: "conflicts with", source: .characters, target: .characters),
            .init(code: "knows/known-by", forward: "knows", inverse: "known by", source: .characters, target: .characters),
            .init(code: "mentors/mentored-by", forward: "mentors", inverse: "mentored by", source: .characters, target: .characters),
            .init(code: "parent-of/child-of.characters", forward: "parent of", inverse: "child of", source: .characters, target: .characters),
            .init(code: "sibling-of/sibling-of", forward: "sibling of", inverse: "sibling of", source: .characters, target: .characters),
            .init(code: "married-to/married-to", forward: "married to", inverse: "married to", source: .characters, target: .characters),
            .init(code: "rivals-with/rivals-with", forward: "rivals with", inverse: "rivals with", source: .characters, target: .characters),
            .init(code: "works-with/works-with", forward: "works with", inverse: "works with", source: .characters, target: .characters)
        ]
    }

    @MainActor
    static func seedRelationTypesIfNeeded(container: ModelContainer) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "Seeding")
        let context = container.mainContext
        context.autosaveEnabled = true

        // Fetch existing codes once (SwiftData: no propertiesToFetch API)
        let fetch = FetchDescriptor<RelationType>()
        let existing = (try? context.fetch(fetch)) ?? []
        var existingCodes = Set(existing.map { $0.code })

        var insertedCount = 0
        for s in relationTypeSeeds {
            if existingCodes.contains(s.code) {
                continue
            }
            let t = RelationType(
                code: s.code,
                forwardLabel: s.forward,
                inverseLabel: s.inverse,
                sourceKind: s.source,
                targetKind: s.target
            )
            context.insert(t)
            existingCodes.insert(s.code)
            insertedCount += 1
        }

        if insertedCount > 0 {
            do {
                try context.save()
                logger.info("Seeded \(insertedCount) RelationType(s).")
            } catch {
                logger.error("Failed to save seeded RelationTypes: \(String(describing: error))")
            }
        } else {
            logger.debug("RelationType seeding skipped; all seeds already present.")
        }
    }
}

#if os(macOS)
import AppKit

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

#if DEBUG
private struct DeveloperCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandMenu("Developer") {
            // Existing diagnostics
            Button("Swimlane Viewer") {
                openWindow(id: "dev.swimlane")
            }
            .keyboardShortcut("1", modifiers: [.command, .shift])

            Button("Card Relationship") {
                openWindow(id: "dev.cardRelationship")
            }
            .keyboardShortcut("2", modifiers: [.command, .shift])

            Button("Card Sheet") {
                openWindow(id: "dev.cardSheet")
            }
            .keyboardShortcut("3", modifiers: [.command, .shift])

            Button("Card Editor") {
                openWindow(id: "dev.cardEditor")
            }
            .keyboardShortcut("4", modifiers: [.command, .shift])

            Button("Image Attribution") {
                openWindow(id: "dev.imageAttribution")
            }
            .keyboardShortcut("5", modifiers: [.command, .shift])

            Divider()

            // New live-container diagnostics
            Button("Cards (Live)") {
                openWindow(id: "dev.cards")
            }
            .keyboardShortcut("6", modifiers: [.command, .shift])

            Button("Recent Edges (Live)") {
                openWindow(id: "dev.recentEdges")
            }
            .keyboardShortcut("7", modifiers: [.command, .shift])

            Button("Relation Types (Live)") {
                openWindow(id: "dev.relationTypes")
            }
            .keyboardShortcut("8", modifiers: [.command, .shift])

            Button("Story Structure (Live)") {
                openWindow(id: "dev.storyStructure")
            }
            .keyboardShortcut("9", modifiers: [.command, .shift])
        }
    }
}
#endif

// MARK: - Diagnostic Window Content (DEBUG-only wrappers for sample-backed tools)

#if DEBUG
import Combine

// Shared helper: build an in-memory ModelContainer for a schema list.
private func makeInMemoryContainer(_ types: [any PersistentModel.Type]) -> ModelContainer {
    let schema = Schema(types)
    let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [cfg])
}

// MARK: Swimlane Viewer

private struct DevSwimlaneWindow: View {
    var body: some View {
        let container = makeInMemoryContainer([Card.self, RelationType.self, CardEdge.self])
        return DevSwimlaneContent()
            .modelContainer(container)
            .padding()
            .background(Color.clear)
    }
}

private struct DevSwimlaneContent: View {
    @Environment(\.modelContext) private var ctx

    @State private var lanes: [SwimlaneViewer.LaneDescriptor] = []

    var body: some View {
        Group {
            if lanes.isEmpty {
                ProgressView("Seeding sample data…")
                    .task { await seed() }
            } else {
                SwimlaneViewer(laneDescriptors: lanes, relationTypeFilter: nil, laneWidth: 420, laneSpacing: 16, contentPadding: 16, showsIndicators: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @MainActor
    private func seed() async {
        let relType = RelationType(code: "references", forwardLabel: "references", inverseLabel: "referenced by")
        ctx.insert(relType)

        // Masters
        let masterA = Card(kind: .projects, name: "Project Alpha", subtitle: "Root A", detailedText: "Alpha master", sizeCategory: .standard)
        let masterB = Card(kind: .projects, name: "Project Beta", subtitle: "Root B", detailedText: "Beta master", sizeCategory: .standard)
        let masterC = Card(kind: .projects, name: "Project Gamma", subtitle: "Root C", detailedText: "Gamma master", sizeCategory: .standard)
        [masterA, masterB, masterC].forEach { ctx.insert($0) }

        func lorem(_ n: Int) -> String {
            let base = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
            return (1...n).map { "\($0). \(base)" }.joined(separator: "\n")
        }
        let longText = lorem(20)

        // Related for A
        let a1 = Card(kind: .characters, name: "Mira", subtitle: "Scout", detailedText: longText, sizeCategory: .compact)
        let a2 = Card(kind: .vehicles, name: "Skiff", subtitle: "Courier", detailedText: longText, sizeCategory: .standard)
        let a3 = Card(kind: .scenes, name: "Market", subtitle: "Evening bustle", detailedText: longText, sizeCategory: .large)
        [a1, a2, a3].forEach { ctx.insert($0) }
        [CardEdge(from: a1, to: masterA, type: relType, createdAt: Date(), sortIndex: 1),
         CardEdge(from: a2, to: masterA, type: relType, createdAt: Date(), sortIndex: 2),
         CardEdge(from: a3, to: masterA, type: relType, createdAt: Date(), sortIndex: 3)
        ].forEach { ctx.insert($0) }

        // Related for B
        let b1 = Card(kind: .characters, name: "Aiden", subtitle: "Pilot", detailedText: longText, sizeCategory: .standard)
        let b2 = Card(kind: .worlds, name: "Aether", subtitle: "Geography", detailedText: longText, sizeCategory: .compact)
        [b1, b2].forEach { ctx.insert($0) }
        [CardEdge(from: b1, to: masterB, type: relType, createdAt: Date(), sortIndex: 1),
         CardEdge(from: b2, to: masterB, type: relType, createdAt: Date(), sortIndex: 2)
        ].forEach { ctx.insert($0) }

        // Related for C
        let g1 = Card(kind: .scenes, name: "Docks", subtitle: "Foggy morning", detailedText: longText, sizeCategory: .standard)
        let g2 = Card(kind: .vehicles, name: "Hauler", subtitle: "Freight", detailedText: longText, sizeCategory: .compact)
        let g3 = Card(kind: .characters, name: "Rhea", subtitle: "Mechanic", detailedText: longText, sizeCategory: .large)
        let g4 = Card(kind: .worlds, name: "Nox", subtitle: "Nightside colony", detailedText: longText, sizeCategory: .standard)
        [g1, g2, g3, g4].forEach { ctx.insert($0) }
        [CardEdge(from: g1, to: masterC, type: relType, createdAt: Date(), sortIndex: 1),
         CardEdge(from: g2, to: masterC, type: relType, createdAt: Date(), sortIndex: 2),
         CardEdge(from: g3, to: masterC, type: relType, createdAt: Date(), sortIndex: 3),
         CardEdge(from: g4, to: masterC, type: relType, createdAt: Date(), sortIndex: 4)
        ].forEach { ctx.insert($0) }

        try? ctx.save()

        lanes = [
            .init(master: masterA, direction: .topToBottom, showsHeader: true),
            .init(master: masterB, direction: .bottomToTop, showsHeader: true),
            .init(master: masterC, direction: .topToBottom, showsHeader: true)
        ]
    }
}

// MARK: Card Relationship

private struct DevCardRelationshipWindow: View {
    var body: some View {
        let container = makeInMemoryContainer([Card.self, RelationType.self, CardEdge.self])
        return DevCardRelationshipContent()
            .modelContainer(container)
            .padding()
    }
}

private struct DevCardRelationshipContent: View {
    @Environment(\.modelContext) private var ctx
    @State private var primary: Card?

    var body: some View {
        Group {
            if let primary {
                CardRelationshipView(primary: primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView("Seeding sample data…")
                    .task { await seed() }
            }
        }
    }

    @MainActor
    private func seed() async {
        let references = RelationType(code: "references", forwardLabel: "references", inverseLabel: "referenced by")
        ctx.insert(references)

        let project = Card(kind: .projects, name: "Exploration Project", subtitle: "Initial Planning", detailedText: "Primary project.", sizeCategory: .standard)
        ctx.insert(project)

        let char1 = Card(kind: .characters, name: "Ada", subtitle: "Analyst", detailedText: "Curious and meticulous.", sizeCategory: .standard)
        let char2 = Card(kind: .characters, name: "Rhea", subtitle: "Mechanic", detailedText: "Pragmatic and resourceful.", sizeCategory: .standard)
        [char1, char2].forEach { ctx.insert($0) }

        [CardEdge(from: char1, to: project, type: references, createdAt: Date(), sortIndex: 1),
         CardEdge(from: char2, to: project, type: references, createdAt: Date(), sortIndex: 2)
        ].forEach { ctx.insert($0) }

        try? ctx.save()
        primary = project
    }
}

// MARK: Card Sheet

private struct DevCardSheetWindow: View {
    var body: some View {
        let container = makeInMemoryContainer([Card.self])
        return DevCardSheetContent()
            .modelContainer(container)
            .padding()
    }
}

private struct DevCardSheetContent: View {
    @Environment(\.modelContext) private var ctx
    @State private var card: Card?

    var body: some View {
        Group {
            if let card {
                NavigationStack {
                    CardSheetView(card: card)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView("Seeding sample card…")
                    .task { await seed() }
            }
        }
    }

    @MainActor
    private func seed() async {
        let c = Card(
            kind: .projects,
            name: "Exploration Project",
            subtitle: "Initial Planning",
            detailedText: """
            # Overview

            This supports **Markdown**, including:
            - Bullet lists
            - Links: [Apple](https://apple.com)
            - Inline code: `let x = 1`
            - [ ] Checklist item
            - [x] Done item
            """,
            author: "M. S.",
            sizeCategory: .standard
        )
        ctx.insert(c)
        try? ctx.save()
        card = c
    }
}

// MARK: Card Editor

private struct DevCardEditorWindow: View {
    var body: some View {
        let container = makeInMemoryContainer([Card.self, AppSettings.self])
        return DevCardEditorContent()
            .modelContainer(container)
            .padding()
    }
}

private struct DevCardEditorContent: View {
    @Environment(\.modelContext) private var ctx

    var body: some View {
        NavigationStack {
            CardEditorView(mode: .create(kind: .projects) { _ in })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            // Ensure settings row exists so default author shortcut works if needed.
            _ = AppSettings.fetchOrCreate(in: ctx)
        }
    }
}

// MARK: Image Attribution

private struct DevImageAttributionWindow: View {
    var body: some View {
        let container = makeInMemoryContainer([Card.self, Source.self, Citation.self])
        return DevImageAttributionContent()
            .modelContainer(container)
            .padding()
    }
}

private struct DevImageAttributionContent: View {
    @Environment(\.modelContext) private var ctx
    @State private var card: Card?

    var body: some View {
        Group {
            if let card {
                ImageAttributionViewer(card: card)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView("Seeding sample attribution…")
                    .task { await seed() }
            }
        }
    }

    @MainActor
    private func seed() async {
        let c = Card(
            kind: .characters,
            name: "Ada",
            subtitle: "The Analyst",
            detailedText: "Curious and meticulous.",
            author: "M. S.",
            sizeCategory: .standard
        )
        let s1 = Source(title: "Photo Archive", authors: "Archivist")
        let s2 = Source(title: "Stock Photo", authors: "Photog Inc.")
        let t0 = Date()
        let cit1 = Citation(card: c, source: s1, kind: .image, locator: "fig. 2", excerpt: "Portrait", contextNote: "Cover image", createdAt: t0.addingTimeInterval(0.1))
        let cit2 = Citation(card: c, source: s2, kind: .image, locator: "ID 12345", excerpt: "Landscape", createdAt: t0.addingTimeInterval(0.2))
        ctx.insert(c); ctx.insert(s1); ctx.insert(s2); ctx.insert(cit1); ctx.insert(cit2)
        try? ctx.save()
        card = c
    }
}
#endif // DEBUG

#endif // os(macOS)

