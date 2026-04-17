Run 7 rerun. Frozen failure note.

High-level read
- Smaller-box reference host.
- Survived IBD and prune overlap much longer than expected.
- Did not get a clean standalone `synced-stress` phase before prune.
- Stayed hot for hours after prune, but remained rougher than run 5.
- Final terminating event was kernel OOM.

Important shape
- Rerun phases present:
  - `run-007-devnet-ibd-2026-04-04T12-08-48Z`
  - `run-007-devnet-synced-stress-pruning-2026-04-04T12-08-48Z`
- No separate rerun `synced-stress` directory exists because the wrapper rolled straight from `ibd` into the prune run when prune started.
- Last prune-run RPC row:
  - `2026-04-05T20:07:06Z`
- Final prune-run row showed:
  - `rpc_ok=1`
  - `is_synced=0`
  - `active_peers=1`
  - `network_virtual_daa_score=3259135`
  - `node_database_blocks_count=1092699`
  - `info_mempool_size=664420`

Resource read
- `summary.md` shows the host operated much closer to the edge than run 5:
  - host CPU iowait p95/max `72.10% / 98.40%`
  - device write await p95/max `768.00 / 4308.00 ms`
  - device queue depth p95/max `13.60 / 110.35`
  - Node RSS max `10.60 GiB`
- This box had only `12 GiB` RAM, so there was very little headroom once memory climbed.
- Separate unloaded fio baseline, captured after the rerun ended with no `kaspad` running, was materially stronger than the weak Proxmox path from run 6:
  - sequential write `57.95 MB/s`
  - sequential read `1181.63 MB/s`
  - 4K random write `92.58 MB/s` (`22603.57 IOPS`)
  - 4K random read `199.35 MB/s` (`48668.82 IOPS`)
- That makes run 7 look less like a fundamentally weak idle-storage baseline problem and more like a small-box headroom problem under prolonged live prune/recovery churn.

Terminal event
- Kernel OOM kill confirmed in `oom-journal.txt`.
- See also `oom-evidence.md`.

Interpretation
- This is not a clean success case like run 5.
- It is also not the same failure profile as run 6.
- Best current read:
  - the smaller box could keep up for a surprisingly long time
  - but under the combined stress/recovery shape it eventually exhausted memory and died
  - this makes `4c/12 GiB` look possible in some cases, but too close to the edge to recommend
