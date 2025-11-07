import SwiftUI
import SwiftData

enum SettingsSection: String, CaseIterable, Identifiable {
    case display = "Display"
    case cards = "Cards"
    case views = "Views"
    case relations = "Relations"
    case images = "Images"
    case author = "Author"

    var id: String { rawValue }

    var title: String { rawValue }

    var systemImage: String {
        switch self {
        case .display:  return "sun.max"
        case .cards:    return "rectangle.grid.2x2"
        case .views:    return "rectangle.3.offgrid"
        case .relations:return "link"
        case .images:   return "photo.on.rectangle"
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
                colorSchemeRaw = s.colorSchemePreference.rawValue
            }
            try? modelContext.save()
        }
    }
}

// MARK: - Detail Panes

private struct DisplaySettingsPane: View {
    @Binding var settings: AppSettings
    var onSave: () -> Void

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
        }
        .formStyle(.grouped)
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
        }
        .sheet(item: $editingCard, content: { card in
            ImageAttributionEditor(card: card, citation: nil) { _ in
                // No-op; editor already saves
            }
            .frame(minWidth: 420, minHeight: 360)
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
            return "No cards with images were found."
        }
        if showMissingOnly {
            return "All images have attribution."
        } else {
            return "No images to show."
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
                    Text(card.subtitle)
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
