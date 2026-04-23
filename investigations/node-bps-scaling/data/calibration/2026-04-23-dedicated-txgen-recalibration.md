# 2026-04-23 Dedicated Txgen Recalibration

## Context

This recalibration followed two aborted baseline attempts:

- helper-host txgen topology: under target on TPS
- bootstrap-local txgen topology: hit target TPS/BPS, but later failed due to bootstrap memory pressure and restart fallout

The new topology under test was:

- bootstrap: `kaspad + miner`
- relay: `kaspad`
- dedicated `hel1` txgen VPS (`cx33`): `Tx_gen`
- `10.0.4.10`: supplementary miner

## 2 + Helper Result

Bootstrap miner stayed at `MINER_THREADS=2`, with the supplementary miner still connected from `87.121.72.51`.

Dedicated txgen host run:

- txgen host service start: `2026-04-23 00:17:38 UTC`
- txgen wallet analysis completed: `2026-04-23 00:17:49 UTC`
- txgen steady submit band: roughly `5.8k-6.4k submit/s` with `0` timeouts

Bootstrap capture summary:

- overall capture window:
  - `2026-04-23T00:16:00Z -> 2026-04-23T00:30:59Z`
  - `19.147 BPS`
  - `5064.7 TPS`
- steady-state window from `00:20:00Z`:
  - `19.02 BPS`
  - `5857.6 TPS`
- last `10 min`:
  - `19.045 BPS`
  - `5865.9 TPS`

Assessment:

- TPS target was materially improved and cleared the `>= 5.5k TPS` floor.
- BPS remained lower than desired at roughly `19.0`, so the topology was not yet considered baseline-ready.

## Supplementary Miner Verification

Bootstrap socket inspection showed a persistent connection from `87.121.72.51` to bootstrap gRPC `16610`, alongside the local miner loopback connection. That confirmed the supplementary miner was present during the recalibration; the low BPS was not caused by a missing helper miner.

## 3 + Helper Sweep

To test whether the missing BPS was simply insufficient bootstrap-local mining power, bootstrap miner threads were temporarily raised from `2` to `3`, while keeping the dedicated txgen host and supplementary miner unchanged.

Warm-window measurement from bootstrap journal `Processed ... in the last 10.00s` samples:

- samples: `39`
- average:
  - `24.441 BPS`
  - `7527.8 TPS`

Assessment:

- `3 + helper` overshot badly.
- The problem is not that the current dedicated-txgen topology needs a full extra bootstrap thread.

## Outcome

The dedicated txgen host topology solved the bootstrap memory issue and produced a much better TPS profile than the earlier helper-host txgen attempt.

Current state of evidence:

- dedicated txgen host + `2 + helper` miners:
  - viable on TPS
  - slightly low on BPS
- dedicated txgen host + `3 + helper` miners:
  - invalid due to major BPS overshoot

The remaining calibration lever is not bootstrap miner thread count. The next likely tuning target is the supplementary miner strength on `10.0.4.10`, if we want to move from roughly `19.0 BPS` toward a tighter `20.0 BPS` without overshooting.
