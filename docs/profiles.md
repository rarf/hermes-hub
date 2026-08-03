# Profiles

Hermes supports **profiles** — isolated sessions, each with its own
`skills/`, `plugins/`, `cron/`, and `memories/`. Profiles live at:

```
%LOCALAPPDATA%\hermes\profiles\<name>\
```

The **default** profile is where most of this hub's plugins run. Some domains
are intentionally isolated so a profile's memory/skills can't leak across
contexts.

## Known profiles

| Profile | Purpose | Isolation rule |
|---------|---------|----------------|
| `default` | General personal + this hub's plugins (OptMem, LifeOS, quota). CLI default. | baseline |
| `casa`   | Family / home domain (`family-ops-casa`, `coaching-casamento`). | Casa/Márcia context kept separate from work. |

> Other work domains (Alldrivers, Jscrambler) are tracked **inside LifeOS as
> domains/objectives**, not as separate Hermes profiles — they share the
> `default` profile but are scoped by the LifeOS work graph. Adjust if you'd
> rather split them into profiles.

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

## Template source of truth

`templates/profiles/` holds **neutral starter** configs (skills lists, plugin
enablement hints). Your live profile data is local-only and never committed.
