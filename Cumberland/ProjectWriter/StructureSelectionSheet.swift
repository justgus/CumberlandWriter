//
//  StructureSelectionSheet.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-21.
//  Part of Phase 4a & 4b: Story Structure Integration - UI Components
//
//  Comprehensive structure selection and switching interface.
//  Used from both Project Dashboard and Writing Surface.
//

import SwiftUI
import SwiftData

struct StructureSelectionSheet: View {
    let project: Card
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var selectedTemplate: (name: String, elements: [String])?
    @State private var currentStructure: StoryStructure?
    @State private var mappingPreview: MappingPreview?
    @State private var isProcessing = false
    @State private var showingConfirmation = false
    @State private var showingCustomCreation = false
    @State private var highlightedBeatIndex: Int? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Template list
                templateList

                Divider()

                // Preview area
                if let selected = selectedTemplate {
                    previewArea(for: selected)
                } else {
                    emptyPreview
                }
            }
            .background(themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground())
            .navigationTitle("Select Story Structure")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCustomCreation = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Custom")
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        showingConfirmation = true
                    }
                    .disabled(selectedTemplate == nil || isProcessing)
                }
            }
            .alert("Apply Structure?", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Apply", role: .destructive) {
                    applyStructure()
                }
            } message: {
                if let preview = mappingPreview {
                    Text("This will map \(preview.sceneCount) scenes to the new structure. This action can be undone.")
                } else {
                    Text("Apply this structure to the project?")
                }
            }
            .onAppear {
                loadCurrentStructure()
            }
            .sheet(isPresented: $showingCustomCreation) {
                CustomStructureCreationSheet(project: project)
                    .onDisappear {
                        loadCurrentStructure()
                    }
            }
            .presentationBackground {
                themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground()
            }
        }
        .preferredColorScheme(preferredColorScheme)
    }

    // MARK: - Theme Support

    private var preferredColorScheme: ColorScheme? {
        // Read the app's color scheme preference from AppStorage
        @AppStorage("AppSettings.colorSchemePreferenceRaw") var colorSchemeRaw: String = "system"

        switch colorSchemeRaw {
        case "light":
            return .light
        case "dark":
            return .dark
        default: // "system"
            return nil // nil = follow system
        }
    }

    // MARK: - Template List

    private var templateList: some View {
        List(StoryStructure.predefinedTemplates, id: \.name) { template in
            Button {
                selectedTemplate = template
                generateMappingPreview(for: template)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

                        Text("\(template.elements.count) beats")
                            .font(.caption)
                            .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                    }

                    Spacer()

                    if currentStructure?.name == template.name {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(themeManager.currentTheme.colors.accentPrimary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(
                selectedTemplate?.name == template.name
                    ? themeManager.currentTheme.colors.accentPrimary.opacity(0.1)
                    : Color.clear
            )
        }
        .frame(maxWidth: 300)
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .background {
            ZStack {
                // Backplate: CODEX at 8-12% opacity
                BackplateView(subject: .codex, opacity: 0.10)

                // Surface color
                themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground()
                    .opacity(0.85)
            }
        }
    }

    // MARK: - Preview Area

    private func previewArea(for template: (name: String, elements: [String])) -> some View {
        VStack(spacing: 0) {
            // Top section: Arc and beats side-by-side (no scrolling)
            HStack(alignment: .top, spacing: 24) {
                // Arc visualization (left side, takes ~40% width)
                arcVisualization(for: template)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Beat list (right side, takes ~60% width, but compact)
                beatList(for: template)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
            .frame(maxHeight: .infinity)

            // Bottom section: Mapping preview (scrollable if needed)
            if let preview = mappingPreview, preview.sceneCount > 0 {
                Divider()

                ScrollView {
                    mappingPreviewSection(preview)
                        .padding(24)
                }
                .frame(maxHeight: 200)
            }
        }
    }

    private var emptyPreview: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 48))
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

            Text("Select a structure to preview")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func arcVisualization(for template: (name: String, elements: [String])) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Narrative Arc")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

            // Create temporary structure to get arc
            let tempStructure = StoryStructure(name: template.name, projectID: nil)
            let arc = tempStructure.narrativeArc

            // Generate arc segments
            let segments = template.elements.enumerated().map { index, name in
                let startPos = Double(index) / Double(max(1, template.elements.count - 1))
                let endPos = index < template.elements.count - 1
                    ? Double(index + 1) / Double(max(1, template.elements.count - 1))
                    : 1.0

                return ArcSegment(
                    startPosition: startPos,
                    endPosition: endPos,
                    startTension: arc.tension(at: startPos),
                    endTension: arc.tension(at: endPos),
                    sceneCount: 0, // No scenes in preview
                    beatLabel: name,
                    beatID: nil
                )
            }

            NarrativeArcVisualization(
                arc: arc,
                segments: segments,
                activePositionFraction: nil,
                height: 180,
                highlightedSegmentIndex: highlightedBeatIndex,
                onSegmentTap: { index in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        highlightedBeatIndex = (highlightedBeatIndex == index) ? nil : index
                    }
                }
            )
            .frame(height: 180)
            .padding(.horizontal, 20)
        }
    }

    private func beatList(for template: (name: String, elements: [String])) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Structure Beats (\(template.elements.count))")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                ForEach(Array(template.elements.enumerated()), id: \.offset) { index, beatName in
                    beatBadge(beatName, displayIndex: index + 1, actualIndex: index)
                }
            }
        }
    }

    private func beatBadge(_ name: String, displayIndex: Int, actualIndex: Int) -> some View {
        let isHighlighted = highlightedBeatIndex == actualIndex

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                highlightedBeatIndex = (highlightedBeatIndex == actualIndex) ? nil : actualIndex
            }
        } label: {
            HStack(spacing: 6) {
                Text("\(displayIndex)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(
                        isHighlighted
                            ? Color.white
                            : themeManager.currentTheme.colors.accentPrimary
                    )
                    .frame(width: 20, height: 20)
                    .background(
                        Circle().fill(
                            isHighlighted
                                ? themeManager.currentTheme.colors.accentPrimary
                                : themeManager.currentTheme.colors.accentPrimary.opacity(0.2)
                        )
                    )

                Text(name)
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground())
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isHighlighted
                            ? themeManager.currentTheme.colors.accentPrimary
                            : Color.clear,
                        lineWidth: 2
                    )
            )
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func mappingPreviewSection(_ preview: MappingPreview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scene Mapping Preview")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

            HStack(spacing: 16) {
                statBadge(
                    icon: "text.badge.checkmark",
                    value: "\(preview.sceneCount)",
                    label: "Scenes"
                )

                if preview.averageMatchQuality > 0 {
                    statBadge(
                        icon: "chart.line.uptrend.xyaxis",
                        value: "\(Int(preview.averageMatchQuality * 100))%",
                        label: "Match Quality"
                    )
                }

                if preview.warnings.count > 0 {
                    statBadge(
                        icon: "exclamationmark.triangle",
                        value: "\(preview.warnings.count)",
                        label: "Warnings",
                        color: .orange
                    )
                }
            }

            if !preview.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(preview.warnings.prefix(3).enumerated()), id: \.offset) { _, warning in
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)

                            Text(warning)
                                .font(.caption)
                                .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                        }
                    }

                    if preview.warnings.count > 3 {
                        Text("... and \(preview.warnings.count - 3) more")
                            .font(.caption2)
                            .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
                            .padding(.leading, 20)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
    }

    private func statBadge(
        icon: String,
        value: String,
        label: String,
        color: Color? = nil
    ) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
            }
            .foregroundStyle(color ?? themeManager.currentTheme.colors.accentPrimary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground(cornerRadius: 8)
        )
    }

    // MARK: - Data Loading

    private func loadCurrentStructure() {
        let projectUUID = project.id
        let descriptor = FetchDescriptor<StoryStructure>(
            predicate: #Predicate { structure in
                structure.projectID == projectUUID
            }
        )

        currentStructure = try? modelContext.fetch(descriptor).first

        // Auto-select current structure
        if let current = currentStructure,
           let template = StoryStructure.predefinedTemplates.first(where: { $0.name == current.name }) {
            selectedTemplate = template
            generateMappingPreview(for: template)
        }
    }

    private func generateMappingPreview(for template: (name: String, elements: [String])) {
        guard let current = currentStructure,
              current.name != template.name else {
            // Same structure - no mapping needed
            mappingPreview = nil
            return
        }

        // Count scenes in current structure
        let sceneCount = current.elements?.reduce(0) { count, element in
            count + (element.assignedCards?.filter { $0.kind == .scenes }.count ?? 0)
        } ?? 0

        if sceneCount == 0 {
            mappingPreview = nil
            return
        }

        // Simulate mapping to estimate quality
        let newStructure = StoryStructure.createFromTemplate(template, for: project.id)
        let service = StructureMappingService(modelContext: modelContext)

        // Note: This is a dry-run simulation - we don't actually apply changes
        let result = simulateMapping(from: current, to: newStructure, using: service)

        mappingPreview = MappingPreview(
            sceneCount: result.mappedSceneCount,
            averageMatchQuality: calculateAverageQuality(from: result.mappings),
            warnings: result.warnings
        )
    }

    private func simulateMapping(
        from oldStructure: StoryStructure,
        to newStructure: StoryStructure,
        using service: StructureMappingService
    ) -> MappingResult {
        // Create a temporary in-memory copy to simulate without modifying real data
        // For now, just return a basic estimate
        let sceneCount = oldStructure.elements?.reduce(0) { count, element in
            count + (element.assignedCards?.filter { $0.kind == .scenes }.count ?? 0)
        } ?? 0

        return MappingResult(
            mappedSceneCount: sceneCount,
            unmappedSceneCount: 0,
            warnings: [],
            mappings: []
        )
    }

    private func calculateAverageQuality(from mappings: [SceneMapping]) -> Double {
        guard !mappings.isEmpty else { return 0.0 }
        let total = mappings.reduce(0.0) { $0 + $1.matchQuality }
        return total / Double(mappings.count)
    }

    // MARK: - Actions

    private func applyStructure() {
        guard let template = selectedTemplate else { return }

        isProcessing = true

        // Check if we're switching structures or applying first structure
        if let current = currentStructure {
            // Switch structure with mapping
            let newStructure = StoryStructure.createFromTemplate(template, for: project.id)
            modelContext.insert(newStructure)

            let service = StructureMappingService(modelContext: modelContext)
            _ = service.switchStructure(
                for: project,
                from: current,
                to: newStructure,
                strategy: .arcBased
            )

            // Delete old structure
            modelContext.delete(current)
        } else {
            // First structure - just create it
            let newStructure = StoryStructure.createFromTemplate(template, for: project.id)
            modelContext.insert(newStructure)
        }

        // Save
        try? modelContext.save()

        isProcessing = false
        dismiss()
    }
}

// MARK: - Supporting Types

private struct MappingPreview {
    let sceneCount: Int
    let averageMatchQuality: Double
    let warnings: [String]
}

// MARK: - Preview

#Preview("Structure Selection") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, StoryStructure.self, configurations: config)
    let context = container.mainContext

    let project = Card(kind: .projects, name: "The Lantern Chronicles", subtitle: "", detailedText: "")
    context.insert(project)

    let structure = StoryStructure.createFromTemplate(
        StoryStructure.predefinedTemplates.first!,
        for: project.id
    )
    context.insert(structure)

    // Add some scenes
    if let element = structure.elements?.first {
        for i in 1...5 {
            let scene = Card(kind: .scenes, name: "Scene \(i)", subtitle: "", detailedText: "")
            context.insert(scene)
            if element.assignedCards == nil {
                element.assignedCards = []
            }
            element.assignedCards?.append(scene)
        }
    }

    return StructureSelectionSheet(project: project)
        .modelContainer(container)
        .environmentObject(ThemeManager())
        .frame(width: 800, height: 600)
}
