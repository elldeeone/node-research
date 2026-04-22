# 20 BPS Calibration Summary

Run window:
- `2026-04-22T02:41:49Z`
- profile: `2 + 1` miners (`bootstrap -t 2`, helper `-t 1`)
- txgen host: `10.0.4.10`
- txgen wallet: `Wallet B`
- mining wallet: `Wallet A`
- txgen tuning:
  - `--max-inflight 6000`
  - `--client-pool-size 8`
  - `--mempool-high-watermark 650000`
  - `--mempool-resume-watermark 450000`
  - `--timeout-cooldown-ms 2000`

Artifacts:
- [bootstrap-rpc.csv](/Users/luke/Projects/node-research/investigations/node-bps-scaling/data/calibration/2026-04-22T02-41-49Z-2plus1-backpressure-tuned/bootstrap-rpc.csv)
- [relay-rpc.csv](/Users/luke/Projects/node-research/investigations/node-bps-scaling/data/calibration/2026-04-22T02-41-49Z-2plus1-backpressure-tuned/relay-rpc.csv)

Measured RPC summary:
- bootstrap overall: `20.44 BPS`, `~5725.8 tx/s`, max mempool `650,002`
- relay overall: `20.43 BPS`, `~5723.4 tx/s`, max mempool `650,068`

Observed txgen behavior:
- txgen stayed near the target band during active phases without entering the earlier timeout storm
- first pause engaged at about `runtime 278s` when mempool reached `651,605`
- txgen resumed at about `runtime 344s` when mempool drained to `446,393`
- a second short pause engaged near the end at about `runtime 593s`
- no runaway `inflight=20000` condition and no repeated RPC timeout wall appeared

Relay host capture summary:
- relay collector run: `tier-20-smoke-relay-2026-04-22T02-41-49Z`
- relay RSS max: `5.49 GiB`
- relay CPU p95/max: `3.04 / 3.43`
- relay disk busy p95/max: `17.30% / 25.50%`
- relay write await p95/max: `3.77 / 6.97 ms`
- no relay OOM occurred during this run

Interpretation:
- this is the first clean `20 BPS` / near-`6k TPS` operating point seen so far
- the mempool-aware gate prevented both the earlier timeout storm and the earlier relay OOM
- the price is a controlled duty cycle: overall processed tx/s stayed below `6k` because txgen intentionally paused when mempool reached the cap
- this `650k / 450k` profile is the best stable operating point observed in calibration so far
