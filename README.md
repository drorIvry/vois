# Vois 🎙️

> Select text anywhere. Press a key. Listen.

[![CI](https://github.com/drorIvry/vois/actions/workflows/ci.yml/badge.svg)](https://github.com/drorIvry/vois/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/drorIvry/vois?include_prereleases)](https://github.com/drorIvry/vois/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2015%2B%20(Apple%20Silicon)-blue)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-6.2-orange)](Package.swift)

**Vois** is a local-first select-to-speak utility for macOS. Select text in
*any* app, press a global shortcut, and a natural offline voice
([Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) running on
[MLX](https://github.com/ml-explore/mlx-swift)) reads it aloud.

**No network. No accounts. No telemetry.** Everything happens on your Mac.

## Features

- 🎯 **Works everywhere** — tiered capture cascade (Accessibility API → menu
  Copy → simulated ⌘C with clipboard restore) covers native apps, browsers,
  and Electron apps
- ⚡ **Fast** — first audio in ~0.1s with a warm model (measured p50)
- 🔒 **Fully offline** — bundled model, zero network access at runtime
- 🎛️ **Floating playback bar** — play/pause, ±sentence skip, 0.5×–3×
  pitch-preserving speed, draggable, never steals focus
- 🗣️ **11 English voices** (US + UK), preview in Settings
- ⌨️ **Rebindable shortcuts** — toggle to speak/stop, Esc stops
- 🧹 **Smart preprocessing** — strips URLs/markdown noise, sentence-streamed
  synthesis starts playback while the rest is still generating

## Install

**Download:** grab `Vois-*.zip` from [Releases](https://github.com/drorIvry/vois/releases),
unzip, move to Applications. CI builds are ad-hoc signed — right-click → Open
on first launch.

**Build from source:**

```bash
git clone https://github.com/drorIvry/vois.git && cd vois
xcodebuild -downloadComponent MetalToolchain   # one-time
scripts/fetch-model.sh                         # ~340MB download → 164MB bf16
scripts/bundle.sh Release
open dist/Vois.app
```

> `swift build` alone can't compile MLX's Metal shaders — `scripts/bundle.sh`
> drives `xcodebuild` and assembles the bundle (frameworks, resources, model).

First launch: onboarding walks you through the Accessibility permission
(required to read your selection), shortcut setup, and a demo.

### Requirements

macOS 15+, Apple Silicon. Building needs Xcode 26+.

## Usage

| Action | How |
|---|---|
| Speak selection | ⌥S (default; rebindable) |
| Stop | ⌥S again, or Esc |
| Replace with new selection | select new text, ⌥S while playing |
| Pause/resume, skip, speed | hover the floating bar |
| Voice / speed / behavior | menu-bar icon → Settings |

### Debug flags

```bash
dist/Vois.app/Contents/MacOS/Vois --spike        # TTFA benchmark, then exits
dist/Vois.app/Contents/MacOS/Vois --say "text"   # speak without capture
```

## Performance (measured, M-series)

| Metric | Target | Measured |
|---|---|---|
| Warm time-to-first-audio p50 | < 1s | **0.12s** |
| Idle RAM (model resident) | < 400MB | ~355MB |
| Idle CPU | ~0% | 0.0% |

## Architecture

Global hotkey ([KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts))
→ capture ([SelectedTextKit](https://github.com/tisfeng/SelectedTextKit))
→ preprocess (sentence split, noise strip)
→ synthesize ([kokoro-ios](https://github.com/mlalma/kokoro-ios) +
[MisakiSwift](https://github.com/mlalma/MisakiSwift) G2P, actor-isolated,
model stays warm)
→ stream into AVAudioEngine (time-pitch rate control)
→ non-activating NSPanel progress pill.

Licensing note: the whole chain is MIT/Apache-2.0 — **no GPL** (espeak-ng is
deliberately not used).

## Manual test checklist

<details>
<summary>Capture matrix + core behaviors (expand)</summary>

Capture — select a paragraph, press the shortcut, expect speech in ~1s:

| App | Capture path | Pass |
|---|---|---|
| Safari | AX API | ☐ |
| Notes | AX API | ☐ |
| Slack (Electron) | menu-Copy / ⌘C fallback | ☐ |
| VS Code (Electron) | menu-Copy / ⌘C fallback | ☐ |
| Terminal | AX / ⌘C | ☐ |
| Preview (PDF) | ⌘C fallback | ☐ |

Core:

- ☐ No selection + shortcut → "No text selected" pill, fades out
- ☐ Bar drag position survives relaunch
- ☐ Hover bar → controls work (pause, ±sentence, speed, close)
- ☐ Speed change mid-playback keeps pitch
- ☐ Esc stops; same-selection re-press stops; new selection replaces
- ☐ Clipboard intact after Electron-app capture
- ☐ Onboarding < 3 min, permission remediation works
- ☐ ~0% CPU idle, < 400MB RAM warm, zero network connections

</details>

## Contributing

PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). This project follows the
[Contributor Covenant](CODE_OF_CONDUCT.md). Security reports: [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) © 2026 Dror Ivry. Kokoro-82M model weights are Apache-2.0
(© hexgrad).
