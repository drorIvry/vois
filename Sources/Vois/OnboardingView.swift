import ApplicationServices
import KeyboardShortcuts
import SwiftUI

/// First-launch card flow (PRD §6 F9): welcome → Accessibility permission →
/// hotkey setup → try-it-yourself demo → done.
struct OnboardingView: View {
    @ObservedObject var controller: SpeechController
    let onFinish: () -> Void

    @State private var step = 0
    @State private var axTrusted = AXIsProcessTrusted()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            controls
        }
        .padding(32)
        .frame(width: 520, height: 560)
        .onReceive(timer) { _ in axTrusted = AXIsProcessTrusted() }
    }

    @ViewBuilder
    private var card: some View {
        switch step {
        case 0: welcome
        case 1: permission
        case 2: hotkey
        default: demo
        }
    }

    private var welcome: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Welcome to Vois").font(.largeTitle.bold())
            Text("Select text in any app, press a shortcut, and hear it read aloud by a natural voice — entirely on your Mac. No account, no cloud, nothing leaves this machine.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var permission: some View {
        VStack(spacing: 16) {
            Image(systemName: axTrusted ? "checkmark.shield.fill" : "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundStyle(axTrusted ? .green : .orange)
            Text("Accessibility Permission").font(.title.bold())
            Text("Vois needs Accessibility access to read the text you select in other apps. macOS will ask once; you can change this anytime in System Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if axTrusted {
                Label("Permission granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                VStack(spacing: 10) {
                    Button("Grant Access") {
                        let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
                        AXIsProcessTrustedWithOptions(opts)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Open System Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                    }
                    Text("System Settings → Privacy & Security → Accessibility → enable Vois")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var hotkey: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Your Shortcut").font(.title.bold())
            Text("Press this shortcut with text selected to hear it. Press again to stop. You can change it now or later in Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            KeyboardShortcuts.Recorder("Speak selection:", name: .speakSelection)
        }
    }

    private var demo: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.badge.checkmark")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Try It Yourself").font(.title.bold())
            Text(Self.demoText)
                .padding(14)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                .textSelection(.enabled)
            Text("Select the paragraph above and press your shortcut — or tap the button.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Button("Read It To Me") {
                controller.speak(text: Self.demoText)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var controls: some View {
        HStack {
            if step > 0 {
                Button("Back") { step -= 1 }
            }
            Spacer()
            if step < 3 {
                Button(step == 1 && !axTrusted ? "Skip for Now" : "Continue") { step += 1 }
                    .buttonStyle(.borderedProminent)
            } else {
                Button("Done") { onFinish() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    static let demoText = "This is Vois reading to you. Every word is generated right here on your Mac, with no internet connection at all. Select any text, anywhere, and press your shortcut to listen."
}
