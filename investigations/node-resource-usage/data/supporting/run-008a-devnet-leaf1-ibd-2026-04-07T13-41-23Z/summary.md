# Node Resource Summary

- Run: `run-008a-devnet-leaf1-ibd-2026-04-07T13-41-23Z`
- Node samples: 33127
- Host samples: 30924
- RPC samples: 0
- Duration seconds: 33358

## Highlights

- Node RSS max: 10.08 GiB
- Node CPU p95/max: 5.40 / 6.21
- Node disk read p95/max: 175.87 / 438.62 MB/s
- Node disk write p95/max: 462.63 / 861.93 MB/s
- Node FD max: 3694

## Host Derived

- Host CPU util p95/max: 70.30% / 83.67%
- Host CPU iowait p95/max: 6.71% / 17.47%
- Host disk read p95/max: 182.98 / 442.50 MB/s
- Host disk write p95/max: 450.67 / 911.70 MB/s
- Host disk read ops p95/max: 1442.00 / 10938.00 ops/s
- Host disk write ops p95/max: 873.00 / 1747.00 ops/s
- Host disk read await p95/max: 0.63 / 11.00 ms
- Host disk write await p95/max: 4.18 / 13.37 ms
- Host disk queue depth p95/max: 3.35 / 9.71
- Host disk busy p95/max: 35.10% / 78.80%
- Storage used max: 112.88 GiB

## Iostat Derived

- Device util p95/max: 33.40% / 72.30%
- Device queue depth p95/max: 3.20 / 8.38
- Device read await p95/max: 0.64 / 4.00 ms
- Device write await p95/max: 4.18 / 11.22 ms
- Device read throughput p95/max: 171.12 / 507.63 MB/s
- Device write throughput p95/max: 421.01 / 854.73 MB/s

## RocksDB

- Event rows: 1000007
- Compactions: 81204
- Flush starts: 12930
- Flush finishes: 12930
- Stall stats rows: 340
- Write stall rows: 293
- Compaction time p95/max: 0.52 / 2.40 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- ibd: node disk write max 761.06 MB/s; device util max 52.70%; rocksdb compactions 4126 stalls 6
- ibd_2: node disk write max 680.98 MB/s; device util max 50.40%; rocksdb compactions 280 stalls 0
- ibd_3: node disk write max 365.96 MB/s; device util max 37.90%; rocksdb compactions 19 stalls 0
- pruning: node disk write max 283.48 MB/s; device util max 50.80%; rocksdb compactions 2148 stalls 2
