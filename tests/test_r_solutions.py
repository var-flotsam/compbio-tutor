"""Run the reference R solutions on several seeds and grade their output.

Skipped when Rscript is not installed; CI installs R so these always run there.
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import pytest

from tutorlib.problems import Problem

ROOT = Path(__file__).resolve().parents[1]
SOLUTIONS = ROOT / "solutions"
RSCRIPT = shutil.which("Rscript")


def solution_ids() -> list[str]:
    return sorted(p.stem for p in SOLUTIONS.glob("*.R"))


def test_every_problem_has_a_solution(problems: dict[str, Problem]) -> None:
    assert set(solution_ids()) == set(problems)


@pytest.mark.parametrize("pid", solution_ids())
def test_solution_matches_starter(problems: dict[str, Problem], pid: str) -> None:
    """Every non-blank line of the starter appears in the solution, so they stay in sync."""
    problem = problems[pid]
    starter = (problem.folder / problem.starter).read_text(encoding="utf-8").splitlines()
    solution = set((SOLUTIONS / f"{pid}.R").read_text(encoding="utf-8").splitlines())
    skip = ("___", "library(")
    missing = [ln for ln in starter if ln.strip() and not any(s in ln for s in skip)]
    missing = [ln for ln in missing if ln not in solution]
    # The last line of a starter often prints a value; solutions print with cat().
    assert len(missing) <= 1, missing


@pytest.mark.skipif(RSCRIPT is None, reason="Rscript not installed")
@pytest.mark.parametrize("pid", solution_ids())
@pytest.mark.parametrize("seed", [1, 2, 3, 11])
def test_solution_is_graded_correct(
    problems: dict[str, Problem], pid: str, seed: int, tmp_path: Path
) -> None:
    problem = problems[pid]
    text = problem.make_dataset(seed)
    (tmp_path / "data").mkdir()
    (tmp_path / "data" / f"{pid}.fasta").write_text(text, encoding="utf-8")
    assert RSCRIPT is not None
    result = subprocess.run(
        [RSCRIPT, "--vanilla", str(SOLUTIONS / f"{pid}.R")],
        cwd=tmp_path,
        capture_output=True,
        text=True,
        timeout=120,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    verdict = problem.grade(result.stdout, text)
    assert verdict.status == "correct", (result.stdout, verdict)
