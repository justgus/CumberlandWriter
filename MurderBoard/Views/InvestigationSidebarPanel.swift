//
//  InvestigationSidebarPanel.swift
//  MurderboardApp
//
//  Collapsible backlog sidebar for the investigation board.
//  Shows nodes not currently on the board (soft-removed via node.board = nil).
//  Supports category filtering, tap-to-detail, drag-to-canvas, and
//  swipe-to-add-to-board. Mirrors the Cumberland SidebarPanel pattern.
//
//  ER-0031: Backlog sidebar for standalone MurderBoard app.
//

import SwiftUI

// MARK: - Investigation Sidebar Panel

struct InvestigationSidebarPanel: View {
    let contentSize: CGSize
    let scheme: ColorScheme

    // State bindings (owned by InvestigationBoardView)
    @Binding var isSidebarVisible: Bool
    @Binding var selectedCategoryFilter: NodeCategory?
    @Binding var detailNode: InvestigationNode?
    @Binding var selectedNodeIDs: Set<UUID>

    // Data
    let backlogNodes: [InvestigationNode]
    let edgeCountProvider: (UUID) -> Int
    let onAddNodes: ([UUID]) -> Void

    var body: some View {
        HStack {
            // Sidebar panel
            if isSidebarVisible {
                ZStack(alignment: .topTrailing) {
                    sidebarPanel()
                        .frame(width: min(320, contentSize.width * 0.35))
                        .transition(.move(edge: .leading).combined(with: .opacity))

                    sidebarToggleButton()
                        .padding(.top, 8)
                        .padding(.trailing, 8)
                }
            }

            Spacer()

            // Toggle button when sidebar is hidden (floating upper-left)
            if !isSidebarVisible {
                VStack {
                    HStack {
                        sidebarToggleButton()
                            .padding(.leading, 20)
                            .padding(.top, 20)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .allowsHitTesting(true)
    }
}

// MARK: - Sidebar Panel Content

extension InvestigationSidebarPanel {
    @ViewBuilder
    private func sidebarPanel() -> some View {
        VStack(spacing: 0) {
            sidebarHeader()
            Divider()
            sidebarNodesList()
                .contentShape(Rectangle())
                .blockInvestigationCanvasGestures()
        }
        .padding(.leading, 20)
        .padding(.vertical, 40)
        #if os(visionOS)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        #else
        .glassEffect(Glass.regular.interactive(), in: .rect(cornerRadius: 16))
        #endif
        .animation(.easeInOut(duration: 0.25), value: isSidebarVisible)
    }

    @ViewBuilder
    private func sidebarHeader() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Backlog")
                    .font(.headline)
                    .foregroundStyle(.primary)

                if selectedNodeIDs.isEmpty {
                    Text("^[\(backlogNodes.count) node](inflect: true)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("^[\(selectedNodeIDs.count) selected](inflect: true)")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                }
            }

            Spacer()

            // Add selected to board
            if !selectedNodeIDs.isEmpty {
                Button {
                    onAddNodes(Array(selectedNodeIDs))
                } label: {
                    Label("Add to Board", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            // Category filter menu
            Menu {
                Button("All Categories") {
                    selectedCategoryFilter = nil
                }
                .disabled(selectedCategoryFilter == nil)

                Divider()

                ForEach(NodeCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategoryFilter = category == selectedCategoryFilter ? nil : category
                    } label: {
                        HStack {
                            Image(systemName: category.systemImage)
                            Text(category.displayName)
                            if selectedCategoryFilter == category {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    if let filter = selectedCategoryFilter {
                        Image(systemName: filter.systemImage)
                            .font(.caption)
                            .foregroundStyle(filter.defaultColor)
                        Text(filter.displayName)
                            .font(.caption)
                            .foregroundStyle(.primary)
                    } else {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.caption)
                        Text("Filter")
                            .font(.caption)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(selectedCategoryFilter != nil ? .primary : .secondary)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func sidebarNodesList() -> some View {
        if backlogNodes.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "tray")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("No nodes in backlog")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if selectedCategoryFilter != nil {
                    Text("Try changing the filter")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
        } else {
            List {
                ForEach(backlogNodes, id: \.id) { node in
                    InvestigationSidebarRow(
                        node: node,
                        isSelected: selectedNodeIDs.contains(node.id),
                        edgeCount: edgeCountProvider(node.id),
                        scheme: scheme,
                        onTap: {
                            if selectedNodeIDs.contains(node.id) {
                                selectedNodeIDs.remove(node.id)
                            } else {
                                selectedNodeIDs.insert(node.id)
                            }
                        },
                        onDetail: { detailNode = node },
                        onAddToBoard: { onAddNodes([node.id]) }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8))
                }

                // Tap empty space below list items to deselect all
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !selectedNodeIDs.isEmpty {
                            selectedNodeIDs.removeAll()
                        }
                    }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func sidebarToggleButton() -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isSidebarVisible.toggle()
            }
        } label: {
            Image(systemName: "sidebar.left")
                .font(.title2)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                #if os(visionOS)
                .background(.regularMaterial, in: .circle)
                #else
                .glassEffect(Glass.regular.interactive(), in: .circle)
                #endif
                .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .help(isSidebarVisible ? "Hide Backlog" : "Show Backlog")
    }
}

// MARK: - Sidebar Row

struct InvestigationSidebarRow: View {
    let node: InvestigationNode
    let isSelected: Bool
    let edgeCount: Int
    let scheme: ColorScheme
    let onTap: () -> Void
    let onDetail: () -> Void
    let onAddToBoard: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Selection toggle button
            Button { onTap() } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Category icon
            Image(systemName: node.category.systemImage)
                .font(.title3)
                .foregroundStyle(node.category.defaultColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(node.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if !node.subtitle.isEmpty {
                        Text(node.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if edgeCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.system(size: 8))
                            Text("\(edgeCount)")
                                .font(.caption2)
                        }
                        .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Info button for detail sheet
            Button {
                onDetail()
            } label: {
                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("View details")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : .clear)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        // Drag support — no .onTapGesture on the row so dragging works freely
        .draggable(node.transferData()) {
            HStack(spacing: 8) {
                Image(systemName: node.category.systemImage)
                    .font(.title3)
                    .foregroundStyle(node.category.defaultColor)
                Text(node.name)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            #if os(visionOS)
            .background(.regularMaterial, in: .rect(cornerRadius: 8))
            #else
            .glassEffect(Glass.regular, in: .rect(cornerRadius: 8))
            #endif
            .shadow(radius: 4)
        }
        // Swipe to add to board
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onAddToBoard()
            } label: {
                Label("Add to Board", systemImage: "plus.circle")
            }
            .tint(.green)
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(node.category.displayName), \(node.name)"))
        .accessibilityHint("Drag to add to board. Info button for details.")
    }
}

// MARK: - Gesture Blocking Modifier (mirrors Cumberland/SidebarPanel.swift)

extension View {
    @ViewBuilder
    func blockInvestigationCanvasGestures() -> some View {
        #if os(macOS)
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in }
                .onEnded { _ in }
        )
        #else
        self
        #endif
    }
}
