# Enhancement Request ER-0029: Consolidate Citation System with Service Layer

**Status:** ✅ Implemented - Verified (2026-02-12)
**Component:** Citation System Organization
**Priority:** Low
**Date Requested:** 2026-02-03
**Date Implemented:** 2026-02-12
**Date Verified:** 2026-02-12

---

## Summary

Consolidated the Citation system by reorganizing view files into subdirectories, creating a centralized CitationManager service that extracts duplicated CRUD operations from 5 view files, and adding citation visibility improvements including a read-only CitationSummaryView for card detail and relationship views.

## Implementation

**R1: Reorganize Citation Directory**
- Created `Citation/Views/` and `Citation/Services/` subdirectories
- Moved 7 view files from `Citation/` to `Citation/Views/`
- Model files (Citation.swift, Source.swift, CitationKind.swift, PendingAttribution.swift) remain in `Model/` for schema/migration coherence

**R2: CitationManager Service**
- Created `Citation/Services/CitationManager.swift` (~135 lines)
- Centralized citation and source CRUD operations
- API: createCitation, updateCitation, deleteCitation, fetchCitations, fetchImageCitations, createSource, fetchOrCreateSource, findSource

**R3: View Refactoring**
- Updated 5 view files to use CitationManager instead of direct modelContext operations

**R4: Build Configuration**
- Updated project.pbxproj membershipExceptions for iOS and visionOS targets

**R5: CitationViewer UI Improvements**
- Changed header from "Citations" to "Citations (double-click to edit)" for discoverability
- Added Edit button (blue, pencil icon) to swipe actions alongside existing Delete button
- Swipe left on any citation row now shows both Edit and Delete actions

**R6: CitationSummaryView — Read-Only Citation Summary**
- Created `Citation/Views/CitationSummaryView.swift` (~76 lines)
- Compact, read-only summary embedded in CardSheetView (Details tab) and CardRelationshipView (Relationships tab)
- Shows citation count with quote.bubble icon, up to 5 citations with color-coded dots by kind (quote=blue, paraphrase=green, image=orange, data=purple), source title (Chicago short format when available), locator, and "+ N more" overflow indicator
- Hidden when card has no citations (no visual noise)
- Uses SwiftData relationship property (`card.citations`) directly as a computed property — no manual fetching, no `.onAppear`/`.task` lifecycle issues
- Added to CardSheetView after CardSheetHeaderView, before Divider
- Added to CardRelationshipView after header GlassCard, before toolbar

## Files Created
- `Cumberland/Citation/Services/CitationManager.swift`
- `Cumberland/Citation/Views/CitationSummaryView.swift`

## Files Moved (Citation/ → Citation/Views/)
- CitationEditor.swift, CitationViewer.swift, ImageAttributionEditor.swift, ImageAttributionViewer.swift, QuickAttributionSheetEditor.swift, SourceDetailEditor.swift, SourceEditorSheet.swift

## Files Modified
- CitationEditor.swift — uses CitationManager
- CitationViewer.swift — uses CitationManager, updated header text, added Edit swipe action
- ImageAttributionEditor.swift — uses CitationManager
- ImageAttributionViewer.swift — uses CitationManager
- QuickAttributionSheetEditor.swift — uses CitationManager
- CardSheetView.swift — added CitationSummaryView
- CardRelationshipView.swift — added CitationSummaryView
- Cumberland.xcodeproj/project.pbxproj — iOS and visionOS membershipExceptions (CitationManager + all views including CitationSummaryView)

## Build Status
- macOS: BUILD SUCCEEDED
- iOS: BUILD SUCCEEDED

## Technical Note

CitationSummaryView reads `card.citations` directly via SwiftData's relationship property rather than using manual fetch operations with `.onAppear` or `.task(id:)`. This approach avoids SwiftUI view lifecycle timing issues where `.onAppear`/`.task` on conditionally-rendered views may not fire reliably on first card selection or tab switches.

---

*Verified: 2026-02-12*
