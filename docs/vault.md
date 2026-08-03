# Vault (Obsidian + LifeOS)

LifeOS keeps its work graph in `$HERMES_HOME/lifeos/state.json` (machine source
of truth). The human-friendly **second brain** is an Obsidian vault that mirrors
life/OKR notes and session history.

## Initialize the vault

Use the LifeOS plugin tool (runs against the local LifeOS instance):

```
lifeos_init_vault   # creates/verifies the private Obsidian vault
```

This scaffolds the vault with domain folders matching your LifeOS domains:
Família, Alldrivers, Jscrambler, Personal, Casa.

## Two-machine sync (optional)

If you run Hermes on more than one machine, use the
`vault-sync-multimachine` approach to keep a canonical vault shared:

- Pick one machine as canonical (holds the source vault).
- Sync via your chosen transport (Git private repo, Syncthing, or
  OneDrive/Google Drive) — the vault is plain markdown, no server needed.
- `doctor.sh` can warn if the vault on this machine is behind the canonical
  copy (timestamp check).

## Vault conventions

- **Notes** are plain markdown; frontmatter carries `domain:` and `kr:` so
  LifeOS/obsidian skills can cross-link.
- **Never** commit the vault to the hub repo — it's personal data. The hub's
  `.gitignore` already excludes runtime artifacts; keep vaults out of `~/hermes-hub`.
- LifeOS state (`state.json`) and OptMem (`LOG.txt`) are the live SoT; the vault
  is a readable mirror, not the other way around.
