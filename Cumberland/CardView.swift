//
//  CardView.swift
//  Cumberland
//
//  Compact card thumbnail tile used in grid and list contexts. Displays the
//  card thumbnail image, name, kind badge, AI-generated badge (ER-0009),
//  size category, and an optional decoration text tab. Supports three size
//  categories (small, medium, large) persisted per card via SwiftData.
//

import SwiftUI
import SwiftData

struct CardView: View {
    // Bindable so changes to sizeCategory are persisted in SwiftData
    @Bindable var card: Card

    // Optional bottom-trailing decoration tab (e.g., relation type name)
    var decorationText: String? = nil

    // Control whether AI badge is shown (ER-0009)
    // Set to false in small card contexts (Murderboard, Relationship graphs)
    var showAIBadge: Bool = true

    @State private var thumbnail: Image?
    @State private var showAIImageInfo: Bool = false
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var themeManager: ThemeManager

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
        let theme = themeManager.currentTheme
        let cardShape = RoundedRectangle(cornerRadius: theme.shapes.cardCornerRadius, style: .continuous)
        // Subtle drop shadow that adapts to color scheme
        let shadows = theme.shadows
        let shadowColor = shadows.cardColor.opacity(scheme == .dark ? shadows.cardDarkOpacity : shadows.cardLightOpacity)
        // Allowance so the overlay tab that’s offset upward is included in the view’s height
        let tabTopAllowance = max(0, -tabOffsetTop)
        // Allowance so the bottom-trailing decoration tab that’s offset downward is included in the view’s height
        let tabBottomAllowance = decorationText == nil ? 0 : max(0, bottomTabOffsetY)
        
        HStack(alignment: .top, spacing: 12) {
            thumbnailView
                .frame(width: thumbnailSide, height: thumbnailSide)
                .clipShape(RoundedRectangle(cornerRadius: theme.shapes.thumbnailCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: theme.shapes.thumbnailCornerRadius, style: .continuous)
                        .stroke(theme.colors.border, lineWidth: 1)
                }
                .padding(.top, thumbnailTopPadding) // space from the tab
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: card.name)
                        .font(theme.fonts.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer(minLength: 8)
                    
                    sizePicker
                }
                
                if let subtitleLine = subtitleAuthorLine, !subtitleLine.isEmpty {
                    Text(subtitleLine)
                        .font(theme.fonts.subheadline)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .accessibilityLabel(accessibleSubtitleAuthorLabel)
                }

                if !card.detailedText.isEmpty {
                    Text(verbatim: card.detailedText)
                        .font(theme.fonts.footnote)
                        .foregroundStyle(theme.colors.textSecondary)
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
                .fill(theme.colors.cardBackground)
                .shadow(color: shadowColor, radius: shadows.cardRadius - 2, x: shadows.cardX, y: shadows.cardY - 1)
        )
        // Cap the overall width so long text doesn’t try to render on one line
        .frame(maxWidth: maxCardWidth, alignment: .topLeading)
        
        .overlay(
            GeometryReader { geo in
                cardShape
                    .strokeBorder(card.kind.accentColor(for: scheme), lineWidth: 12)
                    .preference(
                        key: CardViewActualSizeKey.self,
                        value: {
                            // Whole view size does not include the outer padding of the container hosting this overlay.
                            let full = geo.size
                            return [card.id: full]
                        }()
                    )
            }
        )
        // Manila-style tab that blends into the card (now colored by kind)
        .overlay(alignment: .topLeading) {
            GeometryReader { geo in
                kindTab()
                    .offset(x: tabOffsetLeft, y: tabOffsetTop)
                    .accessibilityHidden(true)
                    .preference(
                        key: CardViewVisualSizeKey.self,
                        value: {
                            // The GeometryReader here sees the rendered size
                            // including the paddings we added above.  The size
                            // needs to include the borders and extras we added here.
                            //
                            let full = geo.size
                            let visualWidth = max(1, full.width)
                            let visualHeight = max(1, full.height)
                            return [card.id: CGSize(width: visualWidth, height: visualHeight)]
                        }()
                    )
            }
        }
        // Optional bottom-trailing decoration tab
        .overlay(alignment: .bottomTrailing) {
            if let text = decorationText, !text.isEmpty {
                decorationTab(text: text)
                    .offset(x: bottomTabOffsetX, y: bottomTabOffsetY)
                    .accessibilityHidden(true)
            }
        }
        // Inner (inset) thicker colored stroke around the card using the card.kind accent color
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
        .accessibilityLabel(Text(verbatim: card.name))
        .accessibilityHint(Text(subtitleAuthorHint))
        // Present AI Image Info panel (ER-0009)
        .sheet(isPresented: $showAIImageInfo) {
            AIImageInfoView(card: card)
                .environmentObject(themeManager)
        }
    } //end var body

    // MARK: - Subviews

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail {
            thumbnail
                .resizable()
                .scaledToFit() // Preserve aspect ratio; no cropping
                .fullSizeImageGesture(for: card)
                .overlay(alignment: .topTrailing) {
                    // AI attribution badge (ER-0009)
                    if showAIBadge && card.imageGeneratedByAI == true {
                        aiAttributionBadge
                    }
                }
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

    /// AI attribution badge for AI-generated images (ER-0009)
    private var aiAttributionBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 8))
            Text("AI")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color.purple.gradient)
        )
        .shadow(radius: 1)
        .padding(3)
        .help(aiAttributionTooltip)
        .onTapGesture {
            showAIImageInfo = true
        }
    }

    /// Tooltip text for AI attribution
    private var aiAttributionTooltip: String {
        var parts: [String] = ["AI Generated"]

        if let provider = card.imageAIProvider {
            parts.append("Provider: \(provider)")
        }

        if let date = card.imageAIGeneratedAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            parts.append("Generated: \(formatter.string(from: date))")
        }

        if let prompt = card.imageAIPrompt, !prompt.isEmpty {
            parts.append("Tap for details")
        }

        return parts.joined(separator: "\n")
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

struct CardViewActualSizeKey: PreferenceKey {
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
    .environmentObject(ThemeManager())
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
    .environmentObject(ThemeManager())
}
