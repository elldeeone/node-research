# 20 BPS Calibration Summary

Run window:
- `2026-04-22T01:33:57Z`
- profile: `2 + 1` miners (`bootstrap -t 2`, helper `-t 1`)
- txgen host: `10.0.4.10`
- txgen wallet: `Wallet B`
- mining wallet: `Wallet A`

Artifacts:
- [bootstrap-rpc.csv](/Users/luke/Projects/node-research/investigations/node-bps-scaling/data/calibration/2026-04-22T01-33-57Z-2plus1/bootstrap-rpc.csv)
- [relay-rpc.csv](/Users/luke/Projects/node-research/investigations/node-bps-scaling/data/calibration/2026-04-22T01-33-57Z-2plus1/relay-rpc.csv)

Measured RPC summary:
- bootstrap overall: `20.82 BPS`, avg mempool `330,601`, max mempool `676,751`
- relay overall: `20.82 BPS`, avg mempool `327,418`, max mempool `676,774`
- bootstrap stable window (`0-540s`): `21.08 BPS`
- relay stable window (`0-540s`): `21.08 BPS`
- bootstrap collapse window (`540-830s`): `20.21 BPS`
- relay collapse window (`540-830s`): `20.22 BPS`
- bootstrap recovery window (`830-900s`): `21.49 BPS`
- relay recovery window (`830-900s`): `21.42 BPS`

Observed txgen behavior from the live session:
- early phase: txgen repeatedly operated around `~5.7k-6.3k submit/s`, with occasional bursts above `6k`
- middle phase: ready-head inventory drained and txgen entered an `inflight=20000` saturation mode with submit rate collapsing toward zero
- recovery phase: a large confirmed-head refresh restored runway and txgen returned to the `~5.8k-6.2k submit/s` band for the final minute

Interpretation:
- the `2 + 1` miner profile is strong enough to hold the tier on average
- relay and bootstrap tracked each other closely, which suggests the relay was not the bottleneck
- the calibration still does **not** qualify as a clean pass yet because txgen was not stable for the full `15 min` window
- the next investigation task is txgen tuning around the late-run saturation / refresh behavior, not another miner-power change
