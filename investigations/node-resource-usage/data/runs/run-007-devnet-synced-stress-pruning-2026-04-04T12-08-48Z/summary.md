# Node Resource Summary

- Run: `run-007-devnet-synced-stress-pruning-2026-04-04T12-08-48Z`
- Node samples: 84320
- Host samples: 79947
- RPC samples: 83788
- Duration seconds: 85759

## Highlights

- Node RSS max: 10.60 GiB
- Node CPU p95/max: 2.43 / 3.82
- Node disk read p95/max: 54.84 / 144.34 MB/s
- Node disk write p95/max: 110.65 / 247.35 MB/s
- Node FD max: 3649

## Host Derived

- Host CPU util p95/max: 64.30% / 97.86%
- Host CPU iowait p95/max: 72.10% / 98.40%
- Host disk read p95/max: 55.30 / 210.85 MB/s
- Host disk write p95/max: 110.47 / 301.46 MB/s
- Host disk read ops p95/max: 638.00 / 7038.00 ops/s
- Host disk write ops p95/max: 302.00 / 18101.00 ops/s
- Host disk read await p95/max: 157.41 / 4649.80 ms
- Host disk write await p95/max: 795.33 / 4030.67 ms
- Host disk queue depth p95/max: 14.43 / 271.19
- Host disk busy p95/max: 102.40% / 767.20%
- Storage used max: 149.33 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 843723.00 / 936355.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 5510.93 / 61600.00 tx/s
- P2P RX p95/max: 2.53 / 6.18 MB/s

## Iostat Derived

- Device util p95/max: 96.90% / 115.40%
- Device queue depth p95/max: 13.60 / 110.35
- Device read await p95/max: 147.20 / 4649.80 ms
- Device write await p95/max: 768.00 / 4308.00 ms
- Device read throughput p95/max: 53.68 / 190.27 MB/s
- Device write throughput p95/max: 104.02 / 270.59 MB/s

## Separate fio Baseline

- Post-run unloaded baseline on the same GMK Nucbox G5 host, with no `kaspad` running:
  - sequential write `57.95 MB/s`, `55.26 IOPS`, mean completion latency `574.632 ms`
  - sequential read `1181.63 MB/s`, `1126.89 IOPS`, mean completion latency `28.238 ms`
  - 4K random write `92.58 MB/s`, `22603.57 IOPS`, mean completion latency `1.398 ms`
  - 4K random read `199.35 MB/s`, `48668.82 IOPS`, mean completion latency `0.651 ms`
- That unloaded baseline is materially stronger than the weak Proxmox path from run 6, so this run's terminal OOM looks more like limited RAM/headroom under prolonged live churn than a clearly underpowered idle storage path.

## RocksDB

- Event rows: 732763
- Compactions: 50510
- Flush starts: 9345
- Flush finishes: 9345
- Stall stats rows: 858
- Write stall rows: 729
- Compaction time p95/max: 3.45 / 39.54 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- ibd: node disk write max 247.20 MB/s; device util max 100.10%; tx processed max 42735.38 tx/s; rocksdb compactions 3435 stalls 24
- ibd_2: node disk write max 247.35 MB/s; device util max 100.00%; tx processed max 46583.08 tx/s; rocksdb compactions 1337 stalls 12
- synced: node disk write max 22.08 MB/s; device util max 84.60%; tx processed max 20271.12 tx/s
- synced_2: node disk write max 38.49 MB/s; device util max 90.00%; tx processed max 7976.10 tx/s
- ibd_3: node disk write max 205.43 MB/s; device util max 100.10%; tx processed max 41721.12 tx/s; rocksdb compactions 620 stalls 6
- ibd_4: node disk write max 198.52 MB/s; device util max 100.10%; tx processed max 30861.11 tx/s; rocksdb compactions 294 stalls 6
- ibd_5: node disk write max 197.59 MB/s; device util max 100.10%; tx processed max 52451.49 tx/s; rocksdb compactions 142 stalls 0
- ibd_6: node disk write max 193.49 MB/s; device util max 86.70%; tx processed max 36776.12 tx/s; rocksdb compactions 77 stalls 0
- ibd_7: node disk write max 196.23 MB/s; device util max 100.10%; tx processed max 41944.33 tx/s; rocksdb compactions 160 stalls 0
- ibd_8: node disk write max 180.36 MB/s; device util max 100.00%; tx processed max 48776.89 tx/s; rocksdb compactions 89 stalls 0
- ibd_9: node disk write max 159.64 MB/s; device util max 100.00%; tx processed max 30921.26 tx/s; rocksdb compactions 43 stalls 0
- ibd_10: node disk write max 180.00 MB/s; device util max 99.30%; tx processed max 61600.00 tx/s; rocksdb compactions 60 stalls 0
- ibd_11: node disk write max 63.91 MB/s; device util max 78.20%; tx processed max 33649.61 tx/s; rocksdb compactions 10 stalls 0
- ibd_12: node disk write max 163.53 MB/s; device util max 88.00%; tx processed max 41762.71 tx/s; rocksdb compactions 48 stalls 0
- ibd_13: node disk write max 121.22 MB/s; device util max 100.10%; tx processed max 37426.29 tx/s; rocksdb compactions 22 stalls 6
- pruning: node disk write max 156.94 MB/s; device util max 100.10%; tx processed max 6129.35 tx/s; rocksdb compactions 976 stalls 12
- synced_3: node disk write max 199.26 MB/s; device util max 115.40%; tx processed max 61600.00 tx/s; rocksdb compactions 18847 stalls 336
- synced_4: node disk write max 58.51 MB/s; device util max 76.00%; tx processed max 14111.55 tx/s; rocksdb compactions 2 stalls 0
- synced_5: node disk write max 15.45 MB/s; device util max 93.20%; tx processed max 10440.68 tx/s; rocksdb compactions 1 stalls 0
- synced_6: node disk write max 30.53 MB/s; device util max 94.20%; tx processed max 7984.05 tx/s
- ibd_14: node disk write max 187.23 MB/s; device util max 100.30%; tx processed max 39029.47 tx/s; rocksdb compactions 367 stalls 6
- ibd_15: node disk write max 192.66 MB/s; device util max 100.10%; tx processed max 39960.08 tx/s; rocksdb compactions 220 stalls 0
- ibd_16: node disk write max 174.42 MB/s; device util max 100.00%; tx processed max 37695.52 tx/s; rocksdb compactions 93 stalls 0
- ibd_17: node disk write max 201.60 MB/s; device util max 100.10%; tx processed max 58147.49 tx/s; rocksdb compactions 67 stalls 0
- ibd_18: node disk write max 53.56 MB/s; device util max 81.70%; tx processed max 32051.54 tx/s; rocksdb compactions 25 stalls 0
- ibd_19: node disk write max 122.17 MB/s; device util max 40.70%; tx processed max 47856.86 tx/s; rocksdb compactions 13 stalls 0
- ibd_20: node disk write max 173.49 MB/s; device util max 100.10%; tx processed max 35821.07 tx/s; rocksdb compactions 80 stalls 0
- ibd_21: node disk write max 166.50 MB/s; device util max 100.10%; tx processed max 28750.74 tx/s; rocksdb compactions 38 stalls 6
- pruning_2: node disk write max 228.49 MB/s; device util max 102.10%; tx processed max 6099.01 tx/s; rocksdb compactions 834 stalls 12
- synced_7: node disk write max 228.49 MB/s; device util max 114.70%; tx processed max 58147.49 tx/s; rocksdb compactions 23755 stalls 420
