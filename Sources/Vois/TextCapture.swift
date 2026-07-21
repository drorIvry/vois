import AppKit
import Foundation
import SelectedTextKit

/// Selected-text capture via SelectedTextKit's tiered cascade (PRD §5.1):
/// AX API → menu Copy → simulated Cmd+C with clipboard save/restore.
///
/// Explicit strategy list, NOT `.auto`: the auto path doesn't catch the AX
/// tier's throw, so Chromium browsers (Arc/Chrome drag selections raise
/// AXError.NoValue) abort before the fallbacks run. The multi-strategy API
/// swallows per-tier errors and moves on.
enum TextCapture {
    static func selectedText() async throws -> String? {
        do {
            if let text = try await SelectedTextManager.shared.getSelectedText(
                strategies: [.accessibility, .menuAction, .shortcut]), !text.isEmpty {
                return text
            }
        } catch let error as SelectedTextKitError {
            if case .accessibilityPermissionDenied = error { throw error }
        }
        // Mouse-capturing TUIs (herdr, tmux, vim) hold their selection inside the
        // terminal process where no AX/copy tier can see it. herdr copies on
        // select, so the clipboard is the selection; fall back to it rather than
        // failing. Cost: with nothing selected anywhere, this speaks the last
        // clipboard instead of erroring.
        return NSPasteboard.general.string(forType: .string)
    }
}
