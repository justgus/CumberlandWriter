// CardSheetView.swift
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

    @State private var fullImage: Image?
    @State private var isDropTargeted: Bool = false

    // Persist Focus Mode across launches and remember which card was focused
    @AppStorage("CardDetailFocusModeEnabled") private var isFocusModeEnabled: Bool = false
    @AppStorage("CardDetailFocusModeCardID") private var focusModeCardIDRaw: String = ""

    // Editor mode
    private enum EditorMode: String, CaseIterable, Identifiable {
        case edit = "Edit"
        case preview = "Preview"
        case split = "Split"

        var id: String { rawValue }
    }
    // Default to Preview; user taps to enter Edit
    @State private var editorMode: EditorMode = .preview

    // Inline editing state
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case name, subtitle, details
    }
    @State private var isEditingName: Bool = false
    @State private var isEditingSubtitle: Bool = false

    @State private var nameDraft: String = ""
    @State private var subtitleDraft: String = ""
    @State private var detailsDraft: String = ""
    @State private var detailsSelection: NSRange = NSRange(location: 0, length: 0)

    // Autosave
    @State private var autosaveTask: Task<Void, Never>?
    private let autosaveDelay: UInt64 = 1_000_000_000 // 1s

    private var isDetailsEditable: Bool {
        editorMode != .preview
    }

    // Only allow image drop/paste when not in Preview
    private var canAcceptImageDrop: Bool {
        editorMode != .preview
    }

    // Hover state for the floating focus control (macOS)
    #if os(macOS)
    @State private var isHoveringFocusButton: Bool = false
    #endif

    // Image attribution visibility (hidden by default; toggled by tapping the image/placeholder)
    @State private var isAttributionVisible: Bool = false

    // Full-size image viewer
    @State private var showFullSizeImage: Bool = false

    // AI Image Info panel (ER-0009)
    @State private var showAIImageInfo: Bool = false

    // MARK: - Quick Attribution Prompt State

    // Context for presenting the quick attribution dialog after a successful drop/import.
    private struct PendingAttribution: Identifiable, Equatable {
        let id = UUID()
        let suggestedURL: URL?
        let isWeb: Bool
        let kind: CitationKind
        let prefilledExcerpt: String?
    }

    @State private var pendingAttribution: PendingAttribution?

    // MARK: - Import state (Files + Photos)

    // Existing image importer (Files)
    @State private var isImportingImage: Bool = false

    // New: Text importer (Files)
    @State private var isImportingText: Bool = false

    // New: Photos picker (iPadOS)
    #if os(iOS)
    @State private var isPresentingPhotosPicker: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    #endif

    // MARK: - Type lists extracted to reduce type-checker load

    private static let imageUTTypes: [UTType] = [
        .data, .image, .png, .jpeg, .tiff, .gif, .heic, .heif, .bmp, .fileURL, .url
    ]
    private static let imageTypeIdentifiers: [String] = CardSheetView.imageUTTypes.map { $0.identifier }

    private static let pasteImageTypes: [UTType] = CardSheetView.imageUTTypes

    private static let textDropTypes: [UTType] = [
        .plainText, .text, .url
    ]

    // MARK: - Body split to reduce complexity

    var body: some View {
        // Break the large modifier chain into smaller groups and add type-erasure
        let step1 = applyNavigationAndToolbar(to: mainScaffold).eraseToAnyView()
        let step2 = applyImageLoadingTasks(to: step1).eraseToAnyView()
        let step3 = applyLifecycleHandlers(to: step2).eraseToAnyView()
        let step4 = applyFocusPresentation(to: step3).eraseToAnyView()
        let step5 = applyQuickAttributionSheet(to: step4).eraseToAnyView()
        let step6 = applyImporters(to: step5)
        return step6
    }

    // Extracted main scaffold from body to shorten the primary expression
    @ViewBuilder
    private var mainScaffold: some View {
        ZStack {
            // Canvas background
            #if !os(visionOS)
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            #endif

            // Make the detail pane a fixed-size canvas that fills the detail column.
            VStack(alignment: .leading, spacing: 16) {
                // Mode selector
                modePicker

                // Header: Title/subtitle on the left, image on the right (drop target).
                header

                // Rich text / plain rendering of detailedText or inline editor
                Divider()

                // Editor/Preview area fills remaining space; inner editors scroll themselves.
                editorArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    // MARK: - Grouped modifier helpers

    @ViewBuilder
    private func applyNavigationAndToolbar<V: View>(to base: V) -> some View {
        base
            .navigationTitle(card.name)
            #if os(iOS)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            #elseif os(macOS)
            .toolbarBackground(.visible, for: .windowToolbar)
            .toolbarBackground(.ultraThinMaterial, for: .windowToolbar)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        toggleFocusForThisCard()
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
                        Button {
                            isPresentingPhotosPicker = true
                        } label: {
                            Label("Image from Photos…", systemImage: "photo.on.rectangle")
                        }
                        Button {
                            presentImagePicker()
                        } label: {
                            Label("Image from Files…", systemImage: "folder")
                        }
                        Divider()
                        Button {
                            presentTextImporter()
                        } label: {
                            Label("Text from Files…", systemImage: "doc.text")
                        }
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    .help("Import content into this card")
                }
                #endif
            }
    }

    @ViewBuilder
    private func applyImageLoadingTasks<V: View>(to base: V) -> some View {
        base
            .task {
                await loadFullImage()
            }
            .task(id: card.id) {
                await loadFullImage()
            }
            .task(id: card.imageFileURL) {
                await loadFullImage()
            }
    }

    @ViewBuilder
    private func applyLifecycleHandlers<V: View>(to base: V) -> some View {
        applyOnChangeHandlers(to: base)
    }

    @ViewBuilder
    private func applyOnChangeHandlers<V: View>(to base: V) -> some View {
        base
            .onChange(of: card.id) { _, _ in
                // Reset local editor state to reflect the newly selected card
                autosaveTask?.cancel()
                isEditingName = false
                isEditingSubtitle = false
                focusedField = nil

                nameDraft = card.name
                subtitleDraft = card.subtitle
                detailsDraft = card.detailedText
                detailsSelection = NSRange(location: 0, length: 0)

                // Default to Preview for a newly selected card
                editorMode = .preview

                // Hide attribution by default for new selection
                isAttributionVisible = false

                // If focus mode was active for another card, disable it for this card.
                if isFocusModeEnabled, focusModeCardIDRaw != card.id.uuidString {
                    UserDefaults.standard.set(false, forKey: "CardDetailFocusModeEnabled")
                    UserDefaults.standard.set("", forKey: "CardDetailFocusModeCardID")
                }
            }
            .onChange(of: card.detailedText) { _, _ in
                // Keep the draft in sync when model changes externally
                if !isDetailsEditable {
                    detailsDraft = card.detailedText
                }
            }
            .onChange(of: editorMode) { old, new in
                // When leaving an editable mode, save if dirty
                if (old == .edit || old == .split), !(new == .edit || new == .split) {
                    saveDetailsIfDirty(actionName: "Edit Details")
                }
                // Ensure the editor is primed with current text when entering an editable mode
                if (new == .edit || new == .split) {
                    detailsDraft = card.detailedText
                    detailsSelection = NSRange(location: (detailsDraft as NSString).length, length: 0)
                    focusedField = .details
                }
                // Clear drop targeting when mode changes to non-editable
                if !(new != .preview) {
                    isDropTargeted = false
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .inactive || newPhase == .background {
                    Task { @MainActor in
                        saveDetailsIfDirty(actionName: "Autosave Details")
                    }
                }
            }
            .onChange(of: detailsDraft) { _, _ in
                guard isDetailsEditable else { return }
                scheduleAutosave()
            }
            .onAppear {
                // Initialize drafts on first appear
                nameDraft = card.name
                subtitleDraft = card.subtitle
                detailsDraft = card.detailedText
                // Hide attribution by default on appear
                isAttributionVisible = false

                // If focus mode was on for this card, present overlay now (without re-toggling AppStorage)
                if isFocusModeEnabled, focusModeCardIDRaw == card.id.uuidString {
                    prepareEditorForFocus()
                    #if os(macOS)
                    FocusOverlayPresenter.shared.present(
                        for: card,
                        text: $detailsDraft,
                        selection: $detailsSelection,
                        toolbar: adaptiveFormattingToolbar,
                        onExit: {
                            UserDefaults.standard.set(false, forKey: "CardDetailFocusModeEnabled")
                            UserDefaults.standard.set("", forKey: "CardDetailFocusModeCardID")
                        }
                    )
                    #endif
                }
            }
            #if os(macOS)
            .onExitCommand {
                if isFocusModeEnabled {
                    UserDefaults.standard.set(false, forKey: "CardDetailFocusModeEnabled")
                    UserDefaults.standard.set("", forKey: "CardDetailFocusModeCardID")
                }
            }
            #endif
            .onChange(of: isFocusModeEnabled) { _, on in
                #if os(macOS)
                if on {
                    guard focusModeCardIDRaw == card.id.uuidString else { return }
                    prepareEditorForFocus()
                    FocusOverlayPresenter.shared.present(
                        for: card,
                        text: $detailsDraft,
                        selection: $detailsSelection,
                        toolbar: adaptiveFormattingToolbar,
                        onExit: {
                            UserDefaults.standard.set(false, forKey: "CardDetailFocusModeEnabled")
                            UserDefaults.standard.set("", forKey: "CardDetailFocusModeCardID")
                        }
                    )
                } else {
                    exitFocusMode(save: true)
                }
                #endif
            }
    }

    @ViewBuilder
    private func applyFocusPresentation<V: View>(to base: V) -> some View {
        #if os(iOS)
        base
            .fullScreenCover(isPresented: focusCoverBinding) {
                FocusFullScreen(
                    isPresented: focusCoverBinding,
                    title: card.name,
                    detailsText: $detailsDraft,
                    selection: $detailsSelection,
                    toolbar: adaptiveFormattingToolbar,
                    onExit: {
                        // These assignments are fine - they're modifying @AppStorage through their projectedValue
                        UserDefaults.standard.set(false, forKey: "CardDetailFocusModeEnabled")
                        UserDefaults.standard.set("", forKey: "CardDetailFocusModeCardID")
                    }
                )
            }
            .onChange(of: isFocusModeEnabled && focusModeCardIDRaw == card.id.uuidString) { _, isActive in
                if isActive {
                    // Prepare editor state when focus mode activates
                    prepareEditorForFocus()
                }
            }
        #else
        base
        #endif
    }

    @ViewBuilder
    private func applyQuickAttributionSheet<V: View>(to base: V) -> some View {
        base
            .sheet(item: $pendingAttribution) { ctx in
                QuickAttributionSheet(card: card,
                                      kind: ctx.kind,
                                      suggestedURL: ctx.suggestedURL,
                                      prefilledExcerpt: ctx.prefilledExcerpt,
                                      onSave: { _ in
                                          isAttributionVisible = true
                                      },
                                      onSkip: {
                                          // Keep content; no attribution
                                      })
                .frame(minWidth: 420, minHeight: 360)
            }
            // Full-size image viewer
            #if os(macOS)
            .sheet(isPresented: $showFullSizeImage) {
                FullSizeImageViewer(card: card, pendingImageData: nil)
                    .id(card.originalImageData?.count ?? 0)
            }
            #else
            .fullScreenCover(isPresented: $showFullSizeImage) {
                FullSizeImageViewer(card: card, pendingImageData: nil)
                    .id(card.originalImageData?.count ?? 0)
            }
            #endif
            // Present AI Image Info panel (ER-0009)
            .sheet(isPresented: $showAIImageInfo) {
                AIImageInfoView(card: card)
            }
    }

    @ViewBuilder
    private func applyImporters<V: View>(to base: V) -> some View {
        base
            .fileImporter(isPresented: $isImportingImage, allowedContentTypes: [.image], allowsMultipleSelection: false) { result in
                if case .success(let urls) = result, let url = urls.first, let data = try? Data(contentsOf: url) {
                    Task { @MainActor in
                        let ok = self.handleDroppedImageData(data)
                        if ok {
                            self.pendingAttribution = PendingAttribution(suggestedURL: nil, isWeb: false, kind: .image, prefilledExcerpt: nil)
                        }
                    }
                }
            }
            .fileImporter(isPresented: $isImportingText, allowedContentTypes: [.plainText, .text], allowsMultipleSelection: false) { result in
                guard case .success(let urls) = result, let url = urls.first else { return }
                Task { @MainActor in
                    if let data = try? Data(contentsOf: url),
                       let s = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) {
                        insertTextAtSelection(s)
                        let excerpt = String(s.prefix(280))
                        self.pendingAttribution = PendingAttribution(suggestedURL: url.isFileURL ? nil : url,
                                                                     isWeb: url.scheme?.hasPrefix("http") == true,
                                                                     kind: .quote,
                                                                     prefilledExcerpt: excerpt)
                    }
                }
            }
            #if os(iOS)
            .photosPicker(isPresented: $isPresentingPhotosPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let item = newItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            let ok = self.handleDroppedImageData(data)
                            if ok {
                                self.pendingAttribution = PendingAttribution(suggestedURL: nil, isWeb: false, kind: .image, prefilledExcerpt: nil)
                            }
                        }
                    } else if let uiImage = try? await item.loadTransferable(type: UIImage.self),
                              let data = uiImage.pngData() ?? uiImage.jpegData(compressionQuality: 0.9) {
                        await MainActor.run {
                            let ok = self.handleDroppedImageData(data)
                            if ok {
                                self.pendingAttribution = PendingAttribution(suggestedURL: nil, isWeb: false, kind: .image, prefilledExcerpt: nil)
                            }
                        }
                    }
                    await MainActor.run {
                        selectedPhotoItem = nil
                    }
                }
            }
            #endif
    }

    // MARK: - Focus Mode UI

    // New floating, round, translucent focus button
    @ViewBuilder
    private var focusGlassButton: some View {
        let isActive = isFocusModeEnabled && focusModeCardIDRaw == card.id.uuidString
        let icon = isActive ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"

        Button {
            toggleFocusForThisCard()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 30, height: 30) // macOS/iPadOS size; iOS hit target still >=44 via padding if needed
        }
        .buttonStyle(.plain)
        .background(
            Circle().fill(.ultraThinMaterial)
        )
        .overlay(
            Circle()
                .stroke(.white.opacity(scheme == .dark ? 0.15 : 0.30), lineWidth: 0.6)
                .blendMode(.overlay)
        )
        .overlay(
            Circle()
                .stroke(.separator.opacity(0.6), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.22 : 0.12), radius: 6, x: 0, y: 3)
        .accessibilityLabel(isActive ? "Exit Focus" : "Enter Focus")
        .help(isActive ? "Exit Focus" : "Enter Focus")
        #if os(macOS)
        .opacity(isActive ? 1.0 : (isHoveringFocusButton ? 1.0 : 0.0))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHoveringFocusButton = hovering
            }
        }
        #endif
    }

    private func toggleFocusForThisCard() {
        if isFocusModeEnabled && focusModeCardIDRaw == card.id.uuidString {
            // Turn off
            UserDefaults.standard.set(false, forKey: "CardDetailFocusModeEnabled")
            UserDefaults.standard.set("", forKey: "CardDetailFocusModeCardID")
        } else {
            // Turn on for this card
            UserDefaults.standard.set(card.id.uuidString, forKey: "CardDetailFocusModeCardID")
            UserDefaults.standard.set(true, forKey: "CardDetailFocusModeEnabled")
        }
    }

    // Inline overlay fallback (iOS, etc.) — now unused on iOS; kept for reference/other platforms
    @ViewBuilder
    private var focusInlineOverlay: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 8) {
                // Top bar with Exit
                HStack {
                    Button {
                        // Toggle off; overlay disappears
                        UserDefaults.standard.set(false, forKey: "CardDetailFocusModeEnabled")
                        UserDefaults.standard.set("", forKey: "CardDetailFocusModeCardID")
                    } label: {
                        Label("Exit Focus", systemImage: "xmark.circle.fill")
                    }
                    .keyboardShortcut(.cancelAction)
                    Spacer()
                }
                .padding(.bottom, 4)

                adaptiveFormattingToolbar
                    .glassToolbarStyle()

                RichTextEditor(
                    text: $detailsDraft,
                    selectedRange: $detailsSelection,
                    isFirstResponder: true,
                    editable: true,
                    onTab: { handleIndentOutdent(isOutdent: false) },
                    onBacktab: { handleIndentOutdent(isOutdent: true) }
                )
                .frame(minHeight: 280)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.regularMaterial)
                        .allowsHitTesting(false)
                )
            }
            .padding()
        }
    }

    // Prepare editor state when entering focus (without touching AppStorage)
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
    private func exitFocusMode(save: Bool) {
        if save {
            saveDetailsIfDirty(actionName: "Edit Details")
        }
        #if os(macOS)
        FocusOverlayPresenter.shared.dismiss()
        #endif
    }

    #if os(iOS)
    // Binding driving the iOS full-screen focus cover
    private var focusCoverBinding: Binding<Bool> {
        Binding<Bool>(
            get: {
                isFocusModeEnabled && focusModeCardIDRaw == card.id.uuidString
            },
            set: { newValue in
                if newValue {
                    // Engage focus for this card
                    UserDefaults.standard.set(card.id.uuidString, forKey: "CardDetailFocusModeCardID")
                    UserDefaults.standard.set(true, forKey: "CardDetailFocusModeEnabled")
                } else {
                    // Dismiss focus
                    UserDefaults.standard.set(false, forKey: "CardDetailFocusModeEnabled")
                    UserDefaults.standard.set("", forKey: "CardDetailFocusModeCardID")
                }
            }
        )
    }
    #endif

    // MARK: - UI Sections

    private var modePicker: some View {
        Picker("Mode", selection: $editorMode) {
            ForEach(EditorMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Editor Mode")
    }

    // Split the large header into smaller pieces to help the type checker.
    private var header: some View {
        // Native material-backed header card (no custom container)
        let corner: CGFloat = 10
        return HStack(alignment: .top, spacing: 16) {
            headerLeftColumn
            Spacer(minLength: 12)
            headerImageSection
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(.thinMaterial)
                .allowsHitTesting(false)
        )
        .overlay(
            ZStack {
                // Base border
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(.separator.opacity(0.6), lineWidth: 0.5)
                    .allowsHitTesting(false)
                // Highlight border when a drag is hovering anywhere over the header AND editable
                if isDropTargeted && canAcceptImageDrop {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(Color.accentColor, lineWidth: 2)
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
                }
            }
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.22 : 0.08), radius: 6, x: 0, y: 3)
        // Make the whole header a drop/paste target for images, but only target when editable
        .contentShape(Rectangle())
        .onDrop(
            of: CardSheetView.imageTypeIdentifiers,
            isTargeted: Binding(
                get: { self.canAcceptImageDrop && self.isDropTargeted },
                set: { newValue in self.isDropTargeted = newValue }
            )
        ) { providers in
            // Reject drop while not editable
            guard canAcceptImageDrop else { return false }
            handleDrop(providers: providers)
            return true
        }
        #if os(macOS)
        .onPasteCommand(of: CardSheetView.pasteImageTypes) { providers in
            guard canAcceptImageDrop else { return }
            handleDrop(providers: providers)
        }
        #else
        .onPasteIfAvailable(of: CardSheetView.pasteImageTypes) { providers in
            guard canAcceptImageDrop else { return false }
            handleDrop(providers: providers)
            return true
        }
        #endif
    }

    // Left column of the header (kind badge, name/subtitle editing).
    @ViewBuilder
    private var headerLeftColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.kind.title)
                .font(.title2).bold()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.thinMaterial)
                        .allowsHitTesting(false)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.separator.opacity(0.6), lineWidth: 0.5)
                        .allowsHitTesting(false)
                )

            // Name: edit in place
            Group {
                if isEditingName {
                    TextField("Name", text: $nameDraft, onCommit: commitName)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.regularMaterial)
                                .allowsHitTesting(false)
                        )
                        .focused($focusedField, equals: .name)
                        .onChange(of: focusedField) { _, newFocus in
                            if newFocus != .name {
                                commitName()
                            }
                        }
                } else {
                    Text(card.name)
                        .font(.title3)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.regularMaterial)
                                .allowsHitTesting(false)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            nameDraft = card.name
                            isEditingName = true
                            focusedField = .name
                        }
                }
            }

            // Subtitle: edit in place
            Group {
                if isEditingSubtitle {
                    TextField("Subtitle (optional)", text: $subtitleDraft, onCommit: commitSubtitle)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.regularMaterial)
                                .allowsHitTesting(false)
                        )
                        .focused($focusedField, equals: .subtitle)
                        .onChange(of: focusedField) { _, newFocus in
                            if newFocus != .subtitle {
                                commitSubtitle()
                            }
                        }
                } else {
                    if !card.subtitle.isEmpty {
                        Text(card.subtitle)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.regularMaterial)
                                    .allowsHitTesting(false)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                subtitleDraft = card.subtitle
                                isEditingSubtitle = true
                                focusedField = .subtitle
                            }
                    } else {
                        Text("Add subtitle")
                            .foregroundStyle(.secondary)
                            .italic()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.regularMaterial)
                                    .allowsHitTesting(false)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                subtitleDraft = ""
                                isEditingSubtitle = true
                                focusedField = .subtitle
                            }
                    }
                }
            }
        }
    }

    // Right-side image section (image display + attribution + importer).
    @ViewBuilder
    private var headerImageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let fullImage {
                    fullImage
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel("Full Image")
                        .accessibilityHint(hasFullSizeImage ? "Double-tap to view full size" : "")
                        .frame(maxHeight: 240)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.regularMaterial)
                                .allowsHitTesting(false)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.quaternary, lineWidth: 0.8)
                                .allowsHitTesting(false)
                        )
                        .overlay(alignment: .topTrailing) {
                            // AI attribution badge (ER-0009)
                            if card.imageGeneratedByAI == true {
                                aiAttributionBadge
                            }
                        }
                        .contentShape(Rectangle())
                        // IMPORTANT: Double-tap must come BEFORE single-tap
                        .onTapGesture(count: 2) {
                            if hasFullSizeImage {
                                showFullSizeImage = true
                            }
                        }
                        // Single tap to toggle attribution (only fires if double-tap doesn't)
                        .onTapGesture(count: 1) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isAttributionVisible.toggle()
                            }
                        }
                        #if os(macOS)
                        .onHover { hovering in
                            if hovering && hasFullSizeImage {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        #else
                        // Long press for iOS/iPadOS
                        .onLongPressGesture(minimumDuration: 0.5) {
                            if hasFullSizeImage {
                                showFullSizeImage = true
                            }
                        }
                        #endif
                        .contextMenu {
                            #if os(iOS)
                            Button("Replace from Photos…") { isPresentingPhotosPicker = true }
                            #endif
                            Button("Replace Image…") { presentImagePicker() }
                            
                            // Add full-size view option if image is available
                            if hasFullSizeImage {
                                Divider()
                                Button {
                                    showFullSizeImage = true
                                } label: {
                                    Label("View Full Size", systemImage: "arrow.up.left.and.arrow.down.right")
                                }
                                #if os(macOS)
                                .keyboardShortcut(.space)
                                #endif
                            }
                            
                            Divider()
                            Button("Remove Image", role: .destructive) { removeImage() }
                        }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text("Drop image here")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                            .allowsHitTesting(false)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.quaternary, lineWidth: 0.8)
                            .allowsHitTesting(false)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isAttributionVisible.toggle()
                        }
                    }
                    .contextMenu {
                        #if os(iOS)
                        Button("Choose from Photos…") { isPresentingPhotosPicker = true }
                        #endif
                        Button("Choose Image…") { presentImagePicker() }
                    }
                }
            }

            // Image attribution (compact) — hidden by default, toggled by tapping the image/placeholder above
            if isAttributionVisible {
                ImageAttributionViewer(card: card)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.thinMaterial)
                            .allowsHitTesting(false)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.separator.opacity(0.6), lineWidth: 0.5)
                            .allowsHitTesting(false)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(width: 160)
        .contentShape(Rectangle())
        // Give it a concrete hit-test surface
        .background(Color.black.opacity(0.001))
    }

    private var hasFullSizeImage: Bool {
        card.imageFileURL != nil || card.originalImageData != nil
    }

    private func presentImagePicker() {
        isImportingImage = true
    }

    private func presentTextImporter() {
        isImportingText = true
    }

    // The host (ContentView) can add a .fileImporter wrapper if desired; here we keep context menus.

    @ViewBuilder
    private var editorArea: some View {
        switch editorMode {
        case .edit:
            editorStack
        case .preview:
            previewStack
        case .split:
            #if os(macOS)
            HStack(spacing: 16) {
                editorStack
                previewStack
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            #else
            VStack(alignment: .leading, spacing: 16) {
                editorStack
                previewStack
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            #endif
        }
    }

    private var editorStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Adaptive single-line toolbar with overflow
            adaptiveFormattingToolbar
                .disabled(!isDetailsEditable)
                .glassToolbarStyle()

            RichTextEditor(
                text: $detailsDraft,
                selectedRange: $detailsSelection,
                isFirstResponder: focusedField == .details,
                editable: isDetailsEditable,
                onTab: { handleIndentOutdent(isOutdent: false) },
                onBacktab: { handleIndentOutdent(isOutdent: true) }
            )
            // Let the editor fill remaining height and scroll internally
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
                    .allowsHitTesting(false)
            )
            // Accept dropped plain text and URLs (for suggested source)
            .onDrop(of: CardSheetView.textDropTypes, isTargeted: nil) { providers in
                handleTextDrop(providers: providers)
            }
        }
        .onAppear {
            detailsDraft = card.detailedText
        }
        .onChange(of: focusedField) { _, newFocus in
            // When focus leaves the editor, save if dirty
            if newFocus != .details {
                saveDetailsIfDirty(actionName: "Edit Details")
            } else {
                // When focusing into details, ensure selection is sane
                if detailsSelection.length == 0 && detailsSelection.location == 0 {
                    detailsSelection = NSRange(location: (detailsDraft as NSString).length, length: 0)
                }
            }
        }
    }

    private var previewStack: some View {
        Group {
            if !detailsDraft.isEmpty {
                RichTextEditor(
                    text: $detailsDraft,
                    selectedRange: $detailsSelection,
                    isFirstResponder: false,
                    editable: false
                )
                // Fill and let the inner editor scroll
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.regularMaterial)
                        .allowsHitTesting(false)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    // Tap-to-edit from preview
                    detailsDraft = card.detailedText
                    editorMode = .edit
                    focusedField = .details
                }
            } else {
                Text("No details yet.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                            .allowsHitTesting(false)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Tap-to-edit from empty preview
                        detailsDraft = card.detailedText
                        editorMode = .edit
                        focusedField = .details
                    }
            }
        }
    }

    // MARK: - Adaptive toolbar

    // Define the toolbar items in order, interleaving dividers
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

    // MARK: - Inline edit commits

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
            registerUndo(actionName: "Edit Name") {
                self.card.name = old
            }
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
            registerUndo(actionName: "Edit Subtitle") {
                self.card.subtitle = old
            }
            card.subtitle = subtitleDraft
            try? modelContext.save()
        }
        isEditingSubtitle = false
        focusedField = nil
    }

    // MARK: - Details save helpers

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

    // MARK: - Formatting operations

    private func toggleWrap(delimiter: String) {
        let ns = detailsDraft as NSString
        var range = detailsSelection
        range.location = max(0, min(range.location, ns.length))
        range.length = max(0, min(range.length, ns.length - range.location))

        // If no selection, insert paired delimiters and place cursor between
        if range.length == 0 {
            let insertion = delimiter + delimiter
            let start = range.location
            let newText = ns.replacingCharacters(in: NSRange(location: start, length: 0), with: insertion)
            detailsDraft = newText
            detailsSelection = NSRange(location: start + delimiter.count, length: 0)
            return
        }

        // Check if selection is already wrapped by delimiter on both sides
        let beforeLoc = range.location - delimiter.count
        let afterLoc = range.location + range.length
        let canCheckBefore = beforeLoc >= 0
        let canCheckAfter = (afterLoc + delimiter.count) <= ns.length

        let before = canCheckBefore ? ns.substring(with: NSRange(location: beforeLoc, length: delimiter.count)) : ""
        let after = canCheckAfter ? ns.substring(with: NSRange(location: afterLoc, length: delimiter.count)) : ""

        if before == delimiter && after == delimiter {
            // Unwrap
            var newText = ns.replacingCharacters(in: NSRange(location: afterLoc, length: delimiter.count), with: "")
            let newNS = newText as NSString
            newText = newNS.replacingCharacters(in: NSRange(location: beforeLoc, length: delimiter.count), with: "")
            detailsDraft = newText
            detailsSelection = NSRange(location: range.location - delimiter.count, length: range.length)
        } else {
            // Wrap
            var newText = ns.replacingCharacters(in: NSRange(location: afterLoc, length: 0), with: delimiter)
            let newNS = newText as NSString
            newText = newNS.replacingCharacters(in: NSRange(location: range.location, length: 0), with: delimiter)
            detailsDraft = newText
            detailsSelection = NSRange(location: range.location + delimiter.count, length: range.length)
        }
    }

    private func toggleItalic() { toggleWrap(delimiter: "*") }
    private func toggleBold() { toggleWrap(delimiter: "**") }
    private func toggleInlineCode() { toggleWrap(delimiter: "`") }

    private func lineRangesCoveringSelection(in ns: NSString, selection: NSRange) -> [NSRange] {
        var lines: [NSRange] = []
        let selEnd = selection.location + selection.length
        var cursor = selection.location

        let firstLine = ns.lineRange(for: NSRange(location: max(0, selection.location - 1), length: 0))
        lines.append(firstLine)
        cursor = firstLine.location + firstLine.length

        while cursor < selEnd {
            let r = ns.lineRange(for: NSRange(location: cursor, length: 0))
            lines.append(r)
            cursor = r.location + r.length
        }
        return lines
    }

    private func replaceRanges(_ ranges: [NSRange], in ns: NSString, with transform: (String, Int) -> String) -> (String, NSRange) {
        var newText = ns as String
        var deltaTotal = 0

        for (idx, range) in ranges.enumerated() {
            let adjusted = NSRange(location: range.location + deltaTotal, length: range.length)
            let line = (newText as NSString).substring(with: adjusted)
            let replaced = transform(line, idx)
            newText = (newText as NSString).replacingCharacters(in: adjusted, with: replaced)
            deltaTotal += (replaced as NSString).length - adjusted.length
        }

        let first = ranges.first!
        let last = ranges.last!
        let newSelStart = first.location
        let newSelEnd = last.location + last.length + deltaTotal
        let newSel = NSRange(location: newSelStart, length: max(0, newSelEnd - newSelStart))
        return (newText, newSel)
    }

    private func lineHasAnyBulletPrefix(_ s: String) -> (has: Bool, markerLen: Int) {
        if s.hasPrefix("- ") { return (true, 2) }
        if s.hasPrefix("* ") { return (true, 2) }
        if s.hasPrefix("+ ") { return (true, 2) }
        return (false, 0)
    }

    private func lineHasChecklistPrefix(_ s: String) -> (has: Bool, markerLen: Int, done: Bool) {
        if s.hasPrefix("- [ ] ") { return (true, 6, false) }
        if s.hasPrefix("- [x] ") { return (true, 6, true) }
        if s.hasPrefix("* [ ] ") { return (true, 6, false) }
        if s.hasPrefix("* [x] ") { return (true, 6, true) }
        return (false, 0, false)
    }

    private func toggleBulletList() {
        let ns = detailsDraft as NSString
        let sel = detailsSelection
        let lines = lineRangesCoveringSelection(in: ns, selection: sel)
        guard !lines.isEmpty else { return }

        let allHave = lines.allSatisfy { r in
            let s = ns.substring(with: r)
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty { return true }
            return lineHasAnyBulletPrefix(s).has || lineHasChecklistPrefix(s).has
        }

        let (text, newSel) = replaceRanges(lines, in: ns) { line, _ in
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return line }
            if lineHasChecklistPrefix(line).has {
                // Convert checklist to plain bullet if allHave and requested removal
                if allHave { return line.replacingOccurrences(of: "- [ ] ", with: "").replacingOccurrences(of: "- [x] ", with: "").replacingOccurrences(of: "* [ ] ", with: "").replacingOccurrences(of: "* [x] ", with: "") }
            }
            let bullet = lineHasAnyBulletPrefix(line)
            if allHave, bullet.has {
                return String(line.dropFirst(bullet.markerLen))
            } else if !allHave {
                return "- " + line
            } else {
                return line
            }
        }
        detailsDraft = text
        detailsSelection = newSel
    }

    private func toggleNumberedList() {
        let ns = detailsDraft as NSString
        let sel = detailsSelection
        let lines = lineRangesCoveringSelection(in: ns, selection: sel)
        guard !lines.isEmpty else { return }

        let numberRegex = try! NSRegularExpression(pattern: #"^\s*\d+\.\s"#, options: [])
        let allNumbered = lines.allSatisfy { r in
            let s = ns.substring(with: r)
            let range = NSRange(location: 0, length: (s as NSString).length)
            return numberRegex.firstMatch(in: s, options: [], range: range) != nil || s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var counter = 1
        let (text, newSel) = replaceRanges(lines, in: ns) { line, _ in
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return line }
            if allNumbered {
                if let match = numberRegex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: (line as NSString).length)) {
                    let replaced = (line as NSString).replacingCharacters(in: match.range, with: "")
                    return replaced
                }
                return line
            } else {
                defer { counter += 1 }
                return "\(counter). " + line
            }
        }
        detailsDraft = text
        detailsSelection = newSel
    }

    private func toggleQuote() {
        let ns = detailsDraft as NSString
        let sel = detailsSelection
        let lines = lineRangesCoveringSelection(in: ns, selection: sel)
        guard !lines.isEmpty else { return }

        let allQuoted = lines.allSatisfy { r in
            let s = ns.substring(with: r)
            return s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || s.hasPrefix("> ")
        }

        let (text, newSel) = replaceRanges(lines, in: ns) { line, _ in
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return line }
            if allQuoted, line.hasPrefix("> ") {
                return String(line.dropFirst(2))
            } else if !allQuoted {
                return "> " + line
            } else {
                return line
            }
        }
        detailsDraft = text
        detailsSelection = newSel
    }

    private func applyHeading(level: Int) {
        let lvl = max(1, min(6, level))
        let prefix = String(repeating: "#", count: lvl) + " "

        let ns = detailsDraft as NSString
        let sel = detailsSelection
        let lines = lineRangesCoveringSelection(in: ns, selection: sel)
        guard !lines.isEmpty else { return }

        let headingRegex = try! NSRegularExpression(pattern: #"^\s*#{1,6}\s"#, options: [])
        let (text, newSel) = replaceRanges(lines, in: ns) { line, _ in
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return line }
            let range = NSRange(location: 0, length: (line as NSString).length)
            if let match = headingRegex.firstMatch(in: line, options: [], range: range) {
                let currentPrefix = (line as NSString).substring(with: match.range)
                let currentCount = currentPrefix.filter { $0 == "#" }.count
                if currentCount == lvl {
                    return (line as NSString).replacingCharacters(in: match.range, with: "")
                } else {
                    return (line as NSString).replacingCharacters(in: match.range, with: prefix)
                }
            } else {
                return prefix + line
            }
        }
        detailsDraft = text
        detailsSelection = newSel
    }

    private func handleIndentOutdent(isOutdent: Bool) {
        let ns = detailsDraft as NSString
        let sel = detailsSelection
        let lines = lineRangesCoveringSelection(in: ns, selection: sel)
        guard !lines.isEmpty else { return }

        let (text, newSel) = replaceRanges(lines, in: ns) { line, _ in
            if isOutdent {
                if line.hasPrefix("    ") { return String(line.dropFirst(4)) }
                else if line.hasPrefix("\t") { return String(line.dropFirst(1)) }
                else if line.hasPrefix(" ") { return String(line.dropFirst(1)) }
                else { return line }
            } else {
                return "    " + line
            }
        }
        detailsDraft = text
        detailsSelection = newSel
    }

    private func ensureTrailingNewline() {
        if detailsDraft.last != "\n" && !detailsDraft.isEmpty {
            detailsDraft.append("\n")
        }
    }

    private func insertCodeBlock() {
        ensureTrailingNewline()
        detailsDraft.append("```\ncode\n```\n")
    }

    // Add checklist toggles

    private func toggleChecklist() {
        let ns = detailsDraft as NSString
        let sel = detailsSelection
        let lines = lineRangesCoveringSelection(in: ns, selection: sel)
        guard !lines.isEmpty else { return }

        // Determine if all selected lines are already checklist items (or empty)
        let allChecklist = lines.allSatisfy { r in
            let s = ns.substring(with: r)
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty { return true }
            return lineHasChecklistPrefix(s).has
        }

        // Regex to strip a numbered list prefix like "1. "
        let numberRegex = try! NSRegularExpression(pattern: #"^\s*\d+\.\s"#, options: [])

        let (text, newSel) = replaceRanges(lines, in: ns) { line, _ in
            // Keep empty lines unchanged
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return line }

            let checklist = lineHasChecklistPrefix(line)
            if allChecklist {
                // Remove checklist marker
                if checklist.has {
                    return String(line.dropFirst(checklist.markerLen))
                }
                return line
            } else {
                // Add unchecked checklist marker, stripping any bullet or number prefix first
                var working = line
                let bullet = lineHasAnyBulletPrefix(working)
                if bullet.has {
                    working = String(working.dropFirst(bullet.markerLen))
                } else if let match = numberRegex.firstMatch(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length)) {
                    working = (working as NSString).replacingCharacters(in: match.range, with: "")
                } else if checklist.has {
                    // If it's already a checklist, normalize to unchecked
                    let dropped = String(working.dropFirst(checklist.markerLen))
                    return "- [ ] " + dropped
                }
                return "- [ ] " + working
            }
        }

        detailsDraft = text
        detailsSelection = newSel
    }

    private func toggleChecklistDoneUndone() {
        let ns = detailsDraft as NSString
        let sel = detailsSelection
        let lines = lineRangesCoveringSelection(in: ns, selection: sel)
        guard !lines.isEmpty else { return }

        // Determine if any selected checklist line is unchecked; if so, we'll check all.
        var anyUnchecked = false
        for r in lines {
            let s = ns.substring(with: r)
            let c = lineHasChecklistPrefix(s)
            if c.has && !c.done {
                anyUnchecked = true
                break
            }
        }

        let (text, newSel) = replaceRanges(lines, in: ns) { line, _ in
            let c = lineHasChecklistPrefix(line)
            guard c.has else { return line } // Only toggle checklist lines

            if anyUnchecked {
                // Mark all as done
                if c.done {
                    return line
                } else {
                    // Replace "[ ] " with "[x] "
                    if line.hasPrefix("- [ ] ") { return line.replacingOccurrences(of: "- [ ] ", with: "- [x] ") }
                    if line.hasPrefix("* [ ] ") { return line.replacingOccurrences(of: "* [ ] ", with: "* [x] ") }
                    return line
                }
            } else {
                // Unmark all as done
                if !c.done {
                    return line
                } else {
                    if line.hasPrefix("- [x] ") { return line.replacingOccurrences(of: "- [x] ", with: "- [ ] ") }
                    if line.hasPrefix("* [x] ") { return line.replacingOccurrences(of: "* [x] ", with: "* [ ] ") }
                    return line
                }
            }
        }

        detailsDraft = text
        detailsSelection = newSel
    }

    // MARK: - Drop + paste handling (images)

    private func handleDrop(providers: [NSItemProvider]) {
        guard !providers.isEmpty else { return }

        for provider in providers {
            #if canImport(UIKit)
            // 0) Try object-based images first (UIKit/AppKit), for robustness
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { obj, _ in
                    if let ui = obj as? UIImage {
                        let data = ui.pngData() ?? ui.jpegData(compressionQuality: 0.9)
                        if let data {
                            Task { @MainActor in
                                let ok = self.handleDroppedImageData(data)
                                if ok {
                                    // No URL context; treat as local
                                    self.pendingAttribution = PendingAttribution(suggestedURL: nil, isWeb: false, kind: .image, prefilledExcerpt: nil)
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
                        let data = nsImageToPngData(img) ?? nsImageToJpegData(img, compression: 0.9)
                        if let data {
                            Task { @MainActor in
                                let ok = self.handleDroppedImageData(data)
                                if ok {
                                    // No URL context; treat as local
                                    self.pendingAttribution = PendingAttribution(suggestedURL: nil, isWeb: false, kind: .image, prefilledExcerpt: nil)
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
                            let ok = self.handleDroppedImageData(data)
                            if ok {
                                // No URL context; treat as local
                                self.pendingAttribution = PendingAttribution(suggestedURL: nil, isWeb: false, kind: .image, prefilledExcerpt: nil)
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
                        let ok = self.handleDroppedImageData(data)
                        if ok {
                            self.pendingAttribution = PendingAttribution(suggestedURL: nil, isWeb: false, kind: .image, prefilledExcerpt: nil)
                        }
                    }
                }
            }
        }
    }

    private func tryLoadURLBasedRepresentations(provider: NSItemProvider) {
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            tryLoadFileURL(provider: provider)
        } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            tryLoadRemoteURL(provider: provider)
        }
    }

    private func tryLoadFileURL(provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            if let url = item as? URL, url.isFileURL, let data = try? Data(contentsOf: url) {
                Task { @MainActor in
                    let ok = self.handleDroppedImageData(data)
                    if ok {
                        // Local file: do not prefill URL
                        self.pendingAttribution = PendingAttribution(suggestedURL: nil, isWeb: false, kind: .image, prefilledExcerpt: nil)
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
                                let ok = self.handleDroppedImageData(data)
                                if ok {
                                    // Web: prefill URL in attribution
                                    self.pendingAttribution = PendingAttribution(suggestedURL: url, isWeb: true, kind: .image, prefilledExcerpt: nil)
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

    // MARK: - Text drop handling

    private func handleTextDrop(providers: [NSItemProvider]) -> Bool {
        guard isDetailsEditable else { return false }
        // Try to extract a URL (if present in the drag) to prefill source
        var suggestedURL: URL?
        if let urlProvider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                if let u = item as? URL, u.scheme?.hasPrefix("http") == true {
                    suggestedURL = u
                }
            }
        }

        // Extract plain text
        guard let textProvider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) || $0.hasItemConformingToTypeIdentifier(UTType.text.identifier) }) else {
            return false
        }

        var handled = false
        textProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
            let dropped: String? = (item as? String) ?? (item as? NSString).map { String($0) }
            guard let s = dropped, !s.isEmpty else { return }
            Task { @MainActor in
                insertTextAtSelection(s)
                // Prompt for a citation (default kind: quote) and prefill excerpt with the dropped text (trim to a reasonable length)
                let excerpt = s.prefix(280)
                self.pendingAttribution = PendingAttribution(suggestedURL: suggestedURL, isWeb: suggestedURL != nil, kind: .quote, prefilledExcerpt: String(excerpt))
            }
            handled = true
        }

        return handled
    }

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

    // MARK: - Drop handling dependencies

    @MainActor
    private func handleDroppedImageData(_ data: Data) -> Bool {
        do {
            let oldURL = card.imageFileURL
            // Note: Image metadata can be extracted using ImageMetadataExtractor.extract(from: data)
            // Attribution is managed separately through the Citation system (see ImageAttributionViewer)
            try card.setOriginalImageData(data, preferredFileExtension: nil)
            registerUndo(actionName: "Replace Image") {
                if let prev = oldURL, let prevData = try? Data(contentsOf: prev) {
                    try? self.card.setOriginalImageData(prevData, preferredFileExtension: prev.pathExtension)
                } else {
                    self.card.removeOriginalImage()
                    self.card.thumbnailData = nil
                    self.card.clearImageCaches()
                }
            }
            try? modelContext.save()
            Task { await loadFullImage() }
            return true
        } catch {
            return false
        }
    }

    private func removeImage() {
        let prevURL = card.imageFileURL
        let prevThumb = card.thumbnailData
        registerUndo(actionName: "Remove Image") {
            if let u = prevURL, let data = try? Data(contentsOf: u) {
                try? self.card.setOriginalImageData(data, preferredFileExtension: u.pathExtension)
                self.card.thumbnailData = prevThumb
            }
        }
        card.removeOriginalImage()
        card.thumbnailData = nil
        card.clearImageCaches()
        try? modelContext.save()
        Task { await loadFullImage() }
    }

    // MARK: - Loaders

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

    // MARK: - AI Attribution Badge (ER-0009)

    /// AI attribution badge for AI-generated images
    private var aiAttributionBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "wand.and.stars")
                .font(.caption2)
            Text("AI")
                .font(.caption2.bold())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.purple.gradient)
        )
        .shadow(radius: 2)
        .padding(6)
        .help(aiAttributionTooltip)
        .onTapGesture {
            showAIImageInfo = true
        }
    }

    /// Tooltip text for AI attribution
    private var aiAttributionTooltip: String {
        var parts: [String] = ["AI Generated"]

        if let provider = card.imageAIProvider {
            parts.append("Provider: \(provider)")
        }

        if let date = card.imageAIGeneratedAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            parts.append("Generated: \(formatter.string(from: date))")
        }

        if let prompt = card.imageAIPrompt, !prompt.isEmpty {
            parts.append("Tap for details")
        }

        return parts.joined(separator: "\n")
    }

    // MARK: - Undo helper

    private func registerUndo(actionName: String, _ undoBlock: @escaping () -> Void) {
        undoManager?.registerUndo(withTarget: VoidBox(action: undoBlock)) { box in
            box.action()
        }
        undoManager?.setActionName(actionName)
    }

    private final class VoidBox {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
    }
}

// MARK: - AdaptiveToolbar

private struct AdaptiveToolbar: View {
    struct Item: Identifiable, Hashable {
        // Keyboard shortcut wrapper to avoid tuple in associated values
        struct Shortcut: Hashable {
            let key: String
            let modifiers: EventModifiers
            init(key: String, modifiers: EventModifiers) {
                self.key = key
                self.modifiers = modifiers
            }
            static func == (lhs: Shortcut, rhs: Shortcut) -> Bool {
                lhs.key == rhs.key && lhs.modifiers == rhs.modifiers
            }
            func hash(into hasher: inout Hasher) {
                hasher.combine(key)
                hasher.combine(modifiers.rawValue)
            }
        }

        enum Kind: Hashable {
            case button(id: String, systemImage: String, title: String?, shortcut: Shortcut?)
            case divider
        }
        // Stable identity stored (not computed) so dividers don't change identity every access
        let id: String
        let kind: Kind
        // Action is not Hashable/Equatable; we'll ignore it in conformance
        let action: (() -> Void)?

        static func button(id: String, systemImage: String, title: String? = nil, shortcut: Shortcut?, action: @escaping () -> Void) -> Item {
            Item(id: id, kind: .button(id: id, systemImage: systemImage, title: title, shortcut: shortcut), action: action)
        }
        static var divider: Item { Item(id: UUID().uuidString, kind: .divider, action: nil) }

        static func == (lhs: Item, rhs: Item) -> Bool {
            lhs.id == rhs.id && lhs.kind == rhs.kind
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(kind)
        }
    }

    let items: [Item]
    var spacing: CGFloat = 8
    var dividerHeight: CGFloat = 18

    @State private var widths: [Int: CGFloat] = [:]
    @State private var availableWidth: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let avail = proxy.size.width
            content(available: avail)
                .onAppear { availableWidth = avail }
                .onChange(of: avail) { _, new in availableWidth = new }
        }
        .frame(height: 32) // keep single line height stable
    }

    @ViewBuilder
    private func content(available: CGFloat) -> some View {
        // First, render hidden measurement row
        measurementRow
            .opacity(0)
            .accessibilityHidden(true)
            .overlay {
                // Then, visible row with overflow
                visibleRow(available: available)
            }
    }

    private var measurementRow: some View {
        HStack(spacing: spacing) {
            ForEach(items.indices, id: \.self) { idx in
                toolbarItemView(for: items[idx], index: idx, measuring: true)
            }
        }
        .background(WidthPreferenceReader())
        .onPreferenceChange(WidthPreferenceKey.self) { value in
            widths = value
        }
    }

    private func visibleRow(available: CGFloat) -> some View {
        let layout = computeLayout(available: available)
        return HStack(spacing: spacing) {
            ForEach(layout.visibleIndices, id: \.self) { idx in
                toolbarItemView(for: items[idx], index: idx, measuring: false)
            }
            if !layout.overflowIndices.isEmpty {
                Menu {
                    // Put overflow items (buttons only) into menu; skip dividers
                    ForEach(layout.overflowIndices, id: \.self) { idx in
                        switch items[idx].kind {
                        case .button(_, let systemImage, let title, _):
                            Button {
                                items[idx].action?()
                            } label: {
                                Label(title ?? "", systemImage: systemImage)
                            }
                        case .divider:
                            Divider()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.automatic)
            }
            Spacer(minLength: 0)
        }
    }

    private func toolbarItemView(for item: Item, index: Int, measuring: Bool) -> some View {
        Group {
            switch item.kind {
            case .button(_, let systemImage, _, let shortcut):
                let button = Button(action: { item.action?() }) {
                    Label("", systemImage: systemImage)
                }
                .buttonStyle(.bordered)
                .labelStyle(.iconOnly)
                .keyboardShortcutIfPresent(shortcut)

                if measuring {
                    button.overlay(SizeReporter(index: index))
                } else {
                    button
                }

            case .divider:
                let divider = Divider().frame(height: dividerHeight)
                if measuring {
                    divider.overlay(SizeReporter(index: index))
                } else {
                    divider
                }
            }
        }
    }

    private func computeLayout(available: CGFloat) -> (visibleIndices: [Int], overflowIndices: [Int]) {
        // If we don't yet know widths, show everything
        guard !widths.isEmpty else {
            return (Array(items.indices), [])
        }

        // Width of the overflow button if needed
        let overflowWidth: CGFloat = 28 // approx bordered icon button + spacing

        var used: CGFloat = 0
        var visible: [Int] = []
        var overflow: [Int] = []

        // We want to preserve separators logic: avoid starting or ending with a divider,
        // and avoid consecutive dividers if they fall at the overflow boundary.
        func canAppend(_ idx: Int, to array: [Int]) -> Bool {
            switch items[idx].kind {
            case .divider:
                // Don't start with divider
                if array.isEmpty { return false }
                // Don't double divider
                if let last = array.last, case .divider = items[last].kind { return false }
                return true
            default:
                return true
            }
        }

        let totalCount = items.count
        for idx in 0..<totalCount {
            let w = widths[idx] ?? 0
            // Determine if we need to reserve overflow button space
            let needsOverflow = (idx < totalCount - 1)
            let spaceNeeded = w + (visible.isEmpty ? 0 : spacing) + (needsOverflow ? (overflowWidth + spacing) : 0)

            if used + spaceNeeded <= available {
                if canAppend(idx, to: visible) {
                    used += (visible.isEmpty ? 0 : spacing) + w
                    visible.append(idx)
                }
            } else {
                // Remaining go to overflow, but clean up trailing divider in visible
                overflow.append(idx)
            }
        }

        // Trim trailing divider from visible
        while let last = visible.last, case .divider = items[last].kind {
            _ = visible.popLast()
        }
        // Remove leading divider in overflow
        while let first = overflow.first, case .divider = items[first].kind {
            overflow.removeFirst()
        }
        // Remove consecutive dividers in overflow
        var cleanedOverflow: [Int] = []
        for idx in overflow {
            if case .divider = items[idx].kind, let last = cleanedOverflow.last, case .divider = items[last].kind {
                continue
            }
            cleanedOverflow.append(idx)
        }

        return (visible, cleanedOverflow)
    }
}

// MARK: - Measurement helpers

private struct SizeReporter: View {
    let index: Int
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: WidthPreferenceKey.self, value: [index: geo.size.width])
        }
    }
}

private struct WidthPreferenceReader: View {
    var body: some View {
        GeometryReader { _ in
            Color.clear
        }
    }
}

private struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private extension View {
    @ViewBuilder
    func keyboardShortcutIfPresent(_ shortcut: AdaptiveToolbar.Item.Shortcut?) -> some View {
        #if os(macOS) || os(iOS)
        if let shortcut {
            self.keyboardShortcut(KeyEquivalent(Character(shortcut.key)), modifiers: shortcut.modifiers)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

// Platform-specific paste handling
private extension View {
    @ViewBuilder
    func onPasteIfAvailable(of types: [UTType], perform action: @escaping ([NSItemProvider]) -> Bool) -> some View {
        // On iOS, paste gestures are more complex and typically handled through UIKit integration
        // For now, we'll skip this on non-macOS platforms since the main paste command is already
        // handled via .onPasteCommand on macOS
        self
    }
}

// MARK: - Fallbacks for missing custom components

// If you have a custom RichTextEditor elsewhere, you can remove this fallback.
private struct RichTextEditor: View {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    let isFirstResponder: Bool
    let editable: Bool
    var onTab: (() -> Void)? = nil
    var onBacktab: (() -> Void)? = nil

    init(text: Binding<String>,
         selectedRange: Binding<NSRange>,
         isFirstResponder: Bool,
         editable: Bool,
         onTab: (() -> Void)? = nil,
         onBacktab: (() -> Void)? = nil) {
        self._text = text
        self._selectedRange = selectedRange
        self.isFirstResponder = isFirstResponder
               self.editable = editable
        self.onTab = onTab
        self.onBacktab = onBacktab
    }

    var body: some View {
        TextEditor(text: $text)
            .disabled(!editable)
    }
}

// Lightweight, native-material glass surface that never intercepts input.
private struct NativeGlassSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    let cornerRadius: CGFloat
    let tintOpacity: Double
    let tint: Color?

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .allowsHitTesting(false)
            )
            .overlay(
                Group {
                    if let tint {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(tintOpacity))
                            .blendMode(.softLight)
                            .allowsHitTesting(false)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(scheme == .dark ? 0.15 : 0.30), lineWidth: 0.6)
                    .blendMode(.overlay)
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.quaternary.opacity(0.55), lineWidth: 0.5)
                    .allowsHitTesting(false)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private extension View {
    func nativeGlassSurface(cornerRadius: CGFloat = 12, tintOpacity: Double = 0.12, tint: Color? = nil) -> some View {
        modifier(NativeGlassSurfaceModifier(cornerRadius: cornerRadius, tintOpacity: tintOpacity, tint: tint))
    }

    // No-op styling modifier if not provided elsewhere.
    func glassToolbarStyle() -> some View { self }

    // Type-erasure to help the compiler with very long chains
    func eraseToAnyView() -> AnyView { AnyView(self) }
}

#if canImport(AppKit)
// NSImage data conversion helpers (ER-0022 Phase 1: Using ImageProcessingService)
private func nsImageToPngData(_ image: NSImage) -> Data? {
    guard let tiff = image.tiffRepresentation else { return nil }
    return ImageProcessingService.shared.convertToPNG(tiff)
}

private func nsImageToJpegData(_ image: NSImage, compression: CGFloat) -> Data? {
    guard let tiff = image.tiffRepresentation else { return nil }
    return ImageProcessingService.shared.convertToJPEG(tiff, compressionQuality: compression)
}
#endif

#if os(iOS)
// Make UIImage loadable via PhotosPickerItem.loadTransferable(type:)
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

// MARK: - macOS Focus Overlay Presenter
// (unchanged below)
// ... the rest of the file remains identical ...
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
