# WireGuard / Amnezia WG collector for prometheus-node-exporter-lua

This collector adds a single Prometheus metric, `wg_latest_handshake_seconds`, for WireGuard and Amnezia WG peers by reading the output of `wg show all latest-handshakes` and `amneziawg show all latest-handshakes`. It is intended for use with the [OpenWrt prometheus-node-exporter-lua](https://github.com/openwrt/packages/tree/openwrt-22.03/utils/prometheus-node-exporter-lua) (or compatible) exporter.

## Requirements

- **prometheus-node-exporter-lua** installed and running on the device (OpenWrt or compatible).
- **Optional**: `/usr/bin/wg` (wireguard-tools) and/or `/usr/bin/amneziawg` for the interfaces you want to monitor. If neither binary is present, the collector does nothing and reports no metrics and no errors.

## Installation

**Using the opkg package (recommended on OpenWrt):**
```
opkg install https://github.com/aaaler/prometheus-node-exporter-lua-wg/releases/download/0.1.0/prometheus-node-exporter-lua-wireguard_0.1.0_all.ipk
```
 
 [Building the opkg package](#building-the-opkg-package)

**Manual install:**

1. Copy `wireguard.lua` to the collectors directory on the device:
   ```bash
   scp wireguard.lua root@<device>:/usr/lib/lua/prometheus-collectors/
   ```
2. If you use WireGuard or Amnezia WG, ensure the corresponding CLI is installed (e.g. `opkg install wireguard-tools` for `wg`).
3. The main exporter discovers collectors at startup via `ls /usr/lib/lua/prometheus-collectors/*.lua`. Restart the exporter service if it was already running:
   ```bash
   /etc/init.d/prometheus-node-exporter-lua restart
   ```

No extra Lua dependencies are required; the collector uses only standard `io.open` and `io.popen`.

## Metric

| Name                         | Type   | Description |
|------------------------------|--------|-------------|
| `wg_latest_handshake_seconds` | gauge  | Unix timestamp (seconds) of the last handshake with the peer. `0` if no handshake has occurred yet. |

**Labels:**

- `device` – interface name (e.g. `wg0`, `awg0`)
- `public_key` – peer public key (base64)
- `type` – `wireguard` or `amneziawg` depending on which CLI produced the value

## Usage

If the exporter is configured to run all collectors (default on OpenWrt when no `collect` list is set), the `wireguard` collector is loaded automatically and scrapes when `/metrics` is requested.

- **Prometheus**: Add a scrape job for the node exporter; the metric will appear as `wg_latest_handshake_seconds{device="...", public_key="...", type="wireguard"}` (or `type="amneziawg"`).
- **Example query** – peers that have not handshaken in the last 5 minutes (assuming Prometheus knows current time):
  ```promql
  (time() - wg_latest_handshake_seconds) > 300
  ```
- **Alert idea**: Alert when a given peer’s last handshake is older than a threshold (e.g. 10 minutes) to detect stale or disconnected tunnels.

## Example alert rule

Alert when a WireGuard/Amnezia WG peer has not had a successful handshake in more than 10 minutes (only for peers that have handshaken at least once, to avoid alerting on newly added peers):

```yaml
- alert: WireGuardPeerStaleHandshake
  expr: (time() - wg_latest_handshake_seconds) > 600 and wg_latest_handshake_seconds > 0
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "WireGuard peer handshake is stale"
    description: "Peer {{ $labels.device }} ({{ $labels.public_key }}) has not had a handshake in more than 10 minutes."
```

For Prometheus Operator, see the [prometheus-rule-wireguard.yaml](prometheus-rule-wireguard.yaml) example.

## Building the opkg package

You can install the collector via an OpenWrt package (`.ipk`) in two ways: build the package with the OpenWrt SDK, or build it manually with the provided script. No CI/CD is required; both are intended for manual use.

### Option 1: Manual ipk build (no SDK)

On any Linux host with GNU `tar` and `gzip` (e.g. Ubuntu/WSL):

```bash
./build-ipk.sh        # builds prometheus-node-exporter-lua-wireguard_1.0.0_all.ipk
./build-ipk.sh 1.0.1  # builds with version 1.0.1
```

Then copy the `.ipk` to the OpenWrt device and install:

```bash
scp prometheus-node-exporter-lua-wireguard_1.0.0_all.ipk root@<device>:/tmp/
ssh root@<device> "opkg install /tmp/prometheus-node-exporter-lua-wireguard_1.0.0_all.ipk"
```

The package depends on `prometheus-node-exporter-lua`; install it first if needed (`opkg install prometheus-node-exporter-lua`).

### Option 2: OpenWrt SDK

1. Clone or copy this repository into your OpenWrt SDK environment (e.g. as a custom feed or a single package under `package/`).
2. From the SDK root, ensure the package path is visible (e.g. `package/feeds/packages/prometheus-node-exporter-lua-wireguard` or a symlink).
3. Build the package:

   ```bash
   make package/prometheus-node-exporter-lua-wireguard/compile V=s
   ```

4. The `.ipk` will be in `bin/packages/<arch>/<feed>/` (e.g. `bin/packages/mipsel_24kc/packages/`). Copy it to the device and install with `opkg install ...`.

The [Makefile](Makefile) installs `wireguard.lua` from the repo root into `/usr/lib/lua/prometheus-collectors/` and declares a dependency on `prometheus-node-exporter-lua`.

## References

- [OpenWrt prometheus-collectors](https://github.com/openwrt/packages/tree/openwrt-22.03/utils/prometheus-node-exporter-lua/files/usr/lib/lua/prometheus-collectors) – other collector examples
- [WireGuard](https://www.wireguard.com/) – VPN protocol and `wg` CLI
- [AmneziaWG](https://github.com/amnezia-vpn/amneziawg) – Amnezia WG implementation and `amneziawg` CLI
