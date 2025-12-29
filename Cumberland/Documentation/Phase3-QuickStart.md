# Phase 3: MapKit Integration - Quick Start Guide

**For Developers & Testers**  
**Date:** November 11, 2025

---

## Getting Started in 5 Minutes

### Prerequisites
1. Latest project build
2. Internet connection (for Apple Maps data)
3. macOS, iOS, or iPadOS device/simulator

### Quick Test Path

```
1. Launch app
2. Create or open a Map-kind card
3. Navigate to "Map Wizard" tab
4. Click "Continue" (Welcome → Method Selection)
5. Select "Capture from Maps" card
6. Click "Continue" (Method Selection → Configure)
7. Type a location (e.g., "New York") in search bar
8. Press Return/Enter
9. Click a search result
10. Watch map zoom to location
11. Pan/zoom to frame your desired area
12. (Optional) Change map style with menu button
13. Click "Capture Map Snapshot"
14. Wait ~2-3 seconds for capture
15. Review preview and metadata
16. Click "Use This Capture"
17. Proceed to Finalize and Save
```

**Expected Result:** High-quality PNG map image saved to card!

---

## What You're Testing

### Core Features
- **Search**: Natural language location search
- **Selection**: One-tap zoom to location
- **Framing**: Pan/zoom to compose capture area
- **Styles**: Switch between Standard/Satellite/Hybrid
- **Capture**: High-res snapshot (2048×2048)
- **Metadata**: Rich information about capture
- **Preview**: Review before committing

### What Should Work
✅ Smooth map interactions  
✅ Fast search results  
✅ Accurate location selection  
✅ High-quality captures  
✅ Clear error messages (if any)  
✅ Seamless wizard flow  

---

## Common Test Scenarios

### Scenario 1: Famous Landmark
```
Search: "Eiffel Tower"
Style: Satellite
Zoom: Close-up of structure
Expected: Detailed aerial view with clear tower
```

### Scenario 2: City Overview
```
Search: "San Francisco"
Style: Hybrid
Zoom: Entire city visible
Expected: Satellite imagery with street labels
```

### Scenario 3: Specific Address
```
Search: "1600 Pennsylvania Avenue NW, Washington, DC"
Style: Standard
Zoom: Building and surroundings
Expected: Street map centered on address
```

### Scenario 4: Natural Feature
```
Search: "Grand Canyon"
Style: Satellite
Zoom: Canyon vista
Expected: Topographic satellite view
```

### Scenario 5: Fantasy Setting Research
```
Search: "Scottish Highlands"
Style: Hybrid
Zoom: Region with mountains and lochs
Expected: Useful reference for world-building
```

---

## Testing Checklist (Abbreviated)

### Must Test
- [ ] Search returns results
- [ ] Map loads and is interactive
- [ ] Capture produces image
- [ ] Can save to card

### Should Test
- [ ] All three map styles work
- [ ] Multiple searches/captures work
- [ ] Error states display properly
- [ ] Recapture works

### Nice to Test
- [ ] Edge cases (North Pole, etc.)
- [ ] Performance with rapid interactions
- [ ] Memory usage over time

---

## Known Behaviors (Not Bugs)

### Expected Behaviors
1. **Search on Submit Only**: Typing doesn't trigger search until Return/Enter
   - *Why*: Prevents API spam, better UX

2. **Fixed Resolution**: All captures are 2048×2048
   - *Why*: Consistent high quality for now, configurable in future

3. **Metadata Display Only**: Metadata shown but not saved to Card yet
   - *Why*: Card model doesn't have metadata field (future enhancement)

4. **Internet Required**: Maps need network connection
   - *Why*: Apple Maps data not cached in app (may use device-cached tiles)

5. **No Annotations**: Can't add pins/labels before capture
   - *Why*: Phase 3.5 feature (planned)

---

## Troubleshooting

### Issue: Search returns no results
**Possible Causes:**
- No internet connection
- Search term too vague or misspelled
- Location doesn't exist in Apple Maps database

**Try:**
- Check network connection
- Try a more specific search
- Search a well-known landmark

---

### Issue: Map tiles not loading
**Possible Causes:**
- Network issues
- Apple Maps service temporarily unavailable

**Try:**
- Wait a few seconds (may be loading)
- Check internet connection
- Try panning to different area
- Restart app

---

### Issue: Capture fails with error
**Possible Causes:**
- Network dropped during capture
- Invalid map region
- Memory issues (rare)

**Try:**
- Check error message for specifics
- Try capturing again
- Zoom to different level
- Restart app if persistent

---

### Issue: Map view is blank/black
**Possible Causes:**
- MapKit not linked properly
- Platform-specific rendering issue
- Simulator limitations (rare)

**Try:**
- Build and run again
- Test on physical device
- Check Xcode console for errors

---

### Issue: Preview doesn't show image
**Possible Causes:**
- Capture actually failed (check for error)
- Platform-specific image conversion issue

**Try:**
- Check if `capturedMapData` is nil
- Look for conversion errors in console
- Try on different platform (macOS vs iOS)

---

## Code Locations

If you need to modify or debug:

### Main Implementation
```
MapWizardView.swift
├─ State: Lines ~48-58 (Maps Integration State)
├─ UI: Lines ~600-850 (mapsConfigView)
├─ Search: Lines ~450-500 (performSearch, selectLocation)
├─ Capture: Lines ~500-600 (captureMapSnapshot)
└─ Metadata: Lines ~600-650 (mapMetadataDisplayView)
```

### Supporting Types
```
MapWizardView.swift
└─ MapCaptureMetadata struct: Lines ~870-876
```

### Validation Logic
```
MapWizardView.swift
└─ canProceed computed property: Lines ~750-770
```

---

## Quick Debugging

### Add Print Statements

```swift
// In performSearch()
print("🔍 Searching for: \(searchText)")
print("📍 Found \(response.mapItems.count) results")

// In selectLocation()
print("📌 Selected: \(item.name ?? "Unknown")")
print("📐 Coordinates: \(item.placemark.coordinate)")

// In captureMapSnapshot()
print("📸 Starting capture...")
print("🖼️ Snapshot completed: \(snapshot != nil)")
print("💾 PNG data size: \(capturedMapData?.count ?? 0) bytes")

// In canProceed
print("✅ Can proceed? \(capturedMapData != nil)")
```

### Check State in Debugger

Set breakpoints and inspect:
- `searchResults` - Should have items after search
- `selectedMapItem` - Should be set after selection
- `capturedMapData` - Should have data after capture
- `mapMetadata` - Should be populated with capture

---

## Performance Benchmarks

### Expected Timings
- **Search**: < 2 seconds for results
- **Location Selection**: Instant (smooth animation)
- **Map Pan/Zoom**: 60fps, no lag
- **Snapshot Capture**: 2-5 seconds
- **Image Display**: < 1 second

### Memory Usage
- **Base Wizard**: ~50-100 MB
- **With Map View**: +50-100 MB (tiles cached)
- **After Capture**: +16 MB (2048×2048 PNG)
- **After Save**: Memory released on reset

*Note: Actual numbers vary by platform and content*

---

## Reporting Issues

### What to Include
1. **Steps to Reproduce**: Exact sequence of actions
2. **Expected Behavior**: What should happen
3. **Actual Behavior**: What actually happened
4. **Platform**: macOS / iOS / iPadOS (version)
5. **Screenshots**: If applicable
6. **Console Logs**: Any errors or warnings
7. **Location Searched**: Specific query used
8. **Map Style**: Standard/Satellite/Hybrid

### Example Bug Report
```
Title: Capture fails when zoomed too close

Steps:
1. Search "Eiffel Tower"
2. Zoom in very close (can see individual details)
3. Tap "Capture Map Snapshot"

Expected: High-res capture of zoomed view
Actual: Error "Failed to capture map"

Platform: macOS 14.0
Map Style: Satellite
Console: (attach error message)
```

---

## Next Steps After Testing

### If Everything Works
- ✅ Mark Phase 3 as tested
- ✅ Consider Phase 3.5 enhancements (annotations, etc.)
- ✅ Move to Phase 2 (Drawing) or Phase 4 (AI)

### If Issues Found
- 🐛 Document all issues
- 🔧 Fix critical bugs
- 🎯 Re-test after fixes
- 📝 Update known issues list

---

## Resources

### Documentation
- `Phase3-MapKit-Integration-Summary.md` - Complete overview
- `Phase3-Architecture-Diagram.md` - Visual flow diagrams
- `Phase3-TestingChecklist.md` - Comprehensive test cases
- `MapWizardViewSpec.md` - Full specification (updated)

### Apple Documentation
- [MapKit SwiftUI](https://developer.apple.com/documentation/mapkit/map)
- [MKLocalSearch](https://developer.apple.com/documentation/mapkit/mklocalsearch)
- [MKMapSnapshotter](https://developer.apple.com/documentation/mapkit/mkmapsnapshotter)

---

## Tips for Best Results

### For Testing
1. **Vary Locations**: Test urban, rural, landmarks, addresses
2. **Try All Styles**: Each style may reveal different issues
3. **Test Extremes**: Very close zoom, very far zoom
4. **Multiple Captures**: Do several in a row
5. **Edge Cases**: Unusual locations (poles, ocean, etc.)

### For Development
1. **Read the Spec**: `MapWizardViewSpec.md` has all details
2. **Study Flow**: `Phase3-Architecture-Diagram.md` shows structure
3. **Check Tests**: `Phase3-TestingChecklist.md` for scenarios
4. **Async Aware**: Remember snapshot is asynchronous
5. **Cross-Platform**: Test on both macOS and iOS if possible

---

## Questions?

### Common Questions

**Q: Can I search coordinates?**  
A: Currently, no. Search uses natural language (places, addresses). Coordinate input could be added in Phase 3.5.

**Q: Can I add pins before capturing?**  
A: Not yet. Annotation tools are planned for Phase 3.5.

**Q: Where is the metadata saved?**  
A: Currently displayed only. Persistence to Card model is Phase 3.5 enhancement.

**Q: Can I change capture resolution?**  
A: Fixed at 2048×2048 for now. Configurable option planned for Phase 3.5.

**Q: Does this work offline?**  
A: Partially. May use cached map tiles, but search requires internet.

---

## Happy Testing! 🗺️

You're now ready to explore the MapKit integration! This is a powerful feature that brings real-world locations into the Map Wizard.

**Feedback Welcome:**  
If you find issues, have suggestions, or want to contribute enhancements, document them and we'll prioritize for future phases.

---

**End of Quick Start Guide**
