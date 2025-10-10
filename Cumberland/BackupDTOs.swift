import Foundation

// MARK: - Manifest

struct BackupManifestDTO: Codable {
    var formatVersion: Int
    var appIdentifier: String
    var exportedAt: Date
    var counts: Counts

    struct Counts: Codable {
        var cards: Int
        var sources: Int
        var citations: Int
        var relationTypes: Int
        var cardEdges: Int
        var appSettings: Int
        var images: Int
    }

    static func v1(appIdentifier: String,
                   cards: Int, sources: Int, citations: Int,
                   relationTypes: Int, cardEdges: Int,
                   appSettings: Int, images: Int) -> BackupManifestDTO {
        BackupManifestDTO(
            formatVersion: 1,
            appIdentifier: appIdentifier,
            exportedAt: Date(),
            counts: .init(cards: cards,
                          sources: sources,
                          citations: citations,
                          relationTypes: relationTypes,
                          cardEdges: cardEdges,
                          appSettings: appSettings,
                          images: images)
        )
    }
}

// MARK: - DTOs

struct CardDTO: Codable {
    var id: UUID
    var kindRaw: String
    var name: String
    var subtitle: String
    var detailedText: String
    var author: String?
    var sizeCategoryRaw: Int
    var normalizedSearchText: String
    // Relative path to original image inside the package, e.g. "images/original/<id>.<ext>"
    var originalImageRelativePath: String?
}

struct SourceDTO: Codable {
    var id: UUID
    var title: String
    var authors: String
    var containerTitle: String?
    var publisher: String?
    var year: Int?
    var volume: String?
    var issue: String?
    var pages: String?
    var doi: String?
    var url: String?
    var accessedDate: Date?
    var license: String?
    var notes: String?
}

struct CitationDTO: Codable {
    var id: UUID
    var cardID: UUID
    var sourceID: UUID
    var kindRaw: String
    var locator: String
    var excerpt: String
    var contextNote: String?
    var createdAt: Date
}

struct RelationTypeDTO: Codable {
    var code: String
    var forwardLabel: String
    var inverseLabel: String
    var sourceKindRaw: String?
    var targetKindRaw: String?
}

struct CardEdgeDTO: Codable {
    var fromID: UUID
    var toID: UUID
    var typeCode: String
    var note: String?
    var createdAt: Date
    var sortIndex: Double
}

struct AppSettingsDTO: Codable {
    var linesCompact: Int
    var linesStandard: Int
    var linesLarge: Int
    var colorSchemePreferenceRaw: String
    var lastSelectedSettingsSectionRaw: String
    var defaultAuthor: String
}

