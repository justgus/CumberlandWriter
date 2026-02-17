//
//  MultiGestureHandler.swift
//  BoardEngine
//
//  Created by Assistant on 10/31/25.
//
//  Cross-platform simultaneous gesture coordinator for canvas views. Wraps
//  platform-specific magnification, rotation, and pan gesture recognizers
//  (AppKit on macOS, UIKit on iOS) into a unified GestureTarget protocol so
//  MurderBoardView and DrawingCanvasView can handle pan/pinch/tap uniformly.
//

import SwiftUI
import Foundation
import OSLog
import Combine

#if os(macOS)
import AppKit
import Combine
import UniformTypeIdentifiers
#elseif os(iOS) || os(tvOS) || os(visionOS)
import UIKit
import UniformTypeIdentifiers
#endif

// MARK: - Gesture Target Protocol
/***************************************************************************************
 * Generic Architecture
 *
 * Core Components:
 * • MultiGestureHandler: Coordinates gesture events and routing
 * • GestureTarget protocol: For objects that handle gestures
 * • CoordinateSpaceInfo: Manages coordinate transformations
 * • GestureConfiguration: Configurable behavior settings
 *
 * 🔧 Key Features
 *
 * 1. Coordinate Space Aware: The parent view updates coordinate transforms as zoom/pan changes
 * 2. Closure-Based API: Simple ClosureGestureTarget for most use cases
 * 3. Flexible Target System: Register/unregister gesture targets dynamically
 * 4. Hit Testing: Automatically routes gestures to the appropriate targets
 * 5. Transform Management: Handles view-to-world coordinate conversions
 *
 * 🎨 Clean SwiftUI Integration
 *
 * The system provides a simple .multiGesture(handler:) modifier that any view can use:
 * <code>
        ZStack {
         // Your content
        }
        .coordinateSpace(name: "myCanvas")
        .multiGesture(handler: gestureHandler)
    </code>
 ****************************************************************************************/

/// Protocol for objects that can receive gesture events
@MainActor
public protocol GestureTarget: AnyObject {
    var gestureID: UUID { get }
    var worldBounds: CGRect { get }
    func canHandleGesture(_ gesture: GestureType) -> Bool
    func handleGesture(_ gesture: GestureEvent)
    // Note: protocol members are implicitly public
}

/// Extended protocol for targets that can handle drag and drop operations
public protocol DropCapableTarget: GestureTarget {
    /// Returns the accepted uniform type identifiers for drops
    var acceptedDropTypes: [UTType] { get }
    
    /// Called when a drag operation enters the target's bounds
    func dragEntered(with session: DropSession, at location: CGPoint, coordinateSpace: CoordinateSpaceInfo)
    
    /// Called when a drag operation moves within the target's bounds
    func dragUpdated(with session: DropSession, at location: CGPoint, coordinateSpace: CoordinateSpaceInfo) -> DropProposal
    
    /// Called when a drag operation exits the target's bounds
    func dragExited()
    
    /// Called when items are dropped on the target
    func performDrop(with session: DropSession, at location: CGPoint, coordinateSpace: CoordinateSpaceInfo) -> Bool
}

/// Abstraction for drop session to handle platform differences
public protocol DropSession {
    var items: [DropItem] { get }
    func hasItemsConforming(to types: [UTType]) -> Bool
    func canLoadObjects<T>(ofClass objectType: T.Type) -> Bool where T: NSItemProviderReading
}

/// Abstraction for drop items
public protocol DropItem {
    var itemProvider: NSItemProvider { get }
}

/// Drop proposal indicating how the system should respond to the drop
public struct DropProposal: Sendable {
    public enum Operation: Sendable {
        case cancel
        case forbidden
        case copy
        case move
        case generic
    }
    
    public let operation: Operation

    public init(operation: Operation) { self.operation = operation }

    public static let cancel = DropProposal(operation: .cancel)
    public static let copy = DropProposal(operation: .copy)
    public static let move = DropProposal(operation: .move)
    public static let forbidden = DropProposal(operation: .forbidden)
}

// MARK: - Gesture Types and Events

public enum GestureType {
    case tap
    case doubleTap
    case drag
    case rightClick
    case pinch
    case twoFingerPan
}

public enum GestureEvent: CustomStringConvertible {
    case tap(location: CGPoint, coordinateSpace: CoordinateSpaceInfo)
    case doubleTap(location: CGPoint, coordinateSpace: CoordinateSpaceInfo)
    case dragBegan(startLocation: CGPoint, coordinateSpace: CoordinateSpaceInfo)
    case dragChanged(location: CGPoint, translation: CGSize, coordinateSpace: CoordinateSpaceInfo)
    case dragEnded(location: CGPoint, translation: CGSize, velocity: CGSize, coordinateSpace: CoordinateSpaceInfo)
    case rightClick(location: CGPoint, coordinateSpace: CoordinateSpaceInfo)
    case pinchBegan(scale: CGFloat, location: CGPoint, center: CGPoint, coordinateSpace: CoordinateSpaceInfo)
    case pinchChanged(scale: CGFloat, location: CGPoint, center: CGPoint, coordinateSpace: CoordinateSpaceInfo)
    case pinchEnded(scale: CGFloat, location: CGPoint, center: CGPoint, coordinateSpace: CoordinateSpaceInfo)
    case twoFingerPanBegan(location: CGPoint, coordinateSpace: CoordinateSpaceInfo)
    case twoFingerPanChanged(translation: CGSize, location: CGPoint, coordinateSpace: CoordinateSpaceInfo)
    case twoFingerPanEnded(translation: CGSize, velocity: CGSize, location: CGPoint, coordinateSpace: CoordinateSpaceInfo)

    public var description: String {
        switch self {
        case .tap(let p, _): return "tap(\(Int(p.x)), \(Int(p.y)))"
        case .doubleTap(let p, _): return "doubleTap(\(Int(p.x)), \(Int(p.y)))"
        case .dragBegan(let p, _): return "dragBegan(\(Int(p.x)), \(Int(p.y)))"
        case .dragChanged(let p, let t, _): return "dragChanged(\(Int(p.x)), \(Int(p.y)), Δ=\(Int(t.width)),\(Int(t.height)))"
        case .dragEnded(let p, let t, let v, _): return "dragEnded(\(Int(p.x)), \(Int(p.y)), Δ=\(Int(t.width)),\(Int(t.height)), v=\(Int(v.width)),\(Int(v.height)))"
        case .rightClick(let p, _): return "rightClick(\(Int(p.x)), \(Int(p.y)))"
        case .pinchBegan(let s, let p, let c, _): return "pinchBegan(s=\(String(format: "%.2f", s)) @ \(Int(p.x)), \(Int(p.y)) center=\(Int(c.x)),\(Int(c.y)))"
        case .pinchChanged(let s, let p, let c, _): return "pinchChanged(s=\(String(format: "%.2f", s)) @ \(Int(p.x)), \(Int(p.y)) center=\(Int(c.x)),\(Int(c.y)))"
        case .pinchEnded(let s, let p, let c, _): return "pinchEnded(s=\(String(format: "%.2f", s)) @ \(Int(p.x)), \(Int(p.y)) center=\(Int(c.x)),\(Int(c.y)))"
        case .twoFingerPanBegan(let p, _): return "twoFingerPanBegan(\(Int(p.x)), \(Int(p.y)))"
        case .twoFingerPanChanged(let t, let p, _): return "twoFingerPanChanged(Δ=\(Int(t.width)),\(Int(t.height)) @ \(Int(p.x)), \(Int(p.y)))"
        case .twoFingerPanEnded(let t, let v, let p, _): return "twoFingerPanEnded(Δ=\(Int(t.width)),\(Int(t.height)), v=\(Int(v.width)),\(Int(v.height)) @ \(Int(p.x)), \(Int(p.y)))"
        }
    }
}

// MARK: - Coordinate Space Information

public struct CoordinateSpaceInfo {
    public let spaceName: String
    public let transform: CGAffineTransform
    public let zoomScale: CGFloat
    public let panOffset: CGPoint

    public init(spaceName: String, transform: CGAffineTransform, zoomScale: CGFloat, panOffset: CGPoint) {
        self.spaceName = spaceName
        self.transform = transform
        self.zoomScale = zoomScale
        self.panOffset = panOffset
    }

    /// Convert a point from gesture/view space to world space
    /// World ← View: w = (v - T) / S
    public func toWorldSpace(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: (point.x - panOffset.x) / max(zoomScale, .ulpOfOne),
            y: (point.y - panOffset.y) / max(zoomScale, .ulpOfOne)
        )
    }
    
    /// Convert a point from world space to gesture/view space
    /// View ← World: v = w*S + T
    public func fromWorldSpace(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.x * zoomScale + panOffset.x,
            y: point.y * zoomScale + panOffset.y
        )
    }
    
    /// Hit test a world-space rectangle against a gesture-space point
    public func hitTest(point: CGPoint, worldRect: CGRect) -> Bool {
        let worldPoint = toWorldSpace(point)
        return worldRect.contains(worldPoint)
    }
}

// MARK: - Popup System

/// Represents a popup menu item
public struct PopupMenuItem {
    public let id = UUID()
    public let title: String
    public let systemImage: String?
    public let isDestructive: Bool
    public let isDisabled: Bool
    public let action: () -> Void

    public init(title: String, systemImage: String? = nil, isDestructive: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isDestructive = isDestructive
        self.isDisabled = isDisabled
        self.action = action
    }
}

/// Popup menu configuration
public struct PopupMenu {
    public let items: [PopupMenuItem]
    public let position: CGPoint
    public let coordinateSpace: CoordinateSpaceInfo

    public init(items: [PopupMenuItem], position: CGPoint, coordinateSpace: CoordinateSpaceInfo) {
        self.items = items
        self.position = position
        self.coordinateSpace = coordinateSpace
    }
}

// MARK: - Multi-Gesture Handler

@MainActor
public class MultiGestureHandler: ObservableObject {

    // MARK: - Zoom Center Configuration

    public enum ZoomCenterMode {
        case pointer
        case fixedViewPoint(CGPoint)          // in gesture/view space
        case fixedWorldPoint(CGPoint)         // in world space
        case custom((_ lastPointerInView: CGPoint, _ coordinateInfo: CoordinateSpaceInfo) -> CGPoint)
    }
    
    /// Controls how zoom center is determined. Default is `.pointer`.
    public var zoomCenterMode: ZoomCenterMode = .pointer
    
    // MARK: - Popup System
    
    /// Currently active popup menu
    @Published public var activePopup: PopupMenu?
    
    // MARK: - Properties
    
    private var targets: [WeakGestureTarget] = []
    private let coordinateSpace: String
    
    // Drop tracking state
    private var currentDropTarget: DropCapableTarget?
    private var activeDropSession: DropSession?
    
    // Gesture state tracking
    @Published public private(set) var isDragging = false
    @Published public private(set) var isPinching = false
    @Published public private(set) var isTwoFingerPanning = false
    
    private var dragTarget: GestureTarget?
    private var dragStartLocation: CGPoint = .zero
    private var lastTapTime: Date = .distantPast
    private var lastTapLocation: CGPoint = .zero
    private let doubleTapTimeWindow: TimeInterval = 0.3
    private let doubleTapLocationTolerance: CGFloat = 10
    
    // Pointer tracking (gesture/view space)
    private var lastPointerLocation: CGPoint = .zero
    public var currentPointerLocation: CGPoint { lastPointerLocation }
    
    // Platform-specific state
    #if os(macOS)
    private var rightClickMenus: [NSMenu] = []
    #endif

    /// Rects (view coordinate space, origin top-left) where two-finger pan/scroll
    /// events should NOT be interpreted as canvas pans and should pass through
    /// to the SwiftUI view hierarchy instead (e.g. the sidebar ScrollView).
    /// Used on macOS via the NSEvent scroll monitor and on iPadOS for trackpad pans.
    public private(set) var scrollExclusionRects: [CGRect] = []

    // Logging
    #if DEBUG
    public var loggingEnabled: Bool = true
    #else
    public var loggingEnabled: Bool = false
    #endif
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.app", category: "MultiGestureHandler")
    
    // MARK: - Initialization
    
    public init(coordinateSpace: String) {
        self.coordinateSpace = coordinateSpace
        cleanupWeakReferences()
        debug("Initialized with coordinateSpace='\(coordinateSpace)'")
    }
    
    // MARK: - Target Management
    
    public func registerTarget(_ target: GestureTarget) {
        // Remove any existing reference to this target
        targets.removeAll { $0.target?.gestureID == target.gestureID }
        // Add new reference
        targets.append(WeakGestureTarget(target))
        cleanupWeakReferences()
        debug("Registered target id=\(target.gestureID) worldBounds=\(rectString(target.worldBounds))")
    }
    
    public func unregisterTarget(_ target: GestureTarget) {
        targets.removeAll { $0.target?.gestureID == target.gestureID }
        debug("Unregistered target id=\(target.gestureID)")
    }

    // MARK: - Scroll Exclusion Zones (DR-0083)

    /// Sets rects (view coordinate space, origin top-left) where two-finger pan/scroll
    /// events pass through to the native scroll view instead of panning the canvas.
    public func setScrollExclusionRects(_ rects: [CGRect]) {
        scrollExclusionRects = rects
    }

    // MARK: - Mouse Exclusion Zones (bottomZoomStrip / HUD overlays)

    /// Rects (view coordinate space, origin top-left) where left-mouse events should
    /// NOT be processed by the NSEvent monitor and should instead pass through to
    /// SwiftUI controls (e.g. the bottom zoom strip HUD on macOS).
    public private(set) var mouseExclusionRects: [CGRect] = []

    /// Sets rects where left-mouse events pass through to SwiftUI controls.
    public func setMouseExclusionRects(_ rects: [CGRect]) {
        mouseExclusionRects = rects
    }

    private func cleanupWeakReferences() {
        let before = targets.count
        targets.removeAll { $0.target == nil }
        let after = targets.count
        if before != after {
            debug("Cleaned up weak targets: \(before - after) removed, \(after) remaining")
        }
    }
    
    // MARK: - Hit Testing
    
    private func findTarget(at location: CGPoint, coordinateInfo: CoordinateSpaceInfo, for gestureType: GestureType) -> GestureTarget? {
        cleanupWeakReferences()

        // Test targets in reverse order (topmost first)
        for weakTarget in targets.reversed() {
            guard let target = weakTarget.target,
                  target.canHandleGesture(gestureType) else { continue }

            let bounds = target.worldBounds
            let hit = coordinateInfo.hitTest(point: location, worldRect: bounds)

            if hit {
                debug("Hit target id=\(target.gestureID) for \(gestureTypeString(gestureType)) at \(pointString(location))")
                return target
            }
        }
        debug("No target for \(gestureTypeString(gestureType)) at \(pointString(location))")
        return nil
    }
    
    // MARK: - Drop Handling
    
    public func findDropTarget(at location: CGPoint, coordinateInfo: CoordinateSpaceInfo, acceptingTypes: [UTType]) -> DropCapableTarget? {
        cleanupWeakReferences()
        
        // Test targets in reverse order (topmost first)
        for weakTarget in targets.reversed() {
            guard let target = weakTarget.target as? DropCapableTarget,
                  coordinateInfo.hitTest(point: location, worldRect: target.worldBounds),
                  !Set(target.acceptedDropTypes).isDisjoint(with: Set(acceptingTypes)) else { continue }
            debug("Drop hit target id=\(target.gestureID) at \(pointString(location)) accepts=\(typesString(acceptingTypes))")
            return target
        }
        debug("No drop target at \(pointString(location)) for types=\(typesString(acceptingTypes))")
        return nil
    }
    
    public func processDragEntered(at location: CGPoint, session: DropSession, coordinateInfo: CoordinateSpaceInfo) {
        updatePointerLocation(location)
        let typesFromSession = extractTypesFromSession(session)
        let newTarget = findDropTarget(at: location, coordinateInfo: coordinateInfo, acceptingTypes: typesFromSession)
        
        if newTarget !== currentDropTarget {
            if let old = currentDropTarget {
                debug("Drop target switched: \(old.gestureID) -> \(String(describing: newTarget?.gestureID))")
            } else {
                debug("Drop target set: \(String(describing: newTarget?.gestureID))")
            }
            currentDropTarget?.dragExited()
            currentDropTarget = newTarget
            activeDropSession = session
            currentDropTarget?.dragEntered(with: session, at: location, coordinateSpace: coordinateInfo)
        } else {
            debug("Drop entered, target unchanged: \(String(describing: currentDropTarget?.gestureID)) at \(pointString(location))")
        }
    }
    
    public func processDragUpdated(at location: CGPoint, session: DropSession, coordinateInfo: CoordinateSpaceInfo) -> DropProposal {
        updatePointerLocation(location)
        let typesFromSession = extractTypesFromSession(session)
        let targetAtLocation = findDropTarget(at: location, coordinateInfo: coordinateInfo, acceptingTypes: typesFromSession)
        
        if targetAtLocation !== currentDropTarget {
            debug("Drop target changed during update to \(String(describing: targetAtLocation?.gestureID)) at \(pointString(location))")
            currentDropTarget?.dragExited()
            currentDropTarget = targetAtLocation
            activeDropSession = session
            currentDropTarget?.dragEntered(with: session, at: location, coordinateSpace: coordinateInfo)
        }
        
        let proposal = currentDropTarget?.dragUpdated(with: session, at: location, coordinateSpace: coordinateInfo) ?? .forbidden
        debug("Drop updated at \(pointString(location)) -> proposal=\(proposal.operation)")
        return proposal
    }
    
    public func processDragExited() {
        debug("Drop exited; clearing current drop target")
        currentDropTarget?.dragExited()
        currentDropTarget = nil
        activeDropSession = nil
    }
    
    public func processPerformDrop(at location: CGPoint, session: DropSession, coordinateInfo: CoordinateSpaceInfo) -> Bool {
        updatePointerLocation(location)
        defer {
            debug("Drop finalized; clearing state")
            currentDropTarget?.dragExited()
            currentDropTarget = nil
            activeDropSession = nil
        }
        let typesFromSession = extractTypesFromSession(session)
        let target = findDropTarget(at: location, coordinateInfo: coordinateInfo, acceptingTypes: typesFromSession)
        let result = target?.performDrop(with: session, at: location, coordinateSpace: coordinateInfo) ?? false
        debug("Perform drop at \(pointString(location)) on target \(String(describing: target?.gestureID)) -> \(result)")
        return result
    }
    
    private func extractTypesFromSession(_ session: DropSession) -> [UTType] {
        // Placeholder: expand as needed
        return [.text, .image, .fileURL]
    }
    
    // MARK: - Popup Management
    
    /// Show a popup menu at the specified location
    public func showPopup(_ menu: PopupMenu) {
        activePopup = menu
        debug("Showing popup with \(menu.items.count) items at \(pointString(menu.position))")
    }
    
    /// Hide any active popup
    public func hidePopup() {
        if activePopup != nil {
            debug("Hiding popup")
            activePopup = nil
        }
    }
    
    /// Check if a point is inside the popup bounds
    public func hitTestPopup(at location: CGPoint) -> Bool {
        guard let popup = activePopup else { return false }
        // Simple hit test - could be made more sophisticated with actual popup bounds
        let popupBounds = CGRect(x: popup.position.x, y: popup.position.y, width: 200, height: CGFloat(popup.items.count * 44))
        return popupBounds.contains(location)
    }

    /// Handle a click on the popup at the given location. Returns true if an item was triggered.
    public func handlePopupClick(at location: CGPoint) -> Bool {
        guard let popup = activePopup else { return false }

        // Calculate which item was clicked based on Y offset from popup position
        let itemHeight: CGFloat = 44
        let yOffset = location.y - popup.position.y

        guard yOffset >= 0 else { return false }

        let itemIndex = Int(yOffset / itemHeight)
        guard itemIndex >= 0 && itemIndex < popup.items.count else { return false }

        let item = popup.items[itemIndex]

        if !item.isDisabled {
            hidePopup()
            item.action()
            return true
        }

        return false
    }

    // MARK: - SwiftUI Integration
    
    public func createGestureModifier(coordinateInfo: CoordinateSpaceInfo) -> some ViewModifier {
        return MultiGestureModifier(handler: self, coordinateInfo: coordinateInfo)
    }
    
    // MARK: - Pointer tracking and zoom center
    
    public func updatePointerLocation(_ location: CGPoint) {
        lastPointerLocation = location
    }
    
    public func computeZoomCenter(fallbackLocation: CGPoint, coordinateInfo: CoordinateSpaceInfo) -> CGPoint {
        switch zoomCenterMode {
        case .pointer:
            // Prefer the last known pointer; if we don't have one yet, use the provided fallback.
            return (lastPointerLocation == .zero) ? fallbackLocation : lastPointerLocation
        case .fixedViewPoint(let p):
            return p
        case .fixedWorldPoint(let w):
            return coordinateInfo.fromWorldSpace(w)
        case .custom(let provider):
            return provider(lastPointerLocation, coordinateInfo)
        }
    }
}

// MARK: - Gesture Processing

extension MultiGestureHandler {
    
    public func processTap(location: CGPoint, coordinateInfo: CoordinateSpaceInfo) {
        updatePointerLocation(location)

        // Check if tap is on popup first
        if activePopup != nil {
            if hitTestPopup(at: location) {
                // Let popup handle the tap (will be handled by popup overlay)
                debug("Tap on popup at \(pointString(location))")
                return
            } else {
                // Tap outside popup - hide it
                hidePopup()
                debug("Tap outside popup - hiding popup")
                return
            }
        }
        
        let now = Date()
        let timeSinceLastTap = now.timeIntervalSince(lastTapTime)
        let distanceFromLastTap = hypot(location.x - lastTapLocation.x, location.y - lastTapLocation.y)
        debug("Tap at \(pointString(location)) Δt=\(String(format: "%.3f", timeSinceLastTap)) d=\(String(format: "%.1f", distanceFromLastTap))")
        
        // Check for double tap
        if timeSinceLastTap < doubleTapTimeWindow && distanceFromLastTap < doubleTapLocationTolerance {
            // Double tap
            if let target = findTarget(at: location, coordinateInfo: coordinateInfo, for: .doubleTap) {
                let event: GestureEvent = .doubleTap(location: location, coordinateSpace: coordinateInfo)
                debug("Dispatch \(event.description) to target id=\(target.gestureID)")
                target.handleGesture(event)
            }
            lastTapTime = .distantPast // Reset to prevent triple tap
        } else {
            // Single tap
            if let target = findTarget(at: location, coordinateInfo: coordinateInfo, for: .tap) {
                let event: GestureEvent = .tap(location: location, coordinateSpace: coordinateInfo)
                debug("Dispatch \(event.description) to target id=\(target.gestureID)")
                target.handleGesture(event)
            }
            lastTapTime = now
            lastTapLocation = location
        }
    }
    
    public func processDragBegan(location: CGPoint, coordinateInfo: CoordinateSpaceInfo) {
        updatePointerLocation(location)
        
        guard !isPinching && !isTwoFingerPanning else {
            debug("Drag begin ignored; pinching=\(isPinching) twoFingerPanning=\(isTwoFingerPanning)")
            return
        }

        dragTarget = findTarget(at: location, coordinateInfo: coordinateInfo, for: .drag)
        dragStartLocation = location
        isDragging = true
        
        let event: GestureEvent = .dragBegan(startLocation: location, coordinateSpace: coordinateInfo)
        if let dragTarget {
            debug("Dispatch \(event.description) to target id=\(dragTarget.gestureID)")
            dragTarget.handleGesture(event)
        } else {
            debug("No drag target to dispatch \(event.description)")
        }
    }
    
    public func processDragChanged(location: CGPoint, coordinateInfo: CoordinateSpaceInfo) {
        updatePointerLocation(location)
        
        guard isDragging, !isPinching, !isTwoFingerPanning else {
            debug("Drag change ignored; dragging=\(isDragging) pinching=\(isPinching) twoFingerPanning=\(isTwoFingerPanning)")
            return
        }
        
        let translation = CGSize(
            width: location.x - dragStartLocation.x,
            height: location.y - dragStartLocation.y
        )
        
        let event: GestureEvent = .dragChanged(location: location, translation: translation, coordinateSpace: coordinateInfo)
        if let dragTarget {
            debug("Dispatch \(event.description) to target id=\(dragTarget.gestureID)")
            dragTarget.handleGesture(event)
        } else {
            debug("No drag target to dispatch \(event.description)")
        }
    }
    
    public func processDragEnded(location: CGPoint, velocity: CGSize, coordinateInfo: CoordinateSpaceInfo) {
        updatePointerLocation(location)

        guard isDragging else {
            debug("Drag end ignored; not dragging")
            return
        }

        let translation = CGSize(
            width: location.x - dragStartLocation.x,
            height: location.y - dragStartLocation.y
        )

        let event: GestureEvent = .dragEnded(location: location, translation: translation, velocity: velocity, coordinateSpace: coordinateInfo)
        if let dragTarget {
            debug("Dispatch \(event.description) to target id=\(dragTarget.gestureID)")
            dragTarget.handleGesture(event)
        } else {
            // No drag target - if minimal movement, treat as a tap on the canvas
            let dragDistance = hypot(translation.width, translation.height)
            if dragDistance < 5 {
                debug("No drag target with minimal movement - treating as tap")
                // Reset drag state first, then process tap
                isDragging = false
                dragTarget = nil
                dragStartLocation = .zero
                processTap(location: location, coordinateInfo: coordinateInfo)
                return
            } else {
                debug("No drag target to dispatch \(event.description)")
            }
        }

        // Reset drag state
        isDragging = false
        dragTarget = nil
        dragStartLocation = .zero
    }
    
    public func processRightClick(location: CGPoint, coordinateInfo: CoordinateSpaceInfo) -> Bool {
        updatePointerLocation(location)
        debug("Right click at \(pointString(location))")
        if let target = findTarget(at: location, coordinateInfo: coordinateInfo, for: .rightClick) {
            let event: GestureEvent = .rightClick(location: location, coordinateSpace: coordinateInfo)
            debug("Dispatch \(event.description) to target id=\(target.gestureID)")
            target.handleGesture(event)
            return true
        }
        return false
    }
    
    public func processPinchBegan(scale: CGFloat, location: CGPoint, coordinateInfo: CoordinateSpaceInfo) {
        isPinching = true
        updatePointerLocation(location)
        let center = computeZoomCenter(fallbackLocation: location, coordinateInfo: coordinateInfo)
        debug("Pinch began scale=\(String(format: "%.3f", scale)) at \(pointString(location)) center=\(pointString(center))")
        
        if let target = findTarget(at: location, coordinateInfo: coordinateInfo, for: .pinch) {
            let event: GestureEvent = .pinchBegan(scale: scale, location: location, center: center, coordinateSpace: coordinateInfo)
            debug("Dispatch \(event.description) to target id=\(target.gestureID)")
            target.handleGesture(event)
        }
    }
    
    public func processPinchChanged(scale: CGFloat, location: CGPoint, coordinateInfo: CoordinateSpaceInfo) {
        updatePointerLocation(location)
        guard isPinching else {
            debug("Pinch change ignored; not pinching")
            return
        }
        
        let center = computeZoomCenter(fallbackLocation: location, coordinateInfo: coordinateInfo)
        if let target = findTarget(at: location, coordinateInfo: coordinateInfo, for: .pinch) {
            let event: GestureEvent = .pinchChanged(scale: scale, location: location, center: center, coordinateSpace: coordinateInfo)
            debug("Dispatch \(event.description) to target id=\(target.gestureID)")
            target.handleGesture(event)
        }
    }
    
    public func processPinchEnded(scale: CGFloat, location: CGPoint, coordinateInfo: CoordinateSpaceInfo) {
        updatePointerLocation(location)
        guard isPinching else {
            debug("Pinch end ignored; not pinching")
            return
        }
        
        let center = computeZoomCenter(fallbackLocation: location, coordinateInfo: coordinateInfo)
        if let target = findTarget(at: location, coordinateInfo: coordinateInfo, for: .pinch) {
            let event: GestureEvent = .pinchEnded(scale: scale, location: location, center: center, coordinateSpace: coordinateInfo)
            debug("Dispatch \(event.description) to target id=\(target.gestureID)")
            target.handleGesture(event)
        }
        
        isPinching = false
        debug("Pinch ended")
    }
    
    public func processTwoFingerPanBegan(location: CGPoint, coordinateInfo: CoordinateSpaceInfo) {
        isTwoFingerPanning = true
        updatePointerLocation(location)
        debug("Two-finger pan began at \(pointString(location))")
        
        if let target = findTarget(at: location, coordinateInfo: coordinateInfo, for: .twoFingerPan) {
            let event: GestureEvent = .twoFingerPanBegan(location: location, coordinateSpace: coordinateInfo)
            debug("Dispatch \(event.description) to target id=\(target.gestureID)")
            target.handleGesture(event)
        }
    }
    
    public func processTwoFingerPanChanged(translation: CGSize, location: CGPoint, coordinateInfo: CoordinateSpaceInfo) {
        updatePointerLocation(location)
        guard isTwoFingerPanning else {
            debug("Two-finger pan change ignored; not panning")
            return
        }
        
        if let target = findTarget(at: location, coordinateInfo: coordinateInfo, for: .twoFingerPan) {
            let event: GestureEvent = .twoFingerPanChanged(translation: translation, location: location, coordinateSpace: coordinateInfo)
            debug("Dispatch \(event.description) to target id=\(target.gestureID)")
            target.handleGesture(event)
        }
    }
    
    public func processTwoFingerPanEnded(translation: CGSize, velocity: CGSize, location: CGPoint, coordinateInfo: CoordinateSpaceInfo) {
        updatePointerLocation(location)
        guard isTwoFingerPanning else {
            debug("Two-finger pan end ignored; not panning")
            return
        }
        
        if let target = findTarget(at: location, coordinateInfo: coordinateInfo, for: .twoFingerPan) {
            let event: GestureEvent = .twoFingerPanEnded(translation: translation, velocity: velocity, location: location, coordinateSpace: coordinateInfo)
            debug("Dispatch \(event.description) to target id=\(target.gestureID)")
            target.handleGesture(event)
        }
        
        isTwoFingerPanning = false
        debug("Two-finger pan ended")
    }
}

// MARK: - SwiftUI View Modifier

private struct MultiGestureModifier: ViewModifier {
    let handler: MultiGestureHandler
    let coordinateInfo: CoordinateSpaceInfo
    
    @State private var pinchLocation: CGPoint = .zero
    
    func body(content: Content) -> some View {
        content
            .coordinateSpace(name: coordinateInfo.spaceName)
            // Seed a sensible default pointer location: the view’s geometric center.
            // This ensures pointer-centered zoom has a valid center before the first move.
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .allowsHitTesting(false) // IMPORTANT: do not intercept right-click/tap hit-testing
                        .onAppear {
                            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                            handler.updatePointerLocation(center)
                        }
                        .onChange(of: geo.size) { _, newSize in
                            let center = CGPoint(x: newSize.width / 2, y: newSize.height / 2)
                            // Only update if we haven't had a real pointer yet (still zero) to avoid fighting live updates.
                            if handler.currentPointerLocation == .zero {
                                handler.updatePointerLocation(center)
                            }
                        }
                }
            )
            .simultaneousGesture(
                // Tap gesture
                SpatialTapGesture()
                    .onEnded { value in
                        handler.processTap(location: value.location, coordinateInfo: coordinateInfo)
                    }
            )
            .simultaneousGesture(
                // Drag gesture
                DragGesture(minimumDistance: 3, coordinateSpace: .named(coordinateInfo.spaceName))
                    .onChanged { value in
                        if !handler.isDragging {
                            handler.processDragBegan(location: value.startLocation, coordinateInfo: coordinateInfo)
                        }
                        handler.processDragChanged(location: value.location, coordinateInfo: coordinateInfo)
                    }
                    .onEnded { value in
                        let velocity = CGSize(width: value.velocity.width, height: value.velocity.height)
                        handler.processDragEnded(location: value.location, velocity: velocity, coordinateInfo: coordinateInfo)
                    }
            )
            #if os(macOS) || os(tvOS) || os(visionOS)
            .simultaneousGesture(
                // Magnification (pinch) gesture (SwiftUI path; iOS uses UIKit recognizer for center)
                MagnificationGesture()
                    .onChanged { value in
                        let loc = handler.currentPointerLocation
                        pinchLocation = loc
                        if !handler.isPinching {
                            handler.processPinchBegan(scale: value, location: loc, coordinateInfo: coordinateInfo)
                        } else {
                            handler.processPinchChanged(scale: value, location: loc, coordinateInfo: coordinateInfo)
                        }
                    }
                    .onEnded { value in
                        let loc = handler.currentPointerLocation
                        handler.processPinchEnded(scale: value, location: loc, coordinateInfo: coordinateInfo)
                    }
            )
            #endif
            // Add drop handling support
            .onDrop(of: [.text, .image, .fileURL], delegate: MultiGestureDropDelegate(handler: handler, coordinateInfo: coordinateInfo))
            .overlay(
                // Platform-specific gesture overlays
                PlatformGestureOverlay(handler: handler, coordinateInfo: coordinateInfo)
            )
            // Popup overlay - rendered on top of everything
            .overlay(
                PopupOverlay(handler: handler)
            )
    }
}

// MARK: - SwiftUI Drop Delegate

private struct MultiGestureDropDelegate: DropDelegate {
    let handler: MultiGestureHandler
    let coordinateInfo: CoordinateSpaceInfo
    
    func dropEntered(info: DropInfo) {
        let session = SwiftUIDropSession(info: info)
        handler.processDragEntered(at: info.location, session: session, coordinateInfo: coordinateInfo)
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        let session = SwiftUIDropSession(info: info)
        let proposal = handler.processDragUpdated(at: info.location, session: session, coordinateInfo: coordinateInfo)
        
        switch proposal.operation {
        case .cancel:
            return DropProposal(operation: .cancel)
        case .forbidden:
            return DropProposal(operation: .forbidden)
        case .copy:
            return DropProposal(operation: .copy)
        case .move:
            return DropProposal(operation: .move)
        case .generic:
            return DropProposal(operation: .generic)
        }
    }
    
    func dropExited(info: DropInfo) {
        handler.processDragExited()
    }
    
    func performDrop(info: DropInfo) -> Bool {
        let session = SwiftUIDropSession(info: info)
        return handler.processPerformDrop(at: info.location, session: session, coordinateInfo: coordinateInfo)
    }
}

// MARK: - SwiftUI Drop Session Implementation

private struct SwiftUIDropSession: DropSession {
    private let dropInfo: DropInfo
    
    init(info: DropInfo) {
        self.dropInfo = info
    }
    
    var items: [DropItem] {
        dropInfo.itemProviders(for: [.text, .image, .fileURL]).map { SwiftUIDropItem(provider: $0) }
    }
    
    func hasItemsConforming(to types: [UTType]) -> Bool {
        dropInfo.hasItemsConforming(to: types.map(\.identifier))
    }
    
    func canLoadObjects<T>(ofClass objectType: T.Type) -> Bool where T: NSItemProviderReading {
        dropInfo.itemProviders(for: [.text, .image, .fileURL]).contains { $0.canLoadObject(ofClass: objectType) }
    }
}

private struct SwiftUIDropItem: DropItem {
    let itemProvider: NSItemProvider
    
    init(provider: NSItemProvider) {
        self.itemProvider = provider
    }
}

// MARK: - Platform-Specific Gesture Overlay

private struct PlatformGestureOverlay: View {
    let handler: MultiGestureHandler
    let coordinateInfo: CoordinateSpaceInfo
    
    var body: some View {
        #if os(macOS)
        MacOSGestureOverlay(handler: handler, coordinateInfo: coordinateInfo)
        #elseif os(iOS) || os(tvOS) || os(visionOS)
        IOSGestureOverlay(handler: handler, coordinateInfo: coordinateInfo)
        #else
        Color.clear
        #endif
    }
}

#if os(macOS)
private struct MacOSGestureOverlay: NSViewRepresentable {
    let handler: MultiGestureHandler
    let coordinateInfo: CoordinateSpaceInfo
    
    func makeNSView(context: Context) -> GestureOverlayView {
        let view = GestureOverlayView()
        view.handler = handler
        view.coordinateInfo = coordinateInfo
        return view
    }
    
    func updateNSView(_ nsView: GestureOverlayView, context: Context) {
        nsView.handler = handler
        nsView.coordinateInfo = coordinateInfo
    }
    
    final class GestureOverlayView: NSView {
        var handler: MultiGestureHandler?
        var coordinateInfo: CoordinateSpaceInfo?
        
        // Local event monitors (so we don't need to win hit-testing)
        private var rightClickMonitor: Any?
        private var scrollMonitor: Any?
        private var mouseMoveMonitor: Any?
        private var leftMouseMonitor: Any?  // Added: NSEvent-based left mouse handling for macOS
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            layer?.backgroundColor = NSColor.clear.cgColor
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        deinit {
            // NSView deallocation always occurs on the main thread, so it is safe
            // to assume main-actor isolation here rather than scheduling a Task
            // (which would race against the object's lifetime).
            MainActor.assumeIsolated {
                removeMonitors()
            }
        }
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            // Recreate monitors when the view gets a window
            removeMonitors()
            addMonitors()
        }
        
        override func viewWillMove(toWindow newWindow: NSWindow?) {
            if newWindow == nil {
                removeMonitors()
            }
            super.viewWillMove(toWindow: newWindow)
        }
        
        // Critical: do not intercept mouse events; let SwiftUI content underneath get them.
        override func hitTest(_ point: NSPoint) -> NSView? {
            return nil
        }
        
        private func addMonitors() {
            guard let window = self.window else { return }
            
            // Left mouse monitor for drag and tap gestures
            // Note: SwiftUI's DragGesture via .simultaneousGesture() does not receive events on macOS
            // when .dropDestination() is present on an inner view. Using NSEvent monitor instead.
            leftMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .leftMouseDragged]) { [weak self] event in
                guard let self,
                      let handler = self.handler,
                      let coordinateInfo = self.coordinateInfo,
                      event.window === window else { return event }

                let pInView = self.convert(event.locationInWindow, from: nil)
                let cgLocation = CGPoint(x: pInView.x, y: self.bounds.height - pInView.y)

                guard self.bounds.contains(pInView) else { return event }

                // Pass through events over HUD overlays (e.g. bottom zoom strip)
                if handler.mouseExclusionRects.contains(where: { $0.contains(cgLocation) }) {
                    return event
                }

                handler.updatePointerLocation(cgLocation)

                // Check if there's an active popup - if so, handle specially
                if let _ = handler.activePopup {
                    let isInsidePopup = handler.hitTestPopup(at: cgLocation)
                    if event.type == .leftMouseUp {
                        if isInsidePopup {
                            // Click inside popup - directly handle the item click
                            _ = handler.handlePopupClick(at: cgLocation)
                        } else {
                            // Click outside popup - hide popup
                            handler.hidePopup()
                        }
                    }
                    // During popup, consume all left mouse events to prevent drag/tap processing
                    return event
                }

                switch event.type {
                case .leftMouseDown:
                    // Start drag gesture
                    handler.processDragBegan(location: cgLocation, coordinateInfo: coordinateInfo)

                case .leftMouseDragged:
                    // Continue drag if active
                    if handler.isDragging {
                        handler.processDragChanged(location: cgLocation, coordinateInfo: coordinateInfo)
                    }

                case .leftMouseUp:
                    // End drag or process as tap
                    if handler.isDragging {
                        handler.processDragEnded(location: cgLocation, velocity: .zero, coordinateInfo: coordinateInfo)
                    } else {
                        // No significant drag movement - treat as tap
                        handler.processTap(location: cgLocation, coordinateInfo: coordinateInfo)
                    }

                default:
                    break
                }

                return event
            }

            // Right-click (secondary button) monitor
            rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]) { [weak self] event in
                guard let self,
                      let handler = self.handler,
                      let coordinateInfo = self.coordinateInfo,
                      event.window === window else { return event }
                
                // Convert window location to our view's coordinate space and flip Y to match SwiftUI coordinates used elsewhere.
                let pInView = self.convert(event.locationInWindow, from: nil)
                let cgLocation = CGPoint(x: pInView.x, y: self.bounds.height - pInView.y)
                
                // Only handle if pointer is inside our overlay's bounds
                if self.bounds.contains(pInView) {
                    handler.updatePointerLocation(cgLocation)
                    let foundTarget = handler.processRightClick(location: cgLocation, coordinateInfo: coordinateInfo)
                    // Only return the event if we found a target, otherwise consume it to prevent unwanted context menus
                    return foundTarget ? event : nil
                }
                // Return the event so default behaviors (e.g., context menus) can proceed if desired.
                return event
            }
            
            // Trackpad two-finger scroll monitor for panning
            scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
                guard let self,
                      let handler = self.handler,
                      let coordinateInfo = self.coordinateInfo,
                      event.window === window else { return event }
                
                // Only handle precise (trackpad) deltas
                guard event.hasPreciseScrollingDeltas else { return event }

                let pInView = self.convert(event.locationInWindow, from: nil)
                let cgLocation = CGPoint(x: pInView.x, y: self.bounds.height - pInView.y)
                guard self.bounds.contains(pInView) else { return event }

                // DR-0083: if the pointer is over a registered exclusion zone (e.g. the
                // sidebar ScrollView) let the event pass through to SwiftUI without
                // treating it as a canvas pan.
                if handler.scrollExclusionRects.contains(where: { $0.contains(cgLocation) }) {
                    return event
                }

                // Phase-based routing
                if event.phase.contains(.began) || event.phase == .mayBegin {
                    handler.updatePointerLocation(cgLocation)
                    handler.processTwoFingerPanBegan(location: cgLocation, coordinateInfo: coordinateInfo)
                } else if event.phase.contains(.changed) {
                    // For direct manipulation, use scroll deltas directly for both axes
                    let translation = CGSize(width: event.scrollingDeltaX, height: event.scrollingDeltaY)
                    handler.updatePointerLocation(cgLocation)
                    handler.processTwoFingerPanChanged(translation: translation, location: cgLocation, coordinateInfo: coordinateInfo)
                } else if event.phase.contains(.ended) || event.phase.contains(.cancelled) {
                    let translation = CGSize(width: event.scrollingDeltaX, height: event.scrollingDeltaY)
                    let velocity = CGSize.zero // NSEvent doesn't provide velocity for scroll wheel
                    handler.updatePointerLocation(cgLocation)
                    handler.processTwoFingerPanEnded(translation: translation, velocity: velocity, location: cgLocation, coordinateInfo: coordinateInfo)
                } else {
                    // Treat any other phases (including momentum) as changes; you may wish to clamp further.
                    let translation = CGSize(width: event.scrollingDeltaX, height: event.scrollingDeltaY)
                    handler.updatePointerLocation(cgLocation)
                    handler.processTwoFingerPanChanged(translation: translation, location: cgLocation, coordinateInfo: coordinateInfo)
                }
                
                // Return the event so normal scrolling in nested views can also occur if any.
                return event
            }
            
            // Mouse move monitor to keep pointer location fresh for pointer-centered zoom
            mouseMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]) { [weak self] event in
                guard let self,
                      let handler = self.handler,
                      event.window === window else { return event }
                let pInView = self.convert(event.locationInWindow, from: nil)
                let cgLocation = CGPoint(x: pInView.x, y: self.bounds.height - pInView.y)
                if self.bounds.contains(pInView) {
                    handler.updatePointerLocation(cgLocation)
                }
                return event
            }
        }
        
        private func removeMonitors() {
            if let m = leftMouseMonitor {
                NSEvent.removeMonitor(m)
                leftMouseMonitor = nil
            }
            if let m = rightClickMonitor {
                NSEvent.removeMonitor(m)
                rightClickMonitor = nil
            }
            if let m = scrollMonitor {
                NSEvent.removeMonitor(m)
                scrollMonitor = nil
            }
            if let m = mouseMoveMonitor {
                NSEvent.removeMonitor(m)
                mouseMoveMonitor = nil
            }
        }
    }
}
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
private struct IOSGestureOverlay: UIViewRepresentable {
    let handler: MultiGestureHandler
    let coordinateInfo: CoordinateSpaceInfo
    
    func makeUIView(context: Context) -> GestureOverlayView {
        let view = GestureOverlayView()
        view.handler = handler
        view.coordinateInfo = coordinateInfo
        return view
    }
    
    func updateUIView(_ uiView: GestureOverlayView, context: Context) {
        uiView.handler = handler
        uiView.coordinateInfo = coordinateInfo
        uiView.refreshRecognizerAttachment()
    }
    
    // GestureOverlayView is a UIScrollView so that:
    // 1. Its built-in panGestureRecognizer receives indirect scroll events (Magic Keyboard
    //    trackpad on iPadOS) via UIScrollType routing — plain UIView subclasses miss these.
    // 2. isScrollEnabled = true is required for UIScrollView to process scroll events through
    //    its gesture pipeline. We prevent actual scrolling by resetting contentOffset to zero
    //    in scrollViewDidScroll and using a zero contentSize so there is nothing to scroll to.
    // 3. point(inside:with:) returns false for normal touch hit-testing so SwiftUI
    //    gestures on the canvas layers below still receive all direct touches.
    class GestureOverlayView: UIScrollView, UIGestureRecognizerDelegate, UIScrollViewDelegate {
        var handler: MultiGestureHandler?
        var coordinateInfo: CoordinateSpaceInfo?

        private var longPress: UILongPressGestureRecognizer?
        // twoFingerPan is now the scroll view's own panGestureRecognizer (configured below).
        private var pinch: UIPinchGestureRecognizer?
        // Keep a reference to the view we add long-press and pinch to (an ancestor),
        // for clean detachment.
        private weak var attachedAncestorView: UIView?

        private var isScrollGestureActive: Bool = false

        // Large virtual content so UIScrollView always has room to accumulate deltas.
        // We keep contentOffset at the center and forward deltas to the canvas.
        private static let virtualSize: CGFloat = 100_000
        private var centerOffset: CGPoint {
            CGPoint(x: GestureOverlayView.virtualSize / 2,
                    y: GestureOverlayView.virtualSize / 2)
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            // isScrollEnabled must be TRUE — when false, UIScrollView drops scroll events
            // after hit-test and panGestureRecognizer never fires, even for trackpad input.
            // We use a large virtual contentSize and keep contentOffset centred; deltas are
            // forwarded to the canvas handler and contentOffset is reset after each callback.
            isScrollEnabled = true
            contentSize = CGSize(width: GestureOverlayView.virtualSize,
                                 height: GestureOverlayView.virtualSize)
            showsVerticalScrollIndicator = false
            showsHorizontalScrollIndicator = false
            isMultipleTouchEnabled = true
            bounces = false
            alwaysBounceVertical = false
            alwaysBounceHorizontal = false
            // Allow trackpad continuous scroll AND discrete mouse wheel events.
            panGestureRecognizer.allowedScrollTypesMask = .all
            // Indirect scroll events (trackpad) carry 0 touch points — minimumNumberOfTouches
            // must be 1 (the default) or the recognizer will never begin for trackpad input.
            // Direct two-finger touch pans are handled by the ancestor's UIPanGestureRecognizer.
            panGestureRecognizer.minimumNumberOfTouches = 1
            panGestureRecognizer.maximumNumberOfTouches = 10
            panGestureRecognizer.cancelsTouchesInView = false
            panGestureRecognizer.delaysTouchesBegan = false
            panGestureRecognizer.delegate = self
            // Enable user interaction on this view so it participates in hit-testing for
            // indirect (trackpad) scroll event routing on iPadOS. Normal touch hit-testing
            // is excluded via point(inside:with:) below so SwiftUI gestures still work.
            isUserInteractionEnabled = true
            delegate = self
            // Start at center so there's equal room to scroll in all directions
            contentOffset = centerOffset
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // Pass through normal touch hit-testing so SwiftUI gestures on the canvas
        // layers below this overlay still receive all direct finger touches.
        // Indirect pointer events (trackpad) use a different routing path and are
        // unaffected by this override — the scroll view still receives them.
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            let t = event?.type.rawValue ?? -1
            if t == UIEvent.EventType.scroll.rawValue {
                return true
            }
            return false
        }

        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            refreshAncestorRecognizers()
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            refreshAncestorRecognizers()
        }

        // Long-press and pinch still need to be on an ancestor because they rely on
        // direct touch hit-testing (our point(inside:with:) passes those through).
        func refreshRecognizerAttachment() {
            refreshAncestorRecognizers()
        }

        private func refreshAncestorRecognizers() {
            guard let host = findInteractiveHostView() else {
                detachAncestorRecognizers()
                return
            }
            if host === attachedAncestorView {
                return
            }
            detachAncestorRecognizers()
            attachAncestorRecognizers(to: host)
        }

        private func findInteractiveHostView() -> UIView? {
            var v = superview
            while let current = v {
                if current.isUserInteractionEnabled { return current }
                v = current.superview
            }
            return superview
        }

        private func attachAncestorRecognizers(to host: UIView) {
            let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            lp.minimumPressDuration = 0.5
            lp.cancelsTouchesInView = false
            lp.delaysTouchesBegan = false
            lp.delegate = self
            host.addGestureRecognizer(lp)
            self.longPress = lp
            
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            pinch.cancelsTouchesInView = false
            pinch.delaysTouchesBegan = false
            pinch.delegate = self
            host.addGestureRecognizer(pinch)
            self.pinch = pinch

            self.attachedAncestorView = host
        }

        private func detachAncestorRecognizers() {
            if let host = attachedAncestorView {
                if let lp = longPress { host.removeGestureRecognizer(lp) }
                if let pinch = pinch { host.removeGestureRecognizer(pinch) }
            }
            longPress = nil
            pinch = nil
            attachedAncestorView = nil
        }

        deinit {
            // UIView deallocation always occurs on the main thread, so it is safe
            // to assume main-actor isolation here rather than scheduling a Task
            // (which would race against the object's lifetime).
            MainActor.assumeIsolated {
                detachAncestorRecognizers()
            }
        }

        // MARK: - UIGestureRecognizerDelegate

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        // MARK: - Actions

        @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard recognizer.state == .began else { return }
            let location = recognizer.location(in: attachedAncestorView ?? recognizer.view)
            if let handler = handler, let coordinateInfo = coordinateInfo {
                handler.updatePointerLocation(location)
                _ = handler.processRightClick(location: location, coordinateInfo: coordinateInfo)
            }
        }

        // MARK: - UIScrollViewDelegate (trackpad pan via indirect scroll events)

        // Called every time UIScrollView updates contentOffset in response to a scroll event
        // (including indirect trackpad input). We capture the delta, immediately reset
        // contentOffset to zero (no actual content scrolling), and forward the delta to the
        // canvas pan handler.
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let offset = scrollView.contentOffset
            let center = centerOffset
            // Compute delta from center position
            let dx = offset.x - center.x
            let dy = offset.y - center.y
            // If this is just our own reset call, ignore
            guard dx != 0 || dy != 0 else { return }

            // Reset back to center so we always have room to accumulate more deltas
            scrollView.contentOffset = center

            let panLocation = panGestureRecognizer.location(in: attachedAncestorView)

            guard let handler = handler, let coordinateInfo = coordinateInfo else { return }

            // DR-0083: pass through if pointer is in the sidebar exclusion zone
            if handler.scrollExclusionRects.contains(where: { $0.contains(panLocation) }) {
                return
            }

            // Negate: scrolling right increases contentOffset.x, which means the content
            // moved left under the finger — we want the canvas to pan right (positive dx).
            let translation = CGSize(width: -dx, height: -dy)

            if !isScrollGestureActive {
                isScrollGestureActive = true
                handler.updatePointerLocation(panLocation)
                handler.processTwoFingerPanBegan(location: panLocation, coordinateInfo: coordinateInfo)
            }

            handler.updatePointerLocation(panLocation)
            handler.processTwoFingerPanChanged(translation: translation, location: panLocation, coordinateInfo: coordinateInfo)
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isScrollGestureActive = false
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            endScrollGesture(scrollView)
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            endScrollGesture(scrollView)
        }

        private func endScrollGesture(_ scrollView: UIScrollView) {
            guard isScrollGestureActive else { return }
            isScrollGestureActive = false
            scrollView.contentOffset = centerOffset

            guard let handler = handler, let coordinateInfo = coordinateInfo else { return }
            let panLocation = panGestureRecognizer.location(in: attachedAncestorView)
            handler.processTwoFingerPanEnded(
                translation: .zero,
                velocity: .zero,
                location: panLocation,
                coordinateInfo: coordinateInfo
            )
        }

        @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            let baseView = attachedAncestorView ?? recognizer.view
            let location = recognizer.location(in: baseView)
            guard let handler = handler, let coordinateInfo = coordinateInfo else { return }

            handler.updatePointerLocation(location)
            switch recognizer.state {
                case .began:
                    handler.processPinchBegan(scale: recognizer.scale, location: location, coordinateInfo: coordinateInfo)
                case .changed:
                    handler.processPinchChanged(scale: recognizer.scale, location: location, coordinateInfo: coordinateInfo)
                case .ended, .cancelled:
                    handler.processPinchEnded(scale: recognizer.scale, location: location, coordinateInfo: coordinateInfo)
                default:
                    break
            }
        }
    }
}
#endif

// MARK: - Weak Reference Wrapper

private class WeakGestureTarget {
    weak var target: GestureTarget?
    
    init(_ target: GestureTarget) {
        self.target = target
    }
}

// MARK: - Popup Overlay View

private struct PopupOverlay: View {
    @ObservedObject var handler: MultiGestureHandler
    
    var body: some View {
        if let popup = handler.activePopup {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    Color.clear // Invisible background for the container
                    
                    // Create the popup menu content with proper intrinsic sizing and Liquid Glass effect
                    VStack(spacing: 0) {
                        ForEach(popup.items, id: \.id) { item in
                            PopupMenuItemView(item: item) {
                                handler.hidePopup()
                                if !item.isDisabled {
                                    item.action()
                                }
                            }
                        }
                    }
                    .fixedSize() // Use intrinsic content size
                    #if os(visionOS)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    #else
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12, style: .continuous))
                    #endif
                    // Position with upper leading edge at pointer
                    .offset(
                        x: min(max(popup.position.x, 8), geometry.size.width - 200), // 8px minimum margin, estimate 200px popup width
                        y: min(max(popup.position.y, 8), geometry.size.height - CGFloat(popup.items.count * 44 + 20)) // 8px minimum margin
                    )
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.2), value: handler.activePopup != nil)
            }
        }
    }
}

private struct PopupMenuItemView: View {
    let item: PopupMenuItem
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            if let systemImage = item.systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                    .foregroundStyle(item.isDisabled ? .secondary : (item.isDestructive ? Color.red : .primary))
                    .frame(width: 20)
            }
            
            Text(item.title)
                .font(.system(size: 14))
                .foregroundStyle(item.isDisabled ? .secondary : (item.isDestructive ? Color.red : .primary))
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minWidth: 160, minHeight: 32)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovered && !item.isDisabled ? Color.primary.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !item.isDisabled {
                action()
            }
        }
        .onHover { hovering in
            if !item.isDisabled {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .opacity(item.isDisabled ? 0.6 : 1.0)
    }
}

// MARK: - View Extension

extension View {
    /// Apply multi-gesture handling to a view
    public func multiGestureHandler(_ handler: MultiGestureHandler, coordinateInfo: CoordinateSpaceInfo) -> some View {
        self.modifier(handler.createGestureModifier(coordinateInfo: coordinateInfo))
    }
}

// MARK: - Debug Helpers

private extension MultiGestureHandler {
    func debug(_ message: String) {
        guard loggingEnabled else { return }
        #if DEBUG
        logger.debug("\(message, privacy: .public)")
        #endif
    }
    
    func pointString(_ p: CGPoint) -> String {
        "(\(Int(p.x)), \(Int(p.y)))"
    }
    
    func rectString(_ r: CGRect) -> String {
        "x:\(Int(r.origin.x)) y:\(Int(r.origin.y)) w:\(Int(r.size.width)) h:\(Int(r.size.height))"
    }
    
    func typesString(_ types: [UTType]) -> String {
        types.map { $0.identifier }.joined(separator: ",")
    }
    
    func gestureTypeString(_ type: GestureType) -> String {
        switch type {
        case .tap: return "tap"
        case .doubleTap: return "doubleTap"
        case .drag: return "drag"
        case .rightClick: return "rightClick"
        case .pinch: return "pinch"
        case .twoFingerPan: return "twoFingerPan"
        }
    }
}
