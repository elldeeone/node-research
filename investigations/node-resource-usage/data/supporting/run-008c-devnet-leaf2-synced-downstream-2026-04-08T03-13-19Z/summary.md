# Node Resource Summary

- Run: `run-008c-devnet-leaf2-synced-downstream-2026-04-08T03-13-19Z`
- Node samples: 82092
- Host samples: 75925
- RPC samples: 82244
- Duration seconds: 82545

## Highlights

- Node RSS max: 9.69 GiB
- Node CPU p95/max: 1.89 / 4.55
- Node disk read p95/max: 99.02 / 261.62 MB/s
- Node disk write p95/max: 174.99 / 529.35 MB/s
- Node FD max: 3715

## Host Derived

- Host CPU util p95/max: 25.91% / 61.25%
- Host CPU iowait p95/max: 3.53% / 16.18%
- Host disk read p95/max: 98.67 / 242.62 MB/s
- Host disk write p95/max: 182.04 / 459.65 MB/s
- Host disk read ops p95/max: 695.00 / 6173.00 ops/s
- Host disk write ops p95/max: 387.00 / 3410.00 ops/s
- Host disk read await p95/max: 0.69 / 2.63 ms
- Host disk write await p95/max: 3.33 / 29.00 ms
- Host disk queue depth p95/max: 1.45 / 9.91
- Host disk busy p95/max: 29.00% / 81.10%
- Storage used max: 119.98 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 127821.00 / 130579.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 4606.18 / 11964.14 tx/s
- P2P RX p95/max: 1.31 / 2.12 MB/s

## Iostat Derived

- Device util p95/max: 27.50% / 74.50%
- Device queue depth p95/max: 1.37 / 8.60
- Device read await p95/max: 0.69 / 3.21 ms
- Device write await p95/max: 3.30 / 29.00 ms
- Device read throughput p95/max: 96.16 / 220.63 MB/s
- Device write throughput p95/max: 168.41 / 452.86 MB/s

## RocksDB

- Event rows: 737279
- Compactions: 55497
- Flush starts: 10976
- Flush finishes: 10976
- Stall stats rows: 822
- Write stall rows: 702
- Compaction time p95/max: 0.55 / 2.61 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- pruning: node disk write max 529.35 MB/s; device util max 54.50%; tx processed max 6762.48 tx/s; rocksdb compactions 2238 stalls 6
- pruning_2: node disk write max 474.52 MB/s; device util max 49.10%; tx processed max 5834.50 tx/s; rocksdb compactions 2163 stalls 6
