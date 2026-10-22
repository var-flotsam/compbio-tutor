from __future__ import annotations

from pathlib import Path

import pytest
from tutorlib.problems import Problem, load_all


@pytest.fixture(scope="session")
def problems() -> dict[str, Problem]:
    return load_all()


@pytest.fixture
def state_home(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    home = tmp_path / ".compbio-tutor"
    monkeypatch.setenv("COMPBIO_TUTOR_HOME", str(home))
    monkeypatch.chdir(tmp_path)
    return home
