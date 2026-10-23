# Numbers and variables: worked explanation

**Method.** Read the counts, pick out G, add up the total, divide:

```r
counts <- scan("data/r0-variables.txt")
g <- counts[3]
total <- sum(counts)
round(g / total, 4)
```

**What you used.** `<-` stores a value in a variable. `counts[3]` takes the third
item, because R counts positions from 1. `sum()` and `round()` are functions:
you give them inputs in parentheses and they give back a result.

**Common slips.** Multiplying by 100 gives a percentage, not a fraction. Using
`counts[1]` gives the share of A. Dividing G by the other three counts leaves G
out of the total.

**The biology.** In a long stretch of random DNA, each base would make up about a
quarter. Real genomes are uneven: the mouse genome is about 21% G.

**Next.** `counts` holds several numbers at once. That's a vector, and the next
problem shows what you can do with one.
