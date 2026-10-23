#!/usr/bin/env bash
# install.sh — clone/update Hermes plugins listed in plugins.json into
# $HERMES_HOME/plugins/<path>, then enable each via `hermes plugins enable`.
#
# Honors `depends_on` (topological install order) and `lifecycle`:
#   - stable / active plugins install by default
#   - experimental plugins are skipped unless you pass --all
#
# Idempotent: skips clone if dir exists (pull latest via sync.sh instead),
# enables even if already enabled.
set -euo pipefail

HUB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_JSON="$HUB_DIR/plugins.json"
INCLUDE_EXPERIMENTAL=0

for arg in "$@"; do
  case "$arg" in
    --all) INCLUDE_EXPERIMENTAL=1 ;;
    -h|--help)
      echo "Usage: bash install.sh [--all]"
      echo "  --all   also install plugins marked lifecycle=experimental"
      exit 0 ;;
  esac
done

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

# --- jq optional: fall back to a python JSON reader --------------------------
if command -v cygpath >/dev/null 2>&1; then
  PLUGINS_JSON_WIN=$(cygpath -w "$PLUGINS_JSON")
else
  PLUGINS_JSON_WIN="$PLUGINS_JSON"
fi

if command -v jq >/dev/null 2>&1; then
  _jq() { jq "$@" "$PLUGINS_JSON"; }
else
  _jq() {
    python - "$PLUGINS_JSON_WIN" "$@" <<'PY'
import json, sys, re
doc = json.load(open(sys.argv[1]))
q = sys.argv[2]
m = re.fullmatch(r"\.plugins\[(\d+)\]\.(\w+)", q)
if m:
    i, k = int(m.group(1)), m.group(2)
    v = doc["plugins"][i].get(k, "")
    print(v if isinstance(v, (str, int)) else json.dumps(v))
elif q == ".plugins | length":
    print(len(doc.get("plugins", [])))
else:
    sys.exit(2)
PY
  }
fi

# Returns the ids in dependency order (depends_on = prereq). Cycles are denied
# by the fact that the hub JSON is hand-maintained and linted in CI.
order_plugins() {
  python - "$PLUGINS_JSON_WIN" "$INCLUDE_EXPERIMENTAL" <<'PY'
import json, sys
doc = json.load(open(sys.argv[1]))
include_exp = sys.argv[2] == "1"
plugins = doc.get("plugins", [])
by_id = {p["id"]: p for p in plugins}
# build edges
edges = {p["id"]: list(p.get("depends_on", [])) for p in plugins}
# stable topo sort (Kahn)
from collections import deque
indeg = {k: 0 for k in edges}
adj = {k: [] for k in edges}
for k, deps in edges.items():
    for d in deps:
        if d not in edges:
            sys.stderr.write(f"WARN: depends_on '{d}' for '{k}' not in index\n")
            continue
        adj[d].append(k)
        indeg[k] += 1
q = deque(sorted([k for k, v in indeg.items() if v == 0]))
out = []
while q:
    n = q.popleft()
    out.append(n)
    for m in adj[n]:
        indeg[m] -= 1
        if indeg[m] == 0:
            q.append(m)
if len(out) != len(edges):
    sys.stderr.write("ERROR: dependency cycle detected among plugins\n")
    sys.exit(3)
for pid in out:
    p = by_id[pid]
    if p.get("lifecycle") == "experimental" and not include_exp:
        sys.stderr.write(f"SKIP(experimental): {pid} (pass --all to install)\n")
        continue
    print(pid)
PY
}

command -v hermes >/dev/null 2>&1 || {
  echo "WARN: 'hermes' CLI not on PATH; plugins will be cloned but not auto-enabled."; }

PLUGIN_ORDER=$(order_plugins)
COUNT=$(echo "$PLUGIN_ORDER" | grep -c . || true)
echo "Hermes hub — installing $COUNT plugin(s) into $PLUGINS_DIR"

for id in $PLUGIN_ORDER; do
  # find the index of this id to read its fields
  idx=$(_jq '.plugins | length' "$PLUGINS_JSON")
  i=0; found=-1
  while [[ $i -lt $idx ]]; do
    if [[ "$(_jq ".plugins[$i].id" "$PLUGINS_JSON")" == "$id" ]]; then found=$i; break; fi
    i=$((i+1))
  done
  [[ $found -ge 0 ]] || continue

  repo=$(_jq ".plugins[$found].repo" "$PLUGINS_JSON")
  branch=$(_jq ".plugins[$found].branch" "$PLUGINS_JSON"); branch=${branch:-master}
  path=$(_jq ".plugins[$found].path" "$PLUGINS_JSON"); path=${path:-$id}
  desc=$(_jq ".plugins[$found].description" "$PLUGINS_JSON")

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
