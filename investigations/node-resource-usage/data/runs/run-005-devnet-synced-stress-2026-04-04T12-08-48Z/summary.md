# Node Resource Summary

- Run: `run-005-devnet-synced-stress-2026-04-04T12-08-48Z`
- Node samples: 17701
- Host samples: 16278
- RPC samples: 17714
- Duration seconds: 17804

## Highlights

- Node RSS max: 9.32 GiB
- Node CPU p95/max: 1.78 / 6.25
- Node disk read p95/max: 60.55 / 295.15 MB/s
- Node disk write p95/max: 177.50 / 573.88 MB/s
- Node FD max: 3647

## Host Derived

- Host CPU util p95/max: 24.83% / 85.06%
- Host CPU iowait p95/max: 2.79% / 8.00%
- Host disk read p95/max: 61.85 / 259.67 MB/s
- Host disk write p95/max: 185.84 / 530.55 MB/s
- Host disk read ops p95/max: 314.50 / 3997.00 ops/s
- Host disk write ops p95/max: 396.00 / 996.00 ops/s
- Host disk read await p95/max: 0.56 / 9.22 ms
- Host disk write await p95/max: 3.90 / 15.78 ms
- Host disk queue depth p95/max: 1.43 / 6.08
- Host disk busy p95/max: 22.70% / 51.60%
- Storage used max: 106.07 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 128420.00 / 130276.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 4601.59 / 101851.04 tx/s
- P2P RX p95/max: 1.41 / 12.95 MB/s

## Iostat Derived

- Device util p95/max: 21.39% / 56.30%
- Device queue depth p95/max: 1.34 / 9.77
- Device read await p95/max: 0.56 / 7.64 ms
- Device write await p95/max: 3.86 / 15.23 ms
- Device read throughput p95/max: 59.40 / 310.60 MB/s
- Device write throughput p95/max: 170.15 / 565.32 MB/s

## RocksDB

- Event rows: 142765
- Compactions: 9579
- Flush starts: 2168
- Flush finishes: 2168
- Stall stats rows: 180
- Write stall rows: 154
- Compaction time p95/max: 0.46 / 1.79 s
- Stall percent p95/max: 0.00 / 0.00%
