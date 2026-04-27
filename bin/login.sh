#!/bin/bash

# Idempotent gate for Midway auth and dev desktop tunnel.
#
# --check  (from .zshrc): read-only validation. Warns on problems, never prompts.
# No args  (manual use): force-refresh cookie, restart tunnel, sync credentials to dev desktop.

COOKIE_FILE="$HOME/.midway/cookie"
SSH_CERT="$HOME/.ssh/id_ecdsa-cert.pub"
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

ssh_cert_valid() {
    [[ -f "$SSH_CERT" ]] || return 1
    local end
    end=$(ssh-keygen -L -f "$SSH_CERT" 2>/dev/null \
        | sed -n 's/.*Valid:.*to \(.*\)/\1/p')
    [[ -n "$end" ]] || return 1
    local exp_epoch now_epoch
    exp_epoch=$(date -d "$end" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$end" +%s 2>/dev/null)
    now_epoch=$(date +%s)
    [[ -n "$exp_epoch" ]] && (( now_epoch < exp_epoch ))
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

# Sync midway cookie and SSH certificate to the dev desktop so that
# a single mwinit on the laptop covers both machines.  Requires the
# same ~/.ssh/id_ecdsa key pair on both hosts.
sync_credentials() {
    [[ -n "$HOST" ]] || return 0
    local ok=0
    for f in "$COOKIE_FILE" "$SSH_CERT"; do
        [[ -f "$f" ]] || continue
        # Use ~/ destination so paths resolve on the remote host,
        # not the local one (macOS /Users/x vs Linux /home/x).
        local dest="~/${f#"$HOME"/}"
        if scp -q -o ConnectTimeout=5 "$f" "$HOST:$dest" 2>/dev/null; then
            echo "Synced $(basename "$f") → $HOST"
        else
            echo "Failed to sync $(basename "$f") to $HOST" >&2
            ok=1
        fi
    done
    return $ok
}

if [[ "$1" == "--check" ]]; then
    cookie_valid || { echo "Midway cookie is invalid or missing. Run login.sh to refresh."; }
    ssh_cert_valid || { echo "SSH certificate is expired or missing. Run login.sh to refresh."; }
    tunnel_running || start_tunnel
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
    sync_credentials
fi
