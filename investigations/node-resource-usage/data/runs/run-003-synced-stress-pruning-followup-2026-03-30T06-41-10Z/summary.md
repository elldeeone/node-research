# Node Resource Summary

- Run: `run-003-synced-stress-pruning-followup-2026-03-30T06-41-10Z`
- Node samples: 12179
- Host samples: 11220
- RPC samples: 12205
- Duration seconds: 12249

## Highlights

- Node RSS max: 8.69 GiB
- Node CPU p95/max: 2.81 / 4.10
- Node disk read p95/max: 36.23 / 175.05 MB/s
- Node disk write p95/max: 170.89 / 278.31 MB/s
- Node FD max: 4175

## Host Derived

- Host CPU util p95/max: 37.08% / 54.18%
- Host CPU iowait p95/max: 2.54% / 10.06%
- Host disk read p95/max: 38.27 / 199.36 MB/s
- Host disk write p95/max: 174.11 / 338.34 MB/s
- Host disk read ops p95/max: 280.00 / 4430.00 ops/s
- Host disk write ops p95/max: 376.00 / 4217.00 ops/s
- Host disk read await p95/max: 0.68 / 5.02 ms
- Host disk write await p95/max: 4.37 / 24.78 ms
- Host disk queue depth p95/max: 1.40 / 7.67
- Host disk busy p95/max: 20.50% / 74.30%
- Storage used max: 82.28 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 48291.00 / 68372.00
- Active peers p95/max: 8.00 / 8.00
- Node tx processed p95/max: 4054.84 / 6750.00 tx/s
- P2P RX p95/max: 1.57 / 2.37 MB/s

## Iostat Derived

- Device util p95/max: 19.40% / 72.30%
- Device queue depth p95/max: 1.34 / 7.09
- Device read await p95/max: 0.68 / 5.04 ms
- Device write await p95/max: 4.33 / 24.78 ms
- Device read throughput p95/max: 36.29 / 183.94 MB/s
- Device write throughput p95/max: 162.64 / 292.13 MB/s

## RocksDB

- Event rows: 118731
- Compactions: 6487
- Flush starts: 2245
- Flush finishes: 2245
- Stall stats rows: 120
- Write stall rows: 103
- Compaction time p95/max: 0.90 / 2.45 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- pruning: node disk write max 255.71 MB/s; device util max 53.30%; tx processed max 6278.17 tx/s; rocksdb compactions 585 stalls 6
- boost: node disk write max 278.31 MB/s; device util max 34.20%; tx processed max 6750.00 tx/s; rocksdb compactions 5743 stalls 114
