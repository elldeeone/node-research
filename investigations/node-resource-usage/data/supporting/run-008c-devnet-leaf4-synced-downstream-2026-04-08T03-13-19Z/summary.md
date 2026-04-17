# Node Resource Summary

- Run: `run-008c-devnet-leaf4-synced-downstream-2026-04-08T03-13-19Z`
- Node samples: 81576
- Host samples: 75031
- RPC samples: 81733
- Duration seconds: 82052

## Highlights

- Node RSS max: 9.96 GiB
- Node CPU p95/max: 1.98 / 4.76
- Node disk read p95/max: 97.35 / 207.59 MB/s
- Node disk write p95/max: 168.21 / 483.72 MB/s
- Node FD max: 3675

## Host Derived

- Host CPU util p95/max: 27.53% / 58.18%
- Host CPU iowait p95/max: 3.48% / 12.71%
- Host disk read p95/max: 97.80 / 219.65 MB/s
- Host disk write p95/max: 176.31 / 444.59 MB/s
- Host disk read ops p95/max: 638.00 / 7684.00 ops/s
- Host disk write ops p95/max: 363.00 / 3981.00 ops/s
- Host disk read await p95/max: 0.71 / 2.05 ms
- Host disk write await p95/max: 3.28 / 11.24 ms
- Host disk queue depth p95/max: 1.35 / 9.03
- Host disk busy p95/max: 28.70% / 80.60%
- Storage used max: 114.31 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 127820.00 / 130747.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 4606.18 / 13204.39 tx/s
- P2P RX p95/max: 1.32 / 2.15 MB/s

## Iostat Derived

- Device util p95/max: 27.10% / 73.10%
- Device queue depth p95/max: 1.27 / 9.60
- Device read await p95/max: 0.71 / 2.50 ms
- Device write await p95/max: 3.27 / 59.50 ms
- Device read throughput p95/max: 94.90 / 205.32 MB/s
- Device write throughput p95/max: 161.57 / 437.06 MB/s

## RocksDB

- Event rows: 736321
- Compactions: 56155
- Flush starts: 10850
- Flush finishes: 10850
- Stall stats rows: 816
- Write stall rows: 697
- Compaction time p95/max: 0.57 / 2.79 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- pruning: node disk write max 367.39 MB/s; device util max 52.80%; tx processed max 6141.58 tx/s; rocksdb compactions 2178 stalls 6
- pruning_2: node disk write max 483.72 MB/s; device util max 49.90%; tx processed max 6135.46 tx/s; rocksdb compactions 2297 stalls 6
