// CardSheetView.swift
// Refactored as part of ER-0022 Phase 3.2
// Extracted components to CardSheet/ folder:
// - CardSheetHeaderView.swift
// - CardSheetEditorArea.swift
// - CardSheetFocusMode.swift
// - CardSheetDropHandler.swift
// - MarkdownFormatting.swift
// Extracted to Components/:
// - AdaptiveToolbar.swift

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif
import CoreTransferable

struct CardSheetView: View {
    let card: Card

    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Image State
    @State private var fullImage: Image?
    @State private var isDropTargeted: Bool = false
    @State private var isAttributionVisible: Bool = false
    @State private var showFullSizeImage: Bool = false
    @State private var showAIImageInfo: Bool = false

    // MARK: - Focus Mode State
    @AppStorage("CardDetailFocusModeEnabled") private var isFocusModeEnabled: Bool = false
    @AppStorage("CardDetailFocusModeCardID") private var focusModeCardIDRaw: String = ""

    // MARK: - Editor State
    @State private var editorMode: CardSheetEditorMode = .preview
    @FocusState private var focusedField: CardSheetFieldFocus?

    // Name/subtitle editing
    @State private var isEditingName: Bool = false
    @State private var isEditingSubtitle: Bool = false
    @State private var nameDraft: String = ""
    @State private var subtitleDraft: String = ""

    // Details editing
    @State private var detailsDraft: String = ""
    @State private var detailsSelection: NSRange = NSRange(location: 0, length: 0)

    // Autosave
    @State private var autosaveTask: Task<Void, Never>?
    private let autosaveDelay: UInt64 = 1_000_000_000 // 1s

    // MARK: - Attribution State
    @State private var pendingAttribution: CardSheetPendingAttribution?

    // MARK: - Import State
    @State private var isImportingImage: Bool = false
    @State private var isImportingText: Bool = false

    #if os(iOS)
    @State private var isPresentingPhotosPicker: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    #endif

    // MARK: - Computed Properties

    private var isDetailsEditable: Bool {
        editorMode != .preview
    }

    private var canAcceptImageDrop: Bool {
        editorMode != .preview
    }

    // MARK: - Body

    var body: some View {
        mainContent
            .navigationTitle(card.name)
            .applyToolbarBackground()
            #if os(iOS) || os(visionOS)
            .toolbar { toolbarContent }
            #endif
            .task { await loadFullImage() }
            .task(id: card.id) { await loadFullImage() }
            .task(id: card.imageFileURL) { await loadFullImage() }
            .onAppear { initializeDrafts() }
            .onChange(of: card.id) { _, _ in handleCardChange() }
            .onChange(of: card.detailedText) { _, _ in syncDetailsIfNeeded() }
            .onChange(of: editorMode) { old, new in handleEditorModeChange(from: old, to: new) }
            .onChange(of: scenePhase) { _, newPhase in handleScenePhaseChange(newPhase) }
            .onChange(of: detailsDraft) { _, _ in handleDetailsDraftChange() }
            .onChange(of: isFocusModeEnabled) { _, on in handleFocusModeChange(on) }
            .applyFocusPresentation(
                card: card,
                isFocusModeEnabled: isFocusModeEnabled,
                focusModeCardIDRaw: focusModeCardIDRaw,
                detailsDraft: $detailsDraft,
                detailsSelection: $detailsSelection,
                toolbar: AnyView(adaptiveFormattingToolbar),
                onPrepare: prepareEditorForFocus,
                onExit: { exitFocusMode() }
            )
            .sheet(item: $pendingAttribution) { ctx in
                QuickAttributionSheet(
                    card: card,
                    kind: ctx.kind,
                    suggestedURL: ctx.suggestedURL,
                    prefilledExcerpt: ctx.prefilledExcerpt,
                    onSave: { _ in isAttributionVisible = true },
                    onSkip: {}
                )
                .frame(minWidth: 420, minHeight: 360)
            }
            .applyFullSizeImageViewer(isPresented: $showFullSizeImage, card: card)
            .sheet(isPresented: $showAIImageInfo) {
                AIImageInfoView(card: card)
            }
            .applyImporters(
                isImportingImage: $isImportingImage,
                isImportingText: $isImportingText,
                onImageImported: handleImageImport,
                onTextImported: handleTextImport
            )
            #if os(iOS)
            .photosPicker(isPresented: $isPresentingPhotosPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in handlePhotosPickerSelection(newItem) }
            #endif
            #if os(macOS)
            .onExitCommand { handleExitCommand() }
            #endif
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            #if !os(visionOS)
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            #endif

            VStack(alignment: .leading, spacing: 16) {
                CardSheetModePicker(editorMode: $editorMode)

                CardSheetHeaderView(
                    card: card,
                    fullImage: $fullImage,
                    isDropTargeted: $isDropTargeted,
                    isAttributionVisible: $isAttributionVisible,
                    showFullSizeImage: $showFullSizeImage,
                    showAIImageInfo: $showAIImageInfo,
                    nameDraft: $nameDraft,
                    subtitleDraft: $subtitleDraft,
                    isEditingName: $isEditingName,
                    isEditingSubtitle: $isEditingSubtitle,
                    focusedField: $focusedField,
                    onCommitName: commitName,
                    onCommitSubtitle: commitSubtitle,
                    onPresentImagePicker: { isImportingImage = true },
                    onPresentPhotosPicker: { presentPhotosPicker() },
                    onRemoveImage: removeImage,
                    onHandleDrop: { providers in dropHandler.handleDrop(providers: providers) },
                    canAcceptImageDrop: canAcceptImageDrop
                )

                Divider()

                CardSheetEditorArea(
                    card: card,
                    editorMode: $editorMode,
                    detailsDraft: $detailsDraft,
                    detailsSelection: $detailsSelection,
                    focusedField: $focusedField,
                    toolbarItems: toolbarItems,
                    onSaveDetailsIfDirty: { actionName in saveDetailsIfDirty(actionName: actionName) },
                    onTextDrop: { providers in textDropHandler.handleTextDrop(providers: providers) },
                    onIndent: { isOutdent in handleIndentOutdent(isOutdent: isOutdent) }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            #if os(macOS)
            .overlay(alignment: .topTrailing) {
                Button {
                    toggleFocusModeForCard(
                        cardID: card.id,
                        isFocusModeEnabled: isFocusModeEnabled,
                        focusModeCardIDRaw: focusModeCardIDRaw
                    )
                } label: {
                    Image(systemName: isFocusModeEnabled && focusModeCardIDRaw == card.id.uuidString
                          ? "arrow.down.right.and.arrow.up.left"
                          : "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.plain)
                .help(isFocusModeEnabled && focusModeCardIDRaw == card.id.uuidString ? "Exit Focus" : "Enter Focus")
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .padding(10)
            }
            #endif
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                toggleFocusModeForCard(
                    cardID: card.id,
                    isFocusModeEnabled: isFocusModeEnabled,
                    focusModeCardIDRaw: focusModeCardIDRaw
                )
            } label: {
                Image(systemName: isFocusModeEnabled && focusModeCardIDRaw == card.id.uuidString
                      ? "arrow.down.right.and.arrow.up.left"
                      : "arrow.up.left.and.arrow.down.right")
            }
            .help(isFocusModeEnabled && focusModeCardIDRaw == card.id.uuidString ? "Exit Focus" : "Enter Focus")
            .keyboardShortcut("f", modifiers: [.command, .shift])
        }

        #if os(iOS)
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button { isPresentingPhotosPicker = true } label: {
                    Label("Image from Photos...", systemImage: "photo.on.rectangle")
                }
                Button { isImportingImage = true } label: {
                    Label("Image from Files...", systemImage: "folder")
                }
                Divider()
                Button { isImportingText = true } label: {
                    Label("Text from Files...", systemImage: "doc.text")
                }
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            .help("Import content into this card")
        }
        #endif
    }

    // MARK: - Formatting Toolbar

    private var toolbarItems: [AdaptiveToolbar.Item] {
        [
            .button(id: "bold", systemImage: "bold", shortcut: .init(key: "b", modifiers: .command)) { toggleBold() },
            .button(id: "italic", systemImage: "italic", shortcut: .init(key: "i", modifiers: .command)) { toggleItalic() },
            .button(id: "inlineCode", systemImage: "curlybraces", shortcut: .init(key: "`", modifiers: .command)) { toggleInlineCode() },
            .button(id: "codeBlock", systemImage: "curlybraces.square", shortcut: nil) { insertCodeBlock() },
            .divider,
            .button(id: "h1", systemImage: "textformat.size.larger", title: "H1", shortcut: .init(key: "1", modifiers: .command)) { applyHeading(level: 1) },
            .button(id: "h2", systemImage: "textformat.size", title: "H2", shortcut: .init(key: "2", modifiers: .command)) { applyHeading(level: 2) },
            .button(id: "h3", systemImage: "textformat.size.smaller", title: "H3", shortcut: .init(key: "3", modifiers: .command)) { applyHeading(level: 3) },
            .divider,
            .button(id: "bullet", systemImage: "list.bullet", shortcut: .init(key: "8", modifiers: [.command, .shift])) { toggleBulletList() },
            .button(id: "number", systemImage: "list.number", shortcut: .init(key: "7", modifiers: [.command, .shift])) { toggleNumberedList() },
            .button(id: "quote", systemImage: "text.quote", shortcut: .init(key: "'", modifiers: .command)) { toggleQuote() },
            .button(id: "checklist", systemImage: "checklist", shortcut: nil) { toggleChecklist() },
            .button(id: "checklistToggle", systemImage: "checkmark.square", shortcut: nil) { toggleChecklistDoneUndone() },
            .divider,
            .button(id: "indent", systemImage: "increase.indent", shortcut: nil) { handleIndentOutdent(isOutdent: false) },
            .button(id: "outdent", systemImage: "decrease.indent", shortcut: nil) { handleIndentOutdent(isOutdent: true) }
        ]
    }

    private var adaptiveFormattingToolbar: some View {
        AdaptiveToolbar(items: toolbarItems)
            .controlSize(.small)
            .labelStyle(.iconOnly)
            .accessibilityElement(children: .contain)
    }

    // MARK: - Drop Handlers

    private var dropHandler: CardSheetDropHandler {
        CardSheetDropHandler(
            card: card,
            modelContext: modelContext,
            undoManager: undoManager,
            onImageLoaded: { await loadFullImage() },
            onAttributionNeeded: { pendingAttribution = $0 }
        )
    }

    private var textDropHandler: CardSheetTextDropHandler {
        CardSheetTextDropHandler(
            isDetailsEditable: { isDetailsEditable },
            insertTextAtSelection: insertTextAtSelection,
            onAttributionNeeded: { pendingAttribution = $0 }
        )
    }

    // MARK: - Initialization & Lifecycle

    private func initializeDrafts() {
        nameDraft = card.name
        subtitleDraft = card.subtitle
        detailsDraft = card.detailedText
        isAttributionVisible = false

        if isFocusModeEnabled, focusModeCardIDRaw == card.id.uuidString {
            prepareEditorForFocus()
            #if os(macOS)
            FocusOverlayPresenter.shared.present(
                for: card,
                text: $detailsDraft,
                selection: $detailsSelection,
                toolbar: adaptiveFormattingToolbar,
                onExit: { exitFocusMode() }
            )
            #endif
        }
    }

    private func handleCardChange() {
        autosaveTask?.cancel()
        isEditingName = false
        isEditingSubtitle = false
        focusedField = nil
        nameDraft = card.name
        subtitleDraft = card.subtitle
        detailsDraft = card.detailedText
        detailsSelection = NSRange(location: 0, length: 0)
        editorMode = .preview
        isAttributionVisible = false

        if isFocusModeEnabled, focusModeCardIDRaw != card.id.uuidString {
            UserDefaults.standard.set(false, forKey: "CardDetailFocusModeEnabled")
            UserDefaults.standard.set("", forKey: "CardDetailFocusModeCardID")
        }
    }

    private func syncDetailsIfNeeded() {
        if !isDetailsEditable {
            detailsDraft = card.detailedText
        }
    }

    private func handleEditorModeChange(from old: CardSheetEditorMode, to new: CardSheetEditorMode) {
        if (old == .edit || old == .split), !(new == .edit || new == .split) {
            saveDetailsIfDirty(actionName: "Edit Details")
        }
        if new == .edit || new == .split {
            detailsDraft = card.detailedText
            detailsSelection = NSRange(location: (detailsDraft as NSString).length, length: 0)
            focusedField = .details
        }
        if new == .preview {
            isDropTargeted = false
        }
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        if newPhase == .inactive || newPhase == .background {
            Task { @MainActor in
                saveDetailsIfDirty(actionName: "Autosave Details")
            }
        }
    }

    private func handleDetailsDraftChange() {
        guard isDetailsEditable else { return }
        scheduleAutosave()
    }

    private func handleFocusModeChange(_ on: Bool) {
        #if os(macOS)
        if on {
            guard focusModeCardIDRaw == card.id.uuidString else { return }
            prepareEditorForFocus()
            FocusOverlayPresenter.shared.present(
                for: card,
                text: $detailsDraft,
                selection: $detailsSelection,
                toolbar: adaptiveFormattingToolbar,
                onExit: { exitFocusMode() }
            )
        } else {
            exitFocusMode(save: true)
        }
        #endif
    }

    #if os(macOS)
    private func handleExitCommand() {
        if isFocusModeEnabled {
            UserDefaults.standard.set(false, forKey: "CardDetailFocusModeEnabled")
            UserDefaults.standard.set("", forKey: "CardDetailFocusModeCardID")
        }
    }
    #endif

    // MARK: - Focus Mode

    @MainActor
    private func prepareEditorForFocus() {
        if editorMode == .preview {
            editorMode = .edit
        }
        detailsDraft = card.detailedText
        detailsSelection = NSRange(location: (detailsDraft as NSString).length, length: 0)
        focusedField = .details
    }

    @MainActor
    private func exitFocusMode(save: Bool = true) {
        if save {
            saveDetailsIfDirty(actionName: "Edit Details")
        }
        #if os(macOS)
        FocusOverlayPresenter.shared.dismiss()
        #endif
    }

    // MARK: - Name/Subtitle Commits

    @MainActor
    private func commitName() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            nameDraft = card.name
            isEditingName = false
            focusedField = nil
            return
        }
        if trimmed != card.name {
            let old = card.name
            registerUndo(actionName: "Edit Name") { self.card.name = old }
            card.name = trimmed
            try? modelContext.save()
        }
        isEditingName = false
        focusedField = nil
    }

    @MainActor
    private func commitSubtitle() {
        if subtitleDraft != card.subtitle {
            let old = card.subtitle
            registerUndo(actionName: "Edit Subtitle") { self.card.subtitle = old }
            card.subtitle = subtitleDraft
            try? modelContext.save()
        }
        isEditingSubtitle = false
        focusedField = nil
    }

    // MARK: - Details Save

    @MainActor
    private func saveDetailsIfDirty(actionName: String) {
        guard detailsDraft != card.detailedText else { return }
        let old = card.detailedText
        registerUndo(actionName: actionName) {
            self.card.detailedText = old
            try? self.modelContext.save()
        }
        card.detailedText = detailsDraft
        try? modelContext.save()
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: autosaveDelay)
            saveDetailsIfDirty(actionName: "Autosave Details")
        }
    }

    // MARK: - Formatting Operations (delegated to MarkdownFormatter)

    private func toggleBold() {
        let (text, sel) = MarkdownFormatter.toggleBold(in: detailsDraft, selection: detailsSelection)
        detailsDraft = text
        detailsSelection = sel
    }

    private func toggleItalic() {
        let (text, sel) = MarkdownFormatter.toggleItalic(in: detailsDraft, selection: detailsSelection)
        detailsDraft = text
        detailsSelection = sel
    }

    private func toggleInlineCode() {
        let (text, sel) = MarkdownFormatter.toggleInlineCode(in: detailsDraft, selection: detailsSelection)
        detailsDraft = text
        detailsSelection = sel
    }

    private func insertCodeBlock() {
        detailsDraft = MarkdownFormatter.insertCodeBlock(in: detailsDraft)
    }

    private func applyHeading(level: Int) {
        let (text, sel) = MarkdownFormatter.applyHeading(level: level, in: detailsDraft, selection: detailsSelection)
        detailsDraft = text
        detailsSelection = sel
    }

    private func toggleBulletList() {
        let (text, sel) = MarkdownFormatter.toggleBulletList(in: detailsDraft, selection: detailsSelection)
        detailsDraft = text
        detailsSelection = sel
    }

    private func toggleNumberedList() {
        let (text, sel) = MarkdownFormatter.toggleNumberedList(in: detailsDraft, selection: detailsSelection)
        detailsDraft = text
        detailsSelection = sel
    }

    private func toggleQuote() {
        let (text, sel) = MarkdownFormatter.toggleQuote(in: detailsDraft, selection: detailsSelection)
        detailsDraft = text
        detailsSelection = sel
    }

    private func toggleChecklist() {
        let (text, sel) = MarkdownFormatter.toggleChecklist(in: detailsDraft, selection: detailsSelection)
        detailsDraft = text
        detailsSelection = sel
    }

    private func toggleChecklistDoneUndone() {
        let (text, sel) = MarkdownFormatter.toggleChecklistDoneUndone(in: detailsDraft, selection: detailsSelection)
        detailsDraft = text
        detailsSelection = sel
    }

    private func handleIndentOutdent(isOutdent: Bool) {
        let (text, sel) = MarkdownFormatter.handleIndentOutdent(isOutdent: isOutdent, in: detailsDraft, selection: detailsSelection)
        detailsDraft = text
        detailsSelection = sel
    }

    // MARK: - Text Insertion

    @MainActor
    private func insertTextAtSelection(_ text: String) {
        let ns = detailsDraft as NSString
        var sel = detailsSelection
        sel.location = max(0, min(sel.location, ns.length))
        sel.length = max(0, min(sel.length, ns.length - sel.location))

        let newText = ns.replacingCharacters(in: sel, with: text)
        let newCursor = sel.location + (text as NSString).length
        detailsDraft = newText
        detailsSelection = NSRange(location: newCursor, length: 0)
        scheduleAutosave()
    }

    // MARK: - Image Loading

    @MainActor
    private func loadFullImage() async {
        let img: Image?
        if let primary = await card.makeImage() {
            img = primary
        } else {
            img = await card.makeThumbnailImage()
        }
        withAnimation(.easeInOut(duration: 0.15)) {
            self.fullImage = img
        }
    }

    private func removeImage() {
        dropHandler.removeImage()
    }

    // MARK: - Import Handlers

    private func handleImageImport(_ data: Data) {
        if dropHandler.handleDroppedImageData(data) {
            pendingAttribution = CardSheetPendingAttribution(
                suggestedURL: nil,
                isWeb: false,
                kind: .image,
                prefilledExcerpt: nil
            )
        }
    }

    private func handleTextImport(_ url: URL, _ text: String) {
        insertTextAtSelection(text)
        let excerpt = String(text.prefix(280))
        pendingAttribution = CardSheetPendingAttribution(
            suggestedURL: url.isFileURL ? nil : url,
            isWeb: url.scheme?.hasPrefix("http") == true,
            kind: .quote,
            prefilledExcerpt: excerpt
        )
    }

    private func presentPhotosPicker() {
        #if os(iOS)
        isPresentingPhotosPicker = true
        #endif
    }

    #if os(iOS)
    private func handlePhotosPickerSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    handleImageImport(data)
                }
            } else if let uiImage = try? await item.loadTransferable(type: UIImage.self),
                      let data = uiImage.pngData() ?? uiImage.jpegData(compressionQuality: 0.9) {
                await MainActor.run {
                    handleImageImport(data)
                }
            }
            await MainActor.run {
                selectedPhotoItem = nil
            }
        }
    }
    #endif

    // MARK: - Undo Helper

    private func registerUndo(actionName: String, _ undoBlock: @escaping () -> Void) {
        undoManager?.registerUndo(withTarget: UndoBox(action: undoBlock)) { box in
            box.action()
        }
        undoManager?.setActionName(actionName)
    }

    private final class UndoBox {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
    }
}

// MARK: - View Extensions for Modifiers

private extension View {
    @ViewBuilder
    func applyToolbarBackground() -> some View {
        #if os(iOS)
        self
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        #elseif os(macOS)
        self
            .toolbarBackground(.visible, for: .windowToolbar)
            .toolbarBackground(.ultraThinMaterial, for: .windowToolbar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func applyFocusPresentation(
        card: Card,
        isFocusModeEnabled: Bool,
        focusModeCardIDRaw: String,
        detailsDraft: Binding<String>,
        detailsSelection: Binding<NSRange>,
        toolbar: AnyView,
        onPrepare: @escaping () -> Void,
        onExit: @escaping () -> Void
    ) -> some View {
        #if os(iOS)
        let binding = Binding<Bool>(
            get: { isFocusModeEnabled && focusModeCardIDRaw == card.id.uuidString },
            set: { newValue in
                if newValue {
                    UserDefaults.standard.set(card.id.uuidString, forKey: "CardDetailFocusModeCardID")
                    UserDefaults.standard.set(true, forKey: "CardDetailFocusModeEnabled")
                } else {
                    UserDefaults.standard.set(false, forKey: "CardDetailFocusModeEnabled")
                    UserDefaults.standard.set("", forKey: "CardDetailFocusModeCardID")
                }
            }
        )
        self
            .fullScreenCover(isPresented: binding) {
                FocusFullScreen(
                    isPresented: binding,
                    title: card.name,
                    detailsText: detailsDraft,
                    selection: detailsSelection,
                    toolbar: toolbar,
                    onExit: onExit
                )
            }
            .onChange(of: isFocusModeEnabled && focusModeCardIDRaw == card.id.uuidString) { _, isActive in
                if isActive { onPrepare() }
            }
        #else
        self
        #endif
    }

    @ViewBuilder
    func applyFullSizeImageViewer(isPresented: Binding<Bool>, card: Card) -> some View {
        #if os(macOS)
        self.sheet(isPresented: isPresented) {
            FullSizeImageViewer(card: card, pendingImageData: nil)
                .id(card.originalImageData?.count ?? 0)
        }
        #else
        self.fullScreenCover(isPresented: isPresented) {
            FullSizeImageViewer(card: card, pendingImageData: nil)
                .id(card.originalImageData?.count ?? 0)
        }
        #endif
    }

    @ViewBuilder
    func applyImporters(
        isImportingImage: Binding<Bool>,
        isImportingText: Binding<Bool>,
        onImageImported: @escaping (Data) -> Void,
        onTextImported: @escaping (URL, String) -> Void
    ) -> some View {
        self
            .fileImporter(isPresented: isImportingImage, allowedContentTypes: [.image], allowsMultipleSelection: false) { result in
                if case .success(let urls) = result, let url = urls.first, let data = try? Data(contentsOf: url) {
                    Task { @MainActor in
                        onImageImported(data)
                    }
                }
            }
            .fileImporter(isPresented: isImportingText, allowedContentTypes: [.plainText, .text], allowsMultipleSelection: false) { result in
                guard case .success(let urls) = result, let url = urls.first else { return }
                Task { @MainActor in
                    if let data = try? Data(contentsOf: url),
                       let s = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) {
                        onTextImported(url, s)
                    }
                }
            }
    }
}

// MARK: - UIImage Transferable (iOS)

#if os(iOS)
extension UIImage: @retroactive Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let image = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            return image
        }
    }

    enum TransferError: Error {
        case importFailed
    }
}
#endif

// MARK: - Preview

#Preview("CardSheetView") {
    let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, configurations: cfg)
    let ctx = ModelContext(container)
    let sample = Card(
        kind: .projects,
        name: "Exploration Project",
        subtitle: "Initial Planning",
        detailedText: """
        # Overview

        This supports **Markdown**, including:
        - Bullet lists
        - Links: [Apple](https://apple.com)
        - Inline code: `let x = 1`
        - [ ] Checklist item
        - [x] Done item

        > Blockquotes also render in Text with AttributedString.
        """,
        author: nil,
        sizeCategory: .standard
    )
    ctx.insert(sample)
    try? ctx.save()

    return NavigationStack {
        CardSheetView(card: sample)
    }
    .modelContainer(container)
}
