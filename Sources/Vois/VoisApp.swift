import SwiftUI

@main
struct VoisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Vois", systemImage: menuBarIcon) {
            MenuContent(controller: appDelegate.controller)
        }

        Settings {
            SettingsView(controller: appDelegate.controller)
        }
    }

    private var menuBarIcon: String { "waveform.circle" }
}

struct MenuContent: View {
    @ObservedObject var controller: SpeechController
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        Button(controller.player.state == .playing ? "Pause" : "Resume") {
            controller.player.togglePause()
        }
        .disabled(!controller.isActive)

        Button("Stop") { controller.stop() }
            .disabled(!controller.isActive)

        Divider()

        Picker("Voice", selection: $settings.voice) {
            ForEach(KokoroVoices.all, id: \.id) { v in
                Text(v.label).tag(v.id)
            }
        }

        Picker("Speed", selection: $settings.speed) {
            ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0], id: \.self) { s in
                Text("\(s, format: .number)×").tag(s)
            }
        }

        Divider()

        SettingsLink { Text("Settings…") }
            .keyboardShortcut(",")

        Button("Quit Vois") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
