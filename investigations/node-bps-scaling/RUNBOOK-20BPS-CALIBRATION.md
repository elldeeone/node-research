# 20 BPS Calibration Runbook

## Purpose

This runbook is the first live execution step for `node-bps-scaling`.

The goal is to validate the `20 BPS` tier before any long capture begins:

- confirm the custom params load cleanly
- confirm the bootstrap can sustain the intended devnet load
- confirm the relay can stay current against the bootstrap
- confirm the separated topology still works under the new tier
- fill the `20bps` row in `data/manifests/tier-validation-register.csv`

This runbook is intentionally conservative about tooling:

- reuse the existing devnet miner and tx-generation workflow from the original investigation
- reuse the shared capture tooling under `shared/`
- do not invent a parallel one-off test harness for this study unless the existing workflow is proven unusable

## Scope

This document started as the calibration runbook, but it now also records the locked profile for the first proper `20 BPS Baseline` run.

Current status:

- `20 BPS` is baseline-ready
- the relay baseline can start on the locked profile below
- downstream smoke is still pending and should be completed before `Single-Downstream` and `Eight-Downstream`

Recommended calibration shape:

- bootstrap and relay both use the same `20bps.override.json`
- relay is the node we inspect most closely
- one downstream leaf is enough as a topology smoke test, but it should be provisioned only after tx generation is already running
- target load is about `6k TPS`
- run long enough to verify cadence, sync health, and basic stability

## Locked 20 BPS Launch Profile

The current canonical `20 BPS` profile is:

- bootstrap miner: `-t 2` during active load windows
- helper miner on `10.0.4.10`: `-t 1`
- txgen host: `10.0.4.10`
- txgen wallet: `Wallet B`
- mining wallet: `Wallet A`
- txgen backpressure flags:
  - `--max-inflight 6000`
  - `--client-pool-size 8`
  - `--mempool-high-watermark 650000`
  - `--mempool-resume-watermark 450000`
  - `--timeout-cooldown-ms 2000`

Observed outcome from the best calibration pass:

- bootstrap: `20.44 BPS`
- relay: `20.43 BPS`
- overall processed load: `~5726 tx/s`
- active txgen phases held near `6k`
- relay RSS max: `5.49 GiB`
- no relay OOM

Interpretation:

- txgen uses mempool backpressure rather than brute-force submit storms
- the node keeps processing backlog while txgen is paused at the high watermark
- the first proper `Baseline` run should reuse this exact profile unless a new blocker appears

## Inputs

- candidate params file:
  - `investigations/node-bps-scaling/configs/generated/20bps.override.json`
- validation register row:
  - `20bps` in `investigations/node-bps-scaling/data/manifests/tier-validation-register.csv`
- optional Hetzner provisioning helper:
  - initial bootstrap + relay only:
    - `investigations/node-bps-scaling/scripts/hcloud-provision.sh --tier 20bps --profile calibration --bootstrap-wan-cidr "$BOOTSTRAP_WAN_CIDR"`
  - later leaf-only add-on:
    - `investigations/node-bps-scaling/scripts/hcloud-provision.sh --tier 20bps --profile leaf1`

## Bootstrap Public RPC Policy

The helper host on your WAN must reach the bootstrap directly over the public internet.

Do not depend on an ad hoc SSH tunnel for the official run path.

The intended setup is:

- bootstrap `kaspad` listens for gRPC on `0.0.0.0:16110`
- Hetzner firewall rules allow that gRPC port only from your WAN CIDR
- the same allowlist can also gate SSH to the bootstrap
- relay and leaves still use the Hetzner private network for node-to-node traffic

Operational rule:

- helper `10.0.4.10` talks to `grpc://$BOOTSTRAP_RPC_PUBLIC_HOST:$BOOTSTRAP_RPC_PUBLIC_PORT`
- bootstrap and relay local collectors still use loopback RPC on their own hosts
- no SSH tunnel is part of the baseline runbook
- if your WAN CIDR changes, rebuild the managed bootstrap firewall before the next run

## Assumptions

- bootstrap and relay are on separate hosts
- the bootstrap side reuses the known-good miner and tx-generation workflow from the original investigation
- the relay host is the `CPX42` reference box
- all nodes use Rusty Kaspa with `--utxoindex`
- RPC remains on the default gRPC port unless you intentionally change it

## Bootstrap Wallet Staging

For a brand-new devnet, do not start the tx generator immediately.

Recommended wallet flow for a fresh network:

- `Wallet A`: first staged wallet; mine into it until it reaches the desired mature-UTXO band
- `Wallet B`: second wallet used after the first cutover, either for continued mining or later tx generation depending on which wallet ends up with the better runway and scan behavior

Recommended sequence:

1. start the bootstrap node
2. generate `Wallet A`
3. point the miner at `Wallet A`
4. leave tx generation off while `Wallet A` accumulates mature coinbase UTXOs
5. once `Wallet A` reaches the chosen mature-UTXO threshold, stop the miner
6. switch the miner to `Wallet B`
7. evaluate which wallet is the better txgen candidate once both wallets have real inventory
8. reserve the better txgen wallet for tx generation and use the other one for ongoing mining
9. if the chosen mining wallet later needs more runway, stop tx generation, top it back up, and cut over again

Practical sizing note for `20 BPS`:

- miner-only warmup creates about one new coinbase UTXO per block
- `20 BPS` for two hours is about `144,000` blocks total
- after coinbase maturity, that gives a roughly `120k-140k` mature-UTXO staging window
- that is enough for an initial smoke check, but it is not the preferred steady-state handoff target for this calibration

This lines up closely with the current modified `Tx_gen` default inventory rule:

- `target_utxo_count = target_tps * 10`
- at `6,000 TPS`, the default target inventory is `60,000` UTXOs

Preferred handoff band for this investigation:

- do not promote a txgen wallet until it reaches roughly `300k-500k` mature UTXOs
- if it starts below that band, mine into it longer before the first real cutover
- if it falls back below that band later, pause tx generation and top the mining wallet back up before switching again

Operational preference:

- prefer controlled miner top-ups into the current mining wallet over large `Tx_gen --prepare-only` expansion stages
- avoid promoting a very large long-running mining wallet directly into tx generation duty without first checking wallet-scan latency

## Variables

Replace these values before running:

```bash
TIER_SLUG=20bps
TIER_LABEL="20 BPS"
OVERRIDE_FILE=/absolute/path/to/20bps.override.json

BOOTSTRAP_HOST=bootstrap.example
BOOTSTRAP_P2P=${BOOTSTRAP_HOST}:16111
BOOTSTRAP_RPC_LOCAL=127.0.0.1:16110
BOOTSTRAP_RPC_PUBLIC_HOST=bootstrap-public-ip.example
BOOTSTRAP_RPC_PUBLIC_PORT=16110
BOOTSTRAP_WAN_CIDR=203.0.113.10/32
BOOTSTRAP_DATA=/var/lib/kaspa-bootstrap-20bps
BOOTSTRAP_MINER_THREADS_ACTIVE=2
BOOTSTRAP_MINER_THREADS_STANDBY=3

RELAY_HOST=relay.example
RELAY_P2P=${RELAY_HOST}:16111
RELAY_RPC=127.0.0.1:16110
RELAY_DATA=/var/lib/kaspa-relay-20bps

HELPER_HOST=10.0.4.10
HELPER_MINER_THREADS=1
HELPER_BOOTSTRAP_RPC_URL="grpc://${BOOTSTRAP_RPC_PUBLIC_HOST}:${BOOTSTRAP_RPC_PUBLIC_PORT}"

LEAF1_HOST=leaf1.example
LEAF1_DATA=/var/lib/kaspa-leaf1-20bps
```

If any nodes are co-located on the same host, you must change `--listen` and `--rpclisten` ports to avoid collisions.

## Required Kaspad Monitoring Flags

For any node you want to capture with `shared/collectors/run-capture.sh`, keep these flags enabled:

```bash
--utxoindex
--perf-metrics
--perf-metrics-interval-sec=1
--loglevel=info,kaspad_lib::daemon=debug,kaspa_mining::monitor=debug
```

The collector can also print them directly:

```bash
shared/collectors/run-capture.sh --print-kaspad-flags
```

## Step 1. Copy The Tier Override File

Copy the exact same `20bps.override.json` file to the bootstrap and relay hosts.

Record the deployed path in your notes so the later capture metadata can refer to the correct candidate file.

## Step 2. Start The Bootstrap

Launch the bootstrap node with the custom tier file and the monitoring flags:

```bash
kaspad \
  --devnet \
  --override-params-file "$OVERRIDE_FILE" \
  --listen "0.0.0.0:16111" \
  --rpclisten "0.0.0.0:${BOOTSTRAP_RPC_PUBLIC_PORT}" \
  --utxoindex \
  --perf-metrics \
  --perf-metrics-interval-sec=1 \
  --loglevel=info,kaspad_lib::daemon=debug,kaspa_mining::monitor=debug \
  --appdir "$BOOTSTRAP_DATA"
```

Checks:

- process starts cleanly
- no immediate override-params error
- no immediate consensus mismatch error
- node listens on the expected P2P and RPC ports
- public bootstrap RPC is protected by the configured WAN allowlist rather than by an SSH tunnel

## Step 3. Start Miner Warmup On The Bootstrap Side

Reuse the same mining workflow from the previous devnet study, but point it at the first staged wallet and leave tx generation off during the initial warmup period.

Setup guidance from the earlier work:

- the successful separated topology used a bootstrap host that carried the devnet node plus tx generation and local mining
- earlier bootstrap-contention work also used off-box miner and txgen load sources when stressing the bootstrap directly

For this investigation, prefer the known-good separated setup from the original study rather than creating a fresh test harness here.

Warmup checks:

- bootstrap remains healthy while mining
- observed chain growth matches the intended tier closely enough
- mature UTXO inventory on the staged wallet grows toward the chosen handoff threshold
- miner-only warmup lasts at least two hours before the first txgen handoff
- the intended txgen wallet is brought into the preferred `300k-500k` mature-UTXO band before the proper txgen run

Do not create a new txgen path for this study unless the old one is unusable. Reuse the known-good workflow and record the exact commands you used in calibration notes.

## Step 4. Handoff The Wallet Roles

Once the chosen staging threshold is reached:

- stop the miner
- reserve the better-scanning high-runway wallet for tx generation
- switch mining to the other wallet

For `20 BPS`, the generic handoff policy is:

- mine to the first staged wallet for at least two hours before the first cutover
- treat roughly `120k-140k` mature UTXOs as a minimum smoke-test threshold, not the preferred run threshold
- do not start the proper txgen calibration until the intended txgen wallet is in the `300k-500k` mature-UTXO band

For the currently validated live network, the winning assignment is:

- `Wallet B` for tx generation
- `Wallet A` for ongoing mining

If the intended txgen wallet is below the preferred band:

- keep mining into the current mining wallet longer before the next handoff
- or, after a later spam attempt drains the txgen wallet, stop tx generation and top the mining wallet back up before switching roles again

Do not assume that the current miner wallet is automatically the best txgen wallet. A wallet that has been mined into for a very long time may become slow to scan and awkward for txgen startup.

## Step 5. Start The Relay

Launch the relay so it keeps the bootstrap as an upstream peer while still serving downstream peers later:

```bash
kaspad \
  --devnet \
  --override-params-file "$OVERRIDE_FILE" \
  --addpeer "$BOOTSTRAP_P2P" \
  --listen "0.0.0.0:16111" \
  --rpclisten "127.0.0.1:16110" \
  --utxoindex \
  --perf-metrics \
  --perf-metrics-interval-sec=1 \
  --loglevel=info,kaspad_lib::daemon=debug,kaspa_mining::monitor=debug \
  --appdir "$RELAY_DATA"
```

Checks:

- relay starts cleanly against the same override file
- relay connects to bootstrap
- relay reaches and holds sync
- relay does not show immediate storage-path distress

## Step 6. Start The Relay Capture

Run a short capture on the relay with the shared collector while the `20 BPS` load is active:

```bash
shared/collectors/run-capture.sh \
  --run-id "tier-20-calibration-relay-$(date -u +%Y-%m-%dT%H-%M-%SZ)" \
  --run-state "tier-calibration" \
  --network "devnet" \
  --rpc-url "grpc://127.0.0.1:16110" \
  --data-dir "$RELAY_DATA" \
  --duration-sec 1800 \
  --provider "hetzner" \
  --instance-name "$RELAY_HOST" \
  --load-source "custom-devnet" \
  --traffic-shape "scaled synthetic load" \
  --payload-profile "same-as-prior-devnet-when-possible" \
  --estimated-bps 20 \
  --estimated-tps 6000 \
  --load-notes "20 BPS calibration; relay attached to bootstrap via addpeer" \
  --notes "node-bps-scaling tier validation"
```

Calibration capture purpose:

- confirm the relay stays observable and healthy
- get a short metric sample to inspect cadence, sync state, CPU, memory, and I/O

If bootstrap telemetry is needed for ambiguity resolution, use the same shared collector there as well rather than inventing a parallel capture path.

## Step 7. Start The Locked Load Profile

After the wallet handoff is complete and the relay capture is live, start the locked `20 BPS` load profile.

Official active-load profile:

- bootstrap miner at `-t 2`
- helper miner on `10.0.4.10` at `-t 1`
- txgen on `10.0.4.10`
- txgen from `Wallet B`
- mining to `Wallet A`

Locked txgen flag set:

- `--tps 6000`
- `--client-pool-size 8`
- `--max-inflight 6000`
- `--mempool-high-watermark 650000`
- `--mempool-resume-watermark 450000`
- `--timeout-cooldown-ms 2000`

Use the tuned devnet-support / workspace txgen build that already includes:

- devnet network support
- separate startup/runtime RPC timeout handling
- large-wallet refresh tuning
- mempool backpressure controls

Helper connectivity rule:

- point helper miner and txgen directly at `grpc://${BOOTSTRAP_RPC_PUBLIC_HOST}:${BOOTSTRAP_RPC_PUBLIC_PORT}`
- do not introduce a local forward such as `127.0.0.1:26610`

Example helper miner launch:

```bash
RPC_HOST="$BOOTSTRAP_RPC_PUBLIC_HOST" \
RPC_PORT="$BOOTSTRAP_RPC_PUBLIC_PORT" \
MINER_THREADS="$HELPER_MINER_THREADS" \
~/node-bps-scaling/bin/remote-miner-helper.sh start
```

Example helper txgen launch:

```bash
Tx_gen \
  --net devnet \
  --rpc-url "$HELPER_BOOTSTRAP_RPC_URL" \
  --tps 6000 \
  --client-pool-size 8 \
  --max-inflight 6000 \
  --mempool-high-watermark 650000 \
  --mempool-resume-watermark 450000 \
  --timeout-cooldown-ms 2000
```

Baseline launch checks:

- intended tx generation rate is actually attempted on the helper host
- bootstrap accepted block rate stays near `20 BPS`
- relay accepted block rate closely tracks the bootstrap
- mempool stays bounded by the backpressure window rather than pinning indefinitely
- relay remains healthy while load is active

Only after these checks still look healthy should you provision the downstream leaf.

## Step 8. Smoke-Test One Downstream Leaf

If you are using Hetzner, provision the leaf only at this point:

```bash
investigations/node-bps-scaling/scripts/hcloud-provision.sh \
  --tier 20bps \
  --profile leaf1 \
  --apply
```

Launch one cold leaf pinned to the relay:

```bash
kaspad \
  --devnet \
  --override-params-file "$OVERRIDE_FILE" \
  --connect "$RELAY_P2P" \
  --rpclisten "127.0.0.1:16110" \
  --utxoindex \
  --perf-metrics \
  --perf-metrics-interval-sec=1 \
  --loglevel=info,kaspad_lib::daemon=debug,kaspa_mining::monitor=debug \
  --appdir "$LEAF1_DATA"
```

Checks:

- leaf attaches only to the relay
- leaf begins syncing normally
- relay remains healthy while serving the leaf

This is only a smoke test for the calibration tier. Full downstream runs come later.

## Step 9. Verify Baseline-Ready Criteria

The `20 BPS` tier is baseline-ready only if:

- bootstrap and relay start cleanly
- observed cadence is acceptably close to the intended tier
- the intended scaled load is sustained closely enough
- bootstrap is not the obvious bottleneck
- relay remains healthy during the smoke window

The tier becomes fully scenario-ready only after:

- one downstream leaf can attach and sync normally

## Step 10. Update The Validation Register

Fill the `20bps` row in:

- `investigations/node-bps-scaling/data/manifests/tier-validation-register.csv`

At minimum, update:

- `validation_status`
- `observed_block_rate`
- `observed_tps`
- `bootstrap_health`
- `relay_health`
- `single_downstream_smoke`
- `final_report_label`
- `notes`

## Suggested Status Vocabulary

Use concise values so the register stays easy to scan:

- `validation_status`: `baseline-ready`, `passed`, `revise`, `blocked`
- `bootstrap_health`: `healthy`, `borderline`, `bottleneck`
- `relay_health`: `healthy`, `borderline`, `failed`
- `single_downstream_smoke`: `passed`, `failed`, `not-run`

## If 20 BPS Is Baseline-Ready

Proceed to:

1. freeze the `20 BPS` report label and locked profile
2. start the publishable `20 BPS Baseline` endurance run
3. complete the downstream smoke before `Single-Downstream`
4. then move to `25 BPS` calibration

## If 20 BPS Fails

Do not start a long run yet.

First identify whether the failure was caused by:

- bad params deployment
- txgen/miner limits
- bootstrap saturation
- relay instability
- port or topology mistakes

Then update the validation register before changing anything.
