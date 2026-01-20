// SpecHeaderGuardTests.swift
import Foundation

#if canImport(Testing)
import Testing

@Suite("Spec Header Guards")
struct SpecHeaderGuardTests {

    // Adjust project-relative path if needed.
    private var fileURL: URL {
        // Assuming project structure: <repo>/Cumberland/MurderboardView.swift
        let fm = FileManager.default
        var dir = URL(fileURLWithPath: fm.currentDirectoryPath)
        // Walk up until we find the file (works in CI and local)
        for _ in 0..<6 {
            let candidate = dir.appendingPathComponent("Cumberland/MurderboardView.swift")
            if fm.fileExists(atPath: candidate.path) {
                return candidate
            }
            dir.deleteLastPathComponent()
        }
        return URL(fileURLWithPath: "Cumberland/MurderboardView.swift")
    }

    private func sectionBulletCount(_ text: String, header: String) -> Int {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let idx = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == header }) else { return 0 }
        var i = idx + 1
        var count = 0
        while i < lines.count {
            let line = lines[i]
            if line.trimmingCharacters(in: .whitespaces).isEmpty { break }
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("*/") { break }
            if line.hasPrefix(" -") { count += 1 }
            i += 1
        }
        return count
    }

    @Test("MurderboardView.swift has Acceptance Criteria and Implementation Plan")
    func hasRequiredSections() throws {
        let data = try Data(contentsOf: fileURL)
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.contains("\n Acceptance Criteria\n"), "Missing Acceptance Criteria section header.")
        #expect(text.contains("\n Implementation Plan\n") || text.contains("\nImplementation Plan\n"), "Missing Implementation Plan section header.")
        let ac = sectionBulletCount(text, header: "Acceptance Criteria")
        let ip = max(sectionBulletCount(text, header: "Implementation Plan"),
                     sectionBulletCount(text, header: " Implementation Plan"))
        #expect(ac >= 10, "Acceptance Criteria too short (\(ac) < 10 bullets).")
        #expect(ip >= 10, "Implementation Plan too short (\(ip) < 10 bullets).")
    }
}

#else
import XCTest

final class SpecHeaderGuardTests: XCTestCase {

    // Adjust project-relative path if needed.
    private var fileURL: URL {
        // Assuming project structure: <repo>/Cumberland/MurderboardView.swift
        let fm = FileManager.default
        var dir = URL(fileURLWithPath: fm.currentDirectoryPath)
        // Walk up until we find the file (works in CI and local)
        for _ in 0..<6 {
            let candidate = dir.appendingPathComponent("Cumberland/MurderboardView.swift")
            if fm.fileExists(atPath: candidate.path) {
                return candidate
            }
            dir.deleteLastPathComponent()
        }
        return URL(fileURLWithPath: "Cumberland/MurderboardView.swift")
    }

    private func sectionBulletCount(_ text: String, header: String) -> Int {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let idx = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == header }) else { return 0 }
        var i = idx + 1
        var count = 0
        while i < lines.count {
            let line = lines[i]
            if line.trimmingCharacters(in: .whitespaces).isEmpty { break }
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("*/") { break }
            if line.hasPrefix(" -") { count += 1 }
            i += 1
        }
        return count
    }

    func testHasRequiredSections() throws {
        let data = try Data(contentsOf: fileURL)
        let text = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(text.contains("\n Acceptance Criteria\n"),
                      "Missing Acceptance Criteria section header.")

        XCTAssertTrue(text.contains("\n Implementation Plan\n") || text.contains("\nImplementation Plan\n"),
                      "Missing Implementation Plan section header.")

        let ac = sectionBulletCount(text, header: "Acceptance Criteria")
        let ip = max(sectionBulletCount(text, header: "Implementation Plan"),
                     sectionBulletCount(text, header: " Implementation Plan"))

        XCTAssertGreaterThanOrEqual(ac, 10, "Acceptance Criteria too short (\(ac) < 10 bullets).")
        XCTAssertGreaterThanOrEqual(ip, 10, "Implementation Plan too short (\(ip) < 10 bullets).")
    }
}
#endif
