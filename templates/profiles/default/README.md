# Profile template: `default`

Neutral starter config for the `default` Hermes profile. This is **not** your
live data — it's the shape setup.sh scaffolds when the profile is absent.

## Skills to enable (examples — adjust to taste)
- optmem-hermes-plugin (memory)
- lifeos-hermes-plugin (cockpit)
- hermes-quota-plugin (footer)
- family-ops-casa, coaching-casamento (only if running default across domains)

## Plugins enabled by default (see plugins.json)
- optmem, lifeos, quota

## Notes
- `default` is the CLI baseline. Casa/Márcia context is isolated into profile
  `casa` (see templates/profiles/casa). Adjust the split in docs/profiles.md.
- Live memory (`LOG.txt`), LifeOS (`state.json`), and profile memories are
  local-only and never committed to the hub.
