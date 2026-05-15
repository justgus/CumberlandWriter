# ER-0016 Phase 2: Manual Setup Guide for Test Data

**Purpose:** Step-by-step guide to manually create test data for Multi-Timeline Graph

**Date Created:** 2026-01-29

**Testing Goal:** Verify proper Timeline/Chronicle/Scene hierarchy visualization

---

## Overview

This guide creates test data demonstrating:
- **3 Character Timelines** (Vex, Kael, Lyra)
- **2 Chronicles** appearing on multiple timelines (Northern Campaign, Ancient Discoveries)
- **14 Scenes** (11 grouped under Chronicles, 3 standalone)
- **1 Calendar System** (Imperial Meridian Calendar)

---

## Part 1: Create Calendar System

### Step 1.1: Create Calendar Card

1. Click **"+ New Card"** → Select **"Calendars"** kind
2. Set name: **"Imperial Meridian Calendar"**
3. Save card

### Step 1.2: Configure Calendar Divisions

1. Open **"Imperial Meridian Calendar"** card
2. Click **ellipsis (⋯)** → Edit Calendar
3. Add 5 time divisions:

| Division | Plural | Length | Variable? |
|----------|--------|--------|-----------|
| Epoch | Epochs | 1 | ☑️ Yes |
| Cycle | Cycles | 360 | ☐ No |
| Season | Seasons | 90 | ☐ No |
| Rotation | Rotations | 24 | ☐ No |
| Segment | Segments | 60 | ☐ No |

4. Save calendar

---

## Part 2: Create Characters

### Step 2.1: Create Character Cards

Create 3 Character cards:

1. **Commander Vex**
   - Name: "Commander Vex"
   - Subtitle: "Military Officer"
   - Detailed Text: "Commander Vex leads the Northern Fleet against Syndicate forces."

2. **Merchant Kael**
   - Name: "Merchant Kael"
   - Subtitle: "Supply Captain"
   - Detailed Text: "Merchant Captain Kael runs supply routes in the frontier during the conflict."

3. **Dr. Lyra Chen**
   - Name: "Dr. Lyra Chen"
   - Subtitle: "Scientist"
   - Detailed Text: "Dr. Lyra Chen studies ancient ruins in the frontier, uncovering historical mysteries."

---

## Part 3: Create Timelines

### Step 3.1: Create Timeline Cards

Create 3 Timeline cards:

1. **Vex's Timeline**
   - Name: "Vex's Timeline"
   - Kind: Timelines
   - Subtitle: "Commander Vex's Campaign Story"

2. **Kael's Timeline**
   - Name: "Kael's Timeline"
   - Kind: Timelines
   - Subtitle: "Merchant Kael's Trade Route Story"

3. **Lyra's Timeline**
   - Name: "Lyra's Timeline"
   - Kind: Timelines
   - Subtitle: "Dr. Lyra Chen's Expedition Story"

### Step 3.2: Link Timelines to Calendar

For each Timeline card:

1. Open the Timeline card
2. Click **ellipsis (⋯)** → Flip to back face
3. **Calendar System:** Select "Imperial Meridian Calendar"
4. **Epoch Date:** Set the starting date:
   - Vex's Timeline: Cycle 1847, Spring Season, Rotation 1
   - Kael's Timeline: Cycle 1847, Spring Season, Rotation 8
   - Lyra's Timeline: Cycle 1847, Spring Season, Rotation 20
5. **Epoch Description:** "Beginning of Cycle 1847"
6. Save

### Step 3.3: Link Characters to Timelines (Optional)

Create relationships to associate characters with their timelines:

- **Commander Vex** → **Vex's Timeline**
  - Relation Type: **"has-timeline/timeline-for"**
  - Direction: Vex → Timeline

- **Merchant Kael** → **Kael's Timeline**
  - Relation Type: **"has-timeline/timeline-for"**
  - Direction: Kael → Timeline

- **Dr. Lyra Chen** → **Lyra's Timeline**
  - Relation Type: **"has-timeline/timeline-for"**
  - Direction: Lyra → Timeline

---

## Part 4: Create Chronicles

### Step 4.1: Create Chronicle Cards

Create 2 Chronicle cards:

1. **The Northern Campaign**
   - Name: "The Northern Campaign"
   - Kind: Chronicles
   - Subtitle: "Military Operation Against Syndicate"
   - Detailed Text: "A major military operation in the frontier against Syndicate forces. This Chronicle appears on both Vex's and Kael's timelines from different perspectives."

2. **Ancient Discoveries**
   - Name: "Ancient Discoveries"
   - Kind: Chronicles
   - Subtitle: "Scientific Expedition"
   - Detailed Text: "A scientific expedition uncovering historical mysteries in ancient ruins on planet Kepler-9."

### Step 4.2: Link Chronicles to Timelines

**CRITICAL:** Chronicles must have **temporal bounds** on each Timeline.

#### The Northern Campaign → Vex's Timeline

1. Open **"The Northern Campaign"** card
2. Go to **Relationships** tab
3. Add relationship:
   - **To:** Vex's Timeline
   - **Relation Type:** **"occurs-in/contains-event"**
   - **Direction:** Chronicle → Timeline
4. **Set Temporal Position:**
   - Click edge → Edit
   - **Temporal Position:** Cycle 1847, Spring Season, Rotation 1 (campaign start from Vex's perspective)
   - **Duration:** 150 rotations (in seconds: 150 × 24 × 3600 = 12,960,000 seconds)
5. Save

#### The Northern Campaign → Kael's Timeline

1. Open **"The Northern Campaign"** card
2. Add relationship:
   - **To:** Kael's Timeline
   - **Relation Type:** **"occurs-in/contains-event"**
   - **Direction:** Chronicle → Timeline
3. **Set Temporal Position:**
   - **Temporal Position:** Cycle 1847, Spring Season, Rotation 12 (Kael joins mid-campaign)
   - **Duration:** 120 rotations (in seconds: 120 × 24 × 3600 = 10,368,000 seconds)
4. Save

#### Ancient Discoveries → Lyra's Timeline

1. Open **"Ancient Discoveries"** card
2. Add relationship:
   - **To:** Lyra's Timeline
   - **Relation Type:** **"occurs-in/contains-event"**
   - **Direction:** Chronicle → Timeline
3. **Set Temporal Position:**
   - **Temporal Position:** Cycle 1847, Spring Season, Rotation 20
   - **Duration:** 160 rotations (in seconds: 160 × 24 × 3600 = 13,824,000 seconds)
4. Save

---

## Part 5: Create Scenes

### Step 5.1: Create Scene Cards

Create 14 Scene cards. For each scene:
- Set **Kind:** Scenes
- Add name, subtitle, detailed text

#### Scenes for The Northern Campaign (Vex's perspective)

1. **Fleet Departure**
   - Subtitle: "Northern Fleet Departs Meridian Prime"
   - Detailed Text: "Commander Vex leads the Northern Fleet departure with military honors."

2. **Border Skirmish**
   - Subtitle: "Encounter with Syndicate Scouts"
   - Detailed Text: "Vex's fleet encounters Syndicate scouts at the border."

3. **Station Assault**
   - Subtitle: "Attack on Syndicate Station Theta"
   - Detailed Text: "The fleet attacks Syndicate Station Theta in a major battle."

4. **Campaign Debrief**
   - Subtitle: "Report to High Command"
   - Detailed Text: "Vex reports to High Command on campaign success."

#### Scenes for The Northern Campaign (Kael's perspective)

5. **Supply Contract**
   - Subtitle: "Contract to Supply Military Fleet"
   - Detailed Text: "Kael signs a contract to supply the military fleet."

6. **Dangerous Delivery**
   - Subtitle: "Supply Run Through Hostile Space"
   - Detailed Text: "Kael navigates through hostile space to deliver critical supplies."

7. **Combat Evacuation**
   - Subtitle: "Evacuating Wounded Soldiers"
   - Detailed Text: "Kael evacuates wounded soldiers during the Station Theta assault."

#### Scenes for Ancient Discoveries

8. **Expedition Launch**
   - Subtitle: "Departing the Institute"
   - Detailed Text: "Lyra's team departs the Institute of Meridian Studies."

9. **First Ruins**
   - Subtitle: "Discovery on Planet Kepler-9"
   - Detailed Text: "The team discovers ancient ruins on planet Kepler-9."

10. **Site Survey**
    - Subtitle: "Documenting the Ruin Complex"
    - Detailed Text: "Lyra surveys the complex documenting artifacts."

11. **Breakthrough**
    - Subtitle: "Translating Ancient Inscriptions"
    - Detailed Text: "Lyra translates inscriptions revealing an ancient warning."

#### Standalone Scenes (not in Chronicles)

12. **Intelligence Briefing**
    - Subtitle: "Post-Campaign Intelligence"
    - Detailed Text: "Vex receives intelligence after the campaign ends."
a
13. **Black Market Deal**
    - Subtitle: "Questionable Transaction"
    - Detailed Text: "Kael makes a questionable deal in the black market."

14. **Warning Transmission**
    - Subtitle: "Urgent Warning to Military"
    - Detailed Text: "Lyra transmits an urgent warning to Vex about the ancient threat."

### Step 5.2: Link Scenes to Timelines

**CRITICAL:** All scenes must be placed on a Timeline with temporal position.

#### Scenes on Vex's Timeline (5 scenes)

For each scene, add relationship:
- **Relation Type:** **"appears-in/features"**
- **Direction:** Scene → Timeline
- **Temporal Position:** (dates below)

**HOW TO SET TEMPORAL POSITION WITH CUSTOM CALENDAR:**

1. Open the **Timeline card** (e.g., "Vex's Timeline")
2. Go to the **Timeline tab**
3. Click the **"Edit Positions…"** button (calendar icon with clock badge)
4. Select the scene you want to position from the dropdown menu
5. The **"Temporal Position"** panel opens. You'll see:
   - **"Custom Calendar" / "Standard Date"** toggle at the top
   - Select **"Custom Calendar"**
6. **Enter the calendar division values:**
   - For example: "Cycle 1847, Spring (Season 0), Rotation 1, Segment 8" means:
     - **Cycle:** 1847
     - **Season:** 0 (Spring = season 0, counting from 0)
     - **Rotation:** 1
     - **Segment:** 8
7. **Set Duration:**
   - Use preset picker or "Custom"
   - For custom: Enter in days/hours/minutes
   - Or: Enter total seconds directly
8. Click **Done**

**Season Numbers (for Imperial Meridian Calendar):**
- Season 0 = Spring
- Season 1 = Summer
- Season 2 = Autumn
- Season 3 = Winter

| Scene | Temporal Position | Duration (seconds) |
|-------|-------------------|-------------------|
| Fleet Departure | Cycle 1847, Spring (0), Rotation 1, Segment 8 | 14,400 (4 segments) |
| Border Skirmish | Cycle 1847, Spring (0), Rotation 15, Segment 14 | 10,800 (3 segments) |
| Station Assault | Cycle 1847, Summer (1), Rotation 12, Segment 10 | 129,600 (36 segments) |
| Campaign Debrief | Cycle 1847, Summer (1), Rotation 88, Segment 16 | 28,800 (8 segments) |
| Intelligence Briefing | Cycle 1847, Autumn (2), Rotation 45, Segment 14 | 21,600 (6 segments) |

**Simplified Input Values:**
- Cycle: 1847, Season: 0 (Spring), Rotation: 1, Segment: 8 = Spring rotation 1
- Cycle: 1847, Season: 0 (Spring), Rotation: 15, Segment: 14 = Spring rotation 15
- Cycle: 1847, Season: 1 (Summer), Rotation: 12, Segment: 10 = Summer rotation 12 (12 + 90 = rotation 102 from year start)

**Note:** 1 segment = 3,600 seconds (1 hour)

#### Scenes on Kael's Timeline (4 scenes)

| Scene | Calendar Input (Cycle, Season, Rotation, Segment) | Duration (seconds) |
|-------|--------------------------------------------------|-------------------|
| Supply Contract | 1847, 0, 12, 6 | 28,800 (8 segments) |
| Dangerous Delivery | 1847, 1, 8, 18 | 86,400 (24 segments) |
| Combat Evacuation | 1847, 1, 14, 4 | 21,600 (6 segments) |
| Black Market Deal | 1847, 2, 22, 20 | 18,000 (5 segments) |

#### Scenes on Lyra's Timeline (5 scenes)

| Scene | Calendar Input (Cycle, Season, Rotation, Segment) | Duration (seconds) |
|-------|--------------------------------------------------|-------------------|
| Expedition Launch | 1847, 0, 20, 10 | 14,400 (4 segments) |
| First Ruins | 1847, 0, 35, 14 | 43,200 (12 segments) |
| Site Survey | 1847, 1, 8, 8 | 259,200 (72 segments) |
| Breakthrough | 1847, 2, 2, 12 | 86,400 (24 segments) |
| Warning Transmission | 1847, 2, 60, 18 | 7,200 (2 segments) |

### Step 5.3: Link Scenes to Chronicles

**CRITICAL:** This creates scene grouping under Chronicles.

#### Scenes in The Northern Campaign (Vex's perspective)

For each scene, add relationship:
- **To:** The Northern Campaign
- **Relation Type:** **"part-of/contains"**
- **Direction:** Scene → Chronicle
- **NO temporal position needed** (scene position is on Timeline, not Chronicle)

Scenes to link:
1. Fleet Departure → The Northern Campaign
2. Border Skirmish → The Northern Campaign
3. Station Assault → The Northern Campaign
4. Campaign Debrief → The Northern Campaign

#### Scenes in The Northern Campaign (Kael's perspective)

Scenes to link:
1. Supply Contract → The Northern Campaign
2. Dangerous Delivery → The Northern Campaign
3. Combat Evacuation → The Northern Campaign

#### Scenes in Ancient Discoveries

Scenes to link:
1. Expedition Launch → Ancient Discoveries
2. First Ruins → Ancient Discoveries
3. Site Survey → Ancient Discoveries
4. Breakthrough → Ancient Discoveries

#### Standalone Scenes (NO Chronicle relationship)

These scenes should NOT have Scene→Chronicle relationships:
- Intelligence Briefing (standalone on Vex's Timeline)
- Black Market Deal (standalone on Kael's Timeline)
- Warning Transmission (standalone on Lyra's Timeline)

---

## Part 6: View Multi-Timeline Graph

### Step 6.1: Open Multi-Timeline Graph

1. Open **"Imperial Meridian Calendar"** card
2. Navigate to **Multi-Timeline Graph** tab
3. You should see:

**Expected Visualization:**

```
Timeline Track: "Vex's Timeline" (blue)
├─[═══════ The Northern Campaign ═══════]  ← Chronicle lozenge
│   ├─● Fleet Departure                    ← Scene marker inside chronicle
│   ├─● Border Skirmish
│   ├─● Station Assault
│   └─● Campaign Debrief
└─● Intelligence Briefing                   ← Standalone scene marker

Timeline Track: "Kael's Timeline" (purple)
├─[═══════ The Northern Campaign ═══════]  ← Same chronicle, different bounds
│   ├─● Supply Contract
│   ├─● Dangerous Delivery
│   └─● Combat Evacuation
└─● Black Market Deal                       ← Standalone scene marker

Timeline Track: "Lyra's Timeline" (pink)
├─[═════════ Ancient Discoveries ═════════] ← Chronicle lozenge
│   ├─● Expedition Launch
│   ├─● First Ruins
│   ├─● Site Survey
│   └─● Breakthrough
└─● Warning Transmission                    ← Standalone scene marker
```

### Step 6.2: Verify Features

✅ **Check these features:**

1. **Timeline Tracks:** 3 horizontal lanes (Vex, Kael, Lyra) with different colors
2. **Chronicle Lozenges:** Semi-transparent rounded rectangles spanning temporal bounds
3. **"The Northern Campaign" appears on TWO timelines** with different start/end dates
4. **Scene Markers:** Small bars with labels at exact temporal positions
5. **Scenes inside Chronicles:** 11 scenes within lozenge bounds
6. **Standalone Scenes:** 3 scenes outside any lozenge
7. **Zoom Controls:** Can zoom in/out and pan along timeline
8. **Track Toggles:** Can show/hide individual timeline tracks

---

## Troubleshooting

### Chronicles not appearing?

- Check Chronicle→Timeline relationship has **temporal position AND duration** set
- Duration must be > 0
- Temporal position must be within Timeline's epoch range

### Scenes not appearing?

- Check Scene→Timeline relationship has **temporal position** set
- Temporal position must be a valid Date
- Scene must be on an enabled Timeline track

### Scenes not grouped under Chronicle?

- Check Scene→Chronicle relationship exists with **"part-of/contains"** relation type
- Scene must also be on the same Timeline as the Chronicle

### Chronicle appears on wrong Timeline?

- Check Chronicle→Timeline relationships
- Each Chronicle can have multiple Chronicle→Timeline edges
- Each edge should point to a different Timeline

---

## Relation Types Reference

| Relationship | Relation Type | Direction | Temporal Data? |
|--------------|---------------|-----------|----------------|
| Character → Timeline | `has-timeline/timeline-for` | Character → Timeline | No |
| Chronicle → Timeline | `occurs-in/contains-event` | Chronicle → Timeline | ✅ **Position + Duration** |
| Scene → Timeline | `appears-in/features` | Scene → Timeline | ✅ **Position + Duration** |
| Scene → Chronicle | `part-of/contains` | Scene → Chronicle | ❌ No |

**Key Points:**
- Chronicle→Timeline edges define Chronicle's temporal span (lozenge bounds)
- Scene→Timeline edges define Scene's temporal position (marker placement)
- Scene→Chronicle edges group Scene under Chronicle (visual nesting)
- Only Chronicle→Timeline and Scene→Timeline need temporal data

---

## Summary

**Total Cards Created:**
- 1 Calendar (Imperial Meridian Calendar)
- 3 Characters (Vex, Kael, Lyra)
- 3 Timelines (Vex's, Kael's, Lyra's)
- 2 Chronicles (Northern Campaign, Ancient Discoveries)
- 14 Scenes (11 in Chronicles, 3 standalone)

**Total Relationships:**
- 3 Character→Timeline (optional)
- 3 Chronicle→Timeline (with temporal bounds)
- 14 Scene→Timeline (with temporal positions)
- 11 Scene→Chronicle (grouping)

**Total: 23 cards, 31 relationships**

---

*Guide Created: 2026-01-29*
*For: ER-0016 Phase 2 Testing*
