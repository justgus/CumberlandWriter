import SwiftUI
import SwiftData

/// UI for reviewing and accepting/rejecting entity and relationship suggestions
/// Phase 5 (ER-0010) - Content Analysis MVP
struct SuggestionReviewView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let sourceCard: Card
    let existingCards: [Card]
    @Binding var pendingRelationships: [SuggestionEngine.RelationshipSuggestion]

    // MARK: - State

    @State private var mutableSuggestions: SuggestionEngine.Suggestions
    @State private var selectedCardSuggestions = Set<UUID>()
    @State private var selectedRelationshipSuggestions = Set<UUID>()
    @State private var selectedCalendarSuggestions = Set<UUID>()  // Phase 7
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showError = false

    init(suggestions: SuggestionEngine.Suggestions, sourceCard: Card, existingCards: [Card], pendingRelationships: Binding<[SuggestionEngine.RelationshipSuggestion]>) {
        self.sourceCard = sourceCard
        self.existingCards = existingCards
        self._pendingRelationships = pendingRelationships
        self._mutableSuggestions = State(initialValue: suggestions)
    }

    private let suggestionEngine = SuggestionEngine()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerView

                    // Card Suggestions Section
                    if !mutableSuggestions.cards.isEmpty {
                        cardSuggestionsSection
                    }

                    // Relationship Suggestions Section
                    if !mutableSuggestions.relationships.isEmpty {
                        relationshipSuggestionsSection
                    }

                    // Calendar Suggestions Section (Phase 7)
                    if !mutableSuggestions.calendars.isEmpty {
                        calendarSuggestionsSection
                    }

                    // Empty State
                    if mutableSuggestions.isEmpty {
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
            Text("Found **\(mutableSuggestions.totalCount)** suggestions")
                .font(.headline)

            Text("Select the cards, relationships, and calendar systems you want to create.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !mutableSuggestions.cards.isEmpty {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .font(.caption)
                    Text("\(mutableSuggestions.cards.count) new cards")
                        .font(.caption)
                }
                .foregroundStyle(.blue)
            }

            if !mutableSuggestions.relationships.isEmpty {
                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.caption)
                    Text("\(mutableSuggestions.relationships.count) relationships")
                        .font(.caption)
                }
                .foregroundStyle(.purple)
            }

            if !mutableSuggestions.calendars.isEmpty {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.caption)
                    Text("\(mutableSuggestions.calendars.count) calendar system(s)")
                        .font(.caption)
                }
                .foregroundStyle(.green)
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

            ForEach($mutableSuggestions.cards) { $suggestion in
                CardSuggestionRow(
                    suggestion: $suggestion,
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

            ForEach(mutableSuggestions.relationships) { suggestion in
                RelationshipSuggestionRow(
                    suggestion: suggestion,
                    isSelected: selectedRelationshipSuggestions.contains(suggestion.id)
                ) {
                    toggleSelection(for: suggestion)
                }
            }
        }
    }

    // MARK: - Calendar Suggestions (Phase 7)

    private var calendarSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar Systems Detected")
                .font(.title3)
                .fontWeight(.semibold)

            ForEach(mutableSuggestions.calendars) { suggestion in
                CalendarSuggestionRow(
                    suggestion: suggestion,
                    isSelected: selectedCalendarSuggestions.contains(suggestion.id)
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
        .disabled(selectedCardSuggestions.isEmpty && selectedRelationshipSuggestions.isEmpty && selectedCalendarSuggestions.isEmpty || isCreating)
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

    private func toggleSelection(for suggestion: SuggestionEngine.CalendarSuggestion) {
        if selectedCalendarSuggestions.contains(suggestion.id) {
            selectedCalendarSuggestions.remove(suggestion.id)
        } else {
            selectedCalendarSuggestions.insert(suggestion.id)
        }
    }

    private func selectAllCards() {
        selectedCardSuggestions = Set(mutableSuggestions.cards.map { $0.id })
        selectedRelationshipSuggestions = Set(mutableSuggestions.relationships.map { $0.id })
        selectedCalendarSuggestions = Set(mutableSuggestions.calendars.map { $0.id })  // Phase 7
    }

    private func selectHighConfidenceOnly() {
        let highConfidence = suggestionEngine.getHighConfidenceSuggestions(mutableSuggestions)
        selectedCardSuggestions = Set(highConfidence.cards.map { $0.id })
        selectedRelationshipSuggestions = Set(highConfidence.relationships.map { $0.id })
        selectedCalendarSuggestions = Set(highConfidence.calendars.map { $0.id })  // Phase 7
    }

    private func deselectAll() {
        selectedCardSuggestions.removeAll()
        selectedRelationshipSuggestions.removeAll()
        selectedCalendarSuggestions.removeAll()  // Phase 7
    }

    private func acceptSelectedSuggestions() {
        isCreating = true

        Task {
            do {
                // Get selected suggestions (with user-modified card types)
                let selectedCards = mutableSuggestions.cards.filter { selectedCardSuggestions.contains($0.id) }
                let selectedRelationships = mutableSuggestions.relationships.filter { selectedRelationshipSuggestions.contains($0.id) }
                let selectedCalendars = mutableSuggestions.calendars.filter { selectedCalendarSuggestions.contains($0.id) }  // Phase 7

                // Create entity cards first
                if !selectedCards.isEmpty {
                    try suggestionEngine.createCards(from: selectedCards, context: modelContext, sourceCard: sourceCard)
                }

                // Phase 7: Create calendar systems
                if !selectedCalendars.isEmpty {
                    for calendarSuggestion in selectedCalendars {
                        let detected = calendarSuggestion.detectedCalendar

                        // Build TimeDivision hierarchy from detected calendar data
                        var divisions: [TimeDivision] = []

                        // Add day division (base unit)
                        divisions.append(TimeDivision(
                            name: "day",
                            pluralName: "days",
                            length: 1,
                            isVariable: false
                        ))

                        // Add week division if days per week is known
                        if let daysPerWeek = detected.daysPerWeek {
                            divisions.append(TimeDivision(
                                name: "week",
                                pluralName: "weeks",
                                length: daysPerWeek,
                                isVariable: false
                            ))
                        }

                        // Add month division
                        if let daysPerMonth = detected.daysPerMonth {
                            divisions.append(TimeDivision(
                                name: "month",
                                pluralName: "months",
                                length: daysPerMonth,
                                isVariable: false
                            ))
                        } else {
                            // Default to 30 days if not specified
                            divisions.append(TimeDivision(
                                name: "month",
                                pluralName: "months",
                                length: 30,
                                isVariable: true
                            ))
                        }

                        // Add year division
                        divisions.append(TimeDivision(
                            name: "year",
                            pluralName: "years",
                            length: detected.monthsPerYear,
                            isVariable: false
                        ))

                        // Phase 7.5: Create CalendarSystem
                        let calendarSystem = CalendarSystem(
                            name: detected.name,
                            divisions: divisions
                        )

                        // Phase 7.5: Create Calendar CARD
                        let calendarCard = Card(
                            kind: .calendars,
                            name: detected.name,
                            subtitle: "\(detected.monthsPerYear) months, \(detected.daysPerMonth ?? 0) days/month",
                            detailedText: detected.context
                        )

                        // Link card to system
                        calendarCard.calendarSystemRef = calendarSystem

                        // Insert both
                        modelContext.insert(calendarSystem)
                        modelContext.insert(calendarCard)

                        #if DEBUG
                        print("✅ [SuggestionReviewView] Created Calendar Card: \(detected.name)")
                        print("   Divisions: \(divisions.map { $0.name }.joined(separator: " → "))")
                        #endif
                    }

                    try modelContext.save()
                }

                // Phase 6 Fix: Split relationships into two groups:
                // 1. Immediate relationships (don't involve source card being created)
                // 2. Pending relationships (involve source card as source OR target)

                let sourceCardName = sourceCard.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                var immediateRelationships: [SuggestionEngine.RelationshipSuggestion] = []
                var deferredRelationships: [SuggestionEngine.RelationshipSuggestion] = []

                for relationship in selectedRelationships {
                    let sourceMatches = relationship.sourceCardName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == sourceCardName
                    let targetMatches = relationship.targetCardName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == sourceCardName

                    if sourceMatches || targetMatches {
                        // This relationship involves the source card being created - defer it
                        deferredRelationships.append(relationship)
                    } else {
                        // This relationship doesn't involve the source card - create it now
                        immediateRelationships.append(relationship)
                    }
                }

                // Create immediate relationships now (all cards exist)
                if !immediateRelationships.isEmpty {
                    let allCards = try modelContext.fetch(FetchDescriptor<Card>())
                    try suggestionEngine.createRelationships(
                        from: immediateRelationships,
                        context: modelContext,
                        existingCards: allCards
                    )
                }

                // Store deferred relationships for creation when source card is saved
                await MainActor.run {
                    pendingRelationships = deferredRelationships
                }

                #if DEBUG
                print("✅ [SuggestionReviewView] Created \(selectedCards.count) entity cards")
                print("✅ [SuggestionReviewView] Created \(selectedCalendars.count) calendar cards")
                print("✅ [SuggestionReviewView] Created \(immediateRelationships.count) immediate relationships")
                print("📋 [SuggestionReviewView] Stored \(deferredRelationships.count) pending relationships (involve '\(sourceCard.name)')")
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
    @Binding var suggestion: SuggestionEngine.CardSuggestion
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

                    // Card type picker - allows user to override AI suggestion
                    Picker("Card Type", selection: $suggestion.cardKind) {
                        ForEach(Kinds.orderedCases.filter { $0 != .structure }, id: \.self) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.caption)
                    .tint(.blue)
                    .help("Change card type (AI suggested: \(suggestion.entity.type.rawValue))")
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

                    Text(suggestion.relationTypeCode)
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
                if let context = suggestion.context {
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

// MARK: - Calendar Suggestion Row (Phase 7)

private struct CalendarSuggestionRow: View {
    let suggestion: SuggestionEngine.CalendarSuggestion
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
                    .foregroundStyle(isSelected ? .green : .secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                // Calendar name
                HStack {
                    Text(suggestion.detectedCalendar.name)
                        .font(.headline)

                    Spacer()

                    ConfidenceBadge(confidence: suggestion.detectedCalendar.confidence)
                }

                // Summary
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.green)

                    Text("\(suggestion.detectedCalendar.monthsPerYear) months")
                        .font(.caption)

                    if let daysPerMonth = suggestion.detectedCalendar.daysPerMonth {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text("\(daysPerMonth) days/month")
                            .font(.caption)
                    }

                    if let daysPerWeek = suggestion.detectedCalendar.daysPerWeek {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text("\(daysPerWeek) days/week")
                            .font(.caption)
                    }
                }

                // Month names (show first 5)
                if !suggestion.detectedCalendar.monthNames.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        let monthsToShow = suggestion.detectedCalendar.monthNames.prefix(5)
                        let remaining = suggestion.detectedCalendar.monthNames.count - monthsToShow.count

                        Text(monthsToShow.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        if remaining > 0 {
                            Text("(+\(remaining) more)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Era name
                if let eraName = suggestion.detectedCalendar.eraName {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("Era: \(eraName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Festivals
                if let festivals = suggestion.detectedCalendar.festivals, !festivals.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)

                        Text("\(festivals.count) festival(s)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Context preview
                Text(suggestion.detectedCalendar.context.prefix(150) + (suggestion.detectedCalendar.context.count > 150 ? "..." : ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(isSelected ? Color.green.opacity(0.05) : Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
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
    @Previewable @State var pendingRelationships: [SuggestionEngine.RelationshipSuggestion] = []

    let sampleEntities = [
        Entity(name: "Shadowblade", type: .artifact, confidence: 0.92, context: "Aria drew the Shadowblade from its sheath"),
        Entity(name: "Temple of Shadows", type: .building, confidence: 0.88, context: "entered the Temple of Shadows"),
        Entity(name: "Blackrock City", type: .location, confidence: 0.75, context: "in Blackrock City")
    ]

    let suggestionEngine = SuggestionEngine()
    let card = Card(kind: .scenes, name: "Test Scene", subtitle: "", detailedText: "Test")
    let suggestions = suggestionEngine.generateCardSuggestions(from: sampleEntities, sourceCard: card)

    SuggestionReviewView(
        suggestions: SuggestionEngine.Suggestions(cards: suggestions, relationships: [], calendars: []),
        sourceCard: card,
        existingCards: [],
        pendingRelationships: $pendingRelationships
    )
}
