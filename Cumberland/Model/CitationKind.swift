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
        case .quote:      return "Quote"
        case .paraphrase: return "Paraphrase"
        case .image:      return "Image"
        case .data:       return "Data"
        } //end switch
    } //end displayName
    
    var id: String { rawValue }

} //end CitationKind
