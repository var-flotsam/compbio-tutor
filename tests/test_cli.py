"""The CLI enforces the teaching rules: one hint at a time, explanations gated."""

from __future__ import annotations

import json
from pathlib import Path

import pytest
import tutor
from tutorlib import sequences as sq


def run(capsys: pytest.CaptureFixture[str], *args: str) -> str:
    tutor.main(list(args))
    return capsys.readouterr().out


def test_show_writes_dataset(state_home: Path, capsys: pytest.CaptureFixture[str]) -> None:
    out = run(capsys, "show", "t1-gc-content")
    assert "Learning goal" in out and "Answer format" in out
    assert (state_home.parent / "data" / "t1-gc-content.fasta").is_file()


def test_hints_one_at_a_time(state_home: Path, capsys: pytest.CaptureFixture[str]) -> None:
    outs = [run(capsys, "hint", "t1-revcomp") for _ in range(4)]
    assert outs[0].startswith("Hint 1 of 3")
    assert outs[2].startswith("Hint 3 of 3")
    assert outs[3].startswith("All 3 hints are used")


def test_explain_is_gated(state_home: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert run(capsys, "explain", "t1-revcomp").startswith("Not yet")
    assert "hint(s) are left" in run(capsys, "explain", "t1-revcomp", "--student-asked")
    for _ in range(3):
        run(capsys, "hint", "t1-revcomp")
    assert run(capsys, "explain", "t1-revcomp").startswith("Not yet")
    out = run(capsys, "explain", "t1-revcomp", "--student-asked")
    assert out.startswith("# Reverse complement")
    assert "answer shown" in run(capsys, "progress")


def test_grade_then_explain(state_home: Path, capsys: pytest.CaptureFixture[str]) -> None:
    run(capsys, "show", "t1-revcomp")
    data = (state_home.parent / "data" / "t1-revcomp.fasta").read_text()
    (seq,) = sq.parse_fasta(data).values()
    wrong = json.loads(run(capsys, "grade", "t1-revcomp", "--answer", seq[::-1]))
    assert wrong["status"] == "incorrect" and wrong["code"] == "reverse_not_complement"
    assert sq.reverse_complement(seq) not in json.dumps(wrong)
    right = json.loads(run(capsys, "grade", "t1-revcomp", "--answer", sq.reverse_complement(seq)))
    assert right["status"] == "correct" and right["attempts"] == 2
    assert run(capsys, "explain", "t1-revcomp").startswith("# Reverse complement")


def test_editing_data_file_does_not_change_key(
    state_home: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    run(capsys, "show", "t1-revcomp")
    path = state_home.parent / "data" / "t1-revcomp.fasta"
    path.write_text(">fake\nAAAA\n")
    out = json.loads(run(capsys, "grade", "t1-revcomp", "--answer", "TTTT"))
    assert out["status"] == "incorrect"


def test_invalid_answer_does_not_count(
    state_home: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    out = json.loads(run(capsys, "grade", "t1-gc-content", "--answer", "lots"))
    assert out["status"] == "invalid" and out["attempts"] == 0


def test_new_seed_resets_progress(state_home: Path, capsys: pytest.CaptureFixture[str]) -> None:
    run(capsys, "hint", "t1-gc-content")
    run(capsys, "dataset", "t1-gc-content", "--seed", "99")
    assert "hints=0" in run(capsys, "progress")


def test_answer_file(state_home: Path, tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    answer = tmp_path / "answer.txt"
    answer.write_text("0.5\n")
    out = json.loads(run(capsys, "grade", "t1-gc-content", "--answer-file", str(answer)))
    assert out["status"] in {"incorrect", "correct"}


def test_unknown_problem(state_home: Path) -> None:
    with pytest.raises(SystemExit, match="Unknown problem"):
        tutor.main(["show", "t9-nope"])


def test_corrupt_progress_file_recovers(
    state_home: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    state_home.mkdir(parents=True)
    (state_home / "progress.json").write_text("{not json")
    assert run(capsys, "progress") == "No problems started yet.\n"
    assert (state_home / "progress.json.bad").is_file()


def test_show_copies_starter_once(state_home: Path, capsys: pytest.CaptureFixture[str]) -> None:
    out = run(capsys, "show", "t1-gc-content")
    work = state_home.parent / "work" / "t1-gc-content.R"
    assert work.is_file() and "Rscript" in out
    work.write_text("# my edits\n")
    run(capsys, "show", "t1-gc-content")
    assert work.read_text() == "# my edits\n"
