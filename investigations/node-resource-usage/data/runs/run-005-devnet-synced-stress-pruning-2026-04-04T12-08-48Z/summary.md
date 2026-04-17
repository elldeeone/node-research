# Node Resource Summary

- Run: `run-005-devnet-synced-stress-pruning-2026-04-04T12-08-48Z`
- Node samples: 227627
- Host samples: 209397
- RPC samples: 227789
- Duration seconds: 228971

## Highlights

- Node RSS max: 10.66 GiB
- Node CPU p95/max: 1.95 / 4.94
- Node disk read p95/max: 88.88 / 327.26 MB/s
- Node disk write p95/max: 173.24 / 521.92 MB/s
- Node FD max: 3844

## Host Derived

- Host CPU util p95/max: 26.86% / 66.20%
- Host CPU iowait p95/max: 3.34% / 17.70%
- Host disk read p95/max: 89.83 / 295.12 MB/s
- Host disk write p95/max: 181.47 / 512.79 MB/s
- Host disk read ops p95/max: 567.00 / 8313.00 ops/s
- Host disk write ops p95/max: 393.00 / 2112.50 ops/s
- Host disk read await p95/max: 0.58 / 7.38 ms
- Host disk write await p95/max: 3.99 / 113.42 ms
- Host disk queue depth p95/max: 1.57 / 9.54
- Host disk busy p95/max: 26.90% / 103.80%
- Storage used max: 169.62 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 128442.00 / 131238.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 4601.59 / 15016.92 tx/s
- P2P RX p95/max: 1.41 / 6.19 MB/s

## Iostat Derived

- Device util p95/max: 25.40% / 96.40%
- Device queue depth p95/max: 1.48 / 9.12
- Device read await p95/max: 0.58 / 8.06 ms
- Device write await p95/max: 3.97 / 70.00 ms
- Device read throughput p95/max: 86.69 / 314.98 MB/s
- Device write throughput p95/max: 166.46 / 497.78 MB/s

## Separate fio Baseline

- Post-run unloaded baseline on the same Hetzner host, with no `kaspad` running:
  - sequential write `2918.16 MB/s`, `2918.16 IOPS`, mean completion latency `10.855 ms`
  - sequential read `3507.13 MB/s`, `3507.13 IOPS`, mean completion latency `9.023 ms`
  - 4K random write `235.59 MB/s`, `60309.86 IOPS`, mean completion latency `0.525 ms`
  - 4K random read `258.26 MB/s`, `66113.66 IOPS`, mean completion latency `0.479 ms`
- That unloaded baseline is strong, and this rerun stayed healthy through prune overlap, so run 5 remains the clean success reference rather than a storage-path failure case.

## RocksDB

- Event rows: 2025442
- Compactions: 146861
- Flush starts: 29681
- Flush finishes: 29681
- Stall stats rows: 2286
- Write stall rows: 1953
- Compaction time p95/max: 0.55 / 2.82 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- pruning: node disk write max 213.74 MB/s; device util max 59.10%; tx processed max 5215.14 tx/s; rocksdb compactions 649 stalls 0
- pruning_2: node disk write max 276.20 MB/s; device util max 62.90%; tx processed max 6129.35 tx/s; rocksdb compactions 682 stalls 0
- pruning_3: node disk write max 377.08 MB/s; device util max 52.70%; tx processed max 6749.00 tx/s; rocksdb compactions 2226 stalls 6
- pruning_4: node disk write max 381.63 MB/s; device util max 40.20%; tx processed max 6755.73 tx/s; rocksdb compactions 2241 stalls 6
- pruning_5: node disk write max 486.87 MB/s; device util max 42.90%; tx processed max 6135.46 tx/s; rocksdb compactions 2173 stalls 6
