//
//  SettingsView.swift
//  Cumberland
//
//  App-wide settings panel organised into sections (Display, Cards, Views,
//  Relations, Images, AI & Providers, Author). Each section maps to a dedicated
//  SwiftUI form. On macOS, rendered in a Settings window; on iOS, in a
//  NavigationStack sheet accessible from the sidebar.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum SettingsSection: String, CaseIterable, Identifiable {
    case display = "Display"
    case cards = "Cards"
    case views = "Views"
    case relations = "Relations"
    case images = "Images"
    case ai = "AI & Providers"
    case author = "Author"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .display:   return String(localized: "Display")
        case .cards:     return String(localized: "Cards")
        case .views:     return String(localized: "Views")
        case .relations: return String(localized: "Relations")
        case .images:    return String(localized: "Images")
        case .ai:        return String(localized: "AI & Providers")
        case .author:    return String(localized: "Author")
        }
    }

    var systemImage: String {
        switch self {
        case .display:  return "sun.max"
        case .cards:    return "rectangle.grid.2x2"
        case .views:    return "rectangle.3.offgrid"
        case .relations:return "link"
        case .images:   return "photo.on.rectangle"
        case .ai:       return "wand.and.stars"
        case .author:   return "person.text.rectangle"
        }
    }
}

// Provide SF Symbols for each SizeCategory.
// compact: compressed vertical rectangle
// standard: regular rectangle
// large: expanded vertical rectangle
extension SizeCategory {
    var systemImage: String {
        switch self {
        case .compact:  return "rectangle.compress.vertical"
        case .standard: return "rectangle"
        case .large:    return "rectangle.expand.vertical"
        }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    // Mirror color scheme preference into UserDefaults for fast app startup
    @AppStorage("AppSettings.colorSchemePreferenceRaw")
    private var colorSchemeRaw: String = ColorSchemePreference.system.rawValue

    // Allow preview injection; production path loads from SwiftData
    @State private var settings: AppSettings?

    // Selected section in the sidebar/root list
    @State private var selection: SettingsSection? = .display

    // Force both columns visible (as much as window size allows)
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    // Preview/utility initializers
    init(previewSettings: AppSettings? = nil) {
        _settings = State(initialValue: previewSettings)
    }

    init(initialSelection: SettingsSection?, previewSettings: AppSettings? = nil) {
        _selection = State(initialValue: initialSelection)
        _settings = State(initialValue: previewSettings)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            detailPane
                // Inline detail titles reduce the vertical header space on macOS.
                .toolbarTitleDisplayMode(.inline)
        }
        .navigationSplitViewStyle(.balanced)
        .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        // Remove the automatic sidebar toggle button
        .toolbar(removing: .sidebarToggle)
        .onAppear {
            // Keep both columns visible when possible
            columnVisibility = .all

            if settings == nil {
                let s = fetchOrCreateSettings()
                // One-time reconciliation: prefer existing UserDefaults value if it differs
                let currentUD = ColorSchemePreference(rawValue: colorSchemeRaw) ?? .system
                if s.colorSchemePreference != currentUD {
                    s.colorSchemePreference = currentUD
                    try? modelContext.save()
                }
                settings = s
                if selection == nil {
                    // Coerce any previously stored value to a valid section.
                    selection = SettingsSection(rawValue: s.lastSelectedSettingsSectionRaw) ?? .display
                }
            } else if selection == nil {
                selection = .display
            }
        }
        .onChange(of: selection) { _, newValue in
            guard let new = newValue, let s = settings else { return }
            s.lastSelectedSettingsSectionRaw = new.rawValue
            try? modelContext.save()
        }
        // Honor the app’s chosen display mode (nil => follow system)
        .preferredColorScheme(settings?.colorSchemePreference.resolvedColorScheme)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selection) {
            ForEach(SettingsSection.allCases) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
                    .contentShape(Rectangle())
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailPane: some View {
        if settings != nil {
            switch selection ?? .display {
            case .display:
                DisplaySettingsPane(
                    settings: settingsBinding(for: \.self),
                    onSave: saveAndSyncUserDefaults
                )
                .navigationTitle("Display")
            case .cards:
                CardSettingsPane(
                    settings: settingsBinding(for: \.self),
                    onSave: save
                )
                .navigationTitle("Cards")
            case .views:
                ViewsSettingsPane(
                    settings: settingsBinding(for: \.self),
                    onSave: save
                )
                .navigationTitle("Views")
            case .relations:
                RelationTypesManagerView()
                    .navigationTitle("Relation Types")
            case .images:
                ImagesSettingsPane()
                    .navigationTitle("Images")
            case .ai:
                AISettingsPane()
                    .navigationTitle("AI & Providers")
            case .author:
                AuthorSettingsPane(
                    settings: settingsBinding(for: \.self),
                    onSave: save
                )
                .navigationTitle("Author")
            }
        } else {
            fallbackLoadingView
                .navigationTitle("Settings")
        }
    }

    private func settingsBinding<T>(for keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { settings![keyPath: keyPath] },
            set: { newValue in
                settings![keyPath: keyPath] = newValue
                save()
            }
        )
    }

    // MARK: - Fallback UI

    private var fallbackLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView("Loading Settings…")
                .controlSize(.regular)

            Text("If this takes too long, you can initialize the defaults now.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    let s = fetchOrCreateSettings()
                    settings = s
                    selection = .display
                }
            } label: {
                Label("Initialize Now", systemImage: "gearshape")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Initialize default settings")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Loading / Saving

    @MainActor
    private func fetchOrCreateSettings() -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.singletonKey == "AppSettingsSingleton" }
        )
        if let first = (try? modelContext.fetch(descriptor))?.first {
            return first
        }
        let created = AppSettings()
        modelContext.insert(created)
        try? modelContext.save()
        return created
    }

    private func save() {
        Task { @MainActor in
            try? modelContext.save()
        }
    }

    // Save and mirror appearance to UserDefaults so the App can read it on next launch (and live)
    private func saveAndSyncUserDefaults() {
        Task { @MainActor in
            if let s = settings {
                // Write directly to UserDefaults to avoid mutation issues
                UserDefaults.standard.set(s.colorSchemePreference.rawValue, forKey: "AppSettings.colorSchemePreferenceRaw")
            }
            try? modelContext.save()
        }
    }
}

// MARK: - Detail Panes

private struct DisplaySettingsPane: View {
    @Binding var settings: AppSettings
    var onSave: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showImportPicker = false
    @State private var showExportPicker = false
    @State private var showDeleteConfirmation = false
    @State private var importError: String?
    @State private var showImportError = false
    @State private var exportData: Data?
    @State private var showShareSheet = false
    @State private var shareURL: URL?

    var body: some View {
        Form {
            Section {
                Picker("Color Scheme", selection: Binding(
                    get: { settings.colorSchemePreference },
                    set: { newValue in
                        settings.colorSchemePreference = newValue
                        onSave()
                    }
                )) {
                    ForEach(ColorSchemePreference.allCases, id: \.self) { pref in
                        Text(pref.displayName).tag(pref)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Color Scheme Preference")
                .help("Choose Light, Dark, or follow the System setting.")
            } header: {
                Text("Appearance")
            } footer: {
                Text("The app can follow System appearance or always use Light/Dark. This preference takes effect app-wide.")
            }

            // ER-0037: Theme picker
            Section {
                Picker("Theme", selection: Binding(
                    get: { themeManager.themeIdentifier },
                    set: { newValue in
                        themeManager.setTheme(newValue)
                    }
                )) {
                    ForEach(themeManager.availableThemes, id: \.id) { theme in
                        Text(theme.displayName)
                            .tag(theme.id)
                    }
                }
                .accessibilityLabel("Theme")
                .help("Choose the visual theme for the app.")

                // Live swatch preview of the current theme
                ThemeSwatchView(theme: themeManager.currentTheme)

                // Import / Export / Duplicate / Share / Delete buttons
                HStack(spacing: 12) {
                    Button {
                        showImportPicker = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    .help("Import a .cumberlandtheme file.")

                    Button {
                        exportCurrentTheme()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .help("Export the current theme as a .cumberlandtheme file.")

                    Button {
                        duplicateCurrentTheme()
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    .help("Create an editable copy of the current theme.")

                    #if os(iOS)
                    Button {
                        shareCurrentTheme()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up.on.square")
                    }
                    .help("Share the current theme via the system share sheet.")
                    #endif

                    if themeManager.isUserTheme(themeManager.themeIdentifier) {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .help("Delete this user-defined theme.")
                    }
                }
            } header: {
                Text("Theme")
            } footer: {
                Text("Choose a built-in theme or import a custom .cumberlandtheme file. Export any theme to share or customize it.")
            }
        }
        .formStyle(.grouped)
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.cumberlandTheme, .json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .fileExporter(
            isPresented: $showExportPicker,
            document: exportData.map { ThemeDocument(data: $0) },
            contentType: .cumberlandTheme,
            defaultFilename: "\(themeManager.currentTheme.id).cumberlandtheme"
        ) { _ in
            exportData = nil
        }
        .alert("Import Error", isPresented: $showImportError) {
            Button("OK") { }
        } message: {
            Text(importError ?? "An unknown error occurred while importing the theme.")
        }
        .alert("Delete Theme?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                themeManager.removeUserTheme(id: themeManager.themeIdentifier)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete the \"\(themeManager.currentTheme.displayName)\" theme. This cannot be undone.")
        }
        #if os(iOS)
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
        #endif
    }

    private func exportCurrentTheme() {
        do {
            exportData = try ThemeFileManager.shared.exportThemeData(from: themeManager.currentTheme)
            showExportPicker = true
        } catch {
            importError = error.localizedDescription
            showImportError = true
        }
    }

    private func duplicateCurrentTheme() {
        do {
            try themeManager.duplicateCurrentTheme()
        } catch {
            importError = "Could not duplicate theme: \(error.localizedDescription)"
            showImportError = true
        }
    }

    #if os(iOS)
    private func shareCurrentTheme() {
        do {
            let data = try ThemeFileManager.shared.exportThemeData(from: themeManager.currentTheme)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(themeManager.currentTheme.id).cumberlandtheme")
            try data.write(to: tempURL, options: .atomic)
            shareURL = tempURL
            showShareSheet = true
        } catch {
            importError = "Could not share theme: \(error.localizedDescription)"
            showImportError = true
        }
    }
    #endif

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let theme = try ThemeFileManager.shared.importTheme(from: url)
                themeManager.addUserTheme(theme)
                themeManager.setTheme(theme.id)
            } catch {
                importError = "Could not import theme: \(error.localizedDescription)"
                showImportError = true
            }
        case .failure(let error):
            importError = error.localizedDescription
            showImportError = true
        }
    }
}

// MARK: - ThemeDocument (for fileExporter)

/// A simple `FileDocument` wrapper for exporting theme JSON data.
struct ThemeDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.cumberlandTheme] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

/// Color swatch preview showing key theme colors.
private struct ThemeSwatchView: View {
    let theme: any Theme

    var body: some View {
        HStack(spacing: 0) {
            // Surface primary
            swatchCell(fill: theme.colors.surfacePrimary)
            // Card background
            Rectangle()
                .fill(theme.colors.cardBackground)
                .frame(width: 28, height: 24)
            // Accent primary
            Rectangle()
                .fill(theme.colors.accentPrimary)
                .frame(width: 28, height: 24)
            // Accent secondary
            Rectangle()
                .fill(theme.colors.accentSecondary)
                .frame(width: 28, height: 24)
            // Accent tertiary
            Rectangle()
                .fill(theme.colors.accentTertiary)
                .frame(width: 28, height: 24)
            // Text primary
            Rectangle()
                .fill(theme.colors.textPrimary)
                .frame(width: 28, height: 24)
            // Destructive
            Rectangle()
                .fill(theme.colors.destructive)
                .frame(width: 28, height: 24)
            // Success
            Rectangle()
                .fill(theme.colors.success)
                .frame(width: 28, height: 24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(theme.colors.border, lineWidth: 0.5)
        )
    }

    /// Render a SurfaceFill as a swatch cell — materials show as a system gray.
    @ViewBuilder
    private func swatchCell(fill: SurfaceFill) -> some View {
        switch fill {
        case .solid(let color):
            Rectangle()
                .fill(color)
                .frame(width: 28, height: 24)
        case .textured(let color, _):
            Rectangle()
                .fill(color)
                .frame(width: 28, height: 24)
        case .material:
            // Materials can't be rendered as a simple color; show a neutral gray placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 28, height: 24)
        }
    }
}

private struct CardSettingsPane: View {
    @Binding var settings: AppSettings
    var onSave: () -> Void

    var body: some View {
        Form {
            Section {
                ForEach(SizeCategory.allCases, id: \.self) { category in
                    HStack {
                        Label(category.displayName, systemImage: category.systemImage)
                        Spacer()
                        Stepper(
                            value: lineLimitBinding(for: category),
                            in: 1...99,
                            step: 1
                        ) {
                            Text("\(lineLimitBinding(for: category).wrappedValue) lines")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .labelsHidden()
                        .accessibilityLabel("\(category.displayName) line limit")
                    }
                }
            } header: {
                Text("Size Category Configuration")
            } footer: {
                Text("Configure how many lines each card size category displays in your layouts.")
            }
        }
        .formStyle(.grouped)
    }

    // Binding for the appropriate field on AppSettings
    private func lineLimitBinding(for category: SizeCategory) -> Binding<Int> {
        Binding(
            get: {
                switch category {
                case .compact:  return settings.linesCompact
                case .standard: return settings.linesStandard
                case .large:    return settings.linesLarge
                }
            },
            set: { newValue in
                switch category {
                case .compact:  settings.linesCompact = newValue
                case .standard: settings.linesStandard = newValue
                case .large:    settings.linesLarge = newValue
                }
                onSave()
            }
        )
    }
}

private struct ViewsSettingsPane: View {
    @Binding var settings: AppSettings
    var onSave: () -> Void

    private let minZoom: Double = 0.6
    private let maxZoom: Double = 1.8

    var body: some View {
        Form {
            Section {
                HStack {
                    Label("Structure Board Zoom", systemImage: "magnifyingglass")
                    Spacer()
                    Slider(
                        value: Binding(
                            get: { settings.structureBoardZoom.clamped(to: minZoom...maxZoom) },
                            set: { newValue in
                                settings.structureBoardZoom = newValue.clamped(to: minZoom...maxZoom)
                                onSave()
                            }
                        ),
                        in: minZoom...maxZoom
                    )
                    .frame(maxWidth: 220)

                    Text("\(Int(round(settings.structureBoardZoom * 100)))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Button("Reset") {
                        settings.structureBoardZoom = 1.0
                        onSave()
                    }
                    .buttonStyle(.bordered)
                    .help("Reset to 100%")
                }
            } header: {
                Text("Structure Board")
            } footer: {
                Text("Default zoom level for the Structure Board. You can also adjust zoom directly in the board with gestures or toolbar controls.")
            }

            // New: Remembered detail tab per Kind (UserDefaults-backed)
            Section {
                ForEach(Kinds.orderedCases.filter { $0 != .structure }, id: \.self) { kind in
                    HStack {
                        Label(kind.singularTitle, systemImage: kind.systemImage)
                        Spacer()
                        Picker("Default Tab", selection: tabBinding(for: kind)) {
                            ForEach(CardDetailTab.allowedTabs(for: kind), id: \.self) { tab in
                                Text(tab.title).tag(tab.rawValue)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 220)
                        .help("Default and remembered tab for \(kind.title)")
                    }
                }

                Button("Reset Remembered Tabs") {
                    resetRememberedTabs()
                }
                .buttonStyle(.bordered)
                .help("Clear the saved default/last-selected detail tab per Kind")
            } header: {
                Text("Card Detail Tabs")
            } footer: {
                Text("Choose the default tab per card type. The app remembers your last selection per type and restores it next time. Tabs not available for a type will fall back to Details.")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - UserDefaults helpers for tab preference

    private func tabKey(for kind: Kinds) -> String { "DetailTab.\(kind.rawValue)" }

    private func getStoredTabRaw(for kind: Kinds) -> String {
        let raw = UserDefaults.standard.string(forKey: tabKey(for: kind))
        // Default to Details; coerce if invalid for the kind
        let tab = CardDetailTab.coerce(CardDetailTab.from(raw: raw, default: .details), for: kind)
        return tab.rawValue
    }

    private func setStoredTabRaw(_ raw: String, for kind: Kinds) {
        let desired = CardDetailTab.from(raw: raw, default: .details)
        let coerced = CardDetailTab.coerce(desired, for: kind)
        UserDefaults.standard.set(coerced.rawValue, forKey: tabKey(for: kind))
    }

    private func tabBinding(for kind: Kinds) -> Binding<String> {
        Binding(
            get: { getStoredTabRaw(for: kind) },
            set: { newRaw in setStoredTabRaw(newRaw, for: kind) }
        )
    }

    private func resetRememberedTabs() {
        for k in Kinds.orderedCases where k != .structure {
            UserDefaults.standard.removeObject(forKey: tabKey(for: k))
        }
    }
}

private struct AuthorSettingsPane: View {
    @Binding var settings: AppSettings
    var onSave: () -> Void

    @State private var tempAuthor: String = ""

    var body: some View {
        Form {
            Section {
                TextField("Name", text: Binding(
                    get: { tempAuthor },
                    set: { newValue in
                        tempAuthor = newValue
                        settings.defaultAuthor = newValue
                        onSave()
                    }
                ))
                .textContentType(.name)
                #if os(iOS) || os(visionOS)
                .textInputAutocapitalization(.words)
                #endif
            } header: {
                Text("Default Author")
            } footer: {
                Text("Use Shift–Command–A in the Author field while editing a Card to insert this default.")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            tempAuthor = settings.defaultAuthor
        }
    }
}

// MARK: - Images Settings Pane

private struct ImagesSettingsPane: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    // Fetch all cards that have either a thumbnail or an original image
    @Query(filter: #Predicate<Card> { $0.thumbnailData != nil || $0.originalImageData != nil },
           sort: [SortDescriptor(\Card.name, order: .forward)])
    private var imageCards: [Card]

    @State private var selection: Set<UUID> = []
    @State private var showMissingOnly: Bool = true

    // Batch sheet
    @State private var isPresentingBatch: Bool = false
    @State private var batchAppliedCount: Int = 0

    // Per-item editor
    @State private var editingCard: Card?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            GroupBox {
                if filteredCards.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                        Text(emptyMessage)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    listView
                }
            }

            footerToolbar
        }
        .padding()
        .sheet(isPresented: $isPresentingBatch) {
            BatchAttributionSheet { result in
                guard let result else { return }
                applyBatchAttribution(source: result.source,
                                      locator: result.locator,
                                      excerpt: result.excerpt,
                                      note: result.note)
            }
            .frame(minWidth: 520, minHeight: 360)
            .environmentObject(themeManager)
        }
        .sheet(item: $editingCard, content: { card in
            ImageAttributionEditor(card: card, citation: nil) { _ in
                // No-op; editor already saves
            }
            .frame(minWidth: 420, minHeight: 360)
            .environmentObject(themeManager)
        })
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label("Images", systemImage: "photo.on.rectangle")
                .font(.title3.bold())
            Spacer()
            Toggle(isOn: $showMissingOnly) {
                Text("Missing attribution only")
            }
            .toggleStyle(.switch)
            .help("Show only images without any image attribution")
        }
    }

    private var filteredCards: [Card] {
        if showMissingOnly {
            return imageCards.filter { !hasAnyImageAttribution(for: $0) }
        } else {
            return imageCards
        }
    }

    private var emptyMessage: String {
        if imageCards.isEmpty {
            return String(localized: "No cards with images were found.")
        }
        if showMissingOnly {
            return String(localized: "All images have attribution.")
        } else {
            return String(localized: "No images to show.")
        }
    }

    private var listView: some View {
        List(filteredCards, selection: $selection) { card in
            HStack(spacing: 10) {
                ThumbnailView(card: card)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(.quaternary, lineWidth: 0.8)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: card.kind.systemImage)
                            .foregroundStyle(.secondary)
                        Text(card.name.isEmpty ? "Untitled" : card.name)
                            .font(.body)
                            .lineLimit(1)
                    }
                    Text(verbatim: card.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if hasAnyImageAttribution(for: card) {
                    Label("Has attribution", systemImage: "checkmark.seal")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.green)
                        .help("At least one image attribution exists for this card")
                } else {
                    Label("Missing attribution", systemImage: "exclamationmark.triangle")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.orange)
                        .help("No image attribution exists for this card")
                }

                Menu {
                    Button {
                        editingCard = card
                    } label: {
                        Label(hasAnyImageAttribution(for: card) ? "Add Another Attribution…" : "Add Attribution…", systemImage: "plus")
                    }
                    if hasAnyImageAttribution(for: card) {
                        Button {
                            editingCard = card
                        } label: {
                            Label("Edit/Add Attribution…", systemImage: "pencil")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
            }
            .tag(card.id)
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    editingCard = card
                } label: {
                    Label(hasAnyImageAttribution(for: card) ? "Add Another Attribution…" : "Add Attribution…", systemImage: "plus")
                }
            }
        }
        #if canImport(UIKit)
        .environment(\.editMode, .constant(.active)) // enable multiselect on iOS/iPadOS
        #endif
        .frame(minHeight: 240, maxHeight: .infinity)
    }

    private var footerToolbar: some View {
        HStack(spacing: 8) {
            Button {
                isPresentingBatch = true
            } label: {
                Label("Set Attribution…", systemImage: "checkmark.seal")
            }
            .disabled(selection.isEmpty)
            .help("Create an image attribution for all selected cards")

            if batchAppliedCount > 0 {
                Text("Applied to \(batchAppliedCount) card(s).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(filteredCards.count) image(s)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Attribution helpers

    private func hasAnyImageAttribution(for card: Card) -> Bool {
        let cardIDOpt: UUID? = card.id
        let kindRaw = CitationKind.image.rawValue
        let fetch = FetchDescriptor<Citation>(
            predicate: #Predicate { $0.card?.id == cardIDOpt && $0.kindRaw == kindRaw },
            sortBy: []
        )
        let found = (try? modelContext.fetch(fetch)) ?? []
        return !found.isEmpty
    }

    @MainActor
    private func applyBatchAttribution(source: Source, locator: String, excerpt: String, note: String?) {
        let ids = selection
        let targets = filteredCards.filter { ids.contains($0.id) }
        guard !targets.isEmpty else { return }

        var created = 0
        let now = Date()
        for card in targets {
            // Create a new image citation per selected card
            let c = Citation(card: card,
                             source: source,
                             kind: .image,
                             locator: locator,
                             excerpt: excerpt,
                             contextNote: note?.isEmpty == false ? note : nil,
                             createdAt: now.addingTimeInterval(Double(created) * 0.001))
            modelContext.insert(c)
            created += 1
        }
        try? modelContext.save()
        batchAppliedCount = created
        // Keep selection as-is; user may apply again
    }
}

// Small thumbnail loader that uses Card.makeThumbnailImage() async
private struct ThumbnailView: View {
    let card: Card
    @State private var image: Image?

    var body: some View {
        ZStack {
            if let image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.secondary.opacity(0.12))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .task(id: card.id) {
            if let thumb = await card.makeThumbnailImage() {
                image = thumb
            } else if let full = await card.makeImage() {
                image = full
            } else {
                image = nil
            }
        }
    }
}

// Batch attribution sheet: choose/create Source and common fields
private struct BatchAttributionSheet: View {
    struct Result {
        let source: Source
        let locator: String
        let excerpt: String
        let note: String?
    }

    var onDone: (Result?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Source.title, order: .forward) private var sources: [Source]

    @State private var selectedSource: Source?
    @State private var locator: String = ""
    @State private var excerpt: String = ""
    @State private var note: String = ""

    @State private var isCreatingSource: Bool = false
    @State private var newSourceTitle: String = ""
    @State private var newSourceAuthors: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set Attribution for Selected Images")
                .font(.title3).bold()

            GroupBox("Source") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Choose Source", selection: Binding(get: {
                        selectedSource?.id
                    }, set: { newID in
                        selectedSource = sources.first(where: { $0.id == newID })
                    })) {
                        Text("— Select —").tag(UUID?.none)
                        ForEach(sources) { s in
                            Text(s.title).tag(Optional(s.id))
                        }
                    }
                    .labelsHidden()

                    Divider().opacity(0.3)

                    DisclosureGroup(isExpanded: $isCreatingSource) {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Title", text: $newSourceTitle)
                            TextField("Authors", text: $newSourceAuthors)
                            Button {
                                createSource()
                            } label: {
                                Label("Create Source", systemImage: "plus")
                            }
                            .disabled(newSourceTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(.top, 6)
                    } label: {
                        Label("Create New Source", systemImage: "plus.circle")
                    }
                }
            }

            GroupBox("Attribution Details (applied to each selected image)") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo")
                        Text("Kind: Image")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    TextField("Locator (e.g., p. 42, fig. 2, 00:12:15)", text: $locator)
                    TextField("Excerpt (optional)", text: $excerpt)
                    TextField("Note (optional)", text: $note)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Button("Cancel") {
                    onDone(nil)
                    dismiss()
                }
                Spacer()
                Button {
                    if let src = selectedSource {
                        onDone(Result(source: src,
                                      locator: locator,
                                      excerpt: excerpt,
                                      note: note.isEmpty ? nil : note))
                        dismiss()
                    }
                } label: {
                    Label("Apply", systemImage: "checkmark.circle.fill")
                }
                .disabled(selectedSource == nil)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }

    private func createSource() {
        let title = newSourceTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let s = Source(title: title, authors: newSourceAuthors)
        modelContext.insert(s)
        try? modelContext.save()
        selectedSource = s
        newSourceTitle = ""
        newSourceAuthors = ""
        isCreatingSource = false
    }
}

// MARK: - AI Settings Pane

private struct AISettingsPane: View {
    // DR-0070: Use @State with onAppear to sync from UserDefaults
    @State private var analysisProvider: String = AISettings.shared.analysisProvider
    @State private var imageGenerationProvider: String = AISettings.shared.imageGenerationProvider
    @State private var needsInitialLoad: Bool = true
    @State private var apiKeys: [String: String] = [:] // providerKey -> entered text
    @State private var showAPIKey: [String: Bool] = [:] // providerKey -> show/hide
    @State private var hasAPIKey: [String: Bool] = [:] // providerKey -> has key in keychain (reactive)
    @State private var savedMessage: String?
    @State private var savedMessageTimer: Timer?

    private var providers: [AIProviderProtocol] {
        AIProviderRegistry.shared.allProviders()
    }

    var body: some View {
        Form {
            // Analysis provider section
            Section {
                Picker("Provider", selection: $analysisProvider) {
                    ForEach(providers, id: \.name) { provider in
                        HStack {
                            Text(provider.name)
                            if !provider.isAvailable {
                                Text("(Unavailable)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(provider.name)
                    }
                }
                .onChange(of: analysisProvider) { _, newValue in
                    // DR-0070: Write to AISettings to persist to UserDefaults
                    AISettings.shared.analysisProvider = newValue
                    showSavedMessage("Analysis provider updated")
                }
            } header: {
                Text("Content Analysis")
            } footer: {
                Text("Used for entity extraction, relationship inference, and content analysis. Apple Intelligence is faster and free.")
            }

            // Image generation provider section
            Section {
                Picker("Provider", selection: $imageGenerationProvider) {
                    ForEach(providers, id: \.name) { provider in
                        HStack {
                            Text(provider.name)
                            if !provider.isAvailable {
                                Text("(Unavailable)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(provider.name)
                    }
                }
                .onChange(of: imageGenerationProvider) { _, newValue in
                    // DR-0070: Write to AISettings to persist to UserDefaults
                    AISettings.shared.imageGenerationProvider = newValue
                    showSavedMessage("Image generation provider updated")
                }
            } header: {
                Text("Image Generation")
            } footer: {
                Text("Used for generating images and maps. DALL-E 3 produces higher quality results but requires API key and has usage costs.")
            }

            // Provider list with API key management
            Section {
                ForEach(providers, id: \.name) { provider in
                    providerRow(for: provider)
                }
            } header: {
                Text("AI Providers")
            } footer: {
                Text("Configure API keys for third-party AI providers. Keys are stored securely in the system keychain.")
            }

            // Saved message
            if let message = savedMessage {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(message)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        // DR-0070: Reload from UserDefaults and keychain when view appears
        .task {
            if needsInitialLoad {
                analysisProvider = AISettings.shared.analysisProvider
                imageGenerationProvider = AISettings.shared.imageGenerationProvider
                loadAPIKeyStatus()
                needsInitialLoad = false
            }
        }
        .onAppear {
            // Also reload on subsequent appearances
            analysisProvider = AISettings.shared.analysisProvider
            imageGenerationProvider = AISettings.shared.imageGenerationProvider
            loadAPIKeyStatus()
        }
    }

    @ViewBuilder
    private func providerRow(for provider: AIProviderProtocol) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Provider header
            HStack {
                Image(systemName: provider.requiresAPIKey ? "key.fill" : "sparkles")
                    .foregroundStyle(provider.isAvailable ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.name)
                        .font(.headline)

                    if let metadata = provider.metadata, let modelVersion = metadata.modelVersion {
                        Text(modelVersion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Availability status
                if provider.isAvailable {
                    Label("Available", systemImage: "checkmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.green)
                        .help("This provider is available for use")
                } else {
                    Label("Unavailable", systemImage: "exclamationmark.triangle")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.orange)
                        .help("This provider is not available on this platform")
                }
            }

            // API key configuration
            if provider.requiresAPIKey {
                apiKeySection(for: provider)
            }

            // Provider metadata
            if let metadata = provider.metadata {
                metadataSection(for: metadata)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func apiKeySection(for provider: AIProviderProtocol) -> some View {
        let providerKey = providerKey(for: provider)
        let hasKey = hasAPIKey[providerKey] ?? false

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("API Key")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if hasKey {
                    Label("Configured", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Label("Not Configured", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            HStack(spacing: 8) {
                Group {
                    if showAPIKey[providerKey] == true {
                        TextField("Enter API Key", text: binding(for: providerKey))
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Enter API Key", text: binding(for: providerKey))
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .font(.system(.body, design: .monospaced))

                Button {
                    let currentValue = showAPIKey[providerKey] ?? false
                    showAPIKey[providerKey] = !currentValue
                } label: {
                    Image(systemName: showAPIKey[providerKey] == true ? "eye.slash" : "eye")
                }
                .buttonStyle(.bordered)
                .help(showAPIKey[providerKey] == true ? "Hide API key" : "Show API key")
            }

            HStack(spacing: 8) {
                Button {
                    saveAPIKey(for: provider, providerKey: providerKey)
                } label: {
                    Label("Save", systemImage: "checkmark.circle")
                }
                .disabled(apiKeys[providerKey]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

                if hasKey {
                    Button(role: .destructive) {
                        deleteAPIKey(for: providerKey)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func metadataSection(for metadata: AIProviderMetadata) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let modelVersion = metadata.modelVersion {
                metadataRow(label: "Model", value: modelVersion)
            }
            if let maxPromptLength = metadata.maxPromptLength {
                metadataRow(label: "Max Prompt Length", value: "\(maxPromptLength) characters")
            }
            if let formats = metadata.supportedImageFormats {
                metadataRow(label: "Supported Formats", value: formats.joined(separator: ", "))
            }

            if let rateLimit = metadata.rateLimit {
                metadataRow(label: "Rate Limit", value: "\(rateLimit.requestsPerMinute) requests/minute")
                if let rpd = rateLimit.requestsPerDay {
                    metadataRow(label: "Daily Limit", value: "\(rpd) requests/day")
                }
            }

            if let license = metadata.licenseInfo {
                metadataRow(label: "License", value: license.licenseType)
                metadataRow(label: "Commercial Use", value: license.commercialUseAllowed ? "Allowed" : "Not Allowed")
                metadataRow(label: "Attribution", value: license.attributionRequired ? "Required" : "Optional")
            }
        }
        .font(.caption)
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Helpers

    private func providerKey(for provider: AIProviderProtocol) -> String {
        // Use first word of provider name, lowercased
        // "OpenAI DALL-E 3" -> "openai"
        // "Apple Intelligence" -> "apple"
        let firstWord = provider.name.split(separator: " ").first.map(String.init) ?? provider.name
        return firstWord.lowercased()
    }

    private func binding(for providerKey: String) -> Binding<String> {
        Binding(
            get: {
                // Only use cached value if it's non-empty
                if let existing = apiKeys[providerKey], !existing.isEmpty {
                    return existing
                }
                // Try to load from keychain
                // Note: try? on a function that returns String? gives us String?? which Swift flattens to String?
                let stored = (try? KeychainHelper.shared.retrieveAPIKey(for: providerKey)) ?? nil
                return stored ?? ""
            },
            set: { newValue in
                apiKeys[providerKey] = newValue
            }
        )
    }

    private func loadAPIKeyStatus() {
        for provider in providers {
            let key = providerKey(for: provider)
            hasAPIKey[key] = KeychainHelper.shared.hasAPIKey(for: key)
        }
    }

    private func saveAPIKey(for provider: AIProviderProtocol, providerKey: String) {
        guard let key = apiKeys[providerKey]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty else {
            return
        }

        do {
            try KeychainHelper.shared.saveAPIKey(key, for: providerKey)
            hasAPIKey[providerKey] = true // Update state
            showSavedMessage("API key saved for \(provider.name)")
            // Clear the text field after successful save
            apiKeys[providerKey] = ""
        } catch {
            showSavedMessage("Failed to save API key: \(error.localizedDescription)")
        }
    }

    private func deleteAPIKey(for providerKey: String) {
        do {
            try KeychainHelper.shared.deleteAPIKey(for: providerKey)
            hasAPIKey[providerKey] = false // Update state
            apiKeys[providerKey] = ""
            showSavedMessage("API key deleted")
        } catch {
            showSavedMessage("Failed to delete API key: \(error.localizedDescription)")
        }
    }

    private func showSavedMessage(_ message: String) {
        savedMessage = message
        savedMessageTimer?.invalidate()
        savedMessageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            savedMessage = nil
        }
    }
}

// MARK: - ShareSheet (iOS)

#if os(iOS)
/// UIActivityViewController wrapper for sharing theme files.
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - Previews

#Preview("Design - Split (Injected, Light)") {
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: AppSettings.self, configurations: config)
    }()

    return SettingsView(
        initialSelection: .views,
        previewSettings: AppSettings(
            colorSchemePreference: .system,
            structureBoardZoom: 0.9
        )
    )
    .frame(minWidth: 520, minHeight: 380)
    .modelContainer(container)
    .preferredColorScheme(.light)
}

#Preview("Design - Split (Injected, Dark — Cards)") {
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: AppSettings.self, configurations: config)
    }()

    return SettingsView(
        initialSelection: .cards,
        previewSettings: AppSettings(
            colorSchemePreference: .dark
        )
    )
    .frame(minWidth: 520, minHeight: 380)
    .modelContainer(container)
    .preferredColorScheme(.dark)
}

#Preview("Live SwiftData - Split") {
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: AppSettings.self, configurations: config)
        let ctx = ModelContext(c)
        ctx.autosaveEnabled = false
        _ = AppSettings.fetchOrCreate(in: ctx)
        return c
    }()

    return SettingsView(initialSelection: .author)
        .frame(minWidth: 520, minHeight: 380)
        .modelContainer(container)
}

#Preview("Relations Pane - Live SwiftData") {
    let container: ModelContainer = {
        let schema = Schema([AppSettings.self, RelationType.self, Card.self, CardEdge.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: schema, configurations: config)
        let ctx = c.mainContext
        // Seed a couple of types and an edge for design-time
        let t1 = RelationType(code: "appears-in/is-appeared-by", forwardLabel: "appears in", inverseLabel: "is appeared by", sourceKind: .characters, targetKind: .scenes)
        let t2 = RelationType(code: "references/referenced-by", forwardLabel: "references", inverseLabel: "referenced by")
        ctx.insert(t1); ctx.insert(t2)
        let a = Card(kind: .characters, name: "Mira", subtitle: "", detailedText: "")
        let b = Card(kind: .scenes, name: "Opening", subtitle: "", detailedText: "")
        ctx.insert(a); ctx.insert(b)
        ctx.insert(CardEdge(from: a, to: b, type: t1))
        _ = AppSettings.fetchOrCreate(in: ctx)
        try? ctx.save()
        return c
    }()

    return SettingsView(initialSelection: .relations)
        .frame(minWidth: 680, minHeight: 480)
        .modelContainer(container)
}
