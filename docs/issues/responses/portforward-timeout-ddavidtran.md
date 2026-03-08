# Response to ddavidtran - Port Forwarding Timeout After Gluetun Update

---

Hi @ddavidtran,

Thanks for reporting this! You've hit a **known bug** introduced in newer Gluetun versions. The good news: this is now fixed in **Script v3.9-F**.

---

## 🔍 What's Happening

Your error is the classic symptom of the **Gluetun API Deadlock**:

```
curl: (28) Operation timed out after 15001 milliseconds with 0 bytes received
ERROR: Could not retrieve forwarded port from Gluetun.
```

In newer Gluetun versions, the port forwarding code **holds a lock** while running the `VPN_PORT_FORWARDING_UP_COMMAND` (your script). When the script calls `GET /v1/portforward`, the HTTP handler needs the **same lock** — creating a deadlock that only breaks when `curl` times out.

This explains your observations perfectly:
- ❌ **Automatic execution fails** — the script runs inside the locked context
- ✅ **Manual execution works** (`Option 2`) — running the script manually doesn't hold the lock

For the full technical breakdown, see: [Gluetun API Deadlock Report](gluetun-api-deadlock-portforward.md)

---

## ✅ The Fix: Update to Script v3.9-F

Script v3.9-F uses a **file-first** strategy: it reads the port from `/tmp/gluetun/forwarded_port` (which Gluetun writes *before* running the script) instead of calling the deadlocked API endpoint. This completely bypasses the issue.

### Step 1: Download the Updated Script

Download `update_qbittorrent_listening_port.sh` (v3.9-F) from the repository.

### Step 2: Replace the Script on Your Server

Copy the updated script to your Gluetun scripts folder, replacing the old one:

```bash
# Example path — adjust to match your setup
cp update_qbittorrent_listening_port.sh /mnt/user/appdata/gluetun/scripts/
```

### Step 3: Ensure Correct Line Endings & Permissions

If you edited the script on Windows, convert the line endings to Unix format:

```bash
sed -i 's/\r$//' /mnt/user/appdata/gluetun/scripts/update_qbittorrent_listening_port.sh
chmod +x /mnt/user/appdata/gluetun/scripts/update_qbittorrent_listening_port.sh
```

### Step 4: Restart Gluetun

Restart your Gluetun container. You should now see this in the logs:

```
INFO [port forwarding] Read forwarded port from file: 31247
```

Instead of the curl timeout error. The script should complete in seconds.

---

## 🔑 Key Changes in v3.9-F

| What Changed | Why |
|---|---|
| Port read from file (`/tmp/gluetun/forwarded_port`) first | Avoids the API deadlock entirely |
| API call kept as fallback | Still works for manual/standalone runs |
| `CURL_TIMEOUT` increased to 30s | Extra safety margin for the API fallback |
| `.gitattributes` added | Prevents Windows line ending issues |

---

## ⚠️ Important: Authentication Config Still Required

Even though the port is now read from a file, you **still need** the Gluetun authentication config if you want the Public IP info to display in the script output (and for the API fallback). Make sure you have one of these configured:

- **Option A:** `HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE` environment variable
- **Option B:** `config.toml` mounted to `/gluetun/auth/config.toml`

See the [Installation Guide](../../installation/setup-gluetun-qbittorrent-port-sync.md) for details.

---

Let me know if the update resolves your issue! 🚀

---

**Best regards,**  
RzrZrx

---
