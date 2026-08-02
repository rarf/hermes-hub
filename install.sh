#!/usr/bin/env bash
# install.sh — clone/update Hermes plugins listed in plugins.json into
# $HERMES_HOME/plugins/<path>, then enable each via `hermes plugins enable`.
#
# Idempotent: skips clone if dir exists (and offers `git pull --ff-only` in
# sync.sh instead), enables even if already enabled.
set -euo pipefail

HUB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_JSON="$HUB_DIR/plugins.json"

# --- resolve HERMES_HOME (mirrors hermes_cli defaults) -----------------------
if [[ -z "${HERMES_HOME:-}" ]]; then
  if [[ -n "${XDG_DATA_HOME:-}" && -d "$XDG_DATA_HOME" ]]; then
    HERMES_HOME="$XDG_DATA_HOME/hermes"
  else
    HERMES_HOME="$HOME/AppData/Local/hermes"
  fi
fi
export HERMES_HOME
PLUGINS_DIR="$HERMES_HOME/plugins"
mkdir -p "$PLUGINS_DIR"

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required (https://stedolan.github.io/jq/)."; exit 1; }
command -v hermes >/dev/null 2>&1 || { echo "WARN: 'hermes' CLI not on PATH; plugins will be cloned but not auto-enabled."; }

PLUGIN_COUNT=$(jq '.plugins | length' "$PLUGINS_JSON")
echo "Hermes hub — installing $PLUGIN_COUNT plugin(s) into $PLUGINS_DIR"

for i in $(seq 0 $((PLUGIN_COUNT - 1))); do
  id=$(jq -r ".plugins[$i].id" "$PLUGINS_JSON")
  repo=$(jq -r ".plugins[$i].repo" "$PLUGINS_JSON")
  branch=$(jq -r ".plugins[$i].branch // \"master\"" "$PLUGINS_JSON")
  path=$(jq -r ".plugins[$i].path // \"$id\"" "$PLUGINS_JSON")
  desc=$(jq -r ".plugins[$i].description // \"\"" "$PLUGINS_JSON")

  target="$PLUGINS_DIR/$path"
  echo
  echo "▶ $id — $desc"

  if [[ -d "$target/.git" ]]; then
    echo "  already cloned at $target (run sync.sh to pull latest)"
  else
    echo "  cloning $repo @ $branch → $target"
    git clone --quiet --branch "$branch" "$repo" "$target"
  fi

  if command -v hermes >/dev/null 2>&1; then
    echo "  enabling plugin: hermes plugins enable $id"
    hermes plugins enable "$id" || echo "  WARN: enable failed (check config / restart daemon)"
  fi
done

echo
echo "Done. Restart the Hermes daemon (or run /plugins in-session) to load changes."
