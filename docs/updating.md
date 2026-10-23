# Updating Hermes — and keeping your unmerged PRs

`hermes update` upgrades the **gateway/core**. That's good — but it can also
**overwrite or drop local patches** you depend on (notably the core hook PRs
that the `quota` plugin relies on). This doc is the procedure to update safely
and keep unmerged PRs alive.

## The unmerged-PR problem

Your `quota` plugin's footer block depends on two **core hooks** that are NOT
yet merged into Hermes core:

- `rarf/footer-hook`
- `rarf/usage-extra-hook`

These are tracked in [`prs.json`](prs.json) with `state: "open"`. If
`hermes update` ships a conflicting core change, the hooks may stop applying.

## Safe update procedure

1. **Snapshot before updating.**
   ```bash
   bash scripts/doctor.sh --snapshot > doctor-before.txt
   ```
2. **Update core.**
   ```bash
   hermes update
   hermes restart
   ```
3. **Verify hooks/plugins survived.**
   ```bash
   bash scripts/doctor.sh
   ```
   `doctor.sh` checks: plugins enabled, LifeOS API up, and that each
   `tracked_by_prs` entry from `prs.json` still resolves (hook present / PR
   still open).
4. **If a tracked PR's patch was dropped**, re-apply it:
   ```bash
   # example shape — adjust to the PR's current diff
   gh api repos/NousResearch/hermes-agent/pulls/<n> --jq '.head.sha'
   git -C "$HERMES_HOME/.." apply <(gh pr diff <n>)
   ```
   (Exact re-apply steps live next to each entry in `prs.json`.)
5. **Sync plugins** to their latest (plugins keep their own repos, unaffected by
   core update):
   ```bash
   bash sync.sh
   ```

## Updating plugins only (no core change)

Plugins are standalone repos — `hermes update` never touches them. Just:

```bash
bash sync.sh        # fast-forward pull every installed plugin
```

## prs.json as the tracker

`prs.json` is the single source of truth for **unmerged PRs you care about**,
across Hermes core and any plugin repo. CI lint checks it stays valid JSON and
that every `tracked_by_prs` reference in `plugins.json` exists in `prs.json`.
See `prs.json` for the live list + re-apply notes.

## Rule of thumb

> Update core on a cadence (e.g. weekly). Always run `doctor.sh` after. Treat
> any `tracked_by_prs` entry as "mine to keep alive" until it's merged upstream
> or superseded.
