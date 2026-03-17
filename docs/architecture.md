# Architecture

## Modules

- `TokenSaverCore`: event schema, scanning, aggregation, widget snapshot models.
- `TokenSaverInstaller`: backup manifest generation, patching, uninstall flow.
- `TokenSaverCLI`: summary, doctor, install, uninstall, and tail commands.
- `TokenSaverApp`: native macOS menu bar app.
- `TokenSaverWidget`: widget surface backed by a shared snapshot file.

## Data flow

1. `safe-distill` emits compact JSONL events to `~/.codex/tokensaver/events/YYYY/MM/DD.jsonl`.
2. `TokenSaverCore` scans those events and builds a rolled-up summary.
3. The CLI prints the summary directly.
4. The app reads the summary and writes a widget snapshot.
5. The widget reads the shared snapshot.

## Product boundaries

- TokenSaver is additive to the existing `safe-distill` path.
- TokenSaver does not replace `safe-distill`.
- V1 does not include a database, billing reconciliation, or web scraping.
