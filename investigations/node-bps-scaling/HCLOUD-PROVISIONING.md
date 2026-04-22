# Hetzner Provisioning Notes

## Current Confirmed Hetzner Context

Verified from the active `hcloud` CLI context:

- active context: `node-perf`
- location available: `hel1`
- preferred server type available: `cpx42`
- preferred image available: `ubuntu-24.04`
- SSH key present: `luke-mbp-id-ed25519`

## Topology Direction

This investigation now treats public IPs as the primary node-to-node path.

That means:

- helper `10.0.4.10` talks directly to the bootstrap public IP
- relay talks to bootstrap via bootstrap public IP
- leaves talk to relay via relay public IP
- no SSH tunnel is part of the intended run path
- the Hetzner private network is optional and off by default

The reason for this change is operational simplicity. Every server already has a public IP, so the cleanest model is:

- your WAN IP for operator access
- explicit peer allowlists between bootstrap, relay, and leaves

## Why Mirror The Earlier Layout

The earlier investigation metadata shows that the relay and downstream leaves were all Hetzner `CPX42`-class nodes in `hel1`.

To minimise accidental topology drift, this investigation should mirror that as closely as practical:

- bootstrap: `cpx42`
- relay: `cpx42`
- leaves: `cpx42`

## Recommended Naming

Use short names that encode both tier and role:

- bootstrap: `nbs-20bps-bootstrap-01`
- relay: `nbs-20bps-relay-01`
- leaf 1: `nbs-20bps-leaf-01`
- leaf 2: `nbs-20bps-leaf-02`
- ...
- leaf 8: `nbs-20bps-leaf-08`

Where `nbs` means `node-bps-scaling`.

## Managed Firewall Model

The provisioning helper now manages four firewall layers per tier:

- `nbs-<tier>-admin-wan`
  - attached to every server
  - allows all TCP, all UDP, and ICMP from your WAN CIDR
- `nbs-<tier>-bootstrap-peers`
  - attached only to bootstrap
  - allows relay public IP to reach bootstrap P2P
- `nbs-<tier>-relay-peers`
  - attached only to relay
  - allows bootstrap public IP and leaf public IPs to reach relay P2P
- `nbs-<tier>-leaf-peers`
  - attached only to leaves
  - allows relay public IP to reach leaf P2P

This gives us a clean rule matrix:

- operator access: your WAN only
- bootstrap node traffic: relay only
- relay node traffic: bootstrap + leaves
- leaf node traffic: relay only

## Operator WAN CIDR

The current operator WAN CIDR for this investigation is:

- `87.121.72.51/32`

If that changes, rerun provisioning with the new CIDR so the managed admin firewall is rebuilt with the new source IP.

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

The helper skips creating any server that already exists, and on `--apply` it rebuilds the managed firewalls from the currently existing tier servers' public IPs.

That means adding a new leaf later also refreshes the relay and leaf allowlists.

## Safety

The helper script defaults to `plan` mode and prints the commands it would run.

It does not create billable servers unless you pass:

```bash
--apply
```

## Suggested First Command

Dry run:

```bash
investigations/node-bps-scaling/scripts/hcloud-provision.sh \
  --tier 20bps \
  --profile calibration \
  --admin-wan-cidr 87.121.72.51/32
```

Real create:

```bash
investigations/node-bps-scaling/scripts/hcloud-provision.sh \
  --tier 20bps \
  --profile calibration \
  --admin-wan-cidr 87.121.72.51/32 \
  --apply
```

Later, when tx generation is already live and you are ready for the downstream smoke:

```bash
investigations/node-bps-scaling/scripts/hcloud-provision.sh \
  --tier 20bps \
  --profile leaf1 \
  --admin-wan-cidr 87.121.72.51/32 \
  --apply
```

## Optional Private Network

If you still want the Hetzner private network attached for convenience, you can opt into it explicitly:

```bash
investigations/node-bps-scaling/scripts/hcloud-provision.sh \
  --tier 20bps \
  --profile calibration \
  --admin-wan-cidr 87.121.72.51/32 \
  --with-private-network \
  --apply
```

That private network is no longer part of the required run path.

## Teardown

The same script can print delete commands instead of create commands:

```bash
investigations/node-bps-scaling/scripts/hcloud-provision.sh \
  --tier 20bps \
  --profile calibration \
  --mode destroy
```

Add `--apply` only when you really want the deletion to happen.
