//
//  ManuscriptAssembler.swift
//  Cumberland
//
//  Assembles manuscript content from a project's chapters and scenes in manuscript order.
//  Also builds Chicago-style footnotes and bibliography for a project card by
//  traversing its incoming card edges to collect linked content cards and
//  their citations. Returns ordered footnote strings and a deduplicated
//  bibliography suitable for export or display.
//
//  Part of the ProjectWriter system - provides manuscript assembly for the
//  ManuscriptWritingSurfaceView.
//

import Foundation
import SwiftData
import Combine

/// Configuration for manuscript assembly
struct AssemblyOptions: Sendable {
    /// Scene separator (e.g., "* * *", "# # #", or custom)
    let sceneSeparator: String

    /// Include chapter headings
    let includeChapterHeadings: Bool

    /// Chapter heading format (e.g., "Chapter {number}: {name}")
    let chapterHeadingFormat: String

    /// Include scene headings
    let includeSceneHeadings: Bool

    /// Scene heading format (e.g., "Scene {number}")
    let sceneHeadingFormat: String

    /// Number of blank lines after chapter heading
    let chapterHeadingSpacing: Int

    /// Number of blank lines after scene separator
    let sceneSeparatorSpacing: Int

    /// Include orphaned scenes at end
    let includeOrphanedScenes: Bool

    /// Orphaned scenes section heading
    let orphanedSectionHeading: String

    nonisolated init(
        sceneSeparator: String = "* * *",
        includeChapterHeadings: Bool = true,
        chapterHeadingFormat: String = "Chapter {number}: {name}",
        includeSceneHeadings: Bool = false,
        sceneHeadingFormat: String = "Scene {number}",
        chapterHeadingSpacing: Int = 2,
        sceneSeparatorSpacing: Int = 2,
        includeOrphanedScenes: Bool = true,
        orphanedSectionHeading: String = "Unorganized Scenes"
    ) {
        self.sceneSeparator = sceneSeparator
        self.includeChapterHeadings = includeChapterHeadings
        self.chapterHeadingFormat = chapterHeadingFormat
        self.includeSceneHeadings = includeSceneHeadings
        self.sceneHeadingFormat = sceneHeadingFormat
        self.chapterHeadingSpacing = chapterHeadingSpacing
        self.sceneSeparatorSpacing = sceneSeparatorSpacing
        self.includeOrphanedScenes = includeOrphanedScenes
        self.orphanedSectionHeading = orphanedSectionHeading
    }

    static let `default` = AssemblyOptions()
}

@MainActor
struct ManuscriptAssembler {
    // Build footnotes and bibliography (Chicago-like) for a project
    static func assemble(for project: Card, in context: ModelContext) -> (footnotes: [String], bibliography: [String]) {
        // Use inverse relationship instead of a fetch predicate
        let edges: [CardEdge] = project.incomingEdges ?? []

        // Collect non-nil "from" cards and deduplicate by their stable UUID
        let fromCards: [Card] = edges.compactMap { $0.from }
        var seenCardIDs = Set<UUID>()
        let contentCards: [Card] = fromCards.filter { seenCardIDs.insert($0.id).inserted }

        // Collect citations in first-occurrence order
        var footnotes: [String] = []
        var sourceIndex: [UUID: Int] = [:] // first occurrence index for source id
        var bibliographySet: Set<UUID> = []
        var bibliography: [String] = []

        for card in contentCards {
            // Use inverse relationship instead of a fetch predicate; sort in-memory
            let cites: [Citation] = (card.citations ?? []).sorted { $0.createdAt < $1.createdAt }

            for cite in cites {
                // Ensure we have a source
                guard let source = cite.source else { continue }

                // Assign a footnote number by first occurrence of the source
                if sourceIndex[source.id] == nil {
                    sourceIndex[source.id] = footnotes.count + 1
                }
                let note = chicagoFootnote(for: cite, source: source)
                footnotes.append(note)

                if !bibliographySet.contains(source.id) {
                    bibliographySet.insert(source.id)
                    bibliography.append(source.chicagoBibliography)
                }
            }
        }

        return (footnotes, bibliography)
    }

    private static func chicagoFootnote(for c: Citation, source: Source) -> String {
        // Simple Chicago-like footnote
        var parts: [String] = []
        parts.append(source.chicagoShort)
        if !c.locator.isEmpty { parts.append(c.locator) }
        if !c.excerpt.isEmpty { parts.append("\"\(c.excerpt)\"") }
        if let note = c.contextNote, !note.isEmpty { parts.append(note) }
        return parts.joined(separator: ", ")
    }

    // MARK: - Manuscript Assembly

    /// Assembled manuscript result
    struct ManuscriptResult {
        /// The full manuscript text
        var text: String

        /// Chapter metadata (for navigation)
        var chapters: [ChapterInfo]

        /// Scene metadata (for navigation and tracking)
        var scenes: [SceneInfo]

        /// Orphaned scenes (if any)
        var orphanedScenes: [SceneInfo]
    }

    struct ChapterInfo {
        var id: UUID
        var name: String
        var number: Int
        var textRange: Range<String.Index>
        var sceneCount: Int
    }

    struct SceneInfo {
        var id: UUID
        var name: String
        var number: Int // Overall scene number in manuscript
        var chapterNumber: Int? // Chapter it belongs to (nil for orphaned)
        var textRange: Range<String.Index>
        var wordCount: Int
    }

    /// Assembles the full manuscript text from a project's chapters and scenes.
    ///
    /// - Parameters:
    ///   - project: The project card to assemble
    ///   - context: The model context for queries
    ///   - options: Assembly options (separator, formatting, etc.)
    /// - Returns: Assembled manuscript result with text and metadata
    static func assembleManuscript(
        for project: Card,
        in context: ModelContext,
        options: AssemblyOptions = AssemblyOptions()
    ) -> ManuscriptResult {
        guard project.kind == .projects else {
            return ManuscriptResult(text: "", chapters: [], scenes: [], orphanedScenes: [])
        }

        let repository = CardRepository(modelContext: context)
        let chapters = repository.fetchChaptersInProject(project)

        var manuscriptText = ""
        var chapterInfos: [ChapterInfo] = []
        var sceneInfos: [SceneInfo] = []
        var overallSceneNumber = 1

        // Assemble chapters in order
        for (chapterIndex, chapter) in chapters.enumerated() {
            let chapterNumber = chapterIndex + 1
            let chapterStartIndex = manuscriptText.endIndex

            // Add chapter heading
            if options.includeChapterHeadings {
                let heading = formatChapterHeading(
                    chapter: chapter,
                    number: chapterNumber,
                    format: options.chapterHeadingFormat
                )
                manuscriptText += heading + "\n"
                manuscriptText += String(repeating: "\n", count: options.chapterHeadingSpacing)
            }

            // Get scenes in this chapter
            let scenes = repository.fetchScenesInChapter(
                chapterID: chapter.id,
                projectID: project.id
            )

            // Assemble scenes in this chapter
            for (sceneIndex, scene) in scenes.enumerated() {
                let sceneStartIndex = manuscriptText.endIndex

                // Add scene heading (optional)
                if options.includeSceneHeadings {
                    let sceneHeading = formatSceneHeading(
                        scene: scene,
                        number: sceneIndex + 1,
                        format: options.sceneHeadingFormat
                    )
                    manuscriptText += sceneHeading + "\n\n"
                }

                // Add scene content
                let sceneText = scene.detailedText
                manuscriptText += sceneText

                let sceneEndIndex = manuscriptText.endIndex

                // Add scene separator (except for last scene in chapter)
                if sceneIndex < scenes.count - 1 {
                    manuscriptText += "\n\n"
                    manuscriptText += options.sceneSeparator
                    manuscriptText += "\n"
                    manuscriptText += String(repeating: "\n", count: options.sceneSeparatorSpacing)
                } else {
                    // Add spacing after last scene in chapter
                    manuscriptText += "\n\n"
                }

                // Record scene metadata
                let wordCount = sceneText.split(separator: " ").count
                sceneInfos.append(SceneInfo(
                    id: scene.id,
                    name: scene.name,
                    number: overallSceneNumber,
                    chapterNumber: chapterNumber,
                    textRange: sceneStartIndex..<sceneEndIndex,
                    wordCount: wordCount
                ))

                overallSceneNumber += 1
            }

            let chapterEndIndex = manuscriptText.endIndex

            // Record chapter metadata
            chapterInfos.append(ChapterInfo(
                id: chapter.id,
                name: chapter.name,
                number: chapterNumber,
                textRange: chapterStartIndex..<chapterEndIndex,
                sceneCount: scenes.count
            ))
        }

        // Handle orphaned scenes
        var orphanedSceneInfos: [SceneInfo] = []
        if options.includeOrphanedScenes {
            let orphanedScenes = repository.fetchOrphanedScenesInProject(project)

            if !orphanedScenes.isEmpty {
                // Add orphaned section heading
                manuscriptText += "\n\n"
                manuscriptText += "# " + options.orphanedSectionHeading + "\n\n"

                for scene in orphanedScenes {
                    let sceneStartIndex = manuscriptText.endIndex

                    // Add scene text
                    let sceneText = scene.detailedText
                    manuscriptText += sceneText
                    manuscriptText += "\n\n"

                    let sceneEndIndex = manuscriptText.endIndex

                    // Record orphaned scene metadata
                    let wordCount = sceneText.split(separator: " ").count
                    orphanedSceneInfos.append(SceneInfo(
                        id: scene.id,
                        name: scene.name,
                        number: overallSceneNumber,
                        chapterNumber: nil,
                        textRange: sceneStartIndex..<sceneEndIndex,
                        wordCount: wordCount
                    ))

                    overallSceneNumber += 1
                }
            }
        }

        return ManuscriptResult(
            text: manuscriptText,
            chapters: chapterInfos,
            scenes: sceneInfos,
            orphanedScenes: orphanedSceneInfos
        )
    }

    /// Format a chapter heading using the template
    private static func formatChapterHeading(chapter: Card, number: Int, format: String) -> String {
        return format
            .replacingOccurrences(of: "{number}", with: "\(number)")
            .replacingOccurrences(of: "{name}", with: chapter.name.isEmpty ? "Untitled" : chapter.name)
    }

    /// Format a scene heading using the template
    private static func formatSceneHeading(scene: Card, number: Int, format: String) -> String {
        return format
            .replacingOccurrences(of: "{number}", with: "\(number)")
            .replacingOccurrences(of: "{name}", with: scene.name.isEmpty ? "Untitled" : scene.name)
    }

    /// Calculate total word count for a manuscript result
    static func wordCount(for result: ManuscriptResult) -> Int {
        return result.scenes.reduce(0) { $0 + $1.wordCount }
            + result.orphanedScenes.reduce(0) { $0 + $1.wordCount }
    }

    /// Calculate chapter word count
    static func wordCount(forChapter chapterID: UUID, in result: ManuscriptResult) -> Int {
        return result.scenes
            .filter { $0.chapterNumber != nil && result.chapters.first(where: { $0.id == chapterID })?.number == $0.chapterNumber }
            .reduce(0) { $0 + $1.wordCount }
    }
}
