//
//  DeveloperToolsView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 11/08/25.
//

import SwiftUI
import SwiftData

/// Developer Tools console for general diagnostics, utilities, and data management
struct DeveloperToolsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var cards: [Card]
    @Query private var boards: [Board]
    @Query private var boardNodes: [BoardNode]
    @Query private var sources: [Source]
    
    @State private var selectedTool: ToolCategory = .overview
    @State private var isRunningAction = false
    @State private var confirmAction: ConfirmableAction?
    @State private var actionResult: String = ""
    
    enum ToolCategory: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case storage = "Storage & Sync"
        case dataIntegrity = "Data Integrity"
        case performance = "Performance"
        case cleanup = "Cleanup"
        
        var id: String { rawValue }
        
        var systemImage: String {
            switch self {
            case .overview: return "chart.bar.doc.horizontal"
            case .storage: return "externaldrive.badge.icloud"
            case .dataIntegrity: return "checkmark.shield"
            case .performance: return "gauge.with.dots.needle.bottom.50percent"
            case .cleanup: return "trash.circle"
            }
        }
    }
    
    enum ConfirmableAction: Identifiable {
        case repairForeignNodes
        case validateAllRelationships
        case clearAllThumbnails
        case resetAllBoardTransforms
        case consolidateDuplicateSources

        var id: String {
            switch self {
            case .repairForeignNodes: return "repairForeignNodes"
            case .validateAllRelationships: return "validateAllRelationships"
            case .clearAllThumbnails: return "clearAllThumbnails"
            case .resetAllBoardTransforms: return "resetAllBoardTransforms"
            case .consolidateDuplicateSources: return "consolidateDuplicateSources"
            }
        }

        var title: String {
            switch self {
            case .repairForeignNodes: return "Repair Foreign Nodes?"
            case .validateAllRelationships: return "Validate Relationships?"
            case .clearAllThumbnails: return "Clear All Thumbnails?"
            case .resetAllBoardTransforms: return "Reset Board Transforms?"
            case .consolidateDuplicateSources: return "Consolidate Duplicate Sources?"
            }
        }

        var message: String {
            switch self {
            case .repairForeignNodes:
                return "This will remove all BoardNodes that reference foreign contexts (e.g., from previews)."
            case .validateAllRelationships:
                return "This will check all card relationships for consistency and repair broken references."
            case .clearAllThumbnails:
                return "This will delete all cached thumbnail data for all cards. Thumbnails will regenerate on demand."
            case .resetAllBoardTransforms:
                return "This will reset zoom and pan transforms for all boards to their default values."
            case .consolidateDuplicateSources:
                return "This will find Sources with identical titles and merge them. All citations will be moved to the first Source, and duplicates will be deleted."
            }
        }

        var confirmLabel: String {
            switch self {
            case .repairForeignNodes: return "Repair"
            case .validateAllRelationships: return "Validate"
            case .clearAllThumbnails: return "Clear"
            case .resetAllBoardTransforms: return "Reset"
            case .consolidateDuplicateSources: return "Consolidate"
            }
        }
    }
    
    var body: some View {
        #if os(visionOS) && DEBUG
        visionOSBody
        #else
        dataManagementBody
        #endif
    }
    
    // MARK: - Platform-Specific Bodies
    
    #if os(visionOS) && DEBUG
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @State private var showEraseConfirmation = false
    @State private var isErasing = false
    
    private var visionOSBody: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Developer utilities for testing and diagnostics.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section("Live Data Diagnostics") {
                    NavigationLink {
                        RecentEdgesDiagnosticsView()
                    } label: {
                        Label("Recent Edges", systemImage: "arrow.triangle.branch")
                    }
                    
                    NavigationLink {
                        RelationTypesDiagnosticsView()
                    } label: {
                        Label("Relation Types", systemImage: "arrow.left.arrow.right")
                    }
                    
                    NavigationLink {
                        StoryStructureDiagnosticsView()
                    } label: {
                        Label("Story Structures", systemImage: "list.bullet.indent")
                    }
                    
                    NavigationLink {
                        SceneProjectRelationDiagnosticsView()
                    } label: {
                        Label("Scene → Project Relations", systemImage: "arrow.right.circle")
                    }
                    
                    NavigationLink {
                        DeveloperBoardsView()
                    } label: {
                        Label("Boards", systemImage: "rectangle.split.3x1")
                    }
                }
                
                Section("Maintenance") {
                    NavigationLink {
                        FixIncompleteRelationshipsView()
                    } label: {
                        Label("Fix Incomplete Relationships", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showEraseConfirmation = true
                    } label: {
                        Label("Erase Database and Reseed", systemImage: "trash.circle.fill")
                    }
                    .disabled(isErasing)
                } footer: {
                    if isErasing {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Erasing and reseeding…")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Developer Tools")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Done", systemImage: "xmark.circle.fill")
                    }
                }
            }
            .confirmationDialog(
                "Erase Database and Reseed?",
                isPresented: $showEraseConfirmation,
                titleVisibility: .visible
            ) {
                Button("Erase and Reseed", role: .destructive) {
                    Task {
                        await performErase()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all data, including synced CloudKit data if enabled. The app will then reseed default Relation Types and Story Structures.\n\nThis cannot be undone.")
            }
        }
    }
    
    @MainActor
    private func performErase() async {
        isErasing = true
        defer { isErasing = false }
        
        // Get the model container from the environment
        let container = modelContext.container
        await CumberlandApp.eraseAndReseed(container: container)
    }
    #endif
    
    private var dataManagementBody: some View {
        NavigationStack {
            #if os(macOS)
            HStack(spacing: 0) {
                // Left sidebar: tool categories
                List(selection: $selectedTool) {
                    ForEach(ToolCategory.allCases) { category in
                        Label(category.rawValue, systemImage: category.systemImage)
                            .tag(category)
                    }
                }
                .listStyle(.sidebar)
                .frame(minWidth: 200, idealWidth: 220, maxWidth: 240)
                
                Divider()
                
                // Right content: tool details
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        toolContent
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Developer Tools")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .status) {
                    if isRunningAction {
                        ProgressView().controlSize(.small)
                    }
                }
            }
            .confirmationDialog(
                confirmAction?.title ?? "",
                isPresented: Binding(
                    get: { confirmAction != nil },
                    set: { if !$0 { confirmAction = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let action = confirmAction {
                    Button {
                        runAction(action)
                    } label: {
                        Text(action.confirmLabel)
                    }
                }
                Button("Cancel", role: .cancel) { confirmAction = nil }
            } message: {
                Text(confirmAction?.message ?? "")
            }
            #elseif os(iOS)
            VStack(spacing: 0) {
                // Top picker: tool categories
                Picker("Tool", selection: $selectedTool) {
                    ForEach(ToolCategory.allCases) { category in
                        Label(category.rawValue, systemImage: category.systemImage)
                            .tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        toolContent
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Developer Tools")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .status) {
                    if isRunningAction {
                        ProgressView().controlSize(.small)
                    }
                }
            }
            .confirmationDialog(
                confirmAction?.title ?? "",
                isPresented: Binding(
                    get: { confirmAction != nil },
                    set: { if !$0 { confirmAction = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let action = confirmAction {
                    Button {
                        runAction(action)
                    } label: {
                        Text(action.confirmLabel)
                    }
                }
                Button("Cancel", role: .cancel) { confirmAction = nil }
            } message: {
                Text(confirmAction?.message ?? "")
            }
            #endif
        }
    }
    
    // MARK: - Tool Content
    
    @ViewBuilder
    private var toolContent: some View {
        switch selectedTool {
        case .overview:
            overviewContent
        case .storage:
            storageContent
        case .dataIntegrity:
            dataIntegrityContent
        case .performance:
            performanceContent
        case .cleanup:
            cleanupContent
        }
    }
    
    // MARK: - Overview
    
    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Database Overview")
                .font(.title2.bold())
            
            GroupBox("Statistics") {
                VStack(alignment: .leading, spacing: 12) {
                    statRow("Total Cards", value: "\(cards.count)")
                    statRow("Total Boards", value: "\(boards.count)")
                    statRow("Total Board Nodes", value: "\(boardNodes.count)")
                    statRow("Total Sources", value: "\(sources.count)")

                    Divider()

                    ForEach(Kinds.orderedCases.filter { $0 != .structure }, id: \.self) { kind in
                        let count = cards.filter { $0.kind == kind }.count
                        statRow(kind.title, value: "\(count)")
                    }
                }
                .padding(.vertical, 4)
            }
            
            GroupBox("Health Checks") {
                VStack(alignment: .leading, spacing: 12) {
                    healthRow(
                        "Orphan Board Nodes",
                        status: orphanNodeCount == 0 ? .healthy : .warning,
                        detail: "\(orphanNodeCount) found"
                    )
                    
                    healthRow(
                        "Empty Boards",
                        status: emptyBoardCount == 0 ? .healthy : .info,
                        detail: "\(emptyBoardCount) found"
                    )
                    
                    healthRow(
                        "Cards with Thumbnails",
                        status: .info,
                        detail: "\(cardsWithThumbnails) of \(cards.count)"
                    )
                }
                .padding(.vertical, 4)
            }
            
            if !actionResult.isEmpty {
                GroupBox("Last Action Result") {
                    Text(actionResult)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    // MARK: - Storage & Sync
    
    @State private var storageInfo: String = "Loading..."
    @State private var storeLocations: [String] = []
    
    private var storageContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Storage & Sync")
                .font(.title2.bold())
            
            Text("Diagnostic information about where your data is stored and sync status.")
                .foregroundStyle(.secondary)
            
            GroupBox("Data Storage") {
                VStack(alignment: .leading, spacing: 12) {
                    statRow("Total Cards", value: "\(cards.count)")
                    statRow("Configuration", value: isCloudKitEnabled ? "CloudKit" : "Local Only")
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Application Support Directory:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                            Text(appSupport.path)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    if !storeLocations.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Store Files Found:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            ForEach(storeLocations, id: \.self) { location in
                                Text(location)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            GroupBox("Sync Status") {
                VStack(alignment: .leading, spacing: 12) {
                    healthRow(
                        "CloudKit",
                        status: isCloudKitEnabled ? .healthy : .warning,
                        detail: isCloudKitEnabled ? "Enabled" : "Disabled (Debug Build)"
                    )
                    
                    statRow("Bundle ID", value: bundleID)
                    statRow("CloudKit Container", value: "iCloud.CumberlandCloud")
                }
                .padding(.vertical, 4)
            }
            
            HStack(spacing: 12) {
                Button {
                    scanStorageLocations()
                } label: {
                    Label("Refresh Storage Info", systemImage: "arrow.clockwise")
                }
                
                Button {
                    openInFinder()
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                }
            }
        }
        .onAppear {
            scanStorageLocations()
        }
    }
    
    private var isCloudKitEnabled: Bool {
        #if DEBUG
        return false // CloudKit disabled in debug builds
        #else
        return true
        #endif
    }
    
    private var bundleID: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }
    
    private func scanStorageLocations() {
        storeLocations = []
        
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            storageInfo = "❌ Could not find Application Support directory"
            return
        }
        
        let fm = FileManager.default
        
        // Look for .store files
        if let enumerator = fm.enumerator(at: appSupport, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                let filename = fileURL.lastPathComponent
                
                if filename.hasSuffix(".store") || 
                   filename.hasSuffix(".store-wal") || 
                   filename.hasSuffix(".store-shm") {
                    
                    // Get file size
                    if let attrs = try? fm.attributesOfItem(atPath: fileURL.path),
                       let size = attrs[.size] as? Int64 {
                        let formatter = ByteCountFormatter()
                        formatter.countStyle = .file
                        let sizeStr = formatter.string(fromByteCount: size)
                        storeLocations.append("\(filename) (\(sizeStr))")
                    } else {
                        storeLocations.append(filename)
                    }
                }
            }
        }
        
        if storeLocations.isEmpty {
            storageInfo = "⚠️ No .store files found in Application Support"
        } else {
            storageInfo = "✓ Found \(storeLocations.count) store file(s)"
        }
    }
    
    private func openInFinder() {
        #if os(macOS)
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: appSupport.path)
        }
        #endif
    }
    
    // MARK: - Data Integrity
    
    private var dataIntegrityContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Integrity")
                .font(.title2.bold())

            Text("Tools to validate and repair data consistency issues.")
                .foregroundStyle(.secondary)

            GroupBox("Board Integrity") {
                VStack(spacing: 12) {
                    actionButton(
                        title: "Repair Foreign Board Nodes",
                        description: "Remove BoardNodes from foreign contexts (e.g., previews)",
                        systemImage: "wrench.and.screwdriver"
                    ) {
                        confirmAction = .repairForeignNodes
                    }

                    actionButton(
                        title: "Validate All Relationships",
                        description: "Check and repair broken card relationships",
                        systemImage: "link.badge.plus"
                    ) {
                        confirmAction = .validateAllRelationships
                    }
                }
                .padding(.vertical, 4)
            }

            GroupBox("Source Integrity") {
                VStack(spacing: 12) {
                    // Show duplicate count
                    let duplicateInfo = duplicateSourceInfo
                    if duplicateInfo.duplicateCount > 0 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("\(duplicateInfo.duplicateCount) duplicate source(s) found (\(duplicateInfo.affectedTitles) unique titles)")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("No duplicate sources found")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }

                    actionButton(
                        title: "Consolidate Duplicate Sources",
                        description: "Merge sources with identical titles, moving all citations to one",
                        systemImage: "arrow.triangle.merge"
                    ) {
                        confirmAction = .consolidateDuplicateSources
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    /// Returns (duplicateCount, affectedTitles) - how many extra sources and how many unique titles have duplicates
    private var duplicateSourceInfo: (duplicateCount: Int, affectedTitles: Int) {
        var titleCounts: [String: Int] = [:]
        for source in sources {
            let normalizedTitle = source.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            titleCounts[normalizedTitle, default: 0] += 1
        }
        let duplicateTitles = titleCounts.filter { $0.value > 1 }
        let duplicateCount = duplicateTitles.values.reduce(0) { $0 + ($1 - 1) } // Count extras beyond the first
        return (duplicateCount, duplicateTitles.count)
    }
    
    // MARK: - Performance
    
    private var performanceContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance")
                .font(.title2.bold())
            
            Text("Monitor and optimize application performance.")
                .foregroundStyle(.secondary)
            
            GroupBox("Memory & Cache") {
                VStack(spacing: 12) {
                    statRow("Cards with cached thumbnails", value: "\(cardsWithThumbnails)")
                    statRow("Total thumbnail data", value: thumbnailDataSize)
                    
                    Divider()
                    
                    actionButton(
                        title: "Clear All Thumbnails",
                        description: "Remove all cached thumbnail data to free memory",
                        systemImage: "photo.circle.fill"
                    ) {
                        confirmAction = .clearAllThumbnails
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Cleanup
    
    private var cleanupContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cleanup")
                .font(.title2.bold())
            
            Text("Remove unused data and reset states.")
                .foregroundStyle(.secondary)
            
            GroupBox("Board Cleanup") {
                VStack(spacing: 12) {
                    actionButton(
                        title: "Reset All Board Transforms",
                        description: "Reset zoom and pan for all boards to default",
                        systemImage: "arrow.uturn.backward.circle"
                    ) {
                        confirmAction = .resetAllBoardTransforms
                    }
                    
                    actionButton(
                        title: "Purge Empty Boards",
                        description: "Delete boards with no nodes",
                        systemImage: "trash"
                    ) {
                        purgeEmptyBoards()
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    enum HealthStatus {
        case healthy
        case warning
        case info
        
        var color: Color {
            switch self {
            case .healthy: return .green
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .healthy: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    private func healthRow(_ label: String, status: HealthStatus, detail: String) -> some View {
        HStack {
            Image(systemName: status.icon)
                .foregroundStyle(status.color)
                .font(.caption)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func actionButton(
        title: String,
        description: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isRunningAction)
    }
    
    // MARK: - Computed Properties
    
    private var orphanNodeCount: Int {
        boardNodes.filter { node in
            node.board == nil || node.card == nil
        }.count
    }
    
    private var emptyBoardCount: Int {
        boards.filter { ($0.nodes?.count ?? 0) == 0 }.count
    }
    
    private var cardsWithThumbnails: Int {
        cards.filter { $0.thumbnailData != nil }.count
    }
    
    private var thumbnailDataSize: String {
        let totalBytes = cards.reduce(0) { $0 + ($1.thumbnailData?.count ?? 0) }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalBytes))
    }
    
    // MARK: - Actions
    
    private func runAction(_ action: ConfirmableAction) {
        isRunningAction = true
        actionResult = ""
        
        Task { @MainActor in
            defer {
                isRunningAction = false
                confirmAction = nil
            }
            
            switch action {
            case .repairForeignNodes:
                DataRepair.repairForeignBoardNodes(in: modelContext)
                actionResult = "✓ Foreign board nodes repaired"
                
            case .validateAllRelationships:
                var fixedCount = 0
                for card in cards {
                    // Validate outgoing edges
                    if let outgoing = card.outgoingEdges {
                        let invalidOutgoing = outgoing.filter { $0.from == nil || $0.to == nil || $0.type == nil }
                        fixedCount += invalidOutgoing.count
                        invalidOutgoing.forEach { modelContext.delete($0) }
                    }
                    
                    // Validate incoming edges
                    if let incoming = card.incomingEdges {
                        let invalidIncoming = incoming.filter { $0.from == nil || $0.to == nil || $0.type == nil }
                        fixedCount += invalidIncoming.count
                        invalidIncoming.forEach { modelContext.delete($0) }
                    }
                }
                try? modelContext.save()
                actionResult = "✓ Validated relationships (\(fixedCount) issues fixed)"
                
            case .clearAllThumbnails:
                var clearedCount = 0
                for card in cards {
                    if card.thumbnailData != nil {
                        card.thumbnailData = nil
                        clearedCount += 1
                    }
                }
                try? modelContext.save()
                actionResult = "✓ Cleared \(clearedCount) thumbnails"
                
            case .resetAllBoardTransforms:
                for board in boards {
                    board.zoomScale = 1.0
                    board.panX = 0
                    board.panY = 0
                    board.clampState()
                }
                try? modelContext.save()
                actionResult = "✓ Reset transforms for \(boards.count) boards"

            case .consolidateDuplicateSources:
                let result = consolidateDuplicateSources()
                actionResult = result
            }
        }
    }

    /// Consolidates duplicate Sources by merging those with identical titles.
    /// All citations from duplicates are moved to the primary Source, then duplicates are deleted.
    @MainActor
    private func consolidateDuplicateSources() -> String {
        // Group sources by normalized title (case-insensitive, trimmed)
        var titleGroups: [String: [Source]] = [:]
        for source in sources {
            let normalizedTitle = source.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            titleGroups[normalizedTitle, default: []].append(source)
        }

        var mergedCount = 0
        var deletedCount = 0

        for (_, group) in titleGroups where group.count > 1 {
            // Sort by: has sourceCard first, then by citation count (descending), then by id for stability
            let sorted = group.sorted { a, b in
                // Prefer one with a sourceCard link
                if (a.sourceCard != nil) != (b.sourceCard != nil) {
                    return a.sourceCard != nil
                }
                // Then prefer one with more citations
                let aCount = a.citations?.count ?? 0
                let bCount = b.citations?.count ?? 0
                if aCount != bCount {
                    return aCount > bCount
                }
                // Then prefer one with more metadata
                let aMetadata = [a.authors, a.publisher ?? "", a.doi ?? "", a.url ?? ""].filter { !$0.isEmpty }.count
                let bMetadata = [b.authors, b.publisher ?? "", b.doi ?? "", b.url ?? ""].filter { !$0.isEmpty }.count
                if aMetadata != bMetadata {
                    return aMetadata > bMetadata
                }
                return a.id.uuidString < b.id.uuidString
            }

            let primary = sorted[0]
            let duplicates = Array(sorted.dropFirst())

            for duplicate in duplicates {
                // Move all citations from duplicate to primary
                if let citations = duplicate.citations {
                    for citation in citations {
                        citation.source = primary
                        mergedCount += 1
                    }
                }

                // Merge metadata from duplicate to primary if primary is missing it
                if primary.authors.isEmpty && !duplicate.authors.isEmpty {
                    primary.authors = duplicate.authors
                }
                if primary.publisher == nil && duplicate.publisher != nil {
                    primary.publisher = duplicate.publisher
                }
                if primary.year == nil && duplicate.year != nil {
                    primary.year = duplicate.year
                }
                if primary.doi == nil && duplicate.doi != nil {
                    primary.doi = duplicate.doi
                }
                if primary.url == nil && duplicate.url != nil {
                    primary.url = duplicate.url
                }
                if primary.containerTitle == nil && duplicate.containerTitle != nil {
                    primary.containerTitle = duplicate.containerTitle
                }
                if primary.volume == nil && duplicate.volume != nil {
                    primary.volume = duplicate.volume
                }
                if primary.issue == nil && duplicate.issue != nil {
                    primary.issue = duplicate.issue
                }
                if primary.pages == nil && duplicate.pages != nil {
                    primary.pages = duplicate.pages
                }
                if primary.license == nil && duplicate.license != nil {
                    primary.license = duplicate.license
                }
                if primary.accessedDate == nil && duplicate.accessedDate != nil {
                    primary.accessedDate = duplicate.accessedDate
                }
                if primary.notes == nil && duplicate.notes != nil {
                    primary.notes = duplicate.notes
                } else if let primaryNotes = primary.notes, let dupNotes = duplicate.notes, !dupNotes.isEmpty {
                    // Append notes if both have them
                    primary.notes = primaryNotes + "\n\n[Merged from duplicate]: " + dupNotes
                }

                // Delete the duplicate source
                modelContext.delete(duplicate)
                deletedCount += 1
            }
        }

        try? modelContext.save()

        if deletedCount == 0 {
            return "✓ No duplicate sources found"
        } else {
            return "✓ Consolidated \(deletedCount) duplicate source(s), moved \(mergedCount) citation(s)"
        }
    }

    private func purgeEmptyBoards() {
        isRunningAction = true
        actionResult = ""
        
        Task { @MainActor in
            defer { isRunningAction = false }
            
            DataRepair.purgeEmptyBoards(in: modelContext)
            actionResult = "✓ Purged empty boards"
        }
    }
}

// MARK: - Preview

#Preview("Developer Tools") {
    let schema = Schema([Card.self, Board.self, BoardNode.self, Source.self, Citation.self])
    let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [cfg])
    let ctx = container.mainContext
    
    // Add some sample data
    let p1 = Card(kind: .projects, name: "Project Alpha", subtitle: "A story", detailedText: "")
    let c1 = Card(kind: .characters, name: "Alice", subtitle: "", detailedText: "")
    let c2 = Card(kind: .characters, name: "Bob", subtitle: "", detailedText: "")
    
    ctx.insert(p1)
    ctx.insert(c1)
    ctx.insert(c2)
    
    let board = Board(name: "Test Board", primaryCard: p1)
    ctx.insert(board)
    
    try? ctx.save()
    
    return DeveloperToolsView()
        .modelContainer(container)
        .frame(width: 800, height: 600)
}
