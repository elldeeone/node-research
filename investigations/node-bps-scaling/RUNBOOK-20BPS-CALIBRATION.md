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

This is a calibration run, not a publishable endurance run.

Recommended calibration shape:

- bootstrap and relay both use the same `20bps.override.json`
- relay is the node we inspect most closely
- one downstream leaf is enough as a topology smoke test
- target load is about `6k TPS`
- run long enough to verify cadence, sync health, and basic stability

## Inputs

- candidate params file:
  - `investigations/node-bps-scaling/configs/generated/20bps.override.json`
- validation register row:
  - `20bps` in `investigations/node-bps-scaling/data/manifests/tier-validation-register.csv`
- optional Hetzner provisioning helper:
  - `investigations/node-bps-scaling/scripts/hcloud-provision.sh --tier 20bps --profile calibration`

## Assumptions

- bootstrap and relay are on separate hosts
- the bootstrap side reuses the known-good miner and tx-generation workflow from the original investigation
- the relay host is the `CPX42` reference box
- all nodes use Rusty Kaspa with `--utxoindex`
- RPC remains on the default gRPC port unless you intentionally change it

## Bootstrap Wallet Staging

For a brand-new devnet, do not start the tx generator immediately.

Recommended wallet flow:

- `Wallet A`: initial bootstrap mining wallet, later handed over to tx generation
- `Wallet B`: ongoing miner wallet after the handoff

Recommended sequence:

1. start the bootstrap node
2. generate `Wallet A`
3. point the miner at `Wallet A`
4. leave tx generation off for at least two hours while `Wallet A` accumulates mature coinbase UTXOs
5. once `Wallet A` reaches the chosen mature-UTXO threshold, stop the miner
6. switch the miner to `Wallet B`
7. start tx generation from `Wallet A`

Practical sizing note for `20 BPS`:

- miner-only warmup creates about one new coinbase UTXO per block
- `20 BPS` for two hours is about `144,000` blocks total
- after coinbase maturity, that gives a roughly `120k-140k` mature-UTXO staging window
- this is a better first-pass target than a one-hour warmup because it leaves meaningful headroom above the txgen default inventory floor

This lines up closely with the current modified `Tx_gen` default inventory rule:

- `target_utxo_count = target_tps * 10`
- at `6,000 TPS`, the default target inventory is `60,000` UTXOs

If you want a larger txgen inventory than miner-only warmup can provide in the desired time window:

- either extend the miner-only warmup beyond the two-hour minimum
- or hand `Wallet A` to `Tx_gen` in `--prepare-only` mode first, with an explicit larger `--target-utxo-count`, then start the real spam run after preparation finishes

## Variables

Replace these values before running:

```bash
TIER_SLUG=20bps
TIER_LABEL="20 BPS"
OVERRIDE_FILE=/absolute/path/to/20bps.override.json

BOOTSTRAP_HOST=bootstrap.example
BOOTSTRAP_P2P=${BOOTSTRAP_HOST}:16111
BOOTSTRAP_RPC=127.0.0.1:16110
BOOTSTRAP_DATA=/var/lib/kaspa-bootstrap-20bps

RELAY_HOST=relay.example
RELAY_P2P=${RELAY_HOST}:16111
RELAY_RPC=127.0.0.1:16110
RELAY_DATA=/var/lib/kaspa-relay-20bps

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
  --rpclisten "127.0.0.1:16110" \
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

## Step 3. Start Miner On The Bootstrap Side

Reuse the same mining workflow from the previous devnet study, but point it at `Wallet A` first and leave tx generation off during the initial warmup period.

Setup guidance from the earlier work:

- the successful separated topology used a bootstrap host that carried the devnet node plus tx generation and local mining
- earlier bootstrap-contention work also used off-box miner and txgen load sources when stressing the bootstrap directly

For this investigation, prefer the known-good separated setup from the original study rather than creating a fresh test harness here.

Calibration checks:

- bootstrap remains healthy while mining
- observed chain growth matches the intended tier closely enough
- mature UTXO inventory on `Wallet A` grows toward the chosen handoff threshold
- miner-only warmup lasts at least two hours before the first txgen handoff

Do not create a new txgen path for this study unless the old one is unusable. Reuse the known-good workflow and record the exact commands you used in calibration notes.

## Step 4. Handoff The Bootstrap Wallets

Once the chosen `Wallet A` threshold is reached:

- stop the miner
- switch the miner to `Wallet B`
- reserve `Wallet A` for tx generation only

For `20 BPS` calibration, the default handoff policy is:

- mine to `Wallet A` for at least two hours before the cutover
- expect roughly `120k-140k` mature UTXOs on `Wallet A` at handoff time
- treat that as the minimum staging target before starting tx generation

If you want to test a larger starting inventory such as `200k-300k` UTXOs:

- mine materially longer before the handoff
- or run `Tx_gen --prepare-only` against `Wallet A` after the handoff until the larger target is reached

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

## Step 6. Start A Relay Calibration Capture

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

## Step 7. Start Tx Generation On The Bootstrap Side

After the miner handoff is complete and the relay capture is live, start tx generation from `Wallet A`.

Recommended approach:

- first calibration pass: use the current default txgen inventory target for `6,000 TPS`, which is `60,000` UTXOs, but only after the two-hour miner warmup and wallet handoff
- larger-inventory pass: if needed, run an explicit `--prepare-only --target-utxo-count <N>` stage before the live spam phase

Calibration checks:

- intended tx generation rate is actually attempted
- bootstrap remains healthy while mining continues to `Wallet B`
- relay remains healthy while bootstrap load is active

## Step 8. Smoke-Test One Downstream Leaf

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

## Step 9. Verify The Validation Pass Criteria

The `20 BPS` tier passes calibration only if:

- bootstrap and relay start cleanly
- observed cadence is acceptably close to the intended tier
- the intended scaled load is sustained closely enough
- bootstrap is not the obvious bottleneck
- relay remains healthy during the smoke window
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

- `validation_status`: `passed`, `revise`, `blocked`
- `bootstrap_health`: `healthy`, `borderline`, `bottleneck`
- `relay_health`: `healthy`, `borderline`, `failed`
- `single_downstream_smoke`: `passed`, `failed`, `not-run`

## If 20 BPS Passes

Proceed to:

1. freeze the `20 BPS` report label
2. prepare the publishable `20 BPS Baseline` endurance run
3. then move to `25 BPS` calibration

## If 20 BPS Fails

Do not start a long run yet.

First identify whether the failure was caused by:

- bad params deployment
- txgen/miner limits
- bootstrap saturation
- relay instability
- port or topology mistakes

Then update the validation register before changing anything.
