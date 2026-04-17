# Run 8a Findings

Run IDs:
- `run-008a-devnet-relay-serving-leaf1-ibd-2026-04-07T13-41-23Z`
- `run-008a-devnet-leaf1-ibd-2026-04-07T13-41-23Z`

Question:
- how much extra load lands on a healthy non-bootstrap relay node while it serves one cold downstream IBD
- whether that materially changes the current Hetzner sizing story from run 5

Primary references:
- `data/runs/run-008a-devnet-relay-serving-leaf1-ibd-2026-04-07T13-41-23Z/summary.md`
- `data/supporting/run-008a-devnet-leaf1-ibd-2026-04-07T13-41-23Z/summary.md`
- `data/supporting/run-008a-devnet-leaf1-ibd-2026-04-07T13-41-23Z/events.csv`
- `data/runs/run-005-devnet-ibd-2026-04-04T12-08-48Z/summary.md`
- `data/runs/run-005-devnet-synced-stress-2026-04-04T12-08-48Z/summary.md`

## Leaf Timing

Important caveat:
- leaf1 `rpc-poller` failed with an exec-format error
- leaf phase timing therefore comes from `kaspad.log` / `events.csv`, not `rpc-metrics.csv`

Useful markers:
- run start: `2026-04-07T13:41:23Z`
- bulk IBD completion: `2026-04-07T15:58:21.489+00:00`
- final short catch-up completion: `2026-04-07T16:08:08.257+00:00`
- prune start: `2026-04-07T18:32:32.867+00:00`
- prune end: `2026-04-07T18:40:53.570+00:00`

IBD timing comparison:
- run 5 direct bootstrap IBD: `5097s` (`84m 57s`)
- run 8a leaf1 bulk IBD via relay: `8218s` (`136m 58s`)
- run 8a leaf1 final catch-up via relay: `8805s` (`146m 45s`)
- relay-fed leaf1 was therefore about `1.61x` slower on the bulk completion point and about `1.73x` slower on the final completion point

Read:
- relay serving did not appear to endanger the relay
- but it does appear to slow downstream sync time materially versus direct bootstrap sync on the same host class

## Relay During Leaf IBD

Compared with run 5 synced-stress baseline:
- node CPU avg rose from `1.09` to `1.73`; p95 from `1.78` to `2.44`
- node read avg rose from `8.00` to `18.04 MB/s`; p95 from `57.74` to `71.51 MB/s`
- node write avg was almost unchanged: `26.05` to `26.86 MB/s`; p95 stayed essentially flat: `169.27` to `169.03 MB/s`
- device util avg rose from `5.39%` to `10.95%`; p95 from `21.36%` to `25.8%`
- device queue depth p95 rose only slightly: `1.34` to `1.55`
- device write await p95 was unchanged in practice: `3.86` to `3.88 ms`
- relay outbound P2P traffic rose sharply while serving the leaf:
  - run 5 baseline avg `0.12 MB/s`
  - run 8a during IBD avg `5.20 MB/s`

Read:
- the main relay cost of one cold downstream IBD is extra serving traffic, extra reads, and some extra CPU
- the write path did not degrade meaningfully
- no sign that one cold leaf pushed this Hetzner box into a storage-failure shape

## Relay After Leaf IBD

Using the clean window after final catch-up and before prune:
- node CPU avg fell from `1.73` during leaf IBD to `1.37`
- node read avg fell from `18.04` to `8.15 MB/s`, almost exactly back at the run 5 baseline `8.00 MB/s`
- node write avg stayed almost flat: `26.86` to `27.19 MB/s`
- device util avg fell from `10.95%` to `4.95%`, essentially baseline territory
- device queue depth p95 fell from `1.55` to `1.40`
- device write await p95 stayed benign: `3.88` to `3.93 ms`
- relay outbound P2P traffic collapsed from `5.20 MB/s` during IBD to `0.85 MB/s` after IBD

One thing that did not fall back:
- node RSS stayed higher after IBD than during it
  - during IBD avg `3.58 GiB`
  - post-IBD pre-prune avg `4.67 GiB`
- this higher memory footprint did not come with worse disk latency or queue growth

Read:
- once the downstream node finished IBD, the relay mostly returned to ordinary synced-stress behavior
- persistent cost looked more like extra memory footprint plus the extra live peer, not sustained storage distress

## Relay During Downstream Prune

Prune window on relay:
- node CPU avg `2.86`
- node write avg `167.12 MB/s`; p95 `216.61 MB/s`
- device util avg `26.74%`; max `46.3%`
- device queue depth avg `1.76`; p95 `2.60`
- device write await avg `4.15 ms`; p95 `5.85 ms`
- active peers stayed `2`

Read:
- downstream prune clearly adds work
- but even here the relay remained well-controlled
- no severe queue blowout
- no bad write-await spike
- no sync loss

## Boring Checks

Things that stayed boring in a good way:
- active peers behaved exactly as intended:
  - run 5 baseline avg `1.0`
  - run 8a during / after / prune avg `2.0`
- network mempool stayed basically unchanged:
  - run 5 baseline avg `126201`
  - run 8a during leaf IBD avg `126331`
  - run 8a post-IBD pre-prune avg `126297`
  - run 8a prune avg `126551`

Read:
- the relay topology changed
- the workload on the mempool did not change in any surprising way

## Bottom Line

What run 8a showed:
- one cold downstream IBD does add real relay load
- the added load is mostly read/serve/CPU, not a major write-path regression
- on this Hetzner `cpx42` class box, one downstream cold leaf does not materially change the node-survival story
- after leaf IBD completes, relay behavior mostly returns toward the run 5 synced baseline
- the strongest new signal from 8a is not relay instability; it is that relay-fed downstream sync is materially slower than direct bootstrap sync

What 8a did not answer:
- whether two concurrent cold leaves create nonlinear storage pressure on the relay
- that remains the key question for `8b` / `8c`
