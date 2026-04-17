# Node Resource Summary

- Run: `run-008c-devnet-leaf6-synced-downstream-2026-04-08T03-13-19Z`
- Node samples: 81847
- Host samples: 75875
- RPC samples: 82006
- Duration seconds: 82312

## Highlights

- Node RSS max: 10.54 GiB
- Node CPU p95/max: 1.89 / 5.59
- Node disk read p95/max: 91.29 / 253.94 MB/s
- Node disk write p95/max: 171.91 / 563.84 MB/s
- Node FD max: 3694

## Host Derived

- Host CPU util p95/max: 26.32% / 64.15%
- Host CPU iowait p95/max: 3.21% / 10.98%
- Host disk read p95/max: 92.86 / 236.54 MB/s
- Host disk write p95/max: 178.83 / 456.70 MB/s
- Host disk read ops p95/max: 544.00 / 7092.00 ops/s
- Host disk write ops p95/max: 368.00 / 3158.00 ops/s
- Host disk read await p95/max: 0.68 / 3.22 ms
- Host disk write await p95/max: 3.23 / 10.00 ms
- Host disk queue depth p95/max: 1.27 / 8.12
- Host disk busy p95/max: 26.80% / 79.50%
- Storage used max: 114.42 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 127819.00 / 130748.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 4606.18 / 13217.56 tx/s
- P2P RX p95/max: 1.32 / 2.07 MB/s

## Iostat Derived

- Device util p95/max: 25.60% / 72.40%
- Device queue depth p95/max: 1.21 / 8.86
- Device read await p95/max: 0.68 / 2.65 ms
- Device write await p95/max: 3.22 / 11.00 ms
- Device read throughput p95/max: 89.51 / 264.73 MB/s
- Device write throughput p95/max: 165.10 / 529.46 MB/s

## RocksDB

- Event rows: 736368
- Compactions: 55888
- Flush starts: 10893
- Flush finishes: 10893
- Stall stats rows: 822
- Write stall rows: 702
- Compaction time p95/max: 0.55 / 2.84 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- pruning: node disk write max 499.46 MB/s; device util max 40.90%; tx processed max 7369.89 tx/s; rocksdb compactions 2290 stalls 6
- pruning_2: node disk write max 563.84 MB/s; device util max 41.90%; tx processed max 6141.58 tx/s; rocksdb compactions 2321 stalls 6
