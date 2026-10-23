# Selective development workflows

This Hermes installation adopts selected process ideas from Superpowers and selected simplicity ideas from Ponytail without installing either plugin.

## Ownership and runtime location

`hermes-hub` owns this setup decision. The active skills remain in the default profile at `~/.hermes/skills/software-development/`, which is Hermes' native user-local skill location.

## Active skills

### New

- `minimal-correct-solution` — ordered need/reuse/stdlib/platform/installed-dependency/smaller-design/new-code decision, with explicit correctness guardrails.
- `verification-before-completion` — claim-specific, fresh, proportional evidence before advancement or completion statements.

### Adapted

- `plan` — classifies work as `spike`, `bounded`, or `architectural` and scales planning depth accordingly.
- `requesting-code-review` — invokes a selective complexity pass only when the diff has concrete complexity signals, then requires fresh completion evidence.
- `simplify-code` — provides a lightweight, read-only Minimal-solution review mode instead of adding a duplicate overengineering-review skill.

## Deliberate exclusions

- No `obra/superpowers` or `DietrichGebert/ponytail` installation.
- No global hook, always-on prompt injection, telemetry, or process-global mode.
- No generic router skill.
- No duplicate `minimal-solution-review`; the existing `simplify-code` skill owns that focused mode.
- No reduction of security, validation, error handling, accessibility, observability, or relevant tests in the name of fewer lines.

## Verification

Run:

```bash
python tests/test_selective_development_skills.py
bash scripts/doctor.sh
```

The first command validates frontmatter and the required behavioral contracts in the five active skill files. The doctor validates the wider Hermes hub setup; its non-fatal warnings remain separate from test failures.
