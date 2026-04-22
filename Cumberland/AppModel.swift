//
//  AppModel.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/10/25.
//
//  Observable app-wide state model. Tracks visionOS immersive space state
//  (open/closed/transitioning) and card editor window requests for spatial
//  window management on visionOS.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    #if os(visionOS)
    /// Tracks card editor presentation for visionOS window management
    /// This allows us to open card editors in separate floating windows
    struct CardEditorRequest: Identifiable, Hashable, Codable {
        let id: UUID
        enum Mode: Hashable, Codable {
            case create(kind: Kinds)
            case edit(cardID: UUID)
        }
        let mode: Mode

        init(mode: Mode) {
            self.id = UUID()
            self.mode = mode
        }
    }
    var pendingCardEditorRequest: CardEditorRequest?
    #endif

    #if os(macOS) || os(visionOS)
    /// Tracks temporal editor presentation for macOS and visionOS window management
    /// This resolves DR-0061: Sheet rendering issues on macOS
    struct TemporalEditorRequest: Identifiable, Hashable, Codable {
        let id: UUID
        let sceneID: UUID
        let timelineID: UUID

        init(sceneID: UUID, timelineID: UUID) {
            self.id = UUID()
            self.sceneID = sceneID
            self.timelineID = timelineID
        }
    }
    var pendingTemporalEditorRequest: TemporalEditorRequest?

    /// Request to open a timeline view window
    /// Phase 6: Timeline Integration - Manuscript → Timeline navigation
    struct TimelineViewRequest: Identifiable, Hashable, Codable {
        let id: UUID
        let timelineID: UUID
        let focusSceneID: UUID?

        init(timelineID: UUID, focusSceneID: UUID? = nil) {
            self.id = UUID()
            self.timelineID = timelineID
            self.focusSceneID = focusSceneID
        }
    }

    /// Request to open a manuscript view window
    /// Phase 6: Timeline Integration - Timeline → Manuscript navigation
    struct ManuscriptViewRequest: Identifiable, Hashable, Codable {
        let id: UUID
        let projectID: UUID
        let focusSceneID: UUID?

        init(projectID: UUID, focusSceneID: UUID? = nil) {
            self.id = UUID()
            self.projectID = projectID
            self.focusSceneID = focusSceneID
        }
    }
    #endif
}
