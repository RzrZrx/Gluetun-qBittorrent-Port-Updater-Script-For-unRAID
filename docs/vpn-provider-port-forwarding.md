# VPN Providers — Port Forwarding Support

This table shows which VPN providers supported by Gluetun have **native port forwarding** integration.  
Only providers with port forwarding support will work with this script.

> **Source:** [Gluetun Wiki](https://github.com/qdm12/gluetun-wiki) · Last updated: 2026-05-16

---

## Providers with Native Port Forwarding

| Provider | Port Forwarding | Gluetun Provider Key | Notes |
|---|:---:|---|---|
| **Private Internet Access (PIA)** | ✅ | `private internet access` | Most popular. Set `PORT_FORWARD_ONLY=true` to auto-select PF servers. Port persists 60 days with bind mount. |
| **ProtonVPN** | ✅ | `protonvpn` | Requires paid plan with port forwarding feature. |
| **Perfect Privacy** | ✅ | `perfect privacy` | — |
| **PrivateVPN** | ✅ | `privatevpn` | — |

## Providers WITHOUT Port Forwarding

These providers are supported by Gluetun but **do not** support port forwarding. This script **will not work** with them unless you manually configure `FIREWALL_VPN_INPUT_PORTS`.

| Provider | Gluetun Provider Key |
|---|---|
| AirVPN | `airvpn` |
| CyberGhost | `cyberghost` |
| ExpressVPN | `expressvpn` |
| FastestVPN | `fastestvpn` |
| Giganews | `giganews` |
| HideMyAss | `hidemyass` |
| IPVanish | `ipvanish` |
| IVPN | `ivpn` |
| Mullvad | `mullvad` |
| NordVPN | `nordvpn` |
| Privado | `privado` |
| PureVPN | `purevpn` |
| SlickVPN | `slickvpn` |
| Surfshark | `surfshark` |
| TorGuard | `torguard` |
| VPN Unlimited | `vpn unlimited` |
| VPNSecure | `vpnsecure` |
| VyprVPN | `vyprvpn` |
| Windscribe | `windscribe` |

---

## PIA Region Notes

Not all PIA server regions support port forwarding. Use `PORT_FORWARD_ONLY=true` to let Gluetun automatically select a server that supports it.

**Known working regions:** US, Canada, Netherlands, Switzerland, Sweden, Romania, Israel  
**Known non-working regions:** UK, Australia

> **Tip:** To see all available PIA regions in your current Gluetun install, run from your Unraid terminal:
> ```bash
> docker exec Gluetun jq -r '.["private internet access"][] | select(type == "object") | .region' /gluetun/servers.json | sort -u
> ```

---

📖 *For the latest provider documentation, see the [Gluetun Wiki — Providers](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers).*
