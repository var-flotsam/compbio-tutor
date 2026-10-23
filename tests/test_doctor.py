"""The setup doctor gives one correct next step for each broken setup."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import pytest
from tutorlib import doctor


def test_folder_check(tmp_path: Path) -> None:
    home = tmp_path / "home"
    course = home / "Documents" / "compbio"
    course.mkdir(parents=True)
    assert doctor.folder_check(course, home).ok
    bad = doctor.folder_check(home, home)
    assert not bad.ok and "compbio" in bad.fix and "cd" in bad.fix
    inside = home / ".claude" / "plugins" / "cache"
    inside.mkdir(parents=True)
    assert not doctor.folder_check(inside, home).ok


def test_windows_path_hint_uses_git_bash_paths() -> None:
    hint = doctor.path_hint("windows", r"C:\Program Files\R\R-4.4.1\bin\Rscript.exe")
    assert "/c/Program Files/R/R-4.4.1/bin" in hint and "~/.bashrc" in hint


def test_windows_candidates_prefer_newest(monkeypatch: pytest.MonkeyPatch) -> None:
    paths = {
        "a": r"C:\Program Files\R\R-4.3.3\bin\Rscript.exe",
        "b": r"C:\Program Files\R\R-4.10.0\bin\Rscript.exe",
        "c": r"C:\Program Files\R\R-4.4.1\bin\Rscript.exe",
    }
    monkeypatch.setattr("glob.glob", lambda pattern: list(paths.values()))
    found = doctor.candidate_rscripts("windows")
    assert found[0].endswith(r"R-4.10.0\bin\Rscript.exe")


def test_missing_r_gives_install_step(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.setattr(doctor, "find_rscript", lambda osname: (None, False))
    for osname, words in [("windows", "winget"), ("macos", ".pkg"), ("linux", "apt")]:
        monkeypatch.setattr(doctor, "os_name", lambda o=osname: o)
        report = doctor.run(cwd=tmp_path)
        assert not report.ok
        text = report.render()
        assert "Next step (R)" in text and words in text


def test_old_r(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.setattr(doctor, "find_rscript", lambda osname: ("/x/Rscript", True))
    monkeypatch.setattr(doctor, "r_version", lambda rscript: (4, 1, 2))
    text = doctor.run(cwd=tmp_path).render()
    assert "4.1.2 is too old" in text


def test_r_off_path(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.setattr(doctor, "os_name", lambda: "windows")
    rscript = r"C:\Program Files\R\R-4.4.1\bin\Rscript.exe"
    monkeypatch.setattr(doctor, "find_rscript", lambda osname: (rscript, False))
    monkeypatch.setattr(doctor, "r_version", lambda r: (4, 4, 1))
    monkeypatch.setattr(
        doctor, "packages_check", lambda r, install: doctor.Check("R packages", True, "ok")
    )
    text = doctor.run(cwd=tmp_path).render()
    assert "Next step (R on PATH)" in text


def test_missing_packages_parsed(monkeypatch: pytest.MonkeyPatch) -> None:
    fake = subprocess.CompletedProcess(
        [], 1, stdout="[ok] R 4.4.1\n[!] Biostrings is missing (needed for Track 1).\n", stderr=""
    )
    monkeypatch.setattr("subprocess.run", lambda *a, **k: fake)
    check = doctor.packages_check("Rscript", install=False)
    assert not check.ok and "Biostrings" in check.detail and "--install-packages" in check.fix


@pytest.mark.skipif(shutil.which("Rscript") is None, reason="Rscript not installed")
def test_real_machine_all_ok(tmp_path: Path) -> None:
    report = doctor.run(cwd=tmp_path)
    assert report.ok, report.render()
