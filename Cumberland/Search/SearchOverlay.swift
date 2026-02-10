//
//  SearchOverlay.swift
//  Cumberland
//
//  Floating keyboard-activated search overlay. Reads from SearchRouter to
//  show/hide, delegates queries to SearchEngine, and presents results in a
//  scrollable list. Tapping a result navigates via NavigationCoordinator and
//  dismisses the overlay.
//

import SwiftUI

struct SearchOverlay: View {
    @Environment(SearchRouter.self) private var searchRouter
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    let maxResults: Int
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false

    var body: some View {
        ZStack {
            // Dimmed background with glass blur that closes the overlay on tap
            Color.black.opacity(0.2)
                .background(.thinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    searchRouter.close()
                }

            // Search panel with liquid glass effect
            VStack(spacing: 16) {
                // Header with glass effect
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .glassEffect(GlassEffect.regular, in: .circle)
                        .padding(8)
                    
                    Text("Search")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button {
                        searchRouter.close()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(GlassButtonStyle())
                }

                // Search field with enhanced styling
                TextField("Search cards...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.background.secondary)
                            .glassEffect(GlassEffect.regular.interactive(), in: .rect(cornerRadius: 12))
                    }
                    .onChange(of: searchText) { _, newText in
                        Task {
                            await performSearch(newText)
                        }
                    }

                if !searchText.isEmpty {
                    // Results area with glass effects
                    if isSearching {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Searching...")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else if searchResults.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("No results found")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(searchResults) { result in
                                    SearchResultRow(result: result) {
                                        navigationCoordinator.navigateToSearchResult(result)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxHeight: 400)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.background.tertiary)
                                .glassEffect(GlassEffect.regular, in: .rect(cornerRadius: 16))
                        }
                    }
                } else {
                    // Empty state with glass effect
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                            .glassEffect(GlassEffect.regular, in: .circle)
                        
                        VStack(spacing: 4) {
                            Text("Start Typing")
                                .font(.headline)
                            
                            Text("Search through all your cards and content")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.vertical, 24)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: 640, maxHeight: 480, alignment: .topLeading)
            .glassEffect(GlassEffect.regular, in: .rect(cornerRadius: 20))
            .padding()
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    @MainActor
    private func performSearch(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        guard let searchEngine = searchRouter.searchEngine else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        // Add small delay to debounce rapid typing
        try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
        
        // Check if search text changed while we were sleeping
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed else {
            return
        }
        
        let results = await searchEngine.search(trimmed, maxResults: maxResults)
        searchResults = results
        
        isSearching = false
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let result: SearchResult
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Kind and match type indicators
                VStack(spacing: 2) {
                    Image(systemName: result.card.kind.systemImage)
                        .font(.caption)
                        .foregroundStyle(result.card.kind.accentColor(for: scheme))
                        .frame(width: 16, height: 16)
                    
                    Image(systemName: result.matchType.systemImage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 16, height: 12)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    // Card name and kind
                    HStack(spacing: 6) {
                        Text(result.card.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text(result.card.kind.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(result.card.kind.backgroundColor(for: scheme).opacity(0.3))
                            )
                    }
                    
                    // Match type and preview
                    HStack(spacing: 4) {
                        Text(result.matchType.rawValue + ":")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(result.preview)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .glassEffect(GlassEffect.regular.interactive(), in: .rect(cornerRadius: 8))
        .help("Navigate to \(result.card.name) - \(result.matchType.rawValue)")
    }
}

#Preview {
    let router = SearchRouter()
    router.isPresented = true
    return SearchOverlay(maxResults: 50)
        .environment(router)
}

#Preview {
    let router = SearchRouter()
    router.isPresented = true
    return SearchOverlay(maxResults: 50)
        .environment(router)
}
