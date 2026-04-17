# Node Resource Summary

- Run: `run-008c-devnet-leaf4-ibd-2026-04-08T03-13-19Z`
- Node samples: 9521
- Host samples: 9055
- RPC samples: 9526
- Duration seconds: 9566

## Highlights

- Node RSS max: 8.24 GiB
- Node CPU p95/max: 5.68 / 6.27
- Node disk read p95/max: 259.32 / 484.52 MB/s
- Node disk write p95/max: 597.55 / 904.79 MB/s
- Node FD max: 3671

## Host Derived

- Host CPU util p95/max: 73.77% / 81.46%
- Host CPU iowait p95/max: 8.31% / 20.74%
- Host disk read p95/max: 266.51 / 432.91 MB/s
- Host disk write p95/max: 588.98 / 901.30 MB/s
- Host disk read ops p95/max: 1582.00 / 11686.00 ops/s
- Host disk write ops p95/max: 1095.00 / 1778.00 ops/s
- Host disk read await p95/max: 0.84 / 6.00 ms
- Host disk write await p95/max: 3.65 / 7.08 ms
- Host disk queue depth p95/max: 3.66 / 5.95
- Host disk busy p95/max: 42.40% / 71.50%
- Storage used max: 105.99 GiB

## Workload

- RPC synced p95/max: 0.00 / 1.00
- Network mempool p95/max: 0.00 / 0.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 67250.25 / 100514.97 tx/s
- P2P RX p95/max: 7.12 / 11.00 MB/s

## Iostat Derived

- Device util p95/max: 40.70% / 65.70%
- Device queue depth p95/max: 3.58 / 5.97
- Device read await p95/max: 0.84 / 5.00 ms
- Device write await p95/max: 3.69 / 10.91 ms
- Device read throughput p95/max: 255.68 / 474.86 MB/s
- Device write throughput p95/max: 563.50 / 856.44 MB/s

## RocksDB

- Event rows: 805854
- Compactions: 67018
- Flush starts: 9867
- Flush finishes: 9867
- Stall stats rows: 98
- Write stall rows: 85
- Compaction time p95/max: 0.54 / 2.04 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- ibd: node disk write max 821.46 MB/s; device util max 65.70%; tx processed max 64166.67 tx/s; rocksdb compactions 4521 stalls 12
