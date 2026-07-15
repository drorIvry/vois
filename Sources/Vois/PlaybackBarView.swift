import SwiftUI

/// Compact pill that expands on hover to show transport controls (PRD §7).
struct PlaybackBarView: View {
    @ObservedObject var controller: SpeechController
    @ObservedObject var settings = AppSettings.shared
    @State private var hovering = false

    var body: some View {
        Group {
            if hovering {
                expanded
            } else {
                compact
            }
        }
        .padding(.horizontal, hovering ? 12 : 16)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.quaternary))
        .onHover { hovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: hovering)
        .fixedSize()
    }

    private var compact: some View {
        HStack(spacing: 8) {
            statusIcon
            if controller.player.sentenceCount > 0 {
                Text("\(min(controller.player.currentSentence + 1, controller.player.sentenceCount))/\(controller.player.sentenceCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var expanded: some View {
        HStack(spacing: 10) {
            Button(action: { controller.player.skipBackward() }) {
                Image(systemName: "backward.frame.fill")
            }
            Button(action: { controller.player.togglePause() }) {
                Image(systemName: controller.player.state == .paused ? "play.fill" : "pause.fill")
                    .frame(width: 16)
            }
            Button(action: { controller.player.skipForward() }) {
                Image(systemName: "forward.frame.fill")
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 70)

            Menu {
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0], id: \.self) { s in
                    Button("\(s, format: .number)×") {
                        settings.speed = s
                        controller.player.rate = Float(s)
                    }
                }
            } label: {
                Text("\(settings.speed, format: .number)×")
                    .font(.caption.monospacedDigit())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Button(action: { controller.stop() }) {
                Image(systemName: "xmark")
            }
        }
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch controller.phase {
        case .capturing:
            Image(systemName: "text.cursor")
        case .synthesizing:
            ProgressView().controlSize(.small)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
        default:
            Image(systemName: controller.player.state == .paused ? "pause.fill" : "waveform")
                .symbolEffect(.variableColor.iterative, isActive: controller.player.state == .playing)
        }
    }

    private var progress: Double {
        let total = controller.player.sentenceCount
        guard total > 0 else { return 0 }
        return Double(controller.player.currentSentence) / Double(total)
    }
}
