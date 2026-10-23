"""Checks that the skill folder follows the Agent Skills spec and our own rules."""

from __future__ import annotations

import re
from pathlib import Path

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


def test_referenced_files_exist_and_are_one_level_deep() -> None:
    _, body = frontmatter()
    links = re.findall(r"\]\(([^)#]+)\)", body)
    assert links
    for link in links:
        path = SKILL_ROOT / link
        assert path.is_file(), link
        if path.suffix == ".md":
            nested = re.findall(r"\]\(([^)#]+\.md)\)", path.read_text(encoding="utf-8"))
            assert not nested, f"{link} links further to {nested}"


def test_long_references_have_contents() -> None:
    for ref in (SKILL_ROOT / "references").glob("*.md"):
        text = ref.read_text(encoding="utf-8")
        if len(text.splitlines()) > 100:
            assert "## Contents" in text, ref.name


def test_every_track1_problem_is_indexed() -> None:
    index = (SKILL_ROOT / "references" / "track1-sequences.md").read_text(encoding="utf-8")
    problems = [p.name for p in (SKILL_ROOT / "problems").iterdir() if p.is_dir()]
    assert problems
    for pid in problems:
        if pid.startswith("t1-"):
            assert pid in index


def test_tutor_command_matches_allowed_tools() -> None:
    fields, body = frontmatter()
    command = "Rscript ${CLAUDE_SKILL_DIR}/scripts/tutor.R"
    assert fields["allowed-tools"] == f"Bash({command} *)"
    assert command in body
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
