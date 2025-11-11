//
//  AppModel.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/10/25.
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
}
