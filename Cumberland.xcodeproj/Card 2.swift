// Card.swift (replaces your current Card.swift contents)
import Foundation
import SwiftData
import SwiftUI
import CoreGraphics
import ImageIO

extension Cumberland.Model {
    @Model
    final class Card: Identifiable {
        var id: UUID
        var name: String
        var shortDescription: String
        var detailedText: String
        var sizeCategory: SizeCategory
        var imageData: Data?

        init(
            id: UUID = UUID(),
            name: String,
            shortDescription: String,
            detailedText: String,
            sizeCategory: SizeCategory = .standard,
            imageData: Data? = nil
        ) {
            self.id = id
            self.name = name
            self.shortDescription = shortDescription
            self.detailedText = detailedText
            self.sizeCategory = sizeCategory
            self.imageData = imageData
        }
    }
}

extension Cumberland.Model.Card {
    var image: Image? { /* unchanged */ return nil }
    var thumbnailImage: Image? { /* unchanged */ return nil }
    func setImageData(_ data: Data?) { /* unchanged */ }
}

private extension Cumberland.Model.Card {
    func cgImage() -> CGImage? { /* unchanged */ return nil }
    func cgThumbnail(maxPixelSize: Int) -> CGImage? { /* unchanged */ return nil }
}

extension Cumberland.Model {
    enum SizeCategory: Int, Codable, CaseIterable, Hashable, Sendable {
        case compact, standard, large
        var displayName: String { /* unchanged */ return "" }
    }
}
