import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @ObservedObject var controller: SpeechController

    var body: some View {
        TabView {
            ShortcutsTab()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
            VoiceTab(controller: controller)
                .tabItem { Label("Voice", systemImage: "person.wave.2") }
            PlaybackTab()
                .tabItem { Label("Playback", systemImage: "play.circle") }
            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 440)
        .fixedSize()
    }
}

private struct ShortcutsTab: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Speak selection:", name: .speakSelection)
            KeyboardShortcuts.Recorder("Stop playback:", name: .stopPlayback)
            Text("Tap the speak shortcut again during playback to stop.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }
}

private struct VoiceTab: View {
    @ObservedObject var controller: SpeechController
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        Form {
            Picker("Voice:", selection: $settings.voice) {
                ForEach(KokoroVoices.all, id: \.id) { v in
                    Text(v.label).tag(v.id)
                }
            }
            Button("Preview") {
                let name = KokoroVoices.label(for: settings.voice).split(separator: " ").first.map(String.init) ?? "your voice"
                controller.speak(text: "Hi, I'm \(name). This is how I sound.")
            }
            Picker("Default speed:", selection: $settings.speed) {
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0], id: \.self) { s in
                    Text("\(s, format: .number)×").tag(s)
                }
            }
        }
        .padding(20)
    }
}

private struct PlaybackTab: View {
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        Form {
            Toggle("Auto-hide bar after playback", isOn: $settings.barAutoHide)
            Toggle("New selection replaces current playback", isOn: $settings.replaceOnNewSelection)
            Button("Reset bar position") { settings.barOrigin = "" }
            Text("Drag the bar anywhere; its position is remembered.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }
}

private struct AboutTab: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Vois").font(.title2.bold())
            Text("Version 1.0")
                .foregroundStyle(.secondary)
            Text("Local-first text to speech. Select text anywhere, press your shortcut, listen. Everything runs on your Mac — no network, no accounts, no telemetry.")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(28)
    }
}
