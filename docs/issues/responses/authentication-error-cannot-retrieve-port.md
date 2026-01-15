# Response to bajire72 - Issue with Port Forwarding Retrieval

---

Hi @bajire72,

Thanks for reporting this issue! The error `ERROR: Could not retrieve forwarded port from Gluetun` typically indicates an authentication or configuration problem with the Gluetun Control Server. Since debug mode is already enabled, let's troubleshoot step by step.

## 1️⃣ Check the Debug Log

First, let's see the **full debug log** which will show us exactly what's failing.

**Method A: Via Docker Command (From Unraid Terminal)**

Run this command from your **Unraid terminal** (SSH or local console):
```bash
docker exec -it gluetun cat /tmp/gluetun/portsync_debug.log
```

> **Tip:** Replace `gluetun` with your container name or use the container ID. Run `docker ps` to list all containers.

**Method B: Via Unraid Appdata (From Unraid Terminal)**

Run this from your **Unraid terminal**:
```bash
cat /mnt/user/appdata/gluetun/scripts/portsync_debug.log
```

> **Note:** Method B only works if you have the `PORT_FORWARDING_STATUS_FILE` path mapping configured correctly in your Gluetun container (Container Path: `/tmp/gluetun` → Host Path: `/mnt/user/appdata/gluetun/scripts/`).

**Method C: From Inside Gluetun Container Console**

If you're already inside the Gluetun container console (via Unraid Docker UI):
```bash
cat /tmp/gluetun/portsync_debug.log
```

Please share the output (but **sanitize any passwords** before posting).

---

## 2️⃣ Common Causes & Solutions

### ⚠️ Recommended Authentication Setup

**Use TOML Config with Basic Auth (Most Reliable)**

The most reliable authentication method is using a TOML configuration file with basic authentication. This method always works and is easier to troubleshoot.

**Step 1: Create the TOML config file**

Create `/mnt/user/appdata/gluetun/auth/config.toml` with:

```toml
# Gluetun Control Server Authentication Configuration
# File: /mnt/user/appdata/gluetun-nginx/auth/config.toml

[[roles]]
name = "qbittorrent"

# List of ALL GET routes from the official Gluetun control server docs
routes = [
  # VPN
  "GET /v1/vpn/status",
  "GET /v1/vpn/settings",

  # Port Forwarding
  "GET /v1/portforward",

  # DNS
  "GET /v1/dns/status",

  # Updater
  "GET /v1/updater/status",

  # Public IP
  "GET /v1/publicip/ip"
]

auth = "basic"
username = "my_gt_username"
password = "my_gt_password"

# You could add other roles below if needed for different users/scripts
# [[roles]]
# name = "another_role"
# ...
```

**Step 2: Add path mapping in Gluetun container**

In Unraid Docker, edit your Gluetun container and click **"Add another Path, Port, Variable..."**

Configure the path mapping as follows:
- **Config Type:** Path
- **Name:** `HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH`
- **Container Path:** `/gluetun/auth/`
- **Host Path:** `/mnt/user/appdata/gluetun/auth/`
- **Access Mode:** Read/Write
- **Description:** (Optional) `Path to Gluetun authentication config`

![Gluetun Path Mapping Configuration](file:///C:/Users/roger_stenersen.no/.gemini/antigravity/brain/1d2cae82-8964-4d72-a2d8-caf7b9b31da4/gluetun_path_mapping_config.png)

> **Note:** The **Name** field `HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH` serves as both the path mapping name and the environment variable that Gluetun uses to locate the config file at `/gluetun/auth/config.toml`.

**Step 3: Add matching script variables**
```
PORTSYNC_GT_USERNAME=my_gt_username
PORTSYNC_GT_PASSWORD=my_gt_password
```

> **Critical:** The username/password in the TOML file MUST match the `PORTSYNC_GT_USERNAME` and `PORTSYNC_GT_PASSWORD` variables exactly.

---

### 🔍 Verify Authentication is Working

**Test via Browser (Easiest):**

Open your browser and go to:
```
http://your-unraid-ip:8000/v1/portforward
```

Replace `your-unraid-ip` with your actual server IP. When prompted, enter your Gluetun username and password from the TOML file.

> **Note:** Replace port `8000` if you changed the Gluetun Control Server port.

✅ **Expected:** Browser displays JSON like `{"port": 12345}`  
❌ **If 401 Error:** Credentials don't match or TOML file isn't loaded

**Test via Terminal:**

```bash
docker exec -it gluetun curl -u "your_username:your_password" http://127.0.0.1:8000/v1/portforward
```

> **Tip:** Replace `gluetun` with your container name/ID. Use `docker ps` to list containers.

---

### 🔧 Verify Port Forwarding is Enabled

Check these environment variables in your **Gluetun container**:

```
VPN_PORT_FORWARDING=on
PORT_FORWARD_ONLY=true
```

---

### 📋 Verify Port Forwarding is Actually Working

Check if Gluetun successfully obtained a forwarded port from your VPN:

```bash
docker logs gluetun 2>&1 | grep -i "port forwarding"
```

> **Tip:** Replace `gluetun` with your container name/ID. Use `docker ps` to list containers.

You should see something like:
```
[port forwarding] port forwarded is 12345
```

If you **don't see this**, then:
- Your VPN provider may not support port forwarding  
- Your VPN account may not have port forwarding enabled
- The VPN server you're connected to may not support it
- Check that `VPN_PORT_FORWARDING=on` in Gluetun

---

## 3️⃣ Environment Information

Please share the following (so I can help better):

- **Unraid Version:** (e.g., 6.12.14 or 7.0.0)
- **Gluetun Version/Tag:** (e.g., `latest` or `v3.38.0`)
- **VPN Provider:** (e.g., PIA, ProtonVPN, Mullvad)
- **Authentication Method Used:** (Basic Auth or API Key)
- **Relevant Gluetun Environment Variables** (sanitize passwords):
  - `VPN_PORT_FORWARDING`
  - `PORT_FORWARD_ONLY`
  - `HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE`
- **Script Environment Variables** (sanitize passwords):
  - `PORTSYNC_GT_USERNAME` / `PORTSYNC_GT_PASSWORD` OR `PORTSYNC_GT_API_KEY`
  - `PORTSYNC_GT_PORT`
  - `PORTSYNC_INTERNAL_ADDRESS`

---

## 📌 Quick Checklist

- [ ] Debug log checked for specific error
- [ ] Verified authentication method matches between Gluetun and script variables
- [ ] Tested Gluetun API manually with curl
- [ ] Confirmed Gluetun successfully obtained a forwarded port from VPN
- [ ] Verified all environment variable names are spelled correctly (case-sensitive!)

---

Let me know what you find, and we'll get this sorted! 🚀

---

**Best regards,**  
[Your Name]
RzrZrx

---
