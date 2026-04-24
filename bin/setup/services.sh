#!/bin/bash
# Syncs service configs from ~/.services to system locations.
# Idempotent — safe to rerun.
#
# Linux:  systemd units + Caddy config
# macOS:  launchd plists (user agents)

set -eu

SERVICES_DIR="$HOME/.services"
changed=false

##### Helpers #####

marker_comment() {
    local style="$1" # "hash" or "xml"
    case "$style" in
        hash) echo "# Managed by ~/.services" ;;
        xml)  echo "<!-- Managed by ~/.services -->" ;;
    esac
}

has_marker() {
    local file="$1" style="$2"
    head -1 "$file" | grep -q "$(marker_comment "$style")"
}

##### Linux: systemd + caddy #####

sync_systemd() {
    local src_dir="$SERVICES_DIR/systemd"
    local dest_dir="/etc/systemd/system"
    local marker
    marker=$(marker_comment hash)

    declare -a managed_services=()

    for src in "$src_dir"/*.service; do
        [[ -f "$src" ]] || continue

        local name
        name=$(basename "$src")
        managed_services+=("$name")
        local dest="$dest_dir/$name"

        local content="$marker"$'\n'"$(cat "$src")"

        if [[ -f "$dest" ]] && [[ "$(cat "$dest")" == "$content" ]]; then
            echo "$name: unchanged"
        else
            echo "$name: updating"
            echo "$content" | sudo tee "$dest" > /dev/null
            changed=true
        fi
    done

    # Prune orphaned services
    for dest in "$dest_dir"/*.service; do
        [[ -f "$dest" ]] || continue

        local name
        name=$(basename "$dest")
        has_marker "$dest" hash || continue
        [[ ${#managed_services[@]} -gt 0 ]] && printf '%s\n' "${managed_services[@]}" | grep -qx "$name" && continue

        echo "$name: removing (orphaned)"
        sudo systemctl stop "$name" 2>/dev/null || true
        sudo systemctl disable "$name" 2>/dev/null || true
        sudo rm "$dest"
        changed=true
    done

    # Sync Caddy config
    local caddy_src="$src_dir/caddy"
    local caddy_dest="/etc/caddy"

    if [[ -d "$caddy_src" ]]; then
        if [[ -f "$caddy_src/Caddyfile" ]]; then
            local content="$marker"$'\n'"$(cat "$caddy_src/Caddyfile")"
            if [[ -f "$caddy_dest/Caddyfile" ]] && [[ "$(cat "$caddy_dest/Caddyfile")" == "$content" ]]; then
                echo "Caddyfile: unchanged"
            else
                echo "Caddyfile: updating"
                echo "$content" | sudo tee "$caddy_dest/Caddyfile" > /dev/null
                changed=true
            fi
        fi

        if [[ -d "$caddy_src/www" ]]; then
            sudo mkdir -p "$caddy_dest/www"
            for src in "$caddy_src/www"/*; do
                [[ -f "$src" ]] || continue
                local name
                name=$(basename "$src")
                local dest="$caddy_dest/www/$name"
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

    # Reload and enable
    [[ ${#managed_services[@]} -eq 0 ]] && return

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
        local status
        status=$(systemctl is-active "$name" 2>/dev/null || echo "unknown")
        echo "  $name: $status"
    done
}

##### macOS: launchd #####

sync_launchd() {
    local src_dir="$SERVICES_DIR/launchd"
    local dest_dir="$HOME/Library/LaunchAgents"
    local marker
    marker=$(marker_comment xml)
    local uid
    uid=$(id -u)

    mkdir -p "$dest_dir"

    declare -a managed_plists=()

    for src in "$src_dir"/*.plist; do
        [[ -f "$src" ]] || continue

        local name
        name=$(basename "$src")
        managed_plists+=("$name")
        local dest="$dest_dir/$name"
        local label="${name%.plist}"

        # Prepend XML comment marker
        local content="$marker"$'\n'"$(cat "$src")"

        if [[ -f "$dest" ]] && [[ "$(cat "$dest")" == "$content" ]]; then
            echo "$label: unchanged"
        else
            echo "$label: updating"
            echo "$content" > "$dest"
            changed=true

            # Reload: unload then load
            launchctl bootout "gui/$uid/$label" 2>/dev/null || true
            launchctl bootstrap "gui/$uid" "$dest"
        fi
    done

    # Prune orphaned plists
    for dest in "$dest_dir"/*.plist; do
        [[ -f "$dest" ]] || continue

        local name
        name=$(basename "$dest")
        has_marker "$dest" xml || continue
        [[ ${#managed_plists[@]} -gt 0 ]] && printf '%s\n' "${managed_plists[@]}" | grep -qx "$name" && continue

        local label="${name%.plist}"
        echo "$label: removing (orphaned)"
        launchctl bootout "gui/$uid/$label" 2>/dev/null || true
        rm "$dest"
        changed=true
    done

    # Ensure all managed services are loaded and running
    [[ ${#managed_plists[@]} -eq 0 ]] && return

    for name in "${managed_plists[@]}"; do
        local label="${name%.plist}"
        local dest="$dest_dir/$name"

        if ! launchctl print "gui/$uid/$label" &>/dev/null; then
            echo "$label: loading"
            launchctl bootstrap "gui/$uid" "$dest"
        fi
    done

    echo ""
    echo "Done. Status:"
    for name in "${managed_plists[@]}"; do
        local label="${name%.plist}"
        if launchctl print "gui/$uid/$label" &>/dev/null; then
            echo "  $label: running"
        else
            echo "  $label: not loaded"
        fi
    done
}

##### Dispatch #####

case "$(uname)" in
    Linux)  sync_systemd ;;
    Darwin) sync_launchd ;;
    *)      echo "Unsupported platform: $(uname)"; exit 1 ;;
esac
