# Node Resource Summary

- Run: `run-008a-devnet-relay-serving-leaf1-ibd-2026-04-07T13-41-23Z`
- Node samples: 33167
- Host samples: 30551
- RPC samples: 33189
- Duration seconds: 33358

## Highlights

- Node RSS max: 6.90 GiB
- Node CPU p95/max: 2.41 / 4.88
- Node disk read p95/max: 75.16 / 212.12 MB/s
- Node disk write p95/max: 178.50 / 414.72 MB/s
- Node FD max: 3648

## Host Derived

- Host CPU util p95/max: 32.49% / 71.16%
- Host CPU iowait p95/max: 3.25% / 10.39%
- Host disk read p95/max: 75.94 / 225.45 MB/s
- Host disk write p95/max: 186.63 / 466.06 MB/s
- Host disk read ops p95/max: 575.00 / 5207.00 ops/s
- Host disk write ops p95/max: 415.00 / 1038.00 ops/s
- Host disk read await p95/max: 0.57 / 2.42 ms
- Host disk write await p95/max: 4.05 / 10.67 ms
- Host disk queue depth p95/max: 1.63 / 8.33
- Host disk busy p95/max: 25.60% / 76.70%
- Storage used max: 172.96 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 128428.00 / 130291.00
- Active peers p95/max: 2.00 / 2.00
- Node tx processed p95/max: 4601.59 / 7976.10 tx/s
- P2P RX p95/max: 1.53 / 6.01 MB/s

## Iostat Derived

- Device util p95/max: 24.30% / 69.60%
- Device queue depth p95/max: 1.53 / 7.78
- Device read await p95/max: 0.57 / 2.31 ms
- Device write await p95/max: 4.06 / 11.61 ms
- Device read throughput p95/max: 73.40 / 210.44 MB/s
- Device write throughput p95/max: 171.13 / 436.27 MB/s

## RocksDB

- Event rows: 298726
- Compactions: 23018
- Flush starts: 4476
- Flush finishes: 4476
- Stall stats rows: 330
- Write stall rows: 281
- Compaction time p95/max: 0.54 / 2.27 s
- Stall percent p95/max: 0.00 / 0.00%

## Event Windows

- pruning: node disk write max 414.72 MB/s; device util max 46.30%; tx processed max 6403.96 tx/s; rocksdb compactions 2131 stalls 6
