"""Deterministic answer graders.

Every grader takes the student's raw answer text and an ``Expected`` value and
returns a ``Verdict``. Messages shown to students never contain the expected
answer. Standard library only, so the skill runs anywhere Python 3.11+ does.
"""

from __future__ import annotations

import math
import re
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass, field
from typing import Literal

Status = Literal["correct", "partial", "incorrect", "invalid"]

DNA = frozenset("ACGT")
RNA = frozenset("ACGU")
# 20 standard amino acids plus '*' for a stop codon.
PROTEIN = frozenset("ACDEFGHIKLMNPQRSTVWY*")
ALPHABETS: Mapping[str, frozenset[str]] = {"dna": DNA, "rna": RNA, "protein": PROTEIN}


@dataclass(frozen=True)
class Diagnostic:
    """A recognised wrong answer and the feedback it earns."""

    code: str
    value: object
    message: str
    # Numeric graders only: overrides the problem's tolerance for this wrong answer,
    # e.g. a percentage reported to 2 decimals.
    tolerance: float | None = None


@dataclass(frozen=True)
class Expected:
    """The correct answer plus known wrong answers, computed from the problem's data."""

    value: object
    diagnostics: Sequence[Diagnostic] = ()


@dataclass(frozen=True)
class Verdict:
    status: Status
    code: str = ""
    message: str = ""
    details: Mapping[str, object] = field(default_factory=dict)


class AnswerFormatError(ValueError):
    """The answer could not be parsed. The message is safe to show the student."""


# --- parsing helpers -------------------------------------------------------


def parse_number(text: str) -> float:
    cleaned = text.strip().replace(",", "")
    if cleaned.endswith("%"):
        raise AnswerFormatError(
            "Please give a plain number without a % sign, in the format the problem asks for."
        )
    try:
        value = float(cleaned)
    except ValueError:
        raise AnswerFormatError(f"I couldn't read {text.strip()!r} as a number.") from None
    if not math.isfinite(value):
        raise AnswerFormatError("Please give a finite number.")
    return value


def normalize_sequence(text: str, alphabet: str) -> str:
    """Upper-case, drop whitespace and digits (as in numbered FASTA lines), check letters."""
    seq = re.sub(r"[\s\d]", "", text).upper()
    if not seq:
        raise AnswerFormatError("The answer is empty. Please paste the sequence.")
    allowed = ALPHABETS[alphabet]
    bad = sorted(set(seq) - allowed)
    if bad:
        raise AnswerFormatError(
            f"These characters aren't valid in a {alphabet.upper()} sequence: {', '.join(bad)}."
        )
    return seq


def parse_items(text: str) -> list[str]:
    """Split a list answer on commas, semicolons or whitespace."""
    items = [item for item in re.split(r"[,;\s]+", text.strip()) if item]
    if not items:
        raise AnswerFormatError("The answer is empty. Please list the items.")
    return items


_INTERVAL = re.compile(
    r"^\s*(?:(?:chr)?(?P<chrom>[0-9]{1,2}|X|Y|MT?)\s*:\s*)?"
    r"(?P<start>[0-9][0-9,._]*)\s*(?:-|–|to)\s*(?P<end>[0-9][0-9,._]*)\s*$",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class Interval:
    chrom: str | None
    start: float
    end: float

    @property
    def width(self) -> float:
        return self.end - self.start


def parse_interval(text: str) -> Interval:
    match = _INTERVAL.match(text)
    if not match:
        raise AnswerFormatError(
            "Please write the interval as chromosome:start-end, for example 7:30.5-34.2."
        )
    start = float(match["start"].replace(",", "").replace("_", ""))
    end = float(match["end"].replace(",", "").replace("_", ""))
    if end < start:
        raise AnswerFormatError("The end of the interval is smaller than the start.")
    chrom = match["chrom"].upper() if match["chrom"] else None
    return Interval(chrom, start, end)


# --- graders ---------------------------------------------------------------


def _match_diagnostic(expected: Expected, same: Callable[[object], bool]) -> Verdict | None:
    for diag in expected.diagnostics:
        if same(diag.value):
            return Verdict("incorrect", diag.code, diag.message)
    return None


def grade_numeric(answer: str, expected: Expected, *, tolerance: float) -> Verdict:
    value = parse_number(answer)

    def close(target: object, tol: float = tolerance) -> bool:
        return isinstance(target, int | float) and abs(value - float(target)) <= tol

    if close(expected.value):
        return Verdict("correct")
    for diag in expected.diagnostics:
        if close(diag.value, tolerance if diag.tolerance is None else diag.tolerance):
            return Verdict("incorrect", diag.code, diag.message)
    return Verdict("incorrect", "wrong_value", "That number isn't right yet.")


def grade_exact(answer: str, expected: Expected, *, case_sensitive: bool = False) -> Verdict:
    def norm(text: object) -> str:
        cleaned = " ".join(str(text).split())
        return cleaned if case_sensitive else cleaned.casefold()

    given = norm(answer)
    if not given:
        raise AnswerFormatError("The answer is empty.")
    if given == norm(expected.value):
        return Verdict("correct")
    diag = _match_diagnostic(expected, lambda target: norm(target) == given)
    if diag:
        return diag
    return Verdict("incorrect", "wrong_value", "That isn't the answer yet.")


def grade_sequence(answer: str, expected: Expected, *, alphabet: str) -> Verdict:
    given = normalize_sequence(answer, alphabet)
    target = str(expected.value)
    if given == target:
        return Verdict("correct")
    diag = _match_diagnostic(expected, lambda value: str(value) == given)
    if diag:
        return diag
    if len(given) != len(target):
        relation = "shorter" if len(given) < len(target) else "longer"
        return Verdict(
            "incorrect",
            "wrong_length",
            f"Your sequence is {relation} than expected.",
            {"length_given": len(given)},
        )
    mismatches = sum(a != b for a, b in zip(given, target, strict=True))
    first = next(i for i, (a, b) in enumerate(zip(given, target, strict=True)) if a != b)
    return Verdict(
        "incorrect",
        "mismatch",
        f"The length is right, but {mismatches} position(s) differ. "
        f"The first difference is at position {first + 1}.",
        {"mismatches": mismatches, "first_mismatch": first + 1},
    )


def grade_set(answer: str, expected: Expected, *, case_sensitive: bool = False) -> Verdict:
    def norm(item: object) -> str:
        return str(item) if case_sensitive else str(item).casefold()

    given = {norm(item) for item in parse_items(answer)}
    target_values = expected.value
    assert isinstance(target_values, Sequence | set | frozenset)
    target = {norm(item) for item in target_values}
    if given == target:
        return Verdict("correct")
    diag = _match_diagnostic(
        expected,
        lambda value: (
            isinstance(value, Sequence | set | frozenset) and {norm(v) for v in value} == given
        ),
    )
    if diag:
        return diag
    missing = len(target - given)
    extra = len(given - target)
    parts = []
    if missing:
        parts.append(f"{missing} item(s) are missing")
    if extra:
        parts.append(f"{extra} item(s) don't belong")
    status: Status = "partial" if given & target else "incorrect"
    return Verdict(
        status, "set_mismatch", "; ".join(parts) + ".", {"missing": missing, "extra": extra}
    )


def grade_choice(answer: str, expected: Expected, *, options: Sequence[str]) -> Verdict:
    given = answer.strip().strip("().").upper()
    valid = [option.upper() for option in options]
    if given not in valid:
        raise AnswerFormatError(f"Please answer with one of: {', '.join(valid)}.")
    if given == str(expected.value).upper():
        return Verdict("correct")
    diag = _match_diagnostic(expected, lambda value: str(value).upper() == given)
    if diag:
        return diag
    return Verdict("incorrect", "wrong_choice", "That's not the best choice.")


def grade_interval(answer: str, expected: Expected, *, tolerance: float) -> Verdict:
    """Correct when both ends are within ``tolerance`` of the expected ends."""
    given = parse_interval(answer)
    target = expected.value
    assert isinstance(target, Interval)
    if target.chrom is not None and given.chrom is None:
        raise AnswerFormatError("Please include the chromosome, for example 7:30.5-34.2.")
    if target.chrom is not None and given.chrom != target.chrom:
        diag = _match_diagnostic(
            expected, lambda value: isinstance(value, Interval) and value.chrom == given.chrom
        )
        return diag or Verdict(
            "incorrect", "wrong_chromosome", "That interval is on a different chromosome."
        )
    start_ok = abs(given.start - target.start) <= tolerance
    end_ok = abs(given.end - target.end) <= tolerance
    if start_ok and end_ok:
        return Verdict("correct")
    overlaps = given.start <= target.end and target.start <= given.end
    if not overlaps:
        return Verdict(
            "incorrect", "no_overlap", "Your interval doesn't overlap the region we're after."
        )
    if given.width < target.width - 2 * tolerance:
        hint = "Your interval is too narrow."
        code = "interval_too_narrow"
    elif given.width > target.width + 2 * tolerance:
        hint = "Your interval is too wide."
        code = "interval_too_wide"
    else:
        hint = "Your interval is about the right width but shifted."
        code = "interval_shifted"
    return Verdict("partial", code, hint)


def grade_ranking(answer: str, expected: Expected, *, top_k: int, ordered: bool = False) -> Verdict:
    """Check the first ``top_k`` items of the student's ranking."""
    given = [item.casefold() for item in parse_items(answer)]
    target_values = expected.value
    assert isinstance(target_values, Sequence)
    target = [str(item).casefold() for item in target_values][:top_k]
    if len(given) < top_k:
        raise AnswerFormatError(f"Please list at least {top_k} items, best first.")
    head = given[:top_k]
    if (head == target) if ordered else (set(head) == set(target)):
        return Verdict("correct")
    hits = len(set(head) & set(target))
    if hits:
        return Verdict(
            "partial",
            "ranking_partial",
            f"{hits} of your top {top_k} are right.",
            {"hits": hits},
        )
    return Verdict("incorrect", "ranking_wrong", f"None of your top {top_k} are right yet.")
