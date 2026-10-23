# Counting: worked explanation

**Method.** Split the sequence into letters, count them, and take the biggest count:

```r
seq <- readLines("data/r0-counting.txt")
counts <- table(strsplit(seq, "")[[1]])
max(counts)
```

**What you used.** `strsplit()` turns one long string into a vector of letters.
`table()` counts each different letter. `max()` picks the largest count;
`names(which.max(counts))` would tell you which base it is.

**Common slips.** `min()` gives the least common base, and `nchar(seq)` gives the
length of the whole sequence.

**The biology.** Base counts are where GC content comes from: the share of G and C
among all bases. You'll compute that in Track 1.

**Next.** Real sequence files have a header line and wrap the sequence over many
lines. The next problem reads one.
