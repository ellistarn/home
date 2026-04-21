#!/bin/bash -eu
# Sets up dev tunnel: *.etarn resolves and routes to dev desk via SSH.
#   - dnsmasq: *.etarn → 127.0.0.1
#   - pfctl: redirect port 80 → $DEV_DESKTOP_TUNNEL_PORT on loopback
#   - login.sh: SSH LocalForward $DEV_DESKTOP_TUNNEL_PORT → dev desk (auto-starts)
#
# Idempotent — safe to rerun.
# Requires DEV_DESKTOP_HOST to be set (e.g. in .zshrc).

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

##### pfctl — redirect port 80 → tunnel port on loopback #####

echo "Writing /etc/pf.anchors/dev-tunnel"
sudo tee /etc/pf.anchors/dev-tunnel > /dev/null <<EOF
# Redirect port 80 → ${PORT} on loopback for dev tunnel
rdr pass on lo0 inet proto tcp from any to 127.0.0.1 port 80 -> 127.0.0.1 port ${PORT}
EOF

if ! grep -q "dev-tunnel" /etc/pf.conf; then
  echo "Adding dev-tunnel anchor to /etc/pf.conf"
  sudo cp /etc/pf.conf /etc/pf.conf.bak
  # Insert rdr-anchor after the last rdr-anchor line
  sudo sed -i '' '/^rdr-anchor "com.apple\/\*"/a\
rdr-anchor "dev-tunnel"
' /etc/pf.conf
  # Append load anchor at the end
  echo 'load anchor "dev-tunnel" from "/etc/pf.anchors/dev-tunnel"' | sudo tee -a /etc/pf.conf > /dev/null
else
  echo "dev-tunnel anchor already in /etc/pf.conf"
fi

echo "Loading pf rules..."
sudo pfctl -f /etc/pf.conf 2>/dev/null
sudo pfctl -E 2>/dev/null

echo ""
echo "Done. *.${DOMAIN} → 127.0.0.1:80 → :${PORT} → SSH → dev desk:${PORT}"
echo ""
echo "Usage:"
echo "  dev-tunnel-down  # stop tunnel"
echo "  Browser:         http://grafana.${DOMAIN}/"
echo ""
echo "Tunnel auto-starts via login.sh on new terminals."
