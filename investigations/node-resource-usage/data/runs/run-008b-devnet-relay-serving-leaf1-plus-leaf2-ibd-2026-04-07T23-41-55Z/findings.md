# Run 8b Findings

Run IDs:
- `run-008b-devnet-relay-serving-leaf1-plus-leaf2-ibd-2026-04-07T23-41-55Z`
- `run-008b-devnet-leaf2-ibd-2026-04-07T23-41-55Z`
- `run-008b-devnet-leaf2-synced-downstream-2026-04-07T23-41-55Z`

Question:
- how much extra relay load appears when one downstream node is already synced and a second downstream node begins a cold IBD
- whether that looks materially different from `8a`, where the relay only served one cold leaf

Primary references:
- `data/runs/run-008b-devnet-relay-serving-leaf1-plus-leaf2-ibd-2026-04-07T23-41-55Z/summary.md`
- `data/supporting/run-008b-devnet-leaf2-ibd-2026-04-07T23-41-55Z/summary.md`
- `data/supporting/run-008b-devnet-leaf2-ibd-2026-04-07T23-41-55Z/events.csv`
- `data/supporting/run-008b-devnet-leaf2-synced-downstream-2026-04-07T23-41-55Z/summary.md`
- `data/runs/run-008a-devnet-relay-serving-leaf1-ibd-2026-04-07T13-41-23Z/findings.md`
- `data/runs/run-005-devnet-synced-stress-2026-04-04T12-08-48Z/summary.md`

## Leaf2 Timing

Useful markers:
- run start: `2026-04-07T23:41:55Z`
- first RPC-synced sample: `2026-04-08T01:57:05Z`
- final log-side bulk catch-up marker: `2026-04-08T01:58:02.342+00:00`
- post-sync steady-state capture then continued for about `995s` in `run-008b-devnet-leaf2-synced-downstream-2026-04-07T23-41-55Z`
- no prune window occurred before wrap

IBD timing comparison:
- run 5 direct bootstrap IBD: `5097s` (`84m 57s`)
- run 8a leaf1 via relay: `8805s` (`146m 45s`) to final catch-up completion
- run 8b leaf2 via relay with leaf1 already synced: `8110s` (`135m 10s`) to first RPC synced sample

Read:
- leaf2 was still much slower than direct bootstrap sync, about `1.59x` slower than run 5
- but leaf2 was not materially slower than leaf1 in `8a`
- that suggests the cost of keeping leaf1 synced while leaf2 performs IBD is modest compared with the already-observed cost of relayed sync itself

## Relay During Leaf2 IBD

Using the relay window before leaf2 hit `is_synced=1` at `2026-04-08T01:57:05Z`:
- active peers sat at `3.0` throughout: bootstrap + leaf1 + leaf2
- node CPU avg rose to `1.98`; p95 `2.69`
- node RSS avg sat high at `7.39 GiB`; p95 `7.43 GiB`
- node read avg rose to `25.11 MB/s`; p95 `99.78 MB/s`
- node write avg was `28.59 MB/s`; p95 `170.55 MB/s`
- device util avg was `13.96%`; p95 `29.2%`
- device queue depth p95 was `1.92`
- device write await p95 was still tame at `3.83 ms`
- relay outbound P2P traffic averaged `6.35 MB/s`

Compared with `8a` during one cold downstream IBD:
- CPU avg `1.73 -> 1.98`
- node read avg `18.04 -> 25.11 MB/s`
- node write avg `26.86 -> 28.59 MB/s`
- device util avg `10.95% -> 13.96%`
- queue depth p95 `1.55 -> 1.92`
- write await p95 stayed essentially flat: `3.88 -> 3.83 ms`
- outbound P2P avg `5.20 -> 6.35 MB/s`

Read:
- adding leaf2 on top of one already-synced downstream clearly increased relay serve/read load
- the increase was real but still incremental, not a step-change into a failure shape
- most importantly, the storage write path still did not deteriorate in a meaningful way

Linearity read:
- relay load did not scale as a clean `2x` jump when leaf2 arrived
- the strongest movement was in serve/read traffic and CPU
- write-path pressure, write latency, and queue depth moved only modestly
- so `8b` looks like a moderate incremental increase, not proportional doubling and not a nonlinear saturation event

## Relay After Leaf2 Synced

Using the relay window after `2026-04-08T01:57:05Z`:
- active peers stayed at `3.0`
- node CPU avg fell from `1.98` to `1.51`
- node read avg fell from `25.11` to `10.88 MB/s`
- node write avg stayed near-flat: `28.59` to `28.08 MB/s`
- device util avg fell from `13.96%` to `6.17%`
- queue depth p95 fell from `1.92` to `1.50`
- write await p95 remained benign: `3.83 -> 3.92 ms`
- relay outbound P2P traffic fell from `6.35` to `1.84 MB/s`

Compared with `8a` after leaf1 IBD:
- relay remained a bit busier
- that makes sense: it now kept two synced downstream peers instead of one
- but it still looked close to ordinary synced-stress behavior rather than a distressed serving node

One thing that stayed high:
- relay RSS stayed around `7.4 GiB` before and after leaf2 sync
- this did not come with bad latency, queue blowout, or stall signals

## Boring Checks

Things that stayed boring in a good way:
- network mempool remained stable during leaf2 IBD
  - relay avg `126432`
  - relay post-sync avg `126532`
- active peers behaved exactly as intended
  - `3` during leaf2 IBD
  - `3` after leaf2 synced
- relay summary still shows no meaningful stall signal
  - RocksDB stall percent p95/max `0.00 / 0.00%`
  - host write await p95/max `3.90 / 9.75 ms`
  - device write await p95/max `3.84 / 9.75 ms`

Read:
- the relay did more work
- but it stayed well within a controlled operating shape

## Bottom Line

What run 8b showed:
- one synced downstream plus one cold downstream is measurably heavier than `8a`
- the extra cost lands mainly on relay reads, serve traffic, CPU, and memory footprint
- the write path still stayed healthy
- relay load rose with leaf2, but not linearly as a simple `2x` of the one-leaf case
- leaf2 sync time was still much slower than direct bootstrap sync, but not materially worse than `8a`
- that makes the already-synced leaf look like a modest incremental burden, not the dominant source of stress

What 8b did not show:
- no convincing nonlinear failure yet
- no prune-overlap evidence for this topology
- the key remaining question is still the simultaneous multi-leaf burst in the next run
