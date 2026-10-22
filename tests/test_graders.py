"""Unit tests for the generic graders, including wrong and malformed answers."""

from __future__ import annotations

import pytest
from tutorlib import graders as g
from tutorlib.graders import AnswerFormatError, Diagnostic, Expected, Interval


class TestNumeric:
    exp = Expected(0.4821, (Diagnostic("percent_not_fraction", 48.21, "pct"),))

    def test_correct_within_tolerance(self) -> None:
        assert g.grade_numeric("0.48214", self.exp, tolerance=1e-4).status == "correct"

    def test_wrong(self) -> None:
        v = g.grade_numeric("0.5", self.exp, tolerance=1e-4)
        assert (v.status, v.code) == ("incorrect", "wrong_value")
        assert "0.48" not in v.message

    def test_diagnostic(self) -> None:
        v = g.grade_numeric("48.21", self.exp, tolerance=1e-4)
        assert (v.status, v.code) == ("incorrect", "percent_not_fraction")

    @pytest.mark.parametrize("bad", ["", "abc", "48%", "nan", "inf"])
    def test_invalid(self, bad: str) -> None:
        with pytest.raises(AnswerFormatError):
            g.grade_numeric(bad, self.exp, tolerance=1e-4)


class TestExact:
    def test_case_and_space_insensitive(self) -> None:
        exp = Expected("Chromosome 16")
        assert g.grade_exact("  chromosome   16 ", exp).status == "correct"

    def test_case_sensitive(self) -> None:
        exp = Expected("Hunk")
        assert g.grade_exact("HUNK", exp, case_sensitive=True).status == "incorrect"

    def test_diagnostic(self) -> None:
        exp = Expected("Hunk", (Diagnostic("human_symbol", "HUNK-human", "m"),))
        assert g.grade_exact("hunk-human", exp).code == "human_symbol"

    def test_empty(self) -> None:
        with pytest.raises(AnswerFormatError):
            g.grade_exact("   ", Expected("x"))


class TestSequence:
    exp = Expected("ATGCC", (Diagnostic("reverse_not_complement", "CCGTA", "rev"),))

    def test_correct_with_whitespace_and_case(self) -> None:
        assert g.grade_sequence("atg\n cc", self.exp, alphabet="dna").status == "correct"

    def test_numbered_fasta_lines(self) -> None:
        assert g.grade_sequence("1 ATG\n4 CC", self.exp, alphabet="dna").status == "correct"

    def test_diagnostic(self) -> None:
        assert g.grade_sequence("CCGTA", self.exp, alphabet="dna").code == "reverse_not_complement"

    def test_wrong_length(self) -> None:
        v = g.grade_sequence("ATGC", self.exp, alphabet="dna")
        assert (v.status, v.code) == ("incorrect", "wrong_length")

    def test_mismatch_reports_position_not_answer(self) -> None:
        v = g.grade_sequence("ATGCA", self.exp, alphabet="dna")
        assert v.code == "mismatch"
        assert v.details["first_mismatch"] == 5
        assert "ATGCC" not in v.message

    def test_bad_letters(self) -> None:
        with pytest.raises(AnswerFormatError, match="X"):
            g.grade_sequence("ATGXC", self.exp, alphabet="dna")

    def test_protein_alphabet(self) -> None:
        exp = Expected("MKV")
        assert g.grade_sequence("mkv", exp, alphabet="protein").status == "correct"
        with pytest.raises(AnswerFormatError):
            g.grade_sequence("MKB", exp, alphabet="protein")


class TestSet:
    exp = Expected(["+1", "-2"])

    def test_order_free(self) -> None:
        assert g.grade_set("-2, +1", self.exp).status == "correct"

    def test_partial(self) -> None:
        v = g.grade_set("+1", self.exp)
        assert (v.status, v.details["missing"], v.details["extra"]) == ("partial", 1, 0)

    def test_disjoint(self) -> None:
        assert g.grade_set("+3", self.exp).status == "incorrect"

    def test_diagnostic(self) -> None:
        exp = Expected(["+1", "-2"], (Diagnostic("forward_only", ["+1"], "m"),))
        assert g.grade_set("+1", exp).code == "forward_only"

    def test_empty(self) -> None:
        with pytest.raises(AnswerFormatError):
            g.grade_set(" , ", self.exp)


class TestChoice:
    def test_choice(self) -> None:
        exp = Expected("B")
        assert g.grade_choice("(b)", exp, options="ABCD").status == "correct"
        assert g.grade_choice("A", exp, options="ABCD").status == "incorrect"
        with pytest.raises(AnswerFormatError):
            g.grade_choice("E", exp, options="ABCD")


class TestInterval:
    exp = Expected(Interval("16", 88.0, 92.0))

    def test_correct(self) -> None:
        assert g.grade_interval("chr16:88.2-91.9", self.exp, tolerance=0.5).status == "correct"

    def test_wrong_chromosome(self) -> None:
        assert g.grade_interval("1:88-92", self.exp, tolerance=0.5).code == "wrong_chromosome"

    def test_too_narrow(self) -> None:
        v = g.grade_interval("16:89.5-90.5", self.exp, tolerance=0.5)
        assert (v.status, v.code) == ("partial", "interval_too_narrow")

    def test_too_wide(self) -> None:
        assert g.grade_interval("16:80-100", self.exp, tolerance=0.5).code == "interval_too_wide"

    def test_shifted(self) -> None:
        assert g.grade_interval("16:89-93", self.exp, tolerance=0.5).code == "interval_shifted"

    def test_no_overlap(self) -> None:
        assert g.grade_interval("16:10-20", self.exp, tolerance=0.5).code == "no_overlap"

    @pytest.mark.parametrize("bad", ["16", "16:92-88", "sixteen:1-2", "88-92"])
    def test_invalid(self, bad: str) -> None:
        with pytest.raises(AnswerFormatError):
            g.grade_interval(bad, self.exp, tolerance=0.5)


class TestRanking:
    exp = Expected(["Hunk", "Zfp148", "Ptpn18", "Other"])

    def test_unordered_top_k(self) -> None:
        assert g.grade_ranking("zfp148, hunk, x", self.exp, top_k=2).status == "correct"

    def test_ordered(self) -> None:
        assert g.grade_ranking("zfp148, hunk", self.exp, top_k=2, ordered=True).status == "partial"

    def test_none_right(self) -> None:
        assert g.grade_ranking("a, b", self.exp, top_k=2).status == "incorrect"

    def test_too_short(self) -> None:
        with pytest.raises(AnswerFormatError):
            g.grade_ranking("hunk", self.exp, top_k=2)
