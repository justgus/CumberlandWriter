//
//  CitationKind.swift
//  Cumberland
//
//  Enum enumerating the four citation kinds: quote, paraphrase, image, data.
//  Provides displayName, SF Symbol name, and color tint for each kind. Used
//  by Citation model and citation UI views to categorise and visually
//  differentiate source references.
//

import Foundation
import SwiftUI

enum CitationKind: String, Codable, Identifiable, CaseIterable, Hashable {
    case quote
    case paraphrase
    case image
    case data

    var displayName: String {
        switch self {
        case .quote:      return String(localized: "Quote")
        case .paraphrase: return String(localized: "Paraphrase")
        case .image:      return String(localized: "Image")
        case .data:       return String(localized: "Data")
        } //end switch
    } //end displayName
    
    var id: String { rawValue }

} //end CitationKind
