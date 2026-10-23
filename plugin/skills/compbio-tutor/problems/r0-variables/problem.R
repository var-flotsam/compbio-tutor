# Problem definition, read by the tutor with sys.source(). Lesson text: CC BY 4.0.
problem <- list(
  id = "r0-variables",
  track = 0L,
  order = 1L,
  title = "Your first R script: numbers and variables",
  goal = "Run an R script, store values in variables with <-, and do arithmetic with them.",
  dataset = "r0.base_counts",
  answer = "r0.g_fraction",
  data_ext = "txt",
  starter = "starter.R",
  answer_format = "a fraction between 0 and 1, rounded to 4 decimal places (for example 0.2817)",
  background = r"(R is a programming language built for working with data. An R script is a
plain text file of instructions that R runs from top to bottom.

Three ideas get you started:
- R can do arithmetic: 2 + 3, 10 / 4, 7 * 6.
- `<-` stores a value under a name, called a variable: `total <- 2 + 3`. After
  that, `total` means 5.
- Functions do work for you. You call one with its name and parentheses:
  `sum(c(2, 3, 4))` adds numbers up, and `round(3.14159, 2)` gives 3.14.

Your data file holds four numbers, one per line: how many times A, C, G and T
appear in a short piece of DNA, in that order.)",
  prompt = r"(What fraction of all the bases are G? That's the G count divided by the total
of all four counts.

The starter script reads the four numbers for you. Before you run anything, look
at your data file: roughly what fraction would you expect?)",
  grader = list(kind = "numeric", tolerance = 0.0001),
  hints = c(
    "Run the starter as it is first and look at what `counts` prints. Which position in it is G?",
    "`counts[3]` is the third number. `sum(counts)` adds up all four.",
    "Store the G count in one variable and the total in another, then divide and use round(x, 4)."
  )
)
