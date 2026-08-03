# Experiments — what we're validating

This hub tracks **experimental** pieces separately so the productive baseline
stays clean. Experimental plugins are skipped by `install.sh` unless you pass
`--all`. Experimental core changes are tracked in `prs.json` (unmerged PRs).

## Current experiments

| Experiment | What | Status | Risk if it breaks |
|------------|------|--------|-------------------|
| **OptMem as permanent memory** | Local append-only LOG + decay TREE replacing/backing cloud memory | `active` (default memory layer for LifeOS) | Low — pure stdlib, offline; falls back to cloud providers |
| **LifeOS Dashboard localhost API** | Plugin starts `127.0.0.1:9128` HTTP API (core only auto-imports bundled `dashboard/plugin_api.py`) | `active` | Medium — if port busy, dashboard tab shows status, still renders |
| **Core hook PRs (footer / usage_extra)** | `rarf/footer-hook`, `rarf/usage-extra-hook` — quota plugin depends on these unmerged hooks | `pending merge` | Medium — `hermes update` can clobber them; see [updating.md](updating.md) |
| **Honcho as memory provider** | Self-hosted Honcho alternative to cloud memory | `experimental` | Isolated — opt-in |

## Promotion rule

An experiment is promoted from `experimental` → `active`/`stable` when:

1. It has run daily for ≥ 2 weeks without manual intervention.
2. `doctor.sh` verifies it cleanly on a fresh `hermes update`.
3. Its unmerged-PR dependency (if any) is either merged upstream or pinned as a
   tracked patch in `prs.json`.

Update `plugins.json` `lifecycle` and `prs.json` `state` when promoting.
