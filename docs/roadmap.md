# Roadmap — plugins, features and upstream work

Living map of what exists, what's in flight, and what's next across the whole
setup. Verified against live GitHub state on **2026-08-13**
(`bash scripts/prs-refresh.sh` re-checks it).

Three layers, tracked in three files:

| Layer | File | What it holds |
|-------|------|---------------|
| Plugins | [`plugins.json`](../plugins.json) | Standalone plugin repos installed into `$HERMES_HOME/plugins/` |
| Upstream PRs | [`prs.json`](../prs.json) | Core PRs the setup depends on or is waiting on |
| Out-of-tree patches | [`patches.json`](../patches.json) | Runtime layers that aren't plugins (e.g. Claude OAuth bypass) |

---

## 1. Plugins — current state

| Plugin | Repo | Lifecycle | Depends on | Blocked by |
|--------|------|-----------|------------|------------|
| **optmem** | `rarf/optmem-hermes-plugin` | `stable` | — | — |
| **lifeos** | `rarf/lifeos-hermes-plugin` | `active` | optmem | — |
| **quota** | `rarf/hermes-quota-plugin` | `stable` | — | #85060, #85061 |

### ⚠ Index vs reality — audited 2026-08-13

`hermes plugins list` and `$HERMES_HOME/plugins/` do **not** match what this
index promises. Verified on this machine:

| Plugin | On disk | Git clone? | `hermes plugins list` |
|--------|---------|-----------|----------------------|
| lifeos | full source | **no `.git`** | `enabled`, v0.5.2, source `user` |
| optmem | full source | **no `.git`** | **`not enabled`**, v0.1.0, source `user` |
| quota | full source | yes | `enabled`, v1.0.0, source `git` |
| hermes-achievements | only `state.json`, `scan_*.json` | no | **absent** |

Three problems, each a roadmap item:

1. **lifeos and optmem are unversioned working copies, not clones.** The index
   says `install.sh` clones them from their repos; in reality they are loose
   directories with no git remote. Any local edit is unversioned and has
   nowhere to be pushed. This silently breaks the standalone-repo guarantee the
   whole hub is built on. → **R0**
2. **optmem is `not enabled`** despite `enabled_by_default: true`. OptMem memory
   *is* working, which means it runs through the core memory provider, not this
   plugin — so the index's description of how it's wired is wrong. → **R0**
3. **hermes-achievements is not a plugin.** It's three state files with no code
   and no entry in `hermes plugins list` — leftover data, not something to
   index. → **R3**

### optmem — permanent memory
Append-only `LOG.txt` + decay-compressed `TREE/`, accent-normalized BM25 recall.
Zero deps, native Windows (upstream `VictorTaelin/OptMem#2` merged for the
`msvcrt` lock). Default memory layer.

Next: benchmark coverage against MemConflict is a separate repo
(`hermes-memconflict`) — promote a summary of results into the plugin README
so the quality claim is checkable.

### lifeos — personal operating system
Domains, objectives, KRs, projects, tasks, events + Dashboard UI on
`127.0.0.1:9128`. Source of truth for the whole LifeOS graph; agents consult
`lifeos_*` tools dynamically rather than hardcoding state.

Next: FR gaps (check-ins, inbox) tracked by the `lifeos-plugin-feature-add`
skill. The localhost API is the main fragility — it's `active`, not `stable`,
until it survives a `hermes update` cleanly per the promotion rule in
[experiments.md](experiments.md).

### quota — per-provider quota footer
`/quota` slash + CLI command and a footer block. **The only plugin gated on
unmerged upstream work**: it needs `transform_footer` (#85060) and
`transform_usage_extra` (#85061). Until those merge, the hooks must be
re-applied locally after every `hermes update` — see
[updating.md](updating.md) and the `reapply` field in `prs.json`.

---

## 2. Upstream PRs — in flight

| PR | What | State | Action needed |
|----|------|-------|---------------|
| [#85060](https://github.com/NousResearch/hermes-agent/pull/85060) | `transform_footer` hook | open, MERGEABLE, BLOCKED | Wait on review |
| [#85061](https://github.com/NousResearch/hermes-agent/pull/85061) | `transform_usage_extra` hook | open, MERGEABLE, BLOCKED | Wait on review |
| [#83318](https://github.com/NousResearch/hermes-agent/pull/83318) | Silence Windows git warning (desktop) | open, MERGEABLE, BLOCKED | Wait on review |
| [#69441](https://github.com/NousResearch/hermes-agent/pull/69441) | Gateway `/profile` picker | open, **CONFLICTING** | **Rebase onto main** |
| [claude-auth#28](https://github.com/kristianvast/hermes-claude-auth/pull/28) | Loader across profiles + Windows | open, CLEAN | Ping maintainer |
| [expo#46449](https://github.com/expo/expo/pull/46449) | Android headless loader guard (AllDrivers) | open, **CONFLICTING** | Rebase or ping |

Landed / closed-but-cherry-picked, kept for provenance: `OptMem#2` (merged),
`#6844` and `#56966` (cherry-picked into core), `#79397` (superseded by the
split above), `#83259` (superseded by #83318).

**Only two PRs actually need work: #69441 and expo#46449 — both need a rebase.**
Everything else is waiting on someone other than us.

---

## 3. Roadmap

### R0 — Reconcile installed plugins with their repos *(urgent, do first)*
`lifeos` and `optmem` are unversioned directories in `$HERMES_HOME/plugins/`
with no git remote, while the hub claims they're clones. Until this is fixed,
local work on them is unbacked and a fresh-machine install produces a
*different* setup than this machine has.

Steps:
1. Diff each local directory against its GitHub repo — find out whether local
   is ahead, behind, or divergent. **Do this before touching anything.**
2. If local is ahead, commit and push that work to the plugin's own repo.
3. Re-establish each as a real clone (or `git init` + `remote add` + reconcile),
   so `sync.sh` can fast-forward them like it does `quota`.
4. Decide whether `optmem` should be an enabled plugin at all, or whether the
   core memory provider is the real integration path — then make
   `plugins.json` say the true thing.

Acceptance: `sync.sh` fast-forwards all three plugins, and `hermes plugins list`
matches `plugins.json` (`enabled_by_default` reflects actual state).

### R1 — Hub as a plugin
Turn this meta-repo into `hermes-hub-plugin`: a plugin that manages other
plugins. Wraps what `install.sh` / `sync.sh` / `doctor.sh` /
`prs-refresh.sh` already do, but as agent-callable tools so the agent — not
the human — notices drift.

Proposed tools:

| Tool | Wraps |
|------|-------|
| `hub_list` | `plugins.json` — installed vs indexed, lifecycle, dependency order |
| `hub_install` / `hub_sync` | `install.sh`, `sync.sh` |
| `hub_doctor` | `scripts/doctor.sh`, parsed into a structured result |
| `hub_prs_status` | `scripts/prs-refresh.sh` — live GitHub drift check |
| `hub_reapply_patches` | `patches.json` + `prs.json` `reapply` after `hermes update` |

Honest limits:
- A plugin **cannot bootstrap itself**. First install stays `git clone` +
  `bash install.sh`. The plugin's value is the post-install loop.
- It **cannot reliably act mid-`hermes update`** (that's the moment the runtime
  is being rebuilt). It verifies and repairs *after*.
- It must not touch core files — per the core `AGENTS.md`, third-party plugins
  live in their own repo and work within the provided ABCs/hooks. This design
  respects that: it shells out to the hub's own scripts.

`hub_doctor` should specifically catch the R0 class of failure: an indexed
plugin whose on-disk copy has no git remote.

Acceptance: `hub_doctor` and `hub_prs_status` return real structured output on
this machine, and a fresh `hermes update` followed by `hub_reapply_patches`
restores the quota hooks without manual steps.

### R2 — Rebase the two conflicting PRs
`#69441` (7 commits, review addressed, gone stale) and `expo#46449`. Both are
mechanical; both are pure rot risk the longer they sit.

### R3 — Clean up `hermes-achievements`
Not a plugin — three state files, no code, absent from `hermes plugins list`.
Either the plugin was removed and left its data behind, or it never installed.
Confirm which, then delete the directory or install the real thing.

### R4 — Close the loop on drift automatically
`prs-refresh.sh` exists but nothing runs it. Once R1 lands, a scheduled job can
call `hub_prs_status` weekly and report only when something moved — the failure
mode this whole exercise came from was *nobody noticing #79397 had been split*.
The R0 audit is the same failure in a different place: the hub described a
reality nobody had re-checked.

### R5 — CI for the refresh script
Add `scripts/prs-refresh.sh` to the lint workflow's `bash -n` sweep (it's
covered by the existing glob) and consider a scheduled CI job that runs the
drift check read-only against the public PRs.

---

## Ordering rationale

**R0 first** — it's the only item where delay risks losing work, and R1's
`hub_doctor` needs to know what "correct" looks like. R2 is independent and can
happen any time. R1 is the keystone; R4 depends on it. R3 is a cleanup. R5 is
cheap once R1 is stable.

Suggested order: **R0 → R2 → R1 → R3 → R4 → R5.**
