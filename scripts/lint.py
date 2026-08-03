#!/usr/bin/env python3
"""Lint hub metadata: plugins.json + prs.json.

Checks:
  - both files are valid JSON
  - every plugin has id/repo/path
  - dependency graph (depends_on) is acyclic
  - every lifecycle is stable|active|experimental
  - every plugins.json tracked_by_prs id exists in prs.json
  - every prs.json entry has allowed state + backs referencing real plugins
"""
import json, sys, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLUGINS = os.path.join(ROOT, "plugins.json")
PRS = os.path.join(ROOT, "prs.json")
ALLOWED_LIFECYCLE = {"stable", "active", "experimental"}
ALLOWED_STATE = {"open", "merged", "closed", "superseded"}

def fail(msg):
    print(f"[FAIL] {msg}")
    sys.exit(1)

def ok(msg):
    print(f"[OK] {msg}")

plug = json.load(open(PLUGINS))
prs = json.load(open(PRS))

plugins = plug.get("plugins", [])
by_id = {p["id"]: p for p in plugins}
for p in plugins:
    if not all(k in p for k in ("id", "repo", "path")):
        fail(f"plugin missing id/repo/path: {p}")
    if p.get("lifecycle", "stable") not in ALLOWED_LIFECYCLE:
        fail(f"plugin {p['id']} bad lifecycle {p.get('lifecycle')}")

# acyclic depends_on
indeg = {p["id"]: 0 for p in plugins}
adj = {p["id"]: [] for p in plugins}
for p in plugins:
    for d in p.get("depends_on", []):
        if d not in by_id:
            fail(f"plugin {p['id']} depends_on unknown '{d}'")
        adj[d].append(p["id"])
        indeg[p["id"]] += 1
queue = [k for k, v in indeg.items() if v == 0]
seen = 0
from collections import deque
q = deque(queue)
while q:
    n = q.popleft(); seen += 1
    for m in adj[n]:
        indeg[m] -= 1
        if indeg[m] == 0:
            q.append(m)
if seen != len(plugins):
    fail("dependency cycle detected in depends_on")

pr_ids = {p["id"] for p in prs.get("prs", [])}
for p in plugins:
    for t in p.get("tracked_by_prs", []):
        if t not in pr_ids:
            fail(f"plugin {p['id']} tracks unknown PR '{t}'")

for p in prs.get("prs", []):
    if p.get("state") not in ALLOWED_STATE:
        fail(f"PR {p['id']} bad state {p.get('state')}")
    for b in p.get("backs", []):
        if b not in by_id:
            fail(f"PR {p['id']} backs unknown plugin '{b}'")

ok("plugins.json + prs.json valid and cross-references resolve")
