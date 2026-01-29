# Test Data Generation Prompt: Multi-Timeline Graph

**Purpose:** Generate test data for the Multi-Timeline Graph feature (Phase 8, ER-0008)

**Date Created:** 2026-01-28

---

## Prompt for AI Provider (GPT-4, Claude, etc.)

Use this prompt to generate detailed test data that can be manually entered into Cumberland to test the Multi-Timeline Graph visualization:

---

### PROMPT START

I need you to generate comprehensive test data for a multi-timeline visualization feature in a worldbuilding application. Please create the following:

**1. ONE CALENDAR SYSTEM**
- Name: Something fantasy/sci-fi appropriate
- Description: Brief explanation of the calendar
- Time Divisions: Define at least 3 hierarchical time divisions (e.g., Year → Month → Day, or Era → Cycle → Phase)
  - For each division, specify: name, plural form, abbreviation, count-in-parent (how many of this unit make up one parent unit)

**2. THREE TO FIVE TIMELINES**
- Each timeline should represent a different storyline or character arc
- All timelines must use the same calendar system created above
- For each timeline, provide:
  - Name (e.g., "Kira's Journey", "The War Campaign", "Merchant Guild Rise")
  - Subtitle (brief description)
  - Epoch date (a starting point for the timeline, in the calendar format)
  - Epoch description (what this date represents)

**3. SCENES FOR EACH TIMELINE**
- Create 5-10 scenes per timeline
- Scenes should have temporal overlap between timelines (some events happening simultaneously)
- For each scene, provide:
  - Name (brief, descriptive)
  - Temporal position (specific date/time in the calendar system)
  - Duration (how long the scene lasts - from 1 hour to several days)
  - Brief description

**REQUIREMENTS:**
- Use a consistent calendar system across all timelines
- Ensure temporal positions create interesting overlaps (e.g., two characters in different timelines having scenes at the same time)
- Vary scene durations (short events like battles, long events like journeys)
- Dates should span at least 6 months to 2 years in the calendar system
- Make the content fantasy or sci-fi themed for worldbuilding context

**OUTPUT FORMAT:**
Present the data in a structured format with clear sections:
1. Calendar System Details
2. Timeline 1 (with all scenes)
3. Timeline 2 (with all scenes)
4. Timeline 3 (with all scenes)
... etc.

For temporal positions, use a format like: "Year 1423, Month of Harvest, Day 15, Hour 14:00"
For durations, use formats like: "2 hours", "3 days", "1 week"

### PROMPT END

---

## Example Output Structure

Below is an example of what the AI should generate:

### Calendar System: Eridani Standard Time

**Description:** The official calendar of the Eridani Empire, based on the orbital period of the capital world.

**Time Divisions:**
1. **Epoch** (Eras in history)
   - Plural: Epochs
   - Abbreviation: E
   - (No parent - top level)

2. **Cycle** (Equivalent to years)
   - Plural: Cycles
   - Abbreviation: CY
   - Count in parent Epoch: Varies by historical era

3. **Phase** (Equivalent to months)
   - Plural: Phases
   - Abbreviation: PH
   - Count in parent Cycle: 10 phases per cycle

4. **Rotation** (Equivalent to days)
   - Plural: Rotations
   - Abbreviation: R
   - Count in parent Phase: 36 rotations per phase

5. **Segment** (Equivalent to hours)
   - Plural: Segments
   - Abbreviation: S
   - Count in parent Rotation: 20 segments per rotation

---

### Timeline 1: Commander Aria's Campaign

**Subtitle:** The Northern Offensive against the Syndicate
**Epoch Date:** Cycle 2847, Phase 1, Rotation 1, Segment 0
**Epoch Description:** Launch of the Northern Fleet

**Scenes:**

1. **Fleet Departure**
   - Temporal Position: Cycle 2847, Phase 1, Rotation 1, Segment 8
   - Duration: 4 segments (4 hours)
   - Description: The fleet departs from Eridani Prime with full military honors.

2. **First Contact**
   - Temporal Position: Cycle 2847, Phase 2, Rotation 15, Segment 12
   - Duration: 2 segments
   - Description: Initial skirmish with Syndicate scouts near the border.

3. **Strategic Planning**
   - Temporal Position: Cycle 2847, Phase 3, Rotation 5, Segment 6
   - Duration: 8 segments
   - Description: War council convenes to plan the assault on Station Theta.

... (continue with 7-10 total scenes)

---

### Timeline 2: Merchant Kael's Trade Route

**Subtitle:** Establishing the Outer Rim supply lines
**Epoch Date:** Cycle 2847, Phase 1, Rotation 10, Segment 0
**Epoch Description:** First successful cargo run to the frontier

**Scenes:**

1. **Cargo Acquisition**
   - Temporal Position: Cycle 2847, Phase 1, Rotation 10, Segment 14
   - Duration: 12 segments
   - Description: Negotiating for medical supplies and rare minerals.

2. **Jump to Frontier**
   - Temporal Position: Cycle 2847, Phase 2, Rotation 3, Segment 6
   - Duration: 5 rotations (transit time)
   - Description: Hyperspace jump through unstable corridors.

... (continue with scenes, some overlapping with Timeline 1's dates)

---

## Manual Data Entry Steps

After generating the data with the AI prompt above, follow these steps to enter it into Cumberland:

### Step 1: Create Calendar Card
1. Create new card with kind = "Calendars"
2. Enter name and subtitle from generated data
3. In Details tab, click "Create Calendar System"
4. Enter the time divisions from the generated data

### Step 2: Create Timeline Cards
1. For each timeline in generated data:
   - Create new card with kind = "Timelines"
   - Enter name and subtitle
   - Flip to back (ellipsis menu)
   - Select the calendar system created in Step 1
   - Set epoch date and description

### Step 3: Create Scene Cards
1. For each scene in the generated data:
   - Create new card with kind = "Scenes"
   - Enter name and description
   - Create relationship: Scene → Timeline using "describes/described-by"

### Step 4: Set Temporal Positions
1. Open each Timeline card
2. Go to Timeline tab (should show temporal mode)
3. Click "Edit Positions..." menu
4. For each scene, set:
   - Temporal position (date/time from generated data)
   - Duration (from generated data)

### Step 5: View Multi-Timeline Graph
1. Open the Calendar card created in Step 1
2. Navigate to Tab 3 (Timeline / Multi-Timeline)
3. Should see all timelines with scenes visualized on shared calendar axis
4. Use zoom controls to adjust view
5. Toggle timeline tracks on/off to test visibility
6. Click scenes to view details

---

## Expected Test Results

When viewing the Multi-Timeline Graph with this test data, you should observe:

✅ Multiple colored timeline tracks (one per timeline)
✅ Scenes displayed as bars with durations on shared X-axis
✅ Temporal overlaps visible (scenes from different timelines at same time)
✅ Zoom controls functional (7 levels from hour to century)
✅ Synchronized scroll across all tracks
✅ Track toggles work to show/hide timelines
✅ Scene labels visible on bars
✅ Tapping scenes shows detail sheet
✅ Empty states work (when all tracks hidden, or no temporal scenes)

---

**Note:** This test data generation approach allows you to use the AI capabilities already in Cumberland to help create complex test scenarios for the multi-timeline feature.
