import Foundation

/// Kokoro's bundled English voices (PRD §6 F7). IDs match the voice file names
/// in the Kokoro voice pack; labels are human-friendly.
enum KokoroVoices {
    struct Voice {
        let id: String
        let label: String
    }

    static let all: [Voice] = [
        .init(id: "af_heart", label: "Heart (US female)"),
        .init(id: "af_bella", label: "Bella (US female)"),
        .init(id: "af_nicole", label: "Nicole (US female)"),
        .init(id: "af_sarah", label: "Sarah (US female)"),
        .init(id: "af_sky", label: "Sky (US female)"),
        .init(id: "am_adam", label: "Adam (US male)"),
        .init(id: "am_michael", label: "Michael (US male)"),
        .init(id: "bf_emma", label: "Emma (UK female)"),
        .init(id: "bf_isabella", label: "Isabella (UK female)"),
        .init(id: "bm_george", label: "George (UK male)"),
        .init(id: "bm_lewis", label: "Lewis (UK male)"),
    ]

    static func label(for id: String) -> String {
        all.first { $0.id == id }?.label ?? id
    }
}
