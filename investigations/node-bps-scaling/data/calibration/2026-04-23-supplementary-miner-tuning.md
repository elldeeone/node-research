# 2026-04-23 Supplementary Miner Tuning

## Context

After the dedicated txgen host (`cx33`) was introduced, the remaining issue was miner shaping:

- bootstrap miner at `-t 2` with no supplementary miner sat low at roughly `19.0 BPS`
- bootstrap miner at `-t 3` with the same topology overshot badly at roughly `24.4 BPS`

That made the supplementary miner the next tuning lever.

## Discovery

The expected supplementary miner was not actually active on `10.0.4.30`.

Actions taken:

- logged into `10.0.4.30`
- deployed `kaspa-miner-musl`
- installed a `systemd` unit for the supplementary miner
- pointed it directly at bootstrap public gRPC `157.180.69.53:16610`
- used the existing off-box mining wallet address:
  - `kaspadev:qp36yywzq3307ev5h2z4yua38qmv9hvcd90gwhujhzn8drwapam5uq4am6049`

Bootstrap miner remained unchanged at:

- `MINER_THREADS=2`

## Sweep Results

### 1 thread, `CPUQuota=60%`

This reproduced the old helper-miner shape but on `10.0.4.30`.

Warm-window result from bootstrap journal samples:

- `22.543 BPS`
- `6943.3 TPS`

Assessment:

- too aggressive
- invalid due to clear cadence overshoot

### 1 thread, `CPUQuota=25%`

Warm-window result from bootstrap journal samples:

- `19.52 BPS`
- `6012.0 TPS`

Txgen host behavior over the same window:

- active submit band remained around `~6k submit/s`
- no timeout storm

Assessment:

- best current fit
- comfortably clears the TPS requirement
- materially closer to `20 BPS` without overshooting

### 1 thread, `CPUQuota=30%`

Warm-window result from bootstrap journal samples:

- `19.392 BPS`
- `5972.8 TPS`

Assessment:

- no improvement over `25%`
- slightly worse combined result in this sweep

## Outcome

Best-known dedicated-txgen profile after miner retuning:

- bootstrap miner: `-t 2`
- supplementary miner host: `10.0.4.30`
- supplementary miner threads: `1`
- supplementary miner `CPUQuota`: `25%`
- dedicated txgen host: `cx33` in `hel1`

Operational state after the sweep:

- supplementary miner left running on `10.0.4.30` at `25%`
- bootstrap miner left at `-t 2`
- dedicated txgen host stopped

This is the current best-known launch posture for the next `20 BPS` dedicated-txgen baseline attempt.
