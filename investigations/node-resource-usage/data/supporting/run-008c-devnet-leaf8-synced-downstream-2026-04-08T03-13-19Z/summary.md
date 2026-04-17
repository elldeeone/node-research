# Node Resource Summary

- Run: `run-008c-devnet-leaf8-synced-downstream-2026-04-08T03-13-19Z`
- Node samples: 81707
- Host samples: 75476
- RPC samples: 81860
- Duration seconds: 82170

## Highlights

- Node RSS max: 10.39 GiB
- Node CPU p95/max: 1.90 / 4.47
- Node disk read p95/max: 100.34 / 252.20 MB/s
- Node disk write p95/max: 171.96 / 306.60 MB/s
- Node FD max: 3675

## Host Derived

- Host CPU util p95/max: 26.37% / 58.39%
- Host CPU iowait p95/max: 3.33% / 11.41%
- Host disk read p95/max: 101.40 / 276.03 MB/s
- Host disk write p95/max: 179.29 / 327.56 MB/s
- Host disk read ops p95/max: 839.00 / 6817.00 ops/s
- Host disk write ops p95/max: 367.00 / 4366.00 ops/s
- Host disk read await p95/max: 0.56 / 1.93 ms
- Host disk write await p95/max: 3.70 / 14.03 ms
- Host disk queue depth p95/max: 1.48 / 9.05
- Host disk busy p95/max: 26.20% / 79.30%
- Storage used max: 114.38 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 127818.00 / 133012.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 4606.18 / 14111.55 tx/s
- P2P RX p95/max: 1.32 / 2.07 MB/s

## Iostat Derived

- Device util p95/max: 24.70% / 71.80%
- Device queue depth p95/max: 1.39 / 8.85
- Device read await p95/max: 0.56 / 1.98 ms
- Device write await p95/max: 3.67 / 14.41 ms
- Device read throughput p95/max: 98.20 / 242.55 MB/s
- Device write throughput p95/max: 165.19 / 342.83 MB/s

## RocksDB

- Event rows: 737120
- Compactions: 56446
- Flush starts: 10880
- Flush finishes: 10880
- Stall stats rows: 822
- Write stall rows: 702
- Compaction time p95/max: 0.56 / 2.88 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- pruning: node disk write max 306.60 MB/s; device util max 49.60%; tx processed max 7676.97 tx/s; rocksdb compactions 2309 stalls 6
- pruning_2: node disk write max 279.45 MB/s; device util max 51.30%; tx processed max 6735.59 tx/s; rocksdb compactions 2166 stalls 6
