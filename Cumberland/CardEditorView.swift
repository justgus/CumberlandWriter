//
//  CardEditorView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/4/25.
//  Refactored by Claude Code on 2026-02-06 as part of ER-0022 Phase 3
//  Reduced from 2,666 lines to ~850 lines by extracting components
//
//  Modal card creation/editing form. Orchestrates sub-components extracted
//  to the CardEditor/ folder: form fields, image controls, thumbnail view,
//  structure panel, timeline section, save handler, drop handler, sheets,
//  and the content-analysis AI button. Supports create and edit modes for
//  all card kinds across macOS, iOS, and visionOS.
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
    @Environment(\.services) private var services
    @Environment(\.colorScheme) private var scheme

    // App settings (for default author)
    @Query(
        FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.singletonKey == "AppSettingsSingleton" }
        )
    ) private var settingsResults: [AppSettings]

    // Track focus so we only handle the shortcut when the Author field is focused
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, subtitle, author, details
    }

    // ER-0022: ViewModel manages all card editor state
    @State private var viewModel: CardEditorViewModel

    // UI state not managed by ViewModel
    @State private var isWorking: Bool = false
    @State private var pendingAttribution: PendingAttribution?
    @State private var descriptionAnalysis: DescriptionAnalyzer.AnalysisResult?

    // Drop handler
    private var dropHandler: CardEditorDropHandler {
        CardEditorDropHandler(
            viewModel: viewModel,
            mode: mode,
            onPendingAttribution: { attribution in
                pendingAttribution = attribution
            }
        )
    }

    // Save handler
    private var saveHandler: CardEditorSaveHandler {
        CardEditorSaveHandler(modelContext: modelContext, viewModel: viewModel, structureRepository: services?.structureRepository)
    }

    // MARK: - Tunable constants (match CardView where sensible)
    #if os(macOS)
    private let thumbnailSide: CGFloat = 72
    private let thumbnailTopPadding: CGFloat = 8
    private let maxCardWidth: CGFloat = .infinity  // Fill available width on macOS (DR-0051)
    #elseif os(visionOS)
    private let thumbnailSide: CGFloat = 96
    private let thumbnailTopPadding: CGFloat = 8
    private let maxCardWidth: CGFloat = 640
    #else  // iOS/iPadOS
    private let thumbnailSide: CGFloat = 72
    private let thumbnailTopPadding: CGFloat = 8
    private let maxCardWidth: CGFloat = 430
    #endif

    private let tabCornerRadius: CGFloat = 8
    private let tabHeight: CGFloat = 22
    private let tabHorizontalPadding: CGFloat = 10
    private let tabVerticalPadding: CGFloat = 2
    private let tabOffsetTop: CGFloat = -10
    private let tabOffsetLeft: CGFloat = 12

    // MARK: - Initialize state from mode

    init(mode: Mode) {
        self.mode = mode

        // Initialize ViewModel based on mode
        let vm = CardEditorViewModel(modelContext: nil) // Will be set from environment

        switch mode {
        case .create(let kind, _):
            // Initialize with defaults for create mode
            vm.name = ""
            vm.subtitle = ""
            vm.author = ""
            vm.detailedText = ""
            vm.sizeCategory = .standard

            // Default structure UI only makes sense for Projects
            if kind == .projects {
                let templates = StoryStructure.predefinedTemplates
                let initialIndex = 0
                let initialTemplate = templates.indices.contains(initialIndex) ? templates[initialIndex] : (name: "Custom Structure", elements: [])
                vm.selectedTemplateIndex = initialIndex
                vm.structureName = initialTemplate.name
                vm.editableElements = initialTemplate.elements.map { EditableElement(name: $0) }
            }

            // Timeline properties default to nil/empty for create mode
            vm.selectedCalendar = nil
            vm.epochDate = nil
            vm.epochDescription = ""

        case .edit(let card, _):
            // Load card data into ViewModel
            vm.loadCard(card)
        }

        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        let _ = mode.kind

        // Break down the body into smaller components to help the compiler
        mainContent
            .padding()
            .frame(minWidth: 520)
            .navigationTitle(navigationTitle)
            #if os(visionOS)
            .ornament(attachmentAnchor: .scene(.trailing)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Size")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Picker("Size", selection: $viewModel.sizeCategory) {
                        ForEach(SizeCategory.allCases, id: \.self) { sc in
                            Text(sc.displayName).tag(sc)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                }
                .padding()
                .glassBackgroundEffect()
            }
            #endif
            .applyImageTasks(viewModel: viewModel, loadThumbnailPreview: loadThumbnailPreview, loadInitialThumbnailIfEditing: loadInitialThumbnailIfEditing)
            .applyDropDestinations(viewModel: viewModel)
            .applyMacOSFocusedValue(focusedField: focusedField, defaultAuthorTrimmed: defaultAuthorTrimmed, insertDefaultAuthor: insertDefaultAuthorIfAvailable)
            .applyOnChangeHandlers(
                viewModel: viewModel,
                mode: mode,
                loadStructure: loadStructureStateForEditIfNeeded,
                updateAnalysis: { newText in
                    descriptionAnalysis = DescriptionAnalyzer.analyze(newText)
                }
            )
            .onAppear {
                setupOnAppear()
            }
            .sheet(item: $pendingAttribution) { ctx in
                attributionSheet(for: ctx)
            }
            .cardEditorSheets(
                viewModel: viewModel,
                mode: mode,
                modelContext: modelContext,
                onAIImageGenerated: handleAIImageGenerated
            )
    }
    
    // MARK: - Body Sub-Views
    
    private var navigationTitle: String {
        let kind = mode.kind
        return isEditing ? "Edit \(kind.title.dropLastIfPluralized())" : "New \(kind.title.dropLastIfPluralized())"
    }
    
    private var mainContent: some View {
        let kind = mode.kind
        
        return ScrollView {
            VStack(spacing: 16) {
                cardFlipContainer(kind: kind)
                    .frame(maxWidth: maxCardWidth)
                
                imageControls
                    .frame(maxWidth: maxCardWidth)
                
                Spacer()
                
                if isWorking {
                    ProgressView().controlSize(.small)
                }
            }
            .frame(maxWidth: maxCardWidth)
            .fileImporter(isPresented: $viewModel.isImportingImage, allowedContentTypes: [.image]) { result in
                handleFileImport(result)
            }
            
            citationsSection
            
            actionButtons(kind: kind)
        }
    }
    
    private func cardFlipContainer(kind: Kinds) -> some View {
        FlipCardContainer(isFlipped: $viewModel.isFlipped) {
            cardSurface(kind: kind) {
                frontCardFields
            }
        } back: {
            cardSurface(kind: kind) {
                backExtrasContent
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if hasKindExtras {
                flipButton
                    .padding(12)
                    .offset(x: 8, y: 8)
            }
        }
    }
    
    private var imageControls: some View {
        CardEditorImageControls(
            viewModel: viewModel,
            hasAnyImage: hasAnyImage,
            descriptionAnalysis: descriptionAnalysis,
            onImportImage: { viewModel.isImportingImage = true },
            onGenerateImage: { viewModel.showAIImageGeneration = true },
            onShowHistory: { viewModel.showImageHistory = true },
            onRemoveImage: { viewModel.removeImage() }
        )
    }
    
    @ViewBuilder
    private var citationsSection: some View {
        if isEditing, case .edit(let card, _) = mode {
            CitationViewer(card: card)
                .frame(maxWidth: maxCardWidth)
        }
    }
    
    private func actionButtons(kind: Kinds) -> some View {
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
            .disabled(!viewModel.validate(for: kind))
        }
        .frame(maxWidth: maxCardWidth)
    }
    
    @ViewBuilder
    private func attributionSheet(for ctx: PendingAttribution) -> some View {
        if case .edit(let card, _) = mode {
            QuickAttributionSheetEditor(
                card: card,
                kind: ctx.kind,
                suggestedURL: ctx.suggestedURL,
                prefilledExcerpt: ctx.prefilledExcerpt,
                onSave: { _ in },
                onSkip: { }
            )
            .frame(minWidth: 420, minHeight: 360)
        }
    }
    
    private func setupOnAppear() {
        if viewModel.modelContext == nil {
            viewModel.setModelContext(modelContext)
        }
        descriptionAnalysis = DescriptionAnalyzer.analyze(viewModel.detailedText)
        viewModel.checkClipboard()
    }

    // MARK: - Front Card Fields

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
                #if os(visionOS)
                // On visionOS, name field takes full width; size picker is in trailing ornament
                TextField("Name", text: $viewModel.name)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .focused($focusedField, equals: .name)
                #else
                HStack(alignment: .firstTextBaseline) {
                    TextField("Name", text: $viewModel.name)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                        .focused($focusedField, equals: .name)

                    sizePicker
                }
                #endif

                TextField("Subtitle (optional)", text: $viewModel.subtitle)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .subtitle)

                TextField("Author (optional)", text: $viewModel.author)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .author)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Details (Markdown supported)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Spacer()

                        // Analyze button (ER-0010)
                        CardEditorAnalysisButton(
                            viewModel: viewModel,
                            mode: mode,
                            modelContext: modelContext
                        )
                    }
                    TextEditor(text: $viewModel.detailedText)
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
                            dropHandler.handleTextDrop(providers)
                        }
                }
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Back Extras Content

    @ViewBuilder
    private var backExtrasContent: some View {
        let kind = mode.kind

        VStack(alignment: .leading, spacing: 16) {
            // Projects: Story Structure creation
            if kind == .projects {
                CardEditorStructurePanel(viewModel: viewModel)
            }

            // Timelines: Calendar system and epoch configuration
            if kind == .timelines || kind == .chronicles {
                CardEditorTimelineSection(viewModel: viewModel)
            }

            // Calendars: Calendar system editor (Phase 7.5)
            if kind == .calendars, case .edit(let card, _) = mode {
                CardEditorCalendarSection(viewModel: viewModel, cardName: card.name)
            }
        }
        .padding()
    }

    // MARK: - Thumbnail Drop View

    private var thumbnailDropView: some View {
        CardEditorThumbnailView(
            viewModel: viewModel,
            mode: mode,
            onShowFullSize: { viewModel.showFullSizeImage = true }
        )
        .onDrop(of: [.image, .url, .fileURL], isTargeted: nil) { providers in
            dropHandler.handleImageDrop(providers: providers)
            return true
        }
    }

    // MARK: - UI Components

    private var flipButton: some View {
        Button {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                viewModel.isFlipped.toggle()
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.borderless)
        .background(Circle().fill(.ultraThinMaterial))
        .help(viewModel.isFlipped ? "Show front" : "Show extras")
    }

    private func cardSurface<Content: View>(kind: Kinds, @ViewBuilder content: () -> Content) -> some View {
        let tabBg = scheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.3)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: kind.systemImage)
                    .foregroundStyle(kind.accentColor(for: scheme))
                Text(kind.title.dropLastIfPluralized())
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, tabHorizontalPadding)
            .padding(.vertical, tabVerticalPadding)
            .frame(height: tabHeight)
            .background(tabBg, in: RoundedRectangle(cornerRadius: tabCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: tabCornerRadius, style: .continuous)
                    .stroke(.quaternary, lineWidth: 0.5)
            }
            .offset(x: tabOffsetLeft, y: tabOffsetTop)

            content()
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.background)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
    }

    private var sizePicker: some View {
        Picker("Size", selection: $viewModel.sizeCategory) {
            ForEach(SizeCategory.allCases, id: \.self) { sc in
                Text(sc.displayName).tag(sc)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Card size")
    }



    // MARK: - Derived Properties

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var hasAnyImage: Bool {
        switch mode {
        case .create:
            return viewModel.imageData != nil
        case .edit(let card, _):
            return viewModel.imageData != nil || card.thumbnailData != nil || card.imageFileURL != nil
        }
    }

    private var defaultAuthorTrimmed: String {
        (settingsResults.first?.defaultAuthor ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Kinds that have additional controls on the back face
    private var hasKindExtras: Bool {
        let kind = mode.kind

        // Projects always show flip button (structure creation)
        if kind == .projects {
            return true
        }

        // Timelines and Chronicles show flip button (calendar/epoch)
        if kind == .timelines || kind == .chronicles {
            return true
        }

        // Calendars show flip button only in edit mode (calendar system editor)
        if kind == .calendars, case .edit = mode {
            return true
        }

        return false
    }

    // MARK: - Actions

    private func insertDefaultAuthorIfAvailable() {
        if !defaultAuthorTrimmed.isEmpty {
            viewModel.author = defaultAuthorTrimmed
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        if case let .success(url) = result,
           let data = try? Data(contentsOf: url) {
            viewModel.imageData = data
            viewModel.imageMetadata = ImageMetadataExtractor.extract(from: data)
        }
    }

    private func handleAIImageGenerated(_ generatedData: GeneratedImageData) {
        // ER-0017: Save current image as version before regenerating
        if case .edit(let card, _) = mode {
            card.saveCurrentImageAsVersion(in: modelContext)
        }

        // Embed EXIF/IPTC metadata into image
        let imageDataWithMetadata = ImageMetadataWriter.embedMetadataForCard(
            imageData: generatedData.imageData,
            prompt: generatedData.prompt,
            provider: generatedData.provider,
            generatedAt: generatedData.generatedAt,
            userCopyright: nil
        )

        // Store the image with embedded metadata
        viewModel.imageData = imageDataWithMetadata

        // Update AI metadata in Card model if in edit mode
        if case .edit(let card, _) = mode {
            card.imageGeneratedByAI = true
            card.imageAIProvider = generatedData.provider
            card.imageAIPrompt = generatedData.prompt
            card.imageAIGeneratedAt = generatedData.generatedAt

            // Auto-create image attribution citation
            createAIImageCitation(
                for: card,
                provider: generatedData.provider,
                prompt: generatedData.prompt,
                generatedAt: generatedData.generatedAt
            )
        }
    }

    private func createAIImageCitation(
        for card: Card,
        provider: String,
        prompt: String,
        generatedAt: Date
    ) {
        // Check if AI attribution citation already exists
        let existingAICitations = (card.citations ?? []).filter { citation in
            citation.kind == .image && citation.source?.title.contains("AI-Generated") == true
        }

        // If we already have an AI image citation, don't create a duplicate
        guard existingAICitations.isEmpty else { return }

        // Create source for AI-generated image
        let source = Source(
            title: "AI-Generated Image (\(provider))",
            authors: provider,
            url: nil,
            accessedDate: generatedAt
        )
        modelContext.insert(source)

        // Create citation for AI-generated image
        let citation = Citation(
            card: card,
            source: source,
            kind: .image,
            locator: "",
            excerpt: "Generated with prompt: \"\(prompt)\"",
            contextNote: nil,
            createdAt: generatedAt
        )

        // Insert into context
        modelContext.insert(citation)

        // Save
        try? modelContext.save()

        #if DEBUG
        print("✅ [CardEditorView] Created AI image citation for card: \(card.name)")
        #endif
    }

    // MARK: - Save

    private func save() {
        let trimmedName = viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        do {
            switch mode {
            case .create(_, let onComplete):
                try saveHandler.saveNewCard(kind: mode.kind, onComplete: { card in
                    onComplete(card)
                    dismiss()
                })

            case .edit(let card, let onComplete):
                try saveHandler.saveExistingCard(card, onComplete: {
                    onComplete()
                    dismiss()
                })
            }
        } catch {
            #if DEBUG
            print("⚠️ [CardEditorView] Save failed: \(error)")
            #endif
        }
    }

    // MARK: - Image Loading

    private func loadThumbnailPreview() async {
        guard let data = viewModel.imageData else { return }

        #if os(macOS)
        if let nsImage = NSImage(data: data) {
            viewModel.thumbnail = Image(nsImage: nsImage)
        }
        #else
        if let uiImage = UIImage(data: data) {
            viewModel.thumbnail = Image(uiImage: uiImage)
        }
        #endif
    }

    private func loadInitialThumbnailIfEditing() async {
        guard case .edit(let card, _) = mode else { return }
        guard let originalImageData = card.originalImageData else { return }

        #if os(macOS)
        if let nsImage = NSImage(data: originalImageData) {
            viewModel.thumbnail = Image(nsImage: nsImage)
        }
        #else
        if let uiImage = UIImage(data: originalImageData) {
            viewModel.thumbnail = Image(uiImage: uiImage)
        }
        #endif
    }

    // MARK: - Structure Loading

    private func loadStructureStateForEditIfNeeded() async {
        guard case .edit(let card, _) = mode else { return }
        guard card.kind == .projects else { return }

        // If a structure already exists linked to this project, load it
        let projectName = card.name
        let fetchDesc = FetchDescriptor<StoryStructure>(
            predicate: #Predicate { structure in
                structure.name == projectName
            }
        )

        guard let existing = try? modelContext.fetch(fetchDesc).first else {
            // No existing structure; user can create one if desired
            viewModel.attachStructure = false
            return
        }

        // Found existing structure; populate UI
        viewModel.attachStructure = true
        viewModel.structureSource = .custom
        viewModel.structureName = existing.name
        viewModel.editableElements = (existing.elements ?? [])
            .sorted(by: { $0.orderIndex < $1.orderIndex })
            .map { el in
                EditableElement(
                    name: el.name,
                    description: el.elementDescription,
                    colorHue: el.colorHue
                )
            }
    }

    // MARK: - Static Utilities

    public static func isSupportedImageURL(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "heic", "heif", "bmp", "tiff", "tif"].contains(ext)
    }

    public static func isSupportedImageData(_ data: Data) -> Bool {
        return makeCGImage(from: data) != nil
    }

    private static func makeCGImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private static func inferFileExtension(from data: Data) -> String? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let uti = CGImageSourceGetType(source) else { return nil }
        let ext = (uti as String).split(separator: ".").last.map(String.init)
        return ext
    }
}

// MARK: - View Modifier Extensions

extension View {
    func applyImageTasks(
        viewModel: CardEditorViewModel,
        loadThumbnailPreview: @escaping () async -> Void,
        loadInitialThumbnailIfEditing: @escaping () async -> Void
    ) -> some View {
        self
            .task(id: viewModel.imageData) {
                await loadThumbnailPreview()
            }
            .task {
                if viewModel.thumbnail == nil {
                    await loadInitialThumbnailIfEditing()
                }
            }
            .onChange(of: viewModel.selectedPhotoItem) { _, newItem in
                Task { await viewModel.processSelectedPhoto() }
            }
    }
    
    func applyDropDestinations(viewModel: CardEditorViewModel) -> some View {
        self
            .dropDestination(for: Data.self) { items, _ in
                if let data = items.first, CardEditorView.isSupportedImageData(data) {
                    viewModel.imageData = data
                    return true
                }
                return false
            }
            .dropDestination(for: URL.self) { urls, _ in
                guard let url = urls.first, CardEditorView.isSupportedImageURL(url),
                      let data = try? Data(contentsOf: url) else { return false }
                viewModel.imageData = data
                return true
            }
    }
    
    @ViewBuilder
    func applyMacOSFocusedValue(
        focusedField: CardEditorView.Field?,
        defaultAuthorTrimmed: String,
        insertDefaultAuthor: @escaping () -> Void
    ) -> some View {
        #if os(macOS)
        self.focusedValue(
            \.insertDefaultAuthor,
            (focusedField == .author && !defaultAuthorTrimmed.isEmpty) ? insertDefaultAuthor : nil
        )
        #else
        self
        #endif
    }
    
    func applyOnChangeHandlers(
        viewModel: CardEditorViewModel,
        mode: CardEditorView.Mode,
        loadStructure: @escaping () async -> Void,
        updateAnalysis: @escaping (String) -> Void
    ) -> some View {
        self
            .onChange(of: viewModel.isFlipped) { _, flipped in
                if flipped {
                    Task { await loadStructure() }
                }
            }
            .onChange(of: viewModel.selectedTemplateIndex) { _, newIndex in
                guard case .create(let createKind, _) = mode, createKind == .projects else { return }
                guard viewModel.structureSource == .template else { return }
                let templates = StoryStructure.predefinedTemplates
                guard templates.indices.contains(newIndex) else { return }
                let t = templates[newIndex]
                viewModel.structureName = t.name
                viewModel.editableElements = t.elements.map { EditableElement(name: $0) }
            }
            .onChange(of: viewModel.detailedText) { _, newText in
                updateAnalysis(newText)
            }
    }
}

// MARK: - Supporting Types
