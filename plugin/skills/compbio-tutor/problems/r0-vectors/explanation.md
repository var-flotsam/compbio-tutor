# Vectors: worked explanation

**Method.** Compare every length with 1000, then count the TRUE values:

```r
lengths <- scan("data/r0-vectors.txt")
is_long <- lengths > 1000
sum(is_long)
```

**What you used.** `lengths > 1000` checks all 20 values at once and gives 20
TRUE/FALSE answers. `sum()` counts TRUE as 1, so it counts the long genes. You
could also write `length(lengths[lengths > 1000])`, which keeps the long genes and
then counts them.

**Common slips.** `>=` also counts genes of exactly 1000 bases, and your file has
two of those. `<` counts the short genes instead.

**The biology.** Mouse and human genes range from a few hundred bases to more than
a million. Most of that length is usually introns, the parts cut out before a gene
is used to build a protein.

**Next.** DNA sequences are text, not numbers. The next problem works with text.
