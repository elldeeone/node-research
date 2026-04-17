# Node Resource Summary

- Run: `run-008c-devnet-leaf5-synced-downstream-2026-04-08T03-13-19Z`
- Node samples: 81882
- Host samples: 75298
- RPC samples: 82042
- Duration seconds: 82357

## Highlights

- Node RSS max: 10.52 GiB
- Node CPU p95/max: 1.98 / 4.87
- Node disk read p95/max: 99.13 / 218.67 MB/s
- Node disk write p95/max: 170.28 / 433.22 MB/s
- Node FD max: 3672

## Host Derived

- Host CPU util p95/max: 27.54% / 62.30%
- Host CPU iowait p95/max: 3.37% / 10.93%
- Host disk read p95/max: 98.77 / 234.10 MB/s
- Host disk write p95/max: 178.63 / 389.18 MB/s
- Host disk read ops p95/max: 718.00 / 7269.00 ops/s
- Host disk write ops p95/max: 362.00 / 4313.00 ops/s
- Host disk read await p95/max: 0.58 / 2.35 ms
- Host disk write await p95/max: 3.84 / 11.59 ms
- Host disk queue depth p95/max: 1.50 / 9.79
- Host disk busy p95/max: 26.80% / 79.10%
- Storage used max: 114.35 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 127818.00 / 130747.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 4606.18 / 12871.64 tx/s
- P2P RX p95/max: 1.32 / 2.12 MB/s

## Iostat Derived

- Device util p95/max: 25.20% / 72.10%
- Device queue depth p95/max: 1.42 / 9.10
- Device read await p95/max: 0.58 / 2.71 ms
- Device write await p95/max: 3.83 / 11.44 ms
- Device read throughput p95/max: 97.04 / 214.06 MB/s
- Device write throughput p95/max: 163.55 / 356.64 MB/s

## RocksDB

- Event rows: 739586
- Compactions: 56259
- Flush starts: 10882
- Flush finishes: 10882
- Stall stats rows: 822
- Write stall rows: 702
- Compaction time p95/max: 0.57 / 2.83 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- pruning: node disk write max 433.22 MB/s; device util max 50.40%; tx processed max 7369.89 tx/s; rocksdb compactions 2193 stalls 6
- pruning_2: node disk write max 375.90 MB/s; device util max 51.60%; tx processed max 6135.46 tx/s; rocksdb compactions 2220 stalls 6
