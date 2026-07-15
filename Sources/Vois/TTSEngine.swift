import Foundation

/// Abstraction over the synthesis backend so the app compiles before the
/// Kokoro integration lands and stays testable after.
protocol TTSEngine: Sendable {
    var sampleRate: Double { get }
    /// Available voice identifiers (e.g. "af_heart").
    var voices: [String] { get }
    /// Synthesize one sentence to mono Float32 samples at `sampleRate`.
    func synthesize(text: String, voice: String) async throws -> [Float]
}
