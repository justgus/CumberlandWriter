//
//  PendingAttribution.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//  Extracted to shared type to avoid duplication
//
//  Transient value type representing a pending image attribution that needs
//  user confirmation. Carries the image data, optional source URL, and
//  optional excerpt, shared between CardEditorDropHandler and
//  CardSheetDropHandler to trigger the QuickAttributionSheet.
//

import Foundation

/// Pending attribution information for dropped content
struct PendingAttribution: Identifiable, Equatable {
    let id = UUID()
    let kind: CitationKind
    let suggestedURL: URL?
    let prefilledExcerpt: String?
}
