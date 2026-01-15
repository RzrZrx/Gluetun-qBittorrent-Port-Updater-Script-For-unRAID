# Known Issues & Solutions

This document tracks known issues, their workarounds, and current status.

## Active Issues

### None Currently Reported
All reported issues have been resolved or are configuration-related.

---

## Resolved Issues

### 1. Authentication Error - Cannot Retrieve Port (Reported: 2026-01-01)

**Status:** ✅ Resolved - User Configuration Issue  
**Reporter:** bajire72  
**Detailed Guide:** [authentication-error-cannot-retrieve-port.md](responses/authentication-error-cannot-retrieve-port.md)

**Symptoms:**
- Error: `ERROR: Could not retrieve forwarded port from Gluetun`
- Script exits with status 1
- Debug mode shows authentication failures

**Root Cause:**
Authentication not properly configured between Gluetun and the script.

**Recommended Solution:**
Use TOML configuration file with Basic Authentication (most reliable):
1. Create `/mnt/user/appdata/gluetun/auth/config.toml` with Basic Auth credentials
2. Add path mapping in Gluetun: `/gluetun/auth/` → `/mnt/user/appdata/gluetun/auth/` (Name: `HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH`)
3. Set matching script variables: `PORTSYNC_GT_USERNAME` and `PORTSYNC_GT_PASSWORD`
4. Verify credentials match exactly between TOML file and script variables

**Prevention:**
- Follow the installation guide precisely
- Use TOML config with Basic Auth (most reliable)
- Test authentication via browser: `http://your-ip:8000/v1/portforward`
- Verify Gluetun API is accessible before configuring the script

---

## Configuration-Related Issues (Not Bugs)

These are common setup mistakes, not script bugs:

### Port Forwarding Not Working
- **Cause:** VPN provider doesn't support port forwarding or it's not enabled on account
- **Solution:** Verify your VPN plan supports port forwarding and it's enabled

### qBittorrent Not Accessible
- **Cause:** qBittorrent not using Gluetun's network stack
- **Solution:** Ensure qBittorrent container has `--net=container:GluetunVPN` (Unraid 6) or Network Type set to Container:GluetunVPN (Unraid 7)

### Script Timeout Errors
- **Cause:** qBittorrent takes longer than 5 minutes to start
- **Solution:** Increase `PORTSYNC_TIMEOUT` to 600 or higher

### Debug Logs Not Found
- **Cause:** Missing path mapping for `/tmp/gluetun`
- **Solution:** Add the `PORT_FORWARDING_STATUS_FILE` path mapping as described in installation guide

---

## Feature Requests

Track potential enhancements here (can be moved to GitHub Issues when appropriate):

- None currently

---

## Reporting New Issues

Before reporting an issue:
1. ✅ Check this document for known issues
2. ✅ Review the [installation guide](../installation/setup-gluetun-qbittorrent-port-sync.md)
3. ✅ Enable debug mode and check logs
4. ✅ Search existing GitHub issues

When reporting:
- Use the [bug report template](../../.github/ISSUE_TEMPLATE/bug_report.md)
- Include debug logs (sanitize passwords!)
- Provide environment details (Unraid version, VPN provider, etc.)

---

*Last updated: 2026-01-15*
