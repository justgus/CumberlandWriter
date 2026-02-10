//
//  AdaptiveToolbar.swift
//  Cumberland
//
//  Extracted from CardSheetView.swift as part of ER-0022 Phase 3.2.
//  Reusable adaptive toolbar that measures available width and automatically
//  moves excess items into an overflow "More" menu. Supports keyboard
//  shortcuts and optional dividers between item groups.
//

import SwiftUI

/// An adaptive toolbar that automatically moves items to an overflow menu when space is limited
struct AdaptiveToolbar: View {
    struct Item: Identifiable, Hashable {
        /// Keyboard shortcut wrapper to avoid tuple in associated values
        struct Shortcut: Hashable {
            let key: String
            let modifiers: EventModifiers

            init(key: String, modifiers: EventModifiers) {
                self.key = key
                self.modifiers = modifiers
            }

            static func == (lhs: Shortcut, rhs: Shortcut) -> Bool {
                lhs.key == rhs.key && lhs.modifiers == rhs.modifiers
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(key)
                hasher.combine(modifiers.rawValue)
            }
        }

        enum Kind: Hashable {
            case button(id: String, systemImage: String, title: String?, shortcut: Shortcut?)
            case divider
        }

        let id: String
        let kind: Kind
        let action: (() -> Void)?

        static func button(
            id: String,
            systemImage: String,
            title: String? = nil,
            shortcut: Shortcut?,
            action: @escaping () -> Void
        ) -> Item {
            Item(
                id: id,
                kind: .button(id: id, systemImage: systemImage, title: title, shortcut: shortcut),
                action: action
            )
        }

        static var divider: Item {
            Item(id: UUID().uuidString, kind: .divider, action: nil)
        }

        static func == (lhs: Item, rhs: Item) -> Bool {
            lhs.id == rhs.id && lhs.kind == rhs.kind
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(kind)
        }
    }

    let items: [Item]
    var spacing: CGFloat = 8
    var dividerHeight: CGFloat = 18

    @State private var widths: [Int: CGFloat] = [:]
    @State private var availableWidth: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let avail = proxy.size.width
            content(available: avail)
                .onAppear { availableWidth = avail }
                .onChange(of: avail) { _, new in availableWidth = new }
        }
        .frame(height: 32)
    }

    @ViewBuilder
    private func content(available: CGFloat) -> some View {
        measurementRow
            .opacity(0)
            .accessibilityHidden(true)
            .overlay {
                visibleRow(available: available)
            }
    }

    private var measurementRow: some View {
        HStack(spacing: spacing) {
            ForEach(items.indices, id: \.self) { idx in
                toolbarItemView(for: items[idx], index: idx, measuring: true)
            }
        }
        .background(WidthPreferenceReader())
        .onPreferenceChange(WidthPreferenceKey.self) { value in
            widths = value
        }
    }

    private func visibleRow(available: CGFloat) -> some View {
        let layout = computeLayout(available: available)
        return HStack(spacing: spacing) {
            ForEach(layout.visibleIndices, id: \.self) { idx in
                toolbarItemView(for: items[idx], index: idx, measuring: false)
            }
            if !layout.overflowIndices.isEmpty {
                Menu {
                    ForEach(layout.overflowIndices, id: \.self) { idx in
                        switch items[idx].kind {
                        case .button(_, let systemImage, let title, _):
                            Button {
                                items[idx].action?()
                            } label: {
                                Label(title ?? "", systemImage: systemImage)
                            }
                        case .divider:
                            Divider()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.automatic)
            }
            Spacer(minLength: 0)
        }
    }

    private func toolbarItemView(for item: Item, index: Int, measuring: Bool) -> some View {
        Group {
            switch item.kind {
            case .button(_, let systemImage, _, let shortcut):
                let button = Button(action: { item.action?() }) {
                    Label("", systemImage: systemImage)
                }
                .buttonStyle(.bordered)
                .labelStyle(.iconOnly)
                .keyboardShortcutIfPresent(shortcut)

                if measuring {
                    button.overlay(SizeReporter(index: index))
                } else {
                    button
                }

            case .divider:
                let divider = Divider().frame(height: dividerHeight)
                if measuring {
                    divider.overlay(SizeReporter(index: index))
                } else {
                    divider
                }
            }
        }
    }

    private func computeLayout(available: CGFloat) -> (visibleIndices: [Int], overflowIndices: [Int]) {
        guard !widths.isEmpty else {
            return (Array(items.indices), [])
        }

        let overflowWidth: CGFloat = 28

        var used: CGFloat = 0
        var visible: [Int] = []
        var overflow: [Int] = []

        func canAppend(_ idx: Int, to array: [Int]) -> Bool {
            switch items[idx].kind {
            case .divider:
                if array.isEmpty { return false }
                if let last = array.last, case .divider = items[last].kind { return false }
                return true
            default:
                return true
            }
        }

        let totalCount = items.count
        for idx in 0..<totalCount {
            let w = widths[idx] ?? 0
            let needsOverflow = (idx < totalCount - 1)
            let spaceNeeded = w + (visible.isEmpty ? 0 : spacing) + (needsOverflow ? (overflowWidth + spacing) : 0)

            if used + spaceNeeded <= available {
                if canAppend(idx, to: visible) {
                    used += (visible.isEmpty ? 0 : spacing) + w
                    visible.append(idx)
                }
            } else {
                overflow.append(idx)
            }
        }

        // Trim trailing divider from visible
        while let last = visible.last, case .divider = items[last].kind {
            _ = visible.popLast()
        }

        // Remove leading divider in overflow
        while let first = overflow.first, case .divider = items[first].kind {
            overflow.removeFirst()
        }

        // Remove consecutive dividers in overflow
        var cleanedOverflow: [Int] = []
        for idx in overflow {
            if case .divider = items[idx].kind,
               let last = cleanedOverflow.last,
               case .divider = items[last].kind {
                continue
            }
            cleanedOverflow.append(idx)
        }

        return (visible, cleanedOverflow)
    }
}

// MARK: - Measurement Helpers

private struct SizeReporter: View {
    let index: Int

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: WidthPreferenceKey.self, value: [index: geo.size.width])
        }
    }
}

private struct WidthPreferenceReader: View {
    var body: some View {
        GeometryReader { _ in
            Color.clear
        }
    }
}

private struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]

    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

// MARK: - Keyboard Shortcut Extension

extension View {
    @ViewBuilder
    func keyboardShortcutIfPresent(_ shortcut: AdaptiveToolbar.Item.Shortcut?) -> some View {
        #if os(macOS) || os(iOS)
        if let shortcut {
            self.keyboardShortcut(KeyEquivalent(Character(shortcut.key)), modifiers: shortcut.modifiers)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
