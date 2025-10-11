// SearchIntegrationGuide.md
# Deep Search Integration Guide

This guide demonstrates how the deep indexing and search functionality works in Cumberland.

## Overview

The search system provides comprehensive full-text search across all Card fields with intelligent navigation that can override default detail views.

## Key Components

### 1. SearchEngine
- Performs full-text search across Card name, subtitle, detailedText, and author fields
- Returns SearchResult objects with context and match information
- Normalizes search queries for case-insensitive, diacritics-insensitive matching

### 2. NavigationCoordinator  
- Manages app-wide navigation state
- Can force CardSheetView to display instead of default detail views
- Handles search result navigation seamlessly

### 3. SearchRouter
- Controls search overlay presentation
- Integrates with SearchEngine for live search results
- Manages search UI state

### 4. SearchOverlay
- Modern SwiftUI search interface with Liquid Glass effects
- Live search results with debouncing
- Rich result previews showing match context

## Navigation Behavior

### Default Detail Views by Kind
- **Projects**: CardRelationshipView (shows related cards)
- **Sources**: CardSheetView (citation management)
- **Structure**: CardSheetView (story structure)
- **Others**: CardSheetView (standard editing)

### Search Result Navigation
When a user clicks a search result:
1. NavigationCoordinator.navigateToSearchResult() is called
2. Sets selectedKind to the card's kind
3. Sets selectedCard to the specific card
4. Sets forceCardSheetView = true
5. MainAppView updates to show CardSheetView regardless of kind's default

## Usage Example

```swift
// In your main app
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .modelContainer(for: Card.self)
        }
    }
}

// The user can:
// 1. Press ⌘F or click search button
// 2. Type "dragon" in search field
// 3. See all cards mentioning "dragon" in any field
// 4. Click a result for a Project card
// 5. Navigate directly to that card's CardSheetView (not CardRelationshipView)
// 6. View the card content with search term context
```

## Search Result Types

Each SearchResult includes:
- `card`: The matching Card object
- `matchType`: Which field matched (.name, .subtitle, .details, .author)
- `preview`: Context excerpt showing the match
- `matchRange`: Location of match in original text

## Customization

### Adding New Searchable Fields
To add new searchable fields to Card:

1. Add the field to Card model
2. Update the field's didSet to call recomputeNormalizedSearchText()
3. Update SearchEngine.search() to include the new field

### Custom Detail Views
To add custom detail views for specific kinds:

1. Update DetailView.defaultDetailView() switch statement
2. Add your custom view case
3. Ensure it can still be overridden by forceCardSheetView

### Search UI Customization
The SearchOverlay uses Liquid Glass effects and can be customized by:
- Modifying LiquidGlassModifiers.swift
- Updating SearchResultRow styling
- Changing search behavior (debouncing, max results, etc.)

## Platform Considerations

### macOS
- Full NavigationSplitView with sidebar, content, and detail panes
- Search accessible via ⌘F keyboard shortcut
- Supports window-based navigation

### iOS/iPadOS  
- Adaptive NavigationSplitView that collapses on smaller screens
- Search button in toolbar
- Native iOS navigation patterns

### visionOS
- Special launch screen with 3D content
- Liquid Glass effects for spatial computing
- MainAppView available after "Get Started"

## Search Performance

The search system is optimized for:
- Live search with debouncing (250ms delay)
- Normalized text matching for better results
- Efficient SwiftData queries with predicates
- Lazy result rendering for large datasets

## Testing Search

To test the search functionality:

1. Create sample cards with various content
2. Use the search overlay (⌘F)
3. Try searching for:
   - Card names
   - Subtitle text  
   - Content from detailedText
   - Author names
4. Verify navigation works correctly
5. Test on different platforms (macOS, iOS, visionOS)