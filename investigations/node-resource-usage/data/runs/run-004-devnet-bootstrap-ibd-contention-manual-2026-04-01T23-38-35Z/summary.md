# Manual Run Summary

- Run: `run-004-devnet-bootstrap-ibd-contention-manual-2026-04-01T23-38-35Z`
- Focus: bootstrap devnet node serving live tx load and remote IBD at the same time
- Bootstrap host: `10.0.3.27`, `12 vCPU`, `25 GiB RAM`, `sda` `330 GiB`, SSD-backed virtual disk (`ROTA=0`)
- DUT peer: Hetzner node `204.168.160.165`
- Hot-load shape: Mac miner + Mac txgen off-box, VM miner off, VM txgen off

## Hot Load

- Capture window: `2026-04-01T23:39:36Z` to `2026-04-01T23:41:06Z`
- Node throughput from `hot-kaspad-journal.log`:
  - avg `9.67 BPS`
  - avg `2117.11 TPS`
  - range `7.7-10.7 BPS`
  - range `1907.6-2401.3 TPS`
- Disk / CPU from `hot-iostat-metrics.csv`:
  - `%util` avg/max: `23.65% / 105.60%`
  - CPU `iowait` avg/max: `3.24% / 43.61%`
  - write await avg/max: `32.12 / 458.91 ms`
  - write throughput avg/max: `10.86 / 52.44 MB/s`
  - write ops avg/max: `30.21 / 222.00 ops/s`
  - queue depth avg/max: `2.44 / 41.95`
- Process / memory from `hot-host-metrics.csv`:
  - `kaspad` RSS avg/max: `2.157 / 2.165 GiB`
  - `kaspad` virtual avg/max: `4.283 / 4.283 GiB`
  - host available RAM avg/min: `24.148 / 24.078 GiB`
  - FD avg/max: `355.9 / 369`
  - thread count avg/max: `84 / 84`

## Idle Baseline

- Capture window: `2026-04-01T23:42:00Z` to `2026-04-01T23:43:30Z`
- Conditions: Mac miner off, Mac txgen off, DUT stopped, bootstrap node only
- Disk / CPU from `idle-iostat-metrics.csv`:
  - `%util` avg/max: `0.29% / 16.70%`
  - CPU `iowait` avg/max: `0.02% / 1.50%`
  - write await avg/max: `1.98 / 105.24 ms`
  - write throughput avg/max: `0.20 / 14.43 MB/s`
  - write ops avg/max: `4.20 / 156.00 ops/s`
  - queue depth avg/max: `0.03 / 2.21`
- Process / memory from `idle-host-metrics.csv`:
  - `kaspad` RSS avg/max: `2.182 / 2.182 GiB`
  - `kaspad` virtual avg/max: `4.240 / 4.240 GiB`
  - host available RAM avg/min: `24.136 / 24.113 GiB`
  - FD avg/max: `349 / 349`
  - thread count avg/max: `62 / 62`

## fio Device Estimates

- Capture window: `2026-04-01T23:44:42Z` to `2026-04-01T23:47:01Z`
- Conditions: bootstrap service stopped for clean device test
- Tool: `fio 3.36`
- Profiles:
  - sequential write, `1 MiB`, `iodepth=32`, `runtime=30s`: `48.58 MB/s`, `48.58 IOPS`, mean completion latency `658.617 ms`
  - sequential read, `1 MiB`, `iodepth=32`, `runtime=30s`: `1133.95 MB/s`, `1133.95 IOPS`, mean completion latency `28.166 ms`
  - random write, `4 KiB`, `iodepth=32`, `runtime=30s`: `6.63 MB/s`, `1696.63 IOPS`, mean completion latency `18.848 ms`
  - random read, `4 KiB`, `iodepth=32`, `runtime=30s`: `364.26 MB/s`, `93250.28 IOPS`, mean completion latency `0.340 ms`
- fio-side disk / CPU from `fio-iostat-metrics.csv`:
  - `%util` avg/max: `79.44% / 100.00%`
  - CPU `iowait` avg/max: `0.75% / 16.58%`
  - write await avg/max: `159.81 / 1257.06 ms`
  - write throughput avg/max: `12.71 / 93.75 MB/s`
  - write ops avg/max: `389.00 / 2671.00 ops/s`
  - queue depth avg/max: `40.17 / 183.09`
- fio-side RAM / CPU from `fio-vmstat.txt`:
  - free RAM avg/min: `18.86 / 18.72 GiB`
  - CPU user avg/max: `0.40% / 22%`
  - CPU system avg/max: `0.67% / 3%`
  - CPU iowait avg/max: `0.78% / 17%`

## Findings

- CPU and RAM were not exhausted in the hot phase. `kaspad` sat around `~2.16 GiB RSS` with `~24 GiB` still available on the host.
- The main moving signal was storage latency / queueing, not memory pressure.
- Zero-load baseline was clean: `%util` `0.29%` avg, `iowait` `0.02%` avg, queue depth `0.03` avg.
- Under off-box tx load plus DUT IBD, the bootstrap could still process about `~2.1k TPS` at about `~9.7 BPS`, but storage wait/queue spikes became severe.
- The DUT initially progressed through IBD, then slowed sharply, then timed out after `120s`.
- That means the bootstrap node can continue normal tx/block work under this load, but cannot reliably sustain public IBD serving at the same time.

## Prior HDD Context

- Earlier manual observation on the same workload shape, before moving the VM to SSD-backed storage:
  - `%util` about `76-97.5%`
  - CPU `iowait` about `5-10%`
  - write await about `14-37 ms`
  - queue depth up to about `12`
  - write throughput up to about `31 MB/s`
- SSD improved the idle baseline substantially and removed the always-hot disk profile, but it did not remove the mixed-load IBD-serving failure mode.

## Practical Learning

- For this devnet lab, the hot bootstrap node should not be the only IBD source for the DUT.
- Better split:
  - bootstrap node: tx sink / chain producer
  - separate calmer serving peer: DUT IBD source
- If a single bootstrap node must also serve IBD, reduce tx load materially before starting the DUT sync.
