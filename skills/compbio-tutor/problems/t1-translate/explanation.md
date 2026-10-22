# Translation: worked explanation

**Method.** Read codons from the first base, look each one up in the standard
code, and stop at the first stop codon:

```r
starts <- seq(1, nchar(seq) - 2, by = 3)
codons <- substring(seq, starts, starts + 2)
aa <- GENETIC_CODE[codons]
protein <- paste(aa[seq_len(which(aa == "*")[1] - 1)], collapse = "")
```

Biostrings can also do it in one call: `translate(DNAString(seq))` returns the
protein with a trailing `*` for the stop.

**Checking yourself.** The sequence is a multiple of 3 bases long. The protein
has (length / 3) - 1 amino acids, because the last codon is the stop. It should
start with M.

**Common slips.** Starting one or two bases late (a different reading frame gives
a completely different protein), or adding a `*` for the stop codon.

**The biology.** The genetic code is almost the same in every living thing, which
is why a mouse gene can be read with the same table as a human or bacterial gene.
Real genes also contain introns, which are cut out of the RNA before translation.
Your sequence was a ready-made coding sequence with no introns.
