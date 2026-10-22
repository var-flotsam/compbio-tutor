# Longest ORF: worked explanation

**Method.** From every ATG, step 3 bases at a time until the first stop codon.
Do this on the given strand and on its reverse complement, keep the longest ORF,
and translate it:

```r
all_orfs <- c(find_orfs(seq), find_orfs(as.character(reverseComplement(DNAString(seq)))))
longest <- all_orfs[which.max(nchar(all_orfs))]
as.character(translate(DNAString(longest)))
```

(`find_orfs` steps with `pos <- pos + 3`.) Note that `gregexpr` finds
non-overlapping matches, which works here because two ATGs can't overlap.

**Common slips.** Searching only the given strand (here, the long ORF may be on
the other one); stepping 1 base at a time instead of 3; or including the stop.

**The biology.** This is a simplified gene finder. Real mouse genes are split into
exons, so one ORF in the genome usually isn't a whole gene. To get the real
protein, researchers use annotated transcripts from databases such as Ensembl,
which is where track 2 begins.
