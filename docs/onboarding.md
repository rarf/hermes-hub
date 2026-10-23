# Onboarding — fresh machine / fresh Hermes

This is the end-to-end path from "empty Windows box" to "fully wired rarf Hermes
setup" (OptMem memory + LifeOS cockpit + quota footer + profiles + Obsidian vault).

> Everything here is **orchestrated** by the hub. The hub never forks Hermes
> core and never folds plugin history into itself — it clones standalone repos
> and documents the local config you must apply by hand (profiles, vault).

## 0. Prerequisites

- Windows 10/11 with [Git for Windows](https://git-scm.com/) (bash/MSYS).
- Python 3.11+ on PATH (`python --version`).
- `hermes` CLI installed and on PATH (Nous Research Hermes Agent).
- GitHub auth: `gh auth login` (account `rarf`) so clones over HTTPS work.

## 1. Clone the hub

```bash
git clone https://github.com/rarf/hermes-hub.git ~/hermes-hub
cd ~/hermes-hub
```

## 2. Install plugins (OptMem → LifeOS → quota, in dependency order)

```bash
bash install.sh          # installs stable + active; skips experimental
# bash install.sh --all  # also installs lifecycle=experimental plugins
```

`install.sh` topologically sorts by `depends_on` so **OptMem installs before
LifeOS** (LifeOS uses OptMem as its permanent memory layer). Each plugin is
cloned into `$HERMES_HOME/plugins/<path>` and enabled.

## 3. Apply local config templates

```bash
bash scripts/setup.sh    # scaffolds profiles + vault from templates/
```

`setup.sh` is **non-destructive**: it only creates entries that don't already
exist. See [profiles.md](profiles.md) and [vault.md](vault.md).

## 4. Restart the Hermes daemon

```bash
hermes restart           # or whatever your install uses to reload plugins
```

LifeOS seeds a neutral template graph on first run. Edit/replace
`seed_known_lifeos.py` in the LifeOS repo to make it yours (the hub does not
commit your personal graph).

## 5. Verify

```bash
bash scripts/doctor.sh   # checks plugins enabled, hooks present, PRs tracked
```

## 6. Daily use

- LifeOS Dashboard tab → your cockpit (objectives/KRs/tasks across domains).
- `memo wake` (OptMem) at session start, or let the plugin hook inject it.
- `bash sync.sh` to fast-forward-pull every plugin.

## Rollback / re-install

Delete `$HERMES_HOME/plugins/<id>` and re-run `install.sh`, or `hermes plugins
disable <id>`. The hub never touches your `state.json` (LifeOS) or `LOG.txt`
(OptMem) — those are your data, kept out of git.
