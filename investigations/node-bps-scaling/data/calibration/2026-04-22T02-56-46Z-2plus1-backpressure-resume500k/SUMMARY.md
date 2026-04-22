# 20 BPS Calibration Summary

Run window:
- `2026-04-22T02:56:46Z`
- profile: `2 + 1` miners (`bootstrap -t 2`, helper `-t 1`)
- txgen host: `10.0.4.10`
- txgen wallet: `Wallet B`
- mining wallet: `Wallet A`
- txgen tuning:
  - `--max-inflight 6000`
  - `--client-pool-size 8`
  - `--mempool-high-watermark 650000`
  - `--mempool-resume-watermark 500000`
  - `--timeout-cooldown-ms 2000`

Artifacts:
- [bootstrap-rpc.csv](/Users/luke/Projects/node-research/investigations/node-bps-scaling/data/calibration/2026-04-22T02-56-46Z-2plus1-backpressure-resume500k/bootstrap-rpc.csv)
- [relay-rpc.csv](/Users/luke/Projects/node-research/investigations/node-bps-scaling/data/calibration/2026-04-22T02-56-46Z-2plus1-backpressure-resume500k/relay-rpc.csv)

Measured RPC summary:
- bootstrap overall: `20.32 BPS`, `~5697.8 tx/s`, max mempool `651,990`
- relay overall: `20.33 BPS`, `~5699.5 tx/s`, max mempool `649,829`

Observed txgen behavior:
- txgen stayed active longer before the first pause than the `450k` resume variant
- first pause engaged at about `runtime 365s` when mempool reached `650,287`
- txgen did not hit the earlier timeout wall and completed the full `600s`
- the shallower hysteresis kept txgen active more continuously late in the run

Relay host capture summary:
- relay collector run: `tier-20-smoke-relay-2026-04-22T02-56-46Z`
- relay RSS max: `6.33 GiB`
- relay CPU p95/max: `3.04 / 3.70`
- relay disk busy p95/max: `18.30% / 35.00%`
- relay write await p95/max: `3.70 / 8.27 ms`
- no relay OOM occurred during this run

Interpretation:
- the `500k` resume point did not improve the overall result
- compared with the `450k` resume variant, this run had:
  - slightly lower overall BPS
  - slightly lower overall tx/s
  - higher relay RSS
- the `650k / 500k` profile is therefore a worse operating point than `650k / 450k`
