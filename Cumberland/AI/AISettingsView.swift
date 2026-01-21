import SwiftUI

/// AI Settings configuration view
/// Allows users to configure AI provider, image generation, and content analysis settings
struct AISettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var settings = AISettings.shared
    @State private var showingAPIKeySheet = false
    @State private var selectedProviderForAPIKey: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                // Provider Selection
                providerSection

                // Image Generation Settings
                imageGenerationSection

                // Content Analysis Settings
                contentAnalysisSection

                // Advanced Settings
                advancedSection
            }
            .navigationTitle("AI Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAPIKeySheet) {
                if let provider = selectedProviderForAPIKey {
                    APIKeyEntryView(provider: provider)
                }
            }
            .alert("Settings Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Provider Section

    private var providerSection: some View {
        Section {
            Toggle("Enable AI Features", isOn: $settings.aiEnabled)

            if settings.aiEnabled {
                Picker("AI Provider", selection: $settings.preferredProvider) {
                    ForEach(settings.availableProviders, id: \.name) { provider in
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

                // API Key management for providers that need it
                if let currentProvider = settings.currentProvider,
                   currentProvider.requiresAPIKey {
                    apiKeyRow(for: currentProvider)
                }

                // Provider info
                if let provider = settings.currentProvider {
                    providerInfo(for: provider)
                }
            }
        } header: {
            Text("AI Provider")
        } footer: {
            if !settings.aiEnabled {
                Text("AI features are disabled. Enable to use image generation and content analysis.")
            } else if !settings.isProviderAvailable {
                Text("No AI providers are available. Some features may not work.")
            }
        }
    }

    private func apiKeyRow(for provider: AIProviderProtocol) -> some View {
        HStack {
            Text("API Key")
            Spacer()
            if settings.hasAPIKey(for: provider.name.lowercased()) {
                Text("••••••••")
                    .foregroundStyle(.secondary)
                Button("Change") {
                    selectedProviderForAPIKey = provider.name
                    showingAPIKeySheet = true
                }
            } else {
                Button("Add") {
                    selectedProviderForAPIKey = provider.name
                    showingAPIKeySheet = true
                }
            }
        }
    }

    private func providerInfo(for provider: AIProviderProtocol) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let metadata = provider.metadata {
                if let version = metadata.modelVersion {
                    Text("Model: \(version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let license = metadata.licenseInfo {
                    Text("License: \(license.licenseType)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Image Generation Section

    private var imageGenerationSection: some View {
        Section {
            Toggle("Auto-Generate Images", isOn: $settings.autoGenerateImages)
                .disabled(!settings.isImageGenerationAvailable)

            if settings.autoGenerateImages {
                Stepper("Min Words: \(settings.autoGenerateMinWords)",
                       value: $settings.autoGenerateMinWords,
                       in: 25...200,
                       step: 25)
            }

            Stepper("Keep \(settings.imageHistoryLimit) Previous Versions",
                   value: $settings.imageHistoryLimit,
                   in: 0...10)

            Toggle("Always Show Attribution Overlay", isOn: $settings.alwaysShowAttributionOverlay)

            NavigationLink("Copyright Template") {
                CopyrightTemplateView()
            }

        } header: {
            Text("Image Generation")
        } footer: {
            if settings.autoGenerateImages {
                Text("Images will be automatically generated when cards have at least \(settings.autoGenerateMinWords) words in their description.")
            } else {
                Text("Use the \"Generate Image\" button to create images on demand.")
            }
        }
    }

    // MARK: - Content Analysis Section

    private var contentAnalysisSection: some View {
        Section {
            Toggle("Enable Content Analysis", isOn: $settings.analysisEnabled)
                .disabled(!settings.aiEnabled)

            if settings.analysisEnabled {
                Picker("Analysis Scope", selection: $settings.analysisScopeEnum) {
                    ForEach(AnalysisScope.allCases, id: \.self) { scope in
                        VStack(alignment: .leading) {
                            Text(scope.displayName)
                            Text(scope.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(scope)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Confidence Threshold: \(settings.confidenceThreshold, specifier: "%.0f")%")
                    Slider(value: $settings.confidenceThreshold,
                          in: 0.5...0.95,
                          step: 0.05)
                }

                Stepper("Min Words: \(settings.analysisMinWordCount)",
                       value: $settings.analysisMinWordCount,
                       in: 10...100,
                       step: 5)

                NavigationLink("Entity Types") {
                    EntityTypesView()
                }

                Toggle("Learn from Feedback", isOn: $settings.enableLearning)
            }

        } header: {
            Text("Content Analysis")
        } footer: {
            if settings.analysisEnabled {
                Text("AI will analyze your descriptions to suggest entities and relationships. Higher confidence thresholds mean fewer but more accurate suggestions.")
            }
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        Section {
            Button("Reset to Defaults") {
                settings.resetToDefaults()
            }

            #if DEBUG
            Button("Print Settings (Debug)") {
                settings.printSettings()
            }

            Button("Clear All API Keys (Debug)") {
                try? KeychainHelper.shared.deleteAllAPIKeys()
            }
            .foregroundStyle(.red)
            #endif

        } header: {
            Text("Advanced")
        }
    }
}

// MARK: - API Key Entry View

struct APIKeyEntryView: View {
    let provider: String
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("API Key", text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()

                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif

                } header: {
                    Text("Enter API Key for \(provider)")
                } footer: {
                    Text("Your API key is stored securely in the Keychain and never leaves your device.")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("API Key")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.isEmpty || isLoading)
                }
            }
        }
    }

    private func saveAPIKey() {
        isLoading = true
        errorMessage = nil

        do {
            try AISettings.shared.setAPIKey(apiKey, for: provider.lowercased())
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Copyright Template View

struct CopyrightTemplateView: View {
    @State private var settings = AISettings.shared

    var body: some View {
        Form {
            Section {
                TextEditor(text: $settings.copyrightTemplate)
                    .frame(minHeight: 100)
                    .font(.body)

            } header: {
                Text("Copyright Template")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available placeholders:")
                    Text("• {YEAR} - Current year")
                    Text("• {USER} - User name")
                    Text("")
                    Text("Preview:")
                    Text(settings.formattedCopyright())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Copyright Template")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Entity Types View

struct EntityTypesView: View {
    @State private var settings = AISettings.shared

    var body: some View {
        Form {
            Section {
                ForEach([EntityType.character, .location, .building, .artifact,
                        .vehicle, .organization, .event, .other], id: \.self) { type in
                    Toggle(type.rawValue, isOn: Binding(
                        get: { settings.isEntityTypeEnabled(type) },
                        set: { settings.setEntityType(type, enabled: $0) }
                    ))
                }
            } header: {
                Text("Enabled Entity Types")
            } footer: {
                Text("Only enabled entity types will be extracted during analysis.")
            }
        }
        .navigationTitle("Entity Types")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Preview

#Preview {
    AISettingsView()
}

#Preview("API Key Entry") {
    APIKeyEntryView(provider: "OpenAI")
}

#Preview("Copyright Template") {
    NavigationStack {
        CopyrightTemplateView()
    }
}

#Preview("Entity Types") {
    NavigationStack {
        EntityTypesView()
    }
}
