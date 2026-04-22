# Story Structure Integration Design

## Current State Analysis

### Existing Implementation
- **StoryStructure Model**: Contains project-specific structures with `projectID` field
- **StructureElement Model**: Individual beats/acts within a structure
- **Many-to-Many**: Scenes can be assigned to multiple structure elements via `Card.structureElements`
- **Structure Board**: Kanban-style UI for dragging scenes between structure beats
- **Structure Repository**: Query and management layer for structures

### Current Limitations
1. **No Structure Selection UI**: When creating a project, no UI to select/assign a structure
2. **One Structure Per Project**: StoryStructure has `projectID`, implying 1:1 relationship
3. **No Structure Switching**: No mechanism to change a project's structure while preserving scene assignments
4. **Hidden in Sidebar**: Structure Board is accessed via sidebar, not integrated with Project Writer

## Design Goals

### 1. Easy Structure Selection
Writers should be able to:
- Select a structure template when creating a new project
- Change the structure of an existing project
- Start without a structure and add one later
- View structure options from both Dashboard and Writing Surface

### 2. Structure Preservation
When changing structures:
- Preserve scene assignments to structurally similar beats
- Minimize disruption to writing workflow
- Provide clear feedback about what changed

### 3. Flexible Workflow
Support multiple workflows:
- **Structure-first**: Choose template, write to beats
- **Discovery writing**: Write freely, add structure later
- **Hybrid**: Start with loose structure, refine later

## Proposed Architecture

### Model Changes

#### Option A: Keep Existing (Recommended)
**No model changes needed.** Current design already supports:
- `StoryStructure.projectID` links structure to project
- One structure per project (simple, clear)
- Scenes assigned to structure elements via many-to-many

**Rationale**: Most writers work with one structure per project. Supporting multiple concurrent structures adds complexity without clear benefit.

#### Option B: Support Multiple Structures (Future Enhancement)
If needed later, could support:
- Remove `projectID` from StoryStructure
- Add new `ProjectStructure` join model with:
  - `projectID: UUID`
  - `structureID: UUID`
  - `isActive: Bool` (which structure is currently active)
  - `createdAt: Date`

### Structure Selection UI

#### 1. Project Creation Flow
**Location**: When creating a new project (CardEditorView or dedicated Project Wizard)

**UI Components**:
```swift
struct ProjectStructureSelector: View {
    @Binding var selectedTemplate: (name: String, elements: [String])?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Story Structure (Optional)")
                .font(.headline)

            Text("Choose a template to organize your scenes")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Template", selection: $selectedTemplate) {
                Text("None (Add Later)").tag(Optional<(String, [String])>.none)

                ForEach(StoryStructure.predefinedTemplates, id: \.name) { template in
                    Text(template.name).tag(template as (String, [String])?)
                }
            }
            .pickerStyle(.menu)
        }
    }
}
```

**Integration**:
- Add to CardEditorView when `card.kind == .projects`
- When project is saved, create StoryStructure if template selected
- Set `StoryStructure.projectID` to link structure to project

#### 2. Project Dashboard Integration
**Location**: ProjectDashboardView (new control in Structure Band section)

**UI Components**:
```swift
// In ProjectDashboardView
private var structureBandHeader: some View {
    HStack {
        Text("Story Structure")
            .font(.caption)
            .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

        Spacer()

        if let structure = currentStructure {
            Menu {
                Button("Change Structure...") {
                    showStructureSelector = true
                }
                Button("Remove Structure") {
                    removeStructure()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(structure.name)
                        .font(.caption2)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(themeManager.currentTheme.colors.accentPrimary)
            }
        } else {
            Button("Add Structure") {
                showStructureSelector = true
            }
            .font(.caption2)
        }
    }
}
```

#### 3. Manuscript Writing Surface Integration
**Location**: ManuscriptWritingSurfaceView (new button in Quick Action Tray or Chapter Tab Strip)

**UI Components**:
```swift
// Add to Quick Action Tray
quickActionButton(
    title: "Structure",
    icon: "list.number",
    action: { showStructureSelector = true }
)

// Or add to Chapter Tab Strip as icon button
Button {
    showStructureSelector = true
} label: {
    Image(systemName: currentStructure == nil ? "list.number" : "list.number.circle.fill")
        .foregroundStyle(currentStructure == nil ? .secondary : .accentPrimary)
}
.help(currentStructure?.name ?? "Add Story Structure")
```

**Sheet Presentation**:
```swift
.sheet(isPresented: $showStructureSelector) {
    StructureSelectionSheet(
        project: project,
        currentStructure: currentStructure,
        onSelected: { newTemplate in
            applyStructure(newTemplate)
        }
    )
}
```

### Structure Selection Sheet

```swift
struct StructureSelectionSheet: View {
    let project: Card
    let currentStructure: StoryStructure?
    let onSelected: ((name: String, elements: [String])) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: (name: String, elements: [String])?
    @State private var showPreservationWarning = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if currentStructure != nil {
                        Button("Remove Structure") {
                            // Remove structure logic
                        }
                        .foregroundStyle(.red)
                    }
                }

                Section("Available Templates") {
                    ForEach(StoryStructure.predefinedTemplates, id: \.name) { template in
                        Button {
                            selectedTemplate = template
                            if currentStructure != nil && hasSceneAssignments {
                                showPreservationWarning = true
                            } else {
                                applyAndDismiss(template)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(template.name)
                                        .font(.body)

                                    if currentStructure?.name == template.name {
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }

                                Text("\(template.elements.count) beats")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Story Structure")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert("Change Structure?", isPresented: $showPreservationWarning) {
            Button("Cancel", role: .cancel) { }
            Button("Change", role: .destructive) {
                if let template = selectedTemplate {
                    applyAndDismiss(template)
                }
            }
        } message: {
            Text("Some scene assignments may be lost when changing structures. Continue?")
        }
    }

    private func applyAndDismiss(_ template: (name: String, elements: [String])) {
        onSelected(template)
        dismiss()
    }
}
```

## Structure Switching with Preservation

### Challenge
When switching from one structure to another:
- Scenes assigned to "Act 1" in Three-Act Structure
- Should they map to "Setup" in Four-Part Structure?
- How do we preserve authorial intent?

### Solution: Proportional Position Mapping

**Algorithm**:
```
For each scene S assigned to element E in old structure:
1. Calculate position: pos = E.orderIndex / oldStructure.elements.count
2. Map to new structure: newIndex = round(pos * newStructure.elements.count)
3. Assign S to newStructure.elements[newIndex]
```

**Example**:
```
Old: Three-Act Structure (3 elements)
- Scene A assigned to "Act 1" (index 0)
- Scene B assigned to "Act 2" (index 1)
- Scene C assigned to "Act 3" (index 2)

New: Five-Act Structure (5 elements)
- Scene A: 0/3 = 0.0 → 0.0 * 5 = 0 → "Exposition"
- Scene B: 1/3 = 0.33 → 0.33 * 5 = 1.67 → 2 → "Climax"
- Scene C: 2/3 = 0.67 → 0.67 * 5 = 3.33 → 3 → "Falling Action"
```

**Trade-offs**:
- ✅ **Simple**: Easy to understand and implement
- ✅ **Automatic**: No user input required
- ✅ **Preserves Flow**: Scenes stay in relative narrative position
- ❌ **Imprecise**: "Act 2" might not semantically map to "Climax"
- ❌ **Data Loss**: No way to undo or see original assignments

### Alternative: Semantic Mapping (Future Enhancement)

Create explicit mappings between structure elements:

```swift
struct StructureMapping {
    static let mappings: [String: [String: String]] = [
        "Three-Act Structure -> Five-Act Structure": [
            "Act 1": "Exposition",
            "Act 2": "Rising Action", // Could map to multiple
            "Act 3": "Resolution"
        ],
        "Three-Act Structure -> Hero's Journey (Simplified)": [
            "Act 1": "Ordinary World",
            "Act 2": "Trials",
            "Act 3": "Return"
        ]
        // ... many more mappings
    ]
}
```

**Trade-offs**:
- ✅ **Semantically Accurate**: Respects narrative meaning
- ✅ **Predictable**: Writers know where scenes will land
- ❌ **Maintenance Burden**: N×N mappings to maintain
- ❌ **Incomplete**: Can't map all structure pairs
- ❌ **Complex**: Ambiguous when element maps to multiple targets

### Better Alternatives to Proportional Mapping

**User Feedback**: "I think we can do better here. Let's discuss this further."

The proportional mapping algorithm has a fundamental flaw: it assumes structural equivalence based solely on position, ignoring semantic meaning. Here are better alternatives:

#### Option A: Interactive Preview with Manual Adjustment (Recommended)

**Concept**: Show a preview dialog where the writer can review and adjust each mapping before confirming.

**UI Flow**:
```
1. Writer clicks "Change Structure" from Three-Act to Hero's Journey
2. Show dialog: "Structure Change Preview"
3. Display side-by-side comparison:

   Three-Act Structure          →    Hero's Journey
   ┌──────────────────┐              ┌──────────────────┐
   │ Act 1            │ ──────────→  │ Ordinary World   │
   │ - Scene A        │              │ - Scene A        │
   │ - Scene B        │              │ - Scene B        │
   └──────────────────┘              └──────────────────┘

   ┌──────────────────┐              ┌──────────────────┐
   │ Act 2            │ ─────┬─────→ │ Call to Adventure│
   │ - Scene C        │      │       │ - Scene C?       │
   │ - Scene D        │      │       └──────────────────┘
   │ - Scene E        │      │       ┌──────────────────┐
   └──────────────────┘      └─────→ │ Trials           │
                                     │ - Scene D?       │
                                     │ - Scene E?       │
                                     └──────────────────┘

4. Writer can drag scenes between beats to adjust
5. Click "Apply" to confirm or "Cancel" to abort
```

**Implementation**:
- Use drag-and-drop for reassignment
- Provide "Auto-assign by position" button as starting point
- Show unassigned scenes in a separate "Unassigned" section
- Allow leaving scenes unassigned (move to backlog)

**Trade-offs**:
- ✅ Complete control, no data loss
- ✅ Clear visibility of what will happen
- ✅ Educational (writer learns structure differences)
- ⏱️ Requires writer time/attention
- 🔧 More complex UI implementation

---

#### Option B: Smart Suggestions with Confidence Scores

**Concept**: Use multiple heuristics to suggest mappings, show confidence, allow adjustment.

**Algorithm**:
```swift
For each scene S assigned to old element E:
  1. Calculate proportional position (baseline)
  2. Analyze scene content (keywords, themes, character arcs)
  3. Compare to new structure element descriptions
  4. Generate ranked suggestions with confidence scores
  5. Present top suggestion, allow writer to choose alternative
```

**Example**:
```
Scene C (currently in "Act 2"):
  Suggestions for Hero's Journey:
  ✓ Call to Adventure (75% confidence) - contains "invitation", "refused"
  • Trials (40% confidence) - contains "challenge"
  • Meeting the Mentor (30% confidence) - contains dialogue
```

**Trade-offs**:
- ✅ Smarter than pure position
- ✅ Provides rationale for suggestions
- ✅ Writer can override
- ❌ Requires content analysis
- ❌ Confidence scores may be misleading
- 🔧 Complex implementation

---

#### Option C: Preserve Assignments, Add to New Beats

**Concept**: Don't try to map at all. Keep existing assignments and let writer add new ones.

**Algorithm**:
```swift
When switching from Structure A to Structure B:
  1. Create new Structure B with empty beats
  2. Keep all scenes assigned to old Structure A elements (read-only)
  3. Writer manually assigns scenes to new Structure B beats
  4. Both assignments visible until writer explicitly removes old ones
```

**UI**:
```
Structure Board shows:
┌─────────────────────────┐
│ Three-Act (Previous)    │  [Hide] [Remove]
├─────────────────────────┤
│ Act 1: Scene A, Scene B │ (read-only, greyed)
│ Act 2: Scene C, Scene D │
│ Act 3: Scene E          │
└─────────────────────────┘

┌─────────────────────────┐
│ Hero's Journey (Active) │
├─────────────────────────┤
│ Ordinary World: [empty] │ (drag scenes from above)
│ Call to Adventure: []   │
│ Trials: []              │
│ ...                     │
└─────────────────────────┘
```

**Trade-offs**:
- ✅ Zero data loss (can always see original)
- ✅ No automatic guessing (explicit intent)
- ✅ Can reference old structure while building new
- ⏱️ Requires manual work
- 🔧 Moderate complexity
- 📦 Stores multiple structure assignments per project

---

#### Option D: Structure Templates with Beat Mappings (Future)

**Concept**: Pre-define common migration paths between popular structures.

**Data Structure**:
```swift
struct StructureMigrationTemplate {
    let fromStructure: String  // "Three-Act Structure"
    let toStructure: String    // "Hero's Journey (Simplified)"
    let beatMappings: [BeatMapping]
}

struct BeatMapping {
    let fromBeat: String       // "Act 1"
    let toBeat: String         // "Ordinary World"
    let confidence: Float      // 0.9 (high confidence)
    let splitRule: SplitRule?  // Optional: how to split if toBeat is array
}
```

**Example Migration Template**:
```swift
ThreeActToHerosJourney = StructureMigrationTemplate(
    from: "Three-Act Structure",
    to: "Hero's Journey (Simplified)",
    mappings: [
        ("Act 1", "Ordinary World", 0.9),
        ("Act 1", "Call to Adventure", 0.8),  // Act 1 scenes split
        ("Act 2", "Trials", 0.9),
        ("Act 2", "Transformation", 0.7),     // Act 2 scenes split
        ("Act 3", "Return", 0.9)
    ]
)
```

**Trade-offs**:
- ✅ Accurate for common pairs
- ✅ Respects narrative structure
- ✅ Can be curated by writing experts
- ❌ Only works for defined pairs
- ❌ Maintenance burden (N×M templates)
- 🔧 Need template authoring UI

---

### Discussion Questions

1. **Which approach feels most natural for your writing workflow?**
   - Option A: Interactive preview with drag-and-drop adjustment?
   - Option B: Smart suggestions with confidence scores?
   - Option C: Preserve old, manually build new?
   - Option D: Pre-defined migration templates?

2. **How often do you anticipate switching structures?**
   - Rarely (once per project) → simpler manual approach acceptable
   - Frequently (experimental workflow) → need fast, automated approach

3. **What's more important?**
   - Speed (quick automatic mapping with review)
   - Accuracy (manual control, no mistakes)
   - Education (understanding structure differences)

4. **Should we support "hybrid" structures?**
   - Example: Use Three-Act for overall flow, overlay Hero's Journey for character arc
   - This would require multi-structure support (currently not implemented)

5. **What about "structure history"?**
   - Should we keep a log of structure changes for undo/comparison?
   - Or treat each change as permanent once confirmed?

## Implementation Plan

### Phase 1: Structure Selection UI
1. Add `ProjectStructureSelector` to CardEditorView for new projects
2. Add structure selector to ProjectDashboardView header
3. Add structure indicator to ManuscriptWritingSurfaceView
4. Create `StructureSelectionSheet` component

### Phase 2: Structure Application
1. Add method to ProjectDashboardService:
   ```swift
   func applyStructure(
       to project: Card,
       template: (name: String, elements: [String])
   ) throws
   ```
2. Handle creation of new StoryStructure with `projectID`
3. Handle deletion of old StoryStructure if exists

### Phase 3: Structure Switching with Preservation
1. Add method to ProjectDashboardService:
   ```swift
   func switchStructure(
       project: Card,
       from oldStructure: StoryStructure,
       to newTemplate: (name: String, elements: [String])
   ) throws -> StructureMigrationResult
   ```
2. Implement proportional position mapping algorithm
3. Return migration result showing what changed

### Phase 4: Integration Testing
1. Test structure selection on new project
2. Test structure addition to existing project
3. Test structure switching with scene preservation
4. Test structure removal

## Open Questions

1. **Multiple Projects, Same Structure?**
   - Should writers be able to reuse a structure across projects?
   - Current design: One structure instance per project (copy template each time)
   - Alternative: Share structure instance, filter scenes by project

2. **Structure as Card?**
   - Should StoryStructure be a Card kind instead of separate model?
   - Pros: Consistent with Cumberland's card-centric design
   - Cons: Structure elements would need to be cards or edges

3. **Structure Board Integration?**
   - Should Structure Board be accessible from Project Writer?
   - Via Quick Action Tray?
   - Via dedicated button in Dashboard?

4. **Structure Versioning?**
   - Should we track structure changes over time?
   - Would allow "undo" after structure switch
   - Adds complexity to data model

## Decisions (2026-04-21)

### User Preferences
1. **Entry Points**: Implement both Writing Surface and Dashboard
   - Priority order: Writing Surface first, then Dashboard
   - Writing Surface: Quick Action button for structure selector
   - Dashboard: Structure menu in Structure Band header

2. **Empty Project Behavior**: No interruption
   - Display Writing Surface immediately
   - Show subtle, dismissible message about structure option
   - Writer can begin writing without selecting a structure

3. **Structure Switching Algorithm**: To be designed further
   - Proportional mapping is too imprecise
   - Need better solution before implementation
   - Open for discussion

4. **Structure Board Access**: Quick Action button in Writing Surface

5. **Semantic Mappings**: Defer
   - Don't implement initially
   - Wait until maintenance burden is justified by user need

### Implementation Priority
1. ✅ **Writing Surface Quick Action** (Phase 1a)
2. ✅ **Dashboard Structure Menu** (Phase 1b)
3. ✅ **Subtle structure hint in empty state** (Phase 1c)
4. 🚧 **Structure switching algorithm** (needs design discussion)
5. ⏸️ **Semantic mappings** (deferred)

### Non-Goals (Don't Implement)
1. ❌ **Multiple active structures per project** (too complex)
2. ❌ **Automatic structure detection** (fragile, error-prone)
3. ❌ **AI-suggested structure** (out of scope)
4. ❌ **Forced structure selection on new project** (interrupts writing flow)

## Summary

The proposed design provides:
- **Clear Entry Points**: Structure selection in Dashboard and Writing Surface
- **Flexible Workflow**: Support structure-first or discovery writing
- **Preservation**: Proportional mapping minimizes disruption when switching
- **Simple Implementation**: Builds on existing data model
- **Future-Proof**: Clear path for enhancements

Writers gain a seamless way to organize their work with story structures while maintaining the flexibility to change their mind as their project evolves.
