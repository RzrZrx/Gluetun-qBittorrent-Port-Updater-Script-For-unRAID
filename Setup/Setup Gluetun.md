# Gluetun and qBittorrent Port Synchronization Script

This script automates the synchronization of the VPN forwarded port from Gluetun with qBittorrent's listening port in an UnRaid environment. It eliminates manual port configuration and optimizes torrent connectivity for VPN providers like PIA or ProtonVPN.

## Benefits
- Eliminates manual port configuration for qBittorrent.
- Optimizes torrent connectivity by syncing qBittorrent’s listening port with the VPN’s forwarded port.
- Centralizes VPN traffic management for multiple Docker containers.

## Prerequisites
### qBittorrent Configuration
- WebUI must be enabled and accessible within the same Docker network as Gluetun.
- Valid WebUI credentials (username and password) are required.

### Network Setup
- Ensure qBittorrent and Gluetun are on the same Docker network or configured for container-to-container communication.
- Additional containers (e.g., Chromium) can be routed through Gluetun using the same setup.

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

### 2. Update the Script
Replace placeholder credentials and ports in the script:
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
Create `/user/appdata/gluetun/auth/config.toml` with:
```toml
[[roles]]
name = "qbittorrent"
routes = ["GET /v1/openvpn/portforwarded"]
auth = "basic"
username = "myusername"
password = "mypassword"
```

### 4. Set Up Gluetun VPN Client  
Add the following environment variables to the Gluetun Docker template (enable Advanced view):

WebUI: `http://[IP]:[PORT:8000]/v1/openvpn/portforwarded`

**PORT_FORWARD_ONLY**  
Config Type: `Variable`  
Name: `PORT_FORWARD_ONLY`  
Key: `PORT_FORWARD_ONLY`  
Value: `true`  
Default Value:  
Description: `Set to true to select servers with port forwarding only`  

**VPN_PORT_FORWARDING**  
Config `Type: Variable`  
Name: `VPN_PORT_FORWARDING`  
Key: `VPN_PORT_FORWARDING`  
Value: `on`  
Default Value:  
Description: `Enables or disables port forwarding on the VPN server. Defaults to off but can be set to on for activation.`  

**PORT_FORWARDING_STATUS_FILE**  
Config Type: `Path`  
Container Path: `/tmp/gluetun`  
Host Path: `/mnt/user/appdata/gluetun/listening_port/`  
Default Value:  
Access Mode: `Read/Write`  
Description: `Defines the file path where the forwarded port number is written. By default, it is located at /tmp/gluetun/forwarded_port, with read/write access.`  

**VPN_PORT_FORWARDING_UP_COMMAND**  
Config Type: `Variable`  
Name: `VPN_PORT_FORWARDING_UP_COMMAND`  
Key: `VPN_PORT_FORWARDING_UP_COMMAND`  
Value: `/bin/sh -c /tmp/gluetun/update_qbittorrent_listening_port.sh`  
Default Value:  
Description: `Specifies the command to execute after the VPN connection is established and port forwarding is configured.`  

**qBittorrent WebUI Port**  
Config Type: `Port`  
Container Port: `8080`  
Host Port: `8080`  
Default Value:  
Connection Type: `TCP`  
Description: `Configures the port used by qBittorrent’s web user interface. The default port is 8080 with TCP connection type.`  

**Chromium WebUI Port**  
Config Type: Port  
Container Port: `3000`  
Host Port: `3000`  
Connection Type: `TCP`  
Description: `Configures the port used by the Chromium-based web user interface. The default port is 3000 with TCP connection type.`  


See the [Gluetun Docker template screenshot](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/raw/main/Setup/img/GluetunVPN_template.png) for reference.

### 5. Set Executable Permissions
Run the following command in the Gluetun VPN Client Console:
```bash
chmod +x /tmp/gluetun/update_qbittorrent_listening_port.sh
```

### 6. Test the Script
Execute the script in the Gluetun VPN Client Console:
```bash
/bin/sh -c /tmp/gluetun/update_qbittorrent_listening_port.sh
```

### 7. Verify qBittorrent Port Update
1. Open the qBittorrent WebUI.
2. Navigate to **Tools > Options > Connection** and confirm the Listening Port has updated.
3. To test, manually set the port to a random number, run the script, and verify the port updates.

## How the Script Works
1. **Setup and Configuration**  
   Defines variables for credentials, API ports, and loopback address for Gluetun and qBittorrent.
2. **Dependency Check**  
   Verifies tools (`curl`, `jq`) and installs them using Alpine Linux’s `apk` if missing.
3. **Wait for qBittorrent Accessibility**  
   Repeatedly attempts to connect to qBittorrent’s WebUI until available, with a timeout for failures.
4. **Fetch Listening Port from Gluetun**  
   Authenticates with Gluetun’s API to retrieve the forwarded port using `curl` and `jq`.
5. **Log in to qBittorrent**  
   Authenticates with qBittorrent’s WebUI API and retrieves a session ID.
6. **Update qBittorrent’s Listening Port**  
   Sends an API request to update qBittorrent’s listening port with Gluetun’s forwarded port.
7. **Log Out from qBittorrent**  
   Ends the session for security.

## Notes
This script was created to streamline Gluetun and qBittorrent integration in UnRaid. It’s ideal for users leveraging VPN port forwarding with providers like PIA or ProtonVPN. For additional containers, refer to the Gluetun Docker template’s Chromium example.
