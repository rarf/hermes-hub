# Profiles

Hermes profiles isolate config, sessions, skills, plugins, crons and memory.
Current default state is `~/.hermes`; named profiles live at
`~/.hermes/profiles/<name>`. An explicit `HERMES_HOME` overrides that location.
Legacy Windows examples elsewhere in this hub are historical, not the active
Linux runtime path.

A profile is a state boundary, not a filesystem or credential sandbox. Host
terminal tools normally keep the real OS `HOME`; verify credential reuse and
exact tool working directory separately.

## Known profiles

| Profile | Purpose | Isolation rule |
|---------|---------|----------------|
| `default` | General baseline and setup work. | Existing personal memory/history retained. |
| `alldrivers-dev` | Bounded AllDrivers delivery and applicable gates. | Work-only OptMem and curated skills. |
| `alldrivers-support` | Support/evidence, read-only by default. | Work-only OptMem; mutations need exact approval. |
| `casa` (template) | Family/home starter, not claimed as an active profile. | Do not create/activate or copy its personal context into work profiles. |

The AllDrivers roles are real named profiles; LifeOS is not required for their
coordination. Live gateway service and access status require execution proof,
not merely a row in this table.

## Switching profiles

```bash
hermes profile use <name>     # e.g. hermes profile use casa
hermes profile use default    # back to baseline
```

A profile switch loads that profile's skills/plugins/cron/memories for the
next session. Do **not** edit another profile's `skills/plugins/cron/memories`
unless explicitly directed — `patch`/`write_file` guard against cross-profile
writes by default.

## Creating a new profile

1. `hermes profile create <name>` (or copy the layout from `default`).
2. Copy the relevant plugin enablement + skills from `templates/profiles/<name>/`
   (the hub ships neutral templates, not your live data).
3. Run `doctor.sh` to confirm the profile's plugins resolve.

## AllDrivers work profiles (2026-10-01)

The current Linux setup uses `~/.hermes` for default and
`~/.hermes/profiles/<name>` for named profiles. `HERMES_HOME` selects the state
boundary; terminal working directory and real OS `HOME` are separate.

`alldrivers-dev` and `alldrivers-support` clone existing configuration/access,
then curate relevant skills and keep only OptMem/quota plugins. They do not
inherit personal memory, channels or scheduled jobs. OptMem stores are distinct
and configured `optmem-only`; model/CLI access is reused rather than re-created.

Review is proportionate to code risk/complexity, not a universal Antigravity
round for simple decisions, configuration or documentation. Required release
and risky-boundary reviews are not waived.

The owner-authorized compact rollout is installed in default and the selected
AllDrivers profiles. Default retains access to every skill in the combined work
allowlists, rather than becoming a work-only profile. The four compact skills
are `authenticated-saas-operations`, `local-test-preflight`,
`release-gate-orchestration` and `synthetic-fixture-delivery`; support keeps only
its two already-selected members. Each installed copy has the same compact
entrypoint and complete, current `references/original-SKILL.md`, plus unchanged
topic references/scripts. Stage-specific full-recipe loading remains mandatory.
Fresh-process actual skill-loader checks passed in all three profiles. Existing
sessions may retain earlier loaded instructions; no live turn was restarted.
Private snapshots, test guards, install/readback receipts and rollback copies
are under `_local/alldrivers-profile-rollout/compact-refresh/`. Update both the
compact boundary and retained complete recipe when adding a new safety rule;
do not edit a copied profile independently and silently let versions diverge.
Gateway activation is excluded from this skills rollout and left to the owner.

The owner approved one shared MCP token directory (not refresh-token copies).
Credentials and host filesystem are therefore shared, while Hermes memory and
sessions remain profile-local. Profiles are not security sandboxes.

Use the **existing default gateway only**. Verify live `served_profiles` before
claiming multiplex service. The current single-profile gateway needs a
controlled, owner-approved restart to adopt multiplexing; no second service is
needed. Keep #402/#403 ownership unchanged and start the next milestone with a
verified handoff after the current gates.

See [the rollout contract](../templates/profiles/alldrivers/README.md) and the
[official profiles guide](https://hermes-agent.nousresearch.com/docs/user-guide/profiles).

## Template source of truth

`templates/profiles/` holds **neutral starter** configs (skills lists, plugin
enablement hints). Your live profile data is local-only and never committed.
