#!/usr/bin/env bash
# prs-refresh.sh — reconcile prs.json against live GitHub state.
#
# Reads every entry in prs.json, queries the real PR via `gh`, and reports
# drift (state / merge_state changes). With --write, applies the live values
# back into prs.json and bumps last_checked.
#
# Why this exists: prs.json drifted badly once — it tracked two synthetic ids
# ("rarf/footer-hook", "rarf/usage-extra-hook") for what was really a single
# PR (#79397), which was later closed and split into #85060 + #85061. Nothing
# noticed. This script makes that class of drift a one-command check.
#
# Usage:
#   bash scripts/prs-refresh.sh           # report drift only (exit 1 if drift)
#   bash scripts/prs-refresh.sh --write   # apply live state into prs.json
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRS="$ROOT/prs.json"
# On Windows/MSYS, native python does not understand /c/Users/... paths.
if command -v cygpath >/dev/null 2>&1; then
  PRS="$(cygpath -m "$PRS")"
fi
WRITE=0
[[ "${1:-}" == "--write" ]] && WRITE=1

command -v gh >/dev/null || { echo "[FAIL] gh CLI not on PATH"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "[FAIL] gh not authenticated (run: gh auth login)"; exit 1; }

python - "$PRS" "$WRITE" <<'PY'
import json, re, subprocess, sys, datetime

path, write = sys.argv[1], sys.argv[2] == "1"
doc = json.load(open(path, encoding="utf-8"))
today = datetime.datetime.utcnow().strftime("%Y-%m-%d")

# A PR we deliberately keep as historical provenance: gh reports CLOSED, but we
# record "superseded"/"merged". Don't flag those as drift.
TERMINAL = {"merged", "superseded"}

drift = 0
for entry in doc.get("prs", []):
    pid = entry["id"]
    m = re.match(r"^([^/]+/[^#]+)#(\d+)$", pid)
    if not m:
        print(f"[SKIP] {pid}: not an owner/repo#number id")
        continue
    repo, num = m.group(1), m.group(2)

    try:
        out = subprocess.run(
            ["gh", "pr", "view", num, "-R", repo,
             "--json", "state,mergeable,mergeStateStatus,title,headRefName,url"],
            capture_output=True, text=True, check=True, timeout=60,
        ).stdout
    except subprocess.CalledProcessError as e:
        print(f"[WARN] {pid}: gh failed — {e.stderr.strip()[:120]}")
        continue
    except subprocess.TimeoutExpired:
        print(f"[WARN] {pid}: gh timed out")
        continue

    live = json.loads(out)
    live_state = live["state"].lower()          # OPEN|CLOSED|MERGED
    live_merge = live["mergeStateStatus"]       # CLEAN|BLOCKED|DIRTY|UNKNOWN

    cur_state = entry.get("state")
    cur_merge = entry.get("merge_state")

    # Terminal bookkeeping states we own; gh's CLOSED doesn't override them.
    state_drift = (cur_state not in TERMINAL) and (live_state != cur_state)
    merge_drift = (cur_state not in TERMINAL) and (live_merge != cur_merge) and live_merge != "UNKNOWN"

    if state_drift or merge_drift:
        drift += 1
        bits = []
        if state_drift:
            bits.append(f"state {cur_state} -> {live_state}")
        if merge_drift:
            bits.append(f"merge {cur_merge} -> {live_merge}")
        print(f"[DRIFT] {pid}: " + "; ".join(bits))
        if write:
            if state_drift:
                entry["state"] = live_state
            if merge_drift:
                entry["merge_state"] = live_merge
    else:
        print(f"[OK] {pid}: {cur_state}/{cur_merge}")

    if write:
        entry["last_checked"] = today
        entry.setdefault("url", live["url"])
        entry.setdefault("branch", live["headRefName"])

if write:
    doc["last_checked"] = today
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(doc, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    print(f"\n[WROTE] {path} ({drift} entr{'y' if drift == 1 else 'ies'} updated)")
    sys.exit(0)

if drift:
    print(f"\n{drift} PR(s) drifted from prs.json. Re-run with --write to apply.")
    sys.exit(1)
print("\nprs.json matches live GitHub state.")
PY
