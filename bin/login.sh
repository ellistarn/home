#!/bin/bash

# Refreshes midway cookie via mwinit -f.
# --check: only refresh if cookie is missing or stale (used by .zshrc)
# No args: always refresh (manual use)

COOKIE_FILE="$HOME/.midway/cookie"
MAX_AGE="8h"

needs_refresh() {
    [[ ! -f "$COOKIE_FILE" ]] || [[ $(find "$COOKIE_FILE" -mtime +$MAX_AGE 2>/dev/null) ]]
}

refresh() {
    echo "Refreshing mwinit..."
    if ! mwinit -f; then
        echo "mwinit failed — removing cookie so next attempt starts clean."
        rm -f "$COOKIE_FILE"
        return 1
    fi
}

if [[ "$1" == "--check" ]]; then
    needs_refresh && refresh
else
    refresh
fi

# Start dev tunnel if not already running
PORT="${DEV_DESKTOP_TUNNEL_PORT:-}"
if [[ -n "${DEV_DESKTOP_HOST:-}" ]] && [[ -n "$PORT" ]] && ! lsof -i :"$PORT" -sTCP:LISTEN &>/dev/null; then
    echo "Starting dev tunnel to ${DEV_DESKTOP_HOST}..."
    ssh -f -N -L "$PORT":localhost:"$PORT" "$DEV_DESKTOP_HOST" 2>/dev/null
fi
