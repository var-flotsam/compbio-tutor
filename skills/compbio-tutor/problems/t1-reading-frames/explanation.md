# Reading frames: worked explanation

**Method.** Translate from base 1, 2 and 3 of the sequence and of its reverse
complement, then keep the frames that have no `*`:

```r
rc <- as.character(reverseComplement(DNAString(seq)))
frames <- c(sapply(1:3, function(k) translate_codons(substring(seq, k))),
            sapply(1:3, function(k) translate_codons(substring(rc, k))))
names(frames) <- c("+1", "+2", "+3", "-1", "-2", "-3")
names(frames)[!grepl("*", frames, fixed = TRUE)]
```

**Common slip.** Checking only the three frames on the given strand. Genes can be
on either strand, so gene-finding programs always scan all six frames.

**The biology.** In random sequence, a stop codon turns up about every 21 codons
(64 / 3). Your read is only 15 codons long, so stop-free frames happen often by
chance. In longer DNA, a frame that stays open for hundreds of codons is much less
likely to be chance, which is the idea behind the next problem.
