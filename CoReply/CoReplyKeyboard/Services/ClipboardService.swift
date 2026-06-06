// ClipboardService.swift
// CoReplyKeyboard
//
// Polls UIPasteboard for changes and surfaces new content to observers.
// Requires "Allow Full Access" in keyboard settings to read clipboard.

import UIKit
import Foundation

@MainActor
final class ClipboardService {

    // MARK: - Singleton

    static let shared = ClipboardService()

    // MARK: - Properties

    private var lastChangeCount: Int = -1
    private var pollingTimer: Timer?

    /// Called whenever new, non-empty clipboard text is detected.
    var onNewClipboardContent: ((String) -> Void)?

    // MARK: - Init

    private init() {}

    // MARK: - Polling

    /// Starts polling the clipboard every 0.5 seconds.
    func startPolling() {
        guard pollingTimer == nil else { return }
        checkForChanges()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkForChanges()
            }
        }
    }

    /// Stops the polling timer.
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - Change Detection

    private func checkForChanges() {
        let currentCount = UIPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Persist change count to AppGroup so the main app can observe.
        AppGroupStorage.shared.lastClipboardChangeCount = currentCount

        guard let raw = UIPasteboard.general.string,
              !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let normalized = normalizeText(raw)
        AppGroupStorage.shared.lastClipboardText = normalized
        onNewClipboardContent?(normalized)
    }

    // MARK: - Text Normalization

    /// Trims whitespace, collapses 3+ consecutive newlines to 2.
    func normalizeText(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        // Collapse runs of spaces (but not tabs/newlines already handled)
        let parts = result.components(separatedBy: " ")
        result = parts.filter { !$0.isEmpty }.joined(separator: " ")
        // Re-apply normalized newline collapse on joined result
        result = result.replacingOccurrences(of: " \n", with: "\n")
        result = result.replacingOccurrences(of: "\n ", with: "\n")
        return result
    }

    // MARK: - Helpers

    /// Returns `true` if the keyboard has Full Access (required for clipboard read).
    func hasFullAccess() -> Bool {
        // UIPasteboard.general.hasStrings is a reasonable proxy; it returns false
        // when there's no string on the board OR when access is denied.
        return UIPasteboard.general.hasStrings
    }

    /// Returns the current clipboard text without triggering change detection.
    func currentText() -> String? {
        guard let raw = UIPasteboard.general.string else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : normalizeText(trimmed)
    }

    /// Forcibly syncs the current clipboard into AppGroup storage and fires the callback.
    func syncCurrentClipboard() {
        let currentCount = UIPasteboard.general.changeCount
        lastChangeCount = currentCount
        AppGroupStorage.shared.lastClipboardChangeCount = currentCount

        guard let text = currentText() else { return }
        AppGroupStorage.shared.lastClipboardText = text
        onNewClipboardContent?(text)
    }
}
