# Privacy

TokenSaver is local-first.

## Stored

- timestamp
- run status
- model name
- raw input bytes, small-model input bytes, and summary output bytes
- raw line counts
- estimated token counts
- estimated big-model savings
- estimated small-model input reduction
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

It backs up both raw `distill` and `safe-distill` entrypoints before patching them.
