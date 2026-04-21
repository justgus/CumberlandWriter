//
//  ProjectDetailView.swift
//  Cumberland
//
//  Created for Cumberland Writer workflow transformation.
//  Replaces the default project card detail view with a writing-first interface.
//
//  This view presents a segmented control to switch between:
//  1. Manuscript Writing Surface - Continuous text editor with scene awareness
//  2. Project Dashboard - Project instrument panel showing structure, status, and issues
//
//  This shifts Cumberland from a card/relationship editor to a full-fledged writing tool
//  where worldbuilding can be performed as the manuscript is written.
//

import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    let project: Card

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    // Tab selection: Manuscript is default/first
    private enum ProjectTab: String, CaseIterable, Identifiable {
        case manuscript = "Manuscript"
        case dashboard = "Dashboard"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .manuscript: return "doc.text"
            case .dashboard: return "chart.bar.doc.horizontal"
            }
        }
    }

    @State private var selectedTab: ProjectTab = .manuscript

    // Persist tab selection per project
    @AppStorage("ProjectDetailView.selectedTab") private var selectedTabRaw: String = ProjectTab.manuscript.rawValue

    var body: some View {
        VStack(spacing: 0) {
            // Top mode/action bar with segmented control
            topModeBar

            // Content area switches between manuscript and dashboard
            tabContent
        }
        .navigationTitle(project.name.isEmpty ? "Untitled Project" : project.name)
        .task {
            // Restore last selected tab
            if let restored = ProjectTab(rawValue: selectedTabRaw) {
                selectedTab = restored
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            // Persist tab selection
            UserDefaults.standard.set(newValue.rawValue, forKey: "ProjectDetailView.selectedTab")
        }
    }

    // MARK: - Top Mode Bar

    private var topModeBar: some View {
        HStack(spacing: 16) {
            // Mode switcher
            Picker("View Mode", selection: $selectedTab) {
                ForEach(ProjectTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)

            Spacer()

            // Quick actions (Resume, Write)
            HStack(spacing: 12) {
                Button {
                    // Resume action - jump to best resumption target
                    resumeWriting()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(.bordered)
                .help("Resume writing at the active scene")

                Button {
                    // Write action - enter manuscript surface
                    withAnimation {
                        selectedTab = .manuscript
                    }
                } label: {
                    Label("Write", systemImage: "pencil")
                }
                .buttonStyle(.borderedProminent)
                .help("Switch to writing mode")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground()
        )
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .manuscript:
            ManuscriptWritingSurfaceView(project: project)
                .transition(.opacity)
        case .dashboard:
            ProjectDashboardView(project: project)
                .transition(.opacity)
        }
    }

    // MARK: - Actions

    private func resumeWriting() {
        // TODO: Implement resume logic to find best resumption target
        // For now, just switch to manuscript mode
        withAnimation {
            selectedTab = .manuscript
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, configurations: config)
    let context = container.mainContext

    let project = Card(kind: .projects, name: "The Lantern Chronicles", subtitle: "A Fantasy Epic", detailedText: "")
    context.insert(project)

    return NavigationStack {
        ProjectDetailView(project: project)
            .modelContainer(container)
            .environmentObject(ThemeManager())
    }
}
