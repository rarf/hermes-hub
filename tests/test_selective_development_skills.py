#!/usr/bin/env python3
"""Validate the selective Superpowers/Ponytail skill integration."""

from pathlib import Path
import re

import yaml


ROOT = Path.home() / ".hermes" / "skills" / "software-development"
NAMES = (
    "minimal-correct-solution",
    "verification-before-completion",
    "plan",
    "requesting-code-review",
    "simplify-code",
)


def load_skill(name: str) -> tuple[dict, str]:
    path = ROOT / name / "SKILL.md"
    text = path.read_text(encoding="utf-8")
    assert text.startswith("---\n"), f"{name}: frontmatter is not at byte zero"
    match = re.match(r"^---\n(.*?)\n---\n(.+)$", text, re.DOTALL)
    assert match, f"{name}: malformed frontmatter or empty body"
    metadata = yaml.safe_load(match.group(1))
    assert isinstance(metadata, dict), f"{name}: frontmatter is not a mapping"
    return metadata, text


def require(text: str, *phrases: str) -> None:
    lowered = text.lower()
    for phrase in phrases:
        assert phrase.lower() in lowered, f"missing required phrase: {phrase}"


def main() -> None:
    skills = {name: load_skill(name) for name in NAMES}

    for name, (metadata, text) in skills.items():
        for key in (
            "name",
            "description",
            "version",
            "author",
            "license",
            "platforms",
            "metadata",
        ):
            assert key in metadata, f"{name}: missing {key}"
        assert metadata["name"] == name, f"{name}: frontmatter name mismatch"
        assert len(metadata["description"]) <= 60, f"{name}: description exceeds 60 characters"
        assert metadata["description"].endswith("."), f"{name}: description needs a period"
        assert metadata["platforms"] == ["linux", "macos", "windows"]
        assert "toolsets=" not in text, f"{name}: unsupported delegate_task argument"

    minimal = skills["minimal-correct-solution"][1]
    ordered = (
        "Does the change need to exist?",
        "equivalent helper, utility, type, endpoint",
        "standard library",
        "platform or framework",
        "already-installed dependency",
        "smaller implementation",
        "Only then write new code",
    )
    positions = [minimal.index(phrase) for phrase in ordered]
    assert positions == sorted(positions), "minimal decision order changed"
    require(
        minimal,
        "input validation",
        "security controls",
        "error handling",
        "accessibility",
        "observability",
        "tests that cover relevant behavior",
        "Do not code-golf",
        "enumerate every caller",
        "root cause",
    )

    verification = skills["verification-before-completion"][1]
    require(
        verification,
        "Name the claim",
        "Choose proof",
        "Run it now",
        "exit code",
        "Count failures",
        "Compare with the requirement",
        "Report honestly",
        "subagent's success report",
        "real user path",
        "proportional to risk",
    )

    plan = skills["plan"][1]
    require(
        plan,
        "**spike**",
        "**bounded**",
        "**architectural**",
        "Do not ask questions when",
        "Escalate to a heavier class",
        "verification-before-completion",
    )
    assert "Each task = 2-5 minutes" not in plan

    review = skills["requesting-code-review"][1]
    require(
        review,
        "Selective minimal-solution review",
        "simplify-code",
        "complexity review, not a correctness gate",
        "verification-before-completion",
    )

    simplify = skills["simplify-code"][1]
    require(
        simplify,
        "Minimal-solution review mode",
        "an abstraction with one implementation",
        "wrapper that only delegates",
        "unnecessary dependency",
        "standard-library, platform, or framework",
        "configuration or flags with no current consumer",
        "dead code",
        "speculative layers",
        "removable boilerplate",
        "simple duplication",
        "complements normal code review and never replaces it",
    )

    for field in ("Location:", "Remove:", "Replace with:", "Impact/limit:", "Estimated reduction:"):
        assert field in review, f"requesting-code-review: missing {field}"
        assert field in simplify, f"simplify-code: missing {field}"

    print(f"PASS: {len(NAMES)} skill files parsed and validated")
    print("PASS: minimal-solution order and safety guardrails")
    print("PASS: completion evidence procedure")
    print("PASS: proportional planning classification")
    print("PASS: selective complexity-review integration")


if __name__ == "__main__":
    main()
