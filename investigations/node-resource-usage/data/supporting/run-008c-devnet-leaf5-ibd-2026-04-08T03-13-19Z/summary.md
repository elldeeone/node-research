# Node Resource Summary

- Run: `run-008c-devnet-leaf5-ibd-2026-04-08T03-13-19Z`
- Node samples: 9226
- Host samples: 8778
- RPC samples: 9229
- Duration seconds: 9267

## Highlights

- Node RSS max: 7.46 GiB
- Node CPU p95/max: 5.63 / 6.16
- Node disk read p95/max: 267.51 / 566.93 MB/s
- Node disk write p95/max: 614.35 / 944.62 MB/s
- Node FD max: 3671

## Host Derived

- Host CPU util p95/max: 73.28% / 80.22%
- Host CPU iowait p95/max: 8.19% / 22.39%
- Host disk read p95/max: 275.42 / 575.09 MB/s
- Host disk write p95/max: 602.89 / 916.71 MB/s
- Host disk read ops p95/max: 1670.00 / 15372.00 ops/s
- Host disk write ops p95/max: 1109.00 / 1734.00 ops/s
- Host disk read await p95/max: 0.72 / 10.50 ms
- Host disk write await p95/max: 4.53 / 8.68 ms
- Host disk queue depth p95/max: 4.03 / 6.57
- Host disk busy p95/max: 38.60% / 56.20%
- Storage used max: 105.97 GiB

## Workload

- RPC synced p95/max: 0.00 / 1.00
- Network mempool p95/max: 0.00 / 0.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 71713.43 / 91293.41 tx/s
- P2P RX p95/max: 7.64 / 9.66 MB/s

## Iostat Derived

- Device util p95/max: 37.00% / 55.80%
- Device queue depth p95/max: 3.91 / 6.63
- Device read await p95/max: 0.74 / 15.00 ms
- Device write await p95/max: 4.56 / 7.99 ms
- Device read throughput p95/max: 263.86 / 522.36 MB/s
- Device write throughput p95/max: 578.89 / 857.14 MB/s

## RocksDB

- Event rows: 807795
- Compactions: 67044
- Flush starts: 9849
- Flush finishes: 9849
- Stall stats rows: 92
- Write stall rows: 80
- Compaction time p95/max: 0.53 / 2.06 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- ibd: node disk write max 750.36 MB/s; device util max 55.80%; tx processed max 78990.06 tx/s; rocksdb compactions 4458 stalls 6
