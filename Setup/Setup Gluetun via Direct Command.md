# Gluetun & qBittorrent Port Sync via Direct Command (wget/curl)

This guide explains how to automatically synchronize the VPN forwarded port from Gluetun with qBittorrent's listening port using **only** Gluetun's `VPN_PORT_FORWARDING_UP_COMMAND` environment variable, without needing a separate script file.

**This method REQUIRES enabling the "Bypass authentication for clients on localhost" option in qBittorrent.**  
Please read the **Security Considerations** section carefully before implementing this method.

## Benefits

*   **Simplicity:** No separate script file to manage, download, or mount. Configuration is entirely within the Gluetun environment variables.
*   **Automatic Updates:** Eliminates manual port configuration errors in qBittorrent.
*   **Optimized Connectivity:** Helps ensure torrent traffic uses the correct forwarded VPN port.

## Prerequisites

### 1. Gluetun Setup
*   Gluetun container running and configured with a VPN provider that supports port forwarding.
*   Port forwarding enabled within Gluetun (see Setup Instructions).

### 2. qBittorrent Setup
*   qBittorrent container running.
*   qBittorrent WebUI must be enabled.
*   **Crucially: "Bypass authentication for clients on localhost" MUST be ENABLED.**
    *   Find this setting in the qBittorrent WebUI: **Tools (Cog icon) > Options > Web UI > Authentication section**. Check the box.
*   qBittorrent must be accessible from *within* the Gluetun container.

### 3. Network Configuration (Recommended)
*   Configure your qBittorrent container to use Gluetun's network. In Unraid's Docker configuration for qBittorrent:
    *   Set **Network Type:** `None`
    *   Add an **Extra Parameter:** `--network=container:gluetun` (replace `gluetun` with the exact name of your Gluetun container if different).
*   This setup ensures the command inside Gluetun can reach qBittorrent via `http://127.0.0.1:<qBittorrent_WebUI_Port>`.

## Setup Instructions

### 1. Configure Gluetun Container
Edit your Gluetun Docker container settings in Unraid (enable Advanced View):

**Add/Set Environment Variables:**
Add or ensure the following **Variables** are set:

*   **`VPN_PORT_FORWARDING`**
    *   **Config Type:** `Variable`
    *   **Name:** `VPN_PORT_FORWARDING`
    *   **Key:** `VPN_PORT_FORWARDING`
    *   **Value:** `on`
    *   **Description:** `REQUIRED: Enables port forwarding feature in Gluetun.`

*   **`PORT_FORWARD_ONLY`** (Optional but Recommended)
    *   **Config Type:** `Variable`
    *   **Name:** `PORT_FORWARD_ONLY`
    *   **Key:** `PORT_FORWARD_ONLY`
    *   **Value:** `true`
    *   **Description:** `OPTIONAL: Instructs Gluetun to only connect to VPN servers that support port forwarding.`

*   **`VPN_PORT_FORWARDING_UP_COMMAND`**
    *   **Config Type:** `Variable`
    *   **Name:** `VPN_PORT_FORWARDING_UP_COMMAND`
    *   **Key:** `VPN_PORT_FORWARDING_UP_COMMAND`
    *   **Value (Using `wget`):**
        ```bash
        sh -c 'wget --retry-connrefused --tries=6 -qO- --post-data="json={\"listen_port\":{{PORTS}}}" http://127.0.0.1:8585/api/v2/app/setPreferences || echo "qBittorrent port update via wget failed (exit code $?)"'
        ```
    *   **Value (Using `curl` - alternative if `wget` is missing):**
        ```bash
        sh -c 'curl -sS --fail --retry 6 --retry-connrefused --header "Referer: http://127.0.0.1:8585" --data-urlencode "json={\"listen_port\":{{PORTS}}}" "http://127.0.0.1:8585/api/v2/app/setPreferences" || echo "qBittorrent port update via curl failed (exit code $?)"'
        ```
    *   **Description:** `REQUIRED: Executes this command when a port is forwarded. {{PORTS}} is automatically replaced by Gluetun.`
    *   ---
        **NOTE (IP Address):** The address `127.0.0.1` is the **loopback address** inside the Gluetun container. When qBittorrent shares Gluetun's network (`--network=container:gluetun`), this address correctly targets the qBittorrent WebUI running in the same network namespace. It should generally **not** be changed unless you have a very unusual custom network configuration.
        **IMPORTANT (Port):** Replace `8585` in the chosen command value with **your actual qBittorrent WebUI port**.
    *   ---

**No Script Mount Needed:**
*   Unlike the script-based method, you **do not** need to configure any Path mounts for script files.

**Apply Changes:**
Save the changes to your Gluetun container configuration. Gluetun will likely restart.

## Verification

1.  **Check Gluetun Logs:** After Gluetun connects to the VPN and obtains a forwarded port, you should see log entries related to the command execution. If it fails, you might see the `echo` message (e.g., "qBittorrent port update via wget failed..."). Success might be silent or show `wget`/`curl` standard output (if `-q` or `-sS` were removed for debugging).
2.  **Check qBittorrent WebUI:**
    *   Open the qBittorrent WebUI.
    *   Navigate to **Tools (Cog icon) > Options > Connection**.
    *   Verify that the **Listening Port** matches the port reported as forwarded in the Gluetun logs.
3.  **Test Port Forwarding:** Use an online port checking tool to test if the reported port is open on your VPN's public IP address.

## Security Considerations (IMPORTANT!)

Enabling **"Bypass authentication for clients on localhost"** in qBittorrent is **required** for this method to work, but it has significant security implications:

*   **What it Does:** This setting tells qBittorrent *not* to ask for a username, password, or session cookie for any request coming from the same network namespace (`127.0.0.1`, localhost).
*   **The Risk:** By enabling this, **any process running inside the Gluetun container** (or any other container sharing Gluetun's network via `--network=container:gluetun`) can send potentially harmful API commands to your qBittorrent instance without needing credentials.
*   **Potential Actions:** A malicious or compromised process within that network namespace could potentially:
    *   Change *any* qBittorrent setting.
    *   Add or delete torrents.
    *   Pause/resume torrents.
    *   Retrieve information about your torrents.
*   **Contrast with Script Method:** The script-based method does *not* require enabling the bypass setting because it handles authentication using the username and password you provide in the script. Only the script, using those credentials, can modify the port.
*   **Decision:** You need to weigh the simplicity of this direct command method against the reduced security introduced by enabling the authentication bypass. If you run other potentially less trusted containers using Gluetun's network, the risk increases.

## How It Works (Direct Command Method)

1.  **Triggering:** Gluetun connects and gets a forwarded port. It prepares to execute the command specified in `VPN_PORT_FORWARDING_UP_COMMAND`.
2.  **Substitution:** Gluetun replaces the `{{PORTS}}` placeholder in the command string with the actual forwarded port number.
3.  **Execution:** Gluetun executes the resulting command string (e.g., using `sh -c '...'`).
4.  **`wget` or `curl` Action:**
    *   The `wget` or `curl` command attempts to connect to the qBittorrent WebUI at `http://127.0.0.1:<Your_qB_Port>`. Retries are attempted if the connection is initially refused.
    *   It sends an HTTP POST request to the `/api/v2/app/setPreferences` API endpoint.
    *   The `--post-data` or `--data-urlencode` option formats the payload correctly as `json={"listen_port":<forwarded_port>}`.
    *   **Crucially:** No authentication (`SID` cookie) is sent. This relies entirely on the "Bypass authentication..." setting being enabled in qBittorrent for the request to be accepted.
    *   qBittorrent receives the request, and because bypass is enabled and the request is from localhost, it processes the request and changes the listening port. It typically returns a `200 OK` status with an empty body.
5.  **Result:** The qBittorrent listening port is updated to match the VPN forwarded port. The `|| echo ...` part provides minimal feedback in the Gluetun log if the `wget`/`curl` command itself fails (e.g., connection timeout, 404 Not Found, 500 Server Error).

## Basic Troubleshooting

*   **Did you enable "Bypass authentication..." in qBittorrent?** This is the most common reason this method fails (results in `403 Forbidden`).
*   **Is the qBittorrent port correct** in the `VPN_PORT_FORWARDING_UP_COMMAND` value (e.g., `8585`)?
*   **Is qBittorrent using Gluetun's network?** (`--network=container:gluetun`) Required for `127.0.0.1` to work.
*   **Is `wget` or `curl` installed?** Check in the Gluetun console (`wget --version` or `curl --version`). The Gluetun image usually includes `curl`.
*   **Check Gluetun logs** for any error messages output by the command (especially if you remove `-q` from `wget` or `-sS` from `curl` for debugging).
