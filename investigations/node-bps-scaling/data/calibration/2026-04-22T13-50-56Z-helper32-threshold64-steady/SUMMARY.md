# 20 BPS Calibration: Direct Public-RPC Helper Steady-State Validation

## Profile

- bootstrap miner: `-t 2`
- helper miner: `-t 1` with `CPUQuota=60%`
- txgen host: `10.0.4.10`
- txgen wallet: `Wallet B`
- mining wallet: `Wallet A`
- helper-to-bootstrap RTT: about `283 ms`
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
  - source: `/tmp/node-bps-tuning/bootstrap-rpc-20260422T134332Z.csv`
  - window: `2026-04-22T13:43:32Z -> 2026-04-22T13:48:31Z`
- steady-state confirmation:
  - source: `/tmp/node-bps-tuning/bootstrap-rpc-steady-20260422T135056Z.csv`
  - window: `2026-04-22T13:52:56Z -> 2026-04-22T14:02:55Z`

## Outcome

- startup-inclusive probe:
  - whole-window average: `19.88 BPS`, `4778.3 TPS`
  - after `60s`: `19.72 BPS`, `5977.7 TPS`
  - after `90s`: `19.66 BPS`, `6054.1 TPS`
  - after `120s`: `19.67 BPS`, `6058.8 TPS`
- steady-state confirmation after a full `120s` warm-up:
  - `19.45 BPS`
  - `5989.8 TPS`
  - ending mempool: `596887`

## Interpretation

The poor startup-inclusive average was mostly a measurement artifact. On the large `Wallet B` path, the first `60-120s` after txgen service start are dominated by wallet-scan and submission ramp-up, so that window should not be used to grade steady-state throughput.

Once warm, the retuned helper profile consistently held the bootstrap near the intended `~6k TPS` target on the direct public-RPC path. The key fixes were:

- increase gRPC client concurrency materially for the long-RTT WAN path
- lower per-connection queue pressure by capping inflight work at `3000`
- raise runtime RPC timeout to avoid premature submit failures on the high-latency path
- only enter cooldown after a real timeout burst instead of a single late response

Operational rule going forward:

- warm txgen for about `120s`
- only then judge `20 BPS` TPS health or begin the steady-state measurement window
