# Node Resource Summary

- Run: `run-006-devnet-ibd-2026-04-04T12-15-49Z`
- Node samples: 22875
- Host samples: 22161
- RPC samples: 22771
- Duration seconds: 23232

## Highlights

- Node RSS max: 10.86 GiB
- Node CPU p95/max: 2.32 / 5.89
- Node disk read p95/max: 29.27 / 63.72 MB/s
- Node disk write p95/max: 94.08 / 259.36 MB/s
- Node FD max: 3655

## Host Derived

- Host CPU util p95/max: 19.98% / 51.94%
- Host CPU iowait p95/max: 54.11% / 91.35%
- Host disk read p95/max: 29.75 / 63.98 MB/s
- Host disk write p95/max: 75.55 / 149.52 MB/s
- Host disk read ops p95/max: 353.00 / 3490.00 ops/s
- Host disk write ops p95/max: 153.00 / 483.00 ops/s
- Host disk read await p95/max: 55.74 / 4551.00 ms
- Host disk write await p95/max: 206.96 / 4293.70 ms
- Host disk queue depth p95/max: 25.63 / 465.53
- Host disk busy p95/max: 97.30% / 146.10%
- Storage used max: 97.53 GiB

## Workload

- RPC synced p95/max: 0.00 / 1.00
- Network mempool p95/max: 0.00 / 0.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 30093.72 / 56809.57 tx/s
- P2P RX p95/max: 3.55 / 6.44 MB/s

## Iostat Derived

- Device util p95/max: 92.30% / 108.70%
- Device queue depth p95/max: 24.74 / 462.07
- Device read await p95/max: 56.38 / 4551.00 ms
- Device write await p95/max: 205.10 / 6221.33 ms
- Device read throughput p95/max: 29.06 / 62.01 MB/s
- Device write throughput p95/max: 69.76 / 142.65 MB/s

## RocksDB

- Event rows: 324576
- Compactions: 27663
- Flush starts: 5062
- Flush finishes: 5062
- Stall stats rows: 236
- Write stall rows: 204
- Compaction time p95/max: 8.29 / 152.66 s
- Stall percent p95/max: 6.30 / 39.00%

## Event Windows

- ibd: node disk write max 219.28 MB/s; device util max 101.70%; tx processed max 52764.94 tx/s
- ibd_2: node disk write max 145.00 MB/s; device util max 100.10%; tx processed max 49132.60 tx/s
- ibd_3: node disk write max 126.51 MB/s; device util max 100.10%; tx processed max 56809.57 tx/s
