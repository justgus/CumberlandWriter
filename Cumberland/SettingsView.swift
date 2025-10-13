import SwiftUI
import SwiftData

enum SettingsSection: String, CaseIterable, Identifiable {
    case display = "Display"
    case cards = "Cards"
    case views = "Views"
    case author = "Author"

    var id: String { rawValue }

    var title: String { rawValue }

    var systemImage: String {
        switch self {
        case .display: return "sun.max"
        case .cards:   return "rectangle.grid.2x2"
        case .views:   return "rectangle.3.offgrid"
        case .author:  return "person.text.rectangle"
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
        }
        .formStyle(.grouped)
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

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
