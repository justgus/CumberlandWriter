//
//  CumberlandApp.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/10/25.
//

import SwiftUI
import SwiftData
import OSLog

// Cross-platform notification for developer-triggered erase
extension Notification.Name {
    static let eraseAndReseed = Notification.Name("Dev.EraseAndReseed")
}

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

        // Build a concrete Schema from the latest versioned schema's models.
        // Latest is V5 (includes Board/BoardNode and AI image metadata).
        // CloudKit handles schema migrations automatically for optional properties and new models.
        let schema = Schema(AppSchemaV5.models)

        // TEMPORARY: Nuclear option for development - delete ALL SwiftData stores
        #if DEBUG
        // Set to true to force deletion of all SwiftData stores on next launch
        if false { // Set to true once if migration issues arise
            let fm = FileManager.default
            
            guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                logger.error("Could not find Application Support directory")
                fatalError("Could not find Application Support directory")
            }
            
            logger.warning("🔍 Searching for SwiftData stores in: \(appSupport.path)")
            
            // Delete ALL .store files and related files in Application Support
            var deletedCount = 0
            
            if let enumerator = fm.enumerator(at: appSupport, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    let filename = fileURL.lastPathComponent
                    
                    // Delete any .store, .store-wal, .store-shm files, or directories that might contain stores
                    if filename.hasSuffix(".store") || 
                       filename.hasSuffix(".store-wal") || 
                       filename.hasSuffix(".store-shm") ||
                       filename.contains("iCloud.CumberlandCloud") {
                        
                        do {
                            // Check if it's a directory
                            var isDirectory: ObjCBool = false
                            if fm.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) {
                                if isDirectory.boolValue {
                                    // Delete entire directory
                                    try fm.removeItem(at: fileURL)
                                    logger.warning("🗑️ Deleted directory: \(filename)")
                                    deletedCount += 1
                                } else {
                                    // Delete file
                                    try fm.removeItem(at: fileURL)
                                    logger.warning("🗑️ Deleted file: \(filename)")
                                    deletedCount += 1
                                }
                            }
                        } catch {
                            logger.error("Failed to delete \(fileURL.path): \(error)")
                        }
                    }
                }
            }
            
            // Also try to delete the app-specific bundle ID directory entirely
            if let bundleID = Bundle.main.bundleIdentifier {
                let appDir = appSupport.appendingPathComponent(bundleID)
                if fm.fileExists(atPath: appDir.path) {
                    do {
                        try fm.removeItem(at: appDir)
                        logger.warning("🗑️ Deleted entire app directory: \(bundleID)")
                        deletedCount += 1
                    } catch {
                        logger.error("Failed to delete app directory: \(error)")
                    }
                }
            }
            
            if deletedCount > 0 {
                logger.warning("⚠️ DELETED \(deletedCount) SwiftData store file(s)/directory(ies). Starting completely fresh.")
            } else {
                logger.debug("No existing store files found to delete.")
            }
        }
        #endif

        // Use the latest schema. CloudKit handles migrations itself.
        // CloudKit enabled after Development Environment reset
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
                // Persist/restore window frame and state
                .background(WindowStateBridge(id: "mainWindow",
                                              autosaveName: "CumberlandMainWindow",
                                              defaults: .standard))
                #endif
                // Bridge the window’s UndoManager into SwiftData so Command-Z works.
                .background(UndoBridge(modelContext: modelContainer.mainContext))
                // Post-upgrade backfill and seed data once the container is available
                .task {
                    await CumberlandApp.backfillOriginalImagesIfNeeded(container: modelContainer)
                    await CumberlandApp.seedRelationTypesIfNeeded(container: modelContainer)
                    // Ensure Scene→Project "stories" edges exist by backfilling from current part-of chains
                    await CumberlandApp.backfillSceneProjectStoriesEdgesIfNeeded(container: modelContainer)
                    await CumberlandApp.seedStoryStructuresIfNeeded(container: modelContainer)
                    await CumberlandApp.seedCalendarSystemsIfNeeded(container: modelContainer)
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
            PreferencesCommands()
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
        
        // PHASE 2: Floating card editor windows
        // Allows card creation/editing in independent floating windows
        // Users can position editors alongside main content for side-by-side workflows
        WindowGroup(for: AppModel.CardEditorRequest.self) { $request in
            if let request {
                CardEditorWindowView(editorRequest: request)
                    .environment(appModel)
                    .modelContainer(modelContainer)
                    .preferredColorScheme(appPreferredColorScheme)
            }
        }
        .defaultSize(width: 840, height: 780)
        #endif
        
        #if os(visionOS) && DEBUG
        // Developer Tools window for visionOS
        Window("Developer Tools", id: "dev.tools") {
            DeveloperToolsView()
                .modelContainer(modelContainer)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 520, minHeight: 480)
        }
        .windowStyle(.plain)
        .defaultSize(width: 600, height: 600)
        #endif

        #if os(macOS)
        // Dedicated Settings/Preferences window for macOS
        // DR-0030: Accessible via Cumberland > Preferences... menu (Cmd+,)
        Window("Preferences", id: "settings") {
            SettingsView()
                .modelContainer(modelContainer)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 520, minHeight: 380)
        }
        .windowResizability(.contentSize)

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

        // New: Fix incomplete relationships (live container)
        Window("Diagnostics: Fix Incomplete Relationships", id: "dev.fixInverseEdges") {
            FixIncompleteRelationshipsView()
                .modelContainer(modelContainer) // live container
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 780, minHeight: 560)
        }

        // New: Boards diagnostics (live container)
        Window("Diagnostics: Boards", id: "dev.boards") {
            DeveloperBoardsView()
                .modelContainer(modelContainer) // live container
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 920, minHeight: 560)
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

// A tiny helper view that attaches the window’s UndoManager to the SwiftData ModelContext.
private struct UndoBridge: View {
    @Environment(\.undoManager) private var undoManager
    let modelContext: ModelContext

    var body: some View {
        // Use task and onChange so we catch initial and future changes.
        Color.clear
            .task { modelContext.undoManager = undoManager }
            .onChange(of: undoManager) { _, newValue in
                modelContext.undoManager = newValue
            }
    }
}

extension CumberlandApp {
    struct SeedDescriptor: Hashable {
        let code: String
        let forward: String
        let inverse: String
        let source: Kinds?
        let target: Kinds?
    }

    // Canonical, idempotent seed set. Codes are stable and human labels are user-facing.
    // IMPORTANT: These relation types are hardcoded in various views throughout the app.
    // Key views that reference specific codes:
    //   - TimelineChartView: describes/described-by, appears-in/is-appeared-by, part-of/has-scene
    //   - StructureBoardView: stories/is-storied-by
    //   - (Add others here as they're identified)
    static var relationTypeSeeds: [SeedDescriptor] {
        [
            // MARK: - Global (Any → Any)
//            .init(code: "references", forward: "references", inverse: "referenced by", source: nil, target: nil),
//            .init(code: "related-to/related-to", forward: "related to", inverse: "related to", source: nil, target: nil),
//            .init(code: "same-as/same-as", forward: "same as", inverse: "same-as", source: nil, target: nil), // keep as-is per existing
//            .init(code: "includes/part-of", forward: "includes", inverse: "part of", source: nil, target: nil),
//            .init(code: "depends-on/required-by", forward: "depends on", inverse: "required by", source: nil, target: nil),
//            .init(code: "precedes/follows", forward: "precedes", inverse: "follows", source: nil, target: nil),
            .init(code: "uses/used-by", forward: "uses", inverse: "used by", source: nil, target: nil),  // ER-0008: Timeline → Calendar
//            .init(code: "inspired-by/inspires", forward: "inspired by", inverse: "inspires", source: nil, target: nil),
//            .init(code: "derived-from/basis-for", forward: "derived from", inverse: "basis for", source: nil, target: nil),

            // MARK: - Scoped (specific Kinds)

            // Bibliographic: Sources → Any
            .init(code: "cites", forward: "cites", inverse: "cited by", source: .sources, target: nil),

            // MARK: - Characters Relations
            
            // Characters ↔ Scenes (REQUIRED by TimelineChartView)
            .init(code: "appears-in/is-appeared-by", forward: "appears in", inverse: "is appeared by", source: .characters, target: .scenes),

            // Characters ↔ Projects (cast listing)
            .init(code: "appears-in/dramatis personae", forward: "appears in", inverse: "dramatis personae", source: .characters, target: .projects),

            // Characters ↔ Vehicles
            .init(code: "pilots/piloted-by", forward: "pilots", inverse: "piloted by", source: .characters, target: .vehicles),

            // Characters ↔ Artifacts
            .init(code: "owns/owned-by", forward: "owns", inverse: "owned by", source: .characters, target: .artifacts),

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

            // MARK: - Scene Relations

            // Scenes ↔ Worlds
            .init(code: "set-in/contains-scene", forward: "set in", inverse: "contains scene", source: .scenes, target: .worlds),

            // Scenes ↔ Chapters (compose) (REQUIRED by TimelineChartView)
            .init(code: "part-of/has-scene", forward: "part of", inverse: "has scene", source: .scenes, target: .chapters),

            // Scenes ↔ Timelines (REQUIRED by TimelineChartView)
            .init(code: "describes/described-by", forward: "describes", inverse: "described by", source: .scenes, target: .timelines),

            // Scenes ↔ Projects (direct story linkage) (REQUIRED by StructureBoardView)
            .init(code: "stories/is-storied-by", forward: "stories", inverse: "is storied by", source: .scenes, target: .projects),

            // MARK: - Project Relations

            // Projects ↔ Worlds (setting)
            .init(code: "set-in/setting-for", forward: "set in", inverse: "setting for", source: .projects, target: .worlds),

            // Projects hierarchy
            .init(code: "parent-of/child-of", forward: "parent of", inverse: "child of", source: .projects, target: .projects),

            // MARK: - Chapter Relations

            // Chapters ↔ Projects (compose)
            .init(code: "part-of/has-member", forward: "part of", inverse: "has member", source: .chapters, target: .projects),

            // MARK: - World Relations

            // Worlds ↔ Rules (application)
            .init(code: "applies/applied-to", forward: "applies", inverse: "applied to", source: .worlds, target: .rules),

            // Maps ↔ Worlds
            .init(code: "maps/mapped-by", forward: "maps", inverse: "mapped by", source: .maps, target: .worlds),

            // MARK: - Location Relations

            // Locations ↔ Maps
            .init(code: "appears-on/shows", forward: "appears on", inverse: "shows", source: .locations, target: .maps),

            // Locations ↔ Worlds
            .init(code: "located-in/contains", forward: "located in", inverse: "contains", source: .locations, target: .worlds),

            // Buildings ↔ Locations
            .init(code: "housed-in/contains-building", forward: "housed in", inverse: "contains building", source: .buildings, target: .locations)
        ]
    }

    @MainActor
    static func backfillOriginalImagesIfNeeded(container: ModelContainer) async {
        let ctx = container.mainContext
        ctx.autosaveEnabled = true

        let urls = ImageStore.shared.listAllOriginalImageURLs()
        guard urls.isEmpty == false else { return }

        // Build a map of id -> URL for quick lookup
        var byID: [UUID: URL] = [:]
        byID.reserveCapacity(urls.count)
        for u in urls {
            if let id = ImageStore.shared.originalID(from: u) {
                byID[id] = u
            }
        }
        guard !byID.isEmpty else { return }

        var fetch = FetchDescriptor<Card>()
        fetch.fetchLimit = 0
        let cards: [Card] = (try? ctx.fetch(fetch)) ?? []
        var updated = 0

        for card in cards {
            guard card.originalImageData == nil, let url = byID[card.id] else { continue }
            if let data = try? Data(contentsOf: url), !data.isEmpty {
                card.originalImageData = data
                if card.thumbnailData == nil, let cg = Card.makeCGImage(from: data) {
                    card.thumbnailData = Card.makePNGThumbnailData(from: cg, maxPixel: 256)
                }
                updated += 1
            }
        }

        if updated > 0 {
            try? ctx.save()
        }
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
        let chProjCodeOpt: String? = chProjCode
        let chapterToProjectFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.type?.code == chProjCodeOpt })
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
        let storiesCodeOpt: String? = storiesCode
        let existingStoriesFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.type?.code == storiesCodeOpt })
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
        let scChCodeOpt: String? = scChCode
        let sceneToChapterFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.type?.code == scChCodeOpt })
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

    // DR-0033: Improved seeding with per-template checking and deduplication
    @MainActor
    static func seedStoryStructuresIfNeeded(container: ModelContainer) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "Seeding")
        let ctx = container.mainContext
        ctx.autosaveEnabled = true

        // DR-0033: First, remove any duplicates that may exist
        await removeDuplicateStructures(container: container)

        // DR-0033: Check each template individually instead of just checking if ANY exists
        var inserted = 0
        for template in StoryStructure.predefinedTemplates {
            // Check if this specific template already exists by name
            // Capture the name in a local variable for the predicate
            let templateName = template.name
            var fetchByName = FetchDescriptor<StoryStructure>(
                predicate: #Predicate<StoryStructure> { structure in
                    structure.name == templateName
                }
            )
            fetchByName.fetchLimit = 1

            if let existing = try? ctx.fetch(fetchByName), !existing.isEmpty {
                logger.debug("Skipping template '\(template.name)' - already exists")
                continue
            }

            // Template doesn't exist, insert it
            let s = StoryStructure.createFromTemplate(template)
            ctx.insert(s)
            inserted += 1
            logger.debug("Inserting template: \(template.name)")
        }

        if inserted > 0 {
            do {
                try ctx.save()
                logger.info("Seeded \(inserted) new StoryStructure template(s).")
            } catch {
                logger.error("Failed to save seeded StoryStructures: \(String(describing: error))")
            }
        } else {
            logger.debug("All templates already present, no seeding needed.")
        }
    }

    // ER-0008: Seed Gregorian calendar template if needed
    @MainActor
    static func seedCalendarSystemsIfNeeded(container: ModelContainer) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "Seeding")
        let ctx = container.mainContext
        ctx.autosaveEnabled = true

        // Check if Gregorian calendar already exists
        let gregorianName = "Gregorian"
        var fetchByName = FetchDescriptor<CalendarSystem>(
            predicate: #Predicate<CalendarSystem> { calendar in
                calendar.name == gregorianName
            }
        )
        fetchByName.fetchLimit = 1

        if let existing = try? ctx.fetch(fetchByName), !existing.isEmpty {
            logger.debug("Gregorian calendar already exists, skipping seed")
            return
        }

        // Create Gregorian calendar template
        let gregorian = CalendarSystem.gregorian()
        gregorian.calendarDescription = "Standard Gregorian calendar with seconds, minutes, hours, days, weeks, months, years, decades, centuries, and millennia"
        ctx.insert(gregorian)

        do {
            try ctx.save()
            logger.info("Seeded Gregorian calendar system")
        } catch {
            logger.error("Failed to seed Gregorian calendar: \(String(describing: error))")
        }
    }

    // DR-0033, DR-0033.1: Remove duplicate structures, keeping only the first of each unique name
    @MainActor
    static func removeDuplicateStructures(container: ModelContainer) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "Deduplication")
        let ctx = container.mainContext
        ctx.autosaveEnabled = false // Disable during cleanup

        // Fetch all structures
        let allStructuresFetch = FetchDescriptor<StoryStructure>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        guard let allStructures = try? ctx.fetch(allStructuresFetch) else {
            logger.error("Failed to fetch structures for deduplication")
            return
        }

        // DR-0033.1: Group by NORMALIZED name (trimmed whitespace, lowercased)
        // Build a dictionary of normalized name -> [all structures with that name]
        var nameGroups: [String: [StoryStructure]] = [:]

        for structure in allStructures {
            // DR-0033.1: Normalize the name for comparison (trim whitespace, lowercase)
            let normalizedName = structure.name.trimmingCharacters(in: .whitespaces).lowercased()

            if nameGroups[normalizedName] == nil {
                nameGroups[normalizedName] = []
            }
            nameGroups[normalizedName]?.append(structure)
        }

        // For each group, determine which structure to keep and which to delete
        var duplicatesToDelete: [StoryStructure] = []

        for (normalizedName, structures) in nameGroups {
            guard structures.count > 1 else {
                // No duplicates for this name
                let structure = structures[0]
                let rawNameDebug = structure.name.replacingOccurrences(of: " ", with: "·")
                logger.debug("Processing '\(rawNameDebug)' (normalized: '\(normalizedName)') - no duplicates")
                continue
            }

            // We have duplicates! Decide which to keep
            logger.info("Found \(structures.count) structures with normalized name '\(normalizedName)'")

            // DR-0033.1: Prefer keeping structures WITH card assignments
            // Check each structure for assignments
            var structuresWithAssignments: [StoryStructure] = []
            var structuresWithoutAssignments: [StoryStructure] = []

            for structure in structures {
                let hasAssignments = structure.elements?.contains { element in
                    !(element.assignedCards?.isEmpty ?? true)
                } ?? false

                let rawNameDebug = structure.name.replacingOccurrences(of: " ", with: "·")
                if hasAssignments {
                    structuresWithAssignments.append(structure)
                    logger.debug("  '\(rawNameDebug)' (ID: \(structure.id)) - HAS card assignments")
                } else {
                    structuresWithoutAssignments.append(structure)
                    logger.debug("  '\(rawNameDebug)' (ID: \(structure.id)) - NO card assignments")
                }
            }

            // DR-0033.1: Smart deletion strategy
            if !structuresWithAssignments.isEmpty {
                // Keep the first one WITH assignments, delete all others
                let toKeep = structuresWithAssignments[0]
                let rawNameDebug = toKeep.name.replacingOccurrences(of: " ", with: "·")
                logger.info("Keeping '\(rawNameDebug)' (ID: \(toKeep.id)) - has card assignments")

                // Delete remaining structures with assignments (if any)
                for structure in structuresWithAssignments.dropFirst() {
                    let rawNameDebug = structure.name.replacingOccurrences(of: " ", with: "·")
                    logger.warning("Cannot delete '\(rawNameDebug)' (ID: \(structure.id)) - has card assignments, manual merge needed")
                    // Don't add to duplicatesToDelete - preserve user data
                }

                // Delete all structures WITHOUT assignments
                for structure in structuresWithoutAssignments {
                    duplicatesToDelete.append(structure)
                    let rawNameDebug = structure.name.replacingOccurrences(of: " ", with: "·")
                    logger.info("Marking '\(rawNameDebug)' (ID: \(structure.id)) for deletion - no assignments")
                }
            } else {
                // None have assignments - keep the oldest (first in sorted list)
                let toKeep = structures[0]
                let rawNameDebug = toKeep.name.replacingOccurrences(of: " ", with: "·")
                logger.info("Keeping oldest '\(rawNameDebug)' (ID: \(toKeep.id)) - none have assignments")

                // Delete the rest
                for structure in structures.dropFirst() {
                    duplicatesToDelete.append(structure)
                    let rawNameDebug = structure.name.replacingOccurrences(of: " ", with: "·")
                    logger.info("Marking '\(rawNameDebug)' (ID: \(structure.id)) for deletion")
                }
            }
        }

        // Delete duplicates (these should all be safe to delete)
        if !duplicatesToDelete.isEmpty {
            logger.info("Deleting \(duplicatesToDelete.count) duplicate structure(s)")
            for duplicate in duplicatesToDelete {
                let rawNameDebug = duplicate.name.replacingOccurrences(of: " ", with: "·")
                logger.info("Deleting '\(rawNameDebug)' (ID: \(duplicate.id))")
                ctx.delete(duplicate)
            }

            do {
                try ctx.save()
                logger.info("Successfully removed \(duplicatesToDelete.count) duplicate structure(s)")
            } catch {
                logger.error("Failed to delete duplicate structures: \(String(describing: error))")
            }
        } else {
            logger.debug("No duplicate structures to delete")
        }

        ctx.autosaveEnabled = true
    }

    // Destructive reset: delete all data and reseed baseline templates.
    @MainActor
    public static func eraseAndReseed(container: ModelContainer) async {
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
            card.cleanupBeforeDeletion(in: container.mainContext)
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
        await backfillOriginalImagesIfNeeded(container: container)
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

private struct PreferencesCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Preferences...") {
                openWindow(id: "settings")
            }
            .keyboardShortcut(",", modifiers: .command)
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

            // New: Boards (Live)
            Button("Boards (Live)") {
                openWindow(id: "dev.boards")
            }
            .keyboardShortcut("B", modifiers: [.command, .shift])

            Divider()

            // New: Fix incomplete relationships
            Button("Fix Incomplete Relationships…") {
                openWindow(id: "dev.fixInverseEdges")
            }
            .keyboardShortcut("R", modifiers: [.command, .shift])

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
#endif // DEBUG

#endif // os(macOS)

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

// MARK: - Fix Incomplete Relationships Tool (DEBUG, all platforms)

#if DEBUG
struct FixIncompleteRelationshipsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    @State private var isRunning: Bool = false
    @State private var report: String = ""
    @State private var createdInverseEdges: Int = 0
    @State private var createdMirrorTypes: Int = 0
    @State private var scannedEdges: Int = 0
    @State private var errors: Int = 0

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "Diagnostics.RepairInverse")

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            HStack(spacing: 8) {
                Button {
                    Task { await runRepair() }
                } label: {
                    Label("Scan and Fix", systemImage: "wrench.and.screwdriver.fill")
                }
                .disabled(isRunning)

                Button {
                    report = ""
                    scannedEdges = 0
                    createdInverseEdges = 0
                    createdMirrorTypes = 0
                    errors = 0
                } label: {
                    Label("Clear Report", systemImage: "trash")
                }
                .disabled(isRunning || report.isEmpty)

                Spacer()

                if isRunning {
                    ProgressView().controlSize(.small)
                }

                if !report.isEmpty {
                    Button {
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(report, forType: .string)
                        #else
                        UIPasteboard.general.string = report
                        #endif
                    } label: {
                        Label("Copy Report", systemImage: "doc.on.doc")
                    }
                }
            }

            summary

            GroupBox("Report") {
                ScrollView {
                    Text(report.isEmpty ? "No report yet. Click “Scan and Fix” to begin." : report)
                        .textSelection(.enabled)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }
                .frame(minHeight: 320)
            }

            Spacer(minLength: 0)
        }
        .padding()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Fix Incomplete Relationships", systemImage: "arrow.triangle.2.circlepath")
                .font(.title3.bold())
            Text("Ensures every CardEdge has an inverse edge using a mirrored RelationType. Creates missing mirror RelationTypes as needed and reports all changes.")
                .foregroundStyle(.secondary)
        }
    }

    private var summary: some View {
        HStack(spacing: 16) {
            statView(title: "Scanned Edges", value: scannedEdges, color: .secondary)
            statView(title: "Inverse Edges Created", value: createdInverseEdges, color: .green)
            statView(title: "Mirror Types Created", value: createdMirrorTypes, color: .blue)
            statView(title: "Errors", value: errors, color: .red)
            Spacer()
        }
    }

    private func statView(title: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text("\(value)").font(.headline).foregroundStyle(color)
        }
    }

    // MARK: - Repair

    @MainActor
    private func runRepair() async {
        isRunning = true
        defer { isRunning = false }

        var lines: [String] = []
        lines.append("=== Fix Incomplete Relationships ===")
        lines.append("Date: \(Date().formatted(date: .abbreviated, time: .standard))")
        lines.append("")

        let ctx = modelContext
        ctx.autosaveEnabled = true

        let allEdges = (try? ctx.fetch(FetchDescriptor<CardEdge>())) ?? []
        scannedEdges = allEdges.count
        lines.append("Scanned edges: \(scannedEdges)")
        lines.append("")

        // Cache all relation types once to reduce fetches
        var typeCache = (try? ctx.fetch(FetchDescriptor<RelationType>())) ?? []

        func fetchType(code: String) -> RelationType? {
            typeCache.first(where: { $0.code == code })
        }

        var createdEdges = 0
        var createdTypes = 0
        var errorCount = 0

        for e in allEdges {
            guard let from = e.from, let to = e.to else { continue }

            // Check if inverse edge already exists (any type); if so, skip
            let toIDOpt: UUID? = to.id
            let fromIDOpt: UUID? = from.id
            let invFetch = FetchDescriptor<CardEdge>(
                predicate: #Predicate {
                    $0.from?.id == toIDOpt && $0.to?.id == fromIDOpt
                }
            )
            if let inv = try? ctx.fetch(invFetch), inv.isEmpty == false {
                continue
            }

            // Determine mirror RelationType
            let mirror: RelationType
            if let t = e.type {
                mirror = ensureMirrorType(for: t, sourceKind: from.kind, targetKind: to.kind, typeCache: &typeCache)
                if !typeCache.contains(where: { $0.code == mirror.code }) {
                    typeCache.append(mirror)
                }
            } else {
                // If original edge has no type, create/use a generic symmetric type
                let forward = "related to"
                let inverse = "related to"
                let code = makeCode(forward: forward, inverse: inverse)
                if let existing = fetchType(code: code) {
                    mirror = existing
                } else {
                    let newType = RelationType(code: code, forwardLabel: forward, inverseLabel: inverse, sourceKind: nil, targetKind: nil)
                    ctx.insert(newType)
                    mirror = newType
                    typeCache.append(newType)
                    createdTypes += 1
                    lines.append("Created type: \(code) (generic, for missing type)")
                }
            }

            // Create inverse edge
            let invEdge = CardEdge(from: to, to: from, type: mirror, note: e.note, createdAt: e.createdAt.addingTimeInterval(0.001))
            ctx.insert(invEdge)
            createdEdges += 1
            lines.append("Inverse edge created: \(from.kind.singularTitle) “\(from.name)” ⇄ \(to.kind.singularTitle) “\(to.name)” using type “\(mirror.code)”")
        }

        do {
            try ctx.save()
        } catch {
            errorCount += 1
            logger.error("Repair save failed: \(String(describing: error))")
            lines.append("ERROR: Failed to save changes: \(String(describing: error))")
        }

        createdInverseEdges = createdEdges
        createdMirrorTypes = createdTypes
        errors = errorCount

        lines.append("")
        lines.append("--- Summary ---")
        lines.append("Scanned: \(scannedEdges)")
        lines.append("Inverse edges created: \(createdInverseEdges)")
        lines.append("Mirror types created: \(createdMirrorTypes)")
        lines.append("Errors: \(errors)")

        report = lines.joined(separator: "\n")
    }

    // MARK: - Mirror helpers

    // Ensure a mirrored type exists (swap source/target kinds and labels).
    @MainActor
    private func ensureMirrorType(for t: RelationType, sourceKind: Kinds, targetKind: Kinds, typeCache: inout [RelationType]) -> RelationType {
        // Desired mirror code from swapped labels
        let desiredCode = makeCode(forward: t.inverseLabel, inverse: t.forwardLabel)

        if let existing = typeCache.first(where: { $0.code == desiredCode }) {
            return existing
        }

        // Try to find a type that matches swapped kinds and swapped labels (even if code differs)
        if let match = typeCache.first(where: {
            ($0.sourceKindRaw == targetKind.rawValue || $0.sourceKindRaw == nil) &&
            ($0.targetKindRaw == sourceKind.rawValue || $0.targetKindRaw == nil) &&
            $0.forwardLabel == t.inverseLabel &&
            $0.inverseLabel == t.forwardLabel
        }) {
            return match
        }

        // Create a new mirror type with a unique code if needed
        var codeToUse = desiredCode
        var suffix = 1
        while typeCache.contains(where: { $0.code == codeToUse }) {
            suffix += 1
            codeToUse = makeCode(forward: t.inverseLabel, inverse: t.forwardLabel, suffix: suffix)
        }

        let mirror = RelationType(
            code: codeToUse,
            forwardLabel: t.inverseLabel,
            inverseLabel: t.forwardLabel,
            sourceKind: targetKind,
            targetKind: sourceKind
        )
        modelContext.insert(mirror)
        createdMirrorTypes += 1
        return mirror
    }

    // Code building helpers
    private func sanitize(_ s: String) -> String {
        let lowered = s.lowercased()
        let replaced = lowered.replacingOccurrences(of: " ", with: "-")
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-")
        let filtered = String(replaced.unicodeScalars.filter { allowed.contains($0) })
        var result = filtered
        while result.contains("--") {
            result = result.replacingOccurrences(of: "--", with: "-")
        }
        return result
    }

    private func makeCode(forward: String, inverse: String, suffix: Int? = nil) -> String {
        let base = "\(sanitize(forward))/\(sanitize(inverse))"
        if let suffix {
            return "\(base)-\(suffix)"
        } else {
            return base
        }
    }
}
#endif // DEBUG

#if os(macOS)
// Additional macOS-only debug functionality can go here if needed
#endif // os(macOS)

#if os(macOS)
import AppKit

// MARK: - Window State Bridge (macOS)

private struct WindowStateBridge: NSViewRepresentable {
    let id: String
    let autosaveName: String
    let defaults: UserDefaults

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            if let window = view.window {
                context.coordinator.attach(to: window, id: id, autosaveName: autosaveName, defaults: defaults)
            } else {
                // Try again on next runloop if window not yet attached
                DispatchQueue.main.async {
                    if let window = view.window {
                        context.coordinator.attach(to: window, id: id, autosaveName: autosaveName, defaults: defaults)
                    }
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        private weak var window: NSWindow?
        private var id: String = ""
               private var defaults: UserDefaults = .standard
        private var observing = false

        private var frameKey: String { "Window.\(id).frame" }
        private var zoomedKey: String { "Window.\(id).zoomed" }
        private var fullScreenKey: String { "Window.\(id).fullScreen" }

        func attach(to window: NSWindow, id: String, autosaveName: String, defaults: UserDefaults) {
            guard self.window !== window else { return }
            self.window = window
            self.id = id
            self.defaults = defaults

            // Enable AppKit autosave of frame
            window.setFrameAutosaveName(autosaveName)

            // Restore saved state (frame, zoomed, full-screen)
            restoreState(for: window)

            if !observing {
                observing = true
                window.delegate = self
                let center = NotificationCenter.default
                center.addObserver(self, selector: #selector(handleResize), name: NSWindow.didResizeNotification, object: window)
                center.addObserver(self, selector: #selector(handleMove), name: NSWindow.didMoveNotification, object: window)
                center.addObserver(self, selector: #selector(handleZoom), name: NSWindow.didEndLiveResizeNotification, object: window)
                center.addObserver(self, selector: #selector(handleEnterFullScreen), name: NSWindow.didEnterFullScreenNotification, object: window)
                center.addObserver(self, selector: #selector(handleExitFullScreen), name: NSWindow.didExitFullScreenNotification, object: window)
            }

            // Save initial state too (in case user quits without moving/resizing)
            saveState(for: window)
        }

        // MARK: - Persist/Restore

        private func restoreState(for window: NSWindow) {
            // Restore frame if we have it (in case autosave didn’t apply yet)
            if let rectString = defaults.string(forKey: frameKey) {
                let rect = NSRectFromString(rectString)
                if let fitted = fit(rect: rect) {
                    window.setFrame(fitted, display: false)
                }
            }

            // Restore full-screen first (if was full screen)
            let wasFull = defaults.bool(forKey: fullScreenKey)
            if wasFull {
                // Enter full screen asynchronously after window is on screen
                DispatchQueue.main.async {
                    if !window.styleMask.contains(.fullScreen) {
                        window.toggleFullScreen(nil)
                    }
                }
                return // zoomed state is irrelevant in full screen
            }

            // Restore zoomed (maximized) state
            let wasZoomed = defaults.bool(forKey: zoomedKey)
            if wasZoomed && !window.isZoomed {
                DispatchQueue.main.async {
                    if !window.isZoomed {
                        window.performZoom(nil)
                    }
                }
            }
        }

        private func saveState(for window: NSWindow) {
            defaults.set(NSStringFromRect(window.frame), forKey: frameKey)
            defaults.set(window.isZoomed, forKey: zoomedKey)
            let isFull = window.styleMask.contains(.fullScreen)
            defaults.set(isFull, forKey: fullScreenKey)
        }

        // Ensure restored frame is at least partially visible on current screens
        private func fit(rect: NSRect) -> NSRect? {
            let screens = NSScreen.screens
            guard !screens.isEmpty else { return rect }
            // If any screen intersects significantly, keep it; otherwise, move to primary visibleFrame
            for s in screens {
                if s.visibleFrame.insetBy(dx: -50, dy: -50).intersects(rect) {
                    return rect
                }
            }
            // Fallback: place in primary screen’s visible area with same size clamped
            let primary = screens.first!.visibleFrame
            var size = rect.size
            size.width = min(size.width, primary.width)
            size.height = min(size.height, primary.height)
            return NSRect(x: primary.minX + 40, y: primary.minY + 40, width: size.width, height: size.height)
        }

        // MARK: - Notifications

        @objc private func handleResize(_ note: Notification) {
            guard let w = window else { return }
            saveState(for: w)
        }

        @objc private func handleMove(_ note: Notification) {
            guard let w = window else { return }
            saveState(for: w)
        }

        @objc private func handleZoom(_ note: Notification) {
            guard let w = window else { return }
            saveState(for: w)
        }

        @objc private func handleEnterFullScreen(_ note: Notification) {
            guard let w = window else { return }
            saveState(for: w)
        }

        @objc private func handleExitFullScreen(_ note: Notification) {
            guard let w = window else { return }
            saveState(for: w)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}
#endif
