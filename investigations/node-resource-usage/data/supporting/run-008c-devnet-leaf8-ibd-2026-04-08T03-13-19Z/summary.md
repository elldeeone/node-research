# Node Resource Summary

- Run: `run-008c-devnet-leaf8-ibd-2026-04-08T03-13-19Z`
- Node samples: 9424
- Host samples: 8962
- RPC samples: 9430
- Duration seconds: 9468

## Highlights

- Node RSS max: 7.71 GiB
- Node CPU p95/max: 5.65 / 6.16
- Node disk read p95/max: 280.61 / 456.60 MB/s
- Node disk write p95/max: 598.69 / 844.57 MB/s
- Node FD max: 3674

## Host Derived

- Host CPU util p95/max: 73.71% / 81.76%
- Host CPU iowait p95/max: 8.33% / 23.64%
- Host disk read p95/max: 286.65 / 470.73 MB/s
- Host disk write p95/max: 591.29 / 840.90 MB/s
- Host disk read ops p95/max: 2172.00 / 15384.00 ops/s
- Host disk write ops p95/max: 1116.00 / 1833.00 ops/s
- Host disk read await p95/max: 0.71 / 22.00 ms
- Host disk write await p95/max: 4.25 / 11.38 ms
- Host disk queue depth p95/max: 4.11 / 8.12
- Host disk busy p95/max: 39.20% / 59.90%
- Storage used max: 105.98 GiB

## Workload

- RPC synced p95/max: 0.00 / 1.00
- Network mempool p95/max: 0.00 / 0.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 66503.48 / 91293.41 tx/s
- P2P RX p95/max: 7.02 / 9.66 MB/s

## Iostat Derived

- Device util p95/max: 37.60% / 56.20%
- Device queue depth p95/max: 4.06 / 9.02
- Device read await p95/max: 0.71 / 22.00 ms
- Device write await p95/max: 4.27 / 11.38 ms
- Device read throughput p95/max: 274.09 / 448.83 MB/s
- Device write throughput p95/max: 563.69 / 782.31 MB/s

## RocksDB

- Event rows: 804390
- Compactions: 66923
- Flush starts: 9859
- Flush finishes: 9859
- Stall stats rows: 92
- Write stall rows: 80
- Compaction time p95/max: 0.56 / 2.15 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- ibd: node disk write max 750.25 MB/s; device util max 56.20%; tx processed max 71928.14 tx/s; rocksdb compactions 4564 stalls 6
