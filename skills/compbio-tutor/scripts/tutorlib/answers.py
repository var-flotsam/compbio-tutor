"""Per-problem datasets and expected answers.

Each problem names a dataset builder and an answer function in its
``problem.toml``. Builders turn a seed into the student's data file text;
answer functions turn that same text into an ``Expected`` value, including
the wrong answers that common misconceptions produce.
"""

from __future__ import annotations

import random
from collections.abc import Callable

from tutorlib import sequences as sq
from tutorlib.graders import Diagnostic, Expected

DatasetBuilder = Callable[[int], str]
AnswerFn = Callable[[str], Expected]

DATASETS: dict[str, DatasetBuilder] = {}
ANSWERS: dict[str, AnswerFn] = {}


def dataset(name: str) -> Callable[[DatasetBuilder], DatasetBuilder]:
    def register(fn: DatasetBuilder) -> DatasetBuilder:
        DATASETS[name] = fn
        return fn

    return register


def answer(name: str) -> Callable[[AnswerFn], AnswerFn]:
    def register(fn: AnswerFn) -> AnswerFn:
        ANSWERS[name] = fn
        return fn

    return register


def _only_record(text: str) -> str:
    records = sq.parse_fasta(text)
    if len(records) != 1:
        raise ValueError(f"expected one FASTA record, found {len(records)}")
    return next(iter(records.values()))


# --- track 1: sequences ----------------------------------------------------


@dataset("t1.gc_dna")
def gc_dna(seed: int) -> str:
    rng = random.Random(seed)
    # GC between 35% and 65% spans typical mammalian regions.
    seq = sq.random_dna(rng, rng.randint(400, 600), gc=rng.uniform(0.35, 0.65))
    return sq.to_fasta(f"sample_{seed}", seq)


@answer("t1.gc_content")
def gc_content(text: str) -> Expected:
    seq = _only_record(text)
    gc = sq.gc_fraction(seq)
    return Expected(
        round(gc, 4),
        (
            Diagnostic(
                "percent_not_fraction",
                round(gc * 100, 4),
                "Your number looks like a percentage. The question asks for a fraction "
                "between 0 and 1.",
                tolerance=0.01,
            ),
            Diagnostic(
                "at_content",
                round(1 - gc, 4),
                "That looks like the share of A and T. Which letters does the question ask about?",
            ),
            Diagnostic(
                "g_only",
                round(seq.count("G") / len(seq), 4),
                "That matches counting only one of the two letters.",
            ),
            Diagnostic(
                "c_only",
                round(seq.count("C") / len(seq), 4),
                "That matches counting only one of the two letters.",
            ),
        ),
    )


@dataset("t1.short_dna")
def short_dna(seed: int) -> str:
    rng = random.Random(seed)
    return sq.to_fasta(f"fragment_{seed}", sq.random_dna(rng, rng.randint(60, 90)))


@answer("t1.reverse_complement")
def reverse_complement(text: str) -> Expected:
    seq = _only_record(text)
    return Expected(
        sq.reverse_complement(seq),
        (
            Diagnostic(
                "reverse_not_complement",
                seq[::-1],
                "You reversed the sequence. On the other strand, each base also pairs "
                "with a different base.",
            ),
            Diagnostic(
                "complement_not_reverse",
                sq.complement(seq),
                "You paired each base correctly. Now think about which end of the "
                "other strand is its 5' end.",
            ),
            Diagnostic(
                "unchanged",
                seq,
                "That's the sequence you started with.",
            ),
        ),
    )


@dataset("t1.coding_dna")
def coding_dna(seed: int) -> str:
    rng = random.Random(seed)
    sense = [c for c, a in sq.CODON_TABLE.items() if a != "*" and c != sq.START]
    codons = [sq.START] + rng.choices(sense, k=rng.randint(15, 25))
    codons.append(rng.choice(sorted(sq.STOPS)))
    return sq.to_fasta(f"cds_{seed}", "".join(codons))


@answer("t1.translate")
def translate(text: str) -> Expected:
    seq = _only_record(text)
    protein = sq.translate(seq, to_stop=True)
    return Expected(
        protein,
        (
            Diagnostic(
                "included_stop",
                protein + "*",
                "Nearly there. A stop codon ends the protein but doesn't add an amino acid.",
            ),
            Diagnostic(
                "wrong_frame_2",
                sq.translate(seq[1:], to_stop=True),
                "That looks like a translation starting one base late. Where does "
                "translation start?",
            ),
            Diagnostic(
                "wrong_frame_3",
                sq.translate(seq[2:], to_stop=True),
                "That looks like a translation starting two bases late. Where does "
                "translation start?",
            ),
            Diagnostic(
                "translated_revcomp",
                sq.translate(sq.reverse_complement(seq), to_stop=True),
                "That looks like a translation of the other strand.",
            ),
        ),
    )


@dataset("t1.orf_dna")
def orf_dna(seed: int) -> str:
    """Random DNA with one planted ORF, on a random strand, that is clearly the longest."""
    rng = random.Random(seed)
    sense = [c for c, a in sq.CODON_TABLE.items() if a != "*"]
    while True:
        orf = sq.START + "".join(rng.choices(sense, k=rng.randint(40, 60))) + "TAA"
        if rng.random() < 0.5:
            orf = sq.reverse_complement(orf)
        left = sq.random_dna(rng, rng.randint(30, 60))
        right = sq.random_dna(rng, rng.randint(30, 60))
        seq = left + orf + right
        orfs = sorted(sq.find_orfs(seq), key=lambda o: o.length_nt, reverse=True)
        # Keep only datasets whose longest ORF is unique, so there is one right answer.
        if len(orfs) >= 2 and orfs[0].length_nt > orfs[1].length_nt + 30:
            return sq.to_fasta(f"contig_{seed}", seq)
        if len(orfs) == 1:
            return sq.to_fasta(f"contig_{seed}", seq)


@answer("t1.longest_orf_protein")
def longest_orf_protein(text: str) -> Expected:
    seq = _only_record(text)
    orfs = sorted(sq.find_orfs(seq), key=lambda o: o.length_nt, reverse=True)
    best = orfs[0]
    forward = [o for o in orfs if o.strand == "+"]
    diagnostics = []
    if best.strand == "-" and forward:
        diagnostics.append(
            Diagnostic(
                "forward_strand_only",
                forward[0].protein,
                "That's the longest ORF on the strand you were given. Did you check the "
                "other strand too?",
            )
        )
    diagnostics.append(
        Diagnostic(
            "included_stop",
            best.protein + "*",
            "Nearly there. Leave out the stop codon's '*'.",
        )
    )
    return Expected(best.protein, tuple(diagnostics))


@answer("t1.reading_frames")
def reading_frames(text: str) -> Expected:
    """Which of the six frames (+1..+3, -1..-3) translate with no stop codon at all?"""
    seq = _only_record(text)
    labels = ["+1", "+2", "+3", "-1", "-2", "-3"]
    frames = sq.six_frame_translations(seq)
    open_frames = [label for label, prot in zip(labels, frames, strict=True) if "*" not in prot]
    forward_only = [label for label in open_frames if label.startswith("+")]
    diagnostics: tuple[Diagnostic, ...] = ()
    if forward_only != open_frames:
        diagnostics = (
            Diagnostic(
                "forward_frames_only",
                forward_only,
                "You checked the three frames on the given strand. There are three more.",
            ),
        )
    return Expected(open_frames, diagnostics)


@dataset("t1.frames_dna")
def frames_dna(seed: int) -> str:
    """Short DNA where at least one frame on each strand is free of stop codons."""
    rng = random.Random(seed)
    while True:
        seq = sq.random_dna(rng, 45)
        frames = sq.six_frame_translations(seq)
        fwd = [f for f in frames[:3] if "*" not in f]
        rev = [f for f in frames[3:] if "*" not in f]
        if fwd and rev and len(fwd) + len(rev) < 6:
            return sq.to_fasta(f"read_{seed}", seq)
