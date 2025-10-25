import SwiftUI

/// Sidebar/backlog panel for the Murder Board view, showing available cards for drag-and-drop.
/// Used from MurderBoardView.
struct BacklogSidebarPanel: View {
    let board: Board?
    let cards: [Card]
    @Binding var selection: Kinds?
    var onClose: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "tray.full")
                    .foregroundStyle(.secondary)
                Text("Backlog")
                    .font(.headline)
                Spacer(minLength: 8)
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Hide Backlog")
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)

            HStack(spacing: 6) {
                Image(systemName: selection == nil ? "line.3.horizontal.decrease.circle" : (selection?.systemImage ?? "line.3.horizontal.decrease.circle"))
                    .foregroundStyle(.secondary)
                Picker("Filter", selection: $selection) {
                    Text("All Kinds").tag(Kinds?.none)
                    ForEach(Kinds.orderedCases.filter { $0 != .structure }, id: \.self) { k in
                        Text(k.title).tag(Kinds?.some(k))
                    }
                }
                .pickerStyle(.menu)
                .help("Filter backlog by kind")
            }
            .padding(.horizontal, 10)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if cards.isEmpty {
                        Text("No cards to add.")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(cards, id: \.id) { card in
                            BacklogCardRow(card: card)
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
    }
}

// MARK: - Backlog Card Row

private struct BacklogCardRow: View {
    let card: Card
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Kind icon
            Image(systemName: card.kind.systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(card.kind.accentColor(for: scheme))
                .frame(width: 20, height: 20)
            
            // Card info
            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if !card.subtitle.isEmpty {
                    Text(card.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 8)
            
            // Thumbnail if available
            Group {
                if let data = card.thumbnailData {
                    #if canImport(UIKit)
                    if let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(.quaternary)
                    }
                    #elseif canImport(AppKit)
                    if let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(.quaternary)
                    }
                    #else
                    Rectangle()
                        .fill(.quaternary)
                    #endif
                } else {
                    Rectangle()
                        .fill(.quaternary)
                }
            }
            .frame(width: 32, height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.clear)
        )
        .contentShape(Rectangle())
        .onDrag {
            NSItemProvider(object: card.id.uuidString as NSString)
        }
    }
}
