# Narrative Arc Functions for Story Structures

## Concept

Each story structure has an inherent **dramatic tension curve** that defines the rise and fall of narrative intensity across its beats. This curve serves two purposes:

1. **Visualization**: Display as sparkline/wave in Project Dashboard Structure Band
2. **Scene Mapping**: Use arc position and slope to intelligently map scenes when switching structures

## Narrative Arc as Function

Each structure's arc is defined as a function `f(x)` where:
- **x**: Normalized position (0.0 to 1.0) through the structure
- **f(x)**: Tension/intensity level (0.0 to 1.0)

### Example: Three-Act Structure

```
Tension
1.0 ┤                                        ╱╲
    │                                       ╱  ╲
    │                                      ╱    ╲
0.7 ┤                           ╱╲        ╱      ╲
    │                          ╱  ╲      ╱        ╲
    │                         ╱    ╲    ╱          ╲
0.5 ┤              ╱╲        ╱      ╲  ╱            ╲
    │             ╱  ╲      ╱        ╲╱              ╲
    │            ╱    ╲    ╱                          ╲
0.3 ┤    ╱╲     ╱      ╲  ╱                            ╲
    │   ╱  ╲   ╱        ╲╱                              ╲
    │  ╱    ╲ ╱                                          ╲
0.0 ┴─╱──────╲──────────────────────────────────────────╲─→
    0.0     0.33      0.5       0.67      0.83          1.0
    │        │         │          │         │            │
   Start   Act 1    Midpoint   Act 2    Climax         End
         Turning             Turning
          Point               Point

Beats:
- Act 1 (0.0 - 0.33): Rising action, ends at first turning point
- Act 2 (0.33 - 0.67): Rising tension with midpoint peak
- Act 3 (0.67 - 1.0): Climax (0.83), then falling action to resolution
```

**Mathematical Definition**:
```swift
func threeActArc(x: Double) -> Double {
    switch x {
    case 0.0..<0.33:   // Act 1: Gentle rise
        return 0.3 + (x / 0.33) * 0.2  // 0.3 → 0.5
    case 0.33..<0.5:   // Early Act 2: Continued rise
        return 0.5 + ((x - 0.33) / 0.17) * 0.2  // 0.5 → 0.7
    case 0.5..<0.67:   // Late Act 2: Rise to second turning point
        return 0.7 + ((x - 0.5) / 0.17) * 0.1  // 0.7 → 0.8
    case 0.67..<0.83:  // Act 3: Rise to climax
        return 0.8 + ((x - 0.67) / 0.16) * 0.2  // 0.8 → 1.0
    default:           // Act 3: Falling action
        return 1.0 - ((x - 0.83) / 0.17) * 0.3  // 1.0 → 0.7
    }
}
```

## Structure Arc Definitions

### Five-Act Structure (Freytag's Pyramid)

```
Tension
1.0 ┤                    ╱╲
    │                   ╱  ╲
    │                  ╱    ╲
0.8 ┤                 ╱      ╲
    │                ╱        ╲
    │          ╱╲   ╱          ╲
0.6 ┤         ╱  ╲ ╱            ╲
    │        ╱    ╲╱              ╲
    │   ╱╲  ╱                      ╲
0.4 ┤  ╱  ╲╱                        ╲
    │ ╱                              ╲
    │╱                                ╲
0.0 ┴──────────────────────────────────╲─→
    0.0  0.2   0.4   0.6   0.8        1.0
    │     │     │     │     │          │
  Expo Rising Climax Fall  Resol     End

Beats:
1. Exposition (0.0 - 0.2): Setup, rising from baseline
2. Rising Action (0.2 - 0.4): First complications
3. Climax (0.4 - 0.6): Peak tension
4. Falling Action (0.6 - 0.8): Consequences unfold
5. Resolution (0.8 - 1.0): Denouement
```

**Key Characteristic**: Classic pyramid shape, peak at 60% mark (different from Three-Act's 83% climax).

---

### Hero's Journey (12-Stage)

```
Tension
1.0 ┤                                  ╱╲
    │                                 ╱  ╲╲
    │                                ╱    ╲╲
0.8 ┤                          ╱╲   ╱      ╲╲
    │                         ╱  ╲ ╱        ╲╲
    │                    ╱╲  ╱    ╲          ╲╲
0.6 ┤               ╱╲  ╱  ╲╱                 ╲╲
    │          ╱╲  ╱  ╲╱                        ╲╲
    │     ╱╲  ╱  ╲╱                              ╲╲
0.4 ┤    ╱  ╲╱                                    ╲╲
    │   ╱                                          ╲╲
    │  ╱                                            ╲
0.0 ┴─╱──────────────────────────────────────────────╲─→
    0.0    0.25    0.5     0.67    0.83           1.0
    │       │       │        │       │              │
  Ord.   Mentor  Ordeal  Road   Resurr.         Return
  World          (peak)  Back

Beats (12 stages mapped to tension):
1. Ordinary World (0.0 - 0.08): Baseline
2. Call to Adventure (0.08 - 0.17): First rise
3. Refusal of Call (0.17 - 0.25): Slight dip
4. Meeting Mentor (0.25 - 0.33): Rise
5. Crossing Threshold (0.33 - 0.42): Significant rise
6. Tests/Allies/Enemies (0.42 - 0.5): Building tension
7. Approach Inmost Cave (0.5 - 0.58): Pre-climax rise
8. **Ordeal** (0.58 - 0.67): PEAK (death/rebirth)
9. Reward (0.67 - 0.75): Post-climax plateau
10. Road Back (0.75 - 0.83): Rising for second peak
11. **Resurrection** (0.83 - 0.92): Second peak
12. Return with Elixir (0.92 - 1.0): Resolution
```

**Key Characteristic**: Two peaks (Ordeal at 62%, Resurrection at 87%), mimics mythological death-and-rebirth pattern.

---

### Save the Cat (15 Beats)

```
Tension
1.0 ┤                                    ╱╲
    │                                   ╱  ╲
    │                              ╱╲  ╱    ╲
0.8 ┤                         ╱╲  ╱  ╲╱      ╲
    │                    ╱╲  ╱  ╲╱             ╲
    │               ╱╲  ╱  ╲╱                   ╲
0.6 ┤          ╱╲  ╱  ╲╱                         ╲
    │     ╱╲  ╱  ╲╱                               ╲
    │    ╱  ╲╱                                     ╲
0.4 ┤   ╱                                           ╲
    │  ╱                                             ╲
    │ ╱                                               ╲
0.0 ┴╱─────────────────────────────────────────────────╲─→
    0.0    0.2    0.4    0.6    0.8                  1.0
    │       │      │      │      │                     │
  Open  Break  Midpt  Bad  Dark                     Final
  Image  Two          Guys  Night                   Image

Beats (15 stages):
1. Opening Image (0.0 - 0.07): Setup
2. Theme Stated (0.07 - 0.13): Initial tension
3. Setup (0.13 - 0.2): World building
4. Catalyst (0.2 - 0.27): Inciting incident
5. Debate (0.27 - 0.33): Rising
6. **Break into Two** (0.33 - 0.4): Act 1 → Act 2 transition
7. B Story (0.4 - 0.47): Relationship subplot
8. Fun and Games (0.47 - 0.53): "Promise of the premise"
9. **Midpoint** (0.53 - 0.6): False victory/defeat
10. Bad Guys Close In (0.6 - 0.67): Rising threat
11. **All Is Lost** (0.67 - 0.73): Lowest point
12. Dark Night of the Soul (0.73 - 0.8): Reflection before climax
13. **Break into Three** (0.8 - 0.87): Act 2 → Act 3
14. **Finale** (0.87 - 0.93): Climax
15. Final Image (0.93 - 1.0): Resolution mirror
```

**Key Characteristic**: Highly structured with specific "beat percentages", midpoint at 50%, climax at 90%.

---

### Academic Paper (IMRaD Structure)

```
Tension (Complexity/Depth)
0.8 ┤          ┌────────────────┐
    │          │                │
    │          │    Results     │
0.6 ┤          │   Discussion   │
    │          │                │
    │    ┌─────┘                └─────┐
0.4 ┤    │                            │
    │    │  Methods                   │  Conclusion
    │    │                            │
0.2 ┤ ┌──┘                            └──┐
    │ │                                  │
    │ │ Intro                            │
0.0 ┴─┴────────────────────────────────────┴─→
    0.0   0.2   0.4   0.6   0.8        1.0
    │      │     │     │     │          │
  Title  Intro Meth  Res   Disc      Concl

Beats:
1. Title/Abstract (0.0 - 0.1): Flat, introductory
2. Introduction (0.1 - 0.25): Rising to problem statement
3. Methods (0.25 - 0.45): Plateau at medium complexity
4. Results (0.45 - 0.65): Peak complexity (data presentation)
5. Discussion (0.65 - 0.85): Sustained high complexity (interpretation)
6. Conclusion (0.85 - 1.0): Falling to summary
```

**Key Characteristic**: Plateau-based rather than peaks, complexity rises then sustains before falling.

---

### Technical Document

```
Tension (Detail Density)
0.6 ┤        ┌──────────────────────────────┐
    │        │                              │
    │        │   Implementation Details     │
0.4 ┤        │   API Reference              │
    │        │   Configuration              │
    │  ┌─────┘                              └────┐
0.2 ┤  │                                         │
    │  │ Overview                           Usage│
    │  │ Requirements                       Guide│
0.0 ┴──┴──────────────────────────────────────────┴─→
    0.0   0.2   0.4   0.6   0.8           1.0
    │      │     │     │     │             │
  Title  Over  Arch  Impl  Config       Append

Beats:
1. Title/Overview (0.0 - 0.15): Low detail, high-level
2. Requirements/Architecture (0.15 - 0.3): Rising detail
3. Implementation (0.3 - 0.5): Peak detail density
4. API Reference (0.5 - 0.65): Sustained peak (reference material)
5. Configuration (0.65 - 0.8): Sustained complexity
6. Usage Examples (0.8 - 0.9): Falling (practical application)
7. Appendix (0.9 - 1.0): Low detail (supplementary)
```

**Key Characteristic**: Extended plateau of high detail in middle, symmetrical rise/fall around it.

---

### Beginning-Middle-End (Simple 3-Part)

```
Tension
1.0 ┤                           ╱╲
    │                          ╱  ╲
    │                         ╱    ╲
0.8 ┤                        ╱      ╲
    │                       ╱        ╲
    │              ╱╲      ╱          ╲
0.6 ┤             ╱  ╲    ╱            ╲
    │            ╱    ╲  ╱              ╲
    │     ╱╲    ╱      ╲╱                ╲
0.4 ┤    ╱  ╲  ╱                          ╲
    │   ╱    ╲╱                            ╲
    │  ╱                                    ╲
0.0 ┴─╱──────────────────────────────────────╲─→
    0.0      0.33           0.67           1.0
    │         │              │              │
  Start   Beginning       Middle          End

Beats:
- Beginning (0.0 - 0.33): Introduction and setup, gentle rise
- Middle (0.33 - 0.67): Complications and rising action to climax
- End (0.67 - 1.0): Climax and resolution
```

**Key Characteristic**: Simplified Three-Act, smooth continuous rise to peak at 75%, then fall.

---

### Four-Part Structure

```
Tension
1.0 ┤                                 ╱╲
    │                                ╱  ╲
    │                               ╱    ╲
0.8 ┤                          ╱╲  ╱      ╲
    │                         ╱  ╲╱        ╲
    │                  ╱╲    ╱               ╲
0.6 ┤                 ╱  ╲  ╱                 ╲
    │          ╱╲    ╱    ╲╱                   ╲
    │         ╱  ╲  ╱                           ╲
0.4 ┤   ╱╲   ╱    ╲╱                             ╲
    │  ╱  ╲ ╱                                     ╲
    │ ╱    ╱                                       ╲
0.0 ┴╱────╱─────────────────────────────────────────╲─→
    0.0  0.25      0.5       0.75                 1.0
    │     │         │          │                   │
   Setup Confr    Resol      Epil                End

Beats:
1. Setup (0.0 - 0.25): Introduction and initial conflict
2. Confrontation (0.25 - 0.5): Rising tension and complications
3. Resolution (0.5 - 0.75): Climax and main conflict resolution
4. Epilogue (0.75 - 1.0): Aftermath and final resolution
```

**Key Characteristic**: Four distinct phases with climax at 60-65%, extended epilogue.

---

### Novel (12-Beat Structure)

```
Tension
1.0 ┤                                    ╱╲
    │                                   ╱  ╲
    │                              ╱╲  ╱    ╲
0.8 ┤                         ╱╲  ╱  ╲╱      ╲
    │                    ╱╲  ╱  ╲╱             ╲
    │               ╱╲  ╱  ╲╱                   ╲
0.6 ┤          ╱╲  ╱  ╲╱                         ╲
    │     ╱╲  ╱  ╲╱                               ╲
    │    ╱  ╲╱                                     ╲
0.4 ┤   ╱                                           ╲
    │  ╱                                             ╲
    │ ╱                                               ╲
0.0 ┴╱─────────────────────────────────────────────────╲─→
    0.0   0.17  0.33  0.5   0.67  0.83             1.0
    │      │     │     │     │     │                │
   Open  Inc  1st PP Midpt 2nd PP Climax          Res

Beats (12 stages):
1. Opening Image (0.0 - 0.08): Hook
2. Hook (0.08 - 0.17): Initial pull
3. Inciting Incident (0.17 - 0.25): Story begins
4. Key Event (0.25 - 0.33): Commitment
5. First Plot Point (0.33 - 0.42): Raise stakes
6. First Pinch Point (0.42 - 0.5): Pressure increases
7. Midpoint (0.5 - 0.58): False victory/defeat
8. Second Pinch Point (0.58 - 0.67): Tightening vise
9. Second Plot Point (0.67 - 0.75): Lowest point
10. Climax (0.75 - 0.83): Peak tension
11. Resolution (0.83 - 0.92): Unwinding
12. Epilogue (0.92 - 1.0): Final image
```

**Key Characteristic**: Similar to Save the Cat but with specific pinch points, dual peaks (midpoint at 50%, climax at 80%).

---

### Short Story (6-Beat Compact Arc)

```
Tension
1.0 ┤                      ╱╲
    │                     ╱  ╲
    │                    ╱    ╲
0.8 ┤                   ╱      ╲
    │              ╱╲  ╱        ╲
    │             ╱  ╲╱          ╲
0.6 ┤            ╱                ╲
    │       ╱╲  ╱                  ╲
    │      ╱  ╲╱                    ╲
0.4 ┤     ╱                          ╲
    │    ╱                            ╲
    │   ╱                              ╲
0.0 ┴──╱────────────────────────────────╲─→
    0.0   0.17  0.33  0.5   0.67     0.83 1.0
    │      │     │     │     │         │   │
  Setup  Inc   Rising Climax Fall    Resol

Beats:
1. Setup (0.0 - 0.17): Quick introduction
2. Inciting Incident (0.17 - 0.33): Story trigger
3. Rising Action (0.33 - 0.5): Build tension quickly
4. Climax (0.5 - 0.67): Peak (earlier than novels)
5. Falling Action (0.67 - 0.83): Quick resolution
6. Resolution (0.83 - 1.0): Denouement
```

**Key Characteristic**: Compressed arc, climax at 58% (earlier than longer forms), quick fall.

---

### Term Paper (10-Section Academic)

```
Complexity
0.7 ┤             ┌──────────────┐
    │             │              │
    │             │   Results    │
0.6 ┤             │  Discussion  │
    │      ┌──────┘              └──────┐
    │      │                            │
0.5 ┤      │  Lit Review                │ Conclusion
    │      │  Methodology               │
    │ ┌────┘                            └────┐
0.4 ┤ │                                      │
    │ │ Intro                                │ Refs
    │ │                                      │
0.3 ┤ │                                      │ Append
    │ │                                      │
0.2 ┤ │                                      └─────┐
    │ │ Abstract                                   │
0.1 ┤ │                                            │
    │ │                                            │
0.0 ┴─┴────────────────────────────────────────────┴─→
    0.0  0.1  0.2  0.3  0.4  0.5  0.6  0.8      1.0
    │     │    │    │    │    │    │    │        │
  Title Abs Intro Lit Meth Res Disc Conc      Append

Beats:
1. Title Page (0.0 - 0.05): Minimal complexity
2. Abstract (0.05 - 0.1): Low, summary
3. Introduction (0.1 - 0.2): Rising, problem statement
4. Literature Review (0.2 - 0.3): Medium complexity, context
5. Methodology (0.3 - 0.45): Rising to detailed procedures
6. Results (0.45 - 0.6): Peak complexity (data/analysis)
7. Discussion (0.6 - 0.75): Sustained peak (interpretation)
8. Conclusion (0.75 - 0.85): Falling, synthesis
9. References (0.85 - 0.95): Low, citations
10. Appendices (0.95 - 1.0): Low, supplementary
```

**Key Characteristic**: Academic structure with plateau at Results/Discussion, symmetrical rise/fall.

---

### White Paper (11-Section Business/Strategy)

```
Complexity
0.7 ┤                  ┌───────────┐
    │                  │           │
    │                  │ Proposed  │
0.6 ┤                  │ Solution  │
    │                  │ Benefits  │
    │          ┌───────┘           └─────┐
0.5 ┤          │                         │
    │          │ Problem                 │ Case
    │   ┌──────┘ Background              │ Studies
0.4 ┤   │                                └────┐
    │   │ Exec                                │
    │   │ Summary                             │ Conclusion
0.3 ┤   │                                     │ CTA
    │   │                                     │
0.2 ┤   │                                     └──┐
    │   │                                        │
0.1 ┤   │                                        │ Refs
    │   │                                        │
0.0 ┴───┴────────────────────────────────────────┴─→
    0.0  0.1  0.2  0.3  0.4  0.5  0.6  0.8    1.0
    │     │    │    │    │    │    │    │      │
   Title Exec Prob Back  Sol  Ben Impl Case  Concl

Beats:
1. Title (0.0 - 0.05): Minimal
2. Executive Summary (0.05 - 0.15): Low, overview
3. Problem Statement (0.15 - 0.25): Rising, establish need
4. Background (0.25 - 0.35): Context and analysis
5. Proposed Solution (0.35 - 0.5): Peak (core content)
6. Benefits (0.5 - 0.6): Sustained complexity
7. Implementation Considerations (0.6 - 0.7): Detailed planning
8. Case Studies (0.7 - 0.8): Practical examples
9. Conclusion (0.8 - 0.9): Summary/synthesis
10. Call to Action (0.9 - 0.95): Low, actionable next steps
11. References (0.95 - 1.0): Minimal, citations
```

**Key Characteristic**: Business-focused, peak at solution (35-60%), practical emphasis with case studies.

---

## Using Arc Functions for Scene Mapping

### The Enhanced Algorithm

When switching from Structure A to Structure B:

```swift
For each scene S at position P in old structure:
  1. Get old arc value: arcA = structureA.arc(P)
  2. Find matching position in new structure:
     - Calculate proportional position: baseP = P
     - Find position in structureB where arcB(x) ≈ arcA
     - Fine-tune based on slope similarity
  3. Assign scene to nearest beat at that position
```

### Example: Three-Act → Hero's Journey

**Scenario**: Scene is at 50% through Three-Act (Act 2 midpoint)

**Step 1**: Get old arc value
- Position: x = 0.5
- Three-Act arc: f(0.5) = 0.7 (rising tension in Act 2)

**Step 2**: Find matching position in Hero's Journey
- Look for position where Hero's Journey arc ≈ 0.7
- Hero's Journey f(x) = 0.7 occurs at multiple points:
  - x ≈ 0.55 (Approach to Inmost Cave) - rising slope
  - x ≈ 0.7 (Reward) - falling slope
- Choose based on slope: 0.5 in Three-Act has positive slope (rising)
- Match to x = 0.55 (also rising) = **Approach to Inmost Cave**

**Result**: Scene mapped from "Act 2 Midpoint" → "Approach to Inmost Cave" (semantically appropriate!)

---

### Slope-Based Fine-Tuning

**Calculate Slope** (rate of tension change):
```swift
func slope(at x: Double, for structure: Structure) -> Double {
    let delta = 0.01
    return (structure.arc(x + delta) - structure.arc(x - delta)) / (2 * delta)
}
```

**Matching Logic**:
```swift
func findBestMatch(
    scenePosition: Double,
    fromStructure: Structure,
    toStructure: Structure
) -> Double {
    let targetArc = fromStructure.arc(scenePosition)
    let targetSlope = fromStructure.slope(at: scenePosition)

    // Search for position in new structure with similar arc AND slope
    var bestPosition = scenePosition // Start with proportional
    var bestScore = Double.infinity

    // Sample positions in new structure
    for x in stride(from: 0.0, through: 1.0, by: 0.01) {
        let arcDiff = abs(toStructure.arc(x) - targetArc)
        let slopeDiff = abs(toStructure.slope(at: x) - targetSlope)

        // Weighted score: arc matters more than slope
        let score = (arcDiff * 0.7) + (slopeDiff * 0.3)

        if score < bestScore {
            bestScore = score
            bestPosition = x
        }
    }

    return bestPosition
}
```

---

## Implementation in Code

### Structure Arc Protocol

```swift
protocol NarrativeArc {
    /// Returns tension level (0.0 - 1.0) at normalized position (0.0 - 1.0)
    func tension(at position: Double) -> Double

    /// Returns rate of tension change at position
    func slope(at position: Double) -> Double

    /// Returns array of (x, y) points for sparkline visualization
    func sparklinePoints(resolution: Int) -> [(x: Double, y: Double)]
}
```

### Extension for StoryStructure

```swift
extension StoryStructure {
    var narrativeArc: NarrativeArc {
        switch name {
        case "Three-Act Structure":
            return ThreeActArc()
        case "Five-Act Structure":
            return FiveActArc()
        case "Hero's Journey (Formal)", "Hero's Journey (Simplified)":
            return HerosJourneyArc()
        case "Save the Cat":
            return SaveTheCatArc()
        case "Academic Paper":
            return AcademicPaperArc()
        case "Technical Document":
            return TechnicalDocumentArc()
        default:
            return LinearArc() // Fallback: straight line from 0.3 to 0.7
        }
    }
}
```

### Arc Implementations

```swift
struct ThreeActArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.33:   // Act 1
            return 0.3 + (x / 0.33) * 0.2
        case 0.33..<0.5:   // Early Act 2
            return 0.5 + ((x - 0.33) / 0.17) * 0.2
        case 0.5..<0.67:   // Late Act 2
            return 0.7 + ((x - 0.5) / 0.17) * 0.1
        case 0.67..<0.83:  // Act 3: Rise to climax
            return 0.8 + ((x - 0.67) / 0.16) * 0.2
        default:           // Act 3: Falling action
            return 1.0 - ((x - 0.83) / 0.17) * 0.3
        }
    }

    func slope(at x: Double) -> Double {
        let delta = 0.01
        return (tension(at: x + delta) - tension(at: x - delta)) / (2 * delta)
    }

    func sparklinePoints(resolution: Int = 100) -> [(Double, Double)] {
        (0..<resolution).map { i in
            let x = Double(i) / Double(resolution - 1)
            return (x, tension(at: x))
        }
    }
}
```

---

## Dashboard Visualization

In ProjectDashboardView's Structure Band, render the arc as a sparkline:

```swift
private func structureBandWithArc() -> some View {
    GeometryReader { geometry in
        ZStack(alignment: .bottom) {
            // Arc sparkline
            if let structure = currentStructure {
                Path { path in
                    let points = structure.narrativeArc.sparklinePoints(resolution: 100)
                    let width = geometry.size.width
                    let height = 60.0

                    for (index, point) in points.enumerated() {
                        let x = point.x * width
                        let y = height - (point.y * height) // Invert Y

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 2)
            }

            // Beat markers on top of arc
            ForEach(beats, id: \.beatID) { beat in
                beatMarker(for: beat, width: geometry.size.width)
            }
        }
    }
}
```

---

## Research Resources

Existing sparkline visualizations of narrative arcs:

1. **Kurt Vonnegut's "Story Shapes"**:
   - "Man in Hole", "Boy Meets Girl", "Cinderella"
   - Hand-drawn tension curves
   - Reference: https://www.openculture.com/2014/02/kurt-vonnegut-masters-thesis-rejected-by-u-chicago.html

2. **Freytag's Pyramid**:
   - Classic five-act visualization
   - https://en.wikipedia.org/wiki/Dramatic_structure#Freytag's_pyramid

3. **Dan Harmon's Story Circle**:
   - Circular narrative structure (adapted from Hero's Journey)
   - https://blog.reedsy.com/guide/story-structure/dan-harmon-story-circle/

4. **Save the Cat Beat Sheet**:
   - Blake Snyder's percentage-based beats
   - https://savethecat.com/beat-sheet

5. **Academic: Sentiment Analysis of Plots**:
   - Research papers on computational narrative arc analysis
   - https://arxiv.org/abs/1606.07772 (Reagan et al., "Emotional Arcs of Stories")

---

## Next Steps

1. **Define Arc Functions**: Implement `NarrativeArc` protocol and concrete arcs for each structure
2. **Visualize in Dashboard**: Render sparklines in Structure Band
3. **Enhanced Scene Mapping**: Use arc-matching algorithm for structure switches
4. **User Testing**: Validate that arc-based mapping feels more accurate than proportional
5. **Custom Arcs**: Allow users to define custom arcs for custom structures (future)

---

## Tufte-Style Visualization in Dashboard

**Design Principle** (Strunk & White clarity, Tufte data-ink ratio):
> Show the narrative arc as a thin sparkline, **thickening the line proportionally** where scenes are assigned to beats.

### Visual Design

```
Structure Band with Narrative Arc (Three-Act Example):

Tension
     ┤                                        ╱━━━╲    ← Thick: 3 scenes
     │                                       ╱     ╲
     │                              ━━━━━━━━       ╲  ← Thick: 5 scenes
     │                             ╱                 ╲
     │                  ━━━        ━                 ╲ ← Thick: 2 scenes
     │                 ╱   ╲      ╱                   ╲
     │        ━━━━━━━━      ╲    ╱                     ╲
     │       ╱               ╲  ╱                       ╲
     │  ─────                 ╲╱                         ╲ ← Thin: 0 scenes
     └──────────────────────────────────────────────────→
     0.0        0.33              0.67       0.83      1.0
     │           │                 │          │         │
    Act 1    Turning Pt 1      Act 2     Climax      End

Legend:
─  Baseline (1pt): No scenes assigned
━  Thin (2pt): 1 scene
━━ Medium (3pt): 2-3 scenes
━━━ Thick (4-5pt): 4-6 scenes
━━━━ Very Thick (6pt+): 7+ scenes
```

### Implementation Strategy

**Data Structure**:
```swift
struct ArcSegment {
    let startPosition: Double  // 0.0 - 1.0
    let endPosition: Double    // 0.0 - 1.0
    let sceneCount: Int        // Number of scenes in this segment
    let tension: Double        // Average tension for this segment
}

func calculateArcSegments(
    structure: StoryStructure,
    scenes: [Card]
) -> [ArcSegment] {
    // For each structure element (beat):
    // 1. Calculate position range (start - end)
    // 2. Count scenes assigned to this beat
    // 3. Sample arc tension across this range
    // 4. Return segment with metadata
}
```

**Line Width Calculation**:
```swift
func lineWidth(for sceneCount: Int) -> CGFloat {
    switch sceneCount {
    case 0:
        return 1.0  // Baseline: thin ghosted line
    case 1:
        return 2.0  // Single scene
    case 2...3:
        return 3.0  // Few scenes
    case 4...6:
        return 4.5  // Several scenes
    default:
        return 6.0  // Many scenes (cap at 6pt)
    }
}
```

**Rendering in SwiftUI**:
```swift
private func narrativeArcView(
    structure: StoryStructure,
    segments: [ArcSegment],
    width: CGFloat,
    height: CGFloat = 60
) -> some View {
    Canvas { context, size in
        // Draw arc with variable-width segments
        for segment in segments {
            let startX = segment.startPosition * width
            let endX = segment.endPosition * width

            // Sample arc points within this segment
            let resolution = Int((endX - startX) / 2) // 1 point per 2pt

            var path = Path()
            for i in 0..<resolution {
                let progress = Double(i) / Double(resolution - 1)
                let x = startX + (endX - startX) * progress
                let position = segment.startPosition +
                               (segment.endPosition - segment.startPosition) * progress
                let tension = structure.narrativeArc.tension(at: position)
                let y = height - (tension * height) // Invert Y

                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            // Stroke with width based on scene count
            context.stroke(
                path,
                with: .color(arcColor(for: segment)),
                lineWidth: lineWidth(for: segment.sceneCount)
            )
        }
    }
}

private func arcColor(for segment: ArcSegment) -> Color {
    if segment.sceneCount == 0 {
        return Color.gray.opacity(0.3)  // Ghost line
    } else {
        return Color.accentPrimary  // Active line
    }
}
```

### Tufte Principles Applied

1. **Data-Ink Ratio**: Line thickness directly encodes scene density (no redundant decoration)
2. **Chartjunk Elimination**: No grid, no axis labels, no legend (self-explanatory)
3. **Small Multiples**: Could show multiple structure arcs for comparison (future)
4. **Sparklines**: Minimal, inline with text, high information density

### Beat Markers

Overlay beat markers on the arc:

```swift
private func beatMarkersView(
    beats: [StructureBeat],
    width: CGFloat,
    height: CGFloat = 60
) -> some View {
    ForEach(beats, id: \.beatID) { beat in
        VStack(spacing: 0) {
            // Vertical tick mark
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 1, height: beat.isMaterialized ? 12 : 8)

            // Beat label below
            Text(beat.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .offset(y: 4)
        }
        .offset(x: beat.normalizedPosition * width, y: 0)
    }
}
```

### Interactive Enhancements

1. **Hover**: Show beat name and scene count on hover
2. **Click Beat**: Jump to that beat in Structure Board
3. **Click Segment**: Show scenes in that beat
4. **Drag Scene**: Drag scene card onto arc to assign to nearest beat

### Example Visualization States

**Empty Project** (No scenes):
```
Tension
     ┤                                        ╱──╲
     │                                       ╱    ╲
     │                              ────────       ╲
     │                             ╱                ╲
     │                  ───        ─                 ╲
     │                 ╱   ╲      ╱                   ╲
     │        ─────────      ╲    ╱                     ╲
     │       ╱               ╲  ╱                       ╲
     │  ─────                 ╲╱                         ╲
     └──────────────────────────────────────────────────→

     All segments thin (1pt), ghosted gray
```

**In-Progress Project** (Some scenes):
```
Tension
     ┤                                        ╱──╲    ← Empty
     │                                       ╱    ╲
     │                              ━━━━━━━━       ╲  ← 5 scenes
     │                             ╱                 ╲
     │                  ━━━        ─                 ╲ ← 2 scenes, 0 scenes
     │                 ╱   ╲      ╱                   ╲
     │        ━━━━━━━━      ╲    ╱                     ╲ ← 4 scenes
     │       ╱               ╲  ╱                       ╲
     │  ─────                 ╲╱                         ╲ ← Empty
     └──────────────────────────────────────────────────→

     Mixed: thick where scenes exist, thin where empty
```

**Complete Project** (All beats filled):
```
Tension
     ┤                                        ╱━━━╲
     │                                       ╱     ╲
     │                              ━━━━━━━━       ╲
     │                             ╱                 ╲
     │                  ━━━        ━━                ╲
     │                 ╱   ╲      ╱                   ╲
     │        ━━━━━━━━      ╲    ╱                     ╲
     │       ╱               ╲  ╱                       ╲
     │  ━━━━                 ╲╱                         ╲
     └──────────────────────────────────────────────────→

     All segments thick (2-6pt), full color
```

### Active Position Marker

Show writer's current position as a vertical line intersecting the arc:

```swift
private func activePositionMarker(
    position: Double,
    width: CGFloat,
    arc: NarrativeArc
) -> some View {
    let x = position * width
    let tension = arc.tension(at: position)
    let y = 60 - (tension * 60)

    return ZStack {
        // Vertical line from bottom to arc
        Rectangle()
            .fill(Color.accentPrimary)
            .frame(width: 2, height: 60 - y)
            .offset(x: x, y: y / 2)

        // Dot on arc
        Circle()
            .fill(Color.accentPrimary)
            .frame(width: 6, height: 6)
            .offset(x: x, y: y)
    }
}
```

---

## Custom Structure Arc Editor (Future Feature)

For writers creating custom structures, provide a visual arc editor:

### UI Concept

```
┌─────────────────────────────────────────────────┐
│ Custom Structure Arc Editor                     │
├─────────────────────────────────────────────────┤
│                                                 │
│  Tension                                        │
│  1.0 ┤         ⊙────────⊙         ⊙            │ ← Draggable control points
│      │        ╱          ╲        ╱╲            │
│  0.5 ┤    ⊙──╱            ╲──⊙───╱  ╲           │
│      │   ╱                   ╱      ╲          │
│  0.0 ┴──⊙──────────────────────────────⊙─────→ │
│      0.0    0.2    0.4    0.6    0.8    1.0    │
│      │      │      │      │      │      │       │
│     Beat1  Beat2  Beat3  Beat4  Beat5  Beat6   │
│                                                 │
│  ⊙ = Control Point (drag to adjust tension)     │
│                                                 │
│  [Reset to Default]  [Save]  [Cancel]          │
└─────────────────────────────────────────────────┘
```

**Implementation**:
- Each beat gets a control point
- Drag vertically to adjust tension (0.0 - 1.0)
- Automatic curve smoothing between points (Catmull-Rom spline)
- Store as array of (position, tension) pairs in StoryStructure

**Data Model Extension**:
```swift
extension StoryStructure {
    var customArcPoints: [(position: Double, tension: Double)]?

    var narrativeArc: NarrativeArc {
        if let custom = customArcPoints {
            return CustomArc(points: custom)
        } else {
            return predefinedArc(for: name)
        }
    }
}
```

---

## Complete Structure Arc Summary

All 13 predefined Cumberland structures now have narrative arc definitions:

### Narrative Structures (Tension-Based)
1. ✅ **Three-Act Structure**: Stair-step with climax at 83%
2. ✅ **Beginning-Middle-End**: Smooth rise to 75%, gentle fall
3. ✅ **Five-Act Structure**: Freytag pyramid, peak at 60%
4. ✅ **Four-Part Structure**: Four phases, climax at 60-65%
5. ✅ **Hero's Journey (Formal)**: Dual peaks (62%, 87%)
6. ✅ **Hero's Journey (Simplified)**: Simplified dual peaks
7. ✅ **Save the Cat**: 15 beats with midpoint at 50%, climax at 90%
8. ✅ **Novel**: 12 beats with pinch points and dual peaks
9. ✅ **Short Story**: Compressed arc, early climax at 58%

### Non-Narrative Structures (Complexity-Based)
10. ✅ **Academic Paper**: IMRaD plateau (peak at Results/Discussion)
11. ✅ **Term Paper**: Academic plateau with symmetrical rise/fall
12. ✅ **Technical Document**: Extended plateau in implementation sections
13. ✅ **White Paper**: Business-focused, peak at solution (35-60%)

### Custom Structures
14. ⏸️ **User-Defined**: Future feature with visual arc editor

---

## Implementation Checklist

### Phase 1: Core Arc System ✅ COMPLETED
- [x] Create `NarrativeArc` protocol (`Model/NarrativeArc.swift`)
- [x] Implement concrete arc classes for all 13 structures
  - ThreeActArc, BeginningMiddleEndArc, FiveActArc, FourPartArc
  - HerosJourneyFormalArc, HerosJourneySimplifiedArc, SaveTheCatArc
  - NovelArc, ShortStoryArc
  - AcademicPaperArc, TermPaperArc, TechnicalDocumentArc, WhitePaperArc
  - LinearArc (fallback for custom structures)
- [x] Extend `StoryStructure` with `narrativeArc` computed property (`Model/StoryStructure.swift:271`)
- [x] Add unit tests for arc functions (`CumberlandTests/Model/NarrativeArcTests.swift`)
  - Protocol conformance tests
  - Range validation tests
  - Specific arc characteristics tests
  - Slope tests
  - Sparkline generation tests
  - StoryStructure integration tests

### Phase 2: Dashboard Visualization ✅ COMPLETED
- [x] Implement arc segment data generation (`Data/ProjectDashboardService.swift:140`)
- [x] Create Canvas-based arc renderer with variable line width (`ProjectWriter/NarrativeArcVisualization.swift`)
- [x] Add beat markers overlay
- [x] Add active position marker (dashed vertical line)
- [x] Implement Tufte-style thickness based on scene count
  - 0 scenes: 1pt ghosted gray
  - 1 scene: 2pt
  - 2-3 scenes: 3pt
  - 4-6 scenes: 4.5pt
  - 7+ scenes: 6pt
- [x] Integrate into Dashboard Structure Band (`ProjectWriter/ProjectDashboardView.swift:131`)
- [ ] Add hover states and tooltips (deferred - future enhancement)

### Phase 3: Scene Mapping Algorithm ✅ COMPLETED
- [x] Implement arc-matching algorithm (`Data/StructureMappingService.swift`)
  - Weighted scoring: 70% tension match + 30% slope direction
  - Samples new arc at 10x element count for precision
  - Maps to nearest beat in new structure
- [x] Add slope-based fine-tuning
  - Rising/falling/flat slope detection
  - Direction matching in scoring algorithm
- [x] Create structure switching preview UI (`ProjectWriter/StructureSelectionSheet.swift`)
  - Shows scene count, average match quality, warnings
  - Live arc visualization preview
  - Beat list display
- [x] Add comprehensive tests (`CumberlandTests/Data/StructureMappingTests.swift`)
  - Arc-based mapping tests
  - Proportional mapping tests
  - Preserve-old strategy tests
  - Edge case handling

### Phase 4a & 4b: UI Integration ✅ COMPLETED
- [x] Create StructureSelectionSheet component (`ProjectWriter/StructureSelectionSheet.swift`)
  - Template list with current structure indicator
  - Arc visualization preview
  - Beat grid display
  - Mapping statistics and warnings
  - Confirmation dialog
- [x] Add structure selector to Dashboard (`ProjectWriter/ProjectDashboardView.swift:140`)
  - "Change" button in Structure Band header
  - Sheet presentation with auto-reload on dismissal
- [x] Add structure selector to Writing Surface (`ProjectWriter/ManuscriptWritingSurfaceView.swift:171`)
  - "Structure" Quick Action button integration
  - Auto-reloads manuscript content on structure change

### Phase 5: Custom Arcs (Future)
- [ ] Design visual arc editor
- [ ] Implement Catmull-Rom spline interpolation
- [ ] Add custom arc data storage to StoryStructure model
- [ ] Create UI for editing custom arcs

---

## Open Questions (Updated)

1. ~~**Should Academic/Technical structures have "tension"?**~~
   - ✅ **RESOLVED**: Use "complexity" or "information density" for non-narrative structures

2. **What about non-linear structures?**
   - Circular narratives (Story Circle) - would need 360° arc?
   - Parallel timelines - overlay multiple arcs?
   - Anthology/episodic structures - repeated mini-arcs?

3. **Should arc functions be editable?**
   - ✅ **YES**: Writers creating custom structures need to define arcs
   - Provide visual editor for custom arc creation

4. **How to visualize multi-arc stories?**
   - Main plot arc + character arc + subplot arc
   - Solution: Allow switching between arc views in Dashboard
   - Or overlay with different colors (limit to 2-3 max)
