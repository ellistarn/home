#!/bin/bash

# Simple auto-mwinit based on cookie age
COOKIE_FILE="$HOME/.midway/cookie"

# If cookie is older than 8 hours, refresh
if [[ ! -f "$COOKIE_FILE" ]] || [[ $(find "$COOKIE_FILE" -mtime +8h 2>/dev/null) ]]; then
    echo "Refreshing mwinit..."
    mwinit -f
fi
