# Config Validation Checklist

## Goal

Validate each custom BPS tier before any long capture begins.

The most important output of this checklist is a trusted final label for every tier that does not map cleanly to whole milliseconds. Until then, refer to the provisional top rung as `Validated Max Tier`.

## Tier Validation Workflow

Run this checklist for:

- `15 BPS`
- `20 BPS`
- `25 BPS`
- `Validated Max Tier`

## 1. Produce The Candidate Params

- generate or derive the override params file for the tier
- record the exact source of the params
- record the exact `target_time_per_block`
- record any coupled blockrate fields that changed with it

For the provisional max tier, do not assume the final public-facing name until this step is complete.

## 2. Boot A Clean Network

- start a fresh non-mainnet network using the candidate params
- confirm the bootstrap starts cleanly
- confirm the relay starts cleanly against the same params
- verify no immediate consensus or compatibility errors appear

## 3. Verify Block Cadence

- observe block production over a short fixed window
- confirm effective cadence is close enough to the intended tier
- record the observed rate and the exact measurement window

If the practical cadence and the nominal BPS label diverge, prefer the exact validated wording in later report text.

Current first-pass candidates already suggest this issue exists for:

- nominal `15 BPS` -> candidate `66 ms`
- nominal `32 BPS` -> candidate `31 ms`

## 4. Verify Load Scaling

- run the tx generator with the intended scaled target
- confirm the offered load is actually sustained
- record any drift between target TPS and observed TPS
- note whether the bottleneck appears to be generation, mining, bootstrap, or relay

## 5. Check Bootstrap Health

- confirm the bootstrap remains synced
- confirm bootstrap storage and CPU stay within a healthy envelope
- confirm bootstrap is not already the limiting factor

If bootstrap becomes the bottleneck here, do not proceed to a long relay run.

## 6. Check Relay Health

- confirm the relay can sync from the bootstrap
- confirm the relay remains current under the offered load
- confirm storage-path metrics stay interpretable during the smoke window

## 7. Check Downstream Attachments

- validate one cold leaf against the relay
- validate the simultaneous downstream workflow needed for the eight-leaf scenario
- confirm the relay remains the sole downstream source

## 8. Freeze Tier Metadata

For every validated tier, record:

- tier label used in report prose
- tier slug used in run IDs and manifests
- nominal BPS
- exact `target_time_per_block`
- observed block cadence from the smoke test
- intended TPS target
- observed TPS from the smoke test
- params file path and hash

## Validation Pass Criteria

A tier is ready for long runs only if:

- bootstrap and relay start cleanly
- observed cadence is close enough to the intended tier
- scaled synthetic load is sustained
- bootstrap is not the clear limiting factor
- relay stays healthy during the smoke window
- downstream workflows attach successfully

## Validation Fail Criteria

Pause the tier and revise params or workflow if:

- consensus params fail to load
- practical cadence does not match the intended tier closely enough
- synthetic load cannot be held
- bootstrap clearly saturates first
- relay fails during the smoke window
- downstream workflows do not behave predictably
