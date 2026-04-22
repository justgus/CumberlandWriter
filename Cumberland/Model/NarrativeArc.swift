//
//  NarrativeArc.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-21.
//  Part of Story Structure Integration - Phase 1
//
//  Defines the narrative tension or complexity curve for story structures.
//  Each structure has an inherent dramatic arc that serves two purposes:
//  1. Dashboard visualization (sparkline with variable line thickness)
//  2. Scene mapping algorithm (arc-matching when switching structures)
//
//  See: Cumberland/Documentation/NARRATIVE-ARC-FUNCTIONS.md

import Foundation

// MARK: - NarrativeArc Protocol

/// Defines the tension or complexity curve for a story structure
protocol NarrativeArc {
    /// Returns tension/complexity level (0.0 - 1.0) at normalized position (0.0 - 1.0)
    ///
    /// For narrative structures, this represents dramatic tension.
    /// For non-narrative structures (academic, technical), this represents complexity or information density.
    ///
    /// - Parameter position: Normalized position through the structure (0.0 = start, 1.0 = end)
    /// - Returns: Tension/complexity level (0.0 = baseline, 1.0 = peak)
    func tension(at position: Double) -> Double

    /// Returns the rate of tension change (slope) at a given position
    ///
    /// Used for arc-matching when switching structures. Scenes on rising slopes should map
    /// to rising slopes in the new structure, and falling to falling.
    ///
    /// - Parameter position: Normalized position through the structure
    /// - Returns: Slope (derivative) of tension at this position
    func slope(at position: Double) -> Double

    /// Returns array of (x, y) points for sparkline visualization
    ///
    /// - Parameter resolution: Number of points to generate (default 100)
    /// - Returns: Array of (position, tension) tuples for plotting
    func sparklinePoints(resolution: Int) -> [(x: Double, y: Double)]
}

// MARK: - Default Implementations

extension NarrativeArc {
    /// Default slope implementation using numerical differentiation
    func slope(at position: Double) -> Double {
        let delta = 0.01
        let positionBefore = max(0.0, position - delta)
        let positionAfter = min(1.0, position + delta)

        let tensionBefore = tension(at: positionBefore)
        let tensionAfter = tension(at: positionAfter)

        return (tensionAfter - tensionBefore) / (positionAfter - positionBefore)
    }

    /// Default sparkline points implementation
    func sparklinePoints(resolution: Int = 100) -> [(x: Double, y: Double)] {
        guard resolution > 1 else { return [] }

        return (0..<resolution).map { i in
            let x = Double(i) / Double(resolution - 1)
            let y = tension(at: x)
            return (x, y)
        }
    }
}

// MARK: - Helper Functions

extension NarrativeArc {
    /// Linear interpolation between two values
    func lerp(from start: Double, to end: Double, progress: Double) -> Double {
        return start + (end - start) * progress
    }

    /// Clamp value to range [0.0, 1.0]
    func clamp(_ value: Double) -> Double {
        return min(max(value, 0.0), 1.0)
    }

    /// Map position within a range to 0.0-1.0
    func normalize(_ position: Double, from start: Double, to end: Double) -> Double {
        guard end > start else { return 0.0 }
        return (position - start) / (end - start)
    }
}

// MARK: - Narrative Structures

/// Three-Act Structure
///
/// Classic Hollywood structure with three distinct acts.
/// Climax at ~83%, two turning points at act boundaries.
///
/// Characteristic: Stair-step rises with final peak before resolution.
struct ThreeActArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.33:   // Act 1: Setup and rising action
            return lerp(from: 0.3, to: 0.5, progress: x / 0.33)

        case 0.33..<0.5:   // Early Act 2: Continued complications
            return lerp(from: 0.5, to: 0.7, progress: (x - 0.33) / 0.17)

        case 0.5..<0.67:   // Late Act 2: Rising to second turning point
            return lerp(from: 0.7, to: 0.8, progress: (x - 0.5) / 0.17)

        case 0.67..<0.83:  // Act 3: Rise to climax
            return lerp(from: 0.8, to: 1.0, progress: (x - 0.67) / 0.16)

        default:           // Act 3: Falling action and resolution
            return lerp(from: 1.0, to: 0.7, progress: (x - 0.83) / 0.17)
        }
    }
}

/// Beginning-Middle-End (Simple 3-Part)
///
/// Simplified three-part structure with smooth transitions.
/// Climax at ~75%, gentler rise than Three-Act.
///
/// Characteristic: Continuous smooth curve, less pronounced act breaks.
struct BeginningMiddleEndArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.33:   // Beginning: Introduction and setup
            return lerp(from: 0.3, to: 0.5, progress: x / 0.33)

        case 0.33..<0.75:  // Middle: Smooth rise to climax
            return lerp(from: 0.5, to: 1.0, progress: (x - 0.33) / 0.42)

        default:           // End: Resolution
            return lerp(from: 1.0, to: 0.6, progress: (x - 0.75) / 0.25)
        }
    }
}

/// Five-Act Structure (Freytag's Pyramid)
///
/// Classic dramatic structure with peak at Act 3 (Climax).
/// Earlier peak (~60%) than Three-Act.
///
/// Characteristic: Pyramid shape with pronounced peak in middle.
struct FiveActArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.2:    // Exposition: Setup
            return lerp(from: 0.2, to: 0.4, progress: x / 0.2)

        case 0.2..<0.4:    // Rising Action: First complications
            return lerp(from: 0.4, to: 0.7, progress: (x - 0.2) / 0.2)

        case 0.4..<0.6:    // Climax: Peak tension
            return lerp(from: 0.7, to: 1.0, progress: (x - 0.4) / 0.2)

        case 0.6..<0.8:    // Falling Action: Consequences
            return lerp(from: 1.0, to: 0.6, progress: (x - 0.6) / 0.2)

        default:           // Resolution: Denouement
            return lerp(from: 0.6, to: 0.3, progress: (x - 0.8) / 0.2)
        }
    }
}

/// Four-Part Structure
///
/// Four distinct phases: Setup, Confrontation, Resolution, Epilogue.
/// Climax at ~60-65%, extended epilogue.
///
/// Characteristic: Four distinct plateaus with climax in Resolution section.
struct FourPartArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.25:   // Setup: Introduction and initial conflict
            return lerp(from: 0.3, to: 0.5, progress: x / 0.25)

        case 0.25..<0.5:   // Confrontation: Rising tension
            return lerp(from: 0.5, to: 0.8, progress: (x - 0.25) / 0.25)

        case 0.5..<0.75:   // Resolution: Climax and main resolution
            let subProgress = (x - 0.5) / 0.25
            if subProgress < 0.5 {  // Rise to climax
                return lerp(from: 0.8, to: 1.0, progress: subProgress / 0.5)
            } else {                // Fall from climax
                return lerp(from: 1.0, to: 0.7, progress: (subProgress - 0.5) / 0.5)
            }

        default:           // Epilogue: Aftermath
            return lerp(from: 0.7, to: 0.4, progress: (x - 0.75) / 0.25)
        }
    }
}

/// Hero's Journey (12-Stage Formal)
///
/// Joseph Campbell's monomyth with dual peaks.
/// First peak at Ordeal (~62%), second at Resurrection (~87%).
///
/// Characteristic: Dual-peak structure mimicking death-and-rebirth pattern.
struct HerosJourneyFormalArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.08:   // Ordinary World
            return 0.2

        case 0.08..<0.17:  // Call to Adventure
            return lerp(from: 0.2, to: 0.35, progress: (x - 0.08) / 0.09)

        case 0.17..<0.25:  // Refusal of Call (slight dip)
            return lerp(from: 0.35, to: 0.3, progress: (x - 0.17) / 0.08)

        case 0.25..<0.33:  // Meeting Mentor
            return lerp(from: 0.3, to: 0.45, progress: (x - 0.25) / 0.08)

        case 0.33..<0.42:  // Crossing Threshold
            return lerp(from: 0.45, to: 0.6, progress: (x - 0.33) / 0.09)

        case 0.42..<0.5:   // Tests, Allies, Enemies
            return lerp(from: 0.6, to: 0.7, progress: (x - 0.42) / 0.08)

        case 0.5..<0.58:   // Approach Inmost Cave
            return lerp(from: 0.7, to: 0.85, progress: (x - 0.5) / 0.08)

        case 0.58..<0.67:  // Ordeal (FIRST PEAK)
            let subProgress = (x - 0.58) / 0.09
            if subProgress < 0.5 {
                return lerp(from: 0.85, to: 1.0, progress: subProgress / 0.5)
            } else {
                return lerp(from: 1.0, to: 0.8, progress: (subProgress - 0.5) / 0.5)
            }

        case 0.67..<0.75:  // Reward (plateau)
            return 0.75

        case 0.75..<0.83:  // Road Back (rise to second peak)
            return lerp(from: 0.75, to: 0.9, progress: (x - 0.75) / 0.08)

        case 0.83..<0.92:  // Resurrection (SECOND PEAK)
            let subProgress = (x - 0.83) / 0.09
            if subProgress < 0.5 {
                return lerp(from: 0.9, to: 1.0, progress: subProgress / 0.5)
            } else {
                return lerp(from: 1.0, to: 0.8, progress: (subProgress - 0.5) / 0.5)
            }

        default:           // Return with Elixir
            return lerp(from: 0.8, to: 0.5, progress: (x - 0.92) / 0.08)
        }
    }
}

/// Hero's Journey (Simplified 5-Stage)
///
/// Streamlined version with key stages only.
/// Similar dual-peak pattern but fewer intermediate stages.
///
/// Characteristic: Simplified dual peaks, easier to work with.
struct HerosJourneySimplifiedArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.2:    // Ordinary World
            return lerp(from: 0.2, to: 0.4, progress: x / 0.2)

        case 0.2..<0.4:    // Call to Adventure
            return lerp(from: 0.4, to: 0.7, progress: (x - 0.2) / 0.2)

        case 0.4..<0.6:    // Trials (first peak)
            let subProgress = (x - 0.4) / 0.2
            if subProgress < 0.5 {
                return lerp(from: 0.7, to: 0.95, progress: subProgress / 0.5)
            } else {
                return lerp(from: 0.95, to: 0.75, progress: (subProgress - 0.5) / 0.5)
            }

        case 0.6..<0.8:    // Transformation (second peak)
            let subProgress = (x - 0.6) / 0.2
            if subProgress < 0.5 {
                return lerp(from: 0.75, to: 1.0, progress: subProgress / 0.5)
            } else {
                return lerp(from: 1.0, to: 0.8, progress: (subProgress - 0.5) / 0.5)
            }

        default:           // Return
            return lerp(from: 0.8, to: 0.5, progress: (x - 0.8) / 0.2)
        }
    }
}

/// Save the Cat (15 Beats)
///
/// Blake Snyder's beat sheet with precise percentages.
/// Midpoint at 50%, "All Is Lost" at 67%, Finale at 90%.
///
/// Characteristic: Highly structured with specific beat positions and multiple peaks.
struct SaveTheCatArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.07:   // Opening Image
            return 0.3

        case 0.07..<0.13:  // Theme Stated
            return 0.35

        case 0.13..<0.2:   // Setup
            return lerp(from: 0.35, to: 0.4, progress: (x - 0.13) / 0.07)

        case 0.2..<0.27:   // Catalyst
            return lerp(from: 0.4, to: 0.55, progress: (x - 0.2) / 0.07)

        case 0.27..<0.33:  // Debate
            return lerp(from: 0.55, to: 0.6, progress: (x - 0.27) / 0.06)

        case 0.33..<0.4:   // Break into Two
            return lerp(from: 0.6, to: 0.7, progress: (x - 0.33) / 0.07)

        case 0.4..<0.47:   // B Story
            return 0.7

        case 0.47..<0.53:  // Fun and Games
            return lerp(from: 0.7, to: 0.75, progress: (x - 0.47) / 0.06)

        case 0.53..<0.6:   // Midpoint (false victory/defeat)
            let subProgress = (x - 0.53) / 0.07
            if subProgress < 0.5 {
                return lerp(from: 0.75, to: 0.85, progress: subProgress / 0.5)
            } else {
                return lerp(from: 0.85, to: 0.8, progress: (subProgress - 0.5) / 0.5)
            }

        case 0.6..<0.67:   // Bad Guys Close In
            return lerp(from: 0.8, to: 0.75, progress: (x - 0.6) / 0.07)

        case 0.67..<0.73:  // All Is Lost (lowest point before climax)
            return lerp(from: 0.75, to: 0.65, progress: (x - 0.67) / 0.06)

        case 0.73..<0.8:   // Dark Night of the Soul
            return lerp(from: 0.65, to: 0.75, progress: (x - 0.73) / 0.07)

        case 0.8..<0.87:   // Break into Three
            return lerp(from: 0.75, to: 0.9, progress: (x - 0.8) / 0.07)

        case 0.87..<0.93:  // Finale (climax)
            let subProgress = (x - 0.87) / 0.06
            if subProgress < 0.5 {
                return lerp(from: 0.9, to: 1.0, progress: subProgress / 0.5)
            } else {
                return lerp(from: 1.0, to: 0.85, progress: (subProgress - 0.5) / 0.5)
            }

        default:           // Final Image
            return lerp(from: 0.85, to: 0.6, progress: (x - 0.93) / 0.07)
        }
    }
}

/// Novel (12-Beat Structure)
///
/// Common beat sheet for novel writing with pinch points.
/// Dual peaks: Midpoint at 50%, Climax at 80%.
///
/// Characteristic: Similar to Save the Cat but with "pinch points" increasing pressure.
struct NovelArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.08:   // Opening Image
            return 0.3

        case 0.08..<0.17:  // Hook
            return lerp(from: 0.3, to: 0.4, progress: (x - 0.08) / 0.09)

        case 0.17..<0.25:  // Inciting Incident
            return lerp(from: 0.4, to: 0.55, progress: (x - 0.17) / 0.08)

        case 0.25..<0.33:  // Key Event
            return lerp(from: 0.55, to: 0.65, progress: (x - 0.25) / 0.08)

        case 0.33..<0.42:  // First Plot Point
            return lerp(from: 0.65, to: 0.75, progress: (x - 0.33) / 0.09)

        case 0.42..<0.5:   // First Pinch Point
            return lerp(from: 0.75, to: 0.8, progress: (x - 0.42) / 0.08)

        case 0.5..<0.58:   // Midpoint (first peak)
            let subProgress = (x - 0.5) / 0.08
            if subProgress < 0.5 {
                return lerp(from: 0.8, to: 0.9, progress: subProgress / 0.5)
            } else {
                return lerp(from: 0.9, to: 0.8, progress: (subProgress - 0.5) / 0.5)
            }

        case 0.58..<0.67:  // Second Pinch Point
            return lerp(from: 0.8, to: 0.85, progress: (x - 0.58) / 0.09)

        case 0.67..<0.75:  // Second Plot Point (lowest before climax)
            return lerp(from: 0.85, to: 0.75, progress: (x - 0.67) / 0.08)

        case 0.75..<0.83:  // Climax (second peak)
            return lerp(from: 0.75, to: 1.0, progress: (x - 0.75) / 0.08)

        case 0.83..<0.92:  // Resolution
            return lerp(from: 1.0, to: 0.7, progress: (x - 0.83) / 0.09)

        default:           // Epilogue
            return lerp(from: 0.7, to: 0.5, progress: (x - 0.92) / 0.08)
        }
    }
}

/// Short Story (6-Beat Compact Arc)
///
/// Compressed narrative arc for short forms.
/// Earlier climax at ~58% than longer forms.
///
/// Characteristic: Single peak, quick rise and fall, compact.
struct ShortStoryArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.17:   // Setup
            return lerp(from: 0.3, to: 0.45, progress: x / 0.17)

        case 0.17..<0.33:  // Inciting Incident
            return lerp(from: 0.45, to: 0.6, progress: (x - 0.17) / 0.16)

        case 0.33..<0.5:   // Rising Action
            return lerp(from: 0.6, to: 0.85, progress: (x - 0.33) / 0.17)

        case 0.5..<0.67:   // Climax (peak earlier than novels)
            let subProgress = (x - 0.5) / 0.17
            if subProgress < 0.5 {
                return lerp(from: 0.85, to: 1.0, progress: subProgress / 0.5)
            } else {
                return lerp(from: 1.0, to: 0.8, progress: (subProgress - 0.5) / 0.5)
            }

        case 0.67..<0.83:  // Falling Action
            return lerp(from: 0.8, to: 0.55, progress: (x - 0.67) / 0.16)

        default:           // Resolution
            return lerp(from: 0.55, to: 0.35, progress: (x - 0.83) / 0.17)
        }
    }
}

// MARK: - Non-Narrative Structures (Complexity-Based)

/// Academic Paper (IMRaD Structure)
///
/// Introduction, Methods, Results, and Discussion format.
/// Peak complexity at Results/Discussion sections.
///
/// Characteristic: Plateau-based, sustained high complexity in middle sections.
struct AcademicPaperArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.1:    // Title/Abstract
            return 0.2

        case 0.1..<0.25:   // Introduction
            return lerp(from: 0.2, to: 0.4, progress: (x - 0.1) / 0.15)

        case 0.25..<0.45:  // Methods
            return lerp(from: 0.4, to: 0.6, progress: (x - 0.25) / 0.2)

        case 0.45..<0.65:  // Results (peak complexity)
            return lerp(from: 0.6, to: 0.8, progress: (x - 0.45) / 0.2)

        case 0.65..<0.85:  // Discussion (sustained peak)
            return 0.8

        case 0.85..<0.95:  // Conclusion
            return lerp(from: 0.8, to: 0.4, progress: (x - 0.85) / 0.1)

        default:           // References/Supplementary
            return 0.2
        }
    }
}

/// Term Paper (10-Section Academic)
///
/// Academic coursework structure with literature review and methodology.
/// Peak at Results/Discussion with symmetrical rise/fall.
///
/// Characteristic: Academic plateau with clear sections.
struct TermPaperArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.05:   // Title Page
            return 0.1

        case 0.05..<0.1:   // Abstract
            return 0.2

        case 0.1..<0.2:    // Introduction
            return lerp(from: 0.2, to: 0.4, progress: (x - 0.1) / 0.1)

        case 0.2..<0.3:    // Literature Review
            return lerp(from: 0.4, to: 0.5, progress: (x - 0.2) / 0.1)

        case 0.3..<0.45:   // Methodology
            return lerp(from: 0.5, to: 0.65, progress: (x - 0.3) / 0.15)

        case 0.45..<0.6:   // Results (peak)
            return lerp(from: 0.65, to: 0.75, progress: (x - 0.45) / 0.15)

        case 0.6..<0.75:   // Discussion (sustained)
            return 0.75

        case 0.75..<0.85:  // Conclusion
            return lerp(from: 0.75, to: 0.4, progress: (x - 0.75) / 0.1)

        case 0.85..<0.95:  // References
            return 0.2

        default:           // Appendices
            return 0.1
        }
    }
}

/// Technical Document (Engineering/Documentation)
///
/// Extended plateau in implementation and API reference sections.
/// Peak detail density in middle third.
///
/// Characteristic: Long sustained plateau, symmetrical documentation structure.
struct TechnicalDocumentArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.15:   // Title/Overview/Requirements
            return lerp(from: 0.1, to: 0.3, progress: x / 0.15)

        case 0.15..<0.3:   // Architecture
            return lerp(from: 0.3, to: 0.5, progress: (x - 0.15) / 0.15)

        case 0.3..<0.8:    // Implementation/API/Config (extended plateau)
            return 0.6

        case 0.8..<0.9:    // Usage Examples
            return lerp(from: 0.6, to: 0.4, progress: (x - 0.8) / 0.1)

        default:           // Appendix/Glossary
            return lerp(from: 0.4, to: 0.2, progress: (x - 0.9) / 0.1)
        }
    }
}

/// White Paper (Business/Strategy)
///
/// Business-focused with peak at Proposed Solution and Benefits sections.
/// Practical emphasis with case studies before conclusion.
///
/// Characteristic: Business arc with solution as peak.
struct WhitePaperArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        switch x {
        case 0.0..<0.05:   // Title
            return 0.1

        case 0.05..<0.15:  // Executive Summary
            return lerp(from: 0.1, to: 0.3, progress: (x - 0.05) / 0.1)

        case 0.15..<0.25:  // Problem Statement
            return lerp(from: 0.3, to: 0.45, progress: (x - 0.15) / 0.1)

        case 0.25..<0.35:  // Background
            return lerp(from: 0.45, to: 0.6, progress: (x - 0.25) / 0.1)

        case 0.35..<0.5:   // Proposed Solution (peak)
            return lerp(from: 0.6, to: 0.75, progress: (x - 0.35) / 0.15)

        case 0.5..<0.6:    // Benefits (sustained)
            return 0.75

        case 0.6..<0.7:    // Implementation Considerations
            return lerp(from: 0.75, to: 0.65, progress: (x - 0.6) / 0.1)

        case 0.7..<0.8:    // Case Studies
            return lerp(from: 0.65, to: 0.5, progress: (x - 0.7) / 0.1)

        case 0.8..<0.9:    // Conclusion
            return lerp(from: 0.5, to: 0.35, progress: (x - 0.8) / 0.1)

        case 0.9..<0.95:   // Call to Action
            return 0.3

        default:           // References
            return 0.2
        }
    }
}

// MARK: - Fallback Arc

/// Linear Arc (Fallback)
///
/// Simple linear rise from 0.3 to 0.7 for structures without defined arcs.
/// Used as fallback for custom structures until user defines custom arc.
///
/// Characteristic: Straight line, neutral, no specific dramatic pattern.
struct LinearArc: NarrativeArc {
    func tension(at x: Double) -> Double {
        return lerp(from: 0.3, to: 0.7, progress: x)
    }
}
