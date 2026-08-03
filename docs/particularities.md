# Particularities — non-obvious Hermes setup facts

Institutional knowledge that isn't obvious from any single repo. Read this
before debugging a "why is X broken" issue.

## Provider routing

- **Claude billing bypass** keeps Claude Code on the Max/Pro subscription; see
  [claude-auth.md](claude-auth.md). A *healthy* bypass does **not** stop quota
  from advancing — burn is driven by request size + session length.
- **`luna` is NEVER billed via Anthropic** (verified across all profiles). Don't
  "fix" routing by adding `api_key` to a `custom_provider` — that breaks the
  OAuth bypass (see claude-auth.md critical rule).
- **x_search triad**: requires `platform_toolsets` enabled + `provider: xai` +
  active-profile `auth.json`. A `[✓]` banner does **not** mean the tool is
  callable — if `x_search` / `tool_describe` returns unavailable, run `/new` or
  `hermes profile use <profile>` to load the right auth.
- **Consumption** should be tied to *quota*, not raw billing (`quota_cache.json`
  was all `None` — wire consumption to quota, not just billing totals).

## Google Workspace

- Credentials live **only** in Hermes. `setup.py --check` may report
  `AUTHENTICATED (partial)` — proceed with existing scopes; only re-open OAuth
  if a *critical* scope is missing.
- Calendar can return `[]` even with events present — cross-check against Gmail
  before concluding "no events".

## Language & domains

- Responses are **EN by default** (practice). Casa/casal use `family-ops-casa` +
  `coaching-casamento` skills; **Todoist is out of family/casa scope** (use
  LifeOS/vault there).
- Default CLI profile = `default`; switch explicitly with
  `hermes profile use <name>`.

## LifeOS source of truth

- The LifeOS plugin API on `:9128` is the SoT. If the API is closed, read
  `C:\Users\ronal\AppData\Local\hermes\lifeos\state.json` directly.

## Debugging first step

- Before blaming an external system, **check `agent.log` first** — absence of a
  trace in one place doesn't prove absence of cause.

## AllDrivers fork-PR conflicts

- GitHub conflicts a PR's head against *current main*, not the PR's base. Don't
  declare resolved just because merge against the base is clean; reproduce
  against the real base, one semantic rule per region, single
  `--force-with-lease` push.
