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
                #if os(macOS)
                .toolbarBackground(.ultraThinMaterial, for: .windowToolbar)
                .toolbarBackground(.visible, for: .windowToolbar)
                #endif
                // Seed relation types and story structure templates once the container is available
                .task {
                    await CumberlandApp.seedRelationTypesIfNeeded(container: modelContainer)
                    // New: ensure Scene→Project "stories" edges exist by backfilling from current part-of chains
                    await CumberlandApp.backfillSceneProjectStoriesEdgesIfNeeded(container: modelContainer)
                    await CumberlandApp.seedStoryStructuresIfNeeded(container: modelContainer)
                }
                // Developer-triggered destructive reset (macOS menu posts a notification)
                .onReceive(NotificationCenter.default.publisher(for: .eraseAndReseed)) { _ in
                    Task { @MainActor in
                        await CumberlandApp.eraseAndReseed(container: modelContainer)
                    }
                }
        }
        #if os(macOS)
        .commands {
            AboutCommands()
            #if DEBUG
            DeveloperCommands()
            #endif
            // New: Editor command to insert default author into the focused Author field.
            EditorCommands()
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

        // New: Scene → Project relation diagnostics (live container)
        Window("Diagnostics: Scene → Project Relations", id: "dev.sceneProjectRelations") {
            SceneProjectRelationDiagnosticsView()
                .modelContainer(modelContainer) // live container
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 720, minHeight: 520)
        }
        #endif
        #endif
     }
}

#if os(macOS)
// Editor-level commands for macOS that can act on focused fields in CardEditorView.
private struct EditorCommands: Commands {
    // This matches the FocusedValues key that CardEditorView publishes on macOS.
    @FocusedValue(\.insertDefaultAuthor) private var insertDefaultAuthor

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Button("Insert Default Author") {
                insertDefaultAuthor?()
            }
            .keyboardShortcut("A", modifiers: [.command, .shift])
            .disabled(insertDefaultAuthor == nil)
        }
    }
}
#endif

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

            // Characters ↔ Projects (cast listing)
            .init(code: "appears-in/dramatis-personae", forward: "appears in", inverse: "dramatis personae", source: .characters, target: .projects),

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
            .init(code: "works-with/works-with", forward: "works with", inverse: "works with", source: .characters, target: .characters),

            // New: Scenes ↔ Projects (direct story linkage)
            .init(code: "stories/is-storied-by", forward: "stories", inverse: "is storied by", source: .scenes, target: .projects)
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

    // New: backfill Scene → Project "stories" edges from existing part-of chains
    @MainActor
    static func backfillSceneProjectStoriesEdgesIfNeeded(container: ModelContainer) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "Backfill")
        let ctx = container.mainContext
        ctx.autosaveEnabled = true

        // Fetch the required relation types
        let fetchTypes = FetchDescriptor<RelationType>()
        let types = (try? ctx.fetch(fetchTypes)) ?? []
        guard
            let storiesType = types.first(where: { $0.code == "stories/is-storied-by" }),
            let sceneToChapterPartOf = types.first(where: { $0.code == "part-of/has-scene" }),
            let chapterToProjectPartOf = types.first(where: { $0.code == "part-of/has-member" })
        else {
            logger.warning("Backfill skipped: required RelationTypes not found yet.")
            return
        }

        // Build Chapter -> Project map from existing edges
        let chProjCode = chapterToProjectPartOf.code
        let chapterToProjectFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.type?.code == chProjCode })
        let chProjEdges = (try? ctx.fetch(chapterToProjectFetch)) ?? []
        var chapterToProjects: [UUID: Set<UUID>] = [:]
        for e in chProjEdges {
            guard let ch = e.from, ch.kind == .chapters, let proj = e.to, proj.kind == .projects else { continue }
            chapterToProjects[ch.id, default: []].insert(proj.id)
        }
        guard !chapterToProjects.isEmpty else {
            logger.debug("Backfill: no Chapter→Project edges to derive from.")
            return
        }

        // Collect existing Scene→Project stories edges to avoid duplicates
        let storiesCode = storiesType.code
        let existingStoriesFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.type?.code == storiesCode })
        let existingStories = (try? ctx.fetch(existingStoriesFetch)) ?? []
        var existingPairs: Set<String> = []
        existingPairs.reserveCapacity(existingStories.count)
        for e in existingStories {
            if let s = e.from, let p = e.to {
                existingPairs.insert("\(s.id.uuidString)|\(p.id.uuidString)")
            }
        }

        // Traverse Scene→Chapter, then map to Project(s), and create missing stories edges
        let scChCode = sceneToChapterPartOf.code
        let sceneToChapterFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.type?.code == scChCode })
        let scChEdges = (try? ctx.fetch(sceneToChapterFetch)) ?? []
        var created = 0
        for e in scChEdges {
            guard let scene = e.from, scene.kind == .scenes, let chapter = e.to, chapter.kind == .chapters else { continue }
            guard let projIDs = chapterToProjects[chapter.id], !projIDs.isEmpty else { continue }
            for pid in projIDs {
                let key = "\(scene.id.uuidString)|\(pid.uuidString)"
                if existingPairs.contains(key) { continue }
                // Fetch the project card instance by id (to attach relationship correctly)
                let projFetch = FetchDescriptor<Card>(predicate: #Predicate { $0.id == pid })
                guard let project = try? ctx.fetch(projFetch).first else { continue }
                let edge = CardEdge(from: scene, to: project, type: storiesType)
                ctx.insert(edge)
                existingPairs.insert(key)
                created += 1
            }
        }

        if created > 0 {
            do {
                try ctx.save()
                logger.info("Backfill: created \(created) Scene→Project 'stories' edges.")
            } catch {
                logger.error("Backfill save failed: \(String(describing: error))")
            }
        } else {
            logger.debug("Backfill: no new 'stories' edges needed.")
        }
    }

    // New: seed StoryStructure templates if needed (idempotent)
    @MainActor
    static func seedStoryStructuresIfNeeded(container: ModelContainer) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "Seeding")
        let ctx = container.mainContext
        ctx.autosaveEnabled = true

        // If any StoryStructure exists, skip (or change to per-name check below if you prefer partial seeding).
        var anyFetch = FetchDescriptor<StoryStructure>()
        anyFetch.fetchLimit = 1
        if let any = try? ctx.fetch(anyFetch), !any.isEmpty {
            logger.debug("StoryStructure seeding skipped; structures already present.")
            return
        }

        // Otherwise, insert all predefined templates
        var inserted = 0
        for template in StoryStructure.predefinedTemplates {
            let s = StoryStructure.createFromTemplate(template)
            ctx.insert(s)
            inserted += 1
        }

        if inserted > 0 {
            do {
                try ctx.save()
                logger.info("Seeded \(inserted) StoryStructure template(s).")
            } catch {
                logger.error("Failed to save seeded StoryStructures: \(String(describing: error))")
            }
        }
    }

    // Destructive reset: delete all data and reseed baseline templates.
    @MainActor
    static func eraseAndReseed(container: ModelContainer) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "Reset")
        let ctx = container.mainContext
        ctx.autosaveEnabled = false

        func deleteAll<T: PersistentModel>(_ type: T.Type, preDelete: ((T) -> Void)? = nil) {
            var desc = FetchDescriptor<T>()
            desc.fetchLimit = 0 // fetch all
            let all = (try? ctx.fetch(desc)) ?? []
            for obj in all {
                preDelete?(obj)
                ctx.delete(obj)
            }
        }

        // Order matters a bit to ensure best cleanup behavior and minimal dangling refs:
        // - Clean up Card files before deletes; cascade removes edges and citations.
        // - Remove child rows before parents where cascade is nullify to keep it clean.
        // StructureElement -> StoryStructure, CardEdge, Citation -> Source, Card, RelationType, AppSettings last.
        deleteAll(StructureElement.self)
        deleteAll(StoryStructure.self)
        deleteAll(CardEdge.self)
        deleteAll(Citation.self)
        deleteAll(Source.self)
        deleteAll(Card.self) { card in
            card.cleanupBeforeDeletion()
        }
        deleteAll(RelationType.self)
        deleteAll(AppSettings.self)

        do {
            try ctx.save()
            logger.info("All data erased successfully.")
        } catch {
            logger.error("Failed to save after erase: \(String(describing: error))")
        }

        // Clear any in-memory image caches after deletion.
        Card.purgeAllImageCaches()

        // Reseed baseline data
        await seedRelationTypesIfNeeded(container: container)
        await backfillSceneProjectStoriesEdgesIfNeeded(container: container)
        await seedStoryStructuresIfNeeded(container: container)

        // Optionally recreate default AppSettings row lazily elsewhere via fetchOrCreate.
        logger.info("Reseeding completed.")
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

            // New: Scene → Project relation diagnostics
            Button("Scene → Project Relations") {
                openWindow(id: "dev.sceneProjectRelations")
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

            Divider()

            // Destructive reset
            Button("Erase Database and Reseed…", role: .destructive) {
                confirmAndTriggerErase()
            }
            .keyboardShortcut("0", modifiers: [.command, .shift])
        }
    }

    private func confirmAndTriggerErase() {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Erase Database and Reseed?"
        alert.informativeText = """
        This will permanently delete all data in the current database, including synced CloudKit data if enabled. The app will then reseed default Relation Types and Story Structures.

        This cannot be undone.
        """
        alert.addButton(withTitle: "Erase and Reseed")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NotificationCenter.default.post(name: .eraseAndReseed, object: nil)
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

// Placeholder debug views to satisfy window content references.
// Replace these with the real implementations if/when available.

struct DevSwimlaneWindow: View {
    var body: some View {
        VStack(spacing: 12) {
            Label("Swimlane Viewer (placeholder)", systemImage: "rectangle.3.group")
                .font(.title3.bold())
            Text("This is a DEBUG-only placeholder for DevSwimlaneWindow.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 800, minHeight: 500)
    }
}

struct DevCardRelationshipWindow: View {
    var body: some View {
        VStack(spacing: 12) {
            Label("Card Relationship (placeholder)", systemImage: "arrow.triangle.pull")
                .font(.title3.bold())
            Text("This is a DEBUG-only placeholder for DevCardRelationshipWindow.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 720, minHeight: 480)
    }
}

struct DevCardSheetWindow: View {
    var body: some View {
        VStack(spacing: 12) {
            Label("Card Sheet (placeholder)", systemImage: "square.grid.2x2")
                .font(.title3.bold())
            Text("This is a DEBUG-only placeholder for DevCardSheetWindow.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 640, minHeight: 480)
    }
}

struct DevImageAttributionWindow: View {
    var body: some View {
        VStack(spacing: 12) {
            Label("Image Attribution (placeholder)", systemImage: "photo.badge.checkmark")
                .font(.title3.bold())
            Text("This is a DEBUG-only placeholder for DevImageAttributionWindow.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 560, minHeight: 420)
    }
}

// (DEBUG windows unchanged…)
#endif // DEBUG

#endif // os(macOS)

// Cross-platform notification for developer-triggered erase
extension Notification.Name {
    static let eraseAndReseed = Notification.Name("Dev.EraseAndReseed")
}

