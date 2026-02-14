//
//  ImageProcessingError.swift
//  ImageProcessing
//
//  Error types for image processing operations.
//

import Foundation

public enum ImageProcessingError: Error, Sendable {
    case invalidImageData
    case conversionFailed(format: String)
    case loadFailed(reason: String)
}
