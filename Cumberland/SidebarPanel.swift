//
//  SidebarPanel.swift  (formerly MBSidebarPanel.swift)
//  Cumberland
//
//  Created by Assistant on 11/1/25.
//
//  Collapsible sidebar panel used in Murderboard and Structure Board contexts
//  to present a secondary content list (e.g., backlog cards or structure
//  element details) alongside the main canvas. Manages animated show/hide
//  transitions and adapts layout to the current canvas size.
//
//  ER-0031: Enhanced with detail navigation (tap), long-press multi-select,
//  swipe-to-pin, richer row metadata (edge count, pending-pin indicator),
//  and accessibility labels. ScrollView > LazyVStack converted to List for
//  swipe action support.
//

import SwiftUI
import SwiftData

// MARK: - Sidebar Backlog Panel

struct SidebarPanel: View {
    let contentSize: CGSize
    let scheme: ColorScheme

    // State bindings
    @Binding var isSidebarVisible: Bool
    @Binding var selectedKindFilter: Kinds?
    @Binding var selectedBacklogCards: Set<UUID>
    @Binding var detailCard: Card?

    // ER-0032: Search and sort bindings
    @Binding var searchText: String
    @Binding var sortOption: BacklogSortOption
    let hasActiveSearch: Bool

    // Data
    let backlogCards: [Card]
    let pendingPinCardIDs: Set<UUID>
    let onAddSelectedCards: () -> Void
    let onTogglePin: (Card) -> Void

    // ER-0032: Track last selected index for shift-click range selection
    @State private var lastSelectedIndex: Int? = nil

    var body: some View {
        HStack {
            // Sidebar panel (0580, 0590)
            if isSidebarVisible {
                ZStack(alignment: .topTrailing) {
                    sidebarPanel()
                        .frame(width: min(320, contentSize.width * 0.35))
                        .transition(.move(edge: .leading).combined(with: .opacity))

                    // Toggle button positioned at top trailing of the sidebar panel (0660)
                    sidebarToggleButton()
                        .padding(.top, 8)
                        .padding(.trailing, 8)
                }
            }

            Spacer()

            // Toggle button when sidebar is hidden (0670: visible even if sidebar is hidden)
            // 0662: When not visible, appears as floating in upper left corner
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
        // DR-0083 / DR-0085: Allow hit testing only on the sidebar content itself.
        // Do NOT use .contentShape(Rectangle()) on the full HStack — the Spacer() fills
        // the entire canvas width and would swallow all touches on iOS (where SwiftUI
        // hit testing governs gesture delivery, unlike macOS which uses NSEvent monitors).
        .allowsHitTesting(true)
    }

    // MARK: - Helpers

    private func edgeCount(for card: Card) -> Int {
        (card.outgoingEdges?.count ?? 0) + (card.incomingEdges?.count ?? 0)
    }

    // ER-0032: Standard platform selection metaphor
    private func handleSelection(card: Card, index: Int, modifiers: EventModifiers) {
        #if os(macOS)
        if modifiers.contains(.command) {
            // Cmd+click: toggle this item
            if selectedBacklogCards.contains(card.id) {
                selectedBacklogCards.remove(card.id)
            } else {
                selectedBacklogCards.insert(card.id)
            }
            lastSelectedIndex = index
        } else if modifiers.contains(.shift), let anchor = lastSelectedIndex {
            // Shift+click: range select from anchor to this index
            let lo = min(anchor, index)
            let hi = max(anchor, index)
            for i in lo...hi {
                if i < backlogCards.count {
                    selectedBacklogCards.insert(backlogCards[i].id)
                }
            }
        } else {
            // Plain click on selected node: deselect all
            if selectedBacklogCards.contains(card.id) {
                selectedBacklogCards.removeAll()
                lastSelectedIndex = nil
            } else {
                selectedBacklogCards = [card.id]
                lastSelectedIndex = index
            }
        }
        #else
        // iOS/visionOS: tap on selected deselects all, otherwise selects one
        if selectedBacklogCards.contains(card.id) {
            selectedBacklogCards.removeAll()
            lastSelectedIndex = nil
        } else {
            selectedBacklogCards = [card.id]
            lastSelectedIndex = index
        }
        #endif
    }
}

// MARK: - Gesture Blocking Modifier (DR-0083)

extension View {
    /// On macOS: consumes drag gestures on the sidebar so trackpad scroll doesn't
    /// propagate to canvas gesture recognizers via SwiftUI's gesture system.
    /// On iOS/iPadOS: this is a no-op. The canvas uses UIKit gesture recognizers
    /// (UIPanGestureRecognizer with minimumNumberOfTouches=2) which are independent
    /// of SwiftUI gesture propagation. Adding a competing DragGesture here breaks
    /// two-finger pan on both the sidebar and the canvas (DR-0085).
    @ViewBuilder
    func blockCanvasGestures() -> some View {
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

// MARK: - Sidebar Panel Implementation

extension SidebarPanel {
    @ViewBuilder
    private func sidebarPanel() -> some View {
        VStack(spacing: 0) {
            // Header with kind filter (0620, 0630)
            sidebarHeader()

            Divider()

            // Cards list (0600, 0610, 0650)
            // DR-0083: blockCanvasGestures() consumes drag gestures on the scroll view so
            // macOS trackpad scroll doesn't propagate to the canvas behind the panel.
            // DR-0085: Applied here on the panel content only (not the outer HStack) so the
            // Spacer() beside the panel does NOT become hittable and swallow iOS touches.
            sidebarCardsList()
                .contentShape(Rectangle())
                .blockCanvasGestures()
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
            // Top row: title, selection actions, kind filter, sort
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Backlog")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("^[\(backlogCards.count) card](inflect: true)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Selection actions
                if !selectedBacklogCards.isEmpty {
                    Menu {
                        Button("Add Selected to Board", systemImage: "plus.circle") {
                            onAddSelectedCards()
                        }
                        .disabled(selectedBacklogCards.isEmpty)

                        Divider()

                        Button("Clear Selection", systemImage: "xmark.circle") {
                            selectedBacklogCards.removeAll()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                    }
                    .menuStyle(.borderlessButton)
                    .help("Actions for selected cards")
                }

                // Kind filter picker (0620, 0630, 0640)
                Menu {
                    Button("All Kinds") {
                        selectedKindFilter = nil
                    }
                    .disabled(selectedKindFilter == nil)

                    Divider()

                    ForEach(Kinds.orderedCases) { kind in
                        Button {
                            selectedKindFilter = kind == selectedKindFilter ? nil : kind
                        } label: {
                            HStack {
                                kind.symbolImage()
                                Text(kind.title)
                                if selectedKindFilter == kind {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if let filter = selectedKindFilter {
                            filter.symbolImage()
                                .font(.caption)
                                .foregroundStyle(filter.accentColor(for: scheme))
                            Text(filter.title)
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
                    .foregroundStyle(selectedKindFilter != nil ? .primary : .secondary)
                }
                .menuStyle(.borderlessButton)

                // ER-0032: Sort picker
                Menu {
                    ForEach(BacklogSortOption.allCases) { option in
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

                TextField("Search cards…", text: $searchText)
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
    private func sidebarCardsList() -> some View {
        if backlogCards.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: hasActiveSearch ? "magnifyingglass" : "tray")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text(hasActiveSearch ? "No matching cards" : "No cards available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if hasActiveSearch || selectedKindFilter != nil {
                    Text("Try changing the search or filter")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
        } else {
            List {
                ForEach(Array(backlogCards.enumerated()), id: \.element.id) { index, card in
                    SidebarCardRow(
                        card: card,
                        isSelected: selectedBacklogCards.contains(card.id),
                        isPendingPin: pendingPinCardIDs.contains(card.id),
                        edgeCount: edgeCount(for: card),
                        scheme: scheme,
                        selectedCount: selectedBacklogCards.count,
                        onSelect: { modifiers in
                            handleSelection(card: card, index: index, modifiers: modifiers)
                        },
                        onDetail: { detailCard = card },
                        onTogglePin: { onTogglePin(card) }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8))
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
            // Consistent icon for both states
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

// MARK: - Sidebar Card Row

struct SidebarCardRow: View {
    let card: Card
    let isSelected: Bool
    let isPendingPin: Bool
    let edgeCount: Int
    let scheme: ColorScheme
    let selectedCount: Int

    // Callbacks
    let onSelect: (EventModifiers) -> Void
    let onDetail: () -> Void
    let onTogglePin: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Kind icon
            card.kind.symbolImage(filled: true)
                .font(.title3)
                .foregroundStyle(card.kind.accentColor(for: scheme))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                // Card name with optional pin indicator
                HStack(spacing: 4) {
                    Text(verbatim: card.name)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if isPendingPin {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                // Subtitle + metadata row
                HStack(spacing: 6) {
                    if !card.subtitle.isEmpty {
                        Text(verbatim: card.subtitle)
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

            // Info button for detail sheet (ER-0032: replaces tap-for-detail)
            Button {
                onDetail()
            } label: {
                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("View details")

            // Small thumbnail if available (0650)
            AsyncImage(url: card.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } placeholder: {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : .clear)
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
        // ER-0031: Swipe-to-pin (pending pin for backlog cards)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onTogglePin()
            } label: {
                Label(isPendingPin ? "Unpin" : "Pin", systemImage: isPendingPin ? "pin.slash" : "pin")
            }
            .tint(.orange)
        }
        // Drag support (preserved from original)
        .draggable(card.createTransferRepresentation()) {
            // Drag preview
            HStack(spacing: 8) {
                card.kind.symbolImage(filled: true)
                    .font(.title3)
                    .foregroundStyle(card.kind.accentColor(for: scheme))

                Text(verbatim: card.name)
                    .font(.subheadline)
                    .lineLimit(1)

                if selectedCount > 1 && isSelected {
                    Text("+ \(selectedCount - 1) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
        // Accessibility (ER-0031)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Click to select. Command-click for multi-select. Info button for details.")
    }

    private var accessibilityLabel: Text {
        var parts: [String] = [card.kind.singularTitle, card.name]
        if !card.subtitle.isEmpty { parts.append(card.subtitle) }
        if edgeCount > 0 { parts.append("\(edgeCount) relationships") }
        if isPendingPin { parts.append("Will be pinned") }
        return Text(parts.joined(separator: ", "))
    }
}

// MARK: - Modifier-Aware Tap Gesture (ER-0032)

/// A view modifier that detects tap gestures along with keyboard modifiers.
/// On macOS, provides Command and Shift modifier detection for standard
/// multi-select behavior. On iOS/visionOS, always reports empty modifiers.
extension View {
    func onModifierTap(perform action: @escaping (EventModifiers) -> Void) -> some View {
        modifier(CumberlandModifierTapGesture(action: action))
    }
}

private struct CumberlandModifierTapGesture: ViewModifier {
    let action: (EventModifiers) -> Void

    #if os(macOS)
    func body(content: Content) -> some View {
        content.overlay {
            CumberlandModifierTapOverlay(action: action)
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

private struct CumberlandModifierTapOverlay: NSViewRepresentable {
    let action: (EventModifiers) -> Void

    func makeNSView(context: Context) -> CumberlandModifierTapNSView {
        let view = CumberlandModifierTapNSView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: CumberlandModifierTapNSView, context: Context) {
        nsView.action = action
    }
}

class CumberlandModifierTapNSView: NSView {
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
        return frame.contains(point) ? self : nil
    }
}
#endif
