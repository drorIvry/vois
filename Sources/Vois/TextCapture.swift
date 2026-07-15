import Foundation
import SelectedTextKit

/// Selected-text capture via SelectedTextKit's tiered cascade (PRD §5.1):
/// AX API → menu Copy → simulated Cmd+C with clipboard save/restore.
enum TextCapture {
    static func selectedText() async throws -> String? {
        try await SelectedTextManager.shared.getSelectedText(strategy: .auto)
    }
}
