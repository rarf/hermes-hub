#!/usr/bin/env bash
# patch.sh — orchestrate out-of-tree patches listed in patches.json.
# Patches MODIFY the Hermes runtime (venv, patches dir, git hooks) — review
# before applying.
#
#   bash patch.sh          # list patches + install status (no changes)
#   bash patch.sh --apply  # clone each missing patch repo + run its install.sh
set -euo pipefail

HUB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCHES_JSON="$HUB_DIR/patches.json"
APPLY=0
[[ "${1:-}" == "--apply" ]] && APPLY=1

if [[ -z "${HERMES_HOME:-}" ]]; then
  HERMES_HOME="${XDG_DATA_HOME:-$HOME/AppData/Local}/hermes"
fi
export HERMES_HOME
SRC_DIR="$HERMES_HOME/patches-src"

python -c "import json;json.load(open('$PATCHES_JSON'))" 2>/dev/null || { echo "patches.json invalid JSON"; exit 1; }

echo "Hermes hub — patches (out-of-tree runtime layers)"
for id in $(python -c "import json;[print(p['id']) for p in json.load(open('$PATCHES_JSON'))['patches']]"); do
  repo=$(python -c "import json;print([p['repo'] for p in json.load(open('$PATCHES_JSON'))['patches'] if p['id']=='$id'][0])")
  branch=$(python -c "import json;print([p.get('branch','main') for p in json.load(open('$PATCHES_JSON'))['patches'] if p['id']=='$id'][0])")
  target="$SRC_DIR/$id"
  if [[ -d "$target/.git" ]]; then
    echo "  [$id] cloned at $target"
  else
    echo "  [$id] NOT cloned ($repo @ $branch)"
  fi
  if [[ $APPLY -eq 1 ]]; then
    if [[ ! -d "$target/.git" ]]; then
      mkdir -p "$SRC_DIR"
      echo "  cloning $repo → $target"
      git clone --quiet --branch "$branch" "$repo" "$target"
    fi
    echo "  running install for $id (modifies Hermes runtime)..."
    (cd "$target" && bash install.sh) || echo "  WARN: install failed for $id"
  fi
done

if [[ $APPLY -eq 0 ]]; then
  echo
  echo "Dry run. Re-run with --apply to clone + install each patch."
fi
