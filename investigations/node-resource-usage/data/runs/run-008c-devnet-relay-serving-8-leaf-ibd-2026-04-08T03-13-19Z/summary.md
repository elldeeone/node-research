# Node Resource Summary

- Run: `run-008c-devnet-relay-serving-8-leaf-ibd-2026-04-08T03-13-19Z`
- Node samples: 91267
- Host samples: 84570
- RPC samples: 91304
- Duration seconds: 91778

## Highlights

- Node RSS max: 10.69 GiB
- Node CPU p95/max: 4.38 / 6.17
- Node disk read p95/max: 103.65 / 259.20 MB/s
- Node disk write p95/max: 169.55 / 364.58 MB/s
- Node FD max: 3668

## Host Derived

- Host CPU util p95/max: 56.36% / 91.65%
- Host CPU iowait p95/max: 3.44% / 38.04%
- Host disk read p95/max: 105.63 / 305.50 MB/s
- Host disk write p95/max: 176.60 / 362.86 MB/s
- Host disk read ops p95/max: 1369.00 / 6033.00 ops/s
- Host disk write ops p95/max: 390.00 / 1092.00 ops/s
- Host disk read await p95/max: 0.61 / 3.92 ms
- Host disk write await p95/max: 4.02 / 21.08 ms
- Host disk queue depth p95/max: 1.80 / 10.98
- Host disk busy p95/max: 28.90% / 80.40%
- Storage used max: 175.48 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 128440.00 / 130747.00
- Active peers p95/max: 9.00 / 9.00
- Node tx processed p95/max: 4606.18 / 14111.55 tx/s
- P2P RX p95/max: 3.03 / 7.84 MB/s

## Iostat Derived

- Device util p95/max: 27.20% / 72.70%
- Device queue depth p95/max: 1.71 / 11.14
- Device read await p95/max: 0.61 / 3.50 ms
- Device write await p95/max: 3.98 / 18.62 ms
- Device read throughput p95/max: 101.66 / 316.25 MB/s
- Device write throughput p95/max: 162.81 / 338.23 MB/s

## RocksDB

- Event rows: 813239
- Compactions: 61744
- Flush starts: 11950
- Flush finishes: 11950
- Stall stats rows: 918
- Write stall rows: 784
- Compaction time p95/max: 0.56 / 2.71 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- pruning: node disk write max 364.58 MB/s; device util max 50.90%; tx processed max 7055.78 tx/s; rocksdb compactions 2249 stalls 6
- pruning_2: node disk write max 292.66 MB/s; device util max 59.00%; tx processed max 6135.46 tx/s; rocksdb compactions 2253 stalls 6
