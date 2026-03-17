# Privacy

TokenSaver is local-first.

## Stored

- timestamp
- run status
- model name
- bytes and line counts
- estimated token counts
- estimated savings
- run duration
- blocker category

## Not stored

- raw stdin or raw log text
- full question text
- full temporary log contents

## Backups

The installer creates a timestamped backup under:

- `~/.codex/backups/tokensaver-bootstrap/<timestamp>/`

before changing any live setup files.
