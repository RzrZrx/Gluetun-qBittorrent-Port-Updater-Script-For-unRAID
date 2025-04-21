# Gluetun and qBittorrent Port Synchronization Script

This script automates the synchronization of the VPN forwarded port from Gluetun with qBittorrent’s listening port, eliminating manual port configuration and optimizing torrent connectivity in a Docker environment.

## Benefits

- Eliminates manual port configuration for qBittorrent.
- Optimizes torrent connectivity by syncing qBittorrent’s listening port with the VPN’s forwarded port.
- Centralizes VPN traffic management for multiple containers.

## Prerequisites

### qBittorrent Configuration

- WebUI must be enabled and accessible within the same Docker network as Gluetun.
- Valid WebUI credentials (username and password) are required.

### Network Setup

- Ensure qBittorrent and Gluetun are on the same Docker network or configured for container-to-container communication.
- Additional containers can be routed through Gluetun (e.g., a Chromium container, as shown in the Gluetun Docker template).

### Variables to Set

- `PORT_FORWARD_ONLY`
- `VPN_PORT_FORWARDING`
- `PORT_FORWARDING_STATUS_FILE`
- `VPN_PORT_FORWARDING_UP_COMMAND`
- `HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH`

## Setup Instructions

### 1. Create Necessary Directories

```bash
/user/appdata/gluetun/auth
/user/appdata/gluetun/listening_port
```

Below is a screenshot of the Gluetun Docker template for reference:
![Screenshot of the Gluetun Docker template](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/raw/main/Setup/img/GluetunVPN_template.png)

### 2. Update the Script

Replace placeholder credentials and ports with your own in the script:

```bash
QBITTORRENT_USERNAME="myusername"  # Username for qBittorrent authentication
QBITTORRENT_PASSWORD="mypassword"  # Password for qBittorrent authentication
GLUETUN_USERNAME="myusername"      # Username for Gluetun authentication
GLUETUN_PASSWORD="mypassword"      # Password for Gluetun authentication
GLUETUN_PORT=8000                  # Default port for Gluetun
QBITTORRENT_PORT=8585              # Default port for qBittorrent
LOOPBACK_ADDRESS="127.0.0.1"       # Default loopback address
```

Save the script to:

```
/user/appdata/gluetun/listening_port/update_qbittorrent_listening_port.sh
```

### 3. Create a Config File

Create `/user/appdata/gluetun/auth/config.toml` with the following content:

```toml
[[roles]]
name = "qbittorrent"
routes = ["GET /v1/openvpn/portforwarded"]
auth = "basic"
username = "myusername"
password = "mypassword"
```

### 4. Set Up Gluetun VPN Client

Configure environment variables for the Gluetun VPN client as needed.

### 5. Set Executable Permissions

Run the following command in the Gluetun VPN Client Console terminal:

```bash
chmod +x /tmp/gluetun/update_qbittorrent_listening_port.sh
```

### 6. Test the Script

Execute the script in the Gluetun VPN Client Console terminal:

```bash
/bin/sh -c /tmp/gluetun/update_qbittorrent_listening_port.sh
```

### 7. Verify qBittorrent Port Updates

1. Open the qBittorrent WebUI.
2. Navigate to **Tools > Options > Connection** and confirm the Listening Port has updated.
3. To test, manually set the port to a random number, run the script, and verify the port updates correctly.

## How the Script Works

1. **Setup and Configuration**

   - Defines variables for credentials, API ports, and loopback address.

2. **Dependency Check**

   - Verifies required tools (`curl`, `jq`) and installs them using Alpine Linux’s `apk` package manager if needed.

3. **Wait for qBittorrent Accessibility**

   - Repeatedly attempts to connect to qBittorrent’s WebUI until available, with a timeout for graceful failure handling.

4. **Fetch Listening Port from Gluetun**

   - Authenticates with Gluetun’s API to retrieve the forwarded port using `curl` and `jq`.

5. **Log in to qBittorrent**

   - Authenticates with the qBittorrent WebUI API and retrieves a session ID.

6. **Update qBittorrent’s Listening Port**

   - Sends an API request to update qBittorrent’s listening port with the forwarded port from Gluetun.

7. **Log Out from qBittorrent**

   - Ends the session for enhanced security.

## About

This script was created to streamline synchronization between Gluetun VPN and qBittorrent in an UnRaid environment. It’s ideal for users leveraging VPN port forwarding with providers like PIA, ProtonVPN, or others. Enjoy an optimized torrent setup!
