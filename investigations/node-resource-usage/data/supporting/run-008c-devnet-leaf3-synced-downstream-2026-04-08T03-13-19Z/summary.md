# Node Resource Summary

- Run: `run-008c-devnet-leaf3-synced-downstream-2026-04-08T03-13-19Z`
- Node samples: 82238
- Host samples: 75952
- RPC samples: 82393
- Duration seconds: 82703

## Highlights

- Node RSS max: 10.67 GiB
- Node CPU p95/max: 1.93 / 3.75
- Node disk read p95/max: 98.43 / 271.42 MB/s
- Node disk write p95/max: 172.31 / 348.89 MB/s
- Node FD max: 3717

## Host Derived

- Host CPU util p95/max: 26.81% / 51.04%
- Host CPU iowait p95/max: 3.48% / 12.91%
- Host disk read p95/max: 98.72 / 269.25 MB/s
- Host disk write p95/max: 179.86 / 352.80 MB/s
- Host disk read ops p95/max: 684.00 / 6260.00 ops/s
- Host disk write ops p95/max: 368.00 / 4464.00 ops/s
- Host disk read await p95/max: 0.69 / 2.34 ms
- Host disk write await p95/max: 3.28 / 10.81 ms
- Host disk queue depth p95/max: 1.38 / 9.12
- Host disk busy p95/max: 28.70% / 79.50%
- Storage used max: 114.31 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 127818.00 / 132093.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 4606.18 / 12283.15 tx/s
- P2P RX p95/max: 1.31 / 2.14 MB/s

## Iostat Derived

- Device util p95/max: 27.20% / 74.00%
- Device queue depth p95/max: 1.31 / 8.78
- Device read await p95/max: 0.69 / 2.65 ms
- Device write await p95/max: 3.28 / 10.71 ms
- Device read throughput p95/max: 96.80 / 269.71 MB/s
- Device write throughput p95/max: 166.22 / 304.31 MB/s

## RocksDB

- Event rows: 736580
- Compactions: 55880
- Flush starts: 10935
- Flush finishes: 10935
- Stall stats rows: 822
- Write stall rows: 702
- Compaction time p95/max: 0.54 / 2.85 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- pruning: node disk write max 329.08 MB/s; device util max 56.40%; tx processed max 7055.78 tx/s; rocksdb compactions 2307 stalls 6
- pruning_2: node disk write max 283.05 MB/s; device util max 53.30%; tx processed max 6141.58 tx/s; rocksdb compactions 2254 stalls 6
