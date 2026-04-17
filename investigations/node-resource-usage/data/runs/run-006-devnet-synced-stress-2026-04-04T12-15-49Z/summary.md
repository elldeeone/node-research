# Node Resource Summary

- Run: `run-006-devnet-synced-stress-2026-04-04T12-15-49Z`
- Node samples: 8107
- Host samples: 7625
- RPC samples: 7891
- Duration seconds: 13188

## Highlights

- Node RSS max: 24.71 GiB
- Node CPU p95/max: 5.52 / 6.43
- Node disk read p95/max: 33.27 / 495.16 MB/s
- Node disk write p95/max: 65.61 / 182.49 MB/s
- Node FD max: 3655

## Host Derived

- Host CPU util p95/max: 46.57% / 54.68%
- Host CPU iowait p95/max: 45.72% / 89.07%
- Host disk read p95/max: 24.86 / 6929.22 MB/s
- Host disk write p95/max: 59.79 / 92.22 MB/s
- Host disk read ops p95/max: 394.00 / 87222.81 ops/s
- Host disk write ops p95/max: 118.00 / 9334.00 ops/s
- Host disk read await p95/max: 25.97 / 1364.50 ms
- Host disk write await p95/max: 94.90 / 990.64 ms
- Host disk queue depth p95/max: 13.27 / 628.22
- Host disk busy p95/max: 90.90% / 2335.69%
- Storage used max: 99.38 GiB

## Workload

- RPC synced p95/max: 1.00 / 1.00
- Network mempool p95/max: 176237.00 / 220629.00
- Active peers p95/max: 1.00 / 1.00
- Node tx processed p95/max: 4303.39 / 42069.79 tx/s
- P2P RX p95/max: 2.25 / 5.58 MB/s

## Iostat Derived

- Device util p95/max: 88.00% / 123.00%
- Device queue depth p95/max: 12.98 / 62.84
- Device read await p95/max: 25.87 / 1478.00 ms
- Device write await p95/max: 92.05 / 929.33 ms
- Device read throughput p95/max: 24.90 / 349.76 MB/s
- Device write throughput p95/max: 56.74 / 83.33 MB/s

## RocksDB

- Event rows: 42845
- Compactions: 3289
- Flush starts: 582
- Flush finishes: 582
- Stall stats rows: 132
- Write stall rows: 86
- Compaction time p95/max: 6.75 / 20.03 s
- Stall percent p95/max: 1.60 / 1.80%

## Event Windows

- synced: node disk write max 71.45 MB/s; device util max 97.10%; tx processed max 0.00 tx/s
- synced_2: node disk write max 182.49 MB/s; device util max 100.00%; tx processed max 42069.79 tx/s
- ibd: node disk write max 182.49 MB/s; device util max 96.90%; tx processed max 42069.79 tx/s
- ibd_2: node disk write max 151.06 MB/s; device util max 96.60%; tx processed max 28894.21 tx/s

## Archival Note

- This run ended in a post-prune recovery failure after the node fell behind under sustained load.
- Final kill cause is now proven by host system logs: kernel OOM kill of `kaspad` at `2026-04-05 08:24:14 AEST`.
- For a host-side narrative and raw host logs, see `failure-note.md` and `node-perf-logs/`.
- For the preserved system-journal excerpt proving the kill mechanism, see `oom-evidence.md`.
- For unloaded storage context on the same `10.0.3.27` Proxmox SSD-backed path, see `run-004-devnet-bootstrap-ibd-contention-manual-2026-04-01T23-38-35Z`.
- That cross-reference matters because the run still reads like a storage-limited recovery failure on an older SSD-backed path, even though the final terminating event was OOM once RSS ballooned in the stuck state.
