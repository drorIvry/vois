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
        try await SelectedTextManager.shared.getSelectedText(
            strategies: [.accessibility, .menuAction, .shortcut])
    }
}
