## Run 6 Failure Note

Host:
- old local VM DUT
- `ubuntu@10.0.3.27`

Observed shape:
- synced successfully
- prune completed successfully
- then stopped making chain progress around `2026-04-05 05:13:46 AEST`
- stayed alive but flatlined: `is_synced=0`, DAA fixed `2406862`, DB blocks fixed `1104448`, mempool fixed `151388`
- RSS kept climbing into the `24-26 GiB` range
- later degraded into heavy read-side disk pressure, RPC timeouts, P2P relay timeouts, and eventual OOM kill

Important evidence:
- prune completion markers are present in `kaspad.log`
- host-side `node-perf-logs/devnet-kaspad.log` shows explicit `Resyncing the utxoindex...` lines earlier in the run
- kernel/system journal evidence now proves the final kill mechanism:
  - `2026-04-05 08:24:14 AEST`
  - `Out of memory: Killed process 1297859 (kaspad)`
  - `anon-rss: 25891448kB`
  - `session-689.scope: A process of this unit has been killed by the OOM killer.`
- see `oom-evidence.md` for the preserved excerpt
- this makes the run consistent with a two-stage failure:
  - storage-limited prune / recovery trouble first
  - then memory ballooning while stuck
  - final termination by kernel OOM kill

Storage baseline context:
- this VM is on Proxmox local SSD storage, not HDD
- see `run-004-devnet-bootstrap-ibd-contention-manual-2026-04-01T23-38-35Z` for the same `10.0.3.27` storage path under no-`kaspad` fio testing
- that baseline showed a notably weak write side for an SSD-backed path:
  - sequential write about `48.58 MB/s`
  - random write `4 KiB` about `6.63 MB/s`
- taken together with run 6, the more accurate read is:
  - not HDD-specific failure
  - likely storage-limited recovery failure on an older SSD-backed path after the node fell behind near prune
  - with the final death delivered by OOM once RSS ballooned in the stuck state

What is not proven:
- exact late-stage trigger
- direct proof that a fresh `utxoindex.resync()` invocation caused the late-stage memory growth
- exact code path that made RSS continue climbing after progress stopped

Best short read:
- strong evidence of post-prune recovery failure under sustained load
- strong alignment with IzioDev's broader hypothesis
- final kill mechanism now proven as OOM
- not airtight proof of identical root cause or exact code path
