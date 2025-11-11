//
//  ImageMetadataExtractor.swift
//  Cumberland
//
//  Created by Mike Stoddard on 11/11/25.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreLocation

/// Extracts and organizes metadata from image files
struct ImageMetadataExtractor {
    
    /// Comprehensive metadata extracted from an image
    struct ImageMetadata {
        // Basic Properties
        let width: Int?
        let height: Int?
        let fileSize: Int64?
        let format: String?
        let colorSpace: String?
        let dpi: Int?
        let hasAlpha: Bool?
        
        // Camera/EXIF Data
        let cameraMake: String?
        let cameraModel: String?
        let dateTimeTaken: Date?
        let focalLength: Double?
        let aperture: Double?
        let iso: Int?
        let exposureTime: Double?
        
        // GPS Data
        let location: CLLocationCoordinate2D?
        let altitude: Double?
        
        // Additional
        let orientation: Int?
        let software: String?
        
        var formattedDimensions: String? {
            guard let w = width, let h = height else { return nil }
            return "\(w) × \(h)"
        }
        
        var formattedFileSize: String? {
            guard let size = fileSize else { return nil }
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
        
        var formattedDPI: String? {
            guard let dpi = dpi else { return nil }
            return "\(dpi) DPI"
        }
        
        var hasGPSData: Bool {
            location != nil
        }
        
        var hasCameraData: Bool {
            cameraMake != nil || cameraModel != nil || dateTimeTaken != nil
        }
    }
    
    // MARK: - Extraction
    
    /// Extract metadata from image data
    static func extract(from data: Data) -> ImageMetadata {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return emptyMetadata()
        }
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return emptyMetadata()
        }
        
        // Extract basic image properties
        let width = properties[kCGImagePropertyPixelWidth as String] as? Int
        let height = properties[kCGImagePropertyPixelHeight as String] as? Int
        let orientation = properties[kCGImagePropertyOrientation as String] as? Int
        let hasAlpha = properties[kCGImagePropertyHasAlpha as String] as? Bool
        let colorSpace = properties[kCGImagePropertyColorModel as String] as? String
        
        // DPI from resolution
        let dpiX = properties[kCGImagePropertyDPIWidth as String] as? Int
        let dpiY = properties[kCGImagePropertyDPIHeight as String] as? Int
        let dpi = dpiX ?? dpiY
        
        // File type
        let type = CGImageSourceGetType(source) as? String
        let format = type.flatMap { UTType($0)?.preferredFilenameExtension?.uppercased() }
        
        // File size (from data)
        let fileSize = Int64(data.count)
        
        // EXIF data
        let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any]
        let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        
        let dateTimeTaken = extractDateTime(from: exif)
        let focalLength = exif?[kCGImagePropertyExifFocalLength as String] as? Double
        let aperture = exif?[kCGImagePropertyExifFNumber as String] as? Double
        let iso = exif?[kCGImagePropertyExifISOSpeedRatings as String] as? [Int]
        let exposureTime = exif?[kCGImagePropertyExifExposureTime as String] as? Double
        
        let cameraMake = tiff?[kCGImagePropertyTIFFMake as String] as? String
        let cameraModel = tiff?[kCGImagePropertyTIFFModel as String] as? String
        let software = tiff?[kCGImagePropertyTIFFSoftware as String] as? String
        
        // GPS data
        let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any]
        let location = extractGPSLocation(from: gps)
        let altitude = gps?[kCGImagePropertyGPSAltitude as String] as? Double
        
        return ImageMetadata(
            width: width,
            height: height,
            fileSize: fileSize,
            format: format,
            colorSpace: colorSpace,
            dpi: dpi,
            hasAlpha: hasAlpha,
            cameraMake: cameraMake?.trimmingCharacters(in: .whitespacesAndNewlines),
            cameraModel: cameraModel?.trimmingCharacters(in: .whitespacesAndNewlines),
            dateTimeTaken: dateTimeTaken,
            focalLength: focalLength,
            aperture: aperture,
            iso: iso?.first,
            exposureTime: exposureTime,
            location: location,
            altitude: altitude,
            orientation: orientation,
            software: software?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    /// Extract metadata from a URL
    static func extract(from url: URL) -> ImageMetadata {
        guard let data = try? Data(contentsOf: url) else {
            return emptyMetadata()
        }
        return extract(from: data)
    }
    
    // MARK: - Private Helpers
    
    private static func emptyMetadata() -> ImageMetadata {
        ImageMetadata(
            width: nil,
            height: nil,
            fileSize: nil,
            format: nil,
            colorSpace: nil,
            dpi: nil,
            hasAlpha: nil,
            cameraMake: nil,
            cameraModel: nil,
            dateTimeTaken: nil,
            focalLength: nil,
            aperture: nil,
            iso: nil,
            exposureTime: nil,
            location: nil,
            altitude: nil,
            orientation: nil,
            software: nil
        )
    }
    
    private static func extractDateTime(from exif: [String: Any]?) -> Date? {
        guard let exif = exif,
              let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String else {
            return nil
        }
        
        // EXIF date format: "YYYY:MM:DD HH:MM:SS"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateString)
    }
    
    private static func extractGPSLocation(from gps: [String: Any]?) -> CLLocationCoordinate2D? {
        guard let gps = gps,
              let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double,
              let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
              let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String else {
            return nil
        }
        
        // Apply hemisphere references
        let lat = (latRef == "S") ? -latitude : latitude
        let lon = (lonRef == "W") ? -longitude : longitude
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// MARK: - Convenience Extensions

extension ImageMetadataExtractor.ImageMetadata {
    
    /// Human-readable summary of key metadata
    var summary: String {
        var lines: [String] = []
        
        if let dims = formattedDimensions {
            lines.append("Size: \(dims)")
        }
        
        if let size = formattedFileSize {
            lines.append("File: \(size)")
        }
        
        if let fmt = format {
            lines.append("Format: \(fmt)")
        }
        
        if let camera = cameraModel {
            lines.append("Camera: \(camera)")
        }
        
        if hasGPSData {
            lines.append("📍 Location data available")
        }
        
        return lines.joined(separator: " · ")
    }
    
    /// Dictionary representation for debugging or storage
    var dictionary: [String: Any] {
        var dict: [String: Any] = [:]
        
        if let width = width { dict["width"] = width }
        if let height = height { dict["height"] = height }
        if let fileSize = fileSize { dict["fileSize"] = fileSize }
        if let format = format { dict["format"] = format }
        if let cameraMake = cameraMake { dict["cameraMake"] = cameraMake }
        if let cameraModel = cameraModel { dict["cameraModel"] = cameraModel }
        if let dateTimeTaken = dateTimeTaken { dict["dateTimeTaken"] = dateTimeTaken }
        
        if let location = location {
            dict["latitude"] = location.latitude
            dict["longitude"] = location.longitude
        }
        
        return dict
    }
}
