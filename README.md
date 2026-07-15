# Vois

Local-first select-to-speak for macOS. Select text in any app, press a global shortcut, and a fully offline Kokoro voice reads it aloud. No network, no accounts, no telemetry.

- **Requires:** macOS 15+, Apple Silicon, Xcode 26 (with Metal Toolchain: `xcodebuild -downloadComponent MetalToolchain`).
- **Engine:** Kokoro-82M via MLX Swift ([kokoro-ios](https://github.com/mlalma/kokoro-ios), MIT) with [MisakiSwift](https://github.com/mlalma/MisakiSwift) phonemization (Apache-2.0 — no GPL espeak-ng anywhere in the tree).
- **Default shortcut:** ⌥S speaks the selection / stops or replaces during playback (rebindable). Esc also stops.

## Build

```bash
# 1. Fetch model weights + voices into Models/Kokoro (one-time, ~350MB download,
#    converted to bf16 → 164MB bundled). Build-time only; the app never touches the network.
scripts/fetch-model.sh

# 2. Build and bundle Vois.app (uses xcodebuild — plain `swift build` cannot
#    compile MLX's Metal shaders)
scripts/bundle.sh Release

# 3. Run
open dist/Vois.app
```

First launch walks through onboarding: grant Accessibility permission (needed to read your selection), pick a shortcut, try the demo. For distribution, replace the ad-hoc codesign in `scripts/bundle.sh` with your Developer ID and notarize.

### Debug flags

```bash
dist/Vois.app/Contents/MacOS/Vois --spike        # measure time-to-first-audio, exit
dist/Vois.app/Contents/MacOS/Vois --say "text"   # exercise synth → bar → playback without capture
```

### Measured on M-series (Release, bf16 weights)

| Metric | PRD target | Measured |
|---|---|---|
| Warm TTFA p50 | < 1s | **0.12s** |
| Cold TTFA (load + first synth) | — | 0.4–1.3s (hidden by launch warm-up) |
| Idle RSS, warm model | < 400MB | **~355MB** |
| Idle CPU | ~0% | 0.0% |

`swift test` runs the text-preprocessor unit tests (the TTS path needs the app bundle, hence `--spike`).

## Manual test checklist

Capture-fallback matrix — select a paragraph, press ⌥S, expect speech in ~1s:

| App | Capture path exercised | Pass |
|---|---|---|
| Safari (web page) | AX API | ☐ |
| Notes | AX API | ☐ |
| Slack (Electron) | menu-Copy / Cmd+C fallback | ☐ |
| VS Code (Electron) | menu-Copy / Cmd+C fallback | ☐ |
| Terminal | AX / Cmd+C | ☐ |
| Preview (PDF) | Cmd+C fallback | ☐ |

Core behaviors:

- ☐ No selection + shortcut → "No text selected" error pill, fades out.
- ☐ Playback bar appears docked bottom-center; drag it; quit + relaunch → position remembered.
- ☐ Hover bar → expands: play/pause, ±sentence skip, speed menu, progress, close all work.
- ☐ Speed change mid-playback keeps pitch.
- ☐ Esc stops playback. ⌥S with the same selection stops; with a new selection replaces playback.
- ☐ "New selection replaces playback" off (Settings → Playback) → ⌥S during playback always stops.
- ☐ Bar fades ~2s after playback ends (unless auto-hide disabled).
- ☐ Clipboard contents intact after capturing from an Electron app (Cmd+C fallback path).
- ☐ Menu bar: pause/resume, stop, voice picker, speed, Settings, Quit.
- ☐ Settings → Voice → Preview speaks with the selected voice.
- ☐ Onboarding completes < 3 min on a fresh machine; "Open System Settings" lands on Privacy & Security → Accessibility; status flips live when granted.
- ☐ Activity Monitor: ~0% CPU idle; < 400MB RAM with warm model.
- ☐ No network connections at any point (Little Snitch / `nettop -p Vois`).

## Notes

- Weights are cast to bf16 at fetch time (halves size and RSS; audio RMS verified sane by `--spike`).
- The playback bar is a non-activating `NSPanel` — it never steals focus from the app you're reading.
- Licensing: Kokoro-82M Apache-2.0 · kokoro-ios MIT · MisakiSwift Apache-2.0 · SelectedTextKit MIT · KeyboardShortcuts MIT · MLX Swift MIT. No espeak-ng (GPL) linked.
