# Vois — Research & PRD

**Product:** Local-first "reverse Wispr Flow" — select text anywhere on screen, hit a global hotkey, a fully offline AI voice reads it aloud.

**Research date:** 2026-07-15. Produced by a deep-research pass: 5 search angles, 23 sources fetched, 115 claims extracted, 25 adversarially verified (24 confirmed, 1 refuted). Confidence labels below reflect verification votes.

---

## 1. Concept validation (TL;DR)

The concept is validated by research:

- **The interaction pattern already works.** Wispr Flow itself ships a "Transforms" feature — highlight any text, press a shortcut (Opt+1/Opt+2), AI acts on it. Same gesture, different action. Core UX bet is de-risked. *(verified 3-0)*
- **The engine exists and is production-proven.** Kokoro (82M params, Apache 2.0, ~315MB) runs faster than real-time on Apple Silicon, fully offline, in pure Swift via MLX — proven by two shipping macOS apps (open-source KokoroTTS, commercial Kokori). *(verified 6-0)*
- **The market gap is real but narrow.** Kokori (commercial) has offline Kokoro TTS but only a desktop UI + localhost REST API — no global select-to-speak hotkey flow. KokoroTTS (open-source, 28 stars) has select-to-speak via macOS Services but is a hobby project with no polish. The gap is **UX polish**, not raw capability. *(verified 6-0)*
- **The technical path is mapped.** Selected-text capture, global hotkeys, and permissions all have off-the-shelf, battle-tested solutions (SelectedTextKit, KeyboardShortcuts, same Accessibility permission model Wispr Flow uses).

---

## 2. Wispr Flow UX teardown (the template to mirror)

All findings below verified against official Wispr Flow docs/changelog as of 2026-07-15.

### 2.1 Hotkey model *(verified 12-0)*
- **Two modes:** push-to-talk (hold key → speak → release → text inserted) and hands-free (double-tap the shortcut, or a dedicated shortcut, to toggle).
- **Defaults:** macOS — `Fn` on Apple keyboards (`Ctrl+Opt` fallback on non-Apple keyboards), `Fn+Space` for hands-free. Windows — `Ctrl+Win` and `Ctrl+Win+Space`.
- **Reverse mapping for Vois:** **hold-to-read** (hold key → reads selection, release → stop) and **toggle-to-read** (tap to start, tap to stop).

### 2.2 Hotkey customization *(verified 6-0)*
- Up to 4 shortcuts per action, max 3 keys per combination.
- Non-primary mouse buttons (middle click, Mouse 4–10) usable standalone or with modifiers.
- Escape (cancel) and Enter fully rebindable via Settings > Shortcuts.

### 2.3 Onboarding *(verified 9-0)*
~5-minute guided card-by-card sequence: install → sign-in → grant permissions → test → set shortcut → language → "Try It Yourself" demo → privacy preferences. Remediation paths shown for denied permissions (System Settings > Privacy & Security > Accessibility).

**Key insight:** Wispr Flow needs macOS Accessibility (TCC) permission to insert text into other apps. Vois needs the *exact same permission* to read selected text (AXSelectedText / simulated Cmd+C). Onboarding is structurally identical, minus the microphone step. One permission, not two.

### 2.4 Flow Bar widget *(verified 3-0)*
Persistent draggable floating widget, dockable to left/right/bottom screen edges, position persisted across sessions, hover-revealed controls, can be disabled in settings. Direct template for Vois's floating playback bar.

---

## 3. Competitive landscape

| Product | Offline | Select-to-speak hotkey | Quality | Gap |
|---|---|---|---|---|
| **Kokori** (commercial, kokori.app) | ✅ fully offline, Kokoro | ❌ desktop UI + localhost:3000 REST API only | 50+ voices, speed control | No global hotkey flow *(verified 6-0)* |
| **KokoroTTS** (OSS, kjyv/KokoroTTS) | ✅ Swift+MLX, no Python | ⚠️ macOS Services + Cmd+Shift+P | Kokoro, faster-than-real-time on Apple Silicon | Hobby project (28★), Services broken in Electron apps *(verified 6-0)* |
| **macOS Spoken Content** | ✅ | ⚠️ built-in Option+Esc | Siri voices | Not researched-verified; anecdotally clunky, limited controls |
| **Speechify / NaturalReader** | ❌ mostly cloud | partial | high (cloud) | Not local; no claims survived verification |

**Positioning:** Vois = Kokoro-quality offline voice + Wispr-Flow-grade hotkey UX. Nobody ships both.

> Caveat: no claims about Speechify/NaturalReader/Spoken Content survived verification — competitor rows for those are directional, not research-backed.

## 4. TTS engine selection

**Decision: Kokoro-82M** (hexgrad, Apache 2.0, StyleTTS2 + iSTFTNet, ~315MB).

Evidence basis — shipping products, not benchmarks:
- KokoroTTS app: 100% Swift via MLX, no Python runtime, faster-than-real-time synthesis on Apple Silicon, macOS 15+. *(verified 3-0)*
- Corroborating self-reported numbers: ~3.3× real-time on iPhone 13 Pro (kokoro-ios/MLX), 14× real-time on M1 Mini (CoreML port).
- Kokori ships it commercially, fully offline, 50+ voices.

**Honest limits of the research** *(important)*:
- The only quantitative model-ranking claim (CodeSOTA blind Elo 1424 for Kokoro) was **refuted 0-3**. Do not claim "best-in-class" — claim "production-proven on target hardware."
- No verified comparative claims survived for Piper, XTTS-v2, F5-TTS, Parler, MeloTTS, or Apple's AVSpeechSynthesizer. Engine choice rests on shipping-product evidence.
- "Faster than real-time" figures are throughput, not time-to-first-audio.

**Open licensing question (must resolve pre-ship):** Kokoro's default phonemizer chain uses espeak-ng (**GPL-3.0**). For a closed-source commercial app use Misaki/MisakiSwift alternatives. Verify voice-pack redistribution rights.

**Fallback/alternative worth benchmarking in-house:** Piper (very fast, lower quality), Apple AVSpeechSynthesizer (zero-install fallback voice, instant start while Kokoro warms up).

## 5. Technical architecture

### 5.1 Selected-text capture — tiered fallback (macOS) *(verified 9-0)*
Single API is NOT enough. Accessibility API (`kAXSelectedTextAttribute`) is per-app opt-in and broken in Chromium/Electron apps (documented in electron/electron#36337). Required cascade:

1. **Accessibility API** (`AXSelectedText`) — primary.
2. **Simulated Cmd+C** — save clipboard → mute alert sound → synthesize Cmd+C → read → restore clipboard.
3. **Menu-bar Copy action** fallback.
4. **AppleScript** for Safari/Chrome/Firefox.

**Off-the-shelf:** [SelectedTextKit](https://github.com/tisfeng/SelectedTextKit) (MIT, Swift 5.7+, macOS 11+, v2.6.4 Feb 2026, extracted from shipping Easydict app) implements exactly this cascade with an `.auto` strategy, including per-app method caching. Use it. *(verified 9-0)*

macOS **Services** menu (KokoroTTS's approach) is a supplement only — broken/empty in Electron apps, and its shortcut is a Services binding, not an app hotkey. *(verified 2-1 — the one medium-confidence finding)*

### 5.2 Windows/Linux (future) *(verified 9-0)*
[get-selected-text](https://github.com/yetone/get-selected-text) (Rust, MIT/Apache-2.0) pattern: Windows/Linux use only simulated Ctrl+C + clipboard save/restore (enigo/arboard). No reliable universal accessibility path there. Caveats: unmaintained since May 2024; weak on Wayland; Windows UI Automation TextPattern is a plausible stronger alternative (unverified).

### 5.3 Global hotkeys *(verified 6-0)*
[sindresorhus/KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) (v3.0.1 Jun 2026, used by shipping MAS apps): user-customizable global shortcuts via Carbon `RegisterEventHotKey` — sandboxed, Mac App Store compatible, no Accessibility permission needed *for the hotkey itself*. Ships `KeyboardShortcuts.Recorder` UI (SwiftUI + AppKit) with UserDefaults persistence and system-conflict warnings. Known issues: media keys unsupported sandboxed; macOS 15 regression for Option-only-modifier shortcuts in sandboxed apps.

### 5.4 Distribution decision
**Direct distribution (notarized, non-MAS) is the default.** Hotkeys are sandbox-safe, but AX-based text reading requires the non-sandboxable Accessibility permission. MAS build would have to lean solely on clipboard/Services capture — degraded. Ship direct; revisit MAS later.

### 5.5 Synthesis pipeline
- Swift + MLX (KokoroTTS proves no Python runtime needed), macOS 15+, Apple Silicon first.
- **Sentence-chunked streaming:** split selection into sentences, synthesize sentence 1 → start playback immediately → synthesize ahead in background. Target time-to-first-audio < 1s (design target — no verified latency benchmarks exist for this; measure in-house).
- Optional instant-start: play first sentence via AVSpeechSynthesizer while Kokoro spins up, or accept warm-model residency (~315MB + runtime memory).
- Playback: AVAudioEngine — pause/resume, speed 0.5×–3× (time-stretch, pitch-preserving), skip ±sentence.

## 6. Feature list

### MVP (v1.0 — macOS, English)
| # | Feature | Notes |
|---|---|---|
| F1 | Global hotkey → speak selection | Default: `Fn+S` tap-to-toggle + hold-to-read variant (mirrors Wispr push-to-talk/hands-free) |
| F2 | Tiered text capture | SelectedTextKit cascade (AX → Cmd+C → menu → AppleScript) |
| F3 | Local Kokoro synthesis | Bundled model, zero network, Swift+MLX |
| F4 | Sentence-streamed playback | First audio < 1s target; synthesize-ahead |
| F5 | Floating playback bar | Flow-Bar style: draggable, edge-dockable, position persisted, hover controls; play/pause, speed, skip ±sentence, progress, close; disable-able |
| F6 | Speed control | 0.5×–3×, persisted |
| F7 | Voice picker | Kokoro's bundled English voices |
| F8 | Hotkey customization | Recorder UI, up to 4 shortcuts/action, ≤3 keys, mouse buttons Mouse4-10, rebindable Escape=stop |
| F9 | Onboarding | ~3-min card flow: welcome → Accessibility permission (with remediation) → set hotkey → "Try it yourself" demo text → done. No account, no sign-in |
| F10 | Menu bar app | No dock icon by default; menu: pause/resume, voice, speed, settings, quit |
| F11 | Escape / re-press stops | Re-press hotkey during playback = stop (or restart with new selection) |
| F12 | Text preprocessing | Strip URLs/markdown noise, expand common abbreviations, sentence splitting |

### v1.x
- Read-from-cursor / read whole visible page (no selection → speak clipboard as fallback, opt-in)
- Highlight-follow: show current sentence in a small overlay
- Queue: new selection while playing → append or replace (setting)
- Per-app capture-method cache + per-app disable list
- Additional Kokoro voices / community voice packs
- LLM pre-pass (local, optional): summarize-then-read "TL;DR mode" for walls of text

### v2+
- Windows (Ctrl+C simulation capture, UI Automation investigation)
- More languages (Kokoro multilingual voices)
- Voice cloning engine upgrade path (XTTS/F5-TTS — needs in-house benchmarking)
- Export selection to audio file

### Explicit non-goals (v1)
- No cloud anything. No accounts. No telemetry beyond opt-in crash reports.
- No PDF/ebook library UI (Speechify territory) — Vois is a utility, not a reader app.
- No dictation (that's Wispr Flow).
- No Mac App Store (sandbox conflict, §5.4).

## 7. UX spec (mirror of Wispr Flow)

**Happy path:** select text anywhere → tap hotkey → *ding + bar appears docked at screen edge* → speech starts < 1s → tap hotkey again (or Esc) to stop → bar fades after 2s idle.

**Playback bar** (Flow Bar mirror): compact pill, docked left/right/bottom edge, draggable, remembers position. Idle = thin sliver; hover = expands to show ⏯ / speed / ±sentence skip / progress / ✕. Never steals focus (non-activating panel).

**States:** capturing (brief pulse) → synthesizing (subtle spinner if > 300ms) → playing (waveform/progress) → paused → error ("Couldn't grab selection — try Cmd+C first", with per-app help link).

**Settings tabs:** Shortcuts (recorder UI) · Voice (picker + preview + speed default) · Playback (bar position, auto-hide, queue behavior) · Apps (per-app overrides) · About.

## 8. Success metrics
- Time-to-first-audio p50 < 1s, p95 < 2.5s (M-series, warm model).
- Capture success rate > 98% across top 20 target apps (browsers, Slack, Mail, VS Code, PDF readers, Terminal).
- Onboarding completion < 3 min; permission-grant rate > 90%.
- Idle footprint: < 400MB RAM (warm model), ~0% CPU.

## 9. Risks & open questions
| Risk | Severity | Mitigation |
|---|---|---|
| espeak-ng GPL-3.0 in phonemizer chain | High (commercial blocker) | Use Misaki/MisakiSwift; audit voice-pack licenses |
| Kokoro time-to-first-audio unmeasured (throughput ≠ latency) | Medium | Prototype week 1; AVSpeech instant-start fallback |
| Electron/Chromium capture failures | Medium | Cmd+C fallback tier; per-app cache; tested app matrix |
| No verified benchmarks vs Piper/F5/XTTS | Low for MVP | Ship Kokoro (production-proven); benchmark in-house for v2 |
| Intel/8GB Mac performance unknown | Medium | Apple Silicon + macOS 15+ requirement for v1 |
| get-selected-text unmaintained; Wayland weak | Low (v2 concern) | Own Rust port or UI Automation for Windows |

**Open questions from research (unresolved, need in-house work):**
1. Kokoro true streaming vs sentence-chunked only; real TTFA numbers.
2. Kokoro vs Piper vs AVSpeechSynthesizer blind listening on target hardware.
3. Actual gaps of macOS Spoken Content / Speechify (no claims survived verification).
4. Windows UI Automation TextPattern viability vs clipboard clobbering.

## 10. Sources (key, verified)
**Primary:** docs.wisprflow.ai (setup guide, hotkey docs, hands-free, Transforms), wisprflow.ai/whats-new, github.com/kjyv/KokoroTTS, kokori.app + /docs, github.com/tisfeng/SelectedTextKit, github.com/yetone/get-selected-text, github.com/sindresorhus/KeyboardShortcuts, electron/electron#36337 & #7260.

**Refuted (do not cite):** codesota.com/guides/tts-models Elo ranking (0-3 refuted).

**Secondary (directional only):** inferless.com, modal.com/blog/open-source-tts, localaimaster.com, gigagpu.com, picovoice.ai latency blog, contracollective.com Kokoro-vs-Piper-vs-XTTS.
