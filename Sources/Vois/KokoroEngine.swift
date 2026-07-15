import Foundation
import KokoroSwift
import MLX

enum VoisError: LocalizedError {
    case modelMissing
    case voiceMissing(String)

    var errorDescription: String? {
        switch self {
        case .modelMissing:
            return "Kokoro model not found. Run scripts/fetch-model.sh, or reinstall Vois."
        case .voiceMissing(let id):
            return "Voice \(id) not found in voice pack."
        }
    }
}

/// Kokoro-82M via MLX Swift (kokoro-ios + MisakiSwift — no espeak-ng, PRD §9).
/// Actor: serializes synthesis and keeps the model resident after first load.
actor KokoroEngine: TTSEngine {
    nonisolated let sampleRate: Double = 24_000
    nonisolated var voices: [String] { KokoroVoices.all.map(\.id) }

    private var tts: KokoroTTS?
    private var voiceCache: [String: MLXArray] = [:]

    /// Load the model off the critical path so the first hotkey press is fast.
    func warmUp() {
        try? load()
        // First synthesis compiles MLX kernels; do it now with a throwaway phrase.
        _ = try? synthesizeSync(text: "Ready.", voice: AppSettings.defaultVoice)
    }

    func synthesize(text: String, voice: String) async throws -> [Float] {
        try synthesizeSync(text: text, voice: voice)
    }

    private func synthesizeSync(text: String, voice: String) throws -> [Float] {
        try load()
        guard let tts else { throw VoisError.modelMissing }
        let style = try voiceEmbedding(voice)
        let language: Language = voice.hasPrefix("b") ? .enGB : .enUS
        let (samples, _) = try tts.generateAudio(voice: style, language: language, text: text, speed: 1.0)
        return samples
    }

    private func voiceEmbedding(_ voice: String) throws -> MLXArray {
        if let cached = voiceCache[voice] { return cached }
        let url = try Self.modelDirectory().appendingPathComponent("voices/\(voice).safetensors")
        guard FileManager.default.fileExists(atPath: url.path),
              let embedding = try MLX.loadArrays(url: url)["voice"] else {
            throw VoisError.voiceMissing(voice)
        }
        voiceCache[voice] = embedding
        return embedding
    }

    private func load() throws {
        guard tts == nil else { return }
        // Cap MLX's GPU buffer cache; otherwise idle RSS balloons past the
        // 400MB PRD target after a few syntheses.
        MLX.GPU.set(cacheLimit: 32 * 1024 * 1024)
        let modelURL = try Self.modelDirectory().appendingPathComponent("kokoro-v1_0.safetensors")
        // KokoroTTS force-unwraps weight loading internally; verify the file first.
        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            throw VoisError.modelMissing
        }
        tts = KokoroTTS(modelPath: modelURL, g2p: .misaki)
    }

    private static func modelDirectory() throws -> URL {
        // Bundled (Vois.app/Contents/Resources/Kokoro) — the shipping path.
        if let bundled = Bundle.main.resourceURL?.appendingPathComponent("Kokoro"),
           FileManager.default.fileExists(atPath: bundled.appendingPathComponent("kokoro-v1_0.safetensors").path) {
            return bundled
        }
        // Dev fallback: repo checkout (works regardless of cwd, e.g. under xcodebuild test).
        let repoRoot = URL(fileURLWithPath: #filePath)  // Sources/Vois/KokoroEngine.swift
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        for dev in [URL(fileURLWithPath: "Models/Kokoro", isDirectory: true),
                    repoRoot.appendingPathComponent("Models/Kokoro", isDirectory: true)] {
            if FileManager.default.fileExists(atPath: dev.appendingPathComponent("kokoro-v1_0.safetensors").path) {
                return dev
            }
        }
        throw VoisError.modelMissing
    }
}
