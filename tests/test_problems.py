"""Checks on the problem files themselves."""

from __future__ import annotations

import re

from tutorlib.problems import MIN_HINTS, Problem


def test_ids_are_unique_and_tracked(problems: dict[str, Problem]) -> None:
    assert len(problems) >= 5
    for pid, problem in problems.items():
        assert re.fullmatch(r"t[1-3]-[a-z0-9-]+", pid)
        assert pid.startswith(f"t{problem.track}-")


def test_hint_ladders(problems: dict[str, Problem]) -> None:
    for problem in problems.values():
        assert len(problem.hints) >= MIN_HINTS
        assert len(set(problem.hints)) == len(problem.hints)


def test_no_text_contains_the_answer(problems: dict[str, Problem]) -> None:
    """Hints, background and prompt must not contain any seed's expected answer."""
    for problem in problems.values():
        shown = " ".join([problem.background, problem.prompt, *problem.hints]).upper()
        for seed in range(1, 21):
            value = problem.expected(problem.make_dataset(seed)).value
            items = value if isinstance(value, list) else [value]
            for item in items:
                text = str(item).upper()
                if len(text) >= 6:
                    assert text not in shown, f"{problem.id} leaks its answer for seed {seed}"


def test_explanations_and_starters_exist(problems: dict[str, Problem]) -> None:
    for problem in problems.values():
        assert problem.explanation_path.read_text(encoding="utf-8").startswith("# ")
        if problem.starter:
            starter = (problem.folder / problem.starter).read_text(encoding="utf-8")
            assert f"data/{problem.id}.fasta" in starter
