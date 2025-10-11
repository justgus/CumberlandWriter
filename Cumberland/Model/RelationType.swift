// RelationType.swift
import Foundation
import SwiftData

@Model
final class RelationType {
    // CloudKit: no unique constraints; provide defaults at declaration
    var code: String = ""
    var forwardLabel: String = ""
    var inverseLabel: String = ""

    // Optional constraints: nil means "applies to any"
    // Store raw values to keep predicates simple and consistent with Card.kindRaw.
    var sourceKindRaw: String? = nil
    var targetKindRaw: String? = nil

    // Inverse collection for CardEdge.type (CloudKit: relationship must be optional)
    @Relationship(deleteRule: .nullify, inverse: \CardEdge.type)
    var edges: [CardEdge]? = []

    init(
        code: String,
        forwardLabel: String,
        inverseLabel: String,
        sourceKind: Kinds? = nil,
        targetKind: Kinds? = nil
    ) {
        self.code = code
        self.forwardLabel = forwardLabel
        self.inverseLabel = inverseLabel
        self.sourceKindRaw = sourceKind?.rawValue
        self.targetKindRaw = targetKind?.rawValue
    }

    // Convenience accessors
    var sourceKind: Kinds? {
        get { sourceKindRaw.flatMap { Kinds(rawValue: $0) } }
        set { sourceKindRaw = newValue?.rawValue }
    }

    var targetKind: Kinds? {
        get { targetKindRaw.flatMap { Kinds(rawValue: $0) } }
        set { targetKindRaw = newValue?.rawValue }
    }

    // Helper: does this type apply to a given source -> target pair?
    func matches(from source: Kinds, to target: Kinds) -> Bool {
        let sourceOK = (sourceKindRaw == nil) || (sourceKindRaw == source.rawValue)
        let targetOK = (targetKindRaw == nil) || (targetKindRaw == target.rawValue)
        return sourceOK && targetOK
    }
}
