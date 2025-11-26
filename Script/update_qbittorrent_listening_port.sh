#!/bin/sh
###############################################################################
# Gluetun -> qBittorrent Listening Port Auto-Updater
# Version: 3.8-T (Timeout Protection)
#
# Created by:     RzrZrx (https://github.com/RzrZrx)
# Unraid user:    Zerax (https://forums.unraid.net/profile/176709-zerax)
#
# Repository:     https://github.com/RzrZrx/Gluetun-qBittorrent-Port-Updater-Script-For-unRAID
#
# Description:    Automatically updates qBittorrent's listening port by fetching
#                 it from the Gluetun API.
#
# Features:       - 'PORTSYNC_' prefix for all environment variables
#                 - Configurable Internal IP (default: 127.0.0.1)
#                 - CURL Timeouts (Prevents stalling on bad IPs)
#                 - Secure credential handling
#                 - Debug mode redirects to file
###############################################################################

SCRIPT_VERSION="3.8-T"

###############################################################################
# USER CONFIGURATION
# Values set here act as defaults.
# You can override these by setting 'PORTSYNC_...' variables in Docker.
###############################################################################

# --- Connection Details ---
# Docker Env: PORTSYNC_INTERNAL_ADDRESS (Default: 127.0.0.1)
INTERNAL_IP="${PORTSYNC_INTERNAL_ADDRESS:-127.0.0.1}"

# Docker Env: PORTSYNC_GT_PORT
GLUETUN_PORT="${PORTSYNC_GT_PORT:-8000}"

# Docker Env: PORTSYNC_QB_PORT
QBITTORRENT_PORT="${PORTSYNC_QB_PORT:-8080}"

# --- qBittorrent Credentials ---
# Docker Env: PORTSYNC_QB_USERNAME
QB_USER="${PORTSYNC_QB_USERNAME:-}"

# Docker Env: PORTSYNC_QB_PASSWORD
QB_PASS="${PORTSYNC_QB_PASSWORD:-}"

# --- Gluetun Credentials ---
# Docker Env: PORTSYNC_GT_USERNAME
GT_USER="${PORTSYNC_GT_USERNAME:-}"

# Docker Env: PORTSYNC_GT_PASSWORD
GT_PASS="${PORTSYNC_GT_PASSWORD:-}"

# Docker Env: PORTSYNC_GT_API_KEY
GT_API_KEY="${PORTSYNC_GT_API_KEY:-}"

# --- Script Behavior ---
# Docker Env: PORTSYNC_TIMEOUT (Default: 300s)
WAIT_TIMEOUT="${PORTSYNC_TIMEOUT:-300}"

# Docker Env: PORTSYNC_DEBUG (Default: false)
DEBUG_MODE="${PORTSYNC_DEBUG:-false}"

# Max time (in seconds) for a single curl request to wait before failing
CURL_TIMEOUT=15

# File paths
COOKIE_FILE="/tmp/qb_cookies.txt"
DEBUG_LOG_FILE="/tmp/gluetun/portsync_debug.log"

###############################################################################
# COLORS
###############################################################################
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'

###############################################################################
# FUNCTIONS
###############################################################################

require_tools() {
    if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        return 0
    fi

    echo "Checking required tools (curl, jq)"
    apk update >/dev/null 2>&1
    if ! command -v curl >/dev/null 2>&1; then
        echo "curl missing -> installing"
        apk add --no-cache curl >/dev/null
    fi
    if ! command -v jq >/dev/null 2>&1; then
        echo "jq missing -> installing"
        apk add --no-cache jq >/dev/null
    fi
}

fetch_gluetun_json() {
    local URL="$1"
    
    if [ -n "$GT_API_KEY" ]; then
        curl -fsS --max-time "$CURL_TIMEOUT" -H "X-API-Key: $GT_API_KEY" "$URL"
    elif [ -n "$GT_USER" ] && [ -n "$GT_PASS" ]; then
        curl -fsS --max-time "$CURL_TIMEOUT" -u "$GT_USER:$GT_PASS" "$URL"
    else
        # Attempt no-auth
        curl -fsS --max-time "$CURL_TIMEOUT" "$URL"
    fi
}

qb_login() {
    rm -f "$COOKIE_FILE"

    # Perform login and store cookies in jar
    LOGIN_RESPONSE=$(curl -fsS --max-time "$CURL_TIMEOUT" \
        --cookie-jar "$COOKIE_FILE" \
        --header "Referer: $QB_HOST" \
        --data-urlencode "username=$QB_USER" \
        --data-urlencode "password=$QB_PASS" \
        "$QB_HOST/api/v2/auth/login")

    if [ "$LOGIN_RESPONSE" = "Ok." ]; then
        return 0
    fi
    return 1
}

countdown_wait_for_qb() {
    local WAIT_INTERVAL=5
    local TIME_ELAPSED=0

    echo -e "${BLUE}Waiting for qBittorrent to become available at: ${CYAN}$QB_HOST${RESET}"

    # Using shorter timeout (5s) for connectivity checks to keep loop responsive
    while ! curl -fsS --head --fail --max-time 5 "$QB_HOST" >/dev/null 2>&1; do
        if [ "$TIME_ELAPSED" -ge "$WAIT_TIMEOUT" ]; then
            echo -e "${RED}ERROR: Timeout reached after ${TIME_ELAPSED}s. qBittorrent is not available.${RESET}"
            echo -e "${YELLOW}Troubleshooting Steps:${RESET}"
            echo -e "${YELLOW}1. Check qBittorrent logs for errors.${RESET}"
            echo -e "${YELLOW}2. Verify 'PORTSYNC_QB_PORT' is ${CYAN}$QBITTORRENT_PORT${RESET}${YELLOW}.${RESET}"
            return 1
        fi
        echo -e "${YELLOW}qBittorrent not ready. Retrying (${TIME_ELAPSED}s / ${WAIT_TIMEOUT}s)${RESET}"
        sleep "$WAIT_INTERVAL"
        TIME_ELAPSED=$((TIME_ELAPSED + WAIT_INTERVAL))
    done

    echo -e "${GREEN}qBittorrent is now available! Continuing${RESET}"
    return 0
}

script_exit() {
    echo ""
    if [ "$SCRIPT_SUCCESS" = true ]; then
        echo -e "${GREEN}Script finished successfully.${RESET}"
    else
        echo -e "${RED}Script finished with errors/warnings.${RESET}"
    fi

    echo -e "${YELLOW}--------------------------------------------------------------------------------${RESET} "
    echo -e "${YELLOW}NOTE: If qBittorrent restarts, its listening port may reset.${RESET} "
    echo -e "${YELLOW}To re-sync:${RESET} "
    echo -e "${YELLOW}  Option 1: Simply RESTART the Gluetun container.${RESET} "
    echo -e "${YELLOW}  Option 2: Run the script manually from the Gluetun console:${RESET} "
    echo -e "${CYAN}            /tmp/gluetun/update_qbittorrent_listening_port.sh | tee /proc/1/fd/1${RESET} "
    echo -e "${YELLOW}--------------------------------------------------------------------------------${RESET} "

    if [ "$SCRIPT_SUCCESS" = true ]; then
        exit 0
    else
        exit 1
    fi
}


###############################################################################
# MAIN SCRIPT EXECUTION
###############################################################################

# Check and enable DEBUG mode if requested
# Accepts: true, 1, yes (case insensitive)
case "$(echo "$DEBUG_MODE" | tr '[:upper:]' '[:lower:]')" in
  true|1|yes)
    echo -e "${YELLOW}!!! DEBUG MODE ENABLED (PORTSYNC_DEBUG) !!!${RESET}"
    echo -e "${YELLOW}Verbose output redirected to: ${CYAN}${DEBUG_LOG_FILE}${RESET}"
    
    # Redirect Standard Error (2) to the log file
    exec 2> "$DEBUG_LOG_FILE"
    
    # Print timestamp to the log file
    echo "--- Debug Session Started: $(date) ---" >&2
    
    set -x  # Enable verbose command printing (goes to file now)
    ;;
esac

SCRIPT_SUCCESS=false

require_tools

GLUETUN_IP_URL="http://$INTERNAL_IP:$GLUETUN_PORT/v1/publicip/ip"
GLUETUN_PORT_URL="http://$INTERNAL_IP:$GLUETUN_PORT/v1/portforward"
QB_HOST="http://$INTERNAL_IP:$QBITTORRENT_PORT"

# Fetch Gluetun Data
IP_JSON=$(fetch_gluetun_json "$GLUETUN_IP_URL" 2>/dev/null || echo "")
PORT_JSON=$(fetch_gluetun_json "$GLUETUN_PORT_URL")

if [ -z "$PORT_JSON" ]; then
    echo -e "${RED}ERROR: Could not retrieve forwarded port from Gluetun.${RESET}"
    echo -e "${YELLOW}Check PORTSYNC_GT credentials or if port forwarding is enabled.${RESET}"
    script_exit
fi

# Parse Data
PUBLIC_IP=$(echo "$IP_JSON" | jq -r .public_ip 2>/dev/null || echo "N/A")
REGION=$(echo "$IP_JSON" | jq -r .region 2>/dev/null || echo "N/A")
TIMEZONE=$(echo "$IP_JSON" | jq -r .timezone 2>/dev/null || echo "N/A")
LISTENING_PORT=$(echo "$PORT_JSON" | jq -r .port 2>/dev/null)

# Validate Port
if ! echo "$LISTENING_PORT" | grep -Eq '^[0-9]+$'; then
    echo -e "${RED}ERROR: Invalid port received from Gluetun: '$LISTENING_PORT'${RESET}"
    script_exit
fi

# 5. Display Info Header
echo ""
echo -e "${BLUE}--------------------- Gluetun to qBittorrent Port Updater ----------------------${RESET} "
echo -e "${BLUE}Running Version:  ${CYAN}${SCRIPT_VERSION}${RESET} "
echo -e "${BLUE}Public IP:        ${CYAN}${PUBLIC_IP}${RESET} "
echo -e "${BLUE}Region:           ${CYAN}${REGION}${RESET} "
echo -e "${BLUE}Timezone:         ${CYAN}${TIMEZONE}${RESET} "
echo -e "${BLUE}Internal IP:      ${CYAN}${INTERNAL_IP}${RESET} "
echo -e "${BLUE}Forwarded Port:   ${CYAN}${LISTENING_PORT}${RESET} "
echo ""
echo -e "${BLUE}Created by:       ${BLUE}Unraid user Zerax${RESET} "
echo -e "${BLUE}GitHub:           ${BLUE}https://tinyurl.com/2r5r3m2x${RESET} "
echo ""

# Wait for QB
countdown_wait_for_qb || script_exit

echo -e "${GREEN}Logging in to qBittorrent${RESET}"
qb_login || {
    echo -e "${RED}ERROR: qBittorrent login failed. Check credentials.${RESET}"
    script_exit
}
echo -e "${GREEN}Login successful.${RESET}"

echo -e "${BLUE}Updating qBittorrent listening port to: ${CYAN}${LISTENING_PORT}${RESET}"

# Generate safe JSON using jq
JSON_PAYLOAD=$(jq -n --argjson port "$LISTENING_PORT" '{listen_port: $port}')

# Send Update
UPDATE_RESPONSE=$(curl -sS --max-time "$CURL_TIMEOUT" \
    --cookie "$COOKIE_FILE" \
    --cookie-jar "$COOKIE_FILE" \
    --header "Referer: $QB_HOST" \
    --data-urlencode "json=$JSON_PAYLOAD" \
    "$QB_HOST/api/v2/app/setPreferences")

if [ -z "$UPDATE_RESPONSE" ] || [ "$UPDATE_RESPONSE" = "Ok." ]; then
    echo -e "${BLUE}Update response: ${GREEN}OK${RESET}"
    SCRIPT_SUCCESS=true
else
    echo -e "${BLUE}Update response: ${YELLOW}$UPDATE_RESPONSE${RESET}"
    SCRIPT_SUCCESS=false
fi

# Logout
curl -sS -X POST --max-time "$CURL_TIMEOUT" --cookie "$COOKIE_FILE" "$QB_HOST/api/v2/auth/logout" >/dev/null
rm -f "$COOKIE_FILE"

script_exit
