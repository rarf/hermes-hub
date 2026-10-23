# Use cases — what this setup covers

Your Hermes is organized around **LifeOS domains**. Each domain maps to a set of
plugins / skills / surfaces. This is the "what's productive" map.

| Domain | What it's for | Served by |
|--------|--------------|-----------|
| **Família** | Family ops, couple communication, coaching | `family-ops-casa`, `coaching-casamento`, LifeOS dashboard, profile `casa` |
| **Casa** | Home, obra (renovation), household function | `home-assistant` (smart home), `family-ops-casa`, LifeOS objective "Avançar obra" |
| **Alldrivers** | Product: paywall, growth, 30 paying clients, churn | `alldrivers-*` skills, LifeOS objective + KRs, Hermes orchestrates leaf agents |
| **Jscrambler** | PM work — audit, allocation, KRs | LifeOS domain only; **do not execute Jscrambler project code here** (PM scope) |
| **Personal** | Finances, health/energy, time coaching | `financas` (local DB app), `coach-tempo` (Capitão), OptMem, LifeOS |

## Surfaces (LifeOS adapters)

LifeOS renders across Hermes's native surfaces — no custom fork:

- **Dashboard** — operational cockpit tab (localhost API on `127.0.0.1:9128`).
- **Kanban** — task boards per project.
- **Skills** — domain skills (`family-ops-casa`, `coaching-casamento`, `alldrivers-*`).
- **Cron** — daily briefings, check-ins, finance monthly review.
- **Session History** — links Hermes sessions to LifeOS objectives/KRs.
- **MCPs / Hermes Plugins** — OptMem (memory), quota (footer), LifeOS itself.

## What is productive vs experimental

See [experiments.md](experiments.md) for the split. In short: LifeOS + OptMem +
quota + the domain skills are **productive**; anything marked `experimental` in
`plugins.json` or `prs.json` is being validated before it's trusted daily.
