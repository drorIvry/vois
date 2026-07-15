import AVFoundation
import Foundation

/// Sentence-chunked audio playback (PRD §5.5): AVAudioEngine + pitch-preserving
/// rate control. Buffers are appended as synthesis completes; playback starts
/// with the first one.
@MainActor
final class AudioPlayer: ObservableObject {
    enum State: Equatable {
        case idle, playing, paused, finished
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var currentSentence: Int = 0
    @Published private(set) var sentenceCount: Int = 0
    @Published var rate: Float = 1.0 {
        didSet { timePitch.rate = rate }
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()
    private var format: AVAudioFormat?

    /// Synthesized sentence buffers, in order. May grow while playing.
    private var buffers: [AVAudioPCMBuffer] = []
    /// Index of the next buffer to schedule.
    private var scheduleIndex = 0
    /// Generation counter: bump on stop/skip so stale completion handlers are ignored.
    private var generation = 0

    init() {
        engine.attach(player)
        engine.attach(timePitch)
    }

    /// Begin a new playback session. `expectedCount` sizes the progress UI.
    func start(sampleRate: Double, expectedCount: Int) {
        stop()
        let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        if format?.sampleRate != sampleRate || !engine.isRunning {
            engine.disconnectNodeOutput(player)
            engine.disconnectNodeOutput(timePitch)
            engine.connect(player, to: timePitch, format: fmt)
            engine.connect(timePitch, to: engine.mainMixerNode, format: fmt)
            format = fmt
        }
        timePitch.rate = rate
        sentenceCount = expectedCount
        currentSentence = 0
        buffers = []
        scheduleIndex = 0
        try? engine.start()
        player.play()
        state = .playing
    }

    /// Append a synthesized sentence; schedules it immediately.
    func append(samples: [Float]) {
        guard let format, state == .playing || state == .paused else { return }
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { src in
            buffer.floatChannelData![0].update(from: src.baseAddress!, count: samples.count)
        }
        buffers.append(buffer)
        scheduleFrom(max(scheduleIndex, buffers.count - 1))
    }

    /// Called by the controller when the last sentence has been appended.
    func finishAppending() {
        sentenceCount = buffers.count
        // If everything already played, mark finished.
        if scheduleIndex >= buffers.count, currentSentence >= buffers.count {
            state = .finished
        }
    }

    func pause() {
        guard state == .playing else { return }
        player.pause()
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        try? engine.start()
        player.play()
        state = .playing
    }

    func togglePause() {
        state == .paused ? resume() : pause()
    }

    func stop() {
        generation += 1
        player.stop()
        engine.stop()
        buffers = []
        scheduleIndex = 0
        currentSentence = 0
        sentenceCount = 0
        state = .idle
    }

    func skipForward() { skip(to: currentSentence + 1) }
    func skipBackward() { skip(to: currentSentence - 1) }

    private func skip(to index: Int) {
        guard !buffers.isEmpty else { return }
        let target = min(max(index, 0), buffers.count - 1)
        generation += 1
        player.stop()
        currentSentence = target
        scheduleIndex = target
        scheduleFrom(target)
        if state != .paused {
            try? engine.start()
            player.play()
            state = .playing
        }
    }

    /// Schedule buffers[from...] that aren't scheduled yet.
    private func scheduleFrom(_ from: Int) {
        let gen = generation
        while scheduleIndex < buffers.count {
            let index = scheduleIndex
            let buffer = buffers[index]
            player.scheduleBuffer(buffer) { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self, self.generation == gen else { return }
                    self.currentSentence = index + 1
                    if index + 1 >= self.buffers.count, index + 1 >= self.sentenceCount {
                        self.state = .finished
                    }
                }
            }
            scheduleIndex += 1
        }
    }
}
