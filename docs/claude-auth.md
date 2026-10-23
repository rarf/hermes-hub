# Claude Code OAuth billing bypass

How rarf's Hermes routes Claude Code through the Max/Pro subscription instead
of direct Anthropic billing — and, critically, how to keep it alive across
`hermes update`.

## What it is

An **out-of-tree patch** ([`rarf/hermes-claude-auth`](https://github.com/rarf/hermes-claude-auth))
that monkey-patches `build_anthropic_kwargs` at runtime via a Python import hook
(`sitecustomize.py`). It does **not** modify hermes-agent source. It passes
Anthropic's server-side OAuth content validation so third-party tools are
accepted.

> This is tracked in [`patches.json`](patches.json), **not** `plugins.json` —
> it is a runtime patch layer, not a Hermes plugin.

## Install

```bash
git clone https://github.com/rarf/hermes-claude-auth.git ~/hermes-claude-auth
cd ~/hermes-claude-auth
./install.sh
```

`install.sh` copies `anthropic_billing_bypass.py` to
`~/AppData/Local/hermes/patches/` and installs the loader as `sitecustomize.py`
in the Hermes venv's `Lib/site-packages/`. Restart the gateway.

Verify — every `hermes` invocation should print:

```
[anthropic_billing_bypass] Bypass installed
[anthropic_billing_bypass] Transport unwrap hook installed
[anthropic_billing_bypass] Rate-limit auto-wait installed
```

## Surviving `hermes update` (the important part)

`hermes update` kills the loader two ways: (1) `git merge --ff-only` of
hermes-agent, and (2) venv rebuild that deletes `sitecustomize.py`. The bypass
ships a **two-layer defense**:

1. **Durable canonical loader** at
   `~/AppData/Local/hermes/patches/sitecustomize.py`.
2. **Git hooks via `core.hooksPath`** (outside the repo, so `git stash` during
   update doesn't drop them):

   ```bash
   mkdir -p "$LOCALAPPDATA/hermes/git-hooks"
   cp post-merge.hook.sh "$LOCALAPPDATA/hermes/git-hooks/post-merge"
   cp post-checkout.hook.sh "$LOCALAPPDATA/hermes/git-hooks/post-checkout"
   chmod +x "$LOCALAPPDATA/hermes/git-hooks/post-"*
   git -C "$LOCALAPPDATA/Hermes/hermes-agent" config core.hooksPath "$LOCALAPPDATA/hermes/git-hooks"
   ```

   The `post-merge` hook restores `venv/Lib/site-packages/sitecustomize.py`
   from `patches/sitecustomize.py` on every update.

This is why the hub keeps patches separate from plugins: each layer has its own
survival mechanism that `hermes update` must not silently undo.

## Context cap (cost protection) — `custom_providers`

Claude Code 2.1.186 exposes a 1M context via OAuth, but it carries a **5x token
multiplier above 200k** — a cost trap for long sessions (the quota-burning
pattern). Cap Claude context at 200k using `custom_providers` in `config.yaml`
(template: [`templates/config/anthropic-context-cap.yaml`](templates/config/anthropic-context-cap.yaml)).

**Critical rule:** do **NOT** add `api_key` / `key_env` to the Anthropic
`custom_provider`. Without them Hermes inherits native Anthropic credentials and
the billing bypass stays active; adding them routes to the custom provider and
**breaks OAuth**. `custom_providers` (read at startup from `config.yaml`)
overrides `models.dev` and survives `hermes update` without hooks.

## Version detection — do NOT pin

Never pin Claude Code to a static version (currently `2.1.186`). Detect at
runtime via `claude --version` and use it for both the `user-agent` and the
signed `cc_version` billing header. Static pins cause the wire-format mismatch
that triggered upstream issue #6. Fallback only when `claude` is absent.

## Pitfalls (from production)

- `sitecustomize.py` in the venv is overwritten by `hermes update`; the durable
  copy under `patches/` survives — rely on the post-merge hook.
- Delete `patches/__pycache__` after editing the bypass; stale bytecode lies.
- Config changes after gateway start may not be active — compare `config.yaml`
  mtime to `agent.log: Starting Hermes Gateway...`.
- A healthy bypass does **NOT** prevent quota from advancing; real burn is
  request size + session length (see [particularities.md](particularities.md)).
- `context-management` / `compact` betas don't work via bypass (architectural:
  requires rewriting Hermes' message list) — keep local compression
  (`threshold_tokens:120000` + `model_thresholds.claude:0.35`) + 200k cap.
- `bash /tmp` ≠ Python's `/tmp` (git-bash `/tmp` → `%TEMP%`); pass native paths
  to Python.

## Fork hygiene

Before opening a PR upstream: confirm the fix isn't covered by an open upstream
PR (e.g. #21 fingerprint parity, #27 auto-wait) or already on upstream main.
Prefer one explanatory issue comment over duplicate PRs.

## Doctor

`scripts/doctor.sh` checks the bypass loader is present (patches + venv copies)
and that `hermes` startup logs the three `[anthropic_billing_bypass]` lines.
