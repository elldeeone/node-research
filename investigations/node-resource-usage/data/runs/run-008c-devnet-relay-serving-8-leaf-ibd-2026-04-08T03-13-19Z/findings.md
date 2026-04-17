# Run 8c Findings

Run IDs:
- `run-008c-devnet-relay-serving-8-leaf-ibd-2026-04-08T03-13-19Z`
- `run-008c-devnet-leaf1-ibd-2026-04-08T03-13-19Z` through `run-008c-devnet-leaf8-ibd-2026-04-08T03-13-19Z`
- corresponding `run-008c-devnet-leaf*-synced-downstream-2026-04-08T03-13-19Z` rollover dirs

Question:
- what happens when one healthy Hetzner relay serves eight simultaneous cold downstream IBDs
- whether this finally creates nonlinear stress, prune-time collapse, or a new minimum-hardware story

Primary references:
- `data/runs/run-008c-devnet-relay-serving-8-leaf-ibd-2026-04-08T03-13-19Z/summary.md`
- `data/runs/run-008c-devnet-relay-serving-8-leaf-ibd-2026-04-08T03-13-19Z/summary.json`
- `data/supporting/run-008c-devnet-leaf1-ibd-2026-04-08T03-13-19Z/summary.json` through `data/supporting/run-008c-devnet-leaf8-ibd-2026-04-08T03-13-19Z/summary.json`
- `data/runs/run-008a-devnet-relay-serving-leaf1-ibd-2026-04-07T13-41-23Z/findings.md`
- `data/runs/run-008b-devnet-relay-serving-leaf1-plus-leaf2-ibd-2026-04-07T23-41-55Z/findings.md`
- `data/runs/run-005-devnet-ibd-2026-04-04T12-08-48Z/summary.md`
- `data/runs/run-005-devnet-synced-stress-pruning-2026-04-04T12-08-48Z/summary.json`

## Headline Result

- relay runtime: `91778s` (`25h 29m 38s`)
- all `8` leaves synced successfully
- active peers stayed pinned at `9`: bootstrap + `8` leaves
- `2` full prune windows were captured
- relay stayed synced through the full run
- no peer collapse
- no OOM
- no write-stall crisis
- no visible failure shape

Best short read:
- `8c` was materially heavier than `8a` and `8b`
- the extra load landed mainly on serve traffic, reads, CPU, and later steady RSS
- it did not turn into the write-path collapse seen on the weaker DUTs

## Leaf Cohort Timing

All eight leaves were cold-started together at `2026-04-08T03:13:19Z`.

Sync timing:
- first leaf synced: `2026-04-08T05:41:57Z` (`8918s`, `148m 38s`)
- last leaf synced: `2026-04-08T05:52:45Z` (`9566s`, `159m 26s`)
- cohort average: `9201s` (`153m 21s`)
- spread from first synced leaf to last synced leaf: `648s` (`10m 48s`)

Comparison:
- run `5` direct bootstrap IBD: `5097s` (`84m 57s`)
- run `8a` one leaf via relay: `8805s` (`146m 45s`)
- run `8b` one synced leaf plus one cold leaf: `8110s` (`135m 10s`)

Read:
- all eight leaves were materially slower than direct bootstrap sync, about `1.75x` to `1.88x` slower than run `5`
- the eight-leaf cohort was still tightly clustered
- concurrency hurt downstream sync time, but not in a chaotic or highly uneven way

## Relay Whole-Run Summary

Whole-run relay headline metrics:
- node RSS max `10.69 GiB`
- node CPU p95 / max `4.38 / 6.17`
- node read p95 / max `103.65 / 259.20 MB/s`
- node write p95 / max `169.55 / 364.58 MB/s`
- node FD max `3668`
- host CPU util p95 / max `56.36 / 91.65%`
- host CPU iowait p95 / max `3.44 / 38.04%`
- host read IOPS p95 / max `1369 / 6033`
- host write IOPS p95 / max `390 / 1092`
- host write await p95 / max `4.02 / 21.08 ms`
- device util p95 / max `27.20 / 72.70%`
- device queue depth p95 / max `1.71 / 11.14`
- device write await p95 / max `3.98 / 18.62 ms`
- RocksDB stall percent p95 / max `0.00 / 0.00%`

Read:
- there were real bursts of strain
- but the whole-run p95 profile still looks like a busy healthy relay, not a collapsing one
- the burst maxima matter, but they were not sustained enough to change the operating story

## Relay During Eight Simultaneous Cold IBDs

Using the relay window from run start to the last leaf sync at `2026-04-08T05:52:45Z`:
- active peers averaged `8.96`, with p95 / max `9 / 9`
- node CPU averaged `4.10`, p95 `5.12`, max `6.17`
- node RSS averaged `6.40 GiB`, p95 `8.41 GiB`, max `8.79 GiB`
- node read throughput averaged `36.24 MB/s`, p95 `108.72 MB/s`, max `241.75 MB/s`
- node write throughput averaged `27.40 MB/s`, p95 `168.21 MB/s`, max `298.23 MB/s`
- derived relay P2P TX averaged `39.40 MB/s`, p95 `53.38 MB/s`, max `74.34 MB/s`
- device util averaged `18.83%`, p95 `33.8%`, max `68.4%`
- device write await averaged `1.02 ms`, p95 `3.87 ms`, max `18.62 ms`
- queue depth averaged `0.57`, p95 `2.17`, max `11.14`
- read IOPS averaged `1029`, p95 `2093`, max `5323`
- write IOPS averaged `71`, p95 `405`, max `794`

Compared with prior relay runs:
- `8a` one cold leaf:
  - node CPU avg `1.73 -> 4.10`
  - node read avg `18.04 -> 36.24 MB/s`
  - node write avg `26.86 -> 27.40 MB/s`
  - relay P2P TX avg `5.20 -> 39.40 MB/s`
- `8b` one synced leaf plus one cold leaf:
  - node CPU avg `1.98 -> 4.10`
  - node read avg `25.11 -> 36.24 MB/s`
  - node write avg `28.59 -> 27.40 MB/s`
  - relay P2P TX avg `6.35 -> 39.40 MB/s`

Read:
- the dominant scaling signal was serve traffic first, then reads and CPU
- average write throughput stayed almost flat versus `8a` and `8b`
- this did not scale as a clean `8x` across every resource
- the missing load from the earlier bootstrap-centric method is real, but it is not primarily a write-path story on this relay class

## Relay After All Leaves Synced

Using the clean window after the last leaf synced and before the first prune:
- node CPU avg fell from `4.10` during the cold-start burst to `2.10`
- node RSS avg rose slightly from `6.40 GiB` to `6.90 GiB`
- node read avg fell from `36.24` to `10.77 MB/s`
- node write avg stayed nearly flat: `27.40 -> 27.20 MB/s`
- derived relay P2P TX fell from `39.40` to `6.62 MB/s`
- device util avg fell from `18.83%` to `7.56%`
- device write await stayed tame: avg `1.02 -> 1.04 ms`, p95 `3.87 -> 3.88 ms`

Longer steady-state behavior between the two prune windows:
- node CPU avg `2.07`
- node RSS avg `8.90 GiB`, p95 `9.76 GiB`, max `9.85 GiB`
- node read avg `12.87 MB/s`
- node write avg `28.10 MB/s`
- derived relay P2P TX avg `5.99 MB/s`
- device util avg `7.13%`
- device write await avg `1.09 ms`, p95 `3.88 ms`
- queue depth avg `0.32`, p95 `1.50`

Read:
- once the leaves finished syncing, the relay mostly relaxed back toward ordinary synced-stress behavior
- the persistent cost of eight synced downstreams was RSS and routine serving overhead
- the persistent cost was not a degraded write path

## Relay During Two Prune Windows

Two full prune windows were captured:
- prune `1`: `2026-04-08T06:32:15.412+00:00` -> `2026-04-08T06:41:35.842+00:00`
- prune `2`: `2026-04-08T18:32:35.166+00:00` -> `2026-04-08T18:41:56.248+00:00`

Prune `1`:
- node CPU avg `3.35`, p95 `4.10`, max `4.88`
- node RSS avg `7.11 GiB`, p95 `7.16 GiB`, max `7.16 GiB`
- node read avg `27.17 MB/s`, p95 `47.23 MB/s`, max `147.22 MB/s`
- node write avg `159.46 MB/s`, p95 `205.59 MB/s`, max `347.69 MB/s`
- derived relay P2P TX avg `5.76 MB/s`
- host CPU iowait avg `4.69%`, p95 `6.04%`, max `8.76%`
- device util avg `28.72%`, p95 `34.10%`, max `50.90%`
- write IOPS avg `330`, p95 `453`, max `720`
- device write await avg `4.27 ms`, p95 `5.97 ms`, max `8.76 ms`
- queue depth avg `1.76`, p95 `2.59`, max `4.36`

Prune `2`:
- node CPU avg `3.38`, p95 `4.13`, max `4.82`
- node RSS avg `9.72 GiB`, p95 `9.74 GiB`, max `9.75 GiB`
- node read avg `31.90 MB/s`, p95 `70.24 MB/s`, max `170.31 MB/s`
- node write avg `158.30 MB/s`, p95 `206.62 MB/s`, max `279.10 MB/s`
- derived relay P2P TX avg `5.83 MB/s`
- host CPU iowait avg `4.74%`, p95 `5.84%`, max `9.38%`
- device util avg `29.17%`, p95 `33.74%`, max `59.00%`
- write IOPS avg `322`, p95 `459`, max `715`
- device write await avg `4.08 ms`, p95 `5.51 ms`, max `7.74 ms`
- queue depth avg `1.69`, p95 `2.47`, max `3.77`

Read:
- prune `2` happened much later, after many more hours of serving, and relay RSS was clearly higher by then
- that higher memory footprint did not translate into worse write latency or deeper queueing
- the two prune windows were very similar on write throughput and device pressure
- that is a strong stability signal

## Comparison With Run 5 No-Leaf Prune

Best practical read versus the healthy no-leaf prune reference:
- `8c` clearly raised CPU and peer-serving load versus run `5`
- `8c` did not produce a meaningfully worse write-path signature on this host class
- write throughput sat in the same general band as the heavier run `5` prune windows
- write await and queue depth also stayed in the same broad band
- prune RSS in `8c` was not worse than the late run `5` no-leaf prune windows

Important nuance:
- prune `1` RSS averaged only `7.11 GiB`
- prune `2` RSS averaged `9.72 GiB`
- late run `5` no-leaf prune windows were already in roughly the `9.8-10.3 GiB` range

Read:
- serving eight downstream peers did make prune busier
- but it made prune busier mainly in CPU and serving terms
- it did not turn prune into a storage-collapse event

## Whole-Run Strain Check

Peak whole-run strain still matters:
- node RSS max `10.69 GiB`
- host CPU util max `91.65%`
- host CPU iowait max `38.04%`
- host write IOPS max `1092`
- host write await max `21.08 ms`
- device util max `72.70%`
- queue depth max `11.14`

Read:
- there were real bursts of strain
- they did not turn into sustained distress
- the relay bent, but it never entered the failure pattern seen on the weak Proxmox path or the small GMK box

## Boring Checks

Things that stayed boring in a good way:
- relay stayed synced for the whole `24h+` run
- active peers stayed pinned at `9`
- network mempool stayed in the same rough band throughout
- RocksDB stall percent in the relay summary stayed `0.00%` at p95 / max
- no peer-collapse
- no sync loss
- no OOM
- no obvious write-stall crisis

## Bottom Line

What run `8c` showed:
- eight simultaneous cold leaves materially increased relay serve traffic, reads, CPU load, and later steady-state RSS
- downstream sync was slower again under this concurrency, but all eight leaves still finished and finished within a tight window
- even this worst controlled relay-serving run remained healthy through two full prune windows
- the main missing load from the earlier bootstrap-centric method is real, but on this Hetzner `cpx42` class relay it still does not look like a write-path collapse

Most important interpretation:
- the relay got much busier
- the extra stress still landed far more on serve/read/CPU than on catastrophic storage latency
- that strengthens the current hardware story rather than overturning it
- storage quality still matters most, and a healthy NVMe-backed `8 vCPU / 16 GiB` class host retained meaningful headroom even under aggressive downstream fanout

What run `8c` did not show:
- no failure point on this host class
- no evidence that `8` concurrent cold downstreams are enough to push this relay into the same pathological shape seen on the weaker DUTs
- so the limiting story is still about weaker storage and weaker headroom, not that a decent relay instantly collapses under normal serving pressure
