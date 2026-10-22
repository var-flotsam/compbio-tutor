# Reverse complement: worked explanation

**Method.** Complement each base, then reverse the order of the letters:

```r
paired <- chartr("ACGT", "TGCA", seq)
answer <- paste(rev(strsplit(paired, "")[[1]]), collapse = "")
```

Bioconductor's Biostrings package does the same thing in one call:
`reverseComplement(DNAString(seq))`.

**Why both steps.** Complementing gives the other strand's bases, but in the
3'-to-5' direction. Sequences are written 5' to 3', so you also reverse them. If
the given strand starts 5'-ATG, the other strand ends with CAT-3'.

**Common slips.** Reversing without complementing, or complementing without
reversing. Each of these gives a real-looking DNA sequence, which is why they are
easy to miss.

**The biology.** Genes sit on both strands. In the mouse genome, about half of all
genes are read from the "minus" strand. Genome browsers such as Ensembl and MGI
show a strand (+ or -) for every gene, and you will use that in track 2.
