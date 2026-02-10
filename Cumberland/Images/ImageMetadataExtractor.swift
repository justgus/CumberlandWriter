//
//  ImageMetadataExtractor.swift
//  Cumberland
//
//  Created by Mike Stoddard on 11/11/25.
//
//  Reads EXIF/IPTC/GPS metadata from image data using ImageIO. Extracts
//  fields such as artist, copyright, description, GPS coordinates, camera
//  make/model, and capture date. Used by the quick-attribution flow to
//  pre-fill citation fields when a user imports an image.
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

        // MARK: - AI Generation Metadata (ER-0009 Phase 4A)

        /// AI provider/artist information (from TIFF Artist or IPTC Source)
        let aiProvider: String?

        /// AI generation prompt (from EXIF UserComment or IPTC Caption)
        let aiPrompt: String?

        /// Copyright information (from TIFF/IPTC Copyright)
        let copyright: String?

        /// Keywords/tags (from IPTC Keywords)
        let keywords: [String]?

        /// Creation date from IPTC (for AI-generated images)
        let iptcDateCreated: Date?
        
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

        /// Whether this image appears to be AI-generated (based on metadata)
        var isAIGenerated: Bool {
            aiProvider != nil || aiPrompt != nil || (keywords?.contains { $0.lowercased().contains("ai") } ?? false)
        }

        /// Formatted AI attribution string
        var aiAttributionText: String? {
            guard let provider = aiProvider else { return nil }
            if let prompt = aiPrompt, !prompt.isEmpty {
                return "\(provider) - \"\(prompt)\""
            }
            return provider
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
        let iptc = properties[kCGImagePropertyIPTCDictionary as String] as? [String: Any]

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

        // MARK: - AI Generation Metadata (ER-0009 Phase 4A)

        // AI Provider (from TIFF Artist or IPTC Source)
        let aiProvider: String? = {
            if let artist = tiff?[kCGImagePropertyTIFFArtist as String] as? String {
                return artist.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let source = iptc?[kCGImagePropertyIPTCSource as String] as? String {
                return source.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return nil
        }()

        // AI Prompt (from EXIF UserComment or IPTC Caption)
        let aiPrompt: String? = {
            // Try EXIF UserComment first (more detailed)
            if let userComment = exif?[kCGImagePropertyExifUserComment as String] as? String {
                // Extract prompt from user comment
                let trimmed = userComment.trimmingCharacters(in: .whitespacesAndNewlines)
                // Parse multi-line format (see ImageMetadataWriter.createUserComment)
                if let promptRange = trimmed.range(of: "Prompt: ") {
                    let afterPrompt = trimmed[promptRange.upperBound...]
                    if let softwareRange = afterPrompt.range(of: "\nSoftware:") {
                        return String(afterPrompt[..<softwareRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    return String(afterPrompt).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return trimmed
            }

            // Fallback to IPTC Caption
            if let caption = iptc?[kCGImagePropertyIPTCCaptionAbstract as String] as? String {
                // Extract prompt from caption (format: "AI-generated image. Prompt: <prompt>")
                let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
                if let promptRange = trimmed.range(of: "Prompt: ") {
                    return String(trimmed[promptRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return trimmed
            }

            return nil
        }()

        // Copyright (from TIFF or IPTC)
        let copyright: String? = {
            if let tiffCopyright = tiff?[kCGImagePropertyTIFFCopyright as String] as? String {
                return tiffCopyright.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let iptcCopyright = iptc?[kCGImagePropertyIPTCCopyrightNotice as String] as? String {
                return iptcCopyright.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return nil
        }()

        // Keywords (from IPTC)
        let keywords = iptc?[kCGImagePropertyIPTCKeywords as String] as? [String]

        // IPTC Date Created (for AI-generated images)
        let iptcDateCreated = extractIPTCDate(from: iptc)
        
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
            software: software?.trimmingCharacters(in: .whitespacesAndNewlines),
            aiProvider: aiProvider,
            aiPrompt: aiPrompt,
            copyright: copyright,
            keywords: keywords,
            iptcDateCreated: iptcDateCreated
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
            software: nil,
            aiProvider: nil,
            aiPrompt: nil,
            copyright: nil,
            keywords: nil,
            iptcDateCreated: nil
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

    /// Extract date from IPTC metadata (ER-0009 Phase 4A)
    private static func extractIPTCDate(from iptc: [String: Any]?) -> Date? {
        guard let iptc = iptc,
              let dateString = iptc[kCGImagePropertyIPTCDateCreated as String] as? String else {
            return nil
        }

        // IPTC date format: "YYYYMMDD"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current

        guard let date = formatter.date(from: dateString) else {
            return nil
        }

        // Try to add time component if available
        if let timeString = iptc[kCGImagePropertyIPTCTimeCreated as String] as? String {
            // IPTC time format: "HHMMSS±HHMM" or "HHMMSS"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HHmmss"
            timeFormatter.locale = Locale(identifier: "en_US_POSIX")
            timeFormatter.timeZone = TimeZone.current

            // Extract just the time part (ignore timezone for now)
            let cleanTime = timeString.components(separatedBy: CharacterSet(charactersIn: "+-")).first ?? timeString
            if let timeDate = timeFormatter.date(from: cleanTime) {
                let calendar = Calendar.current
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: timeDate)

                var combined = DateComponents()
                combined.year = dateComponents.year
                combined.month = dateComponents.month
                combined.day = dateComponents.day
                combined.hour = timeComponents.hour
                combined.minute = timeComponents.minute
                combined.second = timeComponents.second

                return calendar.date(from: combined) ?? date
            }
        }

        return date
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
