# Gluetun-qBittorrent-Port-Updater-Script-For-unRAID

## Overview

This is a shell script designed to run within a [Gluetun](https://github.com/qdm12/gluetun) VPN client container. Its primary purpose is to automatically synchronize the listening port in a [qBittorrent](https://www.qbittorrent.org/) instance with the dynamically forwarded port assigned by your VPN provider via Gluetun.

## The Problem Solved

When using Gluetun with VPN providers that support port forwarding, the specific external port assigned to your VPN connection can often change (e.g., when the VPN reconnects or periodically). For optimal P2P performance (especially seeding), qBittorrent's "Listening Port" setting needs to match this external forwarded port.

Manually checking the Gluetun logs or API and updating the qBittorrent setting each time the port changes is tedious and error-prone. This script automates the entire process.

## Features

*   Fetches the currently active forwarded port directly from the Gluetun Control Server API.
*   Supports Gluetun Control Server authentication (if `HTTP_CONTROL_SERVER_USER` and `HTTP_CONTROL_SERVER_PASSWORD` are set).
*   Waits for the qBittorrent WebUI to become available before attempting connection.
*   Authenticates with the qBittorrent WebUI API (v2).
*   Updates the `listen_port` preference within qBittorrent using the fetched port.
*   Logs out of the qBittorrent WebUI session cleanly.
*   Checks for required tools (`curl`, `jq`) within the Gluetun container and attempts installation if missing (Alpine Linux `apk`).
*   Provides informative output to the console during execution.

## Prerequisites

1.  **Running Gluetun Container:** You must have a Gluetun container running and successfully connected to your VPN.
2.  **Port Forwarding Enabled:** Port forwarding must be enabled and working within your Gluetun configuration (`FIREWALL_VPN_INPUT_PORTS` or provider-specific settings) and supported by your VPN provider.
3.  **Running qBittorrent Container:** You need a qBittorrent container running.
4.  **Network Accessibility:** The Gluetun container must be able to reach the qBittorrent container's WebUI. If qBittorrent's network is routed through Gluetun (common setup), `127.0.0.1` is often the correct address *from within the Gluetun container*.
5.  **qBittorrent WebUI Enabled:** The WebUI must be enabled in qBittorrent's settings.
6.  **Gluetun Control Server Enabled:** The HTTP control server must be enabled in Gluetun (default is enabled on port 8000 unless changed via `HTTP_CONTROL_SERVER_ADDRESS`).

## Setup

1.  **Download the Script:** Obtain the `update_qbittorrent_listening_port.sh` script file.
2.  **Place the Script:** Copy the script into a location *accessible from within the running Gluetun container*.
    *   **Recommended:** Use Docker volumes. Map a host directory (e.g., `/path/on/host/gluetun_scripts`) to a directory inside the Gluetun container (e.g., `/scripts`). Place the script in the host directory.
    *   **Alternative (Less Persistent):** Copy the script directly into the running container using `docker cp update_qbittorrent_listening_port.sh <gluetun_container_name_or_id>:/tmp/gluetun/`. Note that `/tmp` might be cleared if the container restarts without a volume mount.
3.  **Configure the Script:** Edit the script and update the configuration variables within the "USER CONFIGURATION" section:
    *   `GLUETUN_PORT`: Port for the Gluetun Control Server (default `8000`).
    *   `QBITTORRENT_PORT`: Port for the qBittorrent WebUI (default `8081`).
    *   `QBITTORRENT_USERNAME`: Your qBittorrent WebUI username.
    *   `QBITTORRENT_PASSWORD`: Your qBittorrent WebUI password.
    *   `GLUETUN_USERNAME`: Your Gluetun Control Server username (if set via `HTTP_CONTROL_SERVER_USER`).
    *   `GLUETUN_PASSWORD`: Your Gluetun Control Server password (if set via `HTTP_CONTROL_SERVER_PASSWORD`).
    *   **Security Note:** Avoid hardcoding sensitive passwords directly in scripts for production environments. Consider using environment variables or Docker secrets if possible.

## Usage

1.  **Access Gluetun Container:** Open a shell/terminal *inside* the running Gluetun container (e.g., `docker exec -it <gluetun_container_name_or_id> /bin/sh`).
2.  **Make Executable:** Navigate to where you placed the script and make it executable:
    ```sh
    chmod +x /path/inside/container/to/update_qbittorrent_listening_port.sh
    ```
    (Replace `/path/inside/container/to/` with the actual path, e.g., `/scripts/` or `/tmp/gluetun/`).
3.  **Run:** Execute the script:
    ```sh
    /path/inside/container/to/update_qbittorrent_listening_port.sh
    ```
    Or explicitly with sh:
    ```sh
    /bin/sh /path/inside/container/to/update_qbittorrent_listening_port.sh
    ```

## Automation (Recommended)

Manually running the script isn't ideal. Here's how to automate it:

**Using Gluetun's `POST_UP_SCRIPT` Environment Variable:**

This is the most common and recommended method. Gluetun will automatically execute this script every time the VPN connection is successfully established.

1.  Ensure the script is placed in a **persistent location** inside the container (using a volume mount).
2.  Set the following environment variable for your Gluetun container:
    ```
    POST_UP_SCRIPT=/path/inside/container/to/update_qbittorrent_listening_port.sh
    ```
3.  Restart your Gluetun container for the environment variable to take effect.

The script will now run automatically after each successful VPN connection, ensuring the port is updated.

## Troubleshooting Common Errors

*   **`jq: parse error: Invalid numeric literal...` or similar `jq` errors:** The response from the Gluetun API (`/v1/openvpn/portforwarded`) was not the expected JSON `{"port": 12345}`.
    *   Check Gluetun logs for errors related to port forwarding.
    *   Manually run `curl -u "user:pass" http://127.0.0.1:8000/v1/openvpn/portforwarded` inside the container to see the raw output.
    *   Ensure port forwarding is actually enabled and working in Gluetun.
*   **`curl: (22) The requested URL returned error: 401 Unauthorized`:** The Gluetun Control Server requires authentication, but the script provided incorrect or no credentials.
    *   Verify `GLUETUN_USERNAME` and `GLUETUN_PASSWORD` in the script match your Gluetun `HTTP_CONTROL_SERVER_USER` and `HTTP_CONTROL_SERVER_PASSWORD` environment variables.
*   **`Login to qBittorrent failed. Could not retrieve SID.`:** The script could not log into the qBittorrent WebUI.
    *   Verify `QBITTORRENT_USERNAME` and `QBITTORRENT_PASSWORD` are correct.
    *   Ensure the `QBITTORRENT_HOST` (derived from `QBITTORRENT_PORT`) is correct and reachable from within the Gluetun container (`http://127.0.0.1:8081` is common).
    *   Check if the qBittorrent WebUI is enabled and accessible.
*   **`Timeout reached. qBittorrent is not available...`:** The script waited for the qBittorrent WebUI to respond at the specified address and port, but it didn't become available within the timeout period.
    *   Ensure the qBittorrent container is running.
    *   Verify the `QBITTORRENT_PORT` is correct.
    *   Check network connectivity between Gluetun and qBittorrent.
*   **Port Not Updated in qBittorrent (but script reports success):**
    *   Double-check the listening port setting in the qBittorrent WebUI itself.
    *   Ensure the qBittorrent API endpoint (`/api/v2/app/setPreferences`) is correct for your version.

## Acknowledgements

*   Script originally created by Unraid user Zerax (Reddit user u/Snowbreath).
*   Modifications and debugging assistance provided via user feedback.

## License

(Optional: Add a license if you wish, e.g., MIT License)
