## Bug Description
The qb_login function reports a login failure against current qBittorrent versions even when authentication is successful, causing the script to exit with ERROR: qBittorrent login failed. Check credentials.

## Environment
- **Unraid Version**: 7.2.3
- **Gluetun Version**: Latest
- **qBittorrent Version**: 5.2.0
- **Script Version**: v3.9-F
- **VPN Provider**: PIA

## Steps to Reproduce
Run the script against a modern qBittorrent with valid credentials.
Observe the login error.

## Expected Behavior
Successful login to qBittorrent

## Actual Behavior
Error due to invalid credentials.

## Root cause
Root cause

```
The function checks for the literal string "Ok." in the response body:
LOGIN_RESPONSE=$(curl -fsS ... "$QB_HOST/api/v2/auth/login")
if [ "$LOGIN_RESPONSE" = "Ok." ]; then
    return 0
fi
return 1
```

Recent qBittorrent versions (4.6+/5.x) changed the /api/v2/auth/login response on success from:

Old: HTTP 200 + body "Ok." + Set-Cookie: QBT_SID_xxxx=...

to:
New: HTTP 204 No Content + empty body + Set-Cookie: QBT_SID_xxxx=...

Because the body is empty, the "Ok." check fails, even though qBit issued a valid SID cookie (which it only does on successful authentication)

## Suggested fix:
Detect success by the presence of a QBT_SID cookie in the cookie jar rather than by response body. This is version-agnostic — works for both the legacy "Ok." response and the new 204 response, and reflects what actually matters (the cookie is what subsequent calls use to authenticate).
```
qb_login() {
    rm -f "$COOKIE_FILE"

    curl -sS --max-time "$CURL_TIMEOUT" \
        -o /dev/null \
        --cookie-jar "$COOKIE_FILE" \
        --header "Referer: $QB_HOST" \
        --data-urlencode "username=$QB_USER" \
        --data-urlencode "password=$QB_PASS" \
        "$QB_HOST/api/v2/auth/login"

    if [ -f "$COOKIE_FILE" ] && grep -q "QBT_SID" "$COOKIE_FILE"; then
        return 0
    fi
    return 1
}
```