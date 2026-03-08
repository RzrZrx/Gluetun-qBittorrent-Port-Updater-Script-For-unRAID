# Bug Report: Gluetun API Deadlock on `/v1/portforward` (Newer Versions)

**Reported:** 2026-03-08  
**Status:** ✅ Resolved in Script v3.9-F  
**Affects:** Gluetun `latest` image (build `2026-03-08`, commit `57c53bc` and newer)  
**Reporter:** RzrZrx (self-reported during testing)

---

## Symptoms

- Script error: `ERROR: Could not retrieve forwarded port from Gluetun`
- `curl` times out on `GET /v1/portforward` (exit code 28)
- The timeout duration **always matches** the configured `CURL_TIMEOUT` exactly
- `GET /v1/publicip/ip` works instantly (within microseconds)
- Gluetun server log shows a `200` response written **after** the curl timeout:
  ```
  INFO [http server] 200 GET /v1/portforward wrote 15B to 127.0.0.1:36012 in 30.00933837s
  ```

## Root Cause: Lock Inversion (Self-Deadlock)

In newer Gluetun versions, the port forwarding goroutine holds a mutex lock while executing the `VPN_PORT_FORWARDING_UP_COMMAND`. When the script calls `GET /v1/portforward`, the HTTP handler tries to acquire the **same lock** — creating a deadlock:

```
Port Forwarding Goroutine
│
├── Acquires lock on port forwarding state
├── Writes port to /tmp/gluetun/forwarded_port
├── Executes up-command script (WAITS for exit)
│   │
│   └── Script calls GET /v1/portforward
│       └── HTTP handler needs the same lock → BLOCKED
│
└── Cannot release lock until script exits
    └── Script cannot exit until curl times out
```

The cycle breaks only when `curl` hits its `--max-time` limit and aborts, allowing the script to exit and release the lock. This is why the Gluetun response time always equals the curl timeout.

**Note:** `GET /v1/publicip/ip` is unaffected because it uses a separate data structure with its own lock.

## Resolution

**Script v3.9-F** implements a **file-first** port reading strategy:

1. **Primary:** Read the port from `/tmp/gluetun/forwarded_port` (written by Gluetun *before* the up-command runs — no API call, no lock contention)
2. **Fallback:** Call the API only if the file doesn't exist (for manual/standalone script execution)

### Relevant Code Change

```diff
-PORT_JSON=$(fetch_gluetun_json "$GLUETUN_PORT_URL")
-LISTENING_PORT=$(echo "$PORT_JSON" | jq -r .port)
+if [ -f "$PORT_FILE" ]; then
+    LISTENING_PORT=$(cat "$PORT_FILE" 2>/dev/null | tr -d '[:space:]')
+fi
+
+if [ -z "$LISTENING_PORT" ]; then
+    # Fallback to API (for manual runs only)
+    PORT_JSON=$(fetch_gluetun_json "$GLUETUN_PORT_URL")
+    LISTENING_PORT=$(echo "$PORT_JSON" | jq -r .port)
+fi
```

## Additional Issue: Windows Line Endings (CRLF)

During debugging, it was also discovered that editing the script on Windows introduces `\r\n` line endings. When mounted into the Alpine Linux container, the shebang `#!/bin/sh\r` causes a misleading error:

```
/bin/sh: /tmp/gluetun/update_qbittorrent_listening_port.sh: not found
```

**Fix:** Added `.gitattributes` to force `*.sh` files to always use LF line endings in git.

## How to Verify

After updating to v3.9-F, the Gluetun log should show:

```
INFO [port forwarding] Read forwarded port from file: 31247
```

Instead of the previous timeout pattern. The script should complete in seconds, not minutes.

---

*This is a Gluetun-side issue (lock contention in the HTTP control server). It may be fixed in a future Gluetun release. The file-first approach is the recommended workaround and is more efficient regardless.*
