// CitationKind.swift
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
