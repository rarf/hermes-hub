#!/usr/bin/env bash
# setup.sh — scaffold rarf's local Hermes config from hub templates/.
# NON-DESTRUCTIVE: creates only what's missing; never overwrites live data.
set -euo pipefail

HUB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES="$HUB_DIR/templates"

if [[ -z "${HERMES_HOME:-}" ]]; then
  HERMES_HOME="${XDG_DATA_HOME:-$HOME/AppData/Local}/hermes"
fi
export HERMES_HOME
PROFILES_DIR="$HERMES_HOME/profiles"

echo "Hermes hub — setup (non-destructive)"
echo "  HERMES_HOME = $HERMES_HOME"

# --- profiles ----------------------------------------------------------------
mkdir -p "$PROFILES_DIR"
for pt in "$TEMPLATES"/profiles/*/; do
  name=$(basename "$pt")
  target="$PROFILES_DIR/$name"
  if [[ -d "$target" ]]; then
    echo "  profile '$name': exists — left untouched"
  else
    echo "  profile '$name': creating from template"
    mkdir -p "$target"/{skills,plugins,cron,memories}
    cp "$pt"README.md "$target"/README.md 2>/dev/null || true
  fi
done

# --- vault (LifeOS Obsidian) -------------------------------------------------
# The vault is created by the LifeOS plugin's own tool (lifeos_init_vault).
# Here we only surface the template so the user knows the expected shape.
echo
echo "  Vault: run 'lifeos_init_vault' (LifeOS plugin) to scaffold the Obsidian"
echo "         vault. Expected skeleton is in templates/vault/README.md."
echo
echo "Setup complete. Next: 'hermes restart', then 'bash scripts/doctor.sh'."
