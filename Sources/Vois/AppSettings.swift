import Foundation
import SwiftUI

/// User preferences, UserDefaults-backed.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    nonisolated static let defaultVoice = "af_heart"

    @AppStorage("voice") var voice: String = AppSettings.defaultVoice
    @AppStorage("speed") var speed: Double = 1.0
    @AppStorage("barAutoHide") var barAutoHide: Bool = true
    @AppStorage("replaceOnNewSelection") var replaceOnNewSelection: Bool = true
    @AppStorage("onboardingDone") var onboardingDone: Bool = false
    // Playback bar position, persisted as "x,y" of the panel origin. Empty = default dock.
    @AppStorage("barOrigin") var barOrigin: String = ""

    private init() {}
}
