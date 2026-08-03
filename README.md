# Hermes Hub

The **operating manual + orchestrator** for rarf's Hermes Agent setup.

This is a **meta-repo**: it does NOT contain plugin source or your personal
data. Each plugin keeps its own GitHub repo (own history, PRs, release tags) so
it survives `hermes update`. The hub **documents and orchestrates**:

1. **Indexes** plugins in [`plugins.json`](plugins.json) — repo URL, branch,
   install path, dependency order (`depends_on`), lifecycle, and which unmerged
   core PRs they depend on.
2. **Installs** them via [`install.sh`](install.sh) (topological clone into
   `$HERMES_HOME/plugins/<path>` + enable each).
3. **Syncs** them via [`sync.sh`](sync.sh) (fast-forward pull to latest).
4. **Tracks unmerged PRs** in [`prs.json`](prs.json) — the core hook PRs your
   setup depends on, so `hermes update` doesn't silently drop them.
5. **Tracks out-of-tree patches** in [`patches.json`](patches.json) — runtime
   layers that modify Hermes but aren't plugins (e.g. the Claude Code OAuth
   billing bypass). Orchestrated by [`scripts/patch.sh`](scripts/patch.sh).
6. **Documents the whole setup** in [`docs/`](docs/) — onboarding, profiles,
   vault, use cases, experiments, the Claude bypass, particularities (non-obvious
   environment facts), and the safe-update procedure.
7. **Ships templates + scripts** ([`templates/`](templates/),
   [`scripts/`](scripts/)) — non-destructive `setup.sh`, a `doctor.sh` health
   check, `patch.sh`, and `lint.py`, all linted in CI.

## Why a meta-repo (not a monorepo)

Each plugin having its own repo preserves isolation: a bad change to one plugin
can't destabilize others, PRs/reviews are scoped, and a plugin stays alive even
if the hub is deleted. This matches the standalone-repo guarantee that
`hermes-quota-plugin` was built with. Your **LifeOS graph** (`state.json`) and
**OptMem memory** (`LOG.txt`) are local-only and never committed to the hub.

## Layout

```
hermes-hub/
├── plugins.json        # machine-readable index (read by install.sh / sync.sh / CI)
├── prs.json            # unmerged-PR tracker (core hooks the setup depends on)
├── patches.json        # out-of-tree runtime patches (e.g. Claude OAuth bypass)
├── install.sh          # clone + enable all listed plugins (topo order, lifecycle-aware)
├── sync.sh             # fast-forward pull all installed plugins
├── docs/               # onboarding, profiles, vault, usecases, experiments,
│                       #   claude-auth, particularities, updating
├── templates/          # neutral profile + vault + config starter configs
├── scripts/            # setup.sh (scaffold), doctor.sh (verify), patch.sh, lint.py (CI)
└── README.md
```

## Quick start

```bash
git clone https://github.com/rarf/hermes-hub.git ~/hermes-hub
cd ~/hermes-hub

bash install.sh        # OptMem -> LifeOS -> quota (dependency order)
bash scripts/setup.sh  # scaffold profiles + surface vault template (non-destructive)
hermes restart
bash scripts/doctor.sh # verify
```

`HERMES_HOME` is resolved automatically (`~/AppData/Local/hermes` on Windows, or
`$XDG_DATA_HOME/hermes`). Override with `HERMES_HOME=/path bash install.sh`.

## Plugins

| Plugin | Repo | Lifecycle | Depends on | Core PRs |
|--------|------|-----------|-----------|----------|
| **optmem** | [rarf/optmem-hermes-plugin](https://github.com/rarf/optmem-hermes-plugin) | stable | — | — |
| **lifeos** | [rarf/lifeos-hermes-plugin](https://github.com/rarf/lifeos-hermes-plugin) | active | optmem | — |
| **quota** | [rarf/hermes-quota-plugin](https://github.com/rarf/hermes-quota-plugin) | stable | — | [rarf/footer-hook](https://github.com/rarf/footer-hook), [rarf/usage-extra-hook](https://github.com/rarf/usage-extra-hook) |

## Docs map

- [docs/onboarding.md](docs/onboarding.md) — fresh-machine end-to-end setup.
- [docs/profiles.md](docs/profiles.md) — profile map (default, casa) + switching.
- [docs/vault.md](docs/vault.md) — Obsidian + LifeOS vault.
- [docs/usecases.md](docs/usecases.md) — domains → plugins/skills (what's productive).
- [docs/experiments.md](docs/experiments.md) — experimental vs promoted.
- [docs/claude-auth.md](docs/claude-auth.md) — Claude Code OAuth billing bypass + survive-`hermes update`.
- [docs/particularities.md](docs/particularities.md) — non-obvious environment facts (routing, GW, x_search, LifeOS SoT).
- [docs/updating.md](docs/updating.md) — `hermes update` + **keeping unmerged PRs + patches alive**.

## Adding a plugin

1. Create the plugin's own repo (e.g. `rarf/hermes-<name>-plugin`), standalone.
2. Add an entry to `plugins.json` (see the existing `optmem` entry for the shape;
   set `depends_on` if it needs another plugin, `lifecycle`, and `tracked_by_prs`
   if it relies on an unmerged core PR).
3. If it depends on an unmerged core PR, add that PR to `prs.json`.
4. Commit + push the hub, run `python scripts/lint.py` (or let CI run), then
   `bash install.sh`.

Do **not** use git submodules — that would fold plugin history into the hub and
break the standalone-repo property.
