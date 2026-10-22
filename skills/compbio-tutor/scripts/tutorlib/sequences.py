"""Reference sequence functions used to compute expected answers."""

from __future__ import annotations

import random
from dataclasses import dataclass

_COMPLEMENT = str.maketrans("ACGT", "TGCA")

_BASES = "TCAG"
_AMINO = "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG"
# Standard genetic code (NCBI translation table 1), built from the usual TCAG ordering.
CODON_TABLE: dict[str, str] = {
    a + b + c: _AMINO[16 * i + 4 * j + k]
    for i, a in enumerate(_BASES)
    for j, b in enumerate(_BASES)
    for k, c in enumerate(_BASES)
}
START = "ATG"
STOPS = frozenset({"TAA", "TAG", "TGA"})


def gc_fraction(seq: str) -> float:
    if not seq:
        raise ValueError("empty sequence")
    return (seq.count("G") + seq.count("C")) / len(seq)


def complement(seq: str) -> str:
    return seq.translate(_COMPLEMENT)


def reverse_complement(seq: str) -> str:
    return complement(seq)[::-1]


def transcribe(seq: str) -> str:
    return seq.replace("T", "U")


def translate(seq: str, *, to_stop: bool = False) -> str:
    """Translate DNA (or RNA) codon by codon; a trailing partial codon is ignored."""
    dna = seq.replace("U", "T")
    protein = []
    for i in range(0, len(dna) - 2, 3):
        amino = CODON_TABLE[dna[i : i + 3]]
        if to_stop and amino == "*":
            break
        protein.append(amino)
    return "".join(protein)


def six_frame_translations(seq: str) -> list[str]:
    """Frames +1, +2, +3 on the given strand, then -1, -2, -3 on the reverse complement."""
    rc = reverse_complement(seq)
    return [translate(seq[i:]) for i in range(3)] + [translate(rc[i:]) for i in range(3)]


@dataclass(frozen=True)
class Orf:
    strand: str  # "+" or "-"
    start: int  # 1-based position of the A of ATG, on the given strand's coordinates
    end: int  # 1-based position of the last base of the stop codon
    protein: str  # without the stop

    @property
    def length_nt(self) -> int:
        return self.end - self.start + 1


def find_orfs(seq: str, *, min_codons: int = 1) -> list[Orf]:
    """ATG...stop ORFs on both strands. Coordinates refer to the forward strand.

    Nested ORFs (an ATG inside another ORF in the same frame) are included, as
    each ATG can start a protein.
    """
    orfs: list[Orf] = []
    n = len(seq)
    for strand, s in (("+", seq), ("-", reverse_complement(seq))):
        for i in range(n - 2):
            if s[i : i + 3] != START:
                continue
            for j in range(i, n - 2, 3):
                if s[j : j + 3] in STOPS:
                    protein = translate(s[i:j])
                    if len(protein) >= min_codons:
                        if strand == "+":
                            start, end = i + 1, j + 3
                        else:
                            start, end = n - (j + 3) + 1, n - i
                        orfs.append(Orf(strand, start, end, protein))
                    break
    return orfs


def random_dna(rng: random.Random, length: int, gc: float = 0.5) -> str:
    weights = [(1 - gc) / 2, gc / 2, gc / 2, (1 - gc) / 2]
    return "".join(rng.choices("ACGT", weights=weights, k=length))


def to_fasta(name: str, seq: str, width: int = 60) -> str:
    lines = [f">{name}"] + [seq[i : i + width] for i in range(0, len(seq), width)]
    return "\n".join(lines) + "\n"


def parse_fasta(text: str) -> dict[str, str]:
    records: dict[str, str] = {}
    name: str | None = None
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith(">"):
            name = line[1:].split()[0]
            records[name] = ""
        elif name is None:
            raise ValueError("FASTA text must start with a '>' header line")
        else:
            records[name] += line.upper()
    return records
