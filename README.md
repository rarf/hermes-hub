# Hermes Hub

Central index + install scripts for rarf's Hermes plugins.

This is a **meta-repo**: it does NOT contain plugin source. Each plugin keeps
its own GitHub repo (own history, PRs, release tags) so it survives
`hermes update`. This hub only:

1. **Indexes** the plugins in [`plugins.json`](plugins.json) (repo URL, branch,
   install path, core hook dependencies).
2. **Installs** them via [`install.sh`](install.sh) (clones into
   `$HERMES_HOME/plugins/<path>` and enables each).
3. **Syncs** them via [`sync.sh`](sync.sh) (fast-forward pull to latest).

## Why a meta-repo (not a monorepo)

Each plugin having its own repo preserves isolation: a bad change to one plugin
can't destabilize others, PRs/reviews are scoped, and a plugin stays alive even
if the hub is deleted. This matches the standalone-repo guarantee that
`hermes-quota-plugin` was built with.

## Layout

```
hermes-hub/
├── plugins.json     # machine-readable index (read by install.sh / sync.sh)
├── install.sh       # clone + enable all listed plugins
├── sync.sh          # fast-forward pull all installed plugins
└── README.md        # this file
```

## Usage

```bash
# One-time (or on a fresh machine):
bash install.sh

# Pull latest for every installed plugin:
bash sync.sh
```

`HERMES_HOME` is resolved automatically (`~/AppData/Local/hermes` on Windows, or
`$XDG_DATA_HOME/hermes`). Override with `HERMES_HOME=/path bash install.sh`.

## Plugins

| Plugin | Repo | Core hooks required | Status |
|--------|------|---------------------|--------|
| **quota** | [rarf/hermes-quota-plugin](https://github.com/rarf/hermes-quota-plugin) | `footer`, `usage_extra` (PRs: `rarf/footer-hook`, `rarf/usage-extra-hook`) | ✅ active |

## Adding a plugin

1. Create the plugin's own repo (e.g. `rarf/hermes-<name>-plugin`), following
   the `standalone` plugin manifest convention.
2. Add an entry to `plugins.json` (see the existing `quota` entry for the shape).
3. Commit + push the hub, then run `bash install.sh`.

Do **not** use git submodules — that would fold plugin history into the hub and
break the standalone-repo property.
