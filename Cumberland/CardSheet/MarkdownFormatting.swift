//
//  MarkdownFormatting.swift
//  Cumberland
//
//  Extracted from CardSheetView.swift as part of ER-0022 Phase 3.2.
//  Pure-logic struct MarkdownFormatter with static helpers for toggling
//  bold/italic/inline-code delimiters, wrapping selections in block quotes,
//  inserting headers, and prepending list markers in card detail text.
//

import Foundation

/// Markdown formatting operations for text editing
struct MarkdownFormatter {

    // MARK: - Wrap/Unwrap Delimiters

    /// Toggle wrap with delimiter (bold, italic, inline code)
    static func toggleWrap(
        in text: String,
        selection: NSRange,
        delimiter: String
    ) -> (newText: String, newSelection: NSRange) {
        let ns = text as NSString
        var range = selection
        range.location = max(0, min(range.location, ns.length))
        range.length = max(0, min(range.length, ns.length - range.location))

        // If no selection, insert paired delimiters and place cursor between
        if range.length == 0 {
            let insertion = delimiter + delimiter
            let start = range.location
            let newText = ns.replacingCharacters(in: NSRange(location: start, length: 0), with: insertion)
            let newSelection = NSRange(location: start + delimiter.count, length: 0)
            return (newText, newSelection)
        }

        // Check if selection is already wrapped
        let beforeLoc = range.location - delimiter.count
        let afterLoc = range.location + range.length
        let canCheckBefore = beforeLoc >= 0
        let canCheckAfter = (afterLoc + delimiter.count) <= ns.length

        let before = canCheckBefore ? ns.substring(with: NSRange(location: beforeLoc, length: delimiter.count)) : ""
        let after = canCheckAfter ? ns.substring(with: NSRange(location: afterLoc, length: delimiter.count)) : ""

        if before == delimiter && after == delimiter {
            // Unwrap
            var newText = ns.replacingCharacters(in: NSRange(location: afterLoc, length: delimiter.count), with: "")
            let newNS = newText as NSString
            newText = newNS.replacingCharacters(in: NSRange(location: beforeLoc, length: delimiter.count), with: "")
            let newSelection = NSRange(location: range.location - delimiter.count, length: range.length)
            return (newText, newSelection)
        } else {
            // Wrap
            var newText = ns.replacingCharacters(in: NSRange(location: afterLoc, length: 0), with: delimiter)
            let newNS = newText as NSString
            newText = newNS.replacingCharacters(in: NSRange(location: range.location, length: 0), with: delimiter)
            let newSelection = NSRange(location: range.location + delimiter.count, length: range.length)
            return (newText, newSelection)
        }
    }

    static func toggleItalic(in text: String, selection: NSRange) -> (String, NSRange) {
        toggleWrap(in: text, selection: selection, delimiter: "*")
    }

    static func toggleBold(in text: String, selection: NSRange) -> (String, NSRange) {
        toggleWrap(in: text, selection: selection, delimiter: "**")
    }

    static func toggleInlineCode(in text: String, selection: NSRange) -> (String, NSRange) {
        toggleWrap(in: text, selection: selection, delimiter: "`")
    }

    // MARK: - Line Operations

    /// Get line ranges covering the selection
    static func lineRangesCoveringSelection(in ns: NSString, selection: NSRange) -> [NSRange] {
        var lines: [NSRange] = []
        let selEnd = selection.location + selection.length
        var cursor = selection.location

        let firstLine = ns.lineRange(for: NSRange(location: max(0, selection.location - 1), length: 0))
        lines.append(firstLine)
        cursor = firstLine.location + firstLine.length

        while cursor < selEnd {
            let r = ns.lineRange(for: NSRange(location: cursor, length: 0))
            lines.append(r)
            cursor = r.location + r.length
        }
        return lines
    }

    /// Replace ranges with transformed content
    static func replaceRanges(
        _ ranges: [NSRange],
        in ns: NSString,
        with transform: (String, Int) -> String
    ) -> (String, NSRange) {
        var newText = ns as String
        var deltaTotal = 0

        for (idx, range) in ranges.enumerated() {
            let adjusted = NSRange(location: range.location + deltaTotal, length: range.length)
            let line = (newText as NSString).substring(with: adjusted)
            let replaced = transform(line, idx)
            newText = (newText as NSString).replacingCharacters(in: adjusted, with: replaced)
            deltaTotal += (replaced as NSString).length - adjusted.length
        }

        let first = ranges.first!
        let last = ranges.last!
        let newSelStart = first.location
        let newSelEnd = last.location + last.length + deltaTotal
        let newSel = NSRange(location: newSelStart, length: max(0, newSelEnd - newSelStart))
        return (newText, newSel)
    }

    // MARK: - Line Prefix Detection

    static func lineHasAnyBulletPrefix(_ s: String) -> (has: Bool, markerLen: Int) {
        if s.hasPrefix("- ") { return (true, 2) }
        if s.hasPrefix("* ") { return (true, 2) }
        if s.hasPrefix("+ ") { return (true, 2) }
        return (false, 0)
    }

    static func lineHasChecklistPrefix(_ s: String) -> (has: Bool, markerLen: Int, done: Bool) {
        if s.hasPrefix("- [ ] ") { return (true, 6, false) }
        if s.hasPrefix("- [x] ") { return (true, 6, true) }
        if s.hasPrefix("* [ ] ") { return (true, 6, false) }
        if s.hasPrefix("* [x] ") { return (true, 6, true) }
        return (false, 0, false)
    }

    // MARK: - List Operations

    static func toggleBulletList(in text: String, selection: NSRange) -> (String, NSRange) {
        let ns = text as NSString
        let lines = lineRangesCoveringSelection(in: ns, selection: selection)
        guard !lines.isEmpty else { return (text, selection) }

        let allHave = lines.allSatisfy { r in
            let s = ns.substring(with: r)
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty { return true }
            return lineHasAnyBulletPrefix(s).has || lineHasChecklistPrefix(s).has
        }

        return replaceRanges(lines, in: ns) { line, _ in
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return line }
            if lineHasChecklistPrefix(line).has {
                if allHave {
                    return line
                        .replacingOccurrences(of: "- [ ] ", with: "")
                        .replacingOccurrences(of: "- [x] ", with: "")
                        .replacingOccurrences(of: "* [ ] ", with: "")
                        .replacingOccurrences(of: "* [x] ", with: "")
                }
            }
            let bullet = lineHasAnyBulletPrefix(line)
            if allHave, bullet.has {
                return String(line.dropFirst(bullet.markerLen))
            } else if !allHave {
                return "- " + line
            } else {
                return line
            }
        }
    }

    static func toggleNumberedList(in text: String, selection: NSRange) -> (String, NSRange) {
        let ns = text as NSString
        let lines = lineRangesCoveringSelection(in: ns, selection: selection)
        guard !lines.isEmpty else { return (text, selection) }

        let numberRegex = try! NSRegularExpression(pattern: #"^\s*\d+\.\s"#, options: [])
        let allNumbered = lines.allSatisfy { r in
            let s = ns.substring(with: r)
            let range = NSRange(location: 0, length: (s as NSString).length)
            return numberRegex.firstMatch(in: s, options: [], range: range) != nil ||
                   s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var counter = 1
        return replaceRanges(lines, in: ns) { line, _ in
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return line }
            if allNumbered {
                if let match = numberRegex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: (line as NSString).length)) {
                    return (line as NSString).replacingCharacters(in: match.range, with: "")
                }
                return line
            } else {
                defer { counter += 1 }
                return "\(counter). " + line
            }
        }
    }

    static func toggleQuote(in text: String, selection: NSRange) -> (String, NSRange) {
        let ns = text as NSString
        let lines = lineRangesCoveringSelection(in: ns, selection: selection)
        guard !lines.isEmpty else { return (text, selection) }

        let allQuoted = lines.allSatisfy { r in
            let s = ns.substring(with: r)
            return s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || s.hasPrefix("> ")
        }

        return replaceRanges(lines, in: ns) { line, _ in
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return line }
            if allQuoted, line.hasPrefix("> ") {
                return String(line.dropFirst(2))
            } else if !allQuoted {
                return "> " + line
            } else {
                return line
            }
        }
    }

    // MARK: - Heading Operations

    static func applyHeading(level: Int, in text: String, selection: NSRange) -> (String, NSRange) {
        let lvl = max(1, min(6, level))
        let prefix = String(repeating: "#", count: lvl) + " "

        let ns = text as NSString
        let lines = lineRangesCoveringSelection(in: ns, selection: selection)
        guard !lines.isEmpty else { return (text, selection) }

        let headingRegex = try! NSRegularExpression(pattern: #"^\s*#{1,6}\s"#, options: [])
        return replaceRanges(lines, in: ns) { line, _ in
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return line }
            let range = NSRange(location: 0, length: (line as NSString).length)
            if let match = headingRegex.firstMatch(in: line, options: [], range: range) {
                let currentPrefix = (line as NSString).substring(with: match.range)
                let currentCount = currentPrefix.filter { $0 == "#" }.count
                if currentCount == lvl {
                    return (line as NSString).replacingCharacters(in: match.range, with: "")
                } else {
                    return (line as NSString).replacingCharacters(in: match.range, with: prefix)
                }
            } else {
                return prefix + line
            }
        }
    }

    // MARK: - Indentation

    static func handleIndentOutdent(isOutdent: Bool, in text: String, selection: NSRange) -> (String, NSRange) {
        let ns = text as NSString
        let lines = lineRangesCoveringSelection(in: ns, selection: selection)
        guard !lines.isEmpty else { return (text, selection) }

        return replaceRanges(lines, in: ns) { line, _ in
            if isOutdent {
                if line.hasPrefix("    ") { return String(line.dropFirst(4)) }
                else if line.hasPrefix("\t") { return String(line.dropFirst(1)) }
                else if line.hasPrefix(" ") { return String(line.dropFirst(1)) }
                else { return line }
            } else {
                return "    " + line
            }
        }
    }

    // MARK: - Code Block

    static func insertCodeBlock(in text: String) -> String {
        var result = text
        if result.last != "\n" && !result.isEmpty {
            result.append("\n")
        }
        result.append("```\ncode\n```\n")
        return result
    }

    // MARK: - Checklist Operations

    static func toggleChecklist(in text: String, selection: NSRange) -> (String, NSRange) {
        let ns = text as NSString
        let lines = lineRangesCoveringSelection(in: ns, selection: selection)
        guard !lines.isEmpty else { return (text, selection) }

        let allChecklist = lines.allSatisfy { r in
            let s = ns.substring(with: r)
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty { return true }
            return lineHasChecklistPrefix(s).has
        }

        let numberRegex = try! NSRegularExpression(pattern: #"^\s*\d+\.\s"#, options: [])

        return replaceRanges(lines, in: ns) { line, _ in
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return line }

            let checklist = lineHasChecklistPrefix(line)
            if allChecklist {
                if checklist.has {
                    return String(line.dropFirst(checklist.markerLen))
                }
                return line
            } else {
                var working = line
                let bullet = lineHasAnyBulletPrefix(working)
                if bullet.has {
                    working = String(working.dropFirst(bullet.markerLen))
                } else if let match = numberRegex.firstMatch(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length)) {
                    working = (working as NSString).replacingCharacters(in: match.range, with: "")
                } else if checklist.has {
                    let dropped = String(working.dropFirst(checklist.markerLen))
                    return "- [ ] " + dropped
                }
                return "- [ ] " + working
            }
        }
    }

    static func toggleChecklistDoneUndone(in text: String, selection: NSRange) -> (String, NSRange) {
        let ns = text as NSString
        let lines = lineRangesCoveringSelection(in: ns, selection: selection)
        guard !lines.isEmpty else { return (text, selection) }

        var anyUnchecked = false
        for r in lines {
            let s = ns.substring(with: r)
            let c = lineHasChecklistPrefix(s)
            if c.has && !c.done {
                anyUnchecked = true
                break
            }
        }

        return replaceRanges(lines, in: ns) { line, _ in
            let c = lineHasChecklistPrefix(line)
            guard c.has else { return line }

            if anyUnchecked {
                if c.done {
                    return line
                } else {
                    if line.hasPrefix("- [ ] ") { return line.replacingOccurrences(of: "- [ ] ", with: "- [x] ") }
                    if line.hasPrefix("* [ ] ") { return line.replacingOccurrences(of: "* [ ] ", with: "* [x] ") }
                    return line
                }
            } else {
                if !c.done {
                    return line
                } else {
                    if line.hasPrefix("- [x] ") { return line.replacingOccurrences(of: "- [x] ", with: "- [ ] ") }
                    if line.hasPrefix("* [x] ") { return line.replacingOccurrences(of: "* [x] ", with: "* [ ] ") }
                    return line
                }
            }
        }
    }
}
