//
//  CardEditorViewModel.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//
//  @Observable view model for CardEditorView. Manages mutable form state
//  (name, subtitle, details, selected kind, image data, Photos picker item,
//  selected calendar system) and provides async image-loading helpers that
//  bridge PhotosUI and the ImageProcessingService.
//

import Foundation
import SwiftUI
import SwiftData
import PhotosUI

/// ViewModel for CardEditorView, extracting business logic and state management.
/// Reduces CardEditorView from 2,666 lines to ~800 lines.
///
/// **ER-0022 Phase 3**: Extracts business logic from CardEditorView
@Observable
@MainActor
final class CardEditorViewModel {

    // MARK: - Dependencies

    var modelContext: ModelContext?
    private var cardRepository: CardRepository?
    private var relationshipManager: RelationshipManager?
    private var imageProcessingService: ImageProcessingService

    // MARK: - Card Data State

    var name: String = ""
    var subtitle: String = ""
    var author: String = ""
    var detailedText: String = ""
    var sizeCategory: SizeCategory = .standard

    // MARK: - Image State

    var imageData: Data?
    var thumbnail: Image?
    var isWorking: Bool = false
    var imageMetadata: ImageMetadataExtractor.ImageMetadata?

    // MARK: - Image Import State

    var isImportingImage: Bool = false
    var selectedPhotoItem: PhotosPickerItem?
    var isFlipped: Bool = false
    var showFullSizeImage: Bool = false

    // MARK: - AI Image Generation State

    var showAIImageGeneration: Bool = false
    var showAIImageInfo: Bool = false
    var showImageHistory: Bool = false

    // MARK: - Analysis State

    var descriptionAnalysis: DescriptionAnalyzer.AnalysisResult?
    var showAnalysisSuggestions: Bool = false
    var isAnalyzing: Bool = false
    var analysisSuggestions: SuggestionEngine.Suggestions?
    var analysisError: String?
    var showAnalysisError: Bool = false

    // MARK: - Clipboard State

    var showCopyFeedback: Bool = false
    var showPasteFeedback: Bool = false
    var clipboardHasImage: Bool = false

    // MARK: - Relationship Suggestions State

    var pendingRelationships: [SuggestionEngine.RelationshipSuggestion] = []

    // MARK: - Attribution State

    var pendingAttribution: PendingAttribution?

    // MARK: - Structure Creation State (for Scenes)

    var attachStructure: Bool = true
    var structureSource: StructureSource = .template
    var selectedTemplateIndex: Int = 0
    var structureName: String = ""
    var editableElements: [EditableElement] = []
    var isReordering: Bool = false

    // MARK: - Calendar State (for Timeline cards)

    var selectedCalendar: CalendarSystem?
    var epochDate: Date?
    var epochDescription: String = ""

    // MARK: - Initialization

    init(
        modelContext: ModelContext?,
        cardRepository: CardRepository? = nil,
        relationshipManager: RelationshipManager? = nil,
        imageProcessingService: ImageProcessingService? = nil
    ) {
        self.modelContext = modelContext
        self.cardRepository = cardRepository
        self.relationshipManager = relationshipManager
        self.imageProcessingService = imageProcessingService ?? ImageProcessingService.shared

        // If modelContext is provided, initialize repositories
        if let modelContext = modelContext {
            if self.cardRepository == nil {
                self.cardRepository = CardRepository(modelContext: modelContext)
            }
            if self.relationshipManager == nil {
                self.relationshipManager = RelationshipManager(modelContext: modelContext)
            }
        }
    }

    // MARK: - Late Initialization

    /// Update the modelContext after initialization (e.g., from environment)
    func setModelContext(_ modelContext: ModelContext) {
        self.modelContext = modelContext
        if self.cardRepository == nil {
            self.cardRepository = CardRepository(modelContext: modelContext)
        }
        if self.relationshipManager == nil {
            self.relationshipManager = RelationshipManager(modelContext: modelContext)
        }
    }

    // MARK: - Card Setup

    /// Load card data into the view model
    /// - Parameter card: The card to edit
    func loadCard(_ card: Card) {
        self.name = card.name
        self.subtitle = card.subtitle
        self.author = card.author ?? ""
        self.detailedText = card.detailedText
        self.sizeCategory = card.sizeCategory

        // Load image if present
        if let originalImageData = card.originalImageData {
            self.imageData = originalImageData
            #if os(macOS)
            if let nsImage = NSImage(data: originalImageData) {
                self.thumbnail = Image(nsImage: nsImage)
            }
            #else
            if let uiImage = UIImage(data: originalImageData) {
                self.thumbnail = Image(uiImage: uiImage)
            }
            #endif
        }

        // Load calendar data if timeline card
        if card.kind == .timelines {
            self.selectedCalendar = card.calendarSystem
            self.epochDate = card.epochDate
            self.epochDescription = card.epochDescription ?? ""
        }
    }

    /// Save view model data back to card
    /// - Parameter card: The card to update
    func saveToCard(_ card: Card) throws {
        guard let modelContext = modelContext else { return }

        card.name = name
        card.subtitle = subtitle
        card.author = author.isEmpty ? nil : author
        card.detailedText = detailedText
        card.sizeCategory = sizeCategory

        // Save image if changed
        if let imageData = imageData {
            try card.setOriginalImageData(imageData)
        }

        // Save calendar data if timeline card
        if card.kind == .timelines {
            card.calendarSystem = selectedCalendar
            // DR-0089: Auto-set epoch for standard calendars if not already set
            if epochDate == nil, let cal = selectedCalendar, cal.isStandardCalendar {
                epochDate = cal.standardEpochDate
            }
            card.epochDate = epochDate
            card.epochDescription = epochDescription.isEmpty ? nil : epochDescription
        }

        try modelContext.save()
    }

    // MARK: - Image Operations

    /// Process selected photo from PhotosPicker
    func processSelectedPhoto() async {
        guard let selectedPhotoItem = selectedPhotoItem else { return }

        isWorking = true
        defer { isWorking = false }

        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self) {
                imageData = data

                // Generate thumbnail
                #if os(macOS)
                if let nsImage = NSImage(data: data) {
                    thumbnail = Image(nsImage: nsImage)
                }
                #else
                if let uiImage = UIImage(data: data) {
                    thumbnail = Image(uiImage: uiImage)
                }
                #endif

                // Extract metadata
                imageMetadata = ImageMetadataExtractor.extract(from: data)
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }

    /// Remove the current image
    func removeImage() {
        imageData = nil
        thumbnail = nil
        imageMetadata = nil
        selectedPhotoItem = nil
    }

    /// Generate thumbnail from image data
    /// - Parameter data: Image data
    /// - Returns: Thumbnail data
    func generateThumbnail(from data: Data) -> Data? {
        return imageProcessingService.generateThumbnail(from: data)
    }

    // MARK: - Content Analysis

    /// Analyze the detailed text for entity extraction
    func analyzeContent() async {
        guard !detailedText.isEmpty else { return }

        isAnalyzing = true
        analysisError = nil
        showAnalysisError = false

        // Get AI provider (simplified - would need actual provider selection)
        // For now, this is a placeholder showing the pattern
        // The actual CardEditorView would inject the provider
        analysisSuggestions = nil
        isAnalyzing = false

        // Show suggestions sheet
        if analysisSuggestions != nil {
            showAnalysisSuggestions = true
        }
    }

    // MARK: - Clipboard Operations

    /// Check if clipboard has image data
    func checkClipboard() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        clipboardHasImage = pasteboard.types?.contains(.png) ?? false ||
                           pasteboard.types?.contains(.tiff) ?? false
        #else
        clipboardHasImage = UIPasteboard.general.hasImages
        #endif
    }

    /// Copy image to clipboard
    func copyImageToClipboard() {
        guard let imageData = imageData else { return }

        #if os(macOS)
        if let nsImage = NSImage(data: imageData) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([nsImage])
            showCopyFeedback = true
        }
        #else
        if let uiImage = UIImage(data: imageData) {
            UIPasteboard.general.image = uiImage
            showCopyFeedback = true
        }
        #endif
    }

    /// Paste image from clipboard
    func pasteImageFromClipboard() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        if let image = NSImage(pasteboard: pasteboard),
           let data = image.tiffRepresentation {
            imageData = imageProcessingService.convertToPNG(data)
            thumbnail = Image(nsImage: image)
            showPasteFeedback = true
        }
        #else
        if let image = UIPasteboard.general.image,
           let data = image.pngData() {
            imageData = data
            thumbnail = Image(uiImage: image)
            showPasteFeedback = true
        }
        #endif
    }

    // MARK: - Validation

    /// Validate that the card can be saved
    /// - Parameter kind: The card kind
    /// - Returns: True if valid
    func validate(for kind: Kinds) -> Bool {
        // Name is required
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }

        // Timeline validation: no calendar (ordinal) is fine;
        // standard calendars auto-set their epoch; custom calendars require explicit epoch
        if kind == .timelines {
            if let calendar = selectedCalendar {
                if calendar.isStandardCalendar {
                    // Standard calendars have an implicit epoch — auto-set if missing
                    if epochDate == nil {
                        epochDate = calendar.standardEpochDate
                    }
                    return true
                }
                // Custom calendars require explicit epoch
                return epochDate != nil
            }
            // No calendar selected = ordinal timeline, always valid
            return true
        }

        return true
    }

    // MARK: - Save Logic

    /// Create a new card from the view model data
    /// - Parameters:
    ///   - kind: The card kind
    ///   - onStructureNeeded: Callback to handle structure creation for projects
    /// - Returns: The newly created card
    /// - Throws: SwiftData errors
    func createCard(kind: Kinds, onStructureNeeded: ((Card) -> Void)? = nil) throws -> Card {
        guard let modelContext = modelContext else {
            throw CardOperationError.invalidName // Use existing error for now
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw CardOperationError.invalidName
        }

        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let authorValue: String? = trimmedAuthor.isEmpty ? nil : trimmedAuthor

        let card = Card(
            kind: kind,
            name: trimmedName,
            subtitle: subtitle,
            detailedText: detailedText,
            author: authorValue,
            sizeCategory: sizeCategory
        )

        modelContext.insert(card)

        // Set image if present
        if let data = imageData {
            try card.setOriginalImageData(data)
        }

        // Handle calendar/timeline cards
        if kind == .timelines || kind == .chronicles {
            card.calendarSystem = selectedCalendar
            // DR-0089: Auto-set epoch for standard calendars if not already set
            if epochDate == nil, let cal = selectedCalendar, cal.isStandardCalendar {
                epochDate = cal.standardEpochDate
            }
            card.epochDate = epochDate
            let trimmedEpochDesc = epochDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            card.epochDescription = trimmedEpochDesc.isEmpty ? nil : trimmedEpochDesc
        }

        // Handle calendar cards
        if kind == .calendars, let calendar = selectedCalendar {
            modelContext.insert(calendar)
            card.calendarSystemRef = calendar
        }

        try modelContext.save()

        // Create pending relationships
        try createPendingRelationships(modelContext: modelContext)

        // Handle structure creation for projects
        if kind == .projects, attachStructure {
            onStructureNeeded?(card)
        }

        return card
    }

    /// Update an existing card with view model data
    /// - Parameters:
    ///   - card: The card to update
    ///   - onStructureNeeded: Callback to handle structure updates for projects
    /// - Throws: SwiftData errors
    func updateCard(_ card: Card, onStructureNeeded: ((Card) -> Void)? = nil) throws {
        guard let modelContext = modelContext else {
            throw CardOperationError.invalidName // Use existing error for now
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw CardOperationError.invalidName
        }

        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let authorValue: String? = trimmedAuthor.isEmpty ? nil : trimmedAuthor

        card.name = trimmedName
        card.subtitle = subtitle
        card.detailedText = detailedText
        card.author = authorValue
        card.sizeCategory = sizeCategory

        // Set image if changed
        if let data = imageData {
            try card.setOriginalImageData(data)
        }

        // Handle calendar/timeline cards
        if card.kind == .timelines || card.kind == .chronicles {
            card.calendarSystem = selectedCalendar
            // DR-0089: Auto-set epoch for standard calendars if not already set
            if epochDate == nil, let cal = selectedCalendar, cal.isStandardCalendar {
                epochDate = cal.standardEpochDate
            }
            card.epochDate = epochDate
            let trimmedEpochDesc = epochDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            card.epochDescription = trimmedEpochDesc.isEmpty ? nil : trimmedEpochDesc
        }

        // Handle calendar cards
        if card.kind == .calendars {
            if let calendar = selectedCalendar {
                if card.calendarSystemRef == nil {
                    modelContext.insert(calendar)
                }
                card.calendarSystemRef = calendar
            } else {
                card.calendarSystemRef = nil
            }
        }

        try modelContext.save()

        // Create pending relationships
        try createPendingRelationships(modelContext: modelContext)

        // Handle structure updates for projects
        if card.kind == .projects {
            onStructureNeeded?(card)
        }
    }

    /// Create relationships from pending suggestions
    private func createPendingRelationships(modelContext: ModelContext) throws {
        guard !pendingRelationships.isEmpty else { return }

        let allCards = try modelContext.fetch(FetchDescriptor<Card>())
        let suggestionEngine = SuggestionEngine()

        try suggestionEngine.createRelationships(
            from: pendingRelationships,
            context: modelContext,
            existingCards: allCards
        )

        pendingRelationships.removeAll()
    }

    // MARK: - Cleanup

    /// Reset the view model to initial state
    func reset() {
        name = ""
        subtitle = ""
        author = ""
        detailedText = ""
        sizeCategory = .standard
        imageData = nil
        thumbnail = nil
        imageMetadata = nil
        selectedPhotoItem = nil
        isAnalyzing = false
        analysisSuggestions = nil
        analysisError = nil
        showAnalysisSuggestions = false
        showAnalysisError = false
        pendingRelationships = []
        pendingAttribution = nil
        attachStructure = true
        structureSource = .template
        selectedTemplateIndex = 0
        structureName = ""
        editableElements = []
        selectedCalendar = nil
        epochDate = nil
        epochDescription = ""
    }
}

// MARK: - Supporting Types

/// Structure source for scene creation
enum StructureSource: String, Hashable, CaseIterable, Identifiable {
    case template = "Template"
    case custom = "Custom"
    var id: String { rawValue }
}

/// Editable structure element for creation
struct EditableElement: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var description: String = ""
    var colorHue: Double? = nil
}
