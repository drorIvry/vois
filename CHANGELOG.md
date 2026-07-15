# Changelog

All notable changes to Vois are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[SemVer](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-07-15

Initial release.

### Added
- Global-hotkey select-to-speak with tiered text capture (AX API → menu Copy
  → simulated ⌘C with clipboard save/restore) via SelectedTextKit
- Fully offline Kokoro-82M synthesis on MLX Swift (bf16 weights, bundled,
  zero runtime network); MisakiSwift phonemization — no GPL dependencies
- Sentence-streamed playback: first audio ~0.1s warm, synthesize-ahead
- Floating non-activating playback bar: pause/resume, ±sentence skip,
  0.5×–3× pitch-preserving speed, draggable with position persistence,
  auto-fade after playback
- Menu-bar app (no dock icon) with voice picker, speed, settings
- Settings: rebindable shortcuts (recorder UI), 11 English voices with
  preview, playback behavior
- Onboarding: Accessibility permission flow with live status + remediation,
  shortcut setup, try-it demo
- Text preprocessing: sentence splitting, URL/markdown stripping,
  abbreviation expansion
- `--spike` (TTFA benchmark) and `--say` (captureless speak) debug flags

[Unreleased]: https://github.com/drorIvry/vois/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/drorIvry/vois/releases/tag/v1.0.0
