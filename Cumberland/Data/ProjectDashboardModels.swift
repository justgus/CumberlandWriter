//
//  ProjectDashboardModels.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-21.
//  Part of Phase 4: Dashboard Integration
//
//  Data models for the Project Dashboard as specified in
//  cumberland_project_dashboard_design_spec.md Section 6.
//
//  These models are implementation-neutral representations of dashboard state,
//  derived from project data via ProjectDashboardService.
//

import Foundation

// MARK: - Root Dashboard Model

/// Root model for the Project Dashboard
struct ProjectDashboardModel {
    let project: Card
    let currentContext: CurrentContext
    let structureBand: StructureBandModel
    let statusGlyph: StatusGlyphModel
    let returnStrip: ReturnStripModel
    let castShelf: CastShelfModel
    let issuesShelf: IssuesShelfModel
    let threadShelf: ThreadShelfModel
}

// MARK: - Current Context

/// Current active scene and its contents
struct CurrentContext {
    let activeChapterID: UUID?
    let activeSceneID: UUID?
    let activeEventID: UUID?
    let sceneContents: [Card] // Characters, artifacts, vehicles in active scene
    let orphanCounts: [OrphanCount]
}

struct OrphanCount {
    let issueType: String
    let count: Int
}

// MARK: - Structure Band

/// Horizontal project-level structure contour
struct StructureBandModel {
    let beats: [StructureBeat]
    let contourSegments: [ContourSegment]
    let activePositionFraction: Double // 0.0 to 1.0
    let continuityBreaks: [ClosedRange<Double>]
    let narrativeArc: NarrativeArc? // Arc for visualization
    let arcSegments: [ArcSegmentData]? // Segments for Tufte-style visualization
}

/// Arc segment data for visualization
struct ArcSegmentData: Identifiable {
    let id = UUID()
    let startPosition: Double // 0.0 to 1.0
    let endPosition: Double // 0.0 to 1.0
    let sceneCount: Int
    let beatLabel: String?
    let beatID: UUID?
}

struct StructureBeat {
    let beatID: UUID
    let label: String
    let normalizedPosition: Double // 0.0 to 1.0
    let isDefined: Bool
    let isMaterialized: Bool // Has scenes attached
    let attachedSceneCount: Int
}

struct ContourSegment {
    let startFraction: Double // 0.0 to 1.0
    let endFraction: Double // 0.0 to 1.0
    let visualWeight: Double // Line thickness multiplier
    let state: ContourState
}

enum ContourState {
    case formed // Solid, materially supported
    case thin // Defined but lightly realized
    case broken // Missing linkage
}

// MARK: - Status Glyph (Three Concentric Rings)

/// Core project status medallion with three rings
struct StatusGlyphModel {
    let timelineRing: TimelineRing
    let chapterRing: ChapterRing
    let sceneRing: SceneRing
    let activeLocus: ActiveLocus
}

// Outer ring - story/event order
struct TimelineRing {
    let beginMarkerAngle: Double // Radians
    let endMarkerAngle: Double // Radians
    let direction: RingDirection
    let events: [TimelineEventNode]
}

enum RingDirection {
    case clockwise
    case counterclockwise
}

struct TimelineEventNode {
    let eventID: UUID
    let normalizedAngle: Double // Radians, 0 to 2π
    let isActive: Bool
    let isMajor: Bool
}

// Middle ring - chapter formation
struct ChapterRing {
    let spans: [ChapterSpan]
}

struct ChapterSpan {
    let chapterID: UUID
    let startAngle: Double // Radians
    let endAngle: Double // Radians
    let state: GlyphSpanState
}

// Inner ring - scene realization
struct SceneRing {
    let spans: [SceneSpan]
}

struct SceneSpan {
    let sceneID: UUID
    let startAngle: Double // Radians
    let endAngle: Double // Radians
    let state: GlyphSpanState
    let isOrphanSpill: Bool
}

enum GlyphSpanState {
    case formed // Present and materially formed
    case thinDefined // Defined but thin/placeholder
    case missing // Absent or broken
}

struct ActiveLocus {
    let eventID: UUID?
    let chapterID: UUID?
    let sceneID: UUID?
    let eventAngle: Double? // Radians
    let chapterSpan: ClosedRange<Double>? // Radians
    let sceneSpan: ClosedRange<Double>? // Radians
}

// MARK: - Return Strip

/// Last / Resume / Next navigation nodes
struct ReturnStripModel {
    let lastNode: ReturnNode?
    let resumeNode: ReturnNode
    let nextNode: ReturnNode?
}

struct ReturnNode {
    let targetID: UUID
    let targetType: ReturnTargetType
    let title: String
    let subtitle: String
    let excerpt: String // Last few words typed
    let contextTokens: [ContextToken]
}

enum ReturnTargetType {
    case scene
    case chapter
    case structureBeat
}

struct ContextToken {
    let tokenType: ContextTokenType
    let value: String
}

enum ContextTokenType {
    case linkedEvent
    case continuityWarning
    case noteAttached
    case unresolvedCitation
    case povIndicator
}

// MARK: - Cast Shelf

/// Project-level character roster
struct CastShelfModel {
    let characters: [CastCharacter]
    let summaryText: String // e.g., "12 characters"
}

struct CastCharacter {
    let characterID: UUID
    let displayLabel: String
    let thumbnailData: Data?
}

// MARK: - Issues Shelf

/// Actionable project problems
struct IssuesShelfModel {
    let issues: [ProjectIssue]
}

struct ProjectIssue: Identifiable {
    let id: UUID
    let issueType: IssueType
    let displayText: String
    let severity: IssueSeverity
    let linkedTargets: [UUID] // Affected card IDs
    let resolutionActions: [String] // Action labels
}

enum IssueType {
    case orphanedScenes
    case orphanedChapters
    case continuityGap
    case unresolvedCitation
    case unassignedCard
}

enum IssueSeverity {
    case info
    case warning
    case error
}

// MARK: - Thread Shelf

/// Narrative thread tracking (future implementation)
struct ThreadShelfModel {
    let threads: [NarrativeThread]
}

struct NarrativeThread: Identifiable {
    let id: UUID
    let label: String
    let linkedSceneIDs: [UUID]
    let linkedEventIDs: [UUID]
    let linkedCardIDs: [UUID]
    let weight: Double // Visual prominence
}
