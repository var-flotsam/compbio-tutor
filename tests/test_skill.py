"""Checks that the skill folder follows the Agent Skills spec and our own rules."""

from __future__ import annotations

import json
import os
import re
import subprocess
from pathlib import Path

import pytest

SKILL_ROOT = Path(__file__).resolve().parents[1] / "plugin" / "skills" / "compbio-tutor"

SKILL_MD = SKILL_ROOT / "SKILL.md"
SPEC_FIELDS = {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}


def frontmatter() -> tuple[dict[str, str], str]:
    text = SKILL_MD.read_text(encoding="utf-8")
    assert text.startswith("---\n")
    head, body = text[4:].split("\n---\n", 1)
    fields: dict[str, str] = {}
    for line in head.splitlines():
        if line and not line.startswith(" "):
            key, _, value = line.partition(":")
            fields[key.strip()] = value.strip()
    return fields, body


def test_only_spec_fields() -> None:
    fields, _ = frontmatter()
    assert set(fields) <= SPEC_FIELDS
    assert {"name", "description"} <= set(fields)


def test_name_rules() -> None:
    name = frontmatter()[0]["name"]
    assert name == SKILL_ROOT.name
    assert re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name) and len(name) <= 64
    assert "claude" not in name and "anthropic" not in name


def test_description_rules() -> None:
    fields, _ = frontmatter()
    desc = fields["description"]
    assert 0 < len(desc) <= 1024
    assert "<" not in desc and ">" not in desc
    assert "Use when" in desc
    assert len(fields.get("compatibility", "")) <= 500


def test_body_size() -> None:
    _, body = frontmatter()
    assert len(body.splitlines()) < 500


def test_guides_exist_and_link_nowhere() -> None:
    # Guides are printed by `tutor.R guide <name>`, so reading them needs no
    # file access outside the student's course folder.
    _, body = frontmatter()
    assert not re.findall(r"\]\(([^)#]+)\)", body), "use `guide <name>`, not file links"
    guides = set(re.findall(r"`guide ([a-z0-9-]+)`", body))
    assert guides
    for name in guides:
        path = SKILL_ROOT / "references" / f"{name}.md"
        assert path.is_file(), name
        assert not re.findall(r"\]\(([^)#]+\.md)\)", path.read_text(encoding="utf-8")), name
    every = {p.stem for p in (SKILL_ROOT / "references").glob("*.md")}
    assert every == guides, f"guides never mentioned in SKILL.md: {every - guides}"


def test_long_references_have_contents() -> None:
    for ref in (SKILL_ROOT / "references").glob("*.md"):
        text = ref.read_text(encoding="utf-8")
        if len(text.splitlines()) > 100:
            assert "## Contents" in text, ref.name


@pytest.mark.parametrize(
    ("prefix", "guide"), [("r0-", "track0-r-basics.md"), ("t1-", "track1-sequences.md")]
)
def test_every_problem_is_indexed_in_its_track_guide(prefix: str, guide: str) -> None:
    index = (SKILL_ROOT / "references" / guide).read_text(encoding="utf-8")
    problems = [p.name for p in (SKILL_ROOT / "problems").iterdir() if p.is_dir()]
    in_track = [pid for pid in problems if pid.startswith(prefix)]
    assert in_track
    for pid in in_track:
        assert pid in index


def test_tutor_command_matches_allowed_tools() -> None:
    fields, body = frontmatter()
    assert fields["allowed-tools"] == "Bash(compbio-tutor *)"
    assert "compbio-tutor <verb>" in body
    launcher = SKILL_ROOT.parents[1] / "bin" / "compbio-tutor"
    assert launcher.is_file() and os.access(launcher, os.X_OK)
    assert launcher.read_text(encoding="utf-8").startswith("#!/usr/bin/env bash\n")
    assert (SKILL_ROOT / "scripts" / "tutor.R").is_file()


def test_scripts_are_base_r_only() -> None:
    # Students install only R; the tutor must not need packages to start.
    scripts = SKILL_ROOT / "scripts"
    assert not [p for p in scripts.rglob("*") if p.suffix not in {".R", ""}]
    for path in scripts.rglob("*.R"):
        text = path.read_text(encoding="utf-8")
        assert not re.search(r"\b(library|require)\(", text), path.name
        used = set(re.findall(r"\b([A-Za-z][A-Za-z0-9.]*)::", text))
        # BiocManager is only used by `doctor --install-packages`, after installing it.
        assert used <= {"utils", "stats", "tools", "BiocManager"}, (path.name, used)


def test_no_answers_shipped_in_skill() -> None:
    assert not (SKILL_ROOT / "solutions").exists()
    assert not list(SKILL_ROOT.rglob("*solution*"))


def test_skill_size_budget() -> None:
    total = sum(p.stat().st_size for p in SKILL_ROOT.rglob("*") if p.is_file())
    assert total < 10 * 1024 * 1024


PLUGIN_ROOT = SKILL_ROOT.parents[1]
GUARD = PLUGIN_ROOT / "hooks" / "guard.sh"


def run_guard(course: Path, tool: str, tool_input: dict[str, str]) -> bool:
    """True when the hook denies the tool call."""
    payload = json.dumps({"cwd": str(course), "tool_name": tool, "tool_input": tool_input})
    out = subprocess.run(
        ["bash", str(GUARD)], input=payload, capture_output=True, text=True, check=True
    ).stdout
    return '"permissionDecision":"deny"' in out


def test_hook_runs_the_guard() -> None:
    hooks = json.loads((PLUGIN_ROOT / "hooks" / "hooks.json").read_text(encoding="utf-8"))
    (entry,) = hooks["hooks"]["PreToolUse"]
    assert {"Edit", "Write", "MultiEdit", "NotebookEdit", "Bash"} <= set(
        entry["matcher"].split("|")
    )
    assert "${CLAUDE_PLUGIN_ROOT}/hooks/guard.sh" in entry["hooks"][0]["command"]


@pytest.mark.parametrize(
    ("tool", "tool_input", "denied"),
    [
        ("Edit", {"file_path": "{c}/work/r0-variables.R"}, True),
        ("Write", {"file_path": "work/new.R"}, True),
        ("Write", {"file_path": "{c}/data/r0-variables.txt"}, True),
        ("Write", {"file_path": "{c}/.compbio-tutor/progress.dcf"}, True),
        ("Write", {"file_path": "{c}/notes/../work/x.R"}, True),
        ("NotebookEdit", {"notebook_path": "{c}/work/a.ipynb"}, True),
        ("Write", {"file_path": "{c}/notes.md"}, False),
        ("Write", {"file_path": "{c}/workshop.R"}, False),
        ("Bash", {"command": "echo 'x <- 1' > work/r0-variables.R"}, True),
        ("Bash", {"command": "sed -i 's/a/b/' work/r0-variables.R"}, True),
        (
            "Bash",
            {"command": "compbio-tutor grade r0-variables --from-script work/r0-variables.R"},
            False,
        ),
        ("Bash", {"command": "cat work/r0-variables.R 2>/dev/null"}, False),
        ("Read", {"file_path": "{c}/work/r0-variables.R"}, False),
    ],
)
def test_guard_protects_the_students_files(
    tmp_path: Path, tool: str, tool_input: dict[str, str], denied: bool
) -> None:
    (tmp_path / ".compbio-tutor").mkdir()
    filled = {k: v.replace("{c}", str(tmp_path)) for k, v in tool_input.items()}
    assert run_guard(tmp_path, tool, filled) is denied


def test_guard_does_nothing_outside_a_course_folder(tmp_path: Path) -> None:
    assert not run_guard(tmp_path, "Edit", {"file_path": str(tmp_path / "work" / "x.R")})
