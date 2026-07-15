import AppKit
import Foundation

/// Orchestrates the core loop (PRD §5.5): capture → preprocess → synthesize
/// sentence 1 → play immediately → synthesize ahead.
@MainActor
final class SpeechController: ObservableObject {
    enum Phase: Equatable {
        case idle
        case capturing
        case synthesizing
        case playing
        case error(String)
    }

    @Published private(set) var phase: Phase = .idle
    let player = AudioPlayer()
    let bar = PlaybackBarPanel()

    private let engine: TTSEngine
    private let capture: @Sendable () async throws -> String?
    private var synthesisTask: Task<Void, Never>?
    private var fadeWatcher: Task<Void, Never>?

    init(engine: TTSEngine, capture: @escaping @Sendable () async throws -> String?) {
        self.engine = engine
        self.capture = capture
        watchPlayerForFade()
    }

    var isActive: Bool {
        if case .idle = phase { return false }
        return true
    }

    /// Text currently being spoken; used to tell "stop" from "replace" (PRD F11).
    private var currentText: String?

    /// Hotkey handler (PRD F11): idle → speak selection. During playback:
    /// new selection → replace, same/no selection → stop.
    func toggle() {
        guard isActive else {
            speakSelection()
            return
        }
        guard AppSettings.shared.replaceOnNewSelection else {
            stop()
            return
        }
        let previous = currentText
        Task { [weak self] in
            guard let self else { return }
            let text = (try? await self.capture())?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let text, !text.isEmpty, text != previous {
                self.speak(text: text)
            } else {
                self.stop()
            }
        }
    }

    func speakSelection() {
        stop()
        phase = .capturing
        bar.show(controller: self)
        bar.cancelFadeOut()

        synthesisTask = Task { [weak self] in
            guard let self else { return }
            let text: String?
            do {
                text = try await self.capture()
            } catch {
                NSLog("Vois capture error: %@", String(describing: error))
                self.fail("Couldn't grab selection — try Cmd+C first")
                return
            }
            guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                self.fail("No text selected")
                return
            }
            self.speak(text: text)
        }
    }

    /// Speak arbitrary text (core loop; also used by onboarding demo and voice preview).
    func speak(text: String) {
        synthesisTask?.cancel()
        currentText = text

        let sentences = TextPreprocessor.sentences(from: text)
        guard !sentences.isEmpty else {
            fail("Nothing readable in selection")
            return
        }

        phase = .synthesizing
        bar.show(controller: self)
        bar.cancelFadeOut()
        player.rate = Float(AppSettings.shared.speed)
        player.start(sampleRate: engine.sampleRate, expectedCount: sentences.count)

        let voice = AppSettings.shared.voice
        let engine = self.engine
        synthesisTask = Task { [weak self] in
            for (i, sentence) in sentences.enumerated() {
                if Task.isCancelled { return }
                do {
                    let samples = try await engine.synthesize(text: sentence, voice: voice)
                    guard let self, !Task.isCancelled else { return }
                    self.player.append(samples: samples)
                    if i == 0 { self.phase = .playing }
                } catch {
                    guard let self, !Task.isCancelled else { return }
                    if i == 0 {
                        self.fail("Synthesis failed: \(error.localizedDescription)")
                        return
                    }
                    // Mid-stream failure: keep what we have.
                    break
                }
            }
            self?.player.finishAppending()
        }
    }

    func stop() {
        synthesisTask?.cancel()
        synthesisTask = nil
        currentText = nil
        player.stop()
        phase = .idle
        bar.hide()
    }

    private func fail(_ message: String) {
        NSLog("Vois error: %@", message)
        phase = .error(message)
        player.stop()
        bar.show(controller: self)
        bar.scheduleFadeOut()
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            if case .error = self?.phase { self?.phase = .idle }
        }
    }

    /// Fade the bar 2s after playback finishes.
    private func watchPlayerForFade() {
        fadeWatcher = Task { [weak self] in
            guard let self else { return }
            for await _ in self.player.$state.values {
                if self.player.state == .finished {
                    self.phase = .idle
                    self.bar.scheduleFadeOut()
                }
            }
        }
    }
}
