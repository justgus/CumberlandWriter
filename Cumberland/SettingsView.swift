import SwiftUI
import SwiftData

enum SettingsSection: String, CaseIterable, Identifiable {
    case display = "Display"
    case cards = "Cards"
    case author = "Author"

    var id: String { rawValue }

    var title: String { rawValue }

    var systemImage: String {
        switch self {
        case .display: return "sun.max"
        case .cards:   return "rectangle.grid.2x2"
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

// Custom alignment for right-justifying the numeric value column across rows
private extension HorizontalAlignment {
    enum ValueColumn: AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat { d[.trailing] }
    }
    static let valueColumn = HorizontalAlignment(ValueColumn.self)
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

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
                    .tag(section) // Ensure tag type matches selection's wrapped value
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
                    onSave: save
                )
                .navigationTitle("Display")
            case .cards:
                CardSettingsPane(
                    settings: settingsBinding(for: \.self),
                    onSave: save
                )
                .navigationTitle("Cards")
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
}

// MARK: - Detail Panes

private struct DisplaySettingsPane: View {
    @Binding var settings: AppSettings
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Section("Appearance") {
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
                }

                Section {
                    Text("The app can follow System appearance or always use Light/Dark. This preference takes effect app-wide.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            // Add some breathing room around the form while keeping content top-aligned.
            .padding(.top, 8)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// Cards settings: list rows for each size category with data binding, save-on-change, and aligned values
private struct CardSettingsPane: View {
    @Binding var settings: AppSettings
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Constrain the form's width so rows don't sprawl on very wide windows.
            HStack(alignment: .top, spacing: 0) {
                Form {
                    Section("Size Category") {
                        // Use a VStack with our custom alignment to line up the values
                        VStack(alignment: .valueColumn, spacing: 8) {
                            ForEach(SizeCategory.allCases, id: \.self) { category in
                                rowDetail(for: category)
                            }
                        }
                    }
                }
                .frame(maxWidth: 520, alignment: .leading)

                Spacer(minLength: 0)
            }
            // Add padding around the pane similar to DisplaySettingsPane
            .padding(.top, 8)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
            }
        )
    }

    // Row detail: value aligned and a labelless stepper to the right
    @ViewBuilder
    private func rowDetail(for category: SizeCategory) -> some View {
        let binding = lineLimitBinding(for: category)

        HStack(spacing: 12) {
            Label(category.displayName, systemImage: category.systemImage)

            // Compact trailing value right next to the label
            HStack(spacing: 6) {
                // Align the numeric value's trailing edge to the shared value column
                Text("\(binding.wrappedValue)")
                    .font(.body.monospacedDigit())
                    .frame(width: 36, alignment: .trailing) // fits up to 3 digits
                    .lineLimit(1)
                    .alignmentGuide(.valueColumn) { d in d[.trailing] }

                Text("lines")
                    .foregroundStyle(.secondary)

                // Labelless stepper tied to the same binding
                Stepper(value: binding, in: 1...99) {
                    EmptyView()
                }
                .labelsHidden()
                .accessibilityLabel("\(category.displayName) lines stepper")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(category.displayName) lines")
        }
        .onChange(of: binding.wrappedValue) { _, _ in
            onSave()
        }
        .contentShape(Rectangle())
    }
}

// Author settings: lets the user set the default author name
private struct AuthorSettingsPane: View {
    @Binding var settings: AppSettings
    var onSave: () -> Void

    @State private var tempAuthor: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Section("Default Author") {
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

                    Text("Use Shift–Command–A in the Author field while editing a Card to insert this default.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            Spacer(minLength: 0)
        }
        .onAppear {
            tempAuthor = settings.defaultAuthor
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Previews

#Preview("Design - Split (Injected, Light)") {
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: AppSettings.self, configurations: config)
    }()

    return SettingsView(
        initialSelection: .display,
        previewSettings: AppSettings(
            colorSchemePreference: .system
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

