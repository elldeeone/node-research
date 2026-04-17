# Node Resource Summary

- Run: `run-008c-devnet-leaf1-synced-downstream-2026-04-08T03-13-19Z`
- Node samples: 82190
- Host samples: 76032
- RPC samples: 82335
- Duration seconds: 82650

## Highlights

- Node RSS max: 9.97 GiB
- Node CPU p95/max: 1.89 / 4.89
- Node disk read p95/max: 99.34 / 289.69 MB/s
- Node disk write p95/max: 174.04 / 456.52 MB/s
- Node FD max: 3727

## Host Derived

- Host CPU util p95/max: 26.06% / 66.12%
- Host CPU iowait p95/max: 3.46% / 12.00%
- Host disk read p95/max: 99.73 / 294.15 MB/s
- Host disk write p95/max: 181.73 / 460.28 MB/s
- Host disk read ops p95/max: 735.00 / 8600.00 ops/s
- Host disk write ops p95/max: 389.00 / 4475.00 ops/s
- Host disk read await p95/max: 0.58 / 4.84 ms
- Host disk write await p95/max: 4.04 / 14.81 ms
- Host disk queue depth p95/max: 1.64 / 10.01
- Host disk busy p95/max: 27.40% / 79.90%
- Storage used max: 119.58 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 127820.00 / 130579.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 4606.18 / 11976.07 tx/s
- P2P RX p95/max: 1.32 / 2.05 MB/s

## Iostat Derived

- Device util p95/max: 25.90% / 73.30%
- Device queue depth p95/max: 1.55 / 9.00
- Device read await p95/max: 0.58 / 5.41 ms
- Device write await p95/max: 4.02 / 14.81 ms
- Device read throughput p95/max: 97.18 / 280.86 MB/s
- Device write throughput p95/max: 167.23 / 437.88 MB/s

## RocksDB

- Event rows: 735919
- Compactions: 55534
- Flush starts: 10924
- Flush finishes: 10924
- Stall stats rows: 822
- Write stall rows: 702
- Compaction time p95/max: 0.57 / 2.68 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- pruning: node disk write max 456.52 MB/s; device util max 48.60%; tx processed max 6141.58 tx/s; rocksdb compactions 2145 stalls 6
- pruning_2: node disk write max 406.57 MB/s; device util max 46.20%; tx processed max 5828.69 tx/s; rocksdb compactions 2152 stalls 6
