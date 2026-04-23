# 20 BPS Baseline Attempt Aborted: Bootstrap-Local Txgen Topology

Date written: `2026-04-23`

## Summary

The first official `20 BPS Baseline` attempt on the bootstrap-local txgen topology was aborted.

Attempted topology:

- `bootstrap`: `kaspad + miner + txgen`
- `relay`: `kaspad`
- `10.0.4.10`: supplementary miner

The run held the target load while valid, but it did not survive as a continuous overnight baseline. The bootstrap host hit a memory failure, `kaspad` restarted under `systemd`, the bootstrap collector finalized and did not reattach, and `txgen` later degraded into persistent `Not connected to server` errors.

## Run IDs

- bootstrap guardrail: `tier-20-baseline-bootstrap-2026-04-22T14-30-46Z`
- relay IBD: `tier-20-baseline-relay-ibd-2026-04-22T14-30-46Z`
- relay synced: `tier-20-baseline-relay-synced-2026-04-22T14-30-46Z`

The raw run directories for this failed attempt were deleted from the hosts after the failure was investigated.

## Valid Measurement Window

The last trustworthy bootstrap window was:

- start: `2026-04-22T14:31:42Z`
- end: `2026-04-22T17:01:23Z`
- duration: `2h 29m 41s`

Average over the valid bootstrap window:

- `19.9 BPS`
- `6053.6 TPS`

Last valid `30 min` window before the collector froze:

- `19.9 BPS`
- `6130.2 TPS`

This means the topology could hit the target band, but it did not do so robustly enough for a publishable long baseline.

## Failure Timeline

- `2026-04-22T17:01:23Z`
  - last valid bootstrap RPC sample written
- `2026-04-22T17:01:26Z`
  - bootstrap `kaspad` was killed by the OOM killer
- `2026-04-22T17:01:29Z`
  - `systemd` restarted `kaspa-bootstrap-20bps.service`
- after restart
  - bootstrap collector finalized the run and did not reattach to the new `kaspad` process
- `2026-04-22T17:35:51Z`
  - first confirmed bootstrap `txgen` error:
    - `Submit failed: Not connected to server`
- overnight
  - relay stayed alive and synced
  - bootstrap node and miner kept running
  - bootstrap txgen remained up as a process, but the intended `~6k TPS` load was no longer valid

## Resource Notes

Bootstrap resource breakdown during the post-failure inspection:

- `kaspad`
  - about `8.6-8.9 GB` RSS after restart
  - peak systemd memory observed about `9.9 GB`
- `Tx_gen`
  - about `3.9-4.2 GB` RSS
  - peak systemd memory observed about `5.7 GB`
- bootstrap miner
  - about `2 MB` RSS
  - CPU-significant, memory-negligible

Just before the failure, bootstrap host available memory dropped to roughly `380 MB`.

Conclusion:

- the OOM was driven by `kaspad + txgen` memory pressure on the same `16 GB` host
- moving only the miner would not materially reduce bootstrap memory risk
- colocating txgen on bootstrap is the main topology risk exposed by this run

## Decision Taken

Use a new dedicated Hetzner txgen host for the next topology iteration.

Next intended layout:

- `bootstrap`: `kaspad + miner`
- `relay`: `kaspad`
- `10.0.4.10`: supplementary miner
- new `hel1` VPS: `txgen` only

Current preference:

- try a `cx33` first for the dedicated txgen role

## Why The Topology Changes

We are not changing topology because the target load was unreachable.

We are changing topology because:

- the bootstrap-local layout did reach the target band while healthy
- but it was not durable enough for the long baseline run
- the main failure mode was bootstrap memory exhaustion followed by collector and txgen recovery problems

So the next iteration should preserve the successful mining shape while removing txgen from the bootstrap host.
