# Phase 3: MapKit Integration - Testing Checklist

**Date:** November 11, 2025  
**Component:** MapWizardView - Capture from Maps  
**Tester:** _____________  
**Build/Version:** _____________

---

## Pre-Testing Setup

- [ ] Build project successfully
- [ ] Verify MapKit and CoreLocation frameworks linked
- [ ] Test on macOS (primary target)
- [ ] Test on iOS/iPadOS (if applicable)
- [ ] Ensure internet connection available (for Maps data)

---

## Basic Functionality

### Map View Display
- [ ] Map view renders correctly in configure step
- [ ] Map loads with default camera position
- [ ] Map tiles load without errors
- [ ] Map responds to pan gestures
- [ ] Map responds to zoom/pinch gestures
- [ ] Map doesn't freeze or lag during interaction

### Location Search
- [ ] Search field accepts text input
- [ ] Search field has magnifying glass icon
- [ ] Typing doesn't trigger search automatically
- [ ] Pressing Return/Enter triggers search
- [ ] Search results appear in dropdown
- [ ] Search results show location names
- [ ] Search results show addresses (when available)
- [ ] Dropdown scrolls if many results
- [ ] Dropdown has proper max height (~150pt)
- [ ] Clear button (X) appears when text entered
- [ ] Clear button empties search field
- [ ] Clear button removes search results

### Location Selection
- [ ] Tapping search result selects location
- [ ] Selected location dismisses dropdown
- [ ] Map animates to selected location
- [ ] Blue marker appears at selected location
- [ ] Marker shows location name
- [ ] Zoom level is appropriate (not too close/far)

### Map Style Selection
- [ ] Map style menu button visible (top-right)
- [ ] Menu shows three options: Standard, Satellite, Hybrid
- [ ] Standard map style displays correctly
- [ ] Satellite map style displays correctly
- [ ] Hybrid map style displays correctly
- [ ] Checkmark indicates current style
- [ ] Style changes apply immediately
- [ ] Style persists during pan/zoom

---

## Snapshot Capture

### Capture Process
- [ ] "Capture Map Snapshot" button is prominent
- [ ] Button has camera icon
- [ ] Tapping button starts capture
- [ ] Progress indicator appears during capture
- [ ] Button is disabled during capture
- [ ] Capture completes within reasonable time (< 5 seconds)
- [ ] No crashes during capture

### Capture Quality
- [ ] Captured image displays in preview
- [ ] Image quality is high (not pixelated)
- [ ] Image matches what was visible in map view
- [ ] Image includes selected map style
- [ ] Image doesn't include SwiftUI UI elements
- [ ] Image doesn't include search dropdown
- [ ] Image doesn't include style picker button
- [ ] Image resolution is 2048×2048 pixels
- [ ] Image format is PNG

### Metadata Display
- [ ] Metadata GroupBox appears below preview
- [ ] "Capture Information" header displays
- [ ] Location name shows (if applicable)
- [ ] Coordinates display with 4 decimal precision
- [ ] Coordinates match selected location
- [ ] Map type shows (Standard/Satellite/Hybrid)
- [ ] Capture date/time displays correctly
- [ ] Span (lat/long delta) displays with 3 decimal precision
- [ ] All metadata rows have icons
- [ ] Metadata is readable and formatted well

---

## Search Test Cases

### Valid Searches
- [ ] Search "New York" - finds multiple results
- [ ] Search "Eiffel Tower" - finds landmark
- [ ] Search specific address - finds address
- [ ] Search "coffee shop" - finds POIs
- [ ] Search partial name - shows suggestions
- [ ] Search coordinates - finds location (if supported)

### Edge Cases
- [ ] Empty search - no results, no error
- [ ] Search "asdfghjkl" (nonsense) - shows "no results" or empty
- [ ] Search very long string - handles gracefully
- [ ] Search special characters - doesn't crash
- [ ] Search while offline - shows error message
- [ ] Search with network timeout - error handled

---

## Error Handling

### Search Errors
- [ ] No internet connection - error message displays
- [ ] Search API failure - error message displays
- [ ] No results found - graceful handling (empty list)
- [ ] Error messages are user-friendly
- [ ] Errors don't crash the app

### Capture Errors
- [ ] Capture with no network - error message or cached tiles used
- [ ] Snapshot API failure - error message displays
- [ ] Invalid region - error handled gracefully
- [ ] Multiple rapid captures - no crashes
- [ ] Error messages persist until dismissed or success

---

## Wizard Integration

### Navigation Flow
- [ ] "Capture from Maps" method card selectable
- [ ] Selecting method enables "Continue" button
- [ ] Continue advances to map config view
- [ ] Back button returns to method selection
- [ ] Can't proceed without captured snapshot
- [ ] "Use This Capture" advances to finalize step
- [ ] Captured data appears in finalize preview

### State Management
- [ ] Multiple captures replace previous (not accumulate)
- [ ] "Capture Different Area" resets to map view
- [ ] Previous search text cleared on reset
- [ ] Previous selected location cleared on reset
- [ ] Map camera resets properly
- [ ] Wizard reset clears all map state

### Validation
- [ ] Continue button disabled without capture
- [ ] Continue button enabled after successful capture
- [ ] Progress indicator prevents duplicate actions
- [ ] Can navigate back at any point

---

## Cross-Platform Testing

### macOS
- [ ] Map view renders correctly
- [ ] Mouse scrolling for zoom works
- [ ] Click and drag for pan works
- [ ] Keyboard input in search works
- [ ] NSImage conversion successful
- [ ] Snapshot quality correct
- [ ] No platform-specific crashes

### iOS/iPadOS (if applicable)
- [ ] Map view renders correctly
- [ ] Touch gestures work (pan/pinch/zoom)
- [ ] Virtual keyboard appears for search
- [ ] UIImage conversion successful
- [ ] Snapshot quality correct
- [ ] No platform-specific crashes

---

## Performance Testing

### Responsiveness
- [ ] Map interactions feel smooth (no lag)
- [ ] Search results appear quickly (< 2 seconds)
- [ ] Snapshot capture completes reasonably (< 5 seconds)
- [ ] UI doesn't freeze during operations
- [ ] Memory usage reasonable (no leaks)

### Stress Testing
- [ ] Rapid pan/zoom doesn't crash
- [ ] Multiple searches in quick succession work
- [ ] Multiple captures in quick succession work
- [ ] Switching map styles rapidly works
- [ ] Large search result lists don't slow UI

---

## Accessibility

### VoiceOver (if testing)
- [ ] Map view has accessibility label
- [ ] Search field is accessible
- [ ] Search results are navigable
- [ ] Buttons have descriptive labels
- [ ] Metadata is readable by screen reader

### Visual
- [ ] All icons are visible
- [ ] Text is readable at default size
- [ ] Contrast is sufficient for all elements
- [ ] Color isn't the only indicator (checkmarks in menu)

---

## Edge Cases & Corner Cases

### Geographic Edge Cases
- [ ] Search North Pole - handles extreme latitude
- [ ] Search South Pole - handles extreme latitude
- [ ] Search International Date Line area - no wrap issues
- [ ] Search small island - zooms appropriately
- [ ] Search large country - zooms appropriately

### UI Edge Cases
- [ ] Very long location names - truncate gracefully
- [ ] No location name available - shows "Unknown" or placeholder
- [ ] Multiple locations with same name - all appear in results
- [ ] Rapid selection of different locations - animates correctly
- [ ] Changing style during capture - handles gracefully

### Data Edge Cases
- [ ] Capture with automatic camera position - uses sensible default
- [ ] Capture immediately after wizard opens - works
- [ ] Capture after switching from different method - works
- [ ] Recapture after error - clears error state

---

## Integration with Save Flow

### Data Handoff
- [ ] Captured map data copied to `importedImageData`
- [ ] Data persists through finalize step
- [ ] Save to Card works correctly
- [ ] Saved image viewable in Card detail
- [ ] Image quality preserved after save
- [ ] File extension correct (.png)

### Reset After Save
- [ ] Wizard resets to welcome after save
- [ ] All map state cleared
- [ ] No residual data from previous capture
- [ ] Can immediately start new capture

---

## Known Issues (Document Any Found)

### Critical Issues
_List any crashes, data loss, or blocking issues here_

---

### Major Issues
_List any significant functional problems here_

---

### Minor Issues
_List any cosmetic or nice-to-have fixes here_

---

## Test Summary

**Total Test Cases:** ~150+  
**Passed:** _____ / _____  
**Failed:** _____ / _____  
**Blocked:** _____ / _____  
**Skipped:** _____ / _____

**Overall Status:** ⬜ Pass ⬜ Fail ⬜ Partial

**Recommendation:** ⬜ Ship ⬜ Fix Critical Issues ⬜ Needs Major Work

---

## Tester Notes

_Add any additional observations, suggestions, or concerns here_

---

## Sign-Off

**Tester:** _____________  
**Date:** _____________  
**Approved for Release:** ⬜ Yes ⬜ No ⬜ With Conditions

---

**End of Testing Checklist**
