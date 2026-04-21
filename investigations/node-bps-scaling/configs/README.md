# Candidate Tier Overrides

This directory holds first-pass candidate override files for the `node-bps-scaling` investigation.

These files are inputs to calibration, not final validated study artifacts.

## Strategy

The current strategy is intentionally conservative:

- override only the `blockrate` object
- keep the rest of devnet unchanged
- derive the blockrate fields from current upstream core formulas rather than from older illustrative examples

This matches the investigation goal of increasing BPS without making broad unrelated config changes.

## Why These Candidates Come From Core Formulas

Two upstream references are useful but should not be treated as authoritative templates for this investigation:

- `docs/override-params.md` contains an illustrative override example
- `simpa/src/main.rs` contains simulation-oriented parameter mutations

Neither is the right direct source of truth for a minimal custom devnet here.

For this investigation, candidate values are derived from current upstream consensus config formulas in:

- `consensus/core/src/config/bps.rs`
- `consensus/core/src/config/constants.rs`
- `consensus/core/src/config/params.rs`

## Important Millisecond Caveat

`target_time_per_block` is stored in whole milliseconds.

That means some nominal tiers do not map exactly:

- nominal `15 BPS` becomes candidate `66 ms`
- nominal `32 BPS` becomes candidate `31 ms`

The code still reports integer BPS from `1000 / target_time_per_block`, so these candidates are still plausible tier labels for planning, but calibration must freeze the final report wording.

## Generated Artifacts

- `generated/*.override.json`: minimal candidate override files
- `tier-metadata.csv`: derived tier metadata for review

## Regeneration

Run:

```bash
python3 investigations/node-bps-scaling/scripts/generate-tier-overrides.py
```
