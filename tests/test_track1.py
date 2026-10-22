"""Track 1 graders: right answers pass, known mistakes get their code, others fail."""

from __future__ import annotations

import random

import pytest
from tutorlib import sequences as sq
from tutorlib.problems import Problem

SEEDS = list(range(1, 26))


def record(problem: Problem, seed: int) -> tuple[str, str]:
    text = problem.make_dataset(seed)
    (seq,) = sq.parse_fasta(text).values()
    return text, seq


@pytest.mark.parametrize("seed", SEEDS)
def test_datasets_are_reproducible(problems: dict[str, Problem], seed: int) -> None:
    for problem in problems.values():
        if problem.track == 1:
            assert problem.make_dataset(seed) == problem.make_dataset(seed)


def test_different_seeds_give_different_data(problems: dict[str, Problem]) -> None:
    for problem in problems.values():
        if problem.track == 1:
            assert problem.make_dataset(1) != problem.make_dataset(2)


class TestGcContent:
    @pytest.mark.parametrize("seed", SEEDS)
    def test_answers(self, problems: dict[str, Problem], seed: int) -> None:
        p = problems["t1-gc-content"]
        text, seq = record(p, seed)
        gc = (seq.count("G") + seq.count("C")) / len(seq)
        assert p.grade(f"{gc:.4f}", text).status == "correct"
        assert p.grade(f"{gc * 100:.2f}", text).code == "percent_not_fraction"
        assert p.grade(f"{1 - gc:.4f}", text).code == "at_content"
        assert p.grade(f"{seq.count('G') / len(seq):.4f}", text).code == "g_only"
        assert p.grade(f"{gc + 0.01:.4f}", text).status == "incorrect"
        assert p.grade("about half", text).status == "invalid"


class TestRevcomp:
    @pytest.mark.parametrize("seed", SEEDS)
    def test_answers(self, problems: dict[str, Problem], seed: int) -> None:
        p = problems["t1-revcomp"]
        text, seq = record(p, seed)
        comp = seq.translate(str.maketrans("ACGT", "TGCA"))
        assert p.grade(comp[::-1], text).status == "correct"
        assert p.grade(comp[::-1].lower(), text).status == "correct"
        assert p.grade(seq[::-1], text).code == "reverse_not_complement"
        assert p.grade(comp, text).code == "complement_not_reverse"
        assert p.grade(seq, text).code == "unchanged"
        assert p.grade(comp[::-1][:-1], text).code == "wrong_length"
        assert p.grade("ATGN", text).status == "invalid"

    def test_known_example(self) -> None:
        assert sq.reverse_complement("ATGCCGTA") == "TACGGCAT"


class TestTranslate:
    @pytest.mark.parametrize("seed", SEEDS)
    def test_answers(self, problems: dict[str, Problem], seed: int) -> None:
        p = problems["t1-translate"]
        text, seq = record(p, seed)
        protein = sq.translate(seq, to_stop=True)
        assert protein.startswith("M") and len(protein) == len(seq) // 3 - 1
        assert p.grade(protein, text).status == "correct"
        assert p.grade(protein + "*", text).code == "included_stop"
        frame2 = sq.translate(seq[1:], to_stop=True)
        if frame2 != protein:
            assert p.grade(frame2 or "M", text).status == "incorrect"
        assert p.grade(protein[:-1], text).code == "wrong_length"

    def test_codon_table_spot_checks(self) -> None:
        table = sq.CODON_TABLE
        assert len(table) == 64
        assert (table["ATG"], table["TGG"], table["TTT"], table["GGG"]) == ("M", "W", "F", "G")
        assert {c for c, a in table.items() if a == "*"} == {"TAA", "TAG", "TGA"}
        assert sum(a == "L" for a in table.values()) == 6

    def test_known_translation(self) -> None:
        assert sq.translate("ATGAAAGTTTGA", to_stop=True) == "MKV"


class TestReadingFrames:
    @pytest.mark.parametrize("seed", SEEDS)
    def test_answers(self, problems: dict[str, Problem], seed: int) -> None:
        p = problems["t1-reading-frames"]
        text, seq = record(p, seed)
        labels = ["+1", "+2", "+3", "-1", "-2", "-3"]
        rc = sq.reverse_complement(seq)
        prots = [sq.translate(seq[k:]) for k in range(3)] + [sq.translate(rc[k:]) for k in range(3)]
        open_frames = [lab for lab, pr in zip(labels, prots, strict=True) if "*" not in pr]
        assert p.grade(", ".join(reversed(open_frames)), text).status == "correct"
        fwd = [f for f in open_frames if f.startswith("+")]
        assert p.grade(", ".join(fwd), text).code == "forward_frames_only"
        closed = [lab for lab in labels if lab not in open_frames]
        assert p.grade(", ".join(closed), text).status == "incorrect"


class TestLongestOrf:
    @pytest.mark.parametrize("seed", SEEDS)
    def test_answers(self, problems: dict[str, Problem], seed: int) -> None:
        p = problems["t1-longest-orf"]
        text, seq = record(p, seed)
        best = max(sq.find_orfs(seq), key=lambda o: o.length_nt)
        assert p.grade(best.protein, text).status == "correct"
        assert p.grade(best.protein + "*", text).code == "included_stop"
        assert p.grade(best.protein[1:], text).status == "incorrect"

    def test_reverse_strand_diagnostic_appears(self, problems: dict[str, Problem]) -> None:
        p = problems["t1-longest-orf"]
        hits = 0
        for seed in range(1, 60):
            text, seq = record(p, seed)
            best = max(sq.find_orfs(seq), key=lambda o: o.length_nt)
            fwd = [o for o in sq.find_orfs(seq) if o.strand == "+"]
            if best.strand == "-" and fwd:
                longest_fwd = max(fwd, key=lambda o: o.length_nt)
                assert p.grade(longest_fwd.protein, text).code == "forward_strand_only"
                hits += 1
        assert hits > 0

    def test_orf_coordinates(self) -> None:
        #          1234567890123
        seq = "CCATGAAATAGCC"
        (orf,) = [o for o in sq.find_orfs(seq) if o.strand == "+"]
        assert (orf.start, orf.end, orf.protein) == (3, 11, "MK")
        rc_orfs = [o for o in sq.find_orfs(sq.reverse_complement(seq)) if o.strand == "-"]
        assert [(o.start, o.end) for o in rc_orfs] == [(3, 11)]


def test_random_wrong_answers_never_pass(problems: dict[str, Problem]) -> None:
    rng = random.Random(0)
    for problem in problems.values():
        if problem.track != 1:
            continue
        text = problem.make_dataset(7)
        for _ in range(50):
            guess = "".join(rng.choices("ACGT", k=rng.randint(5, 80)))
            if problem.grader["kind"] == "sequence" and problem.grader["alphabet"] == "protein":
                guess = "M" + "".join(rng.choices("ACDEFGHIKLMNPQRSTVWY", k=rng.randint(5, 60)))
            if problem.grader["kind"] == "numeric":
                guess = f"{rng.random():.4f}"
            if problem.grader["kind"] == "set":
                guess = ",".join(rng.sample(["+1", "+2", "+3", "-1", "-2", "-3"], 3))
            verdict = problem.grade(guess, text)
            expected = problem.expected(text).value
            if verdict.status == "correct":
                # Only acceptable if the random guess really is the answer.
                if isinstance(expected, list):
                    assert set(guess.split(",")) == set(expected)
                else:
                    assert guess == expected
