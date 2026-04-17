# Node Resource Summary

- Run: `run-008c-devnet-leaf7-synced-downstream-2026-04-08T03-13-19Z`
- Node samples: 82146
- Host samples: 75879
- RPC samples: 82290
- Duration seconds: 82603

## Highlights

- Node RSS max: 10.64 GiB
- Node CPU p95/max: 1.92 / 4.77
- Node disk read p95/max: 99.48 / 252.22 MB/s
- Node disk write p95/max: 170.73 / 402.38 MB/s
- Node FD max: 3670

## Host Derived

- Host CPU util p95/max: 26.60% / 59.88%
- Host CPU iowait p95/max: 3.59% / 11.02%
- Host disk read p95/max: 100.25 / 250.76 MB/s
- Host disk write p95/max: 178.37 / 453.28 MB/s
- Host disk read ops p95/max: 699.00 / 6631.00 ops/s
- Host disk write ops p95/max: 369.00 / 2581.00 ops/s
- Host disk read await p95/max: 0.63 / 2.05 ms
- Host disk write await p95/max: 4.16 / 150.75 ms
- Host disk queue depth p95/max: 1.65 / 10.32
- Host disk busy p95/max: 28.70% / 83.10%
- Storage used max: 114.46 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 127818.00 / 133012.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 4606.18 / 13204.39 tx/s
- P2P RX p95/max: 1.31 / 2.10 MB/s

## Iostat Derived

- Device util p95/max: 27.10% / 79.40%
- Device queue depth p95/max: 1.56 / 9.32
- Device read await p95/max: 0.63 / 2.11 ms
- Device write await p95/max: 4.14 / 150.75 ms
- Device read throughput p95/max: 97.43 / 242.10 MB/s
- Device write throughput p95/max: 163.62 / 432.33 MB/s

## RocksDB

- Event rows: 738672
- Compactions: 56277
- Flush starts: 10944
- Flush finishes: 10944
- Stall stats rows: 822
- Write stall rows: 702
- Compaction time p95/max: 0.56 / 2.74 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- pruning: node disk write max 402.38 MB/s; device util max 41.90%; tx processed max 6762.48 tx/s; rocksdb compactions 2217 stalls 6
- pruning_2: node disk write max 392.64 MB/s; device util max 55.00%; tx processed max 6442.23 tx/s; rocksdb compactions 2228 stalls 6
