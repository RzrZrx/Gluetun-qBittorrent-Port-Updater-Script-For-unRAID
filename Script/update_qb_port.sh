#!/bin/sh

# Gluetun-qBittorrent Port Updater Script for unRAID (UP_COMMAND Version)
#
# Created by:     Unraid user Zerax (Reddit: u/Snowbreath, GitHub: RzrZrx)
# Repository:     https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID
# Version:        1.0.0 (UP_COMMAND adaptation, accepts empty response, simplified version log)
# Last Updated:   2025-04-22 (Simplified version logging)
# Description:    Automatically updates qBittorrent's port based on the port
#                 provided by Gluetun's VPN_PORT_FORWARDING_UP_COMMAND.
# Notes:          This script is intended to be called by Gluetun itself.

# --- Log Version (Simplified) ---
# Manually set the version here - MUST MATCH the '# Version:' line above
SCRIPT_VERSION="1.0.0"
echo "--- Gluetun-qBittorrent Port Updater Script ---"
echo "Running Script Version: $SCRIPT_VERSION"
echo "Created by: Unraid user Zerax (Reddit: u/Snowbreath, GitHub: RzrZrx)"
# --- End Version Logging ---


# --- START USER CONFIGURATION ---

# Set qBittorrent details
QBITTORRENT_PORT=8080                                      # Default qBittorrent WebUI port

# qBittorrent WebUI Credentials
QBITTORRENT_USERNAME="your_qBittorrent_control_user"       # Replace with your qBittorrent username
QBITTORRENT_PASSWORD="your_qBittorrent_control_password!"  # Replace with your qBittorrent password

# --- END USER CONFIGURATION ---

# --- SCRIPT LOGIC ---

# Variable to track if the update step was considered successful
UPDATE_SUCCESSFUL=false

# Check for the port argument passed by Gluetun's UP_COMMAND
if [ -z "$1" ]; then
    echo "Error: No port argument received from Gluetun UP_COMMAND."
    echo "Ensure this script is called like: /path/to/script.sh {{PORTS}}"
    exit 1
fi

RECEIVED_PORTS="$1"
echo "Received port argument(s) from Gluetun: $RECEIVED_PORTS"

LISTENING_PORT=$(echo "$RECEIVED_PORTS" | cut -d ',' -f 1)

if ! echo "$LISTENING_PORT" | grep -qE '^[0-9]+$'; then
    echo "Error: Invalid port number extracted: [$LISTENING_PORT] from input [$RECEIVED_PORTS]"
    exit 1
fi

echo "Using listening port for qBittorrent: $LISTENING_PORT"

echo "Checking for required tool (curl)..."
if ! command -v curl > /dev/null 2>&1; then
    echo "curl not found. Installing..."
    if command -v apk > /dev/null 2>&1; then
        apk add --no-cache curl
        if ! command -v curl > /dev/null 2>&1; then
             echo "Error: Failed to install curl. Cannot proceed."
             exit 1
        fi
    else
        echo "Error: 'apk' package manager not found. Cannot install curl automatically."
        exit 1
    fi
else
    echo "curl is already installed."
fi

QBITTORRENT_HOST="http://127.0.0.1:$QBITTORRENT_PORT"
echo "Waiting for qBittorrent to be available at $QBITTORRENT_HOST..."
WAIT_TIMEOUT=300
WAIT_INTERVAL=5
TIME_ELAPSED=0

while ! curl -fsS --head --fail "$QBITTORRENT_HOST" > /dev/null; do
    CURL_EXIT_CODE=$?
    if [ "$TIME_ELAPSED" -ge "$WAIT_TIMEOUT" ]; then
        echo "Timeout reached. qBittorrent is not available at $QBITTORRENT_HOST (Last curl code: $CURL_EXIT_CODE). Exiting."
        exit 1
    fi
    echo "qBittorrent is not available yet (curl code: $CURL_EXIT_CODE). Retrying in $WAIT_INTERVAL seconds..."
    sleep "$WAIT_INTERVAL"
    TIME_ELAPSED=$((TIME_ELAPSED + WAIT_INTERVAL))
done
echo "qBittorrent is available. Proceeding with the script..."

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
    echo "Login Response Headers:"
    echo "$LOGIN_RESPONSE_HEADERS"
fi
if [ -n "$COOKIE" ]; then
    echo "Login successful. SID: $COOKIE"
else
    echo "Could not retrieve SID. Proceeding without SID (might work if qBittorrent bypasses auth for localhost)..."
fi

echo "Updating listening port in qBittorrent to $LISTENING_PORT..."
JSON_PAYLOAD="{\"listen_port\": $LISTENING_PORT}"

# Construct curl command string for eval
CURL_COMMAND="curl -sS"
if [ -n "$COOKIE" ]; then
    CURL_COMMAND="$CURL_COMMAND --cookie 'SID=$COOKIE'"
fi
CURL_COMMAND="$CURL_COMMAND \
    --header 'Referer: $QBITTORRENT_HOST' \
    --data-urlencode 'json=$JSON_PAYLOAD' \
    '$QBITTORRENT_HOST/api/v2/app/setPreferences'"

# Removing the Debug Executing command line now as things seem stable
# echo "Debug: Executing command: eval $CURL_COMMAND"
UPDATE_RESPONSE=$(eval $CURL_COMMAND)
# Removing the Debug Raw response line now as things seem stable
# echo "Debug: Raw update response: [$UPDATE_RESPONSE]"

# Check response: Treat "Ok." OR an empty response as SUCCESS for this endpoint
if [ "$UPDATE_RESPONSE" = "Ok." ] || [ -z "$UPDATE_RESPONSE" ]; then
    if [ "$UPDATE_RESPONSE" = "Ok." ]; then
        echo "qBittorrent listening port updated successfully to $LISTENING_PORT (Response: Ok.)."
    else
        echo "qBittorrent listening port updated successfully to $LISTENING_PORT (Confirmed via empty response)."
    fi
    UPDATE_SUCCESSFUL=true # Mark update as successful
elif [ -n "$COOKIE" ] && echo "$UPDATE_RESPONSE" | grep -qi "forbidden"; then
     echo "Warning: Received 'forbidden' response after login. This might happen if 'Bypass authentication for clients on localhost' is enabled AND you provided credentials. Please verify port in WebUI."
elif echo "$UPDATE_RESPONSE" | grep -qi "fail"; then
     echo "Error: Failed to update qBittorrent port. Response: $UPDATE_RESPONSE"
else
    echo "Error: Received unexpected response from qBittorrent update: [$UPDATE_RESPONSE]. Expected 'Ok.' or empty."
fi

# Log out from qBittorrent (only if we logged in successfully)
if [ -n "$COOKIE" ]; then
    echo "Logging out from qBittorrent..."
    LOGOUT_RESPONSE=$(curl -sS -X POST \
        --cookie "SID=$COOKIE" \
        --header "Referer: $QBITTORRENT_HOST" \
        "$QBITTORRENT_HOST/api/v2/auth/logout")

    if [ "$LOGOUT_RESPONSE" = "Ok." ] || [ -z "$LOGOUT_RESPONSE" ]; then
        echo "Logout successful."
    else
        echo "Warning: Logout response from qBittorrent: $LOGOUT_RESPONSE"
    fi
else
    echo "Skipping logout as no SID was obtained."
fi

# Final exit status based on whether the update was marked successful
if [ "$UPDATE_SUCCESSFUL" = true ]; then
     echo "Script finished successfully."
     exit 0
else
     echo "Script finished with errors/warnings during port update."
     exit 1
fi