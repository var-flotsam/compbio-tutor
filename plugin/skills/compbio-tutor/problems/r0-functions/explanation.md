# Functions and loops: worked explanation

**Method.** One function checks one sequence; a loop runs it on all of them:

```r
seqs <- readLines("data/r0-functions.txt")
has_start <- function(s) {
  grepl("ATG", s, fixed = TRUE)
}
count <- 0
for (s in seqs) {
  if (has_start(s)) {
    count <- count + 1
  }
}
count
```

**What you used.** A function packages a step so you can reuse it. The loop runs
the same code once per sequence, and the counter remembers how many matched. R
can also do this without a loop: `sum(grepl("ATG", seqs, fixed = TRUE))`. Loops
are still worth knowing, because some problems need them, such as scanning a
sequence three bases at a time in Track 1.

**Common slips.** Counting every ATG gives a bigger number, because one sequence
has two. The question asks how many sequences contain one.

**The biology.** ATG codes for methionine, so most proteins start with that amino
acid. But ATG also turns up by chance inside genes and between them, which is why
finding real genes takes more than spotting ATG.

**Next.** You've covered the R used in Track 1. Start with `t1-gc-content`.
