"""Per-student progress, stored as JSON in the student's working folder."""

from __future__ import annotations

import json
import os
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

DEFAULT_SEED = 1


def state_dir() -> Path:
    """``$COMPBIO_TUTOR_HOME`` if set, else ``.compbio-tutor`` in the current folder."""
    return Path(os.environ.get("COMPBIO_TUTOR_HOME", ".compbio-tutor"))


@dataclass
class ProblemProgress:
    seed: int = DEFAULT_SEED
    attempts: int = 0
    hints_used: int = 0
    solved: bool = False
    revealed: bool = False
    last_code: str = ""


@dataclass
class Progress:
    problems: dict[str, ProblemProgress] = field(default_factory=dict)

    def get(self, pid: str) -> ProblemProgress:
        return self.problems.setdefault(pid, ProblemProgress())

    @classmethod
    def load(cls) -> Progress:
        path = state_dir() / "progress.json"
        if not path.is_file():
            return cls()
        try:
            raw: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
            return cls({pid: ProblemProgress(**p) for pid, p in raw["problems"].items()})
        except (ValueError, KeyError, TypeError):
            # A damaged file shouldn't block a lesson; keep a copy and start fresh.
            path.replace(path.with_suffix(".json.bad"))
            return cls()

    def save(self) -> None:
        folder = state_dir()
        folder.mkdir(parents=True, exist_ok=True)
        tmp = folder / "progress.json.tmp"
        tmp.write_text(json.dumps(asdict(self), indent=2), encoding="utf-8")
        tmp.replace(folder / "progress.json")


def work_path(pid: str) -> Path:
    """The student's own copy of a problem's starter code."""
    return state_dir().parent / "work" / f"{pid}.R"


def data_path(pid: str) -> Path:
    """Where the student's dataset for a problem is written."""
    return state_dir().parent / "data" / f"{pid}.fasta"
