#!/bin/bash
# Syncs service configs from ~/.services to system locations.
# Idempotent - safe to rerun. Linux only.

[[ "$(uname)" == "Linux" ]] || { echo "Skipping (not Linux)"; exit 0; }
#
# - Copies systemd units to /etc/systemd/system/
# - Copies Caddy config to /etc/caddy/
# - Prunes services no longer in ~/.services/systemd/
# - Reloads/restarts only when changed

set -eu

SERVICES_DIR="$HOME/.services"
SYSTEMD_SRC="$SERVICES_DIR/systemd"
CADDY_SRC="$SERVICES_DIR/caddy"
SYSTEMD_DEST="/etc/systemd/system"
CADDY_DEST="/etc/caddy"
MARKER="# Managed by ~/.services"

changed=false

##### Sync systemd units #####

declare -a managed_services=()

for src in "$SYSTEMD_SRC"/*.service; do
    [[ -f "$src" ]] || continue
    
    name=$(basename "$src")
    managed_services+=("$name")
    dest="$SYSTEMD_DEST/$name"
    
    # Add marker to track managed services
    content="$MARKER"$'\n'"$(cat "$src")"
    
    if [[ -f "$dest" ]] && [[ "$(cat "$dest")" == "$content" ]]; then
        echo "$name: unchanged"
    else
        echo "$name: updating"
        echo "$content" | sudo tee "$dest" > /dev/null
        changed=true
    fi
done

##### Prune orphaned services #####

for dest in "$SYSTEMD_DEST"/*.service; do
    [[ -f "$dest" ]] || continue
    
    name=$(basename "$dest")
    
    # Skip if not managed by us
    head -1 "$dest" | grep -q "^$MARKER" || continue
    
    # Skip if still in source
    printf '%s\n' "${managed_services[@]}" | grep -qx "$name" && continue
    
    echo "$name: removing (orphaned)"
    sudo systemctl stop "$name" 2>/dev/null || true
    sudo systemctl disable "$name" 2>/dev/null || true
    sudo rm "$dest"
    changed=true
done

##### Sync Caddy config #####

if [[ -d "$CADDY_SRC" ]]; then
    # Caddyfile
    if [[ -f "$CADDY_SRC/Caddyfile" ]]; then
        content="$MARKER"$'\n'"$(cat "$CADDY_SRC/Caddyfile")"
        if [[ -f "$CADDY_DEST/Caddyfile" ]] && [[ "$(cat "$CADDY_DEST/Caddyfile")" == "$content" ]]; then
            echo "Caddyfile: unchanged"
        else
            echo "Caddyfile: updating"
            echo "$content" | sudo tee "$CADDY_DEST/Caddyfile" > /dev/null
            changed=true
        fi
    fi
    
    # Static files (www/)
    if [[ -d "$CADDY_SRC/www" ]]; then
        sudo mkdir -p "$CADDY_DEST/www"
        for src in "$CADDY_SRC/www"/*; do
            [[ -f "$src" ]] || continue
            name=$(basename "$src")
            dest="$CADDY_DEST/www/$name"
            if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
                echo "www/$name: unchanged"
            else
                echo "www/$name: updating"
                sudo cp "$src" "$dest"
                changed=true
            fi
        done
    fi
fi

##### Reload and enable #####

if [[ "$changed" == "true" ]]; then
    echo ""
    echo "Reloading systemd..."
    sudo systemctl daemon-reload
fi

for name in "${managed_services[@]}"; do
    if ! systemctl is-enabled "$name" &>/dev/null; then
        echo "Enabling $name"
        sudo systemctl enable "$name"
    fi
    
    if [[ "$changed" == "true" ]]; then
        echo "Restarting $name"
        sudo systemctl restart "$name"
    elif ! systemctl is-active "$name" &>/dev/null; then
        echo "Starting $name"
        sudo systemctl start "$name"
    fi
done

echo ""
echo "Done. Status:"
for name in "${managed_services[@]}"; do
    status=$(systemctl is-active "$name" 2>/dev/null || echo "unknown")
    echo "  $name: $status"
done
