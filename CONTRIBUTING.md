# Contributing to Vois

Thanks for your interest in contributing! Vois is a local-first select-to-speak
utility for macOS, and contributions of all kinds are welcome — bug reports,
capture-compatibility fixes for specific apps, docs, and features.

## Getting set up

Requirements: macOS 15+, Apple Silicon, Xcode 26+.

```bash
git clone https://github.com/drorIvry/vois.git
cd vois

# One-time: Metal toolchain for MLX shader compilation
xcodebuild -downloadComponent MetalToolchain

# Fetch Kokoro weights (~340MB download, converted to bf16)
scripts/fetch-model.sh

# Build the app bundle
scripts/bundle.sh Release
open dist/Vois.app
```

> **Note:** plain `swift build` cannot compile MLX's Metal shaders —
> always build through `scripts/bundle.sh` (which uses `xcodebuild`).

## Running tests

```bash
swift test          # unit tests (text preprocessing)
dist/Vois.app/Contents/MacOS/Vois --spike   # TTS smoke test + latency check
dist/Vois.app/Contents/MacOS/Vois --say "Hello"  # full loop minus capture
```

Before opening a PR, also run through the manual test checklist in the README
for anything your change touches — most of Vois's surface (capture,
permissions, the floating bar) can only be verified by hand.

## Pull requests

- Keep PRs focused; one change per PR.
- Describe *why*, not just *what*.
- New capture quirks/workarounds for specific apps: include the app name and
  version, and which fallback tier ends up handling it.
- CI must pass (build + unit tests).

## Reporting bugs

Use the bug report issue template. For capture failures, always include:
the app you selected text in, macOS version, and whether Accessibility
permission is granted (System Settings → Privacy & Security → Accessibility).

## Code style

Match the surrounding code. SwiftUI for UI, actors for engine-side state,
no new dependencies without discussion (the licensing bar is strict:
nothing GPL — see PRD §9, espeak-ng is explicitly off-limits).

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
