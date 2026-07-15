import ServiceManagement
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
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

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

        Toggle("Start at Login", isOn: $launchAtLogin)
            .onChange(of: launchAtLogin) { _, enable in
                do {
                    enable ? try SMAppService.mainApp.register()
                           : try SMAppService.mainApp.unregister()
                } catch {
                    NSLog("Vois: launch-at-login change failed: %@", String(describing: error))
                    launchAtLogin = SMAppService.mainApp.status == .enabled
                }
            }

        SettingsLink { Text("Settings…") }
            .keyboardShortcut(",")

        Button("Quit Vois") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
