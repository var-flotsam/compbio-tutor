# GC content: worked explanation

**Method.** Drop the header line, join the sequence lines, count each base, and
divide G + C by the total length:

```r
lines <- readLines("data/t1-gc-content.fasta")
seq <- paste(lines[!startsWith(lines, ">")], collapse = "")
counts <- table(strsplit(seq, "")[[1]])
gc <- (counts[["G"]] + counts[["C"]]) / nchar(seq)
round(gc, 4)
```

**Common slips.** Reporting a percentage (48.21) instead of a fraction (0.4821);
counting only G or only C; or computing A + T by mistake, which gives 1 minus
the answer.

**The biology.** Your sequence was generated at random with a set GC content, so
the answer is not exactly 0.5. Real genomes vary too. The mouse genome as a whole is
about 42% GC, and GC-rich stretches tend to have more genes. GC content also
affects lab work: GC-rich DNA holds its strands together more tightly, so it
needs higher temperatures to separate in PCR.

**Next.** Each strand of DNA has a partner. The next problem asks what the other
strand looks like.
