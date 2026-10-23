# Problem definition, read by the tutor with sys.source(). Lesson text: CC BY 4.0.
problem <- list(
  id = "r0-vectors",
  track = 0L,
  order = 2L,
  title = "Many numbers at once: vectors",
  goal = "Work with a vector: its length, comparisons that give TRUE/FALSE, and counting with sum().",
  dataset = "r0.gene_lengths",
  answer = "r0.long_genes",
  data_ext = "txt",
  starter = "starter.R",
  answer_format = "a whole number (for example 9)",
  background = r"(A vector is R's way of holding many values in order, such as all the gene
lengths in a list. Most R functions work on a whole vector at once.

- `length(x)` tells you how many values `x` holds.
- A comparison such as `x > 5` checks every value and gives back a vector of
  TRUE and FALSE, one for each.
- `sum()` counts TRUE as 1 and FALSE as 0, so `sum(x > 5)` counts how many values
  are bigger than 5.
- `x[x > 5]` keeps only the values where the comparison is TRUE.

Genes vary a lot in length. Your data file lists the lengths, in bases, of 20
mouse-like genes, one per line.)",
  prompt = r"(How many of the genes are longer than 1000 bases?

First, guess from a quick look at the file. Then count with R.)",
  grader = list(kind = "numeric", tolerance = 0),
  hints = c(
    "Print `lengths > 1000` and look at it. What do the TRUE values mean?",
    "sum() treats TRUE as 1 and FALSE as 0. What happens if you sum the comparison?",
    "Check the boundary: is a gene of exactly 1000 bases longer than 1000? Compare `>` with `>=`."
  )
)
