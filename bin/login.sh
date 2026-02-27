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
