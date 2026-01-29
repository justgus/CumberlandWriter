# ER-0016 Phase 2 Test Prompt: Timeline/Chronicle/Scene Hierarchy

**Purpose:** Test proper Timeline/Chronicle/Scene hierarchy with Chronicles appearing on multiple Timelines

**Date Created:** 2026-01-29

**Conceptual Model:**
- **Timeline** = Character's full storyline/lifeline
- **Chronicle** = Historical event with temporal bounds (can appear on multiple timelines)
- **Scene** = Specific moment (grouped under Chronicle or standalone)

---

## COPY THIS INTO A PROJECT CARD'S DETAILED TEXT

---

### The Meridian Chronicles: Timeline/Chronicle/Scene Test

This project demonstrates three character timelines with shared Chronicles in the Meridian Empire.

#### Calendar System: Imperial Meridian Calendar

The Imperial Meridian Calendar has five divisions: **Epochs** (eras), **Cycles** (years, 360 rotations each), **Seasons** (quarters, 4 per cycle), **Rotations** (days), and **Segments** (hours, 24 per rotation). Current date: Cycle 1847, Autumn Season, Rotation 60.

#### Character: Commander Vex

Commander Vex is a military officer leading the Northern Fleet.

#### Character: Merchant Kael

Merchant Captain Kael runs supply routes in the frontier.

#### Character: Dr. Lyra Chen

Dr. Lyra Chen is a scientist studying ancient ruins.

#### Timeline: Vex's Timeline

This timeline represents Commander Vex's life and experiences during Cycle 1847. It begins on Cycle 1847, Spring Season, Rotation 1.

#### Timeline: Kael's Timeline

This timeline represents Merchant Kael's life and experiences during Cycle 1847. It begins on Cycle 1847, Spring Season, Rotation 8.

#### Timeline: Lyra's Timeline

This timeline represents Dr. Lyra Chen's life and experiences during Cycle 1847. It begins on Cycle 1847, Spring Season, Rotation 20.

#### Chronicle: The Northern Campaign

The Northern Campaign is a military operation against Syndicate forces in the frontier. This Chronicle appears on both Vex's Timeline and Kael's Timeline.

**On Vex's Timeline:** The Northern Campaign begins on Cycle 1847, Spring Season, Rotation 1 and lasts 150 rotations (through mid-Summer).

**On Kael's Timeline:** The Northern Campaign begins on Cycle 1847, Spring Season, Rotation 12 and lasts 120 rotations (Kael joins mid-campaign).

**Scenes in The Northern Campaign (Vex's perspective):**

**Fleet Departure** is a scene in The Northern Campaign. It occurs on Cycle 1847, Spring Season, Rotation 1, Segment 8 and lasts 4 segments. Commander Vex leads the Northern Fleet departure from Meridian Prime with military honors.

**Border Skirmish** is a scene in The Northern Campaign. It takes place on Cycle 1847, Spring Season, Rotation 15, Segment 14 and lasts 3 segments. Vex's fleet encounters Syndicate scouts at the border.

**Station Assault** is a scene in The Northern Campaign. It occurs on Cycle 1847, Summer Season, Rotation 12, Segment 10 and lasts 36 segments. The fleet attacks Syndicate Station Theta in a major battle.

**Campaign Debrief** is a scene in The Northern Campaign. It happens on Cycle 1847, Summer Season, Rotation 88, Segment 16 and lasts 8 segments. Vex reports to High Command on campaign success.

**Scenes in The Northern Campaign (Kael's perspective):**

**Supply Contract** is a scene in The Northern Campaign. It occurs on Cycle 1847, Spring Season, Rotation 12, Segment 6 and lasts 8 segments. Kael signs a contract to supply the military fleet.

**Dangerous Delivery** is a scene in The Northern Campaign. It takes place on Cycle 1847, Summer Season, Rotation 8, Segment 18 and lasts 24 segments. Kael navigates through hostile space to deliver critical supplies.

**Combat Evacuation** is a scene in The Northern Campaign. It happens on Cycle 1847, Summer Season, Rotation 14, Segment 4 and lasts 6 segments. Kael evacuates wounded soldiers during the Station Theta assault.

#### Chronicle: Ancient Discoveries

Ancient Discoveries is a scientific expedition uncovering historical mysteries. This Chronicle appears only on Lyra's Timeline.

**On Lyra's Timeline:** Ancient Discoveries begins on Cycle 1847, Spring Season, Rotation 20 and lasts 160 rotations (through Autumn).

**Scenes in Ancient Discoveries:**

**Expedition Launch** is a scene in Ancient Discoveries. It occurs on Cycle 1847, Spring Season, Rotation 20, Segment 10 and lasts 4 segments. Lyra's team departs the Institute.

**First Ruins** is a scene in Ancient Discoveries. It takes place on Cycle 1847, Spring Season, Rotation 35, Segment 14 and lasts 12 segments. The team discovers ancient ruins on planet Kepler-9.

**Site Survey** is a scene in Ancient Discoveries. It happens on Cycle 1847, Summer Season, Rotation 8, Segment 8 and lasts 72 segments. Lyra surveys the complex documenting artifacts.

**Breakthrough** is a scene in Ancient Discoveries. It occurs on Cycle 1847, Autumn Season, Rotation 2, Segment 12 and lasts 24 segments. Lyra translates inscriptions revealing an ancient warning.

**Scenes outside Chronicles (standalone):**

**Intelligence Briefing** is a standalone scene on Vex's Timeline. It occurs on Cycle 1847, Autumn Season, Rotation 45, Segment 14 and lasts 6 segments. Vex receives intelligence after the campaign ends.

**Black Market Deal** is a standalone scene on Kael's Timeline. It takes place on Cycle 1847, Autumn Season, Rotation 22, Segment 20 and lasts 5 segments. Kael makes a questionable deal.

**Warning Transmission** is a standalone scene on Lyra's Timeline. It happens on Cycle 1847, Autumn Season, Rotation 60, Segment 18 and lasts 2 segments. Lyra transmits an urgent warning to Vex about the ancient threat discovered in her research.

---

## Post-Analysis Steps

1. **Run Content Analysis** - Accept entity and calendar suggestions
2. **Create Chronicle Cards** - If not auto-created, manually create:
   - "The Northern Campaign" (kind: Chronicles)
   - "Ancient Discoveries" (kind: Chronicles)
3. **Link Timelines to Calendar** - Assign calendar and set epoch dates
4. **Link Chronicles to Timelines** - Create relationships:
   - "The Northern Campaign" → "Vex's Timeline" (edge with temporal position + duration)
   - "The Northern Campaign" → "Kael's Timeline" (edge with temporal position + duration)
   - "Ancient Discoveries" → "Lyra's Timeline" (edge with temporal position + duration)
5. **Link Scenes to Timelines** - Create relationships with temporal positions
6. **Link Scenes to Chronicles** - Group scenes under their parent chronicles
7. **View Multi-Timeline Graph** - Open Calendar card → Multi-Timeline Graph tab

**Expected Results:**
- 3 Timeline tracks (Vex, Kael, Lyra)
- "The Northern Campaign" appears as lozenge on TWO timelines (Vex and Kael) with different bounds
- "Ancient Discoveries" appears as lozenge on ONE timeline (Lyra)
- 7 scenes appear inside Chronicle lozenges (4 in Campaign on Vex, 3 in Campaign on Kael, 4 in Discoveries)
- 3 scenes appear as standalone markers (outside Chronicles)
- Total: 14 scenes, 3 timelines, 2 chronicles, 1 calendar

**Key Tests:**
- ✅ Same Chronicle ("Northern Campaign") on multiple timelines with different temporal bounds
- ✅ Scenes grouped under Chronicles
- ✅ Scenes standalone (not in any Chronicle)
- ✅ Proper visual hierarchy: tracks → lozenges → markers

---

**Word Count:** ~980 words
