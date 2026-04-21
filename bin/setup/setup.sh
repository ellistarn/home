#!/bin/bash -eu
# Orchestrates machine setup. Idempotent — safe to rerun.
# Runs all scripts in ~/bin/setup/ except itself, in sorted order.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for script in $(ls "$SCRIPT_DIR"/*.sh 2>/dev/null | sort); do
  [[ "$(basename "$script")" == "setup.sh" ]] && continue
  echo "==> Running $(basename "$script")"
  "$script"
  echo ""
done

echo "Setup complete."
