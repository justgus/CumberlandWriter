//
//  BoardSidebarPanel.swift
//  BoardEngine
//
//  Generic sidebar panel for the board canvas. Displays backlog items
//  using a consumer-provided row view. Supports show/hide toggle,
//  multi-selection, and keyboard shortcuts.
//

import SwiftUI

// MARK: - Board Sidebar Panel

/// A collapsible sidebar panel for the board canvas backlog.
/// Uses `@ViewBuilder` for row content so consumers provide their own
/// node display (e.g. Cumberland's CardView row, standalone's custom row).
public struct BoardSidebarPanel<DS: BoardDataSource, RowContent: View>: View {
    let contentSize: CGSize
    let scheme: ColorScheme
    @Binding var isSidebarVisible: Bool
    @Binding var selectedNodeIDs: Set<UUID>
    let backlogNodes: [DS.Node]
    let onAddSelected: () -> Void

    @ViewBuilder let rowContent: (_ node: DS.Node, _ isSelected: Bool) -> RowContent

    public init(
        contentSize: CGSize,
        scheme: ColorScheme,
        isSidebarVisible: Binding<Bool>,
        selectedNodeIDs: Binding<Set<UUID>>,
        backlogNodes: [DS.Node],
        onAddSelected: @escaping () -> Void,
        @ViewBuilder rowContent: @escaping (_ node: DS.Node, _ isSelected: Bool) -> RowContent
    ) {
        self.contentSize = contentSize
        self.scheme = scheme
        self._isSidebarVisible = isSidebarVisible
        self._selectedNodeIDs = selectedNodeIDs
        self.backlogNodes = backlogNodes
        self.onAddSelected = onAddSelected
        self.rowContent = rowContent
    }

    public var body: some View {
        if isSidebarVisible {
            VStack(spacing: 8) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "tray.full")
                        .foregroundStyle(.secondary)
                    Text("Backlog")
                        .font(.headline)
                    Spacer(minLength: 8)
                    Text("\(backlogNodes.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        isSidebarVisible = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    #if os(macOS)
                    .help("Hide Backlog")
                    #endif
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)

                // Add selected button
                if !selectedNodeIDs.isEmpty {
                    Button {
                        onAddSelected()
                    } label: {
                        Label("Add \(selectedNodeIDs.count) to Board", systemImage: "plus.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.horizontal, 10)
                }

                Divider()

                // Scrollable list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if backlogNodes.isEmpty {
                            Text("No items to add.")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        } else {
                            ForEach(backlogNodes, id: \.nodeID) { node in
                                let isSelected = selectedNodeIDs.contains(node.nodeID)
                                rowContent(node, isSelected)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if selectedNodeIDs.contains(node.nodeID) {
                                            selectedNodeIDs.remove(node.nodeID)
                                        } else {
                                            selectedNodeIDs.insert(node.nodeID)
                                        }
                                    }
                            }
                        }
                    }
                    .padding(10)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(scheme == .dark ? 0.20 : 0.35), lineWidth: 0.75)
                    .blendMode(.overlay)
            )
            .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.18), radius: 16, x: 0, y: 10)
            .frame(maxHeight: 520)
            .accessibilityElement(children: .contain)
            .onKeyPress(.escape) {
                if !selectedNodeIDs.isEmpty {
                    selectedNodeIDs.removeAll()
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.init("a"), phases: .down) { keyPress in
                if keyPress.modifiers.contains(.command) && !backlogNodes.isEmpty {
                    selectedNodeIDs = Set(backlogNodes.map { $0.nodeID })
                    return .handled
                }
                return .ignored
            }
            .transition(.move(edge: .leading).combined(with: .opacity))
        }
    }
}
