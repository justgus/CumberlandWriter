//
//  ImageStore.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/1/25.
//

import Foundation

final class ImageStore {
    static let shared = ImageStore()

    private let fm = FileManager.default
    private let baseURL: URL

    private init() {
        let appSupport = try! fm.url(for: .applicationSupportDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: true)
        let dir = appSupport.appendingPathComponent("Images", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        self.baseURL = dir
    }

    func originalURL(for id: UUID, fileExtension: String) -> URL {
        baseURL.appendingPathComponent("\(id.uuidString).\(fileExtension)")
    }

    func writeOriginalImageData(_ data: Data, for id: UUID, fileExtension: String) throws -> URL {
        let url = originalURL(for: id, fileExtension: fileExtension)
        // Overwrite if exists
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
        try data.write(to: url, options: .atomic)
        return url
    }

    func deleteOriginalImage(at url: URL) throws {
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
    }
}
