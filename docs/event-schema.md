# Event Schema

Events are written as JSONL records to:

- `~/.codex/tokensaver/events/YYYY/MM/DD.jsonl`

## Fields

- `schema_version`
- `timestamp`
- `tool`
- `provider`
- `source`
- `status`
- `model`
- `raw_input_bytes`
- `small_model_input_bytes`
- `summary_output_bytes`
- `raw_lines`
- `estimated_raw_input_tokens`
- `estimated_small_model_input_tokens`
- `estimated_summary_output_tokens`
- `estimated_big_model_tokens_saved`
- `estimated_small_model_input_reduction`
- `duration_ms`
- `guard_blocked`
- `blocker_category`

## Notes

- Savings are estimates in v1.
- The headline number is big-model savings.
- `safe-distill` also records small-model input reduction as a secondary metric.
- Schema is append-only and versioned.
- Unknown fields should be ignored by readers.
