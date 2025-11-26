# Gluetun qBittorrent Port Synchronization Script

## Introduction

This repository provides a script (`update_qbittorrent_listening_port.sh`) designed to automatically synchronize the listening port in your qBittorrent container with the dynamically forwarded port obtained by your Gluetun VPN container. This is particularly useful when using VPN providers (like Private Internet Access, ProtonVPN) that support port forwarding but may assign different ports over time.

**The Problem:** For optimal torrent health (connecting to peers, seeding effectively), qBittorrent's configured "Listening Port" needs to match the *actual* port being forwarded through your VPN connection managed by Gluetun. Since this forwarded port can change (e.g., on VPN reconnects or based on provider policy), manually updating it in qBittorrent's settings is tedious and easy to forget, leading to poor connectivity.

**The Solution:** This script leverages Gluetun's `VPN_PORT_FORWARDING_UP_COMMAND` feature. When Gluetun successfully obtains or refreshes a forwarded port, it executes this script, passing the new port number directly to it. The script then uses qBittorrent's Web API to automatically:
1. Log in using the credentials you provide.
2. Update the listening port setting within qBittorrent.
3. Log out.

This ensures qBittorrent is always configured to use the correct, currently active forwarded port without manual intervention.

## Script Link

*   **Script:** [`update_qbittorrent_listening_port.sh`](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/blob/main/Script/update_qbittorrent_listening_port.sh) *(V3.8-T)*
*   **Installation Guide:** [`Setup Gluetun qBittorrent Port Synchronization Script .md`](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/blob/main/Setup/Setup%20Gluetun%20qBittorrent%20Port%20Synchronization%20Script%20.md) *(V3.8-T)*

## Key Requirement: Network Mode

For the script (using its default settings) to work correctly, your **qBittorrent container MUST be configured to use the network stack of your Gluetun container**. This allows the script running inside Gluetun to access the qBittorrent Web API.

---

**For detailed setup instructions, please see the project Wiki:**  
**[https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/wiki](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/blob/main/Setup/Setup%20Gluetun%20qBittorrent%20Port%20Synchronization%20Script%20.md)**

---


