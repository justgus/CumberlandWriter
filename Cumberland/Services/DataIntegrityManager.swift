//
//  DataIntegrityManager.swift
//  Cumberland
//
//  Created as part of architectural refactoring to separate data integrity
//  operations from the app layer (CumberlandApp.swift).
//
//  This service encapsulates all one-time seeding, backfill, and data integrity
//  operations that run at app startup. Uses repositories for all data access.
//

import Foundation
import SwiftData
import OSLog

/// Manages data integrity operations including seeding, backfilling, and deduplication
///
/// This service runs one-time or periodic operations at app startup to ensure
/// data consistency and completeness. All operations use UserDefaults flags
/// to prevent re-running.
///
/// **Architecture**: Uses ServiceContainer to access repositories, ensuring
/// platform independence and testability.
@MainActor
final class DataIntegrityManager {

    // MARK: - Data Types

    /// Descriptor for seeding relation types
    private struct SeedDescriptor: Hashable {
        let code: String
        let forward: String
        let inverse: String
        let source: Kinds?
        let target: Kinds?
    }

    // MARK: - Dependencies

    private let container: ModelContainer
    private let services: ServiceContainer
    private let logger: Logger

    /// Canonical, idempotent seed set. Codes are stable and human labels are user-facing.
    /// IMPORTANT: These relation types are hardcoded in various views throughout the app.
    /// Key views that reference specific codes:
    ///   - TimelineChartView: describes/described-by, appears-in/is-appeared-by, part-of/has-scene
    ///   - StructureBoardView: stories/is-storied-by
    private let relationTypeSeeds: [SeedDescriptor] = [
        // MARK: - Global (Any → Any)
        .init(code: "uses/used-by", forward: "uses", inverse: "used by", source: nil, target: nil),  // ER-0008: Timeline → Calendar

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

        // Scenes ↔ Projects (manuscript membership) (REQUIRED by ProjectWriter system)
        .init(code: "belongs-to/contains-scene", forward: "belongs to", inverse: "contains scene", source: .scenes, target: .projects),

        // MARK: - Project Relations

        // Projects ↔ Worlds (setting)
        .init(code: "set-in/setting-for", forward: "set in", inverse: "setting for", source: .projects, target: .worlds),

        // Projects hierarchy
        .init(code: "parent-of/child-of", forward: "parent of", inverse: "child of", source: .projects, target: .projects),

        // MARK: - Chapter Relations

        // Chapters ↔ Projects (compose)
        .init(code: "part-of/has-member", forward: "part of", inverse: "has member", source: .chapters, target: .projects),

        // Chapters ↔ Projects (manuscript membership) (REQUIRED by ProjectWriter system)
        .init(code: "part-of/has-chapter", forward: "part of", inverse: "has chapter", source: .chapters, target: .projects),

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

    // MARK: - Initialization

    /// Initialize the data integrity manager
    /// - Parameter container: The ModelContainer for database access
    init(container: ModelContainer) {
        self.container = container
        self.services = ServiceContainer(modelContext: container.mainContext)
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "DataIntegrity")
    }

    // MARK: - Orchestration

    /// Run all startup integrity checks and seeding operations
    /// Call this once at app startup
    func runAllStartupChecks() async {
        logger.info("Starting data integrity checks...")

        // Order matters: seed base data first, then backfill relationships
        await seedRelationTypesIfNeeded()
        await seedStoryStructuresIfNeeded()
        await migrateOrphanCalendarSystemsIfNeeded()
        await seedCalendarSystemsIfNeeded()

        await backfillOriginalImagesIfNeeded()
        await backfillEdgeCountsIfNeeded()
        await backfillSceneProjectStoriesEdgesIfNeeded()

        await removeDuplicateCalendarCards()

        logger.info("Data integrity checks completed.")
    }

    // MARK: - Seeding Operations

    /// Seed default RelationTypes if they don't exist
    /// Uses RelationTypeManager for idempotent creation
    func seedRelationTypesIfNeeded() async {
        let context = container.mainContext
        context.autosaveEnabled = true

        let mgr = services.relationTypeManager

        var insertedCount = 0
        for s in relationTypeSeeds {
            // ensureRelationType is idempotent — skips if code already exists
            if mgr.fetchRelationType(code: s.code) != nil {
                continue
            }
            mgr.ensureRelationType(
                code: s.code,
                forwardLabel: String(localized: String.LocalizationValue(s.forward)),
                inverseLabel: String(localized: String.LocalizationValue(s.inverse)),
                sourceKind: s.source,
                targetKind: s.target
            )
            insertedCount += 1
        }

        if insertedCount > 0 {
            logger.info("Seeded \(insertedCount) RelationType(s) via RelationTypeManager.")
        } else {
            logger.debug("RelationType seeding skipped; all seeds already present.")
        }
    }

    /// Seed predefined story structures if they don't exist
    /// Removes duplicates first, then adds missing templates
    func seedStoryStructuresIfNeeded() async {
        let ctx = container.mainContext
        ctx.autosaveEnabled = true

        // First, remove any duplicates that may exist
        await removeDuplicateStructures()

        // Check each template individually instead of just checking if ANY exists
        var inserted = 0
        for template in StoryStructure.predefinedTemplates {
            // Check if this specific template already exists by name
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

    /// Migrate orphan CalendarSystem instances to Cards (one-time migration)
    /// Converts standalone CalendarSystem records to proper Calendar Cards
    private func migrateOrphanCalendarSystemsIfNeeded() async {
        let key = "didMigrateCalendarSystemsToCards_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let migrated = CalendarSystemMigrationHelper.migrateOrphanCalendarSystems(services: services)

        logger.info("Calendar migration complete: \(migrated) calendars converted to cards")

        UserDefaults.standard.set(true, forKey: key)
    }

    /// Seed Gregorian calendar system and card if needed
    /// Uses CardRepository and CalendarSystemRepository
    func seedCalendarSystemsIfNeeded() async {
        let ctx = container.mainContext
        ctx.autosaveEnabled = true

        // Check if Gregorian calendar card already exists
        let gregorianName = "Gregorian"
        var fetchCalendarCards = FetchDescriptor<Card>(
            predicate: #Predicate<Card> { card in
                card.kindRaw == "Calendars" && card.name == gregorianName
            }
        )
        fetchCalendarCards.fetchLimit = 1

        if let existing = try? ctx.fetch(fetchCalendarCards), !existing.isEmpty {
            logger.debug("Gregorian calendar card already exists, skipping seed")
            return
        }

        // Create Gregorian calendar system
        let gregorianSystem = CalendarSystem.gregorian()
        gregorianSystem.calendarDescription = "Standard Gregorian calendar with seconds, minutes, hours, days, weeks, months, years, decades, centuries, and millennia"

        do {
            // Insert CalendarSystem via repository
            try services.calendarRepository.insertCalendar(gregorianSystem)

            // Create Calendar Card via repository
            let calendarCard = try services.cardRepository.createCard(
                kind: .calendars,
                name: gregorianName,
                subtitle: "10 divisions from second to millennium",
                detailedText: gregorianSystem.calendarDescription ?? ""
            )

            // Link card to system
            calendarCard.calendarSystemRef = gregorianSystem

            // Save the link
            try ctx.save()

            logger.info("Seeded Gregorian calendar card")
        } catch {
            logger.error("Failed to seed Gregorian calendar card: \(String(describing: error))")
        }
    }

    // MARK: - Backfill Operations

    /// Backfill original images from ImageStore cache to SwiftData
    /// One-time migration to move locally cached images into the database
    func backfillOriginalImagesIfNeeded() async {
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

    /// Backfill Scene → Project "stories" edges from existing part-of chains
    /// Creates bidirectional relationships using EdgeRepository
    func backfillSceneProjectStoriesEdgesIfNeeded() async {
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

                // Use EdgeRepository.createRelationship() instead of direct CardEdge creation
                do {
                    try services.edgeRepository.createRelationship(from: scene, to: project, relationType: storiesType)
                    existingPairs.insert(key)
                    created += 1
                } catch {
                    logger.error("Backfill: failed to create relationship Scene→Project: \(String(describing: error))")
                }
            }
        }

        if created > 0 {
            logger.info("Backfill: created \(created) Scene→Project 'stories' relationship(s) (bidirectional).")
        } else {
            logger.debug("Backfill: no new 'stories' edges needed.")
        }
    }

    /// Backfill cached edge counts for all cards (one-time migration)
    /// Uses EdgeIntegrityMonitor to recalculate counts
    func backfillEdgeCountsIfNeeded() async {
        let key = "didBackfillEdgeCounts_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let ctx = container.mainContext

        let allCards = (try? ctx.fetch(FetchDescriptor<Card>())) ?? []
        var updated = 0
        for card in allCards {
            EdgeIntegrityMonitor.recalculateCounts(for: card, modelContext: ctx)
            updated += 1
        }

        do {
            try ctx.save()
            logger.info("[ER-0036] Backfilled edge counts for \(updated) cards")
        } catch {
            logger.error("[ER-0036] Edge count backfill save failed: \(String(describing: error))")
        }

        UserDefaults.standard.set(true, forKey: key)
    }

    // MARK: - Deduplication Operations

    /// Remove duplicate calendar cards, keeping only the first of each unique name
    /// Also cleans up orphaned CalendarSystem instances
    /// One-time operation guarded by UserDefaults flag
    func removeDuplicateCalendarCards() async {
        let key = "didDeduplicateCalendarCards_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let ctx = container.mainContext
        ctx.autosaveEnabled = false // Disable during cleanup

        // Fetch all calendar cards
        let allCalendarsFetch = FetchDescriptor<Card>(
            predicate: #Predicate<Card> { $0.kindRaw == "Calendars" },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )

        guard let allCalendarCards = try? ctx.fetch(allCalendarsFetch) else {
            logger.error("Failed to fetch calendar cards for deduplication")
            ctx.autosaveEnabled = true
            return
        }

        #if DEBUG
        logger.debug("Starting deduplication: found \(allCalendarCards.count) total calendar cards")
        for card in allCalendarCards {
            logger.debug("  - '\(card.name)' (ID: \(card.id))")
        }
        #endif

        // Group by normalized name (trimmed whitespace, lowercased)
        var nameGroups: [String: [Card]] = [:]

        for card in allCalendarCards {
            let normalizedName = card.name.trimmingCharacters(in: .whitespaces).lowercased()

            if nameGroups[normalizedName] == nil {
                nameGroups[normalizedName] = []
            }
            nameGroups[normalizedName]?.append(card)
        }

        // For each group with duplicates, keep the first and delete the rest
        var duplicatesToDelete: [Card] = []
        var orphanedCalendarSystems: [CalendarSystem] = []

        for (normalizedName, cards) in nameGroups {
            guard cards.count > 1 else {
                continue // No duplicates for this name
            }

            // Keep the first, mark rest for deletion
            let toKeep = cards[0]
            let toDelete = Array(cards.dropFirst())

            logger.info("Found \(cards.count) calendar cards named '\(normalizedName)'. Keeping first (created \(toKeep.name)), deleting \(toDelete.count) duplicates")

            duplicatesToDelete.append(contentsOf: toDelete)
        }

        // Before deleting cards, nullify relationships and mark CalendarSystems for cleanup
        for card in duplicatesToDelete {
            if let calendarSystem = card.calendarSystemRef {
                orphanedCalendarSystems.append(calendarSystem)
                card.calendarSystemRef = nil // Nullify to prevent cascade issues
            }
        }

        // Save after nullifying relationships
        if !duplicatesToDelete.isEmpty {
            do {
                try ctx.save()
                logger.debug("Nullified relationships for \(duplicatesToDelete.count) duplicate cards")
            } catch {
                logger.error("Failed to save after nullifying relationships: \(String(describing: error))")
                ctx.autosaveEnabled = true
                return
            }
        }

        // Delete duplicate cards
        for card in duplicatesToDelete {
            ctx.delete(card)
            logger.debug("Deleted duplicate calendar card: \(card.name)")
        }

        // Delete orphaned CalendarSystems
        for calendarSystem in orphanedCalendarSystems {
            // Only delete if no other card references it
            if calendarSystem.calendarCard == nil {
                ctx.delete(calendarSystem)
                logger.debug("Deleted orphaned CalendarSystem: \(calendarSystem.name)")
            }
        }

        if !duplicatesToDelete.isEmpty {
            do {
                try ctx.save()
                logger.info("Removed \(duplicatesToDelete.count) duplicate calendar cards and \(orphanedCalendarSystems.filter { $0.calendarCard == nil }.count) orphaned systems")
            } catch {
                logger.error("Failed to save after deduplication: \(String(describing: error))")
            }
        } else {
            logger.debug("No duplicate calendar cards found")
        }

        ctx.autosaveEnabled = true

        // Mark as complete to prevent re-running
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Remove duplicate structures, keeping only the first of each unique name
    private func removeDuplicateStructures() async {
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

        // Group by NORMALIZED name (trimmed whitespace, lowercased)
        var nameGroups: [String: [StoryStructure]] = [:]

        for structure in allStructures {
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

            // We have duplicates! Keep the first (oldest by createdAt), delete the rest
            let toKeep = structures[0]
            let toDelete = Array(structures.dropFirst())

            logger.info("Found \(structures.count) structures named '\(normalizedName)'. Keeping oldest (created \(toKeep.createdAt)), deleting \(toDelete.count) duplicates")

            duplicatesToDelete.append(contentsOf: toDelete)
        }

        // Delete duplicates
        for structure in duplicatesToDelete {
            ctx.delete(structure)
            logger.debug("Deleted duplicate structure: \(structure.name)")
        }

        if !duplicatesToDelete.isEmpty {
            do {
                try ctx.save()
                logger.info("Removed \(duplicatesToDelete.count) duplicate structures")
            } catch {
                logger.error("Failed to save after deduplication: \(String(describing: error))")
            }
        } else {
            logger.debug("No duplicate structures found")
        }

        ctx.autosaveEnabled = true
    }

    // MARK: - Manual Maintenance Operations

    /// Report structure returned from repair operations
    struct RepairReport {
        let scannedEdges: Int
        let createdInverseEdges: Int
        let createdMirrorTypes: Int
        let errors: Int
        let detailedLog: String
    }

    /// Destructive reset: delete all data and reseed baseline templates
    /// WARNING: This operation cannot be undone!
    /// - Returns: Success status
    func eraseAndReseed() async throws {
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
            card.cleanupBeforeDeletion(in: self.container.mainContext)
        }
        deleteAll(RelationType.self)
        deleteAll(AppSettings.self)

        try ctx.save()
        logger.info("All data erased successfully.")

        // Clear any in-memory image caches after deletion.
        Card.purgeAllImageCaches()

        // Reset one-time migration keys so they re-run after reseed
        UserDefaults.standard.removeObject(forKey: "didBackfillEdgeCounts_v1")
        UserDefaults.standard.removeObject(forKey: "didDeduplicateCalendarCards_v1")

        // Reseed baseline data
        await runAllStartupChecks()

        logger.info("Reseeding completed.")
    }

    /// Repair incomplete relationships by creating missing inverse edges
    /// Scans all edges and ensures bidirectional relationships exist
    /// - Returns: Detailed repair report
    func repairIncompleteRelationships() async -> RepairReport {
        let ctx = container.mainContext
        ctx.autosaveEnabled = true

        var lines: [String] = []
        lines.append("=== Fix Incomplete Relationships ===")
        lines.append("Date: \(Date().formatted(date: .abbreviated, time: .standard))")
        lines.append("")

        let allEdges = (try? ctx.fetch(FetchDescriptor<CardEdge>())) ?? []
        let scannedEdges = allEdges.count
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
                mirror = ensureMirrorType(for: t, sourceKind: from.kind, targetKind: to.kind, typeCache: &typeCache, createdCount: &createdTypes)
                if !typeCache.contains(where: { $0.code == mirror.code }) {
                    typeCache.append(mirror)
                }
            } else {
                // If original edge has no type, create/use a generic symmetric type
                let forward = "related to"
                let inverse = "related to"
                let code = RelationTypeManager.makeCode(forward: forward, inverse: inverse)
                if let existing = fetchType(code: code) {
                    mirror = existing
                } else {
                    mirror = services.relationTypeManager.ensureRelationType(
                        code: code,
                        forwardLabel: forward,
                        inverseLabel: inverse,
                        sourceKind: nil,
                        targetKind: nil
                    )
                    typeCache.append(mirror)
                    createdTypes += 1
                    lines.append("Created type: \(code) (generic, for missing type)")
                }
            }

            // Create inverse edge using repository
            do {
                _ = try services.edgeRepository.insertSingleEdge(
                    from: to,
                    to: from,
                    type: mirror,
                    note: e.note,
                    createdAt: e.createdAt.addingTimeInterval(0.001)
                )
                createdEdges += 1
                lines.append("Inverse edge created: \(from.kind.singularTitle) \"\(from.name)\" ⇄ \(to.kind.singularTitle) \"\(to.name)\" using type \"\(mirror.code)\"")
            } catch {
                errorCount += 1
                logger.error("Failed to create inverse edge: \(String(describing: error))")
                lines.append("ERROR: Failed to create inverse edge for \(from.name) ⇄ \(to.name): \(String(describing: error))")
            }
        }

        lines.append("")
        lines.append("--- Summary ---")
        lines.append("Scanned: \(scannedEdges)")
        lines.append("Inverse edges created: \(createdEdges)")
        lines.append("Mirror types created: \(createdTypes)")
        lines.append("Errors: \(errorCount)")

        return RepairReport(
            scannedEdges: scannedEdges,
            createdInverseEdges: createdEdges,
            createdMirrorTypes: createdTypes,
            errors: errorCount,
            detailedLog: lines.joined(separator: "\n")
        )
    }

    // MARK: - Private Repair Helpers

    /// Ensure a mirrored type exists (swap source/target kinds and labels)
    /// Used by repair tool to infer correct mirror types
    private func ensureMirrorType(
        for t: RelationType,
        sourceKind: Kinds,
        targetKind: Kinds,
        typeCache: inout [RelationType],
        createdCount: inout Int
    ) -> RelationType {
        // Desired mirror code from swapped labels
        let desiredCode = RelationTypeManager.makeCode(forward: t.inverseLabel, inverse: t.forwardLabel)

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
            codeToUse = RelationTypeManager.makeCode(forward: t.inverseLabel, inverse: t.forwardLabel, suffix: suffix)
        }

        let mirror = RelationType(
            code: codeToUse,
            forwardLabel: t.inverseLabel,
            inverseLabel: t.forwardLabel,
            sourceKind: targetKind,
            targetKind: sourceKind
        )
        container.mainContext.insert(mirror)
        createdCount += 1
        return mirror
    }
}
