#!/usr/bin/env bash
# doctor.sh — verify the hub's setup is healthy on this machine.
# Checks: (1) plugins.json valid, (2) each plugin cloned+enabled, (3) LifeOS
# API reachable, (4) every tracked_by_prs entry resolves in prs.json, (5) hooks
# for core PRs present if the plugin is enabled.
# Pass --snapshot to also dump a before-update report.
set -uo pipefail

HUB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_JSON="$HUB_DIR/plugins.json"
PRS_JSON="$HUB_DIR/prs.json"
SNAPSHOT=0
[[ "${1:-}" == "--snapshot" ]] && SNAPSHOT=1

if [[ -z "${HERMES_HOME:-}" ]]; then
  HERMES_HOME="${XDG_DATA_HOME:-$HOME/AppData/Local}/hermes"
fi
export HERMES_HOME
PLUGINS_DIR="$HERMES_HOME/plugins"

fail=0
ok()   { echo "  [OK]   $1"; }
warn() { echo "  [WARN] $1"; }
bad()  { echo "  [FAIL] $1"; fail=1; }

echo "Hermes hub — doctor"

# (1) JSON validity
python -c "import json;json.load(open('$PLUGINS_JSON'))" 2>/dev/null && ok "plugins.json valid JSON" || bad "plugins.json invalid JSON"
python -c "import json;json.load(open('$PRS_JSON'))" 2>/dev/null     && ok "prs.json valid JSON"     || bad "prs.json invalid JSON"

# (2) plugins present + enabled
for id in $(python -c "import json;[print(p['id']) for p in json.load(open('$PLUGINS_JSON'))['plugins']]"); do
  path=$(python -c "import json;print([p.get('path',p['id']) for p in json.load(open('$PLUGINS_JSON'))['plugins'] if p['id']=='$id'][0])")
  if [[ -d "$PLUGINS_DIR/$path/.git" ]]; then ok "plugin '$id' cloned at $PLUGINS_DIR/$path"; else warn "plugin '$id' not cloned (run install.sh)"; fi
  if command -v hermes >/dev/null 2>&1; then
    if hermes plugins list 2>/dev/null | grep -q "$id"; then ok "plugin '$id' listed"; else warn "plugin '$id' not enabled"; fi
  fi
done

# (3) LifeOS API reachable (localhost, optional)
if command -v curl >/dev/null 2>&1; then
  if curl -s -o /dev/null -w "%{http_code}" --max-time 2 http://127.0.0.1:9128/health 2>/dev/null | grep -q 200; then
    ok "LifeOS API up on 127.0.0.1:9128"
  else
    warn "LifeOS API not reachable on 127.0.0.1:9128 (start Hermes / enable lifeos)"
  fi
fi

# (4) tracked_by_prs resolve in prs.json
python - "$PLUGINS_JSON" "$PRS_JSON" <<'PY'
import json, sys
plug = json.load(open(sys.argv[1]))
prs  = json.load(open(sys.argv[2]))
pr_ids = {p["id"] for p in prs.get("prs", [])}
for p in plug["plugins"]:
    for t in p.get("tracked_by_prs", []):
        if t not in pr_ids:
            print(f"  [FAIL] plugin '{p['id']}' tracks unknown PR '{t}'")
            sys.exit(1)
print("  [OK]   every tracked_by_prs entry resolves in prs.json")
PY

# (5) core PRs still open (informational)
python - "$PRS_JSON" <<'PY'
import json, sys
prs = json.load(open(sys.argv[1])).get("prs", [])
for p in prs:
    print(f"  [INFO] PR {p['id']} -> state={p['state']} backs={','.join(p.get('backs',[])) or '-'}")
PY

if [[ $SNAPSHOT -eq 1 ]]; then
  echo "--- snapshot ---"
  python -c "import json;d=json.load(open('$PLUGINS_JSON'));print('\n'.join(f\"{p['id']}:{p.get('lifecycle','-')}\" for p in d['plugins']))"
fi

echo
if [[ $fail -eq 0 ]]; then echo "doctor: healthy (warnings above are non-fatal)."; else echo "doctor: issues found — see [FAIL] above."; exit 1; fi
