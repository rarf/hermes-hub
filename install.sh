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

# --- jq optional: fall back to a tiny python JSON reader --------------------
# Native python.exe can't read msys-style /c/... paths, so translate to
# Windows style for the fallback reader.
if command -v cygpath >/dev/null 2>&1; then
  PLUGINS_JSON_WIN=$(cygpath -w "$PLUGINS_JSON")
else
  PLUGINS_JSON_WIN="$PLUGINS_JSON"
fi

if command -v jq >/dev/null 2>&1; then
  _jq() { jq "$@"; }
else
  _jq() {
    python - "$PLUGINS_JSON_WIN" "$@" <<'PY'
import json, sys
doc = json.load(open(sys.argv[1]))
q = sys.argv[2]
# Supports: '.plugins | length' and '.plugins[N].key'
import re
if q == ".plugins | length":
    print(len(doc.get("plugins", [])))
elif re.fullmatch(r"\.plugins\[\d+\]\.\w+", q):
    m = re.search(r"\[(\d+)\]\.(\w+)", q)
    i, k = int(m.group(1)), m.group(2)
    print(doc["plugins"][i].get(k, ""))
else:
    sys.exit(2)
PY
  }
fi
command -v hermes >/dev/null 2>&1 || { echo "WARN: 'hermes' CLI not on PATH; plugins will be cloned but not auto-enabled."; }

PLUGIN_COUNT=$(_jq '.plugins | length' "$PLUGINS_JSON")
echo "Hermes hub — installing $PLUGIN_COUNT plugin(s) into $PLUGINS_DIR"

for i in $(seq 0 $((PLUGIN_COUNT - 1))); do
  id=$(_jq ".plugins[$i].id" "$PLUGINS_JSON")
  repo=$(_jq ".plugins[$i].repo" "$PLUGINS_JSON")
  branch=$(_jq ".plugins[$i].branch" "$PLUGINS_JSON")
  branch=${branch:-master}
  path=$(_jq ".plugins[$i].path" "$PLUGINS_JSON")
  path=${path:-$id}
  desc=$(_jq ".plugins[$i].description" "$PLUGINS_JSON")

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
