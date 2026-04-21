# Node BPS Scaling Charter

## Purpose

This investigation is a standalone study of how Kaspa node performance requirements change as block rate rises and synthetic load rises with it.

It is not an extension of `investigations/node-resource-usage`. The earlier work only contributes one design choice here: the separated bootstrap-plus-relay topology proved cleaner than the bootstrap-heavy alternatives, so this investigation reuses that architecture.

## Study Question

How do CPU, memory, storage, and network requirements change as BPS rises when offered load is scaled with BPS on the same reference hardware?

## Locked Decisions

- investigation name: `node-bps-scaling`
- topology: separated `Bootstrap` + `Relay` + optional `Leaves`
- primary DUT: Hetzner `CPX42`-class relay node
- BPS ladder: `20`, `25`, and `Validated Max Tier`
- scenario families per tier:
  - `Baseline`
  - `Single-Downstream`
  - `Eight-Downstream`
- no middle-case equivalent of the old `8b`
- offered synthetic load should scale with BPS while keeping transaction shape as stable as possible
- pruning is first-class evidence, not an afterthought
- hardware boundary testing is a later phase, not part of the first sign-off

## Non-Goals For Phase 1

- proving a universal hardware minimum across all host classes
- repeating the earlier `10 BPS` work
- re-testing the bootstrap-heavy architectures that already looked storage-limited
- turning the bootstrap into a co-equal DUT unless a run becomes ambiguous

## Topology

### Roles

- `Bootstrap`: hosts the custom devnet, local miner, and tx generation
- `Relay`: the node under test on the `CPX42` reference host
- `Leaves`: downstream nodes that sync only from the relay during downstream scenarios

### Why This Topology

- it produced the cleanest evidence in the earlier work
- it reduced ambiguity caused by mixing bootstrap duty and measured serving duty
- it gives the relay a fair chance to show its own scaling behavior

## Tier Ladder

Phase 1 should test these three tiers:

- `20 BPS`
- `25 BPS`
- `Validated Max Tier`

Working throughput targets should scale with BPS:

- `20 BPS` -> about `6.0k TPS`
- `25 BPS` -> about `7.5k TPS`
- `Validated Max Tier` -> the highest practical equivalent after config validation

The exact validated label of any non-exact millisecond tier should remain provisional until calibration freezes it. At the moment, the current candidate set suggests that the provisional max tier needs special care:

- the provisional max tier currently maps to candidate `31 ms`

If the cleanest final label is a target-time label such as `31 ms target time`, the report should use that exact validated wording rather than forcing a premature precision claim.

## Scenario Families

### Baseline

Separated bootstrap plus relay, with no downstream leaves.

Purpose:

- isolate pure higher-BPS relay cost
- measure how pruning and post-prune recovery evolve as BPS rises

Official target:

- at least `3` prune windows, or failure first

### Single-Downstream

Separated bootstrap plus relay, with one cold leaf syncing from the relay.

Purpose:

- measure the smallest meaningful serving penalty at each tier
- determine whether one downstream remains mostly a read/CPU/network tax

Official target:

- leaf fully synced
- at least `1` prune window

### Eight-Downstream

Separated bootstrap plus relay, with eight cold leaves syncing from the relay simultaneously.

Purpose:

- measure the heavy fanout penalty at each tier
- identify whether higher BPS plus fanout creates nonlinear stress during or after pruning

Official target:

- all leaves fully synced
- at least `2` prune windows if the relay remains healthy

## Capture Strategy

### Relay

The relay is the primary subject and receives the full capture stack:

- `kaspad` perf metrics
- host CPU, memory, disk, and network telemetry
- RPC sync and peer telemetry
- `iostat`
- RocksDB log collection and stall parsing
- per-run summaries and event extraction

### Bootstrap

The bootstrap should receive enough telemetry to prove:

- the intended tier configuration is active
- offered load is real
- the bootstrap remained healthy enough to feed the relay

Bootstrap deep-dive analysis is only required when a run becomes ambiguous or suspicious.

## Calibration Policy

No multi-day capture should begin before tier validation passes.

Each tier requires a short calibration phase that confirms:

- the custom params load correctly
- observed block cadence matches the intended tier closely enough
- the tx generator can sustain the scaled load
- the bootstrap remains healthy
- the relay can sync and stay current
- downstream leaves can attach and sync in the downstream scenarios

## Run Order

Recommended order within each tier:

1. tier calibration
2. `Baseline`
3. `Single-Downstream`
4. `Eight-Downstream`

Recommended tier order:

1. `20 BPS`
2. `25 BPS`
3. `Validated Max Tier`

This order lets earlier tiers debug the operational workflow before the more expensive long runs.

## Stop Conditions

Stop a run and mark it failed if any of the following occurs:

- relay loses sync and does not recover in a bounded observation window
- relay is OOM-killed
- bootstrap clearly becomes the bottleneck, invalidating relay interpretation
- the intended synthetic load cannot be sustained
- severe storage-path distress appears and the node enters a visibly pathological state

Examples of distress indicators include:

- sustained high write await
- sustained deep queue depth
- persistent RocksDB stall signals
- repeated failure to recover cleanly after prune windows

## Deliverables

Phase 1 should produce:

- a standalone report under `investigations/node-bps-scaling/REPORT.md`
- a publishable run register and raw-bundle manifest after real captures exist
- per-tier comparison tables for:
  - relay-only cost
  - one-downstream penalty
  - eight-downstream penalty
- a concise conclusion about how the `CPX42` reference host bends or fails as BPS rises

## Deferred Phase 2

Phase 2 should use the most informative high-stress tiers from Phase 1 to test additional hardware classes and identify actual requirement boundaries.

Phase 2 is explicitly out of scope for the initial sign-off.
