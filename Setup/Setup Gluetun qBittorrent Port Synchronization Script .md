# Wiki: Home

## Gluetun to qBittorrent Port Sync

**Version:** 3.8-T  
**Platform:** Docker / Unraid / Alpine Linux

This script automates the process of updating qBittorrent's listening port when using **Gluetun VPN** with dynamic port forwarding. It fetches the forwarded port from the Gluetun API and updates the qBittorrent preferences via its WebUI API.

### Key Features
*   **Robust Syncing:** Waits for qBittorrent to become available (handling container startup race conditions).
*   **Secure:** Supports Docker Environment Variables to keep credentials out of the script file.
*   **Reliable:** Uses a "Cookie Jar" for session management and includes connection timeouts to prevent stalling.
*   **Safety:** Validates JSON data using `jq` to prevent configuration corruption.
*   **Debug Mode:** Built-in troubleshooting redirects verbose logs to a file to keep your console clean.

---

# Installation Guide

## Prerequisites
*   A **Gluetun** container (VPN Client).
*   A **qBittorrent** container.
*   Your VPN provider must support port forwarding, and it must be enabled in the settings.
    (Tested with PIA (Private Internet Access)

### Variables to Set
- `HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH` (Optional – Recommended)
- `HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE` (Optional – Alternative)
- `PORT_FORWARD_ONLY`
- `VPN_PORT_FORWARDING`
- `VPN_PORT_FORWARDING_UP_COMMAND`
- `PORTSYNC_QB_USERNAME`
- `PORTSYNC_QB_PASSWORD`
- `PORTSYNC_INTERNAL_ADDRESS`
- `PORTSYNC_GT_PORT`
- `PORTSYNC_QB_PORT`
- `PORTSYNC_GT_USERNAME`(Optional – Recommended)
- `PORTSYNC_GT_PASSWORD`(Optional – Recommended)
- `PORTSYNC_GT_API_KEY`(Optional – Alternative)
- `PORTSYNC_TIMEOUT`
- `PORTSYNC_DEBUG`
- `qBittorrent WebUI Port`
- `WebBrowser WebUI Port` (Optional)  

### Path to Set
- `HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH` (Optional – Recommended)
- `PORT_FORWARDING_STATUS_FILE`

---

## Step 1: Save the Script
1.  Download the script file (`update_qbittorrent_listening_port.sh`).
2.  Save it to a persistent location on your server (e.g., `/mnt/user/appdata/gluetun/scripts/`).

## Step 2: File Permissions
Before running the script, ensure it is executable. Use one of the following methods:

**Option 1: From Unraid Host Terminal**
Run the following command in your Unraid terminal:
```bash
chmod +x /mnt/user/appdata/gluetun/scripts/update_qbittorrent_listening_port.sh
```

**Option 2: From Gluetun Console**
Use the following command inside the Gluetun VPN Client Console:
```bash
chmod +x /tmp/gluetun/update_qbittorrent_listening_port.sh
```

---

## Step 3: Gluetun Docker Configuration

For the script to work, it must be able to communicate with the Gluetun Control Server (port 8000).

### 1. Set Gluetun Credentials (Required)
**This is the step where you CREATE the Username and Password (or API Key) for Gluetun.**
You are defining these credentials now so the script can log in to the VPN container later.

**Choose ONLY ONE of the following methods** (Method 1 or Method 2).

> **Tip:** If you prefer **API Key** authentication, run this command in the Unraid terminal to generate a random key:
> ```bash
> docker run --rm qmcgaw/gluetun genkey
> # Output example: 5HuQ3QpsZ7o6XKbawtvgvEY
> ```

#### Method 1: Environment Variable (For the lazies not willing to setup a configuration file)
Use the `HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE` variable to set your credentials globally.

Add this **Variable** to your Gluetun container:
*   **Config Type:** Variable
*   **Name:** HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE
*   **Key:** `HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE`
*   **Value:** `*(Copy one of the JSON strings below)*`
*   **Description:** Defines the Gluetun Control Credentials.

**Option A: Basic Authentication (User/Pass)**
*Replace `my_gt_username` and `my_gt_password` with the actual credentials you want to use.*
```json
{"auth":"basic","username":"my_gt_username","password":"my_gt_password"}
```

**Option B: API Key Authentication**
*Replace the `apikey` value with your generated key.*
```json
{"auth":"apikey","apikey":"5HuQ3QpsZ7o6XKbawtvgvEY"}
```

> **Note:** Remember the credentials you set here. You will need to enter these exact values into the script variables in the next step.

---

#### Method 2: Configuration File Advanced (Recommended)
Use `HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH` to point to a TOML file. This allows for multiple roles and fine-grained control.

**1. Create the Config File**
Create a file named `config.toml` on your host (e.g., `/mnt/user/appdata/gluetun/auth/config.toml`).

**Example TOML (Basic Auth):**
```toml
[[roles]]
name = "qbittorrent"
routes = [
  # Port Forwarding
  "GET /v1/portforward",

  # Public IP
  "GET /v1/publicip/ip"
]

auth = "basic"
username = "my_gt_username"
password = "my_gt_password"
```

**Example TOML (API Key):**
```toml
[[roles]]
name = "qbittorrent"
routes = [
  # Port Forwarding
  "GET /v1/portforward",

  # Public IP
  "GET /v1/publicip/ip"
]

auth = "apikey"
apikey = "5HuQ3QpsZ7o6XKbawtvgvEY"
```

---

### 1. Mount the Config File
In your Gluetun Docker settings, add a new **Path**:
*   **Config Type:** Path
*   **Name:** `HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH`
*   **Container Path:** `/gluetun/auth/`
*   **Host Path:** `/mnt/user/appdata/gluetun/auth/`
*   **Access:** Read Only
*   **Description:** Defines the path where Gluetun finds the config.toml file

### 2. Add Script & Status Mappings

**Add the Status File Path:**
*   **Config Type:** Path
*   **Name:** `PORT_FORWARDING_STATUS_FILE`
*   **Container Path:** `/tmp/gluetun`
*   **Host Path:** `/mnt/user/appdata/gluetun/scripts/`
*   **Access:** Read/Write
*   **Description:** Defines the path where Gluetun writes status files (and where our script resides).

---

### 3. Add Environment Variables

**Enable Port Forwarding Only:**
*   **Config Type:** Variable
*   **Name:** PORT_FORWARD_ONLY
*   **Key:** `PORT_FORWARD_ONLY`
*   **Value:** `true`
*   **Description:** Forces Gluetun to only connect to servers that support port forwarding.

**Activate VPN Port Forwarding:**
*   **Config Type:** Variable
*   **Name:** VPN_PORT_FORWARDING
*   **Key:** `VPN_PORT_FORWARDING`
*   **Value:** `on`
*   **Description:** Enables port forwarding on the VPN server.

**Automation Command:**
*   **Config Type:** Variable
*   **Name:** VPN_PORT_FORWARDING_UP_COMMAND
*   **Key:** `VPN_PORT_FORWARDING_UP_COMMAND`
*   **Value:** `/bin/sh -c /tmp/gluetun/update_qbittorrent_listening_port.sh`
*   **Description:** Specifies the command to execute whenever the port forwarding status is updated.

### 2. Port Mappings (Add these to GLUETUN)
Since qBittorrent is attached to Gluetun's network, you must define the WebUI ports **inside the Gluetun container settings**, not qBittorrent.

**qBittorrent WebUI Port:**
*   **Config Type:** Port
*   **Name:** bittorrent WebUI Port
*   **Container Port:** `8080`
*   **Host Port:** `8080`
*   **Connection Type:** TCP
*   **Description:** Configures the port used by qBittorrent’s web user interface, default port 8080.

**Firefox/Chromium WebUI Port (Optional if you want to access the web through the VPN):**
*   **Config Type:** Port
*   **Name:** Firefox WebUI Port
*   **Container Port:** `3000`
*   **Host Port:** `3000`
*   **Connection Type:** TCP
*   **Description:** Configures the port used by the web user interface, default port 3000.

## Step 4: Script Configuration

You can configure the script behavior entirely using **Environment Variables** added to your **Gluetun** container. This keeps your credentials secure and allows you to update settings without editing the script file.

### Connection Settings

**Internal IP Address:**
*   **Config Type:** Variable
*   **Name:** PORTSYNC Internal IP
*   **Key:** `PORTSYNC_INTERNAL_ADDRESS`
*   **Default Value:** `127.0.0.1`
*   **Description:** The IP address used to communicate between containers. Leave as default if containers share the same network stack (Sidecar/Bundle).

**Gluetun API Port:**
*   **Config Type:** Variable
*   **Name:** PORTSYNC Gluetun API Port
*   **Key:** `PORTSYNC_GT_PORT`
*   **Default Value:** `8000`
*   **Description:** The port Gluetun's API listens on (Control Server), default port 8000.

**qBittorrent WebUI Port:**
*   **Config Type:** Variable
*   **Name:** PORTSYNC qBittorrent Port
*   **Key:** `PORTSYNC_QB_PORT`
*   **Default Value:** `8080`
*   **Description:** The WebUI port of qBittorrent, default port 8080).
*   **Note:** If your qBittorrent uses different port you must change this variable.

### qBittorrent Credentials

**qBittorrent Username:**
*   **Config Type:** Variable
*   **Name:** PORTSYNC qBittorrent Username
*   **Key:** `PORTSYNC_QB_USERNAME`
*   **Default Value:** `my_qb_username` *(Replace with your qBittorrent Username)*
*   **Description:** Your qBittorrent WebUI username.

**qBittorrent Password:**
*   **Config Type:** Variable
*   **Name:** PORTSYNC qBittorrent Password
*   **Key:** `PORTSYNC_QB_PASSWORD`
*   **Default Value:** `my_qb_password` *(Replace with your qBittorrent Password)*
*   **Description:** Your qBittorrent WebUI password.

### Gluetun Credentials

Choose ONE of the following methods to match your Gluetun Control Server configuration.

#### Method 1: Basic Authentication (User/Password)
Use this if you configured Gluetun with a username and password.

**Gluetun Username:**
*   **Config Type:** Variable
*   **Name:** PORTSYNC Gluetun Username
*   **Key:** `PORTSYNC_GT_USERNAME`
*   **Default Value:** `my_gt_username` *(Replace with your Gluetun Username)*
*   **Description:** Gluetun Control Server username.

**Gluetun Password:**
*   **Config Type:** Variable
*   **Name:** PORTSYNC Gluetun Password
*   **Key:** `PORTSYNC_GT_PASSWORD`
*   **Default Value:** `my_gt_password` *(Replace with your Gluetun Password)*
*   **Description:** Gluetun Control Server password.

#### Method 2: API Key Authentication
Use this if you configured Gluetun with an API Key.

**Gluetun API Key:**
*   **Config Type:** Variable
*   **Name:** PORTSYNC Gluetun API Key
*   **Key:** `PORTSYNC_GT_API_KEY`
*   **Default Value:** `5HuQ3QpsZ7o6XKbawtvgvEY` *(Replace with your Gluetun API Key)*
*   **Description:** The 22-character API key generated by Gluetun.

### Script Behavior

**Wait Timeout:**
*   **Config Type:** Variable
*   **Name:** PORTSYNC Wait Timeout
*   **Key:** `PORTSYNC_TIMEOUT`
*   **Default Value:** `300`
*   **Description:** Time (in seconds) to wait for qBittorrent to start before giving up.

**Debug Mode:**
*   **Config Type:** Variable
*   **Name:** PORTSYNC Debug Mode
*   **Key:** `PORTSYNC_DEBUG`
*   **Default Value:** `false`
*   **Description:** Set to `true` to enable verbose logging to file (`/tmp/gluetun/portsync_debug.log`).

---

## Step 5: qBittorrent Docker Configuration
For this setup to work, qBittorrent must route its traffic through the Gluetun container.

### 1. Network Setup
When routing traffic through the Gluetun container, you must ensure the **WebUI URL** in the Unraid Docker template does not use Unraid’s default placeholder syntax.

Instead of using the template defaults, replace the entry with your server’s **actual static IP address** and the mapped port.

*   **Change from:** `http://[IP]:[PORT:8080]`
*   **Change to:** `http://192.168.1.50:8080` *(Replace with your Unraid Server IP)*

> **Important:** This rule applies to **all** containers that route their traffic through Gluetun (e.g., sabnzbd, hexchat, firefox). Hardcoding the IP ensures the WebUI icon in the Unraid dashboard functions correctly.

**qBittorrent - Environment variables (Unraid 6.12.14)**
*Turn on Advanced view in template*
*   **WebUI:** `http://192.168.1.50:8080/`  (Replace with your actual Server IP)
*   **Extra Parameters:** `--net=container:GluetunVPN`
*   **Network Type:** None

**qBittorrent - Environment variables (Unraid 7)**
*Turn on Advanced view in template*
*   **WebUI:** `http://192.168.1.50:8080/`  (Replace with your actual Server IP) 
*   **Network Type:** Container
*   **Container Network:** GluetunVPN

---

# Troubleshooting

## Debug Mode
If the script isn't working, enable Debug Mode to see exactly what is happening.

1.  Add the variable `PORTSYNC_DEBUG` with value `true` to your Gluetun container.
2.  Restart the container.
3.  View the logs by running this command in the Unraid terminal:

```bash
docker exec -it gluetun cat /tmp/gluetun/portsync_debug.log
```

> **WARNING:** Debug logs may contain your passwords in plain text (inside `curl` commands). **Always set `PORTSYNC_DEBUG` back to `false`** when you are done troubleshooting.

## Common Issues

**1. "qBittorrent not ready" Timeout**
*   **Cause:** qBittorrent takes longer than 5 minutes (300s) to start, or the script cannot reach the IP/Port.
*   **Fix:** Check if `PORTSYNC_QB_PORT` matches your qBittorrent WebUI port. If your server is slow, increase `PORTSYNC_TIMEOUT` to `600`.

**2. "Script finished with errors/warnings"**
*   **Cause:** Usually incorrect credentials or a changed IP address.
*   **Fix:** Check the container logs. If you see authentication errors, verify `PORTSYNC_QB_USERNAME` and `PORTSYNC_QB_PASSWORD`.

**3. Console Color Bleeding**
*   **Issue:** The "Running Version" line in the logs is colored Blue/Cyan when it shouldn't be.
*   **Cause:** A cosmetic issue with how the Gluetun logger wraps ANSI color codes.
*   **Impact:** Harmless. The script logic is unaffected.

# License

MIT License
