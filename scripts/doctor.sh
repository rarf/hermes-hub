#!/usr/bin/env bash
# Read-only, profile-aware setup inspection. Never install or restart anything.
set -uo pipefail
HUB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 - "$HUB_DIR" "$@" <<'PY'
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import urllib.request

hub = Path(sys.argv[1])
parser = argparse.ArgumentParser(description="Read-only Hermes hub doctor")
parser.add_argument("--snapshot", action="store_true")
parser.add_argument("--profile", default=None)
args = parser.parse_args(sys.argv[2:])
home = Path(os.environ.get("HERMES_HOME") or Path.home() / ".hermes")
if args.profile:
    if not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9_-]*", args.profile):
        parser.error("invalid profile name")
    root = home.parent.parent if home.parent.name == "profiles" else home
    home = root if args.profile == "default" else root / "profiles" / args.profile
print("Hermes hub — doctor")
print(f"  HERMES_HOME = {home}")
failed = False

def report(status, message):
    global failed
    print(f"  [{status}] {message}")
    failed |= status == "FAIL"

try:
    plugins = json.loads((hub / "plugins.json").read_text(encoding="utf-8"))
    prs = json.loads((hub / "prs.json").read_text(encoding="utf-8"))
except (OSError, ValueError) as exc:
    report("FAIL", f"invalid hub metadata: {type(exc).__name__}")
    sys.exit(1)
report("OK", "plugins.json + prs.json valid JSON")
pr_ids = {p["id"] for p in prs.get("prs", [])}
for plugin in plugins.get("plugins", []):
    for reference in plugin.get("tracked_by_prs", []):
        if reference not in pr_ids:
            report("FAIL", f"plugin '{plugin['id']}' tracks unknown PR '{reference}'")
if not failed:
    report("OK", "every tracked_by_prs entry resolves in prs.json")

# Refuse to bootstrap a bogus legacy home through the Hermes wrapper.
enabled = set()
if not (home / "config.yaml").is_file():
    report("FAIL", "profile config.yaml missing; runtime probe not launched")
elif not shutil.which("hermes"):
    report("FAIL", "Hermes CLI unavailable; runtime state unverified")
else:
    env = os.environ.copy()
    env["HERMES_HOME"] = str(home)
    env["HERMES_PROFILE"] = home.name if home.parent.name == "profiles" else "default"
    try:
        result = subprocess.run(["hermes", "plugins", "list", "--plain", "--no-bundled"],
                                env=env, capture_output=True, text=True, timeout=15)
        if result.returncode:
            report("FAIL", f"plugin discovery exit {result.returncode}; runtime unverified")
        else:
            for line in result.stdout.splitlines():
                fields = line.split()
                if fields and fields[0] == "enabled":
                    enabled.add(fields[-1])
    except (OSError, subprocess.TimeoutExpired):
        report("FAIL", "plugin discovery unavailable or timed out; runtime unverified")

known = {p.get("runtime_name", p.get("path", p["id"])) for p in plugins.get("plugins", [])}
for name in sorted(known | enabled):
    path = home / "plugins" / name
    installed = path.is_dir() and any((path / marker).exists()
                                    for marker in ("plugin.yaml", "hermes_plugin.py", ".git"))
    if installed:
        report("OK", f"plugin '{name}' installed at {path}")
    elif name in enabled:
        report("FAIL", f"enabled plugin '{name}' package missing")
    else:
        report("INFO", f"plugin '{name}' not installed in this profile (optional)")
    report("OK" if name in enabled else "INFO",
           f"plugin '{name}' {'enabled' if name in enabled else 'not enabled in this profile'}")

if "lifeos" in enabled:
    try:
        with urllib.request.urlopen("http://127.0.0.1:9128/health", timeout=2) as response:
            report("OK" if response.status == 200 else "WARN", f"LifeOS health HTTP {response.status}")
    except OSError:
        report("WARN", "LifeOS enabled but localhost health unavailable")
else:
    report("INFO", "LifeOS not enabled; health probe not applicable")
if args.snapshot:
    for p in plugins.get("plugins", []):
        print(f"  [SNAPSHOT] {p['id']}:{p.get('lifecycle', '-')} (registry, not live PR status)")
print("doctor: issues found" if failed else "doctor: healthy (optional components excluded)")
sys.exit(int(failed))
PY
