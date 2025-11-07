//
//  MultiGestureTestView.swift
//  Cumberland
//
//  Created by Assistant on 10/31/25.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - Custom UTTypes for internal drags

private extension UTType {
    // Carries the UUID string of a TestItem for internal drags between views.
    // Use a dynamic/ad-hoc UTI so we don't need an Info.plist declaration.
    static let testItemID = UTType("app.cumberland.testitem-id")!
}

// MARK: - Debug Logger

private enum DebugLog {
    // This flag is read from a nonisolated function; mark it as nonisolated(unsafe)
    // to avoid crossing actor boundaries. Keep mutations to a known context if you
    // decide to toggle it at runtime.
    nonisolated(unsafe) static var enabled = true
    
    // Allow logging from any context (including deinit/nonisolated accessors) safely.
    // Use thread-safe Date().formatted instead of a shared DateFormatter instance.
    nonisolated static func log(_ category: String, _ message: @autoclosure () -> String,
                    file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
        guard enabled else { return }
        let ts = Date().formatted(date: .omitted, time: .standard)
        print("[\(ts)] [\(category)] \(message()) — \(file):\(line)")
    }
}

// MARK: - Test View Model

@MainActor
class TestCanvasViewModel: ObservableObject {
    @Published var zoomScale: CGFloat = 1.0 {
        didSet { DebugLog.log("ViewModel", "zoomScale changed: \(oldValue) -> \(zoomScale)") }
    }
    @Published var panOffset: CGPoint = .zero {
        didSet { DebugLog.log("ViewModel", "panOffset changed: \(oldValue) -> \(panOffset)") }
    }
    @Published var selectedItemID: UUID? {
        didSet { DebugLog.log("ViewModel", "selectedItemID changed: \(String(describing: oldValue)) -> \(String(describing: selectedItemID))") }
    }
    @Published var testItems: [TestItem] = [] {
        didSet { DebugLog.log("ViewModel", "testItems updated, count: \(testItems.count)") }
    }
    @Published var logMessages: [String] = [] {
        didSet { DebugLog.log("ViewModel", "logMessages appended, total: \(logMessages.count)") }
    }
    
    // Visual feedback for canvas drop hover
    @Published var isDropHovering: Bool = false {
        didSet { DebugLog.log("ViewModel", "isDropHovering -> \(isDropHovering)") }
    }
    
    // Single-touch background drag behavior: lasso vs pan
    enum BackgroundDragMode: String, CaseIterable, Identifiable {
        case lasso = "Lasso"
        case pan = "Pan"
        var id: String { rawValue }
    }
    @Published var backgroundDragMode: BackgroundDragMode = .lasso {
        didSet { DebugLog.log("ViewModel", "backgroundDragMode -> \(backgroundDragMode.rawValue)") }
    }
    
    // Lasso state (world space)
    @Published var lassoStartWorld: CGPoint? {
        didSet { DebugLog.log("ViewModel", "lassoStartWorld -> \(String(describing: lassoStartWorld))") }
    }
    @Published var lassoCurrentWorld: CGPoint? {
        didSet { DebugLog.log("ViewModel", "lassoCurrentWorld -> \(String(describing: lassoCurrentWorld))") }
    }
    var lassoWorldRect: CGRect? {
        guard let a = lassoStartWorld, let b = lassoCurrentWorld else { return nil }
        let minX = min(a.x, b.x)
        let minY = min(a.y, b.y)
        let maxX = max(a.x, b.x)
        let maxY = max(a.y, b.y)
        return CGRect(x: minX, y: minY, width: max(0, maxX - minX), height: max(0, maxY - minY))
    }
    
    let gestureHandler: MultiGestureHandler
    private let canvasSpaceName = "testCanvas"
    
    // Strongly retain gesture targets so the handler's weak storage doesn't lose them.
    private var retainedTargets: [GestureTarget] = []
    
    init() {
        DebugLog.log("ViewModel", "init()")
        self.gestureHandler = MultiGestureHandler(coordinateSpace: canvasSpaceName)
        
        // Create some test items
        createTestItems()
        
        // Register background target for canvas-level gestures + drops
        let backgroundTarget = TestBackgroundTarget(viewModel: self)
        DebugLog.log("ViewModel", "Registering background target: \(backgroundTarget.gestureID)")
        gestureHandler.registerTarget(backgroundTarget)
        retainedTargets.append(backgroundTarget) // strong retain
        
        // Register targets for each test item (gesture-only; drops are handled by background)
        for item in testItems {
            let itemTarget = TestItemTarget(item: item, viewModel: self)
            DebugLog.log("ViewModel", "Registering item target: \(itemTarget.gestureID) for \(item.title)")
            gestureHandler.registerTarget(itemTarget)
            retainedTargets.append(itemTarget) // strong retain
        }
    }
    
    @MainActor
    deinit {
        let count = retainedTargets.count
        DebugLog.log("ViewModel", "deinit; unregistering \(count) targets")
        for t in retainedTargets {
            gestureHandler.unregisterTarget(t)
        }
        retainedTargets.removeAll()
    }
    
    private func createTestItems() {
        DebugLog.log("ViewModel", "createTestItems()")
        testItems = [
            TestItem(position: CGPoint(x: 100, y: 100), color: .red, title: "Item 1"),
            TestItem(position: CGPoint(x: 300, y: 200), color: .blue, title: "Item 2"),
            TestItem(position: CGPoint(x: 200, y: 300), color: .green, title: "Item 3"),
            TestItem(position: CGPoint(x: 400, y: 150), color: .orange, title: "Item 4")
        ]
    }
    
    func coordinateSpaceInfo() -> CoordinateSpaceInfo {
        let info = CoordinateSpaceInfo(
            spaceName: canvasSpaceName,
            // Keep transform consistent with v = w*S + T (scale then translate)
            transform: CGAffineTransform.identity
                .scaledBy(x: zoomScale, y: zoomScale)
                .translatedBy(x: panOffset.x, y: panOffset.y),
            zoomScale: zoomScale,
            panOffset: panOffset
        )
        DebugLog.log("ViewModel", "coordinateSpaceInfo() -> zoom: \(zoomScale), pan: \(panOffset)")
        return info
    }
    
    func addLogMessage(_ message: String) {
        let timestamp = DateFormatter.timeOnly.string(from: Date())
        let composed = "[\(timestamp)] \(message)"
        logMessages.append(composed)
        DebugLog.log("ViewModel", "addLogMessage: \(message)")
        if logMessages.count > 50 {
            logMessages.removeFirst()
            DebugLog.log("ViewModel", "logMessages trimmed to 50")
        }
    }
    
    func updateItemPosition(id: UUID, position: CGPoint) {
        DebugLog.log("ViewModel", "updateItemPosition id: \(id) -> \(position)")
        if let index = testItems.firstIndex(where: { $0.id == id }) {
            testItems[index].position = position
        } else {
            DebugLog.log("ViewModel", "updateItemPosition: item not found for id \(id)")
        }
    }
    
    func selectItem(id: UUID?) {
        DebugLog.log("ViewModel", "selectItem id: \(String(describing: id))")
        selectedItemID = id
        if let id = id, let item = testItems.first(where: { $0.id == id }) {
            addLogMessage("Selected \(item.title)")
        } else {
            addLogMessage("Cleared selection")
        }
    }
    
    func clearLasso() {
        DebugLog.log("ViewModel", "clearLasso()")
        lassoStartWorld = nil
        lassoCurrentWorld = nil
    }
    
    func performLassoSelection(in worldRect: CGRect) {
        let hits = testItems.filter { $0.worldBounds.intersects(worldRect) }
        if let first = hits.first {
            selectedItemID = first.id
            addLogMessage("Lasso selected \(hits.count) item(s); primary: \(first.title)")
        } else {
            selectedItemID = nil
            addLogMessage("Lasso selected 0 items")
        }
        DebugLog.log("ViewModel", "performLassoSelection in \(worldRect) -> \(hits.map { $0.title })")
    }
    
    // MARK: - Drag & Drop helpers
    
    func addItemFromText(_ text: String, at worldPoint: CGPoint) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmed.isEmpty ? "New Item" : String(trimmed.prefix(40))
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .teal]
        let color = colors.randomElement() ?? .accentColor
        let new = TestItem(position: worldPoint, color: color, title: title)
        testItems.append(new)
        addLogMessage("Created item '\(title)' at \(Int(worldPoint.x)), \(Int(worldPoint.y)) from text drop")
        DebugLog.log("ViewModel", "addItemFromText '\(title)' @ \(worldPoint)")
        
        // Register a gesture target for the new item
        let itemTarget = TestItemTarget(item: new, viewModel: self)
        gestureHandler.registerTarget(itemTarget)
        retainedTargets.append(itemTarget)
    }
    
    func moveItemWithIDString(_ idString: String, to worldPoint: CGPoint) -> Bool {
        guard let uuid = UUID(uuidString: idString),
              let index = testItems.firstIndex(where: { $0.id == uuid }) else {
            DebugLog.log("ViewModel", "moveItemWithIDString: could not resolve UUID from '\(idString)'")
            return false
        }
        testItems[index].position = worldPoint
        addLogMessage("Moved \(testItems[index].title) to \(Int(worldPoint.x)), \(Int(worldPoint.y)) via drop")
        DebugLog.log("ViewModel", "Moved item id \(uuid) -> \(worldPoint)")
        return true
    }
    
    func removeItem(id: UUID) {
        if let idx = testItems.firstIndex(where: { $0.id == id }) {
            let removed = testItems.remove(at: idx)
            addLogMessage("Removed \(removed.title) via trash drop")
            DebugLog.log("ViewModel", "Removed item \(removed.title) id=\(removed.id)")
            if selectedItemID == removed.id { selectedItemID = nil }
            
            // Unregister any retained target for this item
            if let targetIndex = retainedTargets.firstIndex(where: { ($0 as? TestItemTarget)?.itemID == id }) {
                let target = retainedTargets.remove(at: targetIndex)
                gestureHandler.unregisterTarget(target)
            }
        }
    }
}

// MARK: - Test Item Model

struct TestItem: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let title: String
    let size: CGSize = CGSize(width: 80, height: 60)
    
    var worldBounds: CGRect {
        let rect = CGRect(
            x: position.x - size.width/2,
            y: position.y - size.height/2,
            width: size.width,
            height: size.height
        )
        return rect
    }
}

// MARK: - Test Item Target

@MainActor
class TestItemTarget: GestureTarget {
    let gestureID = UUID()
    fileprivate let itemID: UUID
    private let itemSnapshot: TestItem
    private weak var viewModel: TestCanvasViewModel?
    
    init(item: TestItem, viewModel: TestCanvasViewModel) {
        self.itemID = item.id
        self.itemSnapshot = item
        self.viewModel = viewModel
        DebugLog.log("ItemTarget", "init for \(item.title), gestureID: \(gestureID)")
    }
    
    deinit {
        DebugLog.log("ItemTarget", "deinit for id \(itemID) gestureID: \(gestureID)")
    }
    
    var worldBounds: CGRect {
        // Use latest position from view model if available, else snapshot
        if let vm = viewModel, let current = vm.testItems.first(where: { $0.id == itemID }) {
            let rect = current.worldBounds
            DebugLog.log("ItemTarget", "worldBounds for \(current.title): \(rect)")
            return rect
        }
        let rect = itemSnapshot.worldBounds
        DebugLog.log("ItemTarget", "worldBounds snapshot for id \(itemID): \(rect)")
        return rect
    }
    
    func canHandleGesture(_ gesture: GestureType) -> Bool {
        let can: Bool
        switch gesture {
        case .tap, .doubleTap, .drag, .rightClick:
            can = true
        case .pinch, .twoFingerPan:
            can = false
        }
        DebugLog.log("ItemTarget", "canHandleGesture(\(gesture)) for id \(itemID): \(can)")
        return can
    }
    
    func handleGesture(_ gesture: GestureEvent) {
        guard let viewModel = viewModel,
              let item = viewModel.testItems.first(where: { $0.id == itemID }) else {
            DebugLog.log("ItemTarget", "handleGesture: viewModel/item deallocated for id \(itemID)")
            return
        }
        DebugLog.log("ItemTarget", "handleGesture for \(item.title): \(gesture)")
        
        switch gesture {
        case .tap(let location, let coordinateSpace):
            let worldLocation = coordinateSpace.toWorldSpace(location)
            viewModel.selectItem(id: item.id)
            viewModel.addLogMessage("Tapped \(item.title) at \(Int(worldLocation.x)), \(Int(worldLocation.y))")
            DebugLog.log("ItemTarget", "Tap handled for \(item.title) at world \(worldLocation)")
            
        case .doubleTap(let location, let coordinateSpace):
            let worldLocation = coordinateSpace.toWorldSpace(location)
            viewModel.addLogMessage("Double-tapped \(item.title) at \(Int(worldLocation.x)), \(Int(worldLocation.y))")
            DebugLog.log("ItemTarget", "DoubleTap handled for \(item.title) at world \(worldLocation)")
            
        case .dragBegan(let startLocation, let coordinateSpace):
            viewModel.selectItem(id: item.id)
            let worldLocation = coordinateSpace.toWorldSpace(startLocation)
            viewModel.addLogMessage("Started dragging \(item.title) from \(Int(worldLocation.x)), \(Int(worldLocation.y))")
            DebugLog.log("ItemTarget", "DragBegan for \(item.title) at world \(worldLocation)")
            
        case .dragChanged(_, let translation, let coordinateSpace):
            let worldTranslation = CGSize(
                width: translation.width / coordinateSpace.zoomScale,
                height: translation.height / coordinateSpace.zoomScale
            )
            let newPosition = CGPoint(
                x: item.position.x + worldTranslation.width,
                y: item.position.y + worldTranslation.height
            )
            viewModel.updateItemPosition(id: item.id, position: newPosition)
            DebugLog.log("ItemTarget", "DragChanged \(item.title) translation: \(translation) -> worldΔ \(worldTranslation), newPos \(newPosition)")
            
        case .dragEnded(let location, _, _, let coordinateSpace):
            let worldLocation = coordinateSpace.toWorldSpace(location)
            viewModel.addLogMessage("Finished dragging \(item.title) to \(Int(worldLocation.x)), \(Int(worldLocation.y))")
            DebugLog.log("ItemTarget", "DragEnded \(item.title) at world \(worldLocation)")
            
        case .rightClick(let location, let coordinateSpace):
            let worldLocation = coordinateSpace.toWorldSpace(location)
            viewModel.selectItem(id: item.id)
            viewModel.addLogMessage("Right-clicked \(item.title) at \(Int(worldLocation.x)), \(Int(worldLocation.y))")
            DebugLog.log("ItemTarget", "RightClick \(item.title) at world \(worldLocation)")
            
        default:
            DebugLog.log("ItemTarget", "Unhandled gesture for \(item.title): \(gesture)")
        }
    }
}

// MARK: - Background Target (now DropCapable)

@MainActor
class TestBackgroundTarget: DropCapableTarget, GestureTarget {
    let gestureID = UUID()
    private weak var viewModel: TestCanvasViewModel?
    
    // Pinch anchoring state so zoom occurs around the gesture focal point
    private var pinchAnchorWorld: CGPoint?
    private var pinchAnchorScreen: CGPoint?
    
    // For single-touch background pan
    private var panStartOffset: CGPoint?
    
    init(viewModel: TestCanvasViewModel) {
        self.viewModel = viewModel
        DebugLog.log("BackgroundTarget", "init, gestureID: \(gestureID)")
    }
    
    deinit {
        DebugLog.log("BackgroundTarget", "deinit gestureID: \(gestureID)")
    }
    
    // Large bounds to catch background gestures
    var worldBounds: CGRect {
        let rect = CGRect(x: -10000, y: -10000, width: 20000, height: 20000)
        DebugLog.log("BackgroundTarget", "worldBounds: \(rect)")
        return rect
    }
    
    func canHandleGesture(_ gesture: GestureType) -> Bool {
        let can: Bool
        switch gesture {
        case .tap, .pinch, .twoFingerPan, .drag:
            can = true
        case .doubleTap, .rightClick:
            can = false
        }
        DebugLog.log("BackgroundTarget", "canHandleGesture(\(gesture)): \(can)")
        return can
    }
    
    // MARK: DropCapableTarget
    
    var acceptedDropTypes: [UTType] {
        [.testItemID, .text, .image, .fileURL]
    }
    
    func dragEntered(with session: DropSession, at location: CGPoint, coordinateSpace: CoordinateSpaceInfo) {
        viewModel?.isDropHovering = true
        DebugLog.log("BackgroundTarget", "Drop dragEntered at \(location)")
    }
    
    func dragUpdated(with session: DropSession, at location: CGPoint, coordinateSpace: CoordinateSpaceInfo) -> DropProposal {
        // Suggest move for internal node drags; copy for external items
        if session.hasItemsConforming(to: [.testItemID]) {
            return .move
        } else if session.hasItemsConforming(to: [.text, .image, .fileURL]) {
            return .copy
        } else {
            return .forbidden
        }
    }
    
    func dragExited() {
        viewModel?.isDropHovering = false
        DebugLog.log("BackgroundTarget", "Drop dragExited")
    }
    
    func performDrop(with session: DropSession, at location: CGPoint, coordinateSpace: CoordinateSpaceInfo) -> Bool {
        viewModel?.isDropHovering = false
        guard let viewModel = viewModel else { return false }
        let worldPoint = coordinateSpace.toWorldSpace(location)
        DebugLog.log("BackgroundTarget", "performDrop at view \(location) world \(worldPoint)")
        
        // Prefer internal node move first
        for item in session.items {
            let provider = item.itemProvider
            if provider.hasItemConformingToTypeIdentifier(UTType.testItemID.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.testItemID.identifier, options: nil) { obj, _ in
                    if let data = obj as? Data, let idString = String(data: data, encoding: .utf8) {
                        Task { @MainActor in
                            _ = viewModel.moveItemWithIDString(idString, to: worldPoint)
                        }
                    } else if let str = obj as? String {
                        Task { @MainActor in
                            _ = viewModel.moveItemWithIDString(str, to: worldPoint)
                        }
                    }
                }
                return true
            }
        }
        
        // Then accept text to create a new node (works with palette chips and external text)
        for item in session.items {
            let provider = item.itemProvider
            if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { obj, _ in
                    let text: String?
                    if let s = obj as? String {
                        text = s
                    } else if let data = obj as? Data, let s = String(data: data, encoding: .utf8) {
                        text = s
                    } else {
                        text = nil
                    }
                    if let text {
                        Task { @MainActor in
                            viewModel.addItemFromText(text, at: worldPoint)
                        }
                    }
                }
                return true
            }
        }
        
        // Optionally: accept images/files in a future enhancement
        return false
    }
    
    // MARK: Gestures
    
    func handleGesture(_ gesture: GestureEvent) {
        guard let viewModel = viewModel else {
            DebugLog.log("BackgroundTarget", "handleGesture: viewModel deallocated")
            return
        }
        DebugLog.log("BackgroundTarget", "handleGesture: \(gesture)")
        
        switch gesture {
        case .tap(let location, let coordinateSpace):
            viewModel.selectItem(id: nil) // Clear selection
            let worldLocation = coordinateSpace.toWorldSpace(location)
            viewModel.addLogMessage("Background tap at \(Int(worldLocation.x)), \(Int(worldLocation.y))")
            DebugLog.log("BackgroundTarget", "Tap at world \(worldLocation)")
            
        // MARK: Pinch zoom
        case .pinchBegan(let scale, _, let center, let coordinateSpace):
            let worldLocation = coordinateSpace.toWorldSpace(center)
            pinchAnchorWorld = worldLocation
            pinchAnchorScreen = center
            viewModel.addLogMessage("Pinch began at \(Int(worldLocation.x)), \(Int(worldLocation.y)), scale: \(String(format: "%.2f", scale))")
            DebugLog.log("BackgroundTarget", "PinchBegan at world \(worldLocation), screen \(center), scale \(scale)")
            
        case .pinchChanged(let scale, _, let center, let coordinateSpace):
            let newScale = max(0.1, min(5.0, scale))
            // Seed anchors if we missed .began for any reason
            let anchorWorld = pinchAnchorWorld ?? coordinateSpace.toWorldSpace(center)
            let anchorScreen = pinchAnchorScreen ?? center
            
            // Maintain anchorScreen = anchorWorld * S + T  => T = anchorScreen - anchorWorld * S
            let newPan = CGPoint(
                x: anchorScreen.x - anchorWorld.x * newScale,
                y: anchorScreen.y - anchorWorld.y * newScale
            )
            let oldScale = viewModel.zoomScale
            let oldPan = viewModel.panOffset
            viewModel.zoomScale = newScale
            viewModel.panOffset = newPan
            
            DebugLog.log(
                "BackgroundTarget",
                "PinchChanged s=\(String(format: "%.3f", scale))->\(String(format: "%.3f", newScale)) " +
                "anchor world \(anchorWorld) screen \(anchorScreen) " +
                "pan \(oldPan)->\(newPan) zoom \(oldScale)->\(newScale)"
            )
            
        case .pinchEnded(let scale, _, _, _):
            viewModel.addLogMessage("Pinch ended, final scale: \(String(format: "%.2f", scale))")
            pinchAnchorWorld = nil
            pinchAnchorScreen = nil
            DebugLog.log("BackgroundTarget", "PinchEnded final scale \(scale); cleared anchors")
            
        // MARK: Two-finger pan (trackpad/iPad etc.)
        case .twoFingerPanBegan(let location, let coordinateSpace):
            let worldLocation = coordinateSpace.toWorldSpace(location)
            viewModel.addLogMessage("Two-finger pan began at \(Int(worldLocation.x)), \(Int(worldLocation.y))")
            DebugLog.log("BackgroundTarget", "TwoFingerPanBegan at world \(worldLocation)")
            
        case .twoFingerPanChanged(let translation, _, _):
            let old = viewModel.panOffset
            viewModel.panOffset = CGPoint(
                x: viewModel.panOffset.x + translation.width,
                y: viewModel.panOffset.y + translation.height
            )
            DebugLog.log("BackgroundTarget", "TwoFingerPanChanged translation \(translation) pan \(old) -> \(viewModel.panOffset)")
            
        case .twoFingerPanEnded(_, let velocity, _, _):
            viewModel.addLogMessage("Two-finger pan ended, velocity: \(Int(velocity.width)), \(Int(velocity.height))")
            DebugLog.log("BackgroundTarget", "TwoFingerPanEnded velocity \(velocity)")
            
        // MARK: Single-touch background drag (no-hit)
        case .dragBegan(let startLocation, let coordinateSpace):
            switch viewModel.backgroundDragMode {
            case .lasso:
                let startWorld = coordinateSpace.toWorldSpace(startLocation)
                viewModel.lassoStartWorld = startWorld
                viewModel.lassoCurrentWorld = startWorld
                viewModel.addLogMessage("Lasso began at \(Int(startWorld.x)), \(Int(startWorld.y))")
                DebugLog.log("BackgroundTarget", "Lasso drag began world \(startWorld)")
            case .pan:
                panStartOffset = viewModel.panOffset
                viewModel.addLogMessage("Background pan (single-touch) began")
                DebugLog.log("BackgroundTarget", "Pan drag began; panStart=\(String(describing: panStartOffset))")
            }
            
        case .dragChanged(let location, let translation, let coordinateSpace):
            switch viewModel.backgroundDragMode {
            case .lasso:
                let currentWorld = coordinateSpace.toWorldSpace(location)
                viewModel.lassoCurrentWorld = currentWorld
                DebugLog.log("BackgroundTarget", "Lasso drag changed; current world \(currentWorld)")
            case .pan:
                guard let start = panStartOffset else { break }
                let newPan = CGPoint(x: start.x + translation.width, y: start.y + translation.height)
                let old = viewModel.panOffset
                viewModel.panOffset = newPan
                DebugLog.log("BackgroundTarget", "Pan drag changed; pan \(old) -> \(newPan) (Δ=\(translation))")
            }
            
        case .dragEnded(let location, let translation, let velocity, let coordinateSpace):
            switch viewModel.backgroundDragMode {
            case .lasso:
                if let rect = viewModel.lassoWorldRect {
                    viewModel.performLassoSelection(in: rect)
                }
                viewModel.clearLasso()
                DebugLog.log("BackgroundTarget", "Lasso drag ended at world \(coordinateSpace.toWorldSpace(location)); cleared lasso")
            case .pan:
                let old = viewModel.panOffset
                if let start = panStartOffset {
                    let finalPan = CGPoint(x: start.x + translation.width, y: start.y + translation.height)
                    viewModel.panOffset = finalPan
                }
                viewModel.addLogMessage("Background pan ended, velocity: \(Int(velocity.width)), \(Int(velocity.height))")
                DebugLog.log("BackgroundTarget", "Pan drag ended; pan \(old) -> \(viewModel.panOffset)")
                panStartOffset = nil
            }
            
        default:
            DebugLog.log("BackgroundTarget", "Unhandled gesture: \(gesture)")
        }
    }
}

// MARK: - Main Test View

struct MultiGestureTestView: View {
    @StateObject private var viewModel = TestCanvasViewModel()
    @State private var showLog = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Control Panel
                controlPanel
                
                Divider()
                
                // Canvas extracted into its own subview to ease type-checking
                CanvasAreaView(viewModel: viewModel)
            }
            .navigationTitle("Multi-Gesture Test")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Log") {
                        DebugLog.log("View", "Log button tapped. showLog was \(showLog)")
                        showLog.toggle()
                    }
                }
            }
        }
        .onAppear {
            DebugLog.log("View", "MultiGestureTestView appear")
        }
        .onDisappear {
            DebugLog.log("View", "MultiGestureTestView disappear")
        }
        .sheet(isPresented: $showLog) {
            LogView(messages: viewModel.logMessages)
                .onAppear {
                    DebugLog.log("View", "Presenting LogView sheet")
                }
        }
        // Provide the view model to node views for context menu actions
        .environmentObject(viewModel)
    }
    
    private var controlPanel: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                Text("Canvas Controls")
                    .font(.headline)
                Spacer()
                
                // Palette: drag these chips onto the canvas to add nodes
                HStack(spacing: 8) {
                    PaletteChip(title: "Task", color: .blue)
                    PaletteChip(title: "Note", color: .orange)
                    PaletteChip(title: "Idea", color: .purple)
                    PaletteChip(title: "Bug", color: .red)
                }
                .accessibilityLabel("Palette")
                .accessibilityHint("Drag a chip onto the canvas to add a node")
                
                Spacer()
                
                // Background drag mode picker (Lasso vs Pan)
                Picker("Drag Mode", selection: $viewModel.backgroundDragMode) {
                    ForEach(TestCanvasViewModel.BackgroundDragMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)
                
                Button("Reset View") {
                    DebugLog.log("View", "Reset View tapped")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.zoomScale = 1.0
                        viewModel.panOffset = .zero
                        viewModel.clearLasso()
                        viewModel.selectItem(id: nil)
                    }
                }
                .buttonStyle(.bordered)
                
                // Trash drop zone to simulate "dragging off" the canvas
                TrashDropZone { id in
                    viewModel.removeItem(id: id)
                }
                .padding(.leading, 12)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected: \(selectedItemName)")
                        .font(.caption)
                    Text("Zoom: \(String(format: "%.1f", viewModel.zoomScale))x")
                        .font(.caption)
                    Text("Pan: \(Int(viewModel.panOffset.x)), \(Int(viewModel.panOffset.y))")
                        .font(.caption)
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Gestures + Drag/Drop:")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("• Tap to select items")
                        .font(.caption2)
                    Text("• Drag to move items")
                        .font(.caption2)
                    Text("• Pinch to zoom; two-finger pan to move canvas")
                        .font(.caption2)
                    Text("• Single-drag on background: \(viewModel.backgroundDragMode.rawValue)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("• Drag items onto canvas to move; drop text to create")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("• Drag items from Palette onto canvas to add nodes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("• Drag items onto Trash to remove")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            DebugLog.log("View", "controlPanel appear")
        }
        .onChange(of: selectedItemName) { _, new in
            DebugLog.log("View", "selectedItemName changed: \(new)")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    private var selectedItemName: String {
        guard let selectedID = viewModel.selectedItemID,
              let item = viewModel.testItems.first(where: { $0.id == selectedID }) else {
            return "None"
        }
        return item.title
    }
}

// MARK: - Canvas Area (extracted)

private struct CanvasAreaView: View {
    @ObservedObject var viewModel: TestCanvasViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(gridPattern)
                    .overlay(
                        // Drop hover feedback: blue border
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(viewModel.isDropHovering ? Color.accentColor : Color.clear, lineWidth: 3)
                            .animation(.easeInOut(duration: 0.15), value: viewModel.isDropHovering)
                    )
                    // Canvas-level context menu (background only)
                    .contextMenu {
                        Button {
                            DebugLog.log("View", "Canvas CM: Deselect All")
                            viewModel.selectItem(id: nil)
                        } label: {
                            Label("Deselect All", systemImage: "cursorarrow.rays")
                        }
                        
                        Button {
                            DebugLog.log("View", "Canvas CM: Reset View")
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.zoomScale = 1.0
                                viewModel.panOffset = .zero
                                viewModel.clearLasso()
                                viewModel.selectItem(id: nil)
                            }
                        } label: {
                            Label("Reset View", systemImage: "arrow.counterclockwise")
                        }
                        
                        Divider()
                        
                        Button {
                            let next: TestCanvasViewModel.BackgroundDragMode = (viewModel.backgroundDragMode == .lasso) ? .pan : .lasso
                            DebugLog.log("View", "Canvas CM: Toggle Drag Mode -> \(next.rawValue)")
                            viewModel.backgroundDragMode = next
                        } label: {
                            let nextName = (viewModel.backgroundDragMode == .lasso) ? "Pan" : "Lasso"
                            Label("Switch to \(nextName)", systemImage: "hand.point.up.left")
                        }
                        
                        Divider()
                        
                        Button {
                            DebugLog.log("View", "Canvas CM: Zoom In")
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewModel.zoomScale = min(viewModel.zoomScale * 1.2, 5.0)
                            }
                        } label: {
                            Label("Zoom In", systemImage: "plus.magnifyingglass")
                        }
                        
                        Button {
                            DebugLog.log("View", "Canvas CM: Zoom Out")
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewModel.zoomScale = max(viewModel.zoomScale / 1.2, 0.1)
                            }
                        } label: {
                            Label("Zoom Out", systemImage: "minus.magnifyingglass")
                        }
                    }
                
                // Test Items
                ForEach(viewModel.testItems) { item in
                    TestItemView(
                        item: item,
                        isSelected: viewModel.selectedItemID == item.id
                    )
                    .position(
                        x: item.position.x * viewModel.zoomScale + viewModel.panOffset.x,
                        y: item.position.y * viewModel.zoomScale + viewModel.panOffset.y
                    )
                    // Make items draggable: internal UUID for canvas moves; text for external apps
                    .onDrag { makeItemProvider(for: item) }
                    .onAppear {
                        DebugLog.log("View", "TestItemView appear: \(item.title) @ \(item.position)")
                    }
                }
                
                // Lasso overlay (drawn in view space using world→view transform)
                if let lassoViewRect = lassoViewRect(in: viewModel.coordinateSpaceInfo()) {
                    ZStack {
                        // Fill with translucent tint
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: lassoViewRect.width, height: lassoViewRect.height)
                            .position(x: lassoViewRect.midX, y: lassoViewRect.midY)
                        // Stroke border
                        Rectangle()
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .frame(width: lassoViewRect.width, height: lassoViewRect.height)
                            .position(x: lassoViewRect.midX, y: lassoViewRect.midY)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .onAppear {
                        DebugLog.log("View", "Lasso overlay appear viewRect=\(lassoViewRect)")
                    }
                }
                
                // Drop overlay text (optional visual cue)
                if viewModel.isDropHovering {
                    Text("Release to drop")
                        .font(.caption.bold())
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)
                        .transition(.opacity)
                }
                
                // Zoom/Pan info overlay
                VStack {
                    HStack {
                        Text("Zoom: \(String(format: "%.1f", viewModel.zoomScale))x")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        Spacer()
                    }
                    HStack {
                        Text("Pan: \(Int(viewModel.panOffset.x)), \(Int(viewModel.panOffset.y))")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
            }
            .clipped()
            .onAppear {
                DebugLog.log("View", "Canvas ZStack appear, size: \(geometry.size)")
            }
            .onChange(of: viewModel.zoomScale) { _, new in
                DebugLog.log("View", "zoomScale changed (onChange): \(new)")
            }
            .onChange(of: viewModel.panOffset) { _, new in
                DebugLog.log("View", "panOffset changed (onChange): \(new)")
            }
            .multiGestureHandler(viewModel.gestureHandler, coordinateInfo: viewModel.coordinateSpaceInfo())
        }
    }
    
    private var gridPattern: some View {
        Canvas { context, size in
            let spacing: CGFloat = 50
            context.stroke(
                Path { path in
                    // Vertical lines
                    for x in stride(from: 0, through: size.width, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    
                    // Horizontal lines
                    for y in stride(from: 0, through: size.height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                },
                with: .color(.gray.opacity(0.3)),
                lineWidth: 0.5
            )
        }
        .onAppear {
            DebugLog.log("View", "gridPattern Canvas appear")
        }
    }
    
    // Convert current lasso world rect to a view-space rect for drawing
    private func lassoViewRect(in coord: CoordinateSpaceInfo) -> CGRect? {
        guard let worldRect = viewModel.lassoWorldRect else { return nil }
        let p1 = CGPoint(x: worldRect.minX, y: worldRect.minY)
        let p2 = CGPoint(x: worldRect.maxX, y: worldRect.maxY)
        let v1 = coord.fromWorldSpace(p1)
        let v2 = coord.fromWorldSpace(p2)
        let minX = min(v1.x, v2.x)
        let minY = min(v1.y, v2.y)
        let maxX = max(v1.x, v2.x)
        let maxY = max(v1.y, v2.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    // Build an NSItemProvider that carries our internal type and a text fallback
    private func makeItemProvider(for item: TestItem) -> NSItemProvider {
        let provider = NSItemProvider()
        // Internal UUID payload
        let idString = item.id.uuidString
        if let data = idString.data(using: .utf8) {
            provider.registerDataRepresentation(forTypeIdentifier: UTType.testItemID.identifier, visibility: .all) { completion in
                completion(data, nil)
                return nil
            }
        }
        // Also expose title as plain text for external apps
        provider.registerItem(forTypeIdentifier: UTType.text.identifier, loadHandler: { completion, _, _ in
            completion?(item.title as NSString, nil)
        })
        return provider
    }
}

// MARK: - Palette Chip (drag to add node)

private struct PaletteChip: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(color.opacity(0.2))
            )
            .overlay(
                Capsule().stroke(color, lineWidth: 1)
            )
            .onDrag {
                // Provide plain text so the canvas can create a node via existing .text drop path
                let provider = NSItemProvider()
                provider.registerItem(forTypeIdentifier: UTType.text.identifier, loadHandler: { completion, _, _ in
                    completion?(title as NSString, nil)
                })
                return provider
            }
            .accessibilityLabel("\(title) palette item")
            .accessibilityHint("Drag onto the canvas to add a new node")
    }
}

// MARK: - Test Item View

struct TestItemView: View {
    let item: TestItem
    let isSelected: Bool
    @EnvironmentObject private var viewModel: TestCanvasViewModel
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(item.color)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
            )
            .overlay(
                Text(item.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            )
            .frame(width: item.size.width, height: item.size.height)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            // System context menu so right-click (macOS) and long-press (iOS/iPadOS) present actions
            .contextMenu {
                Button {
                    viewModel.selectItem(id: item.id)
                    viewModel.addLogMessage("Context menu: Select \(item.title)")
                } label: {
                    Label("Select", systemImage: "cursorarrow.rays")
                }
                
                Button {
                    viewModel.addLogMessage("Context menu: Duplicate \(item.title)")
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
                
                Button(role: .destructive) {
                    viewModel.addLogMessage("Context menu: Remove \(item.title)")
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            }
            .onChange(of: isSelected) { _, new in
                DebugLog.log("ItemView", "\(item.title) selection changed: \(new)")
            }
            .onAppear {
                DebugLog.log("ItemView", "appear \(item.title), selected: \(isSelected)")
            }
            .onDisappear {
                DebugLog.log("ItemView", "disappear \(item.title)")
            }
    }
}

// MARK: - Trash Drop Zone (off-canvas removal)

private struct TrashDropZone: View {
    var onDropItem: (UUID) -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "trash")
                .imageScale(.large)
            Text("Trash")
                .font(.subheadline)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.red.opacity(0.2) : Color.gray.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovering ? Color.red : Color.clear, lineWidth: 2)
        )
        .onDrop(of: [UTType.testItemID], isTargeted: $isHovering) { providers in
            // Load the first UUID string and remove the item
            guard let provider = providers.first else { return false }
            var handled = false
            let group = DispatchGroup()
            group.enter()
            provider.loadDataRepresentation(forTypeIdentifier: UTType.testItemID.identifier) { data, _ in
                defer { group.leave() }
                if let data, let str = String(data: data, encoding: .utf8), let uuid = UUID(uuidString: str) {
                    handled = true
                    DispatchQueue.main.async {
                        onDropItem(uuid)
                    }
                }
            }
            group.wait()
            return handled
        }
        .accessibilityLabel("Trash Drop Zone")
        .accessibilityHint("Drag items here to remove them from the canvas")
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
}

// MARK: - Log View

struct LogView: View {
    let messages: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                            Text(message)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .id(index)
                        }
                    }
                }
                .onAppear {
                    DebugLog.log("LogView", "appear with \(messages.count) messages")
                    if !messages.isEmpty {
                        proxy.scrollTo(messages.count - 1, anchor: .bottom)
                    }
                }
                .onChange(of: messages.count) { _, new in
                    DebugLog.log("LogView", "messages.count changed: \(new)")
                    if !messages.isEmpty {
                        proxy.scrollTo(messages.count - 1, anchor: .bottom)
                    }
                }
            }
            .navigationTitle("Gesture Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        DebugLog.log("LogView", "Done tapped, dismissing")
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Date Formatter Extension

private extension DateFormatter {
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()
}

// MARK: - Preview

struct MultiGestureTestView_Previews: PreviewProvider {
    static var previews: some View {
        MultiGestureTestView()
    }
}
