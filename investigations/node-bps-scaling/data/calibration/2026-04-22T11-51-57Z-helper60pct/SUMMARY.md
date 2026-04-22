# 20 BPS Calibration: Helper Miner 60% CPU Quota

## Profile

- bootstrap miner: `-t 2`
- helper miner: `-t 1` with `CPUQuota=60%`
- helper txgen: `Wallet B`
- bootstrap mining wallet: `Wallet A`
- txgen flags:
  - `--tps 6000`
  - `--client-pool-size 8`
  - `--max-inflight 6000`
  - `--mempool-high-watermark 650000`
  - `--mempool-resume-watermark 450000`
  - `--timeout-cooldown-ms 2000`

## Capture Window

- bootstrap capture: `tier-20-calibration-bootstrap-2026-04-22T11-51-57Z-helper60pct`
- relay capture: `tier-20-calibration-relay-2026-04-22T11-51-57Z-helper60pct`
- capture duration: about `900s`
- bootstrap RPC sample window: `2026-04-22T11:52:27Z -> 2026-04-22T12:07:26Z`
- relay RPC sample window: `2026-04-22T11:52:27Z -> 2026-04-22T12:07:27Z`

## Outcome

- bootstrap accepted block rate: `19.84 BPS`
- relay accepted block rate: `19.83 BPS`
- bootstrap max RSS: `4.79 GiB`
- relay max RSS: `3.24 GiB`
- helper txgen remained healthy with zero timeout growth

## Interpretation

This is the first clean public-IP, service-based profile that holds the `20 BPS` tier close to target without the earlier `2 + 1` overshoot.

The earlier integer miner splits bracketed the solution:

- bootstrap `-t 2`, helper off: too low
- bootstrap `-t 2`, helper `-t 1`: too high

Applying a `60%` CPU quota to the helper miner produced the expected middle ground and should be treated as the preferred `20 BPS` calibration profile going forward.
