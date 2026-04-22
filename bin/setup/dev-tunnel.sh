#!/bin/bash -eu
# Sets up dev tunnel: *.etarn resolves to localhost via dnsmasq.
# SSH tunnel (managed by login.sh) forwards the port to the dev desk.
# macOS only.

[[ "$(uname)" == "Darwin" ]] || { echo "Skipping (not macOS)"; exit 0; }
#   - dnsmasq: *.etarn → 127.0.0.1
#   - login.sh: SSH LocalForward $DEV_DESKTOP_TUNNEL_PORT → dev desk (auto-starts)
#
# Idempotent — safe to rerun.
# Requires DEV_DESKTOP_HOST and DEV_DESKTOP_TUNNEL_PORT to be set (e.g. in .zshrc).

DOMAIN="etarn"
PORT="${DEV_DESKTOP_TUNNEL_PORT:-}"

if [[ -z "${DEV_DESKTOP_HOST:-}" ]]; then
  echo "ERROR: DEV_DESKTOP_HOST is not set"
  exit 1
fi

if [[ -z "$PORT" ]]; then
  echo "ERROR: DEV_DESKTOP_TUNNEL_PORT is not set"
  exit 1
fi

##### dnsmasq — resolve *.etarn to localhost #####

if ! brew list dnsmasq &>/dev/null; then
  echo "Installing dnsmasq..."
  brew install dnsmasq
else
  echo "dnsmasq already installed"
fi

echo "Enabling conf-dir in /opt/homebrew/etc/dnsmasq.conf"
sed -i '' 's|^#conf-dir=/opt/homebrew/etc/dnsmasq.d/,\*\.conf|conf-dir=/opt/homebrew/etc/dnsmasq.d/,*.conf|' /opt/homebrew/etc/dnsmasq.conf

echo "Writing /opt/homebrew/etc/dnsmasq.d/${DOMAIN}.conf (*.${DOMAIN} -> 127.0.0.1)"
mkdir -p /opt/homebrew/etc/dnsmasq.d
cat > /opt/homebrew/etc/dnsmasq.d/${DOMAIN}.conf <<EOF
# Resolve *.${DOMAIN} to localhost (SSH tunnel handles forwarding to dev desk)
address=/${DOMAIN}/127.0.0.1
EOF

echo "Writing /etc/resolver/${DOMAIN} (nameserver 127.0.0.1)"
sudo mkdir -p /etc/resolver
sudo bash -c "cat > /etc/resolver/${DOMAIN} <<EOF
nameserver 127.0.0.1
EOF"

echo "Restarting dnsmasq service..."
sudo brew services restart dnsmasq

##### clean up legacy pfctl rules (if present) #####

if [[ -f /etc/pf.anchors/dev-tunnel ]]; then
  echo "Removing legacy /etc/pf.anchors/dev-tunnel"
  sudo rm -f /etc/pf.anchors/dev-tunnel
fi

if grep -q "dev-tunnel" /etc/pf.conf 2>/dev/null; then
  echo "Removing legacy dev-tunnel lines from /etc/pf.conf"
  sudo sed -i '' '/dev-tunnel/d' /etc/pf.conf
  sudo pfctl -f /etc/pf.conf 2>/dev/null
fi

echo ""
echo "Done. *.${DOMAIN}:${PORT} → 127.0.0.1:${PORT} → SSH → dev desk:${PORT}"
echo ""
echo "Usage:"
echo "  login.sh         # refresh auth + restart tunnel"
echo "  Browser:         http://grafana.${DOMAIN}:${PORT}/"
echo ""
echo "Tunnel auto-starts via login.sh on new terminals."
