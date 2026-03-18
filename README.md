# TokenSaver

TokenSaver is a Codex-first savings dashboard for local distill workflows.
It reads compact local telemetry from both raw `distill` and `safe-distill` flows and shows
how much prompt load those paths are likely saving the larger coding model.

TokenSaver is:
- compatible with your current `distill` and `safe-distill` setup
- additive and opt-in
- local-first
- not a replacement for CodexBar
- not a general quota tracker in v1

## What ships in v1

- `tokensaver` CLI
- backup-first installer for `distill` and `safe-distill`
- macOS menu bar app
- WidgetKit widget
- compact JSONL event schema stored under `~/.codex/tokensaver/events/`

## Quick start

Download the packaged app:

- go to the GitHub `v0.1.0` release and download `TokenSaver-v0.1.0-macos-arm64.zip`
- unzip `TokenSaver.app`
- drag `TokenSaver.app` into `/Applications`
- launch it from Applications or Spotlight
- if macOS blocks the first launch because the app is unsigned, Control-click the app in Finder and choose `Open` once

For local packaging from source:

```bash
cd /Users/harrysmith/TokenSaver
./Scripts/package_app.sh v0.1.0
```

This creates:

- `dist/TokenSaver.app`
- `dist/TokenSaver-v0.1.0-macos-arm64.zip`
- `dist/TokenSaver-v0.1.0-macos-arm64.zip.sha256`

Build from source:

```bash
cd /Users/harrysmith/TokenSaver
swift build
swift test
```

Run the CLI:

```bash
.build/debug/tokensaver summary
.build/debug/tokensaver doctor
```

Opt-in integration with the existing setup:

```bash
.build/debug/tokensaver install
```

This creates a timestamped backup before changing any live files.

Run the menu bar app from a development build:

```bash
.build/debug/TokenSaverApp
```

That executable path is for development only. The packaged `.app` in `/Applications` is the preferred end-user launch path.

## Design notes

- Token savings are **estimated** in v1 and labeled that way in the UI.
- The headline number is **big-model savings**: raw command output minus the final distilled summary size.
- `safe-distill` also reports how much input it trimmed before the tiny local model sees it.
- No raw stdin, raw logs, or prompt text are persisted.
- The installer patches both `distill` and `safe-distill` minimally and reversibly.
- The app is inspired by CodexBar’s native menu-bar feel and widget pipeline, but it is a smaller, narrower product.

## Docs

- [Architecture](docs/architecture.md)
- [Privacy](docs/privacy.md)
- [Event schema](docs/event-schema.md)
- [UI](docs/ui.md)

## License

MIT
