# WireGuard / Amnezia WG collector for prometheus-node-exporter-lua

This collector adds a single Prometheus metric, `wg_latest_handshake_seconds`, for WireGuard and Amnezia WG peers by reading the output of `wg show all latest-handshakes` and `amneziawg show all latest-handshakes`. It is intended for use with the [OpenWrt prometheus-node-exporter-lua](https://github.com/openwrt/packages/tree/openwrt-22.03/utils/prometheus-node-exporter-lua) (or compatible) exporter.

## Requirements

- **prometheus-node-exporter-lua** installed and running on the device (OpenWrt or compatible).
- **Optional**: `/usr/bin/wg` (wireguard-tools) and/or `/usr/bin/amneziawg` for the interfaces you want to monitor. If neither binary is present, the collector does nothing and reports no metrics and no errors.

## Installation

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

## References

- [OpenWrt prometheus-collectors](https://github.com/openwrt/packages/tree/openwrt-22.03/utils/prometheus-node-exporter-lua/files/usr/lib/lua/prometheus-collectors) – other collector examples
- [WireGuard](https://www.wireguard.com/) – VPN protocol and `wg` CLI
- [AmneziaWG](https://github.com/amnezia-vpn/amneziawg) – Amnezia WG implementation and `amneziawg` CLI
