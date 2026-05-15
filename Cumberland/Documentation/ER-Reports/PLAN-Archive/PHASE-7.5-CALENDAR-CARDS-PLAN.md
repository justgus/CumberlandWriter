# Phase 7.5: Calendar Cards Architecture - Implementation Plan

**Date Created:** 2026-01-26
**Scheduled Implementation:** 2026-01-27
**Estimated Duration:** 3-4 days
**Status:** Planning Complete - Ready for Implementation

---

## Executive Summary

Phase 7.5 elevates CalendarSystem from a background data model to a first-class Card kind, providing:
- Consistent UX (all major entities are cards)
- Calendar-specific detail views with tabs
- Foundation for Phase 8's multi-timeline visualization
- Automatic migration of existing calendars

**Key Principle:** CloudKit handles schema migration automatically - we just ensure all new properties are optional.

---

## Architecture Overview

### Current State
```
Timeline Card
  └─ calendarSystem: CalendarSystem? (direct reference)

CalendarSystem (standalone @Model)
  ├─ name: String
  ├─ divisions: [TimeDivision]
  └─ timelines: [Card]? (inverse)
```

### Target State
```
Calendar Card (kind = .calendars)
  └─ calendarSystemRef: CalendarSystem? (owns the system)

Timeline Card
  └─ calendarSystem: CalendarSystem? (references the system)

CalendarSystem (@Model)
  ├─ name: String
  ├─ divisions: [TimeDivision]
  ├─ timelines: [Card]? (inverse from Timeline.calendarSystem)
  └─ calendarCard: Card? (NEW - inverse from Card.calendarSystemRef)
```

### Key Design Decisions

1. **Calendar cards "own" CalendarSystem objects** (1:1 relationship via calendarSystemRef)
2. **Timeline cards still reference CalendarSystem directly** (preserves existing architecture)
3. **No manual schema migration** (CloudKit handles it automatically)
4. **All new properties are optional** (CloudKit requirement)
5. **Migration runs once on app launch** (UserDefaults flag prevents re-runs)

---

## Implementation Checklist

### Day 1: Data Model & Migration (4-6 hours)

#### 1.1: Kinds Enum Update
**File:** `Model/Kinds.swift`

```swift
// Add to enum
case calendars

// Icon (outline)
case .calendars: return "calendar.badge.gearshape"

// Icon (filled)
case .calendars: return "calendar.badge.gearshape"

// Display name (singular)
case .calendars: return "Calendar"

// Display name (plural)
case .calendars: return "Calendars"

// Color
case .calendars: return .purple  // or .indigo
```

#### 1.2: Card Model Update
**File:** `Model/Card.swift`

```swift
// Add property (after existing relationships)
/// Reference to calendar system (for kind=.calendars only)
/// CloudKit: Optional, defaults to nil
@Relationship(deleteRule: .cascade, inverse: \CalendarSystem.calendarCard)
var calendarSystemRef: CalendarSystem? = nil

// Add computed property
var isCalendarCard: Bool {
    kind == .calendars
}
```

#### 1.3: CalendarSystem Model Update
**File:** `Model/CalendarSystem.swift`

```swift
// Add inverse relationship (after timelines relationship)
/// Calendar card that owns this system (for UI/navigation)
/// CloudKit: Optional, defaults to nil
@Relationship(inverse: \Card.calendarSystemRef)
var calendarCard: Card? = nil
```

#### 1.4: Migration Helper
**File:** `CalendarSystemMigrationHelper.swift` (NEW)

```swift
import Foundation
import SwiftData

/// One-time migration helper for converting standalone CalendarSystem objects to Calendar cards
/// CloudKit Note: No schema migration needed - CloudKit handles new optional properties automatically
struct CalendarSystemMigrationHelper {

    /// Migrate orphaned CalendarSystem objects to Calendar cards
    /// - Parameter context: ModelContext to perform migration
    /// - Returns: Number of calendars migrated
    @discardableResult
    static func migrateOrphanCalendarSystems(context: ModelContext) -> Int {
        #if DEBUG
        print("📅 [Migration] Starting CalendarSystem → Calendar Card migration")
        #endif

        // Fetch all CalendarSystem objects
        let descriptor = FetchDescriptor<CalendarSystem>()
        guard let allCalendars = try? context.fetch(descriptor) else {
            #if DEBUG
            print("⚠️ [Migration] Failed to fetch CalendarSystem objects")
            #endif
            return 0
        }

        #if DEBUG
        print("   Found \(allCalendars.count) total CalendarSystem objects")
        #endif

        // Filter to orphaned calendars (no calendarCard relationship)
        let orphanedCalendars = allCalendars.filter { $0.calendarCard == nil }

        #if DEBUG
        print("   Found \(orphanedCalendars.count) orphaned calendars to migrate")
        #endif

        var migratedCount = 0

        for calendar in orphanedCalendars {
            // Create Calendar card
            let calendarCard = Card(
                kind: .calendars,
                name: calendar.name,
                subtitle: "\(calendar.divisions.count) divisions",
                detailedText: generateCalendarDescription(calendar)
            )

            // Link card to calendar system
            calendarCard.calendarSystemRef = calendar

            // Insert into context
            context.insert(calendarCard)
            migratedCount += 1

            #if DEBUG
            print("   ✅ Migrated: \(calendar.name)")
            #endif
        }

        // Save context
        do {
            try context.save()
            #if DEBUG
            print("✅ [Migration] Successfully migrated \(migratedCount) calendars")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ [Migration] Failed to save context: \(error)")
            #endif
        }

        return migratedCount
    }

    /// Generate detailed description for calendar card
    private static func generateCalendarDescription(_ calendar: CalendarSystem) -> String {
        var description = "Calendar system with \(calendar.divisions.count) time divisions:\n\n"

        for (index, division) in calendar.divisions.enumerated() {
            let indent = String(repeating: "  ", count: index)
            description += "\(indent)• \(division.pluralName.capitalized)"
            if index > 0 {
                description += " (\(division.length) \(calendar.divisions[index - 1].pluralName))"
            }
            description += "\n"
        }

        if let calendarDescription = calendar.calendarDescription {
            description += "\n\(calendarDescription)"
        }

        return description
    }
}
```

#### 1.5: App Launch Migration Trigger
**File:** `CumberlandApp.swift`

```swift
// Add after SwiftData container setup (in init or .onAppear)
// One-time migration: CalendarSystem → Calendar Cards
let migrationKey = "didMigrateCalendarSystemsToCards_v1"
if !UserDefaults.standard.bool(forKey: migrationKey) {
    Task {
        let context = modelContainer.mainContext
        let migrated = CalendarSystemMigrationHelper.migrateOrphanCalendarSystems(context: context)

        #if DEBUG
        print("📅 [App] Calendar migration complete: \(migrated) calendars converted to cards")
        #endif

        // Set flag to prevent re-running
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
```

#### 1.6: Sidebar Update
**File:** `MainAppView.swift`

```swift
// Add @AppStorage for column visibility
@AppStorage("showCalendarsColumn") private var showCalendarsColumn = true

// Add to sidebar after Timelines section
if showCalendarsColumn {
    Section {
        NavigationLink {
            CardListView(kind: .calendars)
        } label: {
            Label {
                HStack {
                    Text("Calendars")
                    Spacer()
                    Text("\(calendarsCount)")
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: Kinds.calendars.iconName)
            }
        }
    }
}

// Add computed property for count
private var calendarsCount: Int {
    let descriptor = FetchDescriptor<Card>(
        predicate: #Predicate { $0.kind == .calendars }
    )
    return (try? modelContext.fetchCount(descriptor)) ?? 0
}

// Add to column visibility menu
Toggle("Calendars", isOn: $showCalendarsColumn)
```

---

### Day 2: Calendar Card Detail View (6-8 hours)

#### 2.1: Create CalendarCardDetailView
**File:** `CalendarCardDetailView.swift` (NEW)

```swift
import SwiftUI
import SwiftData

struct CalendarCardDetailView: View {
    @Bindable var card: Card
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: CalendarTab = .details

    enum CalendarTab: String, CaseIterable {
        case details = "Details"
        case timelines = "Timelines"
        case multiTimeline = "Multi-Timeline"

        var icon: String {
            switch self {
            case .details: return "info.circle"
            case .timelines: return "list.bullet"
            case .multiTimeline: return "chart.line.uptrend.xyaxis"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("Tab", selection: $selectedTab) {
                ForEach(CalendarTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            // Tab content
            TabView(selection: $selectedTab) {
                detailsTab
                    .tag(CalendarTab.details)

                timelinesTab
                    .tag(CalendarTab.timelines)

                multiTimelineTab
                    .tag(CalendarTab.multiTimeline)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(card.name)
    }

    // MARK: - Details Tab

    private var detailsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Basic info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Calendar Name", text: $card.name)
                        .textFieldStyle(.roundedBorder)

                    Text("Subtitle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Brief description", text: Binding(
                        get: { card.subtitle ?? "" },
                        set: { card.subtitle = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                }

                Divider()

                // Calendar system editor
                if let calendarSystem = card.calendarSystemRef {
                    CalendarSystemEditor(calendar: calendarSystem)
                } else {
                    // Create new calendar system
                    Button("Create Calendar System") {
                        let newSystem = CalendarSystem(name: card.name)
                        modelContext.insert(newSystem)
                        card.calendarSystemRef = newSystem
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    // MARK: - Timelines Tab

    @Query private var allTimelines: [Card]

    private var timelinesUsingThisCalendar: [Card] {
        guard let calendar = card.calendarSystemRef else { return [] }
        return allTimelines.filter { timeline in
            timeline.kind == .timelines && timeline.calendarSystem == calendar
        }
    }

    private var timelinesTab: some View {
        Group {
            if timelinesUsingThisCalendar.isEmpty {
                ContentUnavailableView(
                    "No Timelines",
                    systemImage: "calendar.badge.clock",
                    description: Text("No timelines are currently using this calendar system.")
                )
            } else {
                List {
                    ForEach(timelinesUsingThisCalendar) { timeline in
                        NavigationLink(value: timeline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(timeline.name)
                                    .font(.headline)
                                if let subtitle = timeline.subtitle {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Multi-Timeline Tab (Phase 8 Placeholder)

    private var multiTimelineTab: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Multi-Timeline Graph")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Coming in Phase 8")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("This tab will show all timelines using this calendar on a synchronized graph.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: 8) {
                Text("Timelines using this calendar:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if timelinesUsingThisCalendar.isEmpty {
                    Text("No timelines yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(timelinesUsingThisCalendar) { timeline in
                        Label(timeline.name, systemImage: "calendar")
                            .font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}
```

---

### Day 3: Integration & Updates (4-6 hours)

#### 3.1: Update SuggestionReviewView
**File:** `SuggestionReviewView.swift`

```swift
// In acceptSelectedSuggestions() - Phase 7 calendar creation section
// Replace existing calendar creation logic with:

// Phase 7: Create calendar cards (not standalone systems)
if !selectedCalendars.isEmpty {
    for calendarSuggestion in selectedCalendars {
        let detected = calendarSuggestion.detectedCalendar

        // Build TimeDivision hierarchy
        var divisions: [TimeDivision] = []

        divisions.append(TimeDivision(
            name: "day",
            pluralName: "days",
            length: 1,
            isVariable: false
        ))

        if let daysPerWeek = detected.daysPerWeek {
            divisions.append(TimeDivision(
                name: "week",
                pluralName: "weeks",
                length: daysPerWeek,
                isVariable: false
            ))
        }

        if let daysPerMonth = detected.daysPerMonth {
            divisions.append(TimeDivision(
                name: "month",
                pluralName: "months",
                length: daysPerMonth,
                isVariable: false
            ))
        } else {
            divisions.append(TimeDivision(
                name: "month",
                pluralName: "months",
                length: 30,
                isVariable: true
            ))
        }

        divisions.append(TimeDivision(
            name: "year",
            pluralName: "years",
            length: detected.monthsPerYear,
            isVariable: false
        ))

        // Create CalendarSystem
        let calendarSystem = CalendarSystem(
            name: detected.name,
            divisions: divisions
        )

        // Create Calendar CARD
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
```

#### 3.2: Update SceneTemporalPositionEditor Calendar Picker
**File:** `SceneTemporalPositionEditor.swift`

```swift
// Update calendar selection to use Calendar cards
@Query(filter: #Predicate<Card> { $0.kind == .calendars })
private var calendarCards: [Card]

// In calendar picker section
Picker("Calendar System", selection: $selectedCalendar) {
    Text("None").tag(nil as CalendarSystem?)
    ForEach(calendarCards) { card in
        if let system = card.calendarSystemRef {
            Text(card.name).tag(system as CalendarSystem?)
        }
    }
}
```

#### 3.3: Update CardEditorView for .calendars kind
**File:** `CardEditorView.swift`

```swift
// Add calendar-specific handling
if currentCard.kind == .calendars {
    Section("Calendar System") {
        if let calendarSystem = currentCard.calendarSystemRef {
            CalendarSystemEditor(calendar: calendarSystem)
        } else {
            Button("Create Calendar System") {
                let newSystem = CalendarSystem(name: currentCard.name)
                modelContext.insert(newSystem)
                currentCard.calendarSystemRef = newSystem
            }
        }
    }
}

// Hide irrelevant sections for calendar cards
if currentCard.kind != .calendars {
    // ... existing image, temporal position, etc.
}
```

---

### Day 4: Testing & Polish (4-6 hours)

#### 4.1: Manual Testing Checklist
- [ ] Fresh app launch triggers migration
- [ ] Existing calendars appear as Calendar cards in sidebar
- [ ] Can create new Calendar card manually
- [ ] Can create Calendar card from AI suggestion
- [ ] Calendar card detail view shows all 3 tabs
- [ ] Details tab loads CalendarSystemEditor correctly
- [ ] Timelines tab shows correct timelines
- [ ] Can edit calendar through Calendar card
- [ ] Timeline editor shows Calendar cards in picker
- [ ] Selecting calendar card updates timeline correctly
- [ ] Deleting calendar card nullifies timeline references
- [ ] CloudKit sync works for calendar cards

#### 4.2: Fix any issues found
- Debug migration edge cases
- Polish UI transitions
- Verify CloudKit sync
- Test on iOS and macOS

---

## Key CloudKit Notes

**CRITICAL: No Manual Schema Migration**
- CloudKit handles schema evolution automatically
- All new properties MUST be optional or have defaults
- New properties: `Card.calendarSystemRef`, `CalendarSystem.calendarCard`
- Both are optional with `= nil` default
- CloudKit will add these fields to existing records automatically

**Migration Strategy:**
- App launch checks UserDefaults flag: `didMigrateCalendarSystemsToCards_v1`
- If false, run `CalendarSystemMigrationHelper.migrateOrphanCalendarSystems()`
- Helper creates Calendar cards for any CalendarSystem without a calendarCard
- Set flag to true to prevent re-runs
- CloudKit syncs new cards normally

---

## Risk Mitigation

**Risk:** Migration runs multiple times
- **Mitigation:** UserDefaults flag, checks for `calendarCard == nil`

**Risk:** Existing timelines lose calendar references
- **Mitigation:** Timelines still reference CalendarSystem directly (no change)

**Risk:** UI shows both old and new calendar management
- **Mitigation:** Migration creates cards for ALL existing calendars on first launch

**Risk:** CloudKit sync conflicts
- **Mitigation:** All new properties are optional, CloudKit handles gracefully

---

## Success Metrics

- ✅ All existing calendars migrated to cards on first launch
- ✅ Can create calendar cards from AI suggestions
- ✅ Can create calendar cards manually
- ✅ Calendar cards show in sidebar with correct count
- ✅ Timeline editor uses calendar card picker
- ✅ Calendar detail view has 3 functional tabs
- ✅ Deleting calendar card doesn't break timelines
- ✅ CloudKit sync works correctly

---

## Files Summary

**New Files:**
- `CalendarCardDetailView.swift` - Main calendar card UI
- `CalendarSystemMigrationHelper.swift` - One-time migration

**Modified Files:**
- `Model/Kinds.swift` - Add .calendars
- `Model/Card.swift` - Add calendarSystemRef
- `Model/CalendarSystem.swift` - Add calendarCard inverse
- `MainAppView.swift` - Add Calendars sidebar
- `CumberlandApp.swift` - Add migration trigger
- `SuggestionReviewView.swift` - Create calendar cards
- `SceneTemporalPositionEditor.swift` - Use calendar cards in picker
- `CardEditorView.swift` - Handle .calendars kind

---

## Next Steps (Phase 8)

After Phase 7.5 is complete, Phase 8 will:
- Implement multi-timeline visualization in the third tab
- Query all timelines using a calendar
- Render synchronized timeline graph
- Enable timeline comparison and analysis

Phase 7.5 provides the foundation by:
- Creating the third tab placeholder
- Querying timelines by calendar
- Establishing calendar card as the primary UI

---

**END OF PLAN - Ready for Implementation on 2026-01-27**
