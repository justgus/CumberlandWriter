//
//  VisualElementReviewView.swift
//  Cumberland
//
//  Created for ER-0021: AI-Powered Visual Element Extraction
//  Phase 2: User Review & Editing UI
//

import SwiftUI
import OSLog

/// Sheet view for reviewing and editing extracted visual elements before image generation
/// Part of ER-0021 Phase 2: User Review & Editing UI
@MainActor
struct VisualElementReviewView: View {

    // MARK: - Properties

    /// Card description to extract visual elements from
    let cardDescription: String

    /// Card kind for contextual extraction
    let cardKind: Kinds

    /// Card name for context
    let cardName: String

    /// Selected AI provider for generation
    let provider: AIProviderProtocol

    /// Original prompt from card (optional fallback)
    let originalPrompt: String?

    /// Callback when user approves elements and wants to generate
    let onGenerate: (VisualElements) -> Void

    @Environment(\.dismiss) private var dismiss

    /// Extracted visual elements (editable)
    @State private var elements: VisualElements?

    /// Loading state
    @State private var isExtracting: Bool = true

    /// Error state
    @State private var extractionError: Error?

    /// Show advanced options
    @State private var showAdvanced: Bool = false

    /// Logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "VisualElementReviewView")

    /// Can generate image (either with extracted elements OR original prompt)
    private var canGenerate: Bool {
        if elements?.hasSufficientData == true {
            return true
        }
        // Allow generation with original prompt as fallback
        if let original = originalPrompt, !original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return false
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if isExtracting {
                    extractingView
                } else if let error = extractionError {
                    errorView(error)
                } else if let elements = elements {
                    reviewView(elements)
                } else {
                    emptyView
                }
            }
            .navigationTitle("Review Visual Elements")
            #if os(macOS)
            .navigationSubtitle(cardName)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if !isExtracting, elements != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            generateWithElements()
                        } label: {
                            Label("Generate Image", systemImage: "wand.and.stars")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(canGenerate == false)
                    }
                }
            }
        }
        .frame(minWidth: 600, idealWidth: 700,
               minHeight: 650, idealHeight: 800)
        .task {
            await extractVisualElements()
        }
    }

    // MARK: - Subviews

    /// View shown while extracting
    private var extractingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Analyzing description...")
                .font(.headline)

            Text("Extracting visual elements from narrative description")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    /// View shown on extraction error
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Extraction Failed")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await extractVisualElements()
                }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    /// Empty state view
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No visual elements extracted")
                .font(.headline)

            Text("The description may be too short or lack visual details")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    /// Main review view with editable elements
    private func reviewView(_ elements: VisualElements) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with confidence indicator
                headerView(elements)

                // Card-type-specific element groups
                switch elements.cardKind {
                case .characters:
                    characterElementsView(elements)
                case .locations:
                    locationElementsView(elements)
                case .scenes:
                    sceneElementsView(elements)
                case .artifacts:
                    artifactElementsView(elements)
                case .buildings:
                    buildingElementsView(elements)
                case .vehicles:
                    vehicleElementsView(elements)
                default:
                    genericElementsView(elements)
                }

                // Advanced options (cinematic framing)
                if showAdvanced {
                    cinematicFramingView(elements)
                }

                // Advanced toggle
                Button {
                    withAnimation {
                        showAdvanced.toggle()
                    }
                } label: {
                    HStack {
                        Label(
                            showAdvanced ? "Hide Advanced Options" : "Show Advanced Options",
                            systemImage: showAdvanced ? "chevron.up" : "chevron.down"
                        )
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

                // Preview prompt section
                previewPromptView(elements)
            }
            .padding()
        }
    }

    // MARK: - Header View

    private func headerView(_ elements: VisualElements) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.blue)
                Text("Extracted Visual Elements")
                    .font(.title2.bold())
                Spacer()

                // Confidence indicator
                confidenceBadge(elements.extractionConfidence)
            }

            Text("Review and edit the visual elements before generating your image. Only visual elements (what would appear in the image) are shown. Backstory and personality traits have been filtered out.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !elements.hasSufficientData {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Add more visual details to improve generation quality")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }

    private func confidenceBadge(_ confidence: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: confidence > 0.7 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(confidence > 0.7 ? .green : .orange)
            Text("\(Int(confidence * 100))%")
                .font(.caption.bold())
                .foregroundStyle(confidence > 0.7 ? .green : .orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (confidence > 0.7 ? Color.green : Color.orange).opacity(0.15)
        )
        .cornerRadius(6)
    }

    // MARK: - Character Elements View

    private func characterElementsView(_ elements: VisualElements) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Character Portrait Elements")

            editableField(
                title: "Physical Build",
                value: Binding(
                    get: { self.elements?.physicalBuild ?? "" },
                    set: { self.elements?.physicalBuild = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., tall, athletic, lithe",
                icon: "figure.stand"
            )

            editableField(
                title: "Hair",
                value: Binding(
                    get: { self.elements?.hair ?? "" },
                    set: { self.elements?.hair = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., long dark hair in ponytail",
                icon: "scissors"
            )

            editableField(
                title: "Eyes",
                value: Binding(
                    get: { self.elements?.eyes ?? "" },
                    set: { self.elements?.eyes = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., bright green eyes",
                icon: "eye"
            )

            editableField(
                title: "Facial Features",
                value: Binding(
                    get: { self.elements?.facialFeatures ?? "" },
                    set: { self.elements?.facialFeatures = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., strong chin, short nose",
                icon: "face.smiling"
            )

            editableField(
                title: "Skin Tone",
                value: Binding(
                    get: { self.elements?.skinTone ?? "" },
                    set: { self.elements?.skinTone = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., olive, pale, dark brown",
                icon: "paintpalette"
            )

            editableField(
                title: "Clothing",
                value: Binding(
                    get: { self.elements?.clothing ?? "" },
                    set: { self.elements?.clothing = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., orange astronaut jumpsuit",
                icon: "tshirt"
            )

            editableField(
                title: "Accessories",
                value: Binding(
                    get: { self.elements?.accessories?.joined(separator: ", ") ?? "" },
                    set: { self.elements?.accessories = $0.isEmpty ? nil : $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ),
                placeholder: "e.g., silver necklace, leather gloves",
                icon: "star"
            )

            editableField(
                title: "Expression & Pose",
                value: Binding(
                    get: { self.elements?.expression ?? "" },
                    set: { self.elements?.expression = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., confident smile, standing at attention",
                icon: "theatermasks"
            )
        }
    }

    // MARK: - Location Elements View

    private func locationElementsView(_ elements: VisualElements) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Location View Elements")

            editableField(
                title: "Primary Features",
                value: Binding(
                    get: { self.elements?.primaryFeatures?.joined(separator: ", ") ?? "" },
                    set: { self.elements?.primaryFeatures = $0.isEmpty ? nil : $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ),
                placeholder: "e.g., twin moons, rolling sand dunes",
                icon: "mountain.2"
            )

            editableField(
                title: "Scale",
                value: Binding(
                    get: { self.elements?.scale ?? "" },
                    set: { self.elements?.scale = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., vast, intimate, expansive",
                icon: "ruler"
            )

            editableField(
                title: "Architecture",
                value: Binding(
                    get: { self.elements?.architecture ?? "" },
                    set: { self.elements?.architecture = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., stone buildings, wooden structures",
                icon: "building.2"
            )

            editableField(
                title: "Vegetation",
                value: Binding(
                    get: { self.elements?.vegetation ?? "" },
                    set: { self.elements?.vegetation = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., ancient oak trees, desert cacti",
                icon: "leaf"
            )

            // Note: Terrain is represented via primaryFeatures for locations

            if !elements.isSceneWithMood {
                Text("Note: Location views use neutral, documentary lighting. For atmospheric scenes, create a Scene card instead.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }

    // MARK: - Scene Elements View

    private func sceneElementsView(_ elements: VisualElements) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Scene Elements (Location + Mood)")

            editableField(
                title: "Primary Features",
                value: Binding(
                    get: { self.elements?.primaryFeatures?.joined(separator: ", ") ?? "" },
                    set: { self.elements?.primaryFeatures = $0.isEmpty ? nil : $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ),
                placeholder: "e.g., cafe interior, cobblestone street",
                icon: "photo"
            )

            editableField(
                title: "Mood",
                value: Binding(
                    get: { self.elements?.mood ?? "" },
                    set: { self.elements?.mood = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., tense, joyful, mysterious",
                icon: "cloud.sun"
            )

            editableField(
                title: "Atmosphere",
                value: Binding(
                    get: { self.elements?.atmosphere ?? "" },
                    set: { self.elements?.atmosphere = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., foggy, clear starry night, humid afternoon",
                icon: "cloud.fog"
            )

            editableField(
                title: "Color Palette",
                value: Binding(
                    get: { self.elements?.colors?.joined(separator: ", ") ?? "" },
                    set: { self.elements?.colors = $0.isEmpty ? nil : $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ),
                placeholder: "e.g., warm oranges, cool blues, muted grays",
                icon: "paintpalette"
            )

            Text("Scenes include lighting and mood based on narrative events. Analyze your description for emotional indicators to set the right atmosphere.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(8)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(6)
        }
    }

    // MARK: - Artifact Elements View

    private func artifactElementsView(_ elements: VisualElements) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Artifact Elements")

            editableField(
                title: "Object Type",
                value: Binding(
                    get: { self.elements?.objectType ?? "" },
                    set: { self.elements?.objectType = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., sword, amulet, ancient book",
                icon: "sparkles"
            )

            if let partial = elements.showPartial {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Showing partial object: \(partial)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }

            editableField(
                title: "Materials",
                value: Binding(
                    get: { self.elements?.materials?.joined(separator: ", ") ?? "" },
                    set: { self.elements?.materials = $0.isEmpty ? nil : $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ),
                placeholder: "e.g., ancient metal, glowing crystal",
                icon: "cube.transparent"
            )

            editableField(
                title: "Colors & Textures",
                value: Binding(
                    get: { self.elements?.colors?.joined(separator: ", ") ?? "" },
                    set: { self.elements?.colors = $0.isEmpty ? nil : $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ),
                placeholder: "e.g., dark silver, smooth polished surface",
                icon: "paintbrush"
            )

            editableField(
                title: "Condition",
                value: Binding(
                    get: { self.elements?.condition ?? "" },
                    set: { self.elements?.condition = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., pristine, battle-worn, ancient",
                icon: "hammer"
            )

            // Note: Distinctive features are covered by materials and colors for artifacts
        }
    }

    // MARK: - Building Elements View

    private func buildingElementsView(_ elements: VisualElements) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Building Elements")

            editableField(
                title: "Architectural Style",
                value: Binding(
                    get: { self.elements?.architecturalStyle ?? "" },
                    set: { self.elements?.architecturalStyle = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., gothic, modern, fantasy",
                icon: "building.columns"
            )

            if let importance = elements.narrativeImportance {
                HStack(spacing: 8) {
                    Image(systemName: importance == "grand" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(importance == "grand" ? .blue : .orange)
                    Text("Narrative importance: \(importance)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let angle = elements.cameraAngle {
                        Text(angle.displayName)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
                .background((importance == "grand" ? Color.blue : Color.orange).opacity(0.1))
                .cornerRadius(6)
            }

            // Note: Scale is represented via scale property for buildings
            editableField(
                title: "Scale & Size",
                value: Binding(
                    get: { self.elements?.scale ?? "" },
                    set: { self.elements?.scale = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., towering, small, massive",
                icon: "arrow.up.and.down"
            )

            editableField(
                title: "Materials",
                value: Binding(
                    get: { self.elements?.materials?.joined(separator: ", ") ?? "" },
                    set: { self.elements?.materials = $0.isEmpty ? nil : $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ),
                placeholder: "e.g., stone, wood, marble",
                icon: "building.2"
            )

            editableField(
                title: "Condition",
                value: Binding(
                    get: { self.elements?.condition ?? "" },
                    set: { self.elements?.condition = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., well-maintained, ruined, ancient",
                icon: "hammer"
            )

            // Note: Distinctive features are covered by architecture for buildings

            editableField(
                title: "Setting",
                value: Binding(
                    get: { self.elements?.backgroundSetting ?? "" },
                    set: { self.elements?.backgroundSetting = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., clifftop, village square, forest clearing",
                icon: "map"
            )
        }
    }

    // MARK: - Vehicle Elements View

    private func vehicleElementsView(_ elements: VisualElements) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Vehicle Elements")

            editableField(
                title: "Vehicle Type",
                value: Binding(
                    get: { self.elements?.vehicleType ?? "" },
                    set: { self.elements?.vehicleType = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., ship, airship, dragon, carriage",
                icon: "airplane"
            )

            editableField(
                title: "Design & Construction",
                value: Binding(
                    get: { self.elements?.vehicleDesign ?? "" },
                    set: { self.elements?.vehicleDesign = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., sleek hull, ornate decorations",
                icon: "hammer"
            )

            editableField(
                title: "Scale & Size",
                value: Binding(
                    get: { self.elements?.scale ?? "" },
                    set: { self.elements?.scale = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., massive, small, medium-sized",
                icon: "arrow.up.and.down"
            )

            editableField(
                title: "Materials",
                value: Binding(
                    get: { self.elements?.materials?.joined(separator: ", ") ?? "" },
                    set: { self.elements?.materials = $0.isEmpty ? nil : $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ),
                placeholder: "e.g., wood, metal, living scales",
                icon: "cube.transparent"
            )

            // Note: Distinctive features are covered by materials and vehicleDesign for vehicles

            editableField(
                title: "Motion State",
                value: Binding(
                    get: { self.elements?.motionState ?? "" },
                    set: { self.elements?.motionState = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "e.g., at rest, in flight, sailing",
                icon: "wind"
            )
        }
    }

    // MARK: - Generic Elements View

    private func genericElementsView(_ elements: VisualElements) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Visual Elements")

            editableField(
                title: "Main Subject",
                value: Binding(
                    get: { self.elements?.primaryFeatures?.joined(separator: ", ") ?? "" },
                    set: { self.elements?.primaryFeatures = $0.isEmpty ? nil : $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ),
                placeholder: "Primary focus of the image",
                icon: "photo"
            )

            editableField(
                title: "Setting",
                value: Binding(
                    get: { self.elements?.backgroundSetting ?? "" },
                    set: { self.elements?.backgroundSetting = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "Background and context",
                icon: "map"
            )

            editableField(
                title: "Colors",
                value: Binding(
                    get: { self.elements?.colors?.joined(separator: ", ") ?? "" },
                    set: { self.elements?.colors = $0.isEmpty ? nil : $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ),
                placeholder: "Dominant colors",
                icon: "paintpalette"
            )
        }
    }

    // MARK: - Cinematic Framing View

    private func cinematicFramingView(_ elements: VisualElements) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Cinematic Framing & Lighting")

            // Camera Angle
            HStack {
                Label("Camera Angle", systemImage: "camera")
                    .font(.subheadline.bold())
                    .frame(width: 180, alignment: .leading)

                Picker("Camera Angle", selection: Binding(
                    get: { self.elements?.cameraAngle ?? .eyeLevel },
                    set: { self.elements?.cameraAngle = $0 }
                )) {
                    ForEach([CameraAngle.lowAngleLookingUp, .highAngleLookingDown, .eyeLevel, .aerialView, .dramaticAngle], id: \.self) { angle in
                        Text(angle.displayName).tag(angle)
                    }
                }
                .pickerStyle(.menu)
            }

            // Framing
            HStack {
                Label("Framing", systemImage: "viewfinder")
                    .font(.subheadline.bold())
                    .frame(width: 180, alignment: .leading)

                Picker("Framing", selection: Binding(
                    get: { self.elements?.framing ?? .mediumShot },
                    set: { self.elements?.framing = $0 }
                )) {
                    ForEach([Framing.closeUp, .mediumShot, .fullShot, .wideEstablishing], id: \.self) { framing in
                        Text(framing.displayName).tag(framing)
                    }
                }
                .pickerStyle(.menu)
            }

            // Lighting Style
            HStack {
                Label("Lighting Style", systemImage: "sun.max")
                    .font(.subheadline.bold())
                    .frame(width: 180, alignment: .leading)

                Picker("Lighting", selection: Binding(
                    get: { self.elements?.lightingStyle ?? .neutral },
                    set: { self.elements?.lightingStyle = $0 }
                )) {
                    ForEach([LightingStyle.dramatic, .soft, .neutral, .dark, .bright], id: \.self) { lighting in
                        Text(lighting.rawValue.capitalized).tag(lighting)
                    }
                }
                .pickerStyle(.menu)
            }

            Text("These cinematic options control how the image is framed and lit. Defaults are inferred from your description but can be customized.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
        }
    }

    // MARK: - Preview Prompt View

    private func previewPromptView(_ elements: VisualElements) -> some View {
        let prompt: String = {
            if provider.name.contains("Apple") {
                // Show concepts for Apple Intelligence
                let concepts = elements.generateConceptsForAppleIntelligence()
                return concepts.enumerated().map { index, concept in
                    "\(index + 1). \(concept)"
                }.joined(separator: "\n")
            } else if provider.name.contains("OpenAI") {
                return elements.generatePromptForOpenAI()
            } else if provider.name.contains("Anthropic") {
                return elements.generatePromptForAnthropic()
            } else {
                return elements.generatePromptForOpenAI() // Default
            }
        }()

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Preview Generated Prompt")

            Text("This is what will be sent to the AI image generator:")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(prompt)
                .font(.system(.body, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

            if provider.name.contains("Apple") {
                Text("Apple Intelligence uses multiple short concepts (max 95 characters each) for Image Playground.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("OpenAI and Anthropic use a single structured prompt with all visual details.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    private func editableField(
        title: String,
        value: Binding<String>,
        placeholder: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            TextField(placeholder, text: value, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(8)
                #if os(macOS)
                .background(Color(nsColor: .textBackgroundColor))
                #else
                .background(Color(uiColor: .systemBackground))
                #endif
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // MARK: - Actions

    private func extractVisualElements() async {
        isExtracting = true
        extractionError = nil

        do {
            let extractor = VisualElementExtractor(provider: provider)
            let extracted = try await extractor.extractVisualElements(
                from: cardDescription,
                cardKind: cardKind
            )

            await MainActor.run {
                self.elements = extracted
                self.isExtracting = false
            }

            logger.info("Successfully extracted visual elements with confidence \(extracted.extractionConfidence)")
        } catch {
            await MainActor.run {
                self.extractionError = error
                self.isExtracting = false
            }
            logger.error("Visual element extraction failed: \(error.localizedDescription)")
        }
    }

    private func generateWithElements() {
        guard let elements = elements else { return }

        // If extraction has sufficient data, use it
        // Otherwise, pass elements with original prompt marker
        if !elements.hasSufficientData, let original = originalPrompt, !original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            logger.info("Using original prompt as fallback (insufficient extraction data)")
            // Create a modified elements object that signals to use original prompt
            // We'll set a special marker so the parent knows to use original prompt
            var fallbackElements = elements
            fallbackElements.useOriginalPrompt = true
            onGenerate(fallbackElements)
        } else {
            onGenerate(elements)
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    VisualElementReviewView(
        cardDescription: """
        Captain Evilin Drake is a tall woman with long straight dark hair that she
        wears in a ponytail most days. Lithe and thin, she can be seen most days
        wearing her orange astronaut's jumpsuit. She is quick to laugh, with a
        strong chin, short nose, bright green eyes. She grew up on Mars Colony
        Seven and spent ten years commanding deep space missions before retiring
        to teach at the Interplanetary Academy.
        """,
        cardKind: .characters,
        cardName: "Captain Evilin Drake",
        provider: AppleIntelligenceProvider(),
        originalPrompt: "tall woman in orange jumpsuit with green eyes"
    ) { elements in
        print("Generated with elements: \(elements)")
    }
}
