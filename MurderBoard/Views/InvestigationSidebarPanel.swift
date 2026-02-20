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
//  ER-0032: Search, sort, and standard platform selection metaphor.
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

    // ER-0032: Search and sort bindings
    @Binding var searchText: String
    @Binding var sortOption: InvestigationBacklogSortOption
    let hasActiveSearch: Bool

    // Data
    let backlogNodes: [InvestigationNode]
    let edgeCountProvider: (UUID) -> Int
    let onAddNodes: ([UUID]) -> Void

    // ER-0032: Track last selected index for shift-click range selection
    @State private var lastSelectedIndex: Int? = nil

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

    // MARK: - Selection Helpers (ER-0032: Standard platform metaphor)

    /// Handle a click/tap on a node row with modifier key awareness.
    /// - macOS: click = select one, cmd+click = toggle, shift+click = range
    /// - iOS/visionOS: tap = select one (toggle if already selected)
    private func handleSelection(node: InvestigationNode, index: Int, modifiers: EventModifiers) {
        #if os(macOS)
        if modifiers.contains(.command) {
            // Cmd+click: toggle this item
            if selectedNodeIDs.contains(node.id) {
                selectedNodeIDs.remove(node.id)
            } else {
                selectedNodeIDs.insert(node.id)
            }
            lastSelectedIndex = index
        } else if modifiers.contains(.shift), let anchor = lastSelectedIndex {
            // Shift+click: range select from anchor to this index
            let lo = min(anchor, index)
            let hi = max(anchor, index)
            for i in lo...hi {
                if i < backlogNodes.count {
                    selectedNodeIDs.insert(backlogNodes[i].id)
                }
            }
        } else {
            // Plain click on selected node: deselect all
            if selectedNodeIDs.contains(node.id) {
                selectedNodeIDs.removeAll()
                lastSelectedIndex = nil
            } else {
                selectedNodeIDs = [node.id]
                lastSelectedIndex = index
            }
        }
        #else
        // iOS/visionOS: tap on selected deselects all, otherwise selects one
        if selectedNodeIDs.contains(node.id) {
            selectedNodeIDs.removeAll()
            lastSelectedIndex = nil
        } else {
            selectedNodeIDs = [node.id]
            lastSelectedIndex = index
        }
        #endif
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
        VStack(spacing: 8) {
            // Top row: title, actions, category filter, sort
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Backlog")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("^[\(backlogNodes.count) node](inflect: true)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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

                // ER-0032: Sort picker
                Menu {
                    ForEach(InvestigationBacklogSortOption.allCases) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.systemImage)
                                Text(option.label)
                                if sortOption == option {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                        Text(sortOption.label)
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(sortOption != .nameAscending ? .primary : .secondary)
                }
                .menuStyle(.borderlessButton)
            }

            // ER-0032: Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Search nodes…", text: $searchText)
                    .font(.subheadline)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.quaternary)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func sidebarNodesList() -> some View {
        if backlogNodes.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: hasActiveSearch ? "magnifyingglass" : "tray")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text(hasActiveSearch ? "No matching nodes" : "No nodes in backlog")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if hasActiveSearch || selectedCategoryFilter != nil {
                    Text("Try changing the search or filter")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
        } else {
            List {
                ForEach(Array(backlogNodes.enumerated()), id: \.element.id) { index, node in
                    InvestigationSidebarRow(
                        node: node,
                        isSelected: selectedNodeIDs.contains(node.id),
                        edgeCount: edgeCountProvider(node.id),
                        scheme: scheme,
                        onSelect: { modifiers in
                            handleSelection(node: node, index: index, modifiers: modifiers)
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
    let onSelect: (EventModifiers) -> Void
    let onDetail: () -> Void
    let onAddToBoard: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
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
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.3) : .clear, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        // ER-0032: Standard selection — modifier-aware click/tap
        .onModifierTap { modifiers in
            onSelect(modifiers)
        }
        // Drag support
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
        .accessibilityHint("Click to select. Drag to add to board. Info button for details.")
    }
}

// MARK: - Modifier-Aware Tap Gesture

/// A view modifier that detects tap gestures along with keyboard modifiers.
/// On macOS, provides Command and Shift modifier detection for standard
/// multi-select behavior. On iOS/visionOS, always reports empty modifiers.
extension View {
    func onModifierTap(perform action: @escaping (EventModifiers) -> Void) -> some View {
        modifier(ModifierTapGesture(action: action))
    }
}

private struct ModifierTapGesture: ViewModifier {
    let action: (EventModifiers) -> Void

    #if os(macOS)
    func body(content: Content) -> some View {
        content.overlay {
            ModifierTapOverlay(action: action)
        }
    }
    #else
    func body(content: Content) -> some View {
        content.onTapGesture {
            action([])
        }
    }
    #endif
}

#if os(macOS)
import AppKit

private struct ModifierTapOverlay: NSViewRepresentable {
    let action: (EventModifiers) -> Void

    func makeNSView(context: Context) -> ModifierTapNSView {
        let view = ModifierTapNSView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: ModifierTapNSView, context: Context) {
        nsView.action = action
    }
}

private class ModifierTapNSView: NSView {
    var action: ((EventModifiers) -> Void)?

    override func mouseDown(with event: NSEvent) {
        var modifiers: EventModifiers = []
        if event.modifierFlags.contains(.command) { modifiers.insert(.command) }
        if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }
        action?(modifiers)
        // Pass through so .draggable() and other gestures still work
        super.mouseDown(with: event)
    }

    // Allow the view to be transparent to hit-testing for drags
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Only intercept clicks; let drag events pass through
        return frame.contains(point) ? self : nil
    }
}
#endif

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
