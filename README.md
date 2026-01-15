# Gluetun qBittorrent Port Synchronization Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-3.8--T-blue.svg)](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/releases)
[![Platform](https://img.shields.io/badge/platform-Docker%20%7C%20Unraid-orange.svg)](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID)

## Introduction

This repository provides a script (`update_qbittorrent_listening_port.sh`) designed to automatically synchronize the listening port in your qBittorrent container with the dynamically forwarded port obtained by your Gluetun VPN container. This is particularly useful when using VPN providers (like Private Internet Access, ProtonVPN) that support port forwarding but may assign different ports over time.

**The Problem:** For optimal torrent health (connecting to peers, seeding effectively), qBittorrent's configured "Listening Port" needs to match the *actual* port being forwarded through your VPN connection managed by Gluetun. Since this forwarded port can change (e.g., on VPN reconnects or based on provider policy), manually updating it in qBittorrent's settings is tedious and easy to forget, leading to poor connectivity.

**The Solution:** This script leverages Gluetun's `VPN_PORT_FORWARDING_UP_COMMAND` feature. When Gluetun successfully obtains or refreshes a forwarded port, it executes this script, passing the new port number directly to it. The script then uses qBittorrent's Web API to automatically:
1. Log in using the credentials you provide.
2. Update the listening port setting within qBittorrent.
3. Log out.

This ensures qBittorrent is always configured to use the correct, currently active forwarded port without manual intervention.

## Quick Links

*   **Script:** [`update_qbittorrent_listening_port.sh`](script/update_qbittorrent_listening_port.sh) *(v3.8-T)*
*   **Installation Guide:** [Setup Documentation](docs/installation/setup-gluetun-qbittorrent-port-sync.md)
*   **Additional Guides:**
    *   [Setup qBittorrent on Unraid 6](docs/installation/setup-qbittorrent-unraid-6.md)
    *   [Setup qBittorrent on Unraid 7](docs/installation/setup-qbittorrent-unraid-7.md)
    *   [Setup Chromium on Unraid](docs/installation/setup-chromium-unraid.md)

## Key Requirement: Network Mode

For the script (using its default settings) to work correctly, your **qBittorrent container MUST be configured to use the network stack of your Gluetun container**. This allows the script running inside Gluetun to access the qBittorrent Web API.

## Features

- ✅ Automatic port synchronization between Gluetun and qBittorrent
- ✅ Robust handling of container startup race conditions
- ✅ Secure credential management via Docker environment variables
- ✅ Built-in debug mode for troubleshooting
- ✅ Support for major VPN providers (PIA, ProtonVPN, etc.)
- ✅ Compatible with Unraid 6.12.14 and Unraid 7

## Getting Started

1. Download the [script](script/update_qbittorrent_listening_port.sh)
2. Follow the [Installation Guide](docs/installation/setup-gluetun-qbittorrent-port-sync.md)
3. Configure your Gluetun and qBittorrent containers as described
4. Enjoy automated port synchronization!

## Documentation

All documentation is located in the [`docs/`](docs/) directory:
- **Installation guides** - [`docs/installation/`](docs/installation/)
- **Troubleshooting** - [`docs/issues/`](docs/issues/)
  - [Quick Reference Guide](docs/issues/TROUBLESHOOTING_QUICK_REF.md)
  - [Known Issues](docs/issues/KNOWN_ISSUES.md)
- **Images/Screenshots** - [`docs/images/`](docs/images/)

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and recent changes.

## Community

- 💬 **Unraid Forum Thread:** [Guide: Automate qBittorrent Port Updates with Gluetun VPN Client](https://forums.unraid.net/topic/184411-guide-automate-qbittorrent-port-updates-with-gluetun-vpn-client-on-unraid-683-and-above/)  
- 🐛 **Report Issues:** [GitHub Issues](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/issues)
- 📖 **Documentation:** [Installation Guide](docs/installation/setup-gluetun-qbittorrent-port-sync.md)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

---

**Need help?** Open an [issue](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/issues) or check the [troubleshooting section](docs/installation/setup-gluetun-qbittorrent-port-sync.md#troubleshooting) in the installation guide.
