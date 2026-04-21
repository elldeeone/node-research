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

## Provisioning Profiles

The helper script supports these scenario profiles:

- `baseline`
  - bootstrap + relay
- `single`
  - bootstrap + relay + leaf1
- `eight`
  - bootstrap + relay + leaf1..leaf8
- `calibration`
  - alias for `single`

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

That provisions exactly the machines needed for the `20 BPS` calibration runbook without jumping straight to the full eight-leaf cost envelope.

## Suggested First Command

Dry run:

```bash
investigations/node-bps-scaling/scripts/hcloud-provision.sh \
  --tier 20bps \
  --profile calibration
```

Real create:

```bash
investigations/node-bps-scaling/scripts/hcloud-provision.sh \
  --tier 20bps \
  --profile calibration \
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
