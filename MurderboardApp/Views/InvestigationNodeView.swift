//
//  InvestigationNodeView.swift
//  MurderboardApp
//
//  Custom node tile provided via @ViewBuilder to BoardCanvasView.
//  Displays the node name, subtitle, category icon, and accent color.
//

import SwiftUI
import BoardEngine

// MARK: - Investigation Node View

struct InvestigationNodeView: View {
    let node: InvestigationNodeWrapper
    let isSelected: Bool
    let scheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: node.categorySystemImage)
                    .font(.title3)
                    .foregroundStyle(node.accentColor(for: scheme))

                VStack(alignment: .leading, spacing: 2) {
                    Text(node.displayName)
                        .font(.headline)
                        .lineLimit(2)

                    if !node.subtitle.isEmpty {
                        Text(node.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 200, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isSelected ? node.accentColor(for: scheme) : .clear,
                    lineWidth: isSelected ? 3 : 0
                )
        )
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.4 : 0.15),
            radius: isSelected ? 8 : 4,
            y: 2
        )
    }
}
