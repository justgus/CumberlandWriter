//
//  CustomStructureCreationSheet.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-22.
//  Part of Phase 5/7: Custom Story Structure Creation
//
//  Complete workflow for creating custom story structures with custom arcs.
//

import SwiftUI
import SwiftData

struct CustomStructureCreationSheet: View {
    let project: Card
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    // Creation steps
    @State private var currentStep: CreationStep = .nameAndDescription
    @State private var canProceed = false

    // Structure data
    @State private var structureName = ""
    @State private var structureDescription = ""
    @State private var beats: [BeatDefinition] = []
    @State private var customArc = CustomArc.defaultArc(name: "Custom Arc")

    enum CreationStep: Int, CaseIterable {
        case nameAndDescription
        case defineBeats
        case designArc
        case review

        var title: String {
            switch self {
            case .nameAndDescription: return "Name & Description"
            case .defineBeats: return "Define Structure Beats"
            case .designArc: return "Design Narrative Arc"
            case .review: return "Review & Create"
            }
        }

        var instruction: String {
            switch self {
            case .nameAndDescription:
                return "Give your custom structure a name and description"
            case .defineBeats:
                return "Define the structural beats (sections) of your story"
            case .designArc:
                return "Design the dramatic tension curve for your structure"
            case .review:
                return "Review your custom structure before creating"
            }
        }
    }

    struct BeatDefinition: Identifiable, Equatable {
        let id = UUID()
        var name: String
        var description: String
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator

                Divider()

                // Step content
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("Create Custom Structure")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            updateCanProceed()
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 0) {
            ForEach(Array(CreationStep.allCases), id: \.self) { step in
                HStack(spacing: 8) {
                    // Step circle
                    ZStack {
                        Circle()
                            .fill(stepCircleColor(for: step))
                            .frame(width: 32, height: 32)

                        if step.rawValue < currentStep.rawValue {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(step.rawValue + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(step == currentStep ? .white : themeManager.currentTheme.colors.textSecondary)
                        }
                    }

                    // Step title
                    if step == currentStep {
                        Text(step.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                    }

                    // Connector line
                    if step != CreationStep.allCases.last {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue
                                ? themeManager.currentTheme.colors.accentPrimary
                                : themeManager.currentTheme.colors.textTertiary.opacity(0.2)
                            )
                            .frame(height: 2)
                            .frame(maxWidth: step == currentStep ? 20 : .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func stepCircleColor(for step: CreationStep) -> Color {
        if step.rawValue < currentStep.rawValue {
            return themeManager.currentTheme.colors.accentPrimary
        } else if step == currentStep {
            return themeManager.currentTheme.colors.accentPrimary
        } else {
            return themeManager.currentTheme.colors.textTertiary.opacity(0.3)
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Step instruction
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentStep.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

                    Text(currentStep.instruction)
                        .font(.subheadline)
                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                }

                Divider()

                // Step-specific content
                switch currentStep {
                case .nameAndDescription:
                    nameAndDescriptionStep
                case .defineBeats:
                    defineBeatsStep
                case .designArc:
                    designArcStep
                case .review:
                    reviewStep
                }
            }
            .padding(24)
        }
    }

    // MARK: - Step 1: Name & Description

    private var nameAndDescriptionStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Structure Name")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

                TextField("e.g., Five-Act Mystery Structure", text: $structureName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: structureName) { _, _ in updateCanProceed() }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

                TextField("Describe the purpose and use of this structure", text: $structureDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }

            // Example templates
            VStack(alignment: .leading, spacing: 8) {
                Text("Start from Template:")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

                HStack(spacing: 12) {
                    templateButton(name: "Three-Act", beats: ["Act 1", "Act 2", "Act 3"])
                    templateButton(name: "Five-Act", beats: ["Exposition", "Rising", "Climax", "Falling", "Resolution"])
                    templateButton(name: "Start Blank", beats: ["Opening", "Middle", "Ending"])
                }
            }
        }
    }

    private func templateButton(name: String, beats: [String]) -> some View {
        Button {
            self.beats = beats.map { BeatDefinition(name: $0, description: "") }
            updateCanProceed()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.title3)
                Text(name)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground(cornerRadius: 8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: Define Beats

    private var defineBeatsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Beats list
            if beats.isEmpty {
                emptyBeatsPrompt
            } else {
                ForEach(Array(beats.enumerated()), id: \.offset) { index, beat in
                    beatRow(for: beat, at: index)
                }
            }

            // Add beat button
            Button {
                beats.append(BeatDefinition(name: "New Beat", description: ""))
                updateCanProceed()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Beat")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground(cornerRadius: 8)
                )
            }
            .buttonStyle(.plain)

            // Info
            Text("💡 Tip: Define at least 3 beats for a meaningful structure")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                .padding(.top, 8)
        }
    }

    private var emptyBeatsPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

            Text("No beats defined yet")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.colors.textSecondary)

            Text("Add structural beats to organize your story")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func beatRow(for beat: BeatDefinition, at index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index + 1).")
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
                    .frame(width: 30, alignment: .leading)

                TextField("Beat Name", text: Binding(
                    get: { beat.name },
                    set: { beats[index].name = $0; updateCanProceed() }
                ))
                .textFieldStyle(.roundedBorder)

                Button(role: .destructive) {
                    beats.remove(at: index)
                    updateCanProceed()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            }

            HStack {
                Spacer()
                    .frame(width: 30)

                TextField("Description (optional)", text: Binding(
                    get: { beat.description },
                    set: { beats[index].description = $0 }
                ), axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...3)
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Step 3: Design Arc

    private var designArcStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Design your narrative arc by dragging control points to shape the dramatic tension curve.")
                .font(.subheadline)
                .foregroundStyle(themeManager.currentTheme.colors.textSecondary)

            CustomArcEditorView(customArc: $customArc)
        }
    }

    // MARK: - Step 4: Review

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Structure info
            reviewSection(title: "Structure Information") {
                VStack(alignment: .leading, spacing: 8) {
                    reviewRow(label: "Name", value: structureName)
                    if !structureDescription.isEmpty {
                        reviewRow(label: "Description", value: structureDescription)
                    }
                }
            }

            // Beats
            reviewSection(title: "Structure Beats (\(beats.count))") {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(beats.enumerated()), id: \.offset) { index, beat in
                        HStack(spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
                                .frame(width: 30, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(beat.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

                                if !beat.description.isEmpty {
                                    Text(beat.description)
                                        .font(.caption)
                                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                                }
                            }
                        }
                    }
                }
            }

            // Arc preview
            reviewSection(title: "Narrative Arc") {
                NarrativeArcVisualization(
                    arc: customArc,
                    segments: previewArcSegments,
                    activePositionFraction: nil,
                    height: 150
                )
                .frame(height: 150)
            }
        }
    }

    private func reviewSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

            content()
                .padding(16)
                .background(
                    themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground(cornerRadius: 8)
                )
        }
    }

    private func reviewRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
        }
    }

    private var previewArcSegments: [ArcSegment] {
        beats.enumerated().map { index, beat in
            let startPos = Double(index) / Double(max(1, beats.count - 1))
            let endPos = index < beats.count - 1
                ? Double(index + 1) / Double(max(1, beats.count - 1))
                : 1.0

            return ArcSegment(
                startPosition: startPos,
                endPosition: endPos,
                startTension: customArc.tension(at: startPos),
                endTension: customArc.tension(at: endPos),
                sceneCount: 0,
                beatLabel: beat.name,
                beatID: nil
            )
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentStep != .nameAndDescription {
                Button {
                    withAnimation {
                        currentStep = CreationStep(rawValue: currentStep.rawValue - 1) ?? .nameAndDescription
                    }
                    updateCanProceed()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if currentStep != .review {
                Button {
                    withAnimation {
                        currentStep = CreationStep(rawValue: currentStep.rawValue + 1) ?? .review
                    }
                    updateCanProceed()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceed)
            } else {
                Button {
                    createCustomStructure()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Create Structure")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
    }

    // MARK: - Validation

    private func updateCanProceed() {
        switch currentStep {
        case .nameAndDescription:
            canProceed = !structureName.trimmingCharacters(in: .whitespaces).isEmpty
        case .defineBeats:
            canProceed = beats.count >= 2 && beats.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        case .designArc:
            canProceed = true // Arc is always valid
        case .review:
            canProceed = true // Always can create at review step
        }
    }

    // MARK: - Actions

    private func createCustomStructure() {
        // Create the structure
        let structure = StoryStructure(name: structureName, projectID: project.id)

        // Set description as custom arc description
        customArc.name = structureName
        if !structureDescription.isEmpty {
            customArc.description = structureDescription
        }

        // Store custom arc
        structure.customArc = customArc

        // Create elements
        for (index, beat) in beats.enumerated() {
            let element = StructureElement(
                name: beat.name,
                elementDescription: beat.description,
                orderIndex: index
            )
            element.storyStructure = structure
            if structure.elements == nil { structure.elements = [] }
            structure.elements?.append(element)
        }

        // Save to context
        modelContext.insert(structure)
        try? modelContext.save()

        dismiss()
    }
}

// MARK: - Preview

#Preview("Custom Structure Creation") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, StoryStructure.self, configurations: config)
    let context = container.mainContext

    let project = Card(kind: .projects, name: "The Lantern Chronicles", subtitle: "", detailedText: "")
    context.insert(project)

    return CustomStructureCreationSheet(project: project)
        .modelContainer(container)
        .environmentObject(ThemeManager())
        .frame(width: 800, height: 700)
}
