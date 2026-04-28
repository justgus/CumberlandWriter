//
//  SceneTextEditor.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-26.
//  NSTextView/UITextView wrapper for editing a single Scene Card's detailedText.
//
//  Phase 1 Implementation (ER-0056)
//  - Plain Text editing only
//  - Arrow key navigation detection (up/down at boundaries)
//  - Focus management
//  - Text change callbacks
//

import SwiftUI

#if os(macOS)
import AppKit

/// Wrapper view that properly sizes NSTextView
class SizableTextView: NSTextView {
    override var intrinsicContentSize: NSSize {
        guard let layoutManager = layoutManager,
              let textContainer = textContainer else {
            return NSSize(width: NSView.noIntrinsicMetric, height: 100)
        }

        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)

        return NSSize(
            width: NSView.noIntrinsicMetric,
            height: max(100, usedRect.height + textContainerInset.height * 2)
        )
    }
}

/// macOS-specific scene text editor
struct SceneTextEditor: NSViewRepresentable {
    @Binding var text: String
    let scene: Card
    @Binding var isActive: Bool
    var isFocused: FocusState<Bool>.Binding
    var onTextChanged: (String) -> Void
    var onNavigateUp: () -> Void     // Arrow up from first line
    var onNavigateDown: () -> Void   // Arrow down from last line

    func makeNSView(context: Context) -> SizableTextView {
        let textView = SizableTextView()

        // Configuration
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.font = .systemFont(ofSize: 16, weight: .regular)  // Will use serif in future
        textView.textContainerInset = CGSize(width: 60, height: 20)
        textView.delegate = context.coordinator
        textView.backgroundColor = .textBackgroundColor
        textView.drawsBackground = true
        textView.string = text

        // Configure text container for proper sizing
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true
            textContainer.heightTracksTextView = false
            textContainer.containerSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        }

        // Important: Set max/min size for proper vertical sizing
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 100)  // Minimum 100pt height
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        print("DEBUG SceneTextEditor: Created NSTextView with text length: \(text.count)")

        return textView
    }

    func updateNSView(_ textView: SizableTextView, context: Context) {
        // Only update text if it genuinely changed from an external source
        // (not from the user typing in this very text view)
        if textView.string != text && textView.window?.firstResponder != textView {
            let selectedRange = textView.selectedRange()
            textView.string = text

            // Restore cursor position if valid
            if selectedRange.location <= text.count {
                textView.setSelectedRange(selectedRange)
            }

            // Invalidate intrinsic content size when text changes
            textView.invalidateIntrinsicContentSize()
        }

        // Handle focus changes
        if isFocused.wrappedValue && textView.window?.firstResponder != textView {
            textView.window?.makeFirstResponder(textView)
        } else if !isFocused.wrappedValue && textView.window?.firstResponder == textView {
            textView.window?.makeFirstResponder(nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SceneTextEditor

        init(_ parent: SceneTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? SizableTextView else { return }

            // Invalidate size when text changes
            textView.invalidateIntrinsicContentSize()

            // Update text binding and notify parent
            // Use direct update instead of async to maintain focus
            let newText = textView.string
            if parent.text != newText {
                parent.text = newText
                parent.onTextChanged(newText)
            }
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? SizableTextView else { return }

            // Update active state when focus changes
            if textView.window?.firstResponder == textView {
                parent.isActive = true
                parent.isFocused.wrappedValue = true
            }
        }

        // Arrow key navigation detection
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard let sizableTextView = textView as? SizableTextView else { return false }
            // Detect arrow up at first line
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                let cursorLocation = sizableTextView.selectedRange().location

                // Check if cursor is on first line
                if isOnFirstLine(textView: sizableTextView, location: cursorLocation) {
                    DispatchQueue.main.async {
                        self.parent.onNavigateUp()
                    }
                    return true  // Handled
                }
            }

            // Detect arrow down at last line
            if commandSelector == #selector(NSResponder.moveDown(_:)) {
                let cursorLocation = sizableTextView.selectedRange().location

                // Check if cursor is on last line
                if isOnLastLine(textView: sizableTextView, location: cursorLocation) {
                    DispatchQueue.main.async {
                        self.parent.onNavigateDown()
                    }
                    return true  // Handled
                }
            }

            return false  // Not handled, allow default behavior
        }

        // Helper: Check if cursor is on first line
        private func isOnFirstLine(textView: NSTextView, location: Int) -> Bool {
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else {
                return false
            }

            // Ensure layout is complete to avoid recursion
            layoutManager.ensureLayout(for: textContainer)

            // Get glyph index for cursor location
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: location)

            // Get line fragment for this glyph
            var lineRange = NSRange()
            layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineRange, withoutAdditionalLayout: true)

            // First line starts at glyph 0
            return lineRange.location == 0
        }

        // Helper: Check if cursor is on last line
        private func isOnLastLine(textView: NSTextView, location: Int) -> Bool {
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else {
                return false
            }

            let textLength = textView.string.count
            if textLength == 0 {
                return true  // Empty scene = first and last line
            }

            // Ensure layout is complete to avoid recursion
            layoutManager.ensureLayout(for: textContainer)

            // Get glyph index for cursor location
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: location)

            // Get glyph index for last character
            let lastGlyphIndex = layoutManager.glyphIndexForCharacter(at: textLength - 1)

            // Get line fragment ranges without triggering additional layout
            var cursorLineRange = NSRange()
            var lastLineRange = NSRange()
            layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &cursorLineRange, withoutAdditionalLayout: true)
            layoutManager.lineFragmentRect(forGlyphAt: lastGlyphIndex, effectiveRange: &lastLineRange, withoutAdditionalLayout: true)

            // Check if cursor line is same as last line
            return cursorLineRange.location == lastLineRange.location
        }
    }
}

#else
import UIKit

/// iOS-specific scene text editor
struct SceneTextEditor: UIViewRepresentable {
    @Binding var text: String
    let scene: Card
    @Binding var isActive: Bool
    var isFocused: FocusState<Bool>.Binding
    var onTextChanged: (String) -> Void
    var onNavigateUp: () -> Void
    var onNavigateDown: () -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        // Configuration
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: 16, weight: .regular)  // Will use serif in future
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 60, bottom: 20, right: 60)
        textView.delegate = context.coordinator
        textView.backgroundColor = .systemBackground
        textView.text = text

        // Keyboard configuration
        textView.keyboardType = .default
        textView.autocorrectionType = .yes
        textView.spellCheckingType = .yes

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // Update text if it changed externally
        if textView.text != text {
            let selectedRange = textView.selectedRange
            textView.text = text

            // Restore cursor position if valid
            if selectedRange.location <= text.count {
                textView.selectedRange = selectedRange
            }
        }

        // Handle focus changes
        if isFocused.wrappedValue && !textView.isFirstResponder {
            textView.becomeFirstResponder()
        } else if !isFocused.wrappedValue && textView.isFirstResponder {
            textView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SceneTextEditor

        init(_ parent: SceneTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            // Update text binding and notify parent
            DispatchQueue.main.async {
                self.parent.text = textView.text
                self.parent.onTextChanged(textView.text)
            }
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            // Update active state when focus changes
            DispatchQueue.main.async {
                if textView.isFirstResponder {
                    self.parent.isActive = true
                    self.parent.isFocused.wrappedValue = true
                }
            }
        }

        // Note: iOS arrow key navigation detection requires external keyboard
        // For now, we'll handle this in a future phase with gesture recognizers
        // or by detecting when cursor reaches text boundaries
    }
}
#endif
