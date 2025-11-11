//
//  MBSidebarPanel.swift
//  Cumberland
//
//  Created by Assistant on 11/1/25.
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
    
    // Data
    let backlogCards: [Card]
    let onAddSelectedCards: () -> Void
    
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
        .allowsHitTesting(true) // Allow interactions with sidebar and button
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
            sidebarCardsList()
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
                
                // Show count of filtered results and selection info
                let count = backlogCards.count
                let selectedCount = selectedBacklogCards.count
                
                HStack(spacing: 8) {
                    Text("^[\(count) card](inflect: true)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if selectedCount > 0 {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("^[\(selectedCount) selected](inflect: true)")
                            .font(.caption2)
                            .foregroundStyle(Color.accentColor)
                    }
                }
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func sidebarCardsList() -> some View {
        ScrollView {
            if backlogCards.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    
                    Text("No cards available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if selectedKindFilter != nil {
                        Text("Try changing the filter")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                LazyVStack(spacing: 1) {
                    ForEach(Array(backlogCards.enumerated()), id: \.element.id) { index, card in
                        SidebarCardRow(
                            card: card,
                            isSelected: selectedBacklogCards.contains(card.id),
                            scheme: scheme,
                            selectedBacklogCards: $selectedBacklogCards
                        )
                        .id("\(card.id)_\(index)") // Ensure unique IDs even with duplicate card IDs
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
        }
        .frame(maxHeight: .infinity)
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
    let scheme: ColorScheme
    @Binding var selectedBacklogCards: Set<UUID>
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Kind icon
            card.kind.symbolImage(filled: true)
                .font(.title3)
                .foregroundStyle(card.kind.accentColor(for: scheme))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                // Card name
                Text(card.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                // Card subtitle if available
                if !card.subtitle.isEmpty {
                    Text(card.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
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
        .onTapGesture {
            if isSelected {
                selectedBacklogCards.remove(card.id)
            } else {
                selectedBacklogCards.insert(card.id)
            }
        }
        .draggable(card.createTransferRepresentation()) {
            // Drag preview
            HStack(spacing: 8) {
                card.kind.symbolImage(filled: true)
                    .font(.title3)
                    .foregroundStyle(card.kind.accentColor(for: scheme))
                
                Text(card.name)
                    .font(.subheadline)
                    .lineLimit(1)
                
                if selectedBacklogCards.count > 1 && isSelected {
                    Text("+ \(selectedBacklogCards.count - 1) more")
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
        .onHover { hovering in
            // Subtle hover effect could be added here
        }
    }
}
