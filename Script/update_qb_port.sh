#!/bin/sh

# Gluetun-qBittorrent Port Updater Script for unRAID (UP_COMMAND Version)
#
# Created by:     Unraid user Zerax (Reddit: u/Snowbreath, GitHub: RzrZrx)
# Adapted for UP_COMMAND based on Gluetun v4 documentation
# Repository:     https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID
# Version:        1.1.0 (UP_COMMAND adaptation)
# Last Updated:   2025-04-21 (Assumed date from original)
# Description:    Automatically updates qBittorrent's port based on the port
#                 provided by Gluetun's VPN_PORT_FORWARDING_UP_COMMAND.
# Notes:          This script is intended to be called by Gluetun itself.

echo "Script created by Unraid user Zerax (Reddit: u/Snowbreath, GitHub: RzrZrx)"
echo "Adapted for Gluetun's UP_COMMAND."

# --- START USER CONFIGURATION ---

# Set qBittorrent details
QBITTORRENT_PORT=8585               # Default qBittorrent WebUI port

# qBittorrent WebUI Credentials
QBITTORRENT_USERNAME="your_qBittorrent_control_user"        # Replace with your qBittorrent username
QBITTORRENT_PASSWORD="your_qBittorrent_control_password!"   # Replace with your qBittorrent password

# --- END USER CONFIGURATION ---

# --- SCRIPT LOGIC ---

# Check for the port argument passed by Gluetun's UP_COMMAND
if [ -z "$1" ]; then
    echo "Error: No port argument received from Gluetun UP_COMMAND."
    echo "Ensure this script is called like: /path/to/script.sh {{PORTS}}"
    exit 1
fi

RECEIVED_PORTS="$1"
echo "Received port argument(s) from Gluetun: $RECEIVED_PORTS"

# Extract the first port if multiple are provided (comma-separated)
# qBittorrent typically uses only one listening port.
LISTENING_PORT=$(echo "$RECEIVED_PORTS" | cut -d ',' -f 1)

# Validate the extracted port
if ! echo "$LISTENING_PORT" | grep -qE '^[0-9]+$'; then
    echo "Error: Invalid port number extracted: [$LISTENING_PORT] from input [$RECEIVED_PORTS]"
    exit 1
fi

echo "Using listening port for qBittorrent: $LISTENING_PORT"

# Check for missing tools (curl) - jq is no longer strictly needed by this script
echo "Checking for required tools (curl)..."
if ! command -v curl > /dev/null 2>&1; then
    echo "curl not found. Installing..."
    # Assuming apk is the package manager in the Gluetun container
    apk add --no-cache curl
else
    echo "curl is already installed."
fi
# Ensure 'cut' and 'grep' are available (usually are in Alpine base)
if ! command -v cut > /dev/null 2>&1 || ! command -v grep > /dev/null 2>&1; then
    echo "Error: Required command 'cut' or 'grep' not found. This is unexpected."
    exit 1
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

# Step 1: Log in to qBittorrent to retrieve the SID
echo "Logging in to qBittorrent..."
LOGIN_RESPONSE_HEADERS=$(curl -sS -i \
    --cookie-jar /dev/null \
    --header "Referer: $QBITTORRENT_HOST" \
    --data-urlencode "username=$QBITTORRENT_USERNAME" \
    --data-urlencode "password=$QBITTORRENT_PASSWORD" \
    "$QBITTORRENT_HOST/api/v2/auth/login")

COOKIE=$(echo "$LOGIN_RESPONSE_HEADERS" | grep -ioE 'SID=[^;]+' | sed 's/SID=//i')

if [ -z "$COOKIE" ]; then
    echo "Login to qBittorrent failed. Could not retrieve SID. Check credentials and qBittorrent availability."
    echo "Check if qBittorrent option 'Bypass authentication for clients on localhost' is enabled."
    echo "If bypass is enabled, login might fail, but the update may still work if bypass is incorrectly handled by qBittorrent's API response in some versions."
    echo "Login Response Headers:"
    echo "$LOGIN_RESPONSE_HEADERS"
    # Do not exit immediately if bypass might be enabled, try the update anyway
    # exit 1 # <-- Commented out
fi
if [ -n "$COOKIE" ]; then
    echo "Login successful. SID: $COOKIE"
else
    echo "Could not retrieve SID. Proceeding without SID (might work if qBittorrent bypasses auth for localhost)..."
fi

# Step 2: Update the listening port in qBittorrent
echo "Updating listening port in qBittorrent to $LISTENING_PORT..."
JSON_PAYLOAD="{\"listen_port\": $LISTENING_PORT}"

# Construct curl command - conditionally add cookie header
CURL_COMMAND="curl -sS"
if [ -n "$COOKIE" ]; then
    CURL_COMMAND="$CURL_COMMAND --cookie \"SID=$COOKIE\""
fi
CURL_COMMAND="$CURL_COMMAND \
    --header \"Referer: $QBITTORRENT_HOST\" \
    --data-urlencode \"json=$JSON_PAYLOAD\" \
    \"$QBITTORRENT_HOST/api/v2/app/setPreferences\""

echo "Executing: $CURL_COMMAND" # Debugging curl command
UPDATE_RESPONSE=$(eval $CURL_COMMAND) # Use eval to correctly handle quotes in cookie command

# Check response
if [ -z "$UPDATE_RESPONSE" ]; then
    echo "qBittorrent listening port update command sent. Assumed success (empty response)."
elif [ "$UPDATE_RESPONSE" = "Ok." ]; then
    echo "qBittorrent listening port updated successfully to $LISTENING_PORT (Response: Ok.)."
elif echo "$UPDATE_RESPONSE" | grep -qi "fail"; then # Check for failure keywords
     echo "Failed to update qBittorrent port. Response: $UPDATE_RESPONSE"
     # Attempt logout only if we logged in successfully
     if [ -n "$COOKIE" ]; then
         echo "Attempting logout despite update failure..."
         curl -sS -X POST --cookie "SID=$COOKIE" --header "Referer: $QBITTORRENT_HOST" "$QBITTORRENT_HOST/api/v2/auth/logout" > /dev/null
         echo "Logout attempt finished."
     fi
     exit 1
else
    echo "Update response from qBittorrent: $UPDATE_RESPONSE"
    echo "Warning: Received unexpected response, but the port might still be updated. Check qBittorrent settings."
fi

# Step 3: Log out from qBittorrent (only if we logged in successfully)
if [ -n "$COOKIE" ]; then
    echo "Logging out from qBittorrent..."
    LOGOUT_RESPONSE=$(curl -sS -X POST \
        --cookie "SID=$COOKIE" \
        --header "Referer: $QBITTORRENT_HOST" \
        "$QBITTORRENT_HOST/api/v2/auth/logout")

    if [ -z "$LOGOUT_RESPONSE" ]; then
        echo "Logout successful."
    elif [ "$LOGOUT_RESPONSE" = "Ok." ]; then
        echo "Logout successful (Response: Ok.)."
    else
        echo "Warning: Logout response from qBittorrent: $LOGOUT_RESPONSE"
    fi
else
    echo "Skipping logout as no SID was obtained."
fi

echo "Script finished successfully."
exit 0