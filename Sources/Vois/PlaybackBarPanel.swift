import AppKit
import SwiftUI

/// Floating, non-activating playback bar (PRD §7): never steals focus,
/// draggable, position persisted, auto-fades after playback ends.
@MainActor
final class PlaybackBarPanel {
    private var panel: NSPanel?
    private var fadeTask: Task<Void, Never>?

    func show(controller: SpeechController) {
        fadeTask?.cancel()
        if let panel {
            panel.alphaValue = 1
            panel.orderFrontRegardless()
            return
        }
        let view = PlaybackBarView(controller: controller)
        let hosting = NSHostingView(rootView: view)
        // Fixed-size panel; never let SwiftUI drive window size (see PlaybackBarView.size).
        hosting.sizingOptions = []
        hosting.frame.size = PlaybackBarView.size

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: PlaybackBarView.size),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.contentView = hosting
        panel.delegate = moveObserver

        setInitialPosition(panel)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    /// Fade out 2s after playback finishes (PRD §7), unless auto-hide is off.
    func scheduleFadeOut() {
        guard AppSettings.shared.barAutoHide else { return }
        fadeTask?.cancel()
        fadeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, let panel = self?.panel else { return }
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.4
                panel.animator().alphaValue = 0
            } completionHandler: {
                Task { @MainActor [weak self] in self?.hide() }
            }
        }
    }

    func cancelFadeOut() {
        fadeTask?.cancel()
        panel?.alphaValue = 1
    }

    func hide() {
        fadeTask?.cancel()
        panel?.orderOut(nil)
        panel = nil
    }

    private func setInitialPosition(_ panel: NSPanel) {
        if let saved = savedOrigin() {
            panel.setFrameOrigin(saved)
            if panel.screen != nil || NSScreen.screens.contains(where: { $0.frame.intersects(panel.frame) }) {
                return
            }
        }
        // Default dock: bottom-center of the main screen, 24pt above the edge.
        guard let screen = NSScreen.main else { return }
        let f = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(
            x: f.midX - panel.frame.width / 2,
            y: f.minY + 24
        ))
    }

    private func savedOrigin() -> NSPoint? {
        let parts = AppSettings.shared.barOrigin.split(separator: ",").compactMap { Double($0) }
        guard parts.count == 2 else { return nil }
        return NSPoint(x: parts[0], y: parts[1])
    }

    private let moveObserver = MoveObserver()

    private final class MoveObserver: NSObject, NSWindowDelegate {
        func windowDidMove(_ notification: Notification) {
            guard let window = notification.object as? NSWindow else { return }
            let o = window.frame.origin
            AppSettings.shared.barOrigin = "\(o.x),\(o.y)"
        }
    }
}
