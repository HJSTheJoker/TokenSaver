# TokenSaver

TokenSaver is a Codex-first savings dashboard for local distill workflows.
It reads compact local telemetry from your existing `safe-distill` flow and shows
how much prompt load the distill path is likely saving the larger coding model.

TokenSaver is:
- compatible with your current `safe-distill` setup
- additive and opt-in
- local-first
- not a replacement for CodexBar
- not a general quota tracker in v1

## What ships in v1

- `tokensaver` CLI
- backup-first installer for `safe-distill`
- macOS menu bar app
- WidgetKit widget
- compact JSONL event schema stored under `~/.codex/tokensaver/events/`

## Quick start

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

## Design notes

- Token savings are **estimated** in v1 and labeled that way in the UI.
- No raw stdin, raw logs, or prompt text are persisted.
- The installer patches `safe-distill` minimally and reversibly.
- The app is inspired by CodexBar’s native menu-bar feel and widget pipeline, but it is a smaller, narrower product.

## Docs

- [Architecture](docs/architecture.md)
- [Privacy](docs/privacy.md)
- [Event schema](docs/event-schema.md)
- [UI](docs/ui.md)

## License

MIT
