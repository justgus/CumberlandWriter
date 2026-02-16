//
//  LayerPersistenceDelegate.swift
//  BrushEngine
//
//  Protocol for automatic layer persistence notifications.
//  Conforming types receive callbacks whenever LayerManager
//  state changes that warrants saving.
//

import Foundation

// MARK: - Layer Persistence Delegate

/// Implement this protocol on any type that stores BrushEngine layer data.
///
/// External apps connect a ``LayerManager`` to their storage layer
/// by assigning a conforming object to ``LayerManager/persistenceDelegate``.
/// The manager calls ``save(layerData:)`` after every mutating operation,
/// and ``loadDraftWork()`` can be used to restore prior work.
///
/// Example (SwiftData model):
/// ```swift
/// @Model
/// class MapProject: LayerPersistenceDelegate {
///     @Attribute(.externalStorage)
///     var draftLayerData: Data?
///
///     func save(layerData: Data) {
///         self.draftLayerData = layerData
///     }
///
///     func loadDraftWork() -> Data? {
///         return draftLayerData
///     }
/// }
/// ```
public protocol LayerPersistenceDelegate: AnyObject {
    /// Called by ``LayerManager`` whenever layer state changes.
    /// Implementations should persist `layerData` to stable storage.
    func save(layerData: Data)

    /// Called during ``LayerManager/loadDraftWork()`` to restore prior state.
    /// Return `nil` if no saved data exists.
    func loadDraftWork() -> Data?
}
