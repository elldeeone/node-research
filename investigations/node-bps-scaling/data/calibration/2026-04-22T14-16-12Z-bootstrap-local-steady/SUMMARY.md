# 20 BPS Calibration: Bootstrap-Local Txgen Steady-State Validation

## Profile

- bootstrap miner: `-t 2`
- bootstrap txgen: local to bootstrap via `grpc://127.0.0.1:16610`
- helper miner: `10.0.4.10`, `-t 1`, `CPUQuota=60%`
- txgen wallet: `Wallet B`
- mining wallet: `Wallet A`
- txgen flags:
  - `--tps 6000`
  - `--client-pool-size 32`
  - `--max-inflight 3000`
  - `--mempool-high-watermark 650000`
  - `--mempool-resume-watermark 450000`
  - `--rpc-timeout-ms 15000`
  - `--timeout-cooldown-ms 1000`
  - `--timeout-cooldown-threshold 64`

## Capture Windows

- startup-inclusive probe:
  - source: `/tmp/node-bps-tuning/bootstrap-local-txgen-startup-20260422T141339Z.csv`
  - window: `2026-04-22T14:13:39Z -> 2026-04-22T14:15:39Z`
- steady-state confirmation:
  - source: `/tmp/node-bps-tuning/bootstrap-local-txgen-steady-20260422T141612Z.csv`
  - window: `2026-04-22T14:16:12Z -> 2026-04-22T14:26:11Z`

## Outcome

- startup-inclusive probe:
  - whole-window average: `19.37 BPS`, `5113.0 TPS`
  - after `30s`: `19.32 BPS`, `5950.6 TPS`
  - after `45s`: `19.20 BPS`, `5908.2 TPS`
  - after `60s`: `19.01 BPS`, `5849.4 TPS`
- steady-state confirmation:
  - `19.82 BPS`
  - `6105.5 TPS`
  - ending mempool: `502589`

## Interpretation

This is the first validation on the intended final topology: bootstrap-local tx generation with supplementary off-box mining from `10.0.4.10`.

The local txgen path removes the WAN RTT penalty entirely and behaves much more cleanly than the earlier helper-host txgen layout:

- txgen immediately entered the target submit band
- no timeout storm appeared
- the bootstrap held above the required `5.5k TPS` floor in steady-state
- the confirmed steady-state average slightly exceeded the `6k TPS` target

Operational rule going forward:

- bootstrap-local txgen is the canonical `20 BPS` launch model
- treat the first `30-60s` as startup/ramp
- use the steady-state window, not the startup-inclusive window, to grade the official load profile
