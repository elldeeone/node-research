# Hetzner Provisioning Notes

## Current Confirmed Hetzner Context

Verified from the active `hcloud` CLI context:

- active context: `node-perf`
- location available: `hel1`
- preferred server type available: `cpx42`
- preferred image available: `ubuntu-24.04`
- SSH key present: `luke-mbp-id-ed25519`
- no private network currently exists in the project

## Why Mirror The Earlier Layout

The earlier investigation metadata shows that the relay and downstream leaves were all Hetzner `CPX42`-class nodes in `hel1`.

To minimise accidental topology drift, this investigation should mirror that as closely as practical:

- bootstrap: `cpx42`
- relay: `cpx42`
- leaves: `cpx42`

This is not the cheapest possible layout, but it is the cleanest continuity with the prior successful setup.

## Recommended Naming

Use short names that encode both tier and role:

- bootstrap: `nbs-20bps-bootstrap-01`
- relay: `nbs-20bps-relay-01`
- leaf 1: `nbs-20bps-leaf-01`
- leaf 2: `nbs-20bps-leaf-02`
- ...
- leaf 8: `nbs-20bps-leaf-08`

Where `nbs` means `node-bps-scaling`.

## Recommended Private Network

Create a dedicated Hetzner private network for this investigation:

- network name: `node-bps-scaling`
- IP range: `10.80.0.0/16`
- subnet type: `cloud`
- network zone: `eu-central`
- subnet range: `10.80.0.0/24`

Using a private network keeps bootstrap-relay-leaf traffic explicit and easier to reason about.

## Bootstrap Public RPC

The helper host on your WAN should reach the bootstrap directly over the public internet.

That means the bootstrap needs two things from the beginning:

- `kaspad` gRPC listening on `0.0.0.0:16110`
- a bootstrap-only firewall that allows:
  - SSH from your WAN CIDR
  - gRPC from your WAN CIDR
  - P2P from the Hetzner private network

This is the preferred path for the `10.0.4.10` helper host. Do not rely on an ad hoc SSH tunnel for the official run path.

## Provisioning Profiles

The helper script supports these scenario profiles:

- `baseline`
  - bootstrap + relay
- `leaf1`
  - leaf1 only
- `single`
  - bootstrap + relay + leaf1
- `eight`
  - bootstrap + relay + leaf1..leaf8
- `calibration`
  - alias for `baseline`

The intended live sequence is staged:

- provision `calibration` first so only bootstrap + relay are billable during miner warmup
- provision `leaf1` later, only after tx generation is already running and the downstream smoke test is about to begin

The helper now skips creating any server that already exists, so rerunning it with a larger profile is safe for incremental expansion.

## Safety

The helper script defaults to `plan` mode and prints the commands it would run.

It does not create billable servers unless you pass:

```bash
--apply
```

## First Live Hetzner Step

For the first live infra pass, use:

- tier: `20bps`
- profile: `calibration`

That provisions only the machines needed for the bootstrap warmup and relay validation window, without paying for an idle downstream leaf during txgen staging.

## Suggested First Command

Dry run:

```bash
investigations/node-bps-scaling/scripts/hcloud-provision.sh \
  --tier 20bps \
  --profile calibration \
  --bootstrap-wan-cidr YOUR_WAN_CIDR
```

Real create:

```bash
investigations/node-bps-scaling/scripts/hcloud-provision.sh \
  --tier 20bps \
  --profile calibration \
  --bootstrap-wan-cidr YOUR_WAN_CIDR \
  --apply
```

`YOUR_WAN_CIDR` should usually be your current public IPv4 with a host mask such as `203.0.113.10/32`.

The helper script will create and attach a managed firewall named like:

- `nbs-20bps-bootstrap-public-rpc`

and will allow:

- TCP `22` from `YOUR_WAN_CIDR`
- TCP `16110` from `YOUR_WAN_CIDR`
- TCP `16111` from the Hetzner private network CIDR

If your WAN CIDR changes later, delete that managed firewall or rerun the helper with a different `--bootstrap-firewall-name` so the allowlist is rebuilt cleanly.

Later, when tx generation is already live and you are ready for the downstream smoke:

```bash
investigations/node-bps-scaling/scripts/hcloud-provision.sh \
  --tier 20bps \
  --profile leaf1 \
  --apply
```

## Teardown

The same script can print delete commands instead of create commands:

```bash
investigations/node-bps-scaling/scripts/hcloud-provision.sh \
  --tier 20bps \
  --profile calibration \
  --mode destroy
```

Add `--apply` only when you really want the deletion to happen.
