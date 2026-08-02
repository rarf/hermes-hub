#!/usr/bin/env bash
# sync.sh — fast-forward pull every cloned plugin in HERMES_HOME/plugins/<path>
# to its tracked branch. Safe (--ff-only): never rewrites local history.
set -euo pipefail

HUB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_JSON="$HUB_DIR/plugins.json"

if [[ -z "${HERMES_HOME:-}" ]]; then
  HERMES_HOME="$HOME/AppData/Local/hermes"
fi
export HERMES_HOME
PLUGINS_DIR="$HERMES_HOME/plugins"

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required."; exit 1; }

PLUGIN_COUNT=$(jq '.plugins | length' "$PLUGINS_JSON")
for i in $(seq 0 $((PLUGIN_COUNT - 1))); do
  id=$(jq -r ".plugins[$i].id" "$PLUGINS_JSON")
  path=$(jq -r ".plugins[$i].path // \"$id\"" "$PLUGINS_JSON")
  target="$PLUGINS_DIR/$path"
  if [[ -d "$target/.git" ]]; then
    echo "▶ $id: git pull --ff-only"
    git -C "$target" pull --ff-only || echo "  WARN: pull failed for $id"
  else
    echo "▶ $id: not cloned yet (run install.sh)"
  fi
done
echo "Sync complete."
