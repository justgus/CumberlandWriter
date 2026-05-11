//
//  CumberlandApp.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/10/25.
//
//  App entry point. Configures SwiftData container with CloudKit sync, applies
//  color scheme preferences, injects the ServiceContainer, and seeds default
//  RelationTypes on first launch. Registers the developer erase-and-reseed
//  notification and hosts the RootView / ContentView hierarchy.
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

    // ER-0022 Phase 4: Service container for dependency injection
    @State private var serviceContainer: ServiceContainer?

    // ER-0037: Theme manager for theming system
    @StateObject private var themeManager = ThemeManager()

    // MARK: - Shared Container (test access)

    /// The process-wide ModelContainer, set during app init.
    /// Tests running in the hosted test bundle can use this instead of creating
    /// their own container (which would cause SwiftData schema conflicts).
    @MainActor static private(set) var sharedContainer: ModelContainer?

    // ER-0058 Phase 2: Refactored container creation using ModelContainerFactory
    // Supports test overrides, user preferences, and safe fallback (first launch only)
    private static func makeContainer() -> ModelContainer {
        return ModelContainerFactory.makeContainer()
    }

    @State private var modelContainer: ModelContainer = {
        let container = makeContainer()
        sharedContainer = container
        return container
    }()

    // Map persisted raw value to ColorScheme for app-wide application
    private var appPreferredColorScheme: ColorScheme? {
        ColorSchemePreference(rawValue: colorSchemeRaw)?.resolvedColorScheme
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .modelContainer(modelContainer)
                .serviceContainer(serviceContainer ?? ServiceContainer(modelContext: modelContainer.mainContext))
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                #if os(macOS)
                .toolbarBackground(themeManager.currentTheme.colors.surfaceGlass.toolbarShapeStyle, for: .windowToolbar)
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
                    // ER-0022 Phase 4: Initialize service container if not already done
                    if serviceContainer == nil {
                        serviceContainer = ServiceContainer(modelContext: modelContainer.mainContext)
                    }

                    // Run all data integrity checks and seeding operations
                    await DataIntegrityManager(container: modelContainer).runAllStartupChecks()

                    // DR-xxxx: One-time cleanup of NSSplitView frame bloat in UserDefaults
                    let splitViewCleanupKey = "didCleanupNSSplitViewFrames_v1"
                    if !UserDefaults.standard.bool(forKey: splitViewCleanupKey) {
                        CumberlandApp.cleanupNSSplitViewFrames()

                        #if DEBUG
                        print("🧹 [App] NSSplitView frame cleanup complete")
                        #endif

                        // Set flag to prevent re-running
                        UserDefaults.standard.set(true, forKey: splitViewCleanupKey)
                    }
                }
                // Developer-triggered destructive reset (macOS menu posts a notification)
                .onReceive(NotificationCenter.default.publisher(for: .eraseAndReseed)) { _ in
                    Task { @MainActor in
                        await CumberlandApp.eraseAndReseed(container: modelContainer)
                    }
                }
        }
        .commands {
            #if os(macOS)
            AboutCommands()
            #endif
            PreferencesCommands()
            #if DEBUG && os(macOS)
            DeveloperCommands()
            #endif
            #if os(macOS)
            // New: Editor command to insert default author into the focused Author field.
            EditorCommands()
            #endif
        }

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
        // DR-0100: Suppressed on launch
        WindowGroup(for: AppModel.CardEditorRequest.self) { $request in
            if let request {
                CardEditorWindowView(editorRequest: request)
                    .environment(appModel)
                    .modelContainer(modelContainer)
                    .serviceContainer(serviceContainer ?? ServiceContainer(modelContext: modelContainer.mainContext))
                    .themeEnvironment(themeManager)
                    .preferredColorScheme(appPreferredColorScheme)
            }
        }
        .defaultSize(width: 840, height: 780)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        #endif

        #if os(visionOS)
        // Settings window for visionOS (full window, not modal sheet)
        // DR-0100: Suppressed on launch
        Window("Settings", id: "settings") {
            SettingsView()
                .modelContainer(modelContainer)
                .serviceContainer(serviceContainer ?? ServiceContainer(modelContext: modelContainer.mainContext))
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 720, minHeight: 640)
        }
        .windowStyle(.plain)
        .defaultSize(width: 800, height: 700)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        #endif

        #if os(visionOS) && DEBUG
        // Developer Tools window for visionOS
        // DR-0100: Suppressed on launch
        Window("Developer Tools", id: "dev.tools") {
            DeveloperToolsView()
                .modelContainer(modelContainer)
                .serviceContainer(serviceContainer ?? ServiceContainer(modelContext: modelContainer.mainContext))
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 520, minHeight: 480)
        }
        .windowStyle(.plain)
        .defaultSize(width: 600, height: 600)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        #endif

        #if os(macOS)
        // Dedicated Settings/Preferences window for macOS
        // DR-0030: Accessible via Cumberland > Preferences... menu (Cmd+,)
        // DR-0100: Suppressed on launch so only the main window opens on restart
        Window("Preferences", id: "settings") {
            SettingsView()
                .modelContainer(modelContainer)
                .serviceContainer(serviceContainer ?? ServiceContainer(modelContext: modelContainer.mainContext))
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 520, minHeight: 380)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        // About window scene for macOS
        // DR-0100: Suppressed on launch
        Window("About Cumberland", id: "about") {
            AboutView()
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 420, minHeight: 260)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        #if DEBUG
        // Developer Tools window for macOS (consolidated utilities)
        // DR-0100: Suppressed on launch
        Window("Developer Tools", id: "dev.tools") {
            DeveloperToolsView()
                .modelContainer(modelContainer)
                .serviceContainer(serviceContainer ?? ServiceContainer(modelContext: modelContainer.mainContext))
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 600, minHeight: 500)
        }
        .defaultSize(width: 800, height: 600)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        #endif

        #if os(macOS) || os(visionOS)
        // Temporal editor window for macOS and visionOS
        // DR-0061: Using window instead of sheet to fix rendering issues
        // DR-0100: Suppressed on launch
        WindowGroup(for: AppModel.TemporalEditorRequest.self) { $request in
            if let request {
                TemporalEditorWindowView(editorRequest: request)
                    .modelContainer(modelContainer)
                    .serviceContainer(serviceContainer ?? ServiceContainer(modelContext: modelContainer.mainContext))
                    .themeEnvironment(themeManager)
                    .preferredColorScheme(appPreferredColorScheme)
            }
        }
        .defaultSize(width: 560, height: 640)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        // Timeline view window for Phase 6: Timeline Integration
        // Manuscript → Timeline navigation
        WindowGroup(for: AppModel.TimelineViewRequest.self) { $request in
            if let request {
                let context = modelContainer.mainContext
                if let timeline = try? context.fetch(FetchDescriptor<Card>(
                    predicate: #Predicate { $0.id == request.timelineID }
                )).first {
                    TimelineChartView(timeline: timeline)
                        .modelContainer(modelContainer)
                        .serviceContainer(serviceContainer ?? ServiceContainer(modelContext: modelContainer.mainContext))
                        .themeEnvironment(themeManager)
                        .preferredColorScheme(appPreferredColorScheme)
                }
            }
        }
        .defaultSize(width: 900, height: 700)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        // Manuscript view window for Phase 6: Timeline Integration
        // Timeline → Manuscript navigation
        WindowGroup(for: AppModel.ManuscriptViewRequest.self) { $request in
            if let request {
                let context = modelContainer.mainContext
                if let project = try? context.fetch(FetchDescriptor<Card>(
                    predicate: #Predicate { $0.id == request.projectID }
                )).first {
                    ManuscriptWritingSurfaceView(project: project)
                        .modelContainer(modelContainer)
                        .serviceContainer(serviceContainer ?? ServiceContainer(modelContext: modelContainer.mainContext))
                        .themeEnvironment(themeManager)
                        .preferredColorScheme(appPreferredColorScheme)
                }
            }
        }
        .defaultSize(width: 1000, height: 800)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        #endif

        // Developer diagnostic windows (DEBUG only, some use in-memory samples, some live)
        // DR-0100: All diagnostic windows suppressed on launch
        #if DEBUG
        // Existing sample-backed diagnostics
        Window("Diagnostics: Swimlane Viewer", id: "dev.swimlane") {
            DevSwimlaneWindow()
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 960, minHeight: 560)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        Window("Diagnostics: Card Relationship", id: "dev.cardRelationship") {
            DevCardRelationshipWindow()
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 880, minHeight: 560)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        Window("Diagnostics: Card Sheet", id: "dev.cardSheet") {
            DevCardSheetWindow()
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 720, minHeight: 560)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        Window("Diagnostics: Image Attribution", id: "dev.imageAttribution") {
            DevImageAttributionWindow()
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 560, minHeight: 460)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        // Diagnostics that use the live ModelContainer
        Window("Diagnostics: Recent Edges", id: "dev.recentEdges") {
            RecentEdgesDiagnosticsView()
                .modelContainer(modelContainer) // live container
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 720, minHeight: 520)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        Window("Diagnostics: Relation Types", id: "dev.relationTypes") {
            RelationTypesDiagnosticsView()
                .modelContainer(modelContainer) // live container
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 720, minHeight: 520)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        Window("Diagnostics: Story Structure", id: "dev.storyStructure") {
            StoryStructureDiagnosticsView()
                .modelContainer(modelContainer) // live container
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 720, minHeight: 520)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        Window("Diagnostics: Scene → Project Relations", id: "dev.sceneProjectRelations") {
            SceneProjectRelationDiagnosticsView()
                .modelContainer(modelContainer) // live container
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 720, minHeight: 520)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        Window("Diagnostics: Fix Incomplete Relationships", id: "dev.fixInverseEdges") {
            FixIncompleteRelationshipsView()
                .modelContainer(modelContainer) // live container
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 780, minHeight: 560)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        Window("Diagnostics: Boards", id: "dev.boards") {
            DeveloperBoardsView()
                .modelContainer(modelContainer) // live container
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 920, minHeight: 560)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        // DR-0065: CalendarSystem relationship fix tool (live container)
        Window("Fix CalendarSystem Relationships (DR-0065)", id: "dev.fixCalendarRelationships") {
            CalendarSystemCleanupView()
                .modelContainer(modelContainer) // live container
                .themeEnvironment(themeManager)
                .preferredColorScheme(appPreferredColorScheme)
                .frame(minWidth: 640, minHeight: 560)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
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
    // Destructive reset: delete all data and reseed baseline templates.
    @MainActor
    public static func eraseAndReseed(container: ModelContainer) async {
        // Delegate to DataIntegrityManager for all erase and reseed operations
        do {
            try await DataIntegrityManager(container: container).eraseAndReseed()
        } catch {
            let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "Reset")
            logger.error("Erase and reseed failed: \(String(describing: error))")
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
#endif // os(macOS)

// PreferencesCommands - Available on all platforms
private struct PreferencesCommands: Commands {
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            #if os(macOS)
            Button("Preferences...") {
                openWindow(id: "settings")
            }
            .keyboardShortcut(",", modifiers: .command)
            #else
            // iOS/iPadOS: Post notification to trigger settings sheet
            Button("Preferences...") {
                NotificationCenter.default.post(name: Notification.Name("showSettings"), object: nil)
            }
            .keyboardShortcut(",", modifiers: .command)
            #endif
        }
    }
}

extension Notification.Name {
    static let showSettings = Notification.Name("showSettings")
}

#if os(macOS)
#if DEBUG
private struct DeveloperCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandMenu("Developer") {
            // Developer Tools - consolidated utility panel
            Button("Developer Tools…") {
                openWindow(id: "dev.tools")
            }
            .keyboardShortcut("D", modifiers: [.command, .shift])

            Divider()

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

            // DR-0065: Fix CalendarSystem relationships
            Button("Fix CalendarSystem Relationships (DR-0065)…") {
                openWindow(id: "dev.fixCalendarRelationships")
            }
            .keyboardShortcut("C", modifiers: [.command, .shift])

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
    return ModelContainerFactory.makeInMemoryContainer(types)
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

    @State private var isRunning: Bool = false
    @State private var report: String = ""
    @State private var createdInverseEdges: Int = 0
    @State private var createdMirrorTypes: Int = 0
    @State private var scannedEdges: Int = 0
    @State private var errors: Int = 0

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
                    Text(report.isEmpty ? "No report yet. Click \"Scan and Fix\" to begin." : report)
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

        // Delegate to DataIntegrityManager
        let repairResult = await DataIntegrityManager(container: modelContext.container).repairIncompleteRelationships()

        // Update UI state from repair result
        scannedEdges = repairResult.scannedEdges
        createdInverseEdges = repairResult.createdInverseEdges
        createdMirrorTypes = repairResult.createdMirrorTypes
        errors = repairResult.errors
        report = repairResult.detailedLog
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

            // DISABLE AppKit's automatic frame autosave to prevent UserDefaults bloat.
            // AppKit creates unique keys based on SwiftUI's view hierarchy type names,
            // which include memory addresses and change on every launch, accumulating
            // thousands of keys. We manage frame persistence manually via frameKey.
            window.setFrameAutosaveName("")

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

// MARK: - UserDefaults Cleanup

extension CumberlandApp {
    /// Removes accumulated autosave keys from UserDefaults that were created by AppKit/SwiftUI.
    ///
    /// **Problem**: SwiftUI's NavigationSplitView and NSWindow automatic frame persistence
    /// create unique keys based on the view hierarchy's type names. These type names include
    /// memory addresses (e.g., `unknown context at $1234567`) that change on every launch,
    /// causing thousands of orphaned keys to accumulate in UserDefaults.
    ///
    /// **Impact**: The accumulated keys bloated UserDefaults to nearly 4MB (>1,979 keys),
    /// triggering the "Attempting to store >= 4194304 bytes" warning.
    ///
    /// **Solution**: Disable automatic persistence and manage manually with stable keys.
    /// This cleanup runs once after the fix is deployed to remove legacy entries.
    static func cleanupNSSplitViewFrames() {
        let defaults = UserDefaults.standard
        let dict = defaults.dictionaryRepresentation()

        var removedSplitView = 0
        var removedWindowFrame = 0

        for key in dict.keys {
            // Remove NSSplitView autosave keys (from NavigationSplitView)
            if key.contains("NSSplitView Subview Frames") {
                defaults.removeObject(forKey: key)
                removedSplitView += 1
            }
            // Remove NSWindow Frame autosave keys (from WindowStateBridge)
            // But preserve our manual keys (Window.mainWindow.*)
            else if key.hasPrefix("NSWindow Frame") && !key.hasPrefix("Window.") {
                defaults.removeObject(forKey: key)
                removedWindowFrame += 1
            }
        }

        #if DEBUG
        let total = removedSplitView + removedWindowFrame
        if total > 0 {
            print("🧹 UserDefaults cleanup: removed \(removedSplitView) NSSplitView keys + \(removedWindowFrame) NSWindow Frame keys = \(total) total")
        }
        #endif
    }
}
