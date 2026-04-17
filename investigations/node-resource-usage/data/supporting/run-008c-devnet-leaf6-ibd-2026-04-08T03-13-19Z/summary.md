# Node Resource Summary

- Run: `run-008c-devnet-leaf6-ibd-2026-04-08T03-13-19Z`
- Node samples: 9273
- Host samples: 8853
- RPC samples: 9280
- Duration seconds: 9315

## Highlights

- Node RSS max: 7.82 GiB
- Node CPU p95/max: 5.67 / 6.26
- Node disk read p95/max: 270.68 / 512.40 MB/s
- Node disk write p95/max: 606.48 / 857.52 MB/s
- Node FD max: 3664

## Host Derived

- Host CPU util p95/max: 74.12% / 83.96%
- Host CPU iowait p95/max: 7.95% / 27.43%
- Host disk read p95/max: 277.48 / 469.87 MB/s
- Host disk write p95/max: 598.45 / 870.39 MB/s
- Host disk read ops p95/max: 1712.00 / 16128.00 ops/s
- Host disk write ops p95/max: 1119.00 / 1814.00 ops/s
- Host disk read await p95/max: 0.81 / 4.00 ms
- Host disk write await p95/max: 3.60 / 7.66 ms
- Host disk queue depth p95/max: 3.72 / 7.08
- Host disk busy p95/max: 43.00% / 54.00%
- Storage used max: 105.87 GiB

## Workload

- RPC synced p95/max: 0.00 / 1.00
- Network mempool p95/max: 0.00 / 0.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 68648.76 / 91384.62 tx/s
- P2P RX p95/max: 7.27 / 9.62 MB/s

## Iostat Derived

- Device util p95/max: 41.10% / 55.90%
- Device queue depth p95/max: 3.62 / 5.75
- Device read await p95/max: 0.81 / 4.00 ms
- Device write await p95/max: 3.65 / 7.66 ms
- Device read throughput p95/max: 267.49 / 466.78 MB/s
- Device write throughput p95/max: 572.95 / 835.40 MB/s

## RocksDB

- Event rows: 810742
- Compactions: 67372
- Flush starts: 9849
- Flush finishes: 9849
- Stall stats rows: 92
- Write stall rows: 80
- Compaction time p95/max: 0.52 / 2.10 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- ibd: node disk write max 721.96 MB/s; device util max 55.90%; tx processed max 61415.75 tx/s; rocksdb compactions 4457 stalls 6
