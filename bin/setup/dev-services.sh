#!/bin/bash -eu
# Generates systemd user services for OpenCode dev projects.
# Reads ~/.config/opencode/services.json for configuration.
#
# For each project in services.json:
#   - Creates opencode-<name>.service if project path exists
#   - Warns and skips if path doesn't exist (re-run after cloning)
#
# Also generates Caddyfile with reverse proxy routes for all projects,
# and cleans up orphaned services no longer in config.
#
# Idempotent — safe to rerun.

SERVICES_JSON="$HOME/.config/opencode/services.json"
SYSTEMD_DIR="$HOME/.config/systemd/user"
CADDY_DIR="$HOME/.config/caddy"
MARKER="# Managed by dev-services.sh"

if [[ ! -f "$SERVICES_JSON" ]]; then
  echo "ERROR: $SERVICES_JSON not found"
  echo "Create it with: { \"proxy_port\": 9847, \"domain_suffix\": \"etarn\", \"projects\": { \"home\": { \"path\": \"~\", \"port\": 9000 } } }"
  exit 1
fi

# Parse config
PROXY_PORT=$(jq -r '.proxy_port' "$SERVICES_JSON")
DOMAIN_SUFFIX=$(jq -r '.domain_suffix' "$SERVICES_JSON")
PROJECT_NAMES=$(jq -r '.projects | keys[]' "$SERVICES_JSON")

if [[ -z "$PROJECT_NAMES" ]]; then
  echo "ERROR: No projects defined in $SERVICES_JSON"
  exit 1
fi

mkdir -p "$SYSTEMD_DIR" "$CADDY_DIR"

##### Generate systemd services #####

GENERATED_SERVICES=()
CHANGED_SERVICES=()
for name in $PROJECT_NAMES; do
  raw_path=$(jq -r ".projects[\"$name\"].path" "$SERVICES_JSON")
  port=$(jq -r ".projects[\"$name\"].port" "$SERVICES_JSON")
  
  # Expand ~ to $HOME
  path="${raw_path/#\~/$HOME}"
  
  service_file="$SYSTEMD_DIR/opencode-${name}.service"
  GENERATED_SERVICES+=("opencode-${name}.service")
  
  if [[ ! -d "$path" ]]; then
    echo "WARN: $path does not exist, skipping opencode-${name}.service (re-run after cloning)"
    continue
  fi
  
  new_content="$MARKER
[Unit]
Description=OpenCode dev server for $name
After=network.target

[Service]
Type=simple
WorkingDirectory=$path
ExecStart=/bin/bash -lc 'opencode serve --port $port'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target"
  
  if [[ -f "$service_file" ]] && [[ "$(cat "$service_file")" == "$new_content" ]]; then
    echo "opencode-${name}.service unchanged"
  else
    echo "Writing $service_file"
    printf '%s\n' "$new_content" > "$service_file"
    CHANGED_SERVICES+=("opencode-${name}.service")
  fi
done

##### Orphan cleanup #####

for service_file in "$SYSTEMD_DIR"/opencode-*.service; do
  [[ -f "$service_file" ]] || continue
  
  service_name=$(basename "$service_file")
  
  # Skip if it's one we just generated
  if printf '%s\n' "${GENERATED_SERVICES[@]}" | grep -qx "$service_name"; then
    continue
  fi
  
  # Only clean up services we created (have our marker)
  if head -1 "$service_file" | grep -q "^$MARKER"; then
    echo "Removing orphaned $service_name"
    systemctl --user stop "$service_name" 2>/dev/null || true
    systemctl --user disable "$service_name" 2>/dev/null || true
    rm "$service_file"
  fi
done

##### Generate Caddyfile #####

CADDYFILE="$CADDY_DIR/Caddyfile"
CADDY_CONTENT="$MARKER
# Routes all *.${DOMAIN_SUFFIX}:${PROXY_PORT} to OpenCode backends
"

for name in $PROJECT_NAMES; do
  port=$(jq -r ".projects[\"$name\"].port" "$SERVICES_JSON")
  CADDY_CONTENT+="
${name}.${DOMAIN_SUFFIX}:${PROXY_PORT} {
    reverse_proxy localhost:${port}
}"
done

CADDY_CHANGED=false
if [[ -f "$CADDYFILE" ]] && [[ "$(cat "$CADDYFILE")" == "$CADDY_CONTENT" ]]; then
  echo "Caddyfile unchanged"
else
  echo "Writing $CADDYFILE"
  printf '%s\n' "$CADDY_CONTENT" > "$CADDYFILE"
  CADDY_CHANGED=true
fi

##### Reload and restart #####

if [[ ${#CHANGED_SERVICES[@]} -gt 0 ]] || [[ "$CADDY_CHANGED" == "true" ]]; then
  echo "Reloading systemd user daemon..."
  systemctl --user daemon-reload
fi

# Enable services and restart changed ones
for name in $PROJECT_NAMES; do
  service_name="opencode-${name}.service"
  service_file="$SYSTEMD_DIR/$service_name"
  
  [[ -f "$service_file" ]] || continue
  
  if ! systemctl --user is-enabled "$service_name" &>/dev/null; then
    echo "Enabling $service_name"
    systemctl --user enable "$service_name"
  fi
  
  # Only restart if changed or not running
  if printf '%s\n' "${CHANGED_SERVICES[@]:-}" | grep -qx "$service_name"; then
    echo "Restarting $service_name"
    systemctl --user restart "$service_name"
  elif ! systemctl --user is-active "$service_name" &>/dev/null; then
    echo "Starting $service_name"
    systemctl --user start "$service_name"
  fi
done

# Handle Caddy
CADDY_SERVICE="$SYSTEMD_DIR/caddy.service"
if [[ ! -f "$CADDY_SERVICE" ]]; then
  echo "Writing $CADDY_SERVICE"
  cat > "$CADDY_SERVICE" <<EOF
$MARKER
[Unit]
Description=Caddy reverse proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/caddy run --config $CADDYFILE
ExecReload=/usr/local/bin/caddy reload --config $CADDYFILE
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable caddy
fi

if [[ "$CADDY_CHANGED" == "true" ]]; then
  echo "Reloading Caddy..."
  systemctl --user reload caddy 2>/dev/null || systemctl --user restart caddy
elif ! systemctl --user is-active caddy &>/dev/null; then
  echo "Starting Caddy..."
  systemctl --user start caddy
fi

echo ""
echo "Done. Services:"
for name in $PROJECT_NAMES; do
  port=$(jq -r ".projects[\"$name\"].port" "$SERVICES_JSON")
  service_file="$SYSTEMD_DIR/opencode-${name}.service"
  if [[ -f "$service_file" ]]; then
    status=$(systemctl --user is-active "opencode-${name}.service" 2>/dev/null || echo "unknown")
    echo "  ${name}.${DOMAIN_SUFFIX}:${PROXY_PORT} -> localhost:${port} ($status)"
  else
    echo "  ${name}.${DOMAIN_SUFFIX}:${PROXY_PORT} -> localhost:${port} (no service - path missing)"
  fi
done
