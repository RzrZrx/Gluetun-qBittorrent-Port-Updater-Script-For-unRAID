#!/bin/sh

# Gluetun-qBittorrent Port Updater Script for unRAID (UP_COMMAND Version)
#
# Created by:     Unraid user Zerax (Reddit: u/Snowbreath, GitHub: RzrZrx)
# Repository:     https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID
# Version:        1.0.0 (UP_COMMAND adaptation, accepts empty response, add colorized restart note)
# Last Updated:   2025-04-22 (Colorized note, added current port to example)
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
QBITTORRENT_PORT=8080                                        # Default qBittorrent WebUI port

# qBittorrent WebUI Credentials
QBITTORRENT_USERNAME="your_qBittorrent_control_user"         # Replace with your qBittorrent username
QBITTORRENT_PASSWORD="your_qBittorrent_control_password"     # Replace with your qBittorrent password

# --- END USER CONFIGURATION ---

# --- SCRIPT LOGIC ---

# ANSI Color Codes
COLOR_YELLOW='\033[1;33m' # Bold Yellow
COLOR_RESET='\033[0m'     # Reset colors

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

UPDATE_RESPONSE=$(eval $CURL_COMMAND)

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
     # Use echo -e to enable interpretation of backslash escapes (like color codes)
     echo -e "${COLOR_YELLOW}---------------------------------------------------------------------${COLOR_RESET}"
     echo -e "${COLOR_YELLOW}NOTE: If you restart the qBittorrent container, its listening port${COLOR_RESET}"
     echo -e "${COLOR_YELLOW}may reset to the value saved in its config file. To re-sync:${COLOR_RESET}"
     echo -e "${COLOR_YELLOW}  Option 1: Simply RESTART the Gluetun container.${COLOR_RESET}"
     echo -e "${COLOR_YELLOW}            (Gluetun will re-run this script on successful reconnect).${COLOR_RESET}"
     echo -e "${COLOR_YELLOW}  Option 2: Run this script manually from the Gluetun console with${COLOR_RESET}"
     echo -e "${COLOR_YELLOW}            the current Gluetun port (e.g., port $LISTENING_PORT used above):${COLOR_RESET}"
     # Embed the actual port number ($LISTENING_PORT) in the example command
     echo -e "${COLOR_YELLOW}            /gluetun/scripts/update_qb_port.sh $LISTENING_PORT${COLOR_RESET}"
     echo -e "${COLOR_YELLOW}---------------------------------------------------------------------${COLOR_RESET}"
     exit 0
else
     echo "Script finished with errors/warnings during port update."
     exit 1
fi
