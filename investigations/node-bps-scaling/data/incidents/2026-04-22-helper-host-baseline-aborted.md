# 20 BPS Baseline Attempt Aborted: Helper-Host Txgen Topology

Date written: `2026-04-23`

## Summary

The earlier `20 BPS Baseline` attempt that used helper-host txgen was aborted because it did not sustain the required TPS target.

Attempted topology:

- `bootstrap`: `kaspad + miner`
- `relay`: `kaspad`
- `10.0.4.10`: `txgen + supplementary miner`

This attempt did not fail because of a host crash or collector break. It was stopped intentionally after it became clear that the topology was not delivering the required steady-state offered load for the baseline.

## Run IDs

- bootstrap guardrail: `tier-20-baseline-bootstrap-2026-04-22T12-15-35Z`
- relay IBD: `tier-20-baseline-relay-ibd-2026-04-22T12-15-35Z`

## Measured Window

Bootstrap valid window:

- start: `2026-04-22T12:16:03Z`
- end: `2026-04-22T13:32:07Z`
- duration: `4564s` (`1h 16m 04s`)

Bootstrap average over the full attempt:

- `19.792 BPS`
- `4962.9 TPS`

Last `10 min` of the attempt:

- `20.167 BPS`
- `4927.8 TPS`

End-of-window bootstrap state:

- mempool: `0`
- `is_synced=1`

Relay state at the end of the attempt:

- timestamp: `2026-04-22T13:32:07Z`
- `is_synced=0`
- mempool: `0`

## Why It Was Stopped

This attempt was halted because the baseline acceptance criteria were not met.

The project requirement for the `20 BPS` tier was:

- `BPS` near target
- `TPS` at the lowest `5.5k`, preferably as close as possible to `6k`

What actually happened:

- `BPS` was close enough
- `TPS` stayed around `4.9k-5.0k`
- bootstrap mempool drained to zero rather than holding a healthy backlog
- relay had not yet finished IBD, so there was no value in continuing a topology that was already under target on the offered-load side

## Main Lesson

The helper-host txgen topology was not good enough for the official baseline.

At that stage, the important conclusion was:

- the network cadence could be shaped near `20 BPS`
- but the helper-host txgen path was not sustaining the required `20 BPS / ~6k TPS` baseline envelope

This is the run that pushed the investigation into the next tuning phase.

## What Happened Next

This aborted attempt led to two subsequent changes in the investigation:

1. Further txgen control-loop tuning
2. A topology rethink around where txgen should live

Later work showed:

- bootstrap-local txgen could hit the target band in steady-state
- but that topology eventually failed for a different reason: bootstrap memory exhaustion

That later failure is documented separately in:

- [2026-04-23-bootstrap-local-baseline-aborted.md](/Users/luke/Projects/node-research/investigations/node-bps-scaling/data/incidents/2026-04-23-bootstrap-local-baseline-aborted.md)

## Decision Taken

Treat this run as an intentionally aborted baseline attempt.

Reason:

- under-target TPS on the helper-host txgen topology
- not a host crash
- not a collector failure

The lesson to preserve is that being near `20 BPS` was not sufficient. The baseline also needed a stable `~6k TPS` offered-load path, and this topology did not provide it.
