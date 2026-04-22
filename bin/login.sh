#!/bin/bash

# Idempotent gate for Midway auth and dev desktop tunnel.
#
# --check  (from .zshrc): read-only validation. Warns on problems, never prompts.
# No args  (manual use): force-refresh cookie, restart tunnel.

COOKIE_FILE="$HOME/.midway/cookie"
MIDWAY_URL="https://midway-auth.amazon.com/"
HOST="${DEV_DESKTOP_HOST:-}"
PORT="${DEV_DESKTOP_TUNNEL_PORT:-}"

cookie_valid() {
    [[ -f "$COOKIE_FILE" ]] || return 1
    local code
    code=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 --max-time 5 \
        --cookie "$COOKIE_FILE" "$MIDWAY_URL" 2>/dev/null)
    case "$code" in
        200) return 0 ;;
        000) echo "Cannot reach midway-auth (network issue?)" >&2; return 1 ;;
        *)   return 1 ;;
    esac
}

tunnel_running() {
    [[ -n "$HOST" ]] && [[ -n "$PORT" ]] && lsof -i :"$PORT" -sTCP:LISTEN &>/dev/null
}

kill_tunnel() {
    [[ -n "$PORT" ]] && lsof -ti :"$PORT" -sTCP:LISTEN 2>/dev/null | xargs kill 2>/dev/null
}

start_tunnel() {
    [[ -n "$HOST" ]] && [[ -n "$PORT" ]] || return 0
    ssh -f -N -o ConnectTimeout=5 -L "$PORT":localhost:"$PORT" "$HOST" 2>/dev/null
}

if [[ "$1" == "--check" ]]; then
    tunnel_running && exit 0
    cookie_valid || { echo "Midway cookie is invalid or missing. Run login.sh to refresh."; exit 0; }
    start_tunnel
else
    echo "Refreshing mwinit..."
    if ! mwinit -f; then
        echo "mwinit failed — removing cookie so next attempt starts clean."
        rm -f "$COOKIE_FILE"
        exit 1
    fi
    kill_tunnel
    start_tunnel
    sleep 1
    tunnel_running || { echo "Tunnel failed to start to $HOST:$PORT" >&2; exit 1; }
fi
