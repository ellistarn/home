#!/bin/bash -eu
# Orchestrates machine setup. Idempotent — safe to rerun.
# Runs all ~/bin/setup-*.sh scripts in sorted order.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for script in $(ls "$SCRIPT_DIR"/setup-*.sh 2>/dev/null | sort); do
  echo "==> Running $(basename "$script")"
  "$script"
  echo ""
done

echo "Setup complete."
