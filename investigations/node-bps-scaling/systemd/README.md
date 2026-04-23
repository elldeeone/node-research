## Service Model

These unit templates capture the current intended `20bps` layout:

- bootstrap node runs as `kaspa-bootstrap-20bps.service`
- bootstrap miner runs as `kaspa-bootstrap-miner.service`
- relay node runs as `kaspa-relay-20bps.service`
- helper miner runs as `nbs-helper-miner.service`
- dedicated txgen host runs as `nbs-txgen-host.service`

The intended operating model is:

- bootstrap DB is preserved across restarts
- bootstrap RPC is public on `16610`
- bootstrap, relay, and leaves talk over public P2P on `16611`
- bootstrap hosts the primary miner only
- helper host `10.0.4.30` contributes supplementary mining only
- dedicated txgen runs on a separate Hetzner host
- helper miner remains capped with `CPUQuota=25%`
- txgen is installed on the dedicated host as a service and only started during active load windows

## Expected Env Files

Bootstrap node:

- `/opt/node-bps-scaling/secrets/kaspa-bootstrap-20bps.env`

Example:

```bash
OVERRIDE_FILE=/opt/node-bps-scaling/20bps.override.json
APPDIR=/var/lib/kaspa-bootstrap-20bps
P2P_PORT=16611
RPC_PORT=16610
KASPAD_EXTRA_ARGS=
```

Bootstrap miner:

- `/opt/node-bps-scaling/secrets/bootstrap-miner.env`

Example:

```bash
MINER_ADDRESS=kaspadev:...
RPC_HOST=127.0.0.1
RPC_PORT=16610
MINER_THREADS=2
```

Relay node:

- `/opt/node-bps-scaling/secrets/kaspa-relay-20bps.env`

Example:

```bash
OVERRIDE_FILE=/opt/node-bps-scaling/20bps.override.json
APPDIR=/var/lib/kaspa-relay-20bps
P2P_PORT=16611
RPC_PORT=16610
BOOTSTRAP_P2P=157.180.69.53:16611
KASPAD_EXTRA_ARGS=
```

Helper miner wallet:

- `~/node-bps-scaling/remote-miner-wallet.env`

Example:

```bash
MINER_ADDRESS=kaspadev:...
MINER_THREADS=1
```

Remote bootstrap endpoint:

- `~/node-bps-scaling/bootstrap-endpoint.env`

Example:

```bash
BOOTSTRAP_RPC_HOST=157.180.69.53
BOOTSTRAP_RPC_PORT=16610
BOOTSTRAP_P2P=157.180.69.53:16611
```

Dedicated txgen wallet:

- `~/node-bps-scaling/txgen-wallet.env`

Example:

```bash
TX_GEN_PRIVATE_KEY=...
```

## Install Notes

Copy the appropriate service files onto the target host under `/etc/systemd/system/`, reload `systemd`, then enable the units you want active by default:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now kaspa-bootstrap-20bps kaspa-bootstrap-miner
sudo systemctl enable --now kaspa-relay-20bps
sudo systemctl enable --now nbs-helper-miner
sudo systemctl enable nbs-txgen-host
```

The dedicated txgen unit is typically enabled but left stopped until the calibration or baseline load window begins.
