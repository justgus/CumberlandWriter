# Discrepancy Reports (DR) - Batch 11: DR-0101 to DR-0110

This file contains verified discrepancy reports DR-0101 through DR-0110.

**Batch Status:** 🚧 In Progress (1/10 verified)

---

## DR-0101: Theme Color Swatches Not Visible in Settings Picker

**Status:** ✅ Resolved - Verified
**Severity:** Low
**Platform:** macOS
**Component:** SettingsView / Theme Picker
**Date Identified:** 2026-02-27
**Date Resolved:** 2026-02-27
**Date Verified:** 2026-02-27

**Description:**
In Settings > Display > Theme, the color swatches (`ThemeSwatchView`) were not visible next to theme names in the picker. The user could not see a visual preview of theme colors when choosing a theme.

**Root Cause:**
SwiftUI's `Picker` on macOS defaults to a popup/menu style, which strips custom views (like `HStack` with colored `Rectangle`s) down to plain text labels. The `ThemeSwatchView` was placed inside the `Picker`'s `ForEach`, but macOS menu-style pickers cannot render arbitrary SwiftUI views.

**Resolution:**
1. Simplified the `Picker` content to plain `Text` labels only (which macOS menu pickers can render)
2. Moved the `ThemeSwatchView` outside the `Picker` as a live preview of the currently selected theme — this always renders correctly regardless of picker style
3. Enlarged the swatch from 3 tiny rectangles (8x14pt) to 6 larger color cells (28x24pt) showing: surface primary, card background, accent primary, accent secondary, text primary, and shadow color — giving a much more informative preview

**Code Changes:**
- `SettingsView.swift` — `DisplaySettingsPane`: Moved `ThemeSwatchView` below the `Picker` as a standalone live preview
- `SettingsView.swift` — `ThemeSwatchView`: Redesigned with 6 larger swatch cells, `SurfaceFill`-aware rendering (materials shown as neutral gray), and a border overlay

---

*Last Updated: 2026-02-27*
