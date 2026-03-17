# Event Schema

Events are written as JSONL records to:

- `~/.codex/tokensaver/events/YYYY/MM/DD.jsonl`

## Fields

- `schema_version`
- `timestamp`
- `tool`
- `provider`
- `status`
- `model`
- `raw_bytes`
- `excerpt_bytes`
- `raw_lines`
- `estimated_raw_tokens`
- `estimated_excerpt_tokens`
- `estimated_tokens_saved`
- `duration_ms`
- `guard_blocked`
- `blocker_category`

## Notes

- Savings are estimates in v1.
- Schema is append-only and versioned.
- Unknown fields should be ignored by readers.
