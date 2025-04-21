# Gluetun and qBittorrent Port Synchronization Script (VPN_PORT_FORWARDING_UP_COMMAND)

This script automates the synchronization of the VPN forwarded port from Gluetun with qBittorrent's listening port in an UnRaid environment. It eliminates manual port configuration and optimizes torrent connectivity for VPN providers like PIA or ProtonVPN.
https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/blob/main/Script/update_qb_port.sh

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
- `VPN_PORT_FORWARDING_UP_COMMAND`
- `qBittorrent WebUI Port`
- `Chromium WebUI Port`

## Setup Instructions
### 1. Create Necessary Directories
```bash
/user/appdata/gluetun/scripts/
```

### 2. Update the Script
Replace placeholder credentials and ports in the script:
```bash
# --- START USER CONFIGURATION ---

# Set constants
QBITTORRENT_PORT=8080                                         # Default qBittorrent WebUI port

# qBittorrent WebUI Credentials
QBITTORRENT_USERNAME="your_qBittorrent_control_user"          # Username for qBittorrent authentication
QBITTORRENT_PASSWORD="your_qBittorrent_control_password"      # Password for qBittorrent authentication

# --- END USER CONFIGURATION ---
```
Save the script to:
```
/mnt/user/appdata/gluetun/scripts/update_qb_port.sh
```

### 3. Set Up Gluetun VPN Client  
Add the following environment variables to the Gluetun Docker template (enable Advanced view):

WebUI: `http://[IP]:[PORT:8000]/v1/openvpn/portforwarded`

**PORT_FORWARD_ONLY**  
Config Type: `Variable`  
Name: `PORT_FORWARD_ONLY`  
Key: `PORT_FORWARD_ONLY`  
Value: `true`  
Default Value:  
Description: `Set to true to select servers with port forwarding only.`  

**VPN_PORT_FORWARDING**  
Config Type: `Variable`  
Name: `VPN_PORT_FORWARDING`  
Key: `VPN_PORT_FORWARDING`  
Value: `on`  
Default Value:  
Description: `Enables or disables port forwarding on the VPN server. Defaults to off but can be set to on for activation.`  


**VPN_PORT_FORWARDING_UP_COMMAND**  
Config Type: `Variable`  
Name: `VPN_PORT_FORWARDING_UP_COMMAND`  
Key: `VPN_PORT_FORWARDING_UP_COMMAND`  
Value: `/gluetun/scripts/update_qb_port.sh {{PORTS}}`  
Default Value:  
Description: `Specifies the custom script to execute when a new VPN port is forwarded. This script updates qBittorrent with the new port. Ensure the script is properly mounted inside the container and made executable. Replace {{PORTS}} with the forwarded port number automatically passed by Gluetun.` 

**HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH**
Config Type: `Path`  
Name: `HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH`  
Container Path: `/gluetun/auth/`  
Host Path: `/mnt/user/appdata/gluetun/auth/`  
Default Value:  
Access Mode: `Read/Write`  
Description: `Specifies the file path to the HTTP control server authentication configuration. This path should point to a config.toml file containing authentication settings used by the control server.`


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
chmod +x /gluetun/scripts/update_qb_port.sh
```

### 6. Test the Script
Execute the script in the Gluetun VPN Client Console:
```bash
/gluetun/scripts/update_qb_port.sh 12345
```
Then verify that qBittorrent has received the new port:
1. Open the qBittorrent WebUI.
2. Go to Tools > Options > Connection and check that the Listening Port reflects 12345.
3. Optional) For further testing, manually change the port to a different random number, run the script again, and confirm the port updates accordingly.

## How the Script Works

The script leverages Gluetun's `VPN_PORT_FORWARDING_UP_COMMAND` feature to automatically update qBittorrent's listening port. Here's a step-by-step breakdown of its operation:

1.  **Triggering:**
    *   Gluetun successfully connects to the VPN and obtains/refreshes a forwarded port from the provider.
    *   If `VPN_PORT_FORWARDING=on` and `VPN_PORT_FORWARDING_UP_COMMAND` is set (e.g., to `/gluetun/scripts/update_qb_port.sh {{PORTS}}`), Gluetun executes the script.
    *   Gluetun replaces the `{{PORTS}}` placeholder with the actual forwarded port number(s) (e.g., `36276`) before running the script. The script is executed as: `/gluetun/scripts/update_qb_port.sh <port_number>`.

2.  **Initialization:**
    *   **Log Version:** The script first logs its hardcoded version number (e.g., `Running Script Version: 1.0.0`) for diagnostic purposes.
    *   **Read Port Argument:** It reads the port number passed by Gluetun from the first command-line argument (`$1`). If Gluetun were to pass multiple comma-separated ports, the script currently extracts and uses only the *first* one.
    *   **Validate Port:** It checks if the extracted port is a valid number.

3.  **Dependency Check (`curl`):**
    *   The script verifies if the `curl` command-line tool (used for making HTTP API requests) is available within the Gluetun container.
    *   If `curl` is not found, it attempts to install it using the Alpine package manager (`apk add --no-cache curl`). It will exit if `apk` is not found or if the installation fails.

4.  **Wait for qBittorrent:**
    *   The script needs to communicate with the qBittorrent WebUI. It attempts to connect to the address configured in the script (e.g., `http://127.0.0.1:8080`, which assumes qBittorrent is using Gluetun's network stack).
    *   It uses `curl --head` in a loop, checking periodically until the qBittorrent WebUI becomes responsive or a timeout (`WAIT_TIMEOUT`) is reached. This handles cases where qBittorrent might start slower than Gluetun.

5.  **qBittorrent Authentication:**
    *   It sends an HTTP POST request to the qBittorrent WebUI API endpoint (`/api/v2/auth/login`).
    *   The request includes the `QBITTORRENT_USERNAME` and `QBITTORRENT_PASSWORD` specified in the script's configuration section.
    *   If the login is successful, qBittorrent responds with headers including a session cookie (`SID=...`). The script extracts this `SID` value.
    *   *Note: The script attempts to proceed even if SID retrieval fails, in case qBittorrent's "Bypass authentication for clients on localhost" is enabled.*

6.  **Update qBittorrent Port:**
    *   It constructs an API request to update qBittorrent's settings using the `/api/v2/app/setPreferences` endpoint.
    *   The request includes the `SID` cookie (if obtained) for authentication and the `Referer` header.
    *   The data payload specifies the setting to change: `json={"listen_port": <forwarded_port>}`. This is sent using `--data-urlencode`, resulting in an `application/x-www-form-urlencoded` request.
    *   **Response Check:** The script checks the response from qBittorrent. Based on testing, it considers the update successful if the API returns *either* the text `Ok.` *or* an empty response (`""`). Any other response (like `fail`, `forbidden`, or unexpected text) is treated as a warning or error.

7.  **qBittorrent Logout:**
    *   If a session ID (`SID`) was successfully obtained during the login step, the script sends a final API request to `/api/v2/auth/logout` using the `SID`. This cleanly closes the API session with qBittorrent.

8.  **Exit Status:**
    *   The script evaluates whether the "Update qBittorrent Port" step (Step 6) was considered successful (response was `Ok.` or empty).
    *   It exits with a status code `0` if the update was successful.
    *   It exits with a status code `1` if the update failed or encountered an error.
    *   This exit status is reported back to Gluetun and can be seen in the Gluetun logs (e.g., `ERROR [port forwarding] running up command: exit status 1`).

## Notes
This script was created to streamline Gluetun and qBittorrent integration in UnRaid. It’s ideal for users leveraging VPN port forwarding with providers like PIA or ProtonVPN. For additional containers, refer to the Gluetun Docker template’s Chromium example.
