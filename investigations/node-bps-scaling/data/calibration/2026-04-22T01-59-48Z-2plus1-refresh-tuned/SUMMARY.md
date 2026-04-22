# 20 BPS Calibration Summary

Run window:
- `2026-04-22T01:59:48Z`
- profile: `2 + 1` miners (`bootstrap -t 2`, helper `-t 1`)
- txgen host: `10.0.4.10`
- txgen wallet: `Wallet B`
- mining wallet: `Wallet A`
- txgen tuning: separate startup/runtime RPC timeouts plus earlier confirmed-head refresh

Artifacts:
- [bootstrap-rpc.csv](/Users/luke/Projects/node-research/investigations/node-bps-scaling/data/calibration/2026-04-22T01-59-48Z-2plus1-refresh-tuned/bootstrap-rpc.csv)
- [relay-rpc.csv](/Users/luke/Projects/node-research/investigations/node-bps-scaling/data/calibration/2026-04-22T01-59-48Z-2plus1-refresh-tuned/relay-rpc.csv)

Measured RPC summary:
- bootstrap overall: `18.30 BPS`, avg mempool `737,003`, max mempool `1,000,000`
- bootstrap stable window (`0-540s`): `19.04 BPS`, avg mempool `560,359`
- bootstrap collapse window (`540-830s`): `15.00 BPS`, avg mempool `999,680`
- bootstrap recovery window (`830-900s`): `26.73 BPS`, avg mempool `999,494`
- bootstrap overall tx processing: `~5,970 tx/s`
- bootstrap stable-window tx processing: `~5,660 tx/s`

Observed saturation points:
- relay network mempool first exceeded `700k` at `318.774s`
- bootstrap network mempool first exceeded `999k` at `426.376s`

Observed txgen behavior from the live session:
- the earlier refresh logic did trigger before the old failure zone
- one confirmed refresh added `45,383` heads after `25.3s`
- txgen still spent long stretches in the `~5k-7k submit/s` band
- later in the run, submit calls degraded into repeated `RPC request timeout` failures

Relay health note:
- the relay was OOM-killed by the kernel at `2026-04-22 02:11:56 UTC`
- the relay `kaspad` process restarted at `2026-04-22 02:12:01 UTC`
- relay RPC samples after roughly `706s` are not directly comparable with the pre-OOM portion of the run

Interpretation:
- the txgen refresh tuning helped, but it did not produce a clean `15 min` pass
- this rerun surfaced two separate failure modes:
  - bootstrap mempool saturation at the `1,000,000` cap
  - relay memory collapse under the same load profile
- the tier still remains `needs-tuning`
- the next tuning step should focus on why submit RPCs degrade into timeout storms and why the relay grows to OOM despite the earlier txgen refresh behavior
