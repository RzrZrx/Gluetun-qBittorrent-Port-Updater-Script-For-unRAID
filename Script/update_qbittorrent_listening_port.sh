#!/bin/sh

# Script created by Unraid user Zerax (Reddit user u/Snowbreath).
# Modified with debugging and authentication fixes.
echo "Script created by Unraid user Zerax (Reddit user u/Snowbreath)"

# Before running the script, ensure it has executable permissions.
# Use the following command inside the Gluetun VPN Client Console terminal
# to set the correct permissions and make the script executable:
# chmod +x /tmp/gluetun/update_qbittorrent_listening_port.sh

# --- START USER CONFIGURATION ---

# Set constants
GLUETUN_PORT=8000                   # Default Gluetun control server port
QBITTORRENT_PORT=8080               # Default qBittorrent WebUI port

# qBittorrent WebUI Credentials
QBITTORRENT_USERNAME="your_qBittorrent_control_user" # Replace with your qBittorrent username
QBITTORRENT_PASSWORD="your_qBittorrent_control_password"     # Replace with your qBittorrent password

# Gluetun Control Server Credentials (if you set HTTP_CONTROL_SERVER_USER/PASSWORD)
GLUETUN_USERNAME="your_gluetun_control_user"   # <--- CHANGE THIS to your Gluetun control user
GLUETUN_PASSWORD="your_gluetun_control_password" # <--- CHANGE THIS to your Gluetun control password

# --- END USER CONFIGURATION ---

# Consider using environment variables or secrets management for credentials in production environments

# Check for missing tools (curl and jq) and install them if needed
echo "Checking for required tools (curl and jq)..."

if ! command -v curl > /dev/null 2>&1; then
    echo "curl not found. Installing..."
    apk add --no-cache curl
else
    echo "curl is already installed."
fi

if ! command -v jq > /dev/null 2>&1; then
    echo "jq not found. Installing..."
    apk add --no-cache jq
else
    echo "jq is already installed."
fi

# Wait for qBittorrent host to be available
QBITTORRENT_HOST="http://127.0.0.1:$QBITTORRENT_PORT"
echo "Waiting for qBittorrent to be available at $QBITTORRENT_HOST..."
WAIT_TIMEOUT=300  # Timeout in seconds (e.g., 5 minutes)
WAIT_INTERVAL=5   # Interval between checks (e.g., 5 seconds)
TIME_ELAPSED=0

# Use curl -fsS --head to check availability silently but show errors
while ! curl -fsS --head --fail "$QBITTORRENT_HOST" > /dev/null; do
    if [ "$TIME_ELAPSED" -ge "$WAIT_TIMEOUT" ]; then
        echo "Timeout reached. qBittorrent is not available at $QBITTORRENT_HOST. Exiting."
        exit 1
    fi
    echo "qBittorrent is not available yet. Retrying in $WAIT_INTERVAL seconds..."
    sleep "$WAIT_INTERVAL"
    TIME_ELAPSED=$((TIME_ELAPSED + WAIT_INTERVAL))
done
echo "qBittorrent is available. Proceeding with the script..."

# Step 1: Fetch the listening port from Gluetun
GLUETUN_PORT_URL="http://127.0.0.1:$GLUETUN_PORT/v1/openvpn/portforwarded"
echo "Fetching listening port from Gluetun URL: $GLUETUN_PORT_URL"

# Use curl -fsS to fail silently on HTTP errors but show other errors (like connection refused)
# Add the -u option for basic authentication using Gluetun credentials
GLUETUN_RESPONSE=$(curl -fsS -u "$GLUETUN_USERNAME:$GLUETUN_PASSWORD" "$GLUETUN_PORT_URL")
CURL_EXIT_CODE=$?

echo "Curl exit code: $CURL_EXIT_CODE"
echo "Raw Gluetun Response: [$GLUETUN_RESPONSE]" # Brackets help visualize empty/whitespace responses

if [ $CURL_EXIT_CODE -ne 0 ]; then
    # Check if the error is an HTTP error (like 401)
    if [ $CURL_EXIT_CODE -eq 22 ]; then
        # Attempt a non-failing curl to get the response body for better error message
        ERROR_BODY=$(curl -sS -u "$GLUETUN_USERNAME:$GLUETUN_PASSWORD" "$GLUETUN_PORT_URL")
        if echo "$ERROR_BODY" | grep -qi "unauthorized"; then # Check case-insensitively
             echo "Failed to fetch data from Gluetun: Received 401 Unauthorized. Check GLUETUN_USERNAME and GLUETUN_PASSWORD in the script."
        else
             echo "Failed to fetch data from Gluetun (HTTP error, curl code: $CURL_EXIT_CODE). Response body: [$ERROR_BODY]"
        fi
    else
        # Handle non-HTTP errors (network, connection refused, etc.)
        echo "Failed to fetch data from Gluetun (Network/other error, curl code: $CURL_EXIT_CODE)."
    fi
    echo "Please also check if Gluetun is running, port forwarding is active in Gluetun settings, and the URL/port ($GLUETUN_PORT_URL) is correct."
    exit 1
fi


if [ -z "$GLUETUN_RESPONSE" ]; then
    echo "Received empty response from Gluetun. Cannot extract port."
    echo "This might mean port forwarding is disabled or not yet active."
    exit 1
fi

# Try to parse the port using jq
# Use || true to prevent script exit if jq fails, then check the result
LISTENING_PORT=$(echo "$GLUETUN_RESPONSE" | jq -er .port || true)
# -e sets exit code on error, -r outputs raw string

# Check if jq produced valid output (non-empty and numeric)
if ! echo "$LISTENING_PORT" | grep -qE '^[0-9]+$'; then
    echo "Failed to parse valid port number from Gluetun response using jq."
    echo "JQ Input (Raw Gluetun Response): [$GLUETUN_RESPONSE]"
    echo "JQ Output (Attempted Port): [$LISTENING_PORT]"
    exit 1
fi

echo "Fetched listening port: $LISTENING_PORT"

# Step 2: Log in to qBittorrent to retrieve the SID
echo "Logging in to qBittorrent..."
# Use --cookie-jar /dev/null to avoid issues with multiple Set-Cookie headers if any
LOGIN_RESPONSE_HEADERS=$(curl -sS -i \
    --cookie-jar /dev/null \
    --header "Referer: $QBITTORRENT_HOST" \
    --data-urlencode "username=$QBITTORRENT_USERNAME" \
    --data-urlencode "password=$QBITTORRENT_PASSWORD" \
    "$QBITTORRENT_HOST/api/v2/auth/login")

# More robust SID extraction, case-insensitive grep for Set-Cookie
COOKIE=$(echo "$LOGIN_RESPONSE_HEADERS" | grep -ioE 'SID=[^;]+' | sed 's/SID=//i') # Added 'i' flag to sed for case-insensitivity

if [ -z "$COOKIE" ]; then
    echo "Login to qBittorrent failed. Could not retrieve SID. Check credentials and qBittorrent availability."
    echo "Login Response Headers:"
    echo "$LOGIN_RESPONSE_HEADERS"
    exit 1
fi
echo "Login successful. SID: $COOKIE"

# Step 3: Update the listening port in qBittorrent
echo "Updating listening port in qBittorrent to $LISTENING_PORT..."
# Ensure JSON is correctly formatted
JSON_PAYLOAD="{\"listen_port\": $LISTENING_PORT}"
# Use application/x-www-form-urlencoded as per qBittorrent API docs for setPreferences
UPDATE_RESPONSE=$(curl -sS \
    --cookie "SID=$COOKIE" \
    --header "Referer: $QBITTORRENT_HOST" \
    --data-urlencode "json=$JSON_PAYLOAD" \
    "$QBITTORRENT_HOST/api/v2/app/setPreferences")

# Check response
if [ -z "$UPDATE_RESPONSE" ]; then
    # An empty response usually means success for this API call
    echo "qBittorrent listening port updated successfully to $LISTENING_PORT."
else
    # Non-empty might be "Ok." or an error
    if [ "$UPDATE_RESPONSE" = "Ok." ]; then
         echo "qBittorrent listening port updated successfully to $LISTENING_PORT (Response: Ok.)."
    else
        echo "Update response from qBittorrent: $UPDATE_RESPONSE"
        echo "Warning: Received unexpected response, but the port might still be updated. Check qBittorrent settings."
        # Consider exiting with an error code here if strict checking is needed
        # exit 1
    fi
fi

# Step 4: Log out from qBittorrent
echo "Logging out from qBittorrent..."
LOGOUT_RESPONSE=$(curl -sS -X POST \
    --cookie "SID=$COOKIE" \
    --header "Referer: $QBITTORRENT_HOST" \
    "$QBITTORRENT_HOST/api/v2/auth/logout")

if [ -z "$LOGOUT_RESPONSE" ]; then
    echo "Logout successful."
else
     if [ "$LOGOUT_RESPONSE" = "Ok." ]; then
         echo "Logout successful (Response: Ok.)."
     else
        echo "Warning: Logout response from qBittorrent: $LOGOUT_RESPONSE"
     fi
fi

echo "Script finished."
exit 0
