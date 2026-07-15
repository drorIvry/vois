import AppKit
import KeyboardShortcuts
import SwiftUI

extension KeyboardShortcuts.Name {
    // Fn combos aren't expressible as Carbon hotkeys (library strips .function);
    // Option+S is the closest reliable default. Rebindable in Settings.
    static let speakSelection = Self("speakSelection", initial: .init(.s, modifiers: [.option]))
    // Bare Escape can't be a global hotkey (would swallow Esc system-wide);
    // Esc-stops-playback is handled by a passive event monitor below.
    // This is an optional extra stop shortcut (e.g. Cmd+Esc).
    static let stopPlayback = Self("stopPlayback")
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var controller: SpeechController!
    private let engine = KokoroEngine()
    private var onboardingWindow: NSWindow?
    private var escMonitors: [Any] = []

    override init() {
        super.init()
        controller = SpeechController(engine: engine) {
            try await TextCapture.selectedText()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // TTFA spike (PRD build order #1): `Vois --spike` prints timings and exits.
        if CommandLine.arguments.contains("--spike") {
            runSpike()
            return
        }
        // Debug: `Vois --say "text"` exercises the full loop minus capture.
        if let i = CommandLine.arguments.firstIndex(of: "--say"), i + 1 < CommandLine.arguments.count {
            controller.speak(text: CommandLine.arguments[i + 1])
        }

        NSApp.setActivationPolicy(.accessory)  // menu-bar only, no dock icon

        KeyboardShortcuts.onKeyUp(for: .speakSelection) { [weak self] in
            self?.controller.toggle()
        }
        KeyboardShortcuts.onKeyUp(for: .stopPlayback) { [weak self] in
            guard let self, self.controller.isActive else { return }
            self.controller.stop()
        }

        // Esc stops playback (PRD F11). Passive monitors: don't consume the key.
        let escHandler: (NSEvent) -> Void = { [weak self] event in
            guard event.keyCode == 53, event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty,
                  let self, self.controller.isActive else { return }
            self.controller.stop()
        }
        if let global = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: escHandler) {
            escMonitors.append(global)
        }
        escMonitors.append(NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            escHandler(event)
            return event
        } as Any)

        if !AppSettings.shared.onboardingDone {
            showOnboarding()
        }

        // Warm the model off the critical path so the first hotkey press is fast.
        let engine = self.engine
        Task.detached(priority: .utility) {
            await engine.warmUp()
        }
    }

    private func runSpike() {
        let engine = self.engine
        Task.detached {
            do {
                let clock = ContinuousClock()
                var first: [Float] = []
                let cold = try await clock.measure {
                    first = try await engine.synthesize(text: "Hello from Vois.", voice: AppSettings.defaultVoice)
                }
                let rms = (first.reduce(Float(0)) { $0 + $1 * $1 } / Float(max(first.count, 1))).squareRoot()
                print("TTFA cold (load + first synth): \(cold) — \(first.count) samples, RMS \(rms)")
                guard rms.isFinite, rms > 0.001, first.count > 8000 else {
                    print("spike failed: degenerate audio")
                    exit(2)
                }
                var warm: [Duration] = []
                for text in ["This is a warm synthesis pass.",
                             "Latency matters more than throughput.",
                             "The quick brown fox jumps over the lazy dog."] {
                    let t = try await clock.measure {
                        _ = try await engine.synthesize(text: text, voice: AppSettings.defaultVoice)
                    }
                    warm.append(t)
                    print("TTFA warm: \(t)")
                }
                let p50 = warm.sorted()[warm.count / 2]
                print("warm p50: \(p50) (target < 1s: \(p50 < .seconds(1) ? "PASS" : "FAIL"))")
                exit(p50 < .seconds(1) ? 0 : 1)
            } catch {
                print("spike failed: \(error)")
                exit(2)
            }
        }
    }

    func showOnboarding() {
        if let onboardingWindow {
            onboardingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(
            rootView: OnboardingView(controller: controller) { [weak self] in
                AppSettings.shared.onboardingDone = true
                self?.onboardingWindow?.close()
                self?.onboardingWindow = nil
            }
        )
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        onboardingWindow = window
    }
}
