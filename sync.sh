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

# --- jq optional: fall back to a tiny python JSON reader --------------------
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
import json, sys, re
doc = json.load(open(sys.argv[1]))
q = sys.argv[2]
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

PLUGIN_COUNT=$(_jq '.plugins | length' "$PLUGINS_JSON")
for i in $(seq 0 $((PLUGIN_COUNT - 1))); do
  id=$(_jq ".plugins[$i].id" "$PLUGINS_JSON")
  path=$(_jq ".plugins[$i].path" "$PLUGINS_JSON")
  path=${path:-$id}
  target="$PLUGINS_DIR/$path"
  if [[ -d "$target/.git" ]]; then
    echo "▶ $id: git pull --ff-only"
    git -C "$target" pull --ff-only || echo "  WARN: pull failed for $id"
  else
    echo "▶ $id: not cloned yet (run install.sh)"
  fi
done
echo "Sync complete."
