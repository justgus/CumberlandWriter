//
//  BrushRegistry.swift
//  Cumberland
//
//  Central brush management - registry of all brush sets
//

import SwiftUI
import Foundation

// MARK: - Brush Registry

/// Manages all installed brush sets and handles import/export
@Observable
class BrushRegistry {
    // MARK: - Singleton
    
    static let shared = BrushRegistry()
    
    // MARK: - Properties
    
    /// All installed brush sets
    var installedBrushSets: [BrushSet] = []
    
    /// ID of the currently active brush set
    var activeBrushSetID: UUID?
    
    /// Currently selected brush within the active set
    var selectedBrushID: UUID?
    
    // MARK: - Computed Properties
    
    /// The currently active brush set
    var activeBrushSet: BrushSet? {
        get {
            installedBrushSets.first { $0.id == activeBrushSetID }
        }
        set {
            activeBrushSetID = newValue?.id
        }
    }
    
    /// The currently selected brush
    var selectedBrush: MapBrush? {
        get {
            guard let brushSetID = activeBrushSetID,
                  let brushID = selectedBrushID else { return nil }
            return installedBrushSets
                .first { $0.id == brushSetID }?
                .getBrush(id: brushID)
        }
        set {
            selectedBrushID = newValue?.id
        }
    }
    
    /// All built-in brush sets
    var builtInBrushSets: [BrushSet] {
        installedBrushSets.filter { $0.isBuiltIn }
    }
    
    /// All custom/imported brush sets
    var customBrushSets: [BrushSet] {
        installedBrushSets.filter { !$0.isBuiltIn }
    }
    
    /// Whether any brush sets are installed
    var hasBrushSets: Bool {
        !installedBrushSets.isEmpty
    }
    
    // MARK: - Initialization
    
    private init() {
        loadPersistedBrushSets()
        
        // If no brush sets exist, load built-in sets
        if installedBrushSets.isEmpty {
            loadBuiltInBrushSets()
        }
        
        // Set active brush set if not set
        if activeBrushSetID == nil, let firstSet = installedBrushSets.first {
            activeBrushSetID = firstSet.id
            
            // Select first brush in set
            if let firstBrush = firstSet.brushes.first {
                selectedBrushID = firstBrush.id
            }
        }
    }
    
    // MARK: - Built-In Brush Sets
    
    /// Load all built-in brush sets
    func loadBuiltInBrushSets() {
        // Create basic brush set (always available)
        let basicSet = createBasicBrushSet()
        installedBrushSets.append(basicSet)
        
        // Load exterior brush set
        let exteriorSet = ExteriorMapBrushSet.create()
        installedBrushSets.append(exteriorSet)

        // ER-0004: Load interior brush set
        let interiorSet = InteriorMapBrushSet.create()
        installedBrushSets.append(interiorSet)

        // Set exterior as active by default (most common use case)
        if activeBrushSetID == nil {
            activeBrushSetID = exteriorSet.id
            if let firstBrush = exteriorSet.brushes.first {
                selectedBrushID = firstBrush.id
            }
        }
        
        saveBrushSets()
    }
    
    /// Create the basic built-in brush set
    private func createBasicBrushSet() -> BrushSet {
        var brushSet = BrushSet(
            name: "Basic Tools",
            description: "Essential drawing tools for all map types",
            mapType: .custom,
            brushes: [],
            defaultLayers: [.generic],
            author: "Cumberland",
            version: "1.0",
            isBuiltIn: true,
            isInstalled: true
        )
        
        // Add basic brushes
        brushSet.brushes = [
            .basicPen,
            .pencil,
            .marker,
            MapBrush(
                name: "Fine Line",
                icon: "pencil.line",
                category: .basic,
                defaultWidth: 1.0,
                minWidth: 0.5,
                maxWidth: 3.0,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Thick Line",
                icon: "rectangle.fill",
                category: .basic,
                defaultWidth: 15.0,
                minWidth: 10.0,
                maxWidth: 30.0,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Dashed Line",
                icon: "line.diagonal",
                category: .roads,
                defaultWidth: 3.0,
                patternType: .dashed,
                isBuiltIn: true
            ),
            MapBrush(
                name: "Dotted Line",
                icon: "ellipsis",
                category: .roads,
                defaultWidth: 3.0,
                patternType: .dotted,
                isBuiltIn: true
            )
        ]
        
        return brushSet
    }
    
    // MARK: - Brush Set Management
    
    /// Install a brush set
    func installBrushSet(_ brushSet: BrushSet) throws {
        // Check if already installed
        if installedBrushSets.contains(where: { $0.id == brushSet.id }) {
            throw BrushRegistryError.brushSetAlreadyInstalled
        }
        
        var mutableSet = brushSet
        mutableSet.isInstalled = true
        
        installedBrushSets.append(mutableSet)
        saveBrushSets()
    }
    
    /// Uninstall a brush set (only custom sets can be uninstalled)
    func uninstallBrushSet(id: UUID) throws {
        guard let brushSet = installedBrushSets.first(where: { $0.id == id }) else {
            throw BrushRegistryError.brushSetNotFound
        }
        
        if brushSet.isBuiltIn {
            throw BrushRegistryError.cannotUninstallBuiltIn
        }
        
        installedBrushSets.removeAll { $0.id == id }
        
        // If we uninstalled the active set, switch to another
        if activeBrushSetID == id {
            activeBrushSetID = installedBrushSets.first?.id
            if let firstBrush = activeBrushSet?.brushes.first {
                selectedBrushID = firstBrush.id
            } else {
                selectedBrushID = nil
            }
        }
        
        saveBrushSets()
    }
    
    /// Get a brush set by ID
    func getBrushSet(id: UUID) -> BrushSet? {
        installedBrushSets.first { $0.id == id }
    }
    
    /// Update a brush set
    func updateBrushSet(_ brushSet: BrushSet) {
        if let index = installedBrushSets.firstIndex(where: { $0.id == brushSet.id }) {
            installedBrushSets[index] = brushSet
            saveBrushSets()
        }
    }
    
    // MARK: - Custom Brush Set Creation
    
    /// Create a new custom brush set
    @discardableResult
    func createCustomBrushSet(name: String, mapType: MapType) -> BrushSet {
        let brushSet = BrushSet(
            name: name,
            description: "Custom brush set",
            mapType: mapType,
            brushes: [],
            defaultLayers: mapType.recommendedLayers,
            author: nil,
            version: "1.0",
            isBuiltIn: false,
            isInstalled: true
        )
        
        installedBrushSets.append(brushSet)
        saveBrushSets()
        
        return brushSet
    }
    
    /// Add a brush to a custom brush set
    func addBrushToSet(brush: MapBrush, setID: UUID) throws {
        guard var brushSet = getBrushSet(id: setID) else {
            throw BrushRegistryError.brushSetNotFound
        }
        
        if brushSet.isBuiltIn {
            throw BrushRegistryError.cannotModifyBuiltIn
        }
        
        brushSet.addBrush(brush)
        updateBrushSet(brushSet)
    }
    
    /// Remove a brush from a custom brush set
    func removeBrushFromSet(brushID: UUID, setID: UUID) throws {
        guard var brushSet = getBrushSet(id: setID) else {
            throw BrushRegistryError.brushSetNotFound
        }
        
        if brushSet.isBuiltIn {
            throw BrushRegistryError.cannotModifyBuiltIn
        }
        
        brushSet.removeBrush(id: brushID)
        updateBrushSet(brushSet)
    }
    
    // MARK: - Brush Selection
    
    /// Set the active brush set
    func setActiveBrushSet(id: UUID) {
        guard installedBrushSets.contains(where: { $0.id == id }) else { return }
        activeBrushSetID = id
        
        // Auto-select first brush in new set
        if let firstBrush = activeBrushSet?.brushes.first {
            selectedBrushID = firstBrush.id
        }
    }
    
    /// Select a brush by ID (within the active brush set)
    func selectBrush(id: UUID) {
        guard let activeBrushSet = activeBrushSet,
              activeBrushSet.brushes.contains(where: { $0.id == id }) else { return }
        selectedBrushID = id
    }
    
    /// Select the next brush in the active set
    func selectNextBrush() {
        guard let activeBrushSet = activeBrushSet,
              let currentID = selectedBrushID,
              let currentIndex = activeBrushSet.brushes.firstIndex(where: { $0.id == currentID }) else {
            // Select first brush if none selected
            selectedBrushID = activeBrushSet?.brushes.first?.id
            return
        }
        
        let nextIndex = (currentIndex + 1) % activeBrushSet.brushes.count
        selectedBrushID = activeBrushSet.brushes[nextIndex].id
    }
    
    /// Select the previous brush in the active set
    func selectPreviousBrush() {
        guard let activeBrushSet = activeBrushSet,
              let currentID = selectedBrushID,
              let currentIndex = activeBrushSet.brushes.firstIndex(where: { $0.id == currentID }) else {
            // Select last brush if none selected
            selectedBrushID = activeBrushSet?.brushes.last?.id
            return
        }
        
        let previousIndex = (currentIndex - 1 + activeBrushSet.brushes.count) % activeBrushSet.brushes.count
        selectedBrushID = activeBrushSet.brushes[previousIndex].id
    }
    
    // MARK: - Import/Export
    
    /// Export a brush set as a package
    func exportBrushSet(id: UUID) -> Data? {
        guard let brushSet = getBrushSet(id: id) else { return nil }
        
        let package = BrushSetPackage(brushSet: brushSet)
        return try? JSONEncoder().encode(package)
    }
    
    /// Import a brush set from package data
    func importBrushSet(from data: Data) throws -> BrushSet {
        let package = try JSONDecoder().decode(BrushSetPackage.self, from: data)
        var brushSet = package.toBrushSet()
        
        // Ensure unique ID if a set with this ID already exists
        if installedBrushSets.contains(where: { $0.id == brushSet.id }) {
            brushSet = BrushSet(
                id: UUID(), // Generate new ID
                name: brushSet.name + " (Imported)",
                description: brushSet.description,
                mapType: brushSet.mapType,
                brushes: brushSet.brushes,
                defaultLayers: brushSet.defaultLayers,
                thumbnail: brushSet.thumbnail,
                author: brushSet.author,
                version: brushSet.version,
                isBuiltIn: false,
                isInstalled: false
            )
        }
        
        try installBrushSet(brushSet)
        return brushSet
    }
    
    /// Export a brush set to a file URL
    func exportBrushSetToFile(id: UUID, url: URL) throws {
        guard let data = exportBrushSet(id: id) else {
            throw BrushRegistryError.exportFailed
        }
        
        try data.write(to: url)
    }
    
    /// Import a brush set from a file URL
    @discardableResult
    func importBrushSetFromFile(url: URL) throws -> BrushSet {
        let data = try Data(contentsOf: url)
        return try importBrushSet(from: data)
    }
    
    // MARK: - Persistence
    
    private var brushSetsFileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("Cumberland_BrushSets.json")
    }
    
    /// Save all brush sets to disk
    private func saveBrushSets() {
        let collection = BrushSetCollection(brushSets: installedBrushSets)
        
        guard let data = try? JSONEncoder().encode(collection) else {
            print("Failed to encode brush sets")
            return
        }
        
        do {
            try data.write(to: brushSetsFileURL)
        } catch {
            print("Failed to save brush sets: \(error)")
        }
    }
    
    /// Load brush sets from disk
    private func loadPersistedBrushSets() {
        guard FileManager.default.fileExists(atPath: brushSetsFileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: brushSetsFileURL)
            let collection = try JSONDecoder().decode(BrushSetCollection.self, from: data)
            installedBrushSets = collection.brushSets
        } catch {
            print("Failed to load brush sets: \(error)")
        }
    }
    
    // MARK: - Search & Filter
    
    /// Search for brushes across all sets
    func searchBrushes(query: String) -> [MapBrush] {
        guard !query.isEmpty else { return [] }
        
        let lowercasedQuery = query.lowercased()
        var results: [MapBrush] = []
        
        for brushSet in installedBrushSets {
            let matches = brushSet.brushes.filter { brush in
                brush.name.lowercased().contains(lowercasedQuery) ||
                brush.category.rawValue.lowercased().contains(lowercasedQuery)
            }
            results.append(contentsOf: matches)
        }
        
        return results
    }
    
    /// Get all brushes in a specific category across all sets
    func brushes(in category: BrushCategory) -> [MapBrush] {
        installedBrushSets.flatMap { brushSet in
            brushSet.brushes(in: category)
        }
    }
    
    /// Get brush sets for a specific map type
    func brushSets(for mapType: MapType) -> [BrushSet] {
        installedBrushSets.filter { $0.mapType == mapType || $0.mapType == .hybrid }
    }
}

// MARK: - Brush Registry Error

enum BrushRegistryError: LocalizedError {
    case brushSetNotFound
    case brushSetAlreadyInstalled
    case cannotUninstallBuiltIn
    case cannotModifyBuiltIn
    case exportFailed
    case importFailed
    case invalidBrushSetData
    
    var errorDescription: String? {
        switch self {
        case .brushSetNotFound:
            return "The requested brush set was not found."
        case .brushSetAlreadyInstalled:
            return "This brush set is already installed."
        case .cannotUninstallBuiltIn:
            return "Built-in brush sets cannot be uninstalled."
        case .cannotModifyBuiltIn:
            return "Built-in brush sets cannot be modified."
        case .exportFailed:
            return "Failed to export brush set."
        case .importFailed:
            return "Failed to import brush set."
        case .invalidBrushSetData:
            return "The brush set data is invalid or corrupted."
        }
    }
}

// MARK: - Brush Registry Extension for Previews

extension BrushRegistry {
    /// Create a sample registry for previews
    static func sample() -> BrushRegistry {
        let registry = BrushRegistry()
        // The singleton already loads built-in sets
        return registry
    }
}
