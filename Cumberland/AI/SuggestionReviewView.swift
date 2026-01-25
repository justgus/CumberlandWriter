import SwiftUI
import SwiftData

/// UI for reviewing and accepting/rejecting entity and relationship suggestions
/// Phase 5 (ER-0010) - Content Analysis MVP
struct SuggestionReviewView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let suggestions: SuggestionEngine.Suggestions
    let sourceCard: Card
    let existingCards: [Card]

    // MARK: - State

    @State private var selectedCardSuggestions = Set<UUID>()
    @State private var selectedRelationshipSuggestions = Set<UUID>()
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let suggestionEngine = SuggestionEngine()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerView

                    // Card Suggestions Section
                    if !suggestions.cards.isEmpty {
                        cardSuggestionsSection
                    }

                    // Relationship Suggestions Section
                    if !suggestions.relationships.isEmpty {
                        relationshipSuggestionsSection
                    }

                    // Empty State
                    if suggestions.isEmpty {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("Review Suggestions")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    acceptButton
                }

                ToolbarItem(placement: .secondaryAction) {
                    selectAllButton
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Found **\(suggestions.totalCount)** suggestions")
                .font(.headline)

            Text("Select the cards and relationships you want to create.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !suggestions.cards.isEmpty {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .font(.caption)
                    Text("\(suggestions.cards.count) new cards")
                        .font(.caption)
                }
                .foregroundStyle(.blue)
            }

            if !suggestions.relationships.isEmpty {
                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.caption)
                    Text("\(suggestions.relationships.count) relationships")
                        .font(.caption)
                }
                .foregroundStyle(.purple)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Card Suggestions

    private var cardSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Cards to Create")
                .font(.title3)
                .fontWeight(.semibold)

            ForEach(suggestions.cards) { suggestion in
                CardSuggestionRow(
                    suggestion: suggestion,
                    isSelected: selectedCardSuggestions.contains(suggestion.id)
                ) {
                    toggleSelection(for: suggestion)
                }
            }
        }
    }

    // MARK: - Relationship Suggestions

    private var relationshipSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Relationships to Add")
                .font(.title3)
                .fontWeight(.semibold)

            ForEach(suggestions.relationships) { suggestion in
                RelationshipSuggestionRow(
                    suggestion: suggestion,
                    isSelected: selectedRelationshipSuggestions.contains(suggestion.id)
                ) {
                    toggleSelection(for: suggestion)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Suggestions Found")
                .font(.title2)
                .fontWeight(.semibold)

            Text("The AI couldn't find any entities or relationships in the text.\n\nTry adding more descriptive details to your card.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Buttons

    private var acceptButton: some View {
        Button {
            acceptSelectedSuggestions()
        } label: {
            if isCreating {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
            } else {
                Text("Create Selected")
            }
        }
        .disabled(selectedCardSuggestions.isEmpty && selectedRelationshipSuggestions.isEmpty || isCreating)
    }

    private var selectAllButton: some View {
        Menu {
            Button("Select All Cards") {
                selectAllCards()
            }

            Button("Select High Confidence (>85%)") {
                selectHighConfidenceOnly()
            }

            Button("Deselect All") {
                deselectAll()
            }
        } label: {
            Image(systemName: "checkmark.circle")
        }
    }

    // MARK: - Actions

    private func toggleSelection(for suggestion: SuggestionEngine.CardSuggestion) {
        if selectedCardSuggestions.contains(suggestion.id) {
            selectedCardSuggestions.remove(suggestion.id)
        } else {
            selectedCardSuggestions.insert(suggestion.id)
        }
    }

    private func toggleSelection(for suggestion: SuggestionEngine.RelationshipSuggestion) {
        if selectedRelationshipSuggestions.contains(suggestion.id) {
            selectedRelationshipSuggestions.remove(suggestion.id)
        } else {
            selectedRelationshipSuggestions.insert(suggestion.id)
        }
    }

    private func selectAllCards() {
        selectedCardSuggestions = Set(suggestions.cards.map { $0.id })
        selectedRelationshipSuggestions = Set(suggestions.relationships.map { $0.id })
    }

    private func selectHighConfidenceOnly() {
        let highConfidence = suggestionEngine.getHighConfidenceSuggestions(suggestions)
        selectedCardSuggestions = Set(highConfidence.cards.map { $0.id })
        selectedRelationshipSuggestions = Set(highConfidence.relationships.map { $0.id })
    }

    private func deselectAll() {
        selectedCardSuggestions.removeAll()
        selectedRelationshipSuggestions.removeAll()
    }

    private func acceptSelectedSuggestions() {
        isCreating = true

        Task {
            do {
                // Get selected suggestions
                let selectedCards = suggestions.cards.filter { selectedCardSuggestions.contains($0.id) }
                let selectedRelationships = suggestions.relationships.filter { selectedRelationshipSuggestions.contains($0.id) }

                // Create cards
                if !selectedCards.isEmpty {
                    try suggestionEngine.createCards(from: selectedCards, context: modelContext, sourceCard: sourceCard)
                }

                // Create relationships
                if !selectedRelationships.isEmpty {
                    try suggestionEngine.createRelationships(from: selectedRelationships, context: modelContext, existingCards: existingCards)
                }

                #if DEBUG
                print("✅ [SuggestionReviewView] Created \(selectedCards.count) cards and \(selectedRelationships.count) relationships")
                #endif

                // Dismiss
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }

            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isCreating = false
                }
            }
        }
    }
}

// MARK: - Card Suggestion Row

private struct CardSuggestionRow: View {
    let suggestion: SuggestionEngine.CardSuggestion
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button {
                onToggle()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Name and type
                HStack {
                    Text(suggestion.entity.name)
                        .font(.headline)

                    Spacer()

                    Text(suggestion.cardKind.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(6)
                }

                // Confidence
                HStack(spacing: 4) {
                    ConfidenceBadge(confidence: suggestion.confidence)

                    if let context = suggestion.entity.context {
                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(context.prefix(50) + (context.count > 50 ? "..." : ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                // Initial description preview
                Text(suggestion.initialDescription.prefix(100) + (suggestion.initialDescription.count > 100 ? "..." : ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.05) : Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Relationship Suggestion Row

private struct RelationshipSuggestionRow: View {
    let suggestion: SuggestionEngine.RelationshipSuggestion
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button {
                onToggle()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .purple : .secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Relationship description
                HStack(spacing: 8) {
                    Text(suggestion.sourceCardName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(suggestion.relationship.type.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.purple)

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(suggestion.targetCardName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                // Confidence
                ConfidenceBadge(confidence: suggestion.confidence)

                // Context
                if let context = suggestion.relationship.context {
                    Text(context.prefix(100) + (context.count > 100 ? "..." : ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(isSelected ? Color.purple.opacity(0.05) : Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Confidence Badge

private struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: confidenceIcon)
                .font(.caption2)
            Text("\(Int(confidence * 100))%")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(confidenceColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(confidenceColor.opacity(0.1))
        .cornerRadius(4)
    }

    private var confidenceIcon: String {
        if confidence >= 0.85 {
            return "checkmark.seal.fill"
        } else if confidence >= 0.70 {
            return "checkmark.circle"
        } else {
            return "questionmark.circle"
        }
    }

    private var confidenceColor: Color {
        if confidence >= 0.85 {
            return .green
        } else if confidence >= 0.70 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleEntities = [
        Entity(name: "Shadowblade", type: .artifact, confidence: 0.92, context: "Aria drew the Shadowblade from its sheath"),
        Entity(name: "Temple of Shadows", type: .building, confidence: 0.88, context: "entered the Temple of Shadows"),
        Entity(name: "Blackrock City", type: .location, confidence: 0.75, context: "in Blackrock City")
    ]

    let suggestionEngine = SuggestionEngine()
    let card = Card(kind: .scenes, name: "Test Scene", subtitle: "", detailedText: "Test")
    let suggestions = suggestionEngine.generateCardSuggestions(from: sampleEntities, sourceCard: card)

    SuggestionReviewView(
        suggestions: SuggestionEngine.Suggestions(cards: suggestions, relationships: []),
        sourceCard: card,
        existingCards: []
    )
}
