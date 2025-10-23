import SwiftUI
import SwiftData

struct CardView: View {
    // Bindable so changes to sizeCategory are persisted in SwiftData
    @Bindable var card: Card

    // Optional bottom-trailing decoration tab (e.g., relation type name)
    var decorationText: String? = nil

    @State private var thumbnail: Image?
    @Environment(\.colorScheme) private var scheme

    // MARK: - Tunable constants (adjust here later if needed)
    private let compactDetailLines: Int = 1
    private let standardDetailLines: Int = 5
    private let largeDetailLines: Int = 20

    // Optionally vary this by sizeCategory later if desired
    private let thumbnailSide: CGFloat = 72
    private let thumbnailTopPadding: CGFloat = 8 // add breathing room under the tab

    // Cap the card width to avoid single-line stretching of detail text (approx iPhone portrait width)
    private let maxCardWidth: CGFloat = 430

    // Tab appearance (manila folder style)
    private let tabCornerRadius: CGFloat = 8
    private let tabHeight: CGFloat = 22
    private let tabHorizontalPadding: CGFloat = 10
    private let tabVerticalPadding: CGFloat = 2
    private let tabOffsetTop: CGFloat = -10
    private let tabOffsetLeft: CGFloat = 12

    // Bottom decoration tab offsets (mirrors top tab feel)
    private let bottomTabOffsetY: CGFloat = 10
    private let bottomTabOffsetX: CGFloat = -12

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        // Subtle drop shadow that adapts to color scheme
        let shadowColor = Color.black.opacity(scheme == .dark ? 0.25 : 0.10)
        // Allowance so the overlay tab that’s offset upward is included in the view’s height
        let tabTopAllowance = max(0, -tabOffsetTop)
        // Allowance so the bottom-trailing decoration tab that’s offset downward is included in the view’s height
        let tabBottomAllowance = decorationText == nil ? 0 : max(0, bottomTabOffsetY)

        HStack(alignment: .top, spacing: 12) {
            thumbnailView
                .frame(width: thumbnailSide, height: thumbnailSide)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                }
                .padding(.top, thumbnailTopPadding) // space from the tab

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(card.name)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 8)

                    sizePicker
                }

                if let subtitleLine = subtitleAuthorLine, !subtitleLine.isEmpty {
                    Text(subtitleLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .accessibilityLabel(accessibleSubtitleAuthorLabel)
                }

                if !card.detailedText.isEmpty {
                    Text(card.detailedText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(detailLineLimit)
                        .truncationMode(.tail)
                }
            }

            Spacer(minLength: 0)
        }
        // Provide extra top/bottom padding so the offset tabs are included in layout height
        .padding(.top, 20 + tabTopAllowance)
        .padding(.horizontal, 20)
        .padding(.bottom, 20 + tabBottomAllowance)
        // Draw the card surface and give the card a subtle drop shadow
        .background(
            cardShape
                .fill(.background)
                .shadow(color: shadowColor, radius: 6, x: 0, y: 3)
        )
        // Inner (inset) thicker colored stroke around the card using the card.kind accent color
        .overlay(
            cardShape
                .strokeBorder(card.kind.accentColor(for: scheme), lineWidth: 12)
        )
        // Manila-style tab that blends into the card (now colored by kind)
        .overlay(alignment: .topLeading) {
            kindTab()
                .offset(x: tabOffsetLeft, y: tabOffsetTop)
                .accessibilityHidden(true)
        }
        // Optional bottom-trailing decoration tab
        .overlay(alignment: .bottomTrailing) {
            if let text = decorationText, !text.isEmpty {
                decorationTab(text: text)
                    .offset(x: bottomTabOffsetX, y: bottomTabOffsetY)
                    .accessibilityHidden(true)
            }
        }
        // Cap the overall width so long text doesn’t try to render on one line
        .frame(maxWidth: maxCardWidth, alignment: .topLeading)
        // Report the visual “card shape” size (excluding outer padding used only to accommodate tabs)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: CardViewVisualSizeKey.self,
                        value: {
                            // Whole view size includes outer padding we added explicitly:
                            // Horizontal: 20 (left) + 20 (right) = 40
                            // Vertical:   (20 + tabTopAllowance) + (20 + tabBottomAllowance)
                            let full = geo.size
                            let visualWidth = max(1, full.width - 40)
                            let visualHeight = max(1, full.height - ((20 + tabTopAllowance) + (20 + tabBottomAllowance)))
                            return [card.id: CGSize(width: visualWidth, height: visualHeight)]
                        }()
                    )
            }
        )
        .task(id: card.thumbnailData) {
            // Reload when the embedded thumbnail changes
            await loadThumbnail()
        }
        .task {
            // Initial load
            if thumbnail == nil {
                await loadThumbnail()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(card.name))
        .accessibilityHint(Text(subtitleAuthorHint))
    }

    // MARK: - Subviews

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail {
            thumbnail
                .resizable()
                .scaledToFit() // Preserve aspect ratio; no cropping
        } else {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var sizePicker: some View {
        // Map a Binding to the computed sizeCategory wrapper
        let binding = Binding<SizeCategory>(
            get: { card.sizeCategory },
            set: { card.sizeCategory = $0 }
        )
        return Picker("Size", selection: binding) {
            ForEach(SizeCategory.allCases, id: \.self) { sc in
                Text(sc.displayName).tag(sc)
            }
        }
        .pickerStyle(.menu) // drop-down style on macOS and iOS
        .accessibilityLabel("Card size")
    }

    // Manila folder-style tab showing the Kind, now colored by card.kind
    private func kindTab() -> some View {
        HStack(spacing: 6) {
            Image(systemName: card.kind.systemImage)
                .font(.caption2)
            Text(card.kind.title)
                .font(.caption).bold()
                .lineLimit(1)
        }
        .foregroundStyle(.primary.opacity(scheme == .dark ? 0.9 : 0.95))
        .padding(.horizontal, tabHorizontalPadding)
        .padding(.vertical, tabVerticalPadding)
        .frame(height: tabHeight)
        .background(
            RoundedRectangle(cornerRadius: tabCornerRadius, style: .continuous)
                .fill(card.kind.accentColor(for: scheme))
        )
        // No stroke/border on the tab
        // No shadow here to avoid appearing above the card
        .accessibilityLabel(Text(card.kind.title))
    }

    // Bottom-trailing decoration tab (mirrors style of kindTab)
    private func decorationTab(text: String) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.caption).bold()
                .lineLimit(1)
        }
        .foregroundStyle(.primary.opacity(scheme == .dark ? 0.9 : 0.95))
        .padding(.horizontal, tabHorizontalPadding)
        .padding(.vertical, tabVerticalPadding)
        .frame(height: tabHeight)
        .background(
            RoundedRectangle(cornerRadius: tabCornerRadius, style: .continuous)
                .fill(card.kind.accentColor(for: scheme))
        )
    }

    // MARK: - Derived values

    private var detailLineLimit: Int {
        switch card.sizeCategory {
        case .compact:  return compactDetailLines
        case .standard: return standardDetailLines
        case .large:    return largeDetailLines
        }
    }

    // Combine subtitle and author into one secondary line.
    // If both exist: "Subtitle • Author"
    // If only one exists, show that one.
    private var subtitleAuthorLine: String? {
        let subtitle = card.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let author = (card.author ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = [subtitle, author].filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " • ")
    }

    private var subtitleAuthorHint: String {
        let subtitle = card.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let author = (card.author ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !subtitle.isEmpty && !author.isEmpty {
            return "\(subtitle) by \(author)"
        } else if !subtitle.isEmpty {
            return subtitle
        } else if !author.isEmpty {
            return "by \(author)"
        } else {
            return ""
        }
    }

    private var accessibleSubtitleAuthorLabel: Text {
        let subtitle = card.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let author = (card.author ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !subtitle.isEmpty && !author.isEmpty {
            return Text("\(subtitle), by \(author)")
        } else if !subtitle.isEmpty {
            return Text(subtitle)
        } else if !author.isEmpty {
            return Text("by \(author)")
        } else {
            return Text("")
        }
    }

    // MARK: - Thumbnail loading

    @MainActor
    private func loadThumbnail() async {
        // Use the async helper on Card to avoid decoding on the main thread.
        let img = await card.makeThumbnailImage()
        withAnimation(.easeInOut(duration: 0.15)) {
            self.thumbnail = img
        }
    }
}

// MARK: - Visual size preference for hit-testing

struct CardViewVisualSizeKey: PreferenceKey {
    static var defaultValue: [UUID: CGSize] = [:]
    static func reduce(value: inout [UUID: CGSize], nextValue: () -> [UUID: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

#Preview("CardView - Size That Fits", traits: .sizeThatFitsLayout) {
    let sample = Card(
        name: "Exploration Project",
        subtitle: "Initial Planning",
        detailedText: "Define scope, risks, and milestones. Identify stakeholders and resources needed. This is a longer blurb to demonstrate how the size category limits the detail text lines in the view.",
        author: nil,
        sizeCategory: .standard
    )

    return VStack(spacing: 24) {
        CardView(card: sample)
        CardView(card: sample, decorationText: "references")
    }
    .padding()
    .modelContainer(for: Card.self, inMemory: true)
}

#Preview("CardView - Scroll Context") {
    let sample = Card(
        name: "Exploration Project",
        subtitle: "Initial Planning",
        detailedText: "Define scope, risks, and milestones. Identify stakeholders and resources needed. This is a longer blurb to demonstrate how the size category limits the detail text lines in the view.",
        author: "Alex Writer",
        sizeCategory: .standard
    )

    return ScrollView {
        VStack(spacing: 16) {
            CardView(card: sample)
            CardView(card: sample, decorationText: "creates")
        }
        .padding()
    }
    .frame(width: 420)
    .modelContainer(for: Card.self, inMemory: true)
}

