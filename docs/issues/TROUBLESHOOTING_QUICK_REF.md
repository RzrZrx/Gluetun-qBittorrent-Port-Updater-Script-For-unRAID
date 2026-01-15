# Troubleshooting Quick Reference

Quick diagnostic commands and common fixes for the Gluetun qBittorrent Port Synchronization Script.

## 🚨 First Steps - Always Do This

### 1. Enable Debug Mode
Add to Gluetun container:
```
PORTSYNC_DEBUG=true
```
Restart Gluetun, then view logs:

**From Unraid terminal:**
```bash
docker exec -it gluetun cat /tmp/gluetun/portsync_debug.log
```

**Or via appdata (if path mapping configured):**
```bash
cat /mnt/user/appdata/gluetun/scripts/portsync_debug.log
```

> **Tip:** Replace `gluetun` with your container name/ID. Use `docker ps` to list containers.

### 2. Check Gluetun Got a Forwarded Port
```bash
docker logs gluetun 2>&1 | grep -i "port forwarding"
```

> **Tip:** Replace `gluetun` with your container name/ID. Use `docker ps` to list containers.

Should show: `[port forwarding] port forwarded is 12345`

### 3. Test Gluetun API

**Via browser (easiest for Basic Auth):**
```
http://your-unraid-ip:8000/v1/portforward
```
Browser will prompt for username/password.

**Via terminal (works with both auth methods):**
```bash
docker exec -it gluetun curl -u "username:password" http://127.0.0.1:8000/v1/portforward
```

> **Tip:** Replace `gluetun` with your container name/ID. Use `docker ps` to list containers.

---

## 🔧 Common Error Messages

### "Could not retrieve forwarded port from Gluetun"
**Cause:** Authentication issue or Gluetun doesn't have a port  
**Fix:**
1. Verify authentication method matches (basic vs API key)
2. Check Gluetun logs for successful port forwarding
3. Test API manually with curl commands above

### "qBittorrent not ready after X seconds"
**Cause:** qBittorrent slow to start or wrong port  
**Fix:**
1. Verify `PORTSYNC_QB_PORT` matches qBittorrent WebUI port
2. Increase `PORTSYNC_TIMEOUT` to 600
3. Check qBittorrent is using Gluetun's network

### "Authentication failed" (qBittorrent)
**Cause:** Wrong qBittorrent credentials  
**Fix:**
1. Verify `PORTSYNC_QB_USERNAME` and `PORTSYNC_QB_PASSWORD`
2. Try logging into qBittorrent WebUI with same credentials
3. Check for special characters needing escaping

### "Script finished with errors/warnings"
**Cause:** Generic error, need to check debug log  
**Fix:** View debug log with command in "First Steps"

---

## 📋 Environment Variable Checklist

### Required in Gluetun:
- [ ] `VPN_PORT_FORWARDING=on`
- [ ] `PORT_FORWARD_ONLY=true` (recommended)
- [ ] `VPN_PORT_FORWARDING_UP_COMMAND=/bin/sh -c /tmp/gluetun/update_qbittorrent_listening_port.sh`
- [ ] Path mapping: `/gluetun/auth/` → `/mnt/user/appdata/gluetun/auth/` (Name: `HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH`)
- [ ] TOML config file at `/mnt/user/appdata/gluetun/auth/config.toml` with Basic Auth credentials

### Required for Script (in Gluetun container):
- [ ] `PORTSYNC_QB_USERNAME=your_qb_user`
- [ ] `PORTSYNC_QB_PASSWORD=your_qb_pass`
- [ ] `PORTSYNC_GT_USERNAME=your_gt_user` (must match TOML config)
- [ ] `PORTSYNC_GT_PASSWORD=your_gt_pass` (must match TOML config)

### Optional but Helpful:
- [ ] `PORTSYNC_DEBUG=true` (for troubleshooting)
- [ ] `PORTSYNC_TIMEOUT=300` (increase if qBittorrent slow to start)

---

## 🔍 Diagnostic Commands

### Check qBittorrent Listening Port
```bash
docker exec -it qbittorrent cat /config/qBittorrent/qBittorrent.conf | grep "Connection\\\\PortRangeMin"
```

### Verify Network Configuration
**Unraid 6:**
```bash
docker inspect qbittorrent | grep -A5 NetworkMode
```
Should show: `container:gluetun`

**Unraid 7:**
Check container settings show Network Type: Container (GluetunVPN)

### Test qBittorrent API Access from Gluetun
```bash
docker exec -it gluetun curl -I http://127.0.0.1:8080
```
Should return HTTP 200 or redirect to login

### Check Script Permissions
```bash
docker exec -it gluetun ls -la /tmp/gluetun/update_qbittorrent_listening_port.sh
```
Should show: `-rwxr-xr-x` (executable)

---

## 🎯 VPN Provider-Specific Notes

### PIA (Private Internet Access)
- ✅ Fully supported
- Port forwarding requires specific server selection
- Use `PORT_FORWARD_ONLY=true`

### ProtonVPN
- ✅ Supported (paid plans only)
- Port forwarding only on select servers
- May require specific VPN server selection

### Mullvad
- ⚠️ Mullvad removed port forwarding (March 2023)
- Script won't work with Mullvad

### Other Providers
Check Gluetun documentation for port forwarding support

---

## 📞 Getting Help

1. Check [Known Issues](KNOWN_ISSUES.md)
2. Review [Installation Guide](../installation/setup-gluetun-qbittorrent-port-sync.md)
3. Search [GitHub Issues](https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID/issues)
4. Open a new issue using the [bug report template](../../.github/ISSUE_TEMPLATE/bug_report.md)

**When asking for help, always include:**
- Debug log output (sanitize passwords!)
- Unraid version
- Gluetun version
- VPN provider
- Relevant environment variables

---

*Last updated: 2026-01-15*
