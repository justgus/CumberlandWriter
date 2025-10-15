//
//  CardEditorView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/4/25.
//

import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import ImageIO
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

// Focused value key for inserting the default author via a command.
#if os(macOS)
private struct InsertDefaultAuthorActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var insertDefaultAuthor: (() -> Void)? {
        get { self[InsertDefaultAuthorActionKey.self] }
        set { self[InsertDefaultAuthorActionKey.self] = newValue }
    }
}
#endif

struct CardEditorView: View {
    enum Mode {
        case create(kind: Kinds, onComplete: (Card) -> Void)
        case edit(card: Card, onComplete: () -> Void)

        var kind: Kinds {
            switch self {
            case .create(let kind, _): return kind
            case .edit(let card, _):   return card.kind
            }
        }
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    // App settings (for default author)
    @Query(
        FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.singletonKey == "AppSettingsSingleton" }
        )
    ) private var settingsResults: [AppSettings]

    // Track focus so we only handle the shortcut when the Author field is focused
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name, subtitle, author, details
    }

    // Editable fields (initialized in init from mode)
    @State private var name: String
    @State private var subtitle: String
    @State private var author: String
    @State private var detailedText: String
    @State private var sizeCategory: SizeCategory

    // Image handling
    @State private var imageData: Data?
    @State private var thumbnail: Image?
    @State private var isWorking: Bool = false

    // File importer
    @State private var isImportingImage: Bool = false

    // Photos picker
    @State private var selectedPhotoItem: PhotosPickerItem?

    // Flip state for wizard-like back side
    @State private var isFlipped: Bool = false

    // MARK: - Quick Attribution Prompt State (for dropped text/images)
    private struct PendingAttribution: Identifiable, Equatable {
        let id = UUID()
        let kind: CitationKind
        let suggestedURL: URL?
        let prefilledExcerpt: String?
    }
    @State private var pendingAttribution: PendingAttribution?

    // MARK: - Project Structure Creation (only when creating a Project)

    private enum StructureSource: String, Hashable, CaseIterable, Identifiable {
        case template = "Template"
        case custom = "Custom"
        var id: String { rawValue }
    }

    // Whether to attach a structure to the project being created
    @State private var attachStructure: Bool = true

    // Source mode: template or custom
    @State private var structureSource: StructureSource = .template

    // Selected template index; used to seed editableElements
    @State private var selectedTemplateIndex: Int = 0

    // Name of the structure to be created (defaults to template name, editable)
    @State private var structureName: String = ""

    // Inline editable list of elements (names only here; description can be added as needed)
    @State private var editableElements: [EditableElement] = []

    // Reorder toggle (List edit mode)
    @State private var isReordering: Bool = false

    private struct EditableElement: Identifiable, Hashable {
        let id = UUID()
        var name: String
        var description: String = ""
        var colorHue: Double? = nil
    }

    // MARK: - Tunable constants (match CardView where sensible)
    private let thumbnailSide: CGFloat = 72
    private let thumbnailTopPadding: CGFloat = 8
    private let maxCardWidth: CGFloat = 430

    private let tabCornerRadius: CGFloat = 8
    private let tabHeight: CGFloat = 22
    private let tabHorizontalPadding: CGFloat = 10
    private let tabVerticalPadding: CGFloat = 2
    private let tabOffsetTop: CGFloat = -10
    private let tabOffsetLeft: CGFloat = 12

    // Initialize state from mode
    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create(let kind, _):
            _name = State(initialValue: "")
            _subtitle = State(initialValue: "")
            _author = State(initialValue: "")
            _detailedText = State(initialValue: "")
            _sizeCategory = State(initialValue: .standard)
            _imageData = State(initialValue: nil)

            // Default structure UI only makes sense for Projects
            if kind == .projects {
                let templates = StoryStructure.predefinedTemplates
                let initialIndex = 0
                let initialTemplate = templates.indices.contains(initialIndex) ? templates[initialIndex] : (name: "Custom Structure", elements: [])
                _selectedTemplateIndex = State(initialValue: initialIndex)
                _structureName = State(initialValue: initialTemplate.name)
                _editableElements = State(initialValue: initialTemplate.elements.map { EditableElement(name: $0) })
            }
        case .edit(let card, _):
            _name = State(initialValue: card.name)
            _subtitle = State(initialValue: card.subtitle)
            _author = State(initialValue: card.author ?? "")
            _detailedText = State(initialValue: card.detailedText)
            _sizeCategory = State(initialValue: card.sizeCategory)
            _imageData = State(initialValue: nil) // only set when user selects/replaces
        }
    }

    var body: some View {
        let kind = mode.kind

        VStack(spacing: 16) {
            // Flip container hosting front/back faces of the editor "card" surface
            FlipCardContainer(isFlipped: $isFlipped) {
                // FRONT: common fields
                cardSurface(kind: kind) {
                    frontCardFields
                }
            } back: {
                // BACK: kind-specific extras (only if available)
                cardSurface(kind: kind) {
                    backExtrasContent
                }
            }
            // Ellipsis flip button (Wallet-like) only when extras exist
            .overlay(alignment: .bottomTrailing) {
                if hasKindExtras {
                    flipButton
                        .padding(12)
                        .offset(x: 8, y: 8) // let it protrude slightly like a badge
                }
            }
            .frame(maxWidth: maxCardWidth)

            // Image actions
            HStack(spacing: 12) {
                Button {
                    isImportingImage = true
                } label: {
                    Label("Choose Image…", systemImage: "photo.on.rectangle")
                }

                Button(role: .destructive) {
                    removeImage()
                } label: {
                    Label("Remove Image", systemImage: "trash")
                }
                .disabled(!hasAnyImage)

                Spacer()

                if isWorking {
                    ProgressView().controlSize(.small)
                }
            }
            .frame(maxWidth: maxCardWidth)
            .fileImporter(isPresented: $isImportingImage, allowedContentTypes: [.image]) { result in
                if case let .success(url) = result,
                   let data = try? Data(contentsOf: url) {
                    imageData = data
                    // Treat file-import as local; no URL attribution prompt needed.
                }
            }

            // Citations section (edit mode only)
            if isEditing, case .edit(let card, _) = mode {
                CitationViewer(card: card)
                    .frame(maxWidth: maxCardWidth)
            }

            // Note: The structure creation panel is now on the back face when creating a Project.

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Save" : "Create") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .frame(maxWidth: maxCardWidth)
        }
        .padding()
        .frame(minWidth: 520)
        .navigationTitle(isEditing ? "Edit \(kind.title.dropLastIfPluralized())" : "New \(kind.title.dropLastIfPluralized())")
        .task(id: imageData) {
            await loadThumbnailPreview()
        }
        .task {
            if thumbnail == nil {
                await loadInitialThumbnailIfEditing()
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task { await setImageDataFromPickerItem(newItem) }
        }
        .dropDestination(for: Data.self) { items, _ in
            if let data = items.first, Self.isSupportedImageData(data) {
                imageData = data
                return true
            }
            return false
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first, Self.isSupportedImageURL(url),
                  let data = try? Data(contentsOf: url) else { return false }
            imageData = data
            return true
        }
        #if os(macOS)
        // Expose a focused action so the app-level Commands can trigger it with a shortcut.
        .focusedValue(
            \.insertDefaultAuthor,
            (focusedField == .author && !defaultAuthorTrimmed.isEmpty) ? { insertDefaultAuthorIfAvailable() } : nil
        )
        #endif
        // When flipping to the back in edit mode, load existing structure (if any).
        .onChange(of: isFlipped) { _, flipped in
            if flipped {
                Task { await loadStructureStateForEditIfNeeded() }
            }
        }
        // Keep structureName in sync with template selection if user hasn’t edited it.
        .onChange(of: selectedTemplateIndex) { _, newIndex in
            guard case .create(let createKind, _) = mode, createKind == .projects else { return }
            guard structureSource == .template else { return }
            let templates = StoryStructure.predefinedTemplates
            guard templates.indices.contains(newIndex) else { return }
            let t = templates[newIndex]
            // We conservatively update to the selected template name.
            structureName = t.name
            editableElements = t.elements.map { EditableElement(name: $0) }
        }
        // Present the quick attribution sheet right after text/image drop succeeds (edit mode only)
        .sheet(item: $pendingAttribution) { ctx in
            if case .edit(let card, _) = mode {
                QuickAttributionSheetEditor(card: card,
                                            kind: ctx.kind,
                                            suggestedURL: ctx.suggestedURL,
                                            prefilledExcerpt: ctx.prefilledExcerpt,
                                            onSave: { _ in
                                                // Citation created; nothing else to do here
                                            },
                                            onSkip: {
                                                // Leave dropped content unattributed
                                            })
                .frame(minWidth: 420, minHeight: 360)
            } else {
                // In create mode there is no persisted Card yet; skip.
                EmptyView()
            }
        }
    }

    // MARK: - Derived

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var hasAnyImage: Bool {
        switch mode {
        case .create:
            return imageData != nil
        case .edit(let card, _):
            return imageData != nil || card.thumbnailData != nil || card.imageFileURL != nil
        }
    }

    private var defaultAuthorTrimmed: String {
        (settingsResults.first?.defaultAuthor ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Kinds that have additional controls on the back face
    private var hasKindExtras: Bool {
        // Show the flip button for Projects in both create and edit modes.
        return mode.kind == .projects
    }

    // MARK: - Front/Back content

    @ViewBuilder
    private var frontCardFields: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 8) {
                thumbnailDropView
                    .frame(width: thumbnailSide, height: thumbnailSide)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.quaternary, lineWidth: 1)
                    }
                    .padding(.top, thumbnailTopPadding)

                // Compact image attribution panel (only for edit mode)
                if case .edit(let card, _) = mode {
                    ImageAttributionViewer(card: card)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                        .focused($focusedField, equals: .name)

                    sizePicker
                }

                TextField("Subtitle (optional)", text: $subtitle)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .subtitle)

                TextField("Author (optional)", text: $author)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .author)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Details (Markdown supported)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $detailedText)
                        .focused($focusedField, equals: .details)
                        .frame(minHeight: 160)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.background)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(.quaternary, lineWidth: 1)
                        )
                        // Accept dragged text or URLs and append into the details
                        .onDrop(of: [.plainText, .text, .url], isTargeted: nil) { providers in
                            handleTextDrop(providers)
                        }
                }
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var backExtrasContent: some View {
        // Show the panel for Projects in both create and edit modes
        if mode.kind == .projects {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: Kinds.projects.systemImage)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text("Project Options")
                        .font(.headline)
                    Spacer()
                }
                structureCreationPanel
            }
            // Also load existing structure if we're editing and this back face appears early.
            .task {
                await loadStructureStateForEditIfNeeded()
            }
        } else {
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                Text("No additional options")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Flip UI

    private var flipButton: some View {
        let diameter: CGFloat = 40

        return Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                isFlipped.toggle()
            }
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            ZStack {
                // Glassy base
                Circle()
                    .fill(.ultraThinMaterial)

                // Subtle top gloss
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 0.5)
                    .opacity(0.9)

                // Symbol
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .frame(width: diameter, height: diameter)
            // Inner sheen ring
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
            )
            // Outer subtle ring glow
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 4)
                    .blur(radius: 2)
            )
            // Crisp edge
            .overlay(
                Circle()
                    .stroke(.separator, lineWidth: 0.6)
                    .opacity(0.6)
            )
            // Shadows for depth
            .shadow(color: .black.opacity(0.28), radius: 10, x: 0, y: 6)
            .shadow(color: .black.opacity(0.10), radius: 3, x: 0, y: 1)
            .accessibilityLabel(isFlipped ? "Show common fields" : "Show additional options")
        }
        #if os(macOS)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        #endif
        .buttonStyle(.plain)
        .keyboardShortcut(.init("\t"), modifiers: [.command, .shift]) // Cmd-Shift-Tab to flip
    }

    // A shared chrome wrapper that renders the card surface, border, and top-left kind tab.
    @ViewBuilder
    private func cardSurface<Content: View>(kind: Kinds, @ViewBuilder content: () -> Content) -> some View {
        let cardShape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        let shadowColor = Color.black.opacity(scheme == .dark ? 0.25 : 0.10)
        let tabTopAllowance = max(0, -tabOffsetTop)

        HStack(alignment: .top, spacing: 12) {
            content()
        }
        .padding(.top, 20 + tabTopAllowance)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .background(
            cardShape
                .fill(.background)
                .shadow(color: shadowColor, radius: 6, x: 0, y: 3)
        )
        .overlay(
            cardShape
                .strokeBorder(kind.accentColor(for: scheme), lineWidth: 12)
        )
        .overlay(alignment: .topLeading) {
            kindTab(kind: kind)
                .offset(x: tabOffsetLeft, y: tabOffsetTop)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: maxCardWidth, alignment: .topLeading)
    }

    // MARK: - Structure Creation Panel

    @ViewBuilder
    private var structureCreationPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().padding(.vertical, 2)

            Toggle(isOn: $attachStructure) {
                Label("Attach Story Structure", systemImage: "list.number")
            }

            if attachStructure {
                Picker("Source", selection: $structureSource) {
                    ForEach(StructureSource.allCases) { src in
                        Text(src.rawValue).tag(src)
                    }
                }
                .pickerStyle(.segmented)

                // Structure name (editable)
                TextField("Structure Name", text: $structureName)
                    .textFieldStyle(.roundedBorder)

                if structureSource == .template {
                    // Template picker
                    Picker("Template", selection: $selectedTemplateIndex) {
                        ForEach(Array(StoryStructure.predefinedTemplates.enumerated()), id: \.offset) { idx, t in
                            Text(t.name).tag(idx)
                        }
                    }
                    .pickerStyle(.menu)

                    // Inline editor seeded from template (editable + reorder)
                    structureElementEditor
                } else {
                    // Custom structure: start empty or previously edited
                    HStack {
                        Button {
                            // If empty, seed with a single blank row to hint
                            if editableElements.isEmpty {
                                editableElements = [EditableElement(name: "")]
                            }
                        } label: {
                            Label("Start List", systemImage: "text.badge.plus")
                        }
                        .disabled(!editableElements.isEmpty)

                        Spacer()
                    }
                    structureElementEditor
                }
            }
        }
    }

    @ViewBuilder
    private var structureElementEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Elements")
                    .font(.subheadline.bold())
                Spacer()
                Button(isReordering ? "Done" : "Reorder") {
                    withAnimation { isReordering.toggle() }
                }
                .buttonStyle(.bordered)
                .disabled(editableElements.count < 2)
            }

            // Use List for built-in onMove support
            List {
                ForEach(editableElements) { el in
                    HStack(spacing: 8) {
                        // Order indicator
                        if !isReordering {
                            if let idx = editableElements.firstIndex(of: el) {
                                Text("\(idx + 1)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 22, alignment: .trailing)
                            } else {
                                Text("•").frame(width: 22, alignment: .trailing)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Element name", text: bindingForElement(el).name)
                                .textFieldStyle(.roundedBorder)

                            TextField("Description (optional)", text: bindingForElement(el).description)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                        }

                        Spacer()

                        Button(role: .destructive) {
                            if let idx = editableElements.firstIndex(of: el) {
                                editableElements.remove(at: idx)
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Remove element")
                    }
                    .padding(.vertical, 2)
                }
                .onMove { indices, newOffset in
                    editableElements.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            #if os(iOS)
            .environment(\.editMode, .constant(isReordering ? .active : .inactive))
            #endif
            .frame(minHeight: 160, maxHeight: 320)

            HStack {
                Button {
                    editableElements.append(EditableElement(name: ""))
                } label: {
                    Label("Add Element", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)

                Spacer()

                Text("\(editableElements.count) item(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func bindingForElement(_ el: EditableElement) -> (name: Binding<String>, description: Binding<String>) {
        guard let idx = editableElements.firstIndex(of: el) else {
            return (Binding.constant(""), Binding.constant(""))
        }
        return (
            Binding(
                get: { editableElements[idx].name },
                set: { editableElements[idx].name = $0 }
            ),
            Binding(
                get: { editableElements[idx].description },
                set: { editableElements[idx].description = $0 }
            )
        )
    }

    // MARK: - Subviews

    @ViewBuilder
    private var thumbnailDropView: some View {
        ZStack {
            if let thumbnail {
                thumbnail
                    .resizable()
                    .scaledToFit() // Preserve aspect ratio; no cropping
                    .accessibilityLabel("Cover Image")
            } else {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    VStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundStyle(.secondary)
                        Text("Drop image here")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        // Rich image drop handling (parity with CardSheetView)
        .onDrop(
            of: [
                UTType.data.identifier,
                UTType.image.identifier,
                UTType.png.identifier,
                UTType.jpeg.identifier,
                UTType.tiff.identifier,
                UTType.gif.identifier,
                UTType.heic.identifier,
                UTType.heif.identifier,
                UTType.bmp.identifier,
                UTType.fileURL.identifier,
                UTType.url.identifier
            ],
            isTargeted: nil
        ) { providers in
            handleImageDrop(providers: providers)
            return true
        }
        .contextMenu {
            Button {
                isImportingImage = true
            } label: {
                Label("Choose Image…", systemImage: "photo.on.rectangle")
            }
            if #available(iOS 16.0, macOS 13.0, *) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                    Label("Import from Photos…", systemImage: "photo")
                }
            }
        }
    }

    private var sizePicker: some View {
        Picker("Size", selection: $sizeCategory) {
            ForEach(SizeCategory.allCases, id: \.self) { sc in
                Text(sc.displayName).tag(sc)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Card size")
    }

    private func kindTab(kind: Kinds) -> some View {
        HStack(spacing: 6) {
            Image(systemName: kind.systemImage)
                .font(.caption2)
            Text(kind.title)
                .font(.caption).bold()
                .lineLimit(1)
        }
        .foregroundStyle(.primary.opacity(scheme == .dark ? 0.9 : 0.95))
        .padding(.horizontal, tabHorizontalPadding)
        .padding(.vertical, tabVerticalPadding)
        .frame(height: tabHeight)
        .background(
            RoundedRectangle(cornerRadius: tabCornerRadius, style: .continuous)
                .fill(kind.accentColor(for: scheme))
        )
    }

    // MARK: - Author shortcut

    @MainActor
    private func insertDefaultAuthorIfAvailable() {
        let val = defaultAuthorTrimmed
        guard !val.isEmpty, focusedField == .author else { return }
        author = val
    }

    // MARK: - Save

    @MainActor
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let authorValue: String? = trimmedAuthor.isEmpty ? nil : trimmedAuthor

        switch mode {
        case .create(let kind, let onComplete):
            let card = Card(
                kind: kind,
                name: trimmedName,
                subtitle: subtitle,
                detailedText: detailedText,
                author: authorValue,
                sizeCategory: sizeCategory
            )
            modelContext.insert(card)

            if let data = imageData {
                let ext = Self.inferFileExtension(from: data) ?? "jpg"
                try? card.setOriginalImageData(data, preferredFileExtension: ext)
            }

            // If creating a Project and structure is requested, persist it now.
            if kind == .projects, attachStructure {
                persistStructureForNewProject(projectCard: card)
            }

            try? modelContext.save()
            onComplete(card)
            dismiss()

        case .edit(let card, let onComplete):
            card.name = trimmedName
            card.subtitle = subtitle
            card.detailedText = detailedText
            card.author = authorValue
            card.sizeCategory = sizeCategory

            if let data = imageData {
                let ext = Self.inferFileExtension(from: data) ?? "jpg"
                try? card.setOriginalImageData(data, preferredFileExtension: ext)
            }

            // If editing a Project, sync the StoryStructure based on the back-face UI.
            if mode.kind == .projects {
                updateStructureForExistingProject(projectCard: card)
            }

            try? modelContext.save()
            onComplete()
            dismiss()
        }
    }

    private func persistStructureForNewProject(projectCard: Card) {
        // Build from the current editableElements so any edits/reordering are respected.
        let trimmedStructureName = structureName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalStructureName: String = trimmedStructureName.isEmpty
            ? defaultStructureNameFromSource()
            : trimmedStructureName

        // Filter out empty element names
        let elementNames = editableElements
            .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !elementNames.isEmpty else { return }

        // Create the structure and attach to this project via projectID
        let structure = StoryStructure(name: finalStructureName, projectID: projectCard.id)

        if structure.elements == nil { structure.elements = [] }
        for (idx, elementName) in elementNames.enumerated() {
            let el = StructureElement(name: elementName, elementDescription: "", orderIndex: idx)
            el.storyStructure = structure
            structure.elements?.append(el)
        }

        modelContext.insert(structure)
    }

    private func defaultStructureNameFromSource() -> String {
        switch structureSource {
        case .template:
            let templates = StoryStructure.predefinedTemplates
            if templates.indices.contains(selectedTemplateIndex) {
                return templates[selectedTemplateIndex].name
            }
            return "Structure"
        case .custom:
            return "Custom Structure"
        }
    }

    // MARK: - Thumbnail loading

    @MainActor
    private func loadThumbnailPreview() async {
        if let data = imageData, let cg = Self.makeCGImage(from: data) {
            let img = Image(decorative: cg, scale: 1, orientation: .up)
            withAnimation(.easeInOut(duration: 0.15)) {
                self.thumbnail = img
            }
            return
        }
        await loadInitialThumbnailIfEditing()
    }

    @MainActor
    private func loadInitialThumbnailIfEditing() async {
        guard case .edit(let card, _) = mode else {
            thumbnail = nil
            return
        }
        let img = await card.makeThumbnailImage()
        withAnimation(.easeInOut(duration: 0.15)) {
            self.thumbnail = img
        }
    }

    // MARK: - Image operations

    @MainActor
    private func regenerateThumbnailFromOriginalIfPossible() async {
        guard case .edit(let card, _) = mode else { return }
        isWorking = true
        defer { isWorking = false }
        card.regenerateThumbnailFromOriginal()
        await loadInitialThumbnailIfEditing()
    }

    private func removeImage() {
        switch mode {
        case .create:
            imageData = nil
            thumbnail = nil
        case .edit(let card, _):
            card.removeOriginalImage()
            card.thumbnailData = nil
            card.clearImageCaches()
            Task { await loadInitialThumbnailIfEditing() }
        }
    }

    // MARK: - Photos picker handling

    @MainActor
    private func setImageDataFromPickerItem(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isWorking = true
        defer { isWorking = false }
        
        // Try to load raw image data using the Data transferable
        if let data = try? await item.loadTransferable(type: Data.self),
           Self.isSupportedImageData(data) {
            imageData = data
        }
    }

    // MARK: - Text drop handling (details)

    private func handleTextDrop(_ providers: [NSItemProvider]) -> Bool {
        var didHandle = false

        // Try to extract a URL (if present) to prefill source
        var suggestedURL: URL?
        if let urlProvider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                if let u = item as? URL, u.scheme?.hasPrefix("http") == true {
                    suggestedURL = u
                }
            }
            didHandle = true
        }

        // Plain text (primary trigger for the citation prompt)
        if let textProvider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) || $0.hasItemConformingToTypeIdentifier(UTType.text.identifier) }) {
            textProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                let s: String? = (item as? String) ?? (item as? NSString).map { String($0) }
                if let s, !s.isEmpty {
                    Task { @MainActor in
                        self.appendIntoDetails(s)
                        // Only prompt when editing an existing card (we need a Card to attach the citation)
                        if case .edit = self.mode {
                            let excerpt = String(s.prefix(280))
                            self.pendingAttribution = PendingAttribution(kind: .quote,
                                                                         suggestedURL: suggestedURL,
                                                                         prefilledExcerpt: excerpt)
                        }
                    }
                }
            }
            didHandle = true
        }

        return didHandle
    }

    @MainActor
    private func appendIntoDetails(_ incoming: String) {
        let textToInsert = incoming

        // Ensure separation with a newline
        if !detailedText.isEmpty && !detailedText.hasSuffix("\n") {
            detailedText.append("\n")
        }
        detailedText.append(textToInsert)
    }

    // MARK: - Image drop handling (parity with CardSheetView)

    private func handleImageDrop(providers: [NSItemProvider]) {
        guard !providers.isEmpty else { return }

        for provider in providers {
            // 0) Try object-based images first (UIKit/AppKit)
            #if canImport(UIKit)
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { obj, _ in
                    if let ui = obj as? UIImage {
                        let data = ui.pngData() ?? ui.jpegData(compressionQuality: 0.9)
                        if let data {
                            Task { @MainActor in
                                self.imageData = data
                                // No URL context; for edit mode, prompt for local image attribution if desired
                                if self.isEditing {
                                    self.pendingAttribution = PendingAttribution(kind: .image,
                                                                                 suggestedURL: nil,
                                                                                 prefilledExcerpt: nil)
                                }
                            }
                        }
                    } else {
                        self.tryURLOrData(provider: provider)
                    }
                }
                continue
            }
            #endif
            #if canImport(AppKit)
            if provider.canLoadObject(ofClass: NSImage.self) {
                provider.loadObject(ofClass: NSImage.self) { obj, _ in
                    if let img = obj as? NSImage {
                        var outData: Data?
                        if let tiff = img.tiffRepresentation,
                           let rep = NSBitmapImageRep(data: tiff) {
                            outData = rep.representation(using: .png, properties: [:])
                                ?? rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
                        }
                        if let data = outData {
                            Task { @MainActor in
                                self.imageData = data
                                if self.isEditing {
                                    self.pendingAttribution = PendingAttribution(kind: .image,
                                                                                 suggestedURL: nil,
                                                                                 prefilledExcerpt: nil)
                                }
                            }
                        }
                    } else {
                        self.tryURLOrData(provider: provider)
                    }
                }
                continue
            }
            #endif

            // 1) Raw image data (PNG/JPEG/etc.)
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.jpeg.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.tiff.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.gif.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.heic.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.heif.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.bmp.identifier)
            {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    if let data, !data.isEmpty {
                        Task { @MainActor in
                            self.imageData = data
                            if self.isEditing {
                                self.pendingAttribution = PendingAttribution(kind: .image,
                                                                             suggestedURL: nil,
                                                                             prefilledExcerpt: nil)
                            }
                        }
                    } else {
                        self.tryURLOrData(provider: provider)
                    }
                }
                continue
            }

            // 2) File URL (Finder drag)
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                tryLoadFileURL(provider: provider)
                continue
            }

            // 3) Web URL (Safari drag)
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                tryLoadRemoteURL(provider: provider)
                continue
            }
        }
    }

    private func tryURLOrData(provider: NSItemProvider) {
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            tryLoadFileURL(provider: provider)
        } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            tryLoadRemoteURL(provider: provider)
        } else {
            // Last resort: ask for generic data and see if it's an image
            provider.loadItem(forTypeIdentifier: UTType.data.identifier, options: nil) { item, _ in
                if let data = item as? Data, !data.isEmpty {
                    Task { @MainActor in
                        self.imageData = data
                        if self.isEditing {
                            self.pendingAttribution = PendingAttribution(kind: .image,
                                                                         suggestedURL: nil,
                                                                         prefilledExcerpt: nil)
                        }
                    }
                }
            }
        }
    }

    private func tryLoadFileURL(provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            if let url = item as? URL, url.isFileURL, let data = try? Data(contentsOf: url) {
                Task { @MainActor in
                    self.imageData = data
                    // Local file: for edit mode, you may still want to prompt (no URL)
                    if self.isEditing {
                        self.pendingAttribution = PendingAttribution(kind: .image,
                                                                     suggestedURL: nil,
                                                                     prefilledExcerpt: nil)
                    }
                }
            }
        }
    }

    private func tryLoadRemoteURL(provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
            if let url = item as? URL, url.scheme?.hasPrefix("http") == true {
                Task.detached {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if !data.isEmpty {
                            await MainActor.run {
                                self.imageData = data
                                // Web: prefill URL in attribution (edit mode only)
                                if self.isEditing {
                                    self.pendingAttribution = PendingAttribution(kind: .image,
                                                                                 suggestedURL: url,
                                                                                 prefilledExcerpt: nil)
                                }
                            }
                        }
                    } catch {
                        // Ignore failed remote fetch
                    }
                }
            }
        }
    }

    // MARK: - Image helpers

    private static func isSupportedImageURL(_ url: URL) -> Bool {
        guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return false
        }
        return type.conforms(to: .image)
    }

    private static func isSupportedImageData(_ data: Data) -> Bool {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return false }
        return CGImageSourceGetType(src) != nil
    }

    private static func makeCGImage(from data: Data) -> CGImage? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, nil)
    }

    private static func inferFileExtension(from data: Data) -> String? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(src) as String?,
              let utType = UTType(type) else {
            return nil
        }
        return utType.preferredFilenameExtension
    }
}

// MARK: - Flip container

private struct FlipCardContainer<Front: View, Back: View>: View {
    @Binding var isFlipped: Bool
    let front: Front
    let back: Back

    init(isFlipped: Binding<Bool>, @ViewBuilder front: () -> Front, @ViewBuilder back: () -> Back) {
        self._isFlipped = isFlipped
        self.front = front()
        self.back = back()
    }

    var body: some View {
        ZStack {
            front
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0.0 : 1.0)
                .allowsHitTesting(!isFlipped)

            back
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1.0 : 0.0)
                .allowsHitTesting(isFlipped)
        }
        .animation(.easeInOut(duration: 0.45), value: isFlipped)
        .rotation3DEffect(.degrees(0.0001), axis: (x: 0, y: 0, z: 1)) // nudge to enable perspective on some platforms
        .modifier(Perspective())
    }
}

// Adds a bit of perspective for the 3D flip.
private struct Perspective: ViewModifier {
    func body(content: Content) -> some View {
        content
            .compositingGroup()
            .rotation3DEffect(.degrees(0), axis: (x: 0, y: 0, z: 0), perspective: 0.8)
    }
}

extension CardEditorView {
    // Load existing StoryStructure for the project when editing, and populate UI state.
    @MainActor
    private func loadStructureStateForEditIfNeeded() async {
        guard case .edit(let card, _) = mode, mode.kind == .projects else { return }

        // If we already populated once, avoid re-seeding needlessly
        if !editableElements.isEmpty || !structureName.isEmpty || attachStructure == false {
            return
        }

        let projectIDOpt: UUID? = card.id
        let fetch = FetchDescriptor<StoryStructure>(
            predicate: #Predicate { $0.projectID == projectIDOpt },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let structures = (try? modelContext.fetch(fetch)) ?? []

        if let structure = structures.first {
            attachStructure = true
            structureSource = .custom
            structureName = structure.name
            let elements = (structure.elements ?? []).sorted { $0.orderIndex < $1.orderIndex }
            editableElements = elements.map { EditableElement(name: $0.name, description: $0.elementDescription, colorHue: $0.colorHue) }
        } else {
            // No structure yet for this project; default to not attached, but seed template choices
            attachStructure = false
            structureSource = .template
            let templates = StoryStructure.predefinedTemplates
            if let first = templates.first {
                selectedTemplateIndex = 0
                structureName = first.name
                editableElements = first.elements.map { EditableElement(name: $0) }
            }
        }
    }

    // Create, update, or delete the project's StoryStructure when saving edits.
    @MainActor
    private func updateStructureForExistingProject(projectCard: Card) {
        let projectIDOpt: UUID? = projectCard.id
        let fetch = FetchDescriptor<StoryStructure>(
            predicate: #Predicate { $0.projectID == projectIDOpt },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let existing = (try? modelContext.fetch(fetch)) ?? []

        // If user turned off "Attach Story Structure", delete any existing structure.
        if attachStructure == false {
            for s in existing {
                modelContext.delete(s) // cascade deletes elements
            }
            return
        }

        // Build from current UI state
        let trimmedName = structureName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName: String = trimmedName.isEmpty ? defaultStructureNameFromSource() : trimmedName

        let cleanedElements = editableElements
            .map { ($0.name.trimmingCharacters(in: .whitespacesAndNewlines), $0.description.trimmingCharacters(in: .whitespacesAndNewlines), $0.colorHue) }
            .filter { !$0.0.isEmpty }

        guard !cleanedElements.isEmpty else {
            // Nothing to persist; keep any existing structure as-is to avoid accidental wipe.
            return
        }

        if let structure = existing.first {
            // Update name
            structure.name = finalName

            // Remove all existing element rows to replace cleanly
            if let current = structure.elements {
                for el in current {
                    modelContext.delete(el)
                }
            }
            structure.elements = []

            // Recreate elements with new ordering
            for (idx, tuple) in cleanedElements.enumerated() {
                let (name, desc, hue) = tuple
                let el = StructureElement(name: name, elementDescription: desc, orderIndex: idx)
                el.colorHue = hue
                el.storyStructure = structure
                structure.elements?.append(el)
            }
        } else {
            // Create new structure and elements
            let structure = StoryStructure(name: finalName, projectID: projectCard.id)
            structure.elements = []
            for (idx, tuple) in cleanedElements.enumerated() {
                let (name, desc, hue) = tuple
                let el = StructureElement(name: name, elementDescription: desc, orderIndex: idx)
                el.colorHue = hue
                el.storyStructure = structure
                structure.elements?.append(el)
            }
            modelContext.insert(structure)
        }
    }
}

// MARK: - Quick Attribution Sheet (local to CardEditorView)

private struct QuickAttributionSheetEditor: View {
    let card: Card
    let kind: CitationKind
    let suggestedURL: URL?
    let prefilledExcerpt: String?
    var onSave: (Citation) -> Void
    var onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var sourceTitle: String = ""
    @State private var sourceAuthors: String = ""
    @State private var sourceURLString: String = ""
    @State private var locator: String = ""
    @State private var excerpt: String = ""
    @State private var note: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(kind == .image ? "Image Attribution" : "Add Citation")
                .font(.title3).bold()

            GroupBox("Source") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Title (e.g., site, collection, book, etc.)", text: $sourceTitle)
                    TextField("Authors (optional)", text: $sourceAuthors)
                    TextField("URL (optional)", text: $sourceURLString)
                        .urlEntryTraits()
                }
            }

            GroupBox("Details") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: kind == .image ? "photo" : "text.quote")
                        Text("Kind: \(kind.displayName)")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    TextField("Locator (e.g., fig. 2, p. 42, 00:12:15)", text: $locator)
                    TextField("Excerpt (optional)", text: $excerpt)
                    TextField("Note (optional)", text: $note)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Button("Skip") {
                    onSkip()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    saveAttribution()
                } label: {
                    Label("Save", systemImage: "checkmark.circle.fill")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding()
        .onAppear {
            if let u = suggestedURL {
                sourceURLString = u.absoluteString
                // If title empty, infer from host
                if sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    sourceTitle = (u.host ?? "").isEmpty ? "Web Source" : (u.host ?? "Web Source")
                }
            }
            if let prefill = prefilledExcerpt, excerpt.isEmpty {
                excerpt = prefill
            }
        }
    }

    private var canSave: Bool {
        // Allow save if at least a title or a URL is provided
        let hasTitle = !sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasURL = !sourceURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasTitle || hasURL
    }

    @MainActor
    private func saveAttribution() {
        // Normalize fields
        let title = sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let authors = sourceAuthors.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlStr = sourceURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        let loc = locator.trimmingCharacters(in: .whitespacesAndNewlines)
        let exc = excerpt.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteVal = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let finalTitle: String = title.isEmpty
            ? (URL(string: urlStr)?.host ?? (kind == .image ? "Image Source" : "Source"))
            : title

        let src = Source(title: finalTitle, authors: authors, url: urlStr.isEmpty ? nil : urlStr, accessedDate: urlStr.isEmpty ? nil : Date())
        modelContext.insert(src)

        let citation = Citation(card: card,
                                source: src,
                                kind: kind,
                                locator: loc,
                                excerpt: exc,
                                contextNote: noteVal.isEmpty ? nil : noteVal,
                                createdAt: Date())
        modelContext.insert(citation)
        try? modelContext.save()

        onSave(citation)
        dismiss()
    }
}

// MARK: - Cross-platform input traits helpers (local copy)

private extension View {
    @ViewBuilder
    func urlEntryTraits() -> some View {
        #if os(iOS) || os(tvOS) || os(visionOS)
        if #available(iOS 15.0, tvOS 15.0, visionOS 1.0, *) {
            self
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
        } else {
            // Fallback for older OSes
            self
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        #else
        // macOS: no-op
        self
        #endif
    }
}

