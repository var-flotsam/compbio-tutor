"""Load and validate problem folders (``problems/<id>/problem.toml``)."""

from __future__ import annotations

import tomllib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, TypeVar

from tutorlib import answers, graders
from tutorlib.graders import AnswerFormatError, Expected, Verdict

SKILL_ROOT = Path(__file__).resolve().parents[2]
PROBLEMS_DIR = SKILL_ROOT / "problems"
MIN_HINTS = 3
GRADER_KINDS = frozenset({"numeric", "exact", "sequence", "set", "choice", "interval", "ranking"})


T = TypeVar("T")


class ProblemError(Exception):
    """A problem file is malformed. Meant for authors, not students."""


@dataclass(frozen=True)
class Problem:
    id: str
    track: int
    title: str
    goal: str
    background: str
    prompt: str
    answer_format: str
    dataset: str
    answer: str
    grader: dict[str, Any]
    hints: list[str]
    starter: str = ""
    folder: Path = field(default=PROBLEMS_DIR)

    @property
    def explanation_path(self) -> Path:
        return self.folder / "explanation.md"

    def make_dataset(self, seed: int) -> str:
        return answers.DATASETS[self.dataset](seed)

    def expected(self, data_text: str) -> Expected:
        return answers.ANSWERS[self.answer](data_text)

    def grade(self, answer_text: str, data_text: str) -> Verdict:
        expected = self.expected(data_text)
        options = {k: v for k, v in self.grader.items() if k != "kind"}
        kind = self.grader["kind"]
        try:
            match kind:
                case "numeric":
                    return graders.grade_numeric(answer_text, expected, **options)
                case "exact":
                    return graders.grade_exact(answer_text, expected, **options)
                case "sequence":
                    return graders.grade_sequence(answer_text, expected, **options)
                case "set":
                    return graders.grade_set(answer_text, expected, **options)
                case "choice":
                    return graders.grade_choice(answer_text, expected, **options)
                case "interval":
                    return graders.grade_interval(answer_text, expected, **options)
                case "ranking":
                    return graders.grade_ranking(answer_text, expected, **options)
                case _:
                    raise ProblemError(f"{self.id}: unknown grader kind {kind!r}")
        except AnswerFormatError as err:
            return Verdict("invalid", "format", str(err))


def _require(data: dict[str, Any], key: str, kind: type[T], pid: str) -> T:
    if key not in data:
        raise ProblemError(f"{pid}: missing required field {key!r}")
    value = data[key]
    if not isinstance(value, kind):
        raise ProblemError(f"{pid}: field {key!r} should be {kind.__name__}")
    return value


def load_problem(folder: Path) -> Problem:
    path = folder / "problem.toml"
    try:
        data = tomllib.loads(path.read_text(encoding="utf-8"))
    except (OSError, tomllib.TOMLDecodeError) as err:
        raise ProblemError(f"{path}: {err}") from err
    pid = _require(data, "id", str, folder.name)
    if pid != folder.name:
        raise ProblemError(f"{pid}: id must match folder name {folder.name!r}")
    hints = [_require(h, "text", str, pid) for h in data.get("hints", [])]
    if len(hints) < MIN_HINTS:
        raise ProblemError(f"{pid}: needs at least {MIN_HINTS} hints, has {len(hints)}")
    grader = _require(data, "grader", dict, pid)
    if grader.get("kind") not in GRADER_KINDS:
        raise ProblemError(f"{pid}: grader.kind must be one of {sorted(GRADER_KINDS)}")
    dataset = _require(data, "dataset", str, pid)
    answer = _require(data, "answer", str, pid)
    if dataset not in answers.DATASETS:
        raise ProblemError(f"{pid}: unknown dataset builder {dataset!r}")
    if answer not in answers.ANSWERS:
        raise ProblemError(f"{pid}: unknown answer function {answer!r}")
    if not (folder / "explanation.md").is_file():
        raise ProblemError(f"{pid}: explanation.md is missing")
    return Problem(
        id=pid,
        track=_require(data, "track", int, pid),
        title=_require(data, "title", str, pid),
        goal=_require(data, "goal", str, pid),
        background=_require(data, "background", str, pid).strip(),
        prompt=_require(data, "prompt", str, pid).strip(),
        answer_format=_require(data, "answer_format", str, pid),
        dataset=dataset,
        answer=answer,
        grader=grader,
        hints=hints,
        starter=data.get("starter", ""),
        folder=folder,
    )


def load_all(root: Path = PROBLEMS_DIR) -> dict[str, Problem]:
    problems = {}
    for folder in sorted(p for p in root.iterdir() if (p / "problem.toml").is_file()):
        problem = load_problem(folder)
        problems[problem.id] = problem
    return problems
